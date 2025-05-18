import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // Chave global para identificar o formulário e permitir a validação.
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Foco para os campos de texto (melhora a experiência do usuário)
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _loginButtonFocusNode = FocusNode(); // Para focar no botão após a senha

  bool _isPasswordVisible = false;
  bool _isLoading = false; // Para feedback visual durante o login

  @override
  void dispose() {
    // Limpar os controladores e focus nodes quando o widget for descartado
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Esconder o teclado
    FocusScope.of(context).unfocus();

    // Validar o formulário
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Inicia o indicador de carregamento
      });

      // Simulação de uma chamada de API/autenticação
      await Future.delayed(const Duration(seconds: 2));

      // Aqui você implementaria sua lógica de autenticação real.
      // Por exemplo, verificar se _emailController.text e _passwordController.text são válidos.
      final email = _emailController.text;
      final password = _passwordController.text;

      // Exemplo de verificação simples (substitua pela sua lógica)
      if (email == 'teste@exemplo.com' && password == 'senha123') {
        if (mounted) { // Verifica se o widget ainda está na árvore de widgets
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login bem-sucedido!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navegar para a próxima página (ex: HomePage)
          // Navigator.pushReplacementNamed(context, '/home');
          // Por agora, vamos apenas voltar como no seu exemplo original,
          // mas idealmente você navegaria para uma tela principal.
          Navigator.pop(context); // Ou navegue para a tela principal
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email ou senha inválidos.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false; // Termina o indicador de carregamento
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        // Se você quiser um botão de voltar explícito na AppBar:
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Center(
        child: SingleChildScrollView( // Permite rolagem se o conteúdo for maior que a tela
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo ou Título (opcional)
                Text(
                  'Bem-vindo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Faça login para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 40.0),

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
                  textInputAction: TextInputAction.next, // Move para o próximo campo
                  onFieldSubmitted: (_) {
                    // Muda o foco para o campo de senha
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email.';
                    }
                    // Validação simples de email
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done, // Indica que a entrada está concluída
                  onFieldSubmitted: (_) {
                     // Tenta fazer login ou foca no botão de login
                    FocusScope.of(context).requestFocus(_loginButtonFocusNode);
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
                const SizedBox(height: 8.0),

                // Link "Esqueci minha senha" (opcional)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Lógica para "Esqueci minha senha"
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade "Esqueci minha senha" a ser implementada.')),
                      );
                    },
                    child: const Text('Esqueceu a senha?'),
                  ),
                ),
                const SizedBox(height: 24.0),

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
                          // backgroundColor: Theme.of(context).primaryColor, // Cor de fundo
                          // foregroundColor: Colors.white, // Cor do texto e ícone
                        ),
                        onPressed: _login,
                        child: const Text('LOGIN', style: TextStyle(fontSize: 16)),
                      ),
                const SizedBox(height: 16.0),

                // Opção de criar conta (opcional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Não tem uma conta?"),
                    TextButton(
                      onPressed: () {
                        // Navegar para a página de registro
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navegar para a página de registro.')),
                        );
                        // Ex: Navigator.pushNamed(context, '/register');
                      },
                      child: const Text('Crie uma aqui'),
                    ),
                  ],
                ),

                // Botão de Voltar (como no seu exemplo original, se ainda necessário)
                // Se a navegação para login for feita com push, a AppBar já terá o botão de voltar.
                // Se não, você pode adicionar um botão explícito:
                // const SizedBox(height: 20),
                // TextButton(
                //   onPressed: () => Navigator.pop(context),
                //   child: const Text('Voltar para a tela anterior'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}