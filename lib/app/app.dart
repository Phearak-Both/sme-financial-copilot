import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cloud/auth.dart';
import '../data/database.dart';
import '../domain/entry_proposal.dart';
import '../domain/enums.dart';
import '../features/ask/ask_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/entry_form/entry_form_screen.dart';
import '../features/export/export_screen.dart';
import '../features/ledger/entry_detail_screen.dart';
import '../features/ledger/ledger_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'labels.dart';
import 'providers.dart';
import 'theme.dart';

GoRouter _buildRouter(Listenable authRefresh) => GoRouter(
  refreshListenable: authRefresh,
  // Signed-out users see the sign-in screen first, when Supabase is set up.
  redirect: (_, state) {
    final onAuth = state.matchedLocation == '/auth';
    if (signInRequired) return onAuth ? null : '/auth';
    return onAuth ? '/' : null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const AskScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/ledger', builder: (_, _) => const LedgerScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/export', builder: (_, _) => const ExportScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/entry/new',
      builder: (_, state) => EntryFormScreen(
        initialType: EntryType.values
            .where((t) => t.name == state.uri.queryParameters['type'])
            .firstOrNull,
        proposal: state.extra is EntryProposal
            ? state.extra as EntryProposal
            : null,
      ),
    ),
    GoRoute(
      path: '/entry/:id',
      builder: (_, state) =>
          EntryDetailScreen(entryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/entry/:id/edit',
      builder: (_, state) => _EditEntryLoader(state.pathParameters['id']!),
    ),
  ],
);

class SmeCopilotApp extends ConsumerStatefulWidget {
  const SmeCopilotApp({super.key});

  @override
  ConsumerState<SmeCopilotApp> createState() => _SmeCopilotAppState();
}

class _SmeCopilotAppState extends ConsumerState<SmeCopilotApp> {
  // Owned by the app instance so navigation state never outlives it.
  final _authRefresh = AuthRefresh();
  late final GoRouter _router = _buildRouter(_authRefresh);

  @override
  void dispose() {
    _router.dispose();
    _authRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).value ?? defaultLocale;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.light;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: l10n.navAsk,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navLedger,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.download_outlined),
            selectedIcon: const Icon(Icons.download),
            label: l10n.navExport,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

/// Loads an entry before showing the edit form, so deep links work.
class _EditEntryLoader extends ConsumerStatefulWidget {
  const _EditEntryLoader(this.entryId);

  final String entryId;

  @override
  ConsumerState<_EditEntryLoader> createState() => _EditEntryLoaderState();
}

class _EditEntryLoaderState extends ConsumerState<_EditEntryLoader> {
  // Read once: the form owns its state after opening.
  late final Future<EntryRow?> _entry = ref
      .read(ledgerRepositoryProvider)
      .watchEntry(widget.entryId)
      .first;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _entry,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final row = snapshot.data;
        if (row == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.entryNotFound)),
          );
        }
        return EntryFormScreen(initial: row);
      },
    );
  }
}
