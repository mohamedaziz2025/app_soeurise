import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'profile_service.dart';

class NotificationRealtimeService {
  NotificationRealtimeService._();
  static final NotificationRealtimeService instance =
      NotificationRealtimeService._();

  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  io.Socket? _socket;
  bool _connected = false;

  Future<void> connect() async {
    final userId = ProfileService.instance.profile.value.id;
    if (userId.isEmpty) return;
    if (_connected) return;

    notifications.value = <AppNotification>[];

    final socket = io.io(
      ApiConfig.serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      _connected = true;
      socket.emit('join', {'userId': userId});
    });

    socket.on('notification', (data) {
      if (data is Map<String, dynamic>) {
        final notificationUserId = data['userId']?.toString();
        if (notificationUserId != null &&
            notificationUserId.isNotEmpty &&
            notificationUserId != userId) {
          return;
        }
        final notif = AppNotification.fromJson(data);
        final updated = [notif, ...notifications.value];
        notifications.value = updated;
      }
    });

    socket.onDisconnect((_) {
      _connected = false;
    });

    _socket = socket;
    socket.connect();
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
    notifications.value = <AppNotification>[];
  }

  Future<void> loadInitial({int limit = 30}) async {
    final res = await ApiClient.instance.get('/notifications?limit=$limit');
    if (res.success && res.data != null) {
      final list = res.data!['notifications'] as List? ?? [];
      notifications.value = list
          .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> markRead(String notificationId) async {
    await ApiClient.instance.post('/notifications/$notificationId/read', {});
    final updated = notifications.value.map((n) {
      if (n.id == notificationId) {
        return AppNotification(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    notifications.value = updated;
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.post('/notifications/read-all', {});
    final updated = notifications.value
        .map((n) => AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    notifications.value = updated;
  }

  int get unreadCount =>
      notifications.value.where((n) => !n.isRead).length;

  Future<bool> sendPrivateMessage({
    required String recipientUserId,
    required String message,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/notifications/private/$recipientUserId',
        {'message': message},
      );
      return res.success;
    } catch (_) {
      return false;
    }
  }
}
