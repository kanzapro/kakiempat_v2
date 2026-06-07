import 'package:flutter/material.dart';

class AuthLocaleToggle extends StatelessWidget {
  const AuthLocaleToggle({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'id', label: Text('ID')),
        ButtonSegment(value: 'en', label: Text('EN')),
      ],
      selected: {locale.languageCode},
      onSelectionChanged: (s) => onChanged(Locale(s.first)),
    );
  }
}
