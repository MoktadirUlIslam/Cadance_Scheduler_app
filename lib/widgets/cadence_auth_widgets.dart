// lib/Components/cadence_auth_widgets.dart
//
// Shared visual pieces for the login and registration screens.
// All colors are derived from AppColors (colors.dart) and react to
// the active ThemeData — no hardcoded hex values in here.

import 'dart:math';
import 'package:flutter/material.dart';

import '../utilites/app_colors.dart';


/// Resolves AppColors + the current theme into the specific shades
/// these screens need, so every widget stays in sync with light/dark
/// mode automatically.
class CadencePalette {
  final Color primary;      // brand teal (theme-aware)
  final Color primaryDeep;  // darker teal, for gradients
  final Color primaryTint;  // lighter teal, for glows/focus rings
  final Color accent;       // warm coral, used sparingly for links
  final Color surface;      // card background
  final Color ink;          // primary text on the card
  final Color inkSoft;      // secondary text on the card
  final Color border;       // field borders / dividers
  final Color fieldFill;    // text field background
  final bool isDark;

  CadencePalette._({
    required this.primary,
    required this.primaryDeep,
    required this.primaryTint,
    required this.accent,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.border,
    required this.fieldFill,
    required this.isDark,
  });

  factory CadencePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final accent = isDark ? AppColors.accentDark : AppColors.accentLight;

    final hsl = HSLColor.fromColor(primary);
    final primaryDeep =
    hsl.withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0)).toColor();
    final primaryTint =
    hsl.withLightness((hsl.lightness + 0.30).clamp(0.0, 1.0)).toColor();

    return CadencePalette._(
      primary: primary,
      primaryDeep: primaryDeep,
      primaryTint: primaryTint,
      accent: accent,
      surface: theme.colorScheme.surface,
      ink: isDark ? Colors.white.withOpacity(0.94) : const Color(0xFF0E2A21),
      inkSoft: isDark ? Colors.white.withOpacity(0.60) : const Color(0xFF557568),
      border: isDark ? Colors.white.withOpacity(0.14) : const Color(0xFFE2E2D9),
      fieldFill: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      isDark: isDark,
    );
  }
}

/// Animated backdrop shared by the login and registration screens:
/// soft drifting blobs plus a row of pulsing bars, tinted with the
/// app's primary teal.
class CadenceBackground extends StatefulWidget {
  const CadenceBackground({super.key});

  @override
  State<CadenceBackground> createState() => _CadenceBackgroundState();
}

class _CadenceBackgroundState extends State<CadenceBackground>
    with TickerProviderStateMixin {
  late final AnimationController _blobController;
  late final AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _blobController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CadencePalette.of(context);

    return IgnorePointer(
      child: Stack(
        children: [
          _Blob(controller: _blobController, phase: 0.0, top: -60, left: -60,
              size: 220, color: palette.primaryTint.withOpacity(0.35)),
          _Blob(controller: _blobController, phase: 0.35, bottom: 40, right: -50,
              size: 180, color: Colors.white.withOpacity(0.20)),
          _Blob(controller: _blobController, phase: 0.7, bottom: -60, left: 120,
              size: 150, color: palette.primaryTint.withOpacity(0.25)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 110,
            child: _CadenceBars(controller: _barController),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  final double size;
  final Color color;
  final double? top, bottom, left, right;

  const _Blob({
    required this.controller,
    required this.phase,
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = ((controller.value + phase) % 1.0) * 2 * pi;
          final dx = sin(t) * 14;
          final dy = cos(t) * 18;
          final scale = 1.0 + sin(t) * 0.12;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _CadenceBars extends StatelessWidget {
  final AnimationController controller;
  static const int barCount = 26;

  const _CadenceBars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (i) {
          final delay = (i * 0.06) % 1.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final t = ((controller.value - delay) % 1.0 + 1.0) % 1.0;
                final wave = (sin(t * 2 * pi - pi / 2) + 1) / 2; // 0..1
                final height = 8 + wave * 30;
                return Container(
                  width: 4,
                  height: height,
                  margin: const EdgeInsets.only(top: 60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/// Floating-label text field matching the demo's animated focus state.
class CadenceTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CadenceTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CadenceTextField> createState() => _CadenceTextFieldState();
}

class _CadenceTextFieldState extends State<CadenceTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CadencePalette.of(context);
    final isFocused = _focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused ? palette.primary : palette.border,
            width: 1.5,
          ),
          boxShadow: isFocused
              ? [
            BoxShadow(
              color: palette.primaryTint.withOpacity(0.25),
              blurRadius: 0,
              spreadRadius: 4,
            ),
          ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText ? _obscure : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: TextStyle(fontSize: 14, color: palette.ink),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontSize: 14,
              color: isFocused ? palette.primary : palette.inkSoft,
            ),
            floatingLabelStyle: TextStyle(
              fontSize: 13,
              color: palette.primary,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            suffixIcon: widget.obscureText
                ? IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 19,
                color: palette.inkSoft,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Gradient CTA button with a subtle press-scale animation and a
/// built-in loading state.
class CadencePrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const CadencePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  State<CadencePrimaryButton> createState() => _CadencePrimaryButtonState();
}

class _CadencePrimaryButtonState extends State<CadencePrimaryButton> {
  double _scale = 1.0;

  void _setPressed(bool pressed) => setState(() => _scale = pressed ? 0.97 : 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = CadencePalette.of(context);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.primary, palette.primaryDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined "Sign in with Google" button.
class CadenceGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CadenceGoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = CadencePalette.of(context);

    return Material(
      color: palette.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.google.com/favicon.ico',
                width: 17,
                height: 17,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.g_mobiledata, size: 20, color: palette.ink),
              ),
              const SizedBox(width: 10),
              Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A divider with centered "or continue with" text, matching the demo.
class CadenceDivider extends StatelessWidget {
  const CadenceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = CadencePalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: palette.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'or continue with',
              style: TextStyle(fontSize: 12, color: palette.inkSoft),
            ),
          ),
          Expanded(child: Divider(color: palette.border, thickness: 1)),
        ],
      ),
    );
  }
}