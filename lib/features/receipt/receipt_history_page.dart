import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';

class ReceiptHistoryPage extends StatefulWidget {
  const ReceiptHistoryPage({super.key});

  @override
  State<ReceiptHistoryPage> createState() => _ReceiptHistoryPageState();
}

class _ReceiptHistoryPageState extends State<ReceiptHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  int _activeFilterIndex = 0; // 0: Semua, 1: Hari Ini, 2: Minggu Ini, 3: Bulan Ini

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyPeriodFilter(int index) {
    setState(() => _activeFilterIndex = index);
    final receiptService = context.read<ReceiptService>();
    final now = DateTime.now();

    if (index == 0) {
      // Semua
      receiptService.setDateFilter(null, null);
    } else if (index == 1) {
      // Hari Ini
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      receiptService.setDateFilter(start, end);
    } else if (index == 2) {
      // Minggu Ini
      final start = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(start.year, start.month, start.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      receiptService.setDateFilter(startOfWeek, end);
    } else if (index == 3) {
      // Bulan Ini
      final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      receiptService.setDateFilter(startOfMonth, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final receipts = receiptService.receipts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Kwitansi'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Top Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Input with Filter Icon
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => receiptService.setSearchQuery(val),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari nomor, nama, keterangan...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      receiptService.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppColors.secondaryText, size: 20),
                        tooltip: 'Filter Tanggal',
                        onPressed: () async {
                          final receiptService = context.read<ReceiptService>();
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (range != null) {
                            receiptService.setDateFilter(range.start, range.end);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips Row: [Semua] [Hari Ini] [Minggu Ini] [Bulan Ini]
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(0, 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip(1, 'Hari Ini'),
                      const SizedBox(width: 8),
                      _buildFilterChip(2, 'Minggu Ini'),
                      const SizedBox(width: 8),
                      _buildFilterChip(3, 'Bulan Ini'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Receipts List
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
                        const SizedBox(height: 4),
                        const Text(
                          'Belum ada data kwitansi yang sesuai filter.',
                          style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: receipts.length,
                    itemBuilder: (ctx, i) {
                      final r = receipts[i];
                      return _buildReceiptHistoryCard(r);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _activeFilterIndex == index;
    return InkWell(
      onTap: () => _applyPeriodFilter(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptHistoryCard(Receipt r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.receiptDetail, arguments: r);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Middle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.receiptNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.receivedFrom,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(r.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Amount & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(r.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, size: 10, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Dicetak',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
