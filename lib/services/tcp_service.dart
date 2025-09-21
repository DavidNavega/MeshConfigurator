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

    void applyAdmin(admin.AdminMessage message) {
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
            cfgOut.channelIndex = channel.index;
          }
          if (channel.hasSettings() && channel.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(channel.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
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

    Future<bool> request(
        admin.AdminMessage msg,
        bool Function(admin.AdminMessage) matcher,
        ) async {
      List<mesh.FromRadio> frames;
      try {
        frames = await _sendAndReceive(
          msg,
          isComplete: (responses) => responses.any((frame) {
            final adminMsg = _decodeAdminMessage(frame);
            return adminMsg != null && matcher(adminMsg);
          }),
        );
      } on TimeoutException {
        return false;
      }

      var matched = false;
      for (final frame in frames) {
        final adminMsg = _decodeAdminMessage(frame);
        if (adminMsg == null) {
          continue;
        }
        if (matcher(adminMsg)) {
          matched = true;
        }
        applyAdmin(adminMsg);
      }
      return matched;
    }

    var receivedAnyResponse = false;

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
        admin.AdminMessage()..getChannelRequest = index,
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
