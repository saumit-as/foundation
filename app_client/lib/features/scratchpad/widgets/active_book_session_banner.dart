import 'package:flutter/material.dart';

import '../../../data/local/app_database.dart';

class ActiveBookSessionBanner extends StatelessWidget {
  final LocalReadingSession? activeSession;
  final VoidCallback onStartSession;
  final VoidCallback onEndSession;
  final VoidCallback onBurstScan;

  const ActiveBookSessionBanner({
    super.key,
    required this.activeSession,
    required this.onStartSession,
    required this.onEndSession,
    required this.onBurstScan,
  });

  @override
  Widget build(BuildContext context) {
    if (activeSession == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            const Text(
              'No active reading session',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onStartSession,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Start Book Session', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF818CF8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1B4B), // Deep indigo
        border: Border(
          bottom: BorderSide(color: Color(0xFF4338CA)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, size: 20, color: Color(0xFFA5B4FC)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'ACTIVE BOOK: ',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        activeSession!.sourceTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (activeSession!.author != null)
                  Text(
                    'by ${activeSession!.author!}',
                    style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onBurstScan,
            icon: const Icon(Icons.document_scanner_rounded, size: 14),
            label: const Text('Burst Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onEndSession,
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
            tooltip: 'End Reading Session',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
