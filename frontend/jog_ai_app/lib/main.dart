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
import 'package:jog_ai_app/screens/login_screen.dart';
import 'package:jog_ai_app/screens/registration_screen.dart';
import 'package:jog_ai_app/screens/chat_list_screen.dart';
import 'package:jog_ai_app/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:jog_ai_app/services/api_service.dart'; // Criaremos depois
import 'package:jog_ai_app/services/auth_service.dart'; // Criaremos depois
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint; // Adicionar debugPrint

// Se não estiver na web, usar I/O específico para timezone
// A importação condicional pode ser mais complexa de configurar no build.
// Por simplicidade, podemos tentar inicializar ambos e um falhará graciosamente
// ou usar uma abordagem que funcione para ambos como tz_data.initializeTimeZones();

Future<void> main() async { // main agora é async
  WidgetsFlutterBinding.ensureInitialized(); // Necessário se main for async
  debugPrint("APP_MAIN: Teste de print em main.dart"); // Teste de print inicial

  // Inicializar o banco de dados de fusos horários
  tz_data.initializeTimeZones();
  // Definir o local padrão (opcional, mas pode ser útil se você souber o fuso mais comum dos seus usuários)
  // Se a maioria dos seus usuários estiver no Brasil, você pode definir "America/Sao_Paulo" como padrão.
  // No entanto, nossa formatação será explícita para "America/Sao_Paulo", então isso é menos crítico aqui.
  // tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  
  runApp(const MyApp());
}

// Widget para decidir entre Login e ChatList
class AuthWrapper extends StatelessWidget {
  final Widget Function(BuildContext context, int? chatId) chatListScreenBuilder;
  final int? initialChatId;

  const AuthWrapper({super.key, required this.chatListScreenBuilder, this.initialChatId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoggedIn) {
          return chatListScreenBuilder(context, initialChatId);
        } else {
          // Se tentar acessar uma rota protegida sem estar logado, redireciona para login
          // Mantém a rota original nos argumentos para possível redirecionamento após login
          // No entanto, para simplificar, apenas vamos para LoginScreen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != '/login') {
                 // Navigator.of(context).pushReplacementNamed('/login');
                 // Não fazer push aqui para evitar loop se já estivermos indo para login.
            }
          });
          return LoginScreen();
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.indigo, // Usando indigo como base para o azul marinho
      accentColor: Colors.cyan[700], // Ciano mais escuro para accent
    ).copyWith(
      primary: Colors.indigo[900], // Azul Marinho específico para primário
      secondary: Colors.cyan[700], // Ciano mais escuro para secundário/accent
      // onPrimary: Colors.white, // Cor do texto em cima da cor primária (botões)
      // onSecondary: Colors.black, // Cor do texto em cima da cor secundária
    );

    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService(ApiService())),
        // Adicione outros providers aqui conforme necessário
      ],
      child: MaterialApp(
        title: 'JogAI',
        theme: ThemeData(
          colorScheme: colorScheme, // Usando o ColorScheme definido
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.primary, // Azul Marinho da AppBar
            foregroundColor: Colors.cyanAccent, // Manter Ciano claro para AppBar para contraste com Azul Marinho
            titleTextStyle: TextStyle(
              color: Colors.cyanAccent, // Manter Ciano claro para AppBar
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(
              color: Colors.cyanAccent, // Manter Ciano claro para AppBar
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, // Fundo Azul Marinho
              foregroundColor: Colors.white, // Texto Branco para contraste com Azul Marinho
              textStyle: const TextStyle(
                // fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.secondary, // Usará Colors.cyan[700] definido no ColorScheme
              textStyle: const TextStyle(
                // fontSize: 14,
                fontWeight: FontWeight.w600, // Levemente mais forte para links
              )
            ),
          ),
          // Outras customizações de tema aqui...
        ),
        initialRoute: '/', // Rota inicial será a tela de login ou chat list dependendo se está logado
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          Widget page;

          // Helper para construir ChatListScreen com ou sem chatId
          Widget chatListBuilder([int? chatId]) => ChatListScreen(initialChatId: chatId);

          if (uri.path == '/login') {
            page = LoginScreen();
          } 
          else if (uri.path == '/register') {
            page = RegistrationScreen();
          }
          else if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'chat') {
            final chatIdString = uri.pathSegments[1];
            final chatId = int.tryParse(chatIdString);
            page = AuthWrapper(chatListScreenBuilder: (_, id) => chatListBuilder(id), initialChatId: chatId);
          } 
          else if (uri.path == '/' || uri.path == '/dashboard') {
            page = AuthWrapper(chatListScreenBuilder: (_, id) => chatListBuilder(id)); // id será null
          }
          else {
            print("Rota desconhecida: ${settings.name}");
            page = AuthWrapper(chatListScreenBuilder: (_, id) => chatListBuilder(id)); // Fallback para dashboard
          }
          
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}
