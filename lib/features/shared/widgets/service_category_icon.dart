import 'package:flutter/material.dart';

/// Material icon per kategori layanan dari API (bukan label teks).
IconData serviceCategoryIcon(String category) {
  return switch (category) {
    'sports' => Icons.directions_run_outlined,
    'boarding' => Icons.home_outlined,
    'transport' => Icons.local_taxi_outlined,
    'grooming' => Icons.content_cut_outlined,
    'health' => Icons.medical_services_outlined,
    'training' => Icons.school_outlined,
    'events' => Icons.celebration_outlined,
    _ => Icons.pets_outlined,
  };
}
