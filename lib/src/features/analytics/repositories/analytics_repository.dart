import '../../../database/database_helper.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._db);
  final DatabaseHelper _db;

  Future<Map<String, dynamic>> summary() async {
    final db = await _db.database;
    final inventory = await db.rawQuery('SELECT COALESCE(SUM(quantity * purchase_price), 0) v FROM parts');
    final partsRevenue = await db.rawQuery('SELECT COALESCE(SUM(quantity_used * p.selling_price),0) v FROM part_usage pu JOIN parts p ON p.id = pu.part_id');
    final repairRevenue = await db.rawQuery('SELECT COALESCE(SUM(service_charge),0) v FROM invoices');
    return {
      'inventoryValue': (inventory.first['v'] as num).toDouble(),
      'partsRevenue': (partsRevenue.first['v'] as num).toDouble(),
      'repairRevenue': (repairRevenue.first['v'] as num).toDouble(),
    };
  }
}
