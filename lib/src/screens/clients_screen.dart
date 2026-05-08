import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/client_card.dart';
import '../components/custom_search_bar.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../provider/client_provider.dart';
import '../utils/date_utils.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: CustomSearchBar(
              hintText: 'Search by name or phone',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final filtered = _searchQuery.isEmpty
              ? all
              : all.where((c) {
                  final name = (c['name'] ?? '').toString().toLowerCase();
                  final phone = (c['phone'] ?? '').toString();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      phone.contains(_searchQuery);
                }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientsProvider),
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No clients found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return ClientCard(
                        data: c,
                        onEdit: () => _showEditDialog(context, c),
                        onDelete: () =>
                            _showDeleteDialog(context, c),
                        onViewHistory: () =>
                            _showClientHistory(context, c),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  // ── Edit Dialog ───────────────────────────────────────────────────────────

  void _showEditDialog(BuildContext context, Map<String, dynamic> data) {
    final nameCtrl =
        TextEditingController(text: data['name'] as String? ?? '');
    final phoneCtrl =
        TextEditingController(text: data['phone'] as String? ?? '');
    final addressCtrl =
        TextEditingController(text: data['address'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Client'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final updated = Client(
                id: (data['id'] as num?)?.toInt(),
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty
                    ? null
                    : phoneCtrl.text.trim(),
                address: addressCtrl.text.trim().isEmpty
                    ? null
                    : addressCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              try {
                await DatabaseHelper.instance.updateClient(updated);
                ref.invalidate(clientsProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Client updated successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating client: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Delete Dialog ─────────────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Delete "${data['name']}"?\n\nThis will also permanently delete all their invoices.',
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
              final clientId = (data['id'] as num).toInt();
              Navigator.pop(ctx);
              try {
                await DatabaseHelper.instance.deleteClient(clientId);
                ref.invalidate(clientsProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client and all their invoices deleted'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting client: $e'),
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

  // ── Invoice History Sheet ─────────────────────────────────────────────────

  void _showClientHistory(BuildContext context, Map<String, dynamic> data) {
    final clientId = (data['id'] as num).toInt();
    final clientName = data['name'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance
                    .getInvoicesByClientId(clientId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final invoices = snap.data ?? [];
                  if (invoices.isEmpty) {
                    return const Center(
                      child: Text('No invoices for this client.'),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final inv = invoices[i];
                      final date =
                          DateTime.parse(inv['date'] as String);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Colors.indigo.withOpacity(0.1),
                          child: Text(
                            '#${inv['id']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          formatInvoiceDate(date),
                          style:
                              const TextStyle(fontSize: 13),
                        ),
                        trailing: Text(
                          '₹${inv['total_amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

