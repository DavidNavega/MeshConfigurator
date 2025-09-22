import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/node_config.dart';
import 'ble_uuids.dart';

// Protobuf 2.6.1
import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:Buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:Buoys_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:Buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

class BluetoothService {
  BluetoothDevice? _dev;
  BluetoothCharacteristic? _toRadio;
  BluetoothCharacteristic? _fromRadio;
  BluetoothCharacteristic? _fromNum;

  StreamController<mesh.FromRadio>? _fromRadioController;
  StreamSubscription<List<int>>? _fromRadioSubscription;
  StreamSubscription<List<int>>? _fromNumSubscription;
  StreamQueue<mesh.FromRadio>? _fromRadioQueue;

  Completer<void>? _pendingRequest;

  int _lastFromNum = 0;
  int? _myNodeNum;
  bool _nodeNumConfirmed = false;

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);

  int? get myNodeNum => _myNodeNum;
  set myNodeNum(int? value) {
    _myNodeNum = value;
    _nodeNumConfirmed = false;
  }


  // -------- permisos ----------
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // -------- streams ----------
  Future<void> _disposeRadioStreams() async {
    await _fromNumSubscription?.cancel();
    _fromNumSubscription = null;
    await _fromRadioSubscription?.cancel();
    _fromRadioSubscription = null;
    await _fromRadioQueue?.cancel();
    _fromRadioQueue = null;
    await _fromRadioController?.close();
    _fromRadioController = null;
  }

  Future<void> _initializeFromRadioNotifications() async {
    final characteristic = _fromRadio;
    if (characteristic == null) return;

    await _disposeRadioStreams();

    _fromRadioController = StreamController<mesh.FromRadio>.broadcast();
    _fromRadioQueue = StreamQueue(_fromRadioController!.stream);

    if (characteristic.properties.notify) {
      try {
        await characteristic.setNotifyValue(true);
      } catch (_) {}
    }

    _fromRadioSubscription = characteristic.onValueReceived.listen(
          (data) {
        if (data.isEmpty) return;
        try {
          final frame = mesh.FromRadio.fromBuffer(data);
          _captureMyNodeNum(frame);
          final controller = _fromRadioController;
          if (controller == null || controller.isClosed) return;
          controller.add(frame);
        } catch (err, st) {
          final controller = _fromRadioController;
          if (controller == null || controller.isClosed) return;
          controller.addError(err, st);
        }
      },
      onError: (err, st) {
        final controller = _fromRadioController;
        if (controller == null || controller.isClosed) return;
        controller.addError(err, st);
      },
    );
  }

  Future<void> _initializeFromNumNotifications() async {
    final characteristic = _fromNum;
    if (characteristic == null) return;

    await _fromNumSubscription?.cancel();
    _fromNumSubscription = null;

    _lastFromNum = 0;

    if (!characteristic.properties.notify) return;

    try {
      await characteristic.setNotifyValue(true);
    } catch (_) {}

    late final StreamSubscription<List<int>> subscription;
    subscription = characteristic.onValueReceived.listen(
          (data) {
        subscription.pause();
        _handleFromNumNotification(data).whenComplete(() {
          try {
            if (subscription.isPaused) {
              subscription.resume();
            }
          } catch (_) {}
        });
      },
      onError: (err, st) {
        final controller = _fromRadioController;
        if (controller == null || controller.isClosed) return;
        controller.addError(err, st);
      },
    );

    _fromNumSubscription = subscription;
  }

  Future<void> _handleFromNumNotification(List<int> data) async {
    if (data.isEmpty) return;

    if (data.length < 4) return;

    final current = _decodeLittleEndian(data.sublist(0, 4));
    final pending = (current - _lastFromNum) & 0xFFFFFFFF;
    if (pending == 0) {
      _lastFromNum = current;
      return;
    }

    final radioCharacteristic = _fromRadio;
    final controller = _fromRadioController;
    if (radioCharacteristic == null || controller == null || controller.isClosed) {
      return;
    }

    var processed = 0;
    for (var i = 0; i < pending; i++) {
      if (controller.isClosed) break;
      List<int> raw;
      try {
        raw = await radioCharacteristic.read();
      } catch (err, st) {
        if (!controller.isClosed) {
          controller.addError(err, st);
        }
        break;
      }

      processed++;

      if (raw.isEmpty) {
        continue;
      }

      try {
        final frame = mesh.FromRadio.fromBuffer(raw);
        _captureMyNodeNum(frame);
        if (!controller.isClosed) {
          controller.add(frame);
        }
      } catch (err, st) {
        if (!controller.isClosed) {
          controller.addError(err, st);
        }
      }
    }

    if (processed == pending) {
      _lastFromNum = current;
    }
  }

  int _decodeLittleEndian(List<int> bytes) {
    var value = 0;
    for (var i = 0; i < bytes.length; i++) {
      value |= (bytes[i] & 0xff) << (8 * i);
    }
    return value;
  }

  // -------- exclusión de petición ----------
  Future<T> _withRequestLock<T>(Future<T> Function() action) async {
    while (_pendingRequest != null) {
      try {
        await _pendingRequest!.future;
      } catch (_) {
        break;
      }
    }
    final completer = Completer<void>();
    _pendingRequest = completer;
    try {
      return await action();
    } finally {
      _pendingRequest = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  // -------- recolector de respuestas ----------
  Future<List<mesh.FromRadio>> _collectResponses({
    required bool Function(List<mesh.FromRadio>) isComplete,
    Duration timeout = _defaultResponseTimeout,
  }) async {
    final queue = _fromRadioQueue;
    if (queue == null) throw StateError('Radio stream not initialized');

    final responses = <mesh.FromRadio>[];
    final stopwatch = Stopwatch()..start();

    while (true) {
      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Timeout waiting for radio response');
      }

      mesh.FromRadio frame;
      try {
        frame = await queue.next.timeout(remaining);
      } on TimeoutException {
        throw TimeoutException('Timeout waiting for radio response');
      } on StateError {
        if (responses.isEmpty) rethrow;
        return responses;
      } catch (_) {
        continue;
      }

      responses.add(frame);
      _captureMyNodeNum(frame);

      if (isComplete(responses)) {

        final post = Stopwatch()..start();
        while (post.elapsed < _postResponseWindow) {
          final postRemaining = _postResponseWindow - post.elapsed;
          if (postRemaining <= Duration.zero) break;

          final totalRemaining = timeout - stopwatch.elapsed;
          if (totalRemaining <= Duration.zero) break;

          final waitFor =
          postRemaining <= totalRemaining ? postRemaining : totalRemaining;

          try {
            final extra = await queue.next.timeout(waitFor);
            responses.add(extra);
          } on TimeoutException {
            break;
          } on StateError {
            break;
          } catch (_) {
            break;
          }
        }

        return responses;
      }
    }
  }

  bool _isAckOrResponseFrame(mesh.FromRadio frame) {
    return frame.hasPacket() && frame.packet.hasDecoded();
  }

  void _captureMyNodeNum(mesh.FromRadio frame) {
    if (frame.hasMyInfo() && frame.myInfo.hasMyNodeNum()) {
      final newNum = frame.myInfo.myNodeNum;
      if (_myNodeNum != newNum) {
        print('[BluetoothService] MyNodeNum capturado/actualizado: $_myNodeNum -> $newNum');
        _myNodeNum = newNum;
        _nodeNumConfirmed = true; // Confirmar al capturar/actualizar
      } else if (!_nodeNumConfirmed) {
        // Si es el mismo número pero no estaba confirmado (ej. primera vez que se recibe)
        print('[BluetoothService] MyNodeNum re-confirmado: $newNum');
        _nodeNumConfirmed = true;
      }
      // Si ya estaba confirmado y el número es el mismo, no es necesario loguear nada.
    }
  }

  Future<void> _ensureMyNodeNum() async {
    if (_nodeNumConfirmed && _myNodeNum != null) {
      // print('[BluetoothService] _ensureMyNodeNum: MyNodeNum ya confirmado: $_myNodeNum'); // Verboso
      return;
    }
    print('[BluetoothService] Asegurando MyNodeNum (estado actual: confirmado=$_nodeNumConfirmed, num=$_myNodeNum)...');

    final toCharacteristic = _toRadio;
    // Corregir el nombre de la variable para que coincida con la instancia de la clase
    final fromRadioControllerInstance = _fromRadioController; 

    if (toCharacteristic == null || fromRadioControllerInstance == null || fromRadioControllerInstance.isClosed) {
      print('[BluetoothService] _ensureMyNodeNum falló: Características BLE no disponibles o stream cerrado.');
      throw StateError('Características BLE no disponibles o stream de FromRadio cerrado para _ensureMyNodeNum.');
    }

    try {
      await _withRequestLock(() async {
        if (_nodeNumConfirmed && _myNodeNum != null) return; // Doble chequeo dentro del lock

        print('[BluetoothService] _ensureMyNodeNum: Creando futuro para MyInfo...');
        final infoFuture = fromRadioControllerInstance.stream
            .where((frame) => frame.hasMyInfo() && frame.myInfo.hasMyNodeNum())
            .map((frame) {
              // print('[BluetoothService] _ensureMyNodeNum: MyInfo recibido en stream: NodeNum ${frame.myInfo.myNodeNum}'); // Verboso
              return frame.myInfo.myNodeNum;
            })
            .first
            .timeout(_defaultResponseTimeout, onTimeout: () {
              print('[BluetoothService] Timeout (_defaultResponseTimeout) esperando MyInfo en el stream durante _ensureMyNodeNum.');
              throw TimeoutException('Timeout esperando MyNodeInfo del radio (stream) en _ensureMyNodeNum.');
            });

        final toRadioPacket = mesh.ToRadio()
          ..wantConfigId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF; // ID aleatorio
        
        print('[BluetoothService] _ensureMyNodeNum: Enviando solicitud de MyInfo (wantConfigId: ${toRadioPacket.wantConfigId}).');
        await _writeToRadio(toCharacteristic, toRadioPacket.writeToBuffer());

        final nodeNum = await infoFuture;
        // _captureMyNodeNum ya se llama en el listener general de _fromRadioSubscription,
        // por lo que _myNodeNum y _nodeNumConfirmed deberían actualizarse automáticamente.
        // Aquí solo re-confirmamos o actualizamos por si acaso.
        if (_myNodeNum != nodeNum) {
            print('[BluetoothService] _ensureMyNodeNum: MyNodeNum obtenido del futuro: $nodeNum (anterior: $_myNodeNum).');
            _myNodeNum = nodeNum;
        }
        _nodeNumConfirmed = true;
        print('[BluetoothService] _ensureMyNodeNum: MyNodeNum asegurado y confirmado: $_myNodeNum.');
      });
    } on TimeoutException catch(e) {
      // El timeout puede venir del .timeout en el stream o del lock si la acción entera tarda mucho.
      print('[BluetoothService] _ensureMyNodeNum falló por TimeoutException: ${e.message}');
      throw TimeoutException('No se recibió MyNodeInfo del radio (timeout global en _ensureMyNodeNum): ${e.message}');
    } catch (e, s) {
      print('[BluetoothService] _ensureMyNodeNum falló con error inesperado: $e. Stack: $s');
      throw StateError('Error inesperado obteniendo MyNodeInfo en _ensureMyNodeNum: ${e.toString()}');
    }

    if (_myNodeNum == null) {
      print('[BluetoothService] _ensureMyNodeNum falló críticamente: No se pudo determinar el NodeNum del radio después del intento.');
      throw StateError('No se pudo determinar el NodeNum del radio tras _ensureMyNodeNum.');
    }
  }

  // -------- empaquetador: AdminMessage -> MeshPacket.decoded ----------
  mesh.ToRadio _wrapAdminToToRadio(admin.AdminMessage msg) {
    final nodeNum = _myNodeNum;
    if (nodeNum == null) {
      print('[BluetoothService] CRÍTICO: _wrapAdminToToRadio llamado pero _myNodeNum es nulo. El paquete no será dirigido correctamente.');
      // Es crucial tener myNodeNum para dirigir el paquete.
      throw StateError('_myNodeNum no inicializado. Llama a _ensureMyNodeNum antes de enviar comandos administrativos.');
    }
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer()
      ..wantResponse = true; // Generalmente queremos respuesta para mensajes admin

    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;
    // print('[BluetoothService] _wrapAdminToToRadio: Creando paquete para NodeNum $nodeNum con ID $packetId para ${msg.info_.messageName}'); // Verboso

    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..to = nodeNum // Dirigido a nuestro nodo
        ..from = 0 // Usar 0 (Broadcast addr) o un ID específico de app. Firmware suele ignorarlo para AdminApp.
        ..id = packetId // ID de paquete único
        ..priority = mesh.MeshPacket_Priority.RELIABLE // Queremos que los comandos admin lleguen
        ..wantAck = true // Solicitar ACK del radio
        ..decoded = data);
  }

  // -------- envío + recepción ----------
  Future<List<mesh.FromRadio>> _sendAndReceive(
    mesh.ToRadio toRadioMsg, {
    bool Function(List<mesh.FromRadio>)? isComplete,
    Duration timeout = _defaultResponseTimeout,
  }) {
    return _withRequestLock(() async {
      final toCharacteristic = _toRadio;
      if (toCharacteristic == null) {
        print('[BluetoothService] _sendAndReceive falló: Característica de escritura BLE (_toRadio) no disponible.');
        throw StateError('Característica de escritura BLE no disponible.');
      }

      // print('[BluetoothService] _sendAndReceive: Enviando paquete ToRadio con ID ${toRadioMsg.hasPacket() ? toRadioMsg.packet.id : "N/A"}'); // Verboso

      try {
        // Intento de escritura inicial (se delega a _writeToRadio que ya maneja los reintentos con/sin respuesta)
        await _writeToRadio(toCharacteristic, toRadioMsg.writeToBuffer());
        // print('[BluetoothService] _sendAndReceive: Paquete enviado correctamente.'); // Verboso
      } catch (e, s) {
        print('[BluetoothService] _sendAndReceive: Error al escribir en _toRadio: $e. Stack: $s');
        // Relanzar para que sea manejado por el que llama o simplemente no continuar con la recolección de respuestas.
        throw StateError('Error al escribir en la característica BLE: ${e.toString()}');
      }

      var ackSeen = false;
      var userSatisfied = false;

      try {
        // print('[BluetoothService] _sendAndReceive: Comenzando a recolectar respuestas...'); // Verboso
        return await _collectResponses(
          isComplete: (responses) {
            ackSeen = responses.any(_isAckOrResponseFrame); 
            userSatisfied = isComplete?.call(responses) ?? true;
            // if(ackSeen) print('[BluetoothService] _sendAndReceive: ACK recibido.'); // Verboso
            // if(userSatisfied) print('[BluetoothService] _sendAndReceive: Condición de usuario satisfecha.'); // Verboso
            return ackSeen && userSatisfied;
          },
          timeout: timeout,
        );
      } on TimeoutException catch (e) {
        final packetIdForLog = toRadioMsg.hasPacket() ? toRadioMsg.packet.id : "N/A";
        if (!ackSeen) {
          print('[BluetoothService] _sendAndReceive: Timeout (${timeout.inSeconds}s) esperando ACK del radio para el paquete ToRadio con ID $packetIdForLog.');
          throw TimeoutException('Timeout esperando ACK del radio: ${e.message}');
        }
        print('[BluetoothService] _sendAndReceive: Timeout (${timeout.inSeconds}s) esperando respuesta completa del radio para el paquete ToRadio con ID $packetIdForLog (ACK fue recibido).');
        throw TimeoutException('Timeout esperando respuesta completa del radio (ACK recibido): ${e.message}');
      } catch (e, s) {
        print('[BluetoothService] _sendAndReceive: Error durante _collectResponses: $e. Stack: $s');
        throw StateError('Error inesperado durante la recolección de respuestas: ${e.toString()}');
      }
    });
  }

  Future<void> _writeToRadio(
      BluetoothCharacteristic characteristic, List<int> payload) async {
    final supportsWriteWithoutResponse =
        characteristic.properties.writeWithoutResponse;
    final supportsWriteWithResponse = characteristic.properties.write;

    final attempts = <bool>[];
    if (supportsWriteWithoutResponse) {
      attempts.add(true);
    }
    if (supportsWriteWithResponse) {
      attempts.add(false);
    }

    if (attempts.isEmpty) {
      throw StateError('Characteristic does not support write operations');
    }

    FlutterBluePlusException? lastWriteNotPermitted;
    for (final withoutResponse in attempts) {
      try {
        await characteristic.write(
          payload,
          withoutResponse: withoutResponse,
        );
        return;
      } on FlutterBluePlusException catch (err) {
        if (_isWriteNotPermittedError(err)) {
          lastWriteNotPermitted = err;
          continue;
        }
        rethrow;
      }
    }

    if (lastWriteNotPermitted != null &&
        attempts.length == 1 &&
        attempts.first == false) {
      try {
        await characteristic.write(
          payload,
          withoutResponse: true,
        );
        return;
      } on FlutterBluePlusException catch (err) {
        if (_isWriteNotPermittedError(err)) {
          lastWriteNotPermitted = err;
        } else {
          rethrow;
        }
      }
    }

    if (lastWriteNotPermitted != null) {
      throw lastWriteNotPermitted;
    }

    throw StateError('Failed to write to characteristic');
  }

  bool _isWriteNotPermittedError(FlutterBluePlusException err) {
    final message = err.description?.toLowerCase() ?? '';
    return message.contains('write not permitted');
  }

  // -------- conexión ----------
  Future<bool> connectAndInit() async {
    if (!await _ensurePermissions()) return false;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    BluetoothDevice? found;

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final platformName = r.device.platformName;
        if (platformName.isEmpty) {
          continue;
        }
        final name = platformName.toUpperCase();
        if (name.contains('MESHTASTIC') ||
            name.contains('TBEAM') ||
            name.contains('HELTEC') ||
            name.contains('XIAO')) {
          found = r.device;
          break;
        }
      }
      if (found != null) break;
    }
    await FlutterBluePlus.stopScan();

    if (found == null) return false;

    _dev = found;
    await _dev!.connect(autoConnect: false);
    try {
      await _dev!.requestMtu(512);
    } catch (_) {}

    final services = await _dev!.discoverServices();
    for (final s in services) {
      if (s.uuid == MeshUuids.service) {
        for (final c in s.characteristics) {
          if (c.uuid == MeshUuids.toRadio) _toRadio = c;
          if (c.uuid == MeshUuids.fromRadio) _fromRadio = c;
          if (c.uuid == MeshUuids.fromNum) _fromNum = c;
        }
      }
    }

    if (_toRadio == null || _fromRadio == null || _fromNum == null) {
      try {
        await _dev!.disconnect();
      } catch (_) {}
      return false;
    }

    _lastFromNum = 0;
    await _initializeFromRadioNotifications();
    await _initializeFromNumNotifications();
    await _ensureMyNodeNum();

    return true;
  }

  Future<void> disconnect() async {
    try {
      await _fromRadio?.setNotifyValue(false);
    } catch (_) {}
    try {
      await _fromNum?.setNotifyValue(false);
    } catch (_) {}

    await _disposeRadioStreams();

    try {
      await _dev?.disconnect();
    } catch (_) {}

    _dev = null;
    _toRadio = null;
    _fromRadio = null;
    _fromNum = null;
    _lastFromNum = 0;
    _myNodeNum = null;
    _nodeNumConfirmed = false;
  }

  // -------- lectura de configuración ----------
  Future<NodeConfig?> readConfig() async {
    if (_toRadio == null || _fromRadioQueue == null) {
      print('[BluetoothService] readConfig abortado: características BLE no inicializadas (toRadio o fromRadioQueue nulos).');
      // Considerar lanzar un error o devolver un Future.error si es más apropiado para el que llama.
      return null;
    }

    try {
      await _ensureMyNodeNum(); // Asegura que tenemos el NodeNum antes de proceder
    } catch (e, s) {
      print('[BluetoothService] readConfig falló en _ensureMyNodeNum: $e. Stack: $s');
      // Aquí se podría establecer un _lastErrorMessage si se implementa en BluetoothService.
      // Por ahora, solo relanzamos o devolvemos null, dependiendo de la severidad deseada.
      // Devolver null es consistente con la signatura de la función.
      throw StateError('Error al obtener NodeNum para leer config: ${e.toString()}');
    }
    
    print('[BluetoothService] Iniciando lectura de configuración del nodo $_myNodeNum...');
    final cfgOut = NodeConfig(); // Objeto para almacenar la configuración leída

    var primaryChannelCaptured = false; 
    var primaryChannelLogged = false; // Usado para loguear la captura del canal primario solo una vez

    void _applyAdminToConfig(admin.AdminMessage message) {
      // Descomentar si se necesita un log detallado de cada tipo de mensaje procesado:
      // print('[BluetoothService] readConfig._applyAdminToConfig: Procesando ${message.info_.messageName}');

      if (message.hasGetOwnerResponse()) {
        final user = message.getOwnerResponse;
        if (user.hasLongName()) cfgOut.longName = user.longName;
        if (user.hasShortName()) cfgOut.shortName = user.shortName;
        // print('[BluetoothService] readConfig._applyAdminToConfig: Owner info aplicada (LongName: ${cfgOut.longName}, ShortName: ${cfgOut.shortName})'); // Verboso
      }

      if (message.hasGetChannelResponse()) {
        final channel = message.getChannelResponse;
        final isPrimary = channel.role == ch.Channel_Role.PRIMARY;

        if (isPrimary || !primaryChannelCaptured) {
          if (channel.hasIndex()) cfgOut.channelIndex = channel.index;
          if (channel.hasSettings() && channel.settings.hasPsk()) {
            cfgOut.key = Uint8List.fromList(channel.settings.psk);
          }
          // print('[BluetoothService] readConfig._applyAdminToConfig: Channel info (index: ${channel.index}, role: ${channel.role}) aplicada a cfgOut (ChannelIndex: ${cfgOut.channelIndex}, KeyLength: ${cfgOut.key.length})'); // Verboso
        }

        if (isPrimary) {
          primaryChannelCaptured = true;
          if (!primaryChannelLogged) {
            primaryChannelLogged = true;
            print('[BluetoothService] readConfig: Canal PRIMARIO ${cfgOut.channelIndex} capturado con PSK (longitud: ${cfgOut.key.length} bytes).');
          }
        }
      }

      if (message.hasGetModuleConfigResponse() && message.getModuleConfigResponse.hasSerial()) {
        final serial = message.getModuleConfigResponse.serial;
        if (serial.hasMode()) cfgOut.serialOutputMode = serial.mode;
        if (serial.hasBaud()) cfgOut.baudRate = serial.baud;
        // print('[BluetoothService] readConfig._applyAdminToConfig: SerialConfig aplicada (Mode: ${cfgOut.serialOutputMode}, Baud: ${cfgOut.baudRate})'); // Verboso
      }

      if (message.hasGetConfigResponse() && 
          message.getConfigResponse.hasLora() && 
          message.getConfigResponse.lora.hasRegion()) {
        cfgOut.frequencyRegion = message.getConfigResponse.lora.region;
        // print('[BluetoothService] readConfig._applyAdminToConfig: LoRaConfig (Region: ${cfgOut.frequencyRegion}) aplicada.'); // Verboso
      }
    }

    Future<bool> _requestAndApply(
      admin.AdminMessage msgToSend,
      bool Function(admin.AdminMessage) matcher,
      String description, // Añadido para logging descriptivo
    ) async {
      print('[BluetoothService] readConfig: Solicitando $description...');
      List<mesh.FromRadio> frames;
      try {
        frames = await _sendAndReceive(
          _wrapAdminToToRadio(msgToSend),
          isComplete: (responses) => responses.any((fr) {
            final adminMsg = _decodeAdminMessage(fr);
            // print('[BluetoothService] readConfig._requestAndApply.isComplete: Verificando frame para $description. AdminMsg: ${adminMsg != null ? adminMsg.info_.messageName : "null"}'); // Verboso
            return adminMsg != null && matcher(adminMsg);
          }),
          timeout: _defaultResponseTimeout, // Usar el timeout por defecto para cada solicitud
        );
        print('[BluetoothService] readConfig: Respuesta(s) recibida(s) para $description.');
      } on TimeoutException catch (e) {
        print('[BluetoothService] readConfig: Timeout (_defaultResponseTimeout) esperando $description. Error: ${e.message}');
        return false; // Indica que la solicitud específica falló por timeout
      } catch (e, s) {
        print('[BluetoothService] readConfig: Error durante _sendAndReceive para $description: $e. Stack: $s');
        return false; // Indica que la solicitud específica falló por otro error
      }

      var matched = false;
      for (final f in frames) {
        final adminMsg = _decodeAdminMessage(f);
        if (adminMsg == null) {
          // print('[BluetoothService] readConfig._requestAndApply: Frame ignorado (no es AdminMessage) al procesar respuesta para $description.'); // Verboso
          continue;
        }
        // print('[BluetoothService] readConfig._requestAndApply: Procesando AdminMessage ${adminMsg.info_.messageName} para $description.'); // Verboso
        
        _applyAdminToConfig(adminMsg); 

        if (matcher(adminMsg)) {
          // print('[BluetoothService] readConfig._requestAndApply: Match encontrado para $description con ${adminMsg.info_.messageName}.'); // Verboso
          matched = true;
        }
      }
      if (!matched) {
          print('[BluetoothService] readConfig: No se encontró un match específico para $description en las respuestas recibidas.');
      }
      return matched; 
    }

    var receivedAnyResponse = false;

    // Solicitar Owner Info
    final ownerReceived = await _requestAndApply(
      admin.AdminMessage()..getOwnerRequest = true,
      (msg) => msg.hasGetOwnerResponse(),
      'información del propietario (Owner Info)',
    );
    if (ownerReceived) receivedAnyResponse = true;

    // Solicitar LoRa Config (específicamente para la región)
    final loraReceived = await _requestAndApply(
      admin.AdminMessage()..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
      (msg) => msg.hasGetConfigResponse() && msg.getConfigResponse.hasLora() && msg.getConfigResponse.lora.hasRegion(),
      'configuración LoRa (para región)',
    );
    if (loraReceived) receivedAnyResponse = true;

    // Solicitar Canales
    final indicesToQuery = <int>{};
    if (cfgOut.channelIndex > 0 && cfgOut.channelIndex <= 8) { 
      indicesToQuery.add(cfgOut.channelIndex);
    }
    if (!primaryChannelCaptured) {
      indicesToQuery.addAll([0, 1, 2]); 
    }

    for (final index in indicesToQuery) {
      if (primaryChannelCaptured) break; 
      final channelReceived = await _requestAndApply(
        admin.AdminMessage()..getChannelRequest = index,
        (msg) => msg.hasGetChannelResponse() && msg.getChannelResponse.index == index,
        'canal con índice $index',
      );
      if (channelReceived) receivedAnyResponse = true;
    }
    
    if (!primaryChannelCaptured && cfgOut.key.isEmpty) {
        print('[BluetoothService] readConfig: No se capturó canal primario, intentando consulta explícita por canal 0.');
        final channelZeroReceived = await _requestAndApply(
          admin.AdminMessage()..getChannelRequest = 0, 
          (msg) => msg.hasGetChannelResponse(), 
          'canal con índice 0 (intento adicional)',
        );
        if (channelZeroReceived) receivedAnyResponse = true;
    }

    // Solicitar Serial Config
    final serialReceived = await _requestAndApply(
      admin.AdminMessage()..getModuleConfigRequest = admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
      (msg) => msg.hasGetModuleConfigResponse() && msg.getModuleConfigResponse.hasSerial(),
      'configuración del módulo Serial',
    );
    if (serialReceived) receivedAnyResponse = true;

    if (!receivedAnyResponse && cfgOut.longName.isEmpty && cfgOut.key.isEmpty) {
      print('[BluetoothService] readConfig: No se recibió ninguna respuesta válida de configuración del dispositivo.');
      throw TimeoutException('No se recibió ninguna respuesta de configuración del dispositivo tras múltiples intentos.');
    } else if (!primaryChannelCaptured && cfgOut.key.isEmpty) {
      print('[BluetoothService] readConfig: Advertencia - No se pudo obtener la clave del canal (PSK) principal.');
    }

    print('[BluetoothService] Lectura de configuración completada para el nodo $_myNodeNum. Config leída: ${cfgOut.toString()}');
    return cfgOut;
  }

  // -------- escritura de configuración ----------
  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_toRadio == null || _fromRadioQueue == null) {
      print('[BluetoothService] writeConfig abortado: características BLE no inicializadas.');
      return;
    }
    try {
      await _ensureMyNodeNum();
    } catch (e, s) {
      print('[BluetoothService] writeConfig falló en _ensureMyNodeNum: $e. Stack: $s');
      throw StateError('Error al obtener NodeNum para escribir config: ${e.toString()}');
    }
    
    print('[BluetoothService] Iniciando escritura de configuración para el nodo $_myNodeNum...');

    Future<void> sendAdminCommand(admin.AdminMessage msg, String description) async {
      print('[BluetoothService] writeConfig: Enviando comando: $description');
      try {
        await _sendAndReceive(
          _wrapAdminToToRadio(msg),
          // Para escrituras, a menudo solo nos importa el ACK, que _sendAndReceive ya maneja.
          // No necesitamos un matcher específico a menos que esperemos una respuesta particular de un Set...
          // Si el firmware devuelve una respuesta específica a un Set... la lógica de isComplete necesitaría cambiar.
          // Por ahora, asumimos que el ACK es suficiente para confirmar que el comando fue recibido.
          timeout: _defaultResponseTimeout,
        );
        print("[BluetoothService] writeConfig: Comando enviado y ACK recibido para '$description'.");
      } on TimeoutException catch (e) {
        print("[BluetoothService] writeConfig: Timeout esperando ACK para '$description'. Error: ${e.message}");
        throw TimeoutException("Timeout al enviar '$description': ${e.toString()}");
      } catch (e,s) {
        print("[BluetoothService] writeConfig: Error enviando '$description': $e. Stack: $s");
        throw StateError("Error al enviar '$description': ${e.toString()}");
      }
    }

    try {
      // Nombres del nodo
      final userMsg = mesh.User()
        ..shortName = cfgIn.shortName
        ..longName = cfgIn.longName;
      await sendAdminCommand(admin.AdminMessage()..setOwner = userMsg, "SetOwner (Nombres)");

      // Canal (solo primario)
      final settings = ch.ChannelSettings()
        ..name = "CH${cfgIn.channelIndex}" // Nombre descriptivo
        ..psk = cfgIn.key;
      final channel = ch.Channel()
        ..index = cfgIn.channelIndex
        ..role = ch.Channel_Role.PRIMARY 
        ..settings = settings;
      await sendAdminCommand(admin.AdminMessage()..setChannel = channel, "SetChannel (Índice ${cfgIn.channelIndex})");

      // Configuración Serial
      final serialCfg = mod.ModuleConfig_SerialConfig()
        ..enabled = true // Asumimos habilitado si se configura
        ..baud = cfgIn.baudRate
        ..mode = _serialModeFromString(cfgIn.serialModeAsString); // Usar la función helper de la clase
      final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
      await sendAdminCommand(admin.AdminMessage()..setModuleConfig = moduleCfg, "SetModuleConfig (Serial)");

      // Configuración LoRa (Región)
      final lora = cfg.Config_LoRaConfig()
        ..region = _regionFromString(cfgIn.frequencyRegionAsString); // Usar la función helper de la clase
      final configMsg = cfg.Config()..lora = lora;
      await sendAdminCommand(admin.AdminMessage()..setConfig = configMsg, "SetConfig (LoRa)");
      
      print('[BluetoothService] Escritura de configuración: todos los comandos enviados al nodo $_myNodeNum.');
      // Considerar un "commit" o "reboot" si el firmware lo soporta/requiere tras cambios.
      // await sendAdminCommand(admin.AdminMessage()..commitEditSettings = true, "CommitEditSettings");
      // await sendAdminCommand(admin.AdminMessage()..rebootSeconds = 5, "RebootNode");

    } catch (e) {
      // Los errores específicos ya se loguearon en sendAdminCommand
      // Aquí simplemente relanzamos o manejamos un error general de la escritura.
      print('[BluetoothService] Error durante el proceso general de writeConfig: $e');
      // No es necesario relanzar si queremos que la UI maneje el error (_lastErrorMessage style)
      // pero para consistencia con readConfig y _ensureMyNodeNum, relanzar puede ser mejor.
      throw StateError('Error durante la escritura de la configuración: ${e.toString()}');
    }
  }

  // ------- helpers enum <-> string -------
  admin.AdminMessage? _decodeAdminMessage(mesh.FromRadio frame) {
    if (!frame.hasPacket()) return null;
    final packet = frame.packet;
    if (!packet.hasDecoded()) return null;
    final decoded = packet.decoded;
    if (!decoded.hasPayload()) return null;
    if (decoded.portnum != port.PortNum.ADMIN_APP) return null;
    final payload = decoded.payload;
    if (payload.isEmpty) return null;
    try {
      return admin.AdminMessage.fromBuffer(payload);
    } catch (e,s) { // Añadir stack trace al log de error
      print('[BluetoothService] Error al deserializar AdminMessage desde payload: $e. Stack: $s');
      return null;
    }
  }

  mod.ModuleConfig_SerialConfig_Serial_Mode _serialModeFromString(String s) {
    switch (s.toUpperCase()) {
      case 'PROTO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.PROTO;
      case 'TEXTMSG': 
        return mod.ModuleConfig_SerialConfig_Serial_Mode.TEXTMSG;
      case 'TLL': 
      case 'NMEA': 
        return mod.ModuleConfig_SerialConfig_Serial_Mode.NMEA;
      case 'WPL': 
      case 'CALTOPO':
        return mod.ModuleConfig_SerialConfig_Serial_Mode.CALTOPO;
      default:
        print('[BluetoothService] _serialModeFromString: Modo desconocido \'$s\', usando DEFAULT.');
        return mod.ModuleConfig_SerialConfig_Serial_Mode.DEFAULT;
    }
  }

  cfg.Config_LoRaConfig_RegionCode _regionFromString(String s) {
    switch (s) {
      case '433':
        return cfg.Config_LoRaConfig_RegionCode.EU_433;
      case '915':
        return cfg.Config_LoRaConfig_RegionCode.US;
      case '868':
        return cfg.Config_LoRaConfig_RegionCode.EU_868;
      default:
        print('[BluetoothService] _regionFromString: Región desconocida \'$s\', usando EU_868 por defecto.');
        return cfg.Config_LoRaConfig_RegionCode.EU_868;
    }
  }
}
