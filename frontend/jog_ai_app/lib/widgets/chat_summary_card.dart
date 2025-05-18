import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jog_ai_app/models/chat_model.dart';
import 'package:jog_ai_app/utils/date_utils.dart';

// Função auxiliar para converter string hexadecimal em Color
Color hexToColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return Colors.grey[300]!; // Cor padrão se nula ou vazia
  }
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  try {
    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return Colors.grey[300]!; // Cor padrão em caso de erro de parsing
  }
}

class ChatSummaryCard extends StatefulWidget {
  final Chat chat;
  final VoidCallback onTap;
  final Function(Chat chat) onDeleteRequested; // Callback para solicitar exclusão

  const ChatSummaryCard({
    Key? key,
    required this.chat,
    required this.onTap,
    required this.onDeleteRequested,
  }) : super(key: key);

  @override
  State<ChatSummaryCard> createState() => _ChatSummaryCardState();
}

class _ChatSummaryCardState extends State<ChatSummaryCard> {
  bool _isMouseOver = false;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = hexToColor(widget.chat.color);

    return MouseRegion(
      onEnter: (_) => setState(() => _isMouseOver = true),
      onExit: (_) => setState(() => _isMouseOver = false),
      cursor: SystemMouseCursors.click, 
      child: Card(
        elevation: _isMouseOver ? 6.0 : 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cardColor, 
                  width: 12.0,
                ),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.chat.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.chat.age != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            'Idade do jogador: ${widget.chat.age}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        'Status: ${widget.chat.status}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acessado: ${widget.chat.formattedLastAccessedAt}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isMouseOver)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Deletar Chat',
                        onPressed: () {
                          widget.onDeleteRequested(widget.chat);
                        },
                        splashRadius: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 