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

  Future<bool> connect({int baud = 115200}) async {
    final devices = await UsbSerial.listDevices();
    if (devices.isEmpty) return false;
    final dev = devices.first;
    _port = await dev.create();
    if (!await _port!.open()) return false;
    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(baud, 8, 1, UsbPort.PARITY_NONE);
    return true;
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _port?.close();
  }

  // Helper para envolver mensajes admin en ToRadio.packet
  mesh.ToRadio _wrapAdmin(admin.AdminMessage msg) {
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer();

    return mesh.ToRadio()..packet = (mesh.MeshPacket()..decoded = data);
  }

  Future<NodeConfig?> readConfig() async {
    if (_port == null) return null;

    final cfgOut = NodeConfig();

    Future<void> send(admin.AdminMessage msg) async {
      final to = _wrapAdmin(msg);
      await _port!.write(StreamFraming.frame(to.writeToBuffer()));

      final completer = Completer<void>();
      _sub = _port!.inputStream?.listen((chunk) {
        final payload = StreamFraming.deframeOnce(chunk);
        if (payload == null) return;
        final fr = mesh.FromRadio.fromBuffer(payload);

        if (fr.hasNodeInfo() && fr.nodeInfo.hasUser()) {
          final u = fr.nodeInfo.user;
          if (u.hasLongName()) cfgOut.longName = u.longName;
          if (u.hasShortName()) cfgOut.shortName = u.shortName;
        }
        if (fr.hasChannel()) {
          final c = fr.channel;
          if (c.hasIndex()) cfgOut.channelIndex = c.index;
          if (c.hasSettings() && c.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(c.settings.psk);
          }
        }
        if (fr.hasModuleConfig() && fr.moduleConfig.hasSerial()) {
          final s = fr.moduleConfig.serial;
          cfgOut.setSerialModeFromString(
              /*(s.mode == mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO)
                  ? 'WPL'
                  : 'TLL');
              */
              _serialModeEnumToString(s.mode));
          if (s.hasBaud()) cfgOut.baudRate = s.baud;
        }
        if (fr.hasConfig() && fr.config.hasLora()) {
          cfgOut.setFrequencyRegionFromString(_regionEnumToString(fr.config.lora.region));
        }

        if (!completer.isCompleted) completer.complete();
      });
      try {
        await completer.future.timeout(const Duration(seconds: 2));
      } catch (_) {}
      await _sub?.cancel();
    }

    // Peticiones de lectura (ajustadas a enums actuales)
    await send(admin.AdminMessage()
      ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG);
    await send(admin.AdminMessage()
      ..getConfigRequest = admin.AdminMessage_ConfigType.NETWORK_CONFIG);
    await send(admin.AdminMessage()
      ..getModuleConfigRequest = admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG);
    await send(admin.AdminMessage()
      ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG);

    return cfgOut;
  }

  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_port == null) return;

    Future<void> send(admin.AdminMessage msg) async {
      final to = _wrapAdmin(msg);
      await _port!.write(StreamFraming.frame(to.writeToBuffer()));
    }

    // ✅ Nombres → ahora con setOwner
    final userMsg = mesh.User()
      ..shortName = cfgIn.shortName
      ..longName = cfgIn.longName;
    await send(admin.AdminMessage()..setOwner = userMsg);

    // Canal
    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk = cfgIn.key;
    final channel = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role = ch.Channel_Role.PRIMARY
      ..settings = settings;
    await send(admin.AdminMessage()..setChannel = channel);

    // Serial
    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = _serialModeFromString(cfgIn.serialModeAsString);
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
    await send(admin.AdminMessage()..setModuleConfig = moduleCfg);

    // LoRa
    final lora = cfg.Config_LoRaConfig()
      ..region = _regionFromString(cfgIn.frequencyRegionAsString);
    final configMsg = cfg.Config()..lora = lora;
    await send(admin.AdminMessage()..setConfig = configMsg);
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
