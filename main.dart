import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const SmartHomeApp());

const List<String> roomNames = [
  'Living Room', 'Bedroom 1', 'Bedroom 2', 'Kitchen',
  'Bathroom',    'Hallway',   'Garage',    'Garden',
];
const List<IconData> roomIcons = [
  Icons.weekend,    Icons.bed,          Icons.bed_outlined, Icons.kitchen,
  Icons.bathtub,    Icons.door_sliding, Icons.garage,       Icons.yard,
];

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Smart Home',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const ConnectScreen(),
      );
}

// ── Connect Screen ────────────────────────────────────────
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _ipController = TextEditingController(text: '192.168.1.100');
  String? _error;

  void _connect() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => _error = 'Enter an IP address');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(ip: ip)),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Home — Connect')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 32),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'ESP32 IP Address',
                hintText: '192.168.1.100',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _connect,
                child: const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Screen ───────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String ip;
  const HomeScreen({super.key, required this.ip});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WebSocketChannel? _channel;
  final List<bool> _states = List.filled(8, false);
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://${widget.ip}:81'),
      );

      setState(() => _connected = true);

      _channel!.stream.listen(
        (data) {
          final parts = data.toString().split(',');
          if (parts.length != 8) return;
          setState(() {
            for (int i = 0; i < 8; i++) {
              _states[i] = parts[i].trim() == '1';
            }
          });
        },
        onDone:  () => setState(() => _connected = false),
        onError: (_) => setState(() => _connected = false),
      );
    } catch (_) {
      setState(() => _connected = false);
    }
  }

  void _toggle(int i) {
    if (!_connected || _channel == null) return;
    final next = !_states[i];
    _channel!.sink.add('R$i:${next ? "ON" : "OFF"}');
    setState(() => _states[i] = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              Icon(
                _connected ? Icons.wifi : Icons.wifi_off,
                color: _connected ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 4),
              Text(
                _connected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: _connected ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ]),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          crossAxisSpacing: 16,
          mainAxisSpacing:  16,
        ),
        itemCount: 8,
        itemBuilder: (_, i) => _RelayCard(
          label:   roomNames[i],
          icon:    roomIcons[i],
          isOn:    _states[i],
          enabled: _connected,
          onTap:   () => _toggle(i),
        ),
      ),
    );
  }
}

// ── Relay Card ────────────────────────────────────────────
class _RelayCard extends StatelessWidget {
  const _RelayCard({
    required this.label,
    required this.icon,
    required this.isOn,
    required this.enabled,
    required this.onTap,
  });

  final String   label;
  final IconData icon;
  final bool     isOn, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const onColor  = Color(0xFFFFB300);
    const offColor = Color(0xFF37474F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color:        isOn ? onColor.withOpacity(0.85) : offColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isOn
            ? [const BoxShadow(color: Color(0x80FFB300), blurRadius: 12, spreadRadius: 2)]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap:        enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(icon, size: 42,
                     color: isOn ? Colors.white : Colors.grey),
                Text(label,
                     textAlign: TextAlign.center,
                     style: const TextStyle(
                       fontSize: 14, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOn ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOn ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}