import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// Importe para verificar se está no ambiente web
import 'package:flutter/foundation.dart' show kIsWeb;

// Definindo a URL base da API como uma constante.
// Se você configurar um proxy local para contornar o CORS no desenvolvimento web,
// você mudaria esta URL para apontar para o seu proxy (ex: 'http://localhost:8080/api').
const String _apiBaseUrl = 'https://api.restbot.shop';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _loginButtonFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('userEmail');
    final loginTimestamp = prefs.getInt('loginTimestamp');

    if (savedEmail != null && loginTimestamp != null) {
      final lastLogin = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final now = DateTime.now();

      if (now.difference(lastLogin).inDays <= 20) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/auth/login'), // Usando a URL base configurável
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);

          final user = data['user'];
          await prefs.setInt('userId', user['id']);
          await prefs.setString('userName', user['name']);
          await prefs.setString('userEmail', user['email']);
          await prefs.setString('profile', user['profile']);

          final company = user['company'];
          if (company != null) {
            await prefs.setInt('companyId', company['id']);
            await prefs.setString('companyName', company['name']);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login bem-sucedido!'), backgroundColor: Colors.green),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Mensagem de erro do servidor
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro do servidor: ${response.statusCode} - ${response.body}'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        // Tratamento de erro específico para ambiente web (CORS)
        String errorMessage = 'Erro ao conectar: $e';
        if (kIsWeb) {
          // Se estiver no navegador e o erro for de rede/XMLHttpRequest,
          // é muito provável que seja um problema de CORS.
          if (e.toString().contains('XMLHttpRequest') || e.toString().contains('Failed to load network image')) {
            errorMessage = 'Erro de conexão no navegador (CORS). Certifique-se de que o servidor da API permite requisições da sua origem web ou use um proxy.';
          } else if (e.toString().contains('NetworkError')) {
             errorMessage = 'Erro de rede no navegador. Isso pode ser um problema de CORS ou conectividade.';
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'WhaTicket!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Faça login para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 30.0),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'seuemail@exemplo.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email.';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Por favor, insira um email válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Campo de Senha
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Sua senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context)
                        .requestFocus(_loginButtonFocusNode);
                    if (!_isLoading) _login();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha.';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Botão de Login
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        focusNode: _loginButtonFocusNode,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _login,
                        child: const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                const SizedBox(height: 16.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Não tem uma conta?"),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Navegar para a página de registro.'),
                          ),
                        );
                      },
                      child: const Text('Crie uma aqui'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
