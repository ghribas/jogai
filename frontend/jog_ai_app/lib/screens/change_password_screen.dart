import 'package:flutter/material.dart';
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/services/auth_service.dart';
import 'package:jog_ai_app/utils/api_exception.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (authService.userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Usuário não identificado. Faça login novamente.";
        });
        return;
      }

      try {
        await apiService.changePassword(
          authService.userId!,
          _currentPasswordController.text,
          _newPasswordController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso!')),
        );
        // Opcional: Deslogar o usuário para que ele precise logar com a nova senha
        // await authService.logout(); 
        // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        // Ou simplesmente voltar para a tela anterior ou dashboard
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // Navegar para uma tela padrão se não puder voltar (ex: dashboard)
          // Navigator.of(context).pushReplacementNamed('/chat_list'); 
        }
      } on ApiException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = "Ocorreu um erro inesperado. Tente novamente.";
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

 @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar Senha'),
         backgroundColor: Theme.of(context).colorScheme.primary, // Cor de fundo da AppBar
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Cor do texto e ícones da AppBar
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Mantenha sua conta segura',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os campos abaixo para alterar sua senha.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32.0),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha Atual',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha atual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Senha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_person_outlined),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua nova senha';
                      }
                      if (value.length < 6) {
                        return 'Nova senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _confirmNewPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Nova Senha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_person_outlined),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua nova senha';
                      }
                      if (value != _newPasswordController.text) {
                        return 'As novas senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28.0),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _submitChangePassword,
                          child: const Text('Alterar Senha'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 