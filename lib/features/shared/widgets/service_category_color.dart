import 'package:flutter/material.dart';

/// Warna aksen per kategori layanan (7 kategori).
Color serviceCategoryColor(String category) {
  return switch (category) {
    'sports' => const Color(0xFF2E7D5B),
    'boarding' => const Color(0xFF3D6B9E),
    'transport' => const Color(0xFF7B5EA7),
    'grooming' => const Color(0xFFE07B54),
    'health' => const Color(0xFFD64550),
    'training' => const Color(0xFF4A8BC9),
    'events' => const Color(0xFFE8A838),
    _ => const Color(0xFF1F5C4A),
  };
}
