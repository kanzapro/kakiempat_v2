import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Ambil koordinat GPS browser (Flutter web).
Future<({double latitude, double longitude})?> readBrowserGeolocation() async {
  final completer = Completer<({double latitude, double longitude})?>();

  void onSuccess(web.GeolocationPosition position) {
    if (completer.isCompleted) return;
    completer.complete((
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
    ));
  }

  void onError(web.GeolocationPositionError error) {
    if (completer.isCompleted) return;
    completer.complete(null);
  }

  web.window.navigator.geolocation.getCurrentPosition(
    onSuccess.toJS,
    onError.toJS,
  );

  return completer.future.timeout(
    const Duration(seconds: 12),
    onTimeout: () => null,
  );
}
