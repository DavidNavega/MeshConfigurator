import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/config_provider.dart';
import 'services/radio/transport/radio_transport_manager.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    RadioTransportManager? transportManager,
  }) : transportManager = transportManager ?? RadioTransportManager();

  final RadioTransportManager transportManager;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigProvider(transportManager: transportManager),
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
