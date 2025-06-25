import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String apiUrl = 'https://api.restbot.shop/auth/login';
  static const String _jrtCookieKey = 'jrtCookie'; // Chave para salvar o cookie jrt

  Future<bool> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': senha}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      // --- Início da modificação para guardar o cookie jrt ---
      String? setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader != null) {
        // Encontre o cookie 'jrt' no cabeçalho 'set-cookie'
        // Este é um exemplo simples e pode precisar de um parsing mais robusto
        // dependendo da complexidade do cabeçalho Set-Cookie retornado pelo seu servidor.
        RegExp regExp = RegExp(r'jrt=([^;]+);');
        Match? match = regExp.firstMatch(setCookieHeader);

        if (match != null && match.groupCount > 0) {
          String jrtValue = 'jrt=${match.group(1)}'; // Reconstroi o cookie como 'jrt=SEU_TOKEN'
          await prefs.setString(_jrtCookieKey, jrtValue);
          print('Cookie jrt salvo: $jrtValue');
        }
      }
      // --- Fim da modificação para guardar o cookie jrt ---

      // Salva o token e partes importantes do usuário e da empresa
      await prefs.setString('token', data['token']);
      await prefs.setInt('userId', data['user']['id']);
      await prefs.setString('userName', data['user']['name']);
      await prefs.setString('userEmail', data['user']['email']);
      await prefs.setString('userProfile', data['user']['profile']);
      await prefs.setInt('companyId', data['user']['company']['id']);
      await prefs.setString('companyName', data['user']['company']['name']);

      // Opcional: salvar configurações da empresa como JSON string
      await prefs.setString('companySettings', jsonEncode(data['user']['company']['settings']));

      return true;
    }

    return false;
  }

  Future<String?> getJrtCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jrtCookieKey);
  }

  Future<Map<String, dynamic>> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('token'),
      'userId': prefs.getInt('userId'),
      'userName': prefs.getString('userName'),
      'userEmail': prefs.getString('userEmail'),
      'userProfile': prefs.getString('userProfile'),
      'companyId': prefs.getInt('companyId'),
      'companyName': prefs.getString('companyName'),
      'companySettings': jsonDecode(prefs.getString('companySettings') ?? '{}'), // Usar '{}' para JSON vazio
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}