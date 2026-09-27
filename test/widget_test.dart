import 'package:flutter_test/flutter_test.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';

void main() {
  test('App Constants smoke test', () {
    expect(AppConstants.appName, equals('AUDIRA RECEIPT'));
    expect(AppConstants.appSubtitle, equals('Thermal Receipt Printer'));
    expect(AppConstants.paper58WidthChars, equals(32));
    expect(AppConstants.paper80WidthChars, equals(48));
  });
}
