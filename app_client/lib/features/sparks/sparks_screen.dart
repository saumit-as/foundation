import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../data/local/app_database.dart';

class SparksScreen extends ConsumerStatefulWidget {
  const SparksScreen({super.key});

  @override
  ConsumerState<SparksScreen> createState() => _SparksScreenState();
}

class _SparksScreenState extends ConsumerState<SparksScreen> {
  LocalAiSpark? _selectedSpark;
  bool _isExporting = false;

  Future<void> _exportSpark(LocalAiSpark spark) async {
    setState(() => _isExporting = true);
    final api = ref.read(apiClientProvider);

    try {
      final creds = await ref.read(credentialsStoreProvider).getCredentials();
      if (creds == null) return;

      final resp = await api.dio.get<String>(
        '${creds.apiBaseUrl}/api/v1/sparks/${spark.id}/export.md',
      );
      final mdContent = resp.data ?? spark.sparkMarkdown;

      // Save to local documents vault
      String? savePath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        final vaultDir = Directory('${dir.path}/memoria_vault');
        if (!await vaultDir.exists()) {
          await vaultDir.create(recursive: true);
        }
        final slug = spark.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        savePath = '${vaultDir.path}/$slug.md';
        final file = File(savePath);
        await file.writeAsString(mdContent);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savePath != null ? 'Exported to $savePath' : 'Export completed!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildSparkDetail(LocalAiSpark spark, List<LocalCapture> allCaptures) {
    List<String> sourceIds = [];
    try {
      sourceIds = (jsonDecode(spark.sourceCaptureIdsJson) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    } catch (_) {}

    final linkedCaptures = allCaptures.where((c) => sourceIds.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Detail Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(bottom: BorderSide(color: Color(0xFF334155))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  spark.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _exportSpark(spark),
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Export to Vault', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // Markdown View
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (spark.sparkRationale != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF312E81).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4338CA)),
                    ),
                    child: Text(
                      'AI Rationale: ${spark.sparkRationale!}',
                      style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

                MarkdownBody(
                  data: spark.sparkMarkdown,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
                    h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    h2: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 16),
                    h3: const TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
                    code: const TextStyle(backgroundColor: Color(0xFF0F172A), color: Color(0xFF38BDF8), fontFamily: 'monospace'),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),

                // Source Captures Section
                Text(
                  'SOURCE CAPTURES (${linkedCaptures.length})',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (linkedCaptures.isEmpty)
                  const Text('No source captures linked locally.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))
                else
                  ...linkedCaptures.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title ?? c.captureType.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          if (c.rawText != null)
                            Text(
                              c.rawText!,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<List<LocalAiSpark>>(
        stream: (db.select(db.localAiSparks)..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.createdAt)])).watch(),
        builder: (context, sparkSnap) {
          final sparks = sparkSnap.data ?? [];

          return StreamBuilder<List<LocalCapture>>(
            stream: db.select(db.localCaptures).watch(),
            builder: (context, capSnap) {
              final allCaptures = capSnap.data ?? [];

              if (sparks.isEmpty) {
                return const Center(
                  child: Text(
                    'No AI Sparks generated yet.\nAs you capture thoughts, luna-6 will synthesize connections!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                );
              }

              // Responsive Layout
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;

                  if (isWide) {
                    final currentSelected = _selectedSpark ?? sparks.first;
                    return Row(
                      children: [
                        // Left List Pane
                        SizedBox(
                          width: 320,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFF334155))),
                            ),
                            child: ListView.builder(
                              itemCount: sparks.length,
                              itemBuilder: (context, index) {
                                final s = sparks[index];
                                final isSel = s.id == currentSelected.id;
                                return ListTile(
                                  selected: isSel,
                                  selectedTileColor: const Color(0xFF1E293B),
                                  title: Text(
                                    s.title,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : const Color(0xFFCBD5E1),
                                      fontSize: 13,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    s.sparkRationale ?? '',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => setState(() => _selectedSpark = s),
                                );
                              },
                            ),
                          ),
                        ),
                        // Right Detail Pane
                        Expanded(child: _buildSparkDetail(currentSelected, allCaptures)),
                      ],
                    );
                  }

                  // Narrow / Mobile Layout
                  if (_selectedSpark != null) {
                    return Scaffold(
                      backgroundColor: const Color(0xFF0F172A),
                      appBar: AppBar(
                        backgroundColor: const Color(0xFF1E293B),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => setState(() => _selectedSpark = null),
                        ),
                        title: Text(_selectedSpark!.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      body: _buildSparkDetail(_selectedSpark!, allCaptures),
                    );
                  }

                  return ListView.builder(
                    itemCount: sparks.length,
                    itemBuilder: (context, index) {
                      final s = sparks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            s.sparkRationale ?? s.sparkMarkdown,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                          onTap: () => setState(() => _selectedSpark = s),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
