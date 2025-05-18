import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  final Widget child; // Conteúdo principal (ex: ChatScreen)
  final Widget? rail;   // Barra lateral para desktop
  final bool showRail; // Novo parâmetro para controlar a visibilidade do rail

  const MainLayout({
    super.key,
    required this.child,
    this.rail,
    this.showRail = true, // Por padrão, mostra o rail se disponível e em desktop
  });

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isRailExpanded = false; // Inicia recolhido

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 720; // Ponto de quebra para desktop
    final railColor = Colors.grey[100]; // Cinza bem claro, quase branco

    if (isDesktop && widget.rail != null && widget.showRail) {
      return Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _isRailExpanded ? 280.0 : 72.0, // Largura original do ChatRail vs. recolhido
              color: railColor,
              child: Column(
                children: [
                  Container( // Contêiner para o botão de expandir/recolher
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(_isRailExpanded ? Icons.chevron_left : Icons.menu),
                      tooltip: _isRailExpanded ? 'Recolher menu' : 'Expandir menu',
                      onPressed: () {
                        setState(() {
                          _isRailExpanded = !_isRailExpanded;
                        });
                      },
                    ),
                  ),
                  if (_isRailExpanded) // Somente mostra o conteúdo do rail se expandido
                    Expanded(child: widget.rail!),
                ],
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    } else {
      // Em telas menores ou se 'rail' não for fornecido, usa AppBar e Drawer (se houver)
      // A AppBar será definida dentro de cada tela que usa este layout.
      return Scaffold(
        body: widget.child,
      );
    }
  }
} 