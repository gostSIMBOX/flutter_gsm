import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logger/logger.dart';

// Core
import 'core/di/dependency_injection.dart';
import 'core/error/error_handler.dart';
import 'core/utils/app_constants.dart';

// Presentation
import 'presentation/providers/gateway_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/screens/info_screen.dart';
import 'presentation/screens/sms_screen.dart';
import 'presentation/screens/ussd_screen.dart';
import 'presentation/screens/smpp_settings_screen.dart';
import 'presentation/screens/smpp_logs_screen.dart';
import 'presentation/screens/analytics_screen.dart';
import 'presentation/screens/lines_screen.dart';
import 'presentation/screens/sims_screen.dart';
import 'presentation/screens/base_stations_screen.dart';
import 'presentation/screens/codecs_screen.dart';
import 'presentation/screens/calls_screen.dart';
import 'presentation/screens/theme_settings_screen.dart';
import 'presentation/screens/theme_demo_screen.dart';

// Services
import 'presentation/services/theme_service.dart';
import 'presentation/services/localization_service.dart';

// Theme
import 'presentation/theme/app_theme.dart';

final Logger _logger = Logger();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Настройка ориентации экрана
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Настройка системного UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    
    _logger.i('Starting GOSTsimbox Gateway application...');
    
    // Инициализация Dependency Injection
    await DependencyInjection.init();
    
    // Инициализация сервисов
    final themeService = ThemeService();
    final localizationService = LocalizationService();
    
    await Future.wait([
      themeService.initialize(),
      localizationService.initialize(),
    ]);
    
    _logger.i('Application initialized successfully');
    
    runApp(MyApp(
      themeService: themeService,
      localizationService: localizationService,
    ));
  } catch (error, stackTrace) {
    _logger.e('Failed to initialize application', error: error, stackTrace: stackTrace);
    ErrorHandler.handleError(error, stackTrace);
    
    // Показываем экран ошибки
    runApp(const ErrorApp());
  }
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
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            locale: languageProvider.currentLocale,
            supportedLocales: AppConstants.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppConstants.initialRoute,
            routes: _buildRoutes(),
            onGenerateRoute: _onGenerateRoute,
            navigatorObservers: [
              RouteObserver<ModalRoute<void>>(),
            ],
          );
        },
      ),
    );
  }
  
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
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
    };
  }
  
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // Обработка динамических маршрутов
    switch (settings.name) {
      case '/error':
        return MaterialPageRoute(
          builder: (context) => const ErrorScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
        );
    }
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error - ${AppConstants.appName}',
      theme: AppTheme.lightTheme,
      home: const ErrorScreen(),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Error'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Application failed to start',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please restart the application',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Page not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'The requested page does not exist',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
