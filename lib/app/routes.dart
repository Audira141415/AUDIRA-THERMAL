import 'package:flutter/material.dart';
import 'package:audira_receipt/features/dashboard/dashboard_page.dart';
import 'package:audira_receipt/features/printer/bluetooth_scan_page.dart';
import 'package:audira_receipt/features/printer/printer_connected_page.dart';
import 'package:audira_receipt/features/printer/printer_test_page.dart';
import 'package:audira_receipt/features/product/product_catalog_page.dart';
import 'package:audira_receipt/features/receipt/receipt_detail_page.dart';
import 'package:audira_receipt/features/receipt/receipt_form_page.dart';
import 'package:audira_receipt/features/receipt/receipt_preview_page.dart';
import 'package:audira_receipt/features/settings/company_profile_page.dart';
import 'package:audira_receipt/features/splash/splash_page.dart';
import 'package:audira_receipt/features/template/template_gallery_page.dart';
import 'package:audira_receipt/features/template/template_settings_page.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String main = '/main';
  static const String receiptForm = '/receipt/form';
  static const String receiptPreview = '/receipt/preview';
  static const String receiptHistory = '/receipt/history';
  static const String receiptDetail = '/receipt/detail';
  static const String printer = '/printer';
  static const String printerScan = '/printer/scan';
  static const String printerConnected = '/printer/connected';
  static const String printerTest = '/printer/test';
  static const String settings = '/settings';
  static const String companyProfile = '/settings/company';
  static const String templateGallery = '/templates';
  static const String templateSettings = '/templates/settings';
  static const String productCatalog = '/products';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case main:
        final initialIndex = routeSettings.arguments as int? ?? 0;
        return MaterialPageRoute(builder: (_) => DashboardPage(initialTab: initialIndex));
      case receiptForm:
        final receiptToEdit = routeSettings.arguments as Receipt?;
        return MaterialPageRoute(
          builder: (_) => ReceiptFormPage(editReceipt: receiptToEdit),
        );
      case receiptPreview:
        final receipt = routeSettings.arguments as Receipt;
        return MaterialPageRoute(
          builder: (_) => ReceiptPreviewPage(receipt: receipt),
        );
      case receiptDetail:
        final receipt = routeSettings.arguments as Receipt;
        return MaterialPageRoute(
          builder: (_) => ReceiptDetailPage(receipt: receipt),
        );
      case printerScan:
        return MaterialPageRoute(builder: (_) => const BluetoothScanPage());
      case printerConnected:
        return MaterialPageRoute(builder: (_) => const PrinterConnectedPage());
      case printerTest:
        return MaterialPageRoute(builder: (_) => const PrinterTestPage());
      case companyProfile:
        return MaterialPageRoute(builder: (_) => const CompanyProfilePage());
      case templateGallery:
        return MaterialPageRoute(builder: (_) => const TemplateGalleryPage());
      case templateSettings:
        final tpl = routeSettings.arguments as ReceiptTemplate? ?? ReceiptTemplate.allTemplates.first;
        return MaterialPageRoute(builder: (_) => TemplateSettingsPage(template: tpl));
      case productCatalog:
        final isSelection = routeSettings.arguments as bool? ?? false;
        return MaterialPageRoute(builder: (_) => ProductCatalogPage(isSelectionMode: isSelection));
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
