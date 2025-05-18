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

// Converte uma string hexadecimal (ex: "#RRGGBB" ou "RRGGBB") para um objeto Color.
Color hexToColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return Colors.blueGrey; // Cor padrão se nula, vazia ou inválida
  }
  final buffer = StringBuffer();
  if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
  buffer.write(hexColor.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.blueGrey; // Cor padrão em caso de erro de parsing
  }
}

// Converte um objeto Color para uma string hexadecimal "#RRGGBB".
String colorToHex(Color color, {bool leadingHashSign = true}) {
  return '${leadingHashSign ? '#' : ''}'
      '${color.alpha.toRadixString(16).padLeft(2, '0')}'
      '${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}

// Converte um objeto Color para uma string hexadecimal "#RRGGBB", ignorando o alfa.
String colorToHexRGB(Color color, {bool leadingHashSign = true}) {
  return '${leadingHashSign ? '#' : ''}'
      '${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
} 