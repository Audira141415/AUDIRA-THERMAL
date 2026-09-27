import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/thermal_ticket_container.dart';

class PrinterTestPage extends StatefulWidget {
  const PrinterTestPage({super.key});

  @override
  State<PrinterTestPage> createState() => _PrinterTestPageState();
}

class _PrinterTestPageState extends State<PrinterTestPage> {
  Future<void> _handleTestPrint() async {
    final printerService = context.read<PrinterService>();
    final receiptService = context.read<ReceiptService>();

    final result = await printerService.printTest(
      paperSize: receiptService.settings.paperSize,
      company: receiptService.company,
    );

    if (!mounted) return;

    if (result.success) {
      CustomDialogs.showSuccessSnackBar(context, 'Test print berhasil dikirim ke printer!');
    } else {
      CustomDialogs.showPrintFailureDialog(
        context: context,
        errorMessage: result.message,
        onRetry: _handleTestPrint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    final receiptService = context.watch<ReceiptService>();
    final settings = receiptService.settings;
    final isPrinting = printerService.isPrinting;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Test Print'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Center(
                child: ThermalTicketContainer(
                  maxWidth: settings.paperSize == AppConstants.paper80mm ? 400 : 320,
                  child: Column(
                    children: [
                      // Header
                      const Text(
                        'AUDIRA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.thermalInk,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'THERMAL PRINTER TEST',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.thermalInk,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Meta
                      _buildTwoCol('Model', ': XP-58'),
                      _buildTwoCol('Paper', ': ${settings.paperSize}'),
                      _buildTwoCol('Date', ': 27/09/2026 10:24'),
                      const SizedBox(height: 10),
                      _buildDashedLine(),
                      const SizedBox(height: 10),

                      // Text Formatting Samples
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text Normal',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Text Bold',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Text Double Height',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Text Double Width',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDashedLine(),
                      const SizedBox(height: 10),

                      // Alignments
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Align Left', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Text('Align Center', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('Align Right', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      ),
                      const SizedBox(height: 12),
                      _buildDashedLine(),
                      const SizedBox(height: 12),

                      // QR Code Test
                      const Text(
                        'QR Code Test:',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 60,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Terima Kasih',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Button: [🖨️ CETAK TEST PRINT]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isPrinting ? null : _handleTestPrint,
                  icon: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print_rounded, size: 20),
                  label: Text(
                    isPrinting ? 'Sedang Mencetak...' : 'CETAK TEST PRINT',
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoCol(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.secondaryText),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.thermalInk),
          ),
        ],
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
}
