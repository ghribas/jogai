import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jog_ai_app/models/chat_model.dart';
import 'package:jog_ai_app/models/message_model.dart';
import 'package:jog_ai_app/utils/api_exception.dart';

class ApiService {
  // Defina o IP correto se estiver usando um emulador Android ou dispositivo físico.
  // Para emulador Android: 10.0.2.2
  // Para iOS simulador e web/desktop: localhost ou 127.0.0.1
  // Se estiver rodando o backend em uma máquina diferente na rede, use o IP daquela máquina.
  static const String _baseUrl = "http://127.0.0.1:5000/api"; // Porta padrão do Flask é 5000

  Future<Map<String, dynamic>> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chats'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // Aqui normalmente você enviaria um token de autenticação
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode(payload),
    );
    return _handleResponse(response);
  }

  Future<List<Chat>> getUserChats(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chats/$userId'),
      headers: <String, String>{
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );
    final decoded = _handleResponse(response);
    if (decoded is List) {
      return decoded.map((data) => Chat.fromJson(data as Map<String, dynamic>)).toList();
    }
    throw Exception('Resposta inesperada do servidor ao buscar chats.');
  }

  Future<Map<String, dynamic>> getChatDetails(int chatId) async {
     final response = await http.get(
      Uri.parse('$_baseUrl/chat/$chatId'),
      headers: <String, String>{
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendMessage(int chatId, String message) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/$chatId/message'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode(<String, String>{'message': message}),
    );
    return _handleResponse(response);
  }

   Future<Map<String, dynamic>> updateChatStatus(int chatId, String status) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/chat/$chatId/status'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode(<String, String>{'status': status}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateChatObservations(int chatId, String observations) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/chat/$chatId/observations'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode(<String, String>{'observations': observations}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateChatTitle(int chatId, String newTitle) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/chat/$chatId/title'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode(<String, String>{'title': newTitle}),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)); // Decodifica como UTF-8
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      throw Exception('Falha na API: ${response.statusCode} - ${decoded['error'] ?? response.body}');
    }
  }

  // Deletar um chat
  Future<void> deleteChat(int chatId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/chat/$chatId'),
      headers: <String, String>{
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      // Chat deletado com sucesso
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Chat não encontrado para deleção.');
    } else {
      try {
        final responseBody = jsonDecode(response.body);
        throw Exception('Falha ao deletar chat: ${responseBody['error'] ?? response.reasonPhrase}');
      } catch (e) {
        // Se o corpo não for JSON ou estiver vazio
        throw Exception('Falha ao deletar chat: ${response.reasonPhrase} (código: ${response.statusCode})');
      }
    }
  }

  // Atualizar a cor de um chat
  Future<Map<String, dynamic>> updateChatColor(int chatId, String newColorHex) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/chat/$chatId/color'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 'Authorization': 'Bearer YOUR_TOKEN', // Adicionar se autenticação estiver implementada
      },
      body: jsonEncode(<String, String>{'color': newColorHex}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Erro ao atualizar cor do chat: ${errorBody['error']}');
    }
  }

  Future<Map<String, dynamic>> changePassword(int userId, String currentPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/user/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Espera {'message': 'Senha alterada com sucesso!'}
    } else {
      final errorBody = jsonDecode(response.body);
      String errorMessage = errorBody['error'] ?? 'Erro desconhecido ao alterar senha.';
      // Forçar um status code diferente para o Exception se a API retornar um erro específico
      // que o frontend possa querer tratar de forma diferente (ex: 403 para senha atual incorreta)
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  // Novo método para buscar a última idade usada
  Future<int?> getLastUsedAge(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/$userId/last_used_age'),
        headers: <String, String>{
          // 'Authorization': 'Bearer YOUR_TOKEN', // Adicionar se autenticação estiver implementada
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // O backend retorna {'last_used_age': null} ou {'last_used_age': <idade>}
        if (data.containsKey('last_used_age')) {
          return data['last_used_age'] as int?;
        }
        return null; // Caso a chave não exista, embora o backend deva sempre enviar
      } else if (response.statusCode == 404) {
        // Usuário não encontrado, ou talvez nenhum chat com idade ainda - tratar como nenhuma idade prévia
        return null;
      } else {
        // Outros erros de servidor
        print("Erro ao buscar última idade usada: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exceção ao buscar última idade usada: $e");
      return null; // Em caso de qualquer exceção, não pré-preenche
    }
  }
} 