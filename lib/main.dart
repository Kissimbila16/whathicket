import 'package:flutter/material.dart';
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