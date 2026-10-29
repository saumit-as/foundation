import 'dart:convert';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/local/app_database.dart';
import 'widgets/active_book_session_banner.dart';
import 'widgets/capture_card.dart';

class ScratchpadScreen extends ConsumerStatefulWidget {
  const ScratchpadScreen({super.key});

  @override
  ConsumerState<ScratchpadScreen> createState() => _ScratchpadScreenState();
}

class _ScratchpadScreenState extends ConsumerState<ScratchpadScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSaveThought() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    final flusher = ref.read(outboxFlusherProvider);

    try {
      final now = DateTime.now();
      final id = const Uuid().v7();

      // Extract user tags (#tag)
      final tagMatches = RegExp(r'#(\w+)').allMatches(text);
      final tags = tagMatches.map((m) => m.group(1)!).toList();

      // Check active reading session
      final activeSession = await (db.select(db.localReadingSessions)
            ..where((tbl) => tbl.isActive.equals(true)))
          .getSingleOrNull();

      final outboxPayload = {
        'id': id,
        'capture_type': 'quick_thought',
        'raw_text': text,
        'title': null,
        'source_url': null,
        'user_tags': tags,
        'captured_at': now.toIso8601String(),
        'reading_session_id': activeSession?.id,
      };

      await db.insertLocalCaptureAndEnqueueOutbox(
        capture: LocalCapturesCompanion(
          id: drift.Value(id),
          readingSessionId: drift.Value(activeSession?.id),
          captureType: const drift.Value('quick_thought'),
          rawText: drift.Value(text),
          userTagsJson: drift.Value(jsonEncode(tags)),
          capturedAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
        outboxPayload: outboxPayload,
      );

      _textController.clear();
      _focusNode.requestFocus();

      // Background flush attempt
      unawaited(flusher.flush());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleBurstScan() async {
    final db = ref.read(databaseProvider);
    final flusher = ref.read(outboxFlusherProvider);

    try {
      List<String>? pictures;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        pictures = await CunningDocumentScanner.getPictures();
      }

      if (pictures == null || pictures.isEmpty) return;

      final activeSession = await (db.select(db.localReadingSessions)
            ..where((tbl) => tbl.isActive.equals(true)))
          .getSingleOrNull();

      final bookTitle = activeSession?.sourceTitle ?? 'Book Scan';
      final now = DateTime.now();
      final captureId = const Uuid().v7();

      final outboxPayload = {
        'id': captureId,
        'capture_type': 'book_scan',
        'title': '$bookTitle (Scan: ${pictures.length} pages)',
        'raw_text': 'Multi-page burst scan of $bookTitle',
        'page_range': '1-${pictures.length}',
        'user_tags': ['book', 'burst_scan'],
        'reading_session_id': activeSession?.id,
        'captured_at': now.toIso8601String(),
      };

      await db.insertLocalCaptureAndEnqueueOutbox(
        capture: LocalCapturesCompanion(
          id: drift.Value(captureId),
          readingSessionId: drift.Value(activeSession?.id),
          captureType: const drift.Value('book_scan'),
          title: drift.Value('$bookTitle (Scan: ${pictures.length} pages)'),
          rawText: drift.Value('Multi-page burst scan of $bookTitle'),
          pageRange: drift.Value('1-${pictures.length}'),
          userTagsJson: const drift.Value('["book", "burst_scan"]'),
          capturedAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
        outboxPayload: outboxPayload,
      );

      // Queue media uploads for each scanned page
      for (int i = 0; i < pictures.length; i++) {
        final filePath = pictures[i];
        final assetId = const Uuid().v7();
        await db.enqueueOutboxOperation(
          entityId: captureId,
          operation: 'UPLOAD_MEDIA',
          payload: {
            'asset_id': assetId,
            'media_kind': 'book_page',
            'page_order': i,
            'soft_token_budget': 1120,
            'local_file_path': filePath,
          },
          localFilePath: filePath,
        );
      }

      unawaited(flusher.flush());
    } catch (e) {
      debugPrint('Burst scan notice: $e');
    }
  }

  void _showStartSessionDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Start Reading Session', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Book Title (e.g. Crafting Interpreters)',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: authorController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Author (optional)',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final db = ref.read(databaseProvider);
              final sessionId = const Uuid().v7();
              final now = DateTime.now();

              // Deactivate any currently active session
              await (db.update(db.localReadingSessions)
                    ..where((tbl) => tbl.isActive.equals(true)))
                  .write(const LocalReadingSessionsCompanion(isActive: drift.Value(false)));

              // Insert new session
              await db.into(db.localReadingSessions).insert(
                    LocalReadingSessionsCompanion.insert(
                      id: sessionId,
                      sourceTitle: title,
                      author: drift.Value(authorController.text.trim().isEmpty ? null : authorController.text.trim()),
                      createdAt: now,
                    ),
                  );

              await db.enqueueOutboxOperation(
                entityId: sessionId,
                operation: 'START_READING_SESSION',
                payload: {
                  'id': sessionId,
                  'source_title': title,
                  'author': authorController.text.trim().isEmpty ? null : authorController.text.trim(),
                },
              );

              if (ctx.mounted) Navigator.pop(ctx);
              ref.read(outboxFlusherProvider).flush();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Start Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _endCurrentSession(LocalReadingSession session) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.localReadingSessions)..where((tbl) => tbl.id.equals(session.id))).write(
      const LocalReadingSessionsCompanion(isActive: drift.Value(false)),
    );
  }

  Future<void> _addAnnotation(String captureId, String content) async {
    final db = ref.read(databaseProvider);
    final flusher = ref.read(outboxFlusherProvider);
    final annotId = const Uuid().v7();

    await db.insertLocalAnnotationAndEnqueueOutbox(
      annotation: LocalCaptureAnnotationsCompanion(
        id: drift.Value(annotId),
        captureId: drift.Value(captureId),
        content: drift.Value(content),
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    unawaited(flusher.flush());
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Reading Session Banner Stream
            StreamBuilder<LocalReadingSession?>(
              stream: (db.select(db.localReadingSessions)
                    ..where((tbl) => tbl.isActive.equals(true)))
                  .watchSingleOrNull(),
              builder: (context, snapshot) {
                final activeSession = snapshot.data;
                return ActiveBookSessionBanner(
                  activeSession: activeSession,
                  onStartSession: _showStartSessionDialog,
                  onEndSession: () {
                    if (activeSession != null) _endCurrentSession(activeSession);
                  },
                  onBurstScan: _handleBurstScan,
                );
              },
            ),

            // Top Composer (0-tap thought entry)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Capture thought, note, or #tag...',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _handleBurstScan,
                        icon: const Icon(Icons.document_scanner_rounded, size: 20, color: Color(0xFF818CF8)),
                        tooltip: 'Document / Book Scan',
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSaveThought,
                        icon: _isSaving
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Capture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Captures List Stream
            Expanded(
              child: StreamBuilder<List<LocalCapture>>(
                stream: (db.select(db.localCaptures)
                      ..where((tbl) => tbl.isDeleted.equals(false))
                      ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.capturedAt)]))
                    .watch(),
                builder: (context, captureSnap) {
                  final captures = captureSnap.data ?? [];

                  if (captures.isEmpty) {
                    return const Center(
                      child: Text(
                        'Your scratchpad is empty.\nJot down a thought or clip a link above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    );
                  }

                  return StreamBuilder<List<LocalCaptureAnnotation>>(
                    stream: db.select(db.localCaptureAnnotations).watch(),
                    builder: (context, annotSnap) {
                      final allAnnotations = annotSnap.data ?? [];

                      return ListView.builder(
                        itemCount: captures.length,
                        itemBuilder: (context, index) {
                          final cap = captures[index];
                          final capAnnots = allAnnotations
                              .where((a) => a.captureId == cap.id)
                              .toList();

                          return CaptureCard(
                            key: ValueKey(cap.id),
                            capture: cap,
                            annotations: capAnnots,
                            onAddAnnotation: _addAnnotation,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}
