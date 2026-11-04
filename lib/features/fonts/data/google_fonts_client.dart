import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_editor/features/fonts/domain/font_file_validator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_fonts_client.g.dart';

/// Reports download progress: bytes received so far and the total, if known.
typedef ProgressCallback = void Function(int received, int? total);

/// Result of an HTTP GET.
class HttpGetResponse {
  const HttpGetResponse(this.statusCode, this.body);
  final int statusCode;
  final Uint8List body;
}

/// Minimal HTTP GET used by [GoogleFontsClient]; swapped out in tests.
abstract interface class HttpGetter {
  Future<HttpGetResponse> get(
    Uri url, {
    Map<String, String> headers,
    required Duration timeout,
    ProgressCallback? onProgress,
  });
}

/// [HttpGetter] backed by `dart:io` (no extra dependency).
class IoHttpGetter implements HttpGetter {
  @override
  Future<HttpGetResponse> get(
    Uri url, {
    Map<String, String> headers = const {},
    required Duration timeout,
    ProgressCallback? onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(url).timeout(timeout);
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(timeout);
      final total = response.contentLength >= 0 ? response.contentLength : null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(timeout)) {
        builder.add(chunk);
        onProgress?.call(builder.length, total);
      }
      return HttpGetResponse(response.statusCode, builder.takeBytes());
    } finally {
      client.close(force: true);
    }
  }
}

/// Thrown when a font cannot be downloaded.
class FontDownloadException implements Exception {
  const FontDownloadException(this.message);
  final String message;

  @override
  String toString() => 'FontDownloadException: $message';
}

/// Downloads fonts from the public Google Fonts CSS API (no API key).
class GoogleFontsClient {
  GoogleFontsClient({HttpGetter? http}) : _http = http ?? IoHttpGetter();

  final HttpGetter _http;

  /// A user agent without WOFF2 support, for which Google serves a single
  /// complete TrueType file per family (verified for all catalog fonts,
  /// including Devanagari and Gujarati ones).
  static const String trueTypeUserAgent =
      'Mozilla/5.0 (Linux; U; Android 4.0.3; en-us) AppleWebKit/534.30 (KHTML, like Gecko)';

  static const Duration reachabilityTimeout = Duration(seconds: 5);
  static const Duration downloadTimeout = Duration(seconds: 30);

  static final RegExp _trueTypeUrl =
      RegExp(r"url\((https://[^)\s]+)\)\s*format\('truetype'\)");

  /// CSS API URL for the Regular style of [family], optionally subset to the
  /// characters of [text].
  static Uri cssUri(String family, {String? text}) {
    return Uri.https('fonts.googleapis.com', '/css2', <String, String>{
      'family': family,
      'text': ?text,
    });
  }

  /// Extracts the TrueType font URL from a CSS API response, if present.
  static Uri? parseTrueTypeUrl(String css) {
    final match = _trueTypeUrl.firstMatch(css);
    return match == null ? null : Uri.tryParse(match.group(1)!);
  }

  /// Whether the font server can actually be reached right now.
  ///
  /// Makes a tiny real request instead of trusting the network type, so
  /// "mobile data on but no internet", captive Wi-Fi portals (which answer
  /// with an HTML page) and blocked DNS all count as offline.
  Future<bool> isReachable() async {
    try {
      final response = await _http.get(
        cssUri('Roboto', text: 'a'),
        headers: const {'User-Agent': trueTypeUserAgent},
        timeout: reachabilityTimeout,
      );
      return response.statusCode == 200 &&
          String.fromCharCodes(response.body).contains('@font-face');
    } on Object {
      return false;
    }
  }

  /// Downloads the Regular TrueType file of [family].
  Future<Uint8List> downloadFont(String family, {ProgressCallback? onProgress}) {
    return _download(cssUri(family), family, onProgress: onProgress);
  }

  /// Downloads a tiny font containing only the glyphs of [text] in [family],
  /// used to preview a font before it is installed.
  Future<Uint8List> downloadPreview(String family, String text) {
    return _download(cssUri(family, text: text), family);
  }

  Future<Uint8List> _download(
    Uri cssUrl,
    String family, {
    ProgressCallback? onProgress,
  }) async {
    final HttpGetResponse css;
    final HttpGetResponse font;
    try {
      css = await _http.get(
        cssUrl,
        headers: const {'User-Agent': trueTypeUserAgent},
        timeout: downloadTimeout,
      );
      if (css.statusCode != 200) {
        throw FontDownloadException('"$family" is not available (HTTP ${css.statusCode}).');
      }
      final fontUrl = parseTrueTypeUrl(String.fromCharCodes(css.body));
      if (fontUrl == null) {
        throw FontDownloadException('No downloadable file was found for "$family".');
      }
      font = await _http.get(fontUrl, timeout: downloadTimeout, onProgress: onProgress);
    } on FontDownloadException {
      rethrow;
    } on Object catch (error) {
      throw FontDownloadException('Download of "$family" failed: $error');
    }

    if (font.statusCode != 200 || FontFileValidator.detect(font.body) == null) {
      throw FontDownloadException('The downloaded file for "$family" is not a valid font.');
    }
    return font.body;
  }
}

/// App-wide singleton [GoogleFontsClient].
@Riverpod(keepAlive: true)
GoogleFontsClient googleFontsClient(Ref ref) => GoogleFontsClient();
