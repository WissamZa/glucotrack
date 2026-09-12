// Shared emergency-guidance dialog, shown from Home and Add Reading
// whenever a glucose reading falls into a critical band.
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../utils/emergency_guidance.dart';

Future<void> showEmergencyGuidance(
  BuildContext context,
  AppStrings strings,
  EmergencyGuidance guidance,
) {
  final arabic = strings.isRtl;
  final color = switch (guidance.level) {
    EmergencyLevel.low => const Color(0xFFEF4444),
    EmergencyLevel.warningLow => const Color(0xFFF59E0B),
    EmergencyLevel.high => const Color(0xFFF97316),
  };

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.emergency, color: color, size: 32),
      title: Text(
        guidance.title(arabic),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < guidance.steps(arabic).length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        guidance.steps(arabic)[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_hospital, size: 15, color: color),
                      const SizedBox(width: 5),
                      Text(
                        strings.emergencySeekHelp,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guidance.seekHelp(arabic),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.emergencyNote,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.ok),
        ),
      ],
    ),
  );
}
