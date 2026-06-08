import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/core/web/web_nav.dart';
import 'package:kaki_empat/features/auth/presentation/login_page.dart';
import 'package:kaki_empat/features/auth/presentation/register_page.dart';
import 'package:kaki_empat/features/shared/widgets/logo_widget.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class SitterLandingPage extends StatelessWidget {
  const SitterLandingPage({super.key, this.onAuthSuccess});

  final VoidCallback? onAuthSuccess;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.sitterHeroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(alignment: Alignment.centerLeft, child: LogoWidget()),
                const SizedBox(height: 24),
                const _HeroPhoto(),
                const SizedBox(height: 28),
                Text(
                  l10n.sitterHero,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.sitterLandingSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    if (kIsWeb) {
                      navigateToUrl(SsoNav.loginUrlOnWww(
                        auth: 'register',
                        returnTarget: 'sitter',
                      ));
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RegisterPage(
                          defaultRole: 'sitter',
                          onSuccess: onAuthSuccess,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.accentWarm,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.sitterStartNow),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.sitterBenefitsLine,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.wwwTestimonialsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _TestimonialCard(
                  name: l10n.sitterTestimonial1Name,
                  quote: l10n.sitterTestimonial1Quote,
                ),
                const SizedBox(height: 12),
                _TestimonialCard(
                  name: l10n.sitterTestimonial2Name,
                  quote: l10n.sitterTestimonial2Quote,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    if (kIsWeb) {
                      navigateToUrl(
                        SsoNav.loginUrlOnWww(returnTarget: 'sitter'),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LoginPage(onSuccess: onAuthSuccess),
                      ),
                    );
                  },
                  child: Text(l10n.authLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.accentWarm.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 40,
            bottom: 30,
            child: Icon(Icons.pets, size: 72, color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                child: Icon(Icons.sentiment_very_satisfied_rounded, size: 52, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                '🐈 + 😊',
                style: TextStyle(fontSize: 28, color: AppColors.primaryDark.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.name, required this.quote});

  final String name;
  final String quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
