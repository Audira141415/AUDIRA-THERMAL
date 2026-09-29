import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';

class PdfReceiptService {
  PdfReceiptService._();

  /// Generate PDF bytes for receipt
  static Future<Uint8List> generatePdfBytes({
    required Receipt receipt,
    required Company company,
    ReceiptTemplate? template,
    bool isThermalRoll = false,
    String paperSize = '58mm',
  }) async {
    final pdf = pw.Document();
    final tpl = template ?? (receipt.templateId.isNotEmpty ? ReceiptTemplate.findById(receipt.templateId) : ReceiptTemplate.findById('standard_formal'));

    if (isThermalRoll) {
      // Thermal paper roll format (58mm or 80mm width)
      final rollWidth = paperSize == '80mm' ? 80 * PdfPageFormat.mm : 58 * PdfPageFormat.mm;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(rollWidth, double.infinity, marginAll: 8),
          build: (pw.Context context) {
            return _buildThermalRollContent(receipt, company, tpl);
          },
        ),
      );
    } else {
      // Formal A5 / Half-A4 Page Format
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return _buildFormalDocumentContent(receipt, company, tpl);
          },
        ),
      );
    }

    return await pdf.save();
  }

  /// Print directly via Android / System Print Manager
  static Future<void> printPdf({
    required Receipt receipt,
    required Company company,
    ReceiptTemplate? template,
    bool isThermalRoll = false,
    String paperSize = '58mm',
  }) async {
    final bytes = await generatePdfBytes(
      receipt: receipt,
      company: company,
      template: template,
      isThermalRoll: isThermalRoll,
      paperSize: paperSize,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Kwitansi_${receipt.receiptNumber}.pdf',
    );
  }

  /// Save PDF file to temporary directory
  static Future<File> savePdfFile({
    required Receipt receipt,
    required Company company,
    ReceiptTemplate? template,
    bool isThermalRoll = false,
  }) async {
    final bytes = await generatePdfBytes(
      receipt: receipt,
      company: company,
      template: template,
      isThermalRoll: isThermalRoll,
    );

    final tempDir = await getTemporaryDirectory();
    final cleanNum = receipt.receiptNumber.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '_');
    final file = File('${tempDir.path}/kwitansi_$cleanNum.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Share PDF file via WhatsApp, Email, Drive, etc.
  static Future<void> sharePdf({
    required Receipt receipt,
    required Company company,
    ReceiptTemplate? template,
    bool isThermalRoll = false,
  }) async {
    final file = await savePdfFile(
      receipt: receipt,
      company: company,
      template: template,
      isThermalRoll: isThermalRoll,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Kwitansi Pembayaran #${receipt.receiptNumber}',
      text: 'Berikut lampiran file kwitansi digital #${receipt.receiptNumber} dari ${company.name}',
    );
  }

  // =========================================================================
  // FORMAL A5 DOCUMENT LAYOUT
  // =========================================================================
  static pw.Widget _buildFormalDocumentContent(
    Receipt receipt,
    Company company,
    ReceiptTemplate template,
  ) {
    const primaryColor = PdfColor.fromInt(0xFF1E3A8A); // Deep Navy Blue
    const grayColor = PdfColor.fromInt(0xFF64748B);
    const borderColor = PdfColor.fromInt(0xFFE2E8F0);

    pw.MemoryImage? logoImage;
    final isLogoEnabled = receipt.showLogo ?? template.defaultConfig.showLogo;
    if (isLogoEnabled) {
      final customPath = receipt.logoPath ?? company.logo;
      if (customPath != null && customPath.isNotEmpty) {
        try {
          final f = File(customPath);
          if (f.existsSync()) {
            logoImage = pw.MemoryImage(f.readAsBytesSync());
          }
        } catch (_) {}
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header: Company Logo / Name & Document Title
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null) ...[
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (company.tagline.isNotEmpty)
                    pw.Text(
                      company.tagline,
                      style: const pw.TextStyle(fontSize: 9, color: grayColor),
                    ),
                  if (company.address.isNotEmpty)
                    pw.Text(
                      company.address,
                      style: const pw.TextStyle(fontSize: 8.5, color: grayColor),
                    ),
                  if (company.phone.isNotEmpty || company.email.isNotEmpty)
                    pw.Text(
                      [
                        if (company.phone.isNotEmpty) 'Telp: ${company.phone}',
                        if (company.email.isNotEmpty) 'Email: ${company.email}',
                      ].join(' | '),
                      style: const pw.TextStyle(fontSize: 8.5, color: grayColor),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    template.titleHeading.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'No: ${receipt.receiptNumber}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Tgl: ${AppDateFormatter.formatLong(receipt.date)}',
                  style: const pw.TextStyle(fontSize: 9, color: grayColor),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 12),
        pw.Divider(thickness: 1.5, color: primaryColor),
        pw.SizedBox(height: 8),

        // Payer & Transaction Meta Box
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF8FAFC),
            border: pw.Border.all(color: borderColor),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Telah Diterima Dari:', style: const pw.TextStyle(fontSize: 8, color: grayColor)),
                    pw.Text(
                      receipt.receivedFrom,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty)
                      pw.Text('No. HP / WA: ${receipt.customerPhone}', style: const pw.TextStyle(fontSize: 8.5, color: grayColor)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Metode Pembayaran:', style: const pw.TextStyle(fontSize: 8, color: grayColor)),
                    pw.Text(
                      receipt.paymentMethod,
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                    ),
                    if (receipt.cashierName != null && receipt.cashierName!.isNotEmpty)
                      pw.Text('Kasir: ${receipt.cashierName}', style: const pw.TextStyle(fontSize: 8.5, color: grayColor)),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Items Breakdown or Single Description Table
        if (receipt.items.isNotEmpty) ...[
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(3.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                children: [
                  _cell('No', isHeader: true, align: pw.TextAlign.center),
                  _cell('Deskripsi / Item', isHeader: true),
                  _cell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _cell('Harga Satuan', isHeader: true, align: pw.TextAlign.right),
                  _cell('Total', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              ...receipt.items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                return pw.TableRow(
                  children: [
                    _cell('$idx', align: pw.TextAlign.center),
                    _cell(item.name),
                    _cell(item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString(), align: pw.TextAlign.center),
                    _cell(CurrencyFormatter.format(item.unitPrice), align: pw.TextAlign.right),
                    _cell(CurrencyFormatter.format(item.subtotal), align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),
        ] else ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Untuk Keperluan / Pembayaran:', style: const pw.TextStyle(fontSize: 8.5, color: grayColor)),
                pw.SizedBox(height: 4),
                pw.Text(receipt.description, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],

        pw.SizedBox(height: 10),

        // Total, Terbilang & Calculation Summary
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Terbilang & Notes
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFEFF6FF),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Terbilang:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '# ${NumberToWords.convert(receipt.amount)} #',
                          style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('Catatan: ${receipt.notes}', style: const pw.TextStyle(fontSize: 8.5, color: grayColor)),
                  ],
                  if (company.bankInfo.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Rekening: ${company.bankInfo}', style: const pw.TextStyle(fontSize: 8, color: grayColor)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            // Right: Math Breakdown
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                children: [
                  if (receipt.discount > 0)
                    _summaryRow('Diskon:', '- ${CurrencyFormatter.format(receipt.discount)}'),
                  if (receipt.tax > 0)
                    _summaryRow('Pajak / PPN:', '+ ${CurrencyFormatter.format(receipt.tax)}'),
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL:',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(receipt.amount),
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (receipt.cashReceived > 0) ...[
                    _summaryRow('Bayar / Tunai:', CurrencyFormatter.format(receipt.cashReceived)),
                    _summaryRow('Kembalian:', CurrencyFormatter.format(receipt.changeAmount)),
                  ],
                ],
              ),
            ),
          ],
        ),

        pw.Spacer(),

        // Bottom: Status Stamp & Signatures
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // QR Code & Verification
            pw.Row(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'AUDIRA|${receipt.receiptNumber}|${receipt.amount.toInt()}',
                  width: 50,
                  height: 50,
                ),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Kwitansi Resmi Digital', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Validasi sistem AUDIRA', style: const pw.TextStyle(fontSize: 7, color: grayColor)),
                    pw.Text(company.footerMessage, style: const pw.TextStyle(fontSize: 7, color: grayColor)),
                  ],
                ),
              ],
            ),

            // Stamp Badge & Signatures
            pw.Row(
              children: [
                // Stamp
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF16A34A), width: 1.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    receipt.status.toUpperCase(),
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF16A34A),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.SizedBox(width: 24),
                // Signature
                pw.Column(
                  children: [
                    pw.Text('Diterima Oleh,', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 36),
                    pw.Text(
                      receipt.cashierName?.isNotEmpty == true
                          ? receipt.cashierName!
                          : (company.signerName.isNotEmpty ? company.signerName : company.name),
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Container(width: 80, height: 0.5, color: PdfColors.black),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // THERMAL ROLL FORMAT LAYOUT
  // =========================================================================
  static pw.Widget _buildThermalRollContent(
    Receipt receipt,
    Company company,
    ReceiptTemplate template,
  ) {
    final divider = pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - -', style: const pw.TextStyle(fontSize: 8));

    pw.MemoryImage? rollLogo;
    final isLogoEnabled = receipt.showLogo ?? template.defaultConfig.showLogo;
    if (isLogoEnabled) {
      final customPath = receipt.logoPath ?? company.logo;
      if (customPath != null && customPath.isNotEmpty) {
        try {
          final f = File(customPath);
          if (f.existsSync()) {
            rollLogo = pw.MemoryImage(f.readAsBytesSync());
          }
        } catch (_) {}
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (rollLogo != null) ...[
          pw.Center(
            child: pw.Container(
              width: 64,
              height: 36,
              margin: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Image(rollLogo, fit: pw.BoxFit.contain),
            ),
          ),
        ],
        // Store Header
        pw.Center(
          child: pw.Text(
            company.name.toUpperCase(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        if (company.tagline.isNotEmpty)
          pw.Center(child: pw.Text(company.tagline, style: const pw.TextStyle(fontSize: 7.5))),
        if (company.address.isNotEmpty)
          pw.Center(child: pw.Text(company.address, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
        if (company.phone.isNotEmpty)
          pw.Center(child: pw.Text('Telp: ${company.phone}', style: const pw.TextStyle(fontSize: 7))),

        pw.SizedBox(height: 4),
        divider,
        pw.SizedBox(height: 4),

        pw.Center(
          child: pw.Text(
            template.titleHeading.toUpperCase(),
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.SizedBox(height: 4),
        _rollRow('No. Kwitansi', receipt.receiptNumber),
        _rollRow('Tanggal', AppDateFormatter.formatShortWithTime(receipt.date)),
        _rollRow('Penerima/Pelanggan', receipt.receivedFrom),
        if (receipt.customerPhone?.isNotEmpty == true)
          _rollRow('No. HP', receipt.customerPhone!),
        _rollRow('Metode Bayar', receipt.paymentMethod),
        if (receipt.cashierName?.isNotEmpty == true)
          _rollRow('Kasir', receipt.cashierName!),

        pw.SizedBox(height: 4),
        divider,
        pw.SizedBox(height: 4),

        // Items
        if (receipt.items.isNotEmpty) ...[
          ...receipt.items.map((it) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(it.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${it.quantity % 1 == 0 ? it.quantity.toInt() : it.quantity} x ${CurrencyFormatter.format(it.unitPrice)}',
                          style: const pw.TextStyle(fontSize: 7.5),
                        ),
                        pw.Text(CurrencyFormatter.format(it.subtotal), style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                  ],
                ),
              )),
        ] else ...[
          pw.Text('Untuk: ${receipt.description}', style: const pw.TextStyle(fontSize: 8)),
        ],

        pw.SizedBox(height: 4),
        divider,
        pw.SizedBox(height: 4),

        if (receipt.discount > 0)
          _rollRow('Diskon', '- ${CurrencyFormatter.format(receipt.discount)}'),
        if (receipt.tax > 0)
          _rollRow('Pajak / PPN', '+ ${CurrencyFormatter.format(receipt.tax)}'),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(CurrencyFormatter.format(receipt.amount), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),

        if (receipt.cashReceived > 0) ...[
          _rollRow('Tunai / Diterima', CurrencyFormatter.format(receipt.cashReceived)),
          _rollRow('Kembalian', CurrencyFormatter.format(receipt.changeAmount)),
        ],

        pw.SizedBox(height: 4),
        divider,
        pw.SizedBox(height: 4),

        pw.Center(
          child: pw.Text(
            '# ${receipt.status.toUpperCase()} #',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),

        if (receipt.showBarcode ?? template.defaultConfig.showBarcode) ...[
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: (receipt.barcodeData != null && receipt.barcodeData!.trim().isNotEmpty)
                  ? receipt.barcodeData!.trim()
                  : receipt.receiptNumber,
              width: 140,
              height: 35,
              drawText: true,
              textStyle: const pw.TextStyle(fontSize: 7),
            ),
          ),
        ],

        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: 'AUDIRA|${receipt.receiptNumber}|${receipt.amount.toInt()}',
            width: 45,
            height: 45,
          ),
        ),

        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            company.footerMessage,
            style: const pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _rollRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
