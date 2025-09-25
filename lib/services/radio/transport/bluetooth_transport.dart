import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:logging/logging.dart';

import '../../ble_uuids.dart';
import 'radio_transport.dart';

/// BLE: notifica `FromRadio` ya completo por la característica fromRadio.
/// El envío se hace escribiendo en toRadio. No hay framing adicional en BLE.
class BluetoothTransport implements RadioTransport {
  static final Logger _log = Logger('BluetoothTransport');

  fbp.BluetoothDevice? _dev;
  fbp.BluetoothCharacteristic? _toRadio;
  StreamSubscription<Uint8List>? _fromRadioSub;

  final _inboundCtrl = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get inbound => _inboundCtrl.stream;

  @override
  Future<bool> connect() async {
    // Escaneo breve buscando el servicio Meshtastic
    if (fbp.FlutterBluePlus.isScanningNow) {
      await fbp.FlutterBluePlus.stopScan();
    }
    await fbp.FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
      withServices: [MeshUuids.service],
      androidScanMode: fbp.AndroidScanMode.lowLatency,
    );
    await Future.delayed(const Duration(seconds: 3));
    await fbp.FlutterBluePlus.stopScan();

    // Toma cualquier dispositivo conectado o visto recientemente
    final known = await fbp.FlutterBluePlus.connectedDevices;
    fbp.BluetoothDevice? dev;
    if (known.isNotEmpty) {
      dev = known.first;
    } else {
      final system = await fbp.FlutterBluePlus.systemDevices;
      for (final candidate in system) {
        if (candidate is fbp.BluetoothDevice) {
          dev = candidate;
          break;
        }
      }
    }

    if (dev == null) return false;
    _dev = dev;

    try {
      await _dev!.connect(autoConnect: false);
    } catch (_) {
      // si ya está conectado, continúa
    }

    // Descubre características Meshtastic y engancha notificaciones
    final services = await _dev!.discoverServices();
    for (final s in services) {
      if (s.uuid == MeshUuids.service) {
        for (final c in s.characteristics) {
          if (c.uuid == MeshUuids.toRadio) _toRadio = c;
          if (c.uuid == MeshUuids.fromRadio && c.properties.notify) {
            await c.setNotifyValue(true);
            _fromRadioSub = c.onValueReceived.listen(
                  (data) {
                if (!_inboundCtrl.isClosed && data.isNotEmpty) {
                  _inboundCtrl.add(Uint8List.fromList(data));
                }
              },
              onError: _inboundCtrl.addError,
              onDone: () => disconnect(),
              cancelOnError: true,
            );
          }
        }
      }
    }

    final ok = _toRadio != null && _fromRadioSub != null;
    if (!ok) await disconnect();
    return ok;
  }

  @override
  Future<void> disconnect() async {
    await _fromRadioSub?.cancel();
    _fromRadioSub = null;
    _toRadio = null;

    try {
      await _dev?.disconnect();
    } catch (e) {
      _log.info('BLE disconnect(): $e');
    }
    _dev = null;
  }

  @override
  Future<void> send(Uint8List data) async {
    // En BLE los bytes a enviar son un ToRadio (SIN framing adicional).
    final c = _toRadio;
    if (c == null) throw StateError('BLE no conectado');
    // preferimos writeWithoutResponse si está soportado
    final without = c.properties.writeWithoutResponse;
    await c.write(data, withoutResponse: without);
  }
}

