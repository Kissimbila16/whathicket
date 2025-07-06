import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> mostrarNotificacao(String corpo, String titulo) async { // Adicionei titulo
  final int idNotificacao = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'canal_id',
    'Canal Nome',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    idNotificacao,
    titulo, // Usando o título dinâmico
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
  // Mapa para armazenar o último ID de mensagem por ID do ticket
  Map<int, String> ultimoIdMensagemPorTicket = {};

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
      // Faz uma verificação inicial e depois inicia o timer
      await verificarMensagens(userId!, _bearerToken!);
      _mensagemTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        verificarMensagens(userId!, _bearerToken!);
      });
    } else {
      debugPrint('Usuário ou token não encontrado. Não foi possível iniciar a verificação de mensagens.');
      if (mounted) {
        logout(context);
      }
    }
  }

void mostrarErro(String msg) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
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

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Corpo da resposta: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> tickets = data['tickets'] ?? [];

      for (var ticket in tickets) {
        final int ticketId = ticket['id'];
        final String currentLastMessage = ticket['lastMessage'] ?? '[Sem conteúdo]';
        final String contactName = ticket['contact']['name'] ?? 'Contato Desconhecido';

        final String? ultimaRegistrada = ultimoIdMensagemPorTicket[ticketId];

        if (ultimaRegistrada == null || ultimaRegistrada != currentLastMessage) {
          ultimoIdMensagemPorTicket[ticketId] = currentLastMessage;

          debugPrint('Nova mensagem detectada no ticket $ticketId de $contactName');

          await mostrarNotificacao(currentLastMessage, 'Nova mensagem de $contactName');
        }
      }

    } else if (response.statusCode == 401) {
      debugPrint('Erro 401: Token inválido ou expirado. Realizando logout.');
      mostrarErro('Sessão expirada. Faça login novamente.');
      if (mounted) {
        logout(context);
      }

    } else {
      debugPrint('Erro ao verificar tickets: Status ${response.statusCode}');
      mostrarErro('Erro ao verificar mensagens: Status ${response.statusCode}');
    }

  } catch (e) {
    debugPrint('Erro ao verificar tickets: $e');
    mostrarErro('Erro inesperado ao verificar mensagens.');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
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
              onPressed: () => mostrarNotificacao('Esta é uma notificação de teste.', 'Notificação Manual'),
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
                      content: Text('Usuário não logado ou token não carregado.'),
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