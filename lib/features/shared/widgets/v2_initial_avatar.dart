import 'package:flutter/material.dart';

/// Avatar lingkaran dengan inisial nama.
class V2InitialAvatar extends StatelessWidget {
  const V2InitialAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.backgroundColor,
  });

  final String initials;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? scheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
