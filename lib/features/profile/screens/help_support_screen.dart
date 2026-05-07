import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      debugPrint('Launch Error: $e');
    }
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@carbonconnect.app',
      query: 'subject=Support Request&body=Hello Carbon Connect Team,',
    );
    await launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.support_agent, size: 80, color: Color(0xFF10B981)),
          const SizedBox(height: 24),
          const Text(
            'Support Center',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our team is available 24/7 to assist you',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 32),
          _SupportTile(
            icon: Icons.chat_bubble_outline,
            title: 'Live 24x7 Chat',
            subtitle: 'Get instant help from our team',
            onTap: () => _launchUrl(
                "https://wa.me/919725865080?text=I need live support"),
          ),
          _SupportTile(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@carbonconnect.app',
            onTap: _launchEmail,
          ),
          _SupportTile(
            icon: Icons.help_outline,
            title: 'FAQs & Guide',
            subtitle: 'Read our documentation',
            onTap: () => _launchUrl('https://carboncreditbyharsh.lovable.app/'),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Version 1.0.1 (Production)',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF10B981)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8))),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: onTap,
      ),
    );
  }
}
