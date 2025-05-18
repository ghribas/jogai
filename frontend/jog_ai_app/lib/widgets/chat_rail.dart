import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Não é mais usado diretamente aqui se as datas já vêm formatadas ou o modelo faz isso
import 'package:jog_ai_app/models/chat_model.dart';
// import 'package:jog_ai_app/services/api_service.dart'; // Não é mais usado para carregar chats
import 'package:jog_ai_app/services/auth_service.dart';
// import 'package:jog_ai_app/utils/date_utils.dart'; // Não é mais usado diretamente aqui
import 'package:provider/provider.dart';

class ChatRail extends StatefulWidget {
  final Function(int gameId, String gameTitle) onChatSelected;
  final Function() onNewChat; 
  final int? selectedChatId; 
  final List<Chat> chats; // Nova propriedade
  final bool isLoading; // Nova propriedade
  final String? loadingError; // Nova propriedade
  final Future<void> Function()? onRefreshRequested; // Nova propriedade

  const ChatRail({
    super.key,
    required this.onChatSelected,
    required this.onNewChat,
    this.selectedChatId,
    required this.chats, // Requerido
    required this.isLoading, // Requerido
    this.loadingError,
    this.onRefreshRequested,
  });

  @override
  ChatRailState createState() => ChatRailState();
}

class ChatRailState extends State<ChatRail> {
  // Removido _chatsFuture e lógica de _loadChats, refreshChats
  // ApiService get _apiService => Provider.of<ApiService>(context, listen: false);
  AuthService get _authService => Provider.of<AuthService>(context, listen: false);

  // initState e dispose não são mais necessários para carregar chats aqui

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
              child: _buildChatList(), // Usa o novo método para construir a lista
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

  Widget _buildChatList() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar jogos: ${widget.loadingError}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              if (widget.onRefreshRequested != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  onPressed: widget.onRefreshRequested,
                ),
            ],
          ),
        ),
      );
    }

    if (widget.chats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhum jogo encontrado.\nCrie um novo para começar!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Se chegou aqui, temos chats e não há erro / não está carregando
    return ListView.builder(
      itemCount: widget.chats.length,
      itemBuilder: (context, index) {
        final chat = widget.chats[index];
        final isSelected = chat.id == widget.selectedChatId;
        return ListTile(
          title: Text(chat.title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis,),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chat.age != null)
                Text(
                  'Idade: ${chat.age}', 
                  style: TextStyle(
                    fontSize: 11, 
                    color: isSelected 
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.9)
                      : Colors.grey[700]
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(chat.status, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.secondary : null)),
              Text(
                // Assumindo que chat.formattedLastAccessedAt já está formatado corretamente pelo modelo ChatModel
                chat.formattedLastAccessedAt, 
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Theme.of(context).colorScheme.secondary.withOpacity(0.7) : Colors.grey[600],
                ),
              ),
            ],
          ),
          isThreeLine: chat.age != null, // Mantém a lógica de três linhas se a idade estiver presente
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          leading: Icon(Icons.chat_bubble_outline, color: isSelected ? Theme.of(context).colorScheme.secondary : null),
          onTap: () => widget.onChatSelected(chat.id, chat.title),
        );
      },
    );
  }
} 