import 'dart:convert';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';

class ReceiptItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;

  const ReceiptItem({
    required this.id,
    required this.name,
    this.quantity = 1.0,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  ReceiptItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Receipt {
  final int? id;
  final String receiptNumber;
  final DateTime date;
  final String receivedFrom;
  final String? customerPhone;
  final String? cashierName;
  final double amount;
  final String amountWords;
  final String description;
  final String paymentMethod;
  final String status;
  final String? notes;
  final String templateId;
  final double discount;
  final double tax;
  final double cashReceived;
  final double changeAmount;
  final DateTime? dueDate;
  final List<ReceiptItem> items;

  // Multi-Company / Store Identity
  final String? storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? storeTagline;
  final String? storeLegalId;

  // Custom Logo & Barcode
  final String? logoPath;
  final bool? showLogo;
  final bool? showBarcode;
  final String? barcodeData;

  // Direct formatting controls
  final String headerAlign;
  final String titleAlign;
  final String contentAlign;
  final String amountAlign;
  final String stampAlign;
  final String titleFontSize;
  final String amountFontSize;
  final bool isBoldTitle;
  final bool isBoldAmount;
  final bool isCondensed;
  final String stampType;

  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt({
    this.id,
    required this.receiptNumber,
    required this.date,
    required this.receivedFrom,
    this.customerPhone,
    this.cashierName,
    required this.amount,
    required this.amountWords,
    required this.description,
    required this.paymentMethod,
    this.status = 'LUNAS',
    this.notes,
    this.templateId = 'standard_formal',
    this.discount = 0.0,
    this.tax = 0.0,
    this.cashReceived = 0.0,
    this.changeAmount = 0.0,
    this.dueDate,
    this.items = const [],
    this.storeName,
    this.storeAddress,
    this.storePhone,
    this.storeTagline,
    this.storeLegalId,
    this.logoPath,
    this.showLogo = true,
    this.showBarcode,
    this.barcodeData,
    this.headerAlign = 'center',
    this.titleAlign = 'center',
    this.contentAlign = 'left',
    this.amountAlign = 'left',
    this.stampAlign = 'right',
    this.titleFontSize = 'large',
    this.amountFontSize = 'large',
    this.isBoldTitle = true,
    this.isBoldAmount = true,
    this.isCondensed = false,
    this.stampType = 'LUNAS',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get itemsSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  String get dateFormatted {
    return AppDateFormatter.formatShort(date);
  }

  String get dateWithTimeFormatted {
    return AppDateFormatter.formatShortWithTime(date);
  }

  Receipt copyWith({
    int? id,
    String? receiptNumber,
    DateTime? date,
    String? receivedFrom,
    String? customerPhone,
    String? cashierName,
    double? amount,
    String? amountWords,
    String? description,
    String? paymentMethod,
    String? status,
    String? notes,
    String? templateId,
    double? discount,
    double? tax,
    double? cashReceived,
    double? changeAmount,
    DateTime? dueDate,
    List<ReceiptItem>? items,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? storeTagline,
    String? storeLegalId,
    String? logoPath,
    bool? showLogo,
    bool? showBarcode,
    String? barcodeData,
    String? headerAlign,
    String? titleAlign,
    String? contentAlign,
    String? amountAlign,
    String? stampAlign,
    String? titleFontSize,
    String? amountFontSize,
    bool? isBoldTitle,
    bool? isBoldAmount,
    bool? isCondensed,
    String? stampType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      date: date ?? this.date,
      receivedFrom: receivedFrom ?? this.receivedFrom,
      customerPhone: customerPhone ?? this.customerPhone,
      cashierName: cashierName ?? this.cashierName,
      amount: amount ?? this.amount,
      amountWords: amountWords ?? this.amountWords,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      templateId: templateId ?? this.templateId,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      cashReceived: cashReceived ?? this.cashReceived,
      changeAmount: changeAmount ?? this.changeAmount,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      storeTagline: storeTagline ?? this.storeTagline,
      storeLegalId: storeLegalId ?? this.storeLegalId,
      logoPath: logoPath ?? this.logoPath,
      showLogo: showLogo ?? this.showLogo,
      showBarcode: showBarcode ?? this.showBarcode,
      barcodeData: barcodeData ?? this.barcodeData,
      headerAlign: headerAlign ?? this.headerAlign,
      titleAlign: titleAlign ?? this.titleAlign,
      contentAlign: contentAlign ?? this.contentAlign,
      amountAlign: amountAlign ?? this.amountAlign,
      stampAlign: stampAlign ?? this.stampAlign,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      amountFontSize: amountFontSize ?? this.amountFontSize,
      isBoldTitle: isBoldTitle ?? this.isBoldTitle,
      isBoldAmount: isBoldAmount ?? this.isBoldAmount,
      isCondensed: isCondensed ?? this.isCondensed,
      stampType: stampType ?? this.stampType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'date': date.toIso8601String(),
      'received_from': receivedFrom,
      'customer_phone': customerPhone,
      'cashier_name': cashierName,
      'amount': amount,
      'amount_words': amountWords,
      'description': description,
      'payment_method': paymentMethod,
      'status': status,
      'notes': notes,
      'template_id': templateId,
      'discount': discount,
      'tax': tax,
      'cash_received': cashReceived,
      'change_amount': changeAmount,
      'due_date': dueDate?.toIso8601String(),
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'store_tagline': storeTagline,
      'store_legal_id': storeLegalId,
      'logo_path': logoPath,
      'show_logo': (showLogo ?? true) ? 1 : 0,
      'show_barcode': (showBarcode == null) ? null : (showBarcode! ? 1 : 0),
      'barcode_data': barcodeData,
      'header_align': headerAlign,
      'title_align': titleAlign,
      'content_align': contentAlign,
      'amount_align': amountAlign,
      'stamp_align': stampAlign,
      'title_font_size': titleFontSize,
      'amount_font_size': amountFontSize,
      'is_bold_title': isBoldTitle ? 1 : 0,
      'is_bold_amount': isBoldAmount ? 1 : 0,
      'is_condensed': isCondensed ? 1 : 0,
      'stamp_type': stampType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    List<ReceiptItem> parsedItems = [];
    if (map['items_json'] != null && (map['items_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['items_json'] as String);
        if (decoded is List) {
          parsedItems = decoded.map((e) => ReceiptItem.fromMap(Map<String, dynamic>.from(e))).toList();
        }
      } catch (_) {}
    }

    return Receipt(
      id: map['id'] as int?,
      receiptNumber: map['receipt_number'] as String,
      date: DateTime.parse(map['date'] as String),
      receivedFrom: map['received_from'] as String,
      customerPhone: map['customer_phone'] as String?,
      cashierName: map['cashier_name'] as String?,
      amount: (map['amount'] as num).toDouble(),
      amountWords: map['amount_words'] as String,
      description: map['description'] as String,
      paymentMethod: map['payment_method'] as String? ?? 'Tunai (Cash)',
      status: map['status'] as String? ?? 'LUNAS',
      notes: map['notes'] as String?,
      templateId: map['template_id'] as String? ?? 'standard_formal',
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      cashReceived: (map['cash_received'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['due_date'] != null && (map['due_date'] as String).isNotEmpty
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      items: parsedItems,
      storeName: map['store_name'] as String?,
      storeAddress: map['store_address'] as String?,
      storePhone: map['store_phone'] as String?,
      storeTagline: map['store_tagline'] as String?,
      storeLegalId: map['store_legal_id'] as String?,
      logoPath: map['logo_path'] as String?,
      showLogo: map['show_logo'] != null ? (map['show_logo'] as int) == 1 : true,
      showBarcode: map['show_barcode'] != null ? (map['show_barcode'] as int) == 1 : null,
      barcodeData: map['barcode_data'] as String?,
      headerAlign: map['header_align'] as String? ?? 'center',
      titleAlign: map['title_align'] as String? ?? 'center',
      contentAlign: map['content_align'] as String? ?? 'left',
      amountAlign: map['amount_align'] as String? ?? 'left',
      stampAlign: map['stamp_align'] as String? ?? 'right',
      titleFontSize: map['title_font_size'] as String? ?? 'large',
      amountFontSize: map['amount_font_size'] as String? ?? 'large',
      isBoldTitle: (map['is_bold_title'] as int?) != 0,
      isBoldAmount: (map['is_bold_amount'] as int?) != 0,
      isCondensed: (map['is_condensed'] as int?) == 1,
      stampType: map['stamp_type'] as String? ?? 'LUNAS',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
