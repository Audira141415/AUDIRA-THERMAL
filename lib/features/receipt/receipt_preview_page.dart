import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class ReceiptPreviewPage extends StatefulWidget {
  final Receipt receipt;

  const ReceiptPreviewPage({super.key, required this.receipt});

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  late String _currentPaperSize;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ReceiptService>().settings;
    _currentPaperSize = settings.paperSize;
  }

  Future<void> _handlePrint() async {
    final receiptService = context.read<ReceiptService>();
    final printerService = context.read<PrinterService>();

    final updatedSettings = receiptService.settings.copyWith(paperSize: _currentPaperSize);

    final result = await printerService.printReceipt(
      receipt: widget.receipt,
      company: receiptService.company,
      settings: updatedSettings,
    );

    if (!mounted) return;

    if (result.success) {
      CustomDialogs.showSuccessSnackBar(context, result.message);
    } else {
      CustomDialogs.showPrintFailureDialog(
        context: context,
        errorMessage: result.message,
        onRetry: _handlePrint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final printerService = context.watch<PrinterService>();
    final company = receiptService.company;
    final is80mm = _currentPaperSize == AppConstants.paper80mm;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Preview Kwitansi'),
        actions: [
          // Paper size toggle selector
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '58mm', label: Text('58mm', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: '80mm', label: Text('80mm', style: TextStyle(fontSize: 12))),
              ],
              selected: {_currentPaperSize},
              onSelectionChanged: (val) {
                setState(() {
                  _currentPaperSize = val.first;
                });
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: AppColors.primaryLight,
                selectedForegroundColor: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: is80mm ? 420 : 340,
            ),
            decoration: BoxDecoration(
              color: AppColors.thermalPaper,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.thermalBorder.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thermal Paper Header jagged top decoration
                Container(
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: List.generate(
                      24,
                      (index) => Expanded(
                        child: Container(
                          color: index.isEven ? const Color(0xFFE2E8F0) : AppColors.thermalPaper,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      // Company Name
                      Text(
                        company.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.thermalInk,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (company.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          company.address,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.thermalInk,
                          ),
                        ),
                      ],
                      if (company.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Telp: ${company.phone}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.thermalInk,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      _buildThermalDivider('='),
                      const SizedBox(height: 8),

                      // Kwitansi Title
                      const Text(
                        'KWITANSI PEMBAYARAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.thermalInk,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildThermalDivider('-'),
                      const SizedBox(height: 10),

                      // Receipt No & Date
                      _buildThermalRow(
                        left: 'No : ${widget.receipt.receiptNumber}',
                        right: widget.receipt.dateFormatted,
                      ),
                      const SizedBox(height: 8),
                      _buildThermalDivider('-'),
                      const SizedBox(height: 12),

                      // Telah Diterima Dari
                      _buildThermalSection(
                        label: 'Telah diterima dari:',
                        value: widget.receipt.receivedFrom.toUpperCase(),
                        isBold: true,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 12),

                      // Jumlah
                      _buildThermalSection(
                        label: 'Jumlah:',
                        value: CurrencyFormatter.format(widget.receipt.amount),
                        isBold: true,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 12),

                      // Terbilang
                      _buildThermalSection(
                        label: 'Terbilang:',
                        value: widget.receipt.amountWords,
                        isItalic: true,
                        fontSize: 12,
                      ),
                      const SizedBox(height: 12),

                      // Untuk
                      _buildThermalSection(
                        label: 'Untuk Pembayaran:',
                        value: widget.receipt.description,
                        isBold: true,
                        fontSize: 13,
                      ),
                      const SizedBox(height: 12),

                      // Metode Pembayaran & Catatan
                      _buildThermalRow(
                        left: 'Metode Bayar:',
                        right: widget.receipt.paymentMethod,
                      ),
                      if (widget.receipt.notes != null && widget.receipt.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildThermalSection(
                          label: 'Catatan:',
                          value: widget.receipt.notes!,
                          fontSize: 11,
                        ),
                      ],

                      const SizedBox(height: 14),
                      _buildThermalDivider('-'),
                      const SizedBox(height: 18),

                      // Signatures Area
                      if (is80mm) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Penyetor,',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            Text(
                              'Penerima,',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '(______________)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            Text(
                              '( ${company.name.split(' ').first} )',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'Penerima,',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                              SizedBox(height: 44),
                              Text(
                                '(________________)',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text(
                        'Terima Kasih',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.thermalInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Harap simpan bukti pembayaran ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildThermalDivider('='),
                      const SizedBox(height: 8),

                      Text(
                        'AUDIRA RECEIPT • Thermal ESC/POS $_currentPaperSize',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // [EDIT] Button
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.receiptForm,
                      arguments: widget.receipt,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('EDIT'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // [PRINT] Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: printerService.isPrinting ? null : _handlePrint,
                  icon: printerService.isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_rounded, size: 20),
                  label: Text(
                    printerService.isPrinting ? 'Mencetak...' : 'PRINT KWITANSI',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThermalDivider(String char) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8.5).floor();
        return Text(
          char * (count > 0 ? count : 32),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.thermalBorder,
            letterSpacing: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        );
      },
    );
  }

  Widget _buildThermalRow({required String left, required String right}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          left,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.thermalInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            right,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.thermalInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThermalSection({
    required String label,
    required String value,
    bool isBold = false,
    bool isItalic = false,
    double fontSize = 13,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              color: AppColors.thermalInk,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
