import 'package:flutter/foundation.dart';
import '../models/node_config.dart';
import '../services/bluetooth_service.dart';
import '../services/tcp_service.dart';
import '../services/usb_service.dart';

enum ConnKind { bluetooth, tcpHttp, usb }

class ConfigProvider with ChangeNotifier {
  final bluetooth = BluetoothService();
  TcpHttpService? tcp;
  final usb = UsbService();

  ConnKind? _kind;
  NodeConfig _cfg = NodeConfig();
  bool _busy = false;
  String _status = 'Desconectado';
  String? _keyError;

  NodeConfig get cfg => _cfg;
  bool get busy => _busy;
  String get status => _status;
  ConnKind? get kind => _kind;
  String? get keyError => _keyError;

  String get keyDisplay => NodeConfig.keyToDisplay(_cfg.key);

  void _setBusy(bool v) { _busy = v; notifyListeners(); }
  void _setStatus(String s) { _status = s; notifyListeners(); }
  void _setCfg(NodeConfig c) { _cfg = c; _keyError = null; notifyListeners(); }

  Future<void> connectBle() async {
    _setBusy(true);
    _kind = ConnKind.bluetooth;
    _setStatus('Conectando BLE...');
    try {
      final ok = await bluetooth.connectAndInit();
      if (!ok) {
        _setStatus('Error BLE');
        return;
      }
      _setStatus('BLE conectado, leyendo configuración...');
      await readConfig();
    } catch (e) {
      _setStatus('Error BLE: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> connectTcp(String baseUrl) async {
    _setBusy(true);
    _kind = ConnKind.tcpHttp;
    _setStatus('Conectando TCP/HTTP...');
    try {
      tcp = TcpHttpService(baseUrl);
      _setStatus('TCP listo, leyendo configuración...');
      await readConfig();
    } catch (e) {
      _setStatus('Error TCP/HTTP: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> connectUsb() async {
    _setBusy(true);
    _kind = ConnKind.usb;
    _setStatus('Conectando USB...');
    try {
      final ok = await usb.connect();
      if (!ok) {
        _setStatus('Error USB');
        return;
      }
      _setStatus('USB conectado, leyendo configuración...');
      await readConfig();
    } catch (e) {
      _setStatus('Error USB: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> readConfig() async {
    if (_kind == null) {
      _setStatus('Conecta primero');
      return;
    }
    _setBusy(true);
    _setStatus('Leyendo configuración...');
    try {
      NodeConfig? c;
      switch (_kind) {
        case ConnKind.bluetooth:
          c = await bluetooth.readConfig();
          break;
        case ConnKind.tcpHttp:
          c = await tcp?.readConfig();
          break;
        case ConnKind.usb:
          c = await usb.readConfig();
          break;
        default:
          break;
      }
      if (c != null) {
        _setCfg(c);
        _setStatus('Configuración recibida');
      } else {
        _setStatus('No se pudo obtener la configuración');
      }
    } catch (e) {
      _setStatus('Error al leer configuración: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> writeConfig() async {
    _setBusy(true);
    try {
      switch (_kind) {
        case ConnKind.bluetooth:
          await bluetooth.writeConfig(_cfg);
          break;
        case ConnKind.tcpHttp:
          await tcp?.writeConfig(_cfg);
          break;
        case ConnKind.usb:
          await usb.writeConfig(_cfg);
          break;
        default:
          _setStatus('Conecta primero');
      }
    } finally {
      _setBusy(false);
    }
  }

  // Helpers de UI
  void setNames({String? shortName, String? longName}) {
    _cfg = NodeConfig.fromJson(_cfg.toJson());
    if (shortName != null) _cfg.shortName = shortName;
    if (longName != null) _cfg.longName = longName;
    notifyListeners();
  }
  void setChannelIndex(int idx) { _cfg = NodeConfig.fromJson(_cfg.toJson()); _cfg.channelIndex = idx; notifyListeners(); }
  void setKey(String k) {
    final parsed = NodeConfig.parseKeyText(k);
    if (parsed == null) {
      _keyError = 'Formato no válido. Usa hex o Base64.';
      notifyListeners();
      return;
    }
    if (!NodeConfig.isValidKeyLength(parsed)) {
      _keyError = 'La clave debe tener 0, 16 o 32 bytes.';
      notifyListeners();
      return;
    }
    _cfg = NodeConfig.fromJson(_cfg.toJson());
    _cfg.key = parsed;
    _keyError = null;
    notifyListeners();
  }
  void setSerialMode(String m) { _cfg = NodeConfig.fromJson(_cfg.toJson()); _cfg.serialOutputMode = m; notifyListeners(); }
  void setBaud(int b) { _cfg = NodeConfig.fromJson(_cfg.toJson()); _cfg.baudRate = b; notifyListeners(); }
  void setFrequencyRegion(String r) { _cfg = NodeConfig.fromJson(_cfg.toJson()); _cfg.frequencyRegion = r; notifyListeners(); }
}
