import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import '../models/item.dart';
import '../models/sales.dart';
import '../models/scale.dart';
import '../models/user.dart';
import 'branch_provider.dart';
import 'services.dart';

// Catalog ---------------------------------------------------------------

final categoriesProvider = FutureProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(catalogServiceProvider).categories(),
);

/// Every item with the current branch's price and stock, sorted by PLU.
/// Screens filter and search this list locally so typing feels instant.
final itemsProvider = FutureProvider.autoDispose<List<Item>>((ref) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(catalogServiceProvider).items(branchId: branchId);
});

// Scales ------------------------------------------------------------------

final scalesProvider = FutureProvider.autoDispose<List<Scale>>((ref) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(scaleServiceProvider).list(branchId);
});

final scaleProvider = FutureProvider.autoDispose.family<Scale, String>(
  (ref, id) => ref.watch(scaleServiceProvider).get(id),
);

final scaleHistoryProvider = FutureProvider.autoDispose.family<List<ScaleCommand>, String>(
  (ref, id) => ref.watch(scaleServiceProvider).history(id),
);

// Sales -------------------------------------------------------------------

final daySummaryProvider = FutureProvider.autoDispose.family<DaySales, DateTime>((ref, date) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(reportServiceProvider).summary(branchId, date);
});

final dayBillsProvider = FutureProvider.autoDispose.family<List<Bill>, DateTime>((ref, date) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(reportServiceProvider).bills(branchId, date);
});

typedef DateRange = ({DateTime from, DateTime to});

final dailySalesProvider = FutureProvider.autoDispose.family<List<DaySales>, DateRange>((ref, r) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(reportServiceProvider).daily(branchId, r.from, r.to);
});

final itemSalesProvider = FutureProvider.autoDispose.family<List<ItemSales>, DateRange>((ref, r) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(reportServiceProvider).itemSales(branchId, r.from, r.to);
});

// Stock -------------------------------------------------------------------

final purchasesProvider = FutureProvider.autoDispose<List<Purchase>>((ref) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(stockServiceProvider).purchases(branchId);
});

// Settings ----------------------------------------------------------------

final billSettingsProvider = FutureProvider.autoDispose<BillSettings>((ref) {
  final branchId = ref.watch(branchIdProvider);
  return ref.watch(branchServiceProvider).billSettings(branchId);
});

final usersProvider = FutureProvider.autoDispose<List<ShopUser>>(
  (ref) => ref.watch(userServiceProvider).list(),
);
