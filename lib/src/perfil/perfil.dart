import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  String? name;
  String? email;
  String? companyName;
  String? profile;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('userName') ?? 'Nome não disponível';
      email = prefs.getString('userEmail') ?? 'Email não disponível';
      companyName = prefs.getString('companyName') ?? 'Empresa não disponível';
      profile = prefs.getString('profile') ?? 'Perfil não disponível';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              backgroundColor: Colors.grey,
            ),
            const SizedBox(height: 20),

            // Nome do usuário
            Text(
              name ?? 'Carregando...',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Informações
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.blue),
                      title: Text(email ?? ''),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.business, color: Colors.orange),
                      title: Text(companyName ?? ''),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: Colors.teal),
                      title: Text(profile ?? ''),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              icon: const Icon(Icons.arrow_back_ios_new_outlined),
              label: const Text('Voltar na página'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
