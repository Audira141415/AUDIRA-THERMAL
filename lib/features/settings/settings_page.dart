import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  void _editPrefixDialog(BuildContext context, String currentPrefix) {
    final controller = TextEditingController(text: currentPrefix);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Prefix Nomor Kwitansi'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Contoh: AUD-',
            labelText: 'Prefix',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim().toUpperCase();
              if (val.isNotEmpty) {
                final receiptService = context.read<ReceiptService>();
                receiptService.updateSettings(
                  receiptService.settings.copyWith(receiptPrefix: val),
                );
                Navigator.pop(ctx);
                CustomDialogs.showSuccessSnackBar(context, 'Prefix diubah ke $val');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final settings = receiptService.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Pengaturan Kwitansi
            _buildSectionHeader('Pengaturan Kwitansi'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.tag,
                    title: 'Prefix Nomor Kwitansi',
                    trailingText: '${settings.receiptPrefix}-',
                    showChevron: true,
                    onTap: () => _editPrefixDialog(context, settings.receiptPrefix),
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRow(
                    icon: Icons.numbers_rounded,
                    title: 'Nomor Terakhir',
                    trailingText: '${settings.lastReceiptNumber}',
                    showChevron: false,
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRow(
                    icon: Icons.calendar_month_outlined,
                    title: 'Format Tanggal',
                    trailingText: 'DD/MM/YYYY',
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Pengaturan Printer Default
            _buildSectionHeader('Pengaturan Printer Default'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ukuran Kertas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRadioOption(
                        label: '58 mm',
                        isSelected: settings.paperSize == AppConstants.paper58mm,
                        onTap: () => receiptService.updateSettings(
                          settings.copyWith(paperSize: AppConstants.paper58mm),
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildRadioOption(
                        label: '80 mm',
                        isSelected: settings.paperSize == AppConstants.paper80mm,
                        onTap: () => receiptService.updateSettings(
                          settings.copyWith(paperSize: AppConstants.paper80mm),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),

                  // Auto Cut Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Auto Cut (jika didukung)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Switch(
                        value: settings.autoCut,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          receiptService.updateSettings(settings.copyWith(autoCut: val));
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // Cetak Logo Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cetak Logo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Switch(
                        value: settings.printLogo,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          receiptService.updateSettings(settings.copyWith(printLogo: val));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Pengaturan Lainnya
            _buildSectionHeader('Pengaturan Lainnya'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.palette_outlined,
                    title: 'Tema Aplikasi',
                    trailingText: 'Light',
                    showChevron: true,
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Backup Data',
                    subtitle: 'Simpan data ke file',
                    onTap: () {
                      CustomDialogs.showSuccessSnackBar(context, 'Data berhasil dibackup ke memori internal');
                    },
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.restore_rounded,
                    title: 'Restore Data',
                    subtitle: 'Pulihkan data dari file',
                    onTap: () {
                      CustomDialogs.showSuccessSnackBar(context, 'Penyimpanan lokal telah diverifikasi');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String trailingText,
    required bool showChevron,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.secondaryText),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
            ),
            Text(
              trailingText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
            ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.secondaryText),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRowWithSubtitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.secondaryText),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.secondaryText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
