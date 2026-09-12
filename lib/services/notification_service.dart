// Notification scheduling service for GlucoTrack reminders.
//
// Wraps flutter_local_notifications to schedule daily recurring reminders
// at user-specified times. Notifications survive device reboots.
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Root navigator key so notification taps can deep-link into the app
  /// (e.g. open the add-reading screen).
  static final navigatorKey = GlobalKey<NavigatorState>();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Try to set local timezone; fall back to UTC
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      // Find a timezone matching the system offset
      final localName = _findLocalTimezone(offset);
      if (localName != null) {
        tz.setLocalLocation(tz.getLocation(localName));
      }
    } on Exception catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      linux: linuxInit,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  String? _findLocalTimezone(Duration offset) {
    // Common timezones — expand as needed
    final common = [
      'UTC',
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'Europe/London',
      'Europe/Paris',
      'Europe/Berlin',
      'Asia/Riyadh',
      'Asia/Dubai',
      'Asia/Kolkata',
      'Asia/Tokyo',
      'Asia/Shanghai',
      'Australia/Sydney',
      'Pacific/Auckland',
    ];
    for (final name in common) {
      try {
        final loc = tz.getLocation(name);
        if (loc.currentTimeZone.offset == offset) {
          return name;
        }
      } on Exception catch (_) {}
    }
    return null;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Schedule a repeating reminder at the given [hour]:[minute].
  ///
  /// - [weekday] == null → repeats every day (legacy measurement behavior).
  /// - [weekday] 1..7 (DateTime.monday..sunday) → repeats only on that
  ///   weekday (`DateTimeComponents.dayOfWeekAndTime`), used by medication
  ///   schedules with per-day selection.
  /// [id] must be unique per (reminder, weekday, time) combination.
  /// [medication] selects the dedicated medication channel so users can
  /// configure it separately.
  Future<void> scheduleReminder({
    required int id,
    int? weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool medication = false,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (weekday != null) {
      // Walk forward until the weekday matches (0..6 hops).
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    final androidDetails = medication
        ? const AndroidNotificationDetails(
            'glucotrack_medication',
            'GlucoTrack Medication',
            channelDescription:
                'Notifications for medication and insulin reminders',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          )
        : const AndroidNotificationDetails(
            'glucotrack_reminders',
            'GlucoTrack Reminders',
            channelDescription:
                'Notifications for blood glucose measurement reminders',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingReminders() async {
    return _plugin.pendingNotificationRequests();
  }

  void _onNotificationTap(NotificationResponse resp) {
    // Deep-link to the add-reading screen. Uses the root navigator key so it
    // works regardless of which screen is on top when the tap happens.
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed('/add');
    }
  }
}
