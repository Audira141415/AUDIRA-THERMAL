import 'dart:convert';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/database/database.dart';
import 'package:audira_receipt/models/app_settings.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/product.dart';
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
  // COMPANY PROFILES (MULTI-COMPANY / MULTI-STORE)
  // ==========================================

  Future<List<Company>> getAllCompanies() async {
    final db = await _db;
    final maps = await db.query('company', orderBy: 'id ASC');
    if (maps.isEmpty) {
      final defaultComp = Company.defaultCompany();
      await db.insert('company', defaultComp.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return [defaultComp];
    }
    return maps.map((m) => Company.fromMap(m)).toList();
  }

  Future<Company> getCompany({int? id}) async {
    final db = await _db;
    final maps = await db.query(
      'company',
      where: id != null ? 'id = ?' : null,
      whereArgs: id != null ? [id] : null,
      orderBy: 'id ASC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Company.fromMap(maps.first);
    }
    final defaultComp = Company.defaultCompany();
    await db.insert('company', defaultComp.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return defaultComp;
  }

  Future<Company> insertCompany(Company company) async {
    final db = await _db;
    final id = await db.insert(
      'company',
      company.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return company.copyWith(id: id);
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

  Future<int> deleteCompany(int id) async {
    final db = await _db;
    return await db.delete(
      'company',
      where: 'id = ?',
      whereArgs: [id],
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

  // ==========================================
  // ULTIMATE FEATURES: AUTOCOMPLETE, ANALYTICS & BACKUP
  // ==========================================

  /// Get list of unique customer names for form autocomplete
  Future<List<String>> getAllCustomerNames() async {
    try {
      final db = await _db;
      final results = await db.rawQuery(
        'SELECT DISTINCT received_from FROM receipts WHERE received_from IS NOT NULL AND received_from != "" ORDER BY received_from ASC',
      );
      return results.map((r) => r['received_from'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get comprehensive financial summary for analytics
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final db = await _db;
    try {
      final totalRes = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(amount) as total, AVG(amount) as avg, MAX(amount) as max FROM receipts',
      );
      final row = totalRes.first;
      final count = row['count'] as int? ?? 0;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final avg = (row['avg'] as num?)?.toDouble() ?? 0.0;
      final max = (row['max'] as num?)?.toDouble() ?? 0.0;

      final byPaymentRes = await db.rawQuery(
        'SELECT payment_method, COUNT(*) as count, SUM(amount) as total FROM receipts GROUP BY payment_method ORDER BY total DESC',
      );

      return {
        'count': count,
        'total': total,
        'average': avg,
        'max': max,
        'byPayment': byPaymentRes,
      };
    } catch (e) {
      return {
        'count': 0,
        'total': 0.0,
        'average': 0.0,
        'max': 0.0,
        'byPayment': <Map<String, dynamic>>[],
      };
    }
  }

  /// Export receipts into standard CSV text format
  Future<String> exportReceiptsToCsv({DateTime? startDate, DateTime? endDate}) async {
    final receipts = await getAllReceipts(startDate: startDate, endDate: endDate);
    final buffer = StringBuffer();
    buffer.writeln('No Kwitansi,Tanggal,Diterima Dari,Nominal,Terbilang,Untuk Pembayaran,Metode Bayar,Status,Catatan');
    for (final r in receipts) {
      final cleanDesc = r.description.replaceAll('"', '""').replaceAll('\n', ' ');
      final cleanNotes = (r.notes ?? '').replaceAll('"', '""').replaceAll('\n', ' ');
      final cleanFrom = r.receivedFrom.replaceAll('"', '""');
      buffer.writeln('${r.receiptNumber},${r.dateFormatted},"$cleanFrom",${r.amount},"${r.amountWords}","$cleanDesc","${r.paymentMethod}","${r.status}","$cleanNotes"');
    }
    return buffer.toString();
  }

  /// Export entire database into a JSON string backup
  Future<String> exportDatabaseJson() async {
    final receipts = await getAllReceipts();
    final companies = await getAllCompanies();
    final company = await getCompany();
    final settings = await getSettings();
    final printers = await getPrinters();

    final data = {
      'app': 'AUDIRA RECEIPT',
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'company': company.toMap(),
      'companies': companies.map((c) => c.toMap()).toList(),
      'settings': settings.toMap(),
      'printers': printers.map((p) => p.toMap()).toList(),
      'receipts': receipts.map((r) => r.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restore database from JSON backup string
  Future<int> importDatabaseJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final db = await _db;
    int importedCount = 0;

    if (data['companies'] != null) {
      final compList = data['companies'] as List;
      for (final item in compList) {
        final cMap = Map<String, dynamic>.from(item as Map);
        await db.insert('company', cMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } else if (data['company'] != null) {
      final compMap = Map<String, dynamic>.from(data['company'] as Map);
      await updateCompany(Company.fromMap(compMap));
    }

    if (data['settings'] != null) {
      final setMap = Map<String, dynamic>.from(data['settings'] as Map);
      await updateSettings(AppSettings.fromMap(setMap));
    }

    if (data['receipts'] != null) {
      final list = data['receipts'] as List;
      for (final item in list) {
        final rMap = Map<String, dynamic>.from(item as Map);
        await db.insert('receipts', rMap, conflictAlgorithm: ConflictAlgorithm.replace);
        importedCount++;
      }
    }

    return importedCount;
  }

  /// Reset / delete all receipts
  Future<int> clearAllReceipts() async {
    final db = await _db;
    return await db.delete('receipts');
  }

  // ==========================================
  // PRODUCTS (Master Katalog Barang & Jasa)
  // ==========================================

  Future<Product> insertProduct(Product product) async {
    final db = await _db;
    final id = await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return product.copyWith(id: id);
  }

  Future<int> updateProduct(Product product) async {
    final db = await _db;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _db;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getAllProducts({String? query, String? category}) async {
    final db = await _db;
    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      whereClause += '(name LIKE ? OR code LIKE ?)';
      final pattern = '%${query.trim()}%';
      whereArgs.addAll([pattern, pattern]);
    }

    if (category != null && category.trim().isNotEmpty && category != 'Semua') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category.trim());
    }

    final maps = await db.query(
      'products',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<String>> getProductCategories() async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != "" ORDER BY category ASC');
    final list = maps.map((m) => m['category'] as String).toList();
    if (!list.contains('Umum')) list.insert(0, 'Umum');
    return list;
  }
}
