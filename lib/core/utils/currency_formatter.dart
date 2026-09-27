import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterWithoutSymbol = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  /// Format double to Indonesian Rupiah e.g. "Rp 1.500.000"
  static String format(double amount, {bool withSymbol = true}) {
    if (withSymbol) {
      return _formatter.format(amount).trim();
    }
    return _formatterWithoutSymbol.format(amount).trim();
  }

  /// Parse string like "Rp 1.500.000" or "1.500.000" or "1500000" to double
  static double parse(String value) {
    if (value.trim().isEmpty) return 0.0;
    // Strip everything except digits
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

/// TextInputFormatter that formats digits as Indonesian Rupiah while typing
class IndonesianCurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.tryParse(digitsOnly) ?? 0;
    final formatted = _formatter.format(number).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
