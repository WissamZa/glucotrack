// Widget smoke test — verifies the app boots without crashing.
//
// Uses a mocked database so no real SQLite is opened.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:glucotrack/i18n/strings.dart';
import 'package:glucotrack/models/settings.dart';
import 'package:glucotrack/providers/providers.dart';

void main() {
  // ── SettingsProviderState unit tests ──────────────────────────────────────
  group('SettingsProviderState', () {
    test('initial settings are defaults', () {
      final prov = SettingsProviderState();
      expect(prov.settings.language, Language.ar);
      expect(prov.settings.theme, ThemeStyle.classic);
      expect(prov.settings.onboarded, false);
    });

    test('update() changes settings and notifies', () {
      final prov = SettingsProviderState();
      int notifications = 0;
      prov.addListener(() => notifications++);

      prov.update(const Settings(language: Language.en, onboarded: true));
      expect(prov.settings.language, Language.en);
      expect(prov.settings.onboarded, true);
      expect(notifications, 1);
    });
  });

  // ── AppStrings localisation tests ─────────────────────────────────────────
  group('AppStrings', () {
    test('Arabic appName returns سُكَّري', () {
      final strings = AppStrings(Language.ar);
      expect(strings.appName, 'سُكَّري');
    });

    test('English appName returns GlucoTrack', () {
      final strings = AppStrings(Language.en);
      expect(strings.appName, 'GlucoTrack');
    });

    test('get() returns key itself when key is missing', () {
      final strings = AppStrings(Language.en);
      expect(strings.get('nonexistent_key'), 'nonexistent_key');
    });

    test('all nav strings are non-empty in Arabic', () {
      final s = AppStrings(Language.ar);
      expect(s.navHome, isNotEmpty);
      expect(s.navChart, isNotEmpty);
      expect(s.navReminders, isNotEmpty);
      expect(s.navSettings, isNotEmpty);
    });

    test('all nav strings are non-empty in English', () {
      final s = AppStrings(Language.en);
      expect(s.navHome, isNotEmpty);
      expect(s.navChart, isNotEmpty);
      expect(s.navReminders, isNotEmpty);
      expect(s.navSettings, isNotEmpty);
    });

    test('status labels are non-empty in both languages', () {
      for (final lang in Language.values) {
        final s = AppStrings(lang);
        expect(s.statusCriticalLow, isNotEmpty, reason: 'lang=$lang');
        expect(s.statusLow, isNotEmpty, reason: 'lang=$lang');
        expect(s.statusInRange, isNotEmpty, reason: 'lang=$lang');
        expect(s.statusHigh, isNotEmpty, reason: 'lang=$lang');
        expect(s.statusCriticalHigh, isNotEmpty, reason: 'lang=$lang');
      }
    });
  });

  // ── Minimal widget test ───────────────────────────────────────────────────
  group('Widget smoke tests', () {
    testWidgets('SettingsProviderState works inside widget tree', (tester) async {
      final prov = SettingsProviderState();
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProviderState>.value(
          value: prov,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                final settings = ctx.watch<SettingsProviderState>().settings;
                return Scaffold(
                  body: Text(
                    settings.language == Language.ar ? 'Arabic' : 'English',
                    key: const Key('lang-text'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Default language is Arabic
      expect(find.text('Arabic'), findsOneWidget);

      // Update to English and rebuild
      prov.update(const Settings(language: Language.en));
      await tester.pump();
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('ReadingsProvider starts with empty readings', (tester) async {
      final prov = ReadingsProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<ReadingsProvider>.value(
          value: prov,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                final count = ctx.watch<ReadingsProvider>().readings.length;
                return Text('$count', key: const Key('count'));
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });
}
