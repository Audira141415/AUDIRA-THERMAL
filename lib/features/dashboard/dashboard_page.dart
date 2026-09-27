import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/features/printer/printer_page.dart';
import 'package:audira_receipt/features/receipt/receipt_history_page.dart';
import 'package:audira_receipt/features/settings/settings_page.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/printer_status.dart';
import 'package:audira_receipt/widgets/quick_action_card.dart';
import 'package:audira_receipt/widgets/receipt_card.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.receiptForm);
        },
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Buat Kwitansi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const _DashboardView({required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptService>(
      builder: (context, receiptService, _) {
        final recentReceipts = receiptService.receipts.take(4).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await receiptService.refreshDashboardStats();
                await receiptService.refreshReceipts();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header App Title & Subtitle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppConstants.appSubtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        // Quick test print button
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.printerTest),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          tooltip: 'Test Print',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Printer Status Card
                    PrinterStatusWidget(
                      onTap: () => onNavigateTab(2), // go to Printer tab
                    ),
                    const SizedBox(height: 18),

                    // Statistics Cards: Today Receipts & Today Total
                    Row(
                      children: [
                        // Card 1: Today Receipts Count
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Hari Ini',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_outlined,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${receiptService.todayCount} Kwitansi',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Card 2: Today Total Amount
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Transaksi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  CurrencyFormatter.format(receiptService.todayTotalAmount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Big Action Button: BUAT KWITANSI
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.receiptForm);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        label: const Text(
                          'BUAT KWITANSI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Quick Actions Section
                    const Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.history,
                            title: 'Riwayat',
                            subtitle: 'Daftar kwitansi',
                            iconColor: AppColors.primary,
                            iconBgColor: AppColors.primaryLight.withOpacity(0.4),
                            onTap: () => onNavigateTab(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.print,
                            title: 'Printer',
                            subtitle: 'Koneksi & tes',
                            iconColor: AppColors.success,
                            iconBgColor: AppColors.successLight,
                            onTap: () => onNavigateTab(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.store_outlined,
                            title: 'Perusahaan',
                            subtitle: 'Profil bisnis',
                            iconColor: AppColors.warning,
                            iconBgColor: AppColors.warningLight,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.companyProfile),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.settings,
                            title: 'Pengaturan',
                            subtitle: 'Kertas & nomor',
                            iconColor: AppColors.secondaryText,
                            iconBgColor: AppColors.divider,
                            onTap: () => onNavigateTab(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Recent Receipts Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kwitansi Terbaru',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onNavigateTab(1),
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // List of recent receipts
                    if (recentReceipts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.mutedText.withOpacity(0.6),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum Ada Kwitansi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tekan "Buat Kwitansi" untuk membuat kwitansi pertama Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentReceipts.length,
                        itemBuilder: (ctx, i) {
                          final receipt = recentReceipts[i];
                          return ReceiptCard(
                            receipt: receipt,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.receiptDetail,
                                arguments: receipt,
                              );
                            },
                            onPrint: () async {
                              final printerService = context.read<PrinterService>();
                              final result = await printerService.printReceipt(
                                receipt: receipt,
                                company: receiptService.company,
                                settings: receiptService.settings,
                              );
                              if (result.success) {
                                if (context.mounted) {
                                  CustomDialogs.showSuccessSnackBar(context, result.message);
                                }
                              } else {
                                if (context.mounted) {
                                  CustomDialogs.showPrintFailureDialog(
                                    context: context,
                                    errorMessage: result.message,
                                    onRetry: () {
                                      printerService.printReceipt(
                                        receipt: receipt,
                                        company: receiptService.company,
                                        settings: receiptService.settings,
                                      );
                                    },
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
