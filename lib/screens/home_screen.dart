import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _shortC = TextEditingController();
  final _longC = TextEditingController();
  final _keyC = TextEditingController();
  final _tcpUrlC = TextEditingController(text: "http://192.168.1.4:4403");
  ConfigProvider? _provider;

  void _syncControllers(ConfigProvider provider) {
    final cfg = provider.cfg;
    final keyText = provider.keyDisplay;

    TextSelection sel(String text) =>
        TextSelection.collapsed(offset: text.length);

    if (_shortC.text != cfg.shortName) {
      _shortC.value =
          TextEditingValue(text: cfg.shortName, selection: sel(cfg.shortName));
    }
    if (_longC.text != cfg.longName) {
      _longC.value =
          TextEditingValue(text: cfg.longName, selection: sel(cfg.longName));
    }
    if (_keyC.text != keyText) {
      _keyC.value = TextEditingValue(text: keyText, selection: sel(keyText));
    }
  }

  void _onProviderUpdate() {
    final provider = _provider;
    if (provider == null) return;
    if (!mounted) return;
    _syncControllers(provider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ConfigProvider>();
    if (identical(provider, _provider)) {
      return;
    }
    _provider?.removeListener(_onProviderUpdate);
    _provider = provider;
    _provider?.addListener(_onProviderUpdate);
    _syncControllers(provider);
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderUpdate);
    _shortC.dispose();
    _longC.dispose();
    _keyC.dispose();
    _tcpUrlC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ConfigProvider>();

    InputDecoration deco(String label,
        {String? errorText, String? helper}) =>
        InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: errorText,
          helperText: helper,
          helperStyle: const TextStyle(color: Colors.white60),
        );

    const baudOptions = <String>[
      '4800',
      '9600',
      '19200',
      '38400',
      '57600',
      '115200',
    ];
    const dropdownTextStyle = TextStyle(color: Colors.red);
    final channelOptions = List<int>.generate(8, (i) => i + 1);
    if (!channelOptions.contains(p.cfg.channelIndex)) {
      channelOptions.insert(0, p.cfg.channelIndex);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Buoys Configurator'),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Image.asset('assets/logo.png',
                      height: 64, fit: BoxFit.contain)),
              const SizedBox(height: 16),

              // ---- Conexión ----
              Card(
                color: const Color(0xFF121212),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text('Conexión',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: p.busy ? null : () async {
                              await p.connectBle();
                            },
                            icon: const Icon(Icons.bluetooth),
                            label: const Text('Bluetooth'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white),
                          ),
                          ElevatedButton.icon(
                            onPressed: p.busy ? null : () async {
                              await p.connectUsb();
                            },
                            icon: const Icon(Icons.usb),
                            label: const Text('USB'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white),
                          ),
                          if (p.hasTcpFixed)
                            ElevatedButton.icon(
                              onPressed: p.busy ? null : () async {
                                await p.connectTcp(p.fixedTcpUrl ?? '');
                              },
                              icon: const Icon(Icons.wifi),
                              label: const Text('TCP Fijo'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                            )
                          else ...[
                            SizedBox(
                              width: 260,
                              child: TextField(
                                controller: _tcpUrlC,
                                style: const TextStyle(color: Colors.white),
                                decoration: deco(
                                    'URL TCP/HTTP (p.ej. http://192.168.4.1:4403)'),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: p.busy ? null : () async {
                                await p.connectTcp(_tcpUrlC.text.trim());
                              },
                              icon: const Icon(Icons.wifi),
                              label: const Text('TCP/HTTP'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Estado: ${p.status}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: p.busy
                                ? null
                                : () async {
                              await p.readConfig();
                              _syncControllers(p);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black),
                            child: const Text('Leer configuración'),
                          ),
                          ElevatedButton(
                            onPressed: p.busy
                                ? null
                                : () async {
                              await p.writeConfig();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Configuración enviada')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black),
                            child: const Text('Guardar configuración'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---- Parámetros del Nodo ----
              Card(
                color: const Color(0xFF121212),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text('Parámetros Boya',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _shortC,
                        style: const TextStyle(color: Colors.red),
                        decoration: deco('Nombre Corto'),
                        onChanged: (v) => context
                            .read<ConfigProvider>()
                            .setNames(v, p.cfg.longName),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _longC,
                        style: const TextStyle(color: Colors.red),
                        decoration: deco('Nombre Largo'),
                        onChanged: (v) => context
                            .read<ConfigProvider>()
                            .setNames(p.cfg.shortName, v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: p.cfg.channelIndex,
                        items: channelOptions
                            .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text('Canal $i',
                                style: const TextStyle(color: Colors.red))))
                            .toList(),
                        onChanged: (v) => context
                            .read<ConfigProvider>()
                            .setChannelIndex(v ?? p.cfg.channelIndex),
                        decoration: deco('Canal (índice)'),
                        dropdownColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keyC,
                        style: const TextStyle(color: Colors.red),
                        decoration: deco(
                          'Llave (PSK)',
                          errorText: p.keyError,
                          helper: 'Vacío, 1, 16 o 32 bytes en hex o Base64.',
                        ),
                        onChanged: (v) =>
                            context.read<ConfigProvider>().setKeyText(v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: p.serialModeDisplay,
                        items: const [
                          DropdownMenuItem(
                              value: 'DEFAULT',
                              child: Text('DEFAULT',
                                  style: TextStyle(color: Colors.red))),
                          DropdownMenuItem(
                              value: 'PROTO',
                              child: Text('PROTO',
                                  style: TextStyle(color: Colors.red))),
                          DropdownMenuItem(
                              value: 'TLL',
                              child: Text('TLL',
                                  style: TextStyle(color: Colors.red))),
                          DropdownMenuItem(
                              value: 'WPL',
                              child: Text('WPL',
                                  style: TextStyle(color: Colors.red))),
                        ],
                        onChanged: (v) => context
                            .read<ConfigProvider>()
                            .setSerialMode(v ?? 'DEFAULT'),
                        decoration: deco('Salida de datos serie'),
                        dropdownColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: p.baudDisplay,
                        items: baudOptions
                            .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value,
                              style: dropdownTextStyle),
                        ))
                            .toList(),
                        onChanged: (v) => context
                            .read<ConfigProvider>()
                            .setBaud(v ?? '9600'),
                        decoration: deco('Baudrate salida serie'),
                        dropdownColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: p.regionDisplay,
                        items: const [
                          DropdownMenuItem(
                              value: '433',
                              child: Text('433 MHz',
                                  style: TextStyle(color: Colors.red))),
                          DropdownMenuItem(
                              value: '868',
                              child: Text('868 MHz',
                                  style: TextStyle(color: Colors.red))),
                          DropdownMenuItem(
                              value: '915',
                              child: Text('915 MHz',
                                  style: TextStyle(color: Colors.red))),
                        ],
                        onChanged: (v) => context
                            .read<ConfigProvider>()
                            .setFrequencyRegion(v ?? '868'),
                        decoration: deco('Frecuencia'),
                        dropdownColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              if (p.busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

