import 'package:flutter/material.dart';

class ClientCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const ClientCard({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unknown';
    final phone = data['phone'] as String?;
    final invoiceCount = (data['invoice_count'] as num?)?.toInt() ?? 0;
    final totalSpent = (data['total_spent'] as num?)?.toDouble() ?? 0.0;
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onViewHistory,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with initials
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.indigo.withOpacity(0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (phone != null)
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          icon: Icons.receipt_long_outlined,
                          label: '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}',
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.currency_rupee,
                          label: totalSpent.toStringAsFixed(0),
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.indigo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
