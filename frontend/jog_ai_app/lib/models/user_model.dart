class User {
  final int id;
  final String username;
  // Não armazenamos a senha no frontend após o login
  // Podemos adicionar um token JWT aqui se implementarmos

  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'], // Backend retorna 'user_id'
      username: json['username'], // Supondo que o backend possa retornar username no futuro
    );
  }
} 