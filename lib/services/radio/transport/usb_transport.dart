import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:logging/logging.dart';

import 'radio_transport.dart';
import '../../stream_framing.dart';

/// USB: el puerto entrega chunks arbitrarios; aquí usamos el FrameAccumulator
/// para extraer frames completos de `FromRadio` y publicarlos en [inbound].
/// Para enviar, este transporte se encarga de aplicar el framing
/// `StreamFraming.frame` antes de escribir en el puerto serie.
class UsbTransport implements RadioTransport {
  static final Logger _log = Logger('UsbTransport');

  UsbPort? _port;
  StreamSubscription<Uint8List>? _sub;

  final _inboundCtrl = StreamController<Uint8List>.broadcast();
  @override
  Stream<Uint8List> get inbound => _inboundCtrl.stream;

  @override
  Future<bool> connect() async {
    final devices = await UsbSerial.listDevices();
    if (devices.isEmpty) return false;

    final dev = devices.first;
    _port = await dev.create();
    if (_port == null) return false;

    final opened = await _port!.open();
    if (!opened) {
      _port = null;
      return false;
    }

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
      115200,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    final acc = FrameAccumulator();
    _sub = _port!.inputStream?.listen(
          (chunk) {
        for (final payload in acc.addChunk(chunk)) {
          if (!_inboundCtrl.isClosed && payload.isNotEmpty) {
            _inboundCtrl.add(Uint8List.fromList(payload));
          }
        }
      },
      onError: _inboundCtrl.addError,
      onDone: () => disconnect(),
      cancelOnError: true,
    );

    return true;
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _port?.close();
    } catch (e) {
      _log.info('USB close(): $e');
    }
    _port = null;
  }

  @override
  Future<void> send(Uint8List data) async {
    final p = _port;
    if (p == null) throw StateError('USB no conectado');
    final framed = StreamFraming.frame(data);
    await p.write(framed);
  }
}

