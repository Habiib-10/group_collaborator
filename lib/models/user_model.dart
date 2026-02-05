//halkaa soo dhig koodhkaaga Dart ee faylka lib/models/user_model.dart

class User {
  final int? id; // Waxaan ka dhignay int maadaama database-ka int u isticmaalo
  final String name;
  final String email;
  final String role; // Admin ama User

  User({this.id, required this.name, required this.email, required this.role});

  // 1. Ka soo beddel JSON una beddel Model (Marka xogta laga soo aqrinayo API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
    );
  }

  // 2. Ka beddel Model una beddel JSON (Marka xogta loo dirayo API)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}
