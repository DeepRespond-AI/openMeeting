// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pendingQueue)
final pendingQueueProvider = PendingQueueProvider._();

final class PendingQueueProvider
    extends $FunctionalProvider<PendingQueue, PendingQueue, PendingQueue>
    with $Provider<PendingQueue> {
  PendingQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingQueueHash();

  @$internal
  @override
  $ProviderElement<PendingQueue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PendingQueue create(Ref ref) {
    return pendingQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingQueue>(value),
    );
  }
}

String _$pendingQueueHash() => r'6820f9acb57f6b19d4b38a49e13238030376927d';
