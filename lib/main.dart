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
import 'screens/ussd_screen.dart';
import 'screens/smpp_settings_screen.dart';
import 'screens/smpp_logs_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/lines_screen.dart';
import 'screens/sims_screen.dart';
import 'screens/base_stations_screen.dart';
import 'screens/codecs_screen.dart';
import 'screens/calls_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'screens/theme_demo_screen.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация сервисов
  final themeService = ThemeService();
  final localizationService = LocalizationService();
  
  await themeService.initialize();
  await localizationService.initialize();
  
  runApp(MyApp(
    themeService: themeService,
    localizationService: localizationService,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final LocalizationService localizationService;
  
  const MyApp({
    Key? key,
    required this.themeService,
    required this.localizationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GatewayProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: localizationService),
      ],
      child: Consumer2<LanguageProvider, ThemeService>(
        builder: (context, languageProvider, themeService, child) {
          return MaterialApp(
            title: 'GOSTsimbox Gateway',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
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
              '/theme': (context) => const ThemeSettingsScreen(),
              '/info': (context) => const InfoScreen(),
              '/sms': (context) => const SmsScreen(),
              '/ussd': (context) => const UssdScreen(),
        '/smpp-settings': (context) => const SmppSettingsScreen(),
        '/smpp-logs': (context) => const SmppLogsScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/lines': (context) => const LinesScreen(),
              '/sims': (context) => const SimsScreen(),
              '/base-stations': (context) => const BaseStationsScreen(),
              '/codecs': (context) => const CodecsScreen(),
              '/calls': (context) => const CallsScreen(),
              '/theme-demo': (context) => const ThemeDemoScreen(),
            },
          );
        },
      ),
    );
  }
}
