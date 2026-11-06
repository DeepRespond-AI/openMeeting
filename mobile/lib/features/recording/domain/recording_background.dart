/// Keeps the app alive while recording in the background and shows the ongoing
/// recording to the user (Android foreground service notification with elapsed time and a
/// stop action). On iOS the `audio` background mode does this and the service is a no-op.
abstract interface class RecordingBackground {
  /// Starts the background service. Never throws: failures only lose the notification.
  Future<void> start({
    required String channelName,
    required String title,
    required String text,
    required String stopLabel,
  });

  /// Updates the notification text (e.g. the elapsed time).
  Future<void> update({required String text});

  Future<void> stop();

  /// Fires when the user pressed the notification's stop action.
  Stream<void> get stopRequests;
}
