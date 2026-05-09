import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/client.dart';
import '../models/invoice.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('repair_billing.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Clients Table
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT
      )
    ''');

    // 2. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT DEFAULT 'Paid',
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    // 3. Invoice Items (Parts or Services)
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        description TEXT NOT NULL,
        qty INTEGER DEFAULT 1,
        price REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await _createPhase2Tables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPhase2Tables(db);
      await db.execute("ALTER TABLE invoices ADD COLUMN appliance_type TEXT DEFAULT 'Refrigerator'");
      await db.execute("ALTER TABLE invoices ADD COLUMN appliance_details TEXT");
      await db.execute("ALTER TABLE invoices ADD COLUMN service_charge REAL DEFAULT 0");
      await db.execute("ALTER TABLE invoices ADD COLUMN parts_cost REAL DEFAULT 0");
    }
  }

  Future<void> _createPhase2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        appliance_type TEXT NOT NULL,
        brand TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        minimum_stock INTEGER NOT NULL DEFAULT 0,
        purchase_price REAL NOT NULL DEFAULT 0,
        selling_price REAL NOT NULL DEFAULT 0,
        supplier TEXT,
        location TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS part_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        repair_id INTEGER,
        part_id INTEGER NOT NULL,
        quantity_used INTEGER NOT NULL,
        used_at TEXT NOT NULL,
        technician_notes TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        reference_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_parts_part_number ON parts(part_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_parts_appliance_type ON parts(appliance_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_parts_category ON parts(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_part_usage_invoice ON part_usage(invoice_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_transactions_part ON inventory_transactions(part_id)');
  }

  // --- DASHBOARD QUERIES ---

  // Get Total Earnings for the Dashboard
  // Future<double> getTotalEarnings() async {
  //   final db = await instance.database;
  //   var result = await db.rawQuery(
  //     'SELECT SUM(total_amount) as total FROM invoices',
  //   );
  //   return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  // }

  // Get Recent Invoices with Client Names
  Future<List<Map<String, dynamic>>> getRecentInvoices() async {
    final db = await instance.database;
    // We use a JOIN here to get the client's name directly for the dashboard list
    return await db.rawQuery('''
      SELECT invoices.*, clients.name as client_name 
      FROM invoices 
      JOIN clients ON invoices.client_id = clients.id 
      ORDER BY date DESC 
      LIMIT 10
    ''');
  }

  // --- INVOICE CREATION ---
  Future<int> createFullInvoice(Client client, List<InvoiceItem> items) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      // 1. Insert Client (or get existing)
      int clientId = await txn.insert('clients', client.toMap());

      // 2. Calculate Total
      double total = items.fold(
        0,
        (sum, item) => sum + (item.price * item.qty),
      );

      // 3. Insert Invoice
      int invoiceId = await txn.insert('invoices', {
        'client_id': clientId,
        'date': DateTime.now().toIso8601String(),
        'total_amount': total,
        'status': 'Paid',
      });

      // 4. Insert All Items
      for (var item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'description': item.description,
          'qty': item.qty,
          'price': item.price,
        });
      }

      return invoiceId;
    });
  }

  /// Creates an invoice (+ items) for an already-existing client by ID.
  Future<int> createInvoiceForExistingClient(
    int clientId,
    List<InvoiceItem> items,
  ) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final double total =
          items.fold(0, (s, i) => s + i.price * i.qty);

      final int invoiceId = await txn.insert('invoices', {
        'client_id': clientId,
        'date': DateTime.now().toIso8601String(),
        'total_amount': total,
        'status': 'Paid',
      });

      for (final item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'description': item.description,
          'qty': item.qty,
          'price': item.price,
        });
      }

      return invoiceId;
    });
  }


  Future<List<Map<String, dynamic>>> getAllClients() async {
    final db = await instance.database;
    // Include invoice count and total spend per client
    return await db.rawQuery('''
      SELECT clients.*,
             COUNT(invoices.id) as invoice_count,
             COALESCE(SUM(invoices.total_amount), 0) as total_spent
      FROM clients
      LEFT JOIN invoices ON clients.id = invoices.client_id
      GROUP BY clients.id
      ORDER BY clients.name
    ''');
  }

  Future<List<Client>> searchClients(String query) async {
    final db = await instance.database;
    final q = '%$query%';
    final maps = await db.rawQuery(
      "SELECT * FROM clients WHERE name LIKE ? OR phone LIKE ? ORDER BY name LIMIT 8",
      [q, q],
    );
    return maps.map(Client.fromMap).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await instance.database;
    // ON DELETE CASCADE removes invoices and their items automatically
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getInvoicesByClientId(int clientId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT invoices.*
      FROM invoices
      WHERE invoices.client_id = ?
      ORDER BY date DESC
    ''', [clientId]);
  }

  Future<Client> getClientById(int id) async {
    final db = await instance.database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    } else {
      throw Exception('Client with id $id not found');
    }
  }

  // Get a single invoice with its items and embedded client
  Future<Invoice> getInvoiceById(int id) async {
    final db = await instance.database;

    // 1. Fetch invoice row
    final invoiceMaps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (invoiceMaps.isEmpty) throw Exception('Invoice with id $id not found');
    final invoiceMap = invoiceMaps.first;

    // 2. Fetch items
    final itemMaps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    final items = itemMaps.map((m) => InvoiceItem.fromMap(m)).toList();

    // 3. Fetch client
    final client = await getClientById(invoiceMap['client_id'] as int);

    return Invoice.fromMap(invoiceMap, client, items);
  }

  // Inside DatabaseHelper class
  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    // ON DELETE CASCADE in our schema ensures items are also removed

    return await db.transaction((txn) async {
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
