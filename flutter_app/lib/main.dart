// GlucoTrack — Flutter entry point.
//
// Wires up providers, theme, locale, and routes between the 7 screens.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'database/database_helper.dart';
import 'i18n/strings.dart';
import 'providers/providers.dart';
import 'themes/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_reading_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GlucoTrackApp());
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
              // Apply RTL/LTR direction explicitly
              return Directionality(
                textDirection: s.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            home: const AppBootstrap(),
            routes: {
              '/home': (_) => const HomeScreen(),
              '/add': (_) => const AddReadingScreen(),
              '/chart': (_) => const ChartScreen(),
              '/reminders': (_) => const RemindersScreen(),
              '/settings': (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

// Bootstrap: load settings + seed DB + decide onboarding vs main shell.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = DatabaseHelper();
    await db.seedIfEmpty();

    if (!mounted) return;
    final sProv = context.read<SettingsProviderState>();
    await sProv.loadFromDb();

    if (!mounted) return;
    await context.read<ReadingsProvider>().load();
    await context.read<RemindersProvider>().load();

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D9488)),
        ),
      );
    }

    final s = context.watch<SettingsProviderState>().settings;
    if (!s.onboarded) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}

// Main shell — bottom navigation with 5 tabs + floating Add button.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    ChartScreen(),
    RemindersScreen(),
    SettingsScreen(),
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
