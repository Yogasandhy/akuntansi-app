/// Riverpod providers for periods feature
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/period.dart';
import '../domain/repositories/period_repository.dart';

/// Period repository provider
final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  return PeriodRepository();
});

/// All periods provider
final allPeriodsProvider = FutureProvider<List<Period>>((ref) async {
  final repository = ref.watch(periodRepositoryProvider);
  return repository.getAll();
});

/// Active period provider
final activePeriodProvider = FutureProvider<Period?>((ref) async {
  final repository = ref.watch(periodRepositoryProvider);
  return repository.getActive();
});

/// Single period provider
final periodProvider = FutureProvider.family<Period?, String>((ref, uid) async {
  final repository = ref.watch(periodRepositoryProvider);
  return repository.getById(uid);
});
