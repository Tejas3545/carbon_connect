import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
      return response.user != null ? 'success' : 'failed';
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 'failed';
    }
  }

  Future<String> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final aal = _supabase.auth.mfa.getAuthenticatorAssuranceLevel();
      if (aal.nextLevel != aal.currentLevel) {
        state = const AsyncValue.data(null);
        return 'mfa_required';
      }

      state = const AsyncValue.data(null);
      return response.session != null ? 'success' : 'failed';
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 'failed';
    }
  }

  Future<bool> verifyMfa(String code) async {
    state = const AsyncValue.loading();
    try {
      final factors = await _supabase.auth.mfa.listFactors();
      if (factors.all.isEmpty) return false;
      
      final totpFactor = factors.all.firstWhere((f) => f.factorType == FactorType.totp);
      final challenge = await _supabase.auth.mfa.challenge(factorId: totpFactor.id);
      
      await _supabase.auth.mfa.verify(
        factorId: totpFactor.id,
        challengeId: challenge.id,
        code: code,
      );
      
      state = const AsyncValue.data(null);
      return true;
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
