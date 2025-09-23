import 'package:buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;

class RoutingErrorException implements Exception {
  RoutingErrorException(this.reason, {this.packetId});

  final mesh.Routing_Error reason;
  final int? packetId;

  String get message {
    final reasonName = reason.name.isNotEmpty
        ? reason.name
        : 'código ${reason.value}';
    final base = 'El radio reportó un error de enrutamiento ($reasonName)';
    if (packetId != null) {
      return '$base para el paquete $packetId.';
    }
    return '$base.';
  }

  @override
  String toString() => message;
}