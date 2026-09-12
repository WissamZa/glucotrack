// Tests for emergency first-aid guidance — threshold mapping mirrors
// Reading.status() exactly and every guidance carries both languages.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/reading.dart';
import 'package:glucotrack/utils/emergency_guidance.dart';

void main() {
  group('EmergencyGuide.forValue thresholds', () {
    final testCases = <(int value, EmergencyLevel? expected)>[
      (20, EmergencyLevel.low), // deepest plausible low
      (40, EmergencyLevel.low),
      (53, EmergencyLevel.low), // still Level 2 hypo
      (54, EmergencyLevel.warningLow), // Level 1 hypo starts
      (69, EmergencyLevel.warningLow),
      (70, null), // low-but-not-warning: no emergency banner
      (100, null),
      (250, null), // exactly 250 is still only "high"
      (251, EmergencyLevel.high), // critical high starts
      (400, EmergencyLevel.high),
      (600, EmergencyLevel.high),
    ];

    for (final tc in testCases) {
      test('value ${tc.$1} → ${tc.$2?.name ?? 'null'}', () {
        final guidance = EmergencyGuide.forValue(tc.$1);
        if (tc.$2 == null) {
          expect(guidance, isNull);
        } else {
          expect(guidance, isNotNull);
          expect(guidance!.level, tc.$2);
        }
      });
    }
  });

  group('EmergencyGuide.forStatus', () {
    test('maps the three critical statuses to guidance', () {
      expect(
        EmergencyGuide.forStatus(ReadingStatus.criticalLow, 45)?.level,
        EmergencyLevel.low,
      );
      expect(
        EmergencyGuide.forStatus(ReadingStatus.warningLow, 60)?.level,
        EmergencyLevel.warningLow,
      );
      expect(
        EmergencyGuide.forStatus(ReadingStatus.criticalHigh, 300)?.level,
        EmergencyLevel.high,
      );
    });

    test('returns null for non-critical statuses', () {
      expect(EmergencyGuide.forStatus(ReadingStatus.low, 75), isNull);
      expect(EmergencyGuide.forStatus(ReadingStatus.inRange, 120), isNull);
      expect(EmergencyGuide.forStatus(ReadingStatus.high, 200), isNull);
    });
  });

  group('guidance content integrity', () {
    final all = [
      EmergencyGuide.forValue(45)!,
      EmergencyGuide.forValue(60)!,
      EmergencyGuide.forValue(300)!,
    ];

    test(
      'every level has distinct guidance with real steps in BOTH languages',
      () {
        final levels = all.map((g) => g.level).toSet();
        expect(
          levels.length,
          3,
          reason: 'Each critical band needs own content',
        );

        for (final g in all) {
          expect(
            g.stepsAr.length,
            greaterThanOrEqualTo(3),
            reason: '${g.level}: too few Arabic steps',
          );
          expect(
            g.stepsEn.length,
            g.stepsAr.length,
            reason: '${g.level}: AR/EN step counts must match',
          );
          for (final step in [...g.stepsAr, ...g.stepsEn]) {
            expect(step.trim(), isNotEmpty);
          }
          expect(g.titleAr.trim(), isNotEmpty);
          expect(g.titleEn.trim(), isNotEmpty);
          expect(g.seekHelpAr.trim(), isNotEmpty);
          expect(g.seekHelpEn.trim(), isNotEmpty);
        }
      },
    );

    test('language-aware accessors pick the right language', () {
      final g = all.first;
      expect(g.title(true), g.titleAr);
      expect(g.title(false), g.titleEn);
      expect(g.steps(true), g.stepsAr);
      expect(g.steps(false), g.stepsEn);
      expect(g.seekHelp(true), g.seekHelpAr);
      expect(g.seekHelp(false), g.seekHelpEn);
    });

    test('severe-low guidance mentions the 15-15 rule treatment', () {
      final severe = EmergencyGuide.forValue(45)!;
      final mild = EmergencyGuide.forValue(60)!;
      expect(severe.stepsEn.join(' '), contains('15'));
      expect(mild.titleEn, contains('15-15'));
    });

    test('high guidance warns against self-doubling insulin', () {
      final high = EmergencyGuide.forValue(300)!;
      expect(high.stepsEn.join(' ').toLowerCase(), contains('never double'));
      expect(high.stepsAr.join(' '), contains('لا تضاعف'));
    });
  });
}
