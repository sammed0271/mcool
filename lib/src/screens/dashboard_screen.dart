import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/invoice_card.dart';
import '../database/database_helper.dart';
import '../provider/invoice_provider.dart';
import '../screens/invoice_preview_screen.dart';
import '../screens/new_invoice_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Service Dashboard")),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoices) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(invoicesProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent Invoices",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (invoices.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        "No bills generated yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  _buildInvoiceList(context, ref, invoices),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewInvoiceScreen()),
        ),
        label: const Text("New Bill"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> invoices,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = invoices[index];
        final date = DateTime.parse(item['date']);
        return InvoiceCard(
          item: item,
          date: date,
          onLongPress: () {
            ref.read(selectedInvoiceProvider.notifier).state = item;
            _showActionSheet(context, ref);
          },
        );
      },
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
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
              onTap: () => _showDeleteConfirmation(context, ref, sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, BuildContext sheetCtx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to remove this invoice? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final id =
                  (ref.read(selectedInvoiceProvider)?['id'] as num?)?.toInt();
              ref.read(selectedInvoiceProvider.notifier).state = null;
              Navigator.pop(ctx); // close dialog
              Navigator.pop(sheetCtx); // close bottom sheet
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
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

