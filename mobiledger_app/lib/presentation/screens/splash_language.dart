import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/settings_provider.dart';

// ─── Splash Screen ────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    final settings = context.read<SettingsProvider>();
    await settings.init();
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isAuth) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.language);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text('ML',
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('MobiLedger',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  const Text('Track. Learn. Grow.',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.accentLight)),
                  const SizedBox(height: 60),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading Indicator',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.accentLight)),
                  const SizedBox(height: 60),
                  const Text('Version 1.0',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accentLight,
                          fontWeight: FontWeight.w300)),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Language Screen ──────────────────────────────────────────────────────────

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('ML',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                            text: 'Mobi',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        TextSpan(
                            text: 'Ledger',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Track. Learn. Grow in Your Language.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 52),
                const Text(
                  'Choose a language /\nHitamo ururimi',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                _LangBtn(
                  label: 'ENGLISH',
                  onTap: () => _pick(context, 'en'),
                ),
                const SizedBox(height: 16),
                _LangBtn(
                  label: 'KINYARWANDA',
                  onTap: () => _pick(context, 'rw'),
                ),
              ],
            ),
          ),
        ),
      );

  void _pick(BuildContext ctx, String lang) async {
    await ctx.read<SettingsProvider>().setLanguage(lang);
    if (!ctx.mounted) return;
    Navigator.pushReplacementNamed(ctx, AppRoutes.login);
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2)),
        ),
      );
}
