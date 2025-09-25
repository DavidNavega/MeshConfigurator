import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';

import 'transport/radio_transport.dart';

import '../../proto/meshtastic/mesh.pb.dart' as mesh;
import '../../proto/meshtastic/admin.pb.dart' as admin;
import '../../proto/meshtastic/channel.pb.dart' as ch;
import '../../proto/meshtastic/config.pb.dart' as cfg;
import '../../proto/meshtastic/module_config.pb.dart' as mod;
import '../../proto/meshtastic/portnums.pbenum.dart' as port;

import '../../models/node_config.dart';
import '../routing_error_utils.dart'; // si no lo usas, quítalo

/// RadioCoordinator = cerebro de sesión/cola/handshake/heartbeats.
/// Los transports solo mueven bytes; aquí se construyen ToRadio/AdminMessage,
/// se matchean respuestas y se llenan NodeConfig.
class RadioCoordinator {
  static final Logger _log = Logger('RadioCoordinator');

  final RadioTransport _transport;
  final void Function(Object? error)? _onTransportClosed;

  // stream de frames FromRadio ya decodificados (a partir de bytes entrantes)
  final _fromRadioCtrl = StreamController<mesh.FromRadio>.broadcast();
  Stream<mesh.FromRadio> get frames => _fromRadioCtrl.stream;

  StreamSubscription<Uint8List>? _rxSub;
  Timer? _heartbeatTimer;

  // Estado de sesión
  int? _myNodeNum;
  bool _sessionReady = false;
  Uint8List _sessionPasskey = Uint8List(0);
  int _nonce = 0;

  // Exclusión (solo 1 petición en vuelo)
  Completer<void>? _pending;

  // Tiempos
  static const _tAck = Duration(seconds: 5);
  static const _heartbeatEvery = Duration(minutes: 5);

  RadioCoordinator(this._transport, {void Function(Object? error)? onTransportClosed})
      : _onTransportClosed = onTransportClosed;

  int? get myNodeNum => _myNodeNum;

  Future<bool> connect() async {
    await _rxSub?.cancel();
    _rxSub = null;
    _clearSessionState();

    try {
      final ok = await _transport.connect();
      if (!ok) {
        return false;
      }
    } catch (e, st) {
      _log.warning('Error conectando transporte', e, st);
      return false;
    }

    // Suscribe bytes entrantes -> FromRadio
    _rxSub = _transport.inbound.listen((bytes) {
      try {
        final fr = mesh.FromRadio.fromBuffer(bytes);
        _captureMyNodeNum(fr);
        _fromRadioCtrl.add(fr);
      } catch (e) {
        _log.info('FromRadio inválido: $e');
      }
    }, onError: (e, st) {
      _fromRadioCtrl.addError(e, st);
      _handleTransportClosed(e);
    }, onDone: () {
      final err = StateError('Transport cerrado');
      _fromRadioCtrl.addError(err);
      _handleTransportClosed(err);
    }, cancelOnError: true);

    // Handshake: want_config_id + esperar MyInfo
    try {
      await _startConfigSession();
      await _ensureMyNodeNum();
    } catch (e, st) {
      _log.warning('Error durante handshake inicial', e, st);
      await disconnect();
      return false;
    }

    _sessionReady = true;
    _startHeartbeats();
    return true;
  }

  Future<void> disconnect() async {
    _clearSessionState();
    await _rxSub?.cancel();
    _rxSub = null;
    try {
      await _transport.disconnect();
    } catch (e, st) {
      _log.fine('Error desconectando transporte: $e', e, st);
    }

    // cerrar stream si quieres terminar ciclo de vida:
    // await _fromRadioCtrl.close();
  }

  // ----------------- API de alto nivel -----------------

  /// Lee la configuración completa requerida por la app.
  Future<NodeConfig> readConfig() async {
    _ensureSessionOrThrow();

    final out = NodeConfig();
    var primaryCaptured = false;

    void apply(admin.AdminMessage m) {
      _capturePasskey(m);
      if (m.hasGetOwnerResponse()) {
        final u = m.getOwnerResponse;
        if (u.hasShortName()) out.shortName = u.shortName;
        if (u.hasLongName()) out.longName = u.longName;
      }
      if (m.hasGetChannelResponse()) {
        final chResp = m.getChannelResponse;
        final isPrimary = chResp.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryCaptured) {
          if (chResp.hasIndex()) out.channelIndex = chResp.index;
          if (chResp.hasSettings() && chResp.settings.hasPsk()) {
            out.key = Uint8List.fromList(chResp.settings.psk);
          }
        }
        if (isPrimary) primaryCaptured = true;
      }
      if (m.hasGetModuleConfigResponse() &&
          m.getModuleConfigResponse.hasSerial()) {
        final s = m.getModuleConfigResponse.serial;
        if (s.hasBaud()) out.baudRate = s.baud;
        if (s.hasMode()) out.serialOutputMode = s.mode;
      }
      if (m.hasGetConfigResponse() &&
          m.getConfigResponse.hasLora() &&
          m.getConfigResponse.lora.hasRegion()) {
        out.frequencyRegion = m.getConfigResponse.lora.region;
      }
    }

    // owner
    await _sendAdminAndWait(
      msg: admin.AdminMessage()..getOwnerRequest = true,
      matcher: (m) => m.hasGetOwnerResponse(),
      onEachMatch: apply,
      description: 'GetOwner',
    );

    // LoRa region
    await _sendAdminAndWait(
      msg: admin.AdminMessage()
        ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
      matcher: (m) =>
      m.hasGetConfigResponse() &&
          m.getConfigResponse.hasLora() &&
          m.getConfigResponse.lora.hasRegion(),
      onEachMatch: apply,
      description: 'Get LoRa',
    );

    // Canal primario (y fallback por índice conocido)
    final indices = <int>{0};
    if (out.channelIndex > 0 && out.channelIndex <= 8) {
      indices.add(out.channelIndex);
    }
    for (final idx in indices) {
      if (primaryCaptured && idx != 0 && idx != out.channelIndex) continue;
      await _sendAdminAndWait(
        msg: admin.AdminMessage()..getChannelRequest = idx + 1, // IMPORTANTE: +1
        matcher: (m) =>
        m.hasGetChannelResponse() && m.getChannelResponse.index == idx,
        onEachMatch: apply,
        description: 'GetChannel[$idx]',
      );
      if (primaryCaptured && out.channelIndex == idx) break;
    }

    // Serial
    await _sendAdminAndWait(
      msg: admin.AdminMessage()
        ..getModuleConfigRequest =
            admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
      matcher: (m) =>
      m.hasGetModuleConfigResponse() && m.getModuleConfigResponse.hasSerial(),
      onEachMatch: apply,
      description: 'Get Serial',
    );

    return out;
  }

  /// Escribe todos los campos de configuración requeridos.
  Future<void> writeConfig(NodeConfig cfgIn) async {
    _ensureSessionOrThrow();

    // setOwner
    final user = mesh.User()
      ..shortName = cfgIn.shortName
      ..longName = cfgIn.longName;
    await _sendAdminAndWait(
      msg: admin.AdminMessage()..setOwner = user,
      // ACK + no siempre hay respuesta de eco, así que el matcher es la llegada de cualquier ADMIN ACK/respuesta
      matcher: (m) => m.hasSetOwnerResponse() || m.hasGetOwnerResponse(),
      description: 'SetOwner',
    );

    // setChannel (PRIMARY) con PSK
    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk = cfgIn.key; // 0/1/16/32 bytes
    final chan = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role = ch.Channel_Role.PRIMARY
      ..settings = settings;
    await _sendAdminAndWait(
      msg: admin.AdminMessage()..setChannel = chan,
      matcher: (m) =>
      m.hasGetChannelResponse() &&
          m.getChannelResponse.index == cfgIn.channelIndex,
      description: 'SetChannel',
    );

    // setModuleConfig (Serial)
    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = _serialModeFromString(cfgIn.serialModeAsString);
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
    await _sendAdminAndWait(
      msg: admin.AdminMessage()..setModuleConfig = moduleCfg,
      matcher: (m) =>
      m.hasGetModuleConfigResponse() && m.getModuleConfigResponse.hasSerial(),
      description: 'SetModuleConfig(Serial)',
    );

    // setConfig (LoRa)
    final lo = cfg.Config_LoRaConfig()
      ..region = _regionFromString(cfgIn.frequencyRegionAsString);
    final conf = cfg.Config()..lora = lo;
    await _sendAdminAndWait(
      msg: admin.AdminMessage()..setConfig = conf,
      matcher: (m) =>
      m.hasGetConfigResponse() &&
          m.getConfigResponse.hasLora() &&
          m.getConfigResponse.lora.hasRegion(),
      description: 'SetConfig(LoRa)',
    );
  }

  // --------------- Internos de sesión / envío ---------------

  Future<void> _startConfigSession() async {
    final to = mesh.ToRadio()..wantConfigId = _nextNonce();
    await _sendToRadio(to);
  }

  void _startHeartbeats() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(_heartbeatEvery, (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final hb = mesh.ToRadio()..heartbeat = mesh.Heartbeat();
    await _sendToRadio(hb);
  }

  Future<void> _ensureMyNodeNum() async {
    if (_myNodeNum != null) return;

    final completer = Completer<void>();
    late StreamSubscription sub;
    sub = frames.listen((fr) {
      if (fr.hasMyInfo() && fr.myInfo.hasMyNodeNum()) {
        _myNodeNum = fr.myInfo.myNodeNum;
        completer.complete();
        sub.cancel();
      }
    }, onError: (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    });

    // pedir want_config_id para forzar MyInfo si aún no llegó
    final to = mesh.ToRadio()..wantConfigId = _nextNonce();
    await _sendToRadio(to);

    await completer.future.timeout(_tAck);
  }

  Future<void> _sendAdminAndWait({
    required admin.AdminMessage msg,
    required bool Function(admin.AdminMessage) matcher,
    void Function(admin.AdminMessage)? onEachMatch,
    Duration timeout = _tAck,
    String? description,
  }) async {
    _ensureSessionOrThrow();
    await _withLock(() async {
      final to = _wrapAdmin(msg);
      final type = description ?? msg.info_.messageName;

      final done = Completer<void>();
      late StreamSubscription sub;
      sub = frames.listen((fr) {
        try {
          // Lanza si el frame trae error de routing (si no usas esta utilidad, elimina try/catch)
          throwIfRoutingError(fr);
        } catch (e) {
          if (!done.isCompleted) done.completeError(e);
          sub.cancel();
          return;
        }
        final adm = _decodeAdmin(fr);
        if (adm == null) return;
        onEachMatch?.call(adm);
        if (matcher(adm) && !done.isCompleted) {
          done.complete();
          sub.cancel();
        }
      }, onError: (e, st) {
        if (!done.isCompleted) done.completeError(e, st);
      });

      await _sendToRadio(to);
      try {
        await done.future.timeout(timeout);
      } finally {
        await sub.cancel();
      }

      _log.info('[RadioCoordinator] $type OK');
    });
  }

  Future<void> _sendToRadio(mesh.ToRadio to) async {
    final bytes = Uint8List.fromList(to.writeToBuffer());
    await _transport.send(bytes);
  }

  mesh.ToRadio _wrapAdmin(admin.AdminMessage msg) {
    if (_myNodeNum == null) {
      throw StateError('myNodeNum no inicializado');
    }
    // inyectar sessionPasskey si procede
    if (_sessionPasskey.isNotEmpty && msg.sessionPasskey.isEmpty) {
      msg.sessionPasskey = Uint8List.fromList(_sessionPasskey);
    }
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer()
      ..wantResponse = true;

    final pkt = mesh.MeshPacket()
      ..to = _myNodeNum!
      ..from = 0
      ..id = DateTime
          .now()
          .millisecondsSinceEpoch &
      0xFFFFFFFF
      ..priority = mesh.MeshPacket_Priority.RELIABLE
      ..wantAck = true
      ..decoded = data;

    return mesh.ToRadio()..packet = pkt;
  }

  admin.AdminMessage? _decodeAdmin(mesh.FromRadio fr) {
    if (!fr.hasPacket()) return null;
    final p = fr.packet;
    if (!p.hasDecoded()) return null;
    final d = p.decoded;
    if (d.portnum != port.PortNum.ADMIN_APP) return null;
    if (!d.hasPayload()) return null;
    try {
      final m = admin.AdminMessage.fromBuffer(d.payload);
      _capturePasskey(m);
      return m;
    } catch (_) {
      return null;
    }
  }

  void _capturePasskey(admin.AdminMessage m) {
    if (m.sessionPasskey.isNotEmpty) {
      _sessionPasskey = Uint8List.fromList(m.sessionPasskey);
    }
  }

  void _captureMyNodeNum(mesh.FromRadio fr) {
    if (fr.hasMyInfo() && fr.myInfo.hasMyNodeNum()) {
      _myNodeNum = fr.myInfo.myNodeNum;
    }
  }

  void _handleTransportClosed(Object? error) {
    _clearSessionState();
    try {
      _transport.disconnect().catchError((e, st) {
        _log.fine('Error cerrando transporte tras desconexión: $e', e, st);
      });
    } catch (e, st) {
      _log.fine('Error cerrando transporte tras desconexión: $e', e, st);
    }
    _onTransportClosed?.call(error);
  }

  void _clearSessionState() {
    _sessionReady = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Sesión reiniciada'));
    }

    _myNodeNum = null;
    _sessionPasskey = Uint8List(0);
    _nonce = 0;
  }

  int _nextNonce() {
    _nonce = (_nonce + 1) & 0xFFFFFFFF;
    if (_nonce == 0) _nonce = 1;
    return _nonce;
  }

  Future<T> _withLock<T>(Future<T> Function() action) async {
    while (_pending != null) {
      try {
        await _pending!.future;
      } catch (_) {
        break;
      }
    }
    final c = Completer<void>();
    _pending = c;
    try {
      return await action();
    } finally {
      _pending = null;
      if (!c.isCompleted) c.complete();
    }
  }

  void _ensureSessionOrThrow() {
    if (!_sessionReady) {
      throw StateError('Sesión no inicializada');
    }
  }

  // mapeos string -> enums
  cfg.Config_LoRaConfig_RegionCode _regionFromString(String s) {
    switch (s) {
      case '433':
        return cfg.Config_LoRaConfig_RegionCode.EU_433;
      case '915':
        return cfg.Config_LoRaConfig_RegionCode.US;
      case '868':
      default:
        return cfg.Config_LoRaConfig_RegionCode.EU_868;
    }
  }

  mod.ModuleConfig_SerialConfig_Serial_Mode _serialModeFromString(String s) {
    switch (s.toUpperCase()) {
      case 'WPL':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      case 'TLL':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'PROTO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
      case 'TEXTMSG':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
      default:
        return mod.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }
}
