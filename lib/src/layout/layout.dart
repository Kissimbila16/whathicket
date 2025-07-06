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
/// Recebe o corpo (conteúdo da mensagem) e o título da notificação.
Future<void> mostrarNotificacao(String corpo, String titulo) async {
  final int idNotificacao = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  // Detalhes específicos para notificações Android
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'canal_id', // ID do canal (deve ser único)
    'Canal de Notificações', // Nome do canal visível para o usuário
    importance: Importance.high, // Importância da notificação (alta prioridade)
    priority: Priority.high, // Prioridade da notificação
    icon: '@mipmap/ic_launcher', // Ícone da notificação
  );

  // Detalhes gerais da notificação (Android, iOS, etc.)
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  // Exibe a notificação
  await flutterLocalNotificationsPlugin.show(
    idNotificacao, // ID único da notificação
    titulo, // Título da notificação
    corpo, // Corpo/conteúdo da notificação
    notificationDetails, // Detalhes da notificação
  );
}

/// Realiza o logout do usuário, limpando os dados salvos e redirecionando para a tela de login.
Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Limpa todos os dados do SharedPreferences
  debugPrint('Dados do SharedPreferences limpos. Redirecionando para /.');
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, '/'); // Redireciona para a rota inicial (login)
  }
}

/// Página principal (LayoutPage) que exibe o conteúdo da aplicação e gerencia as notificações.
class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  Timer? _mensagemTimer; // Timer para a verificação periódica de mensagens
  int? userId; // ID do usuário logado
  String? _bearerToken; // Token de autenticação Bearer
  // Mapa para armazenar a última mensagem de cada ticket pelo seu ID.
  // Isso ajuda a evitar notificações repetidas para a mesma mensagem.
  Map<int, String> ultimoIdMensagemPorTicket = {};

  @override
  void initState() {
    super.initState();
    // Chama a função para carregar o token e iniciar a verificação de mensagens
    _carregarTokenEIniciarVerificacao();
  }

  @override
  void dispose() {
    // Cancela o timer quando o widget é descartado para evitar vazamentos de memória
    _mensagemTimer?.cancel();
    super.dispose();
  }

  /// Carrega o token e o ID do usuário do SharedPreferences e inicia o timer de verificação.
  Future<void> _carregarTokenEIniciarVerificacao() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId'); // Tenta obter o ID do usuário
    _bearerToken = prefs.getString('token'); // Tenta obter o token

    debugPrint('LayoutPage - userId carregado: $userId');
    debugPrint('LayoutPage - token carregado: $_bearerToken');

    if (userId != null && _bearerToken != null) {
      debugPrint('Token e UserId carregados com sucesso! userId: $userId');
      // Faz uma primeira verificação de mensagens imediatamente
      await verificarMensagens(userId!, _bearerToken!);
      // Configura o timer para verificar mensagens a cada 5 segundos
      _mensagemTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        debugPrint('Verificando mensagens automaticamente...');
        verificarMensagens(userId!, _bearerToken!);
      });
    } else {
      debugPrint('Usuário ou token não encontrado. Não foi possível iniciar a verificação de mensagens.');
      // Se não houver token ou userId, desloga o usuário (ou redireciona para login)
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

    debugPrint('Resposta da API (Status Code): ${response.statusCode}');
    debugPrint('Resposta da API (Body): ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> tickets = data['tickets'] ?? [];

      if (tickets.isEmpty) {
        debugPrint('Nenhum ticket encontrado para o usuário.');
        return;
      }

      // 1. Encontrar o ticket com o updatedAt mais recente
      Map<String, dynamic>? ticketMaisRecente;
      DateTime dataMaisRecente = DateTime.fromMillisecondsSinceEpoch(0);

      for (var ticket in tickets) {
        DateTime updatedAt = DateTime.parse(ticket['updatedAt']);
        if (updatedAt.isAfter(dataMaisRecente)) {
          dataMaisRecente = updatedAt;
          ticketMaisRecente = ticket;
        }
      }

      if (ticketMaisRecente == null) {
        debugPrint('Não foi possível determinar o ticket mais recente.');
        return;
      }

      final int ticketId = ticketMaisRecente['id'];
      final String currentLastMessage = ticketMaisRecente['lastMessage'] ?? '[Sem conteúdo]';
      final String contactName = ticketMaisRecente['contact']['name'] ?? 'Contato Desconhecido';
      final int unreadMessages = ticketMaisRecente['unreadMessages'] ?? 0;

      // 2. Verificar se a mensagem mais recente já foi notificada
      if (ultimoIdMensagemPorTicket[ticketId] != currentLastMessage) {
        ultimoIdMensagemPorTicket[ticketId] = currentLastMessage;

        // Disparar notificação se houver mensagens não lidas ou se for uma nova mensagem
        if (unreadMessages > 0) {
          await mostrarNotificacao(currentLastMessage, 'Nova Mensagem de $contactName');
          debugPrint('Notificação disparada para ticket $ticketId: $currentLastMessage');
        } else {
          debugPrint('Ticket $ticketId tem nova última mensagem, mas sem mensagens não lidas. Sem notificação.');
        }
      } else {
        debugPrint('Mensagem mais recente já foi notificada anteriormente.');
      }
    } else if (response.statusCode == 401) {
      debugPrint('Erro 401: Token inválido ou expirado. Realizando logout.');
      if (mounted) {
        logout(context);
      }
    } else {
      debugPrint('Erro ao verificar tickets: Status Code ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
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
    debugPrint('Erro na requisição para verificar tickets: $e');
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
                // Certifique-se de que a rota '/home' está definida no seu MaterialApp
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                // Certifique-se de que a rota '/perfil' está definida
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
            // Botão para testar uma notificação manual
            ElevatedButton(
              onPressed: () => mostrarNotificacao('Esta é uma notificação de teste.', 'Notificação Manual'),
              child: const Text('Testar Notificação'),
            ),
            const SizedBox(height: 16),
            // Botão para forçar a verificação de mensagens agora
            ElevatedButton(
              onPressed: () {
                if (userId != null && _bearerToken != null) {
                  verificarMensagens(userId!, _bearerToken!);
                } else {
                  // Mensagem caso o usuário não esteja logado ou o token não tenha sido carregado
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
            // Botão de Logout
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