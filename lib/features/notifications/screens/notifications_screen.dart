import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? const Center(
                child: Text('No new notifications',
                    style: TextStyle(color: Color(0xFF94A3B8))),
              )
            : ListView.builder(
                itemCount: notifications.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (notification.isRead ? Colors.grey : const Color(0xFF4184F3)).withValues(alpha: 0.1),
                        child: Icon(
                          notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: notification.isRead ? Colors.grey : const Color(0xFF4184F3),
                        ),
                      ),
                      title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(notification.createdAt),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => ref.read(notificationServiceProvider).markAsRead(notification.id),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
