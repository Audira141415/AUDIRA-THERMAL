import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/widgets/about_license_dialog.dart';
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

  Future<void> _handleBackupJson() async {
    final receiptService = context.read<ReceiptService>();
    try {
      final jsonBackup = await receiptService.exportDatabaseBackup();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.backup_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Backup Data JSON'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cadangan seluruh database SQLite lokal berhasil dibuat. Anda dapat membagikan file .json atau menyalin teksnya:',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonBackup,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonBackup));
                Navigator.pop(ctx);
                CustomDialogs.showSuccessSnackBar(context, 'Data JSON cadangan disalin ke clipboard');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin Teks'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final file = await receiptService.exportBackupJsonFile();
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    subject: 'Cadangan Database AUDIRA RECEIPT',
                    text: 'File cadangan data kwitansi dan pengaturan AUDIRA RECEIPT (.json)',
                  );
                } catch (e) {
                  if (mounted) CustomDialogs.showErrorSnackBar(context, 'Gagal membagikan cadangan: $e');
                }
              },
              icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
              label: const Text('Bagikan File', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      CustomDialogs.showErrorSnackBar(context, 'Gagal membuat backup: $e');
    }
  }

  Future<void> _handleRestoreJson() async {
    final controller = TextEditingController();
    String? pickedFileName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.restore_page_outlined, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Restore Database'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih file backup .json dari memori HP atau tempelkan data JSON cadangan:',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () async {
                      try {
                        final files = await FilePicker.pickFiles(
                          type: FileType.any,
                        );
                        if (files.isNotEmpty && files.first.path != null) {
                          final path = files.first.path!;
                          final file = File(path);
                          final content = await file.readAsString();
                          controller.text = content;
                          setDialogState(() {
                            pickedFileName = files.first.name;
                          });
                        }
                      } catch (e) {
                        debugPrint('FilePicker notice: $e');
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      pickedFileName != null ? 'Terpilih: $pickedFileName' : '📂 Pilih File (.json)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Atau tempel teks JSON manual:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: '{"version": 1, "receipts": [...]}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Pulihkan Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty && mounted) {
      try {
        final receiptService = context.read<ReceiptService>();
        final count = await receiptService.restoreDatabaseBackup(controller.text.trim());
        if (!mounted) return;
        if (count > 0) {
          CustomDialogs.showSuccessSnackBar(context, '$count kwitansi berhasil dipulihkan!');
        } else {
          CustomDialogs.showErrorSnackBar(context, 'Format JSON cadangan tidak valid atau data kosong');
        }
      } catch (e) {
        if (mounted) {
          CustomDialogs.showErrorSnackBar(context, 'Gagal merestore data: $e');
        }
      }
    }
  }

  Future<void> _handleResetAllReceipts() async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context: context,
      title: 'Hapus Semua Kwitansi',
      message: 'Apakah Anda yakin ingin mengosongkan seluruh riwayat kwitansi? Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus Semua',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final receiptService = context.read<ReceiptService>();
      await receiptService.clearAllReceipts();
      if (mounted) {
        CustomDialogs.showSuccessSnackBar(context, 'Seluruh riwayat kwitansi telah dibersihkan');
      }
    }
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
                    showChevron: false,
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.style_outlined,
                    title: 'Pilih Template Kwitansi (22+ Pilihan)',
                    subtitle: 'Aktif: ${receiptService.activeTemplate.name}',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.templateGallery),
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.inventory_2_outlined,
                    title: 'Katalog Produk & Jasa',
                    subtitle: 'Kelola daftar barang, jasa & harga satuan tersimpan',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.productCatalog),
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.tune_rounded,
                    title: 'Kustomisasi Pengaturan Template',
                    subtitle: 'Atur frame, tanda tangan, barcode, QR & footer',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.templateSettings,
                      arguments: receiptService.activeTemplate,
                    ),
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
                    'Ukuran Kertas Default',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRadioOption(
                        label: '48 mm (24 Kolom)',
                        isSelected: settings.paperSize == AppConstants.paper48mm,
                        onTap: () => receiptService.updateSettings(
                          settings.copyWith(paperSize: AppConstants.paper48mm),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildRadioOption(
                        label: '58 mm (32 Kolom)',
                        isSelected: settings.paperSize == AppConstants.paper58mm,
                        onTap: () => receiptService.updateSettings(
                          settings.copyWith(paperSize: AppConstants.paper58mm),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildRadioOption(
                        label: '80 mm (48 Kolom)',
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
                        'Cetak Logo AUDIRA',
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
                  const Divider(height: 16, color: AppColors.divider),

                  // Print Density
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ketebalan Cetak (Density)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      DropdownButton<int>(
                        value: settings.printDensity,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Light (1)')),
                          DropdownMenuItem(value: 2, child: Text('Normal (2)')),
                          DropdownMenuItem(value: 3, child: Text('Dark (3)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            receiptService.updateSettings(settings.copyWith(printDensity: val));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Cadangan & Pemeliharaan Database
            _buildSectionHeader('Cadangan & Pemeliharaan Data'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingRowWithSubtitle(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Backup Database (JSON)',
                    subtitle: 'Ekspor seluruh transaksi & pengaturan ke JSON',
                    onTap: _handleBackupJson,
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.restore_page_outlined,
                    title: 'Restore Database (JSON)',
                    subtitle: 'Pulihkan data dari cadangan JSON',
                    onTap: _handleRestoreJson,
                  ),
                  const Divider(height: 1, indent: 52, color: AppColors.divider),
                  _buildSettingRowWithSubtitle(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Bersihkan Riwayat Kwitansi',
                    subtitle: 'Hapus semua data kwitansi yang tersimpan',
                    titleColor: const Color(0xFFEF4444),
                    onTap: _handleResetAllReceipts,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 4: Lisensi & Informasi Pengembang
            _buildSectionHeader('Lisensi & Pengembang'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingRowWithSubtitle(
                    icon: Icons.verified_user_rounded,
                    title: 'Tentang & Lisensi Resmi AUDIRA',
                    subtitle: 'Pengembang: Agus Dwi R • Lisensi Seumur Hidup',
                    titleColor: AppColors.primary,
                    onTap: () => AboutLicenseDialog.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: titleColor ?? AppColors.secondaryText),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? AppColors.text,
                    ),
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
