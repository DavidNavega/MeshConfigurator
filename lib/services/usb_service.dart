import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';

import '../models/node_config.dart';
import 'stream_framing.dart';

// Importaciones de Protobuf
import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:Buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:Buoys_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:Buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

class UsbService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _sub;
  FrameAccumulator? _frameAccumulator;
  StreamController<mesh.FromRadio>? _frameController;
  String? _lastErrorMessage; // Último mensaje de error para la UI
  int? _myNodeNum; // NodeNum de este dispositivo, obtenido del radio
  bool _nodeNumConfirmed = false; // Si _myNodeNum ha sido confirmado

  // Timeouts estándar
  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200); // Ventana para capturar respuestas adicionales
  static const Duration _permissionRequestTimeout = Duration(seconds: 30); // Timeout para la solicitud de permiso USB

  int? get myNodeNum => _myNodeNum;
  set myNodeNum(int? value) {
    _myNodeNum = value;
    _nodeNumConfirmed = false; // Resetear confirmación si se cambia externamente
  }

  String? get lastErrorMessage => _lastErrorMessage;

  // Asegura que se tienen los permisos para acceder al dispositivo USB.
  Future<bool> _ensurePermission(UsbDevice device) async {
    print('[UsbService] Verificando permiso para dispositivo: ${device.productName ?? device.deviceName}');
    try {
      final dynamic usbSerial = UsbSerial; // Acceso dinámico por si la API no es estática
      final dynamic bus = usbSerial.usbBus;
      
      if (bus == null) {
        print('[UsbService] usbBus es nulo. Esto puede indicar un problema con el plugin usb_serial o no ser necesario en esta plataforma.');
        // En algunas plataformas, o si el plugin no está completamente inicializado, bus puede ser null.
        // Asumir true aquí es optimista. Podría ser más seguro devolver false.
        // Por ahora, se mantiene el comportamiento de devolver true si no hay 'bus' para verificar.
        return true; 
      }

      final dynamic hasPermissionValue = await Future.value(bus.hasPermission(device));
      if (hasPermissionValue == true) {
        print('[UsbService] Permiso USB ya concedido para ${device.productName ?? device.deviceName}.');
        return true;
      }

      print('[UsbService] Solicitando permiso USB para ${device.productName ?? device.deviceName}...');
      final completer = Completer<bool>();
      StreamSubscription? grantedSub;
      StreamSubscription? deniedSub;

      void resolve(bool granted, dynamic eventDevice) {
        if (completer.isCompleted) return;
        // Comprobar si el evento corresponde al dispositivo solicitado
        if (eventDevice is UsbDevice && eventDevice.deviceId == device.deviceId) {
          print('[UsbService] Evento de permiso USB recibido: ${granted ? "CONCEDIDO" : "DENEGADO"} para ${eventDevice.productName ?? eventDevice.deviceName}');
          completer.complete(granted);
        } else if (eventDevice == null && !granted) { 
          // Algunos plugins/plataformas podrían enviar null en denegación
          print('[UsbService] Evento de permiso USB DENEGADO (dispositivo nulo en evento) para ${device.productName ?? device.deviceName}');
          completer.complete(false);
        }
      }

      try {
        final dynamic grantedStreamDynamic = bus.onPermissionGranted;
        final dynamic deniedStreamDynamic = bus.onPermissionDenied;

        if (grantedStreamDynamic is Stream) {
          grantedSub = (grantedStreamDynamic as Stream<dynamic>).listen((dynamic dev) => resolve(true, dev));
        }
        if (deniedStreamDynamic is Stream) {
          deniedSub = (deniedStreamDynamic as Stream<dynamic>).listen((dynamic dev) => resolve(false, dev));
        }

        final dynamic requestValue = await Future.value(bus.requestPermission(device));
        if (requestValue == false && !completer.isCompleted) {
          print('[UsbService] Solicitud de permiso USB retornó false directamente.');
          completer.complete(false);
        }
        
        // Fallback si los streams no están disponibles o no se disparan
        if (!completer.isCompleted && grantedStreamDynamic is! Stream && deniedStreamDynamic is! Stream) {
          print('[UsbService] Streams de eventos de permiso no disponibles. Usando valor de retorno de requestPermission: $requestValue');
          completer.complete(requestValue == true);
        }

        final bool granted = await completer.future.timeout(
          _permissionRequestTimeout,
          onTimeout: () {
            print('[UsbService] Timeout esperando respuesta de permiso USB.');
            return false; // Asumir denegado en timeout
          },
        );

        if (!granted) {
          _lastErrorMessage = 'Permiso USB denegado o timeout para ${device.productName ?? device.deviceName}.';
          print('[UsbService] $_lastErrorMessage');
        }
        return granted;

      } finally {
        await grantedSub?.cancel();
        await deniedSub?.cancel();
      }
    } on NoSuchMethodError catch (e, s) {
      print('[UsbService] Error de método no encontrado en _ensurePermission (NoSuchMethodError). Esto puede indicar un problema con la integración del plugin usb_serial. Error: $e, Stack: $s');
      _lastErrorMessage = 'Error de plugin USB (NoSuchMethodError): ${e.toString()}';
      return false; // Error crítico, no se puede proceder.
    } catch (error, stackTrace) {
      print('[UsbService] Error inesperado solicitando permisos USB: $error. Stack: $stackTrace');
      _lastErrorMessage = 'Error inesperado de permisos USB: ${error.toString()}';
      return false; // Error crítico, no se puede proceder.
    }
  }

  // Intenta conectar a un dispositivo Meshtastic vía USB.
  Future<bool> connect({int baud = 115200}) async {
    _lastErrorMessage = null;
    print('[UsbService] Iniciando conexión USB...');
    List<UsbDevice> devices;
    try {
        devices = await UsbSerial.listDevices();
    } catch (e, s) {
        _lastErrorMessage = 'Error al listar dispositivos USB: ${e.toString()}';
        print('[UsbService] $_lastErrorMessage. Stack: $s');
        return false;
    }

    if (devices.isEmpty) {
      _lastErrorMessage = 'No se encontraron dispositivos USB disponibles.';
      print('[UsbService] $_lastErrorMessage');
      return false;
    }
    
    print('[UsbService] Dispositivos USB encontrados: ${devices.map((d) => "${d.productName ?? d.deviceName} (VID:${d.vid}, PID:${d.pid})").join(", ")}');
    
    // Intenta encontrar un dispositivo Meshtastic o compatible. (Lógica de selección simple)
    final dev = devices.firstWhere((d) {
        final lowerProductName = (d.productName ?? '').toLowerCase();
        final lowerMfgName = (d.manufacturerName ?? '').toLowerCase();
        return lowerProductName.contains('meshtastic') || 
               lowerProductName.contains('t-beam') ||
               lowerProductName.contains('heltec') || 
               lowerProductName.contains('lora') || // Genérico
               lowerProductName.contains('esp32') || // Chip común
               lowerProductName.contains('ch9102') || // Chipset USB-Serial común
               lowerProductName.contains('cp210x') || // Otro chipset USB-Serial común
               lowerMfgName.contains('espressif'); // Fabricante común de ESP32
    }, orElse: () => devices.first); // Si no, toma el primero

    print('[UsbService] Intentando conectar con: ${dev.productName ?? dev.deviceName} (Fabricante: ${dev.manufacturerName ?? "N/A"}, ID Dispositivo: ${dev.deviceId}, VID: ${dev.vid}, PID: ${dev.pid})');
    
    if (!await _ensurePermission(dev)) {
      // _lastErrorMessage ya debería estar fijado por _ensurePermission
      if (_lastErrorMessage == null) _lastErrorMessage = 'Permiso USB denegado para ${dev.productName ?? dev.deviceName}.';
      print('[UsbService] Conexión fallida debido a permisos: $_lastErrorMessage');
      return false;
    }
    
    try {
      _port = await dev.create();
    } on PlatformException catch (error) {
      final message = error.message ?? '';
      if (message.contains('Failed to acquire USB permission') || error.code == 'UsbSerialPortAdapter') {
        _lastErrorMessage = 'Permiso USB denegado (PlatformException) para ${dev.productName ?? dev.deviceName}. Asegúrate de que la app tiene permiso en los ajustes del sistema.';
      } else {
        _lastErrorMessage = 'No se pudo inicializar el dispositivo USB (${dev.productName ?? dev.deviceName}): ${message.isEmpty ? error.code : message}.';
      }
      print('[UsbService] $_lastErrorMessage. Error original: $error');
      return false;
    } catch (error, stackTrace) {
      _lastErrorMessage = 'Error inesperado al crear puerto USB para ${dev.productName ?? dev.deviceName}: ${error.toString()}.';
      print('[UsbService] $_lastErrorMessage. Stack: $stackTrace');
      return false;
    }

    if (_port == null) {
      _lastErrorMessage = 'No se pudo crear el puerto USB para ${dev.productName ?? dev.deviceName} (retornó nulo).';
      print('[UsbService] $_lastErrorMessage');
      return false;
    }

    print('[UsbService] Abriendo puerto USB para ${dev.productName ?? dev.deviceName}...');
    bool portOpened = false;
    try {
        portOpened = await _port!.open();
    } catch (e,s) {
        _lastErrorMessage = 'Excepción al abrir puerto USB para ${dev.productName ?? dev.deviceName}: ${e.toString()}';
        print('[UsbService] $_lastErrorMessage. Stack: $s');
        await disconnect(); // Intentar limpiar
        return false;
    }

    if (!portOpened) {
      _lastErrorMessage = 'No se pudo abrir el puerto USB para ${dev.productName ?? dev.deviceName} (open() retornó false).';
      print('[UsbService] $_lastErrorMessage');
      await disconnect(); // Intentar limpiar
      return false;
    }

    print('[UsbService] Puerto USB abierto. Configurando parámetros (Baud: $baud, DTR: true, RTS: true)...');
    try {
        await _port!.setDTR(true);
        await _port!.setRTS(true);
        await _port!.setPortParameters(baud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
    } catch (e, s) {
        _lastErrorMessage = 'Error configurando parámetros del puerto USB: ${e.toString()}';
        print('[UsbService] $_lastErrorMessage. Stack: $s');
        await disconnect();
        return false;
    }
    
    _frameAccumulator = FrameAccumulator();
    _frameController = StreamController<mesh.FromRadio>.broadcast();

    final input = _port!.inputStream;
    if (input == null) {
      _lastErrorMessage = 'No se pudo acceder al flujo de datos (inputStream) del dispositivo USB (${dev.productName ?? dev.deviceName}).';
      print('[UsbService] $_lastErrorMessage');
      await disconnect();
      return false;
    }

    print('[UsbService] Escuchando datos del puerto USB...');
    _sub = input.listen((Uint8List chunk) {
      // print('[UsbService] Chunk USB recibido (bytes): ${chunk.length}'); // Log muy verboso
      final accumulator = _frameAccumulator;
      final controller = _frameController;
      if (accumulator == null || controller == null || controller.isClosed) {
        return;
      }
      for (final payload in accumulator.addChunk(chunk)) {
        try {
          final frame = mesh.FromRadio.fromBuffer(payload);
          // print('[UsbService] Frame USB decodificado: ${frame.info_.messageName}'); // Log verboso, actualizado para no usar whichPayload
          _captureMyNodeNum(frame);
          if (!controller.isClosed) controller.add(frame);
        } catch (e, s) {
          print('[UsbService] Error al deserializar frame FromRadio desde USB: $e. Payload (hex): ${payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}. Ignorando frame. Stack: $s');
        }
      }
    }, onError: (error, stackTrace) {
        print('[UsbService] Error en el stream de entrada USB: $error. Stack: $stackTrace');
        _lastErrorMessage = 'Error en el stream de datos USB: ${error.toString()}';
        // Considerar una desconexión automática aquí o un reintento.
        disconnect(); 
    }, onDone: () {
        print('[UsbService] Stream de entrada USB cerrado (onDone).');
        // Esto puede indicar que el dispositivo se desconectó.
        // Asegurarse de que el estado refleje la desconexión.
        if (_port != null) { // Si no fue por una llamada a disconnect() explícita
             _lastErrorMessage = 'Dispositivo USB desconectado o stream finalizado.';
             disconnect();
        }
    });
    
    print('[UsbService] Conexión USB establecida y escuchando en ${dev.productName ?? dev.deviceName}.');
    return true;
  }

  // Desconecta del dispositivo USB y limpia los recursos.
  Future<void> disconnect() async {
    print('[UsbService] Iniciando desconexión USB...');
    await _sub?.cancel();
    _sub = null;
    
    if (_frameController != null && !_frameController!.isClosed) {
      await _frameController!.close();
       print('[UsbService] FrameController cerrado.');
    }
    _frameController = null;
    _frameAccumulator = null; // Limpiar acumulador
    
    if (_port != null) {
      try {
        print('[UsbService] Cerrando puerto USB...');
        await _port!.close();
        print('[UsbService] Puerto USB cerrado.');
      } catch (e,s) {
        print('[UsbService] Error al cerrar puerto USB: $e. Stack: $s');
        _lastErrorMessage = 'Error al cerrar puerto USB: ${e.toString()}';
      }
      _port = null;
    }
    
    _myNodeNum = null;
    _nodeNumConfirmed = false;
    print('[UsbService] Desconexión USB completada. Estado limpiado.');
  }

  // Captura y actualiza _myNodeNum si está presente en el frame.
  void _captureMyNodeNum(mesh.FromRadio frame) {
    if (frame.hasMyInfo() && frame.myInfo.hasMyNodeNum()) {
      final newNum = frame.myInfo.myNodeNum;
      if (_myNodeNum != newNum) {
           print('[UsbService] MyNodeNum capturado/actualizado: ${_myNodeNum} -> $newNum');
           _myNodeNum = newNum;
      } else if (!_nodeNumConfirmed) {
          // Si es el mismo número pero no estaba confirmado, loguearlo la primera vez.
          print('[UsbService] MyNodeNum re-confirmado: $newNum');
      }
      _nodeNumConfirmed = true;
    }
  }

  // Asegura que _myNodeNum ha sido obtenido del dispositivo.
  Future<void> _ensureMyNodeNum() async {
    if (_nodeNumConfirmed && _myNodeNum != null) return;
    print('[UsbService] Asegurando MyNodeNum (estado actual: confirmado=$_nodeNumConfirmed, num=$_myNodeNum)...');
    
    final port = _port;
    final controller = _frameController;
    if (port == null || controller == null || controller.isClosed) {
      print('[UsbService] _ensureMyNodeNum falló: Puerto USB no disponible o stream cerrado.');
      throw StateError('Puerto USB no disponible o stream de FromRadio cerrado.');
    }

    // Futuro que se completa cuando se recibe un MyInfo con myNodeNum
    final infoFuture = controller.stream
        .where((frame) => frame.hasMyInfo() && frame.myInfo.hasMyNodeNum())
        .map((frame) => frame.myInfo.myNodeNum)
        .first
        .timeout(_defaultResponseTimeout, onTimeout: () {
            print('[UsbService] Timeout (_defaultResponseTimeout) esperando MyInfo en el stream durante _ensureMyNodeNum.');
            throw TimeoutException('Timeout esperando MyNodeInfo del radio (stream).');
        });

    // Mensaje para solicitar MyInfo (el dispositivo debería enviarlo al conectar o al recibir wantConfigId)
    final toRadio = mesh.ToRadio()
      ..wantConfigId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF; // ID aleatorio
    
    print('[UsbService] Enviando solicitud de MyInfo (wantConfigId: ${toRadio.wantConfigId}) para obtener NodeNum.');
    try {
        await port.write(StreamFraming.frame(toRadio.writeToBuffer()));
    } catch (e,s) {
        print('[UsbService] Error escribiendo solicitud de MyInfo al puerto USB: $e. Stack: $s');
        throw StateError('Error al escribir en puerto USB para MyInfo: ${e.toString()}');
    }
    
    try {
      final nodeNum = await infoFuture; // Espera a que el futuro del stream se complete
      _myNodeNum = nodeNum;
      _nodeNumConfirmed = true;
      print('[UsbService] MyNodeNum asegurado y confirmado: $_myNodeNum');
    } on TimeoutException catch(e) {
      // El timeout ya fue logueado por la lambda onTimeout del stream.
      print('[UsbService] _ensureMyNodeNum falló por TimeoutException: ${e.message}');
      throw TimeoutException('No se recibió MyNodeInfo del radio (timeout global en _ensureMyNodeNum).');
    } catch (e, s) {
      print('[UsbService] _ensureMyNodeNum falló con error inesperado esperando infoFuture: $e. Stack: $s');
      throw StateError('Error inesperado obteniendo MyNodeInfo: ${e.toString()}');
    }

    if (_myNodeNum == null) {
      print('[UsbService] _ensureMyNodeNum falló críticamente: No se pudo determinar el NodeNum del radio después del intento.');
      throw StateError('No se pudo determinar el NodeNum del radio.');
    }
  }

  // Envuelve un AdminMessage en un ToRadio.packet.
  mesh.ToRadio _wrapAdmin(admin.AdminMessage adminMsg) {
    final nodeNum = _myNodeNum;
    if (nodeNum == null) {
      print('[UsbService] CRÍTICO: _wrapAdmin llamado pero _myNodeNum es nulo. El paquete no será dirigido correctamente.');
      // Lanzar excepción es lo correcto para evitar enviar paquetes malformados.
      throw StateError('_myNodeNum no inicializado. Llama a _ensureMyNodeNum antes de enviar comandos administrativos.');
    }
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = adminMsg.writeToBuffer()
      ..wantResponse = true; // Generalmente queremos respuesta para mensajes admin

    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;
    // print('[UsbService] _wrapAdmin: Creando paquete para NodeNum $nodeNum con ID $packetId para ${adminMsg.info_.messageName}'); // Verboso

    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..to = nodeNum // Dirigido a nuestro nodo
        ..from = 0 // Usar 0 (Broadcast addr) o un ID específico de app si se desea diferenciar. Firmware suele ignorarlo para AdminApp.
        ..id = packetId // ID de paquete único
        ..priority = mesh.MeshPacket_Priority.RELIABLE // Queremos que los comandos admin lleguen
        ..wantAck = true // Solicitar ACK del radio
        ..decoded = data);
  }

  // Lee la configuración del nodo.
  Future<NodeConfig?> readConfig() async {
    if (_port == null || _frameController == null) {
      print('[UsbService] readConfig abortado: puerto o frameController nulos.');
      _lastErrorMessage = 'Puerto USB no conectado para leer configuración.';
      return null;
    }
    
    try {
      await _ensureMyNodeNum(); // Asegura que tenemos el NodeNum antes de proceder
    } catch (e, s) {
      print('[UsbService] readConfig falló en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage = 'Error al obtener NodeNum para leer config: ${e.toString()}';
      return null;
    }
    
    print('[UsbService] Iniciando lectura de configuración del nodo $_myNodeNum...');
    final cfgOut = NodeConfig(); // Objeto para almacenar la configuración leída

    var primaryChannelCaptured = false; 
    // var primaryChannelLogged = false; // No parece usarse, comentado para evitar warnings.

    // Aplica los datos de un AdminMessage a cfgOut
    void _applyAdmin(admin.AdminMessage message) {
      // print('[UsbService] readConfig._applyAdmin: Procesando ${message.info_.messageName}'); // Verboso
      if (message.hasGetOwnerResponse()) {
        final user = message.getOwnerResponse;
        if (user.hasLongName()) cfgOut.longName = user.longName;
        if (user.hasShortName()) cfgOut.shortName = user.shortName;
      }
      if (message.hasGetChannelResponse()) {
        final channel = message.getChannelResponse;
        final isPrimary = channel.role == ch.Channel_Role.PRIMARY;
        if (isPrimary || !primaryChannelCaptured) { // Tomar el primer canal o el primario
          if (channel.hasIndex()) cfgOut.channelIndex = channel.index;
          if (channel.hasSettings() && channel.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(channel.settings.psk);
          }
        }
        if (isPrimary) {
          primaryChannelCaptured = true;
          // if (!primaryChannelLogged) { // No parece usarse
          // primaryChannelLogged = true;
          print('[UsbService] readConfig: Canal PRIMARIO ${cfgOut.channelIndex} capturado con PSK (longitud: ${cfgOut.key.length} bytes).');
          // }
        }
      }
      if (message.hasGetModuleConfigResponse() && message.getModuleConfigResponse.hasSerial()) {
        final serial = message.getModuleConfigResponse.serial;
        if (serial.hasMode()) cfgOut.serialOutputMode = serial.mode;
        if (serial.hasBaud()) cfgOut.baudRate = serial.baud;
      }
      if (message.hasGetConfigResponse() && message.getConfigResponse.hasLora() && message.getConfigResponse.lora.hasRegion()) {
        cfgOut.frequencyRegion = message.getConfigResponse.lora.region;
      }
    }

    // Consume frames del stream y aplica los AdminMessage
    void _consumeFrame(mesh.FromRadio fr) {
      final adminMsg = _decodeAdminMessage(fr);
      if (adminMsg != null) {
        _applyAdmin(adminMsg);
      }
    }

    final subscription = _frameController!.stream.listen(_consumeFrame);
    var receivedAnyResponse = false;
    
    // Función helper para solicitar un tipo de configuración y esperar la respuesta correspondiente
    Future<bool> request(admin.AdminMessage msgToSend, bool Function(admin.AdminMessage) matcher, String description) async {
      print('[UsbService] readConfig: Solicitando $description...');
      try {
        await _sendAdminAndWait(msg: msgToSend, matcher: matcher, timeout: _defaultResponseTimeout, description: description);
        print('[UsbService] readConfig: Respuesta recibida para $description.');
        return true;
      } on TimeoutException {
        print('[UsbService] readConfig: Timeout esperando respuesta para $description.');
        return false; // No es un error fatal para toda la lectura, solo para esta parte.
      } catch (e,s) {
        print('[UsbService] readConfig: Error en request para $description: $e. Stack: $s');
        _lastErrorMessage = 'Error solicitando $description: ${e.toString()}';
        return false;
      }
    }

    try {
      // Solicitar todas las partes de la configuración
      final ownerReceived = await request(admin.AdminMessage()..getOwnerRequest = true, (m) => m.hasGetOwnerResponse(), "OwnerInfo");
      receivedAnyResponse = receivedAnyResponse || ownerReceived;

      // DEVICE_CONFIG (aunque no lo usemos directamente en cfgOut, puede ser necesario para el firmware)
      final deviceCfgReceived = await request(admin.AdminMessage()..getConfigRequest = admin.AdminMessage_ConfigType.DEVICE_CONFIG, (m) => m.hasGetConfigResponse() && m.getConfigResponse.hasDevice(), "DeviceConfig");
      receivedAnyResponse = receivedAnyResponse || deviceCfgReceived;
      
      // Canales: intentar con el canal 0 (por defecto) y luego el índice actual si existe y es válido.
      final indicesToQuery = <int>{0}; 
      if (cfgOut.channelIndex > 0 && cfgOut.channelIndex <= 8) { 
           indicesToQuery.add(cfgOut.channelIndex);
      }
      
      for (final index in indicesToQuery) {
        if (primaryChannelCaptured && index != 0 && index != cfgOut.channelIndex) continue; 
        final channelReceived = await request(admin.AdminMessage()..getChannelRequest = index, (m) => m.hasGetChannelResponse() && m.getChannelResponse.index == index, "Channel $index");
        receivedAnyResponse = receivedAnyResponse || channelReceived;
        if (primaryChannelCaptured && cfgOut.channelIndex == index) break; 
      }
      
      final serialReceived = await request(admin.AdminMessage()..getModuleConfigRequest = admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG, (m) => m.hasGetModuleConfigResponse() && m.getModuleConfigResponse.hasSerial(), "SerialConfig");
      receivedAnyResponse = receivedAnyResponse || serialReceived;

      final loraReceived = await request(admin.AdminMessage()..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG, (m) => m.hasGetConfigResponse() && m.getConfigResponse.hasLora() && m.getConfigResponse.lora.hasRegion(), "LoRaConfig");
      receivedAnyResponse = receivedAnyResponse || loraReceived;

      if (!receivedAnyResponse && ownerReceived) { // Si solo obtuvimos owner, puede ser un nodo no completamente configurado.
         print('[UsbService] readConfig: Solo se recibió OwnerInfo. El nodo podría no estar completamente configurado.');
      } else if (!receivedAnyResponse) {
        print('[UsbService] readConfig: No se recibió ninguna respuesta de configuración válida de las solicitudes principales.');
        _lastErrorMessage = 'No se recibió respuesta de configuración del nodo.';
        // No lanzar excepción aquí, devolver cfgOut parcialmente poblado o vacío.
        // La UI deberá manejar un NodeConfig incompleto.
      }
    } finally {
      await subscription.cancel(); // Muy importante cancelar la suscripción general.
      print('[UsbService] readConfig: Suscripción de _consumeFrame cancelada.');
    }
    
    print('[UsbService] Lectura de configuración completada. Config leída: ${cfgOut.toString()}'); // Añadir un método toStringRepresentation a NodeConfig
    return cfgOut;
  }

  // Escribe la configuración al nodo.
  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_port == null) {
      print('[UsbService] writeConfig abortado: puerto USB nulo.');
      _lastErrorMessage = 'Puerto USB no conectado para escribir configuración.';
      return;
    }
    try {
      await _ensureMyNodeNum();
    } catch (e, s) {
      print('[UsbService] writeConfig falló en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage = 'Error al obtener NodeNum para escribir config: ${e.toString()}';
      return;
    }
    
    print('[UsbService] Iniciando escritura de configuración para el nodo $_myNodeNum...');

    try {
      // Nombres del nodo
      final userMsg = mesh.User()
        ..shortName = cfgIn.shortName
        ..longName = cfgIn.longName;
      await _sendAdmin(admin.AdminMessage()..setOwner = userMsg, description: "SetOwner (Nombres)");

      // Canal (solo primario)
      final settings = ch.ChannelSettings()
        ..name = "CH${cfgIn.channelIndex}" // Nombre descriptivo
        ..psk = cfgIn.key;
      final channel = ch.Channel()
        ..index = cfgIn.channelIndex
        ..role = ch.Channel_Role.PRIMARY 
        ..settings = settings;
      await _sendAdmin(admin.AdminMessage()..setChannel = channel, description: "SetChannel (Índice ${cfgIn.channelIndex})");

      // Configuración Serial
      final serialCfg = mod.ModuleConfig_SerialConfig()
        ..enabled = true // Asumimos habilitado si se configura
        ..baud = cfgIn.baudRate
        ..mode = _serialModeFromString(cfgIn.serialModeAsString);
      final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
      await _sendAdmin(admin.AdminMessage()..setModuleConfig = moduleCfg, description: "SetModuleConfig (Serial)");

      // Configuración LoRa (Región)
      final lora = cfg.Config_LoRaConfig()
        ..region = _regionFromString(cfgIn.frequencyRegionAsString);
      final configMsg = cfg.Config()..lora = lora;
      await _sendAdmin(admin.AdminMessage()..setConfig = configMsg, description: "SetConfig (LoRa)");
      
      print('[UsbService] Escritura de configuración: todos los comandos enviados al nodo $_myNodeNum.');
      // Considerar un "commit" o "reboot" si el firmware lo soporta/requiere tras cambios.
      // await _sendAdmin(admin.AdminMessage()..commitEditSettings = true, description: "CommitEditSettings");
      // await _sendAdmin(admin.AdminMessage()..rebootSeconds = 5, description: "RebootNode");


    } catch (e,s) {
      print('[UsbService] Error durante writeConfig: $e. Stack: $s');
      _lastErrorMessage = 'Error al escribir configuración: ${e.toString()}';
      // No relanzar para permitir que la UI maneje el error.
    }
  }

  // Envía un AdminMessage (sin esperar respuesta específica más allá del ACK implícito de _wrapAdmin).
  Future<void> _sendAdmin(admin.AdminMessage msg, {String? description}) async {
    final port = _port;
    if (port == null) {
      print('[UsbService] _sendAdmin (${description ?? msg.info_.messageName}) abortado: puerto USB nulo.');
      throw StateError('Puerto USB nulo al intentar enviar AdminMessage.');
    }
    final toRadioMsg = _wrapAdmin(msg);
    final type = description ?? msg.info_.messageName;
    print("[UsbService] Enviando AdminMessage: '$type' a NodeNum: ${_myNodeNum}, PacketID: ${toRadioMsg.packet.id}");
    try {
        await port.write(StreamFraming.frame(toRadioMsg.writeToBuffer()));
    } catch (e,s) {
        print("[UsbService] Error enviando AdminMessage ('$type') al puerto USB: $e. Stack: $s");
        throw StateError("Error al escribir AdminMessage ('$type') en puerto USB: ${e.toString()}");
    }
  }

  // Envía un AdminMessage y espera una respuesta específica que cumpla con el `matcher`.
  Future<void> _sendAdminAndWait({
    required admin.AdminMessage msg,
    required bool Function(admin.AdminMessage) matcher,
    required Duration timeout, // Hacer timeout explícito
    String? description,
  }) {
    final toRadioMsg = _wrapAdmin(msg); // _wrapAdmin ya valida _myNodeNum
    final type = description ?? msg.info_.messageName;
    print("[UsbService] Enviando AdminMessage ('$type') y esperando respuesta... (NodeNum: ${_myNodeNum}, PacketID: ${toRadioMsg.packet.id})");
    return _sendToRadioAndWait(
      to: toRadioMsg,
      matcher: matcher,
      timeout: timeout,
      description: type,
    );
  }

  // Lógica genérica para enviar un ToRadio y esperar una respuesta específica vía AdminMessage.
  Future<void> _sendToRadioAndWait({
    required mesh.ToRadio to,
    required bool Function(admin.AdminMessage) matcher,
    required Duration timeout,
    String? description, // Para logging
  }) async {
    final port = _port;
    final controller = _frameController;
    if (port == null || controller == null || controller.isClosed) {
      final reason = port == null ? "puerto nulo" : "frameController nulo o cerrado";
      print("[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}') abortado: $reason.");
      throw StateError('Puerto USB o stream no disponible para SendAndWait ($reason).');
    }

    final completer = Completer<void>();
    var commandSent = false; 
    Future<void>? cancelSubFuture; // Para cancelar la suscripción
    late StreamSubscription<mesh.FromRadio> sub;

    sub = controller.stream.listen((frame) {
      if (!commandSent || completer.isCompleted) return; // No procesar hasta enviar o si ya completó
      
      final adminMsg = _decodeAdminMessage(frame);
      if (adminMsg == null) return; // No es un AdminMessage válido
      
      // print("[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): AdminMessage recibido en stream: ${adminMsg.info_.messageName}"); // Verboso
      if (matcher(adminMsg)) {
        print("[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): ¡Respuesta coincidente encontrada!");
        if (!completer.isCompleted) completer.complete();
        cancelSubFuture ??= sub.cancel(); // Cancelar lo antes posible
      }
    });

    try {
      // Primero enviar el comando
      await port.write(StreamFraming.frame(to.writeToBuffer()));
      commandSent = true; // Marcar que el comando fue enviado
      print("[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): Comando enviado. Esperando respuesta por ${timeout.inMilliseconds}ms.");
      
      // Esperar a que el completer se complete o timeout
      await completer.future.timeout(timeout);
    } on TimeoutException {
      print("[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): Timeout esperando respuesta específica.");
      if (!completer.isCompleted) { // Si el timeout vino del await en completer.future
          _lastErrorMessage = "Timeout esperando respuesta para '${description ?? "comando"}'.";
      }
      throw TimeoutException("Timeout esperando respuesta específica para '${description ?? "comando"}'.");
    } finally {
      // Asegurarse de que la suscripción se cancele, incluso si hubo otros errores.
      await (cancelSubFuture ?? sub.cancel());
      // print("[UsbService] _sendToRadioAndWait ('${description ?? "N/A"}'): Suscripción de escucha cancelada."); // Verboso
    }
  }

  // Decodifica un FromRadio a AdminMessage si es aplicable.
  admin.AdminMessage? _decodeAdminMessage(mesh.FromRadio frame) {
    if (!frame.hasPacket()) return null;
    final packet = frame.packet;
    if (!packet.hasDecoded()) return null;
    final decoded = packet.decoded;
    // Solo nos interesan los paquetes ADMIN_APP
    if (decoded.portnum != port.PortNum.ADMIN_APP) return null; 
    if (!decoded.hasPayload()) return null;
    
    final payload = decoded.payload;
    if (payload.isEmpty) return null;
    try {
      return admin.AdminMessage.fromBuffer(payload);
    } catch (e,s) {
      print('[UsbService] Error al deserializar AdminMessage desde payload: $e. Payload (hex): ${payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}. Stack: $s');
      return null;
    }
  }
  
  // ------- Funciones Helper para Enums <-> String (Mantenidas según tu preferencia) -------
  cfg.Config_LoRaConfig_RegionCode _regionFromString(String s) {
    switch (s) {
      case '433':
        return cfg.Config_LoRaConfig_RegionCode.EU_433;
      case '915':
        return cfg.Config_LoRaConfig_RegionCode.US;
      case '868':
      default: // Por defecto EU_868 si no coincide
        return cfg.Config_LoRaConfig_RegionCode.EU_868;
    }
  }

  mod.ModuleConfig_SerialConfig_Serial_Mode _serialModeFromString(String s) {
    switch (s.toUpperCase()) {
      case 'PROTO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
      case 'TEXTMSG': // Añadido para que sea una opción válida
        return mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
      case 'TLL': // Mapeo personalizado: TLL en UI -> NMEA para el firmware
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'NMEA': // Directo si se usa NMEA en UI
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'WPL': // Mapeo personalizado: WPL en UI -> CALTOPO para el firmware
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      case 'CALTOPO': // Directo si se usa CALTOPO en UI
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      default:
        return mod.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }
}

// Considera añadir esto a tu NodeConfig para facilitar el logging:
/*
extension NodeConfigToString on NodeConfig {
  String toStringRepresentation() {
    return 'NodeConfig(shortName: $shortName, longName: $longName, channelIndex: $channelIndex, keyLength: ${key.length}, serialMode: $serialModeAsString, baudRate: $baudRate, freqRegion: $frequencyRegionAsString)';
  }
}
*/
