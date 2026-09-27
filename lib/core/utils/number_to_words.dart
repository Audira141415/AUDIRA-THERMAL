class NumberToWords {
  NumberToWords._();

  static const List<String> _units = [
    '',
    'Satu',
    'Dua',
    'Tiga',
    'Empat',
    'Lima',
    'Enam',
    'Tujuh',
    'Delapan',
    'Sembilan',
    'Sepuluh',
    'Sebelas',
  ];

  /// Convert numeric amount (e.g., 1500000) to Indonesian words:
  /// e.g. "Satu Juta Lima Ratus Ribu Rupiah"
  static String convert(num number, {bool appendRupiah = true}) {
    final intValue = number.toInt();

    if (intValue == 0) {
      return appendRupiah ? 'Nol Rupiah' : 'Nol';
    }

    String result;
    if (intValue < 0) {
      result = 'Minus ${_spellOut(intValue.abs())}';
    } else {
      result = _spellOut(intValue);
    }

    result = _cleanSpacing(result);

    if (appendRupiah) {
      result = '$result Rupiah';
    }

    return result;
  }

  static String _spellOut(int n) {
    if (n < 12) {
      return _units[n];
    } else if (n < 20) {
      return '${_spellOut(n - 10)} Belas';
    } else if (n < 100) {
      final tens = n ~/ 10;
      final remainder = n % 10;
      return '${_units[tens]} Puluh ${_spellOut(remainder)}';
    } else if (n < 200) {
      return 'Seratus ${_spellOut(n - 100)}';
    } else if (n < 1000) {
      final hundreds = n ~/ 100;
      final remainder = n % 100;
      return '${_units[hundreds]} Ratus ${_spellOut(remainder)}';
    } else if (n < 2000) {
      return 'Seribu ${_spellOut(n - 1000)}';
    } else if (n < 1000000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      return '${_spellOut(thousands)} Ribu ${_spellOut(remainder)}';
    } else if (n < 1000000000) {
      final millions = n ~/ 1000000;
      final remainder = n % 1000000;
      return '${_spellOut(millions)} Juta ${_spellOut(remainder)}';
    } else if (n < 1000000000000) {
      final billions = n ~/ 1000000000;
      final remainder = n % 1000000000;
      return '${_spellOut(billions)} Miliar ${_spellOut(remainder)}';
    } else {
      final trillions = n ~/ 1000000000000;
      final remainder = n % 1000000000000;
      return '${_spellOut(trillions)} Triliun ${_spellOut(remainder)}';
    }
  }

  static String _cleanSpacing(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
