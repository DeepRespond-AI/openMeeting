import '../../../core/router/app_routes.dart';

/// Locations of the meeting detail page, including its query parameters.
///
/// Other features (recording, import) navigate with
/// `context.go(MeetingDetailRoute.location(id, autoSummary: true))`; the page reads the
/// parameter through `GoRouterState.of(context)`.
abstract final class MeetingDetailRoute {
  /// Query parameter that asks the detail page to start a summary once on open.
  static const String autoSummaryParam = 'autoSummary';
  static const String autoSummaryOn = '1';

  static String location(String meetingId, {bool autoSummary = false}) {
    final path = AppRoutes.meetingDetail(meetingId);
    if (!autoSummary) return path;
    final query = Uri(queryParameters: {autoSummaryParam: autoSummaryOn}).query;
    return '$path?$query';
  }

  static bool wantsAutoSummary(Map<String, String> queryParameters) =>
      queryParameters[autoSummaryParam] == autoSummaryOn;
}
