import 'package:deeprespond_im/deeprespond_im.dart';

/// Internal keys only; user-facing wording is provided by l10n in the UI.
const rtcJoinTimedOut = 'rtc_join_timed_out';
const rtcReleaseTimedOut = 'rtc_release_timed_out';

String? rtcConnectionFailure(DRException error) =>
    error.code == LocalErrorCode.invalidState && error.reason == 'join_deadline_exceeded'
    ? rtcJoinTimedOut
    : null;
