import 'dart:convert';
import 'dart:typed_data';

import 'package:app_client/core/config/credentials_store.dart';
import 'package:app_client/core/network/memoria_api_client.dart';
import 'package:app_client/data/local/app_database.dart';
import 'package:app_client/data/sync/outbox_flusher.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Map<String, dynamic> deltaResponse = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final path = options.path;

    if (path.endsWith('/api/v1/capture')) {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 'ACCEPTED',
          'id': options.data['id'],
          'processing_status': 'QUEUED',
          'sync_version': 1050,
        }),
        202,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('/annotations')) {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 'CREATED',
          'id': options.data['id'] ?? 'mock_annot_id',
          'sync_version': 1051,
        }),
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.endsWith('/api/v1/sync/delta')) {
      return ResponseBody.fromString(
        jsonEncode(deltaResponse),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'status': 'ok'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeCredentialsStore extends CredentialsStore {
  DeviceCredentials? _creds;

  FakeCredentialsStore(this._creds);

  @override
  Future<DeviceCredentials?> getCredentials() async => _creds;

  @override
  Future<bool> hasCredentials() async => _creds != null;

  @override
  Future<void> saveCredentials(DeviceCredentials creds) async {
    _creds = creds;
  }
}

void main() {
  late AppDatabase db;
  late MockHttpClientAdapter mockAdapter;
  late MemoriaApiClient apiClient;
  late OutboxFlusher flusher;
  late FakeCredentialsStore fakeStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockAdapter = MockHttpClientAdapter();

    fakeStore = FakeCredentialsStore(
      const DeviceCredentials(
        apiBaseUrl: 'http://localhost:8000',
        cfAccessClientId: 'fake_client_id.access',
        cfAccessClientSecret: 'fake_secret',
        deviceId: '0192d04e-7b2a-7000-814f-000000000001',
        bearerKey: 'mem_live_mock_token',
      ),
    );

    final dio = Dio();
    dio.httpClientAdapter = mockAdapter;

    apiClient = MemoriaApiClient(dio: dio, credentialsStore: fakeStore);
    flusher = OutboxFlusher(database: db, apiClient: apiClient);
  });

  tearDown(() async {
    await db.close();
  });

  test('1. Creating a local capture inserts LocalCaptures and OutboxSyncQueue atomically', () async {
    const captureId = '0192d04e-7b2a-7000-814f-000000000002';
    final now = DateTime.now();

    await db.insertLocalCaptureAndEnqueueOutbox(
      capture: LocalCapturesCompanion(
        id: const drift.Value(captureId),
        captureType: const drift.Value('url_bookmark'),
        rawText: const drift.Value('Check out this article on memory engines'),
        title: const drift.Value('Memoria Specs'),
        sourceUrl: const drift.Value('https://example.com/spec'),
        userTagsJson: const drift.Value('["research", "specs"]'),
        capturedAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
      outboxPayload: {
        'id': captureId,
        'capture_type': 'url_bookmark',
        'raw_text': 'Check out this article on memory engines',
        'title': 'Memoria Specs',
        'source_url': 'https://example.com/spec',
        'user_tags': ['research', 'specs'],
      },
    );

    // Verify LocalCaptures row
    final capture = await (db.select(db.localCaptures)
          ..where((tbl) => tbl.id.equals(captureId)))
        .getSingle();
    expect(capture.id, equals(captureId));
    expect(capture.syncStatus, equals('PENDING_SYNC'));
    expect(capture.rawText, equals('Check out this article on memory engines'));

    // Verify OutboxSyncQueue row
    final outboxItems = await db.getPendingOutboxItems();
    expect(outboxItems.length, equals(1));
    expect(outboxItems.first.entityId, equals(captureId));
    expect(outboxItems.first.operation, equals('CREATE_CAPTURE'));
  });

  test('2. Appending marginalia leaves LocalCaptures.rawText 100% immutable and enqueues CREATE_ANNOTATION', () async {
    const captureId = '0192d04e-7b2a-7000-814f-000000000003';
    const annotationId = '0192d04e-7b2a-7000-814f-000000000004';
    final now = DateTime.now();

    // Insert original capture
    await db.insertLocalCaptureAndEnqueueOutbox(
      capture: LocalCapturesCompanion(
        id: const drift.Value(captureId),
        captureType: const drift.Value('quick_thought'),
        rawText: const drift.Value('Original immutable thought note'),
        capturedAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
      outboxPayload: {
        'id': captureId,
        'capture_type': 'quick_thought',
        'raw_text': 'Original immutable thought note',
      },
    );

    // Clear initial outbox for test clarity
    final initialOutbox = await db.getPendingOutboxItems();
    for (final item in initialOutbox) {
      await db.deleteOutboxItem(item.seqId);
    }

    // Insert append-only marginalia
    await db.insertLocalAnnotationAndEnqueueOutbox(
      annotation: LocalCaptureAnnotationsCompanion(
        id: const drift.Value(annotationId),
        captureId: const drift.Value(captureId),
        content: const drift.Value('Follow-up marginalia comment added later'),
        createdAt: drift.Value(now),
      ),
    );

    // Verify parent capture rawText remains completely untouched
    final parent = await (db.select(db.localCaptures)
          ..where((tbl) => tbl.id.equals(captureId)))
        .getSingle();
    expect(parent.rawText, equals('Original immutable thought note'));

    // Verify annotation exists in LocalCaptureAnnotations
    final annots = await (db.select(db.localCaptureAnnotations)
          ..where((tbl) => tbl.captureId.equals(captureId)))
        .get();
    expect(annots.length, equals(1));
    expect(annots.first.content, equals('Follow-up marginalia comment added later'));

    // Verify outbox queued CREATE_ANNOTATION
    final outboxItems = await db.getPendingOutboxItems();
    expect(outboxItems.length, equals(1));
    expect(outboxItems.first.entityId, equals(annotationId));
    expect(outboxItems.first.operation, equals('CREATE_ANNOTATION'));
  });

  test('3. OutboxFlusher.flush() sends operations, marks SYNCED, and applies delta sync', () async {
    const captureId = '0192d04e-7b2a-7000-814f-000000000005';
    const sparkId = '0192d04e-7b2a-7000-814f-000000000006';
    final now = DateTime.now();

    await db.insertLocalCaptureAndEnqueueOutbox(
      capture: LocalCapturesCompanion(
        id: const drift.Value(captureId),
        captureType: const drift.Value('video_reel'),
        rawText: const drift.Value('DNS architecture reel'),
        capturedAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
      outboxPayload: {
        'id': captureId,
        'capture_type': 'video_reel',
        'raw_text': 'DNS architecture reel',
      },
    );

    // Prepare mock delta response
    mockAdapter.deltaResponse = {
      'current_max_sync_version': 1055,
      'has_more': false,
      'captures': [
        {
          'id': captureId,
          'capture_type': 'video_reel',
          'processing_status': 'SPARK_EVALUATED',
          'raw_text': 'DNS architecture reel',
          'transcript_text': 'In this video we configure Unbound on port 5335...',
          'sync_version': 1054,
        }
      ],
      'reading_sessions': [],
      'ai_sparks': [
        {
          'id': sparkId,
          'title': 'Zero-Trust DNS & Homelab Synergy',
          'spark_markdown': '# Synthesized Architecture\n\nCombine Unbound with CF Tunnel.',
          'spark_rationale': 'Connects DNS configuration with homelab notes.',
          'source_capture_ids': [captureId],
          'sync_version': 1055,
        }
      ],
    };

    // Run flush
    final result = await flusher.flush();
    expect(result.processedCount, equals(1));
    expect(result.successCount, equals(1));
    expect(result.errorCount, equals(0));

    // Verify outbox queue is now empty
    final remainingOutbox = await db.getPendingOutboxItems();
    expect(remainingOutbox.isEmpty, isTrue);

    // Verify capture updated to SYNCED with transcript from delta
    final syncedCapture = await (db.select(db.localCaptures)
          ..where((tbl) => tbl.id.equals(captureId)))
        .getSingle();
    expect(syncedCapture.syncStatus, equals('SYNCED'));
    expect(syncedCapture.transcriptText, contains('Unbound on port 5335'));

    // Verify spark was inserted by applyServerDeltaSync
    final sparks = await (db.select(db.localAiSparks)
          ..where((tbl) => tbl.id.equals(sparkId)))
        .get();
    expect(sparks.length, equals(1));
    expect(sparks.first.title, equals('Zero-Trust DNS & Homelab Synergy'));

    // Verify sync cursor updated
    final lastCursor = await db.getLastSyncVersion();
    expect(lastCursor, equals(1055));
  });
}
