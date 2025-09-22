import 'package:Buoys_configurator/exceptions/routing_error_exception.dart';
import 'package:Buoys_configurator/proto/meshtastic/mesh.pb.dart' as mesh;
import 'package:Buoys_configurator/proto/meshtastic/portnums.pbenum.dart' as port;

RoutingErrorException? routingErrorFromFrame(mesh.FromRadio frame) {
  if (!frame.hasPacket()) return null;
  final packet = frame.packet;
  if (!packet.hasDecoded()) return null;
  final decoded = packet.decoded;
  if (decoded.portnum != port.PortNum.ROUTING_APP) return null;
  if (!decoded.hasPayload() || decoded.payload.isEmpty) return null;

  final payload = decoded.payload;
  late final mesh.Routing routing;
  try {
    routing = mesh.Routing.fromBuffer(payload);
  } catch (error) {
    throw StateError(
      'No se pudo decodificar el payload de Routing_APP: ${error.toString()}',
    );
  }

  if (routing.hasErrorReason() &&
      routing.errorReason != mesh.Routing_Error.NONE) {
    final packetId = packet.hasId() ? packet.id : null;
    return RoutingErrorException(routing.errorReason, packetId: packetId);
  }

  return null;
}

void throwIfRoutingError(mesh.FromRadio frame) {
  final routingError = routingErrorFromFrame(frame);
  if (routingError != null) {
    throw routingError;
  }
}