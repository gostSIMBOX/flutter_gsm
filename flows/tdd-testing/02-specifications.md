# Specifications: Testing Strategy

## Test Organization

### Directory Structure

```
test/
├── unit/                      # Unit tests
│   └── gateway_service_test.dart
│
├── core/                      # Core layer tests
│   ├── di/
│   │   └── dependency_injection_test.dart
│   └── error/
│       └── error_handler_test.dart
│
├── services/                  # Service tests
│   ├── api_service_test.dart
│   ├── network_service_test.dart
│   └── storage_service_test.dart
│
├── presentation/              # Presentation layer tests
│   └── services/
│       ├── cache_service_test.dart
│       ├── localization_service_test.dart
│       ├── security_service_test.dart
│       └── theme_service_test.dart
│
├── integration/               # Integration tests
│   └── app_integration_test.dart
│
├── widgets/                   # Widget tests
│   └── dashboard_widget_test.dart
│
├── widget_test.dart           # Basic widget test
│
└── standalone tests/          # Manual testing scripts
    ├── standalone_smpp_test.dart
    └── test_smpp.dart
```

## Unit Test Specifications

### Gateway Service Tests

```dart
// test/unit/gateway_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([SipService, SmsService, TelephonyService])
import 'gateway_service_test.mocks.dart';

void main() {
  group('GatewayService', () {
    late GatewayService service;
    late MockSipService mockSip;
    late MockSmsService mockSms;
    late MockTelephonyService mockTelephony;
    
    setUp(() {
      mockSip = MockSipService();
      mockSms = MockSmsService();
      mockTelephony = MockTelephonyService();
      service = GatewayService();
    });
    
    test('initialize returns true when all services initialize', () async {
      // Arrange
      when(mockTelephony.initialize()).thenAnswer((_) async => true);
      when(mockSip.initialize(any)).thenAnswer((_) async => true);
      when(mockSms.initializeSmpp(any)).thenAnswer((_) async => true);
      
      // Act
      final result = await service.initialize(testConfig);
      
      // Assert
      expect(result, true);
    });
    
    test('makeCallViaSip creates routing and returns ID', () async {
      // Arrange
      await service.initialize(testConfig);
      await service.start();
      when(mockSip.makeCall(any)).thenAnswer((_) async => 'sip_call_123');
      
      // Act
      final routingId = await service.makeCallViaSip('+1234567890');
      
      // Assert
      expect(routingId, isNotNull);
      expect(service.activeRoutings.length, 1);
    });
  });
}
```

### Core Layer Tests

```dart
// test/core/di/dependency_injection_test.dart

void main() {
  group('DependencyInjection', () {
    setUp(() async {
      await DependencyInjection.reset();
    });
    
    test('init registers all required dependencies', () async {
      // Act
      await DependencyInjection.init();
      
      // Assert
      expect(DependencyInjection.isRegistered<SharedPreferences>(), true);
      expect(DependencyInjection.isRegistered<Logger>(), true);
      expect(DependencyInjection.isRegistered<ThemeService>(), true);
    });
    
    test('get returns registered instance', () async {
      // Arrange
      await DependencyInjection.init();
      
      // Act
      final logger = DependencyInjection.get<Logger>();
      
      // Assert
      expect(logger, isA<Logger>());
    });
  });
}
```

```dart
// test/core/error/error_handler_test.dart

void main() {
  group('ErrorHandler', () {
    test('handleError logs error and sends to analytics', () {
      // Arrange
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      
      // Act
      ErrorHandler.handleError(error, stackTrace);
      
      // Assert
      // Verify error was logged
      // Verify analytics received error
    });
    
    test('handleNetworkError shows user-friendly message', () {
      // Arrange
      final error = SocketException('No internet');
      
      // Act
      ErrorHandler.handleNetworkError(error, '/api/test');
      
      // Assert
      // Verify SnackBar shown with appropriate message
    });
  });
}
```

## Widget Test Specifications

### Dashboard Widget Test

```dart
// test/widgets/dashboard_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('DashboardScreen', () {
    testWidgets('displays gateway status cards', (tester) async {
      // Arrange
      final mockGatewayService = MockGatewayService();
      when(mockGatewayService.isRunning).thenReturn(true);
      when(mockGatewayService.getStatus()).thenReturn(testGatewayStatus);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GatewayService>.value(value: mockGatewayService),
          ],
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      
      // Act
      await tester.pump();
      
      // Assert
      expect(find.text('Gateway Status'), findsOneWidget);
      expect(find.text('SIP Connection'), findsOneWidget);
      expect(find.text('GSM Connection'), findsOneWidget);
    });
    
    testWidgets('start button calls gateway.start', (tester) async {
      // Arrange
      final mockGatewayService = MockGatewayService();
      when(mockGatewayService.isRunning).thenReturn(false);
      when(mockGatewayService.start()).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GatewayService>.value(value: mockGatewayService),
          ],
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Assert
      verify(mockGatewayService.start()).called(1);
    });
  });
}
```

## Integration Test Specifications

### App Integration Test

```dart
// test/integration/app_integration_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Full App Flow', () {
    testWidgets('app initializes and shows setup or dashboard', (tester) async {
      // Arrange
      await tester.pumpWidget(const GOSTsimboxApp());
      
      // Act - Wait for initial load
      await tester.pumpAndSettle();
      
      // Assert
      expect(
        find.byType(SetupCheckScreen),
        findsNothing,  // Should have navigated away
      );
      expect(
        find.byType(DashboardScreen),
        findsWidgets,  // Or SetupScreen
      );
    });
    
    testWidgets('complete call flow from start to end', (tester) async {
      // Arrange - Start with configured app
      await tester.pumpWidget(const GOSTsimboxApp());
      await tester.pumpAndSettle();
      
      // Act - Make a call
      await tester.tap(find.text('Start Gateway'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Test Call'));
      await tester.pumpAndSettle();
      
      // Assert - Call is active
      expect(find.text('Active Calls: 1'), findsOneWidget);
      
      // Act - End call
      await tester.tap(find.text('End Call'));
      await tester.pumpAndSettle();
      
      // Assert - Call ended
      expect(find.text('Active Calls: 0'), findsOneWidget);
    });
  });
}
```

## Service Test Specifications

### Theme Service Test

```dart
// test/presentation/services/theme_service_test.dart

void main() {
  group('ThemeService', () {
    late ThemeService service;
    
    setUp(() {
      service = ThemeService();
    });
    
    test('initialize loads saved theme', () async {
      // Arrange
      // Mock SharedPreferences to return dark theme
      
      // Act
      await service.initialize();
      
      // Assert
      expect(service.themeMode, ThemeMode.dark);
    });
    
    test('toggleTheme cycles through all themes', () async {
      // Arrange
      await service.initialize();
      
      // Act & Assert
      expect(service.getThemeName(), 'Dark');
      
      await service.toggleTheme();
      expect(service.getThemeName(), 'System');
      
      await service.toggleTheme();
      expect(service.getThemeName(), 'Light');
      
      await service.toggleTheme();
      expect(service.getThemeName(), 'Dark');  // Back to start
    });
  });
}
```

## Standalone Test Specifications

### SMPP Standalone Test

```dart
// standalone_smpp_test.dart

import 'dart:io';

void main() async {
  print('Testing SMPP connection...');
  
  // Test SMPP server connection
  final host = 'smpp.example.com';
  final port = 2775;
  
  try {
    final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
    print('✓ SMPP connection successful');
    await socket.close();
  } catch (e) {
    print('✗ SMPP connection failed: $e');
  }
  
  exit(0);
}
```

## Test Configuration

### pubspec.yaml

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

### Test Runner Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/gateway_service_test.dart

# Run with coverage
flutter test --coverage

# Run widget tests only
flutter test test/widgets/

# Run integration tests
flutter test integration_test/
```

---

**Status**: DRAFT  
**Created**: 2026-03-03  
**Source**: Legacy analysis (/legacy command)  
**Related**: 01-requirements.md
