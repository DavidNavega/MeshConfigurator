import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/config_provider.dart';
import 'services/radio/radio_coordinator.dart';
import 'services/radio/transport/bluetooth_transport.dart';
import 'services/radio/transport/usb_transport.dart';

import 'screens/home_screen.dart';

void main() {
  final bleCoordinator = RadioCoordinator(BluetoothTransport());
  final usbCoordinator = RadioCoordinator(UsbTransport());
  runApp(MyApp(
    bleCoordinator: bleCoordinator,
    usbCoordinator: usbCoordinator,
  ));
}

class MyApp extends StatelessWidget {
  final RadioCoordinator bleCoordinator;
  final RadioCoordinator usbCoordinator;
  const MyApp({
    super.key,
    required this.bleCoordinator,
    required this.usbCoordinator,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigProvider(
        bleCoordinator: bleCoordinator,
        usbCoordinator: usbCoordinator,
      ),
      child: MaterialApp(
        title: 'Buoys Configurator',
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Colors.red,
            secondary: Colors.white,
            surface: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.red),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
