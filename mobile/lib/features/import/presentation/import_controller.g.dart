// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Audio import (desktop `import.rs`): pick → multipart upload with progress → submitted.
/// Only the upload blocks the page; [BackgroundImports] follows the server transcription.

@ProviderFor(ImportController)
final importControllerProvider = ImportControllerProvider._();

/// Audio import (desktop `import.rs`): pick → multipart upload with progress → submitted.
/// Only the upload blocks the page; [BackgroundImports] follows the server transcription.
final class ImportControllerProvider
    extends $NotifierProvider<ImportController, ImportState> {
  /// Audio import (desktop `import.rs`): pick → multipart upload with progress → submitted.
  /// Only the upload blocks the page; [BackgroundImports] follows the server transcription.
  ImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importControllerHash();

  @$internal
  @override
  ImportController create() => ImportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportState>(value),
    );
  }
}

String _$importControllerHash() => r'4c4f45f69444d97191ba483acd9bdf45d6695122';

/// Audio import (desktop `import.rs`): pick → multipart upload with progress → submitted.
/// Only the upload blocks the page; [BackgroundImports] follows the server transcription.

abstract class _$ImportController extends $Notifier<ImportState> {
  ImportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ImportState, ImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImportState, ImportState>,
              ImportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
