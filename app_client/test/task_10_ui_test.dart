import 'dart:convert';
import 'dart:typed_data';

import 'package:app_client/core/config/credentials_store.dart';
import 'package:app_client/core/network/memoria_api_client.dart';
import 'package:app_client/core/providers.dart';
import 'package:app_client/data/local/app_database.dart';
import 'package:app_client/data/sync/outbox_flusher.dart';
import 'package:app_client/features/scratchpad/scratchpad_screen.dart';
import 'package:app_client/features/scratchpad/widgets/active_book_session_banner.dart';
import 'package:app_client/features/scratchpad/widgets/capture_card.dart';
import 'package:app_client/features/search/search_and_ask_screen.dart';
import 'package:app_client/features/sparks/sparks_screen.dart';
import 'package:app_client/features/triage/triage_deck_screen.dart';
import 'package:app_client/main.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUiHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'status': 'ACCEPTED', 'sync_version': 1}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeTestCredentialsStore extends CredentialsStore {
  final DeviceCredentials _creds;
  FakeTestCredentialsStore(this._creds);

  @override
  Future<DeviceCredentials?> getCredentials() async => _creds;

  @override
  Future<bool> hasCredentials() async => true;
}

void main() {
  late AppDatabase db;
  late FakeTestCredentialsStore fakeStore;
  late MemoriaApiClient apiClient;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    fakeStore = FakeTestCredentialsStore(
      const DeviceCredentials(
        apiBaseUrl: 'http://localhost:8000',
        cfAccessClientId: 'fake.access',
        cfAccessClientSecret: 'fake_secret',
        deviceId: '0192d04e-0000-7000-8000-000000000001',
        bearerKey: 'mem_live_mock',
      ),
    );

    final dio = Dio();
    dio.httpClientAdapter = MockUiHttpClientAdapter();
    apiClient = MemoriaApiClient(dio: dio, credentialsStore: fakeStore);
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        credentialsStoreProvider.overrideWithValue(fakeStore),
        apiClientProvider.overrideWithValue(apiClient),
        outboxFlusherProvider.overrideWithValue(
          OutboxFlusher(
            database: db,
            apiClient: apiClient,
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: child,
      ),
    );
  }

  testWidgets('1. ScratchpadScreen creates note and displays immutable rawText in CaptureCard',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(const ScratchpadScreen()));
    await tester.pumpAndSettle();

    // Verify composer renders
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Capture'), findsOneWidget);

    // Enter note and submit
    await tester.enterText(find.byType(TextField), 'Testing offline instant capture #flutter');
    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();

    // Verify CaptureCard is rendered with exact text
    expect(find.byType(CaptureCard), findsOneWidget);
    expect(find.text('Testing offline instant capture #flutter'), findsOneWidget);

    // Verify local DB state
    final captures = await db.select(db.localCaptures).get();
    expect(captures.length, equals(1));
    expect(captures.first.rawText, equals('Testing offline instant capture #flutter'));
    expect(['PENDING_SYNC', 'SYNCED'], contains(captures.first.syncStatus));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('2. CaptureCard adds marginalia while parent rawText remains 100% immutable',
      (WidgetTester tester) async {
    final now = DateTime.now();
    const captureId = '0192d04e-1111-7000-8000-000000000002';

    await db.into(db.localCaptures).insert(
          LocalCapturesCompanion.insert(
            id: captureId,
            captureType: 'quick_thought',
            rawText: const drift.Value('Initial Immutable Core Thought'),
            capturedAt: now,
            updatedAt: now,
          ),
        );

    await tester.pumpWidget(buildTestApp(const ScratchpadScreen()));
    await tester.pumpAndSettle();

    // Verify card is rendered
    expect(find.text('Initial Immutable Core Thought'), findsOneWidget);

    // Click "Add Follow-up"
    await tester.tap(find.text('Add Follow-up'));
    await tester.pumpAndSettle();

    // Enter marginalia reply
    final replyInput = find.widgetWithText(TextField, 'Append thought / marginalia...');
    expect(replyInput, findsOneWidget);
    await tester.enterText(replyInput, 'Appended marginalia note');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    // Verify marginalia text appears in card
    expect(find.text('Appended marginalia note'), findsOneWidget);
    // Verify initial rawText is still present intact
    expect(find.text('Initial Immutable Core Thought'), findsOneWidget);

    // Verify database immutability
    final cap = await (db.select(db.localCaptures)..where((tbl) => tbl.id.equals(captureId))).getSingle();
    expect(cap.rawText, equals('Initial Immutable Core Thought'));

    final annots = await (db.select(db.localCaptureAnnotations)..where((tbl) => tbl.captureId.equals(captureId))).get();
    expect(annots.length, equals(1));
    expect(annots.first.content, equals('Appended marginalia note'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('3. Starting an Active Book Session displays ActiveBookSessionBanner',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(const ScratchpadScreen()));
    await tester.pumpAndSettle();

    // Initially no active session
    expect(find.text('No active reading session'), findsOneWidget);

    // Click "Start Book Session"
    await tester.tap(find.text('Start Book Session'));
    await tester.pumpAndSettle();

    // Enter book title
    final titleInput = find.widgetWithText(TextField, 'Book Title (e.g. Crafting Interpreters)');
    expect(titleInput, findsOneWidget);
    await tester.enterText(titleInput, 'Designing Data-Intensive Applications');
    await tester.tap(find.text('Start Session'));
    await tester.pumpAndSettle();

    // Verify ActiveBookSessionBanner is updated
    expect(find.byType(ActiveBookSessionBanner), findsOneWidget);
    expect(find.textContaining('Designing Data-Intensive Applications'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('4. Switching tabs renders SparksScreen, SearchAndAskScreen, and TriageDeckScreen with no overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Insert dummy spark
    await db.into(db.localAiSparks).insert(
          LocalAiSparksCompanion.insert(
            id: '0192d04e-2222-7000-8000-000000000003',
            title: 'Distributed Consensus & Raft Notes',
            sparkMarkdown: '# Synthesis\n\nComparing Paxos with Raft leader election.',
            createdAt: DateTime.now(),
          ),
        );

    // Insert dummy triage item
    await db.into(db.localCaptures).insert(
          LocalCapturesCompanion.insert(
            id: '0192d04e-3333-7000-8000-000000000004',
            captureType: 'url_bookmark',
            title: const drift.Value('Raft Paper URL'),
            rawText: const drift.Value('https://raft.github.io/'),
            capturedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(buildTestApp(const AppShell()));
    await tester.pumpAndSettle();

    // 1. Scratchpad (Default)
    expect(find.byType(ScratchpadScreen), findsOneWidget);

    // 2. Switch to Sparks
    await tester.tap(find.text('Sparks'));
    await tester.pumpAndSettle();
    expect(find.byType(SparksScreen), findsOneWidget);
    expect(find.text('Distributed Consensus & Raft Notes'), findsAtLeastNWidgets(1));

    // 3. Switch to Search & Ask
    await tester.tap(find.text('Search & Ask'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchAndAskScreen), findsOneWidget);
    expect(find.text('🔍 Hybrid Search'), findsOneWidget);
    expect(find.text('🧠 Ask Memoria (RAG)'), findsOneWidget);

    // Toggle Ask Memoria mode
    await tester.tap(find.text('🧠 Ask Memoria (RAG)'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Memoria anything grounded in your private notes and media.'), findsOneWidget);

    // 4. Switch to Triage Deck
    await tester.tap(find.text('Triage Deck'));
    await tester.pumpAndSettle();
    expect(find.byType(TriageDeckScreen), findsOneWidget);
    expect(find.text('Raft Paper URL'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
