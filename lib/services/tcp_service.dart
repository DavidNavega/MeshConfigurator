import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/node_config.dart';

import 'package:meshtastic_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:meshtastic_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:meshtastic_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:meshtastic_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:meshtastic_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:meshtastic_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

class TcpHttpService {
  final Uri base;
  TcpHttpService(String baseUrl) : base = Uri.parse(baseUrl);

  // Empaqueta un AdminMessage como Data ADMIN_APP dentro de ToRadio.packet
  mesh.ToRadio _wrapAdmin(admin.AdminMessage msg) {
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer();

    return mesh.ToRadio()..packet = (mesh.MeshPacket()..decoded = data);
  }

  Future<NodeConfig?> readConfig() async {
    final cfgOut = NodeConfig();

    Future<void> send(admin.AdminMessage msg) async {
      final to = _wrapAdmin(msg);
      await http.put(
        base.resolve('/api/v1/toradio'),
        headers: {'Content-Type': 'application/x-protobuf'},
        body: to.writeToBuffer(),
      );
      while (true) {
        final resp = await http.get(base.resolve('/api/v1/fromradio'));
        if (resp.statusCode != 200) break;
        final bytes = resp.bodyBytes;
        if (bytes.isEmpty) break;
        final fr = mesh.FromRadio.fromBuffer(bytes);

        // User ahora llega dentro de NodeInfo
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
            (s.mode == mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO)
                ? 'WPL'
                : 'TLL',
          );
          if (s.hasBaud()) cfgOut.baudRate = s.baud;
        }

        if (fr.hasConfig() && fr.config.hasLora()) {
          cfgOut.setFrequencyRegionFromString(_regionEnumToString(fr.config.lora.region));
        }
      }
    }

    // Peticiones de lectura
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
    Future<void> send(admin.AdminMessage msg) async {
      final to = _wrapAdmin(msg);
      await http.put(
        base.resolve('/api/v1/toradio'),
        headers: {'Content-Type': 'application/x-protobuf'},
        body: to.writeToBuffer(),
      );
    }

    // ✅ Nombres del nodo: usar setUser con mesh.User (no DeviceConfig)
    final userMsg = mesh.User()
      ..shortName = cfgIn.shortName
      ..longName = cfgIn.longName;
    await send(admin.AdminMessage()..setOwner = userMsg);

    // Canal (igual que antes)
    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk = cfgIn.key;
    final channel = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role = ch.Channel_Role.PRIMARY
      ..settings = settings;
    await send(admin.AdminMessage()..setChannel = channel);

    // Serial (igual que antes)
    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = _serialModeFromString(cfgIn.serialModeAsString);
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
    await send(admin.AdminMessage()..setModuleConfig = moduleCfg);

    // LoRa (igual que antes, vía setConfig->Config.lora)
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

  mod.ModuleConfig_SerialConfig_Serial_Mode _serialModeFromString(String s) {
    switch (s.toUpperCase()) {
      case 'PROTO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
      case 'NMEA':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'CALTOPO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      default:
        return mod.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }
}
