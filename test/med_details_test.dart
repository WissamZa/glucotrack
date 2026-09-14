import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/i18n/strings.dart';
import 'package:glucotrack/screens/medication_details_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('MedicationDetailsScreen renders details safely', (tester) async {
    final settingsProv = SettingsProviderState();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProviderState>.value(
        value: settingsProv,
        child: MaterialApp(
          initialRoute: '/',
          builder: (context, child) =>
              SettingsInherited(data: settingsProv, child: child!),
          routes: {
            '/': (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/medication-details',
                    arguments: {
                      'rxcui': 'saudi:panadol',
                      'name': 'Panadol',
                      'synonym': 'بنادول',
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
            '/medication-details': (context) => const MedicationDetailsScreen(),
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Wait for async load to complete
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.byType(MedicationDetailsScreen), findsOneWidget);
    expect(find.text('بنادول'), findsWidgets);
    expect(find.text('Panadol'), findsWidgets);
    expect(find.text('دواعي الاستخدام'), findsWidgets);
    expect(find.text('المكونات'), findsWidgets);
    expect(find.text('Paracetamol'), findsWidgets);
  });
}
