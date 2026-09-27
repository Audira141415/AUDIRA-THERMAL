import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class ReceiptDetailPage extends StatefulWidget {
  final Receipt receipt;

  const ReceiptDetailPage({super.key, required this.receipt});

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  late Receipt _receipt;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
  }

  Future<void> _handlePrint() async {
    final receiptService = context.read<ReceiptService>();
    final printerService = context.read<PrinterService>();

    final result = await printerService.printReceipt(
      receipt: _receipt,
      company: receiptService.company,
      settings: receiptService.settings,
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

  Future<void> _handleDelete() async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context: context,
      title: 'Hapus Kwitansi',
      message: 'Apakah Anda yakin ingin menghapus kwitansi nomor ${_receipt.receiptNumber}?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final success = await context.read<ReceiptService>().deleteReceipt(_receipt.id!);
      if (success && mounted) {
        CustomDialogs.showSuccessSnackBar(context, 'Kwitansi #${_receipt.receiptNumber} berhasil dihapus');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.receiptForm,
      arguments: _receipt,
    );

    if (updated is Receipt && mounted) {
      setState(() {
        _receipt = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Kwitansi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Header Card (Document Icon + Number + Date + Dicetak Badge)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _receipt.receiptNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMMM yyyy • HH:mm', 'id_ID').format(_receipt.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Dicetak',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Details List Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    label: 'Diterima Dari',
                    value: _receipt.receivedFrom,
                  ),
                  const Divider(height: 22, color: AppColors.divider),
                  _buildDetailItem(
                    label: 'Nominal',
                    value: CurrencyFormatter.format(_receipt.amount),
                    isHighlight: true,
                  ),
                  const Divider(height: 22, color: AppColors.divider),
                  _buildDetailItem(
                    label: 'Terbilang',
                    value: _receipt.amountWords,
                  ),
                  const Divider(height: 22, color: AppColors.divider),
                  _buildDetailItem(
                    label: 'Untuk Pembayaran',
                    value: _receipt.description,
                  ),
                  const Divider(height: 22, color: AppColors.divider),
                  _buildDetailItem(
                    label: 'Metode Pembayaran',
                    value: _receipt.paymentMethod,
                  ),
                  const Divider(height: 22, color: AppColors.divider),
                  _buildDetailItem(
                    label: 'Catatan',
                    value: _receipt.notes != null && _receipt.notes!.isNotEmpty ? _receipt.notes! : '-',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. [🖨️ CETAK ULANG] Full Width Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _handlePrint,
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: const Text(
                    'CETAK ULANG',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 2. Row: [EDIT] and [HAPUS]
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _handleEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('EDIT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('HAPUS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
            color: isHighlight ? AppColors.text : AppColors.text,
          ),
        ),
      ],
    );
  }
}
