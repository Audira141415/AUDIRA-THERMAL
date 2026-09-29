import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/pdf_receipt_service.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/models/company.dart';
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

  void _shareReceipt(Company company) {
    final text = PrinterUtils.generateShareableText(receipt: _receipt, company: company);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.share_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Bagikan Kwitansi #${_receipt.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.send_rounded, color: Color(0xFF16A34A))),
              title: const Text('Kirim via WhatsApp (Teks)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Kirim ringkasan nota langsung ke kontak WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await Share.share(text, subject: 'Kwitansi #${_receipt.receiptNumber}');
                } catch (e) {
                  if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal membagikan: $e');
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDBEAFE), child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB))),
              title: const Text('Bagikan Dokumen PDF Resmi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Kirim file PDF dengan kop surat, tabel, & stempel lunas'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfReceiptService.sharePdf(receipt: _receipt, company: company);
                } catch (e) {
                  if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal membagikan PDF: $e');
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.copy_rounded, color: AppColors.secondaryText)),
              title: const Text('Salin Teks ke Clipboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Salin teks pesan untuk ditempel manual'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: text));
                CustomDialogs.showSuccessSnackBar(context, 'Teks kwitansi disalin ke clipboard!');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<ReceiptService>().company;

    Color statusColor = AppColors.success;
    if (_receipt.status.contains('DP')) {
      statusColor = const Color(0xFFD97706);
    } else if (_receipt.status == 'PELUNASAN') {
      statusColor = const Color(0xFF2563EB);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Kwitansi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Cetak Dokumen PDF',
            onPressed: () => PdfReceiptService.printPdf(receipt: _receipt, company: company),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview Cetak',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.receiptPreview, arguments: _receipt);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan Kwitansi',
            onPressed: () => _shareReceipt(company),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Header Card
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
                          AppDateFormatter.formatLongWithTime(_receipt.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _receipt.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
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
                    label: 'Status Pembayaran',
                    value: _receipt.status,
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
              // 1. Row: [PREVIEW STRUK] and [CETAK ULANG]
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.receiptPreview, arguments: _receipt);
                        },
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        label: const Text('PREVIEW'),
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
                    flex: 2,
                    child: SizedBox(
                      height: 46,
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
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Row: [EDIT] and [HAPUS]
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: _handleEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('EDIT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryText,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('HAPUS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
