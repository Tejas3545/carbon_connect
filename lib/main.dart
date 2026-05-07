import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

// IMPORTANT: Replace these placeholders with your actual Supabase project credentials.
const supabaseUrl = 'https://snusijlohkylxedlctoh.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNudXNpamxvaGt5bHhlZGxjdG9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMzg2MTEsImV4cCI6MjA5MzcxNDYxMX0.QJJMM9nGeJaRX27Hc5lssGttjvIQ-dOnoV_0C8mZp6I';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: CarbonConnectApp(),
    ),
  );
}
