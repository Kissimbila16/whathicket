import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson!=null) {
      setState(() {
        _user = jsonDecode(userJson);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'Nome não disponível';
    final email = _user?['email'] ?? 'Email não disponível';
    final phone = _user?['company']?['phone'] ?? 'Telefone não informado';
    final location = _user?['company']?['name'] ?? 'Local não definido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        centerTitle: true,
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

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
                            title: Text(email),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.phone, color: Colors.green),
                            title: Text(phone ?? 'Telefone não disponível'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.red),
                            title: Text(location),
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
