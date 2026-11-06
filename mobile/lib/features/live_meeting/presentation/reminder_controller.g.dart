// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Foreground reminders only. Background push requires platform credentials.

@ProviderFor(LiveReminder)
final liveReminderProvider = LiveReminderProvider._();

/// Foreground reminders only. Background push requires platform credentials.
final class LiveReminderProvider
    extends $NotifierProvider<LiveReminder, LiveSchedule?> {
  /// Foreground reminders only. Background push requires platform credentials.
  LiveReminderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveReminderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveReminderHash();

  @$internal
  @override
  LiveReminder create() => LiveReminder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveSchedule? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveSchedule?>(value),
    );
  }
}

String _$liveReminderHash() => r'855641e2dd0c802dda96a0ad331b004112084e85';

/// Foreground reminders only. Background push requires platform credentials.

abstract class _$LiveReminder extends $Notifier<LiveSchedule?> {
  LiveSchedule? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LiveSchedule?, LiveSchedule?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LiveSchedule?, LiveSchedule?>,
              LiveSchedule?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
