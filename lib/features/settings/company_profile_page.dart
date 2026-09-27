import 'package:flutter/material.dart';
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
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final company = context.read<ReceiptService>().company;
    _nameController = TextEditingController(text: company.name);
    _addressController = TextEditingController(text: company.address);
    _phoneController = TextEditingController(text: company.phone);
    _emailController = TextEditingController(text: company.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final receiptService = context.read<ReceiptService>();

    final updatedCompany = receiptService.company.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
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
                'Logo Perusahaan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const AudiraLogoWidget(size: 32),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        CustomDialogs.showSuccessSnackBar(context, 'Logo default AUDIRA aktif');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Ubah Logo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Nama Perusahaan
              const Text(
                'Nama Perusahaan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'AUDIRA MULTIMEDIA DIGITAL',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 18),

              // 3. Alamat
              const Text(
                'Alamat',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Jl. Ahmad Yani No. 123, Batam',
                ),
              ),
              const SizedBox(height: 18),

              // 4. Telepon
              const Text(
                'Telepon',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '0812 3456 7890',
                ),
              ),
              const SizedBox(height: 18),

              // 5. Email
              const Text(
                'Email',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'info@audira.co.id',
                ),
              ),
              const SizedBox(height: 36),

              // 6. [SIMPAN] Button
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
                          'SIMPAN',
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
}
