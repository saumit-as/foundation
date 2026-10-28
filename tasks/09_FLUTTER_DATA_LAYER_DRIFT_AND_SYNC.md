# 09_FLUTTER_DATA_LAYER_DRIFT_AND_SYNC.md
> **TASK 09: FLUTTER MULTI-DEVICE SCAFFOLD, DRIFT SQLITE TABLES, OUTBOX FLUSHER & `ntfy` PUSH LISTENER**
> - **Prerequisites:** Task 08 `[x] PASSED`
> - **Reference Spec:** [`docs/08_client_and_browser_extension_specs.md`](../docs/08_client_and_browser_extension_specs.md), [`docs/02_DATABASE_AND_VECTOR_SCHEMA.md`](../docs/02_DATABASE_AND_VECTOR_SCHEMA.md), and [`docs/07_reminder_triage_and_push_notification_spec.md`](../docs/07_reminder_triage_and_push_notification_spec.md)

---

## 1. Mandatory Flutter Coding Rules (CRITICAL)
1. **Zero Placeholders:** Never use `// ...` or elided code blocks. Write complete, strictly typed Dart 3 files.
2. **Mandatory Analyzer Validation:** After creating or modifying any Dart file, immediately invoke the Flutter/Dart analyzer (`flutter analyze`). Zero errors are required before proceeding.
3. **Sequential Chunking:** Implement this task in 3 verifiable chunks:
   - **Chunk A:** Project Scaffold, `pubspec.yaml`, Drift Database Schema (`app_database.dart`) & Code Generation (`build_runner`).
   - **Chunk B:** Zero-Trust Dio Network Client, QR Pairing Credential Store & Offline `OutboxFlusher` + Delta Sync Engine.
   - **Chunk C:** Direct `ntfy` WebSocket/HTTP Poll Listener & Native Notification Action Handler (`Mark Done` / `Snooze 3h`) + Unit Tests.

---

## 2. Exact Files to Create

1. `app_client/pubspec.yaml`
2. `app_client/analysis_options.yaml`
3. `app_client/lib/core/config/credentials_store.dart`
4. `app_client/lib/core/network/memoria_api_client.dart`
5. `app_client/lib/data/local/app_database.dart`
6. `app_client/lib/data/sync/outbox_flusher.dart`
7. `app_client/lib/data/sync/ntfy_listener_service.dart`
8. `app_client/test/task_09_sync_test.dart`

---

## 3. Step-by-Step Implementation Instructions

### Chunk A: Scaffold `/app_client` & Drift Database (`app_database.dart`)
1. Create `/app_client` (`flutter create --platforms=android,linux,windows app_client` if not present) and configure `pubspec.yaml` with:
   - `flutter_riverpod`, `riverpod_annotation`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
   - `dio`, `web_socket_channel`, `connectivity_plus`, `flutter_secure_storage`
   - `receive_sharing_intent`, `image_picker`, `cunning_document_scanner`, `mobile_scanner`, `flutter_local_notifications`, `workmanager`, `uuid`, `flutter_markdown`, `url_launcher`
   - Dev dependencies: `build_runner`, `drift_dev`, `riverpod_generator`, `flutter_test`, `flutter_lints`
2. Implement `app_client/lib/data/local/app_database.dart` containing all 6 tables from `docs/02_DATABASE_AND_VECTOR_SCHEMA.md` Section 4:
   - `LocalCaptures` (including `readingSessionId`, `pageRange`, `voiceDistillationJson`, `mediaAssetsJson`, `isTriageReviewed`)
   - `LocalCaptureAnnotations` (append-only marginalia)
   - `LocalReadingSessions` (sticky book sessions)
   - `OutboxSyncQueue` (FIFO transactional outbox)
   - `LocalAiSparks`
   - `SyncStateMeta`
3. Add DAO methods on `AppDatabase`:
   - `insertLocalCaptureAndEnqueueOutbox(...)` (executes in a single SQLite transaction in `<5ms`)
   - `insertLocalAnnotationAndEnqueueOutbox(...)`
   - `applyServerDeltaSync(Map<String, dynamic> deltaPayload)` (upserts captures, annotations, reading sessions, sparks, and updates `last_server_sync_version`)
4. Run `dart run build_runner build --delete-conflicting-outputs` and `flutter analyze`.

### Chunk B: Zero-Trust Dio Client & `OutboxFlusher` (`memoria_api_client.dart` & `outbox_flusher.dart`)
1. Implement `CredentialsStore` (`credentials_store.dart`) parsing the QR JSON bundle (`v`, `api_base_url`, `cf_access_client_id`, `cf_access_client_secret`, `device_id`, `bearer_key`, `ntfy_url`, `ntfy_topic`, `ntfy_token`) and persisting it in `FlutterSecureStorage`.
2. Implement `MemoriaApiClient` (`memoria_api_client.dart`) with a `Dio` interceptor that attaches `CF-Access-Client-Id`, `CF-Access-Client-Secret`, `Authorization: Bearer <bearer_key>`, and `X-Client-Device-Id` to every request.
3. Implement `OutboxFlusher` (`outbox_flusher.dart`):
   - Processes `OutboxSyncQueue` rows ordered by `seqId ASC` where `nextRetryAt == null || nextRetryAt <= DateTime.now()`.
   - Handles operations: `CREATE_CAPTURE`, `UPLOAD_MEDIA`, `CREATE_ANNOTATION`, `ACK_REMINDER`, `TRIAGE_DECISION`, and `START_READING_SESSION`.
   - On `200`/`201`/`202`, deletes the outbox row, marks `LocalCaptures.syncStatus = 'SYNCED'`, and immediately calls `GET /api/v1/sync/delta?since_version=<last_version>`.
   - On network/5xx error, increments `retryCount` and sets exponential backoff (`2^retryCount` seconds, max 15 minutes).

### Chunk C: Direct `ntfy` Listener & Offline-Safe Notification Actions (`ntfy_listener_service.dart`)
1. Connect to `wss://<api_host>/ntfy/<topic>/ws?since=<last_ntfy_id>` with Zero-Trust + `ntfy` Bearer headers.
2. Parse incoming JSON messages (`event == "message"`), store `last_ntfy_message_id` in `SyncStateMeta`, and display a native OS notification via `FlutterLocalNotificationsPlugin` with payload `deep_link_uri` and action buttons `MARK_DONE` and `SNOOZE_3H`.
3. When the user taps `MARK_DONE` or `SNOOZE_3H`, invoke `PATCH /api/v1/reminders/{id}/ack` via `MemoriaApiClient`, falling back to inserting an `ACK_REMINDER` row in `OutboxSyncQueue` if offline.

---

## 4. Deterministic Verification Gate (`PASS / FAIL`)

Write `app_client/test/task_09_sync_test.dart` using an in-memory `NativeDatabase.memory()` Drift instance and a mocked `Dio` adapter verifying:
1. Creating a local capture inserts both `LocalCaptures` (`syncStatus == 'PENDING_SYNC'`) and `OutboxSyncQueue` (`operation == 'CREATE_CAPTURE'`) atomically.
2. Appending a `LocalCaptureAnnotations` note leaves `LocalCaptures.rawText` 100% immutable and enqueues `CREATE_ANNOTATION`.
3. Running `OutboxFlusher.flush()` sends the queued operations, removes them from `OutboxSyncQueue`, updates `syncStatus == 'SYNCED'`, and applies the mock `/api/v1/sync/delta` response (populating `LocalAiSparks` and `last_server_sync_version`).

Run:
```powershell
cd app_client
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/task_09_sync_test.dart
```
- **Success Criteria:** `No issues found!` from `flutter analyze` and `All tests passed!` from `flutter test` (exit code `0`). Mark **Task 09** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
