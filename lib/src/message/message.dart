import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => _error = 'Token não encontrado. Faça login novamente.');
        return;
      }

      final url = Uri.parse('https://api.restbot.shop/messages/1?pageNumber=1');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _messages = data is List ? data : (data['messages'] ?? []);
        });
      } else {
        setState(() => _error = 'Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() => _error = 'Erro de rede: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text(msg['body'] ?? 'Sem conteúdo'),
                        subtitle: Text('ID: ${msg['id'] ?? 'Desconhecido'}'),
                        trailing: Text(msg['createdAt']?.toString() ?? ''),
                      ),
                    );
                  },
                ),
    );
  }
}
