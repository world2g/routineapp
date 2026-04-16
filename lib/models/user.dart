class AppUser {
  final int id;
  final String username;
  final String email;
  final String token; // Django REST auth token

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        username: j['username'] as String,
        email: j['email'] as String,
        token: j['token'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'token': token,
      };
}