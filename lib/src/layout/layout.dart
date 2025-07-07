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

  String? ultimoLastMessage;
  int groupMessageCount = 0;
  int companyMessageCount = 0;

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
      await verificarMensagens(userId!, _bearerToken!);
      _mensagemTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        verificarMensagens(userId!, _bearerToken!);
      });
    } else {
      if (mounted) logout(context);
    }
  }

  Future<void> verificarMensagens(int userId, String token) async {
    final url = Uri.parse('https://api.restbot.shop/tickets/$userId');

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

        final tickets = data['tickets'] as List<dynamic>;

        for (final ticket in tickets) {
          final String lastMessage = ticket['lastMessage'] ?? '[Sem mensagem]';
          final String contactName =
              ticket['contact']?['name'] ?? 'Contato Desconhecido';
          final int unreadMessages = ticket['unreadMessages'] ?? 0;
          final bool isGroup = ticket['isGroup'] ?? false;

          final bool isCompany =
              !RegExp(r'^\d+$').hasMatch(contactName.trim()) &&
              contactName != 'Contato Desconhecido';

          if (lastMessage != ultimoLastMessage) {
            ultimoLastMessage = lastMessage;

            if (unreadMessages > 0) {
              String tituloNotificacao;

              if (isGroup) {
                tituloNotificacao = 'Nova mensagem de GRUPO: $contactName';
              } else if (isCompany) {
                tituloNotificacao = 'Nova mensagem de EMPRESA: $contactName';
              } else {
                tituloNotificacao = 'Nova mensagem de $contactName';
              }

              await mostrarNotificacao(lastMessage, tituloNotificacao);

              setState(() {
                if (isGroup) groupMessageCount++;
                if (isCompany) companyMessageCount++;
              });
            }
          }
        }
      } else if (response.statusCode == 401) {
        if (mounted) logout(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao buscar tickets: ${response.body}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao verificar tickets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          Row(
            children: [
              const Icon(Icons.group, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '$groupMessageCount',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.business, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '$companyMessageCount',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
            ],
          )
        ],
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
              onPressed: () => mostrarNotificacao(
                  'Esta é uma notificação de teste.', 'Notificação Manual'),
              child: const Text('Testar Notificação'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (userId != null && _bearerToken != null) {
                  verificarMensagens(userId!, _bearerToken!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Usuário não logado ou token não carregado.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Verificar Mensagens Agora'),
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
