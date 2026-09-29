import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class ReceiptHistoryPage extends StatefulWidget {
  const ReceiptHistoryPage({super.key});

  @override
  State<ReceiptHistoryPage> createState() => _ReceiptHistoryPageState();
}

class _ReceiptHistoryPageState extends State<ReceiptHistoryPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _activeFilterIndex = 0;
  String _selectedStatusFilter = 'Semua';
  late AnimationController _statsAnimController;
  late Animation<double> _statsFadeAnim;

  @override
  void initState() {
    super.initState();
    _statsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _statsFadeAnim = CurvedAnimation(parent: _statsAnimController, curve: Curves.easeOut);
    _statsAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statsAnimController.dispose();
    super.dispose();
  }

  void _applyPeriodFilter(int index) {
    setState(() => _activeFilterIndex = index);
    final svc = context.read<ReceiptService>();
    final now = DateTime.now();
    if (index == 0) {
      svc.setDateFilter(null, null);
    } else if (index == 1) {
      svc.setDateFilter(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
    } else if (index == 2) {
      final start = now.subtract(Duration(days: now.weekday - 1));
      svc.setDateFilter(DateTime(start.year, start.month, start.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
    } else if (index == 3) {
      svc.setDateFilter(DateTime(now.year, now.month, 1), DateTime(now.year, now.month, now.day, 23, 59, 59));
    }
  }

  void _resetFilters() {
    setState(() {
      _activeFilterIndex = 0;
      _selectedStatusFilter = 'Semua';
      _searchController.clear();
    });
    final svc = context.read<ReceiptService>();
    svc.clearFilters();
  }

  Future<void> _exportCsv() async {
    try {
      final svc = context.read<ReceiptService>();
      final csv = await svc.exportCsv();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.table_chart_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Ekspor Data CSV'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rekap seluruh kwitansi tersimpan dalam format CSV siap diunduh atau dibagikan ke WhatsApp / Excel.', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: SingleChildScrollView(child: Text(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 10))),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(ctx);
                CustomDialogs.showSuccessSnackBar(context, 'Teks CSV berhasil disalin');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin Teks'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final file = await svc.exportCsvFile();
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    subject: 'Laporan Rekap Kwitansi AUDIRA',
                    text: 'Berikut lampiran file laporan rekap transaksi kwitansi AUDIRA RECEIPT (.csv)',
                  );
                } catch (e) {
                  if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal membagikan file: $e');
                }
              },
              icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
              label: const Text('Bagikan File', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      CustomDialogs.showErrorSnackBar(context, 'Gagal membuat CSV: $e');
    }
  }

  void _showQuickActions(Receipt r) {
    final svc = context.read<ReceiptService>();
    final printerSvc = context.read<PrinterService>();

    Color statusColor = AppColors.success;
    if (r.status.contains('DP')) {
      statusColor = const Color(0xFFD97706);
    } else if (r.status == 'PELUNASAN') {
      statusColor = const Color(0xFF2563EB);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),

            // Receipt info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_rounded, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.receiptNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                  Text(r.receivedFrom, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(AppDateFormatter.formatShortWithTime(r.date), style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(CurrencyFormatter.format(r.amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.text)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(r.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Aksi Cepat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
            ),
            const SizedBox(height: 10),

            // 4-button grid
            Row(children: [
              _buildActionBtn(icon: Icons.visibility_rounded, label: 'Preview\nStruk', color: AppColors.primary, onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.receiptPreview, arguments: r);
              }),
              const SizedBox(width: 10),
              _buildActionBtn(icon: Icons.print_rounded, label: 'Cetak\nUlang', color: const Color(0xFF059669), onTap: () async {
                Navigator.pop(ctx);
                final result = await printerSvc.printReceipt(receipt: r, company: svc.company, settings: svc.settings);
                if (!mounted) return;
                if (result.success) {
                  CustomDialogs.showSuccessSnackBar(context, '🖨️ ${r.receiptNumber} berhasil dicetak!');
                } else {
                  CustomDialogs.showErrorSnackBar(context, result.message);
                }
              }),
              const SizedBox(width: 10),
              _buildActionBtn(icon: Icons.edit_rounded, label: 'Edit\nKwitansi', color: const Color(0xFFD97706), onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.receiptForm, arguments: r);
              }),
              const SizedBox(width: 10),
              _buildActionBtn(icon: Icons.copy_rounded, label: 'Salin\nTeks', color: const Color(0xFF7C3AED), onTap: () {
                final plain = PrinterUtils.generateReceiptPlainText(
                  receipt: r,
                  company: svc.company,
                  paperSize: svc.settings.paperSize,
                );
                Clipboard.setData(ClipboardData(text: plain));
                Navigator.pop(ctx);
                CustomDialogs.showSuccessSnackBar(context, 'Teks kwitansi disalin ke clipboard');
              }),
            ]),
            const SizedBox(height: 12),

            // View detail + delete row
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.receiptDetail, arguments: r);
                },
                icon: const Icon(Icons.open_in_full_rounded, size: 16),
                label: const Text('Lihat Detail'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final confirmed = await CustomDialogs.showConfirmDialog(
                    context: context, title: 'Hapus Kwitansi',
                    message: 'Hapus ${r.receiptNumber}? Tidak bisa dibatalkan.',
                    confirmText: 'Hapus', cancelText: 'Batal', isDestructive: true,
                  );
                  if (confirmed && mounted) {
                    final ok = await svc.deleteReceipt(r.id!);
                    if (ok && mounted) CustomDialogs.showSuccessSnackBar(context, '${r.receiptNumber} dihapus');
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, height: 1.2)),
          ]),
        ),
      ),
    );
  }

  Map<String, List<Receipt>> _groupByDate(List<Receipt> receipts) {
    final map = <String, List<Receipt>>{};
    for (final r in receipts) {
      final key = _dateGroupKey(r.date);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  String _dateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hari Ini';
    if (d == yesterday) return 'Kemarin';
    final diff = today.difference(d).inDays;
    if (diff < 7) return '$diff Hari Lalu';
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ReceiptService>();
    final all = svc.receipts;

    final filtered = _selectedStatusFilter == 'Semua'
        ? all
        : all.where((r) => r.status.toUpperCase().contains(_selectedStatusFilter.toUpperCase())).toList();

    final isFilterActive = _activeFilterIndex != 0 ||
        _selectedStatusFilter != 'Semua' ||
        _searchController.text.trim().isNotEmpty ||
        svc.startDate != null;

    final totalSum = filtered.fold<double>(0, (p, e) => p + e.amount);
    final totalDiscount = filtered.fold<double>(0, (p, e) => p + e.discount);
    final totalTax = filtered.fold<double>(0, (p, e) => p + e.tax);
    final avgAmount = filtered.isEmpty ? 0.0 : totalSum / filtered.length;

    final now = DateTime.now();
    final thisMonth = all.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    final thisMonthTotal = thisMonth.fold<double>(0, (p, e) => p + e.amount);
    final lunas = all.where((r) => r.status == 'LUNAS').length;

    final grouped = _groupByDate(filtered);
    final groupKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Riwayat Kwitansi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${all.length} kwitansi tersimpan', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
        ]),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.file_download_outlined), tooltip: 'Ekspor CSV', onPressed: _exportCsv),
        ],
      ),
      body: Column(children: [
        // ── STATS HEADER (Dynamic Financial Summary) ──
        FadeTransition(
          opacity: _statsFadeAnim,
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              if (isFilterActive) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          'REKAP HASIL FILTER AKTIF (${filtered.length})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _resetFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Reset Filter', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _buildStatCard(label: 'Kwitansi Terpilih', value: '${filtered.length}', unit: 'dari ${all.length} total', icon: Icons.filter_list_rounded, flex: 1),
                  const SizedBox(width: 10),
                  _buildStatCard(label: 'Total Nilai Terpilih', value: CurrencyFormatter.format(totalSum, withSymbol: false), unit: 'rupiah tersaring', icon: Icons.payments_rounded, flex: 2),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _buildStatCard(label: 'Rata-rata Nota', value: CurrencyFormatter.format(avgAmount, withSymbol: false), unit: 'per transaksi', icon: Icons.analytics_rounded, flex: 1),
                  const SizedBox(width: 10),
                  _buildStatCard(label: 'Diskon & Pajak', value: 'D: ${CurrencyFormatter.format(totalDiscount, withSymbol: false)}', unit: 'P: ${CurrencyFormatter.format(totalTax, withSymbol: false)}', icon: Icons.percent_rounded, flex: 1),
                ]),
              ] else ...[
                Row(children: [
                  _buildStatCard(label: 'Total Kwitansi', value: '${all.length}', unit: 'dokumen tersimpan', icon: Icons.receipt_long_rounded, flex: 1),
                  const SizedBox(width: 10),
                  _buildStatCard(label: 'Total Nilai', value: CurrencyFormatter.format(all.fold(0.0, (p, e) => p + e.amount), withSymbol: false), unit: 'rupiah keseluruhan', icon: Icons.payments_rounded, flex: 2),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _buildStatCard(label: 'Bulan Ini', value: '${thisMonth.length} kwitansi', unit: CurrencyFormatter.format(thisMonthTotal, withSymbol: false), icon: Icons.calendar_month_rounded, flex: 1),
                  const SizedBox(width: 10),
                  _buildStatCard(label: 'Status Lunas', value: '$lunas', unit: 'dari ${all.length} kwitansi', icon: Icons.check_circle_rounded, flex: 1),
                ]),
              ],
            ]),
          ),
        ),

        // ── SEARCH & FILTER ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => svc.setSearchQuery(val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari no. kwitansi, nama, keterangan...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { _searchController.clear(); svc.setSearchQuery(''); })
                          : null,
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: const Icon(Icons.date_range_rounded, color: AppColors.secondaryText, size: 20),
                  onPressed: () async {
                    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (range != null) svc.setDateFilter(range.start, range.end);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _buildPeriodChip(0, '📋 Semua'), const SizedBox(width: 8),
                _buildPeriodChip(1, '🌅 Hari Ini'), const SizedBox(width: 8),
                _buildPeriodChip(2, '📅 Minggu Ini'), const SizedBox(width: 8),
                _buildPeriodChip(3, '🗓️ Bulan Ini'),
              ]),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _buildStatusChip('Semua'), const SizedBox(width: 6),
                _buildStatusChip('LUNAS'), const SizedBox(width: 6),
                _buildStatusChip('DP'), const SizedBox(width: 6),
                _buildStatusChip('PELUNASAN'),
              ]),
            ),
          ]),
        ),

        // Summary strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text('${filtered.length} kwitansi ditemukan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
              if (isFilterActive) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _resetFilters,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.close, size: 12, color: Colors.red),
                      SizedBox(width: 2),
                      Text('Reset', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                    ]),
                  ),
                ),
              ],
            ]),
            Text('Total: ${CurrencyFormatter.format(totalSum)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
        ),

        // ── LIST ──
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: groupKeys.length,
                  itemBuilder: (ctx, gi) {
                    final label = groupKeys[gi];
                    final items = grouped[label]!;
                    final groupTotal = items.fold<double>(0, (p, e) => p + e.amount);
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 1, color: AppColors.border)),
                          const SizedBox(width: 8),
                          Text(CurrencyFormatter.format(groupTotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
                          Text('  (${items.length})', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                        ]),
                      ),
                      ...items.map((r) => _buildReceiptCard(r)),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildStatCard({required String label, required String value, required String unit, required IconData icon, required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white), overflow: TextOverflow.ellipsis),
            Text(unit, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7)), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }

  Widget _buildPeriodChip(int index, String label) {
    final sel = _activeFilterIndex == index;
    return InkWell(
      onTap: () => _applyPeriodFilter(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: sel ? AppColors.primary : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? Colors.white : AppColors.secondaryText)),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final sel = _selectedStatusFilter == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = status),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? Colors.white : AppColors.secondaryText)),
      ),
    );
  }

  Widget _buildReceiptCard(Receipt r) {
    Color statusColor = AppColors.success;
    if (r.status.contains('DP')) {
      statusColor = const Color(0xFFD97706);
    } else if (r.status == 'PELUNASAN') {
      statusColor = const Color(0xFF2563EB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showQuickActions(r),
          onLongPress: () => Navigator.pushNamed(context, AppRoutes.receiptDetail, arguments: r),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_rounded, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r.receiptNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(r.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(r.receivedFrom, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(CurrencyFormatter.format(r.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(AppDateFormatter.formatTimeOnly(r.date), style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                ]),
              ]),

              if (r.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.label_outline_rounded, size: 12, color: AppColors.secondaryText),
                    const SizedBox(width: 5),
                    Expanded(child: Text(r.description, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              ],

              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.touch_app_rounded, size: 11, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text('Ketuk = aksi cepat  •  Tahan = detail lengkap', style: TextStyle(fontSize: 10, color: AppColors.mutedText.withOpacity(0.7))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: Text(r.paymentMethod, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(24)),
          child: Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.primary.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        const Text('Belum Ada Kwitansi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 6),
        const Text('Kwitansi yang Anda buat akan tersimpan\notomatis dan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.receiptForm),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat Kwitansi Pertama'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }
}
