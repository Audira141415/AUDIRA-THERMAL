import 'dart:convert';
import 'dart:typed_data';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';

class PrinterUtils {
  PrinterUtils._();

  // ESC/POS Command bytes
  static const List<int> escInit = [0x1B, 0x40]; // Initialize / Reset
  static const List<int> escAlignLeft = [0x1B, 0x61, 0x00];
  static const List<int> escAlignCenter = [0x1B, 0x61, 0x01];
  static const List<int> escAlignRight = [0x1B, 0x61, 0x02];

  static const List<int> escBoldOn = [0x1B, 0x45, 0x01];
  static const List<int> escBoldOff = [0x1B, 0x45, 0x00];

  static const List<int> escDoubleHeightWidth = [0x1D, 0x21, 0x11];
  static const List<int> escDoubleHeight = [0x1D, 0x21, 0x01];
  static const List<int> escDoubleWidth = [0x1D, 0x21, 0x10];
  static const List<int> escNormalSize = [0x1D, 0x21, 0x00];

  static const List<int> escUnderlineOn = [0x1B, 0x2D, 0x01];
  static const List<int> escUnderlineOff = [0x1B, 0x2D, 0x00];

  static const List<int> lineFeed = [0x0A];
  static const List<int> paperCut = [0x1D, 0x56, 0x41, 0x00]; // Full cut with feed
  static const List<int> paperCutPartial = [0x1D, 0x56, 0x01]; // Partial cut

  /// Get column width based on paper type
  static int getWidth(String paperSize) {
    return paperSize == AppConstants.paper80mm
        ? AppConstants.paper80WidthChars
        : AppConstants.paper58WidthChars;
  }

  /// Divider line with custom character ('-' or '=')
  static String divider({required int width, String char = '-'}) {
    return char * width;
  }

  /// Create two-column text row aligned left and right
  static String rowTwoColumn({
    required String left,
    required String right,
    required int width,
  }) {
    final available = width - right.length;
    if (available <= 0) {
      return '$left\n$right';
    }
    if (left.length > available) {
      final truncatedLeft = left.substring(0, available > 3 ? available - 1 : available);
      final spaces = width - truncatedLeft.length - right.length;
      return '$truncatedLeft${' ' * (spaces > 0 ? spaces : 1)}$right';
    }
    final spaces = width - left.length - right.length;
    return '$left${' ' * (spaces > 0 ? spaces : 1)}$right';
  }

  /// Center align text within given width
  static String center(String text, int width) {
    if (text.length >= width) return text;
    final totalPad = width - text.length;
    final padLeft = totalPad ~/ 2;
    final padRight = totalPad - padLeft;
    return '${' ' * padLeft}$text${' ' * padRight}';
  }

  /// Wrap text into lines that do not exceed [maxWidth] characters
  static List<String> wrapText(String text, int maxWidth) {
    if (text.isEmpty) return [''];
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      if (currentLine.isEmpty) {
        if (word.length > maxWidth) {
          // Break very long single word
          for (int i = 0; i < word.length; i += maxWidth) {
            final end = (i + maxWidth < word.length) ? i + maxWidth : word.length;
            lines.add(word.substring(i, end));
          }
        } else {
          currentLine = word;
        }
      } else if (currentLine.length + 1 + word.length <= maxWidth) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        if (word.length > maxWidth) {
          for (int i = 0; i < word.length; i += maxWidth) {
            final end = (i + maxWidth < word.length) ? i + maxWidth : word.length;
            lines.add(word.substring(i, end));
          }
          currentLine = '';
        } else {
          currentLine = word;
        }
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  /// Generate full receipt formatted plain text for preview (58mm or 80mm)
  static String generateReceiptPlainText({
    required Receipt receipt,
    required Company company,
    required String paperSize,
  }) {
    final width = getWidth(paperSize);
    final is80 = paperSize == AppConstants.paper80mm;
    final buffer = StringBuffer();

    // Header
    buffer.writeln(center(company.name.toUpperCase(), width));
    if (company.address.isNotEmpty) {
      for (final line in wrapText(company.address, width)) {
        buffer.writeln(center(line, width));
      }
    }
    if (company.phone.isNotEmpty) {
      buffer.writeln(center('Telp: ${company.phone}', width));
    }
    buffer.writeln(divider(width: width, char: '='));

    // Title
    buffer.writeln(center('KWITANSI PEMBAYARAN', width));
    buffer.writeln(divider(width: width, char: '-'));

    // Meta
    buffer.writeln(rowTwoColumn(
      left: 'No : ${receipt.receiptNumber}',
      right: receipt.dateFormatted,
      width: width,
    ));
    buffer.writeln(divider(width: width, char: '-'));

    // Payer
    buffer.writeln('Telah diterima dari:');
    buffer.writeln('  ${receipt.receivedFrom.toUpperCase()}');
    buffer.writeln('');

    // Amount
    buffer.writeln('Jumlah:');
    buffer.writeln('  ${CurrencyFormatter.format(receipt.amount)}');
    buffer.writeln('');

    // Words
    buffer.writeln('Terbilang:');
    for (final line in wrapText(receipt.amountWords, width - 2)) {
      buffer.writeln('  $line');
    }
    buffer.writeln('');

    // Purpose / Description
    buffer.writeln('Untuk:');
    for (final line in wrapText(receipt.description, width - 2)) {
      buffer.writeln('  $line');
    }
    buffer.writeln('');

    // Payment method & notes
    if (is80 || receipt.paymentMethod.isNotEmpty) {
      buffer.writeln('Metode Bayar: ${receipt.paymentMethod}');
    }
    if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) {
      buffer.writeln('Catatan: ${receipt.notes!.trim()}');
    }

    buffer.writeln(divider(width: width, char: '-'));

    // Signatures
    buffer.writeln('');
    if (is80) {
      final leftSign = 'Penyetor,';
      final rightSign = 'Penerima,';
      buffer.writeln(rowTwoColumn(left: leftSign, right: rightSign, width: width));
      buffer.writeln('');
      buffer.writeln('');
      buffer.writeln('');
      buffer.writeln(rowTwoColumn(
        left: '(______________)',
        right: '(${center(company.name.split(' ').first, 14)})',
        width: width,
      ));
    } else {
      buffer.writeln(rowTwoColumn(left: '', right: 'Penerima,', width: width));
      buffer.writeln('');
      buffer.writeln('');
      buffer.writeln(rowTwoColumn(left: '', right: '(________________)', width: width));
    }

    buffer.writeln('');
    buffer.writeln(center('Terima Kasih', width));
    buffer.writeln(center('Harap simpan bukti pembayaran ini', width));
    buffer.writeln(divider(width: width, char: '='));

    return buffer.toString();
  }

  /// Generate direct ESC/POS byte sequence for thermal printer
  static Uint8List generateReceiptEscPosBytes({
    required Receipt receipt,
    required Company company,
    required String paperSize,
    bool autoCut = true,
  }) {
    final width = getWidth(paperSize);
    final is80 = paperSize == AppConstants.paper80mm;
    final bytes = BytesBuilder();

    // Initialize printer
    bytes.add(escInit);

    // Header - Center & Bold Double Size
    bytes.add(escAlignCenter);
    bytes.add(escBoldOn);
    bytes.add(escDoubleHeight);
    bytes.add(utf8.encode('${company.name.toUpperCase()}\n'));
    bytes.add(escNormalSize);
    bytes.add(escBoldOff);

    if (company.address.isNotEmpty) {
      bytes.add(utf8.encode('${company.address}\n'));
    }
    if (company.phone.isNotEmpty) {
      bytes.add(utf8.encode('Telp: ${company.phone}\n'));
    }
    bytes.add(utf8.encode('${divider(width: width, char: '=')}\n'));

    // Title
    bytes.add(escBoldOn);
    bytes.add(escDoubleHeight);
    bytes.add(utf8.encode('KWITANSI\n'));
    bytes.add(escNormalSize);
    bytes.add(escBoldOff);
    bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));

    // Align Left for content
    bytes.add(escAlignLeft);
    bytes.add(utf8.encode('${rowTwoColumn(left: 'No : ${receipt.receiptNumber}', right: receipt.dateFormatted, width: width)}\n'));
    bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));

    // Received From
    bytes.add(utf8.encode('Telah diterima dari:\n'));
    bytes.add(escBoldOn);
    bytes.add(utf8.encode('  ${receipt.receivedFrom.toUpperCase()}\n'));
    bytes.add(escBoldOff);
    bytes.add(lineFeed);

    // Amount - Emphasized
    bytes.add(utf8.encode('Jumlah:\n'));
    bytes.add(escBoldOn);
    bytes.add(escDoubleHeight);
    bytes.add(utf8.encode('  ${CurrencyFormatter.format(receipt.amount)}\n'));
    bytes.add(escNormalSize);
    bytes.add(escBoldOff);
    bytes.add(lineFeed);

    // Terbilang
    bytes.add(utf8.encode('Terbilang:\n'));
    for (final line in wrapText(receipt.amountWords, width - 2)) {
      bytes.add(utf8.encode('  $line\n'));
    }
    bytes.add(lineFeed);

    // Description
    bytes.add(utf8.encode('Untuk:\n'));
    bytes.add(escBoldOn);
    for (final line in wrapText(receipt.description, width - 2)) {
      bytes.add(utf8.encode('  $line\n'));
    }
    bytes.add(escBoldOff);
    bytes.add(lineFeed);

    // Payment method & notes
    if (receipt.paymentMethod.isNotEmpty) {
      bytes.add(utf8.encode('Metode Bayar: ${receipt.paymentMethod}\n'));
    }
    if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) {
      bytes.add(utf8.encode('Catatan: ${receipt.notes!.trim()}\n'));
    }

    bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));

    // Signatures
    bytes.add(lineFeed);
    if (is80) {
      bytes.add(utf8.encode('${rowTwoColumn(left: 'Penyetor,', right: 'Penerima,', width: width)}\n'));
      bytes.add(lineFeed);
      bytes.add(lineFeed);
      bytes.add(lineFeed);
      bytes.add(utf8.encode('${rowTwoColumn(left: '(______________)', right: '(________________)', width: width)}\n'));
    } else {
      bytes.add(utf8.encode('${rowTwoColumn(left: '', right: 'Penerima,', width: width)}\n'));
      bytes.add(lineFeed);
      bytes.add(lineFeed);
      bytes.add(utf8.encode('${rowTwoColumn(left: '', right: '(________________)', width: width)}\n'));
    }

    bytes.add(lineFeed);
    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('Terima Kasih\n'));
    bytes.add(utf8.encode('Harap simpan bukti pembayaran ini\n'));
    bytes.add(utf8.encode('${divider(width: width, char: '=')}\n'));

    // Paper feed lines before cut
    bytes.add(lineFeed);
    bytes.add(lineFeed);
    bytes.add(lineFeed);

    // Paper Cut
    if (autoCut) {
      bytes.add(paperCut);
    }

    return bytes.toBytes();
  }

  /// Generate Test Print ESC/POS bytes
  static Uint8List generateTestPrintBytes({
    required String paperSize,
    required Company company,
  }) {
    final width = getWidth(paperSize);
    final bytes = BytesBuilder();

    bytes.add(escInit);
    bytes.add(escAlignCenter);
    bytes.add(escBoldOn);
    bytes.add(escDoubleHeightWidth);
    bytes.add(utf8.encode('TEST PRINT\n'));
    bytes.add(escNormalSize);
    bytes.add(escBoldOff);
    bytes.add(utf8.encode('AUDIRA THERMAL PRINTER\n'));
    bytes.add(utf8.encode('${divider(width: width, char: '=')}\n'));

    bytes.add(escAlignLeft);
    bytes.add(utf8.encode('Status     : BERHASIL TERHUBUNG\n'));
    bytes.add(utf8.encode('Ukuran     : $paperSize\n'));
    bytes.add(utf8.encode('Lebar Kolom: $width Karakter\n'));
    bytes.add(utf8.encode('Waktu      : ${DateTime.now().toLocal().toString().split('.').first}\n'));
    bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));

    // Text Style Samples
    bytes.add(utf8.encode('Normal Text Test\n'));
    bytes.add(escBoldOn);
    bytes.add(utf8.encode('Bold Text Test\n'));
    bytes.add(escBoldOff);
    bytes.add(escUnderlineOn);
    bytes.add(utf8.encode('Underline Text Test\n'));
    bytes.add(escUnderlineOff);

    // Alignment test
    bytes.add(escAlignLeft);
    bytes.add(utf8.encode('Left Alignment\n'));
    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('Center Alignment\n'));
    bytes.add(escAlignRight);
    bytes.add(utf8.encode('Right Alignment\n'));

    // Two column test
    bytes.add(escAlignLeft);
    bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));
    bytes.add(utf8.encode('${rowTwoColumn(left: 'Item A', right: 'Rp 25.000', width: width)}\n'));
    bytes.add(utf8.encode('${rowTwoColumn(left: 'Item B', right: 'Rp 50.000', width: width)}\n'));
    bytes.add(utf8.encode('${rowTwoColumn(left: 'TOTAL', right: 'Rp 75.000', width: width)}\n'));
    bytes.add(utf8.encode('${divider(width: width, char: '=')}\n'));

    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('Printer ESC/POS Siap Digunakan!\n'));

    bytes.add(lineFeed);
    bytes.add(lineFeed);
    bytes.add(lineFeed);
    bytes.add(paperCut);

    return bytes.toBytes();
  }
}
