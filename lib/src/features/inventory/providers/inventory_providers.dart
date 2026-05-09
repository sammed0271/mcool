import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_helper.dart';
import '../models/part.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(DatabaseHelper.instance);
});

final inventorySearchProvider = StateProvider<String>((ref) => '');

final inventoryPartsProvider = FutureProvider<List<Part>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final query = ref.watch(inventorySearchProvider);
  return repo.getParts(query: query);
});

final lowStockProvider = FutureProvider<List<Part>>((ref) async {
  return ref.watch(inventoryRepositoryProvider).getLowStockParts();
});

final inventoryValueProvider = FutureProvider<double>((ref) async {
  return ref.watch(inventoryRepositoryProvider).getInventoryValue();
});
