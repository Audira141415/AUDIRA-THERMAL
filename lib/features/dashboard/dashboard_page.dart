import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/features/printer/printer_page.dart';
import 'package:audira_receipt/features/receipt/receipt_history_page.dart';
import 'package:audira_receipt/features/settings/settings_page.dart';
import 'package:audira_receipt/widgets/about_license_dialog.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class DashboardPage extends StatefulWidget {
  final int initialTab;

  const DashboardPage({super.key, this.initialTab = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _DashboardView(onNavigateTab: _switchTab),
      const ReceiptHistoryPage(),
      const PrinterPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.secondaryText,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.print_outlined),
              activeIcon: Icon(Icons.print),
              label: 'Printer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const _DashboardView({required this.onNavigateTab});

  Future<void> _showBackupDialog(BuildContext context) async {
    final receiptService = context.read<ReceiptService>();
    try {
      final jsonBackup = await receiptService.exportDatabaseBackup();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.backup_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Backup Data (JSON)'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seluruh data transaksi dan pengaturan SQLite tersimpan dalam format JSON berikut:',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonBackup,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonBackup));
                Navigator.pop(ctx);
                CustomDialogs.showSuccessSnackBar(context, 'Data JSON cadangan disalin ke clipboard');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin JSON'),
            ),
          ],
        ),
      );
    } catch (e) {
      CustomDialogs.showErrorSnackBar(context, 'Gagal mencadangkan data: $e');
    }
  }

  void _showAboutDialog(BuildContext context) {
    AboutLicenseDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final btService = context.watch<BluetoothService>();
    final settings = receiptService.settings;

    final isConnected = btService.isConnected;
    final printerName = btService.connectedPrinter?.name ?? (isConnected ? 'XP-58 Bluetooth' : 'Belum Ada Printer');
    final macAddress = btService.connectedPrinter?.macAddress ?? (isConnected ? '00:11:22:33:44:55' : 'Tidak Terhubung');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Blue Top App Header
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              AppConstants.appSubtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Notification Bell with badge
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            CustomDialogs.showSuccessSnackBar(context, 'Tidak ada notifikasi baru.');
                          },
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                        ),
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Dashboard Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1. Printer Status Card
                  InkWell(
                    onTap: () => onNavigateTab(2),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Green Icon Box
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isConnected ? AppColors.success : AppColors.danger,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.print_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isConnected ? 'Printer Terhubung' : 'Printer Tidak Terhubung',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isConnected ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      printerName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'MAC: $macAddress',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondaryText,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Chips Row
                          Row(
                            children: [
                              _buildPillTag(settings.paperSize),
                              const SizedBox(width: 8),
                              _buildPillTag('Auto Cut: ${settings.autoCut ? 'ON' : 'OFF'}'),
                              const SizedBox(width: 8),
                              _buildPillTag('Density: ${settings.printDensity}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Statistics Card (12 Kwitansi Hari Ini & Rp 8.750.000 Total Transaksi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${receiptService.todayCount}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Kwitansi Hari Ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(receiptService.todayTotalAmount),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Total Transaksi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Big Button "+ BUAT KWITANSI"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.receiptForm);
                      },
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        'BUAT KWITANSI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3.5. Template Kwitansi Banner (22+ Template)
                  Container(
                    margin: const EdgeInsets.only(top: 14, bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.07),
                          const Color(0xFFEFF6FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.templateGallery),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.style_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            receiptService.activeTemplate.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.text,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '22+ Pilihan',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${receiptService.activeTemplate.category} • Tap untuk ganti desain',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Quick Actions Grid (2 rows x 3 columns)
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      _buildGridActionItem(
                        icon: Icons.style_outlined,
                        label: 'Template (22+)',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.templateGallery),
                      ),
                      _buildGridActionItem(
                        icon: Icons.history_rounded,
                        label: 'Riwayat',
                        onTap: () => onNavigateTab(1),
                      ),
                      _buildGridActionItem(
                        icon: Icons.print_outlined,
                        label: 'Printer',
                        onTap: () => onNavigateTab(2),
                      ),
                      _buildGridActionItem(
                        icon: Icons.storefront_outlined,
                        label: 'Data Usaha',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.companyProfile),
                      ),
                      _buildGridActionItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Katalog Item',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.productCatalog),
                      ),
                      _buildGridActionItem(
                        icon: Icons.cloud_download_outlined,
                        label: 'Backup Data',
                        onTap: () => _showBackupDialog(context),
                      ),
                      _buildGridActionItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Tentang & Lisensi',
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),

                  // 5. Transaksi Terbaru Header & Cards
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaksi Terbaru',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab(1),
                        child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (receiptService.receipts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada transaksi kwitansi. Klik "+ BUAT KWITANSI" di atas.',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: receiptService.receipts
                          .take(3)
                          .map((r) => _buildRecentReceiptTile(context, r))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReceiptTile(BuildContext context, Receipt r) {
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.receiptDetail, arguments: r);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
        ),
        title: Text(
          r.receiptNumber,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        subtitle: Text(
          '${r.receivedFrom} • ${AppDateFormatter.formatShort(r.date)}',
          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(r.amount),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              r.status,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildGridActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
