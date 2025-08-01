import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/gateway_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/language_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/info_screen.dart';
import 'screens/sms_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/lines_screen.dart';
import 'screens/sims_screen.dart';
import 'screens/base_stations_screen.dart';
import 'screens/codecs_screen.dart';
import 'screens/calls_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GatewayProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'GSM-SIP Gateway',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0A0A),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1A1A1A),
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600] ?? Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1A1A1A),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
              Locale('es'),
              Locale('fr'),
              Locale('de'),
              Locale('zh'),
              Locale('ja'),
              Locale('ko'),
              Locale('ar'),
              Locale('pt'),
              Locale('it'),
              Locale('th'),
              Locale('tg'),
              Locale('az'),
              Locale('km'),
              Locale('lo'),
              Locale('my'),
              Locale('ms'),
              Locale('sw'),
              Locale('zu'),
              Locale('af'),
              Locale('yo'),
              Locale('ig'),
              Locale('ha'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const DashboardScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/language': (context) => const LanguageSelectionScreen(),
              '/info': (context) => const InfoScreen(),
              '/sms': (context) => const SmsScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/lines': (context) => const LinesScreen(),
              '/sims': (context) => const SimsScreen(),
              '/base-stations': (context) => const BaseStationsScreen(),
              '/codecs': (context) => const CodecsScreen(),
              '/calls': (context) => const CallsScreen(),
            },
          );
        },
      ),
    );
  }
}
