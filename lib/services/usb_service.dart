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

    void _consumeFrame(mesh.FromRadio fr) {
      if (fr.hasNodeInfo() && fr.nodeInfo.hasUser()) {
        final u = fr.nodeInfo.user;
        if (u.hasLongName()) cfgOut.longName = u.longName;
        if (u.hasShortName()) cfgOut.shortName = u.shortName;
      }
      if (fr.hasChannel()) {
        final c = fr.channel;
        final isPrimary = c.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryChannelCaptured) {
          if (c.hasIndex()) cfgOut.channelIndex = c.index;
          if (c.hasSettings() && c.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(c.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
        }
      }
      if (fr.hasModuleConfig() && fr.moduleConfig.hasSerial()) {
        final s = fr.moduleConfig.serial;
        cfgOut.setSerialModeFromString(_serialModeEnumToString(s.mode));
        if (s.hasBaud()) cfgOut.baudRate = s.baud;
      }
      if (fr.hasConfig() && fr.config.hasLora()) {
        cfgOut.setFrequencyRegionFromString(
            _regionEnumToString(fr.config.lora.region));
      }
    }

    final subscription = _frameController!.stream.listen(_consumeFrame);

    Future<void> request(
        admin.AdminMessage msg,
        bool Function(mesh.FromRadio) matcher,
        ) async {
      await _sendAdminAndWait(msg, matcher: matcher);
    }
    try {
      await request(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG,
            (fr) => fr.hasNodeInfo() && fr.nodeInfo.hasUser(),
      );
      final indicesToQuery = <int>{cfgOut.channelIndex};
      for (var i = 0; i < 8; i++) {
        indicesToQuery.add(i);
      }
      for (final index in indicesToQuery) {
        await request(
          admin.AdminMessage()..getChannelRequest = index,
              (fr) => fr.hasChannel(),
        );
        if (primaryChannelCaptured) break;
      }
      await request(
        admin.AdminMessage()
          ..getModuleConfigRequest =
              admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
            (fr) => fr.hasModuleConfig() && fr.moduleConfig.hasSerial(),
      );
      await request(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
            (fr) => fr.hasConfig() && fr.config.hasLora(),
      );
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

  Future<mesh.FromRadio?> _sendAdminAndWait(
      admin.AdminMessage msg, {
        required bool Function(mesh.FromRadio) matcher,
        Duration timeout = const Duration(seconds: 2),
      }) {
    return _sendToRadioAndWait(
      _wrapAdmin(msg),
      matcher: matcher,
      timeout: timeout,
    );
  }

  Future<mesh.FromRadio?> _sendToRadioAndWait(
      mesh.ToRadio to, {
        required bool Function(mesh.FromRadio) matcher,
        Duration timeout = const Duration(seconds: 2),
      }) async {
    final port = _port;
    final controller = _frameController;
    if (port == null || controller == null || controller.isClosed) return null;

    final completer = Completer<mesh.FromRadio>();
    var allowMatch = false;
    Future<void>? cancelFuture;
    late StreamSubscription<mesh.FromRadio> sub;
    sub = controller.stream.listen((frame) {
      if (!allowMatch) return;
      if (!completer.isCompleted && matcher(frame)) {
        completer.complete(frame);
        cancelFuture ??= sub.cancel();
      }
    });

    try {
      final writeFuture = port.write(StreamFraming.frame(to.writeToBuffer()));
      allowMatch = true;
      await writeFuture;
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      return null;
    } finally {
      await (cancelFuture ?? sub.cancel());
    }
  }

  // ------- helpers -------
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

  String _serialModeEnumToString(
      mod.ModuleConfig_SerialConfig_Serial_Mode mode) {
    switch (mode) {
      case mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO:
        return 'PROTO';
      case mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG:
        return 'TEXTMSG';
      case mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO:
        return 'WPL';
      case mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA:
        return 'TLL';
      default:
        return 'DEFAULT';
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
}
