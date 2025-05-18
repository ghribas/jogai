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

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart'; // Para debugPrint

// Função interna para lógica de formatação e conversão
String _formatInternal(DateTime dateTime, String formatPattern, String functionNameForLog) {
  try {
    // Log inicial para ver o estado do DateTime recebido
    // final initialType = dateTime.isUtc ? "UTC" : "Local";
    // debugPrint("$functionNameForLog - Received DateTime: $dateTime (Type: $initialType)");

    DateTime presumedUtcDateTime;
    if (dateTime.isUtc) {
      // debugPrint("$functionNameForLog - Input dateTime is already UTC: $dateTime");
      presumedUtcDateTime = dateTime;
    } else {
      // Se o dateTime não é UTC (ou seja, é local), assumimos que seus componentes
      // (ano, mês, dia, hora, minuto, etc.) representam o tempo em UTC,
      // mas foi parseado como local porque a string da API não tinha indicador de fuso.
      // debugPrint("$functionNameForLog - Input dateTime is local: $dateTime. Reinterpreting its components as UTC values.");
      presumedUtcDateTime = DateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );
    }
    // debugPrint("$functionNameForLog - Presumed UTC DateTime for conversion: $presumedUtcDateTime, isUtc: ${presumedUtcDateTime.isUtc}");

    final brasiliaLocation = tz.getLocation('America/Sao_Paulo');
    // Converte o presumedUtcDateTime para o fuso horário de Brasília
    final zonedTime = tz.TZDateTime.from(presumedUtcDateTime, brasiliaLocation);
    // debugPrint("$functionNameForLog - ZonedTime (Brasilia): $zonedTime");

    return DateFormat(formatPattern).format(zonedTime);
  } catch (e, s) {
    // debugPrint("$functionNameForLog - Erro ao formatar data para Brasília: $e. StackTrace: $s");
    // Fallback: tenta formatar como local e adiciona um aviso
    try {
      return DateFormat(formatPattern).format(dateTime.toLocal()) + " (Local Fallback)";
    } catch (e2) {
      // Fallback final: formata como está e adiciona um aviso
      return DateFormat(formatPattern).format(dateTime) + " (Original Fallback)";
    }
  }
}

// Função para formatar DateTime completo para o fuso horário de Brasília (America/Sao_Paulo)
String formatDateTimeToBrasilia(DateTime dateTime) {
  return _formatInternal(dateTime, 'dd/MM/yy HH:mm', 'formatDateTimeToBrasilia');
}

// Função para formatar apenas a hora para o fuso horário de Brasília
String formatTimeBrasilia(DateTime dateTime) {
  return _formatInternal(dateTime, 'HH:mm', 'formatTimeBrasilia');
}

// Os debugPrints originais do usuário que foram substituídos pela lógica acima:
// String formatDateTimeToBrasilia(DateTime dateTime) {
//   try {
//     DateTime utcDateTime = dateTime; 
//     if (!dateTime.isUtc) {
//       debugPrint("formatDateTimeToBrasilia - Converting local to UTC. Original: $dateTime");
//       utcDateTime = dateTime.toUtc(); 
//     }
//     debugPrint("formatDateTimeToBrasilia - Input (forced UTC): $utcDateTime, isUtc: ${utcDateTime.isUtc}");
    
//     final brasiliaLocation = tz.getLocation('America/Sao_Paulo');
//     final zonedTime = tz.TZDateTime.from(utcDateTime, brasiliaLocation);
//     debugPrint("formatDateTimeToBrasilia - ZonedTime (Brasilia): $zonedTime");
    
//     return DateFormat('dd/MM/yy HH:mm').format(zonedTime);
//   } catch (e) {
//     debugPrint("Erro ao formatar data para Brasília: $e");
//     try {
//       return DateFormat('dd/MM/yy HH:mm').format(dateTime.toLocal()) + " (Local Fallback)";
//     } catch (e2) {
//         return DateFormat('dd/MM/yy HH:mm').format(dateTime) + " (Original Fallback)";
//     }
//   }
// }

// String formatTimeBrasilia(DateTime dateTime) {
//   try {
//     DateTime utcDateTime = dateTime;
//     if (!dateTime.isUtc) {
//       debugPrint("formatTimeBrasilia - Converting local to UTC. Original: $dateTime");
//       utcDateTime = dateTime.toUtc();
//     }
//     debugPrint("formatTimeBrasilia - Input (forced UTC): $utcDateTime, isUtc: ${utcDateTime.isUtc}");
    
//     final brasiliaLocation = tz.getLocation('America/Sao_Paulo');
//     final zonedTime = tz.TZDateTime.from(utcDateTime, brasiliaLocation);
//     debugPrint("formatTimeBrasilia - ZonedTime (Brasilia): $zonedTime");
    
//     return DateFormat('HH:mm').format(zonedTime);
//   } catch (e) {
//     debugPrint("Erro ao formatar hora para Brasília: $e");
//     try {
//         return DateFormat('HH:mm').format(dateTime.toLocal()) + " (Local Fallback)";
//     } catch (e2) {
//         return DateFormat('HH:mm').format(dateTime) + " (Original Fallback)";
//     }
//   }
// } 