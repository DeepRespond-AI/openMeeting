/// Route paths. Navigate with `context.go(AppRoutes.meetings)` /
/// `context.push(AppRoutes.meetingDetail(id))` — never inline path strings.
abstract final class AppRoutes {
  /// Splash while the session is restored.
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  /// Home.
  static const String meetings = '/meetings';
  static const String history = '/history';
  static const String liveRoom = '/live-room';
  static const String messages = '/messages';
  static const String messageChat = '/messages/chat';
  static const String imGroup = '/messages/group';
  static String messageThread(String key) =>
      Uri(path: messageChat, queryParameters: {'key': key}).toString();
  static String groupDetail(String id) =>
      Uri(path: imGroup, queryParameters: {'id': id}).toString();
  static const String recording = '/recording';
  static const String recordingTools = '/recording-tools';
  static const String import = '/import';
  static const String settings = '/settings';

  /// Blocking "update required" page (forced upgrade).
  static const String forceUpdate = '/update';

  /// Path parameter name of [meetingDetail].
  static const String meetingIdParam = 'id';

  /// Pattern of the meeting detail route (child of [meetings]).
  static const String meetingDetailPattern = ':$meetingIdParam';

  static String meetingDetail(String id) => '$meetings/${Uri.encodeComponent(id)}';
}
