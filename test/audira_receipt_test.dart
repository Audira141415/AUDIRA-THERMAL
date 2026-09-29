import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/pdf_receipt_service.dart';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/product.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';

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
    test('Paper width verification for 48mm, 58mm, 80mm', () {
      expect(PrinterUtils.getWidth('48mm'), equals(24));
      expect(PrinterUtils.getWidth('58mm'), equals(32));
      expect(PrinterUtils.getWidth('80mm'), equals(48));
    });

    test('Divider generation for 48mm and 58mm', () {
      final div48 = PrinterUtils.divider(width: 24, char: '-');
      expect(div48.length, equals(24));
      expect(div48, equals('------------------------'));

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

      // Test 48mm generation
      final bytes48 = PrinterUtils.generateReceiptEscPosBytes(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper48mm,
        autoCut: false,
      );
      expect(bytes48.isNotEmpty, isTrue);
      expect(bytes48[0], equals(0x1B));
      expect(bytes48[1], equals(0x40));

      final plainText48 = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper48mm,
      );
      expect(plainText48, contains('No : AUD-2026-00001'));
      expect(plainText48, contains('Tgl: 27/09/2026'));
      expect(plainText48, contains('========================'));

      // Also test with custom '-' separator config
      final customPlain = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper48mm,
        customConfig: const TemplateConfig(separatorChar: '-'),
      );
      expect(customPlain, contains('------------------------'));
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

  group('AppDateFormatter (Indonesian Safe Formatting)', () {
    test('formatLong produces proper Indonesian month names', () {
      final date = DateTime(2026, 9, 28);
      expect(AppDateFormatter.formatLong(date), equals('28 September 2026'));
    });

    test('formatLongWithTime produces date and time', () {
      final dateTime = DateTime(2026, 9, 28, 14, 30);
      expect(AppDateFormatter.formatLongWithTime(dateTime), equals('28 September 2026 • 14:30'));
    });

    test('formatShort produces dd/MM/yyyy', () {
      final date = DateTime(2026, 9, 28);
      expect(AppDateFormatter.formatShort(date), equals('28/09/2026'));
    });

    test('formatShortWithTime produces dd/MM/yyyy HH:mm', () {
      final dateTime = DateTime(2026, 9, 28, 8, 5);
      expect(AppDateFormatter.formatShortWithTime(dateTime), equals('28/09/2026 08:05'));
    });
  });

  group('Receipt Templates (22+ Templates Engine)', () {
    test('ReceiptTemplate has at least 22 templates', () {
      expect(ReceiptTemplate.allTemplates.length, greaterThanOrEqualTo(22));
    });

    test('All templates have unique IDs, names, and descriptions', () {
      final ids = <String>{};
      for (final tpl in ReceiptTemplate.allTemplates) {
        expect(ids.contains(tpl.id), isFalse, reason: 'Duplicate template ID: ${tpl.id}');
        ids.add(tpl.id);
        expect(tpl.name.isNotEmpty, isTrue);
        expect(tpl.category.isNotEmpty, isTrue);
        expect(tpl.titleHeading.isNotEmpty, isTrue);
      }
    });

    test('ReceiptTemplate.findById retrieves accurately with fallback', () {
      final retail = ReceiptTemplate.findById('retail_store');
      expect(retail.id, equals('retail_store'));

      final fallback = ReceiptTemplate.findById('non_existent_id');
      expect(fallback.id, equals('standard_formal'));
    });

    test('TemplateConfig serialization is symmetric', () {
      const original = TemplateConfig(
        invertHeader: true,
        headerAlign: 'left',
        separatorChar: '*',
        showReceiptNumber: false,
        showBarcode: true,
        signerTitle: 'General Manager',
        customFooter: 'Barang yang dibeli tidak dapat ditukar',
      );

      final map = original.toMap();
      final restored = TemplateConfig.fromMap(map);

      expect(restored.invertHeader, equals(original.invertHeader));
      expect(restored.headerAlign, equals(original.headerAlign));
      expect(restored.separatorChar, equals(original.separatorChar));
      expect(restored.showReceiptNumber, equals(original.showReceiptNumber));
      expect(restored.showBarcode, equals(original.showBarcode));
      expect(restored.signerTitle, equals(original.signerTitle));
      expect(restored.customFooter, equals(original.customFooter));
    });

    test('All 22+ templates generate valid ESC/POS bytes across all paper sizes', () {
      final sampleReceipt = Receipt(
        id: 1,
        receiptNumber: 'AUD-2026-TEST',
        date: DateTime.now(),
        receivedFrom: 'PT AUDI TEST SEJAHTERA',
        amount: 2500000,
        amountWords: 'Dua Juta Lima Ratus Ribu Rupiah',
        description: 'Layanan Pengujian Sistem Thermal',
        paymentMethod: 'Transfer Bank',
        status: 'LUNAS',
        notes: 'Semua fitur template berjalan sempurna',
      );

      final sampleCompany = Company(
        name: 'AUDIRA DIGITAL',
        tagline: 'Thermal Receipt System',
        address: 'Jl. Merdeka No. 45 Jakarta',
        phone: '08123456789',
        email: 'info@audira.id',
        bankInfo: 'BCA 12345678',
      );

      for (final tpl in ReceiptTemplate.allTemplates) {
        // Test 48mm
        final bytes48 = PrinterUtils.generateReceiptEscPosBytes(
          receipt: sampleReceipt,
          company: sampleCompany,
          paperSize: AppConstants.paper48mm,
          template: tpl,
        );
        expect(bytes48.isNotEmpty, isTrue, reason: 'Failed 48mm for ${tpl.id}');

        // Test 58mm
        final bytes58 = PrinterUtils.generateReceiptEscPosBytes(
          receipt: sampleReceipt,
          company: sampleCompany,
          paperSize: AppConstants.paper58mm,
          template: tpl,
        );
        expect(bytes58.isNotEmpty, isTrue, reason: 'Failed 58mm for ${tpl.id}');

        // Test 80mm
        final bytes80 = PrinterUtils.generateReceiptEscPosBytes(
          receipt: sampleReceipt,
          company: sampleCompany,
          paperSize: AppConstants.paper80mm,
          template: tpl,
        );
        expect(bytes80.isNotEmpty, isTrue, reason: 'Failed 80mm for ${tpl.id}');

        // Test Plain Text
        final text = PrinterUtils.generateReceiptPlainText(
          receipt: sampleReceipt,
          company: sampleCompany,
          paperSize: AppConstants.paper58mm,
          template: tpl,
        );
        expect(text.isNotEmpty, isTrue);
        expect(text, contains(tpl.titleHeading));
      }
    });

    test('TemplateConfig full customization serialization (font, alignment, custom labels)', () {
      const customCfg = TemplateConfig(
        headerAlign: 'right',
        titleAlign: 'left',
        receivedFromAlign: 'center',
        amountAlign: 'right',
        amountWordsAlign: 'center',
        descriptionAlign: 'right',
        notesAlign: 'center',
        footerAlign: 'left',
        termsAlign: 'right',
        stampAlign: 'left',
        titleFontSize: 'extra_large',
        amountFontSize: 'extra_large',
        fontCondensed: true,
        boldTitle: false,
        boldAmount: false,
        boldCompanyName: false,
        boldReceivedFrom: false,
        boldDescription: false,
        italicAmountWords: true,
        amountWordsCase: 'upper',
        customTitle: 'FAKTUR PEMBAYARAN KHUSUS',
        labelReceivedFrom: 'Nama Pasien:',
        labelAmount: 'Total Tagihan:',
        labelAmountWords: 'Ejaan Rupiah:',
        labelDescription: 'Rincian Tindakan:',
        labelPaymentMethod: 'Sistem Bayar:',
        currencySymbol: 'IDR',
        blankLinesAtEnd: 4,
        isBoxedFrame: true,
      );

      final map = customCfg.toMap();
      final restored = TemplateConfig.fromMap(map);

      expect(restored.headerAlign, equals('right'));
      expect(restored.titleAlign, equals('left'));
      expect(restored.receivedFromAlign, equals('center'));
      expect(restored.amountAlign, equals('right'));
      expect(restored.titleFontSize, equals('extra_large'));
      expect(restored.fontCondensed, isTrue);
      expect(restored.amountWordsCase, equals('upper'));
      expect(restored.customTitle, equals('FAKTUR PEMBAYARAN KHUSUS'));
      expect(restored.labelReceivedFrom, equals('Nama Pasien:'));
      expect(restored.labelAmount, equals('Total Tagihan:'));
      expect(restored.currencySymbol, equals('IDR'));
      expect(restored.blankLinesAtEnd, equals(4));
      expect(restored.isBoxedFrame, isTrue);
    });

    test('ReceiptTemplate.getPresets returns contextual chips for various templates', () {
      final bengkelPresets = ReceiptTemplate.getPresets('automotive_workshop');
      expect(bengkelPresets.isNotEmpty, isTrue);
      expect(bengkelPresets.any((p) => p.contains('Oli') || p.contains('Servis')), isTrue);

      final kostPresets = ReceiptTemplate.getPresets('property_rent');
      expect(kostPresets.isNotEmpty, isTrue);
      expect(kostPresets.any((p) => p.contains('Kost') || p.contains('Sewa')), isTrue);

      final retailPresets = ReceiptTemplate.getPresets('retail_store');
      expect(retailPresets.isNotEmpty, isTrue);

      final fallbackPresets = ReceiptTemplate.getPresets('unknown_template');
      expect(fallbackPresets.isNotEmpty, isTrue);
    });

    test('PrinterUtils.alignText and formatAmountWords work correctly', () {
      final left = PrinterUtils.alignText('TEST', 10, 'left');
      expect(left, equals('TEST'));

      final center = PrinterUtils.alignText('TEST', 10, 'center');
      expect(center.trim(), equals('TEST'));
      expect(center.length, equals(10));

      final right = PrinterUtils.alignText('TEST', 10, 'right');
      expect(right, equals('      TEST'));

      expect(PrinterUtils.formatAmountWords('Satu Juta', 'upper'), equals('SATU JUTA'));
      expect(PrinterUtils.formatAmountWords('Satu Juta', 'lower'), equals('satu juta'));
      expect(PrinterUtils.formatAmountWords('Satu Juta', 'title'), equals('Satu Juta'));
    });

    test('Receipt model supports templateId serialization', () {
      final receipt = Receipt(
        id: 10,
        receiptNumber: 'AUD-2026-0010',
        date: DateTime.now(),
        receivedFrom: 'Budi Santoso',
        amount: 500000,
        amountWords: 'Lima Ratus Ribu Rupiah',
        description: 'Servis Motor',
        paymentMethod: 'Tunai',
        templateId: 'automotive_workshop',
      );

      final map = receipt.toMap();
      expect(map['template_id'], equals('automotive_workshop'));

      final fromMap = Receipt.fromMap(map);
      expect(fromMap.templateId, equals('automotive_workshop'));

      final copied = receipt.copyWith(templateId: 'retail_store');
      expect(copied.templateId, equals('retail_store'));
    });
  });

  group('Product (Master Data Model)', () {
    test('Product creation with defaults', () {
      final p = Product(name: 'Kopi Susu Gula Aren', unitPrice: 18000);
      expect(p.name, equals('Kopi Susu Gula Aren'));
      expect(p.unitPrice, equals(18000));
      expect(p.category, equals('Umum'));
      expect(p.code, isNull);
    });

    test('Product serialization toMap and fromMap is symmetric', () {
      final now = DateTime.now();
      final p = Product(
        id: 42,
        name: 'Paket Servis Ringan',
        code: 'SRV-001',
        unitPrice: 125000,
        category: 'Jasa',
        createdAt: now,
        updatedAt: now,
      );

      final map = p.toMap();
      expect(map['id'], equals(42));
      expect(map['name'], equals('Paket Servis Ringan'));
      expect(map['code'], equals('SRV-001'));
      expect(map['unit_price'], equals(125000.0));
      expect(map['category'], equals('Jasa'));

      final restored = Product.fromMap(map);
      expect(restored.id, equals(p.id));
      expect(restored.name, equals(p.name));
      expect(restored.code, equals(p.code));
      expect(restored.unitPrice, equals(p.unitPrice));
      expect(restored.category, equals(p.category));
    });

    test('Product copyWith updates selected fields', () {
      final p = Product(name: 'Teh Manis', unitPrice: 5000);
      final updated = p.copyWith(unitPrice: 6000, category: 'Minuman');
      expect(updated.name, equals('Teh Manis'));
      expect(updated.unitPrice, equals(6000));
      expect(updated.category, equals('Minuman'));
    });
  });

  group('Thermal ESC/POS Raster Logo Engine', () {
    test('imageRasterBytes generates valid ESC/POS GS v 0 raster bytes', () {
      // Create a small 16x16 test image (black square on white background)
      final testImg = img.Image(width: 16, height: 16);
      img.fill(testImg, color: img.ColorRgb8(255, 255, 255));
      // Draw a black dot in the center
      for (int y = 4; y < 12; y++) {
        for (int x = 4; x < 12; x++) {
          testImg.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      final pngBytes = img.encodePng(testImg);

      final raster = PrinterUtils.imageRasterBytes(pngBytes, maxWidth: 384);
      expect(raster.isNotEmpty, isTrue);

      // Verify GS v 0 mode 0 header (0x1D, 0x76, 0x30, 0x00)
      expect(raster.contains(0x1D), isTrue);
      final gsIdx = raster.indexOf(0x1D);
      expect(raster[gsIdx + 1], equals(0x76));
      expect(raster[gsIdx + 2], equals(0x30));
      expect(raster[gsIdx + 3], equals(0x00));
    });

    test('generateReceiptEscPosBytes includes logo raster bytes when logoBytes is passed', () {
      final receipt = Receipt(
        receiptNumber: 'AUD-2026-LOGO',
        date: DateTime.now(),
        receivedFrom: 'Test Pelanggan',
        amount: 250000,
        amountWords: 'Dua Ratus Lima Puluh Ribu Rupiah',
        description: 'Uji Coba Cetak Logo',
        paymentMethod: 'QRIS',
      );
      final company = Company.defaultCompany();

      final testImg = img.Image(width: 16, height: 16);
      img.fill(testImg, color: img.ColorRgb8(0, 0, 0));
      final pngBytes = img.encodePng(testImg);

      final bytes = PrinterUtils.generateReceiptEscPosBytes(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
        logoBytes: pngBytes,
      );

      expect(bytes.isNotEmpty, isTrue);
      // Contains GS v 0 (0x1D, 0x76, 0x30)
      bool containsGsV0 = false;
      for (int i = 0; i < bytes.length - 3; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x30) {
          containsGsV0 = true;
          break;
        }
      }
      expect(containsGsV0, isTrue);
    });
  });

  group('PDF Kwitansi & Thermal Roll Generator', () {
    test('PdfReceiptService generates valid Formal A5 PDF document', () async {
      final receipt = Receipt(
        receiptNumber: 'AUD-2026-PDF01',
        date: DateTime.now(),
        receivedFrom: 'PT Teknologi Digital',
        amount: 3500000,
        amountWords: 'Tiga Juta Lima Ratus Ribu Rupiah',
        description: 'Jasa Pembuatan Software POS Thermal',
        paymentMethod: 'Transfer Bank',
        discount: 100000,
        tax: 385000,
        items: [
          ReceiptItem(id: '1', name: 'Lisensi Sistem', quantity: 1, unitPrice: 3000000),
          ReceiptItem(id: '2', name: 'Konfigurasi Printer Bluetooth', quantity: 1, unitPrice: 500000),
        ],
      );
      final company = Company.defaultCompany();

      final pdfBytes = await PdfReceiptService.generatePdfBytes(
        receipt: receipt,
        company: company,
        isThermalRoll: false,
      );
      expect(pdfBytes.isNotEmpty, isTrue);

      // Verify PDF Magic Bytes (%PDF-)
      final magic = utf8.decode(pdfBytes.sublist(0, 5));
      expect(magic, equals('%PDF-'));
    });

    test('PdfReceiptService generates valid Thermal Roll PDF document', () async {
      final receipt = Receipt(
        receiptNumber: 'AUD-2026-ROLL01',
        date: DateTime.now(),
        receivedFrom: 'Bpk. Hendra',
        amount: 45000,
        amountWords: 'Empat Puluh Lima Ribu Rupiah',
        description: 'Pembelian Makanan & Minuman',
        paymentMethod: 'Tunai (Cash)',
      );
      final company = Company.defaultCompany();

      final pdfBytes = await PdfReceiptService.generatePdfBytes(
        receipt: receipt,
        company: company,
        isThermalRoll: true,
        paperSize: AppConstants.paper58mm,
      );
      expect(pdfBytes.isNotEmpty, isTrue);

      // Verify PDF Magic Bytes
      final magic = utf8.decode(pdfBytes.sublist(0, 5));
      expect(magic, equals('%PDF-'));
    });
  });

  group('Diskon & Pajak Dynamic Calculations', () {
    test('Calculates discount presets correctly', () {
      const subtotal = 200000.0;
      expect((subtotal * 0.05).roundToDouble(), equals(10000.0));
      expect((subtotal * 0.10).roundToDouble(), equals(20000.0));
      expect((subtotal * 0.15).roundToDouble(), equals(30000.0));
      expect((subtotal * 0.20).roundToDouble(), equals(40000.0));
    });

    test('Calculates tax presets (PPN 11% & 12%) correctly', () {
      const subtotal = 200000.0;
      expect((subtotal * 0.11).roundToDouble(), equals(22000.0));
      expect((subtotal * 0.12).roundToDouble(), equals(24000.0));
      expect((subtotal * 0.10).roundToDouble(), equals(20000.0));
    });

    test('Total calculation with discount and tax', () {
      const subtotal = 500000.0;
      final discount = (subtotal * 0.10).roundToDouble(); // 50.000
      final tax = (subtotal * 0.11).roundToDouble();      // 55.000
      final total = subtotal - discount + tax;            // 505.000
      expect(total, equals(505000.0));
    });
  });

  group('Multi-Toko & Multi-Perusahaan Store Identity', () {
    test('Receipt serialization with custom store identity is symmetric', () {
      final now = DateTime.now();
      final r = Receipt(
        id: 99,
        receiptNumber: 'RCP-TOKO-01',
        date: now,
        receivedFrom: 'Budi Santoso',
        amount: 150000,
        amountWords: 'Seratus Lima Puluh Ribu Rupiah',
        description: 'Pembelian Bahan Pokok',
        paymentMethod: 'Tunai (Cash)',
        storeName: 'TOKO KELONTONG BERKAH',
        storeTagline: 'Pusat Belanja Hemat & Murah',
        storeLegalId: 'NPWP: 09.876.543.2-123.000',
        storeAddress: 'Pasar Baru Blok A No. 12',
        storePhone: '0812-3456-7890',
        createdAt: now,
        updatedAt: now,
      );

      final map = r.toMap();
      expect(map['store_name'], equals('TOKO KELONTONG BERKAH'));
      expect(map['store_tagline'], equals('Pusat Belanja Hemat & Murah'));
      expect(map['store_legal_id'], equals('NPWP: 09.876.543.2-123.000'));
      expect(map['store_address'], equals('Pasar Baru Blok A No. 12'));
      expect(map['store_phone'], equals('0812-3456-7890'));

      final restored = Receipt.fromMap(map);
      expect(restored.storeName, equals('TOKO KELONTONG BERKAH'));
      expect(restored.storeTagline, equals('Pusat Belanja Hemat & Murah'));
      expect(restored.storeLegalId, equals('NPWP: 09.876.543.2-123.000'));
      expect(restored.storeAddress, equals('Pasar Baru Blok A No. 12'));
      expect(restored.storePhone, equals('0812-3456-7890'));
    });

    test('PrinterUtils prints custom store header from receipt', () {
      final company = Company.defaultCompany();
      final receipt = Receipt(
        receiptNumber: 'RCP-002',
        date: DateTime.now(),
        receivedFrom: 'Siti Aminah',
        amount: 250000,
        amountWords: 'Dua Ratus Lima Puluh Ribu Rupiah',
        description: 'Belanja Sayur',
        paymentMethod: 'QRIS',
        storeName: 'WARUNG MAKAN NUSANTARA',
        storeTagline: 'Masakan Khas Tradisional',
        storeLegalId: 'NIB: 9120038471',
        storeAddress: 'Jl. Merdeka No. 45',
        storePhone: '0821-1234-5678',
      );

      final text = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
      );

      expect(text.contains('WARUNG MAKAN NUSANTARA'), isTrue);
      expect(text.contains('Masakan Khas Tradisional'), isTrue);
      expect(text.contains('NIB: 9120038471'), isTrue);
      expect(text.contains('Jl. Merdeka No. 45'), isTrue);
      expect(text.contains('0821-1234-5678'), isTrue);
      // Fallback dummy NPWP from template must NOT appear
      expect(text.contains('01.345.678.9-012.000'), isFalse);
    });

    test('PrinterUtils completely omits empty store fields without forced fallback', () {
      final company = Company(
        name: '',
        tagline: '',
        address: '',
        phone: '',
        email: '',
      );
      final receipt = Receipt(
        receiptNumber: 'RCP-BLANK-01',
        date: DateTime.now(),
        receivedFrom: 'Anonim',
        amount: 50000,
        amountWords: 'Lima Puluh Ribu Rupiah',
        description: 'Tanpa Header',
        paymentMethod: 'Tunai',
        storeName: '',
        storeTagline: '',
        storeLegalId: '',
        storeAddress: '',
        storePhone: '',
      );

      final text = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
      );

      expect(text.contains('NPWP'), isFalse);
      expect(text.contains('NIB'), isFalse);
      expect(text.contains('Telp:'), isFalse);
      expect(text.contains('Jl. Ahmad Yani'), isFalse);
    });
  });

  group('Custom Logo Upload & 1D Barcode Support', () {
    test('Receipt model serialization with logo and barcode fields is symmetric', () {
      final receipt = Receipt(
        receiptNumber: 'RCP-LOGO-BC-01',
        date: DateTime.parse('2026-03-28 14:30:00'),
        receivedFrom: 'Budi Santoso',
        amount: 150000,
        amountWords: 'Seratus Lima Puluh Ribu Rupiah',
        description: 'Pembelian Aksesoris Komputer',
        paymentMethod: 'Transfer QRIS',
        logoPath: '/data/user/0/com.audira.receipt/app_flutter/store_logo_custom.png',
        showLogo: true,
        showBarcode: true,
        barcodeData: 'TRK-2026-998877',
      );

      final map = receipt.toMap();
      expect(map['logo_path'], equals('/data/user/0/com.audira.receipt/app_flutter/store_logo_custom.png'));
      expect(map['show_logo'], equals(1));
      expect(map['show_barcode'], equals(1));
      expect(map['barcode_data'], equals('TRK-2026-998877'));

      final restored = Receipt.fromMap(map);
      expect(restored.logoPath, equals(receipt.logoPath));
      expect(restored.showLogo, isTrue);
      expect(restored.showBarcode, isTrue);
      expect(restored.barcodeData, equals('TRK-2026-998877'));
    });

    test('PrinterUtils prints custom barcodeData in plain text receipt', () {
      final company = Company(name: 'Toko Maju', address: 'Jl. Merdeka', phone: '08123', email: 'toko@majujaya.com');
      final receipt = Receipt(
        receiptNumber: 'INV-001',
        date: DateTime.now(),
        receivedFrom: 'Dewi',
        amount: 75000,
        amountWords: 'Tujuh Puluh Lima Ribu Rupiah',
        description: 'Snack Box',
        paymentMethod: 'Tunai',
        showBarcode: true,
        barcodeData: 'BARCODE-CUSTOM-999',
      );

      final text = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
      );

      expect(text.contains('BARCODE-CUSTOM-999'), isTrue);
    });

    test('PrinterUtils omits barcode when showBarcode is explicitly false', () {
      final company = Company(name: 'Toko Maju', address: 'Jl. Merdeka', phone: '08123', email: 'toko@majujaya.com');
      final receipt = Receipt(
        receiptNumber: 'INV-002',
        date: DateTime.now(),
        receivedFrom: 'Dewi',
        amount: 75000,
        amountWords: 'Tujuh Puluh Lima Ribu Rupiah',
        description: 'Snack Box',
        paymentMethod: 'Tunai',
        showBarcode: false,
      );

      final text = PrinterUtils.generateReceiptPlainText(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
      );

      expect(text.contains('||||||| | |||||'), isFalse);
    });

    test('PrinterUtils generates valid ESC/POS bytes with CODE128 barcode', () {
      final company = Company(name: 'Toko Maju', address: 'Jl. Merdeka', phone: '08123', email: 'toko@majujaya.com');
      final receipt = Receipt(
        receiptNumber: 'INV-003',
        date: DateTime.now(),
        receivedFrom: 'Dewi',
        amount: 75000,
        amountWords: 'Tujuh Puluh Lima Ribu Rupiah',
        description: 'Snack Box',
        paymentMethod: 'Tunai',
        showBarcode: true,
        barcodeData: 'CODE128-POS-DATA',
      );

      final bytes = PrinterUtils.generateReceiptEscPosBytes(
        receipt: receipt,
        company: company,
        paperSize: AppConstants.paper58mm,
      );

      expect(bytes.isNotEmpty, isTrue);
      // Verify GS k (0x1D 0x6B) barcode command is in byte stream
      bool hasBarcodeCommand = false;
      for (int i = 0; i < bytes.length - 2; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x6B) {
          hasBarcodeCommand = true;
          break;
        }
      }
      expect(hasBarcodeCommand, isTrue);
    });

    test('PdfReceiptService generates thermal roll PDF with barcode', () async {
      final company = Company(name: 'Toko Maju', address: 'Jl. Merdeka', phone: '08123', email: 'toko@majujaya.com');
      final receipt = Receipt(
        receiptNumber: 'PDF-BC-01',
        date: DateTime.now(),
        receivedFrom: 'Pelanggan',
        amount: 80000,
        amountWords: 'Delapan Puluh Ribu Rupiah',
        description: 'Produk Belanja',
        paymentMethod: 'Tunai',
        showBarcode: true,
        barcodeData: 'PDF-BARCODE-128',
      );

      final pdfBytes = await PdfReceiptService.generatePdfBytes(
        receipt: receipt,
        company: company,
        isThermalRoll: true,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
