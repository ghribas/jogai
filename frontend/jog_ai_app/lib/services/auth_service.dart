import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/models/user_model.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  User? _currentUser;
  bool _isLoggedIn = false;
  int? _userId;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  int? get userId => _userId;

  AuthService(this._apiService) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final storedUserId = await _storage.read(key: 'userId');
    final storedUsername = await _storage.read(key: 'username'); // Adicional, se quisermos persistir username

    if (storedUserId != null) {
      _userId = int.tryParse(storedUserId);
      if (_userId != null) {
         _isLoggedIn = true;
         // Opcional: recriar User object se username também for salvo
         if (storedUsername != null) {
            _currentUser = User(id: _userId!, username: storedUsername);
         }
         notifyListeners();
      } else {
        // Tratar caso de user_id inválido no storage
        await logout(); 
      }
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      if (response.containsKey('user_id')) {
        _userId = response['user_id'] as int;
        _currentUser = User(id: _userId!, username: username); // Assumimos que o login não retorna username, usamos o fornecido
        _isLoggedIn = true;
        await _storage.write(key: 'userId', value: _userId.toString());
        await _storage.write(key: 'username', value: username); // Salvar username
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Tratar erro de login (ex: mostrar mensagem para o usuário)
      print('Erro no login: $e');
    }
    return false;
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await _apiService.register(username, password);
       if (response.containsKey('user_id')) {
        // Opcionalmente, fazer login automaticamente após o registro
        // return await login(username, password);
        return true; // Indica que o registro foi bem-sucedido
      }
    } catch (e) {
      print('Erro no registro: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    _userId = null;
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'username');
    notifyListeners();
  }
} 