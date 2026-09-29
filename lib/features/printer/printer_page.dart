import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class PrinterPage extends StatelessWidget {
  const PrinterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final btService = context.watch<BluetoothService>();
    final isConnected = btService.isConnected && btService.connectedPrinter != null;
    final printerName = btService.connectedPrinter?.name ?? 'Belum Ada Printer';
    final macAddress = btService.connectedPrinter?.macAddress ?? 'Tidak Terhubung';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Printer'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Top Card: Printer Aktif / Terputus
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected ? AppColors.success : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.successLight : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.print_rounded,
                      color: isConnected ? AppColors.success : AppColors.secondaryText,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Printer Aktif' : 'Printer Terputus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isConnected ? AppColors.success : AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          printerName,
                          style: const TextStyle(
                            fontSize: 14,
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
                  if (isConnected)
                    OutlinedButton(
                      onPressed: () async {
                        final pName = btService.connectedPrinter?.name ?? 'Printer';
                        await btService.disconnect();
                        if (context.mounted) {
                          CustomDialogs.showSuccessSnackBar(context, '$pName berhasil diputuskan');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('PUTUSKAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.printerScan),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('HUBUNGKAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Menu List Items
            _buildMenuItem(
              icon: Icons.bluetooth_searching_rounded,
              title: 'Scan Bluetooth',
              subtitle: 'Cari printer baru',
              onTap: () => Navigator.pushNamed(context, AppRoutes.printerScan),
            ),
            const SizedBox(height: 10),

            _buildMenuItem(
              icon: Icons.inventory_2_outlined,
              title: 'Printer Tersimpan',
              subtitle: 'Kelola printer yang tersimpan',
              onTap: () => Navigator.pushNamed(context, AppRoutes.printerScan),
            ),
            const SizedBox(height: 10),

            _buildMenuItem(
              icon: Icons.fact_check_outlined,
              title: 'Test Print',
              subtitle: 'Coba cetak test halaman',
              onTap: () => Navigator.pushNamed(context, AppRoutes.printerTest),
            ),
            const SizedBox(height: 10),

            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Pengaturan Printer',
              subtitle: 'Ukuran kertas, density, auto cut',
              onTap: () {
                // Navigate to Screen 10 (Printer Connected / Settings)
                Navigator.pushNamed(context, '/printer/connected');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
