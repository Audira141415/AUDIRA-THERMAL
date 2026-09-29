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
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        customer_phone TEXT,
        cashier_name TEXT,
        amount REAL NOT NULL,
        amount_words TEXT NOT NULL,
        description TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT DEFAULT 'LUNAS',
        notes TEXT,
        template_id TEXT DEFAULT 'standard_formal',
        discount REAL DEFAULT 0.0,
        tax REAL DEFAULT 0.0,
        cash_received REAL DEFAULT 0.0,
        change_amount REAL DEFAULT 0.0,
        due_date TEXT,
        items_json TEXT DEFAULT '[]',
        store_name TEXT,
        store_address TEXT,
        store_phone TEXT,
        store_tagline TEXT,
        store_legal_id TEXT,
        logo_path TEXT,
        show_logo INTEGER DEFAULT 1,
        show_barcode INTEGER DEFAULT 1,
        barcode_data TEXT,
        header_align TEXT DEFAULT 'center',
        title_align TEXT DEFAULT 'center',
        content_align TEXT DEFAULT 'left',
        amount_align TEXT DEFAULT 'left',
        stamp_align TEXT DEFAULT 'right',
        title_font_size TEXT DEFAULT 'large',
        amount_font_size TEXT DEFAULT 'large',
        is_bold_title INTEGER DEFAULT 1,
        is_bold_amount INTEGER DEFAULT 1,
        is_condensed INTEGER DEFAULT 0,
        stamp_type TEXT DEFAULT 'LUNAS',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Company Table
    await db.execute('''
      CREATE TABLE company (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        tagline TEXT DEFAULT 'MULTIMEDIA DIGITAL',
        address TEXT,
        phone TEXT,
        email TEXT,
        logo TEXT,
        footer_message TEXT DEFAULT 'Terima kasih atas kepercayaan Anda',
        bank_info TEXT DEFAULT '',
        signer_name TEXT DEFAULT ''
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
        character_size TEXT DEFAULT 'normal',
        active_template_id TEXT DEFAULT 'standard_formal',
        template_configs_json TEXT DEFAULT '{}'
      )
    ''');

    // 5. Products Table (Master Data Katalog Barang / Jasa)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT,
        name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        category TEXT DEFAULT 'Umum',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Seed Starter Products
    final nowIso = DateTime.now().toIso8601String();
    await db.insert('products', {
      'code': 'SRV-01',
      'name': 'Jasa / Layanan Standar',
      'unit_price': 50000.0,
      'category': 'Jasa',
      'created_at': nowIso,
      'updated_at': nowIso,
    });
    await db.insert('products', {
      'code': 'BRG-01',
      'name': 'Produk Barang Umum',
      'unit_price': 25000.0,
      'category': 'Barang',
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    // Seed Initial Companies (Multi-Company Starter Profiles)
    await db.insert('company', {
      'id': 1,
      'name': AppConstants.defaultCompanyName,
      'tagline': 'MULTIMEDIA DIGITAL',
      'address': AppConstants.defaultCompanyAddress,
      'phone': AppConstants.defaultCompanyPhone,
      'email': AppConstants.defaultCompanyEmail,
      'logo': null,
      'footer_message': 'Terima kasih atas kepercayaan Anda',
    });
    await db.insert('company', {
      'id': 2,
      'name': 'Toko Retail & Grosir Berkah',
      'tagline': 'Pusat Belanja Hemat & Sembako Murah',
      'address': 'Pasar Induk Blok B No. 15',
      'phone': '0812-3456-7890',
      'email': 'toko.berkah@gmail.com',
      'logo': null,
      'footer_message': 'Terima kasih atas kunjungan Anda',
    });
    await db.insert('company', {
      'id': 3,
      'name': 'Kedai Kopi & Resto Senja',
      'tagline': 'Coffee, Eatery & Working Space',
      'address': 'Jl. Melati No. 45, Bandung',
      'phone': '0821-9876-5432',
      'email': 'senja.coffee@gmail.com',
      'logo': null,
      'footer_message': 'Selamat menikmati hidangan kami',
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
      'active_template_id': 'standard_formal',
      'template_configs_json': '{}',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE receipts ADD COLUMN status TEXT DEFAULT 'LUNAS'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE company ADD COLUMN tagline TEXT DEFAULT 'MULTIMEDIA DIGITAL'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE company ADD COLUMN footer_message TEXT DEFAULT 'Terima kasih atas kepercayaan Anda'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE company ADD COLUMN bank_info TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE company ADD COLUMN signer_name TEXT DEFAULT ''");
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN active_template_id TEXT DEFAULT 'standard_formal'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN template_configs_json TEXT DEFAULT '{}'");
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE receipts ADD COLUMN template_id TEXT DEFAULT 'standard_formal'");
      } catch (_) {}
    }
    if (oldVersion < 5) {
      final columns = [
        "ALTER TABLE receipts ADD COLUMN customer_phone TEXT",
        "ALTER TABLE receipts ADD COLUMN cashier_name TEXT",
        "ALTER TABLE receipts ADD COLUMN discount REAL DEFAULT 0.0",
        "ALTER TABLE receipts ADD COLUMN tax REAL DEFAULT 0.0",
        "ALTER TABLE receipts ADD COLUMN cash_received REAL DEFAULT 0.0",
        "ALTER TABLE receipts ADD COLUMN change_amount REAL DEFAULT 0.0",
        "ALTER TABLE receipts ADD COLUMN due_date TEXT",
        "ALTER TABLE receipts ADD COLUMN items_json TEXT DEFAULT '[]'",
        "ALTER TABLE receipts ADD COLUMN header_align TEXT DEFAULT 'center'",
        "ALTER TABLE receipts ADD COLUMN title_align TEXT DEFAULT 'center'",
        "ALTER TABLE receipts ADD COLUMN content_align TEXT DEFAULT 'left'",
        "ALTER TABLE receipts ADD COLUMN amount_align TEXT DEFAULT 'left'",
        "ALTER TABLE receipts ADD COLUMN stamp_align TEXT DEFAULT 'right'",
        "ALTER TABLE receipts ADD COLUMN title_font_size TEXT DEFAULT 'large'",
        "ALTER TABLE receipts ADD COLUMN amount_font_size TEXT DEFAULT 'large'",
        "ALTER TABLE receipts ADD COLUMN is_bold_title INTEGER DEFAULT 1",
        "ALTER TABLE receipts ADD COLUMN is_bold_amount INTEGER DEFAULT 1",
        "ALTER TABLE receipts ADD COLUMN is_condensed INTEGER DEFAULT 0",
        "ALTER TABLE receipts ADD COLUMN stamp_type TEXT DEFAULT 'LUNAS'",
      ];
      for (final col in columns) {
        try {
          await db.execute(col);
        } catch (_) {}
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT,
            name TEXT NOT NULL,
            unit_price REAL NOT NULL,
            category TEXT DEFAULT 'Umum',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      final columns = [
        "ALTER TABLE receipts ADD COLUMN store_name TEXT",
        "ALTER TABLE receipts ADD COLUMN store_address TEXT",
        "ALTER TABLE receipts ADD COLUMN store_phone TEXT",
        "ALTER TABLE receipts ADD COLUMN store_tagline TEXT",
        "ALTER TABLE receipts ADD COLUMN store_legal_id TEXT",
      ];
      for (final col in columns) {
        try {
          await db.execute(col);
        } catch (_) {}
      }
      try {
        final compCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM company')) ?? 0;
        if (compCount <= 1) {
          await db.insert('company', {
            'id': 2,
            'name': 'Toko Retail & Grosir Berkah',
            'tagline': 'Pusat Belanja Hemat & Sembako Murah',
            'address': 'Pasar Induk Blok B No. 15',
            'phone': '0812-3456-7890',
            'email': 'toko.berkah@gmail.com',
            'logo': null,
            'footer_message': 'Terima kasih atas kunjungan Anda',
          });
          await db.insert('company', {
            'id': 3,
            'name': 'Kedai Kopi & Resto Senja',
            'tagline': 'Coffee, Eatery & Working Space',
            'address': 'Jl. Melati No. 45, Bandung',
            'phone': '0821-9876-5432',
            'email': 'senja.coffee@gmail.com',
            'logo': null,
            'footer_message': 'Selamat menikmati hidangan kami',
          });
        }
      } catch (_) {}
    }
    if (oldVersion < 8) {
      final columns = [
        "ALTER TABLE receipts ADD COLUMN logo_path TEXT",
        "ALTER TABLE receipts ADD COLUMN show_logo INTEGER DEFAULT 1",
        "ALTER TABLE receipts ADD COLUMN show_barcode INTEGER DEFAULT 1",
        "ALTER TABLE receipts ADD COLUMN barcode_data TEXT",
      ];
      for (final col in columns) {
        try {
          await db.execute(col);
        } catch (_) {}
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
