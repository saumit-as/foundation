import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/local/app_database.dart';

class ShareReceiverSheet extends ConsumerStatefulWidget {
  final String sharedContent;
  final String? sharedTitle;
  final String? localFilePath;

  const ShareReceiverSheet({
    super.key,
    required this.sharedContent,
    this.sharedTitle,
    this.localFilePath,
  });

  @override
  ConsumerState<ShareReceiverSheet> createState() => _ShareReceiverSheetState();
}

class _ShareReceiverSheetState extends ConsumerState<ShareReceiverSheet> {
  final _commentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final db = ref.read(databaseProvider);
    final flusher = ref.read(outboxFlusherProvider);

    try {
      final now = DateTime.now();
      final id = const Uuid().v7();

      final rawText = _commentController.text.trim();
      final tags = _tagsController.text
          .split(RegExp(r'[,\s]+'))
          .map((t) => t.replaceAll('#', '').trim())
          .filter((t) => t.isNotEmpty)
          .toList();

      final isUrl = widget.sharedContent.startsWith('http://') ||
          widget.sharedContent.startsWith('https://');

      String captureType = 'quick_thought';
      if (isUrl) {
        if (widget.sharedContent.contains('instagram.com/reel') ||
            widget.sharedContent.contains('youtube.com/shorts')) {
          captureType = 'video_reel';
        } else if (widget.sharedContent.endsWith('.pdf')) {
          captureType = 'technical_pdf';
        } else {
          captureType = 'url_bookmark';
        }
      }

      final outboxPayload = {
        'id': id,
        'capture_type': captureType,
        'title': widget.sharedTitle ?? (isUrl ? 'Shared Bookmark' : 'Shared Note'),
        'raw_text': rawText.isNotEmpty ? '$rawText\n\n${widget.sharedContent}' : widget.sharedContent,
        'source_url': isUrl ? widget.sharedContent : null,
        'user_tags': tags,
        'captured_at': now.toIso8601String(),
      };

      await db.insertLocalCaptureAndEnqueueOutbox(
        capture: LocalCapturesCompanion(
          id: drift.Value(id),
          captureType: drift.Value(captureType),
          title: drift.Value(widget.sharedTitle ?? (isUrl ? 'Shared Bookmark' : 'Shared Note')),
          rawText: drift.Value(rawText.isNotEmpty ? '$rawText\n\n${widget.sharedContent}' : widget.sharedContent),
          sourceUrl: drift.Value(isUrl ? widget.sharedContent : null),
          userTagsJson: drift.Value(jsonEncode(tags)),
          localMediaPath: drift.Value(widget.localFilePath),
          capturedAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
        outboxPayload: outboxPayload,
        localFilePath: widget.localFilePath,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      flusher.flush();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.share_rounded, size: 20, color: Color(0xFF818CF8)),
              const SizedBox(width: 8),
              const Text(
                'Save to Memoria',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shared Preview Chip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              widget.sharedContent,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _commentController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Add an optional thought / note...',
              hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _tagsController,
            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12),
            decoration: const InputDecoration(
              hintText: '#tags (e.g. #homelab, #research)',
              hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 12),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save to Scratchpad (<15ms)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

extension IterableFilter<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
