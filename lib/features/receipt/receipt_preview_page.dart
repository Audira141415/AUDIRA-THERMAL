import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/widgets/audira_logo.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/thermal_ticket_container.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Top Paper Size Selector Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ukuran Kertas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildPaperOption(
                        label: '58 mm',
                        isSelected: !is80mm,
                        onTap: () => setState(() => _currentPaperSize = AppConstants.paper58mm),
                      ),
                      _buildPaperOption(
                        label: '80 mm',
                        isSelected: is80mm,
                        onTap: () => setState(() => _currentPaperSize = AppConstants.paper80mm),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Thermal Ticket Preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Center(
                child: ThermalTicketContainer(
                  maxWidth: is80mm ? 420 : 330,
                  child: Column(
                    children: [
                      // Car Logo + AUDIRA MULTIMEDIA DIGITAL
                      const AudiraLogoWidget(size: 40),
                      const SizedBox(height: 6),
                      Text(
                        company.address.isNotEmpty ? company.address : 'Jl. Ahmad Yani No. 123, Batam',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.thermalInk,
                        ),
                      ),
                      Text(
                        'Telp. ${company.phone.isNotEmpty ? company.phone : '0812 3456 7890'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.thermalInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDashedLine(),
                      const SizedBox(height: 8),

                      // KWITANSI Title
                      const Text(
                        'KWITANSI',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.thermalInk,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Meta
                      if (is80mm) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'No     : ${widget.receipt.receiptNumber}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                            Text(
                              'Tanggal : ${widget.receipt.dateFormatted}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No     : ${widget.receipt.receiptNumber}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                              ),
                              Text(
                                'Tanggal: ${widget.receipt.dateFormatted}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildDashedLine(),
                      const SizedBox(height: 10),

                      // Telah Diterima Dari
                      _buildReceiptField(
                        label: 'Telah diterima dari :',
                        value: widget.receipt.receivedFrom.toUpperCase(),
                        isBold: true,
                        fontSize: 13,
                      ),
                      const SizedBox(height: 10),

                      // Uang Sejumlah
                      _buildReceiptField(
                        label: 'Uang sejumlah :',
                        value: CurrencyFormatter.format(widget.receipt.amount),
                        isBold: true,
                        fontSize: 18,
                      ),
                      const SizedBox(height: 10),

                      // Terbilang
                      _buildReceiptField(
                        label: 'Terbilang :',
                        value: widget.receipt.amountWords,
                        isItalic: false,
                        fontSize: 12,
                      ),
                      const SizedBox(height: 10),

                      // Untuk Pembayaran
                      _buildReceiptField(
                        label: 'Untuk pembayaran :',
                        value: widget.receipt.description,
                        isBold: true,
                        fontSize: 12,
                      ),
                      const SizedBox(height: 12),
                      _buildDashedLine(),
                      const SizedBox(height: 14),

                      // Date & Signature
                      Align(
                        alignment: is80mm ? Alignment.centerRight : Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Batam, ${widget.receipt.dateFormatted}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Penerima,',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                            const SizedBox(height: 40),
                            const Text(
                              '(_________________)',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Footer
                      const Text(
                        'Terima Kasih',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Bar: [EDIT] and [🖨️ CETAK]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // EDIT Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.receiptForm,
                          arguments: widget.receipt,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'EDIT',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // CETAK Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: printerService.isPrinting ? null : _handlePrint,
                      icon: printerService.isPrinting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print_rounded, size: 20),
                      label: Text(
                        printerService.isPrinting ? 'Mencetak...' : 'CETAK',
                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
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
        ],
      ),
    );
  }

  Widget _buildPaperOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 14,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 6.0).floor();
        return Text(
          '- ' * (count > 0 ? count : 20),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        );
      },
    );
  }

  Widget _buildReceiptField({
    required String label,
    required String value,
    bool isBold = false,
    bool isItalic = false,
    double fontSize = 12,
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
              fontSize: 10,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              color: AppColors.thermalInk,
            ),
          ),
        ],
      ),
    );
  }
}
