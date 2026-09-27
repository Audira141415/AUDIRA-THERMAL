import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('audira_receipt.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Receipts Table
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        received_from TEXT NOT NULL,
        amount REAL NOT NULL,
        amount_words TEXT NOT NULL,
        description TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Company Table
    await db.execute('''
      CREATE TABLE company (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        logo TEXT
      )
    ''');

    // 3. Printer Table
    await db.execute('''
      CREATE TABLE printer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mac_address TEXT NOT NULL,
        paper_size TEXT,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Settings Table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_prefix TEXT DEFAULT '${AppConstants.defaultReceiptPrefix}',
        last_receipt_number INTEGER DEFAULT 0,
        paper_size TEXT DEFAULT '${AppConstants.paper58mm}',
        auto_cut INTEGER DEFAULT 1,
        print_logo INTEGER DEFAULT 0,
        print_density INTEGER DEFAULT 2,
        character_size TEXT DEFAULT 'normal'
      )
    ''');

    // Seed Initial Company
    await db.insert('company', {
      'id': 1,
      'name': AppConstants.defaultCompanyName,
      'address': AppConstants.defaultCompanyAddress,
      'phone': AppConstants.defaultCompanyPhone,
      'email': AppConstants.defaultCompanyEmail,
      'logo': null,
    });

    // Seed Initial Settings
    await db.insert('settings', {
      'id': 1,
      'receipt_prefix': AppConstants.defaultReceiptPrefix,
      'last_receipt_number': 0,
      'paper_size': AppConstants.paper58mm,
      'auto_cut': 1,
      'print_logo': 0,
      'print_density': 2,
      'character_size': 'normal',
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
