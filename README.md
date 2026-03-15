# flutter_gsmsip

[![Pub Version](https://img.shields.io/pub/v/flutter_gsmsip.svg)](https://pub.dev/packages/flutter_gsmsip)
[![License: NativeMindNONC](https://img.shields.io/badge/license-NativeMindNONC-blue.svg)](LICENSE)

A Flutter plugin for Android that provides GSM, SIP, and SMPP functionality. Enables voice calls and SMS over SIP with GSM integration for building telephony gateway applications.

## 📱 Features

- **SIP Voice Calls** - Make and receive SIP calls using PJSIP native stack
- **SMS over SIP** - Send and receive SMS messages via SIP
- **GSM Integration** - Direct GSM telephony integration for SMS and calls
- **SMPP Protocol** - SMPP support for SMS center connectivity
- **Multi-Gateway** - Support for multiple SIP accounts and gateways
- **Event Streaming** - Real-time event streaming for call and message states

## 📦 Installation

Add this to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  flutter_gsmsip: ^0.1.0
```

Or use a local path for development:

```yaml
dependencies:
  flutter_gsmsip:
    path: ../flutter_gsmsip
```

Then run:

```bash
flutter pub get
```

### Android Configuration

Ensure your `AndroidManifest.xml` includes the required permissions:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

## 🚀 Quick Start

### 1. Initialize the Library

```dart
import 'package:flutter_gsmsip/flutter_gsmsip.dart';

final bridge = GsmSipBridge();

// Initialize the GSM SIP bridge
await bridge.initialize();
```

### 2. Configure a SIP Account

```dart
final account = SipAccount(
  id: 'account-1',
  username: 'user',
  password: 'password',
  domain: 'sip.example.com',
  port: 5060,
);

final config = GatewayConfig(
  sipAccount: account,
  autoAnswer: false,
  enableLogging: true,
);
```

### 3. Make a SIP Call

```dart
try {
  await bridge.makeCall('+1234567890');
} catch (e) {
  print('Call failed: $e');
}
```

### 4. Send SMS

```dart
try {
  await bridge.sendSms('+1234567890', 'Hello from flutter_gsmsip!');
} catch (e) {
  print('SMS failed: $e');
}
```

## 📚 API Reference

### Core Classes

#### `GsmSipBridge`

Main API facade for GSM/SIP/SMPP operations.

```dart
final bridge = GsmSipBridge();

// Initialize
await bridge.initialize();

// Check status
bool isReady = bridge.isInitialized;

// Make call
await bridge.makeCall(destination);

// Send SMS
await bridge.sendSms(destination, message);
```

#### `SipAccount`

SIP account configuration entity.

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique account identifier |
| `username` | `String` | SIP username |
| `password` | `String` | SIP password |
| `domain` | `String` | SIP server domain |
| `port` | `int` | SIP port (default: 5060) |

#### `GatewayConfig`

Gateway configuration entity.

| Property | Type | Description |
|----------|------|-------------|
| `sipAccount` | `SipAccount` | SIP account configuration |
| `autoAnswer` | `bool` | Auto-answer incoming calls |
| `enableLogging` | `bool` | Enable debug logging |

### Events

The library provides event streaming for real-time updates:

```dart
// Subscribe to SIP events
bridge.eventStream.listen((event) {
  switch (event.type) {
    case SipEventType.incomingCall:
      print('Incoming call: ${event.data}');
      break;
    case SipEventType.callEnded:
      print('Call ended');
      break;
    case SipEventType.smsReceived:
      print('SMS received: ${event.data}');
      break;
  }
});
```

## 🏗️ Architecture

### Plugin Structure

```
flutter_gsmsip/
├── lib/                      # Dart API
│   ├── flutter_gsmsip.dart   # Main export
│   └── src/
│       ├── entities/         # Domain entities
│       │   ├── sip_account.dart
│       │   ├── sip_call.dart
│       │   ├── gateway_config.dart
│       │   └── gateway_status.dart
│       └── services/         # Service layer
│           └── gsm_sip_bridge.dart
├── android/                  # Native Android code
│   └── src/main/kotlin/      # Kotlin implementation
│       ├── sip/              # SIP native code
│       ├── gsm/              # GSM telephony code
│       └── smpp/             # SMPP code
└── example/                  # Example application
    └── lib/
        └── main.dart         # Working example
```

### Layer Architecture

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Domain** | `lib/src/domain/` | Entities, repository interfaces, use cases |
| **Data** | `lib/src/data/` | Repository implementations, services |
| **Native** | `android/src/main/kotlin/` | PJSIP, GSM, SMPP native code |
| **Presentation** | `example/lib/` | UI, state management (in example app) |

## 📖 Example App

The `example/` directory contains a complete working application demonstrating:

- SIP account configuration UI
- Call management (make, answer, hangup)
- SMS sending and receiving
- Multi-gateway management
- Real-time status monitoring

To run the example:

```bash
cd example
flutter pub get
flutter run
```

## 🔧 Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/telon/flutter_gsmsip.git
cd flutter_gsmsip

# Get dependencies
flutter pub get

# Run tests
flutter test

# Build example app
cd example
flutter build apk --debug
```

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests (requires device/emulator)
flutter test integration_test/
```

## 📋 Requirements

- **Flutter**: >=3.3.0
- **Dart**: ^3.10.8
- **Android**: API level 21+ (Android 5.0)
- **Kotlin**: 1.7.0+
- **Android Gradle Plugin**: 8.1.0+

## 🐛 Known Issues

See the [GitHub Issues](https://github.com/telon/flutter_gsmsip/issues) for known issues and roadmap.

### Current Limitations

- **Android Only**: iOS support not yet implemented
- **PJSIP Version**: Uses specific PJSIP version (bundled in native libs)
- **Service Architecture**: Uses Android foreground services with Intents (ADR-001)

## 📝 Additional Documentation

- [Architecture Decision Records](flows/adr-index.md)
- [Development Flows](flows/)
- [Example App README](example/README.md)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 🙏 Acknowledgments

- [PJSIP](https://www.pjsip.org/) - Native SIP stack
- [Flutter](https://flutter.dev/) - Cross-platform framework
- [SMPP](https://en.wikipedia.org/wiki/Short_Message_Peer-to-Peer) - SMS protocol

## 📄 License

This project is licensed under the **NativeMindNONC License** — see the [LICENSE](LICENSE) file for details.

**Key Terms:**
- ✅ **Free for non-commercial use** (education, research, personal learning)
- ⚠️ **Commercial use requires written permission** from the copyright holder
- 🔄 **ShareAlike**: Derivative works must be published as GitHub Forks under the same license
- 📝 **Attribution required**: Credit the original authors with link to repository

---

**Package**: `flutter_gsmsip`  
**Version**: 0.1.0  
**License**: NativeMindNONC  
**Homepage**: <https://github.com/telon/flutter_gsmsip>  
**Issues**: <https://github.com/telon/flutter_gsmsip/issues>
