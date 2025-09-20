import 'dart:typed_data';

/// Framing para API streaming (USB serie / TCP):
/// Prefijo 0x94, 0xC3, luego longitud (LSB, MSB), seguido del payload protobuf.
class StreamFraming {
  static Uint8List frame(Uint8List proto) {
    final len = proto.length;
    final header = Uint8List.fromList([0x94, 0xC3, len & 0xFF, (len >> 8) & 0xFF]);
    return Uint8List.fromList([...header, ...proto]);
  }

  /// Devuelve el primer payload protobuf encontrado en el buffer.
  static Uint8List? deframeOnce(Uint8List data) {
    for (int i = 0; i + 3 < data.length; i++) {
      if (data[i] == 0x94 && data[i + 1] == 0xC3) {
        final lsb = data[i + 2], msb = data[i + 3];
        final len = (msb << 8) | lsb;
        final start = i + 4, end = start + len;
        if (end <= data.length) return data.sublist(start, end);
      }
    }
    return null;
  }
}
