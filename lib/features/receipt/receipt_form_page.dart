import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/constants/app_constants.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/app_date_formatter.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';
import 'package:audira_receipt/models/company.dart';
import 'package:audira_receipt/models/product.dart';
import 'package:audira_receipt/models/receipt.dart';
import 'package:audira_receipt/models/receipt_template.dart';
import 'package:audira_receipt/widgets/audira_logo.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';
import 'package:audira_receipt/widgets/thermal_ticket_container.dart';

class ReceiptFormPage extends StatefulWidget {
  final Receipt? editReceipt;

  const ReceiptFormPage({super.key, this.editReceipt});

  @override
  State<ReceiptFormPage> createState() => _ReceiptFormPageState();
}

class _ReceiptFormPageState extends State<ReceiptFormPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers
  late TextEditingController _receiptNumberController;
  late TextEditingController _receivedFromController;
  late FocusNode _receivedFromFocusNode;
  late TextEditingController _customerPhoneController;
  late TextEditingController _cashierNameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  late TextEditingController _cashReceivedController;

  // Banner, Reward & Sosmed Controllers (Bisa langsung dikosongkan/diedit di form!)
  late TextEditingController _memberRewardController;
  late TextEditingController _promoBannerController;
  late TextEditingController _socialMediaController;

  late DateTime _selectedDate;
  late String _selectedPaymentMethod;
  late String _selectedStatus;
  late ReceiptTemplate _selectedTemplate;

  // Transaction Mode: Single Amount vs Multi-Item
  bool _isItemMode = false;
  final List<ReceiptItem> _items = [];

  // Multi-Company / Store Identity (Bisa ganti toko atau edit langsung!)
  late TextEditingController _storeNameController;
  late TextEditingController _storeTaglineController;
  late TextEditingController _storeAddressController;
  late TextEditingController _storePhoneController;
  late TextEditingController _storeLegalIdController;
  int? _selectedCompanyId;

  // Logo & Barcode
  String? _logoPath;
  bool _showLogo = true;
  bool _showBarcode = false;
  late TextEditingController _barcodeController;

  // In-place formatting controls (Langsung di form!)
  String _headerAlign = 'center';
  String _titleAlign = 'center';
  String _contentAlign = 'left';
  String _amountAlign = 'left';
  String _stampAlign = 'right';
  String _titleFontSize = 'large';
  String _amountFontSize = 'large';
  bool _isBoldTitle = true;
  bool _isBoldAmount = true;
  bool _isCondensed = false;
  String _stampType = 'LUNAS';

  int _printCopies = 1;
  bool _isLoadingNumber = false;
  bool _isSaving = false;
  List<String> _customerSuggestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    final receipt = widget.editReceipt;
    final receiptService = context.read<ReceiptService>();

    final initialCompany = receiptService.company;
    _selectedCompanyId = initialCompany.id;
    _storeNameController = TextEditingController(text: receipt?.storeName ?? initialCompany.name);
    _storeTaglineController = TextEditingController(text: receipt?.storeTagline ?? initialCompany.tagline);
    _storeAddressController = TextEditingController(text: receipt?.storeAddress ?? initialCompany.address);
    _storePhoneController = TextEditingController(text: receipt?.storePhone ?? initialCompany.phone);
    _storeLegalIdController = TextEditingController(text: receipt?.storeLegalId ?? '');

    if (receipt != null && receipt.templateId.isNotEmpty) {
      _selectedTemplate = ReceiptTemplate.findById(receipt.templateId);
    } else {
      _selectedTemplate = receiptService.activeTemplate;
    }

    final initialCfg = receiptService.getTemplateConfig(_selectedTemplate.id);
    _memberRewardController = TextEditingController(text: initialCfg.memberReward);
    _promoBannerController = TextEditingController(text: initialCfg.promoBanner);
    _socialMediaController = TextEditingController(text: initialCfg.socialMedia);

    _logoPath = receipt?.logoPath ?? initialCompany.logo;
    _showLogo = receipt?.showLogo ?? initialCfg.showLogo;
    _showBarcode = receipt?.showBarcode ?? initialCfg.showBarcode;
    _barcodeController = TextEditingController(text: receipt?.barcodeData ?? '');

    _receiptNumberController = TextEditingController(text: receipt?.receiptNumber ?? '');
    _receivedFromController = TextEditingController(text: receipt?.receivedFrom ?? '');
    _receivedFromFocusNode = FocusNode();
    _customerPhoneController = TextEditingController(text: receipt?.customerPhone ?? '');
    _cashierNameController = TextEditingController(
      text: receipt?.cashierName ?? (receiptService.company.signerName.isNotEmpty ? receiptService.company.signerName : 'Admin / Kasir'),
    );
    _amountController = TextEditingController(
      text: receipt != null && receipt.items.isEmpty ? CurrencyFormatter.format(receipt.amount, withSymbol: false) : '',
    );
    _descriptionController = TextEditingController(text: receipt?.description ?? '');
    _notesController = TextEditingController(text: receipt?.notes ?? '');
    _discountController = TextEditingController(
      text: receipt != null && receipt.discount > 0 ? CurrencyFormatter.format(receipt.discount, withSymbol: false) : '',
    );
    _taxController = TextEditingController(
      text: receipt != null && receipt.tax > 0 ? CurrencyFormatter.format(receipt.tax, withSymbol: false) : '',
    );
    _cashReceivedController = TextEditingController(
      text: receipt != null && receipt.cashReceived > 0 ? CurrencyFormatter.format(receipt.cashReceived, withSymbol: false) : '',
    );

    _selectedDate = receipt?.date ?? DateTime.now();
    _selectedPaymentMethod = receipt?.paymentMethod ?? 'Tunai (Cash)';
    _selectedStatus = receipt?.status ?? 'LUNAS';

    // In-place direct formatting initialization
    if (receipt != null) {
      _headerAlign = receipt.headerAlign;
      _titleAlign = receipt.titleAlign;
      _contentAlign = receipt.contentAlign;
      _amountAlign = receipt.amountAlign;
      _stampAlign = receipt.stampAlign;
      _titleFontSize = receipt.titleFontSize;
      _amountFontSize = receipt.amountFontSize;
      _isBoldTitle = receipt.isBoldTitle;
      _isBoldAmount = receipt.isBoldAmount;
      _isCondensed = receipt.isCondensed;
      _stampType = receipt.stampType;

      if (receipt.items.isNotEmpty) {
        _isItemMode = true;
        _items.addAll(receipt.items);
      }
    } else {
      _syncFormattingWithTemplate(_selectedTemplate);
    }

    // Realtime listeners: set state whenever ANY field changes or is cleared
    _storeNameController.addListener(() => setState(() {}));
    _storeTaglineController.addListener(() => setState(() {}));
    _storeAddressController.addListener(() => setState(() {}));
    _storePhoneController.addListener(() => setState(() {}));
    _storeLegalIdController.addListener(() => setState(() {}));
    _barcodeController.addListener(() => setState(() {}));
    _receiptNumberController.addListener(() => setState(() {}));
    _receivedFromController.addListener(() => setState(() {}));
    _customerPhoneController.addListener(() => setState(() {}));
    _cashierNameController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
    _discountController.addListener(() => setState(() {}));
    _taxController.addListener(() => setState(() {}));
    _cashReceivedController.addListener(() => setState(() {}));
    _memberRewardController.addListener(() => setState(() {}));
    _promoBannerController.addListener(() => setState(() {}));
    _socialMediaController.addListener(() => setState(() {}));

    if (receipt == null) {
      _loadNextReceiptNumber();
    }
    _loadCustomerSuggestions();
  }

  void _syncFormattingWithTemplate(ReceiptTemplate tpl) {
    final cfg = context.read<ReceiptService>().getTemplateConfig(tpl.id);
    setState(() {
      _headerAlign = cfg.headerAlign;
      _titleAlign = cfg.titleAlign;
      _contentAlign = cfg.receivedFromAlign;
      _amountAlign = cfg.amountAlign;
      _stampAlign = cfg.stampAlign;
      _titleFontSize = cfg.titleFontSize;
      _amountFontSize = cfg.amountFontSize;
      _isBoldTitle = cfg.boldTitle;
      _isBoldAmount = cfg.boldAmount;
      _isCondensed = cfg.fontCondensed;
      _stampType = cfg.stampType == 'none' ? 'none' : 'LUNAS';
      _memberRewardController.text = cfg.memberReward;
      _promoBannerController.text = cfg.promoBanner;
      _socialMediaController.text = cfg.socialMedia;
      _showBarcode = cfg.showBarcode;
      _showLogo = cfg.showLogo;
    });
  }

  double get _itemsSubtotal => _items.fold(0.0, (sum, it) => sum + it.subtotal);

  double get _subtotal {
    if (_isItemMode) {
      return _itemsSubtotal;
    } else {
      return CurrencyFormatter.parse(_amountController.text);
    }
  }

  double get _discount => CurrencyFormatter.parse(_discountController.text);
  double get _tax => CurrencyFormatter.parse(_taxController.text);

  double get _totalAmount {
    final total = _subtotal - _discount + _tax;
    return total > 0 ? total : 0.0;
  }

  double get _cashReceived => CurrencyFormatter.parse(_cashReceivedController.text);
  double get _changeAmount => (_cashReceived > _totalAmount && _totalAmount > 0) ? _cashReceived - _totalAmount : 0.0;

  String get _amountWords => _totalAmount > 0 ? NumberToWords.convert(_totalAmount) : 'Nol Rupiah';

  Future<void> _loadCustomerSuggestions() async {
    try {
      final suggestions = await context.read<ReceiptService>().getCustomerSuggestions();
      if (mounted) {
        setState(() => _customerSuggestions = suggestions);
      }
    } catch (_) {}
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
    } catch (_) {
      if (mounted) setState(() => _isLoadingNumber = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeNameController.dispose();
    _storeTaglineController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _storeLegalIdController.dispose();
    _receiptNumberController.dispose();
    _receivedFromController.dispose();
    _receivedFromFocusNode.dispose();
    _customerPhoneController.dispose();
    _cashierNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _cashReceivedController.dispose();
    _memberRewardController.dispose();
    _promoBannerController.dispose();
    _socialMediaController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.png';
        final savedFile = File('${appDir.path}/store_logo_${DateTime.now().millisecondsSinceEpoch}$ext');
        await File(picked.path).copy(savedFile.path);
        setState(() {
          _logoPath = savedFile.path;
          _showLogo = true;
        });
        if (mounted) {
          CustomDialogs.showSuccessSnackBar(context, 'Logo kwitansi berhasil diperbarui!');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialogs.showErrorSnackBar(context, 'Gagal memilih logo: $e');
      }
    }
  }

  void _removeLogo() {
    setState(() {
      _logoPath = null;
      _showLogo = false;
    });
    CustomDialogs.showSuccessSnackBar(context, 'Logo dinonaktifkan dari kwitansi');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectFromCatalog() async {
    final selected = await Navigator.pushNamed(context, AppRoutes.productCatalog, arguments: true);
    if (selected is Product && mounted) {
      _addItemDialog(
        ReceiptItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: selected.name,
          quantity: 1.0,
          unitPrice: selected.unitPrice,
        ),
      );
    }
  }

  Future<void> _showCustomPercentDialog({
    required String title,
    required void Function(double percent) onApply,
  }) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtotal: ${CurrencyFormatter.format(_subtotal)}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Persentase (%)',
                hintText: 'Misal: 7.5',
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (val != null && val >= 0) {
                onApply(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Terapkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentChip(String label, VoidCallback onTap, {bool isReset = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isReset ? Colors.red.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isReset ? Colors.red.withOpacity(0.3) : AppColors.primary.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isReset ? Colors.red : AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _addItemDialog([ReceiptItem? editItem, int? editIndex]) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final qtyCtrl = TextEditingController(text: editItem != null ? (editItem.quantity % 1 == 0 ? editItem.quantity.toInt().toString() : editItem.quantity.toString()) : '1');
    final priceCtrl = TextEditingController(text: editItem != null ? CurrencyFormatter.format(editItem.unitPrice, withSymbol: false) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(editItem != null ? 'Edit Item / Jasa' : 'Tambah Item / Jasa', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang / Layanan *',
                  hintText: 'Misal: Servis Rutin / Nasi Goreng',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty / Jumlah',
                        hintText: '1',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        IndonesianCurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Harga Satuan (Rp) *',
                        hintText: '25.000',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1.0;
              final price = CurrencyFormatter.parse(priceCtrl.text);

              if (name.isEmpty) {
                CustomDialogs.showErrorSnackBar(ctx, 'Nama item wajib diisi');
                return;
              }
              if (price <= 0) {
                CustomDialogs.showErrorSnackBar(ctx, 'Harga satuan harus lebih dari 0');
                return;
              }

              final item = ReceiptItem(
                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                quantity: qty,
                unitPrice: price,
              );

              setState(() {
                if (editIndex != null) {
                  _items[editIndex] = item;
                } else {
                  _items.add(item);
                }
              });

              Navigator.pop(ctx);
            },
            child: const Text('Simpan Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReceipt({bool goToPreview = true}) async {
    if (_formKey.currentState != null) {
      if (!_formKey.currentState!.validate()) {
        _tabController.animateTo(0);
        return;
      }
    } else {
      if (_receiptNumberController.text.trim().isEmpty) {
        _tabController.animateTo(0);
        CustomDialogs.showErrorSnackBar(context, 'Nomor kwitansi wajib diisi');
        return;
      }
      if (!_isItemMode) {
        if (_amountController.text.trim().isEmpty || CurrencyFormatter.parse(_amountController.text) <= 0) {
          _tabController.animateTo(0);
          CustomDialogs.showErrorSnackBar(context, 'Nominal kwitansi harus lebih dari Rp 0');
          return;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _tabController.animateTo(0);
          CustomDialogs.showErrorSnackBar(context, 'Keterangan kwitansi wajib diisi');
          return;
        }
      }
    }

    if (_isItemMode && _items.isEmpty) {
      _tabController.animateTo(0);
      CustomDialogs.showErrorSnackBar(context, 'Tambahkan minimal 1 item untuk mode rincian barang/jasa');
      return;
    }

    if (_totalAmount <= 0) {
      _tabController.animateTo(0);
      CustomDialogs.showErrorSnackBar(context, 'Total kwitansi harus lebih dari Rp 0');
      return;
    }

    setState(() => _isSaving = true);
    final receiptService = context.read<ReceiptService>();

    String finalDesc = _descriptionController.text.trim();
    if (_isItemMode && finalDesc.isEmpty) {
      finalDesc = _items.map((i) => '${i.name} (x${i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity})').join(', ');
    }

    final fromPayer = _receivedFromController.text.trim();
    final dbPayer = fromPayer.isNotEmpty ? fromPayer : 'Pelanggan Umum';

    try {
      Receipt saved;
      if (widget.editReceipt != null) {
        saved = widget.editReceipt!.copyWith(
          receiptNumber: _receiptNumberController.text.trim(),
          date: _selectedDate,
          receivedFrom: dbPayer,
          customerPhone: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
          cashierName: _cashierNameController.text.trim().isEmpty ? null : _cashierNameController.text.trim(),
          amount: _totalAmount,
          amountWords: _amountWords,
          description: finalDesc,
          paymentMethod: _selectedPaymentMethod,
          status: _selectedStatus,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          templateId: _selectedTemplate.id,
          discount: _discount,
          tax: _tax,
          cashReceived: _cashReceived,
          changeAmount: _changeAmount,
          items: _isItemMode ? _items : [],
          storeName: _storeNameController.text.trim().isEmpty ? null : _storeNameController.text.trim(),
          storeAddress: _storeAddressController.text.trim().isEmpty ? null : _storeAddressController.text.trim(),
          storePhone: _storePhoneController.text.trim().isEmpty ? null : _storePhoneController.text.trim(),
          storeTagline: _storeTaglineController.text.trim().isEmpty ? null : _storeTaglineController.text.trim(),
          storeLegalId: _storeLegalIdController.text.trim().isEmpty ? null : _storeLegalIdController.text.trim(),
          logoPath: _logoPath,
          showLogo: _showLogo,
          showBarcode: _showBarcode,
          barcodeData: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          headerAlign: _headerAlign,
          titleAlign: _titleAlign,
          contentAlign: _contentAlign,
          amountAlign: _amountAlign,
          stampAlign: _stampAlign,
          titleFontSize: _titleFontSize,
          amountFontSize: _amountFontSize,
          isBoldTitle: _isBoldTitle,
          isBoldAmount: _isBoldAmount,
          isCondensed: _isCondensed,
          stampType: _stampType,
        );
        await receiptService.updateReceipt(saved);
      } else {
        saved = await receiptService.saveReceipt(
          receiptNumber: _receiptNumberController.text.trim(),
          date: _selectedDate,
          receivedFrom: dbPayer,
          customerPhone: _customerPhoneController.text.trim(),
          cashierName: _cashierNameController.text.trim(),
          amount: _totalAmount,
          description: finalDesc,
          paymentMethod: _selectedPaymentMethod,
          status: _selectedStatus,
          notes: _notesController.text.trim(),
          templateId: _selectedTemplate.id,
          discount: _discount,
          tax: _tax,
          cashReceived: _cashReceived,
          changeAmount: _changeAmount,
          items: _isItemMode ? _items : [],
          storeName: _storeNameController.text.trim().isEmpty ? null : _storeNameController.text.trim(),
          storeAddress: _storeAddressController.text.trim().isEmpty ? null : _storeAddressController.text.trim(),
          storePhone: _storePhoneController.text.trim().isEmpty ? null : _storePhoneController.text.trim(),
          storeTagline: _storeTaglineController.text.trim().isEmpty ? null : _storeTaglineController.text.trim(),
          storeLegalId: _storeLegalIdController.text.trim().isEmpty ? null : _storeLegalIdController.text.trim(),
          logoPath: _logoPath,
          showLogo: _showLogo,
          showBarcode: _showBarcode,
          barcodeData: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          headerAlign: _headerAlign,
          titleAlign: _titleAlign,
          contentAlign: _contentAlign,
          amountAlign: _amountAlign,
          stampAlign: _stampAlign,
          titleFontSize: _titleFontSize,
          amountFontSize: _amountFontSize,
          isBoldTitle: _isBoldTitle,
          isBoldAmount: _isBoldAmount,
          isCondensed: _isCondensed,
          stampType: _stampType,
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

  void _applyTemplateSampleData(ReceiptTemplate tpl) {
    setState(() {
      _selectedTemplate = tpl;
      _syncFormattingWithTemplate(tpl);
      if (tpl.sampleItems.isNotEmpty) {
        _isItemMode = true;
        _items.clear();
        _items.addAll(tpl.sampleItems);
      }
      if (tpl.samplePayer.isNotEmpty) _receivedFromController.text = tpl.samplePayer;
      if (tpl.sampleCustomerPhone.isNotEmpty) _customerPhoneController.text = tpl.sampleCustomerPhone;
      if (tpl.sampleCashier.isNotEmpty) _cashierNameController.text = tpl.sampleCashier;
      if (tpl.sampleDescription.isNotEmpty) _descriptionController.text = tpl.sampleDescription;
      if (tpl.sampleNotes.isNotEmpty) _notesController.text = tpl.sampleNotes;
      if (tpl.sampleDiscount > 0) {
        _discountController.text = CurrencyFormatter.format(tpl.sampleDiscount, withSymbol: false);
      } else {
        _discountController.text = '';
      }
      if (tpl.sampleTax > 0) {
        _taxController.text = CurrencyFormatter.format(tpl.sampleTax, withSymbol: false);
      } else {
        _taxController.text = '';
      }
      if (tpl.sampleCashReceived > 0) {
        _cashReceivedController.text = CurrencyFormatter.format(tpl.sampleCashReceived, withSymbol: false);
      } else {
        _cashReceivedController.text = '';
      }
    });
    CustomDialogs.showSuccessSnackBar(context, 'Contoh lengkap template "${tpl.name}" berhasil diterapkan!');
  }

  void _showTemplateSelectorModal() {
    String selectedCategory = 'Semua';
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final categories = ReceiptTemplate.categories;
          final filtered = ReceiptTemplate.allTemplates.where((t) {
            final matchCategory = selectedCategory == 'Semua' || t.category == selectedCategory;
            final matchSearch = searchQuery.isEmpty ||
                t.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                t.badge.toLowerCase().contains(searchQuery.toLowerCase());
            return matchCategory && matchSearch;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.45,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.style_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        const Text(
                          'Pilih Template Kwitansi (27 Model)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari template (supermarket, resto, bengkel, klinik...)',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setModalState(() => searchQuery = val),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: categories.map((cat) {
                        final isSel = selectedCategory == cat;
                        final isFeatured = cat.contains('Unggulan');
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat, style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: isFeatured ? const Color(0xFFFEF3C7) : AppColors.primary.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: isSel ? (isFeatured ? const Color(0xFFB45309) : AppColors.primary) : AppColors.secondaryText,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => setModalState(() => selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final tpl = filtered[index];
                        final isSelected = tpl.id == _selectedTemplate.id;
                        final hasSample = tpl.sampleItems.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (tpl.isFeatured ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : (tpl.isFeatured ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                              child: Icon(
                                tpl.icon,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : (tpl.isFeatured ? const Color(0xFFD97706) : const Color(0xFF475569)),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tpl.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? AppColors.primary : AppColors.text,
                                    ),
                                  ),
                                ),
                                if (tpl.badge.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tpl.isFeatured ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: tpl.isFeatured ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      tpl.badge,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: tpl.isFeatured ? const Color(0xFFB45309) : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  '${tpl.category} • ${tpl.description}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                ),
                                if (hasSample) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _applyTemplateSampleData(tpl);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome, size: 12, color: Color(0xFF059669)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Pilih + Muat Data Lengkap',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                                : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            onTap: () {
                              setState(() => _selectedTemplate = tpl);
                              _syncFormattingWithTemplate(tpl);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Receipt _buildLiveReceiptObject() {
    String desc = _descriptionController.text.trim();
    if (_isItemMode && desc.isEmpty) {
      desc = _items.map((i) => '${i.name} (x${i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity})').join(', ');
    }

    return Receipt(
      receiptNumber: _receiptNumberController.text.trim().isNotEmpty ? _receiptNumberController.text.trim() : 'AUD-DRAFT',
      date: _selectedDate,
      receivedFrom: _receivedFromController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isNotEmpty ? _customerPhoneController.text.trim() : null,
      cashierName: _cashierNameController.text.trim().isNotEmpty ? _cashierNameController.text.trim() : null,
      amount: _totalAmount,
      amountWords: _amountWords,
      description: desc,
      paymentMethod: _selectedPaymentMethod,
      status: _selectedStatus,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      templateId: _selectedTemplate.id,
      discount: _discount,
      tax: _tax,
      cashReceived: _cashReceived,
      changeAmount: _changeAmount,
      items: _isItemMode ? _items : [],
      storeName: _storeNameController.text.trim().isNotEmpty ? _storeNameController.text.trim() : null,
      storeAddress: _storeAddressController.text.trim().isNotEmpty ? _storeAddressController.text.trim() : null,
      storePhone: _storePhoneController.text.trim().isNotEmpty ? _storePhoneController.text.trim() : null,
      storeTagline: _storeTaglineController.text.trim().isNotEmpty ? _storeTaglineController.text.trim() : null,
      storeLegalId: _storeLegalIdController.text.trim().isNotEmpty ? _storeLegalIdController.text.trim() : null,
      logoPath: _logoPath,
      showLogo: _showLogo,
      showBarcode: _showBarcode,
      barcodeData: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
      headerAlign: _headerAlign,
      titleAlign: _titleAlign,
      contentAlign: _contentAlign,
      amountAlign: _amountAlign,
      stampAlign: _stampAlign,
      titleFontSize: _titleFontSize,
      amountFontSize: _amountFontSize,
      isBoldTitle: _isBoldTitle,
      isBoldAmount: _isBoldAmount,
      isCondensed: _isCondensed,
      stampType: _stampType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<ReceiptService>().company;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.editReceipt != null ? 'Edit Kwitansi' : 'Buat Kwitansi'),
        actions: [
          IconButton(
            tooltip: 'Simpan ke Riwayat',
            onPressed: _isSaving ? null : () => _saveReceipt(goToPreview: false),
            icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveReceipt(goToPreview: true),
            icon: const Icon(Icons.print_rounded, color: Colors.white, size: 18),
            label: const Text('CETAK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.72),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            const Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Formulir Data'),
            Tab(
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              text: 'Live Kertas (${CurrencyFormatter.format(_totalAmount)})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FORMULIR INPUT & IN-PLACE CONTROLS (Kept alive so form key & focus are safe)
          _KeepAliveWrapper(child: _buildFormTab()),

          // TAB 2: LIVE THERMAL RECEIPT CANVAS (Dynamically rebuilt so it is always in sync with form inputs)
          _buildLiveThermalCanvasTab(company),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomBar(),
    );
  }

  Widget _buildFormTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // 1. Template Active Banner
          _buildTemplateHeaderCard(),
          const SizedBox(height: 16),

          // 2. Identitas Toko / Usaha (Multi-Toko & Multi-Perusahaan)
          _buildStoreIdentityCard(),
          const SizedBox(height: 16),

          // 3. IN-PLACE DIRECT FORMATTING TOOLBAR (Font, Perataan, Ukuran langsung di sini!)
          _buildInPlaceFormatToolbar(),
          const SizedBox(height: 16),

          // 4. Info Transaksi & Pelanggan
          _buildTransactionMetaCard(),
          const SizedBox(height: 16),

          // 5. Mode Transaksi Switch: Mode Cepat vs Multi-Item
          _buildModeSwitchCard(),
          const SizedBox(height: 16),

          // 6. Konten Transaksi (Multi-Item Table ATAU Nominal Tunggal)
          if (_isItemMode) _buildItemsEditorSection() else _buildSingleAmountSection(),
          const SizedBox(height: 16),

          // 7. Kalkulator Kasir & Finansial (Diskon, Pajak, Tunai, Kembalian)
          _buildFinancialSummaryCard(),
          const SizedBox(height: 16),

          // 8. Catatan Tambahan & Rangkap
          _buildNotesAndPrintOptionsCard(),
          const SizedBox(height: 16),

          // 9. Banner Promo, Poin & Sosmed (Bisa dikosongkan langsung di sini!)
          _buildBannersAndCustomTextCard(),
        ],
      ),
    );
  }

  Widget _buildStoreIdentityCard() {
    final receiptService = context.watch<ReceiptService>();
    final companies = receiptService.companies;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identitas Toko / Usaha (Multi-Toko)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    Text(
                      'Pilih profil toko atau sesuaikan nama, slogan & kontak kwitansi ini secara fleksibel',
                      style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${companies.length} Toko',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal Store Selection Chips
          const Text(
            'PILIH PROFIL TOKO TERDAFTAR:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondaryText, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...companies.map((comp) {
                  final isSelected = _selectedCompanyId == comp.id ||
                      _storeNameController.text.trim().toLowerCase() == comp.name.trim().toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.store_mall_directory_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      label: Text(
                        comp.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (val) {
                        setState(() {
                          _selectedCompanyId = comp.id;
                          _storeNameController.text = comp.name;
                          _storeTaglineController.text = comp.tagline;
                          _storeAddressController.text = comp.address;
                          _storePhoneController.text = comp.phone;
                          if (comp.logo != null && comp.logo!.isNotEmpty) {
                            _logoPath = comp.logo;
                            _showLogo = true;
                          }
                          if (comp.signerName.isNotEmpty && _cashierNameController.text.isEmpty) {
                            _cashierNameController.text = comp.signerName;
                          }
                        });
                        receiptService.switchActiveCompany(comp);
                      },
                    ),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                  label: const Text('+ Toko Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  onPressed: () => _showAddStoreDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Store Name
          TextFormField(
            controller: _storeNameController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Nama Toko / Usaha',
              hintText: 'Contoh: TOKO BERKAH JAYA, AUDIRA MULTIMEDIA',
              prefixIcon: const Icon(Icons.business_rounded, size: 20),
              suffixIcon: _storeNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _storeNameController.clear(),
                      tooltip: 'Kosongkan',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Slogan / Tagline
          TextFormField(
            controller: _storeTaglineController,
            decoration: InputDecoration(
              labelText: 'Slogan / Tagline / Subtitle Toko (Opsional)',
              hintText: 'Contoh: Pusat Belanja Hemat, Coffee & Space',
              prefixIcon: const Icon(Icons.subtitles_outlined, size: 20),
              suffixIcon: _storeTaglineController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _storeTaglineController.clear(),
                      tooltip: 'Kosongkan',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // NPWP / Legal ID
          TextFormField(
            controller: _storeLegalIdController,
            decoration: InputDecoration(
              labelText: 'NPWP / NIB / Legalitas Usaha (Opsional)',
              hintText: 'Contoh: NPWP: 01.345.678.9-012.000',
              helperText: 'Biarkan kosong jika toko Anda tidak menggunakan NPWP',
              prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
              suffixIcon: _storeLegalIdController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _storeLegalIdController.clear(),
                      tooltip: 'Kosongkan',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Store Address
          TextFormField(
            controller: _storeAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Alamat Lengkap Toko (Opsional)',
              hintText: 'Contoh: Jl. Raya Sudirman No. 88, Jakarta Selatan',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              suffixIcon: _storeAddressController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _storeAddressController.clear(),
                      tooltip: 'Kosongkan',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Phone / CS
          TextFormField(
            controller: _storePhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'No. Telepon / WhatsApp CS Toko (Opsional)',
              hintText: 'Contoh: 0812-3456-7890 / CS: 1500-888',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
              suffixIcon: _storePhoneController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _storePhoneController.clear(),
                      tooltip: 'Kosongkan',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Action row: Save as New Profile or Clear All Header
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                  label: const Text('Simpan Profil Baru', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                  onPressed: () async {
                    final typedName = _storeNameController.text.trim();
                    if (typedName.isEmpty) {
                      CustomDialogs.showErrorSnackBar(context, 'Nama toko tidak boleh kosong untuk disimpan');
                      return;
                    }
                    try {
                      final newComp = Company(
                        name: typedName,
                        tagline: _storeTaglineController.text.trim(),
                        address: _storeAddressController.text.trim(),
                        phone: _storePhoneController.text.trim(),
                        email: '',
                        logo: _logoPath,
                        footerMessage: 'Terima kasih atas kunjungan Anda',
                      );
                      final savedComp = await receiptService.addCompany(newComp);
                      setState(() => _selectedCompanyId = savedComp.id);
                      if (mounted) {
                        CustomDialogs.showSuccessSnackBar(context, 'Profil toko "$typedName" berhasil disimpan!');
                      }
                    } catch (e) {
                      if (mounted) {
                        CustomDialogs.showErrorSnackBar(context, 'Gagal menyimpan profil toko: $e');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all_rounded, size: 16, color: Color(0xFFDC2626)),
                label: const Text('Kosongkan Header', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
                onPressed: () {
                  setState(() {
                    _storeNameController.clear();
                    _storeTaglineController.clear();
                    _storeLegalIdController.clear();
                    _storeAddressController.clear();
                    _storePhoneController.clear();
                    _selectedCompanyId = null;
                  });
                  CustomDialogs.showSuccessSnackBar(context, 'Header toko dikosongkan untuk kwitansi ini');
                },
              ),
            ],
          ),

          const Divider(height: 24, color: AppColors.border),

          // Logo Usaha & Kwitansi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logo Usaha & Struk',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
                      ),
                      Text(
                        'Upload logo kustom toko atau gunakan logo default',
                        style: TextStyle(fontSize: 10, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _showLogo,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _showLogo = val),
              ),
            ],
          ),

          if (_showLogo) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Center(
                        child: _logoPath != null && File(_logoPath!).existsSync()
                            ? Image.file(
                                File(_logoPath!),
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                              )
                            : (receiptService.company.logo != null && File(receiptService.company.logo!).existsSync()
                                ? Image.file(
                                    File(receiptService.company.logo!),
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.contain,
                                  )
                                : const AudiraLogoWidget(size: 32)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_logoPath != null && File(_logoPath!).existsSync())
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (_logoPath != null && File(_logoPath!).existsSync())
                                    ? 'Logo Kustom Aktif'
                                    : 'Logo Default AUDIRA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (_logoPath != null && File(_logoPath!).existsSync())
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.photo_library_outlined, size: 14),
                              label: Text(_logoPath != null ? 'Ganti' : 'Pilih Galeri'),
                              onPressed: () => _pickLogo(ImageSource.gallery),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                textStyle: const TextStyle(fontSize: 11),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.camera_alt_outlined, size: 14),
                              label: const Text('Kamera'),
                              onPressed: () => _pickLogo(ImageSource.camera),
                            ),
                            if (_logoPath != null)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                tooltip: 'Hapus Logo Kustom',
                                onPressed: _removeLogo,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24, color: AppColors.border),

          // Barcode 1D (Code128)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFB45309), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode 1D (CODE128)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
                      ),
                      Text(
                        'Cetak barcode scanning resi / struk kasir',
                        style: TextStyle(fontSize: 10, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _showBarcode,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _showBarcode = val),
              ),
            ],
          ),

          if (_showBarcode) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Nomor / Kode Barcode (Opsional)',
                hintText: 'Kosongkan untuk otomatis menggunakan nomor kwitansi',
                helperText: 'Barcode akan dicetak di struk thermal, PDF, & ditampilkan di layar',
                prefixIcon: const Icon(Icons.barcode_reader, size: 20),
                suffixIcon: _barcodeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => _barcodeController.clear(),
                        tooltip: 'Kosongkan (pakai no. kwitansi)',
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddStoreDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final taglineCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_business_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Tambah Profil Toko Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Daftarkan toko / usaha baru agar Anda bisa berganti identitas kwitansi kapan saja.',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko / Perusahaan *',
                  hintText: 'Contoh: TOKO ROTI AMANAH',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: taglineCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slogan / Tagline',
                  hintText: 'Contoh: Hangat, Segar & Terlengkap',
                  prefixIcon: Icon(Icons.subtitles_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat Toko',
                  hintText: 'Contoh: Jl. Pahlawan No. 10',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon / WA CS',
                  hintText: 'Contoh: 0812-3456-7890',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                CustomDialogs.showErrorSnackBar(ctx, 'Nama toko wajib diisi');
                return;
              }
              final newComp = Company(
                name: name,
                tagline: taglineCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: '',
                footerMessage: 'Terima kasih atas kunjungan Anda',
              );
              final receiptService = context.read<ReceiptService>();
              final saved = await receiptService.addCompany(newComp);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {
                _selectedCompanyId = saved.id;
                _storeNameController.text = saved.name;
                _storeTaglineController.text = saved.tagline;
                _storeAddressController.text = saved.address;
                _storePhoneController.text = saved.phone;
              });
              CustomDialogs.showSuccessSnackBar(context, 'Toko "$name" berhasil ditambahkan dan dipilih!');
            },
            child: const Text('Simpan Toko', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_selectedTemplate.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _selectedTemplate.isFeatured ? const Color(0xFFFEF3C7) : AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedTemplate.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _selectedTemplate.isFeatured ? const Color(0xFFB45309) : AppColors.primary,
                            ),
                          ),
                        ),
                        if (_selectedTemplate.badge.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedTemplate.isFeatured ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _selectedTemplate.isFeatured ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              _selectedTemplate.badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _selectedTemplate.isFeatured ? const Color(0xFFB45309) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedTemplate.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showTemplateSelectorModal,
                icon: const Icon(Icons.style_outlined, size: 15),
                label: const Text('Ganti', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTemplate.description,
            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_selectedTemplate.sampleItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  foregroundColor: const Color(0xFF065F46),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF059669)),
                label: Text(
                  'Muat Contoh Lengkap Template (${_selectedTemplate.sampleItems.length} Item)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _applyTemplateSampleData(_selectedTemplate),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInPlaceFormatToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.format_paint_rounded, color: AppColors.primary, size: 20),
          ),
          title: const Text(
            'Format Font & Perataan Kertas (Di Sini)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          subtitle: const Text(
            'Ubah rata kiri/tengah/kanan & ukuran font seketika',
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),

                  // 1. Perataan Header & Judul
                  const Text('Perataan Judul & Header:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'left', icon: Icon(Icons.format_align_left, size: 16), label: Text('Kiri')),
                      ButtonSegment(value: 'center', icon: Icon(Icons.format_align_center, size: 16), label: Text('Tengah')),
                      ButtonSegment(value: 'right', icon: Icon(Icons.format_align_right, size: 16), label: Text('Kanan')),
                    ],
                    selected: {_headerAlign},
                    onSelectionChanged: (val) {
                      setState(() {
                        _headerAlign = val.first;
                        _titleAlign = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Perataan Konten & Nominal
                  const Text('Perataan Nominal & Pembayar:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'left', icon: Icon(Icons.format_align_left, size: 16), label: Text('Kiri')),
                      ButtonSegment(value: 'center', icon: Icon(Icons.format_align_center, size: 16), label: Text('Tengah')),
                      ButtonSegment(value: 'right', icon: Icon(Icons.format_align_right, size: 16), label: Text('Kanan')),
                    ],
                    selected: {_amountAlign},
                    onSelectionChanged: (val) {
                      setState(() {
                        _amountAlign = val.first;
                        _contentAlign = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Ukuran Font Nominal
                  const Text('Ukuran Font Nominal Uang:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'normal', label: Text('Normal')),
                      ButtonSegment(value: 'large', label: Text('Besar (2x T)')),
                      ButtonSegment(value: 'extra_large', label: Text('Jumbo (2x L+T)')),
                    ],
                    selected: {_amountFontSize},
                    onSelectionChanged: (val) => setState(() => _amountFontSize = val.first),
                  ),
                  const SizedBox(height: 12),

                  // 4. Bold & Condensed Toggles
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Cetak Tebal (Bold)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          value: _isBoldAmount,
                          onChanged: (val) => setState(() {
                            _isBoldAmount = val;
                            _isBoldTitle = val;
                          }),
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Font Rapat (Font B)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          value: _isCondensed,
                          onChanged: (val) => setState(() => _isCondensed = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 5. Stempel Status Cetak
                  const Text('Stempel Cetak di Kertas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildStampChip('LUNAS', const Color(0xFF16A34A)),
                      _buildStampChip('DP / TITIPAN', const Color(0xFFD97706)),
                      _buildStampChip('LUNAS RESMI', const Color(0xFF2563EB)),
                      _buildStampChip('none', Colors.grey, label: 'Tanpa Stempel'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampChip(String value, Color color, {String? label}) {
    final isSel = _stampType == value;
    final displayLabel = label ?? value;
    return ChoiceChip(
      label: Text(displayLabel, style: const TextStyle(fontSize: 11)),
      selected: isSel,
      selectedColor: color.withOpacity(0.18),
      side: BorderSide(color: isSel ? color : const Color(0xFFCBD5E1)),
      labelStyle: TextStyle(
        color: isSel ? color : AppColors.secondaryText,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() {
        _stampType = value;
        if (value != 'none') _selectedStatus = value;
      }),
    );
  }

  Widget _buildTransactionMetaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Transaksi & Pelanggan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // No Kwitansi & Tanggal
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _receiptNumberController,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nomor Kwitansi *',
                    suffixIcon: _isLoadingNumber
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: _loadNextReceiptNumber,
                            tooltip: 'Generate No Baru',
                          ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    child: Text(
                      AppDateFormatter.formatShort(_selectedDate),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Diterima Dari (Nama Pelanggan) with Auto-Complete
          RawAutocomplete<String>(
            textEditingController: _receivedFromController,
            focusNode: _receivedFromFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return _customerSuggestions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) => _receivedFromController.text = selection,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Diterima Dari (Nama Pelanggan)',
                  hintText: 'Nama pelanggan (kosongkan jika tanpa nama)',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  suffixIcon: _receivedFromController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _receivedFromController.clear(),
                          tooltip: 'Kosongkan',
                        )
                      : null,
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 64,
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history, size: 16, color: AppColors.primary),
                          title: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // No WhatsApp & Nama Kasir
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'No. WhatsApp / HP',
                    hintText: '0812xxxx',
                    prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18),
                    suffixIcon: _customerPhoneController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => _customerPhoneController.clear(),
                            tooltip: 'Kosongkan',
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _cashierNameController,
                  decoration: InputDecoration(
                    labelText: 'Kasir / Petugas',
                    hintText: 'Nama kasir',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                    suffixIcon: _cashierNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => _cashierNameController.clear(),
                            tooltip: 'Kosongkan',
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitchCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Text('Mode Kwitansi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.monetization_on_outlined, size: 15),
                label: Text('Nominal Saja', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.table_chart_outlined, size: 15),
                label: Text('Rincian Item (POS)', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {_isItemMode},
            onSelectionChanged: (val) {
              setState(() {
                _isItemMode = val.first;
                if (_isItemMode && _items.isEmpty) {
                  _addItemDialog();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAmountSection() {
    final presets = ReceiptTemplate.getPresets(_selectedTemplate.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nominal Pembayaran Tunggal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              IndonesianCurrencyInputFormatter(),
            ],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'Jumlah Uang (Rp) *',
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              suffixIcon: _amountController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _amountController.clear(),
                    )
                  : null,
            ),
            validator: (val) {
              if (!_isItemMode) {
                if (val == null || val.trim().isEmpty) return 'Nominal wajib diisi';
                if (CurrencyFormatter.parse(val) <= 0) return 'Nominal harus lebih dari 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAmountChip('50 rb', 50000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('100 rb', 100000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('250 rb', 250000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('500 rb', 500000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('1 jt', 1000000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('2.5 jt', 2500000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('5 jt', 5000000),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Untuk Pembayaran
          const Text('Untuk Pembayaran / Keperluan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
          if (presets.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.add_circle_outline, size: 14, color: AppColors.primary),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onPressed: () => _descriptionController.text = p,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Contoh: Jasa Maintenance & Pembelian Suku Cadang',
            ),
            validator: (v) {
              if (!_isItemMode && (v == null || v.trim().isEmpty)) return 'Keterangan wajib diisi';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return InkWell(
      onTap: () {
        _amountController.text = CurrencyFormatter.format(amount, withSymbol: false);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
      ),
    );
  }

  Widget _buildItemsEditorSection() {
    final presets = ReceiptTemplate.getPresets(_selectedTemplate.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Rincian Item / Layanan (Tabel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                '${_items.length} Item',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Preset chip quick adds
          if (presets.isNotEmpty) ...[
            const Text('Tambah Cepat dari Rekomendasi Template:', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.add, size: 14, color: AppColors.primary),
                      backgroundColor: const Color(0xFFEFF6FF),
                      onPressed: () {
                        _addItemDialog(ReceiptItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: p,
                          quantity: 1,
                          unitPrice: 50000,
                        ));
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Items List
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.add_shopping_cart_rounded, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  const Text('Belum ada item ditambahkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addItemDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Input Manual'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _selectFromCatalog,
                        icon: const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.white),
                        label: const Text('Pilih dari Katalog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = _items[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${CurrencyFormatter.format(item.unitPrice)} = ${CurrencyFormatter.format(item.subtotal)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        onPressed: () => _addItemDialog(item, idx),
                        tooltip: 'Edit Item',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _items.removeAt(idx)),
                        tooltip: 'Hapus Item',
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addItemDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Input Manual'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectFromCatalog,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white),
                    label: const Text('Dari Katalog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kalkulasi Finansial & Kasir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal Transaksi', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              Text(
                CurrencyFormatter.format(_subtotal),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Diskon & Pajak Inputs with Quick Percentage Calculators
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        IndonesianCurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Diskon (Rp)',
                        hintText: '0',
                        prefixText: '- ',
                        prefixStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPercentChip('5%', () {
                            final d = (_subtotal * 0.05).roundToDouble();
                            _discountController.text = CurrencyFormatter.format(d, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('10%', () {
                            final d = (_subtotal * 0.10).roundToDouble();
                            _discountController.text = CurrencyFormatter.format(d, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('15%', () {
                            final d = (_subtotal * 0.15).roundToDouble();
                            _discountController.text = CurrencyFormatter.format(d, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('20%', () {
                            final d = (_subtotal * 0.20).roundToDouble();
                            _discountController.text = CurrencyFormatter.format(d, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('% Custom', () {
                            _showCustomPercentDialog(
                              title: 'Diskon Kustom (%)',
                              onApply: (pct) {
                                final d = (_subtotal * (pct / 100)).roundToDouble();
                                _discountController.text = CurrencyFormatter.format(d, withSymbol: false);
                              },
                            );
                          }),
                          if (_discount > 0) ...[
                            const SizedBox(width: 4),
                            _buildPercentChip('Hapus', () => _discountController.text = '', isReset: true),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        IndonesianCurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Pajak (Rp)',
                        hintText: '0',
                        prefixText: '+ ',
                        prefixStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPercentChip('PPN 11%', () {
                            final t = (_subtotal * 0.11).roundToDouble();
                            _taxController.text = CurrencyFormatter.format(t, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('PPN 12%', () {
                            final t = (_subtotal * 0.12).roundToDouble();
                            _taxController.text = CurrencyFormatter.format(t, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('PB1 10%', () {
                            final t = (_subtotal * 0.10).roundToDouble();
                            _taxController.text = CurrencyFormatter.format(t, withSymbol: false);
                          }),
                          const SizedBox(width: 4),
                          _buildPercentChip('% Custom', () {
                            _showCustomPercentDialog(
                              title: 'Pajak Kustom (%)',
                              onApply: (pct) {
                                final t = (_subtotal * (pct / 100)).roundToDouble();
                                _taxController.text = CurrencyFormatter.format(t, withSymbol: false);
                              },
                            );
                          }),
                          if (_tax > 0) ...[
                            const SizedBox(width: 4),
                            _buildPercentChip('Hapus', () => _taxController.text = '', isReset: true),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TOTAL AKHIR (Highlight Card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL AKHIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Wajib Dibayar', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(_totalAmount),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Terbilang Text Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, size: 16, color: Color(0xFF166534)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _amountWords,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Metode Pembayaran
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(
              labelText: 'Metode Pembayaran',
              prefixIcon: Icon(Icons.payment_rounded, size: 18),
            ),
            items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPaymentMethod = val);
            },
          ),
          const SizedBox(height: 12),

          // Tunai / Cash & Kembalian
          if (_selectedPaymentMethod.toLowerCase().contains('tunai') || _selectedPaymentMethod.toLowerCase().contains('cash')) ...[
            TextFormField(
              controller: _cashReceivedController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                IndonesianCurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Uang Tunai Diterima (Rp)',
                hintText: 'Misal: 100.000',
                prefixText: 'Rp ',
                suffixIcon: TextButton(
                  onPressed: () {
                    _cashReceivedController.text = CurrencyFormatter.format(_totalAmount, withSymbol: false);
                  },
                  child: const Text('Uang Pas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            if (_changeAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('UANG KEMBALIAN:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    Text(
                      CurrencyFormatter.format(_changeAmount),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNotesAndPrintOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan & Rangkap Cetak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Catatan Tambahan (Opsional)',
              hintText: 'Misal: Garansi perbaikan 14 hari kerja',
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
              suffixIcon: _notesController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _notesController.clear(),
                      tooltip: 'Kosongkan',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jumlah Cetak (Rangkap)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: _printCopies > 1 ? () => setState(() => _printCopies--) : null,
                    ),
                    Text('$_printCopies', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => setState(() => _printCopies++),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannersAndCustomTextCard() {
    final hasAnyBanner = _memberRewardController.text.isNotEmpty ||
        _promoBannerController.text.isNotEmpty ||
        _socialMediaController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasAnyBanner,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_outlined, color: AppColors.warning, size: 20),
          ),
          title: const Text('Banner Promo, Poin & Sosmed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(
            hasAnyBanner ? 'Teks aktif ditampilkan di struk' : 'Kosong (tidak tampil di struk)',
            style: TextStyle(fontSize: 11, color: hasAnyBanner ? Colors.green.shade700 : AppColors.secondaryText),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  if (hasAnyBanner) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _memberRewardController.clear();
                            _promoBannerController.clear();
                            _socialMediaController.clear();
                          });
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                        label: const Text('Kosongkan Semua Banner', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  TextFormField(
                    controller: _memberRewardController,
                    decoration: InputDecoration(
                      labelText: 'Reward Poin / Member (Opsional)',
                      hintText: 'Contoh: ★ Reward Poin: +15 Poin ★',
                      prefixIcon: const Icon(Icons.stars_outlined, size: 18),
                      suffixIcon: _memberRewardController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => _memberRewardController.clear(),
                              tooltip: 'Kosongkan',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _promoBannerController,
                    decoration: InputDecoration(
                      labelText: 'Banner Promo Bawah (Opsional)',
                      hintText: 'Contoh: Promo Diskon 10% s/d Akhir Bulan!',
                      prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                      suffixIcon: _promoBannerController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => _promoBannerController.clear(),
                              tooltip: 'Kosongkan',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _socialMediaController,
                    decoration: InputDecoration(
                      labelText: 'Sosial Media / Website (Opsional)',
                      hintText: 'Contoh: IG: @toko_anda | Web: www.toko.com',
                      prefixIcon: const Icon(Icons.public_outlined, size: 18),
                      suffixIcon: _socialMediaController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => _socialMediaController.clear(),
                              tooltip: 'Kosongkan',
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveThermalCanvasTab(Company company) {
    final liveReceipt = _buildLiveReceiptObject();
    final config = context.watch<ReceiptService>().getTemplateConfig(_selectedTemplate.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Center(
        child: ThermalTicketContainer(
          maxWidth: 340,
          stampText: _stampType == 'none' ? null : _stampType,
          stampColor: _stampType == 'LUNAS' ? const Color(0xFF16A34A) : (_stampType == 'DP' ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Toko / Usaha
              if (_showLogo) ...[
                Align(
                  alignment: _headerAlign == 'center' ? Alignment.center : (_headerAlign == 'right' ? Alignment.centerRight : Alignment.centerLeft),
                  child: Builder(
                    builder: (context) {
                      final customLogo = _logoPath ?? company.logo;
                      if (customLogo != null && customLogo.isNotEmpty) {
                        final file = File(customLogo);
                        if (file.existsSync()) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Image.file(
                              file,
                              height: 44,
                              fit: BoxFit.contain,
                            ),
                          );
                        }
                      }
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: AudiraLogoWidget(size: 36),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 2),
              ],

              // Header Toko (Sinkron Langsung dari Form Identitas Toko)
              if (_storeNameController.text.trim().isNotEmpty)
                Text(
                  _storeNameController.text.trim().toUpperCase(),
                  textAlign: _headerAlign == 'center' ? TextAlign.center : (_headerAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w900),
                ),
              if (_storeTaglineController.text.trim().isNotEmpty)
                Text(
                  _storeTaglineController.text.trim(),
                  textAlign: _headerAlign == 'center' ? TextAlign.center : (_headerAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black54),
                ),
              if (_storeLegalIdController.text.trim().isNotEmpty)
                Text(
                  _storeLegalIdController.text.trim(),
                  textAlign: _headerAlign == 'center' ? TextAlign.center : (_headerAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold),
                ),
              if (_storeAddressController.text.trim().isNotEmpty)
                Text(
                  _storeAddressController.text.trim(),
                  textAlign: _headerAlign == 'center' ? TextAlign.center : (_headerAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9),
                ),
              if (_storePhoneController.text.trim().isNotEmpty)
                Text(
                  _storePhoneController.text.trim().startsWith('Telp') || _storePhoneController.text.trim().startsWith('CS')
                      ? _storePhoneController.text.trim()
                      : 'Telp: ${_storePhoneController.text.trim()}',
                  textAlign: _headerAlign == 'center' ? TextAlign.center : (_headerAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9),
                ),
              const SizedBox(height: 8),
              _buildDashedLine(char: '='),
              const SizedBox(height: 8),

              // Judul & Stempel
              Text(
                config.customTitle.isNotEmpty ? config.customTitle : _selectedTemplate.titleHeading,
                textAlign: _titleAlign == 'center' ? TextAlign.center : (_titleAlign == 'right' ? TextAlign.right : TextAlign.left),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _titleFontSize == 'extra_large' ? 18 : (_titleFontSize == 'large' ? 15 : 13),
                  fontWeight: _isBoldTitle ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              if (_stampType != 'none') ...[
                const SizedBox(height: 4),
                Align(
                  alignment: _stampAlign == 'center' ? Alignment.center : (_stampAlign == 'right' ? Alignment.centerRight : Alignment.centerLeft),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (_stampType == 'LUNAS' ? const Color(0xFF16A34A) : Colors.orange).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: (_stampType == 'LUNAS' ? const Color(0xFF16A34A) : Colors.orange).withOpacity(0.4)),
                    ),
                    child: Text(
                      _stampType,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _stampType == 'LUNAS' ? const Color(0xFF16A34A) : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _buildDashedLine(char: '-'),
              const SizedBox(height: 8),

              // Meta (Leher)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('No : ${liveReceipt.receiptNumber}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                  Text(liveReceipt.dateFormatted, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                ],
              ),
              if (liveReceipt.cashierName != null && liveReceipt.cashierName!.isNotEmpty)
                Text('Kasir: ${liveReceipt.cashierName}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),

              // Custom Leher Fields
              if (config.leherField1Label.isNotEmpty && config.leherField1Value.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${config.leherField1Label}:', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(config.leherField1Value, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (config.leherField2Label.isNotEmpty && config.leherField2Value.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${config.leherField2Label}:', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                    Text(config.leherField2Value, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                  ],
                ),
              if (config.leherField3Label.isNotEmpty && config.leherField3Value.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${config.leherField3Label}:', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                    Text(config.leherField3Value, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                  ],
                ),
              const SizedBox(height: 8),
              _buildDashedLine(char: '-'),
              const SizedBox(height: 8),

              // Pembayar (Hanya tampil jika nama pembayar atau nomor telepon diisi!)
              if (liveReceipt.receivedFrom.isNotEmpty || (liveReceipt.customerPhone != null && liveReceipt.customerPhone!.isNotEmpty)) ...[
                Text(
                  'Telah diterima dari:',
                  textAlign: _contentAlign == 'center' ? TextAlign.center : (_contentAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54),
                ),
                Text(
                  '${liveReceipt.receivedFrom.isNotEmpty ? liveReceipt.receivedFrom.toUpperCase() : ''}${liveReceipt.customerPhone != null && liveReceipt.customerPhone!.isNotEmpty ? (liveReceipt.receivedFrom.isNotEmpty ? ' (${liveReceipt.customerPhone})' : liveReceipt.customerPhone!) : ''}',
                  textAlign: _contentAlign == 'center' ? TextAlign.center : (_contentAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: _isBoldAmount ? FontWeight.w900 : FontWeight.bold),
                ),
                const SizedBox(height: 10),
              ],

              // Multi-Item Table atau Single Amount
              if (_isItemMode && _items.isNotEmpty) ...[
                _buildDashedLine(char: '-'),
                const SizedBox(height: 6),
                for (final it in _items) ...[
                  Text(it.name, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('  ${it.quantity % 1 == 0 ? it.quantity.toInt() : it.quantity} x ${CurrencyFormatter.format(it.unitPrice, withSymbol: false)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54)),
                      Text(CurrencyFormatter.format(it.subtotal), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                const SizedBox(height: 6),
                _buildDashedLine(char: '-'),
                const SizedBox(height: 6),
                if (_discount > 0 || _tax > 0 || config.serviceChargeAmount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontFamily: 'monospace', fontSize: 10)),
                      Text(CurrencyFormatter.format(_itemsSubtotal), style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                    ],
                  ),
                  if (_discount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.red)),
                        Text('-${CurrencyFormatter.format(_discount)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.red)),
                      ],
                    ),
                  if (config.serviceChargeAmount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(config.serviceChargeLabel.isNotEmpty ? config.serviceChargeLabel : 'Layanan', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                        Text('+${CurrencyFormatter.format(config.serviceChargeAmount)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                      ],
                    ),
                  if (_tax > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (PPN)', style: TextStyle(fontFamily: 'monospace', fontSize: 10)),
                        Text('+${CurrencyFormatter.format(_tax)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  _buildDashedLine(char: '-'),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900)),
                    Text(
                      CurrencyFormatter.format(_totalAmount + config.serviceChargeAmount),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _amountFontSize == 'extra_large' ? 18 : (_amountFontSize == 'large' ? 15 : 13),
                        fontWeight: _isBoldAmount ? FontWeight.w900 : FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (_cashReceived > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TUNAI', style: TextStyle(fontFamily: 'monospace', fontSize: 10)),
                      Text(CurrencyFormatter.format(_cashReceived), style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('KEMBALIAN', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(
                        CurrencyFormatter.format((_cashReceived > (_totalAmount + config.serviceChargeAmount)) ? _cashReceived - (_totalAmount + config.serviceChargeAmount) : 0),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                Text(
                  'Uang Sejumlah:',
                  textAlign: _amountAlign == 'center' ? TextAlign.center : (_amountAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54),
                ),
                Text(
                  CurrencyFormatter.format(_totalAmount),
                  textAlign: _amountAlign == 'center' ? TextAlign.center : (_amountAlign == 'right' ? TextAlign.right : TextAlign.left),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _amountFontSize == 'extra_large' ? 20 : (_amountFontSize == 'large' ? 17 : 14),
                    fontWeight: _isBoldAmount ? FontWeight.w900 : FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Terbilang
              Text(
                'Terbilang: "$_amountWords"',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
              const SizedBox(height: 6),

              if (liveReceipt.description.isNotEmpty) ...[
                Text('Untuk: ${liveReceipt.description}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                const SizedBox(height: 6),
              ],

              Text('Metode: ${liveReceipt.paymentMethod}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              if (liveReceipt.notes != null && liveReceipt.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Catatan: ${liveReceipt.notes}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ],

              if (_memberRewardController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '[ ${_memberRewardController.text.trim()} ]',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ),
              ],

              if (config.guaranteePolicy.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('🛡️ Garansi: ${config.guaranteePolicy}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF1E40AF))),
              ],

              if (config.wifiInfo.isNotEmpty || _socialMediaController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                if (config.wifiInfo.isNotEmpty)
                  Text('📶 WiFi: ${config.wifiInfo}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 9)),
                if (_socialMediaController.text.trim().isNotEmpty)
                  Text(_socialMediaController.text.trim(), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black54)),
              ],

              if (_promoBannerController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('★ ${_promoBannerController.text.trim()}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF9D174D))),
              ],

              // Barcode Visual (1D CODE128)
              if (_showBarcode) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            28,
                            (i) => Container(
                              width: (i % 4 == 0) ? 2.8 : ((i % 2 == 0) ? 1.5 : 1.0),
                              height: 26,
                              margin: const EdgeInsets.symmetric(horizontal: 1.0),
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _barcodeController.text.trim().isNotEmpty
                              ? _barcodeController.text.trim()
                              : liveReceipt.receiptNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              const SizedBox(height: 10),
              _buildDashedLine(char: '-'),
              const SizedBox(height: 10),

              // Footer
              Text(
                company.footerMessage.isNotEmpty ? company.footerMessage : 'Terima Kasih atas Kunjungan Anda',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('*** LUNAS ***', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedLine({String char = '-'}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 7).floor();
        return Text(char * count, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black38));
      },
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('Total: ', style: TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
                      Flexible(
                        child: Text(
                          CurrencyFormatter.format(_totalAmount),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final target = _tabController.index == 0 ? 1 : 0;
                    _tabController.animateTo(target);
                  },
                  tooltip: _tabController.index == 0 ? 'Lihat Kertas Struk' : 'Kembali ke Formulir',
                  icon: Icon(_tabController.index == 0 ? Icons.receipt_long : Icons.edit_note, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _saveReceipt(goToPreview: false),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                    label: const Text('Simpan Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveReceipt(goToPreview: true),
                    icon: const Icon(Icons.print_rounded, size: 17),
                    label: const Text('Simpan & Cetak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
