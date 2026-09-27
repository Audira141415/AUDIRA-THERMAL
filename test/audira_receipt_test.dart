import 'package:flutter_test/flutter_test.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';

void main() {
  group('NumberToWords (Terbilang Bahasa Indonesia)', () {
    test('Converts 0 correctly', () {
      expect(NumberToWords.convert(0), equals('Nol Rupiah'));
    });

    test('Converts 1.500.000 (requested example) correctly', () {
      expect(
        NumberToWords.convert(1500000),
        equals('Satu Juta Lima Ratus Ribu Rupiah'),
      );
    });

    test('Converts 1.000 to Seribu Rupiah (not Satu Ribu)', () {
      expect(NumberToWords.convert(1000), equals('Seribu Rupiah'));
    });

    test('Converts 100 to Seratus Rupiah', () {
      expect(NumberToWords.convert(100), equals('Seratus Rupiah'));
    });

    test('Converts 11 to Sebelas Rupiah', () {
      expect(NumberToWords.convert(11), equals('Sebelas Rupiah'));
    });

    test('Converts 12.500 to Dua Belas Ribu Lima Ratus Rupiah', () {
      expect(
        NumberToWords.convert(12500),
        equals('Dua Belas Ribu Lima Ratus Rupiah'),
      );
    });

    test('Converts 8.750.000 to Delapan Juta Tujuh Ratus Lima Puluh Ribu Rupiah', () {
      expect(
        NumberToWords.convert(8750000),
        equals('Delapan Juta Tujuh Ratus Lima Puluh Ribu Rupiah'),
      );
    });

    test('Converts 1.000.000.000 to Satu Miliar Rupiah', () {
      expect(
        NumberToWords.convert(1000000000),
        equals('Satu Miliar Rupiah'),
      );
    });
  });

  group('CurrencyFormatter', () {
    test('Format with symbol', () {
      final formatted = CurrencyFormatter.format(1500000);
      expect(formatted, contains('1.500.000'));
      expect(formatted, contains('Rp'));
    });

    test('Parse string with symbol and formatting', () {
      expect(CurrencyFormatter.parse('Rp 1.500.000'), equals(1500000.0));
      expect(CurrencyFormatter.parse('1.500.000'), equals(1500000.0));
      expect(CurrencyFormatter.parse(''), equals(0.0));
    });
  });

  group('PrinterUtils and ESC/POS Generation', () {
    test('Paper width verification', () {
      expect(PrinterUtils.getWidth('58mm'), equals(32));
      expect(PrinterUtils.getWidth('80mm'), equals(48));
    });

    test('Divider generation', () {
      final div58 = PrinterUtils.divider(width: 32, char: '-');
      expect(div58.length, equals(32));
      expect(div58, equals('--------------------------------'));
    });

    test('Two column row formatting', () {
      final row = PrinterUtils.rowTwoColumn(left: 'Total', right: 'Rp 10.000', width: 32);
      expect(row.length, equals(32));
      expect(row.startsWith('Total'), isTrue);
      expect(row.endsWith('Rp 10.000'), isTrue);
    });

    test('Text wrapping does not exceed width', () {
      const text = 'Jasa Maintenance Server Bulanan Periode September 2026';
      final wrapped = PrinterUtils.wrapText(text, 30);
      for (final line in wrapped) {
        expect(line.length <= 30, isTrue);
      }
    });

    test('ESC/POS byte generation generates non-empty bytes', () {
      final receipt = Receipt(
        receiptNumber: 'AUD-2026-00001',
        date: DateTime(2026, 9, 27),
        receivedFrom: 'AGUS DWI RIANTO',
        amount: 1500000,
        amountWords: 'Satu Juta Lima Ratus Ribu Rupiah',
        description: 'Jasa Maintenance Server',
        paymentMethod: 'Tunai (Cash)',
      );

      final company = Company.defaultCompany();

      final bytes58 = PrinterUtils.generateReceiptEscPosBytes(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
        autoCut: true,
      );

      expect(bytes58.isNotEmpty, isTrue);
      // Verify initial reset ESC @
      expect(bytes58[0], equals(0x1B));
      expect(bytes58[1], equals(0x40));

      final plainText = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
      );

      expect(plainText, contains('AUD-2026-00001'));
      expect(plainText, contains('AGUS DWI RIANTO'));
      expect(plainText, contains('Jasa Maintenance Server'));
      expect(plainText, contains('KWITANSI PEMBAYARAN'));
    });
  });

  group('Models', () {
    test('Receipt model serialization', () {
      final receipt = Receipt(
        id: 1,
        receiptNumber: 'AUD-2026-00001',
        date: DateTime(2026, 9, 27),
        receivedFrom: 'Budi Santoso',
        amount: 500000,
        amountWords: 'Lima Ratus Ribu Rupiah',
        description: 'Pembelian Router',
        paymentMethod: 'Transfer Bank',
      );

      final map = receipt.toMap();
      expect(map['receipt_number'], equals('AUD-2026-00001'));
      expect(map['amount'], equals(500000.0));

      final restored = Receipt.fromMap(map);
      expect(restored.receiptNumber, equals(receipt.receiptNumber));
      expect(restored.amount, equals(receipt.amount));
      expect(restored.receivedFrom, equals(receipt.receivedFrom));
    });
  });
}
