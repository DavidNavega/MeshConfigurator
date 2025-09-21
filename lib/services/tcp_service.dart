import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/node_config.dart';

import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:Buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:Buoys_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:Buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

class TcpHttpService {
  Uri? _base;

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _pollDelay = Duration(milliseconds: 200);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);

  TcpHttpService([String? baseUrl]) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      updateBaseUrl(baseUrl);
    }
  }

  bool get isConfigured => _base != null;

  Uri get base {
    final current = _base;
    if (current == null) {
      throw StateError('Base URL not configured');
    }
    return current;
  }

  void updateBaseUrl(String baseUrl) {
    _base = Uri.parse(baseUrl);
  }

  void clearBaseUrl() {
    _base = null;
  }

  // Empaqueta un AdminMessage como Data ADMIN_APP dentro de ToRadio.packet
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

  bool _isAckOrResponse(mesh.FromRadio frame) {
    return frame.hasPacket() && frame.packet.hasDecoded();
  }

  Future<List<mesh.FromRadio>> _sendAndReceive(
      admin.AdminMessage msg, {
        bool Function(List<mesh.FromRadio>)? isComplete,
        Duration timeout = _defaultResponseTimeout,
      }) async {
        final base = this.base;
        final to = _wrapAdmin(msg);

        await http.put(
          base.resolve('/api/v1/toradio'),
          headers: {'Content-Type': 'application/x-protobuf'},
          body: to.writeToBuffer(),
        );

        final responses = <mesh.FromRadio>[];
        var ackSeen = false;
        var userSatisfied = false;
        final deadline = DateTime.now().add(timeout);

        while (true) {
          if (DateTime.now().isAfter(deadline)) {
            if (!ackSeen) {
              throw TimeoutException('Timeout waiting for radio acknowledgement');
            }
            throw TimeoutException('Timeout waiting for radio response');
          }

          final resp = await http.get(base.resolve('/api/v1/fromradio'));
          if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
            await Future.delayed(_pollDelay);
            continue;
          }

          final frame = mesh.FromRadio.fromBuffer(resp.bodyBytes);
          responses.add(frame);

          if (!ackSeen && _isAckOrResponse(frame)) {
            ackSeen = true;
          }

          userSatisfied = isComplete?.call(responses) ?? true;

          if (ackSeen && userSatisfied) {
            final postDeadline = DateTime.now().add(_postResponseWindow);

            while (DateTime.now().isBefore(postDeadline)) {
              if (DateTime.now().isAfter(deadline)) break;

              final extraResp = await http.get(base.resolve('/api/v1/fromradio'));
              if (extraResp.statusCode != 200 || extraResp.bodyBytes.isEmpty) {
                await Future.delayed(_pollDelay);
                continue;
              }
              final extraFrame = mesh.FromRadio.fromBuffer(extraResp.bodyBytes);
              responses.add(extraFrame);
            }

            return responses;
          }
        }
  }

  Future<NodeConfig?> readConfig() async {
    final cfgOut = NodeConfig();

    var primaryChannelCaptured = false;

    void applyFrame(mesh.FromRadio fr) {
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
        cfgOut.setSerialModeFromString(
          _serialModeEnumToString(s.mode),
        );
        if (s.hasBaud()) cfgOut.baudRate = s.baud;
      }

      if (fr.hasConfig() && fr.config.hasLora()) {
        cfgOut.setFrequencyRegionFromString(
          _regionEnumToString(fr.config.lora.region),
        );
      }
    }

    Future<void> request(
        admin.AdminMessage msg,
        bool Function(mesh.FromRadio) matcher,
        ) async {
      try {
        final frames = await _sendAndReceive(
          msg,
          isComplete: (responses) => responses.any(matcher),
        );
        for (final frame in frames) {
          applyFrame(frame);
        }
      } on TimeoutException {
        // Ignoramos para continuar intentando leer el resto de la config
      }
    }

    await request(
      admin.AdminMessage()
        ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG,
          (fr) => fr.hasConfig() && fr.config.hasDevice(),
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

    return cfgOut;
  }

  Future<void> writeConfig(NodeConfig cfgIn) async {

    // ✅ Nombres del nodo: usar setUser con mesh.User (no DeviceConfig)
    final userMsg = mesh.User()
      ..shortName = cfgIn.shortName
      ..longName = cfgIn.longName;
    await _sendAndReceive(admin.AdminMessage()..setOwner = userMsg);

    // Canal (igual que antes)
    final settings = ch.ChannelSettings()
      ..name = "CH${cfgIn.channelIndex}"
      ..psk = cfgIn.key;
    final channel = ch.Channel()
      ..index = cfgIn.channelIndex
      ..role = ch.Channel_Role.PRIMARY
      ..settings = settings;
    await _sendAndReceive(admin.AdminMessage()..setChannel = channel);

    // Serial (igual que antes)
    final serialCfg = mod.ModuleConfig_SerialConfig()
      ..enabled = true
      ..baud = cfgIn.baudRate
      ..mode = _serialModeFromString(cfgIn.serialModeAsString);
    final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
    await _sendAndReceive(admin.AdminMessage()..setModuleConfig = moduleCfg);

    // LoRa (igual que antes, vía setConfig->Config.lora)
    final lora = cfg.Config_LoRaConfig()
      ..region = _regionFromString(cfgIn.frequencyRegionAsString);
    final configMsg = cfg.Config()..lora = lora;
    await _sendAndReceive(admin.AdminMessage()..setConfig = configMsg);
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
}
