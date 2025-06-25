import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> inicializar() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(initializationSettings);

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Solicita permissão no Android 13+
    await androidImplementation?.requestNotificationsPermission();

    // Cria o canal se ainda não existir
    const channel = AndroidNotificationChannel(
      'canal_id',
      'Canal Nome',
      description: 'Canal de teste',
      importance: Importance.high,
    );

    await androidImplementation?.createNotificationChannel(channel);
  }

  Future<void> mostrarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'canal_id',
      'Canal Nome',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, titulo, corpo, notificationDetails);
  }
}
