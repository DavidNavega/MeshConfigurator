import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/node_config.dart';
import '../services/radio/transport/radio_transport_manager.dart';

class ConfigProvider extends ChangeNotifier {
  ConfigProvider({
    required this.transportManager,
    String? fixedTcpUrl,
  }) : _fixedTcpUrl = fixedTcpUrl {
    _keyText = NodeConfig.keyToDisplay(cfg.key);
    _keyError = cfg.keyError;
    _statusSub = transportManager.statusStream.listen(_handleTransportStatus);
  }

  final RadioTransportManager transportManager;
  final String? _fixedTcpUrl;

  StreamSubscription<RadioTransportStatus>? _statusSub;

  NodeConfig cfg = NodeConfig();
  bool busy = false;
  String status = 'Desconectado';

  RadioInterfaceType _active = RadioInterfaceType.none;
  RadioInterfaceType get activeInterface => _active;

  bool _pendingInitialSync = false;
  bool _syncingInitial = false;
  bool _connectingNewInterface = false;
  bool _userDisconnect = false;

  late String _keyText;
  String? _keyError;
  String get keyDisplay => _keyText;
  String? get keyError => _keyError;

  String get serialModeDisplay => cfg.serialModeAsString;
  String get baudDisplay => cfg.baudAsString;
  String get regionDisplay => cfg.frequencyRegionAsString;

  bool get hasFixedTcpEndpoint => _fixedTcpUrl != null;
  @Deprecated('Usa hasFixedTcpEndpoint')
  bool get hasTcpFixed => hasFixedTcpEndpoint;
  String? get fixedTcpUrl => _fixedTcpUrl;

  Future<void> connectBle() => _connectInterface(RadioInterfaceType.bluetooth);
  Future<void> connectUsb() => _connectInterface(RadioInterfaceType.usb);

  Future<void> connectTcp(String baseUrl) async {
    if (busy) return;
    final _TcpEndpoint endpoint;
    try {
      endpoint = _parseTcpEndpoint(baseUrl);
    } catch (e) {
      status = 'Dirección TCP inválida: $e';
      notifyListeners();
      return;
    }
    await _connectInterface(
      RadioInterfaceType.tcp,
      host: endpoint.host,
      port: endpoint.port,
    );
  }

  Future<void> disconnect() async {
    if (_active == RadioInterfaceType.none &&
        transportManager.activeInterface == RadioInterfaceType.none) {
      status = 'Desconectado';
      notifyListeners();
      return;
    }
    _userDisconnect = true;
    busy = true;
    notifyListeners();
    await transportManager.disconnect();
    busy = false;
    _pendingInitialSync = false;
    _active = RadioInterfaceType.none;
    status = 'Desconectado';
    notifyListeners();
    _userDisconnect = false;
  }

  Future<void> readConfig() async {
    final coord = transportManager.coordinator;
    if (_active == RadioInterfaceType.none || busy || coord == null) return;

    busy = true;
    status = 'Leyendo configuración...';
    notifyListeners();
    try {
      final cfgNew = await coord.readConfig();
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
    final coord = transportManager.coordinator;
    if (_active == RadioInterfaceType.none || busy || coord == null) return;

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
      await coord.writeConfig(cfg);
      status = 'Configuración enviada';
    } catch (e) {
      status = 'Error enviando configuración: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

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

  @override
  void dispose() {
    _statusSub?.cancel();
    _statusSub = null;
    transportManager.dispose();
    super.dispose();
  }

  Future<void> _connectInterface(RadioInterfaceType target,
      {String? host, int? port}) async {
    if (busy) return;

    _connectingNewInterface = true;
    busy = true;
    _pendingInitialSync = true;
    status = 'Conectando ${_interfaceLabel(target)}...';
    notifyListeners();

    _active = target;

    try {
      final ok = await transportManager.select(target, host: host, port: port);
      if (!ok) {
        status =
            'No se pudo conectar ${_interfaceLabel(target)}. Reintentando en ${transportManager.reconnectDelay.inSeconds}s...';
        return;
      }
      await _performInitialSync();
    } on ArgumentError catch (e) {
      status = 'Dirección inválida: ${e.message}';
      _pendingInitialSync = false;
      _active = RadioInterfaceType.none;
      await transportManager.disconnect();
    } catch (e) {
      status = 'Error conectando ${_interfaceLabel(target)}: $e';
      _pendingInitialSync = false;
      _active = RadioInterfaceType.none;
      await transportManager.disconnect();
    } finally {
      _connectingNewInterface = false;
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _performInitialSync() async {
    if (!_pendingInitialSync || _syncingInitial) return;
    final coord = transportManager.coordinator;
    if (coord == null) {
      status = 'Coordinador no disponible';
      _pendingInitialSync = false;
      notifyListeners();
      return;
    }

    _syncingInitial = true;
    try {
      status = 'Conectado ${_interfaceLabel(_active)}. Leyendo configuración...';
      notifyListeners();
      final newCfg = await coord.readConfig();
      _applyConfig(newCfg);
      status = 'Conectado ${_interfaceLabel(_active)}';
      notifyListeners();
    } catch (e) {
      status = 'Error leyendo configuración: $e';
      notifyListeners();
    } finally {
      _pendingInitialSync = false;
      _syncingInitial = false;
    }
  }

  void _handleTransportStatus(RadioTransportStatus update) async {
    if (update.interface != _active) {
      if (_connectingNewInterface && update.state == RadioConnectionState.disconnected) {
        return; // evento del transporte anterior mientras cambiamos de interfaz
      }
      if (update.interface != RadioInterfaceType.none) {
        return;
      }
    }

    switch (update.state) {
      case RadioConnectionState.connecting:
        if (!busy) {
          status = 'Conectando ${_interfaceLabel(update.interface)}...';
          notifyListeners();
        }
        break;
      case RadioConnectionState.reconnecting:
        status = 'Reconectando ${_interfaceLabel(update.interface)}...';
        _pendingInitialSync = true;
        notifyListeners();
        break;
      case RadioConnectionState.connected:
        status = 'Conectado ${_interfaceLabel(update.interface)}';
        notifyListeners();
        if (_pendingInitialSync) {
          final prevBusy = busy;
          busy = true;
          notifyListeners();
          await _performInitialSync();
          busy = prevBusy;
          notifyListeners();
        }
        break;
      case RadioConnectionState.disconnected:
        if (update.willRetry) {
          final errText = update.error != null ? ': ${update.error}' : '';
          status =
              'Conexión perdida (${_interfaceLabel(update.interface)})$errText. Reintentando...';
          _pendingInitialSync = true;
        } else if (_userDisconnect || _connectingNewInterface) {
          // evento esperado, no modificar estado
        } else {
          status = 'Desconectado';
          _pendingInitialSync = false;
          _active = RadioInterfaceType.none;
        }
        notifyListeners();
        break;
      case RadioConnectionState.idle:
        break;
    }
  }

  _TcpEndpoint _parseTcpEndpoint(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('vacía');
    }

    Uri? uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host;
      final port = uri.hasPort
          ? uri.port
          : (uri.scheme == 'https'
              ? 443
              : (uri.scheme == 'http' ? 80 : 4403));
      return _TcpEndpoint(host, port);
    }

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      final host = parts.first;
      final port = int.tryParse(parts.last) ?? 4403;
      return _TcpEndpoint(host, port);
    }

    return _TcpEndpoint(trimmed, 4403);
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

  String _interfaceLabel(RadioInterfaceType type) {
    switch (type) {
      case RadioInterfaceType.bluetooth:
        return 'Bluetooth';
      case RadioInterfaceType.usb:
        return 'USB';
      case RadioInterfaceType.tcp:
        return 'TCP';
      case RadioInterfaceType.none:
        return 'ninguna';
    }
  }
}

class _TcpEndpoint {
  const _TcpEndpoint(this.host, this.port);

  final String host;
  final int port;
}
