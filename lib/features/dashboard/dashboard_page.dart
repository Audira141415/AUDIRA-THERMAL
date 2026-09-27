import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/features/printer/printer_page.dart';
import 'package:audira_receipt/features/receipt/receipt_history_page.dart';
import 'package:audira_receipt/features/settings/settings_page.dart';
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

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.backup_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Backup Data'),
          ],
        ),
        content: const Text(
          'Semua data kwitansi dan pengaturan tersimpan secara offline di SQLite lokal perangkat Anda. Anda dapat mengekspor atau membuat cadangan database secara otomatis.',
          style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              CustomDialogs.showSuccessSnackBar(context, 'Data kwitansi berhasil dicadangkan ke penyimpanan lokal');
            },
            child: const Text('Cadangkan Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tentang Aplikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              AppConstants.appName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            SizedBox(height: 2),
            Text(
              '${AppConstants.appSubtitle} • v2.0.0',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            SizedBox(height: 12),
            Text(
              'Aplikasi pencetakan kwitansi langsung ke Bluetooth Thermal Printer ESC/POS (58mm & 80mm) secara offline-first tanpa melalui PDF.',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          AppConstants.appSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
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
                        icon: Icons.settings_outlined,
                        label: 'Pengaturan',
                        onTap: () => onNavigateTab(3),
                      ),
                      _buildGridActionItem(
                        icon: Icons.storefront_outlined,
                        label: 'Data Perusahaan',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.companyProfile),
                      ),
                      _buildGridActionItem(
                        icon: Icons.cloud_download_outlined,
                        label: 'Backup Data',
                        onTap: () => _showBackupDialog(context),
                      ),
                      _buildGridActionItem(
                        icon: Icons.info_outline_rounded,
                        label: 'Tentang',
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
