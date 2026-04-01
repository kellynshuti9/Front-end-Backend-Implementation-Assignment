// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:mobiledger_app/presentation/screens/splash_screen.dart';
import 'package:mobiledger_app/presentation/screens/language_screen.dart';
import 'package:mobiledger_app/presentation/screens/login_screen.dart';
import 'package:mobiledger_app/presentation/screens/signup_screen.dart';
import 'package:mobiledger_app/presentation/screens/forgot_password_screen.dart';
import 'package:mobiledger_app/presentation/screens/dashboard_screen.dart';
import 'package:mobiledger_app/presentation/screens/add_product_screen.dart';
import 'package:mobiledger_app/presentation/screens/my_products_screen.dart';
import 'package:mobiledger_app/presentation/screens/edit_product_screen.dart';
import 'package:mobiledger_app/presentation/screens/product_details_screen.dart';
import 'package:mobiledger_app/presentation/screens/sales_screen.dart';
import 'package:mobiledger_app/presentation/screens/browse_shops_screen.dart';
import 'package:mobiledger_app/presentation/screens/shop_details_screen.dart';
import 'package:mobiledger_app/presentation/screens/shopping_cart_screen.dart';
import 'package:mobiledger_app/presentation/screens/credit_tracker_screen.dart';
import 'package:mobiledger_app/presentation/screens/profile_screen.dart';
import 'package:mobiledger_app/presentation/screens/edit_profile_screen.dart';
import 'package:mobiledger_app/presentation/screens/settings_screen.dart';
import 'package:mobiledger_app/presentation/screens/learn_hub_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String language = '/language';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String addProduct = '/add-product';
  static const String myProducts = '/my-products';
  static const String editProduct = '/edit-product';
  static const String productDetails = '/product-details';
  static const String sales = '/sales';
  static const String browseShops = '/browse-shops';
  static const String shopDetails = '/shop-details';
  static const String cart = '/cart';
  static const String creditTracker = '/credit-tracker';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String learnHub = '/learn-hub';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    language: (context) => const LanguageScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignUpScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    dashboard: (context) => const DashboardScreen(),
    addProduct: (context) => const AddProductScreen(),
    myProducts: (context) => const MyProductsScreen(),
    sales: (context) => const SalesScreen(),
    browseShops: (context) => const BrowseShopsScreen(),
    cart: (context) => const ShoppingCartScreen(),
    creditTracker: (context) => const CreditTrackerScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) => const EditProfileScreen(),
    settings: (context) => const SettingsScreen(),
    learnHub: (context) => const LearnHubScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case productDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(
            productId: args?['productId'] ?? '',
          ),
        );
      case editProduct:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => EditProductScreen(
            productId: args['productId'],
            productData: args['productData'],
          ),
        );
      case shopDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ShopDetailsScreen(
            shopData: args,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}