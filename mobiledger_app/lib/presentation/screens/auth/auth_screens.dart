import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/product_provider.dart';
import '../../../domain/providers/shop_provider.dart';
import '../../../domain/providers/order_credit_providers.dart';
import '../../widgets/common/widgets.dart';

// ─── Login Screen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmail(
        email: _email.text.trim(), password: _pass.text);
    if (!mounted) return;
    if (ok) {
      _initProviders();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      _showError(auth.errorMessage ?? 'Login failed. Please try again.');
      auth.clearError();
    }
  }

  Future<void> _googleLogin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _initProviders();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      _showError(
          auth.errorMessage ?? 'Google sign-in failed. Please try again.');
      auth.clearError();
    }
  }

  void _initProviders() {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    context.read<ProductProvider>().watchMyProducts(uid);
    context.read<ProductProvider>().watchAllProducts();
    context.read<ShopProvider>().watchShops();
    context.read<OrderProvider>().watchOrders(uid);
    context.read<CreditProvider>().watchCredits(uid);
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ));

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LoadingOverlay(
          loading: loading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Sign in to continue',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 36),
                  AppTextField(
                    hint: 'Email Address',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(Icons.email_outlined,
                        color: AppColors.textHint, size: 20),
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    hint: 'Password',
                    controller: _pass,
                    obscure: _obscure,
                    prefix: const Icon(Icons.lock_outline,
                        color: AppColors.textHint, size: 20),
                    suffix: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: Validators.password,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                      label: 'Login', onPressed: _login, isLoading: loading),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.forgotPassword),
                      child: const Text('Forgot Password?',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account?",
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.signUp),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _GoogleBtn(onTap: _googleLogin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sign Up Screen ───────────────────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureP = true, _obscureC = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerWithEmail(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text);
    if (!mounted) return;
    if (ok) {
      // Init providers
      final uid = auth.user?.uid ?? '';
      context.read<ProductProvider>().watchMyProducts(uid);
      context.read<ProductProvider>().watchAllProducts();
      context.read<ShopProvider>().watchShops();
      context.read<OrderProvider>().watchOrders(uid);
      context.read<CreditProvider>().watchCredits(uid);
      // Show verification banner
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text(
                'A verification email has been sent to your email address.\n\n'
                'Please verify your email before continuing to use all features.\n\n'
                'You can still use the app but some features may be restricted.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: const Text('Continue to App'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(auth.errorMessage ?? 'Registration failed'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LoadingOverlay(
          loading: loading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Create Account',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Text('Join MobiLedger today',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  AppTextField(
                      hint: 'Full Name',
                      controller: _name,
                      prefix: const Icon(Icons.person_outline,
                          color: AppColors.textHint, size: 20),
                      validator: (v) => Validators.required(v, 'Full name'),
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 14),
                  AppTextField(
                      hint: 'Email Address',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(Icons.email_outlined,
                          color: AppColors.textHint, size: 20),
                      validator: Validators.email,
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 14),
                  AppTextField(
                      hint: 'Password',
                      controller: _pass,
                      obscure: _obscureP,
                      prefix: const Icon(Icons.lock_outline,
                          color: AppColors.textHint, size: 20),
                      suffix: IconButton(
                        icon: Icon(
                            _obscureP
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint,
                            size: 20),
                        onPressed: () => setState(() => _obscureP = !_obscureP),
                      ),
                      validator: Validators.password,
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 14),
                  AppTextField(
                      hint: 'Confirm Password',
                      controller: _confirm,
                      obscure: _obscureC,
                      prefix: const Icon(Icons.lock_outline,
                          color: AppColors.textHint, size: 20),
                      suffix: IconButton(
                        icon: Icon(
                            _obscureC
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint,
                            size: 20),
                        onPressed: () => setState(() => _obscureC = !_obscureC),
                      ),
                      validator: (v) =>
                          Validators.confirmPassword(v, _pass.text),
                      textInputAction: TextInputAction.done),
                  const SizedBox(height: 28),
                  AppButton(
                      label: 'Sign Up',
                      onPressed: _register,
                      isLoading: loading),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account?',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Forgot Password Screen ───────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent! Check your inbox.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to send reset email'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3)));
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LoadingOverlay(
          loading: loading,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text('Forgot Password?',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Text('Enter your email to reset',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset,
                          size: 38, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 36),
                  AppTextField(
                    hint: 'Email Address',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(Icons.email_outlined,
                        color: AppColors.textHint, size: 20),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'SEND RESET LINK',
                    onPressed: _send,
                    isLoading: loading,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Remember password?',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Login',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Button ────────────────────────────────────────────────────────────

class _GoogleBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('G',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Continue with Google',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
}
