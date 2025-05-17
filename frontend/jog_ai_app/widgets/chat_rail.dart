import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jog_ai_app/models/chat_model.dart';
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class ChatRail extends StatefulWidget {
  final Function(int gameId, String gameTitle) onChatSelected;
  final Function() onNewChat;
  final int? selectedChatId;

  const ChatRail({
    super.key,
    required this.onChatSelected,
    required this.onNewChat,
    this.selectedChatId,
  });

  @override
  ChatRailState createState() => ChatRailState();
}

class ChatRailState extends State<ChatRail> {
  late Future<List<Chat>> _gamesFuture;

  ApiService get _apiService => Provider.of<ApiService>(context, listen: false);
  AuthService get _authService => Provider.of<AuthService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _loadGames();
  }
  
  void refreshChats() {
    _loadGames();
  }

  void _loadGames() {
    final userId = _authService.userId;
    if (userId != null) {
      setState(() {
        _gamesFuture = _apiService.getUserChats(userId);
      });
    } else {
      setState(() {
        _gamesFuture = Future.error('Usuário não logado.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    if (!authService.isLoggedIn) {
        return const SizedBox.shrink(); 
    }

    return Material(
      elevation: 2.0,
      child: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sports_esports_outlined),
                label: const Text('Novo Jogo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: widget.onNewChat, 
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Chat>>(
                future: _gamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Erro: ${snapshot.error}', textAlign: TextAlign.center),
                    ));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum jogo'));
                  }

                  final games = snapshot.data!;
                  return ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final isSelected = game.id == widget.selectedChatId;
                      return ListTile(
                        title: Text(game.title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis,),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(game.status, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.secondary : null)),
                            Text(
                              DateFormat('dd/MM/yy HH:mm').format(game.lastAccessedAt.toLocal()),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Theme.of(context).colorScheme.secondary.withOpacity(0.7) : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        leading: Icon(Icons.sports_esports_outlined, color: isSelected ? Theme.of(context).colorScheme.secondary : null),
                        onTap: () => widget.onChatSelected(game.id, game.title),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                    await _authService.logout();
                },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
} 