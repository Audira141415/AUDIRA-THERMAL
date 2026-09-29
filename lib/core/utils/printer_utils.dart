import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';

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

  static const List<int> escInvertOn = [0x1D, 0x42, 0x01]; // GS B 1
  static const List<int> escInvertOff = [0x1D, 0x42, 0x00]; // GS B 0

  static const List<int> lineFeed = [0x0A];
  static const List<int> paperCut = [0x1D, 0x56, 0x41, 0x00]; // Full cut with feed
  static const List<int> paperCutPartial = [0x1D, 0x56, 0x01]; // Partial cut

  /// Generate ESC/POS command bytes to print a standard QR code
  static List<int> qrCodeBytes(String data, {int moduleSize = 5}) {
    final dataBytes = utf8.encode(data);
    final len = dataBytes.length + 3;
    final pL = len % 256;
    final pH = len ~/ 256;
    final safeSize = moduleSize.clamp(3, 8);

    return [
      // 1. Select QR Code model 2
      0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00,
      // 2. Set module size
      0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, safeSize,
      // 3. Error correction level M (49)
      0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31,
      // 4. Store data
      0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30, ...dataBytes,
      // 5. Print QR code
      0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30,
    ];
  }

  /// Generate ESC/POS command bytes to print a CODE128 barcode
  static List<int> barcodeBytes(String data, {int height = 50}) {
    final cleanData = data.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '');
    final dataBytes = utf8.encode(cleanData);
    return [
      0x1D, 0x68, height.clamp(30, 100),
      0x1D, 0x77, 0x02,
      0x1D, 0x48, 0x02,
      0x1D, 0x6B, 0x49, dataBytes.length + 2, 0x7B, 0x42, ...dataBytes,
    ];
  }

  /// Convert image bytes to ESC/POS Raster Bit Image (GS v 0) command
  static List<int> imageRasterBytes(Uint8List imageBytes, {int maxWidth = 384}) {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return [];

      img.Image processed = decoded;
      if (processed.width > maxWidth) {
        processed = img.copyResize(processed, width: maxWidth);
      }

      final widthDots = processed.width;
      final heightDots = processed.height;
      final bytesWidth = (widthDots + 7) ~/ 8;

      final raster = <int>[];

      for (int y = 0; y < heightDots; y++) {
        for (int byteIdx = 0; byteIdx < bytesWidth; byteIdx++) {
          int byteVal = 0;
          for (int bit = 0; bit < 8; bit++) {
            final x = byteIdx * 8 + bit;
            if (x < widthDots) {
              final pixel = processed.getPixel(x, y);
              final lum = pixel.luminance;
              final a = pixel.a;
              if (a > 50 && lum < 160) {
                byteVal |= (1 << (7 - bit));
              }
            }
          }
          raster.add(byteVal);
        }
      }

      final xL = bytesWidth % 256;
      final xH = bytesWidth ~/ 256;
      final yL = heightDots % 256;
      final yH = heightDots ~/ 256;

      return [
        ...escAlignCenter,
        0x1D, 0x76, 0x30, 0x00, // GS v 0 mode 0 (normal)
        xL, xH,
        yL, yH,
        ...raster,
        0x0A,
      ];
    } catch (_) {
      return [];
    }
  }

  /// Generate formatted text receipt for WhatsApp, Telegram, or SMS
  static String generateShareableText({
    required Receipt receipt,
    required Company company,
    ReceiptTemplate? template,
    TemplateConfig? customConfig,
  }) {
    final tpl = template ?? (receipt.templateId.isNotEmpty ? ReceiptTemplate.findById(receipt.templateId) : ReceiptTemplate.findById('standard_formal'));
    final cfg = customConfig ?? tpl.defaultConfig;
    final buffer = StringBuffer();

    final compName = (receipt.storeName != null && receipt.storeName!.trim().isNotEmpty)
        ? receipt.storeName!.trim()
        : company.name.trim();
    final compTagline = (receipt.storeTagline != null)
        ? receipt.storeTagline!.trim()
        : (cfg.headerSubtitle.isNotEmpty ? cfg.headerSubtitle : (cfg.showTagline ? company.tagline.trim() : ''));
    final compLegalId = (receipt.storeLegalId != null)
        ? receipt.storeLegalId!.trim()
        : cfg.businessLegalId.trim();
    final compAddress = (receipt.storeAddress != null)
        ? receipt.storeAddress!.trim()
        : company.address.trim();
    final compPhone = (receipt.storePhone != null)
        ? receipt.storePhone!.trim()
        : (cfg.contactInfo.isNotEmpty ? cfg.contactInfo : company.phone.trim());

    if (tpl.id == 'donation_zakat') {
      buffer.writeln('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      buffer.writeln('۞ *${tpl.titleHeading}* ۞');
    } else if (tpl.id == 'flagship_restaurant' || tpl.id == 'resto_cafe') {
      buffer.writeln('✦ ✦ *${tpl.titleHeading}* ✦ ✦');
    } else if (tpl.id == 'flagship_automotive' || tpl.id == 'automotive_workshop') {
      buffer.writeln('⚙️ *${tpl.titleHeading}*');
    } else if (tpl.id == 'flagship_clinic' || tpl.id == 'clinic_medical') {
      buffer.writeln('⚕️ *${tpl.titleHeading}*');
    } else if (tpl.id == 'flagship_supermarket' || tpl.id == 'minimarket_pos') {
      buffer.writeln('🛒 *${tpl.titleHeading}*');
    } else if (tpl.id == 'laundry_service') {
      buffer.writeln('🧺 *${tpl.titleHeading}*');
    } else {
      buffer.writeln('🧾 *${tpl.titleHeading}*');
    }
    if (compName.isNotEmpty) {
      buffer.writeln('*${compName.toUpperCase()}*');
    }
    if (compTagline.isNotEmpty) {
      buffer.writeln('_${compTagline}_');
    }
    if (compLegalId.isNotEmpty) {
      buffer.writeln(compLegalId);
    }
    if (compAddress.isNotEmpty) {
      buffer.writeln(compAddress);
    }
    if (compPhone.isNotEmpty) {
      final phoneFormatted = compPhone.startsWith('Telp') || compPhone.startsWith('CS') ? compPhone : 'Telp: $compPhone';
      buffer.writeln(phoneFormatted);
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('No. Bukti : *${receipt.receiptNumber}*');
    buffer.writeln('Tanggal   : ${receipt.dateFormatted}');
    if (receipt.cashierName != null && receipt.cashierName!.isNotEmpty) {
      buffer.writeln('Kasir     : ${receipt.cashierName}');
    }
    if (cfg.leherField1Label.isNotEmpty && cfg.leherField1Value.isNotEmpty) {
      buffer.writeln('${cfg.leherField1Label.padRight(10)}: ${cfg.leherField1Value}');
    }
    if (cfg.leherField2Label.isNotEmpty && cfg.leherField2Value.isNotEmpty) {
      buffer.writeln('${cfg.leherField2Label.padRight(10)}: ${cfg.leherField2Value}');
    }
    if (cfg.leherField3Label.isNotEmpty && cfg.leherField3Value.isNotEmpty) {
      buffer.writeln('${cfg.leherField3Label.padRight(10)}: ${cfg.leherField3Value}');
    }
    buffer.writeln('Status    : *[ ${receipt.status} ]*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Telah diterima dari:');
    buffer.writeln('*${receipt.receivedFrom.toUpperCase()}*');
    buffer.writeln('');
    if (receipt.items.isNotEmpty) {
      buffer.writeln('Rincian:');
      for (final item in receipt.items) {
        final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
        buffer.writeln('• ${item.name} ($qtyStr x ${CurrencyFormatter.format(item.unitPrice)}) = ${CurrencyFormatter.format(item.subtotal)}');
      }
      buffer.writeln('----------------------------');
      if (receipt.discount > 0) {
        buffer.writeln('Diskon    : -${CurrencyFormatter.format(receipt.discount)}');
      }
      if (cfg.serviceChargeAmount > 0) {
        final scLabel = cfg.serviceChargeLabel.isNotEmpty ? cfg.serviceChargeLabel : 'Layanan';
        buffer.writeln('$scLabel: +${CurrencyFormatter.format(cfg.serviceChargeAmount)}');
      }
      if (receipt.tax > 0) {
        buffer.writeln('Pajak PPN : +${CurrencyFormatter.format(receipt.tax)}');
      }
      buffer.writeln('Total     : *${CurrencyFormatter.format(receipt.amount + cfg.serviceChargeAmount)}*');
      if (receipt.cashReceived > 0) {
        buffer.writeln('Tunai     : ${CurrencyFormatter.format(receipt.cashReceived)}');
        buffer.writeln('Kembalian : ${CurrencyFormatter.format(receipt.changeAmount)}');
      }
    } else {
      buffer.writeln('Jumlah:');
      buffer.writeln('💰 *${CurrencyFormatter.format(receipt.amount)}*');
    }
    buffer.writeln('');
    buffer.writeln('Terbilang:');
    buffer.writeln('_"${receipt.amountWords}"_');
    buffer.writeln('');
    buffer.writeln('Untuk Keperluan:');
    buffer.writeln(receipt.description);
    buffer.writeln('');
    buffer.writeln('Metode Bayar : ${receipt.paymentMethod}');
    if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) {
      buffer.writeln('Catatan      : ${receipt.notes!.trim()}');
    }
    if (company.bankInfo.isNotEmpty) {
      buffer.writeln('Info Rekening: ${company.bankInfo}');
    }
    if (cfg.memberReward.isNotEmpty) {
      buffer.writeln('🎁 *Member Reward:* ${cfg.memberReward}');
    }
    if (cfg.guaranteePolicy.isNotEmpty) {
      buffer.writeln('🛡️ *Garansi:* ${cfg.guaranteePolicy}');
    }
    if (cfg.wifiInfo.isNotEmpty) {
      buffer.writeln('📶 *WiFi:* ${cfg.wifiInfo}');
    }
    if (cfg.socialMedia.isNotEmpty) {
      buffer.writeln('🌐 *Sosial Media:* ${cfg.socialMedia}');
    }
    if (cfg.promoBanner.isNotEmpty) {
      buffer.writeln('🎉 *Promo:* ${cfg.promoBanner}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (cfg.showTerms && cfg.termsText.isNotEmpty) {
      buffer.writeln('📌 *Ketentuan:*');
      buffer.writeln(cfg.termsText);
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    if (cfg.showFooter) {
      if (cfg.customFooter.isNotEmpty) {
        buffer.writeln(cfg.customFooter);
      } else if (company.footerMessage.isNotEmpty) {
        buffer.writeln(company.footerMessage);
      } else {
        buffer.writeln('Harap simpan bukti pembayaran ini.');
      }
    }
    buffer.writeln('');
    buffer.writeln('Diterbitkan oleh: *${company.name}*');

    return buffer.toString();
  }

  /// Get column width based on paper type
  static int getWidth(String paperSize) {
    if (paperSize == AppConstants.paper80mm) {
      return AppConstants.paper80WidthChars; // 48
    } else if (paperSize == AppConstants.paper48mm) {
      return AppConstants.paper48WidthChars; // 24
    } else {
      return AppConstants.paper58WidthChars; // 32
    }
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

  /// Align text within width according to alignment mode ('left', 'center', 'right')
  static String alignText(String text, int width, String align) {
    if (text.length >= width) return text;
    if (align == 'right') {
      final pad = width - text.length;
      return '${' ' * pad}$text';
    } else if (align == 'center') {
      return center(text, width);
    } else {
      return text;
    }
  }

  /// Format amount words casing ('title', 'upper', 'lower')
  static String formatAmountWords(String words, String casing) {
    if (casing == 'upper') {
      return words.toUpperCase();
    } else if (casing == 'lower') {
      return words.toLowerCase();
    } else {
      return words;
    }
  }

  // ESC/POS Font modes
  static const List<int> escFontA = [0x1B, 0x4D, 0x00]; // Standard 12x24 font
  static const List<int> escFontB = [0x1B, 0x4D, 0x01]; // Condensed 9x17 font

  /// Get ESC/POS alignment command
  static List<int> escAlign(String align) {
    if (align == 'center') return escAlignCenter;
    if (align == 'right') return escAlignRight;
    return escAlignLeft;
  }

  /// Get ESC/POS font size command
  static List<int> escFontSize(String size) {
    if (size == 'extra_large') return escDoubleHeightWidth;
    if (size == 'large') return escDoubleHeight;
    return escNormalSize;
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

  /// Generate full receipt formatted plain text for preview (48mm, 58mm, or 80mm)
  static String generateReceiptPlainText({
    required Receipt receipt,
    required Company company,
    required String paperSize,
    String copyLabel = '',
    ReceiptTemplate? template,
    TemplateConfig? customConfig,
  }) {
    final tpl = template ?? (receipt.templateId.isNotEmpty ? ReceiptTemplate.findById(receipt.templateId) : ReceiptTemplate.findById('standard_formal'));
    final cfg = customConfig ?? tpl.defaultConfig;
    final width = getWidth(paperSize);
    final is80 = paperSize == AppConstants.paper80mm;
    final is48 = paperSize == AppConstants.paper48mm;
    final sepChar = cfg.separatorChar.isNotEmpty ? cfg.separatorChar[0] : '-';
    final titleHeading = cfg.customTitle.isNotEmpty ? cfg.customTitle : tpl.titleHeading;
    final buffer = StringBuffer();

    final effectiveHeaderAlign = receipt.headerAlign.isNotEmpty ? receipt.headerAlign : cfg.headerAlign;
    final effectiveTitleAlign = receipt.titleAlign.isNotEmpty ? receipt.titleAlign : cfg.titleAlign;
    final effectiveAmountAlign = receipt.amountAlign.isNotEmpty ? receipt.amountAlign : cfg.amountAlign;
    final effectiveContentAlign = receipt.contentAlign.isNotEmpty ? receipt.contentAlign : cfg.descriptionAlign;
    final effectiveStampAlign = receipt.stampAlign.isNotEmpty ? receipt.stampAlign : cfg.stampAlign;
    final effectiveStampType = receipt.stampType.isNotEmpty ? receipt.stampType : cfg.stampType;

    // Boxed frame top border
    if (cfg.isBoxedFrame) {
      buffer.writeln('+${'-' * (width - 2)}+');
    }

    // Copy Label Banner (if multi-copy)
    if (copyLabel.isNotEmpty) {
      buffer.writeln(center('*** $copyLabel ***', width));
    }

    // Header
    final compName = (receipt.storeName != null && receipt.storeName!.trim().isNotEmpty)
        ? receipt.storeName!.trim()
        : company.name.trim();
    final compTagline = (receipt.storeTagline != null)
        ? receipt.storeTagline!.trim()
        : (cfg.headerSubtitle.isNotEmpty ? cfg.headerSubtitle : (cfg.showTagline ? company.tagline.trim() : ''));
    final compLegalId = (receipt.storeLegalId != null)
        ? receipt.storeLegalId!.trim()
        : cfg.businessLegalId.trim();
    final compAddress = (receipt.storeAddress != null)
        ? receipt.storeAddress!.trim()
        : company.address.trim();
    final compPhone = (receipt.storePhone != null)
        ? receipt.storePhone!.trim()
        : (cfg.contactInfo.isNotEmpty ? cfg.contactInfo : company.phone.trim());

    if (compName.isNotEmpty) {
      buffer.writeln(alignText(compName.toUpperCase(), width, effectiveHeaderAlign));
    }
    if (compTagline.isNotEmpty) {
      buffer.writeln(alignText(compTagline, width, effectiveHeaderAlign));
    }
    if (compLegalId.isNotEmpty) {
      buffer.writeln(alignText(compLegalId, width, effectiveHeaderAlign));
    }
    if (compAddress.isNotEmpty) {
      for (final line in wrapText(compAddress, width)) {
        buffer.writeln(alignText(line, width, effectiveHeaderAlign));
      }
    }
    if (compPhone.isNotEmpty) {
      final phoneStr = compPhone.startsWith('Telp') || compPhone.startsWith('CS') ? compPhone : 'Telp: $compPhone';
      buffer.writeln(alignText(phoneStr, width, effectiveHeaderAlign));
    }
    buffer.writeln(divider(width: width, char: sepChar == '-' ? '=' : sepChar));

    // Title & Status
    if (tpl.id == 'donation_zakat') {
      buffer.writeln(center('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', width));
      buffer.writeln(center('۞ $titleHeading ۞', width));
    } else if (tpl.id == 'flagship_restaurant' || tpl.id == 'resto_cafe') {
      buffer.writeln(center('✦ ✦ $titleHeading ✦ ✦', width));
    } else if (tpl.id == 'flagship_supermarket' || tpl.id == 'minimarket_pos') {
      buffer.writeln(center('=== $titleHeading ===', width));
    } else if (tpl.id == 'flagship_automotive' || tpl.id == 'automotive_workshop') {
      buffer.writeln(center('=== NOTA SERVIS KENDARAAN ===', width));
    } else if (tpl.id == 'flagship_clinic' || tpl.id == 'clinic_medical') {
      buffer.writeln(center('[ ⚕️ PELAYANAN MEDIS & RESEP ]', width));
    } else if (tpl.id == 'event_ticket' || tpl.id == 'parking_ticket') {
      buffer.writeln(center('✂ - - - - - - - - - - ✂', width));
      buffer.writeln(center(titleHeading, width));
    } else {
      buffer.writeln(alignText(titleHeading, width, effectiveTitleAlign));
    }
    if (effectiveStampType != 'none') {
      final stampDisplay = effectiveStampType == 'custom' && cfg.customStampText.isNotEmpty
          ? cfg.customStampText
          : (effectiveStampType == 'auto' ? receipt.status : effectiveStampType.toUpperCase());
      buffer.writeln(alignText('[ $stampDisplay ]', width, effectiveStampAlign));
    }
    buffer.writeln(divider(width: width, char: sepChar));

    // Meta (No & Tgl)
    if (cfg.showReceiptNumber && cfg.showDate) {
      if (is48) {
        buffer.writeln('No : ${receipt.receiptNumber}');
        buffer.writeln('Tgl: ${receipt.dateFormatted}');
      } else {
        buffer.writeln(rowTwoColumn(
          left: 'No : ${receipt.receiptNumber}',
          right: receipt.dateFormatted,
          width: width,
        ));
      }
    } else if (cfg.showReceiptNumber) {
      buffer.writeln('No : ${receipt.receiptNumber}');
    } else if (cfg.showDate) {
      buffer.writeln('Tgl: ${receipt.dateFormatted}');
    }

    if (receipt.cashierName != null && receipt.cashierName!.isNotEmpty) {
      buffer.writeln('Kasir: ${receipt.cashierName}');
    }

    // Leher Custom Meta Fields
    if (cfg.leherField1Label.isNotEmpty && cfg.leherField1Value.isNotEmpty) {
      buffer.writeln(rowTwoColumn(
        left: '${cfg.leherField1Label}:',
        right: cfg.leherField1Value,
        width: width,
      ));
    }
    if (cfg.leherField2Label.isNotEmpty && cfg.leherField2Value.isNotEmpty) {
      buffer.writeln(rowTwoColumn(
        left: '${cfg.leherField2Label}:',
        right: cfg.leherField2Value,
        width: width,
      ));
    }
    if (cfg.leherField3Label.isNotEmpty && cfg.leherField3Value.isNotEmpty) {
      buffer.writeln(rowTwoColumn(
        left: '${cfg.leherField3Label}:',
        right: cfg.leherField3Value,
        width: width,
      ));
    }
    buffer.writeln(divider(width: width, char: sepChar));

    // Payer (Diterima Dari)
    if (cfg.showReceivedFrom && (receipt.receivedFrom.isNotEmpty || (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty))) {
      final label = cfg.labelReceivedFrom.isNotEmpty ? cfg.labelReceivedFrom : 'Telah diterima dari:';
      buffer.writeln(alignText(label, width, effectiveContentAlign));
      String payerName = receipt.receivedFrom.isNotEmpty ? receipt.receivedFrom.toUpperCase() : '';
      if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty) {
        payerName += (payerName.isNotEmpty ? ' (${receipt.customerPhone})' : receipt.customerPhone!);
      }
      buffer.writeln(alignText(payerName, width, effectiveContentAlign));
      buffer.writeln('');
    }

    // Items Table or Single Amount
    if (receipt.items.isNotEmpty) {
      buffer.writeln(divider(width: width, char: '-'));
      for (final item in receipt.items) {
        buffer.writeln(item.name);
        final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
        final unitStr = CurrencyFormatter.format(item.unitPrice, withSymbol: false);
        final subtotalStr = CurrencyFormatter.format(item.subtotal);
        buffer.writeln(rowTwoColumn(
          left: '  $qtyStr x $unitStr',
          right: subtotalStr,
          width: width,
        ));
      }
      buffer.writeln(divider(width: width, char: '-'));
      final hasDiscountsOrTaxes = receipt.discount > 0 || receipt.tax > 0 || cfg.serviceChargeAmount > 0;
      if (hasDiscountsOrTaxes) {
        buffer.writeln(rowTwoColumn(left: 'Subtotal:', right: CurrencyFormatter.format(receipt.itemsSubtotal), width: width));
        if (receipt.discount > 0) {
          buffer.writeln(rowTwoColumn(left: 'Diskon:', right: '-${CurrencyFormatter.format(receipt.discount)}', width: width));
        }
        if (cfg.serviceChargeAmount > 0) {
          final scLabel = cfg.serviceChargeLabel.isNotEmpty ? cfg.serviceChargeLabel : 'Layanan:';
          buffer.writeln(rowTwoColumn(left: scLabel, right: '+${CurrencyFormatter.format(cfg.serviceChargeAmount)}', width: width));
        }
        if (receipt.tax > 0) {
          buffer.writeln(rowTwoColumn(left: 'Pajak (PPN):', right: '+${CurrencyFormatter.format(receipt.tax)}', width: width));
        }
        buffer.writeln(divider(width: width, char: '-'));
      }
      final grandTotal = receipt.amount + cfg.serviceChargeAmount;
      buffer.writeln(rowTwoColumn(left: 'TOTAL:', right: CurrencyFormatter.format(grandTotal), width: width));
      if (receipt.cashReceived > 0) {
        buffer.writeln(rowTwoColumn(left: 'TUNAI:', right: CurrencyFormatter.format(receipt.cashReceived), width: width));
        final diff = receipt.cashReceived - grandTotal;
        buffer.writeln(rowTwoColumn(left: 'KEMBALIAN:', right: CurrencyFormatter.format(diff > 0 ? diff : 0), width: width));
      }
      buffer.writeln('');
    } else {
      // Amount (Jumlah Uang)
      if (cfg.showAmount) {
        final label = cfg.labelAmount.isNotEmpty ? cfg.labelAmount : 'Jumlah:';
        final formattedAmount = CurrencyFormatter.format(receipt.amount);
        buffer.writeln(alignText(label, width, effectiveAmountAlign));
        buffer.writeln(alignText(formattedAmount, width, effectiveAmountAlign));
        if (receipt.discount > 0) {
          buffer.writeln(rowTwoColumn(left: 'Diskon:', right: '-${CurrencyFormatter.format(receipt.discount)}', width: width));
        }
        if (receipt.tax > 0) {
          buffer.writeln(rowTwoColumn(left: 'Pajak:', right: '+${CurrencyFormatter.format(receipt.tax)}', width: width));
        }
        if (receipt.cashReceived > 0) {
          buffer.writeln(rowTwoColumn(left: 'TUNAI:', right: CurrencyFormatter.format(receipt.cashReceived), width: width));
          buffer.writeln(rowTwoColumn(left: 'KEMBALI:', right: CurrencyFormatter.format(receipt.changeAmount), width: width));
        }
        buffer.writeln('');
      }
    }

    // Words (Terbilang)
    if (cfg.showAmountWords) {
      final label = cfg.labelAmountWords.isNotEmpty ? cfg.labelAmountWords : 'Terbilang:';
      final formattedWords = formatAmountWords(receipt.amountWords, cfg.amountWordsCase);
      buffer.writeln(alignText(label, width, cfg.amountWordsAlign));
      for (final line in wrapText(formattedWords, width - 2)) {
        buffer.writeln(alignText(line, width, cfg.amountWordsAlign));
      }
      buffer.writeln('');
    }

    // Purpose / Description
    if (cfg.showDescription && receipt.description.isNotEmpty) {
      final label = cfg.labelDescription.isNotEmpty ? cfg.labelDescription : 'Untuk:';
      buffer.writeln(alignText(label, width, effectiveContentAlign));
      for (final line in wrapText(receipt.description, width - 2)) {
        buffer.writeln(alignText(line, width, effectiveContentAlign));
      }
      buffer.writeln('');
    }

    // Payment method & notes
    if (cfg.showPaymentMethod && (is80 || receipt.paymentMethod.isNotEmpty)) {
      final pmLabel = cfg.labelPaymentMethod.isNotEmpty ? cfg.labelPaymentMethod : 'Metode Bayar:';
      buffer.writeln('$pmLabel ${receipt.paymentMethod}');
    }
    if (cfg.showNotes && receipt.notes != null && receipt.notes!.trim().isNotEmpty) {
      buffer.writeln('Catatan: ${receipt.notes!.trim()}');
    }
    if (cfg.showBankInfo && company.bankInfo.isNotEmpty) {
      buffer.writeln('Info Rekening: ${company.bankInfo}');
    }

    buffer.writeln(divider(width: width, char: sepChar));

    // Barcode ASCII in text preview
    final shouldShowBarcode = receipt.showBarcode ?? cfg.showBarcode;
    if (shouldShowBarcode) {
      final barcodeVal = (receipt.barcodeData != null && receipt.barcodeData!.trim().isNotEmpty)
          ? receipt.barcodeData!.trim()
          : receipt.receiptNumber;
      buffer.writeln(center('||||||| | ||||| ||||||| |', width));
      buffer.writeln(center('* $barcodeVal *', width));
      buffer.writeln('');
    }

    // Signatures
    if (cfg.showSignatures && cfg.signatureType != 'none') {
      buffer.writeln('');
      final signerDisplay = company.signerName.isNotEmpty
          ? company.signerName
          : (company.name.split(' ').first);
      final signerRole = cfg.signerTitle.isNotEmpty ? cfg.signerTitle : 'Penerima';

      if (cfg.signatureType == 'dual' || is80) {
        const leftSign = 'Penyetor,';
        final rightSign = '$signerRole,';
        buffer.writeln(rowTwoColumn(left: leftSign, right: rightSign, width: width));
        buffer.writeln('');
        buffer.writeln('');
        buffer.writeln('');
        buffer.writeln(rowTwoColumn(
          left: '(______________)',
          right: '(${center(signerDisplay, is48 ? 10 : 14)})',
          width: width,
        ));
      } else {
        buffer.writeln(rowTwoColumn(left: '', right: '$signerRole,', width: width));
        buffer.writeln('');
        buffer.writeln('');
        buffer.writeln(rowTwoColumn(left: '', right: '(${center(signerDisplay, is48 ? 10 : 14)})', width: width));
      }
    }

    // Member Reward / Point
    if (cfg.memberReward.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(center('[ ${cfg.memberReward} ]', width));
    }

    // Guarantee Policy
    if (cfg.guaranteePolicy.isNotEmpty) {
      buffer.writeln('');
      for (final line in wrapText('🛡️ Garansi: ${cfg.guaranteePolicy}', width)) {
        buffer.writeln(alignText(line, width, cfg.footerAlign));
      }
    }

    // Terms & Conditions
    if (cfg.showTerms && cfg.termsText.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(alignText('--- Ketentuan ---', width, cfg.termsAlign));
      for (final line in wrapText(cfg.termsText, width)) {
        buffer.writeln(alignText(line, width, cfg.termsAlign));
      }
    }

    // WiFi Info
    if (cfg.wifiInfo.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(alignText('WiFi: ${cfg.wifiInfo}', width, cfg.footerAlign));
    }

    // Social Media
    if (cfg.socialMedia.isNotEmpty) {
      buffer.writeln(alignText(cfg.socialMedia, width, cfg.footerAlign));
    }

    // Promo Banner
    if (cfg.promoBanner.isNotEmpty) {
      buffer.writeln('');
      for (final line in wrapText('★ ${cfg.promoBanner}', width)) {
        buffer.writeln(alignText(line, width, cfg.footerAlign));
      }
    }

    // Footer
    buffer.writeln('');
    if (cfg.showFooter) {
      final footer = cfg.customFooter.isNotEmpty
          ? cfg.customFooter
          : (company.footerMessage.isNotEmpty ? company.footerMessage : 'Terima Kasih\nHarap simpan bukti pembayaran ini');
      for (final line in wrapText(footer, width)) {
        buffer.writeln(alignText(line, width, cfg.footerAlign));
      }
    }

    // Boxed bottom frame or divider
    if (cfg.isBoxedFrame) {
      buffer.writeln('+${'-' * (width - 2)}+');
    } else {
      buffer.writeln(divider(width: width, char: sepChar == '-' ? '=' : sepChar));
    }

    return buffer.toString();
  }

  /// Generate direct ESC/POS byte sequence for thermal printer
  static Uint8List generateReceiptEscPosBytes({
    required Receipt receipt,
    required Company company,
    required String paperSize,
    bool autoCut = true,
    String copyLabel = '',
    bool includeQrCode = true,
    ReceiptTemplate? template,
    TemplateConfig? customConfig,
    Uint8List? logoBytes,
  }) {
    final tpl = template ?? ReceiptTemplate.allTemplates.first;
    final cfg = customConfig ?? tpl.defaultConfig;
    final width = getWidth(paperSize);
    final is80 = paperSize == AppConstants.paper80mm;
    final is48 = paperSize == AppConstants.paper48mm;
    final sepChar = cfg.separatorChar.isNotEmpty ? cfg.separatorChar[0] : '-';
    final titleHeading = cfg.customTitle.isNotEmpty ? cfg.customTitle : tpl.titleHeading;
    final bytes = BytesBuilder();

    final effectiveHeaderAlign = receipt.headerAlign.isNotEmpty ? receipt.headerAlign : cfg.headerAlign;
    final effectiveTitleAlign = receipt.titleAlign.isNotEmpty ? receipt.titleAlign : cfg.titleAlign;
    final effectiveAmountAlign = receipt.amountAlign.isNotEmpty ? receipt.amountAlign : cfg.amountAlign;
    final effectiveContentAlign = receipt.contentAlign.isNotEmpty ? receipt.contentAlign : cfg.descriptionAlign;
    final effectiveStampAlign = receipt.stampAlign.isNotEmpty ? receipt.stampAlign : cfg.stampAlign;
    final effectiveTitleFontSize = receipt.titleFontSize.isNotEmpty ? receipt.titleFontSize : cfg.titleFontSize;
    final effectiveAmountFontSize = receipt.amountFontSize.isNotEmpty ? receipt.amountFontSize : cfg.amountFontSize;
    final effectiveBoldTitle = receipt.isBoldTitle;
    final effectiveBoldAmount = receipt.isBoldAmount;
    final effectiveCondensed = receipt.isCondensed || cfg.fontCondensed;
    final effectiveStampType = receipt.stampType.isNotEmpty ? receipt.stampType : cfg.stampType;

    // Initialize printer
    bytes.add(escInit);

    // Font selection (Condensed Font B vs Standard Font A)
    if (effectiveCondensed) {
      bytes.add(escFontB);
    } else {
      bytes.add(escFontA);
    }

    // Logo (Monochrome Raster Bit Image)
    if (logoBytes != null && logoBytes.isNotEmpty) {
      final maxLogoWidth = is80 ? 400 : (is48 ? 240 : 320);
      final raster = imageRasterBytes(logoBytes, maxWidth: maxLogoWidth);
      if (raster.isNotEmpty) {
        bytes.add(raster);
      }
    }

    // Multi-copy watermark banner
    if (copyLabel.isNotEmpty) {
      bytes.add(escAlignCenter);
      bytes.add(escBoldOn);
      bytes.add(utf8.encode('*** $copyLabel ***\n'));
      bytes.add(escBoldOff);
    }

    // Header alignment
    bytes.add(escAlign(effectiveHeaderAlign));

    // Invert header if enabled
    if (cfg.invertHeader) {
      bytes.add(escInvertOn);
    }

    final compName = (receipt.storeName != null && receipt.storeName!.trim().isNotEmpty)
        ? receipt.storeName!.trim()
        : company.name.trim();
    final compTagline = (receipt.storeTagline != null)
        ? receipt.storeTagline!.trim()
        : (cfg.headerSubtitle.isNotEmpty ? cfg.headerSubtitle : (cfg.showTagline ? company.tagline.trim() : ''));
    final compLegalId = (receipt.storeLegalId != null)
        ? receipt.storeLegalId!.trim()
        : cfg.businessLegalId.trim();
    final compAddress = (receipt.storeAddress != null)
        ? receipt.storeAddress!.trim()
        : company.address.trim();
    final compPhone = (receipt.storePhone != null)
        ? receipt.storePhone!.trim()
        : (cfg.contactInfo.isNotEmpty ? cfg.contactInfo : company.phone.trim());

    if (compName.isNotEmpty) {
      if (cfg.boldCompanyName) bytes.add(escBoldOn);
      bytes.add(escDoubleHeight);
      bytes.add(utf8.encode('${compName.toUpperCase()}\n'));
      bytes.add(escNormalSize);
      if (cfg.boldCompanyName) bytes.add(escBoldOff);
    }

    if (compTagline.isNotEmpty) {
      bytes.add(utf8.encode('$compTagline\n'));
    }
    if (compLegalId.isNotEmpty) {
      bytes.add(utf8.encode('$compLegalId\n'));
    }
    if (compAddress.isNotEmpty) {
      bytes.add(utf8.encode('$compAddress\n'));
    }
    if (compPhone.isNotEmpty) {
      final phoneFormatted = compPhone.startsWith('Telp') || compPhone.startsWith('CS') ? compPhone : 'Telp: $compPhone';
      bytes.add(utf8.encode('$phoneFormatted\n'));
    }

    if (cfg.invertHeader) {
      bytes.add(escInvertOff);
    }

    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('${divider(width: width, char: sepChar == '-' ? '=' : sepChar)}\n'));

    // Title Alignment & Typography
    bytes.add(escAlign(effectiveTitleAlign));
    if (effectiveBoldTitle) bytes.add(escBoldOn);
    bytes.add(escFontSize(effectiveTitleFontSize));
    bytes.add(utf8.encode('$titleHeading\n'));
    bytes.add(escNormalSize);
    if (effectiveBoldTitle) bytes.add(escBoldOff);

    // Status Badge
    if (effectiveStampType != 'none') {
      final stampDisplay = effectiveStampType == 'custom' && cfg.customStampText.isNotEmpty
          ? cfg.customStampText
          : (effectiveStampType == 'auto' ? receipt.status : effectiveStampType.toUpperCase());
      bytes.add(escAlign(effectiveStampAlign));
      bytes.add(escBoldOn);
      bytes.add(utf8.encode('[ $stampDisplay ]\n'));
      bytes.add(escBoldOff);
    }
    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('${divider(width: width, char: sepChar)}\n'));

    // Meta (No & Tgl)
    bytes.add(escAlignLeft);
    if (cfg.showReceiptNumber && cfg.showDate) {
      if (is48) {
        bytes.add(utf8.encode('No : ${receipt.receiptNumber}\n'));
        bytes.add(utf8.encode('Tgl: ${receipt.dateFormatted}\n'));
      } else {
        bytes.add(utf8.encode('${rowTwoColumn(left: 'No : ${receipt.receiptNumber}', right: receipt.dateFormatted, width: width)}\n'));
      }
    } else if (cfg.showReceiptNumber) {
      bytes.add(utf8.encode('No : ${receipt.receiptNumber}\n'));
    } else if (cfg.showDate) {
      bytes.add(utf8.encode('Tgl: ${receipt.dateFormatted}\n'));
    }

    if (receipt.cashierName != null && receipt.cashierName!.isNotEmpty) {
      bytes.add(utf8.encode('Kasir: ${receipt.cashierName}\n'));
    }

    // Leher Custom Meta Fields
    if (cfg.leherField1Label.isNotEmpty && cfg.leherField1Value.isNotEmpty) {
      bytes.add(utf8.encode('${rowTwoColumn(left: '${cfg.leherField1Label}:', right: cfg.leherField1Value, width: width)}\n'));
    }
    if (cfg.leherField2Label.isNotEmpty && cfg.leherField2Value.isNotEmpty) {
      bytes.add(utf8.encode('${rowTwoColumn(left: '${cfg.leherField2Label}:', right: cfg.leherField2Value, width: width)}\n'));
    }
    if (cfg.leherField3Label.isNotEmpty && cfg.leherField3Value.isNotEmpty) {
      bytes.add(utf8.encode('${rowTwoColumn(left: '${cfg.leherField3Label}:', right: cfg.leherField3Value, width: width)}\n'));
    }
    bytes.add(utf8.encode('${divider(width: width, char: sepChar)}\n'));

    // Received From
    if (cfg.showReceivedFrom && (receipt.receivedFrom.isNotEmpty || (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty))) {
      final label = cfg.labelReceivedFrom.isNotEmpty ? cfg.labelReceivedFrom : 'Telah diterima dari:';
      bytes.add(escAlign(effectiveContentAlign));
      bytes.add(utf8.encode('$label\n'));
      if (cfg.boldReceivedFrom) bytes.add(escBoldOn);
      String payer = receipt.receivedFrom.isNotEmpty ? receipt.receivedFrom.toUpperCase() : '';
      if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty) {
        payer += (payer.isNotEmpty ? ' (${receipt.customerPhone})' : receipt.customerPhone!);
      }
      bytes.add(utf8.encode('  $payer\n'));
      if (cfg.boldReceivedFrom) bytes.add(escBoldOff);
      bytes.add(lineFeed);
    }

    // Items table or single amount
    if (receipt.items.isNotEmpty) {
      bytes.add(escAlignLeft);
      bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));
      for (final item in receipt.items) {
        bytes.add(utf8.encode('${item.name}\n'));
        final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
        final unitStr = CurrencyFormatter.format(item.unitPrice, withSymbol: false);
        final subtotalStr = CurrencyFormatter.format(item.subtotal);
        bytes.add(utf8.encode('${rowTwoColumn(left: '  $qtyStr x $unitStr', right: subtotalStr, width: width)}\n'));
      }
      bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));
      final hasDiscountsOrTaxes = receipt.discount > 0 || receipt.tax > 0 || cfg.serviceChargeAmount > 0;
      if (hasDiscountsOrTaxes) {
        bytes.add(utf8.encode('${rowTwoColumn(left: 'Subtotal:', right: CurrencyFormatter.format(receipt.itemsSubtotal), width: width)}\n'));
        if (receipt.discount > 0) {
          bytes.add(utf8.encode('${rowTwoColumn(left: 'Diskon:', right: '-${CurrencyFormatter.format(receipt.discount)}', width: width)}\n'));
        }
        if (cfg.serviceChargeAmount > 0) {
          final scLabel = cfg.serviceChargeLabel.isNotEmpty ? cfg.serviceChargeLabel : 'Layanan:';
          bytes.add(utf8.encode('${rowTwoColumn(left: scLabel, right: '+${CurrencyFormatter.format(cfg.serviceChargeAmount)}', width: width)}\n'));
        }
        if (receipt.tax > 0) {
          bytes.add(utf8.encode('${rowTwoColumn(left: 'Pajak (PPN):', right: '+${CurrencyFormatter.format(receipt.tax)}', width: width)}\n'));
        }
        bytes.add(utf8.encode('${divider(width: width, char: '-')}\n'));
      }
      if (effectiveBoldAmount) bytes.add(escBoldOn);
      bytes.add(escFontSize(effectiveAmountFontSize));
      final grandTotal = receipt.amount + cfg.serviceChargeAmount;
      bytes.add(utf8.encode('${rowTwoColumn(left: 'TOTAL:', right: CurrencyFormatter.format(grandTotal), width: width)}\n'));
      bytes.add(escNormalSize);
      if (effectiveBoldAmount) bytes.add(escBoldOff);

      if (receipt.cashReceived > 0) {
        bytes.add(utf8.encode('${rowTwoColumn(left: 'TUNAI:', right: CurrencyFormatter.format(receipt.cashReceived), width: width)}\n'));
        final diff = receipt.cashReceived - grandTotal;
        bytes.add(utf8.encode('${rowTwoColumn(left: 'KEMBALIAN:', right: CurrencyFormatter.format(diff > 0 ? diff : 0), width: width)}\n'));
      }
      bytes.add(lineFeed);
    } else {
      // Amount - Emphasized
      if (cfg.showAmount) {
        final label = cfg.labelAmount.isNotEmpty ? cfg.labelAmount : 'Jumlah:';
        bytes.add(escAlign(effectiveAmountAlign));
        bytes.add(utf8.encode('$label\n'));
        if (effectiveBoldAmount) bytes.add(escBoldOn);
        bytes.add(escFontSize(effectiveAmountFontSize));
        bytes.add(utf8.encode('  ${CurrencyFormatter.format(receipt.amount)}\n'));
        bytes.add(escNormalSize);
        if (effectiveBoldAmount) bytes.add(escBoldOff);
        if (receipt.discount > 0) {
          bytes.add(utf8.encode('${rowTwoColumn(left: 'Diskon:', right: '-${CurrencyFormatter.format(receipt.discount)}', width: width)}\n'));
        }
        if (receipt.tax > 0) {
          bytes.add(utf8.encode('${rowTwoColumn(left: 'Pajak:', right: '+${CurrencyFormatter.format(receipt.tax)}', width: width)}\n'));
        }
        if (receipt.cashReceived > 0) {
          bytes.add(utf8.encode('${rowTwoColumn(left: 'TUNAI:', right: CurrencyFormatter.format(receipt.cashReceived), width: width)}\n'));
          bytes.add(utf8.encode('${rowTwoColumn(left: 'KEMBALI:', right: CurrencyFormatter.format(receipt.changeAmount), width: width)}\n'));
        }
        bytes.add(lineFeed);
      }
    }

    // Terbilang
    if (cfg.showAmountWords) {
      final label = cfg.labelAmountWords.isNotEmpty ? cfg.labelAmountWords : 'Terbilang:';
      final formattedWords = formatAmountWords(receipt.amountWords, cfg.amountWordsCase);
      bytes.add(escAlign(cfg.amountWordsAlign));
      bytes.add(utf8.encode('$label\n'));
      for (final line in wrapText(formattedWords, width - 2)) {
        bytes.add(utf8.encode('  $line\n'));
      }
      bytes.add(lineFeed);
    }

    // Description
    if (cfg.showDescription && receipt.description.isNotEmpty) {
      final label = cfg.labelDescription.isNotEmpty ? cfg.labelDescription : 'Untuk:';
      bytes.add(escAlign(effectiveContentAlign));
      bytes.add(utf8.encode('$label\n'));
      if (cfg.boldDescription) bytes.add(escBoldOn);
      for (final line in wrapText(receipt.description, width - 2)) {
        bytes.add(utf8.encode('  $line\n'));
      }
      if (cfg.boldDescription) bytes.add(escBoldOff);
      bytes.add(lineFeed);
    }

    // Payment method & notes
    bytes.add(escAlignLeft);
    if (cfg.showPaymentMethod && receipt.paymentMethod.isNotEmpty) {
      final pmLabel = cfg.labelPaymentMethod.isNotEmpty ? cfg.labelPaymentMethod : 'Metode Bayar:';
      bytes.add(utf8.encode('$pmLabel ${receipt.paymentMethod}\n'));
    }
    if (cfg.showNotes && receipt.notes != null && receipt.notes!.trim().isNotEmpty) {
      bytes.add(utf8.encode('Catatan: ${receipt.notes!.trim()}\n'));
    }
    if (cfg.showBankInfo && company.bankInfo.isNotEmpty) {
      bytes.add(utf8.encode('Info Rek: ${company.bankInfo}\n'));
    }

    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('${divider(width: width, char: sepChar)}\n'));

    // Barcode (CODE128)
    final shouldShowBarcode = receipt.showBarcode ?? cfg.showBarcode;
    if (shouldShowBarcode) {
      final barcodeVal = (receipt.barcodeData != null && receipt.barcodeData!.trim().isNotEmpty)
          ? receipt.barcodeData!.trim()
          : receipt.receiptNumber;
      bytes.add(lineFeed);
      bytes.add(escAlignCenter);
      try {
        bytes.add(barcodeBytes(barcodeVal));
      } catch (_) {}
      bytes.add(lineFeed);
    }

    // Signatures
    if (cfg.showSignatures && cfg.signatureType != 'none') {
      bytes.add(lineFeed);
      final signerDisplay = company.signerName.isNotEmpty
          ? company.signerName
          : (company.name.split(' ').first);
      final signerRole = cfg.signerTitle.isNotEmpty ? cfg.signerTitle : 'Penerima';

      if (cfg.signatureType == 'dual' || is80) {
        bytes.add(utf8.encode('${rowTwoColumn(left: 'Penyetor,', right: '$signerRole,', width: width)}\n'));
        bytes.add(lineFeed);
        bytes.add(lineFeed);
        bytes.add(lineFeed);
        bytes.add(utf8.encode('${rowTwoColumn(left: '(______________)', right: '(${center(signerDisplay, is48 ? 10 : 14)})', width: width)}\n'));
      } else {
        bytes.add(utf8.encode('${rowTwoColumn(left: '', right: '$signerRole,', width: width)}\n'));
        bytes.add(lineFeed);
        bytes.add(lineFeed);
        bytes.add(utf8.encode('${rowTwoColumn(left: '', right: '(${center(signerDisplay, is48 ? 10 : 14)})', width: width)}\n'));
      }
    }

    // Member Reward / Point
    if (cfg.memberReward.isNotEmpty) {
      bytes.add(lineFeed);
      bytes.add(escAlignCenter);
      bytes.add(utf8.encode('[ ${cfg.memberReward} ]\n'));
    }

    // Guarantee Policy
    if (cfg.guaranteePolicy.isNotEmpty) {
      bytes.add(lineFeed);
      bytes.add(escAlign(cfg.footerAlign));
      for (final line in wrapText('Garansi: ${cfg.guaranteePolicy}', width)) {
        bytes.add(utf8.encode('$line\n'));
      }
    }

    // Terms
    if (cfg.showTerms && cfg.termsText.isNotEmpty) {
      bytes.add(lineFeed);
      bytes.add(escAlign(cfg.termsAlign));
      bytes.add(utf8.encode('--- Ketentuan ---\n'));
      for (final line in wrapText(cfg.termsText, width)) {
        bytes.add(utf8.encode('$line\n'));
      }
    }

    // WiFi Info
    if (cfg.wifiInfo.isNotEmpty) {
      bytes.add(lineFeed);
      bytes.add(escAlign(cfg.footerAlign));
      bytes.add(utf8.encode('WiFi: ${cfg.wifiInfo}\n'));
    }

    // Social Media
    if (cfg.socialMedia.isNotEmpty) {
      bytes.add(escAlign(cfg.footerAlign));
      bytes.add(utf8.encode('${cfg.socialMedia}\n'));
    }

    // Promo Banner
    if (cfg.promoBanner.isNotEmpty) {
      bytes.add(lineFeed);
      bytes.add(escAlign(cfg.footerAlign));
      for (final line in wrapText('★ ${cfg.promoBanner}', width)) {
        bytes.add(utf8.encode('$line\n'));
      }
    }

    // QR Code printing for verification (if enabled)
    if (includeQrCode && cfg.showQrCode) {
      bytes.add(lineFeed);
      bytes.add(escAlignCenter);
      try {
        bytes.add(qrCodeBytes(receipt.receiptNumber, moduleSize: is48 ? 4 : 5));
      } catch (_) {}
      bytes.add(lineFeed);
    }

    // Footer
    if (cfg.showFooter) {
      bytes.add(lineFeed);
      bytes.add(escAlign(cfg.footerAlign));
      if (cfg.customFooter.isNotEmpty) {
        bytes.add(utf8.encode('${cfg.customFooter}\n'));
      } else if (company.footerMessage.isNotEmpty) {
        bytes.add(utf8.encode('${company.footerMessage}\n'));
      } else {
        bytes.add(utf8.encode('Terima Kasih\n'));
        bytes.add(utf8.encode('Harap simpan bukti pembayaran ini\n'));
      }
    }
    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('${divider(width: width, char: sepChar == '-' ? '=' : sepChar)}\n'));

    // Blank lines at end before cut
    final endLines = cfg.blankLinesAtEnd.clamp(1, 6);
    for (int i = 0; i < endLines; i++) {
      bytes.add(lineFeed);
    }

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
    Uint8List? logoBytes,
  }) {
    final width = getWidth(paperSize);
    final bytes = BytesBuilder();

    bytes.add(escInit);
    if (logoBytes != null && logoBytes.isNotEmpty) {
      final raster = imageRasterBytes(logoBytes, maxWidth: 320);
      if (raster.isNotEmpty) {
        bytes.add(raster);
      }
    }
    bytes.add(escAlignCenter);
    bytes.add(escBoldOn);
    bytes.add(escDoubleHeightWidth);
    bytes.add(utf8.encode('TEST PRINT\n'));
    bytes.add(escNormalSize);
    bytes.add(escBoldOff);
    bytes.add(utf8.encode('AUDIRA THERMAL PRINTER\n'));
    bytes.add(utf8.encode('${divider(width: width, char: '=')}\n'));

    bytes.add(escAlignLeft);
    if (width <= 24) {
      bytes.add(utf8.encode('Status: TERHUBUNG\n'));
      bytes.add(utf8.encode('Kertas: $paperSize\n'));
      bytes.add(utf8.encode('Kolom : $width Karakter\n'));
      bytes.add(utf8.encode('Waktu : ${DateTime.now().toLocal().toString().substring(0, 16)}\n'));
    } else {
      bytes.add(utf8.encode('Status     : BERHASIL TERHUBUNG\n'));
      bytes.add(utf8.encode('Ukuran     : $paperSize\n'));
      bytes.add(utf8.encode('Lebar Kolom: $width Karakter\n'));
      bytes.add(utf8.encode('Waktu      : ${DateTime.now().toLocal().toString().split('.').first}\n'));
    }
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
