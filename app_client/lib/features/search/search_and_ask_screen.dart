import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class SearchAndAskScreen extends ConsumerStatefulWidget {
  const SearchAndAskScreen({super.key});

  @override
  ConsumerState<SearchAndAskScreen> createState() => _SearchAndAskScreenState();
}

class _SearchAndAskScreenState extends ConsumerState<SearchAndAskScreen> {
  int _selectedModeIndex = 0; // 0 = Search, 1 = Ask Memoria
  final _queryController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Search results
  List<Map<String, dynamic>> _searchResults = [];
  final Set<String> _selectedItemIds = {};

  // Ask Memoria state
  String? _askAnswer;
  List<dynamic> _askCitations = [];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _executeSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedItemIds.clear();
    });

    final api = ref.read(apiClientProvider);
    final db = ref.read(databaseProvider);

    try {
      final creds = await ref.read(credentialsStoreProvider).getCredentials();
      if (creds != null && creds.isValid) {
        // Online Hybrid Search
        final resp = await api.dio.post(
          '${creds.apiBaseUrl}/api/v1/search',
          data: {'query': query, 'limit': 25},
        );
        final list = (resp.data as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
        setState(() => _searchResults = list);
      } else {
        // Offline SQLite search fallback
        final localCaps = await db.select(db.localCaptures).get();
        final list = localCaps
            .where((c) =>
                (c.rawText != null && c.rawText!.toLowerCase().contains(query.toLowerCase())) ||
                (c.title != null && c.title!.toLowerCase().contains(query.toLowerCase())))
            .map((c) => {
                  'owner_id': c.id,
                  'owner_table': 'captures',
                  'modality_composition': c.captureType,
                  'chunk_preview_text': c.rawText ?? c.title ?? '',
                  'combined_score': 1.0,
                })
            .toList();
        setState(() => _searchResults = list);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeAskMemoria() async {
    final question = _queryController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _askAnswer = null;
      _askCitations = [];
    });

    final api = ref.read(apiClientProvider);

    try {
      final creds = await ref.read(credentialsStoreProvider).getCredentials();
      if (creds == null || !creds.isValid) {
        throw StateError('Must be paired with home server to run conversational RAG.');
      }

      final resp = await api.dio.post(
        '${creds.apiBaseUrl}/api/v1/search/ask',
        data: {
          'question': question,
          'save_as_spark': false,
        },
      );

      final data = resp.data as Map<String, dynamic>;
      setState(() {
        _askAnswer = data['answer'] as String?;
        _askCitations = (data['citations'] as List<dynamic>?) ?? [];
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _synthesizeSelectedIntoSpark() async {
    if (_selectedItemIds.length < 2) return;

    setState(() => _isLoading = true);
    final api = ref.read(apiClientProvider);
    final flusher = ref.read(outboxFlusherProvider);

    try {
      final creds = await ref.read(credentialsStoreProvider).getCredentials();
      if (creds == null) return;

      await api.dio.post(
        '${creds.apiBaseUrl}/api/v1/sparks/synthesize',
        data: {
          'capture_ids': _selectedItemIds.toList(),
          'trigger_reason': 'manual_selection',
        },
      );

      await flusher.syncDelta();
      if (!mounted) return;
      setState(() => _selectedItemIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI Spark synthesized! Flushed to local Sparks.'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synthesis failed: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildModalityBadge(String modality) {
    Color bg = const Color(0xFF334155);
    Color fg = Colors.white;

    if (modality.contains('video')) {
      bg = const Color(0xFF701A75);
      fg = const Color(0xFFF0ABFC);
    } else if (modality.contains('audio')) {
      bg = const Color(0xFF064E3B);
      fg = const Color(0xFF6EE7B7);
    } else if (modality.contains('book') || modality.contains('pdf')) {
      bg = const Color(0xFF1E3A8A);
      fg = const Color(0xFF93C5FD);
    } else if (modality.contains('spark')) {
      bg = const Color(0xFF312E81);
      fg = const Color(0xFFA5B4FC);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        modality.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Switcher Header
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('🔍 Hybrid Search', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('🧠 Ask Memoria (RAG)', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        selected: {_selectedModeIndex},
                        onSelectionChanged: (set) => setState(() => _selectedModeIndex = set.first),
                        style: SegmentedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          selectedBackgroundColor: const Color(0xFF6366F1),
                          selectedForegroundColor: Colors.white,
                          foregroundColor: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: _selectedModeIndex == 0
                                ? 'Search keywords, transcripts, books, reels...'
                                : 'Ask questions across your entire knowledge base...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) {
                            if (_selectedModeIndex == 0) {
                              _executeSearch();
                            } else {
                              _executeAskMemoria();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_selectedModeIndex == 0) {
                                  _executeSearch();
                                } else {
                                  _executeAskMemoria();
                                }
                              },
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: Color(0xFF818CF8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Synthesis Bar when 2+ items selected in Search mode
            if (_selectedModeIndex == 0 && _selectedItemIds.length >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF312E81),
                child: Row(
                  children: [
                    Text(
                      '${_selectedItemIds.length} items selected',
                      style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _synthesizeSelectedIntoSpark,
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text('✨ Synthesize into Spark', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))))
                      : _selectedModeIndex == 0
                          ? _buildSearchResultsList()
                          : _buildAskMemoriaView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Search across all notes, videos, PDFs, and books.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final id = (item['owner_id'] ?? item['id'] ?? '').toString();
        final modality = (item['modality_composition'] ?? 'text').toString();
        final text = (item['chunk_preview_text'] ?? item['raw_text'] ?? '').toString();
        final isSelected = _selectedItemIds.contains(id);

        return Card(
          color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155)),
          ),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedItemIds.add(id);
                  } else {
                    _selectedItemIds.remove(id);
                  }
                });
              },
            ),
            title: Row(
              children: [
                _buildModalityBadge(modality),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAskMemoriaView() {
    if (_askAnswer == null) {
      return const Center(
        child: Text(
          'Ask Memoria anything grounded in your private notes and media.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: MarkdownBody(
              data: _askAnswer!,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
                h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                code: const TextStyle(backgroundColor: Color(0xFF0F172A), color: Color(0xFF38BDF8)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_askCitations.isNotEmpty) ...[
            const Text(
              'GROUNDED CITATIONS:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _askCitations.map((c) {
                final cMap = c is Map<String, dynamic> ? c : jsonDecode(c.toString()) as Map<String, dynamic>;
                return Chip(
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF334155)),
                  label: Text(
                    '${cMap['source_type'] ?? 'source'}: ${(cMap['capture_id'] ?? '').toString().substring(0, 8)}',
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
