import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'data/models/product_model.dart';
import 'data/models/shop_model.dart';
import 'data/models/order_model.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/other_repositories.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/cart_provider.dart';
import 'domain/providers/order_credit_providers.dart';
import 'domain/providers/product_provider.dart';
import 'domain/providers/settings_provider.dart';
import 'domain/providers/shop_provider.dart';
import 'presentation/screens/splash_language.dart';
import 'presentation/screens/auth/auth_screens.dart';
import 'presentation/screens/home/home_dashboard.dart';
import 'presentation/screens/products/product_screens.dart';
import 'presentation/screens/browse/browse_screen.dart';
import 'presentation/screens/orders/orders_screens.dart';
import 'presentation/screens/profile_settings_learn_sales.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MobiLedgerApp());
}

class MobiLedgerApp extends StatelessWidget {
  const MobiLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Instantiate repositories ──────────────────────────────────────────
    final authRepo = AuthRepository();
    final productRepo = ProductRepository();
    final shopRepo = ShopRepository();
    final orderRepo = OrderRepository();
    final creditRepo = CreditRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(repository: productRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(repository: shopRepo),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(repository: orderRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => CreditProvider(repository: creditRepo),
        ),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (ctx, settings, auth, _) {
          // When auth state changes to authenticated, start data streams
          if (auth.isAuth && auth.user != null) {
            final uid = auth.user!.uid;
            final pp = ctx.read<ProductProvider>();
            final sp = ctx.read<ShopProvider>();
            final op = ctx.read<OrderProvider>();
            final cp = ctx.read<CreditProvider>();

            // Stagger stream initialization to prevent Firestore state conflicts
            Future.microtask(() {
              pp.watchMyProducts(uid);
              Future.delayed(const Duration(milliseconds: 100), () {
                pp.watchAllProducts();
              });
              Future.delayed(const Duration(milliseconds: 200), () {
                sp.watchShops();
              });
              Future.delayed(const Duration(milliseconds: 300), () {
                op.watchOrders(uid);
              });
              Future.delayed(const Duration(milliseconds: 400), () {
                cp.watchCredits(uid);
              });
            });
          }

          return MaterialApp(
            title: 'MobiLedger',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: _router,
          );
        },
      ),
    );
  }

  Route<dynamic>? _router(RouteSettings s) {
    switch (s.name) {
      // ── Auth ──────────────────────────────────────────────────────────
      case AppRoutes.splash:
        return _fade(const SplashScreen());
      case AppRoutes.language:
        return _slide(const LanguageScreen());
      case AppRoutes.login:
        return _slide(const LoginScreen());
      case AppRoutes.signUp:
        return _slide(const SignUpScreen());
      case AppRoutes.forgotPassword:
        return _slide(const ForgotPasswordScreen());

      // ── Main shell ────────────────────────────────────────────────────
      case AppRoutes.home:
        return _fade(const HomeShell());

      // ── Products ──────────────────────────────────────────────────────
      case AppRoutes.myProducts:
        return _slide(const MyProductsScreen());
      case AppRoutes.addProduct:
        return _slide(const AddProductScreen());
      case AppRoutes.editProduct:
        return _slide(EditProductScreen(product: s.arguments as ProductModel));
      case AppRoutes.productDetail:
        return _slide(
          ProductDetailScreen(product: s.arguments as ProductModel),
        );

      // ── Browse ────────────────────────────────────────────────────────
      case AppRoutes.browseShops:
        return _slide(const BrowseScreen());
      case AppRoutes.shopDetail:
        return _slide(ShopDetailScreen(shop: s.arguments as ShopModel));

      // ── Cart & Orders ─────────────────────────────────────────────────
      case AppRoutes.cart:
        return _slide(const CartScreen());
      case AppRoutes.checkout:
        return _slide(const CheckoutScreen());
      case AppRoutes.orderConfirm:
        return _slide(
          OrderConfirmationScreen(order: s.arguments as OrderModel),
        );
      case AppRoutes.myOrders:
        return _slide(const MyOrdersScreen());

      // ── Credit ────────────────────────────────────────────────────────
      case AppRoutes.creditTracker:
        return _slide(const CreditTrackerScreen());

      // ── Profile & Settings ────────────────────────────────────────────
      case AppRoutes.profile:
        return _slide(const ProfileScreen());
      case AppRoutes.editProfile:
        return _slide(const EditProfileScreen());
      case AppRoutes.settings:
        return _slide(const SettingsScreen());

      // ── Sales ─────────────────────────────────────────────────────────
      case AppRoutes.sales:
        return _slide(const SalesScreen());

      default:
        return _fade(const SplashScreen());
    }
  }

  PageRoute<T> _fade<T>(Widget p) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => p,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  PageRoute<T> _slide<T>(Widget p) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => p,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)).animate(a),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );
}
