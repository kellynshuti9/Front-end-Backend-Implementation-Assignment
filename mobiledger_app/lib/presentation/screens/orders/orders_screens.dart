import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/credit_model.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../domain/providers/order_credit_providers.dart';
import '../../widgets/common/widgets.dart';

// ─── Cart Screen ──────────────────────────────────────────────────────────────

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is Empty',
              subtitle: 'Browse shops and add products',
              buttonLabel: 'Browse',
              onButton: () => Navigator.pop(context),
            )
          : Column(children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Card(
                        child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: AppColors.primary, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(item.product.formattedPrice,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Row(children: [
                              _QtyBtn(
                                  '−', () => cart.decrement(item.product.id)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('${item.quantity}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ),
                              _QtyBtn('+', () => cart.addItem(item.product)),
                            ]),
                          ],
                        )),
                        Column(children: [
                          Text('${item.lineTotal.toStringAsFixed(0)} RWF',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => cart.remove(item.product.id),
                            child: const Text('Remove',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.error)),
                          ),
                        ]),
                      ]),
                    ));
                  },
                ),
              ),
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
                ),
                child: Column(children: [
                  const Text('ORDER SUMMARY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  _SummaryRow(
                      'Subtotal', '${cart.subtotal.toStringAsFixed(0)} RWF'),
                  _SummaryRow('Delivery Fee',
                      '${cart.deliveryFee.toStringAsFixed(0)} RWF'),
                  const _SummaryRow('Discount', '0 RWF'),
                  const Divider(),
                  _SummaryRow('TOTAL', '${cart.total.toStringAsFixed(0)} RWF',
                      bold: true),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'PROCEED TO CHECKOUT',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.checkout),
                  ),
                ]),
              ),
            ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QtyBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)))),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      );
}

// ─── Checkout Screen ──────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addrCtrl = TextEditingController(text: 'KG 7, Kigali, Rwanda');
  int _pmIdx = 0;
  bool _placing = false;
  final _methods = [
    'Mobile Money (MTN/Airtel)',
    'Credit / Debit Card',
    'Cash on Delivery',
  ];

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    setState(() => _placing = true);
    final cart = context.read<CartProvider>();
    final user = context.read<AuthProvider>().user!;
    final items = cart.items
        .map((ci) => OrderItem(
              productId: ci.product.id,
              productName: ci.product.name,
              quantity: ci.quantity,
              unitPrice: ci.product.price,
            ))
        .toList();

    final order = OrderModel(
      id: const Uuid().v4(),
      buyerId: user.uid,
      items: items,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      deliveryAddress: _addrCtrl.text,
      paymentMethod: _methods[_pmIdx],
      status: OrderStatus.active,
      createdAt: DateTime.now(),
    );
    final id = await context.read<OrderProvider>().placeOrder(order);
    cart.clear();
    if (!mounted) return;
    setState(() => _placing = false);
    if (id != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.orderConfirm,
          arguments: order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: LoadingOverlay(
        loading: _placing,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sec('DELIVERY ADDRESS'),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.read<AuthProvider>().user?.fullName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _addrCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Delivery address',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ]),
            )),
            const SizedBox(height: 16),
            _sec('PAYMENT METHOD'),
            Card(
                child: Column(
              children: List.generate(
                _methods.length,
                (i) => RadioListTile<int>(
                  title:
                      Text(_methods[i], style: const TextStyle(fontSize: 13)),
                  value: i,
                  groupValue: _pmIdx,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _pmIdx = v!),
                ),
              ),
            )),
            const SizedBox(height: 16),
            _sec('ORDER SUMMARY'),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                ...cart.items.map((ci) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${ci.product.name} ×${ci.quantity}',
                              style: const TextStyle(fontSize: 12)),
                          Text('${ci.lineTotal.toStringAsFixed(0)} RWF',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    )),
                const Divider(),
                _SummaryRow('Total', '${cart.total.toStringAsFixed(0)} RWF',
                    bold: true),
              ]),
            )),
            const SizedBox(height: 24),
            AppButton(
                label: 'PLACE ORDER', onPressed: _place, isLoading: _placing),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      );
}

// ─── Order Confirmation Screen ────────────────────────────────────────────────

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Order Confirmation'),
            automaticallyImplyLeading: false),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 46, color: Colors.white)),
            const SizedBox(height: 20),
            const Text('Order Confirmed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Thank you for your order',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _row('Order #:', order.orderNumber),
                _row('Date:', order.formattedDate),
                _row('Payment:', order.paymentMethod),
                _row('Delivery:', '3–5 business days'),
                const Divider(),
                _row('Total:', '${order.total.toStringAsFixed(0)} RWF',
                    bold: true),
              ]),
            )),
            const Spacer(),
            AppButton(
              label: 'TRACK ORDER',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.myOrders),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'CONTINUE SHOPPING',
              outlined: true,
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
            ),
          ]),
        ),
      );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(v,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      );
}

// ─── My Orders Screen ─────────────────────────────────────────────────────────

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.navInactive,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'ACTIVE (${prov.active.length})'),
            Tab(text: 'COMPLETED (${prov.completed.length})'),
            Tab(text: 'CANCELLED (${prov.cancelled.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OrderList(orders: prov.active, showCancel: true),
          _OrderList(orders: prov.completed, showRate: true),
          _OrderList(orders: prov.cancelled),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool showCancel, showRate;
  const _OrderList(
      {required this.orders, this.showCancel = false, this.showRate = false});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Orders Here',
        subtitle: 'Your orders will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _OrderCard(
          order: orders[i], showCancel: showCancel, showRate: showRate),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showCancel, showRate;
  const _OrderCard(
      {required this.order, this.showCancel = false, this.showRate = false});

  @override
  Widget build(BuildContext context) {
    Color sc;
    String sl;
    switch (order.status) {
      case OrderStatus.active:
        sc = AppColors.accent;
        sl = 'ACTIVE';
      case OrderStatus.processing:
        sc = AppColors.warning;
        sl = 'PROCESSING';
      case OrderStatus.delivered:
        sc = AppColors.info;
        sl = 'DELIVERED';
      case OrderStatus.cancelled:
        sc = AppColors.error;
        sl = 'CANCELLED';
    }
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(order.orderNumber,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            StatusBadge(label: sl, color: sc),
          ],
        ),
        const SizedBox(height: 6),
        ...order.items.map((item) => Text(
            '• ${item.productName} ×${item.quantity}  '
            '${item.total.toStringAsFixed(0)} RWF',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        const SizedBox(height: 4),
        Text(
            'Total: ${order.total.toStringAsFixed(0)} RWF  |  '
            'Delivery: ${order.deliveryFee.toStringAsFixed(0)} RWF',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text('Date: ${order.formattedDate}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [
          _Btn('TRACK ORDER', AppColors.primary, () {}),
          if (showCancel) ...[
            const SizedBox(width: 8),
            _Btn('CANCEL', AppColors.error, () async {
              await context.read<OrderProvider>().cancelOrder(order.id);
            }),
          ],
          if (showRate) ...[
            const SizedBox(width: 8),
            _Btn('RATE ★', Colors.amber, () {}),
          ],
        ]),
      ]),
    ));
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(7)),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      );
}

// ─── Credit Tracker Screen ────────────────────────────────────────────────────

class CreditTrackerScreen extends StatefulWidget {
  const CreditTrackerScreen({super.key});
  @override
  State<CreditTrackerScreen> createState() => _CreditTrackerScreenState();
}

class _CreditTrackerScreenState extends State<CreditTrackerScreen> {
  String _filter = 'All';

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final form = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Credit Record'),
          content: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AppTextField(
                    hint: 'Debtor Name',
                    controller: nameCtrl,
                    validator: (v) => Validators.required(v, 'Name')),
                const SizedBox(height: 10),
                AppTextField(
                    hint: 'Phone (optional)',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                AppTextField(
                    hint: 'Amount (RWF)',
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    validator: Validators.price),
                const SizedBox(height: 10),
                AppTextField(hint: 'Notes', controller: noteCtrl),
                const SizedBox(height: 10),
                Row(children: [
                  const Text('Due: ', style: TextStyle(fontSize: 13)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setSt(() => dueDate = picked);
                    },
                    child: Text(
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final uid = context.read<AuthProvider>().user?.uid ?? '';
                final credit = CreditModel(
                  id: const Uuid().v4(),
                  creditorId: uid,
                  debtorName: nameCtrl.text.trim(),
                  debtorPhone: phoneCtrl.text.trim(),
                  amount: double.parse(amtCtrl.text),
                  dueDate: dueDate,
                  status: CreditStatus.active,
                  notes: noteCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                await context.read<CreditProvider>().addCredit(credit);
                if (!context.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CreditProvider>();
    List<CreditModel> list;
    switch (_filter) {
      case 'Overdue':
        list = prov.overdue;
      case 'Active':
        list = prov.active;
      case 'Paid':
        list = prov.paid;
      default:
        list = prov.credits;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Credit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
                child: _CreditCard2(
                    'Total Owed',
                    '${prov.totalOwed.toStringAsFixed(0)} RWF',
                    AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(
                child: _CreditCard2(
                    'Overdue',
                    '${prov.totalOverdue.toStringAsFixed(0)} RWF',
                    AppColors.error)),
            const SizedBox(width: 8),
            Expanded(
                child: _CreditCard2(
                    'Active', '${prov.active.length}', AppColors.warning)),
          ]),
        ),
        // Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
              children: ['All', 'Overdue', 'Active', 'Paid'].map((f) {
            final sel = f == _filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary)),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: prov.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : list.isEmpty
                  ? const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No Credits',
                      subtitle: 'Tap + to add a credit record',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _CreditItemCard(credit: list[i]),
                    ),
        ),
      ]),
    );
  }
}

class _CreditCard2 extends StatelessWidget {
  final String title, value;
  final Color color;
  const _CreditCard2(this.title, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
      );
}

class _CreditItemCard extends StatelessWidget {
  final CreditModel credit;
  const _CreditItemCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    final Color sc;
    final String sl;
    if (credit.status == CreditStatus.paid) {
      sc = AppColors.success;
      sl = 'Paid';
    } else if (credit.isOverdue) {
      sc = AppColors.error;
      sl = 'Overdue';
    } else {
      sc = AppColors.warning;
      sl = 'Active';
    }

    return Card(
        child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(credit.debtorName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700))),
          StatusBadge(label: sl, color: sc),
        ]),
        const SizedBox(height: 6),
        Text(
            'Total: ${credit.amount.toStringAsFixed(0)} RWF  '
            '| Remaining: ${credit.remaining.toStringAsFixed(0)} RWF',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text('Due: ${credit.formattedDue}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (credit.notes.isNotEmpty)
          Text('Note: ${credit.notes}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [
          if (credit.status != CreditStatus.paid)
            _PrimaryBtn('Mark Paid', AppColors.success, () async {
              await context.read<CreditProvider>().updateCredit(credit.id, {
                'amountPaid': credit.amount,
                'status': CreditStatus.paid.name,
              });
            }),
          const SizedBox(width: 8),
          _PrimaryBtn('Delete', AppColors.error, () async {
            await context.read<CreditProvider>().deleteCredit(credit.id);
          }),
        ]),
      ]),
    ));
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(7)),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      );
}
