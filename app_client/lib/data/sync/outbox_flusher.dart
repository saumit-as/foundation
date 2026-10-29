import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/network/memoria_api_client.dart';
import '../local/app_database.dart';

class FlushResult {
  final int processedCount;
  final int successCount;
  final int errorCount;
  final String? lastError;

  const FlushResult({
    required this.processedCount,
    required this.successCount,
    required this.errorCount,
    this.lastError,
  });
}

class OutboxFlusher {
  final AppDatabase database;
  final MemoriaApiClient apiClient;
  final Connectivity? connectivity;

  bool _isFlushing = false;

  OutboxFlusher({
    required this.database,
    required this.apiClient,
    this.connectivity,
  });

  bool get isFlushing => _isFlushing;

  /// Flushes pending outbox operations in FIFO order
  Future<FlushResult> flush({int limit = 50}) async {
    if (_isFlushing) {
      return const FlushResult(processedCount: 0, successCount: 0, errorCount: 0);
    }
    _isFlushing = true;

    int successCount = 0;
    int errorCount = 0;
    String? lastError;

    try {
      final pendingItems = await database.getPendingOutboxItems(limit: limit);
      if (pendingItems.isEmpty) {
        return const FlushResult(processedCount: 0, successCount: 0, errorCount: 0);
      }

      for (final item in pendingItems) {
        try {
          await _processItem(item);
          await database.deleteOutboxItem(item.seqId);
          successCount++;
        } catch (err) {
          errorCount++;
          lastError = err.toString();
          final nextRetryCount = item.retryCount + 1;
          // Exponential backoff: 2^retry seconds (capped at 900s = 15m)
          final delaySeconds = min(pow(2, nextRetryCount).toInt(), 900);
          final nextRetryAt = DateTime.now().add(Duration(seconds: delaySeconds));

          await database.updateOutboxItemRetry(
            item.seqId,
            nextRetryCount,
            nextRetryAt,
            lastError,
          );
        }
      }

      // If at least one item was flushed, trigger delta sync
      if (successCount > 0) {
        try {
          await syncDelta();
        } catch (_) {}
      }

      return FlushResult(
        processedCount: pendingItems.length,
        successCount: successCount,
        errorCount: errorCount,
        lastError: lastError,
      );
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _processItem(OutboxSyncQueueData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

    switch (item.operation) {
      case 'CREATE_CAPTURE':
        final resp = await apiClient.sendCapture(payload);
        final respData = resp.data is Map<String, dynamic>
            ? resp.data as Map<String, dynamic>
            : jsonDecode(resp.data.toString()) as Map<String, dynamic>;
        final syncVer = respData['sync_version'] as int? ?? 1;
        await database.markCaptureSynced(item.entityId, syncVer);
        break;

      case 'UPLOAD_MEDIA':
        final filePath = item.localFilePath ?? payload['local_file_path'] as String;
        final mediaKind = payload['media_kind'] as String? ?? 'image';
        await apiClient.uploadMedia(
          captureId: item.entityId,
          filePath: filePath,
          mediaKind: mediaKind,
          assetId: payload['asset_id'] as String?,
          softTokenBudget: payload['soft_token_budget'] as int?,
          sha256Checksum: payload['sha256_checksum'] as String?,
        );
        break;

      case 'CREATE_ANNOTATION':
        final captureId = payload['capture_id'] as String;
        final content = payload['content'] as String;
        final annotationId = payload['id'] as String?;
        await apiClient.addAnnotation(
          captureId: captureId,
          content: content,
          annotationId: annotationId,
        );
        break;

      case 'ACK_REMINDER':
        final reminderId = item.entityId;
        DateTime? snoozedUntil;
        if (payload['snoozed_until'] != null) {
          snoozedUntil = DateTime.tryParse(payload['snoozed_until'].toString());
        }
        await apiClient.ackReminder(reminderId, snoozedUntil: snoozedUntil);
        break;

      case 'TRIAGE_DECISION':
        await apiClient.sendTriageDecision(
          entityId: item.entityId,
          decision: payload['decision'] as String,
          targetTable: payload['target_table'] as String? ?? 'captures',
        );
        break;

      case 'START_READING_SESSION':
        await apiClient.startReadingSession(
          sessionId: item.entityId,
          title: payload['source_title'] as String,
          author: payload['author'] as String?,
          defaultTags: (payload['default_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
        );
        break;

      default:
        throw UnimplementedError('Unknown outbox operation: ${item.operation}');
    }
  }

  /// Fetches delta updates from server and applies them locally
  Future<void> syncDelta({int limit = 200}) async {
    final lastVersion = await database.getLastSyncVersion();
    final delta = await apiClient.getSyncDelta(lastVersion, limit: limit);
    await database.applyServerDeltaSync(delta);
  }
}
