import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/features/www/presentation/www_footer.dart';
import 'package:kaki_empat/features/www/presentation/www_hero_section.dart';
import 'package:kaki_empat/features/www/presentation/www_landing_scope.dart';
import 'package:kaki_empat/features/www/presentation/www_section_header.dart';
import 'package:kaki_empat/features/www/presentation/www_sitter_signup_section.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// www.kakiempat.com — cerita hangat, bukan instruksi.
class WwwRouterPage extends StatelessWidget {
  const WwwRouterPage({
    super.key,
    required this.scrollController,
    required this.sectionKeys,
  });

  final ScrollController scrollController;
  final Map<WwwSection, GlobalKey> sectionKeys;

  Widget _sectionAnchor(WwwSection section, Widget child) {
    return KeyedSubtree(key: sectionKeys[section], child: child);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final padding = V2Responsive.pagePadding(context);
    final serviceColumns = V2Responsive.serviceGridColumns(context);
    final isNarrow = V2Responsive.isNarrowMobile(context);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: V2Responsive.constrain(
        CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: WwwHeroSection(scrollController: scrollController),
            ),
            SliverToBoxAdapter(
              child: _sectionAnchor(
                WwwSection.services,
                Padding(
                  padding: padding.copyWith(bottom: 12),
                  child: WwwSectionHeader(
                    title: l10n.wwwServicesTitle,
                    subtitle: l10n.wwwServicesSubtitle,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: padding.copyWith(bottom: 28),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: serviceColumns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: V2Responsive.serviceCardAspectRatio(context),
                ),
                delegate: SliverChildListDelegate([
                  _ServiceCard(
                    emoji: '🐕',
                    title: l10n.wwwServiceWalkingTitle,
                    description: l10n.wwwServiceWalkingDesc,
                    compact: isNarrow,
                  ),
                  _ServiceCard(
                    emoji: '🏠',
                    title: l10n.wwwServiceSittingTitle,
                    description: l10n.wwwServiceSittingDesc,
                    compact: isNarrow,
                  ),
                  _ServiceCard(
                    emoji: '✂️',
                    title: l10n.wwwServiceGroomingTitle,
                    description: l10n.wwwServiceGroomingDesc,
                    compact: isNarrow,
                  ),
                  _ServiceCard(
                    emoji: '🎓',
                    title: l10n.wwwServiceTrainingTitle,
                    description: l10n.wwwServiceTrainingDesc,
                    compact: isNarrow,
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: padding.copyWith(bottom: 28),
                child: _HowItWorksSection(l10n: l10n),
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionAnchor(
                WwwSection.pricing,
                Padding(
                  padding: padding.copyWith(bottom: 24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WwwSectionHeader(title: l10n.wwwPricingTitle),
                          const SizedBox(height: 16),
                          _PricingRow(
                            icon: Icons.pets,
                            text: l10n.wwwPricingOwnerNote,
                          ),
                          const SizedBox(height: 12),
                          _PricingRow(
                            icon: Icons.handshake_outlined,
                            text: l10n.wwwPricingSitterNote,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionAnchor(
                WwwSection.signup,
                Padding(
                  padding: padding.copyWith(bottom: 24),
                  child: const WwwSitterSignupSection(),
                ),
              ),
            ),
            if (!MvpScope.hideWwwBlog) ...[
              SliverToBoxAdapter(
                child: _sectionAnchor(
                  WwwSection.blog,
                  Padding(
                    padding: padding.copyWith(bottom: 12),
                    child: WwwSectionHeader(title: l10n.wwwBlogTitle),
                  ),
                ),
              ),
              SliverPadding(
                padding: padding.copyWith(bottom: 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _BlogCard(
                      title: l10n.wwwBlog1Title,
                      description: l10n.wwwBlog1Desc,
                    ),
                    const SizedBox(height: 12),
                    _BlogCard(
                      title: l10n.wwwBlog2Title,
                      description: l10n.wwwBlog2Desc,
                    ),
                  ]),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: _sectionAnchor(
                WwwSection.testimonials,
                Padding(
                  padding: padding.copyWith(bottom: 12),
                  child: WwwSectionHeader(title: l10n.wwwTestimonialsTitle),
                ),
              ),
            ),
            SliverPadding(
              padding: padding.copyWith(bottom: 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _TestimonialCard(
                    name: l10n.wwwTestimonial1Name,
                    quote: l10n.wwwTestimonial1Quote,
                  ),
                  const SizedBox(height: 12),
                  _TestimonialCard(
                    name: l10n.wwwTestimonial2Name,
                    quote: l10n.wwwTestimonial2Quote,
                  ),
                  const SizedBox(height: 12),
                  _TestimonialCard(
                    name: l10n.wwwTestimonial3Name,
                    quote: l10n.wwwTestimonial3Quote,
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: padding.copyWith(bottom: 32),
                child: Card(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.wwwCtaTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.wwwCtaSubtitle),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => SsoNav.openSubdomain('owner'),
                          child: Text('🐕 ${l10n.wwwOwnerCta}'),
                        ),
                        if (!MvpScope.hideWwwSitterAppLink) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => SsoNav.openSubdomain('sitter'),
                            child: Text('🤝 ${l10n.wwwPartnerCta}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: WwwFooter()),
          ],
        ),
        context,
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (1, l10n.wwwHowStep1),
      (2, l10n.wwwHowStep2),
      (3, l10n.wwwHowStep3),
    ];
    final isMobile = V2Responsive.isMobile(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WwwSectionHeader(title: l10n.wwwHowItWorksTitle),
            const SizedBox(height: 16),
            if (isMobile)
              ...steps.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HowStep(number: s.$1, text: s.$2),
                  ))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps
                    .map(
                      (s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _HowStep(number: s.$1, text: s.$2),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            '$number',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.emoji,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final String emoji;
  final String title;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(quote, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
