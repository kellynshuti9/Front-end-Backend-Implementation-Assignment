import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../domain/providers/product_provider.dart';
import '../../../domain/providers/shop_provider.dart';
import '../../widgets/common/widgets.dart';

// ─── Browse Screen ────────────────────────────────────────────────────────────

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchCtrl = TextEditingController();
  final _tabs = ['All', 'Nearby', 'Popular', 'Recommended'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopProv = context.watch<ShopProvider>();
    final shops = shopProv.shops;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Browse Shops'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.shopping_cart_outlined),
              if (context.watch<CartProvider>().itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child: Center(
                        child: Text('${context.read<CartProvider>().itemCount}',
                            style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w700))),
                  ),
                ),
            ]),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AppTextField(
            hint: 'Search shops or products...',
            controller: _searchCtrl,
            prefix:
                const Icon(Icons.search, size: 20, color: AppColors.textHint),
            suffix: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      shopProv.clearSearch();
                    })
                : null,
            onChanged: (q) {
              setState(() {});
              shopProv.search(q);
            },
          ),
        ),
        // Tabs
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _tabs[i] == shopProv.tab;
              return GestureDetector(
                onTap: () => shopProv.setTab(_tabs[i]),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_tabs[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: shopProv.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : shops.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'No Shops Found',
                      subtitle: _searchCtrl.text.isNotEmpty
                          ? 'Try a different search'
                          : 'Be the first to list your shop!',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: shops.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ShopCard(shop: shops[i]),
                    ),
        ),
      ]),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopModel shop;
  const _ShopCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final following = auth.isFollowing(shop.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(shop.location,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Row(children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      Text(
                        ' ${shop.rating.toStringAsFixed(1)}'
                        ' (${shop.reviewCount} reviews)  '
                        '· ${shop.productCount} products',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ]),
                  ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: AppButton(
                label: 'Visit Shop',
                height: 38,
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.shopDetail,
                    arguments: shop),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => auth.toggleFollowShop(shop.id, !following),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: following
                      ? AppColors.accent.withOpacity(0.12)
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: following ? AppColors.accent : AppColors.inputBorder,
                  ),
                ),
                child: Text(
                  following ? '✓ Following' : '+ Follow',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: following
                          ? AppColors.accent
                          : AppColors.textSecondary),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Shop Detail Screen ───────────────────────────────────────────────────────

class ShopDetailScreen extends StatefulWidget {
  final ShopModel shop;
  const ShopDetailScreen({super.key, required this.shop});
  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final _searchCtrl = TextEditingController();
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<ProductProvider>().watchShopProducts(widget.shop.ownerId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    context.read<ProductProvider>().stopWatchingShop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final following = auth.isFollowing(widget.shop.id);
    final prodProv = context.watch<ProductProvider>();
    final shop = widget.shop;

    var prods = prodProv.shopProducts;
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      prods = prods
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    if (_categoryFilter != 'All') {
      prods = prods.where((p) => p.category == _categoryFilter).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Details'),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
            if (context.watch<CartProvider>().itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child: Center(
                        child: Text('${context.read<CartProvider>().itemCount}',
                            style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)))),
              ),
          ]),
        ],
      ),
      body: CustomScrollView(slivers: [
        // ── Shop header ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black12)
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(shop.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.verified, color: AppColors.accent, size: 20),
              ]),
              const SizedBox(height: 6),
              if (shop.location.isNotEmpty)
                _infoRow(Icons.location_on_outlined, shop.location),
              if (shop.phone.isNotEmpty)
                _infoRow(Icons.phone_outlined, shop.phone),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                Text(
                  ' ${shop.rating.toStringAsFixed(1)} (${shop.reviewCount} reviews)',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
              const SizedBox(height: 14),
              // Stats
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('${shop.productCount}', 'Products'),
                _stat('${shop.followerCount}', 'Followers'),
                _stat(shop.rating.toStringAsFixed(1), 'Rating'),
              ]),
              const SizedBox(height: 16),
              // Action buttons
              Row(children: [
                Expanded(
                  child: AppButton(
                    label: following ? '✓ Following' : '+ Follow',
                    height: 40,
                    color: following ? AppColors.accent : AppColors.primary,
                    onPressed: () => auth.toggleFollowShop(shop.id, !following),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Message',
                    height: 40,
                    outlined: true,
                    icon: Icons.message_outlined,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Share',
                    height: 40,
                    outlined: true,
                    icon: Icons.share_outlined,
                    onPressed: () {},
                  ),
                ),
              ]),
              if (shop.about.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('About:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(shop.about,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ]),
          ),
        ),

        // ── Product search + filter ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              AppTextField(
                hint: 'Search products in this shop...',
                controller: _searchCtrl,
                prefix: const Icon(Icons.search,
                    size: 20, color: AppColors.textHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              // Category chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', ...kCategories].map((c) {
                    final sel = c == _categoryFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _categoryFilter = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                sel ? AppColors.primary : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SectionHeader(
                title: 'Products (${prods.length})',
              ),
            ]),
          ),
        ),

        // ── Products grid ─────────────────────────────────────────────────
        prods.isEmpty
            ? SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Products',
                  subtitle: _searchCtrl.text.isNotEmpty
                      ? 'No products match your search'
                      : 'This shop has no products yet',
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ShopProductCard(product: prods[i]),
                    childCount: prods.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                ),
              ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ]),
      );

  Widget _stat(String val, String label) => Column(children: [
        Text(val,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]);
}

class _ShopProductCard extends StatelessWidget {
  final ProductModel product;
  const _ShopProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.quantityOf(product.id);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail,
            arguments: product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(product.imageUrls.first,
                              fit: BoxFit.cover),
                        )
                      : const Icon(Icons.shopping_bag_outlined,
                          size: 32, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(product.formattedPrice,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!product.inStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Out of stock')));
                        return;
                      }
                      if (inCart > 0) {
                        Navigator.pushNamed(context, AppRoutes.cart);
                        return;
                      }
                      final added =
                          context.read<CartProvider>().addItem(product);
                      if (added) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} added!')));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !product.inStock
                            ? Colors.grey.shade200
                            : inCart > 0
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          !product.inStock
                              ? 'Out of stock'
                              : inCart > 0
                                  ? '✓ In Cart'
                                  : 'Add to Cart',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: !product.inStock
                                  ? Colors.grey
                                  : inCart > 0
                                      ? AppColors.accent
                                      : Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
