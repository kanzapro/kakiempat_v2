import 'package:intl/intl.dart';

abstract final class V2Formatters {
  static final _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String money(int amount) {
    if (amount <= 0) return '—';
    return _idr.format(amount);
  }

  static String dateTime(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy, HH:mm', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// Waktu relatif singkat, mis. "2 menit lalu".
  static String relativeTime(String raw, {String locale = 'id'}) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) {
        return locale.startsWith('en') ? 'Just now' : 'Baru saja';
      }
      if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return locale.startsWith('en') ? '$m min ago' : '$m menit lalu';
      }
      if (diff.inHours < 24) {
        final h = diff.inHours;
        return locale.startsWith('en') ? '$h hr ago' : '$h jam lalu';
      }
      if (diff.inDays < 7) {
        final d = diff.inDays;
        return locale.startsWith('en') ? '$d d ago' : '$d hari lalu';
      }
      return dateTime(raw);
    } catch (_) {
      return raw;
    }
  }

  static String petSpeciesEmoji(String species) {
    final s = species.trim().toLowerCase();
    return switch (s) {
      'dog' || 'anjing' => '🐕',
      'cat' || 'kucing' => '🐈',
      _ => '🐾',
    };
  }

  static String petSpeciesLabel(String species) {
    final s = species.trim().toLowerCase();
    return switch (s) {
      'dog' => 'Anjing',
      'cat' => 'Kucing',
      'anjing' => 'Anjing',
      'kucing' => 'Kucing',
      _ => species.isNotEmpty ? species : 'Hewan',
    };
  }

  /// Contoh: "🐕 Milo (Anjing)"
  static String petDisplayLabel({
    required String name,
    String species = '',
  }) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Hewan';
    if (species.trim().isEmpty) {
      return '${petSpeciesEmoji('')} $displayName';
    }
    return '${petSpeciesEmoji(species)} $displayName (${petSpeciesLabel(species)})';
  }

  static String bookingStatusLabel(String status) {
    final normalized = status.toLowerCase().replaceAll('_', '');
    return switch (normalized) {
      'open' => 'Menunggu pengasuh',
      'matched' => 'Sudah ditugaskan',
      'pending' => 'Menunggu konfirmasi',
      'awaitingpayment' => 'Menunggu pembayaran',
      'pendingverification' => 'Verifikasi pembayaran',
      'paid' => 'Lunas',
      'paymentrejected' => 'Pembayaran ditolak',
      'cancelled' => 'Dibatalkan',
      'confirmed' => 'Dikonfirmasi',
      'en_route' => 'Dalam perjalanan',
      'in_progress' => 'Sedang berlangsung',
      'completed' => 'Selesai',
      _ => status,
    };
  }

  static String sitterStatusLabel(String status) {
    return switch (status) {
      'draft' => 'Draft',
      'pending_verification' => 'Menunggu verifikasi',
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      _ => status,
    };
  }

  static String serviceLabel(String code) {
    return switch (code) {
      'dog_walking' => 'Dog Walking',
      'pet_walking_group' => 'Social Walk',
      'pet_swimming' => 'Pet Swimming',
      'pet_sitting' => 'Pet Sitting',
      'pet_daycare' => 'Pet Daycare',
      'pet_boarding' => 'Pet Boarding',
      'pet_hotel' => 'Pet Hotel',
      'pet_adoption' => 'Pet Adoption',
      'pet_bike' => 'Pet Bike',
      'pet_taxi' => 'Pet Taxi',
      'grooming_di_tempat' => 'Grooming di Tempat',
      'pet_spa' => 'Pet Spa',
      'vet_home_visit' => 'Vet Home Visit',
      'vet_clinic' => 'Vet Clinic',
      'training_behavioral' => 'Training / Behavioral',
      'pet_training_advanced' => 'Advanced Training',
      'pet_photography' => 'Pet Photography',
      'pet_bereavement' => 'Pet Bereavement',
      'pet_events' => 'Pet Events',
      _ => code.replaceAll('_', ' '),
    };
  }
}
