import 'dart:async';

import 'package:logging/logging.dart';

import '../radio_coordinator.dart';
import 'bluetooth_transport.dart';
import 'radio_transport.dart';
import 'tcp_transport.dart';
import 'usb_transport.dart';

enum RadioInterfaceType { none, bluetooth, usb, tcp }

// Compatibilidad temporal con código previo que referenciaba ActiveInterface.
@Deprecated('Usa RadioInterfaceType en su lugar')
typedef ActiveInterface = RadioInterfaceType;

enum RadioConnectionState { idle, connecting, connected, reconnecting, disconnected }

class RadioTransportStatus {
  const RadioTransportStatus(this.interface, this.state, this.error, this.willRetry);

  final RadioInterfaceType interface;
  final RadioConnectionState state;
  final Object? error;
  final bool willRetry;
}

/// Capa coordinadora encargada de crear el transporte físico apropiado
/// (Bluetooth/USB/TCP), mantener una única instancia activa y reintentar la
/// conexión con retardo cuando se pierde el enlace.
class RadioTransportManager {
  RadioTransportManager({Duration reconnectDelay = const Duration(seconds: 3)})
      : _reconnectDelay = reconnectDelay;

  static final Logger _log = Logger('RadioTransportManager');

  final Duration _reconnectDelay;
  final _statusCtrl = StreamController<RadioTransportStatus>.broadcast();

  RadioInterfaceType _active = RadioInterfaceType.none;
  RadioTransport? _transport;
  RadioCoordinator? _coordinator;
  Timer? _retryTimer;
  Future<bool>? _ongoingConnect;
  bool _keepTrying = false;
  bool _disposed = false;

  Stream<RadioTransportStatus> get statusStream => _statusCtrl.stream;
  RadioCoordinator? get coordinator => _coordinator;
  RadioInterfaceType get activeInterface => _active;
  Duration get reconnectDelay => _reconnectDelay;

  Future<bool> select(RadioInterfaceType interface, {String? host, int? port}) async {
    if (interface == RadioInterfaceType.none) {
      await disconnect();
      return false;
    }

    final transport = _createTransport(interface, host: host, port: port);

    await disconnect();

    _active = interface;
    _transport = transport;
    _coordinator = RadioCoordinator(
      _transport!,
      onTransportClosed: _handleTransportClosed,
    );
    _keepTrying = true;

    return await _attemptConnection();
  }

  Future<void> disconnect() async {
    _keepTrying = false;
    _retryTimer?.cancel();
    _retryTimer = null;

    await _ensureConnectCompleted();

    final coord = _coordinator;
    _coordinator = null;
    _transport = null;

    if (coord != null) {
      try {
        await coord.disconnect();
      } catch (e, st) {
        _log.fine('Error desconectando coordinador', e, st);
      }
    }

    if (!_disposed && _active != RadioInterfaceType.none) {
      _notify(RadioTransportStatus(_active, RadioConnectionState.disconnected, null, false));
    }

    _active = RadioInterfaceType.none;
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    final coord = _coordinator;
    _coordinator = null;
    _transport = null;
    if (coord != null) {
      coord.disconnect().catchError((e, st) {
        _log.fine('Error al cerrar coordinador en dispose', e, st);
      });
    }
    _statusCtrl.close().catchError((e, st) {
      _log.fine('Error cerrando stream de estado', e, st);
    });
  }

  Future<bool> _attemptConnection({bool notify = true}) {
    if (_coordinator == null || !_keepTrying) {
      return Future.value(false);
    }

    final existing = _ongoingConnect;
    if (existing != null) {
      return existing;
    }

    final future = _doAttemptConnection(notify: notify);
    _ongoingConnect = future;
    future.whenComplete(() {
      if (identical(_ongoingConnect, future)) {
        _ongoingConnect = null;
      }
    });
    return future;
  }

  Future<bool> _doAttemptConnection({required bool notify}) async {
    if (_coordinator == null || !_keepTrying) {
      return false;
    }

    if (notify) {
      _notify(RadioTransportStatus(
        _active,
        RadioConnectionState.connecting,
        null,
        _keepTrying,
      ));
    }

    var success = false;
    Object? error;
    try {
      success = await _coordinator!.connect();
    } catch (e, st) {
      _log.warning('Fallo conectando interfaz ${_interfaceLabel(_active)}', e, st);
      error = e;
    }

    if (success) {
      _notify(RadioTransportStatus(_active, RadioConnectionState.connected, null, _keepTrying));
      return true;
    }

    _notify(RadioTransportStatus(
      _active,
      RadioConnectionState.disconnected,
      error,
      _keepTrying,
    ));

    if (_keepTrying) {
      _scheduleReconnect();
    }

    return false;
  }

  void _handleTransportClosed(Object? error) {
    if (_disposed) return;
    final willRetry = _keepTrying;
    _notify(RadioTransportStatus(_active, RadioConnectionState.disconnected, error, willRetry));
    if (willRetry) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_keepTrying) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(_reconnectDelay, () async {
      _retryTimer = null;
      if (_disposed || !_keepTrying) return;

      _notify(RadioTransportStatus(
        _active,
        RadioConnectionState.reconnecting,
        null,
        true,
      ));

      await _ensureConnectCompleted();
      try {
        await _coordinator?.disconnect();
      } catch (e, st) {
        _log.fine('Error cerrando coordinador antes de reintentar', e, st);
      }

      await _attemptConnection();
    });
  }

  Future<void> _ensureConnectCompleted() async {
    final future = _ongoingConnect;
    if (future != null) {
      try {
        await future;
      } catch (_) {}
    }
  }

  RadioTransport _createTransport(RadioInterfaceType interface, {String? host, int? port}) {
    switch (interface) {
      case RadioInterfaceType.bluetooth:
        return BluetoothTransport();
      case RadioInterfaceType.usb:
        return UsbTransport();
      case RadioInterfaceType.tcp:
        final resolvedHost = host;
        if (resolvedHost == null || resolvedHost.isEmpty) {
          throw ArgumentError('Host TCP inválido');
        }
        final resolvedPort = port ?? 4403;
        return TcpTransport(resolvedHost, port: resolvedPort);
      case RadioInterfaceType.none:
        throw StateError('Interfaz none no crea transporte');
    }
  }

  void _notify(RadioTransportStatus status) {
    if (_disposed) return;
    if (!_statusCtrl.isClosed) {
      _statusCtrl.add(status);
    }
  }

  String _interfaceLabel(RadioInterfaceType type) {
    switch (type) {
      case RadioInterfaceType.bluetooth:
        return 'bluetooth';
      case RadioInterfaceType.usb:
        return 'usb';
      case RadioInterfaceType.tcp:
        return 'tcp';
      case RadioInterfaceType.none:
        return 'none';
    }
  }
}
