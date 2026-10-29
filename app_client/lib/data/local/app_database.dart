import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 1. Local Captures Table (Mirrors server captures + offline sync state)
class LocalCaptures extends Table {
  TextColumn get id => text()(); // Client-generated UUIDv7
  TextColumn get readingSessionId => text().nullable()();
  TextColumn get captureType => text()();
  TextColumn get processingStatus =>
      text().withDefault(const Constant('LOCAL_ONLY'))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('PENDING_SYNC'))();

  TextColumn get title => text().nullable()();
  TextColumn get rawText => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get pageRange => text().nullable()();
  TextColumn get userTagsJson => text().withDefault(const Constant('[]'))();

  TextColumn get extractedMarkdown => text().nullable()();
  TextColumn get ocrText => text().nullable()();
  TextColumn get transcriptText => text().nullable()();
  TextColumn get voiceDistillationJson => text().nullable()();
  TextColumn get autoTagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get mediaAssetsJson => text().withDefault(const Constant('[]'))();
  TextColumn get localMediaPath => text().nullable()();

  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isTriageReviewed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 1b. Append-Only Marginalia & Follow-Up Thread Notes on Local Captures
class LocalCaptureAnnotations extends Table {
  TextColumn get id => text()(); // Client-generated UUIDv7
  TextColumn get captureId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 1c. Sticky Reading & Book Scanning Sessions
class LocalReadingSessions extends Table {
  TextColumn get id => text()(); // Client-generated UUIDv7
  TextColumn get sourceTitle => text()();
  TextColumn get author => text().nullable()();
  TextColumn get defaultTagsJson =>
      text().withDefault(const Constant('["book"]'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 2. Transactional Offline Outbox Queue (FIFO)
class OutboxSyncQueue extends Table {
  IntColumn get seqId => integer().autoIncrement()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  TextColumn get localFilePath => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 3. Cached AI Spark Documents
class LocalAiSparks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get sparkMarkdown => text()();
  TextColumn get sparkRationale => text().nullable()();
  TextColumn get relatedProject => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get sourceCaptureIdsJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 4. Sync State Meta KV Store
class SyncStateMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  LocalCaptures,
  LocalCaptureAnnotations,
  LocalReadingSessions,
  OutboxSyncQueue,
  LocalAiSparks,
  SyncStateMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// Single-transaction atomic local capture insertion + outbox queueing (<5ms)
  Future<void> insertLocalCaptureAndEnqueueOutbox({
    required LocalCapturesCompanion capture,
    required Map<String, dynamic> outboxPayload,
    String? localFilePath,
  }) async {
    await transaction(() async {
      await into(localCaptures).insertOnConflictUpdate(capture);
      await into(outboxSyncQueue).insert(
        OutboxSyncQueueCompanion.insert(
          entityId: capture.id.value,
          operation: 'CREATE_CAPTURE',
          payloadJson: jsonEncode(outboxPayload),
          localFilePath: Value(localFilePath),
        ),
      );
    });
  }

  /// Single-transaction atomic append-only marginalia insertion + outbox queueing
  Future<void> insertLocalAnnotationAndEnqueueOutbox({
    required LocalCaptureAnnotationsCompanion annotation,
  }) async {
    await transaction(() async {
      await into(localCaptureAnnotations).insertOnConflictUpdate(annotation);
      await into(outboxSyncQueue).insert(
        OutboxSyncQueueCompanion.insert(
          entityId: annotation.id.value,
          operation: 'CREATE_ANNOTATION',
          payloadJson: jsonEncode({
            'id': annotation.id.value,
            'capture_id': annotation.captureId.value,
            'content': annotation.content.value,
          }),
        ),
      );
    });
  }

  /// Enqueues generic outbox operation (e.g., ACK_REMINDER, TRIAGE_DECISION)
  Future<int> enqueueOutboxOperation({
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    String? localFilePath,
  }) async {
    return await into(outboxSyncQueue).insert(
      OutboxSyncQueueCompanion.insert(
        entityId: entityId,
        operation: operation,
        payloadJson: jsonEncode(payload),
        localFilePath: Value(localFilePath),
      ),
    );
  }

  /// Retrieves due outbox items ordered by seqId ASC
  Future<List<OutboxSyncQueueData>> getPendingOutboxItems({int limit = 50}) async {
    final now = DateTime.now();
    return (select(outboxSyncQueue)
          ..where((tbl) =>
              tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(now))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.seqId)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteOutboxItem(int seqId) async {
    await (delete(outboxSyncQueue)..where((tbl) => tbl.seqId.equals(seqId))).go();
  }

  Future<void> updateOutboxItemRetry(
    int seqId,
    int retryCount,
    DateTime nextRetryAt,
    String? error,
  ) async {
    await (update(outboxSyncQueue)..where((tbl) => tbl.seqId.equals(seqId))).write(
      OutboxSyncQueueCompanion(
        retryCount: Value(retryCount),
        nextRetryAt: Value(nextRetryAt),
        lastError: Value(error),
      ),
    );
  }

  Future<void> markCaptureSynced(String captureId, int syncVersion) async {
    await (update(localCaptures)..where((tbl) => tbl.id.equals(captureId))).write(
      LocalCapturesCompanion(
        syncStatus: const Value('SYNCED'),
        syncVersion: Value(syncVersion),
      ),
    );
  }

  Future<int> getLastSyncVersion() async {
    final row = await (select(syncStateMeta)
          ..where((tbl) => tbl.key.equals('last_server_sync_version')))
        .getSingleOrNull();
    if (row == null) return 0;
    return int.tryParse(row.value) ?? 0;
  }

  Future<void> setSyncMeta(String key, String value) async {
    await into(syncStateMeta).insertOnConflictUpdate(
      SyncStateMetaCompanion.insert(key: key, value: value),
    );
  }

  Future<String?> getSyncMeta(String key) async {
    final row = await (select(syncStateMeta)
          ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Applies delta payload received from GET /api/v1/sync/delta
  Future<void> applyServerDeltaSync(Map<String, dynamic> deltaPayload) async {
    await transaction(() async {
      // 1. Upsert captures
      final capturesList = deltaPayload['captures'] as List<dynamic>? ?? [];
      for (final raw in capturesList) {
        final c = raw as Map<String, dynamic>;
        final id = c['id'] as String;

        final existing = await (select(localCaptures)
              ..where((tbl) => tbl.id.equals(id)))
            .getSingleOrNull();

        final userTags = c['user_tags'] != null
            ? jsonEncode(c['user_tags'])
            : (existing?.userTagsJson ?? '[]');
        final autoTags = c['auto_tags'] != null
            ? jsonEncode(c['auto_tags'])
            : (existing?.autoTagsJson ?? '[]');
        final mediaAssets = c['media_assets'] != null
            ? jsonEncode(c['media_assets'])
            : (existing?.mediaAssetsJson ?? '[]');
        final voiceDist = c['voice_distillation'] != null
            ? jsonEncode(c['voice_distillation'])
            : existing?.voiceDistillationJson;

        await into(localCaptures).insertOnConflictUpdate(
          LocalCapturesCompanion(
            id: Value(id),
            readingSessionId: Value(c['reading_session_id'] as String?),
            captureType: Value(c['capture_type'] as String? ?? 'url_bookmark'),
            processingStatus: Value(c['processing_status'] as String? ?? 'QUEUED'),
            syncStatus: const Value('SYNCED'),
            title: Value(c['title'] as String? ?? existing?.title),
            // User raw text is immutable
            rawText: Value(existing?.rawText ?? c['raw_text'] as String?),
            sourceUrl: Value(c['source_url'] as String? ?? existing?.sourceUrl),
            pageRange: Value(c['page_range'] as String? ?? existing?.pageRange),
            userTagsJson: Value(userTags),
            extractedMarkdown: Value(c['extracted_markdown'] as String? ?? existing?.extractedMarkdown),
            ocrText: Value(c['ocr_text'] as String? ?? existing?.ocrText),
            transcriptText: Value(c['transcript_text'] as String? ?? existing?.transcriptText),
            voiceDistillationJson: Value(voiceDist),
            autoTagsJson: Value(autoTags),
            mediaAssetsJson: Value(mediaAssets),
            capturedAt: Value(DateTime.tryParse(c['captured_at'] as String? ?? '') ?? DateTime.now()),
            updatedAt: Value(DateTime.tryParse(c['updated_at'] as String? ?? '') ?? DateTime.now()),
            isTriageReviewed: Value(existing?.isTriageReviewed ?? false),
            isArchived: Value(c['is_archived'] as bool? ?? false),
            isDeleted: Value(c['is_deleted'] as bool? ?? false),
            syncVersion: Value(c['sync_version'] as int? ?? 0),
          ),
        );

        // Sub-annotations inside capture
        final annotationsList = c['annotations'] as List<dynamic>? ?? [];
        for (final aRaw in annotationsList) {
          final a = aRaw as Map<String, dynamic>;
          await into(localCaptureAnnotations).insertOnConflictUpdate(
            LocalCaptureAnnotationsCompanion(
              id: Value(a['id'] as String),
              captureId: Value(id),
              content: Value(a['content'] as String),
              createdAt: Value(DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime.now()),
              syncVersion: Value(a['sync_version'] as int? ?? 0),
            ),
          );
        }
      }

      // 2. Reading sessions
      final readingSessionsList = deltaPayload['reading_sessions'] as List<dynamic>? ?? [];
      for (final rsRaw in readingSessionsList) {
        final rs = rsRaw as Map<String, dynamic>;
        await into(localReadingSessions).insertOnConflictUpdate(
          LocalReadingSessionsCompanion(
            id: Value(rs['id'] as String),
            sourceTitle: Value(rs['source_title'] as String),
            author: Value(rs['author'] as String?),
            defaultTagsJson: Value(rs['default_tags'] != null ? jsonEncode(rs['default_tags']) : '["book"]'),
            isActive: Value(rs['is_active'] as bool? ?? true),
            createdAt: Value(DateTime.tryParse(rs['created_at'] as String? ?? '') ?? DateTime.now()),
            syncVersion: Value(rs['sync_version'] as int? ?? 0),
          ),
        );
      }

      // 3. AI Sparks
      final sparksList = deltaPayload['ai_sparks'] as List<dynamic>? ?? [];
      for (final spRaw in sparksList) {
        final sp = spRaw as Map<String, dynamic>;
        final sparkId = sp['id'] as String;
        final existingSpark = await (select(localAiSparks)
              ..where((tbl) => tbl.id.equals(sparkId)))
            .getSingleOrNull();

        await into(localAiSparks).insertOnConflictUpdate(
          LocalAiSparksCompanion(
            id: Value(sparkId),
            title: Value(sp['title'] as String),
            sparkMarkdown: Value(sp['spark_markdown'] as String),
            sparkRationale: Value(sp['spark_rationale'] as String?),
            relatedProject: Value(sp['related_project'] as String?),
            tagsJson: Value(sp['tags'] != null ? jsonEncode(sp['tags']) : '[]'),
            sourceCaptureIdsJson: Value(
              sp['source_capture_ids'] != null
                  ? jsonEncode(sp['source_capture_ids'])
                  : '[]',
            ),
            isRead: Value(existingSpark?.isRead ?? false),
            isPinned: Value(sp['is_pinned'] as bool? ?? false),
            createdAt: Value(DateTime.tryParse(sp['created_at'] as String? ?? '') ?? DateTime.now()),
            syncVersion: Value(sp['sync_version'] as int? ?? 0),
          ),
        );
      }

      // 4. Update sync cursor
      final maxVer = deltaPayload['current_max_sync_version'] as int?;
      if (maxVer != null) {
        await setSyncMeta('last_server_sync_version', maxVer.toString());
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'memoria_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
