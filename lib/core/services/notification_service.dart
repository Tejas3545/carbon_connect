import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return ref.read(notificationServiceProvider).streamNotifications(userId);
});

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((event) {
          return event.map((e) => NotificationModel.fromJson(e)).toList();
        });
  }

  Future<void> markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }
}
