import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../models/node_config.dart';
import 'stream_framing.dart';

import 'package:buoys_configurator/exceptions/routing_error_exception.dart';
import 'package:buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:buoys_configurator/proto/meshtastic/module_config.pb.dart'
    as mod;
import 'package:buoys_configurator/proto/meshtastic/portnums.pbenum.dart'
    as port;
import 'package:buoys_configurator/services/routing_error_utils.dart';

class TcpHttpService {
  static final Logger _log = Logger('TcpHttpService');
  Socket? _socket;
  StreamSubscription<Uint8List>? _sub;
  FrameAccumulator? _frameAccumulator;
  StreamController<mesh.FromRadio>? _frameController;

  String? _lastErrorMessage;
  int? _myNodeNum;
  bool _nodeNumConfirmed = false;
  Uint8List _sessionPasskey = Uint8List(0);

  Timer? _heartbeatTimer;
  int _configNonce = 0;
  Future<void> _writeChain = Future.value();
  Completer<void>? _pendingRequest;

  static const Duration _defaultResponseTimeout = Duration(seconds: 15);
  static const Duration _heartbeatInterval = Duration(minutes: 5);
  static const Duration _connectTimeout = Duration(seconds: 5);

  String? _host;
  int _port = 4403;

  String? get lastErrorMessage => _lastErrorMessage;

  int? get myNodeNum => _myNodeNum;
  set myNodeNum(int? value) {
    _myNodeNum = value;
    _nodeNumConfirmed = false;
    if (value == null) {
      _sessionPasskey = Uint8List(0);
      _resetSessionState();
    }
  }

  bool get isConfigured => _host != null;

  void updateBaseUrl(String baseUrl) {
    final parsed = _parseAddress(baseUrl);
    _host = parsed.$1;
    _port = parsed.$2;
    _resetSessionState();
    _lastErrorMessage = null;
  }

  void clearBaseUrl() {
    _host = null;
    _port = 4403;
    _resetSessionState();
    unawaited(disconnect());
  }

  Future<bool> connect() async {
    try {
      await _openSocket();
      return _socket != null;
    } catch (error) {
      _lastErrorMessage ??= 'Error conectando socket TCP: ${error.toString()}';
      return false;
    }
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _sub?.cancel();
    _sub = null;

    await _frameController?.close();
    _frameController = null;
    _frameAccumulator = null;

    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (_) {
        // Ignorar errores al cerrar el socket.
      }
    }
    _socket = null;

    _writeChain = Future.value();
    _pendingRequest = null;

    _myNodeNum = null;
    _nodeNumConfirmed = false;
    _sessionPasskey = Uint8List(0);
  }

  Future<NodeConfig?> readConfig() async {
    try {
      await _openSocket();
    } catch (error) {
      _lastErrorMessage ??= 'Error conectando socket TCP: ${error.toString()}';
      return null;
    }

    final controller = _frameController;
    if (_socket == null || controller == null) {
      _lastErrorMessage =
          'Socket TCP no conectado para leer configuraciÃƒÆ’Ã‚Â³n.';
      return null;
    }

    try {
      await _ensureMyNodeNum();
    } catch (error, stackTrace) {
      _log.info(
          '[TcpService] readConfig fallÃƒÆ’Ã‚Â³ en _ensureMyNodeNum: ${error.toString()}. Stack: $stackTrace');
      _lastErrorMessage =
          'Error al obtener NodeNum para leer config: ${error.toString()}';
      return null;
    }

    _log.info(
        '[TcpService] Iniciando lectura de configuraciÃƒÆ’Ã‚Â³n del nodo $_myNodeNum...');
    final cfgOut = NodeConfig();
    var primaryChannelCaptured = false;

    void applyAdmin(admin.AdminMessage message) {
      _captureSessionPasskey(message);
      if (message.hasGetOwnerResponse()) {
        final user = message.getOwnerResponse;
        if (user.hasLongName()) cfgOut.longName = user.longName;
        if (user.hasShortName()) cfgOut.shortName = user.shortName;
      }
      if (message.hasGetChannelResponse()) {
        final channel = message.getChannelResponse;
        final isPrimary = channel.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryChannelCaptured) {
          if (channel.hasIndex()) cfgOut.channelIndex = channel.index;
          if (channel.hasSettings() && channel.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(channel.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
          _log.info(
              '[TcpService] readConfig: Canal PRIMARIO ${cfgOut.channelIndex} capturado con PSK (longitud: ${cfgOut.key.length} bytes).');
        }
      }
      if (message.hasGetModuleConfigResponse() &&
          message.getModuleConfigResponse.hasSerial()) {
        final serial = message.getModuleConfigResponse.serial;
        if (serial.hasMode()) cfgOut.serialOutputMode = serial.mode;
        if (serial.hasBaud()) cfgOut.baudRate = serial.baud;
      }
      if (message.hasGetConfigResponse() &&
          message.getConfigResponse.hasLora() &&
          message.getConfigResponse.lora.hasRegion()) {
        cfgOut.frequencyRegion = message.getConfigResponse.lora.region;
      }
    }

    bool receivedAnyResponse = false;

    Future<bool> request(
      admin.AdminMessage msgToSend,
      bool Function(admin.AdminMessage) matcher,
      String description,
    ) async {
      _log.info('[TcpService] readConfig: Solicitando $description...');
      try {
        await _sendAdminAndWait(
          msg: msgToSend,
          matcher: matcher,
          timeout: _defaultResponseTimeout,
          description: description,
        );
        _log.info(
            '[TcpService] readConfig: Respuesta recibida para $description.');
        return true;
      } on TimeoutException {
        _log.info(
            '[TcpService] readConfig: Timeout esperando respuesta para $description.');
        return false;
      } catch (error, stackTrace) {
        _log.info(
            '[TcpService] readConfig: Error en request para $description: $error. Stack: $stackTrace');
        if (error is RoutingErrorException) {
          _lastErrorMessage = error.message;
        } else {
          _lastErrorMessage =
              'Error solicitando $description: ${error.toString()}';
        }
        return false;
      }
    }

    final controllerSub = controller.stream.listen((frame) {
      final adminMsg = _decodeAdminMessage(frame);
      if (adminMsg != null) {
        applyAdmin(adminMsg);
      }
    });

    try {
      final ownerReceived = await request(
        admin.AdminMessage()..getOwnerRequest = true,
        (msg) => msg.hasGetOwnerResponse(),
        'OwnerInfo',
      );
      receivedAnyResponse = receivedAnyResponse || ownerReceived;

      final deviceCfgReceived = await request(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG,
        (msg) =>
            msg.hasGetConfigResponse() && msg.getConfigResponse.hasDevice(),
        'DeviceConfig',
      );
      receivedAnyResponse = receivedAnyResponse || deviceCfgReceived;

      final indicesToQuery = <int>{0};
      if (cfgOut.channelIndex > 0 && cfgOut.channelIndex <= 8) {
        indicesToQuery.add(cfgOut.channelIndex);
      }
      indicesToQuery.addAll(List<int>.generate(8, (i) => i + 1));

      for (final index in indicesToQuery) {
        if (primaryChannelCaptured) break;
        final channelReceived = await request(
          admin.AdminMessage()..getChannelRequest = index,
          (msg) =>
              msg.hasGetChannelResponse() &&
              msg.getChannelResponse.index == index,
          'Channel index $index',
        );
        receivedAnyResponse = receivedAnyResponse || channelReceived;
      }

      final serialReceived = await request(
        admin.AdminMessage()
          ..getModuleConfigRequest =
              admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
        (msg) =>
            msg.hasGetModuleConfigResponse() &&
            msg.getModuleConfigResponse.hasSerial(),
        'SerialConfig',
      );
      receivedAnyResponse = receivedAnyResponse || serialReceived;

      final loraReceived = await request(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
        (msg) =>
            msg.hasGetConfigResponse() &&
            msg.getConfigResponse.hasLora() &&
            msg.getConfigResponse.lora.hasRegion(),
        'LoRaConfig',
      );
      receivedAnyResponse = receivedAnyResponse || loraReceived;
    } finally {
      await controllerSub.cancel();
    }

    if (!receivedAnyResponse) {
      throw TimeoutException(
          'No se recibiÃƒÆ’Ã‚Â³ respuesta de configuraciÃƒÆ’Ã‚Â³n');
    }

    return cfgOut;
  }

  Future<void> writeConfig(NodeConfig cfgIn) async {
    await _openSocket();
    await _ensureMyNodeNum();

    _log.info(
        '[TcpService] Enviando configuraciÃƒÆ’Ã‚Â³n para el nodo $_myNodeNum...');

    Future<void> sendCommand(admin.AdminMessage msg, String description) async {
      _log.info('[TcpService] writeConfig: Enviando comando: $description');
      try {
        await _sendAdminAndWait(
          msg: msg,
          matcher: (_) => true,
          timeout: _defaultResponseTimeout,
          description: description,
        );
        _log.info(
            '[TcpService] writeConfig: Comando enviado y ACK recibido para $description.');
      } on TimeoutException catch (error) {
        _lastErrorMessage = 'Timeout enviando $description';
        throw TimeoutException(
            'Timeout enviando $description: ${error.message}');
      }
    }

    try {
      final userMsg = mesh.User()
        ..shortName = cfgIn.shortName
        ..longName = cfgIn.longName;
      await sendCommand(admin.AdminMessage()..setOwner = userMsg, 'SetOwner');

      final settings = ch.ChannelSettings()
        ..name = 'CH${cfgIn.channelIndex}'
        ..psk = cfgIn.key;
      final channel = ch.Channel()
        ..index = cfgIn.channelIndex
        ..role = ch.Channel_Role.PRIMARY
        ..settings = settings;
      await sendCommand(
          admin.AdminMessage()..setChannel = channel, 'SetChannel');

      final serialCfg = mod.ModuleConfig_SerialConfig()
        ..enabled = true
        ..baud = cfgIn.baudRate
        ..mode = _serialModeFromString(cfgIn.serialModeAsString);
      final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
      await sendCommand(
          admin.AdminMessage()..setModuleConfig = moduleCfg, 'SetModuleConfig');

      final lora = cfg.Config_LoRaConfig()
        ..region = _regionFromString(cfgIn.frequencyRegionAsString);
      final configMsg = cfg.Config()..lora = lora;
      await sendCommand(
          admin.AdminMessage()..setConfig = configMsg, 'SetConfig');

      _log.info('[TcpService] writeConfig: todos los comandos enviados.');
    } catch (error) {
      _lastErrorMessage ??=
          'Error general durante writeConfig: ${error.toString()}';
      rethrow;
    }
  }

  Future<void> _openSocket() async {
    if (_socket != null) {
      return;
    }
    final host = _host;
    if (host == null) {
      throw StateError('Base URL not configured');
    }

    try {
      _log.info('[TcpService] Conectando a $host:$_port ...');
      final socket =
          await Socket.connect(host, _port, timeout: _connectTimeout);
      socket.setOption(SocketOption.tcpNoDelay, true);
      _socket = socket;

      _frameAccumulator = FrameAccumulator();
      _frameController = StreamController<mesh.FromRadio>.broadcast();

      _sub = socket.listen(
        (Uint8List chunk) {
          final accumulator = _frameAccumulator;
          final controller = _frameController;
          if (accumulator == null ||
              controller == null ||
              controller.isClosed) {
            return;
          }

          final data = chunk;
          for (final payload in accumulator.addChunk(data)) {
            try {
              final frame = mesh.FromRadio.fromBuffer(payload);
              _captureMyNodeNum(frame);
              if (!controller.isClosed) {
                controller.add(frame);
              }
            } catch (error, stackTrace) {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            }
          }
        },
        onError: (error, stackTrace) {
          _lastErrorMessage = 'Error en el socket TCP: ${error.toString()}';
          _log.info(
              '[TcpService] Error en socket TCP: $error. Stack: $stackTrace');
          unawaited(disconnect());
        },
        onDone: () {
          _lastErrorMessage ??= 'Socket TCP cerrado por el servidor';
          _log.info('[TcpService] Socket TCP cerrado por el servidor');
          unawaited(disconnect());
        },
        cancelOnError: true,
      );

      await _enqueueWrite(Uint8List.fromList([0x94, 0x94, 0x94, 0x94]));
      await _startConfigSession();
    } catch (error) {
      await disconnect();
      _lastErrorMessage =
          'Error conectando a $host:$_port -> ${error.toString()}';
      throw StateError(_lastErrorMessage!);
    }
  }

  Future<void> _ensureMyNodeNum() async {
    await _openSocket();
    if (_nodeNumConfirmed && _myNodeNum != null) {
      return;
    }
    final controller = _frameController;
    if (controller == null || controller.isClosed) {
      throw StateError('Stream TCP no disponible para _ensureMyNodeNum');
    }

    _log.info(
        '[TcpService] Asegurando MyNodeNum (confirmado=$_nodeNumConfirmed, num=$_myNodeNum)...');

    await _withRequestLock(() async {
      if (_nodeNumConfirmed && _myNodeNum != null) {
        return;
      }

      final infoFuture = controller.stream
          .where((frame) => frame.hasMyInfo() && frame.myInfo.hasMyNodeNum())
          .map((frame) => frame.myInfo.myNodeNum)
          .first
          .timeout(_defaultResponseTimeout, onTimeout: () {
        _log.info('[TcpService] Timeout esperando MyInfo en _ensureMyNodeNum.');
        throw TimeoutException(
            'Timeout esperando MyNodeInfo del radio (stream).');
      });

      final toRadio = mesh.ToRadio()
        ..wantConfigId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

      _log.info(
          '[TcpService] Enviando solicitud de MyInfo (wantConfigId: ${toRadio.wantConfigId}).');
      await _enqueueWrite(StreamFraming.frame(toRadio.writeToBuffer()));

      final nodeNum = await infoFuture;
      _myNodeNum = nodeNum;
      _nodeNumConfirmed = true;
      _log.info('[TcpService] MyNodeNum asegurado y confirmado: $_myNodeNum');
    });

    if (_myNodeNum == null) {
      throw StateError('No se pudo determinar el NodeNum del radio.');
    }
  }

  Future<void> _startConfigSession() async {
    await _withRequestLock(() async {
      final socket = _socket;
      if (socket == null) {
        throw StateError('Socket TCP no disponible');
      }

      final nonce = _nextConfigNonce();
      final toRadio = mesh.ToRadio()..wantConfigId = nonce;
      await _enqueueWrite(StreamFraming.frame(toRadio.writeToBuffer()));
    });

    _startHeartbeatTimer();
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final heartbeat = mesh.ToRadio()..heartbeat = mesh.Heartbeat();
    try {
      await _enqueueWrite(StreamFraming.frame(heartbeat.writeToBuffer()));
    } catch (error) {
      _log.info('[TcpService] Error enviando heartbeat TCP: $error');
    }
  }

  int _nextConfigNonce() {
    _configNonce = (_configNonce + 1) & 0xFFFFFFFF;
    if (_configNonce == 0) {
      _configNonce = 1;
    }
    return _configNonce;
  }

  Future<void> _sendAdminAndWait({
    required admin.AdminMessage msg,
    required bool Function(admin.AdminMessage) matcher,
    required Duration timeout,
    required String description,
  }) async {
    final controller = _frameController;
    if (controller == null || controller.isClosed) {
      throw StateError('Stream TCP no disponible para enviar comandos');
    }

    await _withRequestLock(() async {
      final toRadio = _wrapAdmin(msg);
      final completer = Completer<void>();
      var commandSent = false;
      Future<void>? cancelSubFuture;
      late StreamSubscription<mesh.FromRadio> sub;

      sub = controller.stream.listen((frame) {
        if (!commandSent || completer.isCompleted) {
          return;
        }
        try {
          throwIfRoutingError(frame);
        } on RoutingErrorException catch (error) {
          _lastErrorMessage = error.message;
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          cancelSubFuture ??= sub.cancel();
          return;
        }

        final adminMsg = _decodeAdminMessage(frame);
        if (adminMsg != null && matcher(adminMsg)) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          cancelSubFuture ??= sub.cancel();
        }
      });

      try {
        await _enqueueWrite(StreamFraming.frame(toRadio.writeToBuffer()));
        commandSent = true;
        await completer.future.timeout(timeout);
      } on TimeoutException {
        _lastErrorMessage = 'Timeout esperando respuesta para $description.';
        throw TimeoutException(
            'Timeout esperando respuesta para $description.');
      } finally {
        await (cancelSubFuture ?? sub.cancel());
      }
    });
  }

  mesh.ToRadio _wrapAdmin(admin.AdminMessage adminMsg) {
    final nodeNum = _myNodeNum;
    if (nodeNum == null) {
      throw StateError(
          '_myNodeNum no inicializado. Llama a _ensureMyNodeNum antes de enviar comandos administrativos.');
    }
    _injectSessionPasskey(adminMsg);
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = adminMsg.writeToBuffer()
      ..wantResponse = true;

    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;
    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..to = nodeNum
        ..from = 0
        ..id = packetId
        ..priority = mesh.MeshPacket_Priority.RELIABLE
        ..wantAck = true
        ..decoded = data);
  }

  Future<T> _withRequestLock<T>(Future<T> Function() action) async {
    while (_pendingRequest != null) {
      try {
        await _pendingRequest!.future;
      } catch (_) {
        break;
      }
    }
    final completer = Completer<void>();
    _pendingRequest = completer;
    try {
      return await action();
    } finally {
      _pendingRequest = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> _enqueueWrite(Uint8List data) {
    final socket = _socket;
    if (socket == null) {
      throw StateError('Socket TCP no disponible para escritura.');
    }
    _writeChain = _writeChain.then((_) async {
      socket.add(data);
      await socket.flush();
    });
    return _writeChain;
  }

  void _captureSessionPasskey(admin.AdminMessage message) {
    if (message.sessionPasskey.isNotEmpty) {
      _sessionPasskey = Uint8List.fromList(message.sessionPasskey);
    }
  }

  void _injectSessionPasskey(admin.AdminMessage msg) {
    if (_sessionPasskey.isEmpty) return;
    if (msg.sessionPasskey.isNotEmpty) return;
    msg.sessionPasskey = Uint8List.fromList(_sessionPasskey);
  }

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
      case 'PROTO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
      case 'TEXTMSG':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
      case 'TLL':
      case 'NMEA':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'WPL':
      case 'CALTOPO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      default:
        return mod.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }

  admin.AdminMessage? _decodeAdminMessage(mesh.FromRadio frame) {
    if (!frame.hasPacket()) return null;
    final packet = frame.packet;
    if (!packet.hasDecoded()) return null;
    final decoded = packet.decoded;
    if (!decoded.hasPayload()) return null;
    if (decoded.portnum != port.PortNum.ADMIN_APP) return null;
    final payload = decoded.payload;
    if (payload.isEmpty) return null;
    try {
      final message = admin.AdminMessage.fromBuffer(payload);
      _captureSessionPasskey(message);
      return message;
    } catch (error) {
      _log.info('[TcpService] Error al deserializar AdminMessage: $error');
      return null;
    }
  }

  void _captureMyNodeNum(mesh.FromRadio frame) {
    if (frame.hasMyInfo() && frame.myInfo.hasMyNodeNum()) {
      final newNum = frame.myInfo.myNodeNum;
      if (_myNodeNum != newNum) {
        _log.info(
            '[TcpService] MyNodeNum capturado/actualizado: $_myNodeNum -> $newNum');
        _myNodeNum = newNum;
        _nodeNumConfirmed = true;
      } else if (!_nodeNumConfirmed) {
        _log.info('[TcpService] MyNodeNum re-confirmado: $newNum');
        _nodeNumConfirmed = true;
      }
    }
  }

  void _resetSessionState() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _configNonce = 0;
    _writeChain = Future.value();
    _pendingRequest = null;
    _nodeNumConfirmed = false;
    _myNodeNum = null;
    _sessionPasskey = Uint8List(0);
  }

  (String, int) _parseAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError('URL TCP invÃƒÆ’Ã‚Â¡lida');
    }

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      uri = null;
    }

    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host;
      final port = uri.hasPort
          ? uri.port
          : (uri.scheme == 'https' ? 443 : (uri.scheme == 'http' ? 80 : 4403));
      return (host, port);
    }

    final parts = trimmed.split(':');
    if (parts.length == 2) {
      final host = parts.first;
      final port = int.tryParse(parts.last) ?? 4403;
      return (host, port);
    }

    return (trimmed, 4403);
  }
}
