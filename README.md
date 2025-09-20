# Meshtastic Configurator (Flutter) — Paquete v2.6.1.1

**Basado en Meshtastic v2.6.11** (protobufs/firmware).  
Este paquete se distribuye con el nombre **v2.6.1.1** por su compatibilidad con los protos de esa version.

## Características
- Conexión por **BLE**, **TCP/HTTP** y **USB serie**.
- Lectura/escritura: nombre corto/largo, canal + PSK, salida serie (WPL↔CALTOPO, TLL↔NMEA), baudrate (4800…115200).
- **Frecuencia LoRa**: 433 / 868 / 915 MHz (RadioConfig.LoRaConfig.region).
- UI rojo/blanco/negro con logo en `assets/logo.png`.

## Requisitos previos
1. Flutter 3.x + Android SDK
2. `protoc` + `protoc_plugin` para Dart
3. **.pb.dart generados de Meshtastic v2.6.11** (incluidos en `lib/proto/meshtastic/`).

## Comandos
```bash
flutter pub get
flutter run
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

> Si se cambia el firmware a otro tag, regenera los `.pb.dart` con `tools/generate_protos.sh`
> apuntando al tag equivalente de los .proto oficiales.
