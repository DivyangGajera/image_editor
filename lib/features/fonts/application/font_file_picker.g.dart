// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_file_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [FontFilePicker]; overridden in tests.

@ProviderFor(fontFilePicker)
final fontFilePickerProvider = FontFilePickerProvider._();

/// App-wide [FontFilePicker]; overridden in tests.

final class FontFilePickerProvider
    extends $FunctionalProvider<FontFilePicker, FontFilePicker, FontFilePicker>
    with $Provider<FontFilePicker> {
  /// App-wide [FontFilePicker]; overridden in tests.
  FontFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontFilePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontFilePickerHash();

  @$internal
  @override
  $ProviderElement<FontFilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FontFilePicker create(Ref ref) {
    return fontFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FontFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FontFilePicker>(value),
    );
  }
}

String _$fontFilePickerHash() => r'0df35e9ff8be6a28181e4b5470c97511a89dac0c';
