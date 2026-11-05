import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/network/internet_check.dart';

void main() {
  late HttpServer server;
  late int status;

  setUp(() async {
    status = HttpStatus.noContent;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response.statusCode = status;
      if (status == HttpStatus.found) request.response.headers.set('location', 'http://portal.local/');
      if (status == HttpStatus.ok) request.response.write('<html>Sign in to Wi-Fi</html>');
      request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  HttpInternetCheck check() => HttpInternetCheck(
        probe: Uri.parse('http://${server.address.address}:${server.port}/generate_204'),
        timeout: const Duration(seconds: 2),
      );

  test('a 204 answer means online', () async {
    expect(await check().isOnline(), isTrue);
  });

  test('a captive portal page counts as offline', () async {
    status = HttpStatus.ok;
    expect(await check().isOnline(), isFalse);
  });

  test('a captive portal redirect counts as offline', () async {
    status = HttpStatus.found;
    expect(await check().isOnline(), isFalse);
  });

  test('an unreachable server counts as offline', () async {
    final unreachable = check();
    await server.close(force: true);
    expect(await unreachable.isOnline(), isFalse);
  });
}
