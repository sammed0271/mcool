import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final DateTime date;
  final VoidCallback onLongPress;

  const InvoiceCard({
    super.key,
    required this.item,
    required this.date,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.indigo),
        ),
        title: Text(
          '#${item['id'] ?? '0'}  ${item['client_name'] ?? 'Unknown'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formatInvoiceDate(date)),
        trailing: Text(
          '₹${item['total_amount']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
