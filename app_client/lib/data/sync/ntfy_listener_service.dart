import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/credentials_store.dart';
import '../../core/network/memoria_api_client.dart';
import '../local/app_database.dart';

class NtfyListenerService {
  final AppDatabase database;
  final CredentialsStore credentialsStore;
  final MemoriaApiClient apiClient;
  final FlutterLocalNotificationsPlugin? notificationsPlugin;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isConnected = false;

  NtfyListenerService({
    required this.database,
    required this.credentialsStore,
    required this.apiClient,
    this.notificationsPlugin,
  });

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    final creds = await credentialsStore.getCredentials();
    if (creds == null || !creds.isValid || creds.ntfyUrl == null || creds.ntfyTopic == null) {
      return;
    }

    final lastNtfyId = await database.getSyncMeta('last_ntfy_message_id');
    final rawUrl = creds.ntfyUrl!.replaceAll(RegExp(r'/+$'), '');
    final wsBase = rawUrl.replaceFirst(RegExp(r'^http'), 'ws');
    final uriStr = '$wsBase/${creds.ntfyTopic}/ws${lastNtfyId != null ? '?since=$lastNtfyId' : ''}';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(uriStr));
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) async {
          await _handleIncomingMessage(data.toString());
        },
        onError: (err) {
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (_) {
      _isConnected = false;
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _isConnected = false;
  }

  Future<void> _handleIncomingMessage(String rawJson) async {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final event = map['event'] as String?;
      if (event != 'message') return;

      final messageId = map['id'] as String?;
      final title = map['title'] as String? ?? 'Memoria Reminder';
      final message = map['message'] as String? ?? '';
      final clickUri = map['click'] as String?;

      if (messageId != null) {
        await database.setSyncMeta('last_ntfy_message_id', messageId);
      }

      await showNotification(
        id: messageId.hashCode,
        title: title,
        body: message,
        payload: clickUri,
      );
    } catch (_) {}
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (notificationsPlugin == null) return;

    const androidDetails = AndroidNotificationDetails(
      'memoria_reminders',
      'Memoria Reminders',
      channelDescription: 'Anti-fatigue morning and periodic scratchpad reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('MARK_DONE', 'Mark Done'),
        AndroidNotificationAction('SNOOZE_3H', 'Snooze 3h'),
      ],
    );

    const details = NotificationDetails(android: androidDetails);
    await notificationsPlugin!.show(id, title, body, details, payload: payload);
  }

  /// Handles action tap (e.g. from notification action button)
  Future<void> handleNotificationAction(String actionId, String? reminderId) async {
    if (reminderId == null || reminderId.isEmpty) return;

    final isMarkDone = actionId == 'MARK_DONE';
    final snoozedUntil = isMarkDone ? null : DateTime.now().add(const Duration(hours: 3));

    try {
      await apiClient.ackReminder(reminderId, snoozedUntil: snoozedUntil);
    } catch (_) {
      // Offline fallback: enqueue into outbox
      await database.enqueueOutboxOperation(
        entityId: reminderId,
        operation: 'ACK_REMINDER',
        payload: {
          'is_acknowledged': isMarkDone,
          if (snoozedUntil != null) 'snoozed_until': snoozedUntil.toIso8601String(),
        },
      );
    }
  }
}
