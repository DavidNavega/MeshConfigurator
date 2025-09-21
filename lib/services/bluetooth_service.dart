import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
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

      await _writeToRadio(toCharacteristic, toRadioMsg.writeToBuffer());
      var ackSeen = false;
      var userSatisfied = false;

      try {
        await toCharacteristic.write(
          toRadioMsg.writeToBuffer(),
          withoutResponse: false,
        );
      } on FlutterBluePlusException catch (err) {
        final message = err.description?.toLowerCase() ?? '';
        if (message.contains('write not permitted')) {
          await toCharacteristic.write(
            toRadioMsg.writeToBuffer(),
            withoutResponse: true,
          );
        } else {
          rethrow;
        }
      }

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

  Future<void> _writeToRadio(
      BluetoothCharacteristic characteristic, List<int> payload) async {
    final supportsWriteWithoutResponse =
        characteristic.properties.writeWithoutResponse;
    final supportsWriteWithResponse = characteristic.properties.write;

    final attempts = <bool>[];
    if (supportsWriteWithoutResponse) {
      attempts.add(true);
    }
    if (supportsWriteWithResponse) {
      attempts.add(false);
    }

    if (attempts.isEmpty) {
      throw StateError('Characteristic does not support write operations');
    }

    FlutterBluePlusException? lastWriteNotPermitted;
    for (final withoutResponse in attempts) {
      try {
        await characteristic.write(
          payload,
          withoutResponse: withoutResponse,
        );
        return;
      } on FlutterBluePlusException catch (err) {
        if (_isWriteNotPermittedError(err)) {
          lastWriteNotPermitted = err;
          continue;
        }
        rethrow;
      }
    }

    if (lastWriteNotPermitted != null &&
        attempts.length == 1 &&
        attempts.first == false) {
      try {
        await characteristic.write(
          payload,
          withoutResponse: true,
        );
        return;
      } on FlutterBluePlusException catch (err) {
        if (_isWriteNotPermittedError(err)) {
          lastWriteNotPermitted = err;
        } else {
          rethrow;
        }
      }
    }

    if (lastWriteNotPermitted != null) {
      throw lastWriteNotPermitted;
    }

    throw StateError('Failed to write to characteristic');
  }

  bool _isWriteNotPermittedError(FlutterBluePlusException err) {
    final message = err.description?.toLowerCase() ?? '';
    return message.contains('write not permitted');
  }

  // -------- conexión ----------
  Future<bool> connectAndInit() async {
    if (!await _ensurePermissions()) return false;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    BluetoothDevice? found;

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final name = r.device.platformName.toUpperCase();
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
    var primaryChannelLogged = false;

    void _applyAdminToConfig(admin.AdminMessage message) {
      if (message.hasGetOwnerResponse()) {
        final user = message.getOwnerResponse;
        if (user.hasShortName()) {
          cfgOut.shortName = user.shortName;
        }
        if (user.hasLongName()) {
          cfgOut.longName = user.longName;
        }
      }

      if (message.hasGetChannelResponse()) {
        final channel = message.getChannelResponse;
        final isPrimary = channel.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryChannelCaptured) {
          if (channel.hasIndex()) {
            final rawIndex = channel.index;
            cfgOut.channelIndex = rawIndex > 0 ? rawIndex - 1 : rawIndex;
          }
          if (channel.hasSettings() && channel.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(channel.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
          if (!primaryChannelLogged) {
            primaryChannelLogged = true;
            print(
                '[BluetoothService] readConfig() capturó canal ${cfgOut.channelIndex} con PSK (${cfgOut.key.length} bytes).');
          }
        }
      }

      if (message.hasGetModuleConfigResponse() &&
          message.getModuleConfigResponse.hasSerial()) {
        final serial = message.getModuleConfigResponse.serial;
        if (serial.hasMode()) {
          cfgOut.serialOutputMode = serial.mode;
        }
        if (serial.hasBaud()) {
          cfgOut.baudRate = serial.baud;
        }
      }

      if (message.hasGetConfigResponse() &&
          message.getConfigResponse.hasLora() &&
          message.getConfigResponse.lora.hasRegion()) {
        cfgOut.frequencyRegion = message.getConfigResponse.lora.region;
      }
    }

    Future<bool> _requestAndApply(admin.AdminMessage msg,
        bool Function(admin.AdminMessage) matcher) async {
      List<mesh.FromRadio> frames;
      try {
        frames = await _sendAndReceive(
          _wrapAdminToToRadio(msg),
          isComplete: (responses) => responses.any((fr) {
            final adminMsg = _decodeAdminMessage(fr);
            return adminMsg != null && matcher(adminMsg);
          }),
          timeout: _defaultResponseTimeout,
        );
      } on TimeoutException {
        return false;
      }

      var matched = false;
      for (final f in frames) {
        final adminMsg = _decodeAdminMessage(f);
        if (adminMsg == null) {
          continue;
        }
        debugPrint('Received admin response: ${adminMsg.toString()}');
        if (matcher(adminMsg)) {
          matched = true;
        }
        _applyAdminToConfig(adminMsg);
      }
      return matched;
    }

    var receivedAnyResponse = false;

    final ownerReceived = await _requestAndApply(
      admin.AdminMessage()..getOwnerRequest = true,
          (msg) => msg.hasGetOwnerResponse(),
    );
    receivedAnyResponse = receivedAnyResponse || ownerReceived;

    final loraReceived = await _requestAndApply(
      admin.AdminMessage()
        ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
          (msg) =>
      msg.hasGetConfigResponse() &&
          msg.getConfigResponse.hasLora() &&
          msg.getConfigResponse.lora.hasRegion(),
    );
    receivedAnyResponse = receivedAnyResponse || loraReceived;

    final indicesToQuery = <int>{cfgOut.channelIndex};
    for (var i = 0; i < 8; i++) {
      indicesToQuery.add(i);
    }
    for (final index in indicesToQuery) {
      final channelReceived = await _requestAndApply(
        admin.AdminMessage()..getChannelRequest = index + 1,
            (msg) => msg.hasGetChannelResponse(),
      );
      receivedAnyResponse = receivedAnyResponse || channelReceived;
      if (primaryChannelCaptured) break;
    }
    final serialReceived = await _requestAndApply(
      admin.AdminMessage()
        ..getModuleConfigRequest =
            admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
          (msg) =>
      msg.hasGetModuleConfigResponse() &&
          msg.getModuleConfigResponse.hasSerial(),
    );
    receivedAnyResponse = receivedAnyResponse || serialReceived;

    if (!receivedAnyResponse) {
      throw TimeoutException('No se recibió respuesta de configuración');
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
      return admin.AdminMessage.fromBuffer(payload);
    } catch (_) {
      return null;
    }
  }

  // ------- helpers enum <-> string -------
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
