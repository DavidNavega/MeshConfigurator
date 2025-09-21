import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/node_config.dart';
import 'ble_uuids.dart';

// Protobuf 2.6.1
import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:Buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:Buoys_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:Buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

class BluetoothService {
  BluetoothDevice? _dev;
  BluetoothCharacteristic? _toRadio;
  BluetoothCharacteristic? _fromRadio;
  BluetoothCharacteristic? _fromNum;

  StreamController<mesh.FromRadio>? _fromRadioController;
  StreamSubscription<List<int>>? _fromRadioSubscription;
  StreamSubscription<List<int>>? _fromNumSubscription;
  StreamQueue<mesh.FromRadio>? _fromRadioQueue;

  Completer<void>? _pendingRequest;

  int _lastFromNum = 0;

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);

  // -------- permisos ----------
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // -------- streams ----------
  Future<void> _disposeRadioStreams() async {
    await _fromNumSubscription?.cancel();
    _fromNumSubscription = null;
    await _fromRadioSubscription?.cancel();
    _fromRadioSubscription = null;
    await _fromRadioQueue?.cancel();
    _fromRadioQueue = null;
    await _fromRadioController?.close();
    _fromRadioController = null;
  }

  Future<void> _initializeFromRadioNotifications() async {
    final characteristic = _fromRadio;
    if (characteristic == null) return;

    await _disposeRadioStreams();

    _fromRadioController = StreamController<mesh.FromRadio>.broadcast();
    _fromRadioQueue = StreamQueue(_fromRadioController!.stream);

    if (characteristic.properties.notify) {
      try {
        await characteristic.setNotifyValue(true);
      } catch (_) {}
    }

    _fromRadioSubscription = characteristic.onValueReceived.listen(
          (data) {
        if (data.isEmpty) return;
        try {
          final frame = mesh.FromRadio.fromBuffer(data);
          final controller = _fromRadioController;
          if (controller == null || controller.isClosed) return;
          controller.add(frame);
        } catch (err, st) {
          final controller = _fromRadioController;
          if (controller == null || controller.isClosed) return;
          controller.addError(err, st);
        }
      },
      onError: (err, st) {
        final controller = _fromRadioController;
        if (controller == null || controller.isClosed) return;
        controller.addError(err, st);
      },
    );
  }

  Future<void> _initializeFromNumNotifications() async {
    final characteristic = _fromNum;
    if (characteristic == null) return;

    await _fromNumSubscription?.cancel();
    _fromNumSubscription = null;

    _lastFromNum = 0;

    if (!characteristic.properties.notify) return;

    try {
      await characteristic.setNotifyValue(true);
    } catch (_) {}

    late final StreamSubscription<List<int>> subscription;
    subscription = characteristic.onValueReceived.listen(
          (data) {
        subscription.pause();
        _handleFromNumNotification(data).whenComplete(() {
          try {
            if (subscription.isPaused) {
              subscription.resume();
            }
          } catch (_) {}
        });
      },
      onError: (err, st) {
        final controller = _fromRadioController;
        if (controller == null || controller.isClosed) return;
        controller.addError(err, st);
      },
    );

    _fromNumSubscription = subscription;
  }

  Future<void> _handleFromNumNotification(List<int> data) async {
    if (data.isEmpty) return;

    if (data.length < 4) return;

    final current = _decodeLittleEndian(data.sublist(0, 4));
    final pending = (current - _lastFromNum) & 0xFFFFFFFF;
    if (pending == 0) {
      _lastFromNum = current;
      return;
    }

    final radioCharacteristic = _fromRadio;
    final controller = _fromRadioController;
    if (radioCharacteristic == null || controller == null || controller.isClosed) {
      return;
    }

    var processed = 0;
    for (var i = 0; i < pending; i++) {
      if (controller.isClosed) break;
      List<int> raw;
      try {
        raw = await radioCharacteristic.read();
      } catch (err, st) {
        if (!controller.isClosed) {
          controller.addError(err, st);
        }
        break;
      }

      processed++;

      if (raw.isEmpty) {
        continue;
      }

      try {
        final frame = mesh.FromRadio.fromBuffer(raw);
        if (!controller.isClosed) {
          controller.add(frame);
        }
      } catch (err, st) {
        if (!controller.isClosed) {
          controller.addError(err, st);
        }
      }
    }

    if (processed == pending) {
      _lastFromNum = current;
    }
  }

  int _decodeLittleEndian(List<int> bytes) {
    var value = 0;
    for (var i = 0; i < bytes.length; i++) {
      value |= (bytes[i] & 0xff) << (8 * i);
    }
    return value;
  }

  // -------- exclusión de petición ----------
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
      if (!completer.isCompleted) completer.complete();
    }
  }

  // -------- recolector de respuestas ----------
  Future<List<mesh.FromRadio>> _collectResponses({
    required bool Function(List<mesh.FromRadio>) isComplete,
    Duration timeout = _defaultResponseTimeout,
  }) async {
    final queue = _fromRadioQueue;
    if (queue == null) throw StateError('Radio stream not initialized');

    final responses = <mesh.FromRadio>[];
    final stopwatch = Stopwatch()..start();

    while (true) {
      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Timeout waiting for radio response');
      }

      mesh.FromRadio frame;
      try {
        frame = await queue.next.timeout(remaining);
      } on TimeoutException {
        throw TimeoutException('Timeout waiting for radio response');
      } on StateError {
        if (responses.isEmpty) rethrow;
        return responses;
      } catch (_) {
        continue;
      }

      responses.add(frame);

      if (isComplete(responses)) {

        final post = Stopwatch()..start();
        while (post.elapsed < _postResponseWindow) {
          final postRemaining = _postResponseWindow - post.elapsed;
          if (postRemaining <= Duration.zero) break;

          final totalRemaining = timeout - stopwatch.elapsed;
          if (totalRemaining <= Duration.zero) break;

          final waitFor =
          postRemaining <= totalRemaining ? postRemaining : totalRemaining;

          try {
            final extra = await queue.next.timeout(waitFor);
            responses.add(extra);
          } on TimeoutException {
            break;
          } on StateError {
            break;
          } catch (_) {
            break;
          }
        }

        return responses;
      }
    }
  }

  bool _isAckOrResponseFrame(mesh.FromRadio frame) {
    return frame.hasPacket() && frame.packet.hasDecoded();
  }

  // -------- empaquetador: AdminMessage -> MeshPacket.decoded ----------
  mesh.ToRadio _wrapAdminToToRadio(admin.AdminMessage msg) {
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer()
      ..wantResponse = true;

    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..wantAck = true
        ..decoded = data);
  }

  // -------- envío + recepción ----------
  Future<List<mesh.FromRadio>> _sendAndReceive(
      mesh.ToRadio toRadioMsg, {
        bool Function(List<mesh.FromRadio>)? isComplete,
        Duration timeout = _defaultResponseTimeout,
      }) {
    return _withRequestLock(() async {
      final toCharacteristic = _toRadio;
      if (toCharacteristic == null) {
        throw StateError('Radio write characteristic not available');
      }

      await toCharacteristic.write(
        toRadioMsg.writeToBuffer(),
        withoutResponse: false,
      );
      var ackSeen = false;
      var userSatisfied = false;

      try {
        return await _collectResponses(
          isComplete: (responses) {
            ackSeen = responses.any(_isAckOrResponseFrame);
            userSatisfied = isComplete?.call(responses) ?? true;
            return ackSeen && userSatisfied;
          },
          timeout: timeout,
        );
      } on TimeoutException {
        if (!ackSeen) {
          throw TimeoutException('Timeout waiting for radio acknowledgement');
        }
        throw TimeoutException('Timeout waiting for radio response');
      }
    });
  }

  // -------- conexión ----------
  Future<bool> connectAndInit() async {
    if (!await _ensurePermissions()) return false;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    BluetoothDevice? found;

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final name = (r.device.platformName ?? '').toUpperCase();
        if (name.contains('MESHTASTIC') ||
            name.contains('TBEAM') ||
            name.contains('HELTEC') ||
            name.contains('XIAO')) {
          found = r.device;
          break;
        }
      }
      if (found != null) break;
    }
    await FlutterBluePlus.stopScan();

    if (found == null) return false;

    _dev = found;
    await _dev!.connect(autoConnect: false);
    try {
      await _dev!.requestMtu(512);
    } catch (_) {}

    final services = await _dev!.discoverServices();
    for (final s in services) {
      if (s.uuid == MeshUuids.service) {
        for (final c in s.characteristics) {
          if (c.uuid == MeshUuids.toRadio) _toRadio = c;
          if (c.uuid == MeshUuids.fromRadio) _fromRadio = c;
          if (c.uuid == MeshUuids.fromNum) _fromNum = c;
        }
      }
    }

    if (_toRadio == null || _fromRadio == null || _fromNum == null) {
      try {
        await _dev!.disconnect();
      } catch (_) {}
      return false;
    }

    _lastFromNum = 0;
    await _initializeFromRadioNotifications();
    await _initializeFromNumNotifications();

    return true;
  }

  Future<void> disconnect() async {
    try {
      await _fromRadio?.setNotifyValue(false);
    } catch (_) {}
    try {
      await _fromNum?.setNotifyValue(false);
    } catch (_) {}

    await _disposeRadioStreams();

    try {
      await _dev?.disconnect();
    } catch (_) {}

    _dev = null;
    _toRadio = null;
    _fromRadio = null;
    _fromNum = null;
    _lastFromNum = 0;
  }

  // -------- lectura de configuración ----------
  Future<NodeConfig?> readConfig() async {
    if (_toRadio == null || _fromRadioQueue == null) return null;
    final cfgOut = NodeConfig();

    var primaryChannelCaptured = false;


    void _applyFrameToConfig(NodeConfig out, mesh.FromRadio fr) {
      if (fr.hasConfig()) {
        final conf = fr.config;

        // Device (tu build no trae .owner, así que lo quitamos)
        if (conf.hasDevice()) {
          final dev = conf.device;
          // se puede leer otros campos si tu proto lo define
        }

        if (conf.hasLora()) {
          final l = conf.lora;
          if (l.hasRegion()) {
            out.setFrequencyRegionFromString(_regionEnumToString(l.region));
          }
        }
      }

      if (fr.hasModuleConfig() && fr.moduleConfig.hasSerial()) {
        final s = fr.moduleConfig.serial;
        if (s.hasMode()) {
          out.setSerialModeFromString(_serialModeEnumToString(s.mode));
        }
        if (s.hasBaud()) {
          out.baudRate = s.baud;
        }
      }

      if (fr.hasChannel()) {
        final c = fr.channel;
        final isPrimary = c.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryChannelCaptured) {
          if (c.hasIndex()) out.channelIndex = c.index;
          if (c.hasSettings() && c.settings.hasPsk()) {
            out.key = Uint8List.fromList(c.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
        }
      }

      if (fr.hasNodeInfo()) {
        try {
          final ni = fr.nodeInfo;
          if (ni.hasUser()) {
            final u = ni.user;
            if (u.hasShortName()) out.shortName = u.shortName;
            if (u.hasLongName()) out.longName = u.longName;
          }
        } catch (_) {}
      }
    }

    Future<void> _requestAndApply(admin.AdminMessage msg,
        bool Function(mesh.FromRadio) matcher) async {
      try {
        final frames = await _sendAndReceive(
          _wrapAdminToToRadio(msg),
          isComplete: (responses) => responses.any(matcher),
          timeout: _defaultResponseTimeout,
        );
        for (final f in frames) {
          _applyFrameToConfig(cfgOut, f);
        }
      } on TimeoutException {}
    }

    try {
      await _requestAndApply(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
            (fr) => fr.hasConfig() && fr.config.hasLora(),
      );

      await _requestAndApply(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG,
            (fr) => fr.hasConfig() && fr.config.hasDevice(),
      );
      final indicesToQuery = <int>{cfgOut.channelIndex};
      for (var i = 0; i < 8; i++) {
        indicesToQuery.add(i);
      }
      for (final index in indicesToQuery) {
        await _requestAndApply(
          admin.AdminMessage()..getChannelRequest = index,
              (fr) => fr.hasChannel(),
        );
        if (primaryChannelCaptured) break;
      }
      await _requestAndApply(
        admin.AdminMessage()
          ..getModuleConfigRequest =
              admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
            (fr) => fr.hasModuleConfig() && fr.moduleConfig.hasSerial(),
      );
    } catch (_) {
      return null;
    }

    return cfgOut;
  }

  // -------- escritura de configuración ----------
  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_toRadio == null || _fromRadioQueue == null) return;

    Future<void> send(admin.AdminMessage msg) async {
      await _sendAndReceive(
        _wrapAdminToToRadio(msg),
        timeout: _defaultResponseTimeout,
      );
    }

    final user = mesh.User()
      ..shortName = cfgIn.shortName
      ..longName = cfgIn.longName;

    await send(admin.AdminMessage()..setOwner = user);

    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk = cfgIn.key;
    final channel = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role = ch.Channel_Role.PRIMARY
      ..settings = settings;

    await send(admin.AdminMessage()..setChannel = channel);

    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = _serialModeFromString(cfgIn.serialModeAsString);
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;

    await send(admin.AdminMessage()..setModuleConfig = moduleCfg);

    final lora = cfg.Config_LoRaConfig()
      ..region = _regionFromString(cfgIn.frequencyRegionAsString);
    final configMsg = cfg.Config()..lora = lora;

    await send(admin.AdminMessage()..setConfig = configMsg);
  }

  // ------- helpers enum <-> string -------
  String _serialModeEnumToString(
      mod.ModuleConfig_SerialConfig_Serial_Mode m) {
    switch (m) {
      case mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO:
        return 'PROTO';
      case mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG:
        return 'TEXTMSG';
      case mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA:
        return 'TLL';
      case mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO:
        return 'WPL';
      default:
        return 'DEFAULT';
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

  String _regionEnumToString(cfg.Config_LoRaConfig_RegionCode r) {
    switch (r) {
      case cfg.Config_LoRaConfig_RegionCode.EU_433:
        return '433';
      case cfg.Config_LoRaConfig_RegionCode.US:
        return '915';
      case cfg.Config_LoRaConfig_RegionCode.EU_868:
      default:
        return '868';
    }
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
}
