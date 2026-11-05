import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internet_check.g.dart';

/// Whether the internet can actually be reached right now.
abstract interface class InternetCheck {
  Future<bool> isOnline();
}

/// [InternetCheck] making a tiny real request to Google's connectivity
/// endpoint, which answers 204 with an empty body.
///
/// Trusting the network type is not enough: "mobile data on but no balance",
/// captive Wi-Fi portals (which answer 200 or redirect) and blocked DNS all
/// count as offline here.
class HttpInternetCheck implements InternetCheck {
  HttpInternetCheck({Uri? probe, this.timeout = const Duration(seconds: 5)})
      : probe = probe ?? Uri.parse('https://connectivitycheck.gstatic.com/generate_204');

  final Uri probe;
  final Duration timeout;

  @override
  Future<bool> isOnline() async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(probe).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      await response.drain<void>();
      return response.statusCode == HttpStatus.noContent;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}

/// App-wide [InternetCheck]; overridden in tests.
@Riverpod(keepAlive: true)
InternetCheck internetCheck(Ref ref) => HttpInternetCheck();
