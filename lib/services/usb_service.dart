import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';

import 'package:logging/logging.dart';

import '../models/node_config.dart';
import 'stream_framing.dart';

// Importaciones de Protobuf
import 'package:buoys_configurator/exceptions/routing_error_exception.dart';
import 'package:buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:buoys_configurator/proto/meshtastic/module_config.pb.dart'
    as mod;
import 'package:buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:buoys_configurator/proto/meshtastic/portnums.pbenum.dart'
    as port;
import 'package:buoys_configurator/services/routing_error_utils.dart';

class UsbService {
  static final Logger _log = Logger('UsbService');
  UsbPort? _port;
  StreamSubscription<Uint8List>? _sub;
  FrameAccumulator? _frameAccumulator;
  StreamController<mesh.FromRadio>? _frameController;
  String? _lastErrorMessage; // Ãšltimo mensaje de error para la UI
  int? _myNodeNum; // NodeNum de este dispositivo, obtenido del radio
  bool _nodeNumConfirmed = false; // Si _myNodeNum ha sido confirmado
  Uint8List _sessionPasskey = Uint8List(0);
  Timer? _heartbeatTimer;
  int _configNonce = 0;
  static const Duration _heartbeatInterval = Duration(minutes: 5);
  Future<void> _writeChain = Future.value();

  // Timeouts estÃ¡ndar
  static const Duration _defaultResponseTimeout = Duration(seconds: 15);
  // static const Duration _postResponseWindow = Duration(milliseconds: 200); // Ventana para capturar respuestas adicionales
  // static const Duration _permissionRequestTimeout = Duration(seconds: 30); // Ya no se usa _ensurePermission

  int? get myNodeNum => _myNodeNum;
  set myNodeNum(int? value) {
    _myNodeNum = value;
    _nodeNumConfirmed =
        false; // Resetear confirmaciÃ³n si se cambia externamente
    if (value == null) {
      _sessionPasskey = Uint8List(0);
    }
  }

  String? get lastErrorMessage => _lastErrorMessage;

  // Intenta conectar a un dispositivo Meshtastic vÃ­a USB.
  Future<bool> connect({int baud = 115200}) async {
    _lastErrorMessage = null;
    _sessionPasskey = Uint8List(0);
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _configNonce = 0;
    _writeChain = Future.value();
    _log.info('[UsbService] Iniciando conexiÃ³n USB...');
    List<UsbDevice> devices;
    try {
      devices = await UsbSerial.listDevices();
    } catch (e, s) {
      _lastErrorMessage = 'Error al listar dispositivos USB: ${e.toString()}';
      _log.info('[UsbService] $_lastErrorMessage. Stack: $s');
      return false;
    }

    if (devices.isEmpty) {
      _lastErrorMessage = 'No se encontraron dispositivos USB disponibles.';
      _log.info('[UsbService] $_lastErrorMessage');
      return false;
    }

    _log.info(
        '[UsbService] Dispositivos USB encontrados: ${devices.map((d) => "${d.productName ?? d.deviceName} (VID:${d.vid}, PID:${d.pid})").join(", ")}');

    final dev = devices.firstWhere((d) {
      final lowerProductName = (d.productName ?? '').toLowerCase();
      final lowerMfgName = (d.manufacturerName ?? '').toLowerCase();
      return lowerProductName.contains('meshtastic') ||
          lowerProductName.contains('t-beam') ||
          lowerProductName.contains('heltec') ||
          lowerProductName.contains('lora') || // GenÃ©rico
          lowerProductName.contains('esp32') || // Chip comÃºn
          lowerProductName.contains('ch9102') || // Chipset USB-Serial comÃºn
          lowerProductName
              .contains('cp210x') || // Otro chipset USB-Serial comÃºn
          lowerMfgName.contains('espressif'); // Fabricante comÃºn de ESP32
    }, orElse: () => devices.first); // Si no, toma el primero

    _log.info(
        '[UsbService] Intentando conectar con: ${dev.productName ?? dev.deviceName} (Fabricante: ${dev.manufacturerName ?? "N/A"}, ID Dispositivo: ${dev.deviceId}, VID: ${dev.vid}, PID: ${dev.pid})');

    // La lÃ³gica de _ensurePermission se elimina. La gestiÃ³n de permisos ahora se basa en:
    // 1. ConfiguraciÃ³n de AndroidManifest.xml y device_filter.xml para que el SO solicite permisos.
    // 2. El Ã©xito o fracaso de dev.create() y _port.open() para determinar si se puede acceder.

    try {
      _port = await dev.create();
    } on PlatformException catch (error) {
      final message = error.message ?? '';
      // Comprobar mensajes comunes de error de permiso, aunque pueden variar segÃºn la implementaciÃ³n nativa del plugin.
      if (message.toLowerCase().contains('permission') ||
          message.toLowerCase().contains('denied') ||
          error.code ==
              'UsbSerialPortAdapter' || // CÃ³digo de error visto en algunos casos de problemas de puerto/permiso
          message.contains('Failed to acquire USB permission')) {
        // Mensaje especÃ­fico mencionado antes
        _lastErrorMessage =
            'Permiso USB denegado o fallo al adquirir el dispositivo (${dev.productName ?? dev.deviceName}). Verifica los permisos del sistema.';
      } else {
        _lastErrorMessage =
            'No se pudo crear el puerto para el dispositivo USB (${dev.productName ?? dev.deviceName}): ${message.isEmpty ? error.code : message}.';
      }
      _log.info(
          '[UsbService] Error al crear puerto USB (PlatformException): $_lastErrorMessage. Error original: $error');
      return false;
    } catch (error, stackTrace) {
      _lastErrorMessage =
          'Error inesperado al crear puerto USB para ${dev.productName ?? dev.deviceName}: ${error.toString()}.';
      _log.info('[UsbService] $_lastErrorMessage. Stack: $stackTrace');
      return false;
    }

    if (_port == null) {
      _lastErrorMessage =
          'No se pudo crear el puerto USB para ${dev.productName ?? dev.deviceName} (dev.create() retornÃ³ nulo).';
      _log.info('[UsbService] $_lastErrorMessage');
      return false;
    }

    _log.info(
        '[UsbService] Abriendo puerto USB para ${dev.productName ?? dev.deviceName}...');
    bool portOpened = false;
    try {
      portOpened = await _port!.open();
    } catch (e, s) {
      _lastErrorMessage =
          'ExcepciÃ³n al abrir puerto USB para ${dev.productName ?? dev.deviceName}: ${e.toString()}';
      _log.info('[UsbService] $_lastErrorMessage. Stack: $s');
      await disconnect(); // Intentar limpiar
      return false;
    }

    if (!portOpened) {
      // _port.open() devolviendo false a menudo indica que el permiso no fue concedido por el SO, o el dispositivo no estÃ¡ listo.
      _lastErrorMessage =
          'No se pudo abrir el puerto USB para ${dev.productName ?? dev.deviceName} (open() retornÃ³ false). Esto puede deberse a permisos denegados.';
      _log.info('[UsbService] $_lastErrorMessage');
      await disconnect(); // Intentar limpiar
      return false;
    }

    _log.info(
        '[UsbService] Puerto USB abierto. Configurando parÃ¡metros (Baud: $baud, DTR: true, RTS: true)...');
    try {
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
          baud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
    } catch (e, s) {
      _lastErrorMessage =
          'Error configurando parÃ¡metros del puerto USB: ${e.toString()}';
      _log.info('[UsbService] $_lastErrorMessage. Stack: $s');
      await disconnect();
      return false;
    }

    try {
      final wakeSequence = Uint8List.fromList([0x94, 0x94, 0x94, 0x94]);
      await _port!.write(wakeSequence);
      _log.info('[UsbService] Secuencia wake enviada al puerto USB.');
    } catch (e, s) {
      _log.info(
          '[UsbService] Error enviando secuencia wake al puerto USB: $e. Stack: $s');
    }

    _frameAccumulator = FrameAccumulator();
    _frameController = StreamController<mesh.FromRadio>.broadcast();

    final input = _port!.inputStream;
    if (input == null) {
      _lastErrorMessage =
          'No se pudo acceder al flujo de datos (inputStream) del dispositivo USB (${dev.productName ?? dev.deviceName}).';
      _log.info('[UsbService] $_lastErrorMessage');
      await disconnect();
      return false;
    }

    _log.info('[UsbService] Escuchando datos del puerto USB...');
    _sub = input.listen((Uint8List chunk) {
      final accumulator = _frameAccumulator;
      final controller = _frameController;
      if (accumulator == null || controller == null || controller.isClosed) {
        return;
      }
      for (final payload in accumulator.addChunk(chunk)) {
        try {
          final frame = mesh.FromRadio.fromBuffer(payload);
          _captureMyNodeNum(frame);
          if (!controller.isClosed) controller.add(frame);
        } catch (e, s) {
          _log.info(
              '[UsbService] Error al deserializar frame FromRadio desde USB: $e. Payload (hex): ${payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}. Ignorando frame. Stack: $s');
        }
      }
    }, onError: (error, stackTrace) {
      _log.info(
          '[UsbService] Error en el stream de entrada USB: $error. Stack: $stackTrace');
      _lastErrorMessage =
          'Error en el stream de datos USB: ${error.toString()}';
      disconnect();
    }, onDone: () {
      _log.info('[UsbService] Stream de entrada USB cerrado (onDone).');
      if (_port != null) {
        _lastErrorMessage = 'Dispositivo USB desconectado o stream finalizado.';
        disconnect();
      }
    });

    _log.info(
        '[UsbService] Conexion USB establecida y escuchando en ${dev.productName ?? dev.deviceName}.');
    try {
      await _startConfigSession();
    } catch (e, s) {
      _log.info(
          '[UsbService] Error iniciando sesion de configuracion: $e. Stack: $s');
      _lastErrorMessage =
          'Error iniciando sesion de configuracion: ${e.toString()}';
      await disconnect();
      return false;
    }

    return true;
  }

  // Desconecta del dispositivo USB y limpia los recursos.
  Future<void> disconnect() async {
    _log.info('[UsbService] Iniciando desconexiÃ³n USB...');
    await _sub?.cancel();
    _sub = null;

    if (_frameController != null && !_frameController!.isClosed) {
      await _frameController!.close();
      _log.info('[UsbService] FrameController cerrado.');
    }
    _frameController = null;
    _frameAccumulator = null;

    if (_port != null) {
      try {
        _log.info('[UsbService] Cerrando puerto USB...');
        await _port!.close();
        _log.info('[UsbService] Puerto USB cerrado.');
      } catch (e, s) {
        _log.info('[UsbService] Error al cerrar puerto USB: $e. Stack: $s');
        _lastErrorMessage = 'Error al cerrar puerto USB: ${e.toString()}';
      }
      _port = null;
    }

    _myNodeNum = null;
    _nodeNumConfirmed = false;
    _sessionPasskey = Uint8List(0);
    _log.info('[UsbService] DesconexiÃ³n USB completada. Estado limpiado.');
  }

  void _captureMyNodeNum(mesh.FromRadio frame) {
    if (frame.hasMyInfo() && frame.myInfo.hasMyNodeNum()) {
      final newNum = frame.myInfo.myNodeNum;
      if (_myNodeNum != newNum) {
        _log.info(
            '[UsbService] MyNodeNum capturado/actualizado: $_myNodeNum -> $newNum');
        _myNodeNum = newNum;
      } else if (!_nodeNumConfirmed) {
        _log.info('[UsbService] MyNodeNum re-confirmado: $newNum');
      }
      _nodeNumConfirmed = true;
    }
  }

  void _captureSessionPasskey(admin.AdminMessage message) {
    if (message.sessionPasskey.isNotEmpty) {
      _sessionPasskey = Uint8List.fromList(message.sessionPasskey);
    }
  }

  void _injectSessionPasskey(admin.AdminMessage msg) {
    if (_sessionPasskey.isEmpty) return;
    if (msg.sessionPasskey.isNotEmpty) return;
    msg.sessionPasskey = Uint8List.fromList(_sessionPasskey);
  }

  Future<void> _startConfigSession() async {
    final port = _port;
    if (port == null) return;

    final nonce = _nextConfigNonce();
    final toRadio = mesh.ToRadio()..wantConfigId = nonce;
    await _enqueueWrite(StreamFraming.frame(toRadio.writeToBuffer()));
    _startHeartbeatTimer();
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final port = _port;
    if (port == null) return;
    final heartbeat = mesh.ToRadio()..heartbeat = mesh.Heartbeat();
    try {
      await _enqueueWrite(StreamFraming.frame(heartbeat.writeToBuffer()));
    } catch (err) {
      _log.info('[UsbService] Error enviando heartbeat USB: $err');
    }
  }

  int _nextConfigNonce() {
    _configNonce = (_configNonce + 1) & 0xFFFFFFFF;
    if (_configNonce == 0) {
      _configNonce = 1;
    }
    return _configNonce;
  }

  Future<void> _enqueueWrite(Uint8List data) {
    final port = _port;
    if (port == null) {
      throw StateError('Puerto USB no disponible para escritura.');
    }
    _writeChain = _writeChain.then((_) async {
      await port.write(data);
    });
    return _writeChain;
  }

  Future<void> _ensureMyNodeNum() async {
    if (_nodeNumConfirmed && _myNodeNum != null) return;
    _log.info(
        '[UsbService] Asegurando MyNodeNum (estado actual: confirmado=$_nodeNumConfirmed, num=$_myNodeNum)...');

    final port = _port;
    final controller = _frameController;
    if (port == null || controller == null || controller.isClosed) {
      _log.info(
          '[UsbService] _ensureMyNodeNum fallÃ³: Puerto USB no disponible o stream cerrado.');
      throw StateError(
          'Puerto USB no disponible o stream de FromRadio cerrado.');
    }

    final infoFuture = controller.stream
        .where((frame) => frame.hasMyInfo() && frame.myInfo.hasMyNodeNum())
        .map((frame) => frame.myInfo.myNodeNum)
        .first
        .timeout(_defaultResponseTimeout, onTimeout: () {
      _log.info(
          '[UsbService] Timeout (_defaultResponseTimeout) esperando MyInfo en el stream durante _ensureMyNodeNum.');
      throw TimeoutException(
          'Timeout esperando MyNodeInfo del radio (stream).');
    });

    final toRadio = mesh.ToRadio()
      ..wantConfigId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

    _log.info(
        '[UsbService] Enviando solicitud de MyInfo (wantConfigId: ${toRadio.wantConfigId}) para obtener NodeNum.');
    try {
      await _enqueueWrite(StreamFraming.frame(toRadio.writeToBuffer()));
    } catch (e, s) {
      _log.info(
          '[UsbService] Error escribiendo solicitud de MyInfo al puerto USB: $e. Stack: $s');
      throw StateError(
          'Error al escribir en puerto USB para MyInfo: ${e.toString()}');
    }

    try {
      final nodeNum = await infoFuture;
      _myNodeNum = nodeNum;
      _nodeNumConfirmed = true;
      _log.info('[UsbService] MyNodeNum asegurado y confirmado: $_myNodeNum');
    } on TimeoutException catch (e) {
      _log.info(
          '[UsbService] _ensureMyNodeNum fallÃ³ por TimeoutException: ${e.message}');
      throw TimeoutException(
          'No se recibiÃ³ MyNodeInfo del radio (timeout global en _ensureMyNodeNum).');
    } catch (e, s) {
      _log.info(
          '[UsbService] _ensureMyNodeNum fallÃ³ con error inesperado esperando infoFuture: $e. Stack: $s');
      throw StateError(
          'Error inesperado obteniendo MyNodeInfo: ${e.toString()}');
    }

    if (_myNodeNum == null) {
      _log.info(
          '[UsbService] _ensureMyNodeNum fallÃ³ crÃ­ticamente: No se pudo determinar el NodeNum del radio despuÃ©s del intento.');
      throw StateError('No se pudo determinar el NodeNum del radio.');
    }
  }

  mesh.ToRadio _wrapAdmin(admin.AdminMessage adminMsg) {
    final nodeNum = _myNodeNum;
    if (nodeNum == null) {
      _log.info(
          '[UsbService] CRÃTICO: _wrapAdmin llamado pero _myNodeNum es nulo. El paquete no serÃ¡ dirigido correctamente.');
      throw StateError(
          '_myNodeNum no inicializado. Llama a _ensureMyNodeNum antes de enviar comandos administrativos.');
    }
    _injectSessionPasskey(adminMsg);
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = adminMsg.writeToBuffer()
      ..wantResponse = true;

    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..to = nodeNum
        ..from = 0
        ..id = packetId
        ..priority = mesh.MeshPacket_Priority.RELIABLE
        ..wantAck = true
        ..decoded = data);
  }

  Future<NodeConfig?> readConfig() async {
    if (_port == null || _frameController == null) {
      _log.info(
          '[UsbService] readConfig abortado: puerto o frameController nulos.');
      _lastErrorMessage = 'Puerto USB no conectado para leer configuraciÃ³n.';
      return null;
    }

    try {
      await _ensureMyNodeNum();
    } catch (e, s) {
      _log.info(
          '[UsbService] readConfig fallÃ³ en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage =
          'Error al obtener NodeNum para leer config: ${e.toString()}';
      return null;
    }

    _log.info(
        '[UsbService] Iniciando lectura de configuraciÃ³n del nodo $_myNodeNum...');
    final cfgOut = NodeConfig();

    var primaryChannelCaptured = false;

    void applyAdmin(admin.AdminMessage message) {
      _captureSessionPasskey(message);
      if (message.hasGetOwnerResponse()) {
        final user = message.getOwnerResponse;
        if (user.hasLongName()) cfgOut.longName = user.longName;
        if (user.hasShortName()) cfgOut.shortName = user.shortName;
      }
      if (message.hasGetChannelResponse()) {
        final channel = message.getChannelResponse;
        final isPrimary = channel.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryChannelCaptured) {
          if (channel.hasIndex()) cfgOut.channelIndex = channel.index;
          if (channel.hasSettings() && channel.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(channel.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
          _log.info(
              '[UsbService] readConfig: Canal PRIMARIO ${cfgOut.channelIndex} capturado con PSK (longitud: ${cfgOut.key.length} bytes).');
        }
      }
      if (message.hasGetModuleConfigResponse() &&
          message.getModuleConfigResponse.hasSerial()) {
        final serial = message.getModuleConfigResponse.serial;
        if (serial.hasMode()) cfgOut.serialOutputMode = serial.mode;
        if (serial.hasBaud()) cfgOut.baudRate = serial.baud;
      }
      if (message.hasGetConfigResponse() &&
          message.getConfigResponse.hasLora() &&
          message.getConfigResponse.lora.hasRegion()) {
        cfgOut.frequencyRegion = message.getConfigResponse.lora.region;
      }
    }

    void consumeFrame(mesh.FromRadio fr) {
      final adminMsg = _decodeAdminMessage(fr);
      if (adminMsg != null) {
        applyAdmin(adminMsg);
      }
    }

    final subscription = _frameController!.stream.listen(consumeFrame);
    var receivedAnyResponse = false;

    Future<bool> request(admin.AdminMessage msgToSend,
        bool Function(admin.AdminMessage) matcher, String description) async {
      _log.info('[UsbService] readConfig: Solicitando $description...');
      try {
        await _sendAdminAndWait(
            msg: msgToSend,
            matcher: matcher,
            timeout: _defaultResponseTimeout,
            description: description);
        _log.info(
            '[UsbService] readConfig: Respuesta recibida para $description.');
        return true;
      } on TimeoutException {
        _log.info(
            '[UsbService] readConfig: Timeout esperando respuesta para $description.');
        return false;
      } catch (e, s) {
        _log.info(
            '[UsbService] readConfig: Error en request para $description: $e. Stack: $s');
        if (e is RoutingErrorException) {
          _lastErrorMessage = e.message;
        } else {
          _lastErrorMessage = 'Error solicitando $description: ${e.toString()}';
        }
        return false;
      }
    }

    try {
      final ownerReceived = await request(
          admin.AdminMessage()..getOwnerRequest = true,
          (m) => m.hasGetOwnerResponse(),
          "OwnerInfo");
      receivedAnyResponse = receivedAnyResponse || ownerReceived;

      final deviceCfgReceived = await request(
          admin.AdminMessage()
            ..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG,
          (m) => m.hasGetConfigResponse() && m.getConfigResponse.hasDevice(),
          "DeviceConfig");
      receivedAnyResponse = receivedAnyResponse || deviceCfgReceived;

      final indicesToQuery = <int>{0};
      if (cfgOut.channelIndex > 0 && cfgOut.channelIndex <= 8) {
        indicesToQuery.add(cfgOut.channelIndex);
      }

      for (final index in indicesToQuery) {
        if (primaryChannelCaptured &&
            index != 0 &&
            index != cfgOut.channelIndex) continue;
        final channelReceived = await request(
            admin.AdminMessage()..getChannelRequest = index + 1,
            (m) =>
                m.hasGetChannelResponse() &&
                m.getChannelResponse.index == index,
            "Channel $index");
        receivedAnyResponse = receivedAnyResponse || channelReceived;
        if (primaryChannelCaptured && cfgOut.channelIndex == index) break;
      }

      final serialReceived = await request(
          admin.AdminMessage()
            ..getModuleConfigRequest =
                admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
          (m) =>
              m.hasGetModuleConfigResponse() &&
              m.getModuleConfigResponse.hasSerial(),
          "SerialConfig");
      receivedAnyResponse = receivedAnyResponse || serialReceived;

      final loraReceived = await request(
          admin.AdminMessage()
            ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
          (m) =>
              m.hasGetConfigResponse() &&
              m.getConfigResponse.hasLora() &&
              m.getConfigResponse.lora.hasRegion(),
          "LoRaConfig");
      receivedAnyResponse = receivedAnyResponse || loraReceived;

      if (!receivedAnyResponse && ownerReceived) {
        _log.info(
            '[UsbService] readConfig: Solo se recibiÃ³ OwnerInfo. El nodo podrÃ­a no estar completamente configurado.');
      } else if (!receivedAnyResponse) {
        _log.info(
            '[UsbService] readConfig: No se recibiÃ³ ninguna respuesta de configuraciÃ³n vÃ¡lida de las solicitudes principales.');
        _lastErrorMessage =
            'No se recibiÃ³ respuesta de configuraciÃ³n del nodo.';
      }
    } finally {
      await subscription.cancel();
      _log.info(
          '[UsbService] readConfig: SuscripciÃ³n de _consumeFrame cancelada.');
    }

    _log.info('[UsbService] Lectura de configuraciÃ³n completada.');
    return cfgOut;
  }

  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_port == null) {
      _log.info('[UsbService] writeConfig abortado: puerto USB nulo.');
      _lastErrorMessage =
          'Puerto USB no conectado para escribir configuraciÃ³n.';
      return;
    }
    try {
      await _ensureMyNodeNum();
    } catch (e, s) {
      _log.info(
          '[UsbService] writeConfig fallÃ³ en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage =
          'Error al obtener NodeNum para escribir config: ${e.toString()}';
      return;
    }

    _log.info(
        '[UsbService] Iniciando escritura de configuraciÃ³n para el nodo $_myNodeNum...');

    try {
      final userMsg = mesh.User()
        ..shortName = cfgIn.shortName
        ..longName = cfgIn.longName;
      await _sendAdmin(admin.AdminMessage()..setOwner = userMsg,
          description: "SetOwner (Nombres)");

      final settings = ch.ChannelSettings()
        ..name = "CH${cfgIn.channelIndex}"
        ..psk = cfgIn.key;
      final channel = ch.Channel()
        ..index = cfgIn.channelIndex
        ..role = ch.Channel_Role.PRIMARY
        ..settings = settings;
      await _sendAdmin(admin.AdminMessage()..setChannel = channel,
          description: "SetChannel (Ãndice ${cfgIn.channelIndex})");

      final serialCfg = mod.ModuleConfig_SerialConfig()
        ..enabled = true
        ..baud = cfgIn.baudRate
        ..mode = _serialModeFromString(cfgIn.serialModeAsString);
      final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
      await _sendAdmin(admin.AdminMessage()..setModuleConfig = moduleCfg,
          description: "SetModuleConfig (Serial)");

      final lora = cfg.Config_LoRaConfig()
        ..region = _regionFromString(cfgIn.frequencyRegionAsString);
      final configMsg = cfg.Config()..lora = lora;
      await _sendAdmin(admin.AdminMessage()..setConfig = configMsg,
          description: "SetConfig (LoRa)");

      _log.info(
          '[UsbService] Escritura de configuraciÃ³n: todos los comandos enviados al nodo $_myNodeNum.');
    } catch (e, s) {
      _log.info('[UsbService] Error durante writeConfig: $e. Stack: $s');
      if (e is RoutingErrorException) {
        _lastErrorMessage = e.message;
      } else {
        _lastErrorMessage = 'Error al escribir configuraciÃ³n: ${e.toString()}';
      }
      rethrow;
    }
  }

  Future<void> _sendAdmin(admin.AdminMessage msg, {String? description}) async {
    final port = _port;
    if (port == null) {
      _log.info(
          '[UsbService] _sendAdmin (${description ?? msg.info_.messageName}) abortado: puerto USB nulo.');
      throw StateError('Puerto USB nulo al intentar enviar AdminMessage.');
    }
    final toRadioMsg = _wrapAdmin(msg);
    final type = description ?? msg.info_.messageName;
    _log.info(
        "[UsbService] Enviando AdminMessage: '$type' a NodeNum: $_myNodeNum, PacketID: ${toRadioMsg.packet.id}");
    try {
      await _enqueueWrite(StreamFraming.frame(toRadioMsg.writeToBuffer()));
    } catch (e, s) {
      _log.info(
          "[UsbService] Error enviando AdminMessage ('$type') al puerto USB: $e. Stack: $s");
      throw StateError(
          "Error al escribir AdminMessage ('$type') en puerto USB: ${e.toString()}");
    }
  }

  Future<void> _sendAdminAndWait({
    required admin.AdminMessage msg,
    required bool Function(admin.AdminMessage) matcher,
    required Duration timeout,
    String? description,
  }) {
    final toRadioMsg = _wrapAdmin(msg);
    final type = description ?? msg.info_.messageName;
    _log.info(
        "[UsbService] Enviando AdminMessage ('$type') y esperando respuesta... (NodeNum: $_myNodeNum, PacketID: ${toRadioMsg.packet.id})");
    return _sendToRadioAndWait(
      to: toRadioMsg,
      matcher: matcher,
      timeout: timeout,
      description: type,
    );
  }

  Future<void> _sendToRadioAndWait({
    required mesh.ToRadio to,
    required bool Function(admin.AdminMessage) matcher,
    required Duration timeout,
    String? description,
  }) async {
    final port = _port;
    final controller = _frameController;
    if (port == null || controller == null || controller.isClosed) {
      final reason =
          port == null ? "puerto nulo" : "frameController nulo o cerrado";
      _log.info(
          "[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}') abortado: $reason.");
      throw StateError(
          'Puerto USB o stream no disponible para SendAndWait ($reason).');
    }

    final completer = Completer<void>();
    var commandSent = false;
    Future<void>? cancelSubFuture;
    late StreamSubscription<mesh.FromRadio> sub;

    sub = controller.stream.listen((frame) {
      if (!commandSent || completer.isCompleted) return;

      try {
        throwIfRoutingError(frame);
      } on RoutingErrorException catch (error) {
        _lastErrorMessage = error.message;
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        cancelSubFuture ??= sub.cancel();
        return;
      } catch (error, stackTrace) {
        _log.info(
            "[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}') recibiÃ³ frame invÃ¡lido: $error. Stack: $stackTrace");
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        cancelSubFuture ??= sub.cancel();
        return;
      }

      final adminMsg = _decodeAdminMessage(frame);
      if (adminMsg == null) return;

      if (matcher(adminMsg)) {
        _log.info(
            "[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): Â¡Respuesta coincidente encontrada!");
        if (!completer.isCompleted) completer.complete();
        cancelSubFuture ??= sub.cancel();
      }
    });

    try {
      await _enqueueWrite(StreamFraming.frame(to.writeToBuffer()));
      commandSent = true;
      _log.info(
          "[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): Comando enviado. Esperando respuesta por ${timeout.inMilliseconds}ms.");

      await completer.future.timeout(timeout);
    } on TimeoutException {
      _log.info(
          "[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): Timeout esperando respuesta especÃ­fica.");
      if (!completer.isCompleted) {
        _lastErrorMessage =
            "Timeout esperando respuesta para '${description ?? "comando"}'.";
      }
      throw TimeoutException(
          "Timeout esperando respuesta especÃ­fica para '${description ?? "comando"}'.");
    } finally {
      await (cancelSubFuture ?? sub.cancel());
    }
  }

  admin.AdminMessage? _decodeAdminMessage(mesh.FromRadio frame) {
    if (!frame.hasPacket()) return null;
    final packet = frame.packet;
    if (!packet.hasDecoded()) return null;
    final decoded = packet.decoded;
    if (decoded.portnum != port.PortNum.ADMIN_APP) return null;
    if (!decoded.hasPayload()) return null;

    final payload = decoded.payload;
    if (payload.isEmpty) return null;
    try {
      final message = admin.AdminMessage.fromBuffer(payload);
      _captureSessionPasskey(message);
      return message;
    } catch (e, s) {
      _log.info(
          '[UsbService] Error al deserializar AdminMessage desde payload: $e. Payload (hex): ${payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}. Stack: $s');
      return null;
    }
  }

  cfg.Config_LoRaConfig_RegionCode _regionFromString(String s) {
    switch (s) {
      case '433':
        return cfg.Config_LoRaConfig_RegionCode.EU_433;
      case '915':
        return cfg.Config_LoRaConfig_RegionCode.US;
      case '868':
      default:
        return cfg.Config_LoRaConfig_RegionCode.EU_868;
    }
  }

  mod.ModuleConfig_SerialConfig_Serial_Mode _serialModeFromString(String s) {
    switch (s.toUpperCase()) {
      case 'PROTO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
      case 'TEXTMSG':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
      case 'TLL':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'NMEA':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'WPL':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      case 'CALTOPO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      default:
        return mod.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }
}
