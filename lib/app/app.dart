import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/app/theme.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';
import 'package:audira_receipt/core/services/printer_service.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/database/receipt_repository.dart';

class AudiraReceiptApp extends StatelessWidget {
  const AudiraReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ReceiptRepository>(
          create: (_) => ReceiptRepository(),
        ),
        ChangeNotifierProvider<BluetoothService>(
          create: (_) => BluetoothService(),
        ),
        ChangeNotifierProxyProvider2<BluetoothService, ReceiptRepository, PrinterService>(
          create: (ctx) => PrinterService(
            bluetoothService: ctx.read<BluetoothService>(),
            repository: ctx.read<ReceiptRepository>(),
          ),
          update: (_, bluetooth, repo, previous) =>
              previous ?? PrinterService(bluetoothService: bluetooth, repository: repo),
        ),
        ChangeNotifierProxyProvider<ReceiptRepository, ReceiptService>(
          create: (ctx) => ReceiptService(
            repository: ctx.read<ReceiptRepository>(),
          )..init(),
          update: (_, repo, previous) =>
              previous ?? (ReceiptService(repository: repo)..init()),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
