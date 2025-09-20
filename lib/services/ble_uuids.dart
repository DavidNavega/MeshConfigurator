import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// UUIDs oficiales del servicio BLE de Meshtastic.
class MeshUuids {
  static final Guid service =
      Guid("6ba1b218-15a8-461f-9fa8-5dcae273eafd");

  /// Escribe ToRadio (protobuf ToRadio)
  static final Guid toRadio =
      Guid("f75c76d2-129e-4dad-a1dd-7866124401e7");

  /// Lee FromRadio (protobuf FromRadio)
  static final Guid fromRadio =
      Guid("2c55e69e-4993-11ed-b878-0242ac120002");

  /// Notificación: hay datos en FromRadio
  static final Guid fromNum =
      Guid("ed9da18c-a800-4f66-a670-aa7547e34453");

  /// (Opcional) Logs
  static final Guid logs =
      Guid("5a3d6e49-06e6-4423-9944-e9de8cdf9547");
}
