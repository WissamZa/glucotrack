// Glucose unit conversion utility — mg/dL ↔ mmol/L
// Reference: 1 mmol/L = 18 mg/dL (standard clinical conversion)
import '../models/settings.dart';

class UnitConverter {
  static const double _conversionFactor = 18.018;

  /// Convert mg/dL to mmol/L
  static double mgToMmol(int mgDl) => mgDl / _conversionFactor;

  /// Convert mmol/L to mg/dL
  static int mmolToMg(double mmolL) => (mmolL * _conversionFactor).round();

  /// Format a glucose value for display based on current unit setting
  static String format(int valueMgDl, GlucoseUnit unit) {
    switch (unit) {
      case GlucoseUnit.mgDl:
        return '$valueMgDl';
      case GlucoseUnit.mmolL:
        return mgToMmol(valueMgDl).toStringAsFixed(1);
    }
  }

  /// Get the unit label for display
  static String unitLabel(GlucoseUnit unit) {
    switch (unit) {
      case GlucoseUnit.mgDl:
        return 'mg/dL';
      case GlucoseUnit.mmolL:
        return 'mmol/L';
    }
  }

  /// Format value with unit label
  static String formatWithUnit(int valueMgDl, GlucoseUnit unit) {
    return '${format(valueMgDl, unit)} ${unitLabel(unit)}';
  }

  /// Convert target range values
  static int convertValue(int value, GlucoseUnit from, GlucoseUnit to) {
    if (from == to) return value;
    if (from == GlucoseUnit.mgDl && to == GlucoseUnit.mmolL) {
      return mgToMmol(value).round();
    }
    return mmolToMg(value.toDouble());
  }
}
