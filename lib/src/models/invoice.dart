import 'client.dart';

/// Represents a full invoice, including the embedded client and all line items.
class Invoice {
  final int? id;
  final Client client;
  final DateTime date;
  final double totalAmount;
  final List<InvoiceItem> items;

  const Invoice({
    this.id,
    required this.client,
    required this.date,
    required this.totalAmount,
    required this.items,
  });

  /// Creates an [Invoice] from a DB row. A [Client] object must be provided
  /// separately because the `invoices` table only stores `client_id`.
  factory Invoice.fromMap(
    Map<String, dynamic> map,
    Client client,
    List<InvoiceItem> items,
  ) =>
      Invoice(
        id: (map['id'] as num?)?.toInt(),
        client: client,
        date: DateTime.parse(map['date'] as String),
        totalAmount: (map['total_amount'] as num).toDouble(),
        items: items,
      );

  @override
  String toString() =>
      'Invoice(id: $id, client: ${client.name}, total: $totalAmount)';
}

/// A single line item on an invoice.
class InvoiceItem {
  final int? id;
  final String description;
  final int qty;
  final double price;

  double get lineTotal => qty * price;

  const InvoiceItem({
    this.id,
    required this.description,
    this.qty = 1,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'description': description,
        'qty': qty,
        'price': price,
      };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
        id: (map['id'] as num?)?.toInt(),
        description: map['description'] as String,
        qty: (map['qty'] as num?)?.toInt() ?? 1,
        price: (map['price'] as num).toDouble(),
      );

  @override
  String toString() => 'InvoiceItem($description x$qty @ $price)';
}
