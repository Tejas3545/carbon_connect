import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
      return response.user != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      state = const AsyncValue.data(null);
      return response.session != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> setRole(String role) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    state = const AsyncValue.loading();
    try {
      // Upsert user role into our custom users table
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'role': role,
        'kyc_status': 'PENDING',
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
