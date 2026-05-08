import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/custom_search_bar.dart';
import '../components/invoice_card.dart';
import '../database/database_helper.dart';
import '../provider/invoice_provider.dart';
import 'invoice_preview_screen.dart';
import 'new_invoice_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: CustomSearchBar(
              hintText: 'Search by name or invoice #',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allInvoices) {
          final filtered = _searchQuery.isEmpty
              ? allInvoices
              : allInvoices.where((inv) {
                  final name =
                      (inv['client_name'] ?? '').toString().toLowerCase();
                  final id = inv['id'].toString();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      id.contains(_searchQuery);
                }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No invoices found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final date = DateTime.parse(item['date'] as String);
                      return InvoiceCard(
                        item: item,
                        date: date,
                        onLongPress: () {
                          ref.read(selectedInvoiceProvider.notifier).state =
                              item;
                          _showActionSheet(context);
                        },
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewInvoiceScreen()),
        ),
        label: const Text('New Bill'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print / Share Receipt'),
              onTap: () async {
                final selected = ref.read(selectedInvoiceProvider);
                ref.read(selectedInvoiceProvider.notifier).state = null;
                Navigator.pop(sheetCtx);
                if (selected == null) return;
                final invoiceId = (selected['id'] as num).toInt();
                try {
                  final invoice =
                      await DatabaseHelper.instance.getInvoiceById(invoiceId);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePreviewScreen(invoice: invoice),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not load invoice: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Invoice',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to remove this invoice? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final id = (ref.read(selectedInvoiceProvider)?['id'] as num?)
                  ?.toInt();
              ref.read(selectedInvoiceProvider.notifier).state = null;
              Navigator.pop(ctx);
              if (id == null) return;
              try {
                await DatabaseHelper.instance.deleteInvoice(id);
                ref.invalidate(invoicesProvider);
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Invoice deleted successfully')),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting invoice: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

