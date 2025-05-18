import 'package:flutter/material.dart';
import 'package:jog_ai_app/models/message_model.dart';
import 'package:jog_ai_app/models/chat_model.dart' show Chat;
import 'package:jog_ai_app/services/api_service.dart';
import 'package:jog_ai_app/utils/color_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jog_ai_app/utils/date_utils.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  // String? chatTitle; // O título agora virá do _chatDetails

  const ChatScreen({super.key, required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true; // Inicia como true para carregar detalhes
  bool _isSending = false;
  Chat? _chatDetails;
  bool _isEditingTitle = false; // Novo estado para edição do título
  late TextEditingController _titleEditingController; // Controlador para o TextField do título
  final FocusNode _titleFocusNode = FocusNode(); // Nó de foco para o TextField do título

  ApiService get _apiService => Provider.of<ApiService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _loadChatDetails();
    _titleEditingController = TextEditingController();

    // Listener para quando o TextField do título perder o foco
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus && _isEditingTitle) {
        // Se perdeu o foco E estava editando, salvar (ou poderia ser cancelar)
        // Por simplicidade, vamos salvar ao perder o foco.
        _saveTitleChange();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _titleEditingController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadChatDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.getChatDetails(widget.chatId);
      if (!mounted) return;
      final List<dynamic> messagesJson = response['messages'] ?? [];
      final List<Message> loadedMessages = messagesJson
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
      
      setState(() {
        _chatDetails = Chat.fromJson(response as Map<String, dynamic>); 
        _messages = loadedMessages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar chat: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isSending) {
      return;
    }
    final String text = _messageController.text;
    _messageController.clear();

    setState(() {
      _isSending = true;
      _messages.add(Message(
        id: -1, chatId: widget.chatId, sender: 'user', content: text, timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      final response = await _apiService.sendMessage(widget.chatId, text);
      final userMessageJson = response['user_message'];
      final geminiMessageJson = response['gemini_message'];
      final newChatStatus = response['chat_status'] as String?;

      if (!mounted) return;

      Message? confirmedUserMessage;
      Message? geminiMessage;

      if (userMessageJson != null) {
        try {
          confirmedUserMessage = Message.fromJson(userMessageJson as Map<String, dynamic>);
        } catch (e) {
          print("Erro ao parsear userMessageJson: $e"); // Manter
          throw Exception("Falha ao processar mensagem do usuário: $e"); 
        }
      }

      if (geminiMessageJson != null) {
         try {
          geminiMessage = Message.fromJson(geminiMessageJson as Map<String, dynamic>);
        } catch (e) {
          print("Erro ao parsear geminiMessageJson: $e"); // Manter
          throw Exception("Falha ao processar mensagem do Gemini: $e");
        }
      }

      setState(() {
        _messages.removeWhere((msg) => msg.id == -1 && msg.sender == 'user' && msg.content == text);

        if (confirmedUserMessage != null) {
          _messages.add(confirmedUserMessage);
        }
        if (geminiMessage != null) {
          _messages.add(geminiMessage);
        }
        
        if (newChatStatus != null) {
          if (_chatDetails != null) { 
            _chatDetails!.status = newChatStatus;
          }
        }
        _isSending = false;
      });
      _scrollToBottom();

    } catch (e) {
      print("Erro em _sendMessage: ${e.toString()}"); // Manter
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.removeWhere((msg) => msg.id == -1 && msg.sender == 'user' && msg.content == text);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _showObservationDialog() {
    TextEditingController observationController = TextEditingController(text: _chatDetails?.observations ?? '');
    showDialog(
        context: context,
        builder: (context) {
            return AlertDialog(
                title: const Text('Observações do Chat'),
                content: TextField(
                    controller: observationController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        hintText: 'Digite suas observações aqui...',
                        border: OutlineInputBorder(),
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                        onPressed: () async {
                            try {
                                await _apiService.updateChatObservations(widget.chatId, observationController.text);
                                setState(() {
                                    _chatDetails?.observations = observationController.text;
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Observações atualizadas!')),
                                );
                            } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao atualizar observações: ${e.toString()}')),
                                );
                            }
                        },
                        child: const Text('Salvar'),
                    ),
                ],
            );
        });
  }

  void _showStatusMenu() {
    if (_chatDetails == null) return;
    List<String> availableStatuses;
    final currentStatus = _chatDetails!.status;

    if (currentStatus == 'new' || currentStatus == 'started') {
      availableStatuses = ['cancelled', 'finished'];
    } else {
      availableStatuses = ['new', 'started', 'finished', 'cancelled']; // Todas as opções para outros status
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: availableStatuses.map((status) {
              return ListTile(
                title: Text(status[0].toUpperCase() + status.substring(1)),
                leading: Icon(
                  _chatDetails?.status == status ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _chatDetails?.status == status ? Theme.of(context).colorScheme.secondary : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _apiService.updateChatStatus(widget.chatId, status);
                    if (!mounted) return;
                    setState(() {
                      _chatDetails!.status = status;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status atualizado para: $status')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar status: ${e.toString()}')),
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showColorPicker() {
    if (_chatDetails == null) return;
    Color pickerColor = hexToColor(_chatDetails!.color);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma cor para o chat'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false, // Geralmente não queremos transparência para cores de UI de chat
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [], // Para não mostrar labels de RGB, HSV etc.
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(8.0)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Salvar Cor'),
              onPressed: () async {
                final newColorHex = colorToHexRGB(pickerColor); // Usar colorToHexRGB
                Navigator.of(context).pop();
                try {
                  final updatedChatData = await _apiService.updateChatColor(widget.chatId, newColorHex);
                  if (!mounted) return;
                  setState(() {
                    _chatDetails = Chat.fromJson(updatedChatData); // Atualizar com todos os dados do chat
                  });
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cor do chat atualizada para $newColorHex!')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar cor: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _startTitleEdit() {
    if (_chatDetails == null) return;
    setState(() {
      _isEditingTitle = true;
      _titleEditingController.text = _chatDetails!.title;
    });
    // Solicitar foco para o TextField após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  Future<void> _saveTitleChange() async {
    if (_chatDetails == null || !_isEditingTitle) return;
    final newTitle = _titleEditingController.text.trim();
    final originalTitle = _chatDetails!.title;

    setState(() {
      _isEditingTitle = false; // Sai do modo de edição imediatamente
    });

    if (newTitle.isNotEmpty && newTitle != originalTitle) {
      try {
        final updatedChat = await _apiService.updateChatTitle(widget.chatId, newTitle);
        if (!mounted) return;
        setState(() {
          _chatDetails = Chat.fromJson(updatedChat); // Atualiza com os dados do backend
        });
        // Opcional: snackbar de sucesso
      } catch (e) {
        if (!mounted) return;
        // Reverter para o título original se o salvamento falhar
        setState(() {
          _chatDetails!.title = originalTitle; // Reverte visualmente
          _titleEditingController.text = originalTitle;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar título: ${e.toString()}')),
        );
      }
    } else if (newTitle.isEmpty) {
        // Se o título for deixado vazio, reverter para o original
        _titleEditingController.text = originalTitle;
        // Poderia mostrar um SnackBar informando que o título não pode ser vazio
    }
  }

  void _cancelTitleEdit() {
    if (_chatDetails == null) return;
    setState(() {
      _isEditingTitle = false;
      _titleEditingController.text = _chatDetails!.title; // Reverte qualquer mudança não salva
    });
  }

  Widget _buildChatBubble(Message message) {
    final isUserMessage = message.sender == 'user';
    final String messageContent = message.content;

    // Condição para o botão "Iniciar Aventura" (lógica anterior)
    bool showInitialAdventureButton = !isUserMessage && 
                               _chatDetails?.status == 'new' && 
                               messageContent.contains('Deseja iniciar a aventura agora?') &&
                               _messages.where((m) => m.sender == 'user').isEmpty;

    List<Widget> bubbleContentWidgets = [];
    List<String> geminiOptions = [];

    if (!isUserMessage) {
      // Tentar extrair opções formatadas como [OPCAO] ...
      final lines = messageContent.split('\n');
      String mainText = "";
      for (var line in lines) {
        if (line.trim().startsWith('[OPCAO]')) {
          geminiOptions.add(line.trim().substring('[OPCAO]'.length).trim());
        } else {
          mainText += line + '\n';
        }
      }
      bubbleContentWidgets.add(Text(mainText.trim(), style: TextStyle(color: Colors.black87)));
    } else {
      // Mensagem do usuário normal
      bubbleContentWidgets.add(Text(messageContent, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)));
    }

    // Adicionar timestamp
    bubbleContentWidgets.add(const SizedBox(height: 4.0));
    bubbleContentWidgets.add(Text(
      formatTimeBrasilia(message.timestamp),
      style: TextStyle(fontSize: 10.0, color: isUserMessage ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7) : Colors.black54),
    ));

    // Adicionar botão de "Iniciar Aventura" se aplicável
    if (showInitialAdventureButton) {
      bubbleContentWidgets.add(const SizedBox(height: 12.0));
      bubbleContentWidgets.add(
        ElevatedButton(
          child: const Text('Sim, iniciar aventura!'),
          onPressed: () {
            _messageController.text = "Sim, vamos começar!";
            _sendMessage();
          },
        )
      );
    } 
    // Adicionar botões de opção do Gemini se houver opções e não for o botão de iniciar aventura
    else if (geminiOptions.isNotEmpty) {
      bubbleContentWidgets.add(const SizedBox(height: 10.0));
      for (var optionText in geminiOptions) {
        bubbleContentWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: ElevatedButton(
              child: Text(optionText, textAlign: TextAlign.center),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                textStyle: const TextStyle(fontWeight: FontWeight.normal),
              ),
              onPressed: () {
                _messageController.text = optionText; // Envia o texto da opção como mensagem
                _sendMessage();
              },
            ),
          )
        );
      }
    }

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Para a coluna se ajustar ao conteúdo
          children: bubbleContentWidgets,
        )
      ),
    );
  }

  Widget _buildConfigInfoPanelAdjusted() {
    if (_chatDetails == null) {
      return const SizedBox.shrink();
    }

    List<Widget> configItems = [];

    // Helper para adicionar item à lista se o valor não for nulo/vazio
    void addItem(String label, String? value, IconData icon, {bool indent = false}) {
      if (value != null && value.isNotEmpty) {
        configItems.add(_buildConfigDetailItem(context, label, value, icon: icon, indent: indent));
      }
    }

    addItem("Universo", _chatDetails!.universo, Icons.public);
    if (_chatDetails!.universo != _chatDetails!.universoOutro) { // Só mostra 'outro' se diferente
      addItem("Universo (Outro)", _chatDetails!.universoOutro, Icons.public, indent: true);
    }
    addItem("Gênero", _chatDetails!.genero, Icons.theater_comedy);
    if (_chatDetails!.genero != _chatDetails!.generoOutro) { // Só mostra 'outro' se diferente
      addItem("Gênero (Outro)", _chatDetails!.generoOutro, Icons.theater_comedy, indent: true);
    }
    if (_chatDetails!.age != null) {
        addItem("Idade do Jogador", _chatDetails!.age.toString(), Icons.cake_outlined);
    }
    addItem("Protagonista", _chatDetails!.nomeProtagonista, Icons.person_pin_circle_outlined);
    addItem("Nome do Mundo/Jogo", _chatDetails!.nomeUniversoJogo, Icons.map_outlined);
    addItem("Antagonista", _chatDetails!.nomeAntagonista, Icons.sports_kabaddi_outlined); // Ícone de antagonista
    addItem("Inspiração", _chatDetails!.inspiracao, Icons.lightbulb_outline);

    if (configItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    bool useTwoColumns = screenWidth > 600;

    Widget detailsContent;
    if (useTwoColumns) {
      List<Widget> column1 = [];
      List<Widget> column2 = [];
      for (int i = 0; i < configItems.length; i++) {
        if (i.isEven) {
          column1.add(configItems[i]);
        } else {
          column2.add(configItems[i]);
        }
      }
      detailsContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: column1)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: column2)),
          ],
        ),
      );
    } else {
      detailsContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: configItems),
      );
    }

    return ExpansionTile(
      title: const Text('Configurações da Aventura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      collapsedIconColor: Theme.of(context).colorScheme.secondary,
      iconColor: Theme.of(context).colorScheme.secondary,
      initiallyExpanded: false,
      children: [detailsContent], // Usar o detailsContent aqui
    );
  }

  Widget _buildConfigDetailItem(BuildContext context, String label, String value, {IconData? icon, bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 16.0 : 0, bottom: 8.0, right: 8.0), // Adicionado padding à direita
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text.rich( // Usar Text.rich para melhor controle de quebra de linha
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium, // Usar bodyMedium para consistência
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
              textAlign: TextAlign.left, // Garantir alinhamento à esquerda
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando Chat...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chatDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro no Chat')),
        body: const Center(child: Text('Não foi possível carregar os detalhes do chat.')),
      );
    }

    Color appBarColor = hexToColor(_chatDetails?.color);
    // Determinar a cor do texto da AppBar para contraste
    Color appBarTextColor = appBarColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    Widget appBarTitleWidget;
    if (_isEditingTitle) {
      appBarTitleWidget = TextField(
        controller: _titleEditingController,
        focusNode: _titleFocusNode,
        autofocus: true,
        style: TextStyle(color: appBarTextColor, fontSize: 20), // Ajustar tamanho da fonte se necessário
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Digite o título",
          hintStyle: TextStyle(color: appBarTextColor.withOpacity(0.7)),
        ),
        onSubmitted: (_) => _saveTitleChange(), // Salvar ao pressionar Enter
        // onTapOutside: (_) => _saveTitleChange(), // Já tratado pelo FocusNode listener
      );
    } else {
      appBarTitleWidget = GestureDetector(
        onTap: _startTitleEdit,
        child: Text(
          _chatDetails?.title ?? 'Chat',
          style: TextStyle(color: appBarTextColor),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: appBarTitleWidget, // Título dinâmico
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        actionsIconTheme: IconThemeData(color: appBarTextColor),
        actions: _isEditingTitle
          ? [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar Edição',
                onPressed: _cancelTitleEdit,
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Salvar Título',
                onPressed: _saveTitleChange,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Mudar Cor do Chat',
                onPressed: _showColorPicker,
              ),
              IconButton(
                icon: const Icon(Icons.sticky_note_2_outlined),
                tooltip: 'Observações',
                onPressed: _showObservationDialog,
              ),
              PopupMenuButton<String>(
                tooltip: 'Mudar Status',
                onSelected: (value) async {
                  if (value == 'change_status') {
                    _showStatusMenu();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'change_status',
                    child: Text('Mudar Status do Chat'),
                  ),
                ],
              ),
            ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: <Widget>[
              if (!_isLoading && _chatDetails != null) 
                  _buildConfigInfoPanelAdjusted(),
              Expanded(
                child: _messages.isEmpty
                    ? Center(child: Text(_chatDetails?.status == 'new' ? (_chatDetails?.observations ?? 'Envie uma mensagem para começar.') : 'Envie uma mensagem para continuar.'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildChatBubble(message);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    IconButton(
                      icon: _isSending ? const SizedBox(width:24, height:24, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 