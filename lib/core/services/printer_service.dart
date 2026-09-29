import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/database/receipt_repository.dart';
import 'package:audira_receipt/models/app_settings.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';
import 'package:audira_receipt/models/thermal_printer.dart';

class PrintResult {
  final bool success;
  final String message;
  final bool isNotConnected;
  final bool isBluetoothOff;

  PrintResult({
    required this.success,
    required this.message,
    this.isNotConnected = false,
    this.isBluetoothOff = false,
  });

  factory PrintResult.success({String message = 'Kwitansi berhasil dicetak!'}) {
    return PrintResult(success: true, message: message);
  }

  factory PrintResult.notConnected({String message = 'Printer tidak terhubung'}) {
    return PrintResult(
      success: false,
      message: message,
      isNotConnected: true,
    );
  }

  factory PrintResult.bluetoothOff({String message = 'Bluetooth belum diaktifkan'}) {
    return PrintResult(
      success: false,
      message: message,
      isBluetoothOff: true,
    );
  }

  factory PrintResult.error(String message) {
    return PrintResult(success: false, message: message);
  }
}

class PrinterService extends ChangeNotifier {
  final BluetoothService bluetoothService;
  final ReceiptRepository repository;

  bool _isPrinting = false;
  String _statusMessage = '';

  bool get isPrinting => _isPrinting;
  String get statusMessage => _statusMessage;

  PrinterService({
    required this.bluetoothService,
    required this.repository,
  });

  /// Print test page to currently connected or default printer
  Future<PrintResult> printTest({
    required String paperSize,
    required Company company,
    Uint8List? logoBytes,
  }) async {
    Uint8List? resolvedLogo = logoBytes;
    if (resolvedLogo == null && company.logo != null && company.logo!.isNotEmpty) {
      try {
        final f = File(company.logo!);
        if (await f.exists()) {
          resolvedLogo = await f.readAsBytes();
        }
      } catch (_) {}
    }

    return _executePrint(
      label: 'Test Print',
      generateBytes: () => PrinterUtils.generateTestPrintBytes(
        paperSize: paperSize,
        company: company,
        logoBytes: resolvedLogo,
      ),
    );
  }

  /// Print actual receipt with ESC/POS commands
  Future<PrintResult> printReceipt({
    required Receipt receipt,
    required Company company,
    required AppSettings settings,
    String? paperSizeOverride,
    ReceiptTemplate? template,
    TemplateConfig? customConfig,
    Uint8List? logoBytes,
  }) async {
    final effectivePaperSize = paperSizeOverride ?? settings.paperSize;

    Uint8List? resolvedLogo = logoBytes;
    final isLogoEnabled = receipt.showLogo ?? (customConfig?.showLogo ?? true);
    if (!isLogoEnabled) {
      resolvedLogo = null;
    } else if (resolvedLogo == null) {
      final customPath = receipt.logoPath ?? company.logo;
      if (customPath != null && customPath.isNotEmpty) {
        try {
          final f = File(customPath);
          if (await f.exists()) {
            resolvedLogo = await f.readAsBytes();
          }
        } catch (_) {}
      }
    }

    return _executePrint(
      label: 'Kwitansi #${receipt.receiptNumber}',
      generateBytes: () => PrinterUtils.generateReceiptEscPosBytes(
        receipt: receipt,
        company: company,
        paperSize: effectivePaperSize,
        autoCut: settings.autoCut,
        template: template,
        customConfig: customConfig,
        logoBytes: resolvedLogo,
      ),
    );
  }

  /// Core print execution pipeline
  Future<PrintResult> _executePrint({
    required String label,
    required Uint8List Function() generateBytes,
  }) async {
    _isPrinting = true;
    _statusMessage = 'Memeriksa Bluetooth...';
    notifyListeners();

    try {
      // 1. Check Bluetooth ON, auto-enable if off
      var btEnabled = await bluetoothService.isBluetoothEnabled();
      if (!btEnabled) {
        _statusMessage = 'Mengaktifkan Bluetooth...';
        notifyListeners();
        await bluetoothService.enableBluetooth();
        await Future.delayed(const Duration(milliseconds: 600));
        btEnabled = await bluetoothService.isBluetoothEnabled();
      }

      if (!btEnabled) {
        _isPrinting = false;
        _statusMessage = 'Bluetooth tidak aktif';
        notifyListeners();
        return PrintResult.bluetoothOff(
          message: 'Bluetooth belum diaktifkan. Silakan aktifkan Bluetooth di ponsel Anda.',
        );
      }

      // 2. Check Permission
      final permOk = await bluetoothService.requestPermissions();
      if (!permOk) {
        _isPrinting = false;
        _statusMessage = 'Izin Bluetooth ditolak';
        notifyListeners();
        return PrintResult.error('Izin Bluetooth belum diberikan. Mohon berikan izin di Pengaturan.');
      }

      // 3. Check Physical Connection & Auto-Reconnect
      bool isConnected = bluetoothService.isConnected;
      if (isConnected) {
        // Double check hardware RFCOMM socket is still responsive
        final isAlive = await bluetoothService.checkActualConnection();
        if (!isAlive) {
          isConnected = false;
        }
      }

      if (!isConnected) {
        _statusMessage = 'Mencari printer terdaftar...';
        notifyListeners();

        ThermalPrinter? targetPrinter = bluetoothService.connectedPrinter;
        targetPrinter ??= await repository.getDefaultPrinter();

        if (targetPrinter != null) {
          _statusMessage = 'Menyambungkan ke ${targetPrinter.name}...';
          notifyListeners();

          final connected = await bluetoothService.connect(targetPrinter);
          if (!connected) {
            _isPrinting = false;
            _statusMessage = 'Gagal tersambung';
            notifyListeners();
            final detail = bluetoothService.lastErrorMessage.isNotEmpty
                ? bluetoothService.lastErrorMessage
                : 'Tidak dapat tersambung ke printer ${targetPrinter.name} (${targetPrinter.macAddress}). Pastikan printer menyala dan dekat.';
            return PrintResult.notConnected(message: detail);
          }
        } else {
          _isPrinting = false;
          _statusMessage = 'Printer belum dipilih';
          notifyListeners();
          return PrintResult.notConnected(
            message: 'Belum ada printer yang terhubung. Silakan pilih dan sambungkan printer terlebih dahulu.',
          );
        }
      }

      // 4. Generate ESC/POS Bytes
      _statusMessage = 'Menyiapkan data cetak...';
      notifyListeners();
      final bytes = generateBytes();

      // 5. Send Bytes to Printer
      _statusMessage = 'Mengirim data ke printer...';
      notifyListeners();

      final sent = await bluetoothService.sendBytes(bytes);
      if (!sent) {
        _isPrinting = false;
        _statusMessage = 'Gagal mengirim data';
        notifyListeners();
        final detail = bluetoothService.lastErrorMessage.isNotEmpty
            ? bluetoothService.lastErrorMessage
            : 'Printer tidak merespons atau koneksi terputus saat mencetak. Pastikan printer menyala dan kertas tidak habis.';
        return PrintResult.error(detail);
      }

      _statusMessage = 'Pencetakan selesai';
      _isPrinting = false;
      notifyListeners();
      return PrintResult.success(message: 'Kwitansi berhasil dicetak!');
    } catch (e) {
      _isPrinting = false;
      _statusMessage = 'Pencetakan gagal';
      notifyListeners();
      return PrintResult.error('Printer gagal mencetak: $e');
    }
  }
}
