import 'dart:convert';
import 'dart:typed_data';

// Modelo de configuración de nodo Meshtastic que manipularemos desde la app.
class NodeConfig {
  static const allowedKeyLengths = [0, 16, 32];
  String shortName;
  String longName;
  int channelIndex;
  Uint8List key;             // PSK (0, 16 o 32 bytes)
  String serialOutputMode;   // "WPL" (CALTOPO) o "TLL" (NMEA)
  int baudRate;              // 4800..115200
  String frequencyRegion;    // "433", "868", "915"


  NodeConfig({
    this.shortName = '',
    this.longName = '',
    this.channelIndex = 0,
    Uint8List? key,
    this.serialOutputMode = 'TLL',
    this.baudRate = 9600,
    this.frequencyRegion = '868',
  }) : key = key ?? Uint8List(0);

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
