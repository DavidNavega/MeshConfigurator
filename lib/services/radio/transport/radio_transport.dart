import 'dart:async';
import 'dart:typed_data';

/// Contrato común para todos los transportes físicos (BLE, USB, TCP…).
/// Deben:
/// - exponer [inbound] con payloads `FromRadio` completos (sin cabecera de
///   framing) como `Uint8List`.
/// - implementar connect/disconnect.
/// - implementar [send] recibiendo el `ToRadio` en bruto; si el medio requiere
///   framing adicional (USB/TCP) se aplica dentro del propio transporte.
abstract class RadioTransport {
  Stream<Uint8List> get inbound;
  Future<bool> connect();
  Future<void> disconnect();
  Future<void> send(Uint8List data);
}
