import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../domain/providers/product_provider.dart';
import '../../widgets/common/widgets.dart';

// ─── My Products Screen ───────────────────────────────────────────────────────

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final list = prov.myProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AppTextField(
            hint: 'Search products...',
            prefix:
                const Icon(Icons.search, size: 20, color: AppColors.textHint),
            onChanged: prov.setSearch,
          ),
        ),
        // Status chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            _Chip('Active ${prov.activeCount}', AppColors.success),
            const SizedBox(width: 8),
            _Chip('Low Stock ${prov.lowStockCount}', AppColors.warning),
            const SizedBox(width: 8),
            _Chip('Out ${prov.outCount}', AppColors.error),
          ]),
        ),
        Expanded(
          child: prov.loadingMine
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : list.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Products Yet',
                      subtitle: 'Tap + to add your first product',
                      buttonLabel: 'Add Product',
                      onButton: () =>
                          Navigator.pushNamed(context, AppRoutes.addProduct),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ProductCard(product: list[i]),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(product.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                StatusBadge(
                  label: product.stockStatus,
                  color: product.stockQuantity == 0
                      ? AppColors.error
                      : product.stockQuantity < 5
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                'Price: ${product.formattedPrice}   '
                'Stock: ${product.stockQuantity}   '
                'Category: ${product.category}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(children: [
                _Btn(
                    'Edit',
                    AppColors.info,
                    () => Navigator.pushNamed(context, AppRoutes.editProduct,
                        arguments: product)),
                const SizedBox(width: 8),
                _Btn('Delete', AppColors.error,
                    () => _confirmDelete(context, product)),
                const SizedBox(width: 8),
                _Btn(
                    'View',
                    AppColors.primary,
                    () => Navigator.pushNamed(context, AppRoutes.productDetail,
                        arguments: product)),
              ]),
            ],
          ),
        ),
      );

  void _confirmDelete(BuildContext ctx, ProductModel p) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded,
              size: 48, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text('Delete Product?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uid = ctx.read<AuthProvider>().user?.uid ?? '';
                  final ok = await ctx
                      .read<ProductProvider>()
                      .deleteProduct(p.id, uid);

                  if (!ctx.mounted) return;

                  if (ok) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    final error = ctx.read<ProductProvider>().error ??
                        'Failed to delete product';
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    ctx.read<ProductProvider>().clearError();
                  }
                },
                child: const Text('Delete'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ),
      );
}

// ─── Add Product Screen ───────────────────────────────────────────────────────

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _desc = TextEditingController();
  String _cat = kCategories.first;
  bool _isExpense = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final product = ProductModel(
        id: const Uuid().v4(),
        ownerId: user.uid,
        ownerName: user.fullName,
        shopName: user.shopName.isNotEmpty
            ? user.shopName
            : "${user.fullName}'s Shop",
        name: _name.text.trim(),
        category: _cat,
        price: double.parse(_price.text),
        stockQuantity: int.parse(_stock.text),
        description: _desc.text.trim(),
        imageUrls: const [],
        isExpense: _isExpense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final ok = await context.read<ProductProvider>().addProduct(product);
      if (!mounted) return;
      setState(() => _saving = false);

      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final error =
            context.read<ProductProvider>().error ?? 'Failed to save product';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<ProductProvider>().clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Add Product')),
        body: LoadingOverlay(
          loading: _saving,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _lbl('Product Name'),
                  AppTextField(
                    hint: 'e.g. Fresh Organic Tomatoes',
                    controller: _name,
                    validator: (v) => Validators.required(v, 'Product name'),
                  ),
                  const SizedBox(height: 16),
                  _lbl('Category'),
                  DropdownButtonFormField<String>(
                    initialValue: _cat,
                    decoration: _dropDeco(),
                    items: kCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _cat = v!),
                  ),
                  const SizedBox(height: 16),
                  _lbl('Price (RWF)'),
                  AppTextField(
                    hint: '0',
                    controller: _price,
                    keyboardType: TextInputType.number,
                    validator: Validators.price,
                  ),
                  const SizedBox(height: 16),
                  _lbl('Stock Quantity'),
                  AppTextField(
                    hint: '0',
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    validator: Validators.quantity,
                  ),
                  const SizedBox(height: 16),
                  _lbl('Description (optional)'),
                  AppTextField(
                    hint: 'Describe your product...',
                    controller: _desc,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  // Image placeholder row
                  _lbl('Product Images'),
                  Row(
                      children: List.generate(
                          3,
                          (i) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.inputBorder),
                                  ),
                                  child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.textHint),
                                ),
                              ))),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('This is an expense'),
                    value: _isExpense,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isExpense = v ?? false),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: AppButton(
                          label: 'Save Product',
                          onPressed: _save,
                          isLoading: _saving),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                          label: 'Cancel',
                          outlined: true,
                          onPressed: () => Navigator.pop(context)),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  InputDecoration _dropDeco() => InputDecoration(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      );
}

// ─── Edit Product Screen ──────────────────────────────────────────────────────

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _name, _price, _stock, _desc;
  late String _cat;
  final _form = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product.name);
    _price =
        TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _stock =
        TextEditingController(text: widget.product.stockQuantity.toString());
    _desc = TextEditingController(text: widget.product.description);
    _cat = kCategories.contains(widget.product.category)
        ? widget.product.category
        : kCategories.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final ok = await context.read<ProductProvider>().updateProduct(
        widget.product.id,
        {
          'name': _name.text.trim(),
          'category': _cat,
          'price': double.parse(_price.text),
          'stockQuantity': int.parse(_stock.text),
          'description': _desc.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() => _saving = false);

      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final error =
            context.read<ProductProvider>().error ?? 'Failed to update product';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<ProductProvider>().clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Edit Product')),
        body: LoadingOverlay(
          loading: _saving,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Center(
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image,
                            size: 40, color: AppColors.textHint),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('⊕ Change Image',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 20),
                  _lbl('Product Name'),
                  AppTextField(
                      hint: '',
                      controller: _name,
                      validator: (v) => Validators.required(v, 'Name')),
                  const SizedBox(height: 14),
                  _lbl('Price (RWF)'),
                  AppTextField(
                      hint: '',
                      controller: _price,
                      keyboardType: TextInputType.number,
                      validator: Validators.price),
                  const SizedBox(height: 14),
                  _lbl('Category'),
                  DropdownButtonFormField<String>(
                    initialValue: _cat,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                    items: kCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _cat = v!),
                  ),
                  const SizedBox(height: 14),
                  _lbl('Description'),
                  AppTextField(hint: '', controller: _desc, maxLines: 3),
                  const SizedBox(height: 14),
                  _lbl('Quantity Available'),
                  Row(children: [
                    _StepBtn('−', () {
                      final v = int.tryParse(_stock.text) ?? 0;
                      if (v > 0) _stock.text = (v - 1).toString();
                    }),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AppTextField(
                          hint: '0',
                          controller: _stock,
                          keyboardType: TextInputType.number,
                          validator: Validators.quantity,
                        ),
                      ),
                    ),
                    _StepBtn('+', () {
                      final v = int.tryParse(_stock.text) ?? 0;
                      _stock.text = (v + 1).toString();
                    }),
                  ]),
                  const SizedBox(height: 28),
                  AppButton(
                      label: 'Save Changes',
                      onPressed: _save,
                      isLoading: _saving),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white))),
        ),
      );
}

// ─── Product Detail Screen ────────────────────────────────────────────────────

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartProvider>();
    final inCart = cart.quantityOf(p.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
            if (cart.itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle),
                  child: Center(
                      child: Text('${cart.itemCount}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                ),
              ),
          ]),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: p.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(p.imageUrls.first, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Text('Product Image',
                        style: TextStyle(color: Colors.white, fontSize: 16))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const Text(' 4.8 (124 reviews)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            if (inCart > 0)
              StatusBadge(label: 'In cart: $inCart', color: AppColors.success),
          ]),
          const SizedBox(height: 6),
          Text(p.name,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(p.formattedPrice,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error)),
          const SizedBox(height: 16),
          // Details card
          Card(
              child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _row('Category:', p.category),
              _row('Stock:', '${p.stockQuantity} units'),
              _row('Shop:', p.shopName.isNotEmpty ? p.shopName : 'N/A'),
              if (p.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(p.description,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
            ]),
          )),
          const SizedBox(height: 16),
          // Qty stepper
          const Text('Quantity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            _QBtn('−', () {
              if (_qty > 1) setState(() => _qty--);
            }),
            const SizedBox(width: 16),
            Text('$_qty',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
            _QBtn('+', () {
              if (_qty < p.stockQuantity) setState(() => _qty++);
            }),
          ]),
          const SizedBox(height: 24),
          AppButton(
            label: 'ADD TO CART',
            onPressed: p.inStock
                ? () {
                    final cart = context.read<CartProvider>();
                    bool added = false;
                    for (var i = 0; i < _qty; i++) {
                      if (!cart.addItem(p)) break;
                      added = true;
                    }
                    if (added) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p.name} added to cart!')));
                    }
                  }
                : null,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'BUY NOW',
            color: AppColors.error,
            onPressed: p.inStock
                ? () {
                    final cart = context.read<CartProvider>();
                    for (var i = 0; i < _qty; i++) {
                      cart.addItem(p);
                    }
                    Navigator.pushNamed(context, AppRoutes.cart);
                  }
                : null,
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 80,
              child: Text(l,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _QBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600))),
        ),
      );
}
