import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/models/receipt.dart';
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
  String _amountWords = '';
  int _printCopies = 1;
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
    _selectedPaymentMethod = receipt?.paymentMethod ?? 'Transfer Bank';

    if (receipt != null) {
      _amountWords = receipt.amountWords;
    }

    _amountController.addListener(_updateTerbilang);

    if (receipt == null) {
      _loadNextReceiptNumber();
    }
  }

  void _updateTerbilang() {
    final amount = CurrencyFormatter.parse(_amountController.text);
    setState(() {
      _amountWords = amount > 0 ? NumberToWords.convert(amount) : '';
    });
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
    _amountController.removeListener(_updateTerbilang);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kwitansi' : 'Buat Kwitansi'),
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
              // 1. Nomor Kwitansi
              _buildFieldLabel('Nomor Kwitansi'),
              TextFormField(
                controller: _receiptNumberController,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'AUD-2026-00014',
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
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.secondaryText),
                          onPressed: _loadNextReceiptNumber,
                          tooltip: 'Generate Nomor Baru',
                        ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // 2. Tanggal
              _buildFieldLabel('Tanggal'),
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
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.secondaryText),
                      const SizedBox(width: 12),
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
                ),
              ),
              const SizedBox(height: 16),

              // 3. Diterima Dari
              _buildFieldLabel('Diterima Dari'),
              TextFormField(
                controller: _receivedFromController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nama Pembayar',
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.secondaryText),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama pembayar wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // 4. Nominal
              _buildFieldLabel('Nominal'),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  IndonesianCurrencyInputFormatter(),
                ],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: const Text(
                      'Rp',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                  ),
                  suffixIcon: _amountController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _amountController.clear(),
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nominal wajib diisi';
                  if (CurrencyFormatter.parse(val) <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // 5. Terbilang (otomatis) Light Green Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terbilang (otomatis)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF166534),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _amountWords.isNotEmpty ? _amountWords : 'Nol Rupiah',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_amountWords.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF166534)),
                        tooltip: 'Salin Terbilang',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _amountWords));
                          CustomDialogs.showSuccessSnackBar(context, 'Terbilang disalin ke clipboard');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. Untuk Pembayaran
              _buildFieldLabel('Untuk Pembayaran'),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Jasa Maintenance Server',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Keterangan wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // 7. Metode Pembayaran
              _buildFieldLabel('Metode Pembayaran'),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.secondaryText),
                ),
                items: AppConstants.paymentMethods.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
              ),
              const SizedBox(height: 16),

              // 8. Catatan (Opsional)
              _buildFieldLabel('Catatan (Opsional)'),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: '-',
                ),
              ),
              const SizedBox(height: 18),

              // 9. Jumlah Cetak Stepper Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jumlah Cetak',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _printCopies > 1 ? () => setState(() => _printCopies--) : null,
                          icon: const Icon(Icons.remove, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_printCopies',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _printCopies++),
                          icon: const Icon(Icons.add, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 10. Bottom Action Buttons: [SIMPAN] and [PREVIEW →]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _saveReceipt(goToPreview: false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'SIMPAN',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveReceipt(goToPreview: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PREVIEW',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
