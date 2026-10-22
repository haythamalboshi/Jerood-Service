import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// يهيّئ بيانات المناطق الزمنية والإضافة نفسها، ويطلب إذن الإشعارات على
  /// أندرويد 13+. يجب استدعاؤها مرة واحدة عند إقلاع التطبيق (main.dart).
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (Platform.isAndroid) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('تعذّر طلب إذن الإشعارات: $e');
      }
    }

    _initialized = true;
  }

  Future<bool> scheduleWaterReminder({
    required DateTime deliveryDateTime,
    required String neighborhood,
  }) async {
    if (!_initialized) await init();

    // جدولة التذكير قبل 8 ساعات بالضبط من موعد وصول المياه
    final scheduledTime = deliveryDateTime.subtract(const Duration(hours: 8));
    final now = DateTime.now();

    final effectiveTime = scheduledTime.isBefore(now)
        ? now.add(const Duration(seconds: 10))
        : scheduledTime;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jerood_water_channel',
      'تنبيهات أدوار المياه - جيرود',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final tzTime = tz.TZDateTime.from(effectiveTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      1001,
      'تذكير دور المياه - $neighborhood',
      'مياه الشرب ستبدأ بالضخ في $neighborhood خلال 8 ساعات. يرجى تجهيز الخزانات والمضخات.',
      tzTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'water_$neighborhood',
    );
    return true;
  }
}
