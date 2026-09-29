import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/database/receipt_repository.dart';
import 'package:audira_receipt/models/app_settings.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/product.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';

class ReceiptService extends ChangeNotifier {
  final ReceiptRepository repository;

  List<Receipt> _receipts = [];
  List<Product> _products = [];
  List<Company> _companies = [];
  int _todayCount = 0;
  double _todayTotalAmount = 0.0;
  Company _company = Company.defaultCompany();
  AppSettings _settings = AppSettings.defaultSettings();
  bool _isLoading = false;

  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  ReceiptService({required this.repository});

  List<Receipt> get receipts => _receipts;
  List<Product> get products => _products;
  List<Company> get companies => _companies;
  int get todayCount => _todayCount;
  double get todayTotalAmount => _todayTotalAmount;
  Company get company => _company;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// Load initial data on app startup
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _companies = await repository.getAllCompanies();
      if (_companies.isNotEmpty) {
        _company = _companies.first;
      } else {
        _company = await repository.getCompany();
        _companies = [_company];
      }
      _settings = await repository.getSettings();
      await refreshDashboardStats();
      await refreshReceipts();
      await refreshProducts();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard metrics
  Future<void> refreshDashboardStats() async {
    try {
      _todayCount = await repository.getTodayCount();
      _todayTotalAmount = await repository.getTodayTotalAmount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing dashboard stats: $e');
    }
  }

  /// Refresh receipts with current search and date filters
  Future<void> refreshReceipts() async {
    try {
      _receipts = await repository.getAllReceipts(
        query: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing receipts: $e');
    }
  }

  /// Get the next sequential receipt number
  Future<String> getNextReceiptNumber() async {
    return await repository.generateNextReceiptNumber();
  }

  /// Create and save a new receipt
  Future<Receipt> saveReceipt({
    required String receiptNumber,
    required DateTime date,
    required String receivedFrom,
    String? customerPhone,
    String? cashierName,
    required double amount,
    required String description,
    required String paymentMethod,
    String status = 'LUNAS',
    String? notes,
    String templateId = 'standard_formal',
    double discount = 0.0,
    double tax = 0.0,
    double cashReceived = 0.0,
    double changeAmount = 0.0,
    DateTime? dueDate,
    List<ReceiptItem> items = const [],
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? storeTagline,
    String? storeLegalId,
    String? logoPath,
    bool? showLogo,
    bool? showBarcode,
    String? barcodeData,
    String headerAlign = 'center',
    String titleAlign = 'center',
    String contentAlign = 'left',
    String amountAlign = 'left',
    String stampAlign = 'right',
    String titleFontSize = 'large',
    String amountFontSize = 'large',
    bool isBoldTitle = true,
    bool isBoldAmount = true,
    bool isCondensed = false,
    String stampType = 'LUNAS',
  }) async {
    final amountWords = NumberToWords.convert(amount);

    final newReceipt = Receipt(
      receiptNumber: receiptNumber,
      date: date,
      receivedFrom: receivedFrom.trim(),
      customerPhone: customerPhone?.trim().isEmpty ?? true ? null : customerPhone?.trim(),
      cashierName: cashierName?.trim().isEmpty ?? true ? null : cashierName?.trim(),
      amount: amount,
      amountWords: amountWords,
      description: description.trim(),
      paymentMethod: paymentMethod,
      status: status,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      templateId: templateId,
      discount: discount,
      tax: tax,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
      dueDate: dueDate,
      items: items,
      storeName: storeName?.trim().isEmpty ?? true ? null : storeName?.trim(),
      storeAddress: storeAddress?.trim().isEmpty ?? true ? null : storeAddress?.trim(),
      storePhone: storePhone?.trim().isEmpty ?? true ? null : storePhone?.trim(),
      storeTagline: storeTagline?.trim().isEmpty ?? true ? null : storeTagline?.trim(),
      storeLegalId: storeLegalId?.trim().isEmpty ?? true ? null : storeLegalId?.trim(),
      logoPath: logoPath?.trim().isEmpty ?? true ? null : logoPath?.trim(),
      showLogo: showLogo ?? true,
      showBarcode: showBarcode,
      barcodeData: barcodeData?.trim().isEmpty ?? true ? null : barcodeData?.trim(),
      headerAlign: headerAlign,
      titleAlign: titleAlign,
      contentAlign: contentAlign,
      amountAlign: amountAlign,
      stampAlign: stampAlign,
      titleFontSize: titleFontSize,
      amountFontSize: amountFontSize,
      isBoldTitle: isBoldTitle,
      isBoldAmount: isBoldAmount,
      isCondensed: isCondensed,
      stampType: stampType,
    );

    final saved = await repository.insertReceipt(newReceipt);
    await refreshDashboardStats();
    await refreshReceipts();
    return saved;
  }

  /// Update an existing receipt
  Future<void> updateReceipt(Receipt receipt) async {
    await repository.updateReceipt(receipt);
    await refreshDashboardStats();
    await refreshReceipts();
  }

  /// Delete a receipt
  Future<bool> deleteReceipt(int id) async {
    try {
      final rows = await repository.deleteReceipt(id);
      await refreshDashboardStats();
      await refreshReceipts();
      return rows > 0;
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
      return false;
    }
  }

  /// Search filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshReceipts();
  }

  /// Date range filter
  void setDateFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    refreshReceipts();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    refreshReceipts();
  }

  /// Refresh companies list
  Future<void> refreshCompanies() async {
    try {
      _companies = await repository.getAllCompanies();
      if (_companies.isNotEmpty) {
        final currentId = _company.id;
        final matched = _companies.where((c) => c.id == currentId);
        if (matched.isNotEmpty) {
          _company = matched.first;
        } else {
          _company = _companies.first;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing companies: $e');
    }
  }

  /// Switch active store / company profile
  void switchActiveCompany(Company comp) {
    _company = comp;
    notifyListeners();
  }

  /// Add a new store / company profile
  Future<Company> addCompany(Company comp) async {
    final inserted = await repository.insertCompany(comp);
    await refreshCompanies();
    _company = inserted;
    notifyListeners();
    return inserted;
  }

  /// Remove a store / company profile
  Future<void> removeCompany(int id) async {
    await repository.deleteCompany(id);
    await refreshCompanies();
  }

  /// Update company profile
  Future<void> updateCompany(Company company) async {
    await repository.updateCompany(company);
    _company = company;
    await refreshCompanies();
    notifyListeners();
  }

  /// Update app settings
  Future<void> updateSettings(AppSettings settings) async {
    await repository.updateSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  /// Update active paper size in settings and persist to database
  Future<void> updatePaperSize(String paperSize) async {
    final updated = _settings.copyWith(paperSize: paperSize);
    await updateSettings(updated);
  }

  /// Get distinct customer names for form suggestions
  Future<List<String>> getCustomerSuggestions() async {
    return await repository.getAllCustomerNames();
  }

  /// Get comprehensive financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    return await repository.getFinancialSummary();
  }

  /// Export receipts to CSV string
  Future<String> exportCsv({DateTime? startDate, DateTime? endDate}) async {
    return await repository.exportReceiptsToCsv(startDate: startDate, endDate: endDate);
  }

  /// Export receipts to physical CSV file for native sharing
  Future<File> exportCsvFile({DateTime? startDate, DateTime? endDate}) async {
    final csvContent = await exportCsv(startDate: startDate, endDate: endDate);
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName = 'audira_kwitansi_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvContent, flush: true);
    return file;
  }

  /// Export full database backup as JSON string
  Future<String> exportDatabaseBackup() async {
    return await repository.exportDatabaseJson();
  }

  /// Export full database backup to physical JSON file for native sharing
  Future<File> exportBackupJsonFile() async {
    final jsonContent = await exportDatabaseBackup();
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName = 'audira_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonContent, flush: true);
    return file;
  }

  /// Restore database from JSON backup
  Future<int> restoreDatabaseBackup(String jsonStr) async {
    final count = await repository.importDatabaseJson(jsonStr);
    await init();
    return count;
  }

  /// Clear all transaction history
  Future<void> clearAllReceipts() async {
    await repository.clearAllReceipts();
    await refreshDashboardStats();
    await refreshReceipts();
  }

  // ==========================================
  // PRODUCT CATALOG MANAGEMENT
  // ==========================================

  /// Refresh products list with query and category filters
  Future<void> refreshProducts({String? query, String? category}) async {
    try {
      _products = await repository.getAllProducts(query: query, category: category);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing products: $e');
    }
  }

  /// Add a new product to database
  Future<Product> addProduct({
    String? code,
    required String name,
    required double unitPrice,
    String category = 'Umum',
  }) async {
    final product = Product(
      code: code,
      name: name,
      unitPrice: unitPrice,
      category: category,
    );
    final saved = await repository.insertProduct(product);
    await refreshProducts();
    return saved;
  }

  /// Update an existing product
  Future<void> updateProduct(Product product) async {
    await repository.updateProduct(product);
    await refreshProducts();
  }

  /// Delete a product
  Future<void> deleteProduct(int id) async {
    await repository.deleteProduct(id);
    await refreshProducts();
  }

  /// Get distinct product categories
  Future<List<String>> getProductCategories() async {
    return await repository.getProductCategories();
  }

  // ==========================================
  // TEMPLATE MANAGEMENT
  // ==========================================

  /// Get currently active template
  ReceiptTemplate get activeTemplate {
    return ReceiptTemplate.findById(_settings.activeTemplateId);
  }

  /// Get effective configuration for a given template
  TemplateConfig getTemplateConfig(String templateId) {
    try {
      if (_settings.templateConfigsJson.trim().isNotEmpty && _settings.templateConfigsJson != '{}') {
        final Map<String, dynamic> allConfigs = jsonDecode(_settings.templateConfigsJson);
        if (allConfigs.containsKey(templateId)) {
          return TemplateConfig.fromMap(Map<String, dynamic>.from(allConfigs[templateId]));
        }
      }
    } catch (e) {
      debugPrint('Error parsing template config for $templateId: $e');
    }
    return ReceiptTemplate.findById(templateId).defaultConfig;
  }

  /// Get effective configuration for the currently active template
  TemplateConfig get activeTemplateConfig {
    return getTemplateConfig(_settings.activeTemplateId);
  }

  /// Set the active template ID
  Future<void> setActiveTemplate(String templateId) async {
    final updated = _settings.copyWith(activeTemplateId: templateId);
    await updateSettings(updated);
  }

  /// Update and save custom configuration for a template
  Future<void> updateTemplateConfig(String templateId, TemplateConfig config) async {
    try {
      Map<String, dynamic> allConfigs = {};
      if (_settings.templateConfigsJson.trim().isNotEmpty && _settings.templateConfigsJson != '{}') {
        allConfigs = Map<String, dynamic>.from(jsonDecode(_settings.templateConfigsJson));
      }
      allConfigs[templateId] = config.toMap();
      final updated = _settings.copyWith(templateConfigsJson: jsonEncode(allConfigs));
      await updateSettings(updated);
    } catch (e) {
      debugPrint('Error saving template config: $e');
    }
  }

  /// Reset a template's configuration back to its factory default
  Future<void> resetTemplateConfig(String templateId) async {
    try {
      if (_settings.templateConfigsJson.trim().isNotEmpty && _settings.templateConfigsJson != '{}') {
        final Map<String, dynamic> allConfigs = Map<String, dynamic>.from(jsonDecode(_settings.templateConfigsJson));
        allConfigs.remove(templateId);
        final updated = _settings.copyWith(templateConfigsJson: jsonEncode(allConfigs));
        await updateSettings(updated);
      }
    } catch (e) {
      debugPrint('Error resetting template config: $e');
    }
  }
}
