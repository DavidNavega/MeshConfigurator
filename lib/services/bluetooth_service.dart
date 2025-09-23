import 'dart:async';
import 'dart:io' show Platform; // ImportaciÃƒÂ¯Ã‚Â¿Ã‚Â½n aÃƒÂ¯Ã‚Â¿Ã‚Â½adida
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp; // MODIFICADO
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Importacion aÃƒÂ±adida

import '../models/node_config.dart';
import 'ble_uuids.dart';

// Protobuf 2.6.1
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

class BluetoothService {
  static final Logger _log = Logger('BluetoothService');
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

  Timer? _heartbeatTimer;
  int _configNonce = 0;
  static const Duration _heartbeatInterval = Duration(minutes: 5);

  String? _lastErrorMessage; // Para mensajes de error a la UI

  static const Duration _defaultResponseTimeout = Duration(seconds: 5);
  static const Duration _postResponseWindow = Duration(milliseconds: 200);
  static const Duration _scanTimeoutDuration =
      Duration(seconds: 10); // Timeout para el escaneo BLE

  int? get myNodeNum => _myNodeNum;
  set myNodeNum(int? value) {
    _myNodeNum = value;
    _nodeNumConfirmed = false;
  }

  String? get lastErrorMessage =>
      _lastErrorMessage; // Getter para el mensaje de error

  // -------- permisos ----------
  Future<bool> _ensurePermissions() async {
    _lastErrorMessage = null; // Limpiar mensaje de error anterior
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      List<Permission> permissionsToRequest = [];

      if (androidInfo.version.sdkInt >= 31) {
        // Android 12 (API 31) y superior
        permissionsToRequest.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ]);
      } else {
        // Android 11 (API 30) e inferior
        permissionsToRequest.add(Permission.locationWhenInUse);
      }

      if (permissionsToRequest.isEmpty) {
        _log.info(
            '[BluetoothService] No se requieren permisos de tiempo de ejecuciÃƒÆ’Ã‚Â³n especÃƒÆ’Ã‚Â­ficos para esta versiÃƒÆ’Ã‚Â³n de Android.');
        return true;
      }

      _log.info(
          '[BluetoothService] Solicitando permisos: $permissionsToRequest');
      Map<Permission, PermissionStatus> statuses =
          await permissionsToRequest.request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
          String permissionName = permission.toString().split('.').last;
          _log.info(
              '[BluetoothService] Permiso denegado: $permissionName ($status)');
          _lastErrorMessage =
              'Permiso $permissionName denegado. Es necesario para la funcionalidad Bluetooth.';

          if (status.isPermanentlyDenied) {
            _lastErrorMessage =
                'Permiso $permissionName denegado permanentemente. Por favor, actÃƒÆ’Ã‚Â­valo en los ajustes de la aplicaciÃƒÆ’Ã‚Â³n.';
            // AquÃƒÆ’Ã‚Â­ podrÃƒÆ’Ã‚Â­as llamar a openAppSettings(); si quieres guiar al usuario.
          }
        } else {
          _log.info(
              '[BluetoothService] Permiso concedido: ${permission.toString().split('.').last}');
        }
      });

      if (!allGranted) {
        _log.info(
            '[BluetoothService] No se concedieron todos los permisos Bluetooth requeridos.');
      }
      return allGranted;
    }
    _log.info(
        '[BluetoothService] Asumiendo que los permisos se manejan de otra forma para plataformas no Android o no se requiere solicitud en tiempo de ejecuciÃƒÆ’Ã‚Â³n.');
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
        _dispatchFromRadioPayload(data);
      },
      onError: (err, st) {
        final controller = _fromRadioController;
        if (controller == null || controller.isClosed) return;
        controller.addError(err, st);
      },
    );
  }

  void _dispatchFromRadioPayload(List<int> raw) {
    if (raw.isEmpty) return;
    final controller = _fromRadioController;
    if (controller == null || controller.isClosed) return;
    try {
      final frame = mesh.FromRadio.fromBuffer(raw);
      _captureMyNodeNum(frame);
      controller.add(frame);
    } catch (err, st) {
      if (!controller.isClosed) {
        controller.addError(err, st);
      }
    }
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

  Future<void> _primeFromRadioMailbox({int maxReads = 64}) async {
    final characteristic = _fromRadio;
    final controller = _fromRadioController;
    if (characteristic == null || controller == null || controller.isClosed) {
      return;
    }

    for (var i = 0; i < maxReads; i++) {
      List<int> raw;
      try {
        raw = await characteristic.read();
      } catch (err, st) {
        if (!controller.isClosed) {
          controller.addError(err, st);
        }
        break;
      }

      if (raw.isEmpty) {
        break;
      }

      _dispatchFromRadioPayload(raw);
    }
  }

  Future<void> _startConfigSession() async {
    await _withRequestLock<void>(() async {
      final characteristic = _toRadio;
      if (characteristic == null) {
        return;
      }

      final nonce = _nextConfigNonce();
      final toRadio = mesh.ToRadio()..wantConfigId = nonce;
      await _writeToRadio(characteristic, toRadio.writeToBuffer());
    });

    _startHeartbeatTimer();
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final heartbeat = mesh.ToRadio()..heartbeat = mesh.Heartbeat();
    try {
      await _withRequestLock<void>(() async {
        final characteristic = _toRadio;
        if (characteristic == null) {
          return;
        }
        await _writeToRadio(characteristic, heartbeat.writeToBuffer());
      });
    } catch (err) {
      _log.info('[BluetoothService] Error enviando heartbeat BLE: $err');
    }
  }

  int _nextConfigNonce() {
    _configNonce = (_configNonce + 1) & 0xFFFFFFFF;
    if (_configNonce == 0) {
      _configNonce = 1;
    }
    return _configNonce;
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
    if (radioCharacteristic == null ||
        controller == null ||
        controller.isClosed) {
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

      _dispatchFromRadioPayload(raw);
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

  // -------- exclusiÃƒÆ’Ã‚Â³n de peticiÃƒÆ’Ã‚Â³n ----------
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
        _log.info(
            '[BluetoothService] MyNodeNum capturado/actualizado: $_myNodeNum -> $newNum');
        _myNodeNum = newNum;
        _nodeNumConfirmed = true; // Confirmar al capturar/actualizar
      } else if (!_nodeNumConfirmed) {
        // Si es el mismo nÃƒÆ’Ã‚Âºmero pero no estaba confirmado (ej. primera vez que se recibe)
        _log.info('[BluetoothService] MyNodeNum re-confirmado: $newNum');
        _nodeNumConfirmed = true;
      }
      // Si ya estaba confirmado y el nÃƒÆ’Ã‚Âºmero es el mismo, no es necesario loguear nada.
    }
  }

  Future<void> _ensureMyNodeNum() async {
    if (_nodeNumConfirmed && _myNodeNum != null) {
      // _log.info('[BluetoothService] _ensureMyNodeNum: MyNodeNum ya confirmado: $_myNodeNum'); // Verboso
      return;
    }
    _log.info(
        '[BluetoothService] Asegurando MyNodeNum (estado actual: confirmado=$_nodeNumConfirmed, num=$_myNodeNum)...');

    final toCharacteristic = _toRadio;
    // Corregir el nombre de la variable para que coincida con la instancia de la clase
    final fromRadioControllerInstance = _fromRadioController;

    if (toCharacteristic == null ||
        fromRadioControllerInstance == null ||
        fromRadioControllerInstance.isClosed) {
      _log.info(
          '[BluetoothService] _ensureMyNodeNum fallÃƒÆ’Ã‚Â³: CaracterÃƒÆ’Ã‚Â­sticas BLE no disponibles o stream cerrado.');
      throw StateError(
          'CaracterÃƒÆ’Ã‚Â­sticas BLE no disponibles o stream de FromRadio cerrado para _ensureMyNodeNum.');
    }

    try {
      await _withRequestLock(() async {
        if (_nodeNumConfirmed && _myNodeNum != null)
          return; // Doble chequeo dentro del lock

        _log.info(
            '[BluetoothService] _ensureMyNodeNum: Creando futuro para MyInfo...');
        final infoFuture = fromRadioControllerInstance.stream
            .where((frame) => frame.hasMyInfo() && frame.myInfo.hasMyNodeNum())
            .map((frame) {
              // _log.info('[BluetoothService] _ensureMyNodeNum: MyInfo recibido en stream: NodeNum ${frame.myInfo.myNodeNum}'); // Verboso
              return frame.myInfo.myNodeNum;
            })
            .first
            .timeout(_defaultResponseTimeout, onTimeout: () {
              _log.info(
                  '[BluetoothService] Timeout (_defaultResponseTimeout) esperando MyInfo en el stream durante _ensureMyNodeNum.');
              throw TimeoutException(
                  'Timeout esperando MyNodeInfo del radio (stream) en _ensureMyNodeNum.');
            });

        final toRadioPacket = mesh.ToRadio()
          ..wantConfigId = DateTime.now().millisecondsSinceEpoch &
              0xFFFFFFFF; // ID aleatorio

        _log.info(
            '[BluetoothService] _ensureMyNodeNum: Enviando solicitud de MyInfo (wantConfigId: ${toRadioPacket.wantConfigId}).');
        await _writeToRadio(toCharacteristic, toRadioPacket.writeToBuffer());

        final nodeNum = await infoFuture;
        // _captureMyNodeNum ya se llama en el listener general de _fromRadioSubscription,
        // por lo que _myNodeNum y _nodeNumConfirmed deberÃƒÆ’Ã‚Â­an actualizarse automÃƒÆ’Ã‚Â¡ticamente.
        // AquÃƒÆ’Ã‚Â­ solo re-confirmamos o actualizamos por si acaso.
        if (_myNodeNum != nodeNum) {
          _log.info(
              '[BluetoothService] _ensureMyNodeNum: MyNodeNum obtenido del futuro: $nodeNum (anterior: $_myNodeNum).');
          _myNodeNum = nodeNum;
        }
        _nodeNumConfirmed = true;
        _log.info(
            '[BluetoothService] _ensureMyNodeNum: MyNodeNum asegurado y confirmado: $_myNodeNum.');
      });
    } on TimeoutException catch (e) {
      // El timeout puede venir del .timeout en el stream o del lock si la acciÃƒÆ’Ã‚Â³n entera tarda mucho.
      _log.info(
          '[BluetoothService] _ensureMyNodeNum fallÃƒÆ’Ã‚Â³ por TimeoutException: ${e.message}');
      throw TimeoutException(
          'No se recibiÃƒÆ’Ã‚Â³ MyNodeInfo del radio (timeout global en _ensureMyNodeNum): ${e.message}');
    } catch (e, s) {
      _log.info(
          '[BluetoothService] _ensureMyNodeNum fallÃƒÆ’Ã‚Â³ con error inesperado: $e. Stack: $s');
      throw StateError(
          'Error inesperado obteniendo MyNodeInfo en _ensureMyNodeNum: ${e.toString()}');
    }

    if (_myNodeNum == null) {
      _log.info(
          '[BluetoothService] _ensureMyNodeNum fallÃƒÆ’Ã‚Â³ crÃƒÆ’Ã‚Â­ticamente: No se pudo determinar el NodeNum del radio despuÃƒÆ’Ã‚Â©s del intento.');
      throw StateError(
          'No se pudo determinar el NodeNum del radio tras _ensureMyNodeNum.');
    }
  }

  // -------- empaquetador: AdminMessage -> MeshPacket.decoded ----------
  mesh.ToRadio _wrapAdminToToRadio(admin.AdminMessage msg) {
    final nodeNum = _myNodeNum;
    if (nodeNum == null) {
      _log.info(
          '[BluetoothService] CRÃƒÆ’Ã‚ÂTICO: _wrapAdminToToRadio llamado pero _myNodeNum es nulo. El paquete no serÃƒÆ’Ã‚Â¡ dirigido correctamente.');
      // Es crucial tener myNodeNum para dirigir el paquete.
      throw StateError(
          '_myNodeNum no inicializado. Llama a _ensureMyNodeNum antes de enviar comandos administrativos.');
    }
    _injectSessionPasskey(msg);
    final data = mesh.Data()
      ..portnum = port.PortNum.ADMIN_APP
      ..payload = msg.writeToBuffer()
      ..wantResponse =
          true; // Generalmente queremos respuesta para mensajes admin

    final packetId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;
    // _log.info('[BluetoothService] _wrapAdminToToRadio: Creando paquete para NodeNum $nodeNum con ID $packetId para ${msg.info_.messageName}'); // Verboso

    return mesh.ToRadio()
      ..packet = (mesh.MeshPacket()
        ..to = nodeNum // Dirigido a nuestro nodo
        ..from =
            0 // Usar 0 (Broadcast addr) o un ID especÃƒÆ’Ã‚Â­fico de app. Firmware suele ignorarlo para AdminApp.
        ..id = packetId // ID de paquete ÃƒÆ’Ã‚Âºnico
        ..priority = mesh.MeshPacket_Priority
            .RELIABLE // Queremos que los comandos admin lleguen
        ..wantAck = true // Solicitar ACK del radio
        ..decoded = data);
  }

  // -------- envÃƒÆ’Ã‚Â­o + recepciÃƒÆ’Ã‚Â³n ----------
  Future<List<mesh.FromRadio>> _sendAndReceive(
    mesh.ToRadio toRadioMsg, {
    bool Function(List<mesh.FromRadio>)? isComplete,
    Duration timeout = _defaultResponseTimeout,
  }) {
    return _withRequestLock(() async {
      final toCharacteristic = _toRadio;
      if (toCharacteristic == null) {
        _log.info(
            '[BluetoothService] _sendAndReceive fallÃƒÆ’Ã‚Â³: CaracterÃƒÆ’Ã‚Â­stica de escritura BLE (_toRadio) no disponible.');
        throw StateError('CaracterÃƒÆ’Ã‚Â­stica de escritura BLE no disponible.');
      }

      // _log.info('[BluetoothService] _sendAndReceive: Enviando paquete ToRadio con ID ${toRadioMsg.hasPacket() ? toRadioMsg.packet.id : "N/A"}'); // Verboso

      try {
        // Intento de escritura inicial (se delega a _writeToRadio que ya maneja los reintentos con/sin respuesta)
        await _writeToRadio(toCharacteristic, toRadioMsg.writeToBuffer());
        // _log.info('[BluetoothService] _sendAndReceive: Paquete enviado correctamente.'); // Verboso
      } catch (e, s) {
        _log.info(
            '[BluetoothService] _sendAndReceive: Error al escribir en _toRadio: $e. Stack: $s');
        // Relanzar para que sea manejado por el que llama o simplemente no continuar con la recolecciÃƒÆ’Ã‚Â³n de respuestas.
        throw StateError(
            'Error al escribir en la caracterÃƒÆ’Ã‚Â­stica BLE: ${e.toString()}');
      }

      var ackSeen = false;
      var userSatisfied = false;
      final userComplete = isComplete;
      var inspectedCount = 0;

      try {
        // _log.info('[BluetoothService] _sendAndReceive: Comenzando a recolectar respuestas...'); // Verboso
        final responses = await _collectResponses(
          isComplete: (frames) {
            while (inspectedCount < frames.length) {
              throwIfRoutingError(frames[inspectedCount]);
              inspectedCount++;
            }
            ackSeen = frames.any(_isAckOrResponseFrame);
            userSatisfied = userComplete?.call(frames) ?? true;
            // if(ackSeen) _log.info('[BluetoothService] _sendAndReceive: ACK recibido.'); // Verboso
            // if(userSatisfied) _log.info('[BluetoothService] _sendAndReceive: CondiciÃƒÆ’Ã‚Â³n de usuario satisfecha.'); // Verboso
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
        final packetIdForLog =
            toRadioMsg.hasPacket() ? toRadioMsg.packet.id : "N/A";
        if (!ackSeen) {
          _log.info(
              '[BluetoothService] _sendAndReceive: Timeout (${timeout.inSeconds}s) esperando ACK del radio para el paquete ToRadio con ID $packetIdForLog.');
          throw TimeoutException(
              'Timeout esperando ACK del radio: ${e.message}');
        }
        _log.info(
            '[BluetoothService] _sendAndReceive: Timeout (${timeout.inSeconds}s) esperando respuesta completa del radio para el paquete ToRadio con ID $packetIdForLog (ACK fue recibido).');
        throw TimeoutException(
            'Timeout esperando respuesta completa del radio (ACK recibido): ${e.message}');
      } on RoutingErrorException {
        rethrow;
      } catch (e, s) {
        _log.info(
            '[BluetoothService] _sendAndReceive: Error durante _collectResponses: $e. Stack: $s');
        throw StateError(
            'Error inesperado durante la recolecciÃƒÆ’Ã‚Â³n de respuestas: ${e.toString()}');
      }
    });
  }

  Future<void> _writeToRadio(
      fbp.BluetoothCharacteristic characteristic, List<int> payload) async {
    final supportsWriteWithResponse = characteristic.properties.write;
    final supportsWriteWithoutResponse =
        characteristic.properties.writeWithoutResponse;

    final attempts = <bool>[];
    if (supportsWriteWithResponse) {
      attempts.add(false);
    }
    if (supportsWriteWithoutResponse) {
      attempts.add(true);
    }

    if (attempts.isEmpty) {
      throw StateError('Characteristic does not support write operations');
    }

    if (payload.isEmpty) {
      return;
    }

    final mtu = _dev?.mtuNow ?? 23;
    final chunkSize = math.max(20, mtu - 3);

    for (var offset = 0; offset < payload.length; offset += chunkSize) {
      final end = math.min(payload.length, offset + chunkSize);
      final chunk = payload.sublist(offset, end);

      fbp.FlutterBluePlusException? lastWriteNotPermitted;
      var chunkWritten = false;

      for (final withoutResponse in attempts) {
        try {
          await characteristic.write(
            chunk,
            withoutResponse: withoutResponse,
          );
          chunkWritten = true;
          if (withoutResponse) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
          break;
        } on fbp.FlutterBluePlusException catch (err) {
          if (_isWriteNotPermittedError(err)) {
            lastWriteNotPermitted = err;
            continue;
          }
          rethrow;
        }
      }

      if (!chunkWritten) {
        if (lastWriteNotPermitted != null) {
          throw lastWriteNotPermitted;
        }
        throw StateError('Failed to write to characteristic');
      }
    }
  }

  bool _isWriteNotPermittedError(fbp.FlutterBluePlusException err) {
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

  // -------- conexiÃƒÆ’Ã‚Â³n ----------
  Future<bool> connectAndInit() async {
    _lastErrorMessage = null;
    _sessionPasskey = Uint8List(0);
    _log.info('[BluetoothService] Iniciando connectAndInit...');

    var adapterState =
        await fbp.FlutterBluePlus.adapterState.first; // MODIFICADO
    if (adapterState != fbp.BluetoothAdapterState.on) {
      // MODIFICADO
      _log.info(
          '[BluetoothService] El adaptador Bluetooth estÃƒÆ’Ã‚Â¡ ${adapterState.name}.');
      _lastErrorMessage =
          'El Bluetooth estÃƒÆ’Ã‚Â¡ ${adapterState.name}. Por favor, enciÃƒÆ’Ã‚Â©ndelo.';
      if (Platform.isAndroid) {
        try {
          _log.info('[BluetoothService] Solicitando encender Bluetooth...');
          await fbp.FlutterBluePlus.turnOn(); // MODIFICADO
          await Future.delayed(const Duration(milliseconds: 500));
          adapterState =
              await fbp.FlutterBluePlus.adapterState.first; // MODIFICADO
          if (adapterState != fbp.BluetoothAdapterState.on) {
            // MODIFICADO
            _log.info(
                '[BluetoothService] Bluetooth sigue apagado despuÃƒÆ’Ã‚Â©s de la solicitud.');
            return false;
          }
          _log.info(
              '[BluetoothService] Bluetooth ahora estÃƒÆ’Ã‚Â¡ encendido despuÃƒÆ’Ã‚Â©s de la solicitud.');
        } catch (e) {
          _log.info(
              '[BluetoothService] No se pudo solicitar encender Bluetooth (o no es soportado): $e');
          return false;
        }
      } else {
        return false;
      }
    }
    _log.info('[BluetoothService] El adaptador Bluetooth estÃƒÆ’Ã‚Â¡ encendido.');

    if (!await _ensurePermissions()) {
      _log.info('[BluetoothService] Permisos Bluetooth no concedidos.');
      return false;
    }
    _log.info('[BluetoothService] Permisos Bluetooth concedidos.');

    _log.info(
        '[BluetoothService] Iniciando escaneo BLE (lÃƒÆ’Ã‚Â³gica mejorada)...'); // MODIFICADO
    fbp.BluetoothDevice? foundDevice;
    final scanCompleter = Completer<fbp.BluetoothDevice?>();
    StreamSubscription<List<fbp.ScanResult>>? scanSubscription;
    Timer? scanTimeoutTimer;

    try {
      if (fbp.FlutterBluePlus.isScanningNow) {
        _log.info(
            '[BluetoothService] Escaneo previo en curso, deteniÃƒÆ’Ã‚Â©ndolo...');
        await fbp.FlutterBluePlus.stopScan();
        _log.info('[BluetoothService] Escaneo previo detenido.');
      }

      // ***** INICIO DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA PARA ESCANEO *****
      scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        // NUEVO LOG DE DEPURACIÃƒÆ’Ã¢â‚¬Å“N
        _log.info(
            '[BluetoothService] Scan results callback fired. Completer isCompleted: ${scanCompleter.isCompleted}. Results count: ${results.length}');

        if (scanCompleter.isCompleted) return;
        // _log.info('[BluetoothService] Lote de resultados de escaneo recibido (cantidad: ${results.length}).'); // Verboso si hay muchos dispositivos

        for (final r in results) {
          String advertisedName = r.advertisementData.advName;
          if (advertisedName.isEmpty) {
            advertisedName = r.advertisementData.localName;
          }
          // Usar platformName como ÃƒÆ’Ã‚Âºltimo recurso para la lÃƒÆ’Ã‚Â³gica de coincidencia de nombres,
          // pero priorizar advertisedName/localName para la identificaciÃƒÆ’Ã‚Â³n y el log.
          String nameForMatching = advertisedName.isNotEmpty
              ? advertisedName
              : r.device.platformName;
          String displayNameForLog = advertisedName.isNotEmpty
              ? advertisedName
              : (r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : r.device.remoteId.toString());

          final remoteId = r.device.remoteId;
          final rssi = r.rssi;
          final serviceUuids = r.advertisementData.serviceUuids;
          // Asumiendo que MeshUuids.service es del tipo fbp.Guid. Si fuera String, la comparaciÃƒÆ’Ã‚Â³n necesitarÃƒÆ’Ã‚Â­a .toString() y toLowerCase()
          bool hasMeshtasticServiceUuid =
              serviceUuids.any((uuid) => uuid == MeshUuids.service);

          _log.info(
              '[BluetoothService] Dispositivo visto: ID: $remoteId, RSSI: $rssi, NameForLog: "$displayNameForLog", AdvName: "${r.advertisementData.advName}", LocalName: "${r.advertisementData.localName}", PlatformName: "${r.device.platformName}", HasMeshtasticServiceUUID: $hasMeshtasticServiceUuid, All ServiceUUIDs: $serviceUuids');

          bool isCompatible = false;

          // 1. Comprobar por UUID de servicio Meshtastic
          if (hasMeshtasticServiceUuid) {
            _log.info(
                '[BluetoothService] Compatible por UUID: "$displayNameForLog" ($remoteId)');
            isCompatible = true;
          }

          // 2. Comprobar por nombre si no se encontrÃƒÆ’Ã‚Â³ por UUID y el nombre para matching no estÃƒÆ’Ã‚Â¡ vacÃƒÆ’Ã‚Â­o
          if (!isCompatible && nameForMatching.isNotEmpty) {
            final upperDeviceName = nameForMatching.toUpperCase();
            if (upperDeviceName
                    .startsWith('MESHTASTIC') || // Cubre Meshtastic_XXXX
                upperDeviceName.contains('TBEAM') ||
                upperDeviceName.contains('HELTEC') ||
                upperDeviceName.contains('LORA') ||
                upperDeviceName.contains('XIAO')) {
              _log.info(
                  '[BluetoothService] Compatible por Nombre: "$displayNameForLog" ($remoteId)');
              isCompatible = true;
            }
          }

          if (isCompatible) {
            _log.info(
                '[BluetoothService] Ãƒâ€šÃ‚Â¡Dispositivo Meshtastic compatible SELECCIONADO!: "$displayNameForLog" ($remoteId)');
            if (!scanCompleter.isCompleted) {
              scanCompleter.complete(r.device);
            }
            break; // Salir del bucle for interno una vez que se encuentra un dispositivo compatible
          }
        }
      }, onError: (e, s) {
        _log.info(
            '[BluetoothService] Error en el stream de scanResults: $e. Stack: $s');
        if (!scanCompleter.isCompleted) {
          scanCompleter.completeError(e, s);
        }
      });
      // ***** FIN DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA PARA ESCANEO *****

      _log.info(
          '[BluetoothService] Llamando a fbp.FlutterBluePlus.startScan() con timeout de ${_scanTimeoutDuration.inSeconds}s...');
      unawaited(fbp.FlutterBluePlus.startScan(
          timeout: _scanTimeoutDuration,
          androidScanMode: fbp.AndroidScanMode.lowLatency,
          withServices: [MeshUuids.service])); // MODIFICADO
      _log.info(
          '[BluetoothService] fbp.FlutterBluePlus.startScan() invocado (no bloqueante).');

      scanTimeoutTimer =
          Timer(_scanTimeoutDuration + const Duration(seconds: 1), () {
        if (!scanCompleter.isCompleted) {
          _log.info(
              '[BluetoothService] Timeout general del escaneo alcanzado por el Timer. No se encontrÃƒÆ’Ã‚Â³ dispositivo compatible.');
          scanCompleter.complete(null);
        }
      });

      _log.info(
          '[BluetoothService] Esperando resultado del escaneo (scanCompleter.future)...');
      foundDevice = await scanCompleter.future;
    } catch (e, s) {
      _log.info(
          '[BluetoothService] EXCEPCIÃƒÆ’Ã¢â‚¬Å“N durante la nueva lÃƒÆ’Ã‚Â³gica de escaneo: $e. Stack: $s');
      _lastErrorMessage = 'Error durante el escaneo BLE: ${e.toString()}';
    } finally {
      _log.info(
          '[BluetoothService] Bloque finally de la nueva lÃƒÆ’Ã‚Â³gica de escaneo.');
      scanTimeoutTimer?.cancel();
      // ***** INICIO DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA EN FINALLY *****
      if (fbp.FlutterBluePlus.isScanningNow) {
        _log.info(
            '[BluetoothService] El escaneo sigue activo en finally, deteniÃƒÆ’Ã‚Â©ndolo...');
        await fbp.FlutterBluePlus.stopScan();
        _log.info('[BluetoothService] Escaneo detenido en finally.');
      } else {
        _log.info(
            '[BluetoothService] El escaneo ya no estaba activo al llegar a finally (o FlutterBluePlus.stopScan() ya se completÃƒÆ’Ã‚Â³).');
      }
      await scanSubscription?.cancel();
      _log.info('[BluetoothService] SuscripciÃƒÆ’Ã‚Â³n a scanResults cancelada.');
      // ***** FIN DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA EN FINALLY *****
    }

    if (foundDevice == null) {
      // ***** INICIO DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA TRAS ESCANEO *****
      _log.info(
          '[BluetoothService] No se encontrÃƒÆ’Ã‚Â³ ningÃƒÆ’Ã‚Âºn dispositivo Meshtastic compatible tras el escaneo mejorado.');
      _lastErrorMessage ??=
          'No se encontrÃƒÆ’Ã‚Â³ dispositivo Meshtastic. AsegÃƒÆ’Ã‚Âºrate que estÃƒÆ’Ã‚Â¡ encendido, visible y cerca.';
      // ***** FIN DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA TRAS ESCANEO *****
      return false;
    }
    // ***** INICIO DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA ASIGNACIÃƒÆ’Ã¢â‚¬Å“N Dispositivo *****
    String displayName = foundDevice.platformName;
    // Usar platformName si estÃƒÆ’Ã‚Â¡ disponible, si no, usar el ID del dispositivo como fallback para el log.
    _log.info(
        '[BluetoothService] Dispositivo compatible asignado: "${displayName.isNotEmpty ? displayName : foundDevice.remoteId.toString()}" (ID: ${foundDevice.remoteId}).');
    // ***** FIN DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA ASIGNACIÃƒÆ’Ã¢â‚¬Å“N Dispositivo *****
    _dev = foundDevice;

    // --- Resto de la lÃƒÆ’Ã‚Â³gica de conexiÃƒÆ’Ã‚Â³n y descubrimiento de servicios ---
    _log.info('[BluetoothService] Intentando conectar a ${_dev!.remoteId}...');
    try {
      await _dev!.connect(autoConnect: false);
      _log.info('[BluetoothService] Conectado a ${_dev!.remoteId}.');
    } catch (e, s) {
      _log.info(
          '[BluetoothService] Error al conectar al dispositivo: $e. Stack: $s');
      _lastErrorMessage = 'Error al conectar: ${e.toString()}';
      await disconnect(); // Limpiar
      return false;
    }

    _log.info('[BluetoothService] Solicitando MTU 512...');
    try {
      await _dev!.requestMtu(512);
      _log.info('[BluetoothService] MTU solicitado.');
    } catch (e, s) {
      _log.info('[BluetoothService] Error solicitando MTU: $e. Stack: $s');
      // No es fatal, pero puede afectar el rendimiento
    }

    _log.info('[BluetoothService] Descubriendo servicios...');
    List<fbp.BluetoothService>? services;
    try {
      services = await _dev!.discoverServices();
      _log.info(
          '[BluetoothService] Servicios descubiertos (${services.length}).');
    } catch (e, s) {
      _log.info(
          '[BluetoothService] Error descubriendo servicios: $e. Stack: $s');
      _lastErrorMessage = 'Error descubriendo servicios: ${e.toString()}';
      await disconnect();
      return false;
    }

    for (final s in services) {
      if (s.uuid == MeshUuids.service) {
        _log.info(
            '[BluetoothService] Servicio Meshtastic encontrado: ${s.uuid}.');
        for (final c in s.characteristics) {
          if (c.uuid == MeshUuids.toRadio) {
            _toRadio = c;
            _log.info(
                '[BluetoothService] CaracterÃƒÆ’Ã‚Â­stica ToRadio encontrada.');
          }
          if (c.uuid == MeshUuids.fromRadio) {
            _fromRadio = c;
            _log.info(
                '[BluetoothService] CaracterÃƒÆ’Ã‚Â­stica FromRadio encontrada.');
          }
          if (c.uuid == MeshUuids.fromNum) {
            _fromNum = c;
            _log.info(
                '[BluetoothService] CaracterÃƒÆ’Ã‚Â­stica FromNum encontrada.');
          }
        }
      }
    }

    if (_toRadio == null || _fromRadio == null || _fromNum == null) {
      _log.info(
          '[BluetoothService] No se encontraron todas las caracterÃƒÆ’Ã‚Â­sticas Meshtastic requeridas.');
      _lastErrorMessage =
          'No se encontraron caracterÃƒÆ’Ã‚Â­sticas BLE Meshtastic requeridas.';
      await disconnect();
      return false;
    }
    _log.info(
        '[BluetoothService] Todas las caracterÃƒÆ’Ã‚Â­sticas Meshtastic encontradas.');

    _lastFromNum = 0;
    _log.info(
        '[BluetoothService] Inicializando notificaciones FromRadio y FromNum...');
    await _initializeFromRadioNotifications();
    await _primeFromRadioMailbox();
    await _initializeFromNumNotifications();
    try {
      await _startConfigSession();
    } catch (e, s) {
      _log.info(
          '[BluetoothService] Error iniciando sesion de configuracion: $e. Stack: $s');
      _lastErrorMessage =
          'Error iniciando sesion de configuracion: ${e.toString()}';
      await disconnect();
      return false;
    }
    _log.info(
        '[BluetoothService] Notificaciones inicializadas y sesion configurada.');

    try {
      await _ensureMyNodeNum();
      _log.info('[BluetoothService] MyNodeNum asegurado: $_myNodeNum.');
    } catch (e, s) {
      _log.info(
          '[BluetoothService] Error crÃƒÆ’Ã‚Â­tico durante _ensureMyNodeNum despuÃƒÆ’Ã‚Â©s de la conexiÃƒÆ’Ã‚Â³n: $e. Stack: $s');
      _lastErrorMessage = 'Error obteniendo info del nodo: ${e.toString()}';
      await disconnect();
      return false;
    }

    _log.info('[BluetoothService] connectAndInit completado exitosamente.');
    return true;
  }

  Future<void> disconnect() async {
    _log.info('[BluetoothService] Iniciando desconexiÃƒÆ’Ã‚Â³n...');
    try {
      await _fromRadio?.setNotifyValue(false);
      _log.info('[BluetoothService] Notificaciones de FromRadio desactivadas.');
    } catch (e) {
      _log.info(
          '[BluetoothService] Error desactivando notificaciones FromRadio: $e');
    }
    try {
      await _fromNum?.setNotifyValue(false);
      _log.info('[BluetoothService] Notificaciones de FromNum desactivadas.');
    } catch (e) {
      _log.info(
          '[BluetoothService] Error desactivando notificaciones FromNum: $e');
    }

    await _disposeRadioStreams();
    _log.info('[BluetoothService] Streams de radio eliminados.');

    // ***** INICIO DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA EN DISCONNECT *****
    try {
      // Asegurarse de que _dev no es null y estÃƒÆ’Ã‚Â¡ conectado antes de intentar desconectar.
      // fbp.BluetoothDevice.isConnected utiliza una llamada nativa que puede ser lenta o fallar si el dispositivo ya no existe.
      // Una comprobaciÃƒÆ’Ã‚Â³n de nulidad para _dev es un primer paso seguro.
      if (_dev != null) {
        // Idealmente, se consultarÃƒÆ’Ã‚Â­a un estado de conexiÃƒÆ’Ã‚Â³n mantenido localmente si `_dev!.isConnected` es problemÃƒÆ’Ã‚Â¡tico.
        // Por ahora, asumimos que si _dev no es null, es vÃƒÆ’Ã‚Â¡lido intentar la desconexiÃƒÆ’Ã‚Â³n.
        // La propia llamada a disconnect de flutter_blue_plus deberÃƒÆ’Ã‚Â­a manejar si ya no estÃƒÆ’Ã‚Â¡ conectado.
        _log.info('[BluetoothService] Intentando desconectar dispositivo...');
        await _dev!.disconnect();
        _log.info(
            '[BluetoothService] Dispositivo desconectado de la instancia.');
      } else {
        _log.info(
            '[BluetoothService] El dispositivo ya era nulo, no se requiere desconexiÃƒÆ’Ã‚Â³n.');
      }
    } catch (e) {
      _log.info(
          '[BluetoothService] Error durante la desconexiÃƒÆ’Ã‚Â³n del dispositivo: $e');
      // No relanzar, ya que estamos limpiando.
    }
    // ***** FIN DE SECCIÃƒÆ’Ã¢â‚¬Å“N MODIFICADA EN DISCONNECT *****

    _dev = null;
    _toRadio = null;
    _fromRadio = null;
    _fromNum = null;
    _lastFromNum = 0;
    _myNodeNum = null;
    _nodeNumConfirmed = false;
    _sessionPasskey = Uint8List(0);
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _configNonce = 0;
    _log.info('[BluetoothService] Estado de BluetoothService limpiado.');
  }

  // -------- lectura de configuraciÃƒÆ’Ã‚Â³n ----------
  Future<NodeConfig?> readConfig() async {
    if (_toRadio == null || _fromRadioQueue == null) {
      _log.info(
          '[BluetoothService] readConfig abortado: caracterÃƒÆ’Ã‚Â­sticas BLE no inicializadas (toRadio o fromRadioQueue nulos).');
      _lastErrorMessage =
          'CaracterÃƒÆ’Ã‚Â­sticas BLE no disponibles para leer config.';
      return null;
    }

    try {
      await _ensureMyNodeNum(); // Asegura que tenemos el NodeNum antes de proceder
    } catch (e, s) {
      _log.info(
          '[BluetoothService] readConfig fallÃƒÆ’Ã‚Â³ en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage =
          'Error al obtener NodeNum para leer config: ${e.toString()}';
      throw StateError(
          'Error al obtener NodeNum para leer config: ${e.toString()}'); // Relanzar para que la UI lo maneje
    }

    _log.info(
        '[BluetoothService] Iniciando lectura de configuraciÃƒÆ’Ã‚Â³n del nodo $_myNodeNum...');
    final cfgOut =
        NodeConfig(); // Objeto para almacenar la configuraciÃƒÆ’Ã‚Â³n leÃƒÆ’Ã‚Â­da

    var primaryChannelCaptured = false;
    var primaryChannelLogged =
        false; // Usado para loguear la captura del canal primario solo una vez

    void applyAdminToConfig(admin.AdminMessage message) {
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
            _log.info(
                '[BluetoothService] readConfig: Canal PRIMARIO ${cfgOut.channelIndex} capturado con PSK (longitud: ${cfgOut.key.length} bytes).');
          }
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

    Future<bool> requestAndApply(
      admin.AdminMessage msgToSend,
      bool Function(admin.AdminMessage) matcher,
      String description, // AÃƒÆ’Ã‚Â±adido para logging descriptivo
    ) async {
      _log.info('[BluetoothService] readConfig: Solicitando $description...');
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
        _log.info(
            '[BluetoothService] readConfig: Respuesta(s) recibida(s) para $description.');
      } on TimeoutException catch (e) {
        _log.info(
            '[BluetoothService] readConfig: Timeout (_defaultResponseTimeout) esperando $description. Error: ${e.message}');
        _lastErrorMessage = 'Timeout esperando $description.';
        return false;
      } catch (e, s) {
        _log.info(
            '[BluetoothService] readConfig: Error durante _sendAndReceive para $description: $e. Stack: $s');
        _lastErrorMessage = 'Error solicitando $description: ${e.toString()}';
        return false;
      }

      var matched = false;
      for (final f in frames) {
        final adminMsg = _decodeAdminMessage(f);
        if (adminMsg == null) {
        continue;
      }
        applyAdminToConfig(adminMsg);
        if (matcher(adminMsg)) {
        matched = true;
      }
      }
      if (!matched)
        _log.info(
            '[BluetoothService] readConfig: No se encontrÃƒÆ’Ã‚Â³ un match especÃƒÆ’Ã‚Â­fico para $description en las respuestas recibidas.');
      return matched;
    }

    var receivedAnyResponse = false;
    final ownerReceived = await requestAndApply(
        admin.AdminMessage()..getOwnerRequest = true,
        (msg) => msg.hasGetOwnerResponse(),
        'informaciÃƒÆ’Ã‚Â³n del propietario (Owner Info)');
    if (ownerReceived) {
      receivedAnyResponse = true;
    }

    final loraReceived = await requestAndApply(
        admin.AdminMessage()
          ..getConfigRequest = admin.AdminMessage_ConfigType.LORA_CONFIG,
        (msg) =>
            msg.hasGetConfigResponse() &&
            msg.getConfigResponse.hasLora() &&
            msg.getConfigResponse.lora.hasRegion(),
        'configuraciÃƒÆ’Ã‚Â³n LoRa (para regiÃƒÆ’Ã‚Â³n)');
    if (loraReceived) {
      receivedAnyResponse = true;
    }

    final indicesToQuery = <int>{};
    if (cfgOut.channelIndex > 0 && cfgOut.channelIndex <= 8)
      indicesToQuery.add(cfgOut.channelIndex);
    if (!primaryChannelCaptured) {
      indicesToQuery.addAll([0, 1, 2]);
    }

    for (final index in indicesToQuery) {
      if (primaryChannelCaptured) {
        break;
      }
      final channelReceived = await requestAndApply(
          admin.AdminMessage()..getChannelRequest = index + 1,
          (msg) =>
              msg.hasGetChannelResponse() &&
              msg.getChannelResponse.index == index,
          'canal con ÃƒÆ’Ã‚Â­ndice $index');
      if (channelReceived) {
        receivedAnyResponse = true;
      }
    }

    if (!primaryChannelCaptured && cfgOut.key.isEmpty) {
      _log.info(
          '[BluetoothService] readConfig: No se capturÃƒÆ’Ã‚Â³ canal primario, intentando consulta explÃƒÆ’Ã‚Â­cita por canal 0.');
      final channelZeroReceived = await requestAndApply(
          admin.AdminMessage()..getChannelRequest = 0 + 1,
          (msg) =>
              msg.hasGetChannelResponse() && msg.getChannelResponse.index == 0,
          'canal con ÃƒÆ’Ã‚Â­ndice 0 (intento adicional)');
      if (channelZeroReceived) {
      receivedAnyResponse = true;
    }
    }

    final serialReceived = await requestAndApply(
        admin.AdminMessage()
          ..getModuleConfigRequest =
              admin.AdminMessage_ModuleConfigType.SERIAL_CONFIG,
        (msg) =>
            msg.hasGetModuleConfigResponse() &&
            msg.getModuleConfigResponse.hasSerial(),
        'configuraciÃƒÆ’Ã‚Â³n del mÃƒÆ’Ã‚Â³dulo Serial');
    if (serialReceived) {
      receivedAnyResponse = true;
    }

    if (!receivedAnyResponse && cfgOut.longName.isEmpty && cfgOut.key.isEmpty) {
      _log.info(
          '[BluetoothService] readConfig: No se recibiÃƒÆ’Ã‚Â³ ninguna respuesta vÃƒÆ’Ã‚Â¡lida de configuraciÃƒÆ’Ã‚Â³n del dispositivo.');
      _lastErrorMessage =
          'No se recibiÃƒÆ’Ã‚Â³ respuesta de configuraciÃƒÆ’Ã‚Â³n del nodo.';
      throw TimeoutException(
          'No se recibiÃƒÆ’Ã‚Â³ ninguna respuesta de configuraciÃƒÆ’Ã‚Â³n del dispositivo tras mÃƒÆ’Ã‚Âºltiples intentos.');
    } else if (!primaryChannelCaptured && cfgOut.key.isEmpty) {
      _log.info(
          '[BluetoothService] readConfig: Advertencia - No se pudo obtener la clave del canal (PSK) principal.');
      _lastErrorMessage = 'Advertencia: No se pudo obtener PSK del canal.';
    }

    _log.info(
        '[BluetoothService] Lectura de configuraciÃƒÆ’Ã‚Â³n completada para el nodo $_myNodeNum. Config leÃƒÆ’Ã‚Â­da: ${cfgOut.toString()}');
    return cfgOut;
  }

  // -------- escritura de configuraciÃƒÆ’Ã‚Â³n ----------
  Future<void> writeConfig(NodeConfig cfgIn) async {
    if (_toRadio == null || _fromRadioQueue == null) {
      _log.info(
          '[BluetoothService] writeConfig abortado: caracterÃƒÆ’Ã‚Â­sticas BLE no inicializadas.');
      _lastErrorMessage =
          'CaracterÃƒÆ’Ã‚Â­sticas BLE no disponibles para escribir config.';
      return;
    }
    try {
      await _ensureMyNodeNum();
    } catch (e, s) {
      _log.info(
          '[BluetoothService] writeConfig fallÃƒÆ’Ã‚Â³ en _ensureMyNodeNum: $e. Stack: $s');
      _lastErrorMessage =
          'Error al obtener NodeNum para escribir config: ${e.toString()}';
      throw StateError(
          'Error al obtener NodeNum para escribir config: ${e.toString()}');
    }

    _log.info(
        '[BluetoothService] Iniciando escritura de configuraciÃƒÆ’Ã‚Â³n para el nodo $_myNodeNum...');

    Future<void> sendAdminCommand(
        admin.AdminMessage msg, String description) async {
      _log.info(
          '[BluetoothService] writeConfig: Enviando comando: $description');
      try {
        await _sendAndReceive(
          _wrapAdminToToRadio(msg),
          timeout: _defaultResponseTimeout,
        );
        _log.info(
            "[BluetoothService] writeConfig: Comando enviado y ACK recibido para '$description'.");
      } on TimeoutException catch (e) {
        _log.info(
            "[BluetoothService] writeConfig: Timeout esperando ACK para '$description'. Error: ${e.message}");
        _lastErrorMessage = "Timeout enviando '$description'";
        throw TimeoutException(
            "Timeout al enviar '$description': ${e.toString()}");
      } catch (e, s) {
        _log.info(
            "[BluetoothService] writeConfig: Error enviando '$description': $e. Stack: $s");
        _lastErrorMessage = "Error enviando '$description'";
        throw StateError("Error al enviar '$description': ${e.toString()}");
      }
    }

    try {
      final userMsg = mesh.User()
        ..shortName = cfgIn.shortName
        ..longName = cfgIn.longName;
      await sendAdminCommand(
          admin.AdminMessage()..setOwner = userMsg, "SetOwner (Nombres)");

      final settings = ch.ChannelSettings()
        ..name = "CH${cfgIn.channelIndex}"
        ..psk = cfgIn.key;
      final channel = ch.Channel()
        ..index = cfgIn.channelIndex
        ..role = ch.Channel_Role.PRIMARY
        ..settings = settings;
      await sendAdminCommand(admin.AdminMessage()..setChannel = channel,
          "SetChannel (ÃƒÆ’Ã‚Ândice ${cfgIn.channelIndex})");

      final serialCfg = mod.ModuleConfig_SerialConfig()
        ..enabled = true
        ..baud = cfgIn.baudRate
        ..mode = _serialModeFromString(cfgIn.serialModeAsString);
      final moduleCfg = mod.ModuleConfig()..serial = serialCfg;
      await sendAdminCommand(admin.AdminMessage()..setModuleConfig = moduleCfg,
          "SetModuleConfig (Serial)");

      final lora = cfg.Config_LoRaConfig()
        ..region = _regionFromString(cfgIn.frequencyRegionAsString);
      final configMsg = cfg.Config()..lora = lora;
      await sendAdminCommand(
          admin.AdminMessage()..setConfig = configMsg, "SetConfig (LoRa)");

      _log.info(
          '[BluetoothService] Escritura de configuraciÃƒÆ’Ã‚Â³n: todos los comandos enviados al nodo $_myNodeNum.');
    } catch (e) {
      _log.info(
          '[BluetoothService] Error durante el proceso general de writeConfig: $e');
      _lastErrorMessage ??= 'Error general durante writeConfig';
      throw StateError(
          'Error durante la escritura de la configuraciÃƒÆ’Ã‚Â³n: ${e.toString()}');
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
    } catch (e, s) {
      // AÃƒÆ’Ã‚Â±adir stack trace al log de error
      _log.info(
          '[BluetoothService] Error al deserializar AdminMessage desde payload: $e. Stack: $s');
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
        _log.info(
            '[BluetoothService] _serialModeFromString: Modo desconocido \'$s\', usando DEFAULT.');
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
        _log.info(
            '[BluetoothService] _regionFromString: RegiÃƒÆ’Ã‚Â³n desconocida \'$s\', usando EU_868 por defecto.');
        return cfg.Config_LoRaConfig_RegionCode.EU_868;
    }
  }
}



