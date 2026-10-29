import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../data/local/app_database.dart';

class CaptureCard extends StatefulWidget {
  final LocalCapture capture;
  final List<LocalCaptureAnnotation> annotations;
  final Future<void> Function(String captureId, String annotationContent) onAddAnnotation;

  const CaptureCard({
    super.key,
    required this.capture,
    required this.annotations,
    required this.onAddAnnotation,
  });

  @override
  State<CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<CaptureCard> {
  bool _isDrawerExpanded = false;
  bool _isReplying = false;
  final _replyController = TextEditingController();
  bool _isSubmittingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge() {
    String label = '⚡ Local Pending';
    Color bgColor = const Color(0xFF334155);
    Color textColor = const Color(0xFFE2E8F0);

    if (widget.capture.syncStatus == 'SYNCED') {
      switch (widget.capture.processingStatus) {
        case 'QUEUED':
        case 'SCRAPING':
        case 'OCR_IN_PROGRESS':
        case 'TRANSCRIBING':
          label = '⏳ Indexing Multimodal';
          bgColor = const Color(0xFF1E3A8A);
          textColor = const Color(0xFF93C5FD);
          break;
        case 'EXTRACTION_PARTIAL':
        case 'EXTRACTION_FAILED':
          label = '⚠️ Partial — Rescue in Browser';
          bgColor = const Color(0xFF78350F);
          textColor = const Color(0xFFFCD34D);
          break;
        case 'SPARK_EVALUATED':
          label = '✨ Spark Linked';
          bgColor = const Color(0xFF312E81);
          textColor = const Color(0xFFA5B4FC);
          break;
        case 'EMBEDDED':
          label = '✓ Indexed';
          bgColor = const Color(0xFF064E3B);
          textColor = const Color(0xFF6EE7B7);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVoiceDistillationCard() {
    if (widget.capture.voiceDistillationJson == null) return const SizedBox.shrink();

    try {
      final data = jsonDecode(widget.capture.voiceDistillationJson!) as Map<String, dynamic>;
      final summaryBullets = (data['summary_bullets'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final actionItems = (data['action_items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF475569).withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Color(0xFF818CF8)),
                SizedBox(width: 6),
                Text(
                  'VOICE MEMO DISTILLATION',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...summaryBullets.map((bullet) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFF94A3B8))),
                      Expanded(
                        child: Text(
                          bullet,
                          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            if (actionItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'ACTION ITEMS:',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...actionItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_box_outlined, size: 14, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSubmittingReply) return;

    setState(() => _isSubmittingReply = true);
    try {
      await widget.onAddAnnotation(widget.capture.id, text);
      _replyController.clear();
      setState(() => _isReplying = false);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReply = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExtractedContext = widget.capture.ocrText != null ||
        widget.capture.transcriptText != null ||
        widget.capture.extractedMarkdown != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                _buildStatusBadge(),
                const SizedBox(width: 8),
                Text(
                  widget.capture.captureType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.capture.capturedAt.hour.toString().padLeft(2, '0')}:${widget.capture.capturedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title if any
            if (widget.capture.title != null && widget.capture.title!.isNotEmpty) ...[
              Text(
                widget.capture.title!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Immutable raw text note
            if (widget.capture.rawText != null && widget.capture.rawText!.isNotEmpty)
              Text(
                widget.capture.rawText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE2E8F0),
                  height: 1.4,
                ),
              ),

            // Voice Distillation Summary if audio
            _buildVoiceDistillationCard(),

            // Source URL chip
            if (widget.capture.sourceUrl != null && widget.capture.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, size: 12, color: Color(0xFF818CF8)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.capture.sourceUrl!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF818CF8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Append-Only Marginalia Threads
            if (widget.annotations.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 6),
              ...widget.annotations.map(
                (annot) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          annot.content,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Reply Form
            if (_isReplying) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Append thought / marginalia...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSubmittingReply ? null : _submitReply,
                    icon: _isSubmittingReply
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 16, color: Color(0xFF818CF8)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isReplying = false),
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],

            // Bottom Actions Bar
            const SizedBox(height: 8),
            Row(
              children: [
                if (!_isReplying)
                  TextButton.icon(
                    onPressed: () => setState(() => _isReplying = true),
                    icon: const Icon(Icons.add_comment_outlined, size: 13),
                    label: const Text('Add Follow-up', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
                const Spacer(),
                if (hasExtractedContext)
                  TextButton.icon(
                    onPressed: () => setState(() => _isDrawerExpanded = !_isDrawerExpanded),
                    icon: Icon(
                      _isDrawerExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 14,
                    ),
                    label: Text(
                      _isDrawerExpanded ? 'Hide Extracted' : 'Extracted Context',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF818CF8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
              ],
            ),

            // Collapsible Extracted Context Drawer
            if (_isDrawerExpanded && hasExtractedContext) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.capture.ocrText != null) ...[
                      const Text(
                        'OCR EXTRACTED TEXT:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.capture.ocrText!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                      const SizedBox(height: 6),
                    ],
                    if (widget.capture.transcriptText != null) ...[
                      const Text(
                        'AUDIO/VIDEO TRANSCRIPT:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.capture.transcriptText!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
