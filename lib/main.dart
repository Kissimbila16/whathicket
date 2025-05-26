import 'package:flutter/material.dart';
import 'src/login/login.dart';     // Tela de login
import 'src/home/home.dart';     // Tela de login
import 'src/layout/layout.dart';     // Tela de login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exemplo de Rotas',
      initialRoute: '/', // Rota inicial
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const LayoutPage(),
      },
    );
  }
}
