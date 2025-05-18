import 'package:flutter/material.dart';
import 'package:jog_ai_app/models/chat_model.dart';
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/services/auth_service.dart';
import 'package:jog_ai_app/widgets/chat_summary_card.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatefulWidget {
  final Function(int chatId, String chatTitle) onChatSelected;
  final Future<void> Function() onNewChat;
  final List<Chat> chats;
  final bool isLoading;
  final String? loadingError;
  final Future<void> Function()? onRefreshRequested;

  const DashboardView({
    super.key, 
    required this.onChatSelected, 
    required this.onNewChat,
    required this.chats,
    required this.isLoading,
    this.loadingError,
    this.onRefreshRequested,
  });

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String? _username;
  bool _isNewChatCardHovering = false;

  AuthService get _authService => Provider.of<AuthService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _username = _authService.currentUser?.username;
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, Chat chat) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Você tem certeza que deseja excluir o chat "${chat.title}"?'),
                const Text('Esta ação não pode ser desfeita.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await apiService.deleteChat(chat.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chat "${chat.title}" excluído com sucesso.')),
                    );
                    widget.onRefreshRequested?.call();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir chat: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                'Ocorreu um erro:', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent)
              ),
              const SizedBox(height: 10),
              Text(
                widget.loadingError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
              ),
              const SizedBox(height: 24),
              if (widget.onRefreshRequested != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  onPressed: widget.onRefreshRequested,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final bool hasChats = widget.chats.isNotEmpty;
    Widget mainContentArea;

    if (!hasChats) {
      mainContentArea = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Theme.of(context).colorScheme.secondary.withOpacity(0.6)),
            const SizedBox(height: 24),
            const Text(
              'Nenhum jogo encontrado com o filtro atual.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tente limpar a busca ou crie um novo jogo!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Criar Novo Jogo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ).copyWith(
                   overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return Theme.of(context).colorScheme.primary.withOpacity(0.85);
                      }
                      if (states.contains(MaterialState.pressed)) {
                        return Theme.of(context).colorScheme.primary.withOpacity(0.7);
                      }
                      return null;
                    },
                  ),
                ),
                onPressed: widget.onNewChat,
              ),
            ),
          ],
        ),
      );
    } else {
      final displayChats = widget.chats;

      Widget newGameCard = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) => setState(() => _isNewChatCardHovering = true),
        onExit: (event) => setState(() => _isNewChatCardHovering = false),
        child: GestureDetector(
          onTap: widget.onNewChat,
          child: Card(
            elevation: _isNewChatCardHovering ? 6.0 : 3.0,
            color: _isNewChatCardHovering 
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.85)
                : Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: InkWell(
              onTap: widget.onNewChat,
              borderRadius: BorderRadius.circular(12.0),
              splashColor: Theme.of(context).colorScheme.onSecondary.withOpacity(0.1),
              highlightColor: Theme.of(context).colorScheme.onSecondary.withOpacity(0.05),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 40, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Novo Jogo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      mainContentArea = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : (MediaQuery.of(context).size.width > 500 ? 2 : 1)),
            childAspectRatio: 1.3,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: displayChats.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: newGameCard,
              );
            }
            final chat = displayChats[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ChatSummaryCard(
                chat: chat,
                onTap: () => widget.onChatSelected(chat.id, chat.title),
                onDeleteRequested: (chatToDelete) {
                  _showDeleteConfirmationDialog(context, chatToDelete);
                },
              ),
            );
          },
        ),
      );
    }

    String greetingText = "Olá${_username != null ? ', $_username' : ''}!";
    if (_username != null && widget.chats.isNotEmpty) {
      greetingText = "Olá, $_username! Continue sua aventura ou crie uma nova:";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 8.0), 
          child: Text(
            greetingText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)
            ),
          ),
        ),
        Expanded(
          child: mainContentArea,
        ),
      ],
    );
  }
} 