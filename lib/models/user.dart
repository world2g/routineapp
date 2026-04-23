import 'package:supabase_flutter/supabase_flutter.dart';
 
class AppUser {
  final String id;       // Supabase UID
  final String username; // stored in user_metadata['username']
  final String email;
 
  const AppUser({
    required this.id,
    required this.username,
    required this.email,
  });
 
  factory AppUser.fromSupabase(User user) => AppUser(
        id:       user.id,
        username: user.userMetadata?['username'] as String? ??
                  user.email!.split('@').first,
        email:    user.email!,
      );
}