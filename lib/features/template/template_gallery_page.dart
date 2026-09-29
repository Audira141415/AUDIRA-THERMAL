import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/features/template/template_settings_page.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/thermal_ticket_container.dart';

class TemplateGalleryPage extends StatefulWidget {
  const TemplateGalleryPage({super.key});

  @override
  State<TemplateGalleryPage> createState() => _TemplateGalleryPageState();
}

class _TemplateGalleryPageState extends State<TemplateGalleryPage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Mock receipt for live preview in cards
  late final Receipt _sampleReceipt;

  @override
  void initState() {
    super.initState();
    _sampleReceipt = Receipt(
      id: 999,
      receiptNumber: 'AUD-2026-SAMPLE',
      date: DateTime.now(),
      receivedFrom: 'PT AUDI UTAMA JAYA',
      amount: 750000,
      amountWords: 'Tujuh Ratus Lima Puluh Ribu Rupiah',
      description: 'Layanan Jasa & Pembayaran Transaksi Resmi',
      paymentMethod: 'Transfer Bank',
      status: 'LUNAS',
      notes: 'Terima kasih atas kerja samanya',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReceiptTemplate> _getFilteredTemplates() {
    return ReceiptTemplate.allTemplates.where((tpl) {
      final matchCategory = _selectedCategory == 'Semua' || tpl.category == _selectedCategory;
      final matchQuery = _searchQuery.isEmpty ||
          tpl.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tpl.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tpl.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchQuery;
    }).toList();
  }

  void _showTemplatePreviewModal(BuildContext context, ReceiptTemplate template, Company company, TemplateConfig config) {
    Receipt previewReceipt = _sampleReceipt;
    if (template.sampleItems.isNotEmpty) {
      final subtotal = template.sampleItems.fold(0.0, (sum, it) => sum + it.subtotal);
      final discount = template.sampleDiscount;
      final tax = template.sampleTax;
      final total = subtotal - discount + tax;
      previewReceipt = Receipt(
        id: 999,
        receiptNumber: 'AUD-2026-${template.id.toUpperCase().replaceAll('_', '-').substring(0, template.id.length > 8 ? 8 : template.id.length)}',
        date: DateTime.now(),
        receivedFrom: template.samplePayer.isNotEmpty ? template.samplePayer : 'Pelanggan Umum',
        customerPhone: template.sampleCustomerPhone.isNotEmpty ? template.sampleCustomerPhone : null,
        cashierName: template.sampleCashier.isNotEmpty ? template.sampleCashier : 'Admin / Kasir',
        amount: total,
        amountWords: '...',
        description: template.sampleDescription.isNotEmpty ? template.sampleDescription : 'Layanan & Pembayaran Resmi',
        paymentMethod: 'Tunai (Cash)',
        status: 'LUNAS',
        notes: template.sampleNotes.isNotEmpty ? template.sampleNotes : null,
        items: template.sampleItems,
        discount: discount,
        tax: tax,
        cashReceived: template.sampleCashReceived,
        changeAmount: (template.sampleCashReceived > total) ? template.sampleCashReceived - total : 0,
        templateId: template.id,
      );
    }

    final previewText = PrinterUtils.generateReceiptPlainText(
      receipt: previewReceipt,
      company: company,
      paperSize: AppConstants.paper58mm,
      template: template,
      customConfig: config,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(template.icon, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          Text(
                            template.category,
                            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ThermalTicketContainer(
                      maxWidth: 320,
                      stampText: config.stampType == 'none' ? null : (config.stampType == 'auto' ? 'LUNAS' : config.stampType.toUpperCase()),
                      stampColor: AppColors.success,
                      child: Text(
                        previewText,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          height: 1.3,
                          letterSpacing: 0.2,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Pengaturan'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TemplateSettingsPage(template: template),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Pilih Template'),
                        onPressed: () async {
                          await context.read<ReceiptService>().setActiveTemplate(template.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            CustomDialogs.showSuccessSnackBar(context, 'Template "${template.name}" berhasil diterapkan!');
                          }
                        },
                      ),
                    ),
                  ],
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
    final activeId = receiptService.settings.activeTemplateId;
    final company = receiptService.company;
    final filteredTemplates = _getFilteredTemplates();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Galeri Template Kwitansi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Template Default',
            onPressed: () async {
              await receiptService.setActiveTemplate('standard_formal');
              if (context.mounted) {
                CustomDialogs.showSuccessSnackBar(context, 'Kembali ke Template Standar Formal');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari 22+ template (nama, kategori, bidang)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                // Horizontal category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReceiptTemplate.categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.text,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Count Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Text(
                  '${filteredTemplates.length} Template Ditemukan',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                ),
                const Spacer(),
                const Text(
                  'Klik kartu untuk melihat preview struk',
                  style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),

          // Template Cards Grid / List
          Expanded(
            child: filteredTemplates.isEmpty
                ? const Center(
                    child: Text('Tidak ada template yang cocok dengan pencarian.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final tpl = filteredTemplates[index];
                      final isActive = tpl.id == activeId;
                      final config = receiptService.getTemplateConfig(tpl.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: isActive ? 2 : 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isActive ? AppColors.primary : AppColors.border,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showTemplatePreviewModal(context, tpl, company, config),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.primary.withOpacity(0.12) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        tpl.icon,
                                        color: isActive ? AppColors.primary : const Color(0xFF475569),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  tpl.name,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.text,
                                                  ),
                                                ),
                                              ),
                                              if (isActive)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check, size: 12, color: Colors.white),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'AKTIF',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: tpl.isFeatured ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  tpl.category,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: tpl.isFeatured ? const Color(0xFFB45309) : const Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                              if (tpl.badge.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: tpl.isFeatured ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: tpl.isFeatured ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    tpl.badge,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: tpl.isFeatured ? const Color(0xFFB45309) : const Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (tpl.sampleItems.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                                  ),
                                                  child: Text(
                                                    '${tpl.sampleItems.length} Item',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF047857),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tpl.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Feature Pill Badges
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildFeaturePill(
                                      icon: Icons.border_horizontal,
                                      label: 'Separator: ${config.separatorChar}',
                                    ),
                                    if (config.signatureType != 'none')
                                      _buildFeaturePill(
                                        icon: Icons.draw,
                                        label: config.signatureType == 'dual' ? 'TTD Ganda' : 'TTD ${config.signerTitle}',
                                      ),
                                    if (config.showQrCode)
                                      _buildFeaturePill(
                                        icon: Icons.qr_code,
                                        label: 'QR Code',
                                      ),
                                    if (config.showBarcode)
                                      _buildFeaturePill(
                                        icon: Icons.barcode_reader,
                                        label: 'Barcode',
                                      ),
                                    if (config.showTerms)
                                      _buildFeaturePill(
                                        icon: Icons.gavel,
                                        label: 'Syarat & Klaim',
                                      ),
                                    if (config.isBoxedFrame)
                                      _buildFeaturePill(
                                        icon: Icons.crop_square,
                                        label: 'Box Frame',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                      label: const Text('Lihat Struk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showTemplatePreviewModal(context, tpl, company, config),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.settings_outlined, size: 19, color: AppColors.secondaryText),
                                      tooltip: 'Sesuaikan Pengaturan',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TemplateSettingsPage(template: tpl),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isActive ? const Color(0xFFE2E8F0) : AppColors.primary,
                                        foregroundColor: isActive ? const Color(0xFF64748B) : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: isActive
                                          ? null
                                          : () async {
                                              await receiptService.setActiveTemplate(tpl.id);
                                              if (context.mounted) {
                                                CustomDialogs.showSuccessSnackBar(context, 'Template "${tpl.name}" aktif!');
                                              }
                                            },
                                      child: Text(
                                        isActive ? 'Sedang Digunakan' : 'Gunakan',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
