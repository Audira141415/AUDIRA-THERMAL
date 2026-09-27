import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/database/receipt_repository.dart';
import 'package:audira_receipt/models/thermal_printer.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  List<ThermalPrinter> _savedPrinters = [];
  bool _isLoadingPrinters = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinters();
  }

  Future<void> _loadSavedPrinters() async {
    setState(() => _isLoadingPrinters = true);
    try {
      final repo = context.read<ReceiptRepository>();
      final list = await repo.getPrinters();
      if (mounted) {
        setState(() {
          _savedPrinters = list;
          _isLoadingPrinters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPrinters = false);
      }
    }
  }

  Future<void> _handleConnect(ThermalPrinter printer) async {
    final btService = context.read<BluetoothService>();
    final repo = context.read<ReceiptRepository>();

    final success = await btService.connect(printer);
    if (!mounted) return;

    if (success) {
      // Save printer to database as default
      final updated = printer.copyWith(isDefault: true);
      await repo.savePrinter(updated);
      await _loadSavedPrinters();
      if (mounted) {
        CustomDialogs.showSuccessSnackBar(context, 'Terhubung ke ${printer.name}');
      }
    } else {
      CustomDialogs.showErrorSnackBar(
        context,
        btService.lastErrorMessage.isNotEmpty
            ? btService.lastErrorMessage
            : 'Gagal terhubung ke printer ${printer.name}',
      );
    }
  }

  Future<void> _handleDisconnect() async {
    final btService = context.read<BluetoothService>();
    await btService.disconnect();
    if (mounted) {
      CustomDialogs.showSuccessSnackBar(context, 'Printer telah diputuskan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = context.watch<BluetoothService>();
    final receiptService = context.watch<ReceiptService>();
    final settings = receiptService.settings;
    final isConnected = btService.isConnected;
    final connectedPrinter = btService.connectedPrinter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _loadSavedPrinters();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Printer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected ? AppColors.success.withOpacity(0.4) : AppColors.border,
                  width: isConnected ? 1.5 : 1,
                ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Printer Aktif Saat Ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected ? AppColors.successLight : AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isConnected ? AppColors.success : AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected ? '🟢 Terhubung' : '🔴 Tidak Terhubung',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isConnected ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isConnected ? connectedPrinter!.name : 'Belum Ada Printer Terhubung',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(height: 4),
                    Text(
                      'MAC: ${connectedPrinter!.macAddress}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Actions row
                  Row(
                    children: [
                      if (isConnected) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleDisconnect,
                            icon: const Icon(Icons.link_off, size: 18, color: AppColors.danger),
                            label: const Text('Putuskan', style: TextStyle(color: AppColors.danger)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.printerScan),
                          icon: const Icon(Icons.bluetooth_searching, size: 18),
                          label: Text(isConnected ? 'Ganti Printer' : 'Scan Printer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Test Print Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Test Print Thermal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Uji coba koneksi, font, baris, dan cutter ESC/POS.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.printerTest),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Tes Sekarang'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Printer Configuration Settings
            const Text(
              'Konfigurasi Kertas & Cetak',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Paper Size selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ukuran Kertas Default',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '58mm (32 kolom) atau 80mm (48 kolom)',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '58mm', label: Text('58mm')),
                          ButtonSegment(value: '80mm', label: Text('80mm')),
                        ],
                        selected: {settings.paperSize},
                        onSelectionChanged: (val) {
                          receiptService.updateSettings(
                            settings.copyWith(paperSize: val.first),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: AppColors.divider),

                  // Auto Cut Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto Cut Kertas (GS V)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    subtitle: const Text(
                      'Potong otomatis setelah kwitansi selesai dicetak',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                    value: settings.autoCut,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      receiptService.updateSettings(
                        settings.copyWith(autoCut: val),
                      );
                    },
                  ),
                  const Divider(height: 28, color: AppColors.divider),

                  // Density
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ketebalan Cetak (Density)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mengatur intensitas panas thermal',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                      DropdownButton<int>(
                        value: settings.printDensity,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Normal (1)')),
                          DropdownMenuItem(value: 2, child: Text('Tebal (2)')),
                          DropdownMenuItem(value: 3, child: Text('Sangat Tebal (3)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            receiptService.updateSettings(
                              settings.copyWith(printDensity: val),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Saved / Paired Printers List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Printer Tersimpan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.printerScan),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Scan Baru'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingPrinters)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_savedPrinters.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.print_disabled_outlined, size: 36, color: AppColors.mutedText),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum Ada Printer Tersimpan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scan Bluetooth untuk menambahkan printer thermal Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.printerScan),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Scan Bluetooth Sekarang'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedPrinters.length,
                itemBuilder: (ctx, i) {
                  final printer = _savedPrinters[i];
                  final isCurrentActive = isConnected && connectedPrinter?.macAddress == printer.macAddress;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentActive ? AppColors.primary : AppColors.border,
                        width: isCurrentActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrentActive ? AppColors.primaryLight : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.print,
                            color: isCurrentActive ? AppColors.primary : AppColors.secondaryText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    printer.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  if (printer.isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${printer.macAddress} • ${printer.paperSize}',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _handleConnect(printer),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Connect'),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
