import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/plant_repository.dart';

class NotificationService {
  static const _notifId = 1;
  static const _channelId = 'plant_care';
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Cuidado de plantas',
          description: 'Recordatorios de revisión de tierra y riego',
          importance: Importance.high,
        ));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> reschedule(PlantRepository repo) async {
    await _plugin.cancel(_notifId);

    final dueDates = await repo.getNextDueDates();
    if (dueDates.isEmpty) return;

    final earliest =
        dueDates.values.reduce((a, b) => a.isBefore(b) ? a : b);

    final earliestDay =
        DateTime(earliest.year, earliest.month, earliest.day);
    final dueCount = dueDates.values
        .where((d) =>
            !DateTime(d.year, d.month, d.day).isAfter(earliestDay))
        .length;

    String title;
    String body;

    if (dueCount == 1) {
      final plantId = dueDates.entries
          .firstWhere((e) => !DateTime(
                e.value.year, e.value.month, e.value.day,
              ).isAfter(earliestDay))
          .key;
      final plants = await repo.getPlants();
      final plant =
          plants.firstWhere((p) => p.id == plantId, orElse: () => plants.first);
      final name =
          (plant.nickname?.isNotEmpty == true) ? plant.nickname! : plant.species;
      title = name;
      body = 'Es momento de revisar la tierra. Toca antes de regar.';
    } else {
      title = 'Tienes $dueCount plantas para revisar';
      body = 'Abre la app para ver el plan de hoy.';
    }

    // Convert local DateTime to UTC for scheduling — fires at the correct
    // absolute moment regardless of timezone offset.
    final utc = earliest.toUtc();
    final scheduledAt = tz.TZDateTime.utc(
      utc.year, utc.month, utc.day, utc.hour, utc.minute,
    );

    await _plugin.zonedSchedule(
      _notifId,
      title,
      body,
      scheduledAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Cuidado de plantas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();

  static Future<void> showTest() async {
    await _plugin.show(
      99,
      'Prueba de notificación',
      'Las notificaciones funcionan correctamente.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Cuidado de plantas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
