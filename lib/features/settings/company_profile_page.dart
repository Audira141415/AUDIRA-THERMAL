import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/widgets/audira_logo.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bankInfoController;
  late TextEditingController _signerNameController;
  late TextEditingController _footerMessageController;

  String? _logoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final company = context.read<ReceiptService>().company;
    _logoPath = company.logo;
    _nameController = TextEditingController(text: company.name);
    _taglineController = TextEditingController(text: company.tagline);
    _addressController = TextEditingController(text: company.address);
    _phoneController = TextEditingController(text: company.phone);
    _emailController = TextEditingController(text: company.email);
    _bankInfoController = TextEditingController(text: company.bankInfo);
    _signerNameController = TextEditingController(text: company.signerName);
    _footerMessageController = TextEditingController(text: company.footerMessage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankInfoController.dispose();
    _signerNameController.dispose();
    _footerMessageController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.png';
        final savedFile = File('${appDir.path}/company_logo$ext');
        await File(picked.path).copy(savedFile.path);
        setState(() => _logoPath = savedFile.path);
        if (mounted) {
          CustomDialogs.showSuccessSnackBar(context, 'Logo perusahaan berhasil dipilih');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showErrorSnackBar(context, 'Gagal memilih logo: $e');
      }
    }
  }

  void _removeLogo() {
    setState(() => _logoPath = null);
    CustomDialogs.showSuccessSnackBar(context, 'Logo diatur kembali ke default');
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    final receiptService = context.read<ReceiptService>();

    final updatedCompany = receiptService.company.copyWith(
      logo: _logoPath,
      name: _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      bankInfo: _bankInfoController.text.trim(),
      signerName: _signerNameController.text.trim(),
      footerMessage: _footerMessageController.text.trim(),
    );

    try {
      await receiptService.updateCompany(updatedCompany);
      if (mounted) {
        setState(() => _isSaving = false);
        CustomDialogs.showSuccessSnackBar(context, 'Profil perusahaan berhasil disimpan');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomDialogs.showErrorSnackBar(context, 'Gagal menyimpan profil: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengaturan Perusahaan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Logo Perusahaan
              const Text(
                'Logo Struk Perusahaan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    if (_logoPath != null && File(_logoPath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_logoPath!),
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      const AudiraLogoWidget(size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _logoPath != null ? 'Logo Kustom Aktif' : 'Logo Default AUDIRA',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            _logoPath != null ? 'Dicetak di struk thermal & PDF' : 'Pilih file gambar dari galeri HP',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: Text(_logoPath != null ? 'Ganti' : 'Pilih Logo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_logoPath != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _removeLogo,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        tooltip: 'Hapus Logo',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Nama Perusahaan
              _buildFieldLabel('Nama Usaha / Perusahaan'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'AUDIRA MULTIMEDIA DIGITAL',
                  prefixIcon: Icon(Icons.business_outlined, size: 20, color: AppColors.secondaryText),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // 3. Slogan / Tagline
              _buildFieldLabel('Slogan / Tagline Struk'),
              TextFormField(
                controller: _taglineController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'MULTIMEDIA DIGITAL & IT SERVICES',
                  prefixIcon: Icon(Icons.short_text_rounded, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Alamat
              _buildFieldLabel('Alamat Lengkap'),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Jl. Ahmad Yani No. 123, Batam Center',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Telepon & Email
              _buildFieldLabel('Telepon / WhatsApp'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '0812 3456 7890',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Email'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'info@audira.co.id',
                  prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Info Rekening Bank
              _buildFieldLabel('Info Pembayaran / Rekening Bank'),
              TextFormField(
                controller: _bankInfoController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'BCA: 8800123456 a/n PT AUDIRA',
                  prefixIcon: Icon(Icons.account_balance_outlined, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Nama Kasir / Penandatangan
              _buildFieldLabel('Nama Penandatangan (Penerima)'),
              TextFormField(
                controller: _signerNameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Kasir / Bendahara / Nama Anda',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // 8. Pesan Footer Struk
              _buildFieldLabel('Pesan Footer Struk Thermal'),
              TextFormField(
                controller: _footerMessageController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Terima kasih atas kepercayaan Anda',
                  prefixIcon: Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 32),

              // SIMPAN Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
      ),
    );
  }
}
