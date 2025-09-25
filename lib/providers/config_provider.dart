import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/node_config.dart';
import '../services/radio/radio_coordinator.dart';
import '../services/radio/transport/tcp_transport.dart';

enum ActiveInterface { none, bluetooth, usb, tcp }

class ConfigProvider extends ChangeNotifier {
  final RadioCoordinator bleCoordinator;
  final RadioCoordinator usbCoordinator;
  RadioCoordinator? tcpCoordinator;

  ConfigProvider({
    required this.bleCoordinator,
    required this.usbCoordinator,
  }) {
    _keyText = NodeConfig.keyToDisplay(cfg.key);
    _keyError = cfg.keyError;
  }

  ActiveInterface _active = ActiveInterface.none;
  ActiveInterface get activeInterface => _active;

  NodeConfig cfg = NodeConfig();
  bool busy = false;
  String status = 'Desconectado';

  late String _keyText;
  String? _keyError;
  String get keyDisplay => _keyText;
  String? get keyError => _keyError;

  String get serialModeDisplay => cfg.serialModeAsString;
  String get baudDisplay => cfg.baudAsString;
  String get regionDisplay => cfg.frequencyRegionAsString;

  // ---------------- Conexiones ----------------

  Future<void> connectBle() => _connect(ActiveInterface.bluetooth);
  Future<void> connectUsb() => _connect(ActiveInterface.usb);

  Future<void> connectTcp(String baseUrl) async {
    if (busy) return;
    busy = true;
    status = 'Conectando TCP...';
    notifyListeners();

    await _disconnectActive();

    try {
      // parse host:port desde la URL
      final uri = Uri.tryParse(baseUrl.trim());
      final host = uri?.host.isNotEmpty == true ? uri!.host : baseUrl.trim();
      final port = uri?.hasPort == true
          ? uri!.port
          : (uri?.scheme == 'https'
          ? 443
          : (uri?.scheme == 'http' ? 80 : 4403));

      tcpCoordinator = RadioCoordinator(TcpTransport(host, port: port));

      final ok = await tcpCoordinator!.connect();
      if (!ok) {
        status = 'No se pudo conectar TCP';
        return;
      }
      _active = ActiveInterface.tcp;
      status = 'Conectado TCP. Leyendo configuración...';
      notifyListeners();

      final newCfg = await tcpCoordinator!.readConfig();
      _applyConfig(newCfg);

      status = 'Conectado TCP';
    } catch (e) {
      status = 'Error conectando TCP: $e';
      _active = ActiveInterface.none;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async => _disconnectActive();

  Future<void> _disconnectActive() async {
    switch (_active) {
      case ActiveInterface.bluetooth:
        await bleCoordinator.disconnect();
        break;
      case ActiveInterface.usb:
        await usbCoordinator.disconnect();
        break;
      case ActiveInterface.tcp:
        await tcpCoordinator?.disconnect();
        tcpCoordinator = null;
        break;
      case ActiveInterface.none:
        break;
    }
    _active = ActiveInterface.none;
    status = 'Desconectado';
    notifyListeners();
  }

  RadioCoordinator _coordinatorFor(ActiveInterface t) {
    switch (t) {
      case ActiveInterface.bluetooth:
        return bleCoordinator;
      case ActiveInterface.usb:
        return usbCoordinator;
      case ActiveInterface.tcp:
        return tcpCoordinator!;
      case ActiveInterface.none:
        throw StateError('No hay transporte activo');
    }
  }

  // ---------------- Lectura/Escritura ----------------

  Future<void> readConfig() async {
    if (_active == ActiveInterface.none || busy) return;
    busy = true;
    status = 'Leyendo configuración...';
    notifyListeners();
    try {
      final cfgNew = await _coordinatorFor(_active).readConfig();
      _applyConfig(cfgNew);
      status = 'Configuración leída';
    } catch (e) {
      status = 'Error leyendo configuración: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> writeConfig() async {
    if (_active == ActiveInterface.none || busy) return;

    final parsed = NodeConfig.parseKeyText(_keyText);
    if (parsed == null || !NodeConfig.isValidKeyLength(parsed)) {
      _keyError = 'Clave inválida (usa 0, 1, 16 o 32 bytes)';
      notifyListeners();
      return;
    }
    cfg.key = Uint8List.fromList(parsed);
    _keyText = NodeConfig.keyToDisplay(cfg.key);
    _keyError = null;

    busy = true;
    status = 'Enviando configuración...';
    notifyListeners();
    try {
      await _coordinatorFor(_active).writeConfig(cfg);
      status = 'Configuración enviada';
    } catch (e) {
      status = 'Error enviando configuración: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------------- Setters para la UI ----------------

  void setNames(String shortName, String longName) {
    cfg.shortName = shortName;
    cfg.longName = longName;
    notifyListeners();
  }

  void setChannelIndex(int index) {
    cfg.channelIndex = index;
    notifyListeners();
  }

  void setKeyText(String text) {
    _keyText = text;
    final parsed = NodeConfig.parseKeyText(text);
    if (parsed == null || !NodeConfig.isValidKeyLength(parsed)) {
      _keyError = 'Clave inválida (usa 0, 1, 16 o 32 bytes)';
    } else {
      _keyError = null;
    }
    notifyListeners();
  }

  void setSerialMode(String mode) {
    cfg.setSerialModeFromString(mode);
    notifyListeners();
  }

  void setBaud(String baud) {
    cfg.setBaudFromString(baud);
    notifyListeners();
  }

  void setFrequencyRegion(String region) {
    cfg.setFrequencyRegionFromString(region);
    notifyListeners();
  }

  // ---------------- Helpers ----------------

  void _applyConfig(NodeConfig newCfg) {
    cfg
      ..shortName = newCfg.shortName
      ..longName = newCfg.longName
      ..channelIndex = newCfg.channelIndex
      ..key = Uint8List.fromList(newCfg.key)
      ..baudRate = newCfg.baudRate
      ..serialOutputMode = newCfg.serialOutputMode
      ..frequencyRegion = newCfg.frequencyRegion;

    _keyText = NodeConfig.keyToDisplay(cfg.key);
    _keyError = cfg.keyError;
  }
}


