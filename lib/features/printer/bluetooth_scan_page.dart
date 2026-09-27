import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/database/receipt_repository.dart';
import 'package:audira_receipt/models/thermal_printer.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final btService = context.read<BluetoothService>();
    await btService.scanPrinters();
    if (btService.lastErrorMessage.isNotEmpty && mounted) {
      CustomDialogs.showErrorSnackBar(context, btService.lastErrorMessage);
    }
  }

  Future<void> _connectToPrinter(ThermalPrinter printer) async {
    final btService = context.read<BluetoothService>();
    final repo = context.read<ReceiptRepository>();

    final printerWithConfig = printer.copyWith(
      paperSize: AppConstants.paper58mm,
      isDefault: true,
    );

    final success = await btService.connect(printerWithConfig);
    if (!mounted) return;

    if (success) {
      await repo.savePrinter(printerWithConfig);
      if (!mounted) return;
      CustomDialogs.showSuccessSnackBar(context, 'Berhasil terhubung ke ${printer.name}');
      Navigator.pop(context, true);
    } else {
      CustomDialogs.showErrorSnackBar(
        context,
        btService.lastErrorMessage.isNotEmpty
            ? btService.lastErrorMessage
            : 'Gagal terhubung ke ${printer.name}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = context.watch<BluetoothService>();
    final isScanning = btService.isScanning;
    final devices = btService.availableDevices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Bluetooth'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. Radar Pulse Animation Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ripple
                          if (isScanning) ...[
                            Container(
                              width: 120 * _radarController.value,
                              height: 120 * _radarController.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity((1 - _radarController.value) * 0.25),
                              ),
                            ),
                            Container(
                              width: 90 * _radarController.value,
                              height: 90 * _radarController.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity((1 - _radarController.value) * 0.35),
                              ),
                            ),
                          ],
                          // Center Bluetooth Icon Circle
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bluetooth_rounded, color: Colors.white, size: 30),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isScanning ? 'Mencari printer...' : 'Pencarian Selesai',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Pastikan printer dalam mode pairing',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // 2. Section Header: Perangkat Ditemukan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Perangkat Ditemukan (${devices.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),

          // 3. Devices List
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bluetooth_searching_rounded, size: 48, color: AppColors.mutedText),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Perangkat Ditemukan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pastikan Bluetooth aktif dan dekat dengan printer',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (ctx, i) {
                      final printer = devices[i];
                      final isCurrent = btService.isConnected &&
                          btService.connectedPrinter?.macAddress == printer.macAddress;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isCurrent ? AppColors.success : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent ? AppColors.successLight : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.print_outlined,
                                color: isCurrent ? AppColors.success : AppColors.secondaryText,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    printer.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    printer.macAddress,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryText,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _connectToPrinter(printer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrent ? AppColors.success : AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              child: Text(isCurrent ? 'TERHUBUNG' : 'HUBUNGKAN'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. Bottom Button: [BERHENTI SCAN / SCAN ULANG]
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  if (isScanning) {
                    setState(() {});
                  } else {
                    _startScan();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isScanning ? 'BERHENTI SCAN' : 'SCAN ULANG',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
