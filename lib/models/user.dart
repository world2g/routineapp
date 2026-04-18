import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String username;
  final String email;

  const AppUser({required this.id, required this.username, required this.email});

  factory AppUser.fromFirebase(User user) => AppUser(
        id:       user.uid,
        username: user.displayName ?? user.email!.split('@').first,
        email:    user.email!,
      );
}
