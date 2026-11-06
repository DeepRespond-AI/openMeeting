/// `MM:SS`, or `H:MM:SS` from one hour on (recording timer, notification).
String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(Duration.minutesPerHour).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(Duration.secondsPerMinute).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Formats a timeline position in seconds like [formatElapsed].
String formatSeconds(double seconds) =>
    formatElapsed(Duration(milliseconds: (seconds * Duration.millisecondsPerSecond).round()));
