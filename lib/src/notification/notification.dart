import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final android = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Permissão no Android 13+
  final granted = await android?.requestNotificationsPermission();
  print("Permissão concedida? $granted");

  // Criar canal
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'canal_id',
    'Canal Nome',
    description: 'Canal de teste',
    importance: Importance.high,
  );

  await android?.createNotificationChannel(channel);

  runApp(const MyApp());
}


void mostrarNotificacao() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'canal_id',
    'Canal Nome',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Título da Notificação',
    'Corpo da Notificação',
    notificationDetails,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notificação Local',
      home: Scaffold(
        appBar: AppBar(title: const Text('Teste de Notificação')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              mostrarNotificacao();
            },
            child: const Text('Mostrar Notificação'),
          ),
        ),
      ),
    );
  }
}
