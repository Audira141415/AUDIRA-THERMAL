import 'package:intl/intl.dart';

class Receipt {
  final int? id;
  final String receiptNumber;
  final DateTime date;
  final String receivedFrom;
  final double amount;
  final String amountWords;
  final String description;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt({
    this.id,
    required this.receiptNumber,
    required this.date,
    required this.receivedFrom,
    required this.amount,
    required this.amountWords,
    required this.description,
    required this.paymentMethod,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get dateFormatted {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get dateWithTimeFormatted {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Receipt copyWith({
    int? id,
    String? receiptNumber,
    DateTime? date,
    String? receivedFrom,
    double? amount,
    String? amountWords,
    String? description,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      date: date ?? this.date,
      receivedFrom: receivedFrom ?? this.receivedFrom,
      amount: amount ?? this.amount,
      amountWords: amountWords ?? this.amountWords,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
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
      'amount': amount,
      'amount_words': amountWords,
      'description': description,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as int?,
      receiptNumber: map['receipt_number'] as String,
      date: DateTime.parse(map['date'] as String),
      receivedFrom: map['received_from'] as String,
      amount: (map['amount'] as num).toDouble(),
      amountWords: map['amount_words'] as String,
      description: map['description'] as String,
      paymentMethod: map['payment_method'] as String? ?? 'Tunai (Cash)',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
