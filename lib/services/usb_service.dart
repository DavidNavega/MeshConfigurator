import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

import '../models/node_config.dart';
import 'stream_framing.dart';

import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:Buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:Buoys_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:Buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

class UsbService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _sub;
  FrameAccumulator? _frameAccumulator;
  StreamController<mesh.FromRadio>? _frameController;

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);

  Future<bool> connect({int baud = 115200}) async {
    final devices = await UsbSerial.listDevices();
    if (devices.isEmpty) return false;
    final dev = devices.first;
    _port = await dev.create();
    if (!await _port!.open()) return false;
    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(baud, 8, 1, UsbPort.PARITY_NONE);
    _frameAccumulator = FrameAccumulator();
    _frameController = StreamController<mesh.FromRadio>.broadcast();

    final input = _port!.inputStream;
    if (input == null) {
      await disconnect();
      return false;
    }

    _sub = input.listen((chunk) {
      final accumulator = _frameAccumulator;
      final controller = _frameController;
      if (accumulator == null || controller == null || controller.isClosed) {
        return;
      }
      for (final payload in accumulator.addChunk(chunk)) {
        try {
          controller.add(mesh.FromRadio.fromBuffer(payload));
        } catch (_) {
          // Ignoramos frames inválidos o emisiones tras el cierre del stream.
        }
      }
    });
    return true;
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    if (_frameController != null && !_frameController!.isClosed) {
      await _frameController!.close();
    }
    _frameController = null;
    _frameAccumulator = null;
    await _port?.close();
    _port = null;
  }

  // Helper para envolver mensajes admin en ToRadio.packet
  mesh.ToRadio _wrapAdmin(admin.AdminMessage msg) {
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer()
      ..wantResponse = true;

    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..wantAck = true
        ..decoded = data);
  }

  Future<NodeConfig?> readConfig() async {
    if (_port == null || _frameController == null) return null;

    final cfgOut = NodeConfig();

    var primaryChannelCaptured = false;
    var primaryChannelLogged = false;

    void _applyAdmin(admin.AdminMessage message) {
      if (message.hasGetOwnerResponse()) {
        final user = message.getOwnerResponse;
        if (user.hasLongName()) {
          cfgOut.longName = user.longName;
        }
        if (user.hasShortName()) {
          cfgOut.shortName = user.shortName;
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
                '[UsbService] readConfig() capturó canal ${cfgOut.channelIndex} con PSK (${cfgOut.key.length} bytes).');
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

    void _consumeFrame(mesh.FromRadio fr) {
      final adminMsg = _decodeAdminMessage(fr);
      if (adminMsg != null) {
        _applyAdmin(adminMsg);
      }
    }

    final subscription = _frameController!.stream.listen(_consumeFrame);

    Future<bool> request(
        admin.AdminMessage msg,
        bool Function(admin.AdminMessage) matcher,
        ) async {
      try {
        await _sendAdminAndWait(msg, matcher: matcher);
        return true;
      } on TimeoutException {
        return false;
      }
    }

    var receivedAnyResponse = false;

    try {
      final ownerReceived = await request(
        admin.AdminMessage()..getOwnerRequest = true,
            (msg) => msg.hasGetOwnerResponse(),
      );
      receivedAnyResponse = receivedAnyResponse || ownerReceived;

      final deviceConfigReceived = await request(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG,
            (msg) =>
        msg.hasGetConfigResponse() && msg.getConfigResponse.hasDevice(),
      );
      receivedAnyResponse = receivedAnyResponse || deviceConfigReceived;
      final indicesToQuery = <int>{cfgOut.channelIndex};
      for (var i = 0; i < 8; i++) {
        indicesToQuery.add(i);
      }
      for (final index in indicesToQuery) {
        final channelReceived = await request(
          admin.AdminMessage()..getChannelRequest = index + 1,
              (msg) => msg.hasGetChannelResponse(),
        );
        receivedAnyResponse = receivedAnyResponse || channelReceived;
        if (primaryChannelCaptured) break;
      }
      final serialReceived = await request(
        admin.AdminMessage()
          ..getModuleConfigRequest =
              admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
            (msg) =>
        msg.hasGetModuleConfigResponse() &&
            msg.getModuleConfigResponse.hasSerial(),
      );
      receivedAnyResponse = receivedAnyResponse || serialReceived;

      final loraReceived = await request(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
            (msg) =>
        msg.hasGetConfigResponse() &&
            msg.getConfigResponse.hasLora() &&
            msg.getConfigResponse.lora.hasRegion(),
      );
      receivedAnyResponse = receivedAnyResponse || loraReceived;

      if (!receivedAnyResponse) {
        throw TimeoutException('No se recibió respuesta de configuración');
      }
    } finally {
      await subscription.cancel();
    }

    return cfgOut;
  }

  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_port == null) return;

    // ✅ Nombres → ahora con setOwner
    final userMsg = mesh.User()
      ..shortName = cfgIn.shortName
      ..longName = cfgIn.longName;
    await _sendAdmin(admin.AdminMessage()..setOwner = userMsg);

    // Canal
    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk = cfgIn.key;
    final channel = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role = ch.Channel_Role.PRIMARY
      ..settings = settings;
    await _sendAdmin(admin.AdminMessage()..setChannel = channel);

    // Serial
    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = _serialModeFromString(cfgIn.serialModeAsString);
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
    await _sendAdmin(admin.AdminMessage()..setModuleConfig = moduleCfg);

    // LoRa
    final lora = cfg.Config_LoRaConfig()
      ..region = _regionFromString(cfgIn.frequencyRegionAsString);
    final configMsg = cfg.Config()..lora = lora;
    await _sendAdmin(admin.AdminMessage()..setConfig = configMsg);
  }

  Future<void> _sendAdmin(admin.AdminMessage msg) async {
    final port = _port;
    if (port == null) return;
    final to = _wrapAdmin(msg);
    await port.write(StreamFraming.frame(to.writeToBuffer()));
  }

  Future<void> _sendAdminAndWait(
      admin.AdminMessage msg, {
        required bool Function(admin.AdminMessage) matcher,
        Duration timeout = const Duration(seconds: 2),
      }) {
    return _sendToRadioAndWait(
      _wrapAdmin(msg),
      matcher: matcher,
      timeout: timeout,
    );
  }

  Future<void> _sendToRadioAndWait(
      mesh.ToRadio to, {
        required bool Function(admin.AdminMessage) matcher,
        Duration timeout = const Duration(seconds: 2),
      }) async {
    final port = _port;
    final controller = _frameController;
    if (port == null || controller == null || controller.isClosed) {
      throw StateError('Puerto USB no disponible');
    }

    final completer = Completer<void>();
    var allowMatch = false;
    Future<void>? cancelFuture;
    late StreamSubscription<mesh.FromRadio> sub;
    sub = controller.stream.listen((frame) {
      if (!allowMatch) return;
      final adminMsg = _decodeAdminMessage(frame);
      if (adminMsg == null) return;
      if (!completer.isCompleted && matcher(adminMsg)) {
        completer.complete();
        cancelFuture ??= sub.cancel();
      }
    });

    try {
      final writeFuture = port.write(StreamFraming.frame(to.writeToBuffer()));
      allowMatch = true;
      await writeFuture;
      await completer.future.timeout(timeout);
    } finally {
      await (cancelFuture ?? sub.cancel());
    }
  }

  // ------- helpers -------
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
      case 'TLL':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'WPL':
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
      return admin.AdminMessage.fromBuffer(payload);
    } catch (_) {
      return null;
    }
  }
}
