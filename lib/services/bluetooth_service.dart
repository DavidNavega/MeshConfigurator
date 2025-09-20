import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/node_config.dart';
import 'ble_uuids.dart';

// Protobuf generados (ajusta los paths si fuera necesario)
import 'package:meshtastic_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:meshtastic_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:meshtastic_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:meshtastic_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:meshtastic_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:meshtastic_configurator/proto/meshtastic/mesh.pb.dart' as usr;

class BluetoothService {
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  BluetoothDevice? _dev;
  BluetoothCharacteristic? _toRadio;
  BluetoothCharacteristic? _fromRadio;
  BluetoothCharacteristic? _fromNum;
  StreamController<mesh.FromRadio>? _fromRadioController;
  StreamSubscription<List<int>>? _fromRadioSubscription;
  StreamQueue<mesh.FromRadio>? _fromRadioQueue;
  Completer<void>? _pendingRequest;

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }
  Future<void> _disposeRadioStreams() async {
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
          _fromRadioController?.add(frame);
        } catch (error, stackTrace) {
          _fromRadioController?.addError(error, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        _fromRadioController?.addError(error, stackTrace);
      },
    );
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

  Future<List<mesh.FromRadio>> _collectResponses({
    required bool Function(List<mesh.FromRadio>) isComplete,
    Duration timeout = _defaultResponseTimeout,
  }) async {
    final queue = _fromRadioQueue;
    if (queue == null) {
      throw StateError('Radio stream not initialized');
    }

    final responses = <mesh.FromRadio>[];
    final stopwatch = Stopwatch()..start();

    while (true) {
      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        if (responses.isEmpty) {
          throw TimeoutException('Timeout waiting for radio response');
        }
        return responses;
      }

      mesh.FromRadio frame;
      try {
        frame = await queue.next.timeout(remaining);
      } on TimeoutException {
        if (responses.isEmpty) {
          throw TimeoutException('Timeout waiting for radio response');
        }
        return responses;
      } on StateError {
        if (responses.isEmpty) rethrow;
        return responses;
      }

      responses.add(frame);

      if (isComplete(responses)) {
        final postStopwatch = Stopwatch()..start();
        while (postStopwatch.elapsed < _postResponseWindow) {
          final postRemaining = _postResponseWindow - postStopwatch.elapsed;
          if (postRemaining <= Duration.zero) break;
          try {
            final extra = await queue.next.timeout(postRemaining);
            responses.add(extra);
          } on TimeoutException {
            break;
          } on StateError {
            break;
          }
        }
        return responses;
      }
    }
  }

  Future<List<mesh.FromRadio>> _sendAndReceive(
      mesh.ToRadio message, {
        bool Function(List<mesh.FromRadio>)? isComplete,
        Duration timeout = _defaultResponseTimeout,
      }) {
    return _withRequestLock(() async {
      final toCharacteristic = _toRadio;
      if (toCharacteristic == null) {
        throw StateError('Radio write characteristic not available');
      }

      await toCharacteristic.write(
        message.writeToBuffer(),
        withoutResponse: false,
      );

      return _collectResponses(
        isComplete: isComplete ?? (responses) => responses.isNotEmpty,
        timeout: timeout,
      );
    });
  }

  Future<bool> connectAndInit() async {
    if (!await _ensurePermissions()) return false;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    BluetoothDevice? found;
    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final name = (r.device.platformName ?? '').toUpperCase();
        if (name.contains('MESHTASTIC') || name.contains('TBEAM') ||
            name.contains('HELTEC') || name.contains('XIAO')) {
          found = r.device; break;
        }
      }
      if (found != null) break;
    }
    await _ble.stopScan();
    if (found == null) return false;

    _dev = found;
    await _dev!.connect(autoConnect: false);
    try { await _dev!.requestMtu(512); } catch (_) {}

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
      await _dev!.disconnect();
      return false;
    }
    await _initializeFromRadioNotifications();
    if (_fromNum!.properties.notify) {
      await _fromNum!.setNotifyValue(true);
    }
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

    try { await _dev?.disconnect(); } catch (_) {}

    _dev = null;
    _toRadio = null;
    _fromRadio = null;
    _fromNum = null;
  }

  Future<NodeConfig?> readConfig() async {
    if (_toRadio == null || _fromRadioQueue == null) return null;
    final cfgOut = NodeConfig();

    void _applyFrameToConfig(NodeConfig cfg, mesh.FromRadio fr) {
      if (fr.hasUser()) {
        final u = fr.user;
        if (u.hasLongName()) cfg.longName = u.longName;
        if (u.hasShortName()) cfg.shortName = u.shortName;
      }
      if (fr.hasChannel()) {
        final c = fr.channel;
        if (c.hasIndex()) cfg.channelIndex = c.index;
        if (c.hasSettings() && c.settings.hasPsk()) {
          cfg.key = Uint8List.fromList(c.settings.psk);
        }
      }
      if (fr.hasModuleConfig() && fr.moduleConfig.hasSerial()) {
        final s = fr.moduleConfig.serial;
        cfg.serialOutputMode =
        (s.mode == mod.ModuleConfig_SerialConfig_SerialMode.CALTOPO) ? 'WPL' : 'TLL';
        if (s.hasBaud()) cfg.baudRate = s.baud;
      }
      if (fr.hasRadio()) {
        final r = fr.radio;
        if (r.hasLora()) {
          final region = r.lora.region;
          switch (region) {
            case 2:
              cfg.frequencyRegion = '433';
              break; // EU433
            case 3:
              cfg.frequencyRegion = '868';
              break; // EU868
            case 1:
              cfg.frequencyRegion = '915';
              break; // US915
            default:
              break;
            }
          }
        }
      }
    }

  Future<void> requestAndApply(
      mesh.ToRadio message,
      bool Function(mesh.FromRadio) matcher,
      ) async {
    try {
      final frames = await _sendAndReceive(
        message,
        isComplete: (responses) => responses.any(matcher),
        timeout: _defaultResponseTimeout,
      );
      for (final frame in frames) {
        _applyFrameToConfig(cfgOut, frame);
      }
    } on TimeoutException {
      // Ignore timeouts to allow partial configuration reads.
    }
  }

  try {
  await requestAndApply(
  mesh.ToRadio()
  ..admin = (admin.AdminMessage()
  ..getConfigRequest = (admin.AdminMessage_ConfigType.USER)),
  (frame) => frame.hasUser(),
  );
  await requestAndApply(
  mesh.ToRadio()
  ..admin = (admin.AdminMessage()
  ..getConfigRequest = (admin.AdminMessage_ConfigType.CHANNEL)),
  (frame) => frame.hasChannel(),
  );
  await requestAndApply(
  mesh.ToRadio()
  ..admin = (admin.AdminMessage()
  ..getModuleConfigRequest = (admin.ModuleConfigType.SERIAL)),
  (frame) => frame.hasModuleConfig() && frame.moduleConfig.hasSerial(),
  );
  await requestAndApply(
  mesh.ToRadio()
  ..admin = (admin.AdminMessage()
  ..getConfigRequest = (admin.AdminMessage_ConfigType.RADIO)),
  (frame) => frame.hasRadio(),
  );
  } catch (_) {
  return null;
  }

  return cfgOut;
}

  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_toRadio == null || _fromRadioQueue == null) return;

    Future<void> send(mesh.ToRadio message) async {
      try {
        await _sendAndReceive(
          message,
          isComplete: (responses) => responses.isNotEmpty,
          timeout: _defaultResponseTimeout,
        );
      } on TimeoutException {
        throw TimeoutException('Timeout waiting for radio acknowledgement');
      }
    }

    final u = usr.User()
      ..shortName = cfgIn.shortName
      ..longName  = cfgIn.longName;
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()..setUser = u));

    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk  = cfgIn.key;
    final channel = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role  = ch.Channel_Role.PRIMARY
      ..settings = settings;
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()..setChannel = channel));

    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = (cfgIn.serialOutputMode == 'WPL')
        ? mod.ModuleConfig_SerialConfig_SerialMode.CALTOPO
        : mod.ModuleConfig_SerialConfig_SerialMode.NMEA;
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()..setModuleConfig = moduleCfg));

    int regionEnum = 3; // EU868
    if (cfgIn.frequencyRegion == '433') regionEnum = 2;
    if (cfgIn.frequencyRegion == '915') regionEnum = 1;
    final lora = cfg.LoRaConfig()..region = regionEnum;
    final radio = cfg.RadioConfig()..lora = lora;
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()..setRadio = radio));
  }
}
