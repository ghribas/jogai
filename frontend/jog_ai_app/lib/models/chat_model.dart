import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:jog_ai_app/utils/date_utils.dart';

class Chat {
  final int id;
  final int userId;
  String title;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  String status;
  String? observations;
  String? color;
  // List<Message> messages; // Pode ser carregado separadamente ou incluído aqui

  // Campos de pré-configuração
  final String? universo;
  final String? universoOutro;
  final String? genero;
  final String? generoOutro;
  final String? nomeProtagonista;
  final String? nomeUniversoJogo;
  final String? nomeAntagonista;
  final String? inspiracao;
  final int? age;

  Chat({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.status,
    this.observations,
    this.color,
    // Campos de pré-configuração
    this.universo,
    this.universoOutro,
    this.genero,
    this.generoOutro,
    this.nomeProtagonista,
    this.nomeUniversoJogo,
    this.nomeAntagonista,
    this.inspiracao,
    this.age,
    // required this.messages,
  });

  String get formattedCreatedAt => formatDateTimeToBrasilia(createdAt);
  String get formattedLastAccessedAt => formatDateTimeToBrasilia(lastAccessedAt);


  factory Chat.fromJson(Map<String, dynamic> json) {
    // Helper para parsear datas, tratando possíveis nulos ou formatos incorretos
    DateTime parseDate(String? dateString) {
      if (dateString == null) return DateTime.now(); // Ou lançar erro, ou default
      return DateTime.tryParse(dateString) ?? DateTime.now();
    }

    Map<String, dynamic> config = json['config'] ?? {};

    return Chat(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0, 
      title: json['title'] as String? ?? 'Chat Desconhecido',
      createdAt: parseDate(json['created_at'] as String?),
      lastAccessedAt: parseDate(json['last_accessed_at'] as String?),
      status: json['status'] as String? ?? 'new',
      observations: json['observations'] as String?,
      color: json['color'] as String?,
      // Campos de pré-configuração
      universo: config['universo'] as String?,
      universoOutro: config['universo_outro'] as String?,
      genero: config['genero'] as String?,
      generoOutro: config['genero_outro'] as String?,
      nomeProtagonista: config['nome_protagonista'] as String?,
      nomeUniversoJogo: config['nome_universo_jogo'] as String?,
      nomeAntagonista: config['nome_antagonista'] as String?,
      inspiracao: config['inspiracao'] as String?,
      age: config['age'] as int?,
      // messages: (json['messages'] as List<dynamic>? ?? [])
      //     .map((msgJson) => Message.fromJson(msgJson as Map<String, dynamic>))
      //     .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'last_accessed_at': lastAccessedAt.toIso8601String(),
    'status': status,
    'observations': observations,
    'color': color,
    // Campos de pré-configuração
    'config': {
      'universo': universo,
      'universo_outro': universoOutro,
      'genero': genero,
      'genero_outro': generoOutro,
      'nome_protagonista': nomeProtagonista,
      'nome_universo_jogo': nomeUniversoJogo,
      'nome_antagonista': nomeAntagonista,
      'inspiracao': inspiracao,
      'age': age,
    },
    // 'messages': messages.map((msg) => msg.toJson()).toList(),
  };

  Chat copyWith({
    int? id,
    int? userId,
    String? title,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    String? status,
    ValueGetter<String?>? observations,
    ValueGetter<String?>? color,
    ValueGetter<String?>? universo,
    ValueGetter<String?>? universoOutro,
    ValueGetter<String?>? genero,
    ValueGetter<String?>? generoOutro,
    ValueGetter<String?>? nomeProtagonista,
    ValueGetter<String?>? nomeUniversoJogo,
    ValueGetter<String?>? nomeAntagonista,
    ValueGetter<String?>? inspiracao,
    ValueGetter<int?>? age,
  }) {
    return Chat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      status: status ?? this.status,
      observations: observations != null ? observations() : this.observations,
      color: color != null ? color() : this.color,
      universo: universo != null ? universo() : this.universo,
      universoOutro: universoOutro != null ? universoOutro() : this.universoOutro,
      genero: genero != null ? genero() : this.genero,
      generoOutro: generoOutro != null ? generoOutro() : this.generoOutro,
      nomeProtagonista: nomeProtagonista != null ? nomeProtagonista() : this.nomeProtagonista,
      nomeUniversoJogo: nomeUniversoJogo != null ? nomeUniversoJogo() : this.nomeUniversoJogo,
      nomeAntagonista: nomeAntagonista != null ? nomeAntagonista() : this.nomeAntagonista,
      inspiracao: inspiracao != null ? inspiracao() : this.inspiracao,
      age: age != null ? age() : this.age,
    );
  }

  // Getters para facilitar o acesso aos campos de configuração (já devem existir da etapa anterior)
  String? get getUniverso => universo;
} 