/// Akuntansi App - Professional offline-first accounting application
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/database/database_service.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/periods/domain/repositories/period_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.initialize();

  // Seed default data if needed
  final accountRepo = AccountRepository();
  await accountRepo.seedDefaults();

  final periodRepo = PeriodRepository();
  await periodRepo.initializeIfEmpty();

  runApp(const ProviderScope(child: AkuntansiApp()));
}

class AkuntansiApp extends StatelessWidget {
  const AkuntansiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Akuntansi App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
