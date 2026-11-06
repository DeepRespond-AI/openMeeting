import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notice_presentation.g.dart';

/// Root and shell navigators share the policy, using separate observers. Record
/// refresh always runs; transient notifications never cover a dialog or sheet.
class NoticePresentation {
  final _popups = <Route<dynamic>>{};
  VoidCallback? onNavigation;
  bool get canShow => _popups.isEmpty;
  void opened(Route<dynamic> route) {
    if (route is PopupRoute) _popups.add(route);
    onNavigation?.call();
  }
  void closed(Route<dynamic> route) {
    _popups.remove(route);
    onNavigation?.call();
  }
}

class NoticeNavigatorObserver extends NavigatorObserver {
  NoticeNavigatorObserver(this.presentation);
  final NoticePresentation presentation;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => presentation.opened(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => presentation.closed(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => presentation.closed(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) presentation.closed(oldRoute);
    if (newRoute != null) presentation.opened(newRoute);
  }
}

@Riverpod(keepAlive: true)
NoticePresentation noticePresentation(Ref ref) => NoticePresentation();
