import 'package:flutter/material.dart';

class SitterBadge {
  const SitterBadge({
    required this.code,
    required this.label,
    this.icon = Icons.verified,
  });

  final String code;
  final String label;
  final IconData icon;

  factory SitterBadge.fromJson(Map<String, dynamic> json) {
    final code = '${json['code'] ?? ''}';
    return SitterBadge(
      code: code,
      label: '${json['label'] ?? code}',
      icon: _iconForCode(code),
    );
  }

  static IconData _iconForCode(String code) => switch (code) {
        'verified' => Icons.verified,
        'on_time' => Icons.schedule,
        'friendly' => Icons.favorite,
        'favorite' => Icons.star,
        'promo' => Icons.local_offer,
        _ => Icons.military_tech_outlined,
      };
}

class V2SitterBadgeRow extends StatelessWidget {
  const V2SitterBadgeRow({
    super.key,
    required this.badges,
    this.compact = false,
  });

  final List<SitterBadge> badges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.map((b) {
        return Chip(
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(b.icon, size: compact ? 14 : 16, color: theme.colorScheme.primary),
          label: Text(
            b.label,
            style: compact
                ? theme.textTheme.labelSmall
                : theme.textTheme.labelMedium,
          ),
          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        );
      }).toList(),
    );
  }
}
