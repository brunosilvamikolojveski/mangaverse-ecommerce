import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

http.Client createHttpClient() => BrowserClient()..withCredentials = true;

String? readXsrfToken() {
  for (final cookie in web.document.cookie.split(';')) {
    final value = cookie.trim();
    if (value.startsWith('XSRF-TOKEN=')) {
      return Uri.decodeComponent(value.substring('XSRF-TOKEN='.length));
    }
  }

  return null;
}
