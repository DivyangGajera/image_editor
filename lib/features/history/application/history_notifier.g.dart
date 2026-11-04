// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Project-scoped [HistoryManager]. Disposed (and its Hive box closed) when the
/// last listener of the project's history goes away.

@ProviderFor(historyManager)
final historyManagerProvider = HistoryManagerFamily._();

/// Project-scoped [HistoryManager]. Disposed (and its Hive box closed) when the
/// last listener of the project's history goes away.

final class HistoryManagerProvider
    extends $FunctionalProvider<HistoryManager, HistoryManager, HistoryManager>
    with $Provider<HistoryManager> {
  /// Project-scoped [HistoryManager]. Disposed (and its Hive box closed) when the
  /// last listener of the project's history goes away.
  HistoryManagerProvider._({
    required HistoryManagerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'historyManagerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$historyManagerHash();

  @override
  String toString() {
    return r'historyManagerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<HistoryManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryManager create(Ref ref) {
    final argument = this.argument as String;
    return historyManager(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryManager>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryManagerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$historyManagerHash() => r'd4a117b174ef46292132113882533b7c8be962ff';

/// Project-scoped [HistoryManager]. Disposed (and its Hive box closed) when the
/// last listener of the project's history goes away.

final class HistoryManagerFamily extends $Family
    with $FunctionalFamilyOverride<HistoryManager, String> {
  HistoryManagerFamily._()
    : super(
        retry: null,
        name: r'historyManagerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Project-scoped [HistoryManager]. Disposed (and its Hive box closed) when the
  /// last listener of the project's history goes away.

  HistoryManagerProvider call(String projectId) =>
      HistoryManagerProvider._(argument: projectId, from: this);

  @override
  String toString() => r'historyManagerProvider';
}

/// Riverpod notifier coordinating canvas undo/redo history operations.

@ProviderFor(HistoryNotifier)
final historyProvider = HistoryNotifierFamily._();

/// Riverpod notifier coordinating canvas undo/redo history operations.
final class HistoryNotifierProvider
    extends $NotifierProvider<HistoryNotifier, HistoryState> {
  /// Riverpod notifier coordinating canvas undo/redo history operations.
  HistoryNotifierProvider._({
    required HistoryNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'historyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$historyNotifierHash();

  @override
  String toString() {
    return r'historyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HistoryNotifier create() => HistoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$historyNotifierHash() => r'403bb1af4508746328759d0cb947b0dab1a71449';

/// Riverpod notifier coordinating canvas undo/redo history operations.

final class HistoryNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          HistoryNotifier,
          HistoryState,
          HistoryState,
          HistoryState,
          String
        > {
  HistoryNotifierFamily._()
    : super(
        retry: null,
        name: r'historyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Riverpod notifier coordinating canvas undo/redo history operations.

  HistoryNotifierProvider call(String projectId) =>
      HistoryNotifierProvider._(argument: projectId, from: this);

  @override
  String toString() => r'historyProvider';
}

/// Riverpod notifier coordinating canvas undo/redo history operations.

abstract class _$HistoryNotifier extends $Notifier<HistoryState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  HistoryState build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HistoryState, HistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryState, HistoryState>,
              HistoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
