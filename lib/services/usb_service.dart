import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

import '../models/node_config.dart';
import 'stream_framing.dart';

import 'package:meshtastic_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:meshtastic_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:meshtastic_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:meshtastic_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:meshtastic_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:meshtastic_configurator/proto/meshtastic/user.pb.dart' as usr;

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

  Future<NodeConfig?> readConfig() async {
    if (_port == null) return null;

    final cfgOut = NodeConfig();

    Future<void> send(mesh.ToRadio to) async {
      await _port!.write(StreamFraming.frame(to.writeToBuffer()));
      final completer = Completer<void>();
      _sub = _port!.inputStream?.listen((chunk) {
        final payload = StreamFraming.deframeOnce(chunk);
        if (payload == null) return;
        final fr = mesh.FromRadio.fromBuffer(payload);

        if (fr.hasUser()) {
          final u = fr.user;
          if (u.hasLongName()) cfgOut.longName = u.longName;
          if (u.hasShortName()) cfgOut.shortName = u.shortName;
        }
        if (fr.hasChannel()) {
          final c = fr.channel;
          if (c.hasIndex()) cfgOut.channelIndex = c.index;
          if (c.hasSettings() && c.settings.hasPsk()) cfgOut.key = c.settings.psk;
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
        if (!completer.isCompleted) { completer.complete(); }
      });
      try { await completer.future.timeout(const Duration(seconds: 2)); } catch (_) {}
      await _sub?.cancel();
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
    if (_port == null) return;

    Future<void> send(mesh.ToRadio to) async {
      await _port!.write(StreamFraming.frame(to.writeToBuffer()));
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
