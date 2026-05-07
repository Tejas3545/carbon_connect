import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash screen for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      if (mounted) context.go('/login');
      return;
    }

    // Check if Biometric Login is enabled
    final biometricEnabled = await _storage.read(key: 'biometric_enabled');
    if (biometricEnabled == 'true') {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access Carbon Connect',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (!authenticated) {
          // If biometric fails/cancelled, we stay on splash or go back to login
          // Usually we stay on splash to allow retrying
          return;
        }
      } catch (e) {
        debugPrint('Biometric Auth Error: $e');
        // Fallback to password or stay on splash
      }
    }

    final userId = session.user.id;
    final supabase = Supabase.instance.client;

    try {
      // 1. Attempt to fetch profile
      final response = await supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) {
        // 2. Self-healing: Create missing profile row
        await supabase.from('users').insert({
          'id': userId,
          'phone': session.user.phone,
          'kyc_status': 'PENDING',
        });
        if (mounted) context.go('/role-select');
      } else {
        if (mounted) {
          if (response['role'] != null) {
            context.go('/home');
          } else {
            context.go('/role-select');
          }
        }
      }
    } catch (e) {
      debugPrint('Auth Check Error: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco,
              size: 80,
              color: Color(0xFF00D4AA),
            ),
            const SizedBox(height: 24),
            const Text(
              'CarbonConnect',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4AA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
