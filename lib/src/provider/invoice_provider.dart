import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

/// All invoices (recent). Re-fetched whenever invalidated.
final invoicesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => DatabaseHelper.instance.getRecentInvoices(),
);

/// Currently selected invoice row (for long-press actions).
final selectedInvoiceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
