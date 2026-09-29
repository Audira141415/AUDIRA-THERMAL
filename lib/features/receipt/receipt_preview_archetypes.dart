import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';
import 'package:audira_receipt/widgets/audira_logo.dart';

enum ReceiptArchetype {
  supermarket,
  restaurant,
  automotive,
  clinic,
  formalLegal,
  donation,
  laundry,
  boxedRetro,
  ticketEvent,
  onlineStore,
  standard,
}

class ReceiptPreviewArchetypes {
  ReceiptPreviewArchetypes._();

  static ReceiptArchetype getArchetype(ReceiptTemplate tpl) {
    final id = tpl.id;
    if (id == 'flagship_supermarket' ||
        id == 'minimarket_pos' ||
        id == 'retail_store' ||
        id == 'toko_sembako' ||
        id == 'utility_ppob') {
      return ReceiptArchetype.supermarket;
    }
    if (id == 'flagship_restaurant' ||
        id == 'resto_cafe' ||
        id == 'hotel_lodging' ||
        id == 'salon_barber') {
      return ReceiptArchetype.restaurant;
    }
    if (id == 'flagship_automotive' ||
        id == 'automotive_workshop' ||
        id == 'gadget_repair' ||
        id == 'vehicle_rental') {
      return ReceiptArchetype.automotive;
    }
    if (id == 'flagship_clinic' || id == 'clinic_medical') {
      return ReceiptArchetype.clinic;
    }
    if (id == 'flagship_corporate' ||
        id == 'standard_formal' ||
        id == 'tax_invoice' ||
        id == 'property_booking' ||
        id == 'school_tuition' ||
        id == 'jewelry_gold' ||
        id == 'classic_luxury') {
      return ReceiptArchetype.formalLegal;
    }
    if (id == 'donation_zakat') {
      return ReceiptArchetype.donation;
    }
    if (id == 'laundry_service') {
      return ReceiptArchetype.laundry;
    }
    if (id == 'boxed_frame') {
      return ReceiptArchetype.boxedRetro;
    }
    if (id == 'event_ticket' || id == 'parking_ticket') {
      return ReceiptArchetype.ticketEvent;
    }
    if (id == 'warung_digital' || id == 'logistics_shipping') {
      return ReceiptArchetype.onlineStore;
    }
    return ReceiptArchetype.standard;
  }

  static Widget buildTicketContent({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required String paperSize,
    String? stampText,
    Color stampColor = AppColors.success,
  }) {
    final is80mm = paperSize == AppConstants.paper80mm;
    final is48mm = paperSize == AppConstants.paper48mm;
    final is58mm = paperSize == AppConstants.paper58mm;
    final archetype = getArchetype(template);

    switch (archetype) {
      case ReceiptArchetype.supermarket:
        return _buildSupermarket(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.restaurant:
        return _buildRestaurant(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.automotive:
        return _buildAutomotive(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.clinic:
        return _buildClinic(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.formalLegal:
        return _buildFormalLegal(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.donation:
        return _buildDonation(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.laundry:
        return _buildLaundry(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.boxedRetro:
        return _buildBoxedRetro(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.ticketEvent:
        return _buildTicketEvent(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.onlineStore:
        return _buildOnlineStore(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
      case ReceiptArchetype.standard:
        return _buildStandard(
          receipt: receipt,
          company: company,
          template: template,
          config: config,
          is48mm: is48mm,
          is58mm: is58mm,
          is80mm: is80mm,
          stampText: stampText,
          stampColor: stampColor,
        );
    }
  }

  // ===========================================================================
  // 1. SUPERMARKET & POS RETAIL ARCHETYPE
  // ===========================================================================
  static Widget _buildSupermarket({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);
    final compAddress = _getStoreAddress(receipt, company);
    final compPhone = _getStorePhone(receipt, company, config);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Solid Inverted Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      compName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: is48mm ? 12 : 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'FAKTUR PENJUALAN RETAIL / KASIR POS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: is48mm ? 7 : 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ),
        if (compAddress.isNotEmpty || compPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          if (compAddress.isNotEmpty)
            Text(
              compAddress,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9, color: AppColors.secondaryText),
            ),
          if (compPhone.isNotEmpty)
            Text(
              compPhone,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9, color: AppColors.secondaryText),
            ),
        ],
        const SizedBox(height: 8),

        // Cashier & Register Ribbon
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REG: ${config.leherField1Value.isNotEmpty ? config.leherField1Value : 'POS-02'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'SHIFT: 1',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KASIR: ${receipt.cashierName != null && receipt.cashierName!.isNotEmpty ? receipt.cashierName : 'Siti N.'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5),
                  ),
                  Text(
                    receipt.dateFormatted,
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STRUK: #${receipt.receiptNumber}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, color: AppColors.secondaryText),
                  ),
                  Text(
                    '[ ${stampText ?? receipt.status} ]',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold, color: stampColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3-Column Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF0F172A), width: 1.5),
              bottom: BorderSide(color: Color(0xFF0F172A), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text('ITEM / PRODUK', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                flex: 3,
                child: Text('QTY x HARGA', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                flex: 3,
                child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Items List or Lump Sum
        if (receipt.items.isNotEmpty) ...[
          for (final item in receipt.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      item.name,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9 : 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}x${CurrencyFormatter.format(item.unitPrice, withSymbol: false)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, color: AppColors.secondaryText),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.format(item.subtotal),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9 : 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          _buildReceiptFieldRow(
            label: 'Total Belanja :',
            value: CurrencyFormatter.format(receipt.amount),
            isBold: true,
            fontSize: is48mm ? 13 : 15,
          ),
        ],

        const SizedBox(height: 6),
        _buildDashedLineText(char: '-'),
        const SizedBox(height: 4),

        // Subtotals, Discount & Tax
        if (receipt.items.isNotEmpty && (receipt.discount > 0 || receipt.tax > 0 || config.serviceChargeAmount > 0)) ...[
          _buildTwoColRow('Subtotal', CurrencyFormatter.format(receipt.itemsSubtotal), is48mm: is48mm),
          if (receipt.discount > 0)
            _buildTwoColRow('Hemat Belanja (Diskon)', '-${CurrencyFormatter.format(receipt.discount)}', is48mm: is48mm, color: Colors.red),
          if (receipt.tax > 0)
            _buildTwoColRow('PPN (11%)', '+${CurrencyFormatter.format(receipt.tax)}', is48mm: is48mm),
          const SizedBox(height: 4),
        ],

        // High-Contrast TOTAL Banner
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 11 : 13, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Text(
                CurrencyFormatter.format(receipt.amount + config.serviceChargeAmount),
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 13 : 16, fontWeight: FontWeight.w900, color: const Color(0xFF38BDF8)),
              ),
            ],
          ),
        ),

        // Tunai & Kembalian
        if (receipt.cashReceived > 0) ...[
          _buildTwoColRow('TUNAI', CurrencyFormatter.format(receipt.cashReceived), is48mm: is48mm),
          _buildTwoColRow('KEMBALIAN', CurrencyFormatter.format(receipt.changeAmount), is48mm: is48mm, color: Colors.green[800], isBold: true),
        ],

        // Member Reward Points Card
        if (config.memberReward.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFB45309)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    config.memberReward,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 9, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Barcode with Code128
        const SizedBox(height: 10),
        _buildBarcodeWidget(receipt, is48mm),

        // Return Policy Callout
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            config.termsText.isNotEmpty ? config.termsText : 'Barang retur maks 1x24 jam wajib dengan struk fisik asli.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 8.5, color: const Color(0xFF475569)),
          ),
        ),

        // Footer
        if (config.showFooter) ...[
          const SizedBox(height: 8),
          Text(
            config.customFooter.isNotEmpty ? config.customFooter : 'Terima Kasih Atas Kunjungan Anda!\nSelamat Datang Kembali',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 2. RESTO & CAFE FINE DINING ARCHETYPE
  // ===========================================================================
  static Widget _buildRestaurant({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);
    final compTagline = _getStoreTagline(receipt, company, config);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ornate Dining Header
        Text(
          '✦ ✦ ✦ BILL RESTORAN & CAFE ✦ ✦ ✦',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: is48mm ? 8 : 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: const Color(0xFFB45309),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: is48mm ? 13 : 16,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        if (compTagline.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            compTagline,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9, fontStyle: FontStyle.italic, color: AppColors.secondaryText),
          ),
        ],
        const SizedBox(height: 8),
        _buildDashedLineText(char: '='),
        const SizedBox(height: 6),

        // Table & Waiter Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant_rounded, size: 13, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Text(
                        config.leherField1Value.isNotEmpty ? config.leherField1Value : 'TABLE 08 (VIP Lounge)',
                        style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SERVER: ${receipt.cashierName ?? 'Bayu P. (Host)'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, color: const Color(0xFFB45309)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DINE IN',
                  style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Menu Items
        if (receipt.items.isNotEmpty) ...[
          for (final item in receipt.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9.5 : 11.5, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '  ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${CurrencyFormatter.format(item.unitPrice, withSymbol: false)}',
                        style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, color: AppColors.secondaryText),
                      ),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9.5 : 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          _buildReceiptFieldRow(
            label: 'Total Bill :',
            value: CurrencyFormatter.format(receipt.amount),
            isBold: true,
            fontSize: is48mm ? 13 : 15,
          ),
        ],

        const SizedBox(height: 6),
        _buildDashedLineText(char: '-'),
        const SizedBox(height: 4),

        // Charges Breakdown
        _buildTwoColRow('Subtotal Hidangan', CurrencyFormatter.format(receipt.itemsSubtotal > 0 ? receipt.itemsSubtotal : receipt.amount), is48mm: is48mm),
        if (config.serviceChargeAmount > 0)
          _buildTwoColRow(config.serviceChargeLabel.isNotEmpty ? config.serviceChargeLabel : 'Service Charge (5%)', '+${CurrencyFormatter.format(config.serviceChargeAmount)}', is48mm: is48mm),
        if (receipt.tax > 0)
          _buildTwoColRow('Resto Tax (PB1 10%)', '+${CurrencyFormatter.format(receipt.tax)}', is48mm: is48mm),
        if (receipt.discount > 0)
          _buildTwoColRow('Diskon Promosi', '-${CurrencyFormatter.format(receipt.discount)}', is48mm: is48mm, color: Colors.red),

        const SizedBox(height: 6),
        _buildDashedLineText(char: '='),
        const SizedBox(height: 6),

        _buildTwoColRow('TOTAL BILL', CurrencyFormatter.format(receipt.amount + config.serviceChargeAmount), is48mm: is48mm, isBold: true, fontSize: is48mm ? 13 : 15, color: const Color(0xFFB45309)),
        if (receipt.cashReceived > 0) ...[
          const SizedBox(height: 4),
          _buildTwoColRow('TUNAI', CurrencyFormatter.format(receipt.cashReceived), is48mm: is48mm),
          _buildTwoColRow('KEMBALIAN', CurrencyFormatter.format(receipt.changeAmount), is48mm: is48mm, color: Colors.green[800], isBold: true),
        ],

        // Free WiFi Credentials
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.wifiInfo.isNotEmpty ? config.wifiInfo : 'Free WiFi SSID: AUD-RESTO | Pass: kuliner123',
                  style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),

        // Google Review Badge with QR
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Scan QR untuk Review Bintang 5 & Dapatkan Free Dessert!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 8.5, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        _buildQrCodeWidget(is48mm),

        // Footer
        if (config.showFooter) ...[
          const SizedBox(height: 6),
          Text(
            config.customFooter.isNotEmpty ? config.customFooter : 'Terima Kasih Atas Kunjungan Anda\nSelamat Menikmati Hidangan & Sampai Jumpa!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 3. BENGKEL RESMI & OTOMOTIF ARCHETYPE
  // ===========================================================================
  static Widget _buildAutomotive({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Technical Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.car_repair_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                'NOTA SERVIS & SURAT JALAN',
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9 : 11, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),

        // Vehicle Plate & Odometer Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        config.leherField1Value.isNotEmpty ? config.leherField1Value : 'PLAT: D 1452 AUD',
                        style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  Text(
                    config.leherField2Value.isNotEmpty ? config.leherField2Value : 'ODO: 62.450 KM',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SA: ${receipt.cashierName ?? 'Budi Hartono'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, color: Colors.white70),
                  ),
                  Text(
                    receipt.dateFormatted,
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Parts & Services
        if (receipt.items.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            color: const Color(0xFFE2E8F0),
            child: Text(
              'RINCIAN PENGERJAAN & SUKU CADANG',
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 9, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          for (final item in receipt.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.name,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}x',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, color: AppColors.secondaryText),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.format(item.subtotal),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          _buildReceiptFieldRow(
            label: 'Total Biaya Servis :',
            value: CurrencyFormatter.format(receipt.amount),
            isBold: true,
            fontSize: is48mm ? 13 : 15,
          ),
        ],

        const SizedBox(height: 6),
        _buildDashedLineText(char: '='),
        const SizedBox(height: 4),

        _buildTwoColRow('TOTAL BIAYA', CurrencyFormatter.format(receipt.amount), is48mm: is48mm, isBold: true, fontSize: is48mm ? 12 : 14),

        // Warranty Badge
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.guaranteePolicy.isNotEmpty ? config.guaranteePolicy : 'GARANSI RESMI: 14 Hari / 1.000 KM (Klaim wajib nota fisik & segel mekanik utuh).',
                  style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                ),
              ),
            ],
          ),
        ),

        // Signatures
        const SizedBox(height: 12),
        _buildDualSignatures(
          leftTitle: 'Pelanggan,',
          rightTitle: 'Kepala Bengkel,',
          signerName: company.signerName.isNotEmpty ? company.signerName : 'Kepala Mekanik',
          is48mm: is48mm,
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. KLINIK MEDIS, APOTEK & LAB ARCHETYPE
  // ===========================================================================
  static Widget _buildClinic({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Medical Caduceus Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital_rounded, color: Color(0xFF059669), size: 16),
            const SizedBox(width: 6),
            Text(
              'BUKTI PELAYANAN MEDIS & RESEP',
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9 : 11, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),

        // Patient & Doctor Information Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NO RM  : ${config.leherField1Value.isNotEmpty ? config.leherField1Value : 'RM-092-881'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                  ),
                  Text(
                    receipt.dateFormatted,
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, color: const Color(0xFF166534)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PASIEN : ${receipt.receivedFrom.isNotEmpty ? receipt.receivedFrom : 'Pasien Umum'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'DOKTER: ${config.leherField2Value.isNotEmpty ? config.leherField2Value : 'dr. Spesialis'}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Rx Medical Items
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          color: const Color(0xFFE2E8F0),
          child: Text(
            '℞ RESEP OBAT & TINDAKAN MEDIS',
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 4),
        if (receipt.items.isNotEmpty) ...[
          for (final item in receipt.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.name,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}x',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, color: AppColors.secondaryText),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.format(item.subtotal),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          _buildReceiptFieldRow(
            label: 'Total Biaya :',
            value: CurrencyFormatter.format(receipt.amount),
            isBold: true,
            fontSize: is48mm ? 13 : 15,
          ),
        ],

        const SizedBox(height: 6),
        _buildDashedLineText(char: '-'),
        const SizedBox(height: 4),

        _buildTwoColRow('TOTAL PEMBAYARAN', CurrencyFormatter.format(receipt.amount), is48mm: is48mm, isBold: true, fontSize: is48mm ? 12 : 14),

        // Medication Notice Callout
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medication_rounded, color: Color(0xFFDC2626), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aturan Pakai: Habiskan antibiotik sesuai resep dokter. Simpan obat di tempat sejuk & kering terlindung sinar matahari langsung.',
                  style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 8.5, color: const Color(0xFF991B1B)),
                ),
              ),
            ],
          ),
        ),

        // Doctor / Pharmacist Sign
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Apoteker / Kasir Medis,', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10)),
              SizedBox(height: is48mm ? 24 : 32),
              Text(
                '(${company.signerName.isNotEmpty ? company.signerName : 'apt. Rina O., S.Farm'})',
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. KWITANSI FORMAL, KORPORAT, PAJAK & HUKUM ARCHETYPE
  // ===========================================================================
  static Widget _buildFormalLegal({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);
    final compAddress = _getStoreAddress(receipt, company);
    final compLegalId = _getStoreLegalId(receipt, config);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Legal Double Border Top
        _buildDashedLineText(char: '='),
        const SizedBox(height: 4),

        // Company Name & Legal NPWP
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 13 : 15, fontWeight: FontWeight.w900),
        ),
        if (compLegalId.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            compLegalId,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, fontWeight: FontWeight.bold),
          ),
        ],
        if (compAddress.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            compAddress,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 8.5, color: AppColors.secondaryText),
          ),
        ],
        const SizedBox(height: 4),
        _buildDashedLineText(char: '='),
        const SizedBox(height: 6),

        // Official Title
        Text(
          config.customTitle.isNotEmpty ? config.customTitle : template.titleHeading,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),

        // Meta No & Tanggal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('No Bukti: ${receipt.receiptNumber}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10, fontWeight: FontWeight.bold)),
            Text('Tanggal: ${receipt.dateFormatted}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10)),
          ],
        ),
        const SizedBox(height: 6),
        _buildDashedLineText(char: '-'),
        const SizedBox(height: 8),

        // Diterima Dari
        _buildReceiptFieldRow(
          label: 'Telah Diterima Dari :',
          value: receipt.receivedFrom.isNotEmpty ? receipt.receivedFrom.toUpperCase() : 'PELANGGAN UMUM',
          isBold: true,
          fontSize: is48mm ? 11 : 13,
        ),
        const SizedBox(height: 8),

        // Thick Double-Border Nominal Box
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF0F172A), width: 1.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('JUMLAH UANG :', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.bold)),
              Text(
                CurrencyFormatter.format(receipt.amount),
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 13 : 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Terbilang
        _buildReceiptFieldRow(
          label: 'Terbilang :',
          value: '## ${receipt.amountWords} ##',
          isItalic: true,
          fontSize: is48mm ? 9 : 11,
        ),
        const SizedBox(height: 8),

        // Untuk Keperluan
        _buildReceiptFieldRow(
          label: 'Untuk Pembayaran :',
          value: receipt.description,
          isBold: true,
          fontSize: is48mm ? 9.5 : 11.5,
        ),
        const SizedBox(height: 6),
        _buildReceiptFieldRow(
          label: 'Metode Pembayaran :',
          value: receipt.paymentMethod,
          fontSize: is48mm ? 8.5 : 10,
        ),
        const SizedBox(height: 10),
        _buildDashedLineText(char: '-'),
        const SizedBox(height: 10),

        // Materai & Dual Signatures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text('Penyetor,', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10)),
                SizedBox(height: is48mm ? 26 : 34),
                Text('(______________)', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'MATERAI\nRp 10.000',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 6 : 7.5, color: Colors.grey.shade600),
              ),
            ),
            Column(
              children: [
                Text('${config.signerTitle.isNotEmpty ? config.signerTitle : 'Penerima'},', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10)),
                SizedBox(height: is48mm ? 26 : 34),
                Text(
                  '(${company.signerName.isNotEmpty ? company.signerName : 'Penerima Sah'})',
                  style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),
        _buildDashedLineText(char: '='),
      ],
    );
  }

  // ===========================================================================
  // 6. DONASI, ZAKAT & INFAQ ARCHETYPE
  // ===========================================================================
  static Widget _buildDonation({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bismillah Calligraphy
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: is48mm ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF065F46),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '۞ ۞ ۞ TANDA TERIMA ZAKAT & INFAQ ۞ ۞ ۞',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 9, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
        ),
        const SizedBox(height: 4),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 11 : 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        _buildDashedLineText(char: '.'),
        const SizedBox(height: 8),

        // Muzakki Details
        _buildReceiptFieldRow(
          label: 'Muzakki / Donatur :',
          value: receipt.receivedFrom.isNotEmpty ? receipt.receivedFrom.toUpperCase() : 'HAMBA ALLAH',
          isBold: true,
          fontSize: is48mm ? 10.5 : 12.5,
        ),
        const SizedBox(height: 6),
        _buildReceiptFieldRow(
          label: 'Uang Sejumlah :',
          value: CurrencyFormatter.format(receipt.amount),
          isBold: true,
          fontSize: is48mm ? 13 : 15,
        ),
        const SizedBox(height: 4),
        _buildReceiptFieldRow(
          label: 'Terbilang :',
          value: '(${receipt.amountWords})',
          isItalic: true,
          fontSize: is48mm ? 8.5 : 10,
        ),
        const SizedBox(height: 6),
        _buildReceiptFieldRow(
          label: 'Peruntukan Donasi :',
          value: receipt.description,
          fontSize: is48mm ? 9 : 11,
        ),
        const SizedBox(height: 8),

        // Doa Berkah Callout
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Text(
            '"Semoga Allah memberikan pahala atas apa yang Anda infaqkan, memberkahi harta yang tersisa, dan menjadikannya pembersih jiwa & rezeki."',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 9, fontStyle: FontStyle.italic, color: const Color(0xFF065F46)),
          ),
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Amil / Petugas Yayasan,', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10)),
              SizedBox(height: is48mm ? 24 : 32),
              Text(
                '(${company.signerName.isNotEmpty ? company.signerName : 'Petugas Amil'})',
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. LAUNDRY & DRY CLEAN ARCHETYPE
  // ===========================================================================
  static Widget _buildLaundry({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF2563EB), size: 16),
            const SizedBox(width: 6),
            Text(
              'NOTA CUCIAN LAUNDRY & DRY CLEAN',
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),

        // Washing Schedule Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TGL MASUK: ${receipt.dateFormatted}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold)),
                  Text('BERAT: 4.5 KG', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ESTIMASI : 2 Hari Kerja', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, color: const Color(0xFF1D4ED8))),
                  Text('PAKET: CUCI WANGI', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        _buildReceiptFieldRow(label: 'Nama Pelanggan :', value: receipt.receivedFrom, isBold: true),
        const SizedBox(height: 6),
        _buildReceiptFieldRow(label: 'Total Biaya Cucian :', value: CurrencyFormatter.format(receipt.amount), isBold: true, fontSize: is48mm ? 13 : 15),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Nota ini wajib dibawa saat pengambilan cucian. Komplain pakaian maksimal 1x24 jam setelah serah terima.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 8.5, color: AppColors.secondaryText),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 8. BOXED RETRO ARCHETYPE
  // ===========================================================================
  static Widget _buildBoxedRetro({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '+-----------------------------------+',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 9),
          ),
          Text(
            compName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900),
          ),
          Text(
            'KWITANSI KOTAK RETRO',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 10, letterSpacing: 1.0),
          ),
          Text(
            '+-----------------------------------+',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 9),
          ),
          const SizedBox(height: 6),
          _buildReceiptFieldRow(label: 'Diterima Dari :', value: receipt.receivedFrom, isBold: true),
          const SizedBox(height: 6),
          _buildReceiptFieldRow(label: 'Jumlah Uang   :', value: CurrencyFormatter.format(receipt.amount), isBold: true, fontSize: is48mm ? 13 : 15),
          const SizedBox(height: 4),
          _buildReceiptFieldRow(label: 'Terbilang     :', value: receipt.amountWords, isItalic: true),
          const SizedBox(height: 6),
          _buildReceiptFieldRow(label: 'Untuk         :', value: receipt.description),
          const SizedBox(height: 8),
          Text(
            '+-----------------------------------+',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 9),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. TIKET EVENT & WORKSHOP ARCHETYPE
  // ===========================================================================
  static Widget _buildTicketEvent({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_rounded, color: Color(0xFF7C3AED), size: 16),
            const SizedBox(width: 6),
            Text(
              'TIKET MASUK & REGISTRASI EVENT',
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF7C3AED)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),

        // Perforated Scissors Cut Line
        Text(
          '✂ - - - - - - - - - - - - - - - - - - - ✂',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7.5 : 9, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),

        // Access Pass Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PASS : VIP PASS', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF6D28D9))),
                  Text('GATE: PINTU 01', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF6D28D9))),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'PEMEGANG: ${receipt.receivedFrom.isNotEmpty ? receipt.receivedFrom : 'Peserta'}',
                style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        _buildQrCodeWidget(is48mm),
        const SizedBox(height: 6),
        Text(
          'Tunjukkan QR Code ini pada petugas gerbang saat registrasi ulang.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 7 : 8.5, color: AppColors.secondaryText),
        ),
      ],
    );
  }

  // ===========================================================================
  // 10. TOKO ONLINE & RESI ARCHETYPE
  // ===========================================================================
  static Widget _buildOnlineStore({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_rounded, color: Color(0xFF0284C7), size: 16),
            const SizedBox(width: 6),
            Text(
              'RESI PENGIRIMAN & PESANAN',
              style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF0284C7)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          compName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 12 : 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),

        // Resi & Courier Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KURIR: JNE REGULER', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1))),
                  Text('#${receipt.receiptNumber}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PENERIMA: ${receipt.receivedFrom}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5)),
                  Text(receipt.dateFormatted, style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildBarcodeWidget(receipt, is48mm),
        const SizedBox(height: 8),

        _buildReceiptFieldRow(label: 'Total Tagihan :', value: CurrencyFormatter.format(receipt.amount), isBold: true, fontSize: is48mm ? 13 : 15),
      ],
    );
  }

  // ===========================================================================
  // 11. STANDARD / DEFAULT FALLBACK ARCHETYPE
  // ===========================================================================
  static Widget _buildStandard({
    required Receipt receipt,
    required Company company,
    required ReceiptTemplate template,
    required TemplateConfig config,
    required bool is48mm,
    required bool is58mm,
    required bool is80mm,
    String? stampText,
    required Color stampColor,
  }) {
    final compName = _getStoreName(receipt, company);
    final compTagline = _getStoreTagline(receipt, company, config);
    final compAddress = _getStoreAddress(receipt, company);
    final compPhone = _getStorePhone(receipt, company, config);

    return Column(
      children: [
        if (config.invertHeader && compName.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  compName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: is48mm ? 13 : 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                if (compTagline.isNotEmpty)
                  Text(
                    compTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: is48mm ? 8 : 9,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          )
        else ...[
          if (receipt.showLogo ?? config.showLogo) ...[
            Builder(
              builder: (context) {
                final customLogo = receipt.logoPath ?? company.logo;
                if (customLogo != null && customLogo.isNotEmpty) {
                  final file = File(customLogo);
                  if (file.existsSync()) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Image.file(
                        file,
                        height: is48mm ? 36 : 48,
                        fit: BoxFit.contain,
                      ),
                    );
                  }
                }
                return AudiraLogoWidget(size: is48mm ? 32 : 40);
              },
            ),
            const SizedBox(height: 4),
          ],
          if (compName.isNotEmpty)
            Text(
              compName.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: is48mm ? 13 : 15,
                fontWeight: config.boldCompanyName ? FontWeight.w900 : FontWeight.w600,
                color: AppColors.thermalInk,
              ),
            ),
          if (compTagline.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              compTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: is48mm ? 8 : 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.thermalInk,
              ),
            ),
          ],
        ],
        if (compAddress.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            compAddress,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: is48mm ? 9 : 10,
              color: AppColors.thermalInk,
            ),
          ),
        ],
        if (compPhone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            compPhone,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: is48mm ? 9 : 10,
              color: AppColors.thermalInk,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildDashedLineText(char: config.separatorChar == '-' ? '=' : config.separatorChar),
        const SizedBox(height: 8),

        // Title
        Text(
          config.customTitle.isNotEmpty ? config.customTitle : template.titleHeading,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: is48mm ? 12 : (config.titleFontSize == 'extra_large' ? 18 : (config.titleFontSize == 'large' ? 15 : 13)),
            fontWeight: config.boldTitle ? FontWeight.w900 : FontWeight.w600,
            color: AppColors.thermalInk,
            letterSpacing: is48mm ? 0.8 : 1.2,
          ),
        ),
        if (config.stampType != 'none') ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: stampColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: stampColor.withOpacity(0.4)),
            ),
            child: Text(
              stampText ?? receipt.status.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: is48mm ? 9 : 10,
                fontWeight: FontWeight.w900,
                color: stampColor,
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),

        // Meta Leher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('No     : ${receipt.receiptNumber}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 10 : 11)),
            Text('Tanggal: ${receipt.dateFormatted}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 10 : 11)),
          ],
        ),
        if (receipt.cashierName != null && receipt.cashierName!.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Kasir  : ${receipt.cashierName}', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 10 : 11)),
          ),

        const SizedBox(height: 8),
        _buildDashedLineText(char: config.separatorChar),
        const SizedBox(height: 8),

        // Content
        if (receipt.receivedFrom.isNotEmpty) ...[
          _buildReceiptFieldRow(
            label: '${config.labelReceivedFrom.isNotEmpty ? config.labelReceivedFrom : 'Telah diterima dari'} :',
            value: receipt.receivedFrom.toUpperCase(),
            isBold: receipt.isBoldAmount,
            fontSize: is48mm ? 11 : 13,
          ),
          const SizedBox(height: 8),
        ],

        // Items or Single Amount
        if (receipt.items.isNotEmpty) ...[
          for (final item in receipt.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 10 : 12, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '  ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${CurrencyFormatter.format(item.unitPrice, withSymbol: false)}',
                        style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 9 : 11, color: AppColors.secondaryText),
                      ),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 10 : 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          _buildDashedLineText(char: '-'),
          const SizedBox(height: 4),
          _buildTwoColRow('TOTAL', CurrencyFormatter.format(receipt.amount), is48mm: is48mm, isBold: true, fontSize: is48mm ? 12 : 14),
        ] else ...[
          _buildReceiptFieldRow(
            label: '${config.labelAmount.isNotEmpty ? config.labelAmount : 'Uang sejumlah'} :',
            value: CurrencyFormatter.format(receipt.amount),
            isBold: true,
            fontSize: is48mm ? 14 : 18,
          ),
        ],

        if (config.showAmountWords) ...[
          const SizedBox(height: 8),
          _buildReceiptFieldRow(
            label: 'Terbilang :',
            value: receipt.amountWords,
            isItalic: true,
            fontSize: is48mm ? 9 : 11,
          ),
        ],

        if (config.showDescription) ...[
          const SizedBox(height: 8),
          _buildReceiptFieldRow(
            label: 'Untuk pembayaran :',
            value: receipt.description,
            fontSize: is48mm ? 10 : 12,
          ),
        ],

        const SizedBox(height: 12),
        _buildDashedLineText(char: config.separatorChar),
        const SizedBox(height: 10),

        // Dual or Single Signatures
        if (config.showSignatures && config.signatureType != 'none') ...[
          _buildDualSignatures(
            leftTitle: 'Penyetor,',
            rightTitle: '${config.signerTitle},',
            signerName: company.signerName.isNotEmpty ? company.signerName : config.signerTitle,
            is48mm: is48mm,
          ),
        ],

        if (config.showFooter) ...[
          const SizedBox(height: 10),
          Text(
            config.customFooter.isNotEmpty ? config.customFooter : 'Terima Kasih atas kepercayaan Anda',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SHARED UTILITY METHODS & WIDGET BUILDERS
  // ===========================================================================
  static String _getStoreName(Receipt receipt, Company company) {
    return (receipt.storeName != null && receipt.storeName!.trim().isNotEmpty)
        ? receipt.storeName!.trim()
        : company.name.trim();
  }

  static String _getStoreTagline(Receipt receipt, Company company, TemplateConfig config) {
    return (receipt.storeTagline != null)
        ? receipt.storeTagline!.trim()
        : (config.headerSubtitle.isNotEmpty ? config.headerSubtitle : (config.showTagline ? company.tagline.trim() : ''));
  }

  static String _getStoreLegalId(Receipt receipt, TemplateConfig config) {
    return (receipt.storeLegalId != null)
        ? receipt.storeLegalId!.trim()
        : config.businessLegalId.trim();
  }

  static String _getStoreAddress(Receipt receipt, Company company) {
    return (receipt.storeAddress != null)
        ? receipt.storeAddress!.trim()
        : company.address.trim();
  }

  static String _getStorePhone(Receipt receipt, Company company, TemplateConfig config) {
    final raw = (receipt.storePhone != null)
        ? receipt.storePhone!.trim()
        : (config.contactInfo.isNotEmpty ? config.contactInfo : company.phone.trim());
    if (raw.isEmpty) return '';
    return raw.startsWith('Telp') || raw.startsWith('CS') ? raw : 'Telp. $raw';
  }

  static Widget _buildDashedLineText({String char = '-', Color color = const Color(0xFF94A3B8)}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 6.0).floor();
        final unit = char == '=' ? '=' : (char == '*' ? '*' : (char == '.' ? '. ' : '$char '));
        return Text(
          unit * (count > 0 ? count : 20),
          style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: color),
          maxLines: 1,
          overflow: TextOverflow.clip,
        );
      },
    );
  }

  static Widget _buildTwoColRow(
    String label,
    String value, {
    required bool is48mm,
    bool isBold = false,
    double? fontSize,
    Color? color,
  }) {
    final size = fontSize ?? (is48mm ? 9 : 11);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'monospace', fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: 'monospace', fontSize: size, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _buildReceiptFieldRow({
    required String label,
    required String value,
    bool isBold = false,
    bool isItalic = false,
    double fontSize = 11,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: AppColors.thermalInk,
          ),
        ),
      ],
    );
  }

  static Widget _buildBarcodeWidget(Receipt receipt, bool is48mm) {
    final code = (receipt.barcodeData != null && receipt.barcodeData!.trim().isNotEmpty)
        ? receipt.barcodeData!.trim()
        : receipt.receiptNumber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              is48mm ? 22 : 30,
              (i) => Container(
                width: (i % 4 == 0) ? 2.5 : ((i % 2 == 0) ? 1.5 : 1.0),
                height: is48mm ? 22 : 28,
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            code,
            style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8 : 9.5, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _buildQrCodeWidget(bool is48mm) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.qr_code_2_rounded, size: is48mm ? 42 : 50, color: Colors.black),
      ),
    );
  }

  static Widget _buildDualSignatures({
    required String leftTitle,
    required String rightTitle,
    required String signerName,
    required bool is48mm,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(leftTitle, style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10)),
            SizedBox(height: is48mm ? 22 : 28),
            Text('(______________)', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(rightTitle, style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10)),
            SizedBox(height: is48mm ? 22 : 28),
            Text('($signerName)', style: TextStyle(fontFamily: 'monospace', fontSize: is48mm ? 8.5 : 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
