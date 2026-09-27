import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/printer_status.dart';

class PrinterTestPage extends StatefulWidget {
  const PrinterTestPage({super.key});

  @override
  State<PrinterTestPage> createState() => _PrinterTestPageState();
}

class _PrinterTestPageState extends State<PrinterTestPage> {
  String _selectedPaperSize = AppConstants.paper58mm;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ReceiptService>().settings;
    _selectedPaperSize = settings.paperSize;
  }

  Future<void> _handleTestPrint() async {
    final printerService = context.read<PrinterService>();
    final receiptService = context.read<ReceiptService>();

    final result = await printerService.printTest(
      paperSize: _selectedPaperSize,
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
    final isPrinting = printerService.isPrinting;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Test Print Thermal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current connection status
            const PrinterStatusWidget(),
            const SizedBox(height: 16),

            // Paper size selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ukuran Kertas Uji Coba',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '58mm', label: Text('58mm')),
                      ButtonSegment(value: '80mm', label: Text('80mm')),
                    ],
                    selected: {_selectedPaperSize},
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedPaperSize = val.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test Print Preview Ticket
            Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.thermalPaper,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.thermalBorder),
              ),
              child: Column(
                children: [
                  const Text(
                    'TEST PRINT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.thermalInk,
                    ),
                  ),
                  const Text(
                    'AUDIRA THERMAL PRINTER',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.thermalInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '================================',
                    style: TextStyle(fontFamily: 'monospace', color: AppColors.thermalBorder),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Status     : BERHASIL TERHUBUNG\nUkuran     : ESC/POS Thermal\nNormal Text Sample\n[ BOLD TEXT SAMPLE ]\n_Underline Text Sample_\nLeft Alignment\n           Center Alignment\n               Right Alignment\n--------------------------------\nItem A                  Rp 25.000\nItem B                  Rp 50.000\nTOTAL                   Rp 75.000\n================================',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Printer ESC/POS Siap Digunakan!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '[ Auto Cut Paper Command ]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Print button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isPrinting ? null : _handleTestPrint,
                icon: isPrinting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_rounded, size: 22),
                label: Text(
                  isPrinting ? 'Sedang Mencetak...' : 'CETAK TEST PAGE SEKARANG',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
