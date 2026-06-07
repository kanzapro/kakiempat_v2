import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// HTTP client web yang mengirim cookie lintas subdomain (*.kakiempat.com).
http.Client createCredentialedHttpClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
