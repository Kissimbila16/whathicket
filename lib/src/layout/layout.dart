import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Instância global para as notificações locais
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Mostra uma notificação local no dispositivo.
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

/// Envia uma mensagem de debug para log e como notificação (canal de debug)
Future<void> debugNotify(String mensagem) async {
  debugPrint(mensagem);
  await mostrarNotificacao(
    mensagem,
    'Debug',
    canalId: 'debug_channel',
    canalNome: 'Mensagens de Debug',
    importancia: Importance.low,
  );
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

  String? ultimoLastMessage;

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

    await debugNotify('LayoutPage - userId carregado: $userId');
    await debugNotify('LayoutPage - token carregado: $_bearerToken');

    if (userId != null && _bearerToken != null) {
      await debugNotify('Token e UserId carregados com sucesso! userId: $userId');
      await verificarMensagens(userId!, _bearerToken!);
      _mensagemTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        verificarMensagens(userId!, _bearerToken!);
      });
    } else {
      await debugNotify(
          'Usuário ou token não encontrado. Não foi possível iniciar a verificação de mensagens.');
      if (mounted) {
        logout(context);
      }
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

      await debugNotify(
          'Resposta da API (Status Code): ${response.statusCode}');
      await debugNotify('Resposta da API (Body): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String lastMessage = data['lastMessage'] ?? '[Sem mensagem]';
        final String contactName =
            data['contact']?['name'] ?? 'Contato Desconhecido';
        final int unreadMessages = data['unreadMessages'] ?? 0;

        if (lastMessage != ultimoLastMessage) {
          ultimoLastMessage = lastMessage;

          if (unreadMessages > 0) {
            await mostrarNotificacao(
                lastMessage, 'Nova mensagem de $contactName');
            await debugNotify(
                'Notificação disparada: $lastMessage de $contactName');
          } else {
            await debugNotify(
                'Nova última mensagem detectada mas sem mensagens não lidas: $lastMessage');
          }
        } else {
          await debugNotify(
              'Última mensagem já foi notificada anteriormente: $lastMessage');
        }
      } else if (response.statusCode == 401) {
        await debugNotify(
            'Erro 401: Token inválido ou expirado. Realizando logout.');
        if (mounted) {
          logout(context);
        }
      } else {
        await debugNotify(
            'Erro ao verificar ticket: Status ${response.statusCode}');
        // await debugNotify('Corpo da resposta: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao buscar ticket: ${response.body}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      await debugNotify('Erro na requisição para verificar ticket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao verificar ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
