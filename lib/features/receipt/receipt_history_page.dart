import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/receipt_card.dart';

class ReceiptHistoryPage extends StatefulWidget {
  const ReceiptHistoryPage({super.key});

  @override
  State<ReceiptHistoryPage> createState() => _ReceiptHistoryPageState();
}

class _ReceiptHistoryPageState extends State<ReceiptHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      if (mounted) {
        context.read<ReceiptService>().setDateFilter(picked.start, picked.end);
      }
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    context.read<ReceiptService>().setDateFilter(null, null);
  }

  Future<void> _handleDelete(Receipt receipt) async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context: context,
      title: 'Hapus Kwitansi',
      message: 'Apakah Anda yakin ingin menghapus kwitansi nomor ${receipt.receiptNumber} atas nama ${receipt.receivedFrom}?',
      confirmText: 'Ya, Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final success = await context.read<ReceiptService>().deleteReceipt(receipt.id!);
      if (success && mounted) {
        CustomDialogs.showSuccessSnackBar(context, 'Kwitansi #${receipt.receiptNumber} berhasil dihapus');
      }
    }
  }

  Future<void> _handlePrint(Receipt receipt) async {
    final receiptService = context.read<ReceiptService>();
    final printerService = context.read<PrinterService>();

    final result = await printerService.printReceipt(
      receipt: receipt,
      company: receiptService.company,
      settings: receiptService.settings,
    );

    if (!mounted) return;

    if (result.success) {
      CustomDialogs.showSuccessSnackBar(context, result.message);
    } else {
      CustomDialogs.showPrintFailureDialog(
        context: context,
        errorMessage: result.message,
        onRetry: () => _handlePrint(receipt),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptService>(
      builder: (context, receiptService, _) {
        final receipts = receiptService.receipts;
        final totalAmount = receipts.fold<double>(0.0, (sum, r) => sum + r.amount);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Riwayat Kwitansi'),
            actions: [
              IconButton(
                icon: Icon(
                  _selectedDateRange != null ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _selectedDateRange != null ? AppColors.primary : AppColors.secondaryText,
                ),
                tooltip: 'Filter Tanggal',
                onPressed: _pickDateRange,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => receiptService.refreshReceipts(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar & Filter Indicators
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => receiptService.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Cari nomor, nama pembayar, atau tujuan...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  receiptService.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.date_range, size: 14, color: AppColors.primaryDark),
                                const SizedBox(width: 6),
                                Text(
                                  '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: _clearDateRange,
                                  child: const Icon(Icons.close, size: 14, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Summary bar (Total count & sum)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menampilkan ${receipts.length} Kwitansi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      'Total: ${CurrencyFormatter.format(totalAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt List
              Expanded(
                child: receipts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: AppColors.mutedText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Tidak Ada Kwitansi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchController.text.isNotEmpty || _selectedDateRange != null
                                  ? 'Coba sesuaikan pencarian atau filter Anda'
                                  : 'Belum ada data kwitansi yang tersimpan',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => receiptService.refreshReceipts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: receipts.length,
                          itemBuilder: (ctx, index) {
                            final receipt = receipts[index];
                            return ReceiptCard(
                              receipt: receipt,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.receiptDetail,
                                  arguments: receipt,
                                );
                              },
                              onPrint: () => _handlePrint(receipt),
                              onDelete: () => _handleDelete(receipt),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
