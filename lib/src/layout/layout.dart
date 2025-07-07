import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for configuration
const String _apiBaseUrl = 'https://api.restbot.shop';
const Duration _messageCheckInterval = Duration(seconds: 5);
const String _defaultChannelId = 'default';
const String _defaultChannelName = 'Notificações';

// Initialize the notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(
  String body,
  String title, {
  String channelId = _defaultChannelId,
  String channelName = _defaultChannelName,
  Importance importance = Importance.high,
}) async {
  try {
    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.high ? Priority.high : Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  } catch (e) {
    debugPrint('Erro ao exibir notificação: $e');
  }
}

Future<void> logout(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  } catch (e) {
    debugPrint('Erro ao realizar logout: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao realizar logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  Timer? _messageTimer;
  int? userId;
  String? _bearerToken;
  String? _lastMessage;
  int groupMessageCount = 0;
  int companyMessageCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await initializeNotifications();
    await _loadTokenAndStartVerification();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTokenAndStartVerification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId');
      _bearerToken = prefs.getString('token');

      if (userId != null && _bearerToken != null) {
        await _checkMessages(userId!, _bearerToken!);
        _messageTimer = Timer.periodic(_messageCheckInterval, (_) {
          _checkMessages(userId!, _bearerToken!);
        });
      } else {
        if (mounted) await logout(context);
      }
    } catch (e) {
      debugPrint('Erro ao carregar token: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar configurações do usuário.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkMessages(int userId, String token) async {
    if (_isLoading) return; // Prevent concurrent API calls
    setState(() => _isLoading = true);

    final url = Uri.parse('$_apiBaseUrl/tickets/$userId');

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
        final tickets = data['tickets'] as List<dynamic>? ?? [];

        for (final ticket in tickets) {
          final String lastMessage = ticket['lastMessage']?.toString() ?? '[Sem mensagem]';
          final String contactName =
              ticket['contact']?['name']?.toString() ?? 'Contato Desconhecido';
          final int unreadMessages = ticket['unreadMessages'] as int? ?? 0;
          final bool isGroup = ticket['isGroup'] as bool? ?? false;

          final bool isCompany =
              !RegExp(r'^\d+$').hasMatch(contactName.trim()) &&
              contactName != 'Contato Desconhecido';

          if (lastMessage != _lastMessage && unreadMessages > 0) {
            _lastMessage = lastMessage;

            String title;
            if (isGroup) {
              title = 'Nova mensagem de GRUPO: $contactName';
            } else if (isCompany) {
              title = 'Nova mensagem de EMPRESA: $contactName';
            } else {
              title = 'Nova mensagem de $contactName';
            }

            await showNotification(lastMessage, title);

            if (mounted) {
              setState(() {
                if (isGroup) groupMessageCount++;
                if (isCompany) companyMessageCount++;
              });
            }
          }
        }
      } else if (response.statusCode == 401) {
        if (mounted) await logout(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao buscar tickets: ${response.statusCode}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar mensagens: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão ao verificar tickets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          ),
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
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => showNotification(
                        'Esta é uma notificação de teste.',
                        'Notificação Manual',
                      ),
              child: const Text('Testar Notificação'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (userId != null && _bearerToken != null) {
                        _checkMessages(userId!, _bearerToken!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Usuário não logado ou token não carregado.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
              child: const Text('Verificar Mensagens Agora'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => logout(context),
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