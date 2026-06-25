// Notification scheduling service for GlucoTrack reminders.
//
// Wraps flutter_local_notifications to schedule daily recurring reminders
// at user-specified times. Notifications survive device reboots.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  String? _findLocalTimezone(Duration offset) {
    // Common timezones — expand as needed
    final common = [
      'UTC', 'America/New_York', 'America/Chicago', 'America/Denver',
      'America/Los_Angeles', 'Europe/London', 'Europe/Paris', 'Europe/Berlin',
      'Asia/Riyadh', 'Asia/Dubai', 'Asia/Kolkata', 'Asia/Tokyo', 'Asia/Shanghai',
      'Australia/Sydney', 'Pacific/Auckland',
    ];
    for (final name in common) {
      try {
        final loc = tz.getLocation(name);
        if (loc.currentTimeZone.offset(DateTime.now().millisecondsSinceEpoch) ==
            offset.inMilliseconds) {
          return name;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a daily reminder at the given [hour]:[minute].
  /// [id] should be a stable hash of the reminder ID.
  Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'glucotrack_reminders',
      'GlucoTrack Reminders',
      channelDescription: 'Notifications for blood glucose measurement reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingReminders() async {
    return _plugin.pendingNotificationRequests();
  }

  void _onNotificationTap(NotificationResponse resp) {
    // Future: deep-link to the add-reading screen
  }
}
