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

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return "ApiException (Status $statusCode): $message";
    }
    return "ApiException: $message";
  }
} 