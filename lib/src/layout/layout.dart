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

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    canalId,
    canalNome,
    importance: importancia,
    priority: importancia == Importance.high ? Priority.high : Priority.low,
    icon: '@mipmap/ic_launcher',
  );

  final NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    idNotificacao,
    titulo,
    corpo,
    notificationDetails,
  );
}

Future<void> debugNotify(String mensagem) async {
  debugPrint(mensagem);
}

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await debugNotify('Dados do SharedPreferences limpos. Redirecionando para /.');
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
      await debugNotify('Token e UserId carregados com sucesso! userId: $userId');
      _mensagemTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        listarContatosComMensagens(userId!, _bearerToken!);
      });
    } else {
      await debugNotify(
          'Usuário ou token não encontrado. Não foi possível iniciar a verificação de mensagens.');
      if (mounted) {
        logout(context);
      }
    }
  }

  /// LISTA os contatos do usuário logado com tickets.
  Future<List<Map<String, dynamic>>> listarContatosComMensagens(int userId, String token) async {
    final url = Uri.parse('https://api.restbot.shop/contacts');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await debugNotify('Listar contatos - Status: ${response.statusCode}');
      await debugNotify('Listar contatos - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('contacts')) {
          final List contacts = data['contacts'];
          return List<Map<String, dynamic>>.from(contacts);
        } else {
          await debugNotify('Resposta inesperada: não contém chave contacts');
          return [];
        }
      } else {
        await debugNotify('Erro ao listar contatos: ${response.body}');
        return [];
      }
    } catch (e) {
      await debugNotify('Erro ao listar contatos: $e');
      return [];
    }
  }

  /// PEGA as mensagens do ticket especificado.
  Future<List<Map<String, dynamic>>> pegarMensagens(int userId, String token) async {
    final url = Uri.parse('https://api.restbot.shop/messages/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await debugNotify('Pegar mensagens - Status: ${response.statusCode}');
      await debugNotify('Pegar mensagens - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          await debugNotify('Resposta inesperada: não é uma lista');
          return [];
        }
      } else {
        await debugNotify('Erro ao pegar mensagens: ${response.body}');
        return [];
      }
    } catch (e) {
      await debugNotify('Erro ao pegar mensagens: $e');
      return [];
    }
  }

  Future<void> testarListagem() async {
    if (userId == null || _bearerToken == null) return;

    final contatos = await listarContatosComMensagens(userId!, _bearerToken!);
    debugPrint('📋 Contatos:');
    for (var contato in contatos) {
      debugPrint('${contato['name']} (${contato['id']})');
      if ((contato['tickets'] as List).isNotEmpty) {
        final ticketId = contato['tickets'][0]['id'];
        debugPrint('➡️ Ticket: $ticketId');

        final mensagens = await pegarMensagens(userId!, _bearerToken!);
        for (var msg in mensagens) {
          debugPrint('📨 ${msg['body']}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whaticket'),
        centerTitle: true,
        backgroundColor: Colors.teal,
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