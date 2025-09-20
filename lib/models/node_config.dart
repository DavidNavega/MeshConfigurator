// Modelo de configuración de nodo Meshtastic que manipularemos desde la app.
class NodeConfig {
  String shortName;
  String longName;
  int channelIndex;
  String key;               // PSK (0, 16 o 32 bytes)
  String serialOutputMode;  // "WPL" (CALTOPO) o "TLL" (NMEA)
  int baudRate;             // 4800..115200
  String frequencyRegion;   // "433", "868", "915"

  NodeConfig({
    this.shortName = '',
    this.longName = '',
    this.channelIndex = 0,
    this.key = '',
    this.serialOutputMode = 'TLL',
    this.baudRate = 9600,
    this.frequencyRegion = '868',
  });

  Map<String, dynamic> toJson() => {
        'shortName': shortName,
        'longName': longName,
        'channelIndex': channelIndex,
        'key': key,
        'serialOutputMode': serialOutputMode,
        'baudRate': baudRate,
        'frequencyRegion': frequencyRegion,
      };

  factory NodeConfig.fromJson(Map<String, dynamic> map) => NodeConfig(
        shortName: map['shortName'] ?? '',
        longName: map['longName'] ?? '',
        channelIndex: map['channelIndex'] ?? 0,
        key: map['key'] ?? '',
        serialOutputMode: map['serialOutputMode'] ?? 'TLL',
        baudRate: map['baudRate'] ?? 9600,
        frequencyRegion: map['frequencyRegion'] ?? '868',
      );
}
