class AppConstants {
  AppConstants._();

  static const String appName = 'AUDIRA RECEIPT';
  static const String appSubtitle = 'Thermal Receipt Printer';
  static const String appVersion = '1.0.0';

  // Printer Paper Sizes
  static const String paper48mm = '48mm';
  static const String paper58mm = '58mm';
  static const String paper80mm = '80mm';

  // Paper character widths
  static const int paper48WidthChars = 24;
  static const int paper58WidthChars = 32;
  static const int paper80WidthChars = 48;

  // Receipt Number
  static const String defaultReceiptPrefix = 'AUD';
  static const int receiptNumberLength = 5;

  // Payment Methods
  static const List<String> paymentMethods = [
    'Tunai (Cash)',
    'Transfer Bank',
    'QRIS',
    'Kartu Debit',
    'Kartu Kredit',
    'Lainnya',
  ];

  // Default Company
  static const String defaultCompanyName = 'AUDIRA MULTIMEDIA DIGITAL';
  static const String defaultCompanyAddress = 'Jl. Raya Digital No. 88, Jakarta';
  static const String defaultCompanyPhone = '+62 812-3456-7890';
  static const String defaultCompanyEmail = 'info@audira.id';
}
