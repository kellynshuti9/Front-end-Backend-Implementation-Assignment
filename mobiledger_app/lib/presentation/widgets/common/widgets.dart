import 'package:flutter/material.dart';
import '/../core/constants/app_colors.dart';

// ─── AppButton ────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.color,
    this.textColor,
    this.width,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 18,
                    color: outlined
                        ? (textColor ?? AppColors.primary)
                        : (textColor ?? Colors.white)),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: outlined
                        ? (textColor ?? AppColors.primary)
                        : (textColor ?? Colors.white),
                  )),
            ],
          );

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    if (outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color ?? AppColors.primary, width: 1.5),
            shape: shape,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          shape: shape,
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}

// ─── AppTextField ─────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final String? initialValue;
  final bool autofocus;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.initialValue,
    this.autofocus = false,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        initialValue: initialValue,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: obscure ? 1 : maxLines,
        enabled: enabled,
        onChanged: onChanged,
        validator: validator,
        autofocus: autofocus,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
          prefixIcon: prefix,
          suffixIcon: suffix,
        ),
      );
}

// ─── AppBottomNavBar ──────────────────────────────────────────────────────────

class AppBottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: AppColors.primary,
      indicatorColor: AppColors.accent.withOpacity(0.25),
      selectedIndex: index,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: AppColors.navInactive),
          selectedIcon: Icon(Icons.home, color: AppColors.accent),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined, color: AppColors.navInactive),
          selectedIcon: Icon(Icons.storefront, color: AppColors.accent),
          label: 'Browse',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined, color: AppColors.navInactive),
          selectedIcon: Icon(Icons.school, color: AppColors.accent),
          label: 'Learn',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: AppColors.navInactive),
          selectedIcon: Icon(Icons.settings, color: AppColors.accent),
          label: 'Settings',
        ),
      ],
    );
  }
}

// ─── LoadingOverlay ───────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  const LoadingOverlay({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        if (loading)
          Container(
            color: Colors.black38,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
      ]);
}

// ─── SectionHeader ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      );
}

// ─── StatusBadge ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 48, color: AppColors.textHint),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              if (buttonLabel != null) ...[
                const SizedBox(height: 28),
                AppButton(label: buttonLabel!, onPressed: onButton, width: 200),
              ],
            ],
          ),
        ),
      );
}

// ─── MobiLedger Logo Row ──────────────────────────────────────────────────────

class LogoRow extends StatelessWidget {
  final double size;
  const LogoRow({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 2.2,
            height: size * 2.2,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(size * 0.4),
            ),
            child: Center(
              child: Text('ML',
                  style: TextStyle(
                      fontSize: size * 0.75,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'Mobi',
                  style: TextStyle(
                      fontSize: size,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              TextSpan(
                  text: 'Ledger',
                  style: TextStyle(
                      fontSize: size,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
            ]),
          ),
        ],
      );
}
