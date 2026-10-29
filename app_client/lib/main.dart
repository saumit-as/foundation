import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/providers.dart';
import 'features/onboarding/qr_onboarding_screen.dart';
import 'features/scratchpad/scratchpad_screen.dart';
import 'features/search/search_and_ask_screen.dart';
import 'features/share_receiver/share_receiver_sheet.dart';
import 'features/sparks/sparks_screen.dart';
import 'features/triage/triage_deck_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MemoriaApp(),
    ),
  );
}

class MemoriaApp extends StatelessWidget {
  const MemoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memoria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoading = true;
  bool _hasCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final store = ref.read(credentialsStoreProvider);
    final hasCreds = await store.hasCredentials();
    if (mounted) {
      setState(() {
        _hasCredentials = hasCreds;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (!_hasCredentials) {
      return QrOnboardingScreen(
        onConnected: () => setState(() => _hasCredentials = true),
      );
    }

    return const AppShell();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScratchpadScreen(),
    SparksScreen(),
    SearchAndAskScreen(),
    TriageDeckScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initShareReceiver();
  }

  void _initShareReceiver() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        ReceiveSharingIntent.instance.getMediaStream().listen((files) {
          if (files.isNotEmpty && mounted) {
            final f = files.first;
            _openShareSheet(f.path);
          }
        });

        ReceiveSharingIntent.instance.getInitialMedia().then((files) {
          if (files.isNotEmpty && mounted) {
            final f = files.first;
            _openShareSheet(f.path);
          }
        });
      } catch (_) {}
    }
  }

  void _openShareSheet(String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareReceiverSheet(sharedContent: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              backgroundColor: const Color(0xFF0F172A),
              selectedIconTheme: const IconThemeData(color: Color(0xFF818CF8)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.edit_note_rounded),
                  label: Text('Scratchpad', style: TextStyle(fontSize: 11)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_rounded),
                  label: Text('Sparks', style: TextStyle(fontSize: 11)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.saved_search_rounded),
                  label: Text('Search & Ask', style: TextStyle(fontSize: 11)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.style_rounded),
                  label: Text('Triage Deck', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1E293B)),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFF312E81),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_rounded),
            label: 'Scratchpad',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Sparks',
          ),
          NavigationDestination(
            icon: Icon(Icons.saved_search_rounded),
            label: 'Search & Ask',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_rounded),
            label: 'Triage Deck',
          ),
        ],
      ),
    );
  }
}
