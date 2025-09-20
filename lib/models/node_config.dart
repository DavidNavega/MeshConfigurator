import 'dart:typed_data';
import 'package:protobuf/protobuf.dart' as $pb;
import '../proto/meshtastic/mesh.pb.dart' as pb;
import '../proto/meshtastic/module_config.pbenum.dart' as pb;
import '../proto/meshtastic/config.pbenum.dart' as pb;

import 'dart:convert';

// Modelo de configuración de nodo Meshtastic que manipularemos desde la app.
class NodeConfig {
  static const allowedKeyLengths = [0, 16, 32];
  String shortName;
  String longName;
  int channelIndex;
  Uint8List key; // PSK (0, 16 o 32 bytes)

  pb.ModuleConfig_SerialConfig_Serial_Baud baudRate; // 4800..115200
  pb.ModuleConfig_SerialConfig_Serial_Mode serialOutputMode; // modos serial
  pb.Config_LoRaConfig_RegionCode frequencyRegion; // región LoRa

  NodeConfig({
    this.shortName = '',
    this.longName = '',
    this.channelIndex = 0,
    Uint8List? key,
    this.baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_9600,
    this.serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.NMEA,
    this.frequencyRegion = pb.Config_LoRaConfig_RegionCode.EU_868,
  }) : key = key ?? Uint8List(0);

  // -------------------
  // Baudrate converters
  // -------------------
  void setBaudFromString(String b) {
    switch (b) {
      case '115200':
        baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_115200;
        break;
      case '921600':
        baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_921600;
        break;
      case '9600':
      default:
        baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_9600;
    }
  }

  String get baudAsString {
    switch (baudRate) {
      case pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_115200:
        return '115200';
      case pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_921600:
        return '921600';
      case pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_9600:
      default:
        return '9600';
    }
  }

  // ---------------------
  // Serial Mode converters
  // ---------------------
  void setSerialModeFromString(String m) {
    switch (m.toUpperCase()) {
      case 'PROTO':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
        break;
      case 'TEXTMSG':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
        break;
      case 'NMEA':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
        break;
      case 'CALTOPO':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
        break;
      default:
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }

  String get serialModeAsString {
    switch (serialOutputMode) {
      case pb.ModuleConfig_SerialConfig_Serial_Mode.PROTO:
        return 'PROTO';
      case pb.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG:
        return 'TEXTMSG';
      case pb.ModuleConfig_SerialConfig_Serial_Mode.NMEA:
        return 'NMEA';
      case pb.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO:
        return 'CALTOPO';
      default:
        return 'DEFAULT';
    }
  }

  // ------------------------
  // Frequency Region converters
  // ------------------------
  void setFrequencyRegionFromString(String r) {
    switch (r) {
      case '433':
        frequencyRegion = pb.Config_LoRaConfig_RegionCode.EU_433;
        break;
      case '915':
        frequencyRegion = pb.Config_LoRaConfig_RegionCode.US;
        break;
      case '868':
      default:
        frequencyRegion = pb.Config_LoRaConfig_RegionCode.EU_868;
    }
  }

  String get frequencyRegionAsString {
    switch (frequencyRegion) {
      case pb.Config_LoRaConfig_RegionCode.EU_433:
        return '433';
      case pb.Config_LoRaConfig_RegionCode.US:
        return '915';
      case pb.Config_LoRaConfig_RegionCode.EU_868:
        return '868';
      default:
        return '';
    }
  }

  // ------------------------
  // JSON support
  // ------------------------
  Map<String, dynamic> toJson() => {
    'shortName': shortName,
    'longName': longName,
    'channelIndex': channelIndex,
    'key': base64Encode(key),
    'serialOutputMode': serialModeAsString,
    'baudRate': baudAsString,
    'frequencyRegion': frequencyRegionAsString,
  };

  factory NodeConfig.fromJson(Map<String, dynamic> map) {
    final cfg = NodeConfig(
      shortName: map['shortName'] ?? '',
      longName: map['longName'] ?? '',
      channelIndex: map['channelIndex'] ?? 0,
      key: _decodeKeyFromJson(map['key']),
    );
    cfg.setSerialModeFromString(map['serialOutputMode'] ?? 'DEFAULT');
    cfg.setBaudFromString(map['baudRate']?.toString() ?? '9600');
    cfg.setFrequencyRegionFromString(map['frequencyRegion']?.toString() ?? '868');
    return cfg;
  }

  static Uint8List _decodeKeyFromJson(dynamic source) {
    if (source is String && source.isNotEmpty) {
      try {
        return Uint8List.fromList(base64Decode(source));
      } catch (_) {
        // Ignora errores y cae a lista vacía.
      }
    }
    if (source is List) {
      return Uint8List.fromList(source.cast<int>());
    }
    return Uint8List(0);
  }

  /// Convierte una cadena (hexadecimal o Base64) en bytes.
  /// Devuelve `null` si el formato no es válido.
  static Uint8List? parseKeyText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Uint8List(0);

    final noSpaces = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (noSpaces.isEmpty) return Uint8List(0);

    if (noSpaces.length.isEven && RegExp(r'^[0-9a-fA-F]+$').hasMatch(noSpaces)) {
      final bytes = Uint8List(noSpaces.length ~/ 2);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] =
            int.parse(noSpaces.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return bytes;
    }

    try {
      final decoded = base64Decode(noSpaces);
      return Uint8List.fromList(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Representación hexadecimal de la clave.
  static String keyToHex(Uint8List key) =>
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Representación Base64 de la clave.
  static String keyToBase64(Uint8List key) => base64Encode(key);

  /// Devuelve una representación amigable (hex) para la UI.
  static String keyToDisplay(Uint8List key) => keyToHex(key);

  /// Comprueba si el tamaño de la clave es válido para Meshtastic.
  static bool isValidKeyLength(Uint8List key) =>
      allowedKeyLengths.contains(key.length);

  // Helpers para la UI vía ConfigProvider
  String get keyDisplay => keyToDisplay(key);
  String? get keyError =>
      isValidKeyLength(key) ? null : "Clave inválida";
}

/*
import 'dart:typed_data';
import 'package:protobuf/protobuf.dart' as $pb;
import '../proto/meshtastic/mesh.pb.dart' as pb;
import '../proto/meshtastic/module_config.pbenum.dart' as pb;
import '../proto/meshtastic/config.pbenum.dart' as pb;

import 'dart:convert';
import 'dart:typed_data';

// Modelo de configuración de nodo Meshtastic que manipularemos desde la app.
class NodeConfig {
  static const allowedKeyLengths = [0, 16, 32];
  String shortName;
  String longName;
  int channelIndex;
  Uint8List key;             // PSK (0, 16 o 32 bytes)

  pb.ModuleConfig_SerialConfig_Serial_Baud baudRate;          // 4800..115200
  pb.ModuleConfig_SerialConfig_Serial_Mode serialOutputMode;  // "WPL" (CALTOPO) o "TLL" (NMEA)
  pb.Config_LoRaConfig_RegionCode frequencyRegion;            // "433", "868", "915"

  NodeConfig({
    this.shortName = '',
    this.longName = '',
    this.channelIndex = 0,
    Uint8List? key,
    this.baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_9600,
    this.serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.NMEA,
    this.frequencyRegion = pb.Config_LoRaConfig_RegionCode.EU_868,
  }) : key = key ?? Uint8List(0);

  // Baudrate converters
  // -------------------
  void setBaudFromString(String b) {
    switch (b) {
      case '115200':
        baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_115200;
        break;
      case '921600':
        baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_921600;
        break;
      case '9600':
      default:
        baudRate = pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_9600;
    }
  }

  String get baudAsString {
    switch (baudRate) {
      case pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_115200:
        return '115200';
      case pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_921600:
        return '921600';
      case pb.ModuleConfig_SerialConfig_Serial_Baud.BAUD_9600:
      default:
        return '9600';
    }
  }

  // ---------------------
  // Serial Mode converters
  // ---------------------
  void setSerialModeFromString(String m) {
    switch (m.toUpperCase()) {
      case 'PROTO':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
        break;
      case 'TEXTMSG':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
        break;
      case 'NMEA':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
        break;
      case 'CALTOPO':
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
        break;
      default:
        serialOutputMode = pb.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }

  String get serialModeAsString {
    switch (serialOutputMode) {
      case pb.ModuleConfig_SerialConfig_Serial_Mode.PROTO:
        return 'PROTO';
      case pb.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG:
        return 'TEXTMSG';
      case pb.ModuleConfig_SerialConfig_Serial_Mode.NMEA:
        return 'NMEA';
      case pb.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO:
        return 'CALTOPO';
      default:
        return 'DEFAULT';
    }
  }

  // ------------------------
  // Frequency Region converters
  // ------------------------
  void setFrequencyRegionFromString(String r) {
    switch (r) {
      case '433':
        frequencyRegion = pb.Config_LoRaConfig_RegionCode.EU_433;
        break;
      case '915':
        frequencyRegion = pb.Config_LoRaConfig_RegionCode.US;
        break;
      case '868':
      default:
        frequencyRegion = pb.Config_LoRaConfig_RegionCode.EU_868;
    }
  }

  String get frequencyRegionAsString {
    switch (frequencyRegion) {
      case pb.Config_LoRaConfig_RegionCode.EU_433:
        return '433';
      case pb.Config_LoRaConfig_RegionCode.US:
        return '915';
      case pb.Config_LoRaConfig_RegionCode.EU_868:
        return '868';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
    'shortName': shortName,
    'longName': longName,
    'channelIndex': channelIndex,
    'key': base64Encode(key),
    'serialOutputMode': serialOutputMode,
    'baudRate': baudRate,
    'frequencyRegion': frequencyRegion,
  };

  factory NodeConfig.fromJson(Map<String, dynamic> map) => NodeConfig(
    shortName: map['shortName'] ?? '',
    longName: map['longName'] ?? '',
    channelIndex: map['channelIndex'] ?? 0,
    key: _decodeKeyFromJson(map['key']),
    serialOutputMode: map['serialOutputMode'] ?? 'TLL',
    baudRate: map['baudRate'] ?? 9600,
    frequencyRegion: map['frequencyRegion'] ?? '868',
  );
  static Uint8List _decodeKeyFromJson(dynamic source) {
    if (source is String && source.isNotEmpty) {
      try {
        return Uint8List.fromList(base64Decode(source));
      } catch (_) {
        // Ignora errores y cae a lista vacía.
      }
    }
    if (source is List) {
      return Uint8List.fromList(source.cast<int>());
    }
    return Uint8List(0);
  }

  /// Convierte una cadena (hexadecimal o Base64) en bytes.
  /// Devuelve `null` si el formato no es válido.
  static Uint8List? parseKeyText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Uint8List(0);

    final noSpaces = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (noSpaces.isEmpty) return Uint8List(0);

    if (noSpaces.length.isEven && RegExp(r'^[0-9a-fA-F]+$').hasMatch(noSpaces)) {
      final bytes = Uint8List(noSpaces.length ~/ 2);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = int.parse(noSpaces.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return bytes;
    }

    try {
      final decoded = base64Decode(noSpaces);
      return Uint8List.fromList(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Representación hexadecimal de la clave.
  static String keyToHex(Uint8List key) =>
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Representación Base64 de la clave.
  static String keyToBase64(Uint8List key) => base64Encode(key);

  /// Devuelve una representación amigable (hex) para la UI.
  static String keyToDisplay(Uint8List key) => keyToHex(key);

  /// Comprueba si el tamaño de la clave es válido para Meshtastic.
  static bool isValidKeyLength(Uint8List key) =>
      allowedKeyLengths.contains(key.length);
}
*/
