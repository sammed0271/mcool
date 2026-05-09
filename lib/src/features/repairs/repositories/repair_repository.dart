import '../../../database/database_helper.dart';

class RepairRepository {
  RepairRepository(this._db);
  final DatabaseHelper _db;

  Future<List<Map<String, dynamic>>> applianceHistory(String applianceType) async {
    final db = await _db.database;
    return db.query('invoices', where: 'appliance_type = ?', whereArgs: [applianceType], orderBy: 'date DESC');
  }
}
