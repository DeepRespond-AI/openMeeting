import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meetings_changed.g.dart';

/// App-wide "the set of meetings changed" signal (a revision counter).
///
/// Features that create or delete meetings outside the list screen (recording,
/// import) call [MeetingsChanged.bump]; providers that cache meeting lists
/// `ref.watch` it and rebuild. Lives in core so features never import each other.
@Riverpod(keepAlive: true)
class MeetingsChanged extends _$MeetingsChanged {
  @override
  int build() => 0;

  void bump() => state++;
}
