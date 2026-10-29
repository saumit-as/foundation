import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/local/app_database.dart';

class TriageDeckScreen extends ConsumerStatefulWidget {
  const TriageDeckScreen({super.key});

  @override
  ConsumerState<TriageDeckScreen> createState() => _TriageDeckScreenState();
}

class _TriageDeckScreenState extends ConsumerState<TriageDeckScreen> {
  final _focusNode = FocusNode();
  int _currentIndex = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _makeDecision(LocalCapture capture, String decision) async {
    final db = ref.read(databaseProvider);
    final flusher = ref.read(outboxFlusherProvider);

    // Update local capture
    await (db.update(db.localCaptures)..where((tbl) => tbl.id.equals(capture.id))).write(
      LocalCapturesCompanion(
        isTriageReviewed: const drift.Value(true),
        isArchived: drift.Value(decision == 'ARCHIVE'),
        isDeleted: drift.Value(decision == 'DISMISS'),
      ),
    );

    // Queue outbox operation
    await db.enqueueOutboxOperation(
      entityId: capture.id,
      operation: 'TRIAGE_DECISION',
      payload: {
        'id': capture.id,
        'decision': decision,
        'target_table': 'captures',
      },
    );

    // Background flush attempt
    flusher.flush();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyP) {
      // Pin to project
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyE) {
      // Archive
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyX) {
      // Dismiss
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.space) {
      // Keep
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: StreamBuilder<List<LocalCapture>>(
            stream: (db.select(db.localCaptures)
                  ..where((tbl) => tbl.isTriageReviewed.equals(false) & tbl.isDeleted.equals(false))
                  ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.capturedAt)]))
                .watch(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all_rounded, size: 56, color: Color(0xFF10B981)),
                      SizedBox(height: 12),
                      Text(
                        'All caught up!',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No unreviewed captures in your triage deck.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              if (_currentIndex >= items.length) {
                _currentIndex = 0;
              }

              final current = items[_currentIndex];

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Top Progress Bar
                    Row(
                      children: [
                        Text(
                          'TRIAGE DECK (${_currentIndex + 1}/${items.length})',
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        const Text(
                          'Keys: Space=Keep, E=Archive, X=Dismiss',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card View
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF334155),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    current.captureType.toUpperCase(),
                                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${current.capturedAt.month}/${current.capturedAt.day} ${current.capturedAt.hour}:${current.capturedAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (current.title != null) ...[
                              Text(
                                current.title!,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  current.rawText ?? current.ocrText ?? current.transcriptText ?? 'No raw text',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Decision Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton.filled(
                          onPressed: () => _makeDecision(current, 'DISMISS'),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF991B1B), padding: const EdgeInsets.all(16)),
                          tooltip: 'Dismiss (X)',
                        ),
                        IconButton.filled(
                          onPressed: () => _makeDecision(current, 'ARCHIVE'),
                          icon: const Icon(Icons.archive_outlined, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF475569), padding: const EdgeInsets.all(16)),
                          tooltip: 'Archive (E)',
                        ),
                        IconButton.filled(
                          onPressed: () => _makeDecision(current, 'KEEP'),
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.all(16)),
                          tooltip: 'Keep (Space)',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
