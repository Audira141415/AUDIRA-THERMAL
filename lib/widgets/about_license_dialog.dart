import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class AboutLicenseDialog extends StatelessWidget {
  const AboutLicenseDialog({super.key});

  static const String developerName = 'Agus Dwi R';
  static const String brandName = 'AUDIRA (Audira Thermal Systems)';
  static const String copyrightNotice = '© 2026 Agus Dwi R (AUDIRA). All Rights Reserved.';
  static const String licenseType = 'Lisensi Komersial Mandiri & Hak Cipta Penuh';
  static const String certificateSerial = '6a3029f5e6a8c72';
  static const String certificateSha256 =
      'C1:89:2A:FC:F2:1C:FE:A9:27:5C:B5:A5:6B:8F:EE:B0:A4:B0:3D:11:4F:94:9C:3E:04:18:BC:74:06:17:47:8D';

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AboutLicenseDialog(),
    );
  }

  void _copyLicenseInfo(BuildContext context) {
    const text = '''
=== INFORMASI LISENSI RESMI AUDIRA ===
Aplikasi: ${AppConstants.appName}
Versi: 2.0.0
Pemilik Lisensi & Pengembang: $developerName
Brand: $brandName
Hak Cipta: $copyrightNotice
Tipe Lisensi: $licenseType
Masa Berlaku: Permanen (Seumur Hidup / Offline Lifetime)
Sertifikat Tanda Tangan: RSA 2048-Bit (SHA384withRSA)
Serial Sertifikat: $certificateSerial
SHA-256 Fingerprint: $certificateSha256
Keterangan: Hak cipta dan kepemilikan penuh dilindungi undang-undang. Bebas biaya langganan bulanan selamanya.
======================================
''';
    Clipboard.setData(const ClipboardData(text: text));
    CustomDialogs.showSuccessSnackBar(context, 'Detail lisensi resmi disalin ke clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang & Lisensi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Sertifikat Resmi Pengembang',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              // Status Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LISENSI RESMI BERSERTIFIKAT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Software Details Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Nama Aplikasi', AppConstants.appName, isBold: true),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildInfoRow('Versi Sistem', 'v2.0.0 (Release Build v8)'),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildInfoRow('Pemilik & Developer', developerName, isBold: true, highlightColor: AppColors.primary),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildInfoRow('Brand Ekosistem', brandName),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildInfoRow('Tipe Lisensi', licenseType),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildInfoRow('Masa Berlaku', 'Permanen (Seumur Hidup / Offline)'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Security & Digital Certificate Box
              const Text(
                'SERTIFIKAT DIGITAL & TANDA TANGAN APK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'RSA 2048-Bit • SHA384withRSA',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Serial: $certificateSerial',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SHA-256 Fingerprint:',
                      style: TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      certificateSha256,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Terms & Protection Note
              Text(
                copyrightNotice,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hak cipta dilindungi undang-undang. Seluruh arsitektur pencetakan thermal, desain template, dan modul aplikasi dimiliki sepenuhnya oleh Agus Dwi R. Bebas biaya langganan bulanan tanpa batas waktu.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _copyLicenseInfo(context),
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Salin Lisensi', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Tutup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: highlightColor ?? AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
