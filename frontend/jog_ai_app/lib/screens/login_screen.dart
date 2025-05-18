import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jog_ai_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success = await authService.login(_username, _password);
      
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Navegação é tratada pelo Consumer no main.dart
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no login. Verifique suas credenciais.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar removida para um visual mais limpo na tela de login/registro com box central
      // appBar: AppBar(title: const Text('Login - JogAI')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[200]!, Colors.grey[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Para evitar overflow se o teclado aparecer
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
              constraints: const BoxConstraints(maxWidth: 400), // Largura máxima do box
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[50], // Fundo do box branco acinzentado
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Para o box se ajustar ao conteúdo
                  children: <Widget>[
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        // Estilo padrão para o texto (será herdado por "Login ")
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary, // Azul marinho do tema
                        ),
                        children: <TextSpan>[
                          const TextSpan(text: 'Login '), // Mantém a cor primária
                          TextSpan(
                            text: 'JogAI',
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary), // Cor ciano do tema
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Usuário', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Por favor, insira seu usuário' : null,
                      onSaved: (value) => _username = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Por favor, insira sua senha' : null,
                      onSaved: (value) => _password = value!,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48) // Botão largo
                            ),
                            child: const Text('Entrar'), // Texto já será azul marinho pelo tema do botão
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text('Não tem uma conta? Registre-se'), // Cor ciano pelo tema do TextButton
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 