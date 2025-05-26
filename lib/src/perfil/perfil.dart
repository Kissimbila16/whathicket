import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Ação para editar o perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar Perfil clicado!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Permite rolagem se o conteúdo for muito grande
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Imagem de Perfil
              const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150', // Imagem de placeholder
                ),
                backgroundColor: Colors.grey,
              ),
              const SizedBox(height: 20),

              // Nome do Usuário
              const Text(
                'João da Silva',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Ocupação/Título
              const Text(
                'Desenvolvedor Flutter | Entusiasta de UI/UX',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Informações de Contato
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: const <Widget>[
                      ListTile(
                        leading: Icon(Icons.email, color: Colors.blue),
                        title: Text('joao.silva@example.com'),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.phone, color: Colors.green),
                        title: Text('+55 (11) 98765-4321'),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.location_on, color: Colors.red),
                        title: Text('São Paulo, Brasil'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão de Ação (Ex: Configurações)
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configurações clicado!')),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurações do Perfil'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Botão de largura total
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}