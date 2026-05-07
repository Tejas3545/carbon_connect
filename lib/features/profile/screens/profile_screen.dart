import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/profile_service.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    setState(() {
      _biometricEnabled = enabled == 'true';
    });
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  void _toggleBiometric(bool value) async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication is not available on this device.')),
        );
      }
      return;
    }

    if (value) {
      bool authenticated = false;
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometrics for secure app access',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }

      if (authenticated) {
        await _storage.write(key: 'biometric_enabled', value: 'true');
        setState(() => _biometricEnabled = true);
      }
    } else {
      await _storage.delete(key: 'biometric_enabled');
      setState(() => _biometricEnabled = false);
    }
  }

  void _showBankDetails() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final details = await ref.read(profileServiceProvider).fetchBankDetails(userId);

    if (!mounted) return;

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bank details found. Please complete KYC.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Account Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00D4AA))),
            const SizedBox(height: 24),
            _DetailItem(label: 'Bank Name', value: details.bankName),
            _DetailItem(label: 'Account Number', value: details.accountNumber),
            _DetailItem(label: 'IFSC Code', value: details.ifscCode),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF1E2D42),
            child: Icon(Icons.person,
                size: 50, color: const Color(0xFF00D4AA).withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          ref.watch(profileProvider).when(
            data: (profile) => Column(
              children: [
                Text(
                  profile?.fullName ?? 'User',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  profile?.email ?? user?.email ?? user?.phone ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => Text(
              user?.email ?? user?.phone ?? 'User',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: ref.watch(profileProvider).when(
              data: (profile) {
                final status = profile?.kycStatus ?? 'PENDING';
                final color = status == 'VERIFIED' ? const Color(0xFF22C55E) : Colors.amber;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'KYC $status',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Text('KYC PENDING', style: TextStyle(color: Colors.amber)),
            ),
          ),
          const SizedBox(height: 32),
          _SettingsTile(
            icon: Icons.account_balance,
            title: 'Bank Details',
            onTap: _showBankDetails,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: Color(0xFF00D4AA)),
            title: const Text('Biometric Login'),
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
            activeThumbColor: const Color(0xFF00D4AA),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active,
                color: Color(0xFF00D4AA)),
            title: const Text('Push Notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Notifications enabled' : 'Notifications disabled')),
              );
            },
            activeThumbColor: const Color(0xFF00D4AA),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => context.push('/help-support'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2D42),
              foregroundColor: const Color(0xFFEF4444),
            ),
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00D4AA)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
