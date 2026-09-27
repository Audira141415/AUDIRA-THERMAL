import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/database/database.dart';
import 'package:audira_receipt/models/app_settings.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/thermal_printer.dart';
import 'package:sqflite/sqflite.dart';

class ReceiptRepository {
  final AppDatabase _dbProvider;

  ReceiptRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  // ==========================================
  // RECEIPTS
  // ==========================================

  Future<Receipt> insertReceipt(Receipt receipt) async {
    final db = await _db;
    final id = await db.insert(
      'receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update settings last_receipt_number if applicable
    await _updateLastReceiptNumber(receipt.receiptNumber);

    return receipt.copyWith(id: id);
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await _db;
    return await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await _db;
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Receipt?> getReceiptById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Receipt.fromMap(maps.first);
    }
    return null;
  }

  Future<Receipt?> getReceiptByNumber(String receiptNumber) async {
    final db = await _db;
    final maps = await db.query(
      'receipts',
      where: 'receipt_number = ?',
      whereArgs: [receiptNumber],
    );
    if (maps.isNotEmpty) {
      return Receipt.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Receipt>> getAllReceipts({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      whereClause += '(receipt_number LIKE ? OR received_from LIKE ? OR description LIKE ?)';
      final pattern = '%${query.trim()}%';
      whereArgs.addAll([pattern, pattern, pattern]);
    }

    if (startDate != null) {
      final startIso = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0).toIso8601String();
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startIso);
    }

    if (endDate != null) {
      final endIso = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endIso);
    }

    final maps = await db.query(
      'receipts',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );

    return maps.map((e) => Receipt.fromMap(e)).toList();
  }

  Future<List<Receipt>> getTodayReceipts() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getAllReceipts(startDate: startOfDay, endDate: endOfDay);
  }

  Future<int> getTodayCount() async {
    final receipts = await getTodayReceipts();
    return receipts.length;
  }

  Future<double> getTodayTotalAmount() async {
    final receipts = await getTodayReceipts();
    return receipts.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Generates the next sequential receipt number, e.g. "AUD-2026-00001"
  /// Guarantees no collisions by checking both settings and highest existing receipt number
  Future<String> generateNextReceiptNumber() async {
    final db = await _db;
    final settings = await getSettings();
    final prefix = settings.receiptPrefix.trim().isEmpty
        ? AppConstants.defaultReceiptPrefix
        : settings.receiptPrefix.trim();
    final currentYear = DateTime.now().year;
    final yearPattern = '$prefix-$currentYear-%';

    // Query highest number matching pattern in database
    final result = await db.rawQuery('''
      SELECT receipt_number FROM receipts 
      WHERE receipt_number LIKE ? 
      ORDER BY id DESC LIMIT 1
    ''', [yearPattern]);

    int nextSequence = 1;

    if (result.isNotEmpty) {
      final lastNumStr = result.first['receipt_number'] as String;
      final parts = lastNumStr.split('-');
      if (parts.length >= 3) {
        final seq = int.tryParse(parts.last) ?? 0;
        nextSequence = seq + 1;
      }
    }

    // Also check settings lastReceiptNumber
    if (settings.lastReceiptNumber >= nextSequence) {
      nextSequence = settings.lastReceiptNumber + 1;
    }

    final formattedSeq = nextSequence.toString().padLeft(AppConstants.receiptNumberLength, '0');
    return '$prefix-$currentYear-$formattedSeq';
  }

  Future<void> _updateLastReceiptNumber(String receiptNumber) async {
    try {
      final parts = receiptNumber.split('-');
      if (parts.length >= 3) {
        final seq = int.tryParse(parts.last);
        if (seq != null) {
          final db = await _db;
          await db.rawUpdate('''
            UPDATE settings 
            SET last_receipt_number = ? 
            WHERE id = 1 AND last_receipt_number < ?
          ''', [seq, seq]);
        }
      }
    } catch (_) {}
  }

  // ==========================================
  // COMPANY PROFILE
  // ==========================================

  Future<Company> getCompany() async {
    final db = await _db;
    final maps = await db.query('company', where: 'id = 1');
    if (maps.isNotEmpty) {
      return Company.fromMap(maps.first);
    }
    final defaultComp = Company.defaultCompany();
    await db.insert('company', defaultComp.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return defaultComp;
  }

  Future<int> updateCompany(Company company) async {
    final db = await _db;
    return await db.update(
      'company',
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id ?? 1],
    );
  }

  // ==========================================
  // SETTINGS
  // ==========================================

  Future<AppSettings> getSettings() async {
    final db = await _db;
    final maps = await db.query('settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      return AppSettings.fromMap(maps.first);
    }
    final defaultSet = AppSettings.defaultSettings();
    await db.insert('settings', defaultSet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return defaultSet;
  }

  Future<int> updateSettings(AppSettings settings) async {
    final db = await _db;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id ?? 1],
    );
  }

  // ==========================================
  // PRINTERS
  // ==========================================

  Future<List<ThermalPrinter>> getPrinters() async {
    final db = await _db;
    final maps = await db.query('printer', orderBy: 'is_default DESC, name ASC');
    return maps.map((e) => ThermalPrinter.fromMap(e)).toList();
  }

  Future<ThermalPrinter?> getDefaultPrinter() async {
    final db = await _db;
    final maps = await db.query('printer', where: 'is_default = 1', limit: 1);
    if (maps.isNotEmpty) {
      return ThermalPrinter.fromMap(maps.first);
    }
    final anyPrinter = await db.query('printer', limit: 1);
    if (anyPrinter.isNotEmpty) {
      return ThermalPrinter.fromMap(anyPrinter.first);
    }
    return null;
  }

  Future<ThermalPrinter> savePrinter(ThermalPrinter printer) async {
    final db = await _db;
    if (printer.isDefault) {
      await db.update('printer', {'is_default': 0});
    }

    final existing = await db.query(
      'printer',
      where: 'mac_address = ?',
      whereArgs: [printer.macAddress],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'printer',
        printer.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return printer.copyWith(id: id);
    } else {
      final id = await db.insert('printer', printer.toMap());
      return printer.copyWith(id: id);
    }
  }

  Future<void> setDefaultPrinter(String macAddress) async {
    final db = await _db;
    await db.update('printer', {'is_default': 0});
    await db.update(
      'printer',
      {'is_default': 1},
      where: 'mac_address = ?',
      whereArgs: [macAddress],
    );
  }

  Future<int> deletePrinter(int id) async {
    final db = await _db;
    return await db.delete('printer', where: 'id = ?', whereArgs: [id]);
  }
}
