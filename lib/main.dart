import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/config_provider.dart';
import 'screens/home_screen.dart';
import 'services/bluetooth_service.dart';
import 'services/tcp_service.dart';
import 'services/usb_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigProvider(
        bluetoothService: BluetoothService(),
        usbService: UsbService(),
        tcpService: TcpHttpService(),
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
