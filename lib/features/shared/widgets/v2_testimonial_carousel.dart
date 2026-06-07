import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/data/dummy_content.dart';
import 'package:kaki_empat/features/shared/widgets/v2_initial_avatar.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Carousel testimoni horizontal dengan auto-scroll setiap 5 detik.
class V2TestimonialCarousel extends StatefulWidget {
  const V2TestimonialCarousel({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<DummyTestimonial> items;

  @override
  State<V2TestimonialCarousel> createState() => _V2TestimonialCarouselState();
}

class _V2TestimonialCarouselState extends State<V2TestimonialCarousel> {
  late final PageController _pageCtrl;
  Timer? _autoTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    if (widget.items.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_currentPage + 1) % widget.items.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TestimonialCard(item: item),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final active = i == _currentPage;
            return Container(
              width: active ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.item});

  final DummyTestimonial item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                V2InitialAvatar(
                  initials: item.initials,
                  backgroundColor: item.avatarColor.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: theme.textTheme.titleSmall),
                      Text(
                        '${item.role} · ${item.city}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StarRating(rating: item.rating),
              ],
            ),
            const SizedBox(height: 12),
            Icon(Icons.format_quote, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item.quote,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 16, color: theme.colorScheme.tertiary),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Carousel testimoni sitter — data dari [DummyContent].
class V2SitterTestimonialCarousel extends StatelessWidget {
  const V2SitterTestimonialCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return V2TestimonialCarousel(
      title: l10n.sitterTestimonialsTitle,
      items: DummyContent.sitterTestimonials(l10n),
    );
  }
}
