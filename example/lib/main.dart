import 'package:flutter/material.dart';
import 'package:flutter_gsmsip/flutter_gsmsip.dart';

void main() {
  runApp(const MinimalExampleApp());
}

class MinimalExampleApp extends StatelessWidget {
  const MinimalExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_gsmsip Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_gsmsip Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Library Imported Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'flutter_gsmsip is working',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _showLibraryInfo(context);
              },
              child: const Text('Show Library Info'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLibraryInfo(BuildContext context) {
    // Demonstrate that library types are accessible
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Library Types Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeRow('SipAccount'),
            _buildTypeRow('SipCall'),
            _buildTypeRow('SipEvent'),
            _buildTypeRow('GatewayConfig'),
            _buildTypeRow('GatewayStatus'),
            _buildTypeRow('CallRouting'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRow(String typeName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(typeName),
        ],
      ),
    );
  }
}
