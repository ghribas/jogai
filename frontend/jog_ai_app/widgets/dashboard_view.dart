import 'package:flutter/material.dart';
import 'package:jog_ai_app/models/chat_model.dart';
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/services/auth_service.dart';
import 'package:jog_ai_app/widgets/chat_summary_card.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatefulWidget {
  final Function(int gameId, String gameTitle) onChatSelected;
  final Future<void> Function() onNewChat;

  const DashboardView({super.key, required this.onChatSelected, required this.onNewChat});

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<List<Chat>> _recentGamesFuture;
  String? _username;
  bool _isNewGameCardHovering = false;

  ApiService get _apiService => Provider.of<ApiService>(context, listen: false);
  AuthService get _authService => Provider.of<AuthService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _username = _authService.currentUser?.username;
    _loadRecentGames();
  }

  void _loadRecentGames() {
    final userId = _authService.userId;
    if (userId != null) {
      setState(() {
        _recentGamesFuture = _apiService.getUserChats(userId);
      });
    } else {
      if (mounted) {
          setState(() {
            _recentGamesFuture = Future.error('Usuário não logado para carregar dashboard.');
          });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, Chat game) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Você tem certeza que deseja excluir o jogo "${game.title}"?'),
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
                  await _apiService.deleteChat(game.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Jogo "${game.title}" excluído com sucesso.')),
                    );
                    _loadRecentGames();
                    widget.onChatSelected(-1, "");
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir jogo: ${e.toString()}')),
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
    return FutureBuilder<List<Chat>>(
      future: _recentGamesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar jogos: ${snapshot.error}'));
        }

        final bool hasGames = snapshot.hasData && snapshot.data!.isNotEmpty;
        Widget mainContentArea;

        if (!hasGames) {
          mainContentArea = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_esports_outlined, size: 80, color: Theme.of(context).colorScheme.secondary.withOpacity(0.7)),
                const SizedBox(height: 24),
                const Text(
                  'Nenhum jogo por aqui ainda!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crie um novo jogo para começar sua aventura.',
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
          final allGames = snapshot.data!;
          
          List<Widget> gameCards = allGames.map((game) => ChatSummaryCard(
            chat: game,
            onTap: () => widget.onChatSelected(game.id, game.title),
            onDeleteRequested: () => _showDeleteConfirmationDialog(context, game),
          )).toList();
          
          Widget newGameCard = MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (event) => setState(() => _isNewGameCardHovering = true),
            onExit: (event) => setState(() => _isNewGameCardHovering = false),
            child: GestureDetector(
              onTap: widget.onNewChat,
              child: Card(
                elevation: _isNewGameCardHovering ? 6.0 : 3.0, 
                color: _isNewGameCardHovering 
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          List<Widget> gridItems = [newGameCard, ...gameCards];

          mainContentArea = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _username != null ? 'Bem-vindo(a), $_username!' : 'Seus Jogos Recentes',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continue de onde parou ou comece uma nova aventura.',
                   style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true, 
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300.0,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      return gridItems[index];
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return mainContentArea;
      },
    );
  }
} 