import 'package:flutter/material.dart';
import 'package:audira_receipt/models/receipt.dart';

/// Configuration options for a receipt template
class TemplateConfig {
  // Alignments ('left', 'center', 'right')
  final String headerAlign;
  final String titleAlign;
  final String receivedFromAlign;
  final String amountAlign;
  final String amountWordsAlign;
  final String descriptionAlign;
  final String notesAlign;
  final String footerAlign;
  final String termsAlign;
  final String stampAlign;

  // Typography & Font Sizing
  final String titleFontSize; // 'normal', 'large', 'extra_large'
  final String amountFontSize; // 'normal', 'large', 'extra_large'
  final bool fontCondensed; // ESC/POS Font B (9x17)
  final bool boldTitle;
  final bool boldAmount;
  final bool boldCompanyName;
  final bool boldReceivedFrom;
  final bool boldDescription;
  final bool italicAmountWords;
  final String amountWordsCase; // 'title', 'upper', 'lower'

  // Customizable Field Labels
  final String customTitle; // Overrides template heading if not empty
  final String labelReceivedFrom;
  final String labelAmount;
  final String labelAmountWords;
  final String labelDescription;
  final String labelPaymentMethod;
  final String currencySymbol; // 'Rp', 'IDR', 'Rp.', ''

  // Spacing & Structure
  final int blankLinesAtEnd; // 1, 2, 3, 4
  final String lineSpacing; // 'compact', 'normal', 'loose'
  final bool invertHeader; // GS B 1 in ESC/POS
  final String separatorChar; // '-', '=', '.', '*', '#'
  final bool isBoxedFrame; // Retro boxed layout (+---+ | |)

  // Visibility Toggles
  final bool showLogo;
  final bool showTagline;
  final bool showReceiptNumber;
  final bool showDate;
  final bool showTime;
  final bool showReceivedFrom;
  final bool showAmount;
  final bool showAmountWords;
  final bool showDescription;
  final bool showPaymentMethod;
  final bool showNotes;
  final bool showBankInfo;
  final bool showSignatures;
  final String signatureType; // 'single', 'dual', 'box', 'none'
  final String signerTitle; // 'Penerima', 'Kasir', 'Bendahara', 'Dokter', etc.
  final String stampType; // 'auto', 'lunas', 'dp', 'pelunasan', 'custom', 'none'
  final String customStampText;
  final bool showQrCode;
  final String qrCodeData; // 'receipt_number', 'company_web', 'verification'
  final bool showBarcode;
  final bool showFooter;
  final String customFooter;
  final bool showTerms;
  final String termsText;

  // Extended Flagship & Full Layout Fields
  final String headerSubtitle;
  final String businessLegalId;
  final String contactInfo;
  final String leherField1Label;
  final String leherField1Value;
  final String leherField2Label;
  final String leherField2Value;
  final String leherField3Label;
  final String leherField3Value;
  final String serviceChargeLabel;
  final double serviceChargeAmount;
  final String wifiInfo;
  final String socialMedia;
  final String memberReward;
  final String promoBanner;
  final String guaranteePolicy;
  final String badge;

  const TemplateConfig({
    this.headerAlign = 'center',
    this.titleAlign = 'center',
    this.receivedFromAlign = 'left',
    this.amountAlign = 'left',
    this.amountWordsAlign = 'left',
    this.descriptionAlign = 'left',
    this.notesAlign = 'left',
    this.footerAlign = 'center',
    this.termsAlign = 'center',
    this.stampAlign = 'center',
    this.titleFontSize = 'large',
    this.amountFontSize = 'large',
    this.fontCondensed = false,
    this.boldTitle = true,
    this.boldAmount = true,
    this.boldCompanyName = true,
    this.boldReceivedFrom = true,
    this.boldDescription = true,
    this.italicAmountWords = false,
    this.amountWordsCase = 'title',
    this.customTitle = '',
    this.labelReceivedFrom = 'Telah diterima dari:',
    this.labelAmount = 'Jumlah:',
    this.labelAmountWords = 'Terbilang:',
    this.labelDescription = 'Untuk:',
    this.labelPaymentMethod = 'Metode Bayar:',
    this.currencySymbol = 'Rp',
    this.blankLinesAtEnd = 3,
    this.lineSpacing = 'normal',
    this.invertHeader = false,
    this.separatorChar = '-',
    this.isBoxedFrame = false,
    this.showLogo = true,
    this.showTagline = true,
    this.showReceiptNumber = true,
    this.showDate = true,
    this.showTime = true,
    this.showReceivedFrom = true,
    this.showAmount = true,
    this.showAmountWords = true,
    this.showDescription = true,
    this.showPaymentMethod = true,
    this.showNotes = true,
    this.showBankInfo = true,
    this.showSignatures = true,
    this.signatureType = 'single',
    this.signerTitle = 'Penerima',
    this.stampType = 'auto',
    this.customStampText = '',
    this.showQrCode = true,
    this.qrCodeData = 'receipt_number',
    this.showBarcode = false,
    this.showFooter = true,
    this.customFooter = '',
    this.showTerms = false,
    this.termsText = '',
    this.headerSubtitle = '',
    this.businessLegalId = '',
    this.contactInfo = '',
    this.leherField1Label = '',
    this.leherField1Value = '',
    this.leherField2Label = '',
    this.leherField2Value = '',
    this.leherField3Label = '',
    this.leherField3Value = '',
    this.serviceChargeLabel = '',
    this.serviceChargeAmount = 0.0,
    this.wifiInfo = '',
    this.socialMedia = '',
    this.memberReward = '',
    this.promoBanner = '',
    this.guaranteePolicy = '',
    this.badge = '',
  });

  TemplateConfig copyWith({
    String? headerAlign,
    String? titleAlign,
    String? receivedFromAlign,
    String? amountAlign,
    String? amountWordsAlign,
    String? descriptionAlign,
    String? notesAlign,
    String? footerAlign,
    String? termsAlign,
    String? stampAlign,
    String? titleFontSize,
    String? amountFontSize,
    bool? fontCondensed,
    bool? boldTitle,
    bool? boldAmount,
    bool? boldCompanyName,
    bool? boldReceivedFrom,
    bool? boldDescription,
    bool? italicAmountWords,
    String? amountWordsCase,
    String? customTitle,
    String? labelReceivedFrom,
    String? labelAmount,
    String? labelAmountWords,
    String? labelDescription,
    String? labelPaymentMethod,
    String? currencySymbol,
    int? blankLinesAtEnd,
    String? lineSpacing,
    bool? invertHeader,
    String? separatorChar,
    bool? isBoxedFrame,
    bool? showLogo,
    bool? showTagline,
    bool? showReceiptNumber,
    bool? showDate,
    bool? showTime,
    bool? showReceivedFrom,
    bool? showAmount,
    bool? showAmountWords,
    bool? showDescription,
    bool? showPaymentMethod,
    bool? showNotes,
    bool? showBankInfo,
    bool? showSignatures,
    String? signatureType,
    String? signerTitle,
    String? stampType,
    String? customStampText,
    bool? showQrCode,
    String? qrCodeData,
    bool? showBarcode,
    bool? showFooter,
    String? customFooter,
    bool? showTerms,
    String? termsText,
    String? headerSubtitle,
    String? businessLegalId,
    String? contactInfo,
    String? leherField1Label,
    String? leherField1Value,
    String? leherField2Label,
    String? leherField2Value,
    String? leherField3Label,
    String? leherField3Value,
    String? serviceChargeLabel,
    double? serviceChargeAmount,
    String? wifiInfo,
    String? socialMedia,
    String? memberReward,
    String? promoBanner,
    String? guaranteePolicy,
    String? badge,
  }) {
    return TemplateConfig(
      headerAlign: headerAlign ?? this.headerAlign,
      titleAlign: titleAlign ?? this.titleAlign,
      receivedFromAlign: receivedFromAlign ?? this.receivedFromAlign,
      amountAlign: amountAlign ?? this.amountAlign,
      amountWordsAlign: amountWordsAlign ?? this.amountWordsAlign,
      descriptionAlign: descriptionAlign ?? this.descriptionAlign,
      notesAlign: notesAlign ?? this.notesAlign,
      footerAlign: footerAlign ?? this.footerAlign,
      termsAlign: termsAlign ?? this.termsAlign,
      stampAlign: stampAlign ?? this.stampAlign,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      amountFontSize: amountFontSize ?? this.amountFontSize,
      fontCondensed: fontCondensed ?? this.fontCondensed,
      boldTitle: boldTitle ?? this.boldTitle,
      boldAmount: boldAmount ?? this.boldAmount,
      boldCompanyName: boldCompanyName ?? this.boldCompanyName,
      boldReceivedFrom: boldReceivedFrom ?? this.boldReceivedFrom,
      boldDescription: boldDescription ?? this.boldDescription,
      italicAmountWords: italicAmountWords ?? this.italicAmountWords,
      amountWordsCase: amountWordsCase ?? this.amountWordsCase,
      customTitle: customTitle ?? this.customTitle,
      labelReceivedFrom: labelReceivedFrom ?? this.labelReceivedFrom,
      labelAmount: labelAmount ?? this.labelAmount,
      labelAmountWords: labelAmountWords ?? this.labelAmountWords,
      labelDescription: labelDescription ?? this.labelDescription,
      labelPaymentMethod: labelPaymentMethod ?? this.labelPaymentMethod,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      blankLinesAtEnd: blankLinesAtEnd ?? this.blankLinesAtEnd,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      invertHeader: invertHeader ?? this.invertHeader,
      separatorChar: separatorChar ?? this.separatorChar,
      isBoxedFrame: isBoxedFrame ?? this.isBoxedFrame,
      showLogo: showLogo ?? this.showLogo,
      showTagline: showTagline ?? this.showTagline,
      showReceiptNumber: showReceiptNumber ?? this.showReceiptNumber,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
      showReceivedFrom: showReceivedFrom ?? this.showReceivedFrom,
      showAmount: showAmount ?? this.showAmount,
      showAmountWords: showAmountWords ?? this.showAmountWords,
      showDescription: showDescription ?? this.showDescription,
      showPaymentMethod: showPaymentMethod ?? this.showPaymentMethod,
      showNotes: showNotes ?? this.showNotes,
      showBankInfo: showBankInfo ?? this.showBankInfo,
      showSignatures: showSignatures ?? this.showSignatures,
      signatureType: signatureType ?? this.signatureType,
      signerTitle: signerTitle ?? this.signerTitle,
      stampType: stampType ?? this.stampType,
      customStampText: customStampText ?? this.customStampText,
      showQrCode: showQrCode ?? this.showQrCode,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      showBarcode: showBarcode ?? this.showBarcode,
      showFooter: showFooter ?? this.showFooter,
      customFooter: customFooter ?? this.customFooter,
      showTerms: showTerms ?? this.showTerms,
      termsText: termsText ?? this.termsText,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      businessLegalId: businessLegalId ?? this.businessLegalId,
      contactInfo: contactInfo ?? this.contactInfo,
      leherField1Label: leherField1Label ?? this.leherField1Label,
      leherField1Value: leherField1Value ?? this.leherField1Value,
      leherField2Label: leherField2Label ?? this.leherField2Label,
      leherField2Value: leherField2Value ?? this.leherField2Value,
      leherField3Label: leherField3Label ?? this.leherField3Label,
      leherField3Value: leherField3Value ?? this.leherField3Value,
      serviceChargeLabel: serviceChargeLabel ?? this.serviceChargeLabel,
      serviceChargeAmount: serviceChargeAmount ?? this.serviceChargeAmount,
      wifiInfo: wifiInfo ?? this.wifiInfo,
      socialMedia: socialMedia ?? this.socialMedia,
      memberReward: memberReward ?? this.memberReward,
      promoBanner: promoBanner ?? this.promoBanner,
      guaranteePolicy: guaranteePolicy ?? this.guaranteePolicy,
      badge: badge ?? this.badge,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'header_align': headerAlign,
      'title_align': titleAlign,
      'received_from_align': receivedFromAlign,
      'amount_align': amountAlign,
      'amount_words_align': amountWordsAlign,
      'description_align': descriptionAlign,
      'notes_align': notesAlign,
      'footer_align': footerAlign,
      'terms_align': termsAlign,
      'stamp_align': stampAlign,
      'title_font_size': titleFontSize,
      'amount_font_size': amountFontSize,
      'font_condensed': fontCondensed,
      'bold_title': boldTitle,
      'bold_amount': boldAmount,
      'bold_company_name': boldCompanyName,
      'bold_received_from': boldReceivedFrom,
      'bold_description': boldDescription,
      'italic_amount_words': italicAmountWords,
      'amount_words_case': amountWordsCase,
      'custom_title': customTitle,
      'label_received_from': labelReceivedFrom,
      'label_amount': labelAmount,
      'label_amount_words': labelAmountWords,
      'label_description': labelDescription,
      'label_payment_method': labelPaymentMethod,
      'currency_symbol': currencySymbol,
      'blank_lines_at_end': blankLinesAtEnd,
      'line_spacing': lineSpacing,
      'invert_header': invertHeader,
      'separator_char': separatorChar,
      'is_boxed_frame': isBoxedFrame,
      'show_logo': showLogo,
      'show_tagline': showTagline,
      'show_receipt_number': showReceiptNumber,
      'show_date': showDate,
      'show_time': showTime,
      'show_received_from': showReceivedFrom,
      'show_amount': showAmount,
      'show_amount_words': showAmountWords,
      'show_description': showDescription,
      'show_payment_method': showPaymentMethod,
      'show_notes': showNotes,
      'show_bank_info': showBankInfo,
      'show_signatures': showSignatures,
      'signature_type': signatureType,
      'signer_title': signerTitle,
      'stamp_type': stampType,
      'custom_stamp_text': customStampText,
      'show_qr_code': showQrCode,
      'qr_code_data': qrCodeData,
      'show_barcode': showBarcode,
      'show_footer': showFooter,
      'custom_footer': customFooter,
      'show_terms': showTerms,
      'terms_text': termsText,
      'header_subtitle': headerSubtitle,
      'business_legal_id': businessLegalId,
      'contact_info': contactInfo,
      'leher_field1_label': leherField1Label,
      'leher_field1_value': leherField1Value,
      'leher_field2_label': leherField2Label,
      'leher_field2_value': leherField2Value,
      'leher_field3_label': leherField3Label,
      'leher_field3_value': leherField3Value,
      'service_charge_label': serviceChargeLabel,
      'service_charge_amount': serviceChargeAmount,
      'wifi_info': wifiInfo,
      'social_media': socialMedia,
      'member_reward': memberReward,
      'promo_banner': promoBanner,
      'guarantee_policy': guaranteePolicy,
      'badge': badge,
    };
  }

  factory TemplateConfig.fromMap(Map<String, dynamic> map) {
    return TemplateConfig(
      headerAlign: map['header_align'] as String? ?? 'center',
      titleAlign: map['title_align'] as String? ?? 'center',
      receivedFromAlign: map['received_from_align'] as String? ?? 'left',
      amountAlign: map['amount_align'] as String? ?? 'left',
      amountWordsAlign: map['amount_words_align'] as String? ?? 'left',
      descriptionAlign: map['description_align'] as String? ?? 'left',
      notesAlign: map['notes_align'] as String? ?? 'left',
      footerAlign: map['footer_align'] as String? ?? 'center',
      termsAlign: map['terms_align'] as String? ?? 'center',
      stampAlign: map['stamp_align'] as String? ?? 'center',
      titleFontSize: map['title_font_size'] as String? ?? 'large',
      amountFontSize: map['amount_font_size'] as String? ?? 'large',
      fontCondensed: map['font_condensed'] as bool? ?? false,
      boldTitle: map['bold_title'] as bool? ?? true,
      boldAmount: map['bold_amount'] as bool? ?? true,
      boldCompanyName: map['bold_company_name'] as bool? ?? true,
      boldReceivedFrom: map['bold_received_from'] as bool? ?? true,
      boldDescription: map['bold_description'] as bool? ?? true,
      italicAmountWords: map['italic_amount_words'] as bool? ?? false,
      amountWordsCase: map['amount_words_case'] as String? ?? 'title',
      customTitle: map['custom_title'] as String? ?? '',
      labelReceivedFrom: map['label_received_from'] as String? ?? 'Telah diterima dari:',
      labelAmount: map['label_amount'] as String? ?? 'Jumlah:',
      labelAmountWords: map['label_amount_words'] as String? ?? 'Terbilang:',
      labelDescription: map['label_description'] as String? ?? 'Untuk:',
      labelPaymentMethod: map['label_payment_method'] as String? ?? 'Metode Bayar:',
      currencySymbol: map['currency_symbol'] as String? ?? 'Rp',
      blankLinesAtEnd: map['blank_lines_at_end'] as int? ?? 3,
      lineSpacing: map['line_spacing'] as String? ?? 'normal',
      invertHeader: map['invert_header'] as bool? ?? false,
      separatorChar: map['separator_char'] as String? ?? '-',
      isBoxedFrame: map['is_boxed_frame'] as bool? ?? false,
      showLogo: map['show_logo'] as bool? ?? true,
      showTagline: map['show_tagline'] as bool? ?? true,
      showReceiptNumber: map['show_receipt_number'] as bool? ?? true,
      showDate: map['show_date'] as bool? ?? true,
      showTime: map['show_time'] as bool? ?? true,
      showReceivedFrom: map['show_received_from'] as bool? ?? true,
      showAmount: map['show_amount'] as bool? ?? true,
      showAmountWords: map['show_amount_words'] as bool? ?? true,
      showDescription: map['show_description'] as bool? ?? true,
      showPaymentMethod: map['show_payment_method'] as bool? ?? true,
      showNotes: map['show_notes'] as bool? ?? true,
      showBankInfo: map['show_bank_info'] as bool? ?? true,
      showSignatures: map['show_signatures'] as bool? ?? true,
      signatureType: map['signature_type'] as String? ?? 'single',
      signerTitle: map['signer_title'] as String? ?? 'Penerima',
      stampType: map['stamp_type'] as String? ?? 'auto',
      customStampText: map['custom_stamp_text'] as String? ?? '',
      showQrCode: map['show_qr_code'] as bool? ?? true,
      qrCodeData: map['qr_code_data'] as String? ?? 'receipt_number',
      showBarcode: map['show_barcode'] as bool? ?? false,
      showFooter: map['show_footer'] as bool? ?? true,
      customFooter: map['custom_footer'] as String? ?? '',
      showTerms: map['show_terms'] as bool? ?? false,
      termsText: map['terms_text'] as String? ?? '',
      headerSubtitle: map['header_subtitle'] as String? ?? '',
      businessLegalId: map['business_legal_id'] as String? ?? '',
      contactInfo: map['contact_info'] as String? ?? '',
      leherField1Label: map['leher_field1_label'] as String? ?? '',
      leherField1Value: map['leher_field1_value'] as String? ?? '',
      leherField2Label: map['leher_field2_label'] as String? ?? '',
      leherField2Value: map['leher_field2_value'] as String? ?? '',
      leherField3Label: map['leher_field3_label'] as String? ?? '',
      leherField3Value: map['leher_field3_value'] as String? ?? '',
      serviceChargeLabel: map['service_charge_label'] as String? ?? '',
      serviceChargeAmount: (map['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
      wifiInfo: map['wifi_info'] as String? ?? '',
      socialMedia: map['social_media'] as String? ?? '',
      memberReward: map['member_reward'] as String? ?? '',
      promoBanner: map['promo_banner'] as String? ?? '',
      guaranteePolicy: map['guarantee_policy'] as String? ?? '',
      badge: map['badge'] as String? ?? '',
    );
  }
}

/// Represents a receipt template specification
class ReceiptTemplate {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final String titleHeading;
  final TemplateConfig defaultConfig;
  final List<String> descriptionPresets;
  final bool isFeatured;
  final String badge;
  final List<ReceiptItem> sampleItems;
  final String samplePayer;
  final String sampleCustomerPhone;
  final String sampleCashier;
  final String sampleDescription;
  final String sampleNotes;
  final double sampleDiscount;
  final double sampleTax;
  final double sampleCashReceived;

  const ReceiptTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.titleHeading,
    required this.defaultConfig,
    this.descriptionPresets = const [],
    this.isFeatured = false,
    this.badge = '',
    this.sampleItems = const [],
    this.samplePayer = '',
    this.sampleCustomerPhone = '',
    this.sampleCashier = '',
    this.sampleDescription = '',
    this.sampleNotes = '',
    this.sampleDiscount = 0.0,
    this.sampleTax = 0.0,
    this.sampleCashReceived = 0.0,
  });

  /// All Predefined Receipt Templates (Including 5 Flagship Templates)
  static const List<ReceiptTemplate> allTemplates = [
    // =========================================================================
    // ⭐ 5 TEMPLATE UNGGULAN (FLAGSHIP TERLENGKAP: HEADER, LEHER, ISI & FOOTER)
    // =========================================================================

    // ⭐ 1. SUPERMARKET & MEGA RETAIL POS (UNGGULAN)
    ReceiptTemplate(
      id: 'flagship_supermarket',
      name: 'Mega Supermarket & POS Retail',
      category: 'F&B & Retail',
      isFeatured: true,
      badge: '⭐ UNGGULAN',
      description: 'Format faktur kasir supermarket modern terlengkap: identitas NPWP/NIB, nomor register kasir & shift, poin member belanja, tabel 5 item, barcode Code128, kebijakan retur 1x24 jam, dan promo belanja tebus murah.',
      icon: Icons.local_grocery_store_rounded,
      titleHeading: 'FAKTUR PENJUALAN RETAIL',
      samplePayer: 'Ibu Hj. Dewi Sartika',
      sampleCustomerPhone: '0812-3456-7890',
      sampleCashier: 'Siti Nurhaliza (POS-02 / Shift 1)',
      sampleDescription: 'Belanja Kebutuhan Pokok Sembako & Dapur Bulanan',
      sampleNotes: 'Member VIP GOLD (Poin: 1.450) - Promo Tebus Murah Aktif',
      sampleDiscount: 15000,
      sampleTax: 31400,
      sampleCashReceived: 350000,
      sampleItems: [
        ReceiptItem(id: 'sm_1', name: 'Minyak Goreng Tropical 2L', quantity: 2, unitPrice: 38500),
        ReceiptItem(id: 'sm_2', name: 'Beras Ramos Premium 5kg', quantity: 1, unitPrice: 74000),
        ReceiptItem(id: 'sm_3', name: 'Telur Ayam Omega 1kg', quantity: 1, unitPrice: 32500),
        ReceiptItem(id: 'sm_4', name: 'Susu UHT Greenfields 1L', quantity: 3, unitPrice: 24000),
        ReceiptItem(id: 'sm_5', name: 'Kopi Arabika Robusta 200g', quantity: 1, unitPrice: 45000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        headerSubtitle: '',
        businessLegalId: '',
        contactInfo: '',
        leherField1Label: 'No. Register',
        leherField1Value: 'POS-02 / Shift Siang',
        leherField2Label: 'Member ID',
        leherField2Value: 'VIP-GOLD-99214',
        leherField3Label: 'Waktu Transaksi',
        leherField3Value: '14:20:15 WIB',
        separatorChar: '=',
        showSignatures: false,
        signatureType: 'none',
        showBarcode: true,
        showQrCode: true,
        stampType: 'LUNAS',
        memberReward: '★ Reward Poin Belanja: +31 Poin (Saldo: 1.481 Poin) ★',
        promoBanner: 'Promo Tebus Murah Minyak 1L Rp 10.000 s/d 30 Sept 2026!',
        socialMedia: 'IG: @supermarketmegaindo | Web: www.megaindo.co.id',
        showTerms: true,
        termsText: 'Barang retur maks 1x24 jam wajib dengan struk fisik asli. Produk beku/segar tidak dapat diretur.',
        customFooter: 'Terima Kasih Atas Kunjungan Anda\nSelamat Datang Kembali!',
      ),
      descriptionPresets: [
        'Belanja Kebutuhan Pokok Sembako & Dapur Bulanan',
        'Pembelian Paket Perlengkapan Rumah Tangga & Sanitasi',
        'Belanja Bahan Makanan Segar, Buah & Daging',
        'Pembelian Snack, Biskuit & Minuman Ringan',
        'Pengadaan ATK & Kebutuhan Kantor Bulanan',
      ],
    ),

    // ⭐ 2. RESTO & CAFE FINE DINING (UNGGULAN)
    ReceiptTemplate(
      id: 'flagship_restaurant',
      name: 'Resto & Cafe Fine Dining (Full Bill)',
      category: 'F&B & Retail',
      isFeatured: true,
      badge: '⭐ UNGGULAN',
      description: 'Format bill restoran & cafe mewah: identitas NIB & PB1 resto, nomor meja & jumlah pax, nama server/waiter, rincian menu hidangan, service charge 5%, pajak restoran PB1 10%, password WiFi, dan QR review bintang 5.',
      icon: Icons.dinner_dining_rounded,
      titleHeading: 'GUEST BILL & RECEIPT',
      samplePayer: 'Bpk. Hendra Wijaya',
      sampleCustomerPhone: '0813-7722-3344',
      sampleCashier: 'Bayu Pratama (Server #04)',
      sampleDescription: 'Dining Experience & Gathering Keluarga (4 Pax)',
      sampleNotes: 'Table 08 (VIP Lounge) - Steak Medium Well, No Straw',
      sampleDiscount: 88800,
      sampleTax: 83916,
      sampleCashReceived: 1000000,
      sampleItems: [
        ReceiptItem(id: 'rf_1', name: 'Wagyu Ribeye Steak 250g (MB5)', quantity: 2, unitPrice: 285000),
        ReceiptItem(id: 'rf_2', name: 'Creamy Truffle Fettuccine', quantity: 1, unitPrice: 125000),
        ReceiptItem(id: 'rf_3', name: 'Iced Lychee Blossom Tea', quantity: 2, unitPrice: 45000),
        ReceiptItem(id: 'rf_4', name: 'Signature Espresso Macchiato', quantity: 1, unitPrice: 38000),
        ReceiptItem(id: 'rf_5', name: 'Classic Italian Tiramisu', quantity: 1, unitPrice: 65000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        headerSubtitle: '',
        businessLegalId: '',
        contactInfo: '',
        leherField1Label: 'No. Meja / Table',
        leherField1Value: 'TABLE 08 (VIP Lounge - 4 Pax)',
        leherField2Label: 'Server / Host',
        leherField2Value: 'Bayu Pratama (Server #04)',
        leherField3Label: 'Tipe Order',
        leherField3Value: 'DINE IN (Makan di Tempat)',
        serviceChargeLabel: 'Service Charge (5%)',
        serviceChargeAmount: 39960,
        separatorChar: '-',
        showSignatures: false,
        signatureType: 'none',
        showBarcode: false,
        showQrCode: true,
        stampType: 'LUNAS',
        wifiInfo: 'Free WiFi SSID: GRAND-BISTRO-VIP | Pass: culinarylovers',
        socialMedia: 'IG: @grandbistro.jkt | TikTok: @grandbistroid',
        promoBanner: 'Scan QR di bawah untuk Google Review & dapatkan Dessert Gratis!',
        showTerms: true,
        termsText: 'Harga belum termasuk tipping sukarela untuk server Anda. Tidak ada service charge untuk takeaway.',
        customFooter: 'Terima Kasih Atas Kunjungan Anda\nSelamat Menikmati Hidangan & Sampai Jumpa!',
      ),
      descriptionPresets: [
        'Dining Experience & Gathering Keluarga (4 Pax)',
        'Romantic Dinner Set Course & Wine Pairing',
        'Executive Business Lunch Meeting (6 Pax)',
        'Afternoon High Tea & Artisan Pastry Platter',
        'Private Birthday Celebration Package',
      ],
    ),

    // ⭐ 3. BENGKEL RESMI & SERVIS OTOMOTIF (UNGGULAN)
    ReceiptTemplate(
      id: 'flagship_automotive',
      name: 'Bengkel Resmi & Servis Otomotif',
      category: 'Jasa & Servis',
      isFeatured: true,
      badge: '⭐ UNGGULAN',
      description: 'Nota work order & servis kendaraan bermotor paling komprehensif: plat nomor polisi, tipe mobil/motor, KM odometer, nama mekanik, rincian jasa & sparepart original, klausul garansi 14 hari/1000 KM, dan tanda tangan ganda.',
      icon: Icons.car_repair_rounded,
      titleHeading: 'NOTA SERVIS & SURAT JALAN KENDARAAN',
      samplePayer: 'Bpk. Ir. Bambang Setiawan',
      sampleCustomerPhone: '0812-2233-4455',
      sampleCashier: 'Mas Budi Hartono (Service Advisor)',
      sampleDescription: 'Servis Berkala 60.000 KM + Ganti Oli & Kuras Rem',
      sampleNotes: 'Innova Reborn Diesel V AT (Plat: D 1452 AUD) - Odo: 62.450 KM',
      sampleDiscount: 110000,
      sampleTax: 198000,
      sampleCashReceived: 2000000,
      sampleItems: [
        ReceiptItem(id: 'ba_1', name: 'Jasa Servis Berkala & Tune Up Injeksi', quantity: 1, unitPrice: 350000),
        ReceiptItem(id: 'ba_2', name: 'Oli Mesin TMO Diesel Synth 5W-30 (4L)', quantity: 2, unitPrice: 507500),
        ReceiptItem(id: 'ba_3', name: 'Filter Oli Original Toyota Innova', quantity: 1, unitPrice: 85000),
        ReceiptItem(id: 'ba_4', name: 'Filter Udara Mesin Reborn Diesel', quantity: 1, unitPrice: 220000),
        ReceiptItem(id: 'ba_5', name: 'Brake & Parts Cleaner Aerosol', quantity: 2, unitPrice: 45000),
        ReceiptItem(id: 'ba_6', name: 'Jasa Kuras Minyak Rem 4 Roda DOT 4', quantity: 1, unitPrice: 150000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        headerSubtitle: '',
        businessLegalId: '',
        contactInfo: '',
        leherField1Label: 'No. Polisi (Plat)',
        leherField1Value: 'D 1452 AUD (Innova Reborn Diesel)',
        leherField2Label: 'KM Odometer',
        leherField2Value: '62.450 KM (Next: 72.000 KM)',
        leherField3Label: 'Kepala Mekanik / SA',
        leherField3Value: 'Budi Hartono / Sigit',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Kepala Bengkel / SA',
        showBarcode: true,
        showQrCode: true,
        stampType: 'LUNAS RESMI',
        guaranteePolicy: 'GARANSI SERVIS: Berlaku 14 Hari kalender atau 1.000 KM sejak nota diterbitkan (mana tercapai lebih dulu). Garansi gugur jika segel mekanik rusak.',
        promoBanner: 'Jadwal Servis Berikutnya: 72.000 KM atau tgl 28/12/2026. Free cek rem & baterai!',
        socialMedia: 'IG: @garudamotorsport | Web: www.garudamotor.com',
        showTerms: true,
        termsText: 'Klaim garansi wajib menunjukkan nota asli dan segel tidak dirusak. Sparepart bekas dapat dibawa pulang pelanggan.',
        customFooter: 'Utamakan Keselamatan Berkendara Anda!\nTerima Kasih Atas Kepercayaan Anda',
      ),
      descriptionPresets: [
        'Servis Berkala 60.000 KM + Ganti Oli & Kuras Rem',
        'Overhaul Rem Depan Belakang & Ganti Kampas Rem',
        'Ganti Timing Belt, Tensioner & Water Pump Set',
        'Perbaikan Kaki-Kaki, Tierod, Ball Joint & Bushing',
        'Spooring 3D Digital & Balancing Finish 4 Roda',
      ],
    ),

    // ⭐ 4. KLINIK MEDIS, APOTEK & LABORATORIUM (UNGGULAN)
    ReceiptTemplate(
      id: 'flagship_clinic',
      name: 'Klinik Medis, Apotek & Lab Diagnostik',
      category: 'Kesehatan & Lifestyle',
      isFeatured: true,
      badge: '⭐ UNGGULAN',
      description: 'Kuitansi pelayanan kesehatan keluarga resmi: nomor rekam medis (RM), nama dokter spesialis & SIP, apoteker penanggung jawab, nama & usia pasien, rincian tindakan medis serta obat resep, tanda tangan apoteker, dan QR validasi resep.',
      icon: Icons.local_hospital_rounded,
      titleHeading: 'KUITANSI PELAYANAN MEDIS & RESEP OBAT',
      samplePayer: 'Ibu Ratna Puspita (Ibu Pasien)',
      sampleCustomerPhone: '0812-9988-7711',
      sampleCashier: 'apt. Rina Oktaviani, S.Farm (Apoteker)',
      sampleDescription: 'Pemeriksaan Dokter Spesialis Anak & Terapi Nebulizer',
      sampleNotes: 'Pasien: An. Keisha Aurelia (Usia 5 Th) - No RM: RM-092-881',
      sampleDiscount: 0,
      sampleTax: 0,
      sampleCashReceived: 600000,
      sampleItems: [
        ReceiptItem(id: 'km_1', name: 'Jasa Konsultasi dr. Spesialis Anak (Sp.A)', quantity: 1, unitPrice: 250000),
        ReceiptItem(id: 'km_2', name: 'Tindakan Terapi Inhalasi Nebulizer Medis', quantity: 1, unitPrice: 120000),
        ReceiptItem(id: 'km_3', name: 'Obat Resep: Sirup Cefixime 100mg/5ml', quantity: 1, unitPrice: 85000),
        ReceiptItem(id: 'km_4', name: 'Obat Resep: Sirup Paracetamol Drop 15ml', quantity: 1, unitPrice: 45000),
        ReceiptItem(id: 'km_5', name: 'Multivitamin Curcuma Plus Sirup 100ml', quantity: 1, unitPrice: 38000),
        ReceiptItem(id: 'km_6', name: 'Biaya Adm & Pendaftaran Pasien Baru', quantity: 1, unitPrice: 25000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        headerSubtitle: '',
        businessLegalId: '',
        contactInfo: '',
        leherField1Label: 'No. Rekam Medis (RM)',
        leherField1Value: 'RM-092-881 (An. Keisha / 5 Th)',
        leherField2Label: 'Dokter Pemeriksa',
        leherField2Value: 'dr. Farhan Sp.A (SIP: 503/440/2024)',
        leherField3Label: 'Apoteker Penanggung',
        leherField3Value: 'apt. Rina Oktaviani, S.Farm',
        separatorChar: '-',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Apoteker / Kasir Medis',
        showBarcode: true,
        showQrCode: true,
        stampType: 'LUNAS RESMI',
        guaranteePolicy: 'PERHATIAN MEDIS: Habiskan antibiotik sesuai anjuran dokter. Simpan obat di tempat kering sejuk terlindung cahaya matahari.',
        socialMedia: 'Layanan Ambulans 24 Jam: 0815-6677-8899',
        showTerms: true,
        termsText: 'Obat yang sudah dibeli tidak dapat ditukar/dikembalikan demi menjamin integritas mutu dan keamanan farmasi medis.',
        customFooter: 'Semoga Lekas Sembuh & Sehat Selalu\nKesehatan Keluarga Anda Adalah Prioritas Kami',
      ),
      descriptionPresets: [
        'Pemeriksaan Dokter Spesialis Anak & Terapi Nebulizer',
        'Konsultasi Dokter Umum & Paket Obat Flu Batuk Demam',
        'Pemeriksaan Laboratorium Darah Lengkap & Gula Darah',
        'Tindakan Perawatan Luka Bedah Minor & Ganti Perban',
        'Pemeriksaan Gigi, Pembersihan Karang (Scaling) & Tambal',
      ],
    ),

    // ⭐ 5. KWITANSI RESMI KORPORAT, PAJAK & PROPERTI (UNGGULAN)
    ReceiptTemplate(
      id: 'flagship_corporate',
      name: 'Kwitansi Resmi Korporat, Pajak & Properti',
      category: 'Umum & Bisnis',
      isFeatured: true,
      badge: '⭐ UNGGULAN',
      description: 'Format dokumen hukum & perpajakan resmi perusahaan: NPWP & legalitas badan hukum, nomor kontrak/PO proyek, nominal jumbo terbilang formal, rekening korporat verified, stempel materai resmi, klausul hukum perdata, dan tanda tangan direktur.',
      icon: Icons.domain_rounded,
      titleHeading: 'KWITANSI PEMBAYARAN RESMI BERMATERAI',
      samplePayer: 'PT. SINAR JAYA NUSANTARA',
      sampleCustomerPhone: '0811-1234-5678',
      sampleCashier: 'Dra. Hj. Ratna Juwita, M.M (Finance Director)',
      sampleDescription: 'Pelunasan Pembayaran Sewa Office Suite 2501 (350 m2) Periode Okt 2026 - Sept 2027 Termasuk Maintenance',
      sampleNotes: 'Nomor PO: PO-GMP-99120 | No. Kontrak: KTR/GMP-SJN/PROJ-VII/2026',
      sampleDiscount: 0,
      sampleTax: 0,
      sampleCashReceived: 0,
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        headerSubtitle: '',
        businessLegalId: '',
        contactInfo: '',
        leherField1Label: 'No. Bukti Transaksi',
        leherField1Value: 'KWT/GMP-FIN/IX/2026/0889',
        leherField2Label: 'NPWP Penyetor',
        leherField2Value: '01.998.776.5-015.000 (PT Sinar Jaya)',
        leherField3Label: 'No. Kontrak / PO',
        leherField3Value: 'KTR/GMP-SJN/PROJ-VII/2026',
        titleFontSize: 'large',
        amountFontSize: 'extra_large',
        boldTitle: true,
        boldAmount: true,
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Finance & Accounting Director',
        showBarcode: true,
        showQrCode: true,
        stampType: 'LUNAS RESMI',
        showBankInfo: true,
        guaranteePolicy: 'LEGALITAS HUKUM: Kwitansi ini adalah bukti pembayaran yang sah dan berkekuatan hukum tetap sesuai KUH Perdata Pasal 1320. Pembayaran telah diverifikasi masuk ke rekening korporat.',
        socialMedia: 'Website: www.grahamakmur.co.id | Portal: partner.grahamakmur.co.id',
        showTerms: true,
        termsText: 'Kuitansi asli ini diterbitkan 1 (satu) rangkap untuk pihak penyetor sebagai dokumen pembukuan akuntansi dan perpajakan resmi.',
        customFooter: 'Dokumen Resmi Keuangan PT Graha Makmur Propertindo\nDisimpan Sebagai Dokumen Pembukuan Pajak Resmi',
      ),
      descriptionPresets: [
        'Pelunasan Pembayaran Sewa Office Suite 2501 (350 m2) Periode Okt 2026 - Sept 2027 Termasuk Maintenance',
        'Pembayaran Uang Muka (Down Payment 30%) Proyek Konstruksi Pabrik',
        'Pembayaran Termin ke-3 (Progress Fisik 75%) Pengadaan Server & IT Infrastructure',
        'Pelunasan Biaya Jasa Konsultasi Hukum & Audit Finansial Tahunan',
        'Pembayaran Biaya Pengelolaan Gedung (Service Charge & Sinking Fund) Triwulan IV',
      ],
    ),


    // =========================================================================
    // TEMPLATE STANDAR & SEKTORAL
    // =========================================================================

// 1. Standar Formal
    ReceiptTemplate(
      id: 'standard_formal',
      name: 'Standar Formal',
      category: 'Umum & Bisnis',
      description: 'Kwitansi resmi standar perkantoran & perusahaan dengan garis tegas dan tanda tangan ganda.',
      icon: Icons.assignment_outlined,
      titleHeading: 'KWITANSI PEMBAYARAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Penerima',
        showQrCode: true,
      ),
    ),

    // 2. Kasir Retail & Toko
    ReceiptTemplate(
      id: 'retail_store',
      name: 'Kasir Retail & Toko',
      category: 'F&B & Retail',
      description: 'Format struk kasir toko atau minimarket dengan barcode dan syarat retur barang.',
      icon: Icons.storefront_outlined,
      titleHeading: 'STRUK PEMBELIAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showSignatures: false,
        signatureType: 'none',
        showBarcode: true,
        showTerms: true,
        termsText: 'Barang yang sudah dibeli tidak dapat ditukar/dikembalikan.',
        customFooter: 'Terima kasih atas kunjungan Anda!',
      ),
    ),

    // 3. Restoran, Cafe & F&B
    ReceiptTemplate(
      id: 'resto_cafe',
      name: 'Restoran, Cafe & F&B',
      category: 'F&B & Retail',
      description: 'Struk resto/cafe dengan info pesanan, password WiFi, dan ucapan selamat menikmati.',
      icon: Icons.restaurant_outlined,
      titleHeading: 'ORDER & PAYMENT BILL',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showSignatures: false,
        signerTitle: 'Kasir/Server',
        showQrCode: true,
        customFooter: 'Free WiFi: AUD-GUEST | Pass: kopienak123\nSelamat Menikmati Hidangan!',
      ),
    ),

    // 4. Bengkel & Otomotif
    ReceiptTemplate(
      id: 'automotive_workshop',
      name: 'Bengkel & Otomotif',
      category: 'Jasa & Servis',
      description: 'Nota jasa servis motor/mobil dengan garansi perbaikan dan tanda tangan mekanik.',
      icon: Icons.car_repair_outlined,
      titleHeading: 'KWITANSI SERVIS KENDARAAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Kepala Bengkel / Mekanik',
        showTerms: true,
        termsText: 'Garansi servis berlaku 14 hari. Wajib bawa nota fisik.',
        customFooter: 'Servis Rutin Kendaraan Anda Demi Keselamatan!',
      ),
    ),

    // 5. Laundry & Dry Clean
    ReceiptTemplate(
      id: 'laundry_service',
      name: 'Laundry & Dry Clean',
      category: 'Jasa & Servis',
      description: 'Kwitansi cucian kiloan/satuan lengkap dengan tanggal selesai dan aturan klaim.',
      icon: Icons.local_laundry_service_outlined,
      titleHeading: 'NOTA LAUNDRY',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showSignatures: true,
        signatureType: 'single',
        signerTitle: 'Petugas Kasir',
        showTerms: true,
        termsText: 'Klaim luntur/hilang max 1x24 jam sejak pengambilan wajib menyertakan nota ini.',
        customFooter: 'Pakaian Bersih, Harum & Rapi',
      ),
    ),

    // 6. Rental Mobil & Motor
    ReceiptTemplate(
      id: 'vehicle_rental',
      name: 'Rental Mobil & Motor',
      category: 'Jasa & Servis',
      description: 'Bukti sewa armada kendaraan dengan klausul jaminan dan denda keterlambatan.',
      icon: Icons.key_outlined,
      titleHeading: 'BUKTI SEWA KENDARAAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Pihak Rental',
        showTerms: true,
        termsText: 'Overtime denda Rp 50.000/jam. BBM kembali sesuai posisi awal.',
        customFooter: 'Hati-hati di jalan, utamakan keselamatan!',
      ),
    ),

    // 7. Klinik & Apotek
    ReceiptTemplate(
      id: 'clinic_medical',
      name: 'Klinik, Medis & Apotek',
      category: 'Kesehatan & Lifestyle',
      description: 'Kwitansi pembayaran konsultasi, perawatan medis, atau tebus obat apotek.',
      icon: Icons.local_hospital_outlined,
      titleHeading: 'BUKTI PEMBAYARAN MEDIS',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showSignatures: true,
        signatureType: 'single',
        signerTitle: 'Apoteker / Kasir Medis',
        showQrCode: true,
        customFooter: 'Semoga Lekas Sembuh & Sehat Selalu',
      ),
    ),

    // 8. Ekspedisi & Logistik
    ReceiptTemplate(
      id: 'logistics_shipping',
      name: 'Ekspedisi & Logistik',
      category: 'Jasa & Servis',
      description: 'Resi pengiriman paket barang dengan barcode pelacakan dan konfirmasi biaya kirim.',
      icon: Icons.local_shipping_outlined,
      titleHeading: 'RESI PENGIRIMAN LOGISTIK',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showBarcode: true,
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Petugas Loket',
        showTerms: true,
        termsText: 'Paket diasuransikan sesuai ketentuan ekspedisi.',
        customFooter: 'Lacak kiriman di website resmi kami',
      ),
    ),

    // 9. Salon & Barbershop
    ReceiptTemplate(
      id: 'salon_barber',
      name: 'Salon & Barbershop',
      category: 'Kesehatan & Lifestyle',
      description: 'Struk perawatan rambut dan kecantikan dengan nama stylist/kapster.',
      icon: Icons.content_cut_outlined,
      titleHeading: 'BEAUTY & GROOMING RECEIPT',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '.',
        showSignatures: false,
        signerTitle: 'Stylist / Kasir',
        customFooter: 'Terima kasih telah mempercayakan penampilan Anda!',
      ),
    ),

    // 10. Toko Emas & Perhiasan
    ReceiptTemplate(
      id: 'jewelry_gold',
      name: 'Toko Emas & Perhiasan',
      category: 'Kemewahan & Investasi',
      description: 'Surat bukti pembelian perhiasan emas dengan klausul buyback dan jaminan kadar.',
      icon: Icons.diamond_outlined,
      titleHeading: 'SURAT BUKTI PEMBELIAN EMAS',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Toko Emas',
        showTerms: true,
        termsText: 'Penjualan kembali (buyback) wajib membawa surat nota ini & barang utuh.',
        customFooter: 'Investasi Masa Depan Terpercaya',
      ),
    ),

    // 11. Servis HP & Gadget
    ReceiptTemplate(
      id: 'gadget_repair',
      name: 'Servis HP & Laptop',
      category: 'Jasa & Servis',
      description: 'Tanda terima servis perangkat elektronik dengan garansi perbaikan 30 hari.',
      icon: Icons.devices_other_outlined,
      titleHeading: 'NOTA SERVIS GADGET',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showBarcode: true,
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Teknisi / Admin',
        showTerms: true,
        termsText: 'Garansi servis 30 hari pada kerusakan yang sama (bukan human error/kena air).',
        customFooter: 'Barang tidak diambil > 60 hari di luar tanggung jawab kami.',
      ),
    ),

    // 12. Booking Fee & Properti
    ReceiptTemplate(
      id: 'property_booking',
      name: 'Booking & DP Properti',
      category: 'Properti & Real Estate',
      description: 'Kwitansi tanda jadi atau uang muka pemesanan unit properti / kavling tanah.',
      icon: Icons.apartment_outlined,
      titleHeading: 'KWITANSI UANG MUKA (DP)',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Developer / Agen Properti',
        showTerms: true,
        termsText: 'Pembatalan sepihak mengakibatkan uang booking tidak dapat ditarik kembali.',
        customFooter: 'Selamat atas investasi masa depan Anda!',
      ),
    ),

    // 13. SPP & Pendidikan
    ReceiptTemplate(
      id: 'school_tuition',
      name: 'SPP & Biaya Pendidikan',
      category: 'Pendidikan',
      description: 'Bukti pembayaran SPP sekolah, uang pendaftaran kursus, atau bimbingan belajar.',
      icon: Icons.school_outlined,
      titleHeading: 'BUKTI PEMBAYARAN PENDIDIKAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'single',
        signerTitle: 'Bendahara Sekolah / Yayasan',
        showQrCode: true,
        customFooter: 'Simpan bukti pembayaran ini untuk bukti kelulusan administrasi.',
      ),
    ),

    // 14. Donasi, Zakat & Infaq
    ReceiptTemplate(
      id: 'donation_zakat',
      name: 'Donasi, Zakat & Infaq',
      category: 'Sosial & Keagamaan',
      description: 'Tanda penerimaan zakat, sedekah, dan donasi kemanusiaan dengan doa mustahiq.',
      icon: Icons.volunteer_activism_outlined,
      titleHeading: 'BUKTI PENERIMAAN ZAKAT / INFAQ',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '.',
        showSignatures: true,
        signatureType: 'single',
        signerTitle: 'Amil / Petugas Yayasan',
        showQrCode: true,
        customFooter: 'Jazakumullah Khairan Katsiran.\nSemoga Allah melimpahkan berkah & rezeki berlimpah.',
      ),
    ),

    // 15. Tagihan & PPOB
    ReceiptTemplate(
      id: 'utility_ppob',
      name: 'Tagihan & PPOB',
      category: 'Keuangan & Tagihan',
      description: 'Struk pembayaran tagihan rutin seperti listrik, PDAM, pulsa, dan iuran WiFi.',
      icon: Icons.receipt_long_outlined,
      titleHeading: 'STRUK PEMBAYARAN TAGIHAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showSignatures: false,
        showBarcode: true,
        customFooter: 'Struk ini merupakan bukti pembayaran yang sah dari penyedia layanan.',
      ),
    ),

    // 16. Hotel & Penginapan
    ReceiptTemplate(
      id: 'hotel_lodging',
      name: 'Hotel & Penginapan',
      category: 'Hospitality & Travel',
      description: 'Kwitansi sewa kamar hotel, villa, atau homestay lengkap dengan info check-out.',
      icon: Icons.hotel_outlined,
      titleHeading: 'GUEST FOLIO / HOTEL BILL',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'single',
        signerTitle: 'Front Office Cashier',
        showTerms: true,
        termsText: 'Check-out time maks pukul 12.00 WIB. Harap kembalikan kunci kamar.',
        customFooter: 'Wishing you a pleasant and memorable stay!',
      ),
    ),

    // 17. Parkir & Karcis Masuk
    ReceiptTemplate(
      id: 'parking_ticket',
      name: 'Parkir & Karcis Masuk',
      category: 'Tiket & Retribusi',
      description: 'Karcis retribusi parkir atau tiket tempat wisata dengan barcode gerbang.',
      icon: Icons.local_parking_outlined,
      titleHeading: 'KARCIS RETRIBUSI RESMI',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '-',
        showSignatures: false,
        showBarcode: true,
        showTerms: true,
        termsText: 'Kehilangan karcis dikenakan denda sesuai peraturan pengelola.',
        customFooter: 'Jangan tinggalkan barang berharga di kendaraan.',
      ),
    ),

    // 18. Minimalis Clean Modern
    ReceiptTemplate(
      id: 'minimalist_modern',
      name: 'Minimalis Clean Modern',
      category: 'Desain Khusus',
      description: 'Tata letak ultra-bersih tanpa ornamen ramai, spasi lega dan tipografi kontras tinggi.',
      icon: Icons.crop_portrait_outlined,
      titleHeading: 'BUKTI PEMBAYARAN',
      defaultConfig: TemplateConfig(
        headerAlign: 'left',
        separatorChar: '-',
        showTagline: false,
        showSignatures: true,
        signatureType: 'single',
        signerTitle: 'Otorisasi',
        showQrCode: true,
      ),
    ),

    // 19. Elegan & Klasik Luxury
    ReceiptTemplate(
      id: 'classic_luxury',
      name: 'Elegan & Klasik Luxury',
      category: 'Desain Khusus',
      description: 'Desain megah dengan ornamen bintang, garis ganda klasik, dan nuansa mewah.',
      icon: Icons.auto_awesome_outlined,
      titleHeading: 'KWITANSI RESMI EKSKLUSIF',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '*',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Direksi / Penerima',
        showQrCode: true,
        customFooter: '✦ ✦ ✦  EXCELLENCE IN QUALITY  ✦ ✦ ✦',
      ),
    ),

    // 20. Border Box Kotak Klasik
    ReceiptTemplate(
      id: 'boxed_frame',
      name: 'Border Box Kotak Klasik',
      category: 'Desain Khusus',
      description: 'Format kotak retro yang dibingkai garis bingkai ASCII di sekeliling kwitansi.',
      icon: Icons.crop_square_outlined,
      titleHeading: 'KWITANSI KOTAK RETRO',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '#',
        isBoxedFrame: true,
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Penerima Sah',
        showQrCode: true,
      ),
    ),

    // 21. Faktur Pajak Sederhana
    ReceiptTemplate(
      id: 'tax_invoice',
      name: 'Faktur Pajak Sederhana',
      category: 'Umum & Bisnis',
      description: 'Nota komersial berstandar faktur sederhana dengan informasi pajak & legalitas usaha.',
      icon: Icons.account_balance_outlined,
      titleHeading: 'FAKTUR PENJUALAN & PAJAK',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '=',
        showSignatures: true,
        signatureType: 'dual',
        signerTitle: 'Penjual Kena Pajak',
        showQrCode: true,
        showTerms: true,
        termsText: 'Faktur ini merupakan bukti transaksi sah sesuai perpajakan yang berlaku.',
        customFooter: 'Terima kasih atas kepatuhan pajak Anda.',
      ),
    ),

    // 22. Tiket Event & Workshop
    ReceiptTemplate(
      id: 'event_ticket',
      name: 'Event, Seminar & Tiket',
      category: 'Tiket & Retribusi',
      description: 'Kwitansi registrasi event/seminar/workshop dengan QR code untuk akses masuk pintu gerbang.',
      icon: Icons.confirmation_number_outlined,
      titleHeading: 'TIKET REGISTRASI EVENT',
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        separatorChar: '*',
        showSignatures: false,
        showQrCode: true,
        showTerms: true,
        termsText: 'Tunjukkan QR Code ini pada petugas gerbang saat registrasi ulang.',
        customFooter: 'Sampai jumpa di lokasi acara!',
      ),
    ),

    // 23. ⭐ MINIMARKET LENGKAP (Indomaret / Alfamart Style - FULL POS)
    ReceiptTemplate(
      id: 'minimarket_pos',
      name: '🏪 Minimarket Lengkap (POS Kasir)',
      category: 'Belanja & Retail',
      isFeatured: true,
      badge: '🏪 LENGKAP',
      description: 'Struk kasir minimarket TERLENGKAP gaya Indomaret/Alfamart: 15+ item dari sembako, minuman, snack/ciki, kebersihan & peralatan RT, diskon member, pajak, barcode, poin reward, dan QR digital.',
      icon: Icons.store_rounded,
      titleHeading: 'STRUK PEMBELIAN',
      samplePayer: 'Pelanggan Umum',
      sampleCashier: 'Susi (REG-02 / Shift Siang)',
      sampleDescription: 'Belanja Harian — Sembako, Minuman, Snack & Kebutuhan RT',
      sampleNotes: 'Member Card: 0812-3456-7890 | VIP Silver',
      sampleDiscount: 12500,
      sampleTax: 0,
      sampleCashReceived: 300000,
      sampleItems: [
        // === SEMBAKO ===
        ReceiptItem(id: 'mk_01', name: 'Beras Pulen Wangi 5kg        [SKU:BR005]', quantity: 1, unitPrice: 72000),
        ReceiptItem(id: 'mk_02', name: 'Minyak Goreng Tropical 2L    [SKU:MG002]', quantity: 2, unitPrice: 38500),
        ReceiptItem(id: 'mk_03', name: 'Gula Pasir Gulaku 1kg        [SKU:GP001]', quantity: 1, unitPrice: 17500),
        ReceiptItem(id: 'mk_04', name: 'Telur Ayam Omega 10 butir    [SKU:TA010]', quantity: 1, unitPrice: 28000),
        // === MINUMAN ===
        ReceiptItem(id: 'mk_05', name: 'Aqua Botol 600ml             [SKU:AQ600]', quantity: 3, unitPrice: 4500),
        ReceiptItem(id: 'mk_06', name: 'Teh Pucuk Harum 350ml        [SKU:TP350]', quantity: 2, unitPrice: 5000),
        ReceiptItem(id: 'mk_07', name: 'Susu Bearbrand 140ml         [SKU:SB140]', quantity: 3, unitPrice: 8000),
        ReceiptItem(id: 'mk_08', name: 'Kopi Good Day 3in1 Mocafé    [SKU:KG3M1]', quantity: 5, unitPrice: 3000),
        // === SNACK & CIKI ===
        ReceiptItem(id: 'mk_09', name: 'Indomie Goreng Spesial       [SKU:IM001]', quantity: 5, unitPrice: 3500),
        ReceiptItem(id: 'mk_10', name: 'Chitato Sapi Panggang 75g    [SKU:CT075]', quantity: 2, unitPrice: 11000),
        ReceiptItem(id: 'mk_11', name: 'Taro Net Original 65g        [SKU:TN065]', quantity: 1, unitPrice: 9500),
        ReceiptItem(id: 'mk_12', name: 'Oreo Vanilla 119g            [SKU:OR119]', quantity: 1, unitPrice: 14500),
        // === KEBERSIHAN & PERAWATAN ===
        ReceiptItem(id: 'mk_13', name: 'Sabun Lifebuoy Total 75g     [SKU:SL075]', quantity: 2, unitPrice: 5500),
        ReceiptItem(id: 'mk_14', name: 'So Klin Lantai 800ml         [SKU:SK800]', quantity: 1, unitPrice: 18500),
        // === PERALATAN RUMAH TANGGA ===
        ReceiptItem(id: 'mk_15', name: 'Rinso Matic Bubuk 800g       [SKU:RM800]', quantity: 1, unitPrice: 32000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        titleAlign: 'center',
        amountFontSize: 'large',
        headerSubtitle: '',
        businessLegalId: '',
        contactInfo: '',
        leherField1Label: 'No. Register',
        leherField1Value: 'REG-02 / Shift Siang (12:00-20:00)',
        leherField2Label: 'Kartu Member',
        leherField2Value: '0812-3456-7890 [VIP Silver]',
        leherField3Label: 'Tgl & Jam',
        leherField3Value: '28/09/2026  14:32:07',
        separatorChar: '-',
        showSignatures: false,
        signatureType: 'none',
        showReceivedFrom: false,
        showAmountWords: false,
        showDescription: true,
        labelDescription: 'Keterangan:',
        showBarcode: true,
        showQrCode: true,
        showBankInfo: false,
        stampType: 'LUNAS',
        memberReward: '★ Poin Belanja: +35 Poin  •  Saldo Poin: 1.284 Poin ★\n  Tukar 500 Poin = Diskon Rp 5.000 di transaksi berikutnya',
        promoBanner: '🔥 PROMO: Beli 2 Minyak Tropical hemat Rp 5.000!\n   Senin-Jumat: Extra Poin 2x untuk Member Silver & Gold',
        socialMedia: 'IG/TikTok: @minimarketku | Web: www.minimarketku.id',
        serviceChargeLabel: 'Kantong Plastik (Opsional)',
        serviceChargeAmount: 200,
        showTerms: true,
        termsText: '• Struk = bukti bayar sah, simpan dengan baik.\n• Retur/penukaran maks 1x24 jam dengan struk asli.\n• Produk beku, segar & makanan siap saji tdk dpt diretur.\n• Keberatan transaksi hub. CS: 1500-400.',
        customFooter: 'Terima Kasih Sudah Berbelanja! 🛒\n Selamat Datang Kembali — Hemat Setiap Hari!',
        blankLinesAtEnd: 3,
      ),
    ),

    // 24. Toko Sembako & Kelontong
    ReceiptTemplate(
      id: 'toko_sembako',
      name: 'Toko Sembako & Kelontong',
      category: 'Belanja & Retail',
      description: 'Nota belanja toko sembako dan kelontong tradisional dengan rincian item, harga satuan, subtotal, dan kembalian tunai.',
      icon: Icons.rice_bowl_rounded,
      titleHeading: 'NOTA PEMBELIAN',
      samplePayer: 'Bu Sari',
      sampleCashier: 'Pemilik',
      sampleDescription: 'Pembelian Bahan Sembako & Kebutuhan Dapur',
      sampleCashReceived: 200000,
      sampleItems: [
        ReceiptItem(id: 'sk_1', name: 'Beras Setra Ramos 5kg', quantity: 2, unitPrice: 68000),
        ReceiptItem(id: 'sk_2', name: 'Minyak Goreng Refill 2L', quantity: 1, unitPrice: 35000),
        ReceiptItem(id: 'sk_3', name: 'Gula Pasir 1kg', quantity: 1, unitPrice: 17000),
        ReceiptItem(id: 'sk_4', name: 'Telur Ayam Ras (1kg)', quantity: 1, unitPrice: 30000),
        ReceiptItem(id: 'sk_5', name: 'Tepung Terigu Segitiga 1kg', quantity: 2, unitPrice: 14000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        titleAlign: 'center',
        headerSubtitle: 'Lengkap, Murah & Terpercaya',
        separatorChar: '-',
        showSignatures: false,
        signatureType: 'none',
        showAmountWords: false,
        showReceivedFrom: true,
        labelReceivedFrom: 'Pembeli:',
        showBarcode: false,
        showQrCode: false,
        stampType: 'none',
        showTerms: true,
        termsText: 'Barang yang sudah dibeli tidak dapat dikembalikan. Harga sewaktu-waktu berubah.',
        customFooter: 'Terima Kasih\nBelanja Lagi Ya! :)',
      ),
    ),

    // 25. Toko Online & Warung Digital
    ReceiptTemplate(
      id: 'warung_digital',
      name: 'Toko Online & Warung Digital',
      category: 'Belanja & Retail',
      description: 'Struk modern untuk toko online/warung digital: nomor pesanan/order, QR code verifikasi, info pengiriman, barcode paket, dan sosmed toko.',
      icon: Icons.shopping_bag_rounded,
      titleHeading: 'KONFIRMASI PESANAN',
      samplePayer: 'Agus Salim (Pelanggan Toko)',
      sampleCustomerPhone: '0812-9988-7766',
      sampleCashier: 'Admin Toko',
      sampleDescription: 'Pembelian Produk via Toko Online / COD',
      sampleNotes: 'Pengiriman: JNE REG | Estimasi: 2-3 Hari Kerja',
      sampleDiscount: 10000,
      sampleItems: [
        ReceiptItem(id: 'wd_1', name: 'Kopi Sachet Kapal Api Spesial (10pc)', quantity: 2, unitPrice: 22000),
        ReceiptItem(id: 'wd_2', name: 'Teh Sariwangi Tali (25 sachet)', quantity: 1, unitPrice: 14000),
        ReceiptItem(id: 'wd_3', name: 'Mie Sedaap Goreng (5 bks)', quantity: 3, unitPrice: 18500),
        ReceiptItem(id: 'wd_4', name: 'Garam Dapur Cap Kapal 250g (2pcs)', quantity: 1, unitPrice: 9000),
      ],
      defaultConfig: TemplateConfig(
        headerAlign: 'center',
        titleAlign: 'center',
        headerSubtitle: 'Toko Online Terpercaya • Fast Response',
        contactInfo: 'WA: 0812-3456-7890 | IG: @warungdigital_id',
        leherField1Label: 'No. Order',
        leherField1Value: '#WD-2026-08891',
        leherField2Label: 'Status',
        leherField2Value: 'LUNAS / PAID',
        separatorChar: '=',
        showSignatures: false,
        signatureType: 'none',
        showBarcode: true,
        showQrCode: true,
        showAmountWords: false,
        showReceivedFrom: true,
        labelReceivedFrom: 'Pemesan:',
        stampType: 'LUNAS',
        socialMedia: 'Tokopedia | Shopee | TikTok Shop: @warungdigital',
        promoBanner: 'Gratis Ongkir Min. Belanja 100rb! Kode: HEMAT100',
        memberReward: '★ Poin Loyalitas: +5 Poin (Saldo: 128 Poin) ★',
        showTerms: true,
        termsText: 'Pesanan tidak bisa dibatalkan setelah dikonfirmasi. Komplain maks 1x24 jam setelah diterima.',
        customFooter: 'Terima Kasih Sudah Berbelanja!\nRating & Ulasan = Semangat Kami ⭐',
      ),
    ),
  ];

  /// Find a template by ID (defaults to standard_formal if not found)
  static ReceiptTemplate findById(String? id) {
    if (id == null || id.isEmpty) {
      return allTemplates.firstWhere((t) => t.id == 'standard_formal', orElse: () => allTemplates.first);
    }
    return allTemplates.firstWhere(
      (t) => t.id == id,
      orElse: () => allTemplates.firstWhere((t) => t.id == 'standard_formal', orElse: () => allTemplates.first),
    );
  }

  /// Get distinct template categories (with ⭐ Unggulan first)
  static List<String> get categories {
    final set = <String>{'Semua', '⭐ Unggulan'};
    for (final t in allTemplates) {
      if (t.category != '⭐ Unggulan') {
        set.add(t.category);
      }
    }
    return set.toList();
  }

  /// Get contextual description presets tailored to the template
  static List<String> getPresets(String templateId) {
    switch (templateId) {
      case 'flagship_supermarket':
        return [
          'Belanja Kebutuhan Pokok Sembako & Dapur Bulanan',
          'Pembelian Paket Perlengkapan Rumah Tangga & Sanitasi',
          'Belanja Bahan Makanan Segar, Buah & Daging',
          'Pembelian Snack, Biskuit & Minuman Ringan',
          'Pengadaan ATK & Kebutuhan Kantor Bulanan',
        ];
      case 'flagship_restaurant':
        return [
          'Dining Experience & Gathering Keluarga (4 Pax)',
          'Romantic Dinner Set Course & Wine Pairing',
          'Executive Business Lunch Meeting (6 Pax)',
          'Afternoon High Tea & Artisan Pastry Platter',
          'Private Birthday Celebration Package',
        ];
      case 'flagship_automotive':
        return [
          'Servis Berkala 60.000 KM + Ganti Oli & Kuras Rem',
          'Overhaul Rem Depan Belakang & Ganti Kampas Rem',
          'Ganti Timing Belt, Tensioner & Water Pump Set',
          'Perbaikan Kaki-Kaki, Tierod, Ball Joint & Bushing',
          'Spooring 3D Digital & Balancing Finish 4 Roda',
        ];
      case 'flagship_clinic':
        return [
          'Pemeriksaan Dokter Spesialis Anak & Terapi Nebulizer',
          'Konsultasi Dokter Umum & Paket Obat Flu Batuk Demam',
          'Pemeriksaan Laboratorium Darah Lengkap & Gula Darah',
          'Tindakan Perawatan Luka Bedah Minor & Ganti Perban',
          'Pemeriksaan Gigi, Pembersihan Karang (Scaling) & Tambal',
        ];
      case 'flagship_corporate':
        return [
          'Pelunasan Pembayaran Sewa Office Suite 2501 (350 m2) Periode Okt 2026 - Sept 2027 Termasuk Maintenance',
          'Pembayaran Uang Muka (Down Payment 30%) Proyek Konstruksi Pabrik',
          'Pembayaran Termin ke-3 (Progress Fisik 75%) Pengadaan Server & IT Infrastructure',
          'Pelunasan Biaya Jasa Konsultasi Hukum & Audit Finansial Tahunan',
          'Pembayaran Biaya Pengelolaan Gedung (Service Charge & Sinking Fund) Triwulan IV',
        ];
      case 'automotive_workshop':
        return [
          'Servis Rutin Berkala + Ganti Oli Mesin',
          'Ganti Kampas Rem Depan/Belakang',
          'Tune Up Mesin & Pembersihan Throttle Body',
          'Ganti Aki Kering GS Astra + Servis CVT',
          'Spooring & Balancing 4 Roda',
        ];
      case 'retail_store':
        return [
          'Pembelian Alat Tulis Kantor & Kertas HVS',
          'Belanja Perlengkapan Rumah Tangga',
          'Pembelian Paket Sembako Toko',
          'Belanja Bahan Baku Produksi',
          'Pembelian Barang Pecah Belah',
        ];
      case 'resto_cafe':
        return [
          'Paket Makan Siang Keluarga & Minuman',
          'Reservasi Meja Acara Ulang Tahun (15 Pax)',
          'Pesanan Coffee Break & Snack Box',
          'Catering Nasi Box Ayam Bakar (30 Porsi)',
          'Paket Dinner Romantis Spesial',
        ];
      case 'laundry_service':
        return [
          'Cuci Komplit Reguler (Cuci + Kering + Setrika)',
          'Cuci Kiloan Express 1 Hari Selesai',
          'Cuci Bedcover & Selimut Tebal Jumbo',
          'Dry Cleaning Jas & Celana Formal',
          'Cuci Sepatu Sneaker & Tas Kulit',
        ];
      case 'medical_clinic':
        return [
          'Konsultasi Dokter Umum & Pemeriksaan Fisik',
          'Penebusan Resep Obat & Multivitamin',
          'Tindakan Perawatan Luka & Jahitan',
          'Pemeriksaan Lab Gula Darah & Kolesterol',
          'Pemeriksaan USG Kandungan & Konsultasi',
        ];
      case 'salon_barbershop':
        return [
          'Potong Rambut Stylish + Cuci Rambut + Pijat',
          'Pewarnaan Rambut (Coloring) & Bleaching',
          'Perawatan Creambath Tradisional & Hair Mask',
          'Paket Cukur Kumis/Jenggot + Hot Towel',
          'Perawatan Facial Wajah & Totok Wajah',
        ];
      case 'property_rent':
        return [
          'Pembayaran Sewa Kamar Kost Periode Bulan Ini',
          'Deposit Jaminan Kunci & Kamar (Refundable)',
          'Iuran Pemeliharaan Listrik, Air & WiFi Kost',
          'Pelunasan Sewa Rumah Kontrakan 1 Tahun',
          'Sewa Paviliun Bulanan Termasuk AC & Kasur',
        ];
      case 'education_course':
        return [
          'Pembayaran SPP / Iuran Kursus Bulan Ini',
          'Biaya Pendaftaran Siswa Baru & Buku Modul',
          'Paket Bimbingan Belajar Intensif UN / UTBK',
          'Les Privat Bahasa Inggris (8 Pertemuan)',
          'Biaya Ujian Sertifikasi & Kelulusan',
        ];
      case 'car_rental':
        return [
          'Sewa Mobil Avanza 24 Jam Lepas Kunci',
          'Rental Mobil Innova Reborn + Driver + BBM',
          'Deposit Jaminan Sewa Mobil (Refundable)',
          'Biaya Tambahan Jam (Overtime 4 Jam)',
          'Antar Jemput Bandara (Drop Off / Pick Up)',
        ];
      case 'carwash_detailing':
        return [
          'Cuci Mobil Hidrolik Salju + Kolong Sasis',
          'Paket Cuci Komplit + Vacuum Interior Kabin',
          'Poles Jamur Kaca Depan & Samping',
          'Paket Detailing Interior & Fogging Bakteri',
          'Poles Bodi 3 Step Nano Ceramic Coating',
        ];
      case 'wedding_photography':
        return [
          'DP Paket Dokumentasi Foto & Video Wedding',
          'Pelunasan Dokumentasi Resepsi Pernikahan',
          'Sesi Foto Prewedding Outdoor + Cetak Kanvas',
          'Sewa Gaun Pengantin & Rias Makeup Artist',
          'Cetak Album Foto Kolase Magnetic 20 Halaman',
        ];
      case 'building_materials':
        return [
          'Pembelian Semen Tiga Roda 50kg (25 Sak)',
          'Pembelian Pasir Cor 1 Truk Colt Diesel',
          'Pembelian Besi Beton Ulir 10mm SNI (20 Batang)',
          'Cat Tembok Dulux Weathershield 20 Liter',
          'Keramik Lantai Granit 60x60 (10 Dus)',
        ];
      case 'petshop_vet':
        return [
          'Grooming Kucing / Anjing Komplit Kutu & Jamur',
          'Vaksinasi Rabies & Pemeriksaan Dokter Hewan',
          'Pembelian Pakan Kucing Royal Canin 2kg',
          'Biaya Penitipan Hewan (Pet Hotel 3 Hari)',
          'Obat Tetes Kutu & Vitamin Penumbuh Bulu',
        ];
      case 'optical_store':
        return [
          'Frame Kacamata Titanium + Lensa Anti Radiasi',
          'Pemeriksaan Refraksi Tajam Penglihatan Mata',
          'Lensa Photochromic Transition Blue Ray',
          'Softlens Bening Bulanan + Cairan Pembersih',
          'Pembersihan Ultrasonik & Penyetelan Kacamata',
        ];
      case 'tour_travel':
        return [
          'Paket Tour Wisata 3 Hari 2 Malam All-In',
          'Tiket Pesawat Pulang Pergi Maskapai Garuda',
          'Biaya Pengurusan Visa & Asuransi Perjalanan',
          'DP Paket Wisata Domestik / Mancanegara',
          'Sewa Bus Pariwisata 30 Seat + BBM + Driver',
        ];
      case 'notaris_ppat':
        return [
          'Jasa Pembuatan Akta Jual Beli (AJB) Tanah',
          'Legalisasi Dokumen & Perjanjian Notariil',
          'Jasa Pendirian PT / CV Lengkap SK Kemenkumham',
          'Pengecekan Sertifikat Tanah di Kantor BPN',
          'Biaya Pendaftaran Hak Tanggungan Elektronik',
        ];
      case 'wholesale_agent':
        return [
          'Pembelian Grosir Minyak Goreng 2L (10 Karton)',
          'Pelunasan Faktur Penjualan Partai Besar',
          'DP Pengiriman Barang PO Resmi No. 0048',
          'Pembelian Beras Premium 25kg (15 Karung)',
          'Pembelian Gula Pasir Curah (5 Karung 50kg)',
        ];
      case 'architecture_design':
        return [
          'Jasa Desain Arsitektur Rumah Tinggal 2 Lantai',
          'Gambar Kerja Arsitektur, Struktur & MEP Lengkap',
          'Penyusunan Rencana Anggaran Biaya (RAB)',
          '3D Render Visualisasi Eksterior & Interior',
          'Jasa Pengawasan Berkala Lapangan (Supervisi)',
        ];
      case 'hotel_homestay':
        return [
          'Sewa Kamar Deluxe 2 Malam Termasuk Sarapan',
          'Sewa 1 Unit Villa 3 Kamar Tidur Akhir Pekan',
          'Deposit Jaminan Kunci Check-in Hotel',
          'Biaya Tambahan Extra Bed & Late Check-out',
          'Paket Menginap + Sewa Sepeda & Barbeque',
        ];
      case 'event_ticket':
        return [
          'Tiket Masuk Regular Seminar Digital Business',
          'Tiket VIP Front Row Workshop Eksklusif',
          'Registrasi Lomba Musik & Sertifikat Fisik',
          'Tiket Presale Gelombang 1 Konser Musik',
          'Akses Masuk Exhibition Booth & Goodie Bag',
        ];
      case 'minimarket_pos':
        return [
          'Belanja Sembako & Bahan Dapur Bulanan',
          'Pembelian Snack, Ciki, Biskuit & Minuman',
          'Belanja Deterjen, Sabun & Perlengkapan Mandi',
          'Pembelian Peralatan Rumah Tangga & Kebersihan',
          'Belanja Minuman Ringan, Air Mineral & Susu',
        ];
      case 'toko_sembako':
        return [
          'Pembelian Bahan Sembako & Kebutuhan Dapur',
          'Belanja Beras, Minyak Goreng & Gula Pasir',
          'Pembelian Telur, Tepung & Bumbu Masak',
          'Belanja Bahan Pokok Bulanan',
          'Pembelian Santan, Kecap & Saos Tomat',
        ];
      case 'warung_digital':
        return [
          'Pembelian Produk via Toko Online / COD',
          'Belanja Groceries & Produk Konsumsi Harian',
          'Order Produk Makanan & Minuman Sachet',
          'Pembelian Produk Rumah Tangga via WA Order',
          'Belanja Produk Kebutuhan Dapur (Pre-Order)',
        ];
      case 'minimalist_clean':
      case 'standard_formal':
      default:
        return [
          'Pembayaran Invoice Tagihan Jasa Resmi',
          'Pelunasan Kontrak Kerja Tahap 1',
          'Uang Muka (DP) Pekerjaan Pengadaan Barang',
          'Pembayaran Biaya Administrasi & Operasional',
          'Pembayaran Pembelian Barang & Jasa',
        ];
    }
  }
}
