// ignore_for_file: unnecessary_import

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> mostrarNotificacao(
  String corpo,
  String titulo, {
  String canalId = 'default',
  String canalNome = 'Notificações',
  Importance importancia = Importance.high,
}) async {
  final int idNotificacao =
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  final androidDetails = AndroidNotificationDetails(
    canalId,
    canalNome,
    importance: importancia,
    priority: importancia == Importance.high ? Priority.high : Priority.low,
    icon: '@mipmap/ic_launcher',
  );

  final notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    idNotificacao,
    titulo,
    corpo,
    notificationDetails,
  );
}

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, '/');
  }
}

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  Timer? _mensagemTimer;
  int? userId;
  String? _bearerToken;

  @override
  void initState() {
    super.initState();
    _carregarTokenEIniciarVerificacao();
  }

  @override
  void dispose() {
    _mensagemTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarTokenEIniciarVerificacao() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    _bearerToken = prefs.getString('token');

    if (userId != null && _bearerToken != null) {
      _mensagemTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        verificarNovasMensagens(userId!, _bearerToken!);
      });
    } else {
      if (mounted) {
        logout(context);
      }
    }
  }

  Future<void> verificarNovasMensagens(int userId, String token) async {
    final contatos = await listarContatosComMensagens(userId, token);

    final prefs = await SharedPreferences.getInstance();
    final notificadosPorTicket =
        prefs.getStringMap('ultimoNotificadoPorTicket') ?? {};

    for (var contato in contatos) {
      if ((contato as Map).isNotEmpty) {
        final ticketId = contato['tickets'][0]['id'].toString();
        final mensagens = await pegarMensagens(int.parse(ticketId), token);
            debugPrint('📋 msg: $mensagens');
        if (mensagens.isEmpty) continue;

        // Ordenar mensagens da mais antiga para a mais recente
        mensagens.sort((a, b) {
          final tsA = DateTime.tryParse(a['createdAt'] ?? '')?.millisecondsSinceEpoch ?? 0;
          final tsB = DateTime.tryParse(b['createdAt'] ?? '')?.millisecondsSinceEpoch ?? 0;
          return tsA.compareTo(tsB);
        });

        // Pega só a última mensagem
        final ultimaMsg = mensagens.last;

        final msgId = ultimaMsg['id'].toString();
        final corpo = ultimaMsg['body'] ?? '';
        final autor = contato['name'] ?? 'Desconhecido';
        final ultimoNotificado = notificadosPorTicket[ticketId];

        if (msgId != ultimoNotificado) {
          await mostrarNotificacao(corpo, 'Nova mensagem de $autor');
          notificadosPorTicket[ticketId] = msgId;
        }
      }
    }

    await prefs.setString(
      'ultimoNotificadoPorTicket',
      jsonEncode(notificadosPorTicket),
    );
  }

  Future<List<Map<String, dynamic>>> listarContatosComMensagens(
      int userId, String token) async {
    final url = Uri.parse('https://api.restbot.shop/contacts');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('contacts')) {
          final List contacts = data['contacts'];
          return List<Map<String, dynamic>>.from(contacts);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> pegarMensagens(
      int ticketId, String token) async {
    final url = Uri.parse('https://api.restbot.shop/messages/$ticketId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('messages')) {
          return List<Map<String, dynamic>>.from(data['messages']);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> testarListagem() async {
    if (userId == null || _bearerToken == null) return;

    final contatos = await listarContatosComMensagens(userId!, _bearerToken!);
    print('📋 Contatos: $contatos');
    for (var contato in contatos) {
      debugPrint('${contato['name']} (${contato['number']})');
      if ((contato['tickets'] as List).isNotEmpty) {
        final ticketId = contato['id'];

        final mensagens = await pegarMensagens(ticketId, _bearerToken!);
        if (mensagens.isEmpty) continue;

        // Ordenar e pegar só a última mensagem
        mensagens.sort((a, b) {
          final tsA = DateTime.tryParse(a['createdAt'] ?? '')?.millisecondsSinceEpoch ?? 0;
          final tsB = DateTime.tryParse(b['createdAt'] ?? '')?.millisecondsSinceEpoch ?? 0;
          return tsA.compareTo(tsB);
        });

        final ultimaMsg = mensagens.last;

        debugPrint('📨 ${ultimaMsg['body']}');
        // await mostrarNotificacao(ultimaMsg['body'], 'Nova mensagem de ${contato['name']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whaticket'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 4.0,
      ),
      drawer: Drawer(
        width: 200,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      'Menu',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/perfil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                logout(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: testarListagem,
              child: const Text('Listar contatos + mensagens'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension SharedPreferencesMap on SharedPreferences {
  Map<String, String> getStringMap(String key) {
    final jsonStr = getString(key);
    if (jsonStr == null) return {};
    final decoded = jsonDecode(jsonStr);
    return Map<String, String>.from(decoded);
  }
}
