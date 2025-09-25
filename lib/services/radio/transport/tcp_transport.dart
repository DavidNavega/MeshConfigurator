import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'radio_transport.dart';
import '../../stream_framing.dart';

/// Transporte TCP sin estado compartido con HTTP: abre un socket simple y
/// expone frames `FromRadio` completos (payload protobuf sin cabecera) a través
/// de [inbound]. Los bytes enviados se enmarcan con el protocolo de streaming
/// `StreamFraming` dentro del propio transporte.
class TcpTransport implements RadioTransport {
  TcpTransport(this.host, {this.port = 4403, this.connectTimeout = const Duration(seconds: 5)});

  static final Logger _log = Logger('TcpTransport');

  final String host;
  final int port;
  final Duration connectTimeout;

  final _inboundCtrl = StreamController<Uint8List>.broadcast();
  final FrameAccumulator _accumulator = FrameAccumulator();

  Socket? _socket;
  StreamSubscription<Uint8List>? _sub;

  @override
  Stream<Uint8List> get inbound => _inboundCtrl.stream;

  @override
  Future<bool> connect() async {
    await disconnect();
    try {
      final socket = await Socket.connect(host, port, timeout: connectTimeout);
      _socket = socket;
      _accumulator.clear();
      _sub = socket.listen(
        (chunk) {
          for (final payload in _accumulator.addChunk(chunk)) {
            if (!_inboundCtrl.isClosed && payload.isNotEmpty) {
              _inboundCtrl.add(Uint8List.fromList(payload));
            }
          }
        },
        onError: (error, stackTrace) {
          if (!_inboundCtrl.isClosed) {
            _inboundCtrl.addError(error, stackTrace);
          }
        },
        onDone: () {
          if (!_inboundCtrl.isClosed) {
            _inboundCtrl.addError(StateError('Socket TCP cerrado'));
          }
        },
        cancelOnError: true,
      );
      return true;
    } catch (e, st) {
      _log.warning('Error conectando socket TCP $host:$port', e, st);
      await disconnect();
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _accumulator.clear();
    await _sub?.cancel();
    _sub = null;
    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (e, st) {
        _log.fine('Error cerrando socket TCP', e, st);
      }
    }
    _socket = null;
  }

  @override
  Future<void> send(Uint8List data) async {
    final socket = _socket;
    if (socket == null) {
      throw StateError('TCP no conectado');
    }
    final framed = StreamFraming.frame(data);
    socket.add(framed);
    await socket.flush();
  }
}
