// GlucoTrack — Flutter entry point.
//
// Wires up providers, theme, locale, and routes between the screens.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite_native;

import 'i18n/strings.dart';
import 'models/settings.dart';
import 'providers/providers.dart';
import 'themes/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_reading_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/export_screen.dart';
import 'screens/ble_sync_screen.dart';

void main() {
  // Ensure Flutter binding is initialized before any async work
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.android ||
             defaultTargetPlatform == TargetPlatform.iOS) {
    // Mobile: use the native sqflite factory (no FFI needed)
    databaseFactory = sqflite_native.databaseFactory;
  } else {
    // Desktop (Linux, Windows, macOS): use FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Wrap the entire app in a zone that catches errors to prevent white screen
  runZonedGuarded(() {
    runApp(const GlucoTrackApp());
  }, (error, stack) {
    // Log errors — in production these would go to Crashlytics/Sentry
    debugPrint('=== UNCAUGHT ERROR ===');
    debugPrint('$error');
    debugPrint('$stack');
  });
}

class GlucoTrackApp extends StatelessWidget {
  const GlucoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProviderState>(create: (_) => SettingsProviderState()),
        ChangeNotifierProvider<ReadingsProvider>(create: (_) => ReadingsProvider()),
        ChangeNotifierProvider<RemindersProvider>(create: (_) => RemindersProvider()),
      ],
      child: Consumer<SettingsProviderState>(
        builder: (context, settingsProv, _) {
          final s = settingsProv.settings;
          return MaterialApp(
            title: 'GlucoTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.forStyle(s.theme),
            locale: Locale(s.language == Language.ar ? 'ar' : 'en'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return SettingsInherited(
                data: settingsProv,
                child: Directionality(
                  textDirection: s.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
              );
            },
            home: const AppBootstrap(),
            routes: {
              '/home': (_) => const HomeScreen(),
              '/add': (_) => const AddReadingScreen(),
              '/chart': (_) => const ChartScreen(),
              '/reminders': (_) => const RemindersScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/insights': (_) => const InsightsScreen(),
              '/export': (_) => const ExportScreen(),
              '/sync': (_) => const BleSyncScreen(),
            },
          );
        },
      ),
    );
  }
}

// Bootstrap: load settings + seed DB + decide onboarding vs main shell.
// Shows a loading indicator while initializing, and an error screen if
// anything goes wrong (prevents white screen of death).
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Load settings from DB
      if (!mounted) return;
      await context.read<SettingsProviderState>().loadFromDb();

      // Load readings and reminders
      if (!mounted) return;
      await context.read<ReadingsProvider>().load();
      if (!mounted) return;
      await context.read<RemindersProvider>().load();

      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } catch (e, stack) {
      debugPrint('=== INIT ERROR ===');
      debugPrint('$e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen if initialization failed
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _init();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading spinner while initializing
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0D9488)),
              SizedBox(height: 16),
              Text(
                'GlucoTrack',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show onboarding or main shell
    final s = context.watch<SettingsProviderState>().settings;
    if (!s.onboarded) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}

// Main shell — bottom navigation with 4 tabs + floating Add button.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static final _screens = <Widget>[
    const HomeScreen(),
    const ChartScreen(),
    const RemindersScreen(),
    const SettingsScreen(),
  ];

  void _openAdd() async {
    await Navigator.of(context).pushNamed('/add');
    if (mounted) context.read<ReadingsProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, Icons.home, strings.navHome, 0),
              _navItem(Icons.bar_chart_outlined, Icons.bar_chart, strings.navChart, 1),
              const SizedBox(width: 56), // space for FAB
              _navItem(Icons.notifications_outlined, Icons.notifications, strings.navReminders, 2),
              _navItem(Icons.settings_outlined, Icons.settings, strings.navSettings, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData outlined, IconData filled, String label, int idx) {
    final selected = _index == idx;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return InkWell(
      onTap: () => setState(() => _index = idx),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? filled : outlined, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
