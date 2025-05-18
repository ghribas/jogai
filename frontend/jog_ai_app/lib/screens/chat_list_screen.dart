// -----------------------------------------------------------------------------
// Sistema: JogAI
// Autor: Guilherme Heyse Ribas
// Criado em: 15 e 16 de maio de 2025
// Evento: Imersão IA - 3ª Edição (Alura + Google Gemini)
//
// Este sistema foi inteiramente desenvolvido com auxílio da inteligência artificial
// Google Gemini, utilizando Python e Flutter com integração direta ao modelo Gemini.
//
// Todos os arquivos deste projeto foram gerados durante a Imersão promovida pela Alura
// em parceria com o Google, como uma exploração prática do uso de IA em desenvolvimento
// de software.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:jog_ai_app/models/chat_model.dart';
import 'package:jog_ai_app/screens/chat_screen.dart';
import 'package:jog_ai_app/screens/change_password_screen.dart';
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/services/auth_service.dart';
import 'package:jog_ai_app/widgets/chat_rail.dart';
import 'package:jog_ai_app/widgets/main_layout.dart';
import 'package:jog_ai_app/widgets/dashboard_view.dart';
import 'package:jog_ai_app/widgets/chat_config_form.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  final int? initialChatId;

  const ChatListScreen({super.key, this.initialChatId});

  @override
  ChatListScreenState createState() => ChatListScreenState();
}

class ChatListScreenState extends State<ChatListScreen> {
  int? _selectedChatId;
  final GlobalKey<ChatRailState> _chatRailKey = GlobalKey<ChatRailState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  List<Chat> _allUserChats = [];
  List<Chat> _filteredUserChats = [];
  bool _isLoadingChats = true;
  String? _loadingError;

  ApiService get _apiService => Provider.of<ApiService>(context, listen: false);
  AuthService get _authService => Provider.of<AuthService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _selectedChatId = widget.initialChatId;
    
    _searchController.addListener(_onSearchChanged);
    _loadAllUserChats();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
      _filterChats();
    });
  }

  Future<void> _loadAllUserChats() async {
    if (!mounted) return;
    setState(() {
      _isLoadingChats = true;
      _loadingError = null;
    });
    try {
      final userId = _authService.userId;
      if (userId != null) {
        final chats = await _apiService.getUserChats(userId);
        if (!mounted) return;
        setState(() {
          _allUserChats = chats;
          _filterChats();
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loadingError = "Usuário não autenticado.";
          _allUserChats = [];
          _filteredUserChats = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = "Erro ao carregar chats: ${e.toString()}";
        _allUserChats = [];
        _filteredUserChats = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  void _filterChats() {
    if (_searchTerm.isEmpty) {
      _filteredUserChats = List.from(_allUserChats);
    } else {
      _filteredUserChats = _allUserChats
          .where((chat) =>
              chat.title.toLowerCase().contains(_searchTerm.toLowerCase()))
          .toList();
    }
  }

  void _onChatSelected(int chatId, String chatTitle) {
    if (chatId == -1) {
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }
    Navigator.of(context).pushReplacementNamed('/chat/$chatId');

    if (MediaQuery.of(context).size.width < 720 && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToDashboard() {
    // setState(() {
    //   _selectedChatId = null;
    //   _selectedChatTitle = null;
    // });
    // Navega para a rota raiz, que deve mostrar o dashboard.
    // O ChatListScreen será reconstruído, e _selectedChatId será null.
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _navigateToChangePassword() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
  }

  Future<void> _createNewGame() async {
    final userId = _authService.userId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não logado. Não é possível criar jogo.')),
      );
      return;
    }

    // Buscar a última idade usada pelo usuário
    int? lastUsedAge;
    try {
      lastUsedAge = await _apiService.getLastUsedAge(userId);
    } catch (e) {
      // Não bloquear o fluxo se falhar, apenas não haverá pré-preenchimento
      print("Erro ao buscar última idade usada em _createNewGame: $e");
    }

    // Mostrar o diálogo de configuração
    final configData = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false, // O usuário deve preencher ou cancelar
      builder: (BuildContext dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        double dialogWidth;
        if (screenWidth > 1024) { // Desktop
          dialogWidth = 600;
        } else if (screenWidth > 600) { // Tablet
          dialogWidth = screenWidth * 0.8;
        } else { // Smartphone
          dialogWidth = screenWidth * 0.9;
        }

        return AlertDialog(
          title: const Text("Configurar Novo Jogo"),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Ajustar padding do conteúdo
          content: SizedBox(
            width: dialogWidth,
            child: ChatConfigForm(
              initialAge: lastUsedAge, // Passar a idade para o formulário
              onSubmit: (data) {
                Navigator.of(dialogContext).pop(data); // Retorna os dados do formulário
              },
            ),
          ),
          // As ações (botões) estão dentro do ChatConfigForm
        );
      },
    );

    if (configData == null) return; // Usuário cancelou o diálogo

    try {
      // O campo 'title' não é mais enviado daqui, o backend irá gerá-lo.
      final Map<String, dynamic> chatPayload = {
        'user_id': userId,
        ...configData, // Adiciona todas as configurações do formulário
      };
      
      // Remover chaves com valor null antes de enviar para a API, se necessário
      // A API já deve estar preparada para lidar com campos opcionais como null ou ausentes.
      // chatPayload.removeWhere((key, value) => value == null);

      final newChatData = await _apiService.createChat(chatPayload);
      
      final newChatId = newChatData['id'] as int;
      // O título agora vem diretamente do backend, gerado pelo Gemini ou fallback.
      final newGameTitle = newChatData['title'] as String? ?? "Jogo Criado"; 

      if (!mounted) return;
      await _loadAllUserChats();

      // Navegar para a tela do novo chat usando pushReplacementNamed
      // Isso garante que o ChatListScreen seja reconstruído com o initialChatId correto
      // se a navegação for para /chat/<id>
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacementNamed('/chat/$newChatId');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar novo jogo: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (!authService.isLoggedIn) {
      // Se não estiver logado, auth_wrapper deve redirecionar para login.
      // Manter um CircularProgressIndicator pode ser útil se houver um pequeno delay no wrapper.
      return const Scaffold(body: Center(child: Text("Redirecionando para login...")));
    }

    // Tenta obter o chatId da rota se não foi passado via construtor
    final route = ModalRoute.of(context);
    if (route != null) {
      final uri = Uri.parse(route.settings.name ?? '');
      if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'chat') {
        final pathChatId = int.tryParse(uri.pathSegments[1]);
        if (pathChatId != null && _selectedChatId != pathChatId) {
           WidgetsBinding.instance.addPostFrameCallback((_) { 
            if (mounted) {
                 setState(() {
                    _selectedChatId = pathChatId;
                 });
            }
           });
        }
      } else if ((uri.path == '/' || uri.path == '/dashboard' || uri.path.isEmpty) && _selectedChatId != null) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
                 setState(() {
                    _selectedChatId = null;
                 });
            }
         });
      }
    }

    final bool isDesktop = MediaQuery.of(context).size.width >= 720;
    final bool estaNoDashboard = _selectedChatId == null;

    // Construção do campo de busca
    Widget searchField = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar chats pelo título...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.light 
              ? Colors.grey[200] 
              : Colors.grey[800],
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear(); // _onSearchChanged será chamado pelo listener
                  },
                )
              : null,
        ),
      ),
    );

    final chatRail = ChatRail(
      // key: _chatRailKey, // O GlobalKey para ChatRailState não é mais estritamente necessário
                           // se não precisarmos chamar métodos nele diretamente daqui.
                           // Mas pode ser mantido se houver outros usos.
      chats: _filteredUserChats, 
      isLoading: _isLoadingChats,
      loadingError: _loadingError,
      onChatSelected: _onChatSelected,
      onNewChat: _createNewGame,
      selectedChatId: _selectedChatId,
      onRefreshRequested: _loadAllUserChats, 
    );

    Widget mainContent;

    if (_selectedChatId != null) {
      mainContent = ChatScreen(
        key: ValueKey(_selectedChatId), 
        chatId: _selectedChatId!,
      );
    } else {
      // Envolve o DashboardView com uma Column para adicionar o searchField acima dele
      mainContent = Column(
        children: [
          searchField, // Adiciona o campo de busca aqui quando no dashboard
          Expanded(
            child: DashboardView(
              chats: _filteredUserChats, 
              isLoading: _isLoadingChats,
              loadingError: _loadingError,
              onChatSelected: _onChatSelected,
              onNewChat: _createNewGame,
              onRefreshRequested: _loadAllUserChats,
            ),
          ),
        ],
      );
    }

    // Definição do PopupMenuButton de usuário
    Widget userActionsMenu = PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle), 
      tooltip: 'Menu do Usuário',
      onSelected: (value) async {
        if (value == 'change_password') {
          _navigateToChangePassword();
        } else if (value == 'logout') {
          await _authService.logout();
          // A navegação será tratada pelo AuthWrapper
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'change_password',
          child: Text('Alterar Senha'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Sair'),
        ),
      ],
    );
    
    // Título da AppBar
    String appBarTitleText;
    if (estaNoDashboard) {
        appBarTitleText = 'Meus Jogos';
    } else {
        // Fornecer todos os campos obrigatórios para o Chat de fallback
        final now = DateTime.now();
        final selectedChat = _allUserChats.firstWhere(
          (c) => c.id == _selectedChatId, 
          orElse: () => Chat(
            id:0, 
            title:'Chat Não Encontrado', // Título mais informativo
            userId:0, // Ou um ID de usuário inválido/padrão
            createdAt: now, 
            lastAccessedAt: now, 
            status: 'unknown',
            // Outros campos como color, age, etc., são opcionais no construtor do ChatModel
          )
        ); 
        appBarTitleText = selectedChat.title;
    }

    // Definição da AppBar (como no seu código)
    AppBar appBar = AppBar(
      iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white),
      actionsIconTheme: IconThemeData(color: Theme.of(context).appBarTheme.actionsIconTheme?.color ?? Colors.white),
      title: isDesktop 
        ? Row(
            children: [
              InkWell(
                onTap: _navigateToDashboard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                  child: Text(
                    "JogAI", 
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ),
              ),
              const SizedBox(width: 24),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: _navigateToDashboard,
                child: const Text('Meus jogos', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: _createNewGame,
                child: const Text('Novo jogo', style: TextStyle(fontSize: 16)),
              ),
              if (!estaNoDashboard && _selectedChatId != null) ...[
                const Spacer(), 
                Expanded(
                  child: Text(
                    appBarTitleText, 
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
                      fontSize: 18, 
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end, // Alinha à direita se houver espaço
                  ),
                ),
              ]
            ],
          )
        : InkWell(
            onTap: _navigateToDashboard,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                estaNoDashboard ? "JogAI" : appBarTitleText, 
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )
              ),
            ),
          ),
      leading: !isDesktop
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(), // Usa _scaffoldKey aqui
            )
          : null, 
      actions: [
        if (isDesktop) 
          userActionsMenu
        else ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'dashboard') {
                _navigateToDashboard();
              } else if (value == 'new_chat') {
                _createNewGame();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'dashboard',
                child: Text('Meus jogos'),
              ),
              const PopupMenuItem<String>(
                value: 'new_chat',
                child: Text('Novo jogo'),
              ),
            ],
          ),
          userActionsMenu,
        ],
      ],
    );

    return Scaffold(
      key: _scaffoldKey, // _scaffoldKey é usado AQUI, no Scaffold principal.
      appBar: appBar,
      drawer: !isDesktop ? Drawer(child: chatRail) : null, 
      body: MainLayout(
        // REMOVER scaffoldKey daqui, pois MainLayout não o define.
        // scaffoldKey: _scaffoldKey, 
        rail: isDesktop ? chatRail : null, 
        showRail: isDesktop, // Simplificado: sempre mostra o rail em desktop se fornecido
        child: mainContent, 
      ),
    );
  }
} 