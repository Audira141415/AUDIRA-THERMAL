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

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  String _selectedPaperSize = AppConstants.paper58mm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
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
      paperSize: _selectedPaperSize,
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
        title: const Text('Scan Printer Bluetooth'),
        actions: [
          if (isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Scan Ulang',
              onPressed: _startScan,
            ),
        ],
      ),
      body: Column(
        children: [
          // Paper size selector banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Ukuran Kertas Printer',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Terapkan untuk printer yang akan dihubungkan',
                      style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '58mm', label: Text('58mm', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: '80mm', label: Text('80mm', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {_selectedPaperSize},
                  onSelectionChanged: (val) {
                    setState(() {
                      _selectedPaperSize = val.first;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Instructions Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pastikan Bluetooth HP aktif, Thermal Printer dalam keadaan ON, dan telah di-pairing di menu Bluetooth perangkat Android Anda.',
                      style: TextStyle(fontSize: 12, color: AppColors.text, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Devices List
          Expanded(
            child: isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 16),
                        Text(
                          'Sedang mencari printer Bluetooth...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mendeteksi perangkat yang terpasang (paired)',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  )
                : devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bluetooth_searching,
                              size: 56,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Printer Tidak Ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Pastikan printer Bluetooth telah di-pairing di pengaturan Bluetooth Android terlebih dahulu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _startScan,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Cari Ulang'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: devices.length,
                        itemBuilder: (ctx, i) {
                          final printer = devices[i];
                          final isCurrentlyConnected = btService.isConnected &&
                              btService.connectedPrinter?.macAddress == printer.macAddress;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrentlyConnected ? AppColors.success : AppColors.border,
                                width: isCurrentlyConnected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCurrentlyConnected
                                        ? AppColors.successLight
                                        : AppColors.primaryLight.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.print_outlined,
                                    color: isCurrentlyConnected ? AppColors.success : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        printer.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        printer.macAddress,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryText,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrentlyConnected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '🟢 Terhubung',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => _connectToPrinter(printer),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Hubungkan'),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
