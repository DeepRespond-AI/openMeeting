import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'live_activity.g.dart';

/// Prevent forced installation/navigation from interrupting a joined meeting.
@Riverpod(keepAlive: true)
class LiveActivity extends _$LiveActivity {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}
