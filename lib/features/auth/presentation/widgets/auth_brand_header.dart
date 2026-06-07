import 'package:flutter/material.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Logo + judul brand di atas form auth, dengan animasi fade-in.
class AuthBrandHeader extends StatefulWidget {
  const AuthBrandHeader({super.key});

  @override
  State<AuthBrandHeader> createState() => _AuthBrandHeaderState();
}

class _AuthBrandHeaderState extends State<AuthBrandHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fade,
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            semanticLabel: l10n.appTitle,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.appTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
