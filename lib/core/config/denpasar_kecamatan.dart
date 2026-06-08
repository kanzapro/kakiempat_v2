/// 4 kecamatan Kota Denpasar — wilayah operasional MVP hyperlocal.
abstract final class DenpasarKecamatan {
  static const barat = 'Denpasar Barat';
  static const timur = 'Denpasar Timur';
  static const selatan = 'Denpasar Selatan';
  static const utara = 'Denpasar Utara';

  static const all = [barat, timur, selatan, utara];

  static bool isValid(String? value) =>
      value != null && all.contains(value.trim());

  static String? normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return isValid(trimmed) ? trimmed : null;
  }
}
