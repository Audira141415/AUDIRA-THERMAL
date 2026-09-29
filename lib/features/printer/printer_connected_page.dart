import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class PrinterConnectedPage extends StatefulWidget {
  const PrinterConnectedPage({super.key});

  @override
  State<PrinterConnectedPage> createState() => _PrinterConnectedPageState();
}

class _PrinterConnectedPageState extends State<PrinterConnectedPage> {
  @override
  Widget build(BuildContext context) {
    final btService = context.watch<BluetoothService>();
    final receiptService = context.watch<ReceiptService>();
    final settings = receiptService.settings;

    final isConnected = btService.isConnected && btService.connectedPrinter != null;
    final printerName = btService.connectedPrinter?.name ?? 'Tidak Ada Printer Terhubung';
    final macAddress = btService.connectedPrinter?.macAddress ?? 'Tidak Terhubung';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Printer Terhubung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            // 1. Printer Hardware Illustration & Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isConnected ? AppColors.success : AppColors.border),
              ),
              child: Column(
                children: [
                  // Printer hardware illustration
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 14,
                          child: Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const Icon(Icons.print_rounded, color: Colors.white70, size: 40),
                        Positioned(
                          bottom: 12,
                          right: 14,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isConnected ? AppColors.success : AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    printerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'MAC: $macAddress',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.successLight : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.cancel_outlined,
                          size: 12,
                          color: isConnected ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isConnected ? 'Terhubung' : 'Terputus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isConnected ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Quick Tools Row: [Test Print] [Atur Kertas] [Atur Density] [Auto Cut]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickTool(
                        icon: Icons.receipt_long_rounded,
                        label: 'Test Print',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.printerTest),
                      ),
                      _buildQuickTool(
                        icon: Icons.aspect_ratio_rounded,
                        label: 'Atur Kertas',
                        onTap: () {
                          final newSize = settings.paperSize == AppConstants.paper48mm
                              ? AppConstants.paper58mm
                              : (settings.paperSize == AppConstants.paper58mm
                                  ? AppConstants.paper80mm
                                  : AppConstants.paper48mm);
                          receiptService.updateSettings(settings.copyWith(paperSize: newSize));
                          CustomDialogs.showSuccessSnackBar(context, 'Kertas diubah ke $newSize');
                        },
                      ),
                      _buildQuickTool(
                        icon: Icons.tune_rounded,
                        label: 'Atur Density',
                        onTap: () {
                          final newDensity = settings.printDensity >= 3 ? 1 : settings.printDensity + 1;
                          receiptService.updateSettings(settings.copyWith(printDensity: newDensity));
                          CustomDialogs.showSuccessSnackBar(context, 'Density diubah ke $newDensity');
                        },
                      ),
                      _buildQuickTool(
                        icon: Icons.content_cut_rounded,
                        label: 'Auto Cut',
                        onTap: () {
                          final newCut = !settings.autoCut;
                          receiptService.updateSettings(settings.copyWith(autoCut: newCut));
                          CustomDialogs.showSuccessSnackBar(context, 'Auto cut ${newCut ? 'diaktifkan' : 'dinonaktifkan'}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Configuration Form
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ukuran Kertas
                  const Text(
                    'Ukuran Kertas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRadioOption(
                        label: '48 mm',
                        isSelected: settings.paperSize == AppConstants.paper48mm,
                        onTap: () => receiptService.updateSettings(settings.copyWith(paperSize: AppConstants.paper48mm)),
                      ),
                      const SizedBox(width: 18),
                      _buildRadioOption(
                        label: '58 mm',
                        isSelected: settings.paperSize == AppConstants.paper58mm,
                        onTap: () => receiptService.updateSettings(settings.copyWith(paperSize: AppConstants.paper58mm)),
                      ),
                      const SizedBox(width: 18),
                      _buildRadioOption(
                        label: '80 mm',
                        isSelected: settings.paperSize == AppConstants.paper80mm,
                        onTap: () => receiptService.updateSettings(settings.copyWith(paperSize: AppConstants.paper80mm)),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),

                  // Print Density Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Print Density',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Text(
                        '${settings.printDensity}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.printDensity.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      receiptService.updateSettings(settings.copyWith(printDensity: val.round()));
                    },
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // Auto Cut Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Auto Cut (jika didukung)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Switch(
                        value: settings.autoCut,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          receiptService.updateSettings(settings.copyWith(autoCut: val));
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // Cetak Logo Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cetak Logo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Switch(
                        value: settings.printLogo,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          receiptService.updateSettings(settings.copyWith(printLogo: val));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Action Button (PUTUSKAN if connected, or HUBUNGKAN if disconnected)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: isConnected
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        final pName = btService.connectedPrinter?.name ?? 'Printer';
                        await btService.disconnect();
                        if (context.mounted) {
                          CustomDialogs.showSuccessSnackBar(context, '$pName berhasil diputuskan');
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text(
                        'PUTUSKAN PRINTER',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.printerScan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
                      label: const Text(
                        'PILIH & HUBUNGKAN PRINTER',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTool({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.secondaryText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
