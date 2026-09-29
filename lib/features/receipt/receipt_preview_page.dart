import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/pdf_receipt_service.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/features/template/template_settings_page.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/thermal_ticket_container.dart';
import 'package:audira_receipt/features/receipt/receipt_preview_archetypes.dart';

class ReceiptPreviewPage extends StatefulWidget {
  final Receipt receipt;

  const ReceiptPreviewPage({super.key, required this.receipt});

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  late String _currentPaperSize;
  ReceiptTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    final receiptService = context.read<ReceiptService>();
    final settings = receiptService.settings;
    _currentPaperSize = settings.paperSize;
    if (widget.receipt.templateId.isNotEmpty) {
      _selectedTemplate = ReceiptTemplate.findById(widget.receipt.templateId);
    } else {
      _selectedTemplate = receiptService.activeTemplate;
    }
  }

  Future<void> _handlePrint() async {
    final receiptService = context.read<ReceiptService>();
    final printerService = context.read<PrinterService>();

    final updatedSettings = receiptService.settings.copyWith(paperSize: _currentPaperSize);
    await receiptService.updatePaperSize(_currentPaperSize);
    final tpl = _selectedTemplate ?? receiptService.activeTemplate;
    final config = receiptService.getTemplateConfig(tpl.id);

    final result = await printerService.printReceipt(
      receipt: widget.receipt,
      company: receiptService.company,
      settings: updatedSettings,
      paperSizeOverride: _currentPaperSize,
      template: tpl,
      customConfig: config,
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

  void _copyPlainTextReceipt(Company company) {
    final receiptService = context.read<ReceiptService>();
    final tpl = _selectedTemplate ?? receiptService.activeTemplate;
    final config = receiptService.getTemplateConfig(tpl.id);
    final text = PrinterUtils.generateReceiptPlainText(
      receipt: widget.receipt,
      company: company,
      paperSize: _currentPaperSize,
      template: tpl,
      customConfig: config,
    );
    Clipboard.setData(ClipboardData(text: text));
    CustomDialogs.showSuccessSnackBar(context, 'Teks struk (${tpl.name}) berhasil disalin');
  }

  void _showShareDialog(Company company) {
    final receiptService = context.read<ReceiptService>();
    final tpl = _selectedTemplate ?? receiptService.activeTemplate;
    final config = receiptService.getTemplateConfig(tpl.id);
    final shareText = PrinterUtils.generateShareableText(
      receipt: widget.receipt,
      company: company,
      template: tpl,
      customConfig: config,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.share_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Bagikan Kwitansi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Teks format WhatsApp (${tpl.name}):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(
                      shareText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareText));
                        Navigator.pop(ctx);
                        CustomDialogs.showSuccessSnackBar(context, 'Teks kwitansi berhasil disalin!');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                      label: const Text('Salin Teks', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await Share.share(shareText, subject: 'Kwitansi #${widget.receipt.receiptNumber}');
                        } catch (e) {
                          if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal membagikan: $e');
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: const Text('Kirim Teks WA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await PdfReceiptService.sharePdf(
                            receipt: widget.receipt,
                            company: company,
                            template: tpl,
                          );
                        } catch (e) {
                          if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal membagikan PDF: $e');
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                      label: const Text('Bagikan PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await PdfReceiptService.printPdf(
                            receipt: widget.receipt,
                            company: company,
                            template: tpl,
                          );
                        } catch (e) {
                          if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal mencetak PDF: $e');
                        }
                      },
                      icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                      label: const Text('Cetak PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showTemplateSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.style_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pilih Template Kwitansi (22+ Model)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, AppRoutes.templateGallery);
                      },
                      child: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ReceiptTemplate.allTemplates.length,
                  itemBuilder: (_, index) {
                    final tpl = ReceiptTemplate.allTemplates[index];
                    final isSelected = tpl.id == (_selectedTemplate?.id ?? '');
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                        child: Icon(tpl.icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF475569)),
                      ),
                      title: Text(
                        tpl.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.text,
                        ),
                      ),
                      subtitle: Text(
                        '${tpl.category} • ${tpl.description}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                          : null,
                      onTap: () {
                        setState(() => _selectedTemplate = tpl);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final printerService = context.watch<PrinterService>();
    final company = receiptService.company;
    final is80mm = _currentPaperSize == AppConstants.paper80mm;
    final is48mm = _currentPaperSize == AppConstants.paper48mm;
    final is58mm = _currentPaperSize == AppConstants.paper58mm;

    final tpl = _selectedTemplate ?? receiptService.activeTemplate;
    final config = receiptService.getTemplateConfig(tpl.id);

    Color stampColor = AppColors.success;
    if (widget.receipt.status.contains('DP')) {
      stampColor = const Color(0xFFD97706);
    } else if (widget.receipt.status == 'PELUNASAN') {
      stampColor = const Color(0xFF2563EB);
    }

    String? stampText;
    if (config.stampType != 'none') {
      if (config.stampType == 'custom' && config.customStampText.isNotEmpty) {
        stampText = config.customStampText;
      } else if (config.stampType == 'auto') {
        stampText = widget.receipt.status;
      } else {
        stampText = config.stampType.toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Preview Kwitansi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
            tooltip: 'Cetak / Simpan PDF',
            onPressed: () {
              PdfReceiptService.printPdf(
                receipt: widget.receipt,
                company: company,
                template: tpl,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Salin Teks Struk',
            onPressed: () => _copyPlainTextReceipt(company),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Bagikan via WhatsApp / PDF',
            onPressed: () => _showShareDialog(company),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Paper Size Selector Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        label: '48 mm',
                        isSelected: is48mm,
                        onTap: () async {
                          setState(() => _currentPaperSize = AppConstants.paper48mm);
                          await receiptService.updatePaperSize(AppConstants.paper48mm);
                          if (context.mounted) {
                            CustomDialogs.showSuccessSnackBar(context, 'Ukuran cetak disetel ke 48 mm (24 Kolom)');
                          }
                        },
                      ),
                      _buildPaperOption(
                        label: '58 mm',
                        isSelected: is58mm,
                        onTap: () async {
                          setState(() => _currentPaperSize = AppConstants.paper58mm);
                          await receiptService.updatePaperSize(AppConstants.paper58mm);
                          if (context.mounted) {
                            CustomDialogs.showSuccessSnackBar(context, 'Ukuran cetak disetel ke 58 mm (32 Kolom)');
                          }
                        },
                      ),
                      _buildPaperOption(
                        label: '80 mm',
                        isSelected: is80mm,
                        onTap: () async {
                          setState(() => _currentPaperSize = AppConstants.paper80mm);
                          await receiptService.updatePaperSize(AppConstants.paper80mm);
                          if (context.mounted) {
                            CustomDialogs.showSuccessSnackBar(context, 'Ukuran cetak disetel ke 80 mm (48 Kolom)');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Template Selector Bar (22+ Models)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: InkWell(
              onTap: _showTemplateSelectorModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(tpl.icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TEMPLATE STRUK (22+ PILIHAN)',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                          ),
                          Text(
                            tpl.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                      tooltip: 'Sesuaikan Pengaturan Template',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TemplateSettingsPage(template: tpl)),
                        );
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Ganti', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Thermal Ticket Preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Center(
                child: ThermalTicketContainer(
                  maxWidth: is80mm ? 420 : (is48mm ? 275 : 330),
                  stampText: stampText,
                  stampColor: stampColor,
                  child: ReceiptPreviewArchetypes.buildTicketContent(
                    receipt: widget.receipt,
                    company: company,
                    template: tpl,
                    config: config,
                    paperSize: _currentPaperSize,
                    stampText: stampText,
                    stampColor: stampColor,
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
}
