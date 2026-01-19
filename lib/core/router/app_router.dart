/// App router configuration using go_router
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/responsive_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/journal/presentation/screens/journal_list_screen.dart';
import '../../features/journal/presentation/screens/journal_entry_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/accounts/presentation/screens/account_ledger_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Navigation destinations for the app
enum AppDestination {
  dashboard(
    path: '/',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  transactions(
    path: '/transactions',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Transaksi',
  ),
  accounts(
    path: '/accounts',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    label: 'Akun',
  ),
  reports(
    path: '/reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    label: 'Laporan',
  ),
  settings(
    path: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Pengaturan',
  );

  const AppDestination({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Global key for the navigator
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// Router configuration
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Shell route for main navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ResponsiveShell(child: child);
      },
      routes: [
        // Dashboard
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),

        // Transactions (Journal List)
        GoRoute(
          path: '/transactions',
          name: 'transactions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: JournalListScreen()),
          routes: [
            // New journal entry
            GoRoute(
              path: 'new',
              name: 'new-journal',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const JournalEntryScreen(),
            ),
            // Edit journal entry
            GoRoute(
              path: ':id',
              name: 'edit-journal',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return JournalEntryScreen(journalId: id);
              },
            ),
          ],
        ),

        // Accounts
        GoRoute(
          path: '/accounts',
          name: 'accounts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AccountsScreen()),
          routes: [
            // Account ledger
            GoRoute(
              path: ':id/ledger',
              name: 'account-ledger',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AccountLedgerScreen(accountId: id);
              },
            ),
          ],
        ),

        // Reports
        GoRoute(
          path: '/reports',
          name: 'reports',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ReportsScreen()),
        ),

        // Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);
