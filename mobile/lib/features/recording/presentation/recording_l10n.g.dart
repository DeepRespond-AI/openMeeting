// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_l10n.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Localizations for text produced outside the widget tree (meeting title, notification),
/// resolved like `MaterialApp` does: the UI language setting, else the device locale.

@ProviderFor(recordingL10n)
final recordingL10nProvider = RecordingL10nProvider._();

/// Localizations for text produced outside the widget tree (meeting title, notification),
/// resolved like `MaterialApp` does: the UI language setting, else the device locale.

final class RecordingL10nProvider
    extends
        $FunctionalProvider<
          AppLocalizations,
          AppLocalizations,
          AppLocalizations
        >
    with $Provider<AppLocalizations> {
  /// Localizations for text produced outside the widget tree (meeting title, notification),
  /// resolved like `MaterialApp` does: the UI language setting, else the device locale.
  RecordingL10nProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingL10nProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingL10nHash();

  @$internal
  @override
  $ProviderElement<AppLocalizations> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLocalizations create(Ref ref) {
    return recordingL10n(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLocalizations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLocalizations>(value),
    );
  }
}

String _$recordingL10nHash() => r'7499d01a8ab4809d2813fcb0a3bf6ebf4dc3064a';
