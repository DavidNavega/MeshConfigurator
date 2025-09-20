import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/node_config.dart';

import 'package:meshtastic_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:meshtastic_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:meshtastic_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:meshtastic_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:meshtastic_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:meshtastic_configurator/proto/meshtastic/user.pb.dart' as usr;

class TcpHttpService {
  final Uri base;
  TcpHttpService(String baseUrl) : base = Uri.parse(baseUrl);

  Future<NodeConfig?> readConfig() async {
    final cfgOut = NodeConfig();

    Future<void> send(mesh.ToRadio to) async {
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

        if (fr.hasUser()) {
          final u = fr.user;
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
          cfgOut.serialOutputMode =
              (s.mode == mod.ModuleConfig_SerialConfig_SerialMode.CALTOPO) ? 'WPL' : 'TLL';
          if (s.hasBaud()) cfgOut.baudRate = s.baud;
        }
        if (fr.hasRadio()) {
          final r = fr.radio;
          if (r.hasLora()) {
            final region = r.lora.region;
            switch (region) {
              case 2: cfgOut.frequencyRegion = '433'; break;
              case 3: cfgOut.frequencyRegion = '868'; break;
              case 1: cfgOut.frequencyRegion = '915'; break;
              default: break;
            }
          }
        }
      }
    }

    await send(mesh.ToRadio()..admin = (admin.AdminMessage()
      ..getConfigRequest = (admin.AdminMessage_ConfigType.USER)));
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()
      ..getConfigRequest = (admin.AdminMessage_ConfigType.CHANNEL)));
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()
      ..getModuleConfigRequest = (admin.ModuleConfigType.SERIAL)));
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()
      ..getConfigRequest = (admin.AdminMessage_ConfigType.RADIO)));

    return cfgOut;
  }

  Future<void> writeConfig(NodeConfig cfgIn) async {
    Future<void> send(mesh.ToRadio to) async {
      await http.put(
        base.resolve('/api/v1/toradio'),
        headers: {'Content-Type': 'application/x-protobuf'},
        body: to.writeToBuffer(),
      );
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

    int regionEnum = 3;
    if (cfgIn.frequencyRegion == '433') regionEnum = 2;
    if (cfgIn.frequencyRegion == '915') regionEnum = 1;
    final lora = cfg.LoRaConfig()..region = regionEnum;
    final radio = cfg.RadioConfig()..lora = lora;
    await send(mesh.ToRadio()..admin = (admin.AdminMessage()..setRadio = radio));
  }
}
