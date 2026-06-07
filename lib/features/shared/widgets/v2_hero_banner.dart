import 'package:flutter/material.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';

/// Hero section dengan gradient hijau, ilustrasi, dan animasi fade-in.
class V2HeroBanner extends StatefulWidget {
  const V2HeroBanner({
    super.key,
    required this.headline,
    required this.subheadline,
    this.illustration,
    this.actions = const [],
    this.stats = const [],
  });

  final String headline;
  final String subheadline;
  final Widget? illustration;
  final List<Widget> actions;
  final List<Widget> stats;

  @override
  State<V2HeroBanner> createState() => _V2HeroBannerState();
}

class _V2HeroBannerState extends State<V2HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = V2Responsive.of(context) != V2ScreenSize.mobile;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5EE),
              Color(0xFFF8FBF9),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: V2Responsive.pagePadding(context).copyWith(
            top: 32,
            bottom: 32,
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildText(theme)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildIllustration()),
                  ],
                )
              : Column(
                  children: [
                    _buildIllustration(),
                    const SizedBox(height: 24),
                    _buildText(theme),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return widget.illustration ??
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.accent.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.directions_walk_rounded,
              size: 96,
              color: AppColors.primary,
            ),
          ),
        );
  }

  Widget _buildText(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.headline,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.subheadline,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (widget.stats.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: widget.stats,
          ),
        ],
        if (widget.actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          ..._spacedActions(widget.actions),
        ],
      ],
    );
  }

  List<Widget> _spacedActions(List<Widget> actions) {
    final out = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 12));
      out.add(actions[i]);
    }
    return out;
  }
}
