import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(inventoryPartsProvider);
    final lowStockAsync = ref.watch(lowStockProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by part number, category, brand...'),
              onChanged: (v) => ref.read(inventorySearchProvider.notifier).state = v,
            ),
            const SizedBox(height: 12),
            lowStockAsync.when(data: (low) => Align(alignment: Alignment.centerLeft, child: Text('Low stock items: ${low.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))), loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink()),
            const SizedBox(height: 12),
            Expanded(
              child: partsAsync.when(
                data: (parts) => ListView.builder(
                  itemCount: parts.length,
                  itemBuilder: (_, i) {
                    final p = parts[i];
                    return ListTile(
                      title: Text('${p.partNumber} · ${p.name}'),
                      subtitle: Text('${p.applianceType} · ${p.category} · Qty ${p.quantity}'),
                      trailing: p.isLowStock ? const Icon(Icons.warning_amber, color: Colors.red) : null,
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
