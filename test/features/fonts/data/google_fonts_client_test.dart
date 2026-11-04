import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/fonts/data/google_fonts_client.dart';

/// Scripted [HttpGetter]: answers each URL from [routes].
class FakeHttp implements HttpGetter {
  FakeHttp(this.routes);

  final Map<String, FutureOr<HttpGetResponse> Function()> routes;
  final List<Uri> requested = <Uri>[];
  final List<Map<String, String>> headersSent = <Map<String, String>>[];

  @override
  Future<HttpGetResponse> get(
    Uri url, {
    Map<String, String> headers = const {},
    required Duration timeout,
    ProgressCallback? onProgress,
  }) async {
    requested.add(url);
    headersSent.add(headers);
    final handler = routes.entries.where((e) => url.toString().contains(e.key)).firstOrNull;
    if (handler == null) throw const SocketException('unreachable');
    final response = await handler.value();
    onProgress?.call(response.body.length, response.body.length);
    return response;
  }
}

HttpGetResponse text(int status, String body) =>
    HttpGetResponse(status, Uint8List.fromList(body.codeUnits));

final validTtf = Uint8List.fromList([0x00, 0x01, 0x00, 0x00, ...List<int>.filled(60, 7)]);

const fontCss = '''
@font-face {
  font-family: 'Hind Vadodara';
  font-style: normal;
  font-weight: 400;
  src: url(https://fonts.gstatic.com/s/hindvadodara/v16/abc.ttf) format('truetype');
}
''';

void main() {
  group('cssUri and parsing', () {
    test('builds the CSS API URL with an optional text subset', () {
      expect(
        GoogleFontsClient.cssUri('Hind Vadodara').toString(),
        'https://fonts.googleapis.com/css2?family=Hind+Vadodara',
      );
      expect(
        GoogleFontsClient.cssUri('Anton', text: 'Anton').queryParameters,
        {'family': 'Anton', 'text': 'Anton'},
      );
    });

    test('extracts the TrueType URL from a stylesheet', () {
      expect(
        GoogleFontsClient.parseTrueTypeUrl(fontCss),
        Uri.parse('https://fonts.gstatic.com/s/hindvadodara/v16/abc.ttf'),
      );
      expect(GoogleFontsClient.parseTrueTypeUrl('<html>Sign in to Wi-Fi</html>'), isNull);
    });
  });

  group('isReachable', () {
    test('is true only when the font server answers with a real stylesheet', () async {
      final client = GoogleFontsClient(http: FakeHttp({'css2': () => text(200, fontCss)}));
      expect(await client.isReachable(), isTrue);
    });

    test('a captive portal answering 200 with HTML counts as offline', () async {
      final client = GoogleFontsClient(
        http: FakeHttp({'css2': () => text(200, '<html>Please log in</html>')}),
      );
      expect(await client.isReachable(), isFalse);
    });

    test('server errors, DNS failures and timeouts count as offline', () async {
      expect(
        await GoogleFontsClient(http: FakeHttp({'css2': () => text(503, '')})).isReachable(),
        isFalse,
      );
      expect(await GoogleFontsClient(http: FakeHttp({})).isReachable(), isFalse);
      expect(
        await GoogleFontsClient(
          http: FakeHttp({'css2': () => throw TimeoutException('slow')}),
        ).isReachable(),
        isFalse,
      );
    });
  });

  group('downloadFont', () {
    test('fetches the stylesheet with a TrueType user agent, then the font file', () async {
      final http = FakeHttp({
        'css2': () => text(200, fontCss),
        'gstatic': () => HttpGetResponse(200, validTtf),
      });
      final progress = <int>[];

      final bytes = await GoogleFontsClient(http: http)
          .downloadFont('Hind Vadodara', onProgress: (received, _) => progress.add(received));

      expect(bytes, validTtf);
      expect(http.requested.last.host, 'fonts.gstatic.com');
      expect(http.headersSent.first['User-Agent'], GoogleFontsClient.trueTypeUserAgent);
      expect(progress, isNotEmpty);
    });

    test('reports unknown families, missing files and invalid font data', () async {
      Future<void> expectFailure(Map<String, FutureOr<HttpGetResponse> Function()> routes) {
        return expectLater(
          GoogleFontsClient(http: FakeHttp(routes)).downloadFont('X'),
          throwsA(isA<FontDownloadException>()),
        );
      }

      await expectFailure({'css2': () => text(400, 'bad family')});
      await expectFailure({'css2': () => text(200, '/* no font */')});
      await expectFailure({
        'css2': () => text(200, fontCss),
        'gstatic': () => text(200, '<html>not a font</html>'),
      });
      await expectFailure({});
    });
  });

  test('downloadPreview requests a subset for the given text', () async {
    final http = FakeHttp({
      'css2': () => text(200, fontCss),
      'gstatic': () => HttpGetResponse(200, validTtf),
    });

    await GoogleFontsClient(http: http).downloadPreview('Hind Vadodara', 'Hind Vadodara');

    expect(http.requested.first.queryParameters['text'], 'Hind Vadodara');
  });
}
