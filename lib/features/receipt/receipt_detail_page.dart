import 'package:flutter/material.dart';
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
      confirmText: 'Ya, Hapus',
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
        title: Text('Detail #${_receipt.receiptNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Kwitansi',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Hapus Kwitansi',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _receipt.receiptNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        _receipt.dateFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Nominal Kwitansi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(_receipt.amount),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Terbilang: "${_receipt.amountWords}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Details Card
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
                  const Text(
                    'Rincian Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Telah Diterima Dari',
                    value: _receipt.receivedFrom,
                    isBold: true,
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _buildDetailRow(
                    icon: Icons.description_outlined,
                    label: 'Untuk Pembayaran',
                    value: _receipt.description,
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _buildDetailRow(
                    icon: Icons.payment_outlined,
                    label: 'Metode Pembayaran',
                    value: _receipt.paymentMethod,
                  ),
                  if (_receipt.notes != null && _receipt.notes!.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.divider),
                    _buildDetailRow(
                      icon: Icons.note_alt_outlined,
                      label: 'Catatan Tambahan',
                      value: _receipt.notes!,
                    ),
                  ],
                  const Divider(height: 24, color: AppColors.divider),
                  _buildDetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Waktu Dibuat',
                    value: _receipt.dateWithTimeFormatted,
                  ),
                ],
              ),
            ),
          ],
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
              // [Preview] button
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.receiptPreview,
                      arguments: _receipt,
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // [Reprint] button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _handlePrint,
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: const Text(
                    'CETAK ULANG',
                    style: TextStyle(
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryText),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
