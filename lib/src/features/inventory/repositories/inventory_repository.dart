import 'package:sqflite/sqflite.dart';

import '../../../database/database_helper.dart';
import '../models/part.dart';
import '../models/part_usage.dart';

class InventoryRepository {
  InventoryRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<Part>> getParts({String query = ''}) async {
    final db = await _dbHelper.database;
    if (query.trim().isEmpty) {
      final rows = await db.query('parts', orderBy: 'name');
      return rows.map(Part.fromMap).toList();
    }
    final q = '%${query.trim()}%';
    final rows = await db.query('parts', where: 'part_number LIKE ? OR name LIKE ? OR appliance_type LIKE ? OR category LIKE ? OR brand LIKE ?', whereArgs: [q, q, q, q, q], orderBy: 'name');
    return rows.map(Part.fromMap).toList();
  }

  Future<int> upsertPart(Part part) async {
    final db = await _dbHelper.database;
    final map = part.toMap()..remove('id');
    if (part.id == null) return db.insert('parts', map);
    await db.update('parts', map, where: 'id = ?', whereArgs: [part.id]);
    return part.id!;
  }

  Future<List<Part>> getLowStockParts() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT * FROM parts WHERE quantity <= minimum_stock ORDER BY quantity ASC');
    return rows.map(Part.fromMap).toList();
  }

  Future<void> consumeParts({required int invoiceId, required List<PartUsage> usages}) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final usage in usages) {
        final row = await txn.query('parts', columns: ['quantity'], where: 'id = ?', whereArgs: [usage.partId]);
        final currentQty = (row.first['quantity'] as num).toInt();
        if (currentQty < usage.quantityUsed) {
          throw Exception('Insufficient stock for part ${usage.partId}');
        }
        await txn.update('parts', {'quantity': currentQty - usage.quantityUsed, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [usage.partId]);
        await txn.insert('part_usage', usage.toMap()..['invoice_id'] = invoiceId);
        await txn.insert('inventory_transactions', {'part_id': usage.partId, 'transaction_type': 'consume', 'quantity_change': -usage.quantityUsed, 'reference_id': invoiceId, 'notes': usage.technicianNotes, 'created_at': DateTime.now().toIso8601String()});
      }
    });
  }

  Future<double> getInventoryValue() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT COALESCE(SUM(quantity * purchase_price), 0) AS value FROM parts');
    return (rows.first['value'] as num).toDouble();
  }
}
