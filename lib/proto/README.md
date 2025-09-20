Este directorio contiene los `.pb.dart` generados desde los `.proto` oficiales de Meshtastic **v2.6.11**.
Si actualizas el firmware a otro tag, regenera con:

  dart pub global activate protoc_plugin
  protoc -I <ruta/protobufs> --dart_out=lib/proto     <ruta/protobufs>/meshtastic/mesh.proto     <ruta/protobufs>/meshtastic/admin.proto     <ruta/protobufs>/meshtastic/channel.proto     <ruta/protobufs>/meshtastic/config.proto     <ruta/protobufs>/meshtastic/module_config.proto
