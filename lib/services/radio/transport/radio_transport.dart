import 'dart:async';
import 'dart:typed_data';

/// Contrato común para todos los transportes físicos (BLE, USB, TCP…).
/// Deben:
/// - exponer [inbound] con frames completos de `mesh.FromRadio` (bytes ya “delimitados”)
/// - implementar connect/disconnect
/// - implementar send(Uint8List framedToRadio) con bytes ya enmarcados (StreamFraming.frame)

abstract class RadioTransport {
  Stream<List<int>> get inbound;
  Future<bool> connect();
  Future<void> disconnect();
  Future<void> send(List<int> data);
}
