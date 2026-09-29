import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
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
  bool _isBluetoothOn = true;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBluetoothAndScan();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothAndScan() async {
    final btService = context.read<BluetoothService>();
    final on = await btService.isBluetoothEnabled();
    if (mounted) {
      setState(() => _isBluetoothOn = on);
    }
    if (!on) {
      final enabled = await btService.enableBluetooth();
      if (mounted) {
        setState(() => _isBluetoothOn = enabled);
      }
    }
    await _startScan();
  }

  Future<void> _startScan() async {
    final btService = context.read<BluetoothService>();
    await btService.scanPrinters();
    if (!mounted) return;
    final on = await btService.isBluetoothEnabled();
    if (!mounted) return;
    setState(() => _isBluetoothOn = on);
    if (btService.lastErrorMessage.isNotEmpty) {
      CustomDialogs.showErrorSnackBar(context, btService.lastErrorMessage);
    }
  }

  Future<void> _enableBluetoothNow() async {
    final btService = context.read<BluetoothService>();
    final success = await btService.enableBluetooth();
    if (mounted) {
      setState(() => _isBluetoothOn = success);
    }
    if (success) {
      _startScan();
    } else {
      await btService.openBluetoothSettings();
    }
  }

  Future<void> _connectToPrinter(ThermalPrinter printer) async {
    final btService = context.read<BluetoothService>();
    final repo = context.read<ReceiptRepository>();
    final receiptService = context.read<ReceiptService>();

    if (!printer.isBonded) {
      CustomDialogs.showSuccessSnackBar(
        context,
        'Memasangkan ke ${printer.name}... Jika diminta PIN di ponsel, ketik 1234 atau 0000',
      );
    }

    final printerWithConfig = printer.copyWith(
      paperSize: printer.paperSize.isNotEmpty ? printer.paperSize : receiptService.settings.paperSize,
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
            : 'Gagal terhubung ke ${printer.name}. Pastikan printer menyala dan dekat.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = context.watch<BluetoothService>();
    final isScanning = btService.isScanning;
    final pairedPrinters = btService.pairedDevices;
    final discoveredPrinters = btService.discoveredDevices;
    final allDevices = btService.availableDevices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan & Pairing Bluetooth'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_bluetooth_rounded),
            tooltip: 'Pengaturan Bluetooth HP',
            onPressed: () => btService.openBluetoothSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bluetooth OFF warning banner
          if (!_isBluetoothOn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_disabled_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bluetooth ponsel nonaktif.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _enableBluetoothNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('AKTIFKAN'),
                  ),
                ],
              ),
            ),

          // 1. Radar Pulse Animation Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isScanning) ...[
                            Container(
                              width: 100 * _radarController.value,
                              height: 100 * _radarController.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity((1 - _radarController.value) * 0.25),
                              ),
                            ),
                            Container(
                              width: 75 * _radarController.value,
                              height: 75 * _radarController.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity((1 - _radarController.value) * 0.35),
                              ),
                            ),
                          ],
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 26),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isScanning ? 'Mencari & Memindai Printer...' : 'Pencarian Selesai',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Mendukung printer yang sudah dipasangkan dan perangkat baru di sekitar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Shortcut helper for Bluetooth settings & default PIN info
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PIN default printer thermal: 1234 atau 0000',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: () => btService.openBluetoothSettings(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Buka Setting HP',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Device List (Categorized: Paired vs Discovered)
          Expanded(
            child: allDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bluetooth_searching_rounded, size: 48, color: AppColors.mutedText),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Printer Ditemukan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Pastikan printer thermal menyala, Bluetooth aktif, dan berada dekat smartphone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => btService.openBluetoothSettings(),
                          icon: const Icon(Icons.settings_bluetooth_rounded, size: 16),
                          label: const Text('Buka Pengaturan Bluetooth HP'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Section A: Perangkat Terpasang (Paired / Bonded)
                      if (pairedPrinters.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Perangkat Tersimpan / Terpasang (${pairedPrinters.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...pairedPrinters.map((p) => _buildPrinterTile(p, btService)),
                      ],

                      // Section B: Perangkat Baru Ditemukan (Unpaired / Discovered)
                      if (discoveredPrinters.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.radar_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Text(
                                'Perangkat Baru Ditemukan - Siap Pairing (${discoveredPrinters.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...discoveredPrinters.map((p) => _buildPrinterTile(p, btService)),
                      ],
                    ],
                  ),
          ),

          // 3. Bottom Button: [BERHENTI SCAN / SCAN ULANG]
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (isScanning) {
                    btService.stopScan();
                  } else {
                    _startScan();
                  }
                },
                icon: Icon(
                  isScanning ? Icons.stop_circle_outlined : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(
                  isScanning ? 'BERHENTI SCAN' : 'SCAN ULANG & CARI PRINTER',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning ? const Color(0xFF475569) : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterTile(ThermalPrinter printer, BluetoothService btService) {
    final isCurrent = btService.isConnected && btService.connectedPrinter?.macAddress == printer.macAddress;
    final isConnecting = btService.connectionState == BluetoothConnState.connecting &&
        btService.connectedPrinter?.macAddress == printer.macAddress;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.success
              : (printer.isBonded ? AppColors.border : const Color(0xFFFDE68A)),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? AppColors.successLight
                  : (printer.isBonded ? const Color(0xFFF1F5F9) : const Color(0xFFFEF3C7)),
            ),
            child: Icon(
              Icons.print_rounded,
              color: isCurrent
                  ? AppColors.success
                  : (printer.isBonded ? AppColors.secondaryText : const Color(0xFFD97706)),
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
                    Expanded(
                      child: Text(
                        printer.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (!printer.isBonded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          'BARU',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                        ),
                      ),
                  ],
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
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isConnecting ? null : () => _connectToPrinter(printer),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrent
                  ? AppColors.success
                  : (printer.isBonded ? AppColors.primary : const Color(0xFF0F766E)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            child: isConnecting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isCurrent ? 'TERHUBUNG' : (printer.isBonded ? 'HUBUNGKAN' : 'PAIR & KONEK')),
          ),
        ],
      ),
    );
  }
}
