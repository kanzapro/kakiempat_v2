import 'package:flutter/material.dart';

/// Avatar hewan dengan Hero animation (ikon Material).
class V2PetAvatar extends StatelessWidget {
  const V2PetAvatar({
    super.key,
    required this.petId,
    this.size = 40,
    this.heroTag,
  });

  final String petId;
  final double size;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      child: Icon(Icons.pets, size: size * 0.5, color: scheme.onPrimaryContainer),
    );
    final tag = heroTag ?? 'pet-$petId';
    if (petId.isEmpty) return avatar;
    return Hero(tag: tag, child: avatar);
  }
}
