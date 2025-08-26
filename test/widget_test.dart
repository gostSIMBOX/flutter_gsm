// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gsm_sip_gateway/main.dart';
import 'package:flutter_gsm_sip_gateway/providers/gateway_provider.dart';
import 'package:flutter_gsm_sip_gateway/providers/dashboard_provider.dart';
import 'package:flutter_gsm_sip_gateway/providers/language_provider.dart';
import 'package:flutter_gsm_sip_gateway/services/localization_service.dart';
import 'package:flutter_gsm_sip_gateway/services/theme_service.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GatewayProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MyApp(
          localizationService: LocalizationService(),
          themeService: ThemeService(),
        ),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
