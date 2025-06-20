import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest_all.dart'; // <-- REMOVED 'as tz_data'
import 'package:timezone/timezone.dart' as tz;

// Importa suas páginas
import 'src/login/login.dart';
import 'src/home/home.dart';
import 'src/layout/layout.dart';
import 'src/perfil/perfil.dart';
import 'src/groups/groups.dart';



void main() async {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Main App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const LayoutPage(),
        '/perfil': (context) => const PerfilPage(),
        '/groups': (context) => const GroupsPage(),
      },
    );
  }
}