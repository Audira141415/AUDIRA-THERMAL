import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/printer_utils.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/thermal_ticket_container.dart';

class TemplateSettingsPage extends StatefulWidget {
  final ReceiptTemplate template;

  const TemplateSettingsPage({super.key, required this.template});

  @override
  State<TemplateSettingsPage> createState() => _TemplateSettingsPageState();
}

class _TemplateSettingsPageState extends State<TemplateSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TemplateConfig _config;

  // Controllers for text labels
  late TextEditingController _customTitleController;
  late TextEditingController _labelReceivedFromController;
  late TextEditingController _labelAmountController;
  late TextEditingController _labelAmountWordsController;
  late TextEditingController _labelDescriptionController;
  late TextEditingController _labelPaymentMethodController;
  late TextEditingController _signerTitleController;
  late TextEditingController _customStampController;
  late TextEditingController _termsController;
  late TextEditingController _customFooterController;

  // Controllers for extended / flagship fields
  late TextEditingController _headerSubtitleController;
  late TextEditingController _businessLegalIdController;
  late TextEditingController _contactInfoController;
  late TextEditingController _leherField1LabelController;
  late TextEditingController _leherField1ValueController;
  late TextEditingController _leherField2LabelController;
  late TextEditingController _leherField2ValueController;
  late TextEditingController _leherField3LabelController;
  late TextEditingController _leherField3ValueController;
  late TextEditingController _serviceChargeLabelController;
  late TextEditingController _wifiInfoController;
  late TextEditingController _socialMediaController;
  late TextEditingController _memberRewardController;
  late TextEditingController _promoBannerController;
  late TextEditingController _guaranteePolicyController;
  double _serviceChargeAmount = 0.0;

  // Sample receipt for live preview
  late final Receipt _sampleReceipt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final receiptService = context.read<ReceiptService>();
    _config = receiptService.getTemplateConfig(widget.template.id);

    _customTitleController = TextEditingController(text: _config.customTitle);
    _labelReceivedFromController = TextEditingController(text: _config.labelReceivedFrom);
    _labelAmountController = TextEditingController(text: _config.labelAmount);
    _labelAmountWordsController = TextEditingController(text: _config.labelAmountWords);
    _labelDescriptionController = TextEditingController(text: _config.labelDescription);
    _labelPaymentMethodController = TextEditingController(text: _config.labelPaymentMethod);
    _signerTitleController = TextEditingController(text: _config.signerTitle);
    _customStampController = TextEditingController(text: _config.customStampText);
    _termsController = TextEditingController(text: _config.termsText);
    _customFooterController = TextEditingController(text: _config.customFooter);

    // Extended flagship fields
    _headerSubtitleController = TextEditingController(text: _config.headerSubtitle);
    _businessLegalIdController = TextEditingController(text: _config.businessLegalId);
    _contactInfoController = TextEditingController(text: _config.contactInfo);
    _leherField1LabelController = TextEditingController(text: _config.leherField1Label);
    _leherField1ValueController = TextEditingController(text: _config.leherField1Value);
    _leherField2LabelController = TextEditingController(text: _config.leherField2Label);
    _leherField2ValueController = TextEditingController(text: _config.leherField2Value);
    _leherField3LabelController = TextEditingController(text: _config.leherField3Label);
    _leherField3ValueController = TextEditingController(text: _config.leherField3Value);
    _serviceChargeLabelController = TextEditingController(text: _config.serviceChargeLabel);
    _serviceChargeAmount = _config.serviceChargeAmount;
    _wifiInfoController = TextEditingController(text: _config.wifiInfo);
    _socialMediaController = TextEditingController(text: _config.socialMedia);
    _memberRewardController = TextEditingController(text: _config.memberReward);
    _promoBannerController = TextEditingController(text: _config.promoBanner);
    _guaranteePolicyController = TextEditingController(text: _config.guaranteePolicy);

    _sampleReceipt = Receipt(
      id: 999,
      receiptNumber: 'AUD-2026-TEST',
      date: DateTime.now(),
      receivedFrom: 'BAPAK HENDRA KURNIAWAN',
      amount: 1500000,
      amountWords: 'Satu Juta Lima Ratus Ribu Rupiah',
      description: 'Layanan Servis & Pembelian Komponen Resmi',
      paymentMethod: 'Transfer Bank',
      status: 'LUNAS',
      notes: 'Garansi resmi terdaftar pada sistem',
      templateId: widget.template.id,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customTitleController.dispose();
    _labelReceivedFromController.dispose();
    _labelAmountController.dispose();
    _labelAmountWordsController.dispose();
    _labelDescriptionController.dispose();
    _labelPaymentMethodController.dispose();
    _signerTitleController.dispose();
    _customStampController.dispose();
    _termsController.dispose();
    _customFooterController.dispose();
    _headerSubtitleController.dispose();
    _businessLegalIdController.dispose();
    _contactInfoController.dispose();
    _leherField1LabelController.dispose();
    _leherField1ValueController.dispose();
    _leherField2LabelController.dispose();
    _leherField2ValueController.dispose();
    _leherField3LabelController.dispose();
    _leherField3ValueController.dispose();
    _serviceChargeLabelController.dispose();
    _wifiInfoController.dispose();
    _socialMediaController.dispose();
    _memberRewardController.dispose();
    _promoBannerController.dispose();
    _guaranteePolicyController.dispose();
    super.dispose();
  }

  TemplateConfig _getCurrentWorkingConfig() {
    return _config.copyWith(
      customTitle: _customTitleController.text.trim(),
      labelReceivedFrom: _labelReceivedFromController.text.trim(),
      labelAmount: _labelAmountController.text.trim(),
      labelAmountWords: _labelAmountWordsController.text.trim(),
      labelDescription: _labelDescriptionController.text.trim(),
      labelPaymentMethod: _labelPaymentMethodController.text.trim(),
      signerTitle: _signerTitleController.text.trim(),
      customStampText: _customStampController.text.trim(),
      termsText: _termsController.text.trim(),
      customFooter: _customFooterController.text.trim(),
      headerSubtitle: _headerSubtitleController.text.trim(),
      businessLegalId: _businessLegalIdController.text.trim(),
      contactInfo: _contactInfoController.text.trim(),
      leherField1Label: _leherField1LabelController.text.trim(),
      leherField1Value: _leherField1ValueController.text.trim(),
      leherField2Label: _leherField2LabelController.text.trim(),
      leherField2Value: _leherField2ValueController.text.trim(),
      leherField3Label: _leherField3LabelController.text.trim(),
      leherField3Value: _leherField3ValueController.text.trim(),
      serviceChargeLabel: _serviceChargeLabelController.text.trim(),
      serviceChargeAmount: _serviceChargeAmount,
      wifiInfo: _wifiInfoController.text.trim(),
      socialMedia: _socialMediaController.text.trim(),
      memberReward: _memberRewardController.text.trim(),
      promoBanner: _promoBannerController.text.trim(),
      guaranteePolicy: _guaranteePolicyController.text.trim(),
    );
  }

  void _saveSettings() async {
    final updatedConfig = _getCurrentWorkingConfig();
    final receiptService = context.read<ReceiptService>();
    await receiptService.updateTemplateConfig(widget.template.id, updatedConfig);

    if (mounted) {
      CustomDialogs.showSuccessSnackBar(context, 'Pengaturan template "${widget.template.name}" berhasil disimpan!');
      Navigator.pop(context);
    }
  }

  void _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Pengaturan Template?'),
        content: Text('Kembalikan semua konfigurasi (font, perataan, label) template "${widget.template.name}" ke setelan bawaan pabrik?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Sekarang'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final receiptService = context.read<ReceiptService>();
      await receiptService.resetTemplateConfig(widget.template.id);
      final defaultConfig = widget.template.defaultConfig;

      setState(() {
        _config = defaultConfig;
        _customTitleController.text = defaultConfig.customTitle;
        _labelReceivedFromController.text = defaultConfig.labelReceivedFrom;
        _labelAmountController.text = defaultConfig.labelAmount;
        _labelAmountWordsController.text = defaultConfig.labelAmountWords;
        _labelDescriptionController.text = defaultConfig.labelDescription;
        _labelPaymentMethodController.text = defaultConfig.labelPaymentMethod;
        _signerTitleController.text = defaultConfig.signerTitle;
        _customStampController.text = defaultConfig.customStampText;
        _termsController.text = defaultConfig.termsText;
        _customFooterController.text = defaultConfig.customFooter;
        _headerSubtitleController.text = defaultConfig.headerSubtitle;
        _businessLegalIdController.text = defaultConfig.businessLegalId;
        _contactInfoController.text = defaultConfig.contactInfo;
        _leherField1LabelController.text = defaultConfig.leherField1Label;
        _leherField1ValueController.text = defaultConfig.leherField1Value;
        _leherField2LabelController.text = defaultConfig.leherField2Label;
        _leherField2ValueController.text = defaultConfig.leherField2Value;
        _leherField3LabelController.text = defaultConfig.leherField3Label;
        _leherField3ValueController.text = defaultConfig.leherField3Value;
        _serviceChargeLabelController.text = defaultConfig.serviceChargeLabel;
        _serviceChargeAmount = defaultConfig.serviceChargeAmount;
        _wifiInfoController.text = defaultConfig.wifiInfo;
        _socialMediaController.text = defaultConfig.socialMedia;
        _memberRewardController.text = defaultConfig.memberReward;
        _promoBannerController.text = defaultConfig.promoBanner;
        _guaranteePolicyController.text = defaultConfig.guaranteePolicy;
      });

      if (mounted) {
        CustomDialogs.showSuccessSnackBar(context, 'Setelan template berhasil direset ke bawaan pabrik');
      }
    }
  }

  void _showLivePreviewModal(Company company) {
    final currentConfig = _getCurrentWorkingConfig();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
                    const Icon(Icons.preview_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pratinjau Thermal: ${widget.template.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      maxWidth: 340,
                      stampText: currentConfig.stampType == 'custom' && currentConfig.customStampText.isNotEmpty
                          ? currentConfig.customStampText
                          : (currentConfig.stampType == 'auto' ? 'LUNAS' : currentConfig.stampType.toUpperCase()),
                      stampColor: currentConfig.stampType == 'dp' ? AppColors.warning : AppColors.success,
                      child: _buildTicketPreview(company, currentConfig),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketPreview(Company company, TemplateConfig cfg) {
    final effectiveTitle = cfg.customTitle.isNotEmpty ? cfg.customTitle : widget.template.titleHeading;
    final sepChar = cfg.separatorChar.isNotEmpty ? cfg.separatorChar[0] : '-';

    TextAlign toTextAlign(String align) {
      if (align == 'center') return TextAlign.center;
      if (align == 'right') return TextAlign.right;
      return TextAlign.left;
    }

    CrossAxisAlignment toCrossAlign(String align) {
      if (align == 'center') return CrossAxisAlignment.center;
      if (align == 'right') return CrossAxisAlignment.end;
      return CrossAxisAlignment.start;
    }

    double titleFontSize() {
      if (cfg.titleFontSize == 'extra_large') return 18;
      if (cfg.titleFontSize == 'large') return 15;
      return 13;
    }

    double amountFontSize() {
      if (cfg.amountFontSize == 'extra_large') return 20;
      if (cfg.amountFontSize == 'large') return 17;
      return 14;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          company.name.toUpperCase(),
          textAlign: toTextAlign(cfg.headerAlign),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: cfg.boldCompanyName ? FontWeight.w900 : FontWeight.w600,
            color: AppColors.thermalInk,
          ),
        ),
        if (cfg.showTagline && company.tagline.isNotEmpty)
          Text(
            company.tagline,
            textAlign: toTextAlign(cfg.headerAlign),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.secondaryText),
          ),
        if (company.address.isNotEmpty)
          Text(
            company.address,
            textAlign: toTextAlign(cfg.headerAlign),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.thermalInk),
          ),
        Text(
          'Telp: ${company.phone}',
          textAlign: toTextAlign(cfg.headerAlign),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.thermalInk),
        ),
        const SizedBox(height: 6),
        Text(sepChar * 28, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 6),

        // Title
        Text(
          effectiveTitle,
          textAlign: toTextAlign(cfg.titleAlign),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: titleFontSize(),
            fontWeight: cfg.boldTitle ? FontWeight.w900 : FontWeight.w600,
            color: AppColors.thermalInk,
          ),
        ),
        if (cfg.stampType != 'none') ...[
          const SizedBox(height: 4),
          Align(
            alignment: cfg.stampAlign == 'center' ? Alignment.center : (cfg.stampAlign == 'right' ? Alignment.centerRight : Alignment.centerLeft),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Text(
                cfg.stampType == 'custom' && cfg.customStampText.isNotEmpty ? cfg.customStampText : 'LUNAS',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(sepChar * 28, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 6),

        // Meta
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('No : ${_sampleReceipt.receiptNumber}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
            Text(_sampleReceipt.dateFormatted, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        Text(sepChar * 28, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 8),

        // Diterima Dari
        if (cfg.showReceivedFrom) ...[
          Column(
            crossAxisAlignment: toCrossAlign(cfg.receivedFromAlign),
            children: [
              Text(cfg.labelReceivedFrom, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.secondaryText)),
              Text(
                _sampleReceipt.receivedFrom,
                textAlign: toTextAlign(cfg.receivedFromAlign),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: cfg.boldReceivedFrom ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Jumlah (Amount)
        if (cfg.showAmount) ...[
          Column(
            crossAxisAlignment: toCrossAlign(cfg.amountAlign),
            children: [
              Text(cfg.labelAmount, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.secondaryText)),
              Text(
                CurrencyFormatter.format(_sampleReceipt.amount),
                textAlign: toTextAlign(cfg.amountAlign),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: amountFontSize(),
                  fontWeight: cfg.boldAmount ? FontWeight.w900 : FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Terbilang
        if (cfg.showAmountWords) ...[
          Column(
            crossAxisAlignment: toCrossAlign(cfg.amountWordsAlign),
            children: [
              Text(cfg.labelAmountWords, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.secondaryText)),
              Text(
                PrinterUtils.formatAmountWords(_sampleReceipt.amountWords, cfg.amountWordsCase),
                textAlign: toTextAlign(cfg.amountWordsAlign),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontStyle: cfg.italicAmountWords ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Deskripsi
        if (cfg.showDescription) ...[
          Column(
            crossAxisAlignment: toCrossAlign(cfg.descriptionAlign),
            children: [
              Text(cfg.labelDescription, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.secondaryText)),
              Text(
                _sampleReceipt.description,
                textAlign: toTextAlign(cfg.descriptionAlign),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: cfg.boldDescription ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Syarat
        if (cfg.showTerms && cfg.termsText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            cfg.termsText,
            textAlign: toTextAlign(cfg.termsAlign),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 4),
        ],

        // Footer
        if (cfg.showFooter) ...[
          const SizedBox(height: 6),
          Text(
            cfg.customFooter.isNotEmpty ? cfg.customFooter : 'Terima kasih atas kunjungan Anda',
            textAlign: toTextAlign(cfg.footerAlign),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final company = receiptService.company;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'Studio Kustomisasi Desain & Font',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            tooltip: 'Pratinjau Struk',
            onPressed: () => _showLivePreviewModal(company),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Bawaan',
            onPressed: _resetToDefault,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.format_align_center, size: 18), text: 'Perataan'),
            Tab(icon: Icon(Icons.text_fields, size: 18), text: 'Tipografi & Font'),
            Tab(icon: Icon(Icons.edit_note_rounded, size: 18), text: 'Label Teks'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Struktur Cetak'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: '⭐ Unggulan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlignmentsTab(),
          _buildTypographyTab(),
          _buildCustomLabelsTab(),
          _buildStructureTab(),
          _buildFlagshipTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showLivePreviewModal(company),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Pratinjau'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('SIMPAN DESAIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: TATA LETAK & PERATAAN (ALIGNMENTS)
  // ==========================================
  Widget _buildAlignmentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Atur posisi teks (Rata Kiri, Tengah, atau Kanan) untuk setiap bagian kwitansi.',
          Icons.format_align_justify_rounded,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Perataan Header & Judul',
          children: [
            _buildAlignmentSelector(
              label: 'Nama Toko & Header Usaha',
              icon: Icons.business_rounded,
              currentValue: _config.headerAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(headerAlign: val)),
            ),
            const Divider(height: 24),
            _buildAlignmentSelector(
              label: 'Judul Kwitansi / Struk',
              icon: Icons.title_rounded,
              currentValue: _config.titleAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(titleAlign: val)),
            ),
            const Divider(height: 24),
            _buildAlignmentSelector(
              label: 'Posisi Cap / Stamp (LUNAS/DP)',
              icon: Icons.verified_rounded,
              currentValue: _config.stampAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(stampAlign: val)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Perataan Isi Transaksi',
          children: [
            _buildAlignmentSelector(
              label: 'Diterima Dari (Nama Pembayar)',
              icon: Icons.person_outline_rounded,
              currentValue: _config.receivedFromAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(receivedFromAlign: val)),
            ),
            const Divider(height: 24),
            _buildAlignmentSelector(
              label: 'Blok Nominal (Jumlah Uang)',
              icon: Icons.payments_outlined,
              currentValue: _config.amountAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(amountAlign: val)),
            ),
            const Divider(height: 24),
            _buildAlignmentSelector(
              label: 'Teks Terbilang',
              icon: Icons.spellcheck_rounded,
              currentValue: _config.amountWordsAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(amountWordsAlign: val)),
            ),
            const Divider(height: 24),
            _buildAlignmentSelector(
              label: 'Deskripsi / Untuk Keperluan',
              icon: Icons.description_outlined,
              currentValue: _config.descriptionAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(descriptionAlign: val)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Perataan Footer & Syarat',
          children: [
            _buildAlignmentSelector(
              label: 'Pesan Footer Bawah',
              icon: Icons.subtitles_outlined,
              currentValue: _config.footerAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(footerAlign: val)),
            ),
            const Divider(height: 24),
            _buildAlignmentSelector(
              label: 'Syarat & Ketentuan',
              icon: Icons.gavel_rounded,
              currentValue: _config.termsAlign,
              onChanged: (val) => setState(() => _config = _config.copyWith(termsAlign: val)),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: TIPOGRAFI & FONT SETTINGS
  // ==========================================
  Widget _buildTypographyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Sesuaikan ukuran font thermal ESC/POS, tebal (bold), cetak miring, dan mode huruf.',
          Icons.text_fields_rounded,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Skala Ukuran Huruf (ESC/POS)',
          children: [
            _buildFontSizeSelector(
              label: 'Ukuran Font Judul Kwitansi',
              currentValue: _config.titleFontSize,
              onChanged: (val) => setState(() => _config = _config.copyWith(titleFontSize: val)),
            ),
            const Divider(height: 24),
            _buildFontSizeSelector(
              label: 'Ukuran Font Nominal Uang',
              currentValue: _config.amountFontSize,
              onChanged: (val) => setState(() => _config = _config.copyWith(amountFontSize: val)),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mode Font B (Condensed / Rapat)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Menggunakan font thermal 9x17 yang lebih kecil dan muat lebih banyak karakter.', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              value: _config.fontCondensed,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _config = _config.copyWith(fontCondensed: val)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Ketebalan Huruf (Bold / Tebal)',
          children: [
            _buildSwitchTile('Tebalkan Judul Kwitansi', _config.boldTitle, (val) => setState(() => _config = _config.copyWith(boldTitle: val))),
            _buildSwitchTile('Tebalkan Nominal Jumlah Uang', _config.boldAmount, (val) => setState(() => _config = _config.copyWith(boldAmount: val))),
            _buildSwitchTile('Tebalkan Nama Usaha / Toko', _config.boldCompanyName, (val) => setState(() => _config = _config.copyWith(boldCompanyName: val))),
            _buildSwitchTile('Tebalkan Nama Pembayar (Diterima Dari)', _config.boldReceivedFrom, (val) => setState(() => _config = _config.copyWith(boldReceivedFrom: val))),
            _buildSwitchTile('Tebalkan Deskripsi Pembayaran', _config.boldDescription, (val) => setState(() => _config = _config.copyWith(boldDescription: val))),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Format Teks Terbilang',
          children: [
            const Text('Gaya Huruf Terbilang:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'title', label: Text('Huruf Depan Besar', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 'upper', label: Text('SEMUA BESAR', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 'lower', label: Text('semua kecil', style: TextStyle(fontSize: 11))),
              ],
              selected: {_config.amountWordsCase},
              onSelectionChanged: (val) => setState(() => _config = _config.copyWith(amountWordsCase: val.first)),
            ),
            const SizedBox(height: 14),
            _buildSwitchTile('Cetak Miring (Italic) Terbilang', _config.italicAmountWords, (val) => setState(() => _config = _config.copyWith(italicAmountWords: val))),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: LABEL & TEKS KUSTOM
  // ==========================================
  Widget _buildCustomLabelsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Kustomisasi label setiap kolom struk agar sesuai dengan jenis bisnis Anda (misal: "Nama Pasien", "Penyewa", dll).',
          Icons.edit_note_rounded,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Judul & Simbol Mata Uang',
          children: [
            _buildTextField(
              controller: _customTitleController,
              label: 'Judul Kwitansi Kustom',
              hint: widget.template.titleHeading,
              helper: 'Kosongkan jika ingin memakai judul bawaan template',
            ),
            const SizedBox(height: 14),
            const Text('Simbol Mata Uang:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Rp', 'IDR', 'Rp.', ''].map((sym) {
                final isSelected = _config.currencySymbol == sym;
                return ChoiceChip(
                  label: Text(sym.isEmpty ? 'Tanpa Simbol' : sym),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _config = _config.copyWith(currencySymbol: sym));
                  },
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Label Kolom Transaksi',
          children: [
            _buildTextField(
              controller: _labelReceivedFromController,
              label: 'Label "Diterima Dari"',
              hint: 'Telah diterima dari:',
              helper: 'Contoh: Nama Pasien, Penyewa Kamar, Pelanggan Yth',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _labelAmountController,
              label: 'Label "Jumlah Uang"',
              hint: 'Jumlah:',
              helper: 'Contoh: Total Tagihan, Uang Sejumlah, Total Pembayaran',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _labelAmountWordsController,
              label: 'Label "Terbilang"',
              hint: 'Terbilang:',
              helper: 'Contoh: Ejaan Rupiah, Terbilang Uang',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _labelDescriptionController,
              label: 'Label "Untuk Pembayaran"',
              hint: 'Untuk:',
              helper: 'Contoh: Keperluan, Keterangan Servis, Rincian Pembelian',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _labelPaymentMethodController,
              label: 'Label "Metode Bayar"',
              hint: 'Metode Bayar:',
              helper: 'Contoh: Pembayaran Via, Jalur Transaksi',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Penandatangan, Cap & Syarat',
          children: [
            _buildTextField(
              controller: _signerTitleController,
              label: 'Jabatan Penandatangan',
              hint: 'Penerima',
              helper: 'Contoh: Kasir, Bendahara, Dokter, Kepala Bengkel',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _customStampController,
              label: 'Teks Cap Kustom',
              hint: 'LUNAS / DP / SELESAI',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _termsController,
              label: 'Syarat & Ketentuan',
              hint: 'Barang yang sudah dibeli tidak dapat ditukar...',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _customFooterController,
              label: 'Pesan Footer Kustom',
              hint: 'Terima kasih atas kunjungan Anda!',
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: STRUKTUR & CETAK THERMAL
  // ==========================================
  Widget _buildStructureTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Atur tampilan elemen struk, karakter garis pembatas, bingkai retro, dan jumlah baris kosong di akhir kertas.',
          Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Garis Pembatas & Bingkai',
          children: [
            const Text('Karakter Garis Pembatas:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['-', '=', '*', '~', '.'].map((char) {
                final isSelected = _config.separatorChar == char;
                return ChoiceChip(
                  label: Text('$char$char$char$char$char ($char)'),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'monospace',
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _config = _config.copyWith(separatorChar: char));
                  },
                );
              }).toList(),
            ),
            const Divider(height: 24),
            _buildSwitchTile(
              'Bingkai Kotak Retro (+---+)',
              _config.isBoxedFrame,
              (val) => setState(() => _config = _config.copyWith(isBoxedFrame: val)),
              subtitle: 'Membungkus struk dengan garis border kotak ASCII.',
            ),
            _buildSwitchTile(
              'Invert Header (Teks Putih di Latar Hitam)',
              _config.invertHeader,
              (val) => setState(() => _config = _config.copyWith(invertHeader: val)),
              subtitle: 'Menggunakan mode GS B 1 pada printer untuk nama toko kontras.',
            ),
            const Divider(height: 24),
            const Text('Jarak Kertas di Akhir (Feed Lines sebelum Cut):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 Baris')),
                ButtonSegment(value: 2, label: Text('2 Baris')),
                ButtonSegment(value: 3, label: Text('3 Baris')),
                ButtonSegment(value: 4, label: Text('4 Baris')),
              ],
              selected: {_config.blankLinesAtEnd},
              onSelectionChanged: (val) => setState(() => _config = _config.copyWith(blankLinesAtEnd: val.first)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Elemen yang Ditampilkan',
          children: [
            _buildSwitchTile('Tampilkan Logo Usaha', _config.showLogo, (val) => setState(() => _config = _config.copyWith(showLogo: val))),
            _buildSwitchTile('Tampilkan Tagline Toko', _config.showTagline, (val) => setState(() => _config = _config.copyWith(showTagline: val))),
            _buildSwitchTile('Tampilkan Nomor Kwitansi', _config.showReceiptNumber, (val) => setState(() => _config = _config.copyWith(showReceiptNumber: val))),
            _buildSwitchTile('Tampilkan Tanggal Transaksi', _config.showDate, (val) => setState(() => _config = _config.copyWith(showDate: val))),
            _buildSwitchTile('Tampilkan Metode Pembayaran', _config.showPaymentMethod, (val) => setState(() => _config = _config.copyWith(showPaymentMethod: val))),
            _buildSwitchTile('Tampilkan Catatan Transaksi', _config.showNotes, (val) => setState(() => _config = _config.copyWith(showNotes: val))),
            _buildSwitchTile('Tampilkan Info Rekening Bank', _config.showBankInfo, (val) => setState(() => _config = _config.copyWith(showBankInfo: val))),
            _buildSwitchTile('Tampilkan Tanda Tangan', _config.showSignatures, (val) => setState(() => _config = _config.copyWith(showSignatures: val))),
            _buildSwitchTile('Tampilkan QR Code Verifikasi', _config.showQrCode, (val) => setState(() => _config = _config.copyWith(showQrCode: val))),
            _buildSwitchTile('Tampilkan Barcode CODE128', _config.showBarcode, (val) => setState(() => _config = _config.copyWith(showBarcode: val))),
            _buildSwitchTile('Tampilkan Syarat & Ketentuan', _config.showTerms, (val) => setState(() => _config = _config.copyWith(showTerms: val))),
            _buildSwitchTile('Tampilkan Pesan Footer', _config.showFooter, (val) => setState(() => _config = _config.copyWith(showFooter: val))),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 5: UNGGULAN & LANJUTAN (FLAGSHIP)
  // ==========================================
  Widget _buildFlagshipTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Pengaturan lanjutan untuk template ⭐ Unggulan: info header bisnis, baris leher, biaya layanan, promo & sosial media.',
          Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 16),

        // HEADER BISNIS LENGKAP
        _buildSectionCard(
          title: '🏢 Info Header Bisnis Lengkap',
          children: [
            _buildTextField(
              controller: _headerSubtitleController,
              label: 'Subtitle Header (Slogan / Layanan)',
              hint: 'Contoh: Resmi Terdaftar • Berpengalaman 15 Tahun',
              helper: 'Muncul di bawah nama toko pada header struk',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _businessLegalIdController,
              label: 'Legalitas Usaha (NPWP / NIB / SIPP)',
              hint: 'Contoh: NPWP: 01.234.567.8-901.000',
              helper: 'Nomor identitas hukum usaha Anda',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _contactInfoController,
              label: 'Info Kontak Lengkap (Telp, Email, Web)',
              hint: 'Contoh: Telp: 0778-123456 | WA: 0812-3456',
              helper: 'Menggantikan kolom telepon default',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // BARIS LEHER KUSTOM
        _buildSectionCard(
          title: '🔖 Baris Leher Kustom (Custom Neck Fields)',
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Tambahkan baris kustom di bagian leher struk (antara header dan isi). Cocok untuk: No. Meja, No. Polisi, No. Rekam Medis, No. Pesanan, dll.',
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Baris 1:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _leherField1LabelController,
                    label: 'Label Baris 1',
                    hint: 'No. Meja',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _leherField1ValueController,
                    label: 'Nilai / Isi Baris 1',
                    hint: 'Meja 07 (Teras)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Baris 2:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _leherField2LabelController,
                    label: 'Label Baris 2',
                    hint: 'Jumlah Pax',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _leherField2ValueController,
                    label: 'Nilai / Isi Baris 2',
                    hint: '4 Orang',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Baris 3:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _leherField3LabelController,
                    label: 'Label Baris 3',
                    hint: 'Waiter',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _leherField3ValueController,
                    label: 'Nilai / Isi Baris 3',
                    hint: 'Riko / Lantai 2',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // BIAYA LAYANAN / SERVICE CHARGE
        _buildSectionCard(
          title: '💳 Biaya Layanan (Service Charge)',
          children: [
            _buildTextField(
              controller: _serviceChargeLabelController,
              label: 'Label Biaya Layanan',
              hint: 'Contoh: Biaya Layanan (10%), Tip, Parkir',
              helper: 'Nama biaya tambahan pada total tagihan',
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nominal Biaya Layanan (Rp):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      CurrencyFormatter.format(_serviceChargeAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                Slider(
                  value: _serviceChargeAmount.clamp(0, 100000),
                  min: 0,
                  max: 100000,
                  divisions: 200,
                  activeColor: AppColors.primary,
                  label: CurrencyFormatter.format(_serviceChargeAmount),
                  onChanged: (val) => setState(() => _serviceChargeAmount = (val / 500).round() * 500.0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final v in [0.0, 2000.0, 5000.0, 10000.0, 20000.0])
                      GestureDetector(
                        onTap: () => setState(() => _serviceChargeAmount = v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _serviceChargeAmount == v ? AppColors.primary : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v == 0 ? 'Gratis' : CurrencyFormatter.format(v, withSymbol: false),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _serviceChargeAmount == v ? Colors.white : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // PROMO & SOSIAL
        _buildSectionCard(
          title: '📢 Promo, Sosial Media & WiFi',
          children: [
            _buildTextField(
              controller: _wifiInfoController,
              label: 'Info WiFi (Nama & Password)',
              hint: 'Contoh: SSID: CafeKita | Pass: cafeoke123',
              helper: 'Tampilkan di footer struk (restoran, cafe, hotel)',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _socialMediaController,
              label: 'Akun Sosial Media / Website',
              hint: 'Contoh: IG: @tokoku | TikTok: @tokoviral',
              helper: 'Saluran promosi bisnis Anda',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _promoBannerController,
              label: 'Banner Promo (Pesan Spesial)',
              hint: 'Contoh: Diskon 20% setiap Jumat! Tunjukkan struk ini.',
              helper: 'Tampil di akhir struk sebagai baris promosi bintang ★',
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // LOYALTY & GARANSI
        _buildSectionCard(
          title: '🏆 Program Loyalitas & Garansi',
          children: [
            _buildTextField(
              controller: _memberRewardController,
              label: 'Info Member / Poin Reward',
              hint: 'Contoh: +75 Poin • Total: 1.240 Poin Member',
              helper: 'Tampil sebagai badge poin/member di footer struk',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _guaranteePolicyController,
              label: 'Kebijakan Garansi Barang / Jasa',
              hint: 'Contoh: Garansi servis 14 hari, spare part 3 bulan',
              helper: 'Tampil sebagai blok garansi (ikon 🛡️) di struk',
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildAlignmentSelector({
    required String label,
    required IconData icon,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'left',
                icon: Icon(Icons.format_align_left_rounded, size: 16),
                label: Text('Kiri', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'center',
                icon: Icon(Icons.format_align_center_rounded, size: 16),
                label: Text('Tengah', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'right',
                icon: Icon(Icons.format_align_right_rounded, size: 16),
                label: Text('Kanan', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {currentValue},
            onSelectionChanged: (val) => onChanged(val.first),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSelector({
    required String label,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'normal',
                label: Text('Normal', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'large',
                label: Text('Besar (2x T)', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'extra_large',
                label: Text('Jumbo (2x L+T)', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {currentValue},
            onSelectionChanged: (val) => onChanged(val.first),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)) : null,
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helper,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
