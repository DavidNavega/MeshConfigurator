import 'dart:async';
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
import 'package:meshtastic_configurator/proto/meshtastic/user.pb.dart' as usr;

class BluetoothService {
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  BluetoothDevice? _dev;
  BluetoothCharacteristic? _toRadio;
  BluetoothCharacteristic? _fromRadio;
  BluetoothCharacteristic? _fromNum;

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<bool> connectAndInit() async {
    if (!await _ensurePermissions()) return false;
    await _ble.startScan(timeout: const Duration(seconds: 8));
    BluetoothDevice? found;
    await for (final results in _ble.scanResults) {
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
    if (_fromNum!.properties.notify) {
      await _fromNum!.setNotifyValue(true);
    }
    return true;
  }

  Future<void> disconnect() async {
    try { await _dev?.disconnect(); } catch (_) {}
  }

  Future<NodeConfig?> readConfig() async {
    if (_toRadio == null || _fromRadio == null) return null;
    final cfgOut = NodeConfig();

    Future<void> send(mesh.ToRadio to) async {
      await _toRadio!.write(to.writeToBuffer(), withoutResponse: false);
      while (true) {
        final data = await _fromRadio!.read();
        if (data.isEmpty) break;
        final fr = mesh.FromRadio.fromBuffer(data);

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
              case 2: cfgOut.frequencyRegion = '433'; break; // EU433
              case 3: cfgOut.frequencyRegion = '868'; break; // EU868
              case 1: cfgOut.frequencyRegion = '915'; break; // US915
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
    if (_toRadio == null) return;

    Future<void> send(mesh.ToRadio to) async {
      await _toRadio!.write(to.writeToBuffer(), withoutResponse: false);
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
