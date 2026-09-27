import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _prefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<ReceiptService>().settings;
    _prefixController.text = settings.receiptPrefix;
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _updatePrefix() async {
    final prefix = _prefixController.text.trim().toUpperCase();
    if (prefix.isEmpty) {
      CustomDialogs.showErrorSnackBar(context, 'Prefix tidak boleh kosong');
      return;
    }

    final receiptService = context.read<ReceiptService>();
    await receiptService.updateSettings(
      receiptService.settings.copyWith(receiptPrefix: prefix),
    );

    if (mounted) {
      CustomDialogs.showSuccessSnackBar(context, 'Prefix berhasil diubah menjadi $prefix');
    }
  }

  Future<void> _resetCounter() async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context: context,
      title: 'Reset Penomoran Kwitansi',
      message: 'Apakah Anda yakin ingin mengatur ulang nomor urut kwitansi kembali ke nomor 1? Nomor berikutnya akan dimulai dari 00001.',
      confirmText: 'Ya, Reset',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final receiptService = context.read<ReceiptService>();
      await receiptService.updateSettings(
        receiptService.settings.copyWith(lastReceiptNumber: 0),
      );
      if (mounted) {
        CustomDialogs.showSuccessSnackBar(context, 'Nomor urut berhasil direset ke 0');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final settings = receiptService.settings;
    final company = receiptService.company;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Profile Card Link
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.companyProfile),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Edit profil & identitas kop kwitansi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Receipt Numbering Settings
            const Text(
              'Format Penomoran Kwitansi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prefixController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Prefix Nomor',
                            hintText: 'AUD',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _updatePrefix,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contoh format nomor kwitansi:',
                          style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${settings.receiptPrefix}-${DateTime.now().year}-00001',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nomor urut terakhir di database: ${settings.lastReceiptNumber}',
                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetCounter,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset Urutan ke 00001'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Printer Options Settings
            const Text(
              'Pencetakan ESC/POS',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto Cut Kertas (GS V)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    subtitle: const Text(
                      'Potong kertas setelah pencetakan selesai',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                    value: settings.autoCut,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      receiptService.updateSettings(settings.copyWith(autoCut: val));
                    },
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ukuran Kertas Bawaan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '58mm (ringkas) atau 80mm (lebar)',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '58mm', label: Text('58mm')),
                          ButtonSegment(value: '80mm', label: Text('80mm')),
                        ],
                        selected: {settings.paperSize},
                        onSelectionChanged: (val) {
                          receiptService.updateSettings(settings.copyWith(paperSize: val.first));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About App Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Versi ${AppConstants.appVersion} • Offline-First',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aplikasi cetak kwitansi langsung ke printer thermal Bluetooth menggunakan perintah ESC/POS tanpa melalui rendering PDF yang berat. Semua data tersimpan aman secara offline di SQLite lokal perangkat.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
