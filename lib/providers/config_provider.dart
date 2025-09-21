import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/node_config.dart';
import '../services/bluetooth_service.dart';
import '../services/tcp_service.dart';
import '../services/usb_service.dart';

enum ActiveInterface { none, bluetooth, usb, tcp }

class ConfigProvider extends ChangeNotifier {
  ConfigProvider({
    BluetoothService? bluetoothService,
    UsbService? usbService,
    TcpHttpService? tcpService,
  })  : _bluetoothService = bluetoothService ?? BluetoothService(),
        _usbService = usbService ?? UsbService(),
        _tcpService = tcpService ?? TcpHttpService() {
    _keyText = NodeConfig.keyToDisplay(cfg.key);
    _keyError = cfg.keyError;
  }

  final BluetoothService _bluetoothService;
  final UsbService _usbService;
  final TcpHttpService _tcpService;

  NodeConfig cfg = NodeConfig();
  bool busy = false;
  String status = 'Desconectado';

  ActiveInterface _activeInterface = ActiveInterface.none;
  ActiveInterface get activeInterface => _activeInterface;
  bool get isConnected => _activeInterface != ActiveInterface.none;

  late String _keyText;
  String? _keyError;

  // ✅ Getters para la UI
  String get keyDisplay => _keyText;
  String? get keyError {
    final parsed = NodeConfig.parseKeyText(_keyText);
    if (parsed == null) {
      return "Clave inválida";
    }
    return NodeConfig.isValidKeyLength(parsed) ? null : "Clave inválida";
  }
  String get serialModeDisplay => cfg.serialModeAsString;
  String get baudDisplay => cfg.baudAsString;
  String get regionDisplay => cfg.frequencyRegionAsString;


  // ✅ Métodos de conexión
  Future<void> connectBle() async {
    if (busy) return;

    busy = true;
    status = "Conectando por Bluetooth...";
    notifyListeners();

    await _disconnectActive();
    const interface = ActiveInterface.bluetooth;

    try {
      final connected = await _bluetoothService.connectAndInit();
      if (!connected) {
        status = 'No se pudo conectar por Bluetooth';
        await _disconnectInterface(interface);
        return;
      }

      _activeInterface = interface;
      status = 'Conectado por Bluetooth. Leyendo configuración...';
      notifyListeners();

      final newCfg = await _readConfigFor(interface);
      _applyConfig(newCfg);
      status = 'Conectado por Bluetooth';
    } catch (error) {
      status = 'Error de Bluetooth: ${_errorDescription(error)}';
      await _disconnectInterface(interface);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> connectUsb() async {
    if (busy) return;

    busy = true;
    status = "Conectando por USB...";
    notifyListeners();
    await _disconnectActive();
    const interface = ActiveInterface.usb;

    try {
      final connected = await _usbService.connect();
      if (!connected) {
        status =
            _usbService.lastErrorMessage ?? 'No se pudo conectar por USB';
        await _disconnectInterface(interface);
        return;
      }

      _activeInterface = interface;
      status = 'Conectado por USB. Leyendo configuración...';
      notifyListeners();

      final newCfg = await _readConfigFor(interface);
      _applyConfig(newCfg);
      status = 'Conectado por USB';
    } catch (error) {
      status = 'Error de USB: ${_errorDescription(error)}';
      await _disconnectInterface(interface);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> connectTcp(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      status = 'Debes ingresar una URL válida';
      notifyListeners();
      return;
    }
    if (busy) return;

    busy = true;
    status = "Conectando a $trimmed ...";
    notifyListeners();
    await _disconnectActive();
    const interface = ActiveInterface.tcp;

    try {
      _tcpService.updateBaseUrl(trimmed);
      _activeInterface = interface;

      status = 'Conectado a $trimmed. Leyendo configuración...';
      notifyListeners();

      final newCfg = await _readConfigFor(interface);
      _applyConfig(newCfg);
      status = 'Conectado a $trimmed';
    } catch (error) {
      status = 'Error TCP/HTTP: ${_errorDescription(error)}';
      await _disconnectInterface(interface);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---- Métodos de configuración ----
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
    if (parsed == null) {
      _keyError = 'Formato de clave inválido';
    } else if (!NodeConfig.isValidKeyLength(parsed)) {
      _keyError = 'Clave inválida (usa 0, 16 o 32 bytes)';
    } else {
      cfg.key = Uint8List.fromList(parsed);
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

  Future<void> readConfig() async {
    final interface = _activeInterface;
    if (interface == ActiveInterface.none) {
      status = 'No hay una conexión activa';
      notifyListeners();
      return;
    }
    if (busy) return;
    busy = true;
    status = "Leyendo configuración...";
    notifyListeners();
    try {
      final newCfg = await _readConfigFor(interface);
      _applyConfig(newCfg);
      status = 'Configuración leída (${_interfaceLabel(interface)})';
    } catch (error) {
      status =
      'Error al leer configuración: ${_errorDescription(error)}';
      await _disconnectInterface(interface);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> writeConfig() async {
    final interface = _activeInterface;
    if (interface == ActiveInterface.none) {
      status = 'No hay una conexión activa';
      notifyListeners();
      return;
    }
    if (_keyError != null) {
      status = _keyError ?? 'Clave inválida';
      notifyListeners();
      return;
    }
    if (busy) return;

    busy = true;
    status = "Enviando configuración...";
    notifyListeners();
    try {
      switch (interface) {
        case ActiveInterface.bluetooth:
          await _bluetoothService.writeConfig(cfg);
          break;
        case ActiveInterface.usb:
          await _usbService.writeConfig(cfg);
          break;
        case ActiveInterface.tcp:
          await _tcpService.writeConfig(cfg);
          break;
        case ActiveInterface.none:
          break;
      }
      status = 'Configuración enviada (${_interfaceLabel(interface)})';
    } catch (error) {
      status =
      'Error al enviar configuración: ${_errorDescription(error)}';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<NodeConfig> _readConfigFor(ActiveInterface interface) async {
    NodeConfig? newCfg;
    switch (interface) {
      case ActiveInterface.bluetooth:
        newCfg = await _bluetoothService.readConfig();
        break;
      case ActiveInterface.usb:
        newCfg = await _usbService.readConfig();
        break;
      case ActiveInterface.tcp:
        newCfg = await _tcpService.readConfig();
        break;
      case ActiveInterface.none:
        break;
    }

    if (newCfg == null) {
      throw StateError('No se pudo obtener la configuración del dispositivo');
    }
    return newCfg;
  }

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

  Future<void> _disconnectActive() {
    return _disconnectInterface(_activeInterface);
  }

  Future<void> _disconnectInterface(ActiveInterface interface) async {
    switch (interface) {
      case ActiveInterface.bluetooth:
        await _bluetoothService.disconnect();
        break;
      case ActiveInterface.usb:
        await _usbService.disconnect();
        break;
      case ActiveInterface.tcp:
        _tcpService.clearBaseUrl();
        break;
      case ActiveInterface.none:
        return;
    }
    if (_activeInterface == interface) {
      _activeInterface = ActiveInterface.none;
    }
  }

  String _interfaceLabel(ActiveInterface interface) {
    switch (interface) {
      case ActiveInterface.bluetooth:
        return 'Bluetooth';
      case ActiveInterface.usb:
        return 'USB';
      case ActiveInterface.tcp:
        return 'TCP/HTTP';
      case ActiveInterface.none:
        return 'Sin conexión';
    }
  }

  String _errorDescription(Object error) {
    if (error is TimeoutException) {
      return 'Tiempo de espera agotado';
    }
    final message = error.toString();
    return message
        .replaceFirst(RegExp(r'^Exception: '), '')
        .replaceFirst(RegExp(r'^StateError: '), '')
        .trim();
  }
}
