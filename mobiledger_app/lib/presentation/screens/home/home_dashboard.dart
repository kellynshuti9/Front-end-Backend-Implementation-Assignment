import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../domain/providers/product_provider.dart';
import '../../../domain/providers/order_credit_providers.dart';
import '../../widgets/common/widgets.dart';
import '../browse/browse_screen.dart';
import '../profile_settings_learn_sales.dart';

// ─── Home Shell ───────────────────────────────────────────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    BrowseScreen(),
    LearnScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _idx, children: _screens),
        bottomNavigationBar: AppBottomNavBar(
          index: _idx,
          onTap: (i) => setState(() => _idx = i),
        ),
      );
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final products = context.watch<ProductProvider>();
    final orders = context.watch<OrderProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: const EdgeInsets.fromLTRB(16, 44, 16, 12),
                child: Row(
                  children: [
                    const LogoRow(),
                    const Spacer(),
                    // Cart badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.cart),
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${cart.itemCount}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accent.withOpacity(0.3),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                (user?.fullName.isNotEmpty == true)
                                    ? user!.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700))
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row ─────────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: _StatCard(
                      title: 'Active\nProducts',
                      value: '${products.activeCount}',
                      color: AppColors.primaryLight,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.myProducts),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatCard(
                      title: "Today's\nSales",
                      value: '${orders.active.length}',
                      color: AppColors.info,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.sales),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatCard(
                      title: 'Monthly\nIncome',
                      value: _fmt(orders.totalSalesThisMonth),
                      color: AppColors.warning,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.sales),
                    )),
                  ]),

                  const SizedBox(height: 20),

                  // ── Recent Activity ───────────────────────────────────────
                  SectionHeader(
                    title: 'Recent Activity',
                    action: 'View All',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRoutes.sales),
                  ),
                  const SizedBox(height: 8),
                  products.myProducts.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              products.loadingMine
                                  ? 'Loading products...'
                                  : 'No recent activity. Add your first product!',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: products.myProducts
                                  .take(3)
                                  .map(
                                    (p) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: p.inStock
                                                ? AppColors.success
                                                : AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${p.name} — ${p.formattedPrice}',
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        StatusBadge(
                                          label: p.stockStatus,
                                          color: p.stockQuantity == 0
                                              ? AppColors.error
                                              : p.stockQuantity < 5
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                        ),
                                      ]),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('View All Activity'),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.myProducts),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Quick Actions ─────────────────────────────────────────
                  const SectionHeader(title: '⚡ Quick Actions'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: _QuickAction(
                      icon: Icons.add_box_outlined,
                      label: 'Add Product',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.addProduct),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickAction(
                      icon: Icons.bar_chart,
                      label: 'View Sales',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.sales),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickAction(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Manage Credit',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.creditTracker),
                    )),
                  ]),

                  const SizedBox(height: 24),

                  // ── Low Stock Alert ───────────────────────────────────────
                  if (products.lowStockCount > 0 || products.outCount > 0)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${products.lowStockCount} low stock, '
                            '${products.outCount} out of stock',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.myProducts),
                          child: const Text('View'),
                        ),
                      ]),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard(
      {required this.title,
      required this.value,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70, height: 1.3)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}
