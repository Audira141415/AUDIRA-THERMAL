import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/receipt_service.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/models/product.dart';
import 'package:audira_receipt/widgets/custom_dialogs.dart';

class ProductCatalogPage extends StatefulWidget {
  final bool isSelectionMode;

  const ProductCatalogPage({super.key, this.isSelectionMode = false});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() {
      context.read<ReceiptService>().refreshProducts(
        query: _searchController.text,
        category: _selectedCategory == 'Semua' ? null : _selectedCategory,
      );
    });
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<ReceiptService>().getProductCategories();
    if (mounted) {
      setState(() {
        _categories = ['Semua', ...cats.where((c) => c != 'Semua')];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditProductDialog([Product? editProduct]) {
    final nameCtrl = TextEditingController(text: editProduct?.name ?? '');
    final codeCtrl = TextEditingController(text: editProduct?.code ?? '');
    final priceCtrl = TextEditingController(
      text: editProduct != null ? CurrencyFormatter.format(editProduct.unitPrice, withSymbol: false) : '',
    );
    String category = editProduct?.category ?? 'Umum';

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            editProduct != null ? 'Edit Produk / Jasa' : 'Tambah Produk / Jasa',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nama Barang / Jasa *',
                      hintText: 'Misal: Kopi Susu / Jasa Print',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      IndonesianCurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Harga Satuan (Rp) *',
                      hintText: '15.000',
                    ),
                    validator: (v) {
                      final parsed = CurrencyFormatter.parse(v ?? '');
                      if (parsed <= 0) return 'Harga harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kode / SKU (Opsional)',
                      hintText: 'Misal: BRG-001',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: ['Umum', 'Barang', 'Jasa', 'Makanan', 'Minuman', 'Elektronik', 'Lainnya']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                ],
              ),
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
                if (formKey.currentState?.validate() != true) return;
                final svc = context.read<ReceiptService>();
                final price = CurrencyFormatter.parse(priceCtrl.text);
                final msg = editProduct != null ? 'Produk berhasil diperbarui' : 'Produk berhasil ditambahkan';

                if (editProduct != null) {
                  await svc.updateProduct(editProduct.copyWith(
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                    unitPrice: price,
                    category: category,
                    updatedAt: DateTime.now(),
                  ));
                } else {
                  await svc.addProduct(
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                    unitPrice: price,
                    category: category,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadCategories();
                if (mounted) {
                  CustomDialogs.showSuccessSnackBar(context, msg);
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(Product product) async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context: context,
      title: 'Hapus Produk',
      message: 'Hapus "${product.name}" dari katalog produk?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed && product.id != null && mounted) {
      await context.read<ReceiptService>().deleteProduct(product.id!);
      await _loadCategories();
      if (mounted) CustomDialogs.showSuccessSnackBar(context, 'Produk dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptService = context.watch<ReceiptService>();
    final products = receiptService.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Pilih Produk dari Katalog' : 'Katalog Produk & Jasa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Produk',
            onPressed: () => _showAddEditProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode produk...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.primary : AppColors.secondaryText,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        context.read<ReceiptService>().refreshProducts(
                          query: _searchController.text,
                          category: cat == 'Semua' ? null : cat,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Product List
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada produk di katalog',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ketuk tombol + untuk menambahkan produk atau jasa pertama',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => _showAddEditProductDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Tambah Produk Baru'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Icon(
                              p.category == 'Jasa'
                                  ? Icons.build_outlined
                                  : (p.category == 'Makanan' || p.category == 'Minuman'
                                      ? Icons.restaurant_outlined
                                      : Icons.shopping_bag_outlined),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(p.unitPrice),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              if (p.code != null && p.code!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.code!,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.secondaryText),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                p.category,
                                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                          trailing: widget.isSelectionMode
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => Navigator.pop(context, p),
                                  child: const Text('PILIH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondaryText),
                                      onPressed: () => _showAddEditProductDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                      onPressed: () => _handleDelete(p),
                                    ),
                                  ],
                                ),
                          onTap: widget.isSelectionMode ? () => Navigator.pop(context, p) : () => _showAddEditProductDialog(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}
