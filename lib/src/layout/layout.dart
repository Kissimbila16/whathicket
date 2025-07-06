import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> mostrarNotificacao(String corpo) async {
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
    'Nova mensagem recebida',
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
  String? ultimoIdMensagem;
  String? _bearerToken; // Variável para armazenar o token

  @override
  void initState() {
    super.initState();
    _carregarTokenEIniciarVerificacao(); // Chamada inicial para carregar o token e iniciar o timer
  }

  @override
  void dispose() {
    _mensagemTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarTokenEIniciarVerificacao() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    _bearerToken = prefs.getString('token'); // Assumindo que o token é salvo como 'token'

    if (userId != null && _bearerToken != null) {
      _mensagemTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        verificarMensagens(userId!, _bearerToken!);
      });
    } else {
      debugPrint('Usuário ou token não encontrado. Não foi possível iniciar a verificação de mensagens.');
      // Opcional: Redirecionar para a tela de login se o token não for encontrado
      if (mounted) {
        logout(context);
      }
    }
  }

  Future<void> verificarMensagens(int userId, String token) async {
    final url = Uri.parse('https://api.restbot.shop/messages/$userId?pageNumber=1');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Adicionando o cabeçalho de autorização
          'Content-Type': 'application/json', // É uma boa prática incluir o Content-Type
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final mensagens = data['messages'] ?? [];

        if (mensagens.isNotEmpty) {
          final primeira = mensagens[0];
          final msgId = primeira['id'].toString();

          // Mostra notificação apenas se for uma mensagem nova
          if (msgId != ultimoIdMensagem) {
            ultimoIdMensagem = msgId;
            final texto = primeira['body'] ?? '[Sem conteúdo]';
            await mostrarNotificacao(texto);
          }
        }
      } else if (response.statusCode == 401) {
        // Lida com erro de não autorizado (token expirado ou inválido)
        debugPrint('Erro 401: Token inválido ou expirado. Realizando logout.');
        if (mounted) {
          logout(context);
        }
      } else {
        debugPrint('Erro ao verificar mensagens: Status Code ${response.statusCode}');
        debugPrint('Corpo da resposta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao verificar mensagens: $e');
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
        onPressed: () => mostrarNotificacao('Notificação manual'),
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
        child: const Text('Verificar Mensagem Agora'),
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