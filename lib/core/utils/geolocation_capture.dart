import 'package:kaki_empat/core/web/browser_geolocation.dart';

typedef GeoCoordinates = ({double latitude, double longitude});

/// Ambil koordinat: GPS browser dulu, lalu fallback profil tersimpan.
Future<GeoCoordinates?> resolveCoordinates({
  double? storedLatitude,
  double? storedLongitude,
}) async {
  final browser = await readBrowserGeolocation();
  if (browser != null) {
    return (latitude: browser.latitude, longitude: browser.longitude);
  }
  if (storedLatitude != null && storedLongitude != null) {
    return (latitude: storedLatitude, longitude: storedLongitude);
  }
  return null;
}
