import 'package:flutter/foundation.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/database/receipt_repository.dart';
import 'package:audira_receipt/models/app_settings.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';

class ReceiptService extends ChangeNotifier {
  final ReceiptRepository repository;

  List<Receipt> _receipts = [];
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
      _company = await repository.getCompany();
      _settings = await repository.getSettings();
      await refreshDashboardStats();
      await refreshReceipts();
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
    required double amount,
    required String description,
    required String paymentMethod,
    String? notes,
  }) async {
    final amountWords = NumberToWords.convert(amount);

    final newReceipt = Receipt(
      receiptNumber: receiptNumber,
      date: date,
      receivedFrom: receivedFrom.trim(),
      amount: amount,
      amountWords: amountWords,
      description: description.trim(),
      paymentMethod: paymentMethod,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
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

  /// Update company profile
  Future<void> updateCompany(Company company) async {
    await repository.updateCompany(company);
    _company = company;
    notifyListeners();
  }

  /// Update app settings
  Future<void> updateSettings(AppSettings settings) async {
    await repository.updateSettings(settings);
    _settings = settings;
    notifyListeners();
  }
}
