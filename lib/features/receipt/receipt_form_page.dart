import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/widgets/amount_field.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class ReceiptFormPage extends StatefulWidget {
  final Receipt? editReceipt;

  const ReceiptFormPage({super.key, this.editReceipt});

  @override
  State<ReceiptFormPage> createState() => _ReceiptFormPageState();
}

class _ReceiptFormPageState extends State<ReceiptFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _receiptNumberController;
  late TextEditingController _receivedFromController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late String _selectedPaymentMethod;
  bool _isLoadingNumber = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final receipt = widget.editReceipt;

    _receiptNumberController = TextEditingController(text: receipt?.receiptNumber ?? '');
    _receivedFromController = TextEditingController(text: receipt?.receivedFrom ?? '');
    _amountController = TextEditingController(
      text: receipt != null ? CurrencyFormatter.format(receipt.amount, withSymbol: false) : '',
    );
    _descriptionController = TextEditingController(text: receipt?.description ?? '');
    _notesController = TextEditingController(text: receipt?.notes ?? '');

    _selectedDate = receipt?.date ?? DateTime.now();
    _selectedPaymentMethod = receipt?.paymentMethod ?? AppConstants.paymentMethods.first;

    if (receipt == null) {
      _loadNextReceiptNumber();
    }
  }

  Future<void> _loadNextReceiptNumber() async {
    setState(() => _isLoadingNumber = true);
    try {
      final receiptService = context.read<ReceiptService>();
      final nextNumber = await receiptService.getNextReceiptNumber();
      if (mounted) {
        setState(() {
          _receiptNumberController.text = nextNumber;
          _isLoadingNumber = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNumber = false);
      }
    }
  }

  @override
  void dispose() {
    _receiptNumberController.dispose();
    _receivedFromController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveReceipt({bool goToPreview = true}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final receiptService = context.read<ReceiptService>();
    final amount = CurrencyFormatter.parse(_amountController.text);

    try {
      Receipt saved;
      if (widget.editReceipt != null) {
        saved = widget.editReceipt!.copyWith(
          receiptNumber: _receiptNumberController.text.trim(),
          date: _selectedDate,
          receivedFrom: _receivedFromController.text.trim(),
          amount: amount,
          description: _descriptionController.text.trim(),
          paymentMethod: _selectedPaymentMethod,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await receiptService.updateReceipt(saved);
      } else {
        saved = await receiptService.saveReceipt(
          receiptNumber: _receiptNumberController.text.trim(),
          date: _selectedDate,
          receivedFrom: _receivedFromController.text.trim(),
          amount: amount,
          description: _descriptionController.text.trim(),
          paymentMethod: _selectedPaymentMethod,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      CustomDialogs.showSuccessSnackBar(
        context,
        widget.editReceipt != null ? 'Kwitansi berhasil diperbarui' : 'Kwitansi berhasil disimpan',
      );

      if (goToPreview) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.receiptPreview,
          arguments: saved,
        );
      } else {
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CustomDialogs.showErrorSnackBar(context, 'Gagal menyimpan kwitansi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editReceipt != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kwitansi' : 'Buat Kwitansi'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _saveReceipt(goToPreview: true),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              label: const Text('Preview'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Section 1: Number & Date
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
                    const Text(
                      'Informasi Kwitansi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Receipt Number Field
                    TextFormField(
                      controller: _receiptNumberController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Kwitansi *',
                        hintText: 'AUD-2026-00001',
                        prefixIcon: const Icon(Icons.tag, color: AppColors.secondaryText, size: 20),
                        suffixIcon: _isLoadingNumber
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                tooltip: 'Generate Nomor Baru',
                                onPressed: _loadNextReceiptNumber,
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor kwitansi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date Picker Input
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.secondaryText,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tanggal Kwitansi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.edit_calendar,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card Section 2: Payer & Amount
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
                    const Text(
                      'Penerimaan & Nominal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Received From
                    TextFormField(
                      controller: _receivedFromController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Telah Diterima Dari *',
                        hintText: 'Nama lengkap pembayar / instansi',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.secondaryText, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama pembayar wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount with Auto-Terbilang
                    AmountField(
                      controller: _amountController,
                      initialAmountWords: widget.editReceipt?.amountWords,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card Section 3: Purpose, Method, Notes
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
                    const Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description / Untuk Pembayaran
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Untuk Pembayaran *',
                        hintText: 'Contoh: Jasa Maintenance Server / Pembelian Hardware',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.description_outlined, color: AppColors.secondaryText, size: 20),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Keterangan pembayaran wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Metode Pembayaran',
                        prefixIcon: Icon(Icons.payment_outlined, color: AppColors.secondaryText, size: 20),
                      ),
                      items: AppConstants.paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPaymentMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes (Optional)
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan (Opsional)',
                        hintText: 'Catatan internal atau nomor referensi',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.note_alt_outlined, color: AppColors.secondaryText, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveReceipt(goToPreview: false),
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: const Text('Simpan Saja'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveReceipt(goToPreview: true),
                      icon: const Icon(Icons.print_outlined, size: 20),
                      label: const Text('Simpan & Cetak'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
