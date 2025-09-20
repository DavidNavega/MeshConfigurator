import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/node_config.dart';

class ConfigProvider extends ChangeNotifier {
  NodeConfig cfg = NodeConfig();
  bool busy = false;
  String status = "Desconectado";

  // ✅ Getters para la UI
  String get keyDisplay => cfg.keyDisplay;
  String? get keyError => cfg.keyError;
  String get serialModeDisplay => cfg.serialModeAsString;
  String get baudDisplay => cfg.baudAsString;
  String get regionDisplay => cfg.frequencyRegionAsString;


  // ✅ Métodos de conexión
  Future<void> connectBle() async {
    busy = true;
    status = "Conectando por Bluetooth...";
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    busy = false;
    status = "Conectado por Bluetooth";
    notifyListeners();
  }

  Future<void> connectUsb() async {
    busy = true;
    status = "Conectando por USB...";
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    busy = false;
    status = "Conectado por USB";
    notifyListeners();
  }

  Future<void> connectTcp(String url) async {
    busy = true;
    status = "Conectando a $url ...";
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    busy = false;
    status = "Conectado a $url";
    notifyListeners();
  }

  // ---- Métodos de configuración (ya existentes, no los toco) ----
  void setNames(String shortName, String longName) {
    cfg.shortName = shortName;
    cfg.longName = longName;
    notifyListeners();
  }

  void setChannelIndex(int index) {
    cfg.channelIndex = index;
    notifyListeners();
  }

  void setKey(Uint8List key) {
    cfg.key = key;
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
    busy = true;
    status = "Leyendo configuración...";
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    busy = false;
    status = "Configuración leída";
    notifyListeners();
  }

  Future<void> writeConfig() async {
    busy = true;
    status = "Enviando configuración...";
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    busy = false;
    status = "Configuración enviada";
    notifyListeners();
  }
}
