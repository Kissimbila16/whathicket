import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Um fundo cinza claro
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0), // Adiciona um espaçamento ao redor do conteúdo
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Centraliza os elementos horizontalmente
            children: <Widget>[
              const Text(
                'WhaTicket!',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Cor do texto principal
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Bem-vindo à Página Inicial!',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
              const SizedBox(height: 40.0),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.blueAccent, // Cor de fundo do botão
                  foregroundColor: Colors.black, // Cor do texto do botão
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Bordas arredondadas
                  ),
                  textStyle: const TextStyle(fontSize: 18.0),
                ),
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 20.0),
              // Você pode adicionar mais widgets aqui, como um logo ou uma imagem
              // Exemplo de um logo (certifique-se de ter o asset configurado no pubspec.yaml)
              // Image.asset(
              //   'assets/logo.png',
              //   height: 100.0,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}