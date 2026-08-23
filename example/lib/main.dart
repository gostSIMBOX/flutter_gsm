import 'package:flutter/material.dart';
import 'package:flutter_gsm/flutter_gsm.dart';

void main() {
  runApp(const FlutterGsmExampleApp());
}

class FlutterGsmExampleApp extends StatelessWidget {
  const FlutterGsmExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_gsm example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ModemListScreen(),
    );
  }
}

/// Minimal demo of [ModemRepository]: discover modems, show live state via
/// [ModemRepository.modemEvents], dial/send SMS/send USSD on the first one.
class ModemListScreen extends StatefulWidget {
  const ModemListScreen({super.key});

  @override
  State<ModemListScreen> createState() => _ModemListScreenState();
}

class _ModemListScreenState extends State<ModemListScreen> {
  final ModemRepository _repository = ModemRepositoryImpl();

  List<ModemDevice> _modems = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository.modemEvents.listen((_) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final modems = await _repository.listModems();
      if (mounted) setState(() { _modems = modems; _error = null; });
    } on ModemException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _dial(String modemId) async {
    try {
      await _repository.dial(modemId, '+1234567890');
      _showSnack('Call initiated on $modemId');
    } on ModemException catch (e) {
      _showSnack('Dial failed: $e');
    }
  }

  Future<void> _sendSms(String modemId) async {
    try {
      await _repository.sendSms(modemId, '+1234567890', 'Test message');
      _showSnack('SMS sent from $modemId');
    } on ModemException catch (e) {
      _showSnack('SMS failed: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_gsm example')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _modems.length,
                itemBuilder: (context, index) {
                  final modem = _modems[index];
                  return ListTile(
                    title: Text(modem.displayName ?? modem.id),
                    subtitle: Text('${modem.state.name} · signal: ${modem.signal ?? '?'}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () => _dial(modem.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sms),
                          onPressed: () => _sendSms(modem.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
