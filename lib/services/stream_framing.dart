import 'dart:typed_data';

/// Framing para API streaming (USB serie / TCP):
/// Prefijo 0x94, 0xC3, luego longitud (LSB, MSB), seguido del payload protobuf.
class StreamFraming {
  static Uint8List frame(Uint8List proto) {
    final len = proto.length;
    final header = Uint8List.fromList([0x94, 0xC3, len & 0xFF, (len >> 8) & 0xFF]);
    return Uint8List.fromList([...header, ...proto]);
  }
}

/// Acumulador que mantiene los fragmentos pendientes entre llamadas y
/// devuelve todos los payloads protobuf completos que se detecten al añadir
/// cada chunk recibido.
class FrameAccumulator {
  final List<int> _buffer = <int>[];

  /// Añade [chunk] al buffer y produce todos los payloads protobuf completos
  /// encontrados. Los fragmentos incompletos permanecen en el buffer para ser
  /// completados con llamadas sucesivas.
  Iterable<Uint8List> addChunk(Uint8List chunk) sync* {
    if (chunk.isEmpty) return;

    _buffer.addAll(chunk);

    while (true) {
      final headerIndex = _findHeader();

      if (headerIndex == -1) {
        _discardGarbage();
        break;
      }
      if (headerIndex > 0) {
        _buffer.removeRange(0, headerIndex);
      }

      if (_buffer.length < 4) break;

      final len = _buffer[2] | (_buffer[3] << 8);
      final frameLength = 4 + len;

      if (_buffer.length < frameLength) break;

      final payload = Uint8List.fromList(_buffer.sublist(4, frameLength));
      _buffer.removeRange(0, frameLength);
      yield payload;
    }
  }

  /// Limpia el estado interno descartando cualquier fragmento pendiente.
  void clear() => _buffer.clear();

  int _findHeader() {
    for (var i = 0; i + 1 < _buffer.length; i++) {
      if (_buffer[i] == 0x94 && _buffer[i + 1] == 0xC3) {
        return i;
      }
    }
    return -1;
  }

  void _discardGarbage() {
    if (_buffer.isEmpty) return;
    final keep = _buffer.last == 0x94 ? 1 : 0;
    if (keep < _buffer.length) {
      _buffer.removeRange(0, _buffer.length - keep);
    }
  }
}
