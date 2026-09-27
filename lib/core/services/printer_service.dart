import 'package:flutter/foundation.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/database/receipt_repository.dart';
import 'package:audira_receipt/models/app_settings.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';

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
  }) async {
    return _executePrint(
      label: 'Test Print',
      generateBytes: () => PrinterUtils.generateTestPrintBytes(
        paperSize: paperSize,
        company: company,
      ),
    );
  }

  /// Print actual receipt with ESC/POS commands
  Future<PrintResult> printReceipt({
    required Receipt receipt,
    required Company company,
    required AppSettings settings,
  }) async {
    return _executePrint(
      label: 'Kwitansi #${receipt.receiptNumber}',
      generateBytes: () => PrinterUtils.generateReceiptEscPosBytes(
        receipt: receipt,
        company: company,
        paperSize: settings.paperSize,
        autoCut: settings.autoCut,
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
      // 1. Check Bluetooth ON
      final btEnabled = await bluetoothService.isBluetoothEnabled();
      if (!btEnabled) {
        _isPrinting = false;
        _statusMessage = 'Bluetooth tidak aktif';
        notifyListeners();
        return PrintResult.bluetoothOff();
      }

      // 2. Check Permission
      final permOk = await bluetoothService.requestPermissions();
      if (!permOk) {
        _isPrinting = false;
        _statusMessage = 'Izin Bluetooth ditolak';
        notifyListeners();
        return PrintResult.error('Izin Bluetooth belum diberikan.');
      }

      // 3. Check Connection
      if (!bluetoothService.isConnected) {
        // Try auto connecting to default printer from database
        _statusMessage = 'Mencari printer default...';
        notifyListeners();

        final defaultPrinter = await repository.getDefaultPrinter();
        if (defaultPrinter != null) {
          _statusMessage = 'Menyambungkan ke ${defaultPrinter.name}...';
          notifyListeners();

          final connected = await bluetoothService.connect(defaultPrinter);
          if (!connected) {
            _isPrinting = false;
            _statusMessage = 'Gagal tersambung';
            notifyListeners();
            return PrintResult.notConnected(
              message: 'Tidak dapat tersambung ke printer ${defaultPrinter.name}.',
            );
          }
        } else {
          _isPrinting = false;
          _statusMessage = 'Printer belum dipilih';
          notifyListeners();
          return PrintResult.notConnected(
            message: 'Belum ada printer yang terhubung.',
          );
        }
      }

      // 4. Generate ESC/POS Bytes
      _statusMessage = 'Menyiapkan data cetak ESC/POS...';
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
        return PrintResult.error('Printer gagal mencetak. Silakan periksa koneksi printer.');
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
