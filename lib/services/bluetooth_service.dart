import 'dart:async';
import 'dart:io' show Platform; // Importación añadida
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp; // MODIFICADO
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Importación añadida

import '../models/node_config.dart';
import 'ble_uuids.dart';

// Protobuf 2.6.1
import 'package:Buoys_configurator/exceptions/routing_error_exception.dart';
import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/admin.pb.dart' as admin;
import 'package:Buoys_configurator/proto/meshtastic/channel.pb.dart' as ch;
import 'package:Buoys_configurator/proto/meshtastic/module_config.pb.dart' as mod;
import 'package:Buoys_configurator/proto/meshtastic/config.pb.dart' as cfg;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;
import 'package:Buoys_configurator/services/routing_error_utils.dart';

class BluetoothService {
  fbp.BluetoothDevice? _dev; // MODIFICADO
  fbp.BluetoothCharacteristic? _toRadio; // MODIFICADO
  fbp.BluetoothCharacteristic? _fromRadio; // MODIFICADO
  fbp.BluetoothCharacteristic? _fromNum; // MODIFICADO

  StreamController<mesh.FromRadio>? _fromRadioController;
  StreamSubscription<List<int>>? _fromRadioSubscription;
  StreamSubscription<List<int>>? _fromNumSubscription;
  StreamQueue<mesh.FromRadio>? _fromRadioQueue;

  Completer<void>? _pendingRequest;

  int _lastFromNum = 0;
  int? _myNodeNum;
  bool _nodeNumConfirmed = false;
  Uint8List _sessionPasskey = Uint8List(0);

  String? _lastErrorMessage; // Para mensajes de error a la UI

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);
  static const Duration _scanTimeoutDuration = Duration(seconds: 10); // Timeout para el escaneo BLE

  int? get myNodeNum => _myNodeNum;
  set myNodeNum(int? value) {
    _myNodeNum = value;
    _nodeNumConfirmed = false;
  }
  String? get lastErrorMessage => _lastErrorMessage; // Getter para el mensaje de error

  // -------- permisos ----------
  Future<bool> _ensurePermissions() async {
    _lastErrorMessage = null; // Limpiar mensaje de error anterior
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      List<Permission> permissionsToRequest = [];

      if (androidInfo.version.sdkInt >= 31) { // Android 12 (API 31) y superior
        permissionsToRequest.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ]);
      } else { // Android 11 (API 30) e inferior
        permissionsToRequest.add(Permission.locationWhenInUse);
      }

      if (permissionsToRequest.isEmpty) {
        print('[BluetoothService] No se requieren permisos de tiempo de ejecución específicos para esta versión de Android.');
        return true;
      }

      print('[BluetoothService] Solicitando permisos: $permissionsToRequest');
      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
          String permissionName = permission.toString().split('.').last;
          print('[BluetoothService] Permiso denegado: $permissionName ($status)');
          _lastErrorMessage = 'Permiso $permissionName denegado. Es necesario para la funcionalidad Bluetooth.';
          
          if (status.isPermanentlyDenied) {
            _lastErrorMessage = 'Permiso $permissionName denegado permanentemente. Por favor, actívalo en los ajustes de la aplicación.';
            // Aquí podrías llamar a openAppSettings(); si quieres guiar al usuario.
          }
        } else {
          print('[BluetoothService] Permiso concedido: ${permission.toString().split('.').last}');
        }
      });

      if (!allGranted) {
          print('[BluetoothService] No se concedieron todos los permisos Bluetooth requeridos.');
      }
      return allGranted;
    }
    print('[BluetoothService] Asumiendo que los permisos se manejan de otra forma para plataformas no Android o no se requiere solicitud en tiempo de ejecución.');
    return true;
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
    _injectSessionPasskey(msg);
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
      final userComplete = isComplete;
      var inspectedCount = 0;


      try {
        // print('[BluetoothService] _sendAndReceive: Comenzando a recolectar respuestas...'); // Verboso
        final responses = await _collectResponses(
          isComplete: (frames) {
            while (inspectedCount < frames.length) {
              throwIfRoutingError(frames[inspectedCount]);
              inspectedCount++;
            }
            ackSeen = frames.any(_isAckOrResponseFrame);
            userSatisfied = userComplete?.call(frames) ?? true;
            // if(ackSeen) print('[BluetoothService] _sendAndReceive: ACK recibido.'); // Verboso
            // if(userSatisfied) print('[BluetoothService] _sendAndReceive: Condición de usuario satisfecha.'); // Verboso
            return ackSeen && userSatisfied;
          },
          timeout: timeout,
        );

        while (inspectedCount < responses.length) {
          throwIfRoutingError(responses[inspectedCount]);
          inspectedCount++;
        }

        return responses;
      } on TimeoutException catch (e) {
        final packetIdForLog = toRadioMsg.hasPacket() ? toRadioMsg.packet.id : "N/A";
        if (!ackSeen) {
          print('[BluetoothService] _sendAndReceive: Timeout (${timeout.inSeconds}s) esperando ACK del radio para el paquete ToRadio con ID $packetIdForLog.');
          throw TimeoutException('Timeout esperando ACK del radio: ${e.message}');
        }
        print('[BluetoothService] _sendAndReceive: Timeout (${timeout.inSeconds}s) esperando respuesta completa del radio para el paquete ToRadio con ID $packetIdForLog (ACK fue recibido).');
        throw TimeoutException('Timeout esperando respuesta completa del radio (ACK recibido): ${e.message}');
      } on RoutingErrorException {
        rethrow;
      } catch (e, s) {
        print('[BluetoothService] _sendAndReceive: Error durante _collectResponses: $e. Stack: $s');
        throw StateError('Error inesperado durante la recolección de respuestas: ${e.toString()}');
      }
    });
  }

  Future<void> _writeToRadio(
      fbp.BluetoothCharacteristic characteristic, List<int> payload) async { // MODIFICADO
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

    fbp.FlutterBluePlusException? lastWriteNotPermitted; // MODIFICADO
    for (final withoutResponse in attempts) {
      try {
        await characteristic.write(
          payload,
          withoutResponse: withoutResponse,
        );
        return;
      } on fbp.FlutterBluePlusException catch (err) { // MODIFICADO
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
      } on fbp.FlutterBluePlusException catch (err) { // MODIFICADO
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

  bool _isWriteNotPermittedError(fbp.FlutterBluePlusException err) { // MODIFICADO
    final message = err.description?.toLowerCase() ?? '';
    return message.contains('write not permitted');
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

  // -------- conexión ----------
  Future<bool> connectAndInit() async {
    _lastErrorMessage = null;
    _sessionPasskey = Uint8List(0);
    print('[BluetoothService] Iniciando connectAndInit...');

    var adapterState = await fbp.FlutterBluePlus.adapterState.first; // MODIFICADO
    if (adapterState != fbp.BluetoothAdapterState.on) { // MODIFICADO
      print('[BluetoothService] El adaptador Bluetooth está ${adapterState.name}.');
      _lastErrorMessage = 'El Bluetooth está ${adapterState.name}. Por favor, enciéndelo.';
      if (Platform.isAndroid) {
        try {
          print('[BluetoothService] Solicitando encender Bluetooth...');
          await fbp.FlutterBluePlus.turnOn(); // MODIFICADO
          await Future.delayed(const Duration(milliseconds: 500));
          adapterState = await fbp.FlutterBluePlus.adapterState.first; // MODIFICADO
          if (adapterState != fbp.BluetoothAdapterState.on) { // MODIFICADO
            print('[BluetoothService] Bluetooth sigue apagado después de la solicitud.');
            return false;
          }
          print('[BluetoothService] Bluetooth ahora está encendido después de la solicitud.');
        } catch (e) {
          print('[BluetoothService] No se pudo solicitar encender Bluetooth (o no es soportado): $e');
          return false;
        }
      } else {
        return false;
      }
    }
    print('[BluetoothService] El adaptador Bluetooth está encendido.');

    if (!await _ensurePermissions()) {
      print('[BluetoothService] Permisos Bluetooth no concedidos.');
      return false;
    }
    print('[BluetoothService] Permisos Bluetooth concedidos.');

    print('[BluetoothService] Iniciando escaneo BLE (nueva lógica)...');
    fbp.BluetoothDevice? foundDevice; // MODIFICADO
    final scanCompleter = Completer<fbp.BluetoothDevice?>(); // MODIFICADO
    StreamSubscription<List<fbp.ScanResult>>? scanSubscription; // MODIFICADO
    Timer? scanTimeoutTimer;

    try {
      if (fbp.FlutterBluePlus.isScanningNow) { // MODIFICADO
        print('[BluetoothService] Escaneo previo en curso, deteniéndolo...');
        await fbp.FlutterBluePlus.stopScan(); // MODIFICADO
        print('[BluetoothService] Escaneo previo detenido.');
      }

      scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) { // MODIFICADO
        if (scanCompleter.isCompleted) return;
        print('[BluetoothService] Lote de resultados de escaneo recibido (cantidad: ${results.length}).');
        for (final r in results) {
          final deviceName = r.device.platformName;
          if (deviceName.isNotEmpty) {
            print('[BluetoothService] Dispositivo encontrado: "$deviceName" (${r.device.remoteId})');
            final upperDeviceName = deviceName.toUpperCase();
            // Comprobación de nombres mejorada
            if (upperDeviceName.startsWith('MESHTASTIC') || // Incluye Meshtastic_XXXX
                upperDeviceName.contains('TBEAM') ||
                upperDeviceName.contains('HELTEC') ||
                upperDeviceName.contains('LORA') ||
                upperDeviceName.contains('XIAO')) {
              print('[BluetoothService] ¡Dispositivo Meshtastic compatible encontrado!: "$deviceName"');
              if (!scanCompleter.isCompleted) {
                scanCompleter.complete(r.device);
              }
              break; // Salir del bucle for interno
            }
          }
        }
      }, onError: (e, s) {
        print('[BluetoothService] Error en el stream de scanResults: $e. Stack: $s');
        if (!scanCompleter.isCompleted) {
          scanCompleter.completeError(e, s);
        }
      });

      print('[BluetoothService] Llamando a fbp.FlutterBluePlus.startScan() con timeout de ${_scanTimeoutDuration.inSeconds}s...'); // MODIFICADO
      // Iniciar escaneo - el future de startScan se puede ignorar o manejar de forma no bloqueante aquí
      // ya que la lógica principal está en el listener y el completer.
      // fbp.FlutterBluePlus.startScan terminará por sí mismo después de _scanTimeoutDuration.
      unawaited(fbp.FlutterBluePlus.startScan(timeout: _scanTimeoutDuration)); // MODIFICADO
      print('[BluetoothService] fbp.FlutterBluePlus.startScan() invocado (no bloqueante).'); // MODIFICADO
      
      // Configurar un temporizador por si el stream no completa y el escaneo termina
      scanTimeoutTimer = Timer(_scanTimeoutDuration + const Duration(seconds: 1), () { // Un poco más que el timeout de startScan
          if (!scanCompleter.isCompleted) {
              print('[BluetoothService] Timeout general del escaneo alcanzado por el Timer. No se encontró dispositivo compatible.');
              scanCompleter.complete(null); // Completa con null si el temporizador expira
          }
      });

      print('[BluetoothService] Esperando resultado del escaneo (scanCompleter.future)...');
      foundDevice = await scanCompleter.future;

    } catch (e, s) {
      print('[BluetoothService] EXCEPCIÓN durante la nueva lógica de escaneo: $e. Stack: $s');
      _lastErrorMessage = 'Error durante el escaneo BLE: ${e.toString()}';
      // El finally se encargará de limpiar
    } finally {
      print('[BluetoothService] Bloque finally de la nueva lógica de escaneo.');
      scanTimeoutTimer?.cancel();
      await scanSubscription?.cancel();
      if (fbp.FlutterBluePlus.isScanningNow) { // MODIFICADO
        print('[BluetoothService] El escaneo sigue activo en finally, deteniéndolo...');
        await fbp.FlutterBluePlus.stopScan(); // MODIFICADO
        print('[BluetoothService] Escaneo detenido en finally.');
      } else {
        print('[BluetoothService] El escaneo ya no estaba activo al llegar a finally.');
      }
    }

    if (foundDevice == null) {
      print('[BluetoothService] No se encontró ningún dispositivo Meshtastic compatible.');
      if (_lastErrorMessage == null) {
        _lastErrorMessage = 'No se encontró dispositivo Meshtastic. Asegúrate que está encendido y visible.';
      }
      return false;
    }
    print('[BluetoothService] Dispositivo compatible asignado: ${foundDevice.platformName}.');
    _dev = foundDevice;
    
    // --- Resto de la lógica de conexión y descubrimiento de servicios ---
    print('[BluetoothService] Intentando conectar a ${_dev!.remoteId}...');
    try {
      await _dev!.connect(autoConnect: false);
      print('[BluetoothService] Conectado a ${_dev!.remoteId}.');
    } catch (e,s) {
      print('[BluetoothService] Error al conectar al dispositivo: $e. Stack: $s');
      _lastErrorMessage = 'Error al conectar: ${e.toString()}';
      await disconnect(); // Limpiar
      return false;
    }

    print('[BluetoothService] Solicitando MTU 512...');
    try {
      await _dev!.requestMtu(512);
      print('[BluetoothService] MTU solicitado.');
    } catch (e,s) {
      print('[BluetoothService] Error solicitando MTU: $e. Stack: $s');
      // No es fatal, pero puede afectar el rendimiento
    }

    print('[BluetoothService] Descubriendo servicios...');
    List<fbp.BluetoothService>? services; // MODIFICADO
    try {
      services = await _dev!.discoverServices();
      print('[BluetoothService] Servicios descubiertos (${services.length}).');
    } catch (e,s) {
      print('[BluetoothService] Error descubriendo servicios: $e. Stack: $s');
      _lastErrorMessage = 'Error descubriendo servicios: ${e.toString()}';
      await disconnect();
      return false;
    }

    for (final s in services) {
      if (s.uuid == MeshUuids.service) {
        print('[BluetoothService] Servicio Meshtastic encontrado: ${s.uuid}.');
        for (final c in s.characteristics) {
          if (c.uuid == MeshUuids.toRadio) {
            _toRadio = c;
            print('[BluetoothService] Característica ToRadio encontrada.');
          }
          if (c.uuid == MeshUuids.fromRadio) {
            _fromRadio = c;
            print('[BluetoothService] Característica FromRadio encontrada.');
          }
          if (c.uuid == MeshUuids.fromNum) {
            _fromNum = c;
            print('[BluetoothService] Característica FromNum encontrada.');
          }
        }
      }
    }

    if (_toRadio == null || _fromRadio == null || _fromNum == null) {
      print('[BluetoothService] No se encontraron todas las características Meshtastic requeridas.');
      _lastErrorMessage = 'No se encontraron características BLE Meshtastic requeridas.';
      await disconnect();
      return false;
    }
    print('[BluetoothService] Todas las características Meshtastic encontradas.');

    _lastFromNum = 0;
    print('[BluetoothService] Inicializando notificaciones FromRadio y FromNum...');
    await _initializeFromRadioNotifications();
    await _initializeFromNumNotifications();
    print('[BluetoothService] Notificaciones inicializadas.');

    try {
      await _ensureMyNodeNum();
      print('[BluetoothService] MyNodeNum asegurado: $_myNodeNum.');
    } catch (e,s) {
      print('[BluetoothService] Error crítico durante _ensureMyNodeNum después de la conexión: $e. Stack: $s');
      _lastErrorMessage = 'Error obteniendo info del nodo: ${e.toString()}';
      await disconnect();
      return false;
    }
    
    print('[BluetoothService] connectAndInit completado exitosamente.');
    return true;
  }

  Future<void> disconnect() async {
    print('[BluetoothService] Iniciando desconexión...');
    try {
      await _fromRadio?.setNotifyValue(false);
      print('[BluetoothService] Notificaciones de FromRadio desactivadas.');
    } catch (e) {
      print('[BluetoothService] Error desactivando notificaciones FromRadio: $e');
    }
    try {
      await _fromNum?.setNotifyValue(false);
      print('[BluetoothService] Notificaciones de FromNum desactivadas.');
    } catch (e) {
      print('[BluetoothService] Error desactivando notificaciones FromNum: $e');
    }

    await _disposeRadioStreams();
    print('[BluetoothService] Streams de radio eliminados.');

    try {
      await _dev?.disconnect();
      print('[BluetoothService] Dispositivo desconectado.');
    } catch (e) {
      print('[BluetoothService] Error desconectando dispositivo: $e');
    }

    _dev = null;
    _toRadio = null;
    _fromRadio = null;
    _fromNum = null;
    _lastFromNum = 0;
    _myNodeNum = null;
    _nodeNumConfirmed = false;
    _sessionPasskey = Uint8List(0);
    print('[BluetoothService] Estado de BluetoothService limpiado.');
  }

  // -------- lectura de configuración ----------
  Future<NodeConfig?> readConfig() async {
    if (_toRadio == null || _fromRadioQueue == null) {
      print('[BluetoothService] readConfig abortado: características BLE no inicializadas (toRadio o fromRadioQueue nulos).');
      _lastErrorMessage = 'Características BLE no disponibles para leer config.';
      return null;
    }

    try {
      await _ensureMyNodeNum(); // Asegura que tenemos el NodeNum antes de proceder
    } catch (e, s) {
      print('[BluetoothService] readConfig falló en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage = 'Error al obtener NodeNum para leer config: ${e.toString()}';
      throw StateError('Error al obtener NodeNum para leer config: ${e.toString()}'); // Relanzar para que la UI lo maneje
    }
    
    print('[BluetoothService] Iniciando lectura de configuración del nodo $_myNodeNum...');
    final cfgOut = NodeConfig(); // Objeto para almacenar la configuración leída

    var primaryChannelCaptured = false; 
    var primaryChannelLogged = false; // Usado para loguear la captura del canal primario solo una vez

    void _applyAdminToConfig(admin.AdminMessage message) {
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
      }
      if (message.hasGetConfigResponse() && 
          message.getConfigResponse.hasLora() && 
          message.getConfigResponse.lora.hasRegion()) {
        cfgOut.frequencyRegion = message.getConfigResponse.lora.region;
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
            return adminMsg != null && matcher(adminMsg);
          }),
          timeout: _defaultResponseTimeout, 
        );
        print('[BluetoothService] readConfig: Respuesta(s) recibida(s) para $description.');
      } on TimeoutException catch (e) {
        print('[BluetoothService] readConfig: Timeout (_defaultResponseTimeout) esperando $description. Error: ${e.message}');
        _lastErrorMessage = 'Timeout esperando $description.';
        return false; 
      } catch (e, s) {
        print('[BluetoothService] readConfig: Error durante _sendAndReceive para $description: $e. Stack: $s');
        _lastErrorMessage = 'Error solicitando $description: ${e.toString()}';
        return false; 
      }

      var matched = false;
      for (final f in frames) {
        final adminMsg = _decodeAdminMessage(f);
        if (adminMsg == null) continue;
        _applyAdminToConfig(adminMsg); 
        if (matcher(adminMsg)) matched = true;
      }
      if (!matched) print('[BluetoothService] readConfig: No se encontró un match específico para $description en las respuestas recibidas.');
      return matched; 
    }

    var receivedAnyResponse = false;
    final ownerReceived = await _requestAndApply( admin.AdminMessage()..getOwnerRequest = true, (msg) => msg.hasGetOwnerResponse(), 'información del propietario (Owner Info)');
    if (ownerReceived) receivedAnyResponse = true;

    final loraReceived = await _requestAndApply( admin.AdminMessage()..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG, (msg) => msg.hasGetConfigResponse() && msg.getConfigResponse.hasLora() && msg.getConfigResponse.lora.hasRegion(), 'configuración LoRa (para región)');
    if (loraReceived) receivedAnyResponse = true;

    final indicesToQuery = <int>{};
    if (cfgOut.channelIndex > 0 && cfgOut.channelIndex <= 8) indicesToQuery.add(cfgOut.channelIndex);
    if (!primaryChannelCaptured) indicesToQuery.addAll([0, 1, 2]); 

    for (final index in indicesToQuery) {
      if (primaryChannelCaptured) break;
      final channelReceived = await _requestAndApply( admin.AdminMessage()..getChannelRequest = index + 1, (msg) => msg.hasGetChannelResponse() && msg.getChannelResponse.index == index, 'canal con índice $index');
      if (channelReceived) receivedAnyResponse = true;
    }
    
    if (!primaryChannelCaptured && cfgOut.key.isEmpty) {
        print('[BluetoothService] readConfig: No se capturó canal primario, intentando consulta explícita por canal 0.');
        final channelZeroReceived = await _requestAndApply( admin.AdminMessage()..getChannelRequest = 0 + 1, (msg) => msg.hasGetChannelResponse() && msg.getChannelResponse.index == 0, 'canal con índice 0 (intento adicional)');
        if (channelZeroReceived) receivedAnyResponse = true;
    }

    final serialReceived = await _requestAndApply( admin.AdminMessage()..getModuleConfigRequest = admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG, (msg) => msg.hasGetModuleConfigResponse() && msg.getModuleConfigResponse.hasSerial(), 'configuración del módulo Serial');
    if (serialReceived) receivedAnyResponse = true;

    if (!receivedAnyResponse && cfgOut.longName.isEmpty && cfgOut.key.isEmpty) {
      print('[BluetoothService] readConfig: No se recibió ninguna respuesta válida de configuración del dispositivo.');
      _lastErrorMessage = 'No se recibió respuesta de configuración del nodo.';
      throw TimeoutException('No se recibió ninguna respuesta de configuración del dispositivo tras múltiples intentos.');
    } else if (!primaryChannelCaptured && cfgOut.key.isEmpty) {
      print('[BluetoothService] readConfig: Advertencia - No se pudo obtener la clave del canal (PSK) principal.');
       _lastErrorMessage = 'Advertencia: No se pudo obtener PSK del canal.';
    }

    print('[BluetoothService] Lectura de configuración completada para el nodo $_myNodeNum. Config leída: ${cfgOut.toString()}');
    return cfgOut;
  }

  // -------- escritura de configuración ----------
  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_toRadio == null || _fromRadioQueue == null) {
      print('[BluetoothService] writeConfig abortado: características BLE no inicializadas.');
      _lastErrorMessage = 'Características BLE no disponibles para escribir config.';
      return;
    }
    try {
      await _ensureMyNodeNum();
    } catch (e, s) {
      print('[BluetoothService] writeConfig falló en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage = 'Error al obtener NodeNum para escribir config: ${e.toString()}';
      throw StateError('Error al obtener NodeNum para escribir config: ${e.toString()}');
    }
    
    print('[BluetoothService] Iniciando escritura de configuración para el nodo $_myNodeNum...');

    Future<void> sendAdminCommand(admin.AdminMessage msg, String description) async {
      print('[BluetoothService] writeConfig: Enviando comando: $description');
      try {
        await _sendAndReceive(
          _wrapAdminToToRadio(msg),
          timeout: _defaultResponseTimeout,
        );
        print("[BluetoothService] writeConfig: Comando enviado y ACK recibido para '$description'.");
      } on TimeoutException catch (e) {
        print("[BluetoothService] writeConfig: Timeout esperando ACK para '$description'. Error: ${e.message}");
        _lastErrorMessage = "Timeout enviando '$description'";
        throw TimeoutException("Timeout al enviar '$description': ${e.toString()}");
      } catch (e,s) {
        print("[BluetoothService] writeConfig: Error enviando '$description': $e. Stack: $s");
        _lastErrorMessage = "Error enviando '$description'";
        throw StateError("Error al enviar '$description': ${e.toString()}");
      }
    }

    try {
      final userMsg = mesh.User()..shortName = cfgIn.shortName..longName = cfgIn.longName;
      await sendAdminCommand(admin.AdminMessage()..setOwner = userMsg, "SetOwner (Nombres)");

      final settings = ch.ChannelSettings()..name = "CH${cfgIn.channelIndex}"..psk = cfgIn.key;
      final channel = ch.Channel()..index = cfgIn.channelIndex..role = ch.Channel_Role.PRIMARY..settings = settings;
      await sendAdminCommand(admin.AdminMessage()..setChannel = channel, "SetChannel (Índice ${cfgIn.channelIndex})");

      final serialCfg = mod.ModuleConfig_SerialConfig()..enabled = true..baud = cfgIn.baudRate..mode = _serialModeFromString(cfgIn.serialModeAsString);
      final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
      await sendAdminCommand(admin.AdminMessage()..setModuleConfig = moduleCfg, "SetModuleConfig (Serial)");

      final lora = cfg.Config_LoRaConfig()..region = _regionFromString(cfgIn.frequencyRegionAsString);
      final configMsg = cfg.Config()..lora = lora;
      await sendAdminCommand(admin.AdminMessage()..setConfig = configMsg, "SetConfig (LoRa)");
      
      print('[BluetoothService] Escritura de configuración: todos los comandos enviados al nodo $_myNodeNum.');

    } catch (e) {
      print('[BluetoothService] Error durante el proceso general de writeConfig: $e');
      if (_lastErrorMessage == null) _lastErrorMessage = 'Error general durante writeConfig';
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
      final message = admin.AdminMessage.fromBuffer(payload);
      _captureSessionPasskey(message);
      return message;
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
