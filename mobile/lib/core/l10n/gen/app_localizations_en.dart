// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authTabLogin => 'Sign in';

  @override
  String get authTabRegister => 'Register';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneHint => '11-digit mobile number';

  @override
  String get authPhonePrefix => '+86 ';

  @override
  String get authPhoneInvalid => 'Enter a valid mainland China mobile number';

  @override
  String get authCodeLabel => 'Verification code';

  @override
  String authCodeHint(int length) {
    return '$length-digit SMS code';
  }

  @override
  String authCodeInvalid(int length) {
    return 'Enter the $length-digit code';
  }

  @override
  String get authSendCode => 'Get code';

  @override
  String get authResendCode => 'Resend';

  @override
  String authResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authSending => 'Sending…';

  @override
  String get authCodeSent => 'Code sent. Check your SMS.';

  @override
  String authDevCodeHint(String code) {
    return 'Dev code: $code (tap to fill)';
  }

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authNameRequired => 'Please enter your name';

  @override
  String authNameTooLong(int max) {
    return 'Name must be at most $max characters';
  }

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authRegisterButton => 'Register and sign in';

  @override
  String get authRegistrationClosed =>
      'Registration is closed on this server. Ask your administrator for an account.';

  @override
  String get authSmsNotReady =>
      'SMS is not configured on this server; verification codes cannot be sent yet.';

  @override
  String authConfigLoadFailed(String detail) {
    return 'Could not load the sign-in settings: $detail';
  }

  @override
  String get authServerRequired =>
      'This build has no service configured, so you cannot sign in. Contact your administrator.';

  @override
  String get authMethodPassword => 'Password';

  @override
  String get authMethodCode => 'SMS code';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String authPasswordHint(int min, int max) {
    return '$min–$max characters with letters and digits';
  }

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordHint => 'Enter the password again';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String authPasswordLength(int min, int max) {
    return 'Password must be $min–$max characters';
  }

  @override
  String get authPasswordSpaces => 'Password cannot start or end with a space';

  @override
  String get authPasswordLetterDigit => 'Password must contain both letters and digits';

  @override
  String get authPasswordMismatch => 'The two passwords do not match';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authBackToLogin => 'Back to sign in';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetHint =>
      'Verify your mobile number with an SMS code, then choose a new password.';

  @override
  String get authResetButton => 'Reset password and sign in';

  @override
  String get imMessageActions => 'Message actions';

  @override
  String get imMessageCopy => 'Copy';

  @override
  String get imMessageCopied => 'Copied';

  @override
  String get imMessageDelete => 'Delete';

  @override
  String get imMessageCancel => 'Cancel';

  @override
  String get imMessageConfirm => 'Confirm';

  @override
  String get imMessageDeleteTitle => 'Delete this message?';

  @override
  String get imMessageDeleteDescription =>
      'This only removes it from your history. Other participants keep their copy.';

  @override
  String get imMessageRecalledSelf => 'You recalled a message';

  @override
  String imMessageRecalledOther(String name) {
    return '$name recalled a message';
  }

  @override
  String imMessageRecallExpiredMinutes(int minutes) {
    return 'Cannot recall messages sent more than $minutes minutes ago';
  }

  @override
  String imMessageRecallExpiredSeconds(int seconds) {
    return 'Cannot recall messages sent more than $seconds seconds ago';
  }

  @override
  String get imMessageRecallUnavailable => 'This message cannot be recalled';

  @override
  String get imMessageSending => 'Sending…';

  @override
  String get imMessageSendFailed => 'Failed to send';

  @override
  String get appName => 'DR Meeting';

  @override
  String commonTextTooLong(int max) {
    return 'Use at most $max characters.';
  }

  @override
  String get appTagline => 'AI meeting assistant';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonStart => 'Start';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonProcessing => 'Processing…';

  @override
  String get commonEmpty => 'Nothing here yet';

  @override
  String get commonEnabled => 'Enabled';

  @override
  String get commonDisabled => 'Disabled';

  @override
  String get commonComingSoon => 'This feature is coming soon';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get timeToday => 'Today';

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String errorWithDetail(String detail) {
    return 'Error: $detail';
  }

  @override
  String get errorNetwork => 'Cannot reach the server. Check your network or the server address.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String get errorBadRequest => 'The request was rejected.';

  @override
  String get errorUnauthorized => 'Your session is no longer valid. Please sign in again.';

  @override
  String get errorForbidden => 'You are not allowed to do this.';

  @override
  String get errorNotFound => 'Not found, or it has been deleted.';

  @override
  String get errorConflict => 'Conflict. Refresh and try again.';

  @override
  String get errorPayloadTooLarge => 'The content is too large for the server.';

  @override
  String get errorInvalidInput => 'Invalid input. Please check and try again.';

  @override
  String get errorRateLimited => 'Too many requests. Please try again later.';

  @override
  String get errorUnavailable => 'The service is temporarily unavailable.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorCancelled => 'Cancelled';

  @override
  String get errorNotConfigured => 'No server address has been set.';

  @override
  String get errorUnknown => 'An unknown error occurred.';

  @override
  String get authSessionExpired => 'Your session has expired. Please sign in again.';

  @override
  String get navOnboarding => 'Welcome';

  @override
  String get navLogin => 'Sign in';

  @override
  String get navMeetings => 'Meetings';

  @override
  String get navMeetingDetail => 'Meeting';

  @override
  String get navRecording => 'Record';

  @override
  String get navImport => 'Import audio';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get meetingsEmpty => 'No meetings yet';

  @override
  String get meetingsUntitled => 'Untitled meeting';

  @override
  String transcriptionLanguageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'auto': 'Auto detect',
      'zh': 'Chinese',
      'en': 'English',
      'ja': 'Japanese',
      'ko': 'Korean',
      'yue': 'Cantonese',
      'de': 'German',
      'fr': 'French',
      'es': 'Spanish',
      'ru': 'Russian',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get liveMediaConnectingInBackground =>
      'Audio/video is connecting in the background. Chat and member controls are available.';

  @override
  String get liveMediaReleasing => 'Waiting for the previous audio/video connection to close…';

  @override
  String get liveMediaReleaseTimedOut =>
      'The previous audio/video connection is still closing. Retry shortly, or leave this meeting.';

  @override
  String get liveMediaJoinTimedOut =>
      'The audio/video service was not ready before the join deadline. Try again later; meeting controls and chat remain available.';

  @override
  String get liveChatMessageHint => 'Message everyone';

  @override
  String get liveChatEmoji => 'Emoji';

  @override
  String get liveChatEmojiFaces => 'Faces';

  @override
  String get liveChatEmojiGestures => 'Gestures';

  @override
  String get liveChatEmojiSymbols => 'Symbols';

  @override
  String get liveShareStop => 'Stop sharing';

  @override
  String get liveShareStarting => 'Starting screen share…';

  @override
  String get liveShareSharing => 'Sharing your screen';

  @override
  String get liveShareCaptureHint => 'Participants can see the screen content you choose to share';

  @override
  String get liveShareDenied => 'Screen capture was not allowed. Try again and allow sharing.';

  @override
  String get liveShareFailed => 'Screen sharing failed. Check your connection and try again.';

  @override
  String get liveShareReplaced => 'Another participant replaced your screen share';

  @override
  String get liveShareStopFailed => 'Capture stopped. Refresh to confirm the sharing state.';

  @override
  String get liveShareWaiting => 'Receiving shared screen…';

  @override
  String get liveShareReceiveFailed => 'No shared screen received. Refresh to retry.';

  @override
  String liveShareBy(String name) {
    return 'Shared by $name';
  }

  @override
  String get liveSpeaking => 'Speaking';

  @override
  String get liveNetwork => 'Network quality';

  @override
  String get liveNetworkUnknown => 'Unknown';

  @override
  String get liveNetworkGood => 'Good';

  @override
  String get liveNetworkFair => 'Fair';

  @override
  String get liveNetworkPoor => 'Poor';

  @override
  String get liveNetworkScope =>
      'RTC link metrics between this device and the meeting media service. Unknown when no sample is available.';

  @override
  String get liveNetworkRtt => 'Round-trip latency';

  @override
  String get liveNetworkLoss => 'Packet loss';

  @override
  String get liveNetworkNoData => 'No data';

  @override
  String get liveMinimize => 'Go home and stay connected';

  @override
  String get liveReturnMeeting => 'Return to meeting';

  @override
  String get liveSessionOngoing => 'Meeting in progress; audio and sharing stay connected';

  @override
  String get liveRoomConflict =>
      'Returned to your current meeting. Leave it before joining another.';

  @override
  String get imUnknownUser => 'User';

  @override
  String get liveRecordingVersionMismatch =>
      'This server does not support automatic meeting recording. Update it and retry.';

  @override
  String get liveSharedRecord => 'Shared attendance record · Read only';

  @override
  String get liveSharedSummaryEmpty => 'The summary is not ready yet. Refresh later to check.';

  @override
  String get liveDownloadAudio => 'Cloud download';

  @override
  String get liveDownloadingAudio => 'Downloading recording…';

  @override
  String get liveAudioSaved => 'Recording saved. You can share or save it to Files.';

  @override
  String get liveExportAudio => 'Share or save recording';

  @override
  String get liveRecordEndedNotice =>
      'Meeting ended. The recording is processing in the background.';

  @override
  String get liveRecordCompletedNotice => 'The meeting recording and summary are ready.';

  @override
  String get liveRecordFailedNotice =>
      'Meeting processing failed. Any saved audio remains available.';

  @override
  String get liveViewRecord => 'View record';

  @override
  String get liveHome => 'Home';

  @override
  String get liveHistory => 'Meetings';

  @override
  String get liveMine => 'Me';

  @override
  String get liveMessages => 'Messages';

  @override
  String get liveWelcome => 'Meet with purpose';

  @override
  String get liveWelcomeHint => 'Connect, share ideas and keep meeting notes';

  @override
  String get liveJoin => 'Join';

  @override
  String get liveQuick => 'Meet now';

  @override
  String get liveSchedule => 'Schedule';

  @override
  String get liveRecordingHint => 'Record audio, transcribe and create notes';

  @override
  String get liveUpcoming => 'Upcoming';

  @override
  String get liveNoSchedules => 'No scheduled meetings';

  @override
  String get liveRefresh => 'Refresh';

  @override
  String get liveCode => 'Meeting code';

  @override
  String get liveCodeHint => 'Enter a 6-digit meeting code';

  @override
  String liveCodeValue(String code) {
    return 'Meeting code: $code';
  }

  @override
  String get livePassword => 'Meeting password';

  @override
  String get livePasswordOptional => 'Required only for protected meetings';

  @override
  String get liveMic => 'Microphone';

  @override
  String get liveCamera => 'Camera';

  @override
  String get liveJoinNotice =>
      'You can enable audio and video after joining. This meeting may be recorded.';

  @override
  String get liveTitle => 'Meeting title';

  @override
  String get liveTitleRequired => 'Enter a meeting title';

  @override
  String get livePasswordInvalid => 'Use a 4–6 digit password';

  @override
  String get liveFutureTime => 'Choose a future start time';

  @override
  String get liveEditSchedule => 'Edit schedule';

  @override
  String get liveStartTime => 'Start time';

  @override
  String get liveDuration => 'Duration';

  @override
  String liveMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get liveRequirePassword => 'Require a password';

  @override
  String get liveWaitingRoom => 'Waiting room';

  @override
  String liveReminder(int minutes) {
    return 'Remind $minutes minutes before (while app is open)';
  }

  @override
  String get liveSave => 'Save';

  @override
  String get liveSaving => 'Working…';

  @override
  String get liveEdit => 'Edit';

  @override
  String get liveCancelSchedule => 'Cancel schedule';

  @override
  String get liveBack => 'Cancel';

  @override
  String get liveConfirm => 'Confirm';

  @override
  String get liveRoom => 'Meeting';

  @override
  String get liveJoining => 'Joining meeting…';

  @override
  String get liveWaiting => 'Waiting for the host to admit you';

  @override
  String get liveCancelJoin => 'Cancel joining';

  @override
  String get liveBackHome => 'Back to home';

  @override
  String get liveEnded => 'Meeting ended or left';

  @override
  String get liveViewNotes => 'View meeting notes';

  @override
  String liveMembersCount(int count) {
    return '$count members';
  }

  @override
  String get liveReconnecting => 'Reconnecting…';

  @override
  String get liveMediaUnavailable =>
      'Audio/video is not connected. Room controls and chat remain available.';

  @override
  String get liveRetry => 'Retry';

  @override
  String get liveError => 'Operation failed';

  @override
  String get liveMe => 'Me';

  @override
  String get liveMembers => 'Members';

  @override
  String get liveChat => 'Chat';

  @override
  String get liveMore => 'More';

  @override
  String get liveLeave => 'Leave';

  @override
  String get liveEnd => 'End meeting';

  @override
  String get liveEndHint =>
      'Remaining audio uploads are confirmed before ending. Processing continues in the background, and all actual attendees can view, play and download the record.';

  @override
  String get liveLeaveHint =>
      'Leaving does not end the meeting. You can still view, play and download the recording after the meeting ends.';

  @override
  String get liveClose => 'Close';

  @override
  String get liveHost => 'Host';

  @override
  String get liveMember => 'Member';

  @override
  String get liveAdmit => 'Admit';

  @override
  String get liveDeny => 'Deny';

  @override
  String get liveMuteAll => 'Mute all';

  @override
  String get liveMute => 'Mute';

  @override
  String get liveUnmute => 'Allow unmute';

  @override
  String get liveApproveHand => 'Approve hand';

  @override
  String get liveRemove => 'Remove';

  @override
  String get liveTransfer => 'Transfer ownership';

  @override
  String get liveAttach => 'Attach file';

  @override
  String get liveMessage => 'Message';

  @override
  String get liveSend => 'Send';

  @override
  String get liveNoMessages => 'No messages yet';

  @override
  String get liveRaiseHand => 'Raise hand';

  @override
  String get liveLowerHand => 'Lower hand';

  @override
  String get liveSwitchCamera => 'Switch camera';

  @override
  String get liveSpeaker => 'Use speakerphone';

  @override
  String get liveEarpiece => 'Use earpiece';

  @override
  String get liveShare => 'Share screen';

  @override
  String get liveShareUnavailable => 'Screen sharing is not available in this mobile version';

  @override
  String get liveSettings => 'Meeting settings';

  @override
  String get liveSettingsHint => 'Changes apply to future joins without removing current members.';

  @override
  String get liveHostOnly => 'Only the host can edit meeting settings';

  @override
  String get liveKeepPassword => 'Leave blank to keep the current password';

  @override
  String get imConversations => 'Conversations';

  @override
  String get imContacts => 'Contacts';

  @override
  String get imGroups => 'Groups';

  @override
  String get imNew => 'New conversation';

  @override
  String get imEmpty => 'Nothing here yet';

  @override
  String get imCreateGroup => 'Create group';

  @override
  String get imGroupName => 'Group name';

  @override
  String get imUserId => 'User ID';

  @override
  String get imMemberIds => 'User IDs separated by commas or spaces';

  @override
  String get imCreate => 'Create';

  @override
  String get imManageGroup => 'Manage group';

  @override
  String get imPin => 'Pin / unpin';

  @override
  String get imLoadOlder => 'Load earlier messages';

  @override
  String get imLoadMore => 'Load more';

  @override
  String get imRecalled => 'Message recalled';

  @override
  String get imAttachment => 'Attachment';

  @override
  String get imDownload => 'Download';

  @override
  String get imPlay => 'Play';

  @override
  String get imRecall => 'Recall';

  @override
  String get imImage => 'Image';

  @override
  String get imVideo => 'Video';

  @override
  String get imFile => 'File';

  @override
  String get imVoice => 'Voice';

  @override
  String get imStopSend => 'Stop and send';

  @override
  String get imVoiceLimit => 'Recording limit reached; this recording was cancelled';

  @override
  String get imStopPlayback => 'Stop playback';

  @override
  String get imRequests => 'Friend requests';

  @override
  String get imNoRequests => 'No pending requests';

  @override
  String get imAddContact => 'Add contact';

  @override
  String get imAccept => 'Accept';

  @override
  String get imDecline => 'Decline';

  @override
  String get imRemark => 'Remark';

  @override
  String get imRemoveContact => 'Remove contact';

  @override
  String get imInvitations => 'Group invitations';

  @override
  String get imAnnouncement => 'Announcement';

  @override
  String get imInvite => 'Invite members';

  @override
  String get imAdminRole => 'Toggle administrator';

  @override
  String get imDismissGroup => 'Dismiss group';

  @override
  String get imLeaveGroup => 'Leave group';

  @override
  String liveReminderSoon(String title) {
    return 'Meeting starts soon: $title';
  }

  @override
  String get liveRecordingTitle => 'Meeting recording';

  @override
  String get liveRecordingOff => 'Automatic recording is not active yet';

  @override
  String get liveRecordingShared => 'Shared meeting recording is active';

  @override
  String get liveRecordingActive => 'Recording meeting audio';

  @override
  String get liveRecordingUploading => 'Uploading meeting audio';

  @override
  String get liveRecordingFailed => 'Meeting recording failed';

  @override
  String get liveRecordingWaiting => 'Waiting for recordable audio tracks';

  @override
  String get liveRecordingNoFrames =>
      'No audio frames received. Check microphone permissions and media connection.';

  @override
  String get liveRecordingBacklog =>
      'Recording upload queue is full. Capture is paused; retry the upload.';

  @override
  String liveRecordingError(String message) {
    return 'Recording failed: $message';
  }

  @override
  String get liveRoomRecordingHint =>
      'Meetings record automatically. The host uploads received audio tracks and confirms remaining chunks before ending. All actual attendees, including early leavers, can view and download the record. Missing tracks or upload failures are never reported as recording success.';

  @override
  String get liveRecordingStart => 'Start recording';

  @override
  String get liveRecordingStop => 'Stop recording';

  @override
  String get liveRecordingRequest => 'Request recording';

  @override
  String get liveRecordingPending => 'Awaiting host approval';

  @override
  String get liveRecordingApprovals => 'Recording requests';

  @override
  String get liveRecordingNoRequests => 'No pending recording requests';

  @override
  String get liveRecordingProcessed => 'Meeting recording processed';

  @override
  String get liveRecordingProcessing => 'Processing recording, transcript and minutes';

  @override
  String get liveHistoryRecords => 'Meeting history';

  @override
  String get liveUpcomingTab => 'Scheduled meetings';

  @override
  String get liveScheduleActive =>
      'In progress · end the current session before editing or cancelling';

  @override
  String get liveScheduleSearch => 'Search title, meeting number or host';

  @override
  String get liveScheduleNoMatches => 'No matching scheduled meetings';

  @override
  String liveScheduleHost(String name) {
    return 'Host: $name';
  }

  @override
  String get liveScheduleDate => 'Meeting date';

  @override
  String get imPause => 'Pause';

  @override
  String get liveRecordingTools => 'Record & transcribe';

  @override
  String get liveRecordingToolsHint => 'Record live audio or import an audio file to transcribe';

  @override
  String get liveToday => 'Today';

  @override
  String get liveTomorrow => 'Tomorrow';

  @override
  String get liveAgendaOngoing => 'In progress';

  @override
  String get liveAgendaJoined => 'Joined';

  @override
  String liveAgendaDay(String day, String date) {
    return '$day $date';
  }

  @override
  String liveAgendaTime(String start, String end) {
    return '$start–$end';
  }

  @override
  String get liveInvite => 'Invite participants';

  @override
  String liveInvitation(String title, String code) {
    return 'You are invited to a DR Meeting\nTopic: $title\nMeeting code: $code';
  }

  @override
  String get meetingsSearchHint => 'Search meeting titles or transcripts';

  @override
  String get meetingsSearchEmpty => 'No matching meetings';

  @override
  String get meetingsSearchClear => 'Clear search';

  @override
  String get meetingsSearchPartialWarning =>
      'Transcript search is temporarily unavailable. Showing title matches only.';

  @override
  String get meetingsEmptyHint => 'Tap \"Start recording\" to capture your first meeting';

  @override
  String get meetingsStartRecording => 'Start recording';

  @override
  String get meetingsImportAudio => 'Import audio';

  @override
  String get meetingsDeleteTitle => 'Delete this meeting?';

  @override
  String meetingsDeleteMessage(String title) {
    return '\"$title\" and its transcript, summary and recording will be permanently removed. This cannot be undone.';
  }

  @override
  String get meetingsDeleted => 'Meeting deleted';

  @override
  String meetingsDeleteFailed(String error) {
    return 'Failed to delete meeting: $error';
  }

  @override
  String get meetingsSttNotReady => 'Speech recognition is temporarily unavailable';

  @override
  String get meetingsLlmNotReady => 'Meeting summaries are temporarily unavailable';

  @override
  String get meetingsOffline => 'Cannot reach the service; what you see may be out of date';

  @override
  String get meetingsTitleHint => 'Meeting title';

  @override
  String get meetingsTitleEmpty => 'Meeting title cannot be empty';

  @override
  String get meetingsRenamed => 'Meeting renamed';

  @override
  String meetingsRenameFailed(String error) {
    return 'Failed to rename meeting: $error';
  }

  @override
  String meetingsCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String meetingsDuration(String duration) {
    return 'Duration $duration';
  }

  @override
  String get meetingsTabInfo => 'Meeting info';

  @override
  String get meetingsTabTranscript => 'Transcript';

  @override
  String get meetingsTabSummary => 'AI summary';

  @override
  String get meetingsActions => 'More actions';

  @override
  String get meetingsTranscriptEmpty => 'No transcript';

  @override
  String get meetingsTranscriptEmptyHint => 'No speech was transcribed for this meeting.';

  @override
  String get meetingsTranscriptProcessing => 'Processing meeting recording…';

  @override
  String get meetingsTranscriptChecking => 'Checking meeting processing status…';

  @override
  String get meetingsTranscriptIncompleteHint =>
      'The transcript is not ready. Check the processing status; saved recordings remain available.';

  @override
  String get meetingsTranscriptStatusUnavailable => 'Unable to confirm transcript status';

  @override
  String get meetingsTranscriptProcessingFailed => 'Transcript processing did not complete';

  @override
  String get meetingsTranscriptProcessingHint =>
      'The transcript appears here automatically when it is ready.';

  @override
  String get meetingsTranscriptLoadingMore => 'Loading more…';

  @override
  String meetingsTranscriptShowing(int loaded, int total) {
    return 'Showing $loaded of $total segments';
  }

  @override
  String get meetingsTranscriptLoadMoreFailed => 'Failed to load, tap to retry';

  @override
  String meetingsPlayFrom(String time) {
    return 'Play from $time';
  }

  @override
  String get meetingsAudioLoading => 'Loading recording…';

  @override
  String get meetingsAudioUnavailable => 'This meeting has no recording';

  @override
  String get meetingsAudioLoadFailed => 'Failed to load recording';

  @override
  String get meetingsAudioPlay => 'Play';

  @override
  String get meetingsAudioPause => 'Pause';

  @override
  String meetingsAudioBack(int seconds) {
    return 'Back $seconds seconds';
  }

  @override
  String meetingsAudioForward(int seconds) {
    return 'Forward $seconds seconds';
  }

  @override
  String get meetingsAudioSpeed => 'Playback speed';

  @override
  String meetingsAudioSpeedValue(String speed) {
    return '$speed×';
  }

  @override
  String get meetingsAudioPosition => 'Playback position';

  @override
  String get meetingsActionCopyTranscript => 'Copy transcript';

  @override
  String get meetingsActionShare => 'Share as Markdown';

  @override
  String get meetingsActionRetranscribe => 'Retranscribe';

  @override
  String get meetingsActionDelete => 'Delete meeting';

  @override
  String get meetingsTranscriptCopied => 'Transcript copied to clipboard';

  @override
  String get meetingsTranscriptCopyEmpty => 'No transcript to copy';

  @override
  String get meetingsShareEmpty => 'Nothing to share yet';

  @override
  String meetingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String meetingsMdTranscriptTitle(String title) {
    return 'Transcript: $title';
  }

  @override
  String meetingsMdSummaryTitle(String title) {
    return 'Meeting summary: $title';
  }

  @override
  String get meetingsMdDate => 'Date';

  @override
  String get meetingsMdDuration => 'Duration';

  @override
  String get meetingsMdMeetingId => 'Meeting ID';

  @override
  String get meetingsMdSummary => 'Summary';

  @override
  String get meetingsMdTranscript => 'Transcript';

  @override
  String get meetingsMdNoSummary => '(No summary yet)';

  @override
  String get meetingsRetranscribeTitle => 'Retranscribe meeting';

  @override
  String get meetingsRetranscribeDescription =>
      'Re-process the recording with different language settings. The current transcript will be replaced.';

  @override
  String get meetingsRetranscribeHint =>
      'The server\'s current speech model will be used. Choosing the language improves accuracy.';

  @override
  String get meetingsRetranscribeStart => 'Start retranscription';

  @override
  String get meetingsRetranscribeRunning => 'Retranscribing…';

  @override
  String meetingsRetranscribeComplete(int count) {
    return 'Retranscription complete — $count segments created';
  }

  @override
  String get meetingsRetranscribeCancelled => 'Retranscription cancelled';

  @override
  String get meetingsRetranscribeAlreadyRunning =>
      'A transcription job is already running for this meeting';

  @override
  String get meetingsTranscriptionLanguage => 'Transcription language';

  @override
  String meetingsLanguageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'auto': 'Auto detect (original language)',
      'zh': 'Chinese',
      'en': 'English',
      'ja': 'Japanese',
      'ko': 'Korean',
      'yue': 'Cantonese',
      'de': 'German',
      'fr': 'French',
      'es': 'Spanish',
      'ru': 'Russian',
      'it': 'Italian',
      'pt': 'Portuguese',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String meetingsJobProgress(int percent) {
    return '$percent%';
  }

  @override
  String get summaryCustomPromptLabel => 'Additional context (optional)';

  @override
  String get summaryCustomPromptHint =>
      'Participants, meeting goal, background… helps the AI write a better summary.';

  @override
  String get summaryGenerate => 'Generate summary';

  @override
  String get summaryRegenerate => 'Regenerate';

  @override
  String get summaryStop => 'Stop';

  @override
  String get summaryGenerating => 'Generating summary…';

  @override
  String get summaryGeneratingHint =>
      'Long meetings may take a minute. You can keep reading the transcript meanwhile.';

  @override
  String get summaryEmptyTitle => 'No summary yet';

  @override
  String get summaryEmptyDescription =>
      'Generate an AI summary to get key points, decisions and action items from this meeting.';

  @override
  String get summaryLlmNotReady =>
      'Meeting summaries are temporarily unavailable. Please try again later or contact your administrator.';

  @override
  String get summaryFailedGeneration => 'Summary generation failed';

  @override
  String summaryFailedGenerationDetail(String error) {
    return 'Summary generation failed: $error';
  }

  @override
  String get summaryFailedEmpty =>
      'The generated summary has no visible content. Please try again.';

  @override
  String get summaryFailedTimeout => 'Summary generation is taking too long. Check again later.';

  @override
  String get summaryCompleted => 'Summary generated';

  @override
  String get summaryStopped => 'Summary generation stopped';

  @override
  String summaryStopFailed(String error) {
    return 'Failed to stop: $error';
  }

  @override
  String get summaryEdit => 'Edit summary';

  @override
  String get summaryEditTab => 'Edit';

  @override
  String get summaryPreviewTab => 'Preview';

  @override
  String get summaryEditHint => 'Edit the summary in Markdown';

  @override
  String get summarySaved => 'Summary saved';

  @override
  String summarySaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get summaryDiscardTitle => 'Discard unsaved changes?';

  @override
  String get summaryDiscard => 'Discard';

  @override
  String get summaryCopied => 'Summary copied to clipboard';

  @override
  String get summaryCopyEmpty => 'No summary content to copy';

  @override
  String get summaryAutoStarted => 'Summary generation started automatically';

  @override
  String get importDescription =>
      'Create a new meeting from an audio file. It is uploaded and transcribed by the server.';

  @override
  String get importPickFile => 'Choose an audio file';

  @override
  String importSupportedFormats(String formats) {
    return 'Supported formats: $formats';
  }

  @override
  String get importChangeFile => 'Choose another file';

  @override
  String get importMeetingTitle => 'Meeting title';

  @override
  String get importTitleHint => 'Enter a meeting title';

  @override
  String get importLanguageHint =>
      'The audio is uploaded to the server and transcribed with the server\'s current speech model.';

  @override
  String get importStart => 'Import';

  @override
  String get importUploading => 'Uploading audio…';

  @override
  String get importSubmitting => 'Upload finished, submitting to the server…';

  @override
  String get importUploadedBackground => 'Audio uploaded — transcribing in the background';

  @override
  String get importBackgroundHint =>
      'You can leave this page once the upload finishes; the server transcribes the file in the background.';

  @override
  String importTranscribed(String title, int count) {
    return '\"$title\" is transcribed — $count segments';
  }

  @override
  String importTranscribeFailed(String title, String message) {
    return 'Transcribing \"$title\" failed: $message';
  }

  @override
  String importTranscribeLost(String title) {
    return 'Could not follow the transcription of \"$title\". Check the meeting list later.';
  }

  @override
  String get importCancelled => 'Import cancelled';

  @override
  String get importDisabled => 'Audio import is disabled';

  @override
  String importFileSize(String size) {
    return '$size MB · Choose another file';
  }

  @override
  String importFailedDetail(String error) {
    return 'Import failed: $error';
  }

  @override
  String onboardingStepProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to DR Meeting';

  @override
  String get onboardingWelcomeBody =>
      'Record, transcribe live and get AI meeting notes in one app. First, pick your language.';

  @override
  String get onboardingAccountTitle => 'Sign in or register';

  @override
  String get onboardingAccountBody =>
      'Use your phone number and an SMS code. New users can register right here.';

  @override
  String onboardingSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get onboardingSwitchAccount => 'Use another account';

  @override
  String get onboardingMicTitle => 'Allow microphone access';

  @override
  String get onboardingMicBody =>
      'Recording meetings needs the microphone. Audio is only sent to your server for transcription and notes. You can also allow it later when you record.';

  @override
  String get onboardingMicAllow => 'Allow microphone';

  @override
  String get onboardingMicGranted => 'Microphone access granted';

  @override
  String get onboardingMicDenied =>
      'Microphone access was denied. Turn it on in the system settings.';

  @override
  String get onboardingMicOpenSettings => 'Open system settings';

  @override
  String get onboardingMicSkip => 'Skip for now';

  @override
  String recordingMeetingTitle(String timestamp) {
    return 'Meeting $timestamp';
  }

  @override
  String get recordingNewTitle => 'New recording';

  @override
  String get recordingTitleHint => 'Meeting title';

  @override
  String get recordingRename => 'Edit title';

  @override
  String get recordingStatusIdle => 'Ready';

  @override
  String get recordingStatusPreparing => 'Preparing…';

  @override
  String get recordingStatusRecording => 'Recording';

  @override
  String get recordingStatusPaused => 'Paused';

  @override
  String get recordingStatusInterrupted => 'Interrupted';

  @override
  String get recordingStatusStopping => 'Finishing…';

  @override
  String get recordingStatusDone => 'Done';

  @override
  String get recordingStatusError => 'Error';

  @override
  String get recordingStart => 'Start recording';

  @override
  String get recordingStop => 'Stop recording';

  @override
  String get recordingPause => 'Pause';

  @override
  String get recordingResume => 'Resume';

  @override
  String get recordingInterruptedHint =>
      'Recording was interrupted by a call or another app. Tap Resume to continue.';

  @override
  String get recordingStoppingHint => 'Saving the recording…';

  @override
  String recordingPendingUploads(int count) {
    return '$count segments waiting to upload; they will be sent when the network is back';
  }

  @override
  String get recordingTranscriptTitle => 'Live transcript';

  @override
  String get recordingTranscriptEmpty =>
      'The transcript appears here in real time once you start recording';

  @override
  String get recordingSourceLabel => 'Audio source';

  @override
  String get recordingSourceMicrophone => 'Microphone';

  @override
  String get recordingSourceSystem => 'System audio';

  @override
  String get recordingSourceUnsupported => 'System audio is not supported on this device';

  @override
  String get recordingSourceNeedsPermission => 'Permission required on first use';

  @override
  String get recordingSourceLimitationsLink => 'About system audio';

  @override
  String get recordingLimitationsTitle => 'About system audio';

  @override
  String get recordingLimitationsMix =>
      'System audio records what the phone plays together with the microphone — for online meetings or videos played on the speaker.';

  @override
  String get recordingLimitationsCalls =>
      'The OS does not allow recording the other side of voice calls (e.g. WeChat or Tencent Meeting calls), and some apps forbid capture. In those cases turn on the speakerphone and record with the microphone.';

  @override
  String get recordingLimitationsConsent =>
      'Starting system audio asks for screen recording / broadcast permission, and the system shows a recording indicator while it runs.';

  @override
  String get recordingLimitationsDevice =>
      'Some OS versions or devices cannot capture system audio; only the microphone is available there.';

  @override
  String get recordingErrorPermission =>
      'Microphone access is off. Allow DR Meeting to use the microphone in system settings.';

  @override
  String get recordingErrorCancelled => 'Permission was declined; recording did not start.';

  @override
  String get recordingErrorUnsupported =>
      'The selected audio source is not supported on this device.';

  @override
  String get recordingErrorBusy =>
      'The recording device is in use by another app. Try again later.';

  @override
  String get recordingErrorPlatform => 'Could not start recording. Please try again.';

  @override
  String get recordingErrorStartTitle => 'Could not start recording';

  @override
  String get recordingErrorUploadTitle => 'Audio upload failed';

  @override
  String get recordingRetryUpload => 'Upload again';

  @override
  String get recordingUseMicrophone => 'Use microphone';

  @override
  String get recordingSettingsAction => 'Open settings';

  @override
  String get recordingNotificationChannel => 'Recording';

  @override
  String get recordingNotificationTitle => 'DR Meeting is recording';

  @override
  String recordingNotificationText(String elapsed) {
    return 'Recorded $elapsed';
  }

  @override
  String get recordingBusyLeaveHint =>
      'Recording in progress — stop it here or from the notification';

  @override
  String get recordingLanguageLabel => 'Transcription language';

  @override
  String get settingsChangeAvatar => 'Change avatar';

  @override
  String get settingsAvatarPicking => 'Selecting image…';

  @override
  String get settingsAvatarUploading => 'Uploading avatar…';

  @override
  String get settingsAvatarSaving => 'Saving avatar…';

  @override
  String get settingsAvatarSaved => 'Avatar updated';

  @override
  String settingsAvatarHint(int megabytes) {
    return 'PNG, JPG or WebP, up to $megabytes MB';
  }

  @override
  String settingsAvatarSize(int megabytes) {
    return 'Choose an image no larger than $megabytes MB.';
  }

  @override
  String get settingsAvatarType => 'Choose a valid PNG, JPG or WebP image.';

  @override
  String get settingsAvatarPickFailed =>
      'Unable to read the image. Check permissions and try again.';

  @override
  String get settingsAvatarUploadFailed =>
      'Upload failed. Your previous avatar is unchanged. Try again.';

  @override
  String get settingsAvatarSaveFailed =>
      'Save failed. Your previous avatar is unchanged. Try again.';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsEditName => 'Edit name';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutConfirmTitle => 'Sign out?';

  @override
  String get settingsLogoutConfirmBody =>
      'You will need your password or an SMS code to sign in again.';

  @override
  String get settingsLockedWhileRecording => 'Not available while recording';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsDefaultSource => 'Default recording source';

  @override
  String get settingsSourceMicrophone => 'Microphone only';

  @override
  String get settingsSourceMicrophoneHint => 'For in-person meetings: records the room.';

  @override
  String get settingsSourceSystem => 'Device audio + microphone';

  @override
  String get settingsSourceSystemHintAndroid =>
      'Needs Android 10+ and the screen-capture prompt when recording starts. Voice-call audio (e.g. WeChat or VooV calls) and apps that forbid capture cannot be recorded — use the speaker and the microphone instead.';

  @override
  String get settingsSourceSystemHintIos =>
      'Uses iOS screen broadcast; the status bar turns red while recording. Call audio of some apps and protected content are muted by the system. Not available in the simulator.';

  @override
  String get settingsTranscriptionLanguage => 'Transcription language';

  @override
  String get settingsAutoSummary => 'Auto-generate summary';

  @override
  String get settingsAutoSummaryHint =>
      'Create AI meeting notes after a recording or import finishes';

  @override
  String get settingsKeepLocalAudio => 'Keep local recordings';

  @override
  String get settingsKeepLocalAudioHint =>
      'Keep the audio file on this device after it was uploaded';

  @override
  String get settingsAboutSection => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsPassword => 'Password';

  @override
  String get settingsPasswordIsSet => 'Set';

  @override
  String get settingsPasswordNotSet => 'Not set — SMS code sign-in only';

  @override
  String get settingsSetPassword => 'Set password';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsSetPasswordHint =>
      'After setting a password you can sign in with your mobile number and password; SMS codes keep working.';

  @override
  String get settingsChangePasswordHint =>
      'Other devices signed in to this account will be signed out. Forgot your current password? Sign out and use “Forgot password?”.';

  @override
  String get settingsOldPassword => 'Current password';

  @override
  String get settingsOldPasswordRequired => 'Please enter your current password';

  @override
  String get settingsPasswordSaved => 'Password set. You can now sign in with it.';

  @override
  String get settingsPasswordChanged => 'Password changed. Other devices have been signed out.';

  @override
  String settingsPasswordFailed(String detail) {
    return 'Failed to save the password: $detail';
  }

  @override
  String get systemAudioNotificationChannelName => 'System audio capture';

  @override
  String get systemAudioNotificationTitle => 'DR Meeting is capturing system audio';

  @override
  String get systemAudioNotificationText =>
      'Recording what your phone plays. Tap to return to the app.';

  @override
  String get systemAudioBroadcastStoppedByApp =>
      'Recording finished. The system audio broadcast has stopped.';

  @override
  String get systemAudioBroadcastNotStartedFromApp =>
      'Choose \"Allow system audio\" on the DR Meeting recording screen and start recording before starting the broadcast.';

  @override
  String get systemAudioAndroidConsentTitle => 'Allow system audio';

  @override
  String get systemAudioAndroidConsentBody =>
      'Android will now ask whether DR Meeting may record or cast your screen. Choose \"Entire screen\" and tap \"Start\". DR Meeting only captures sound, never the picture. A notification is shown while capturing.';

  @override
  String get systemAudioAndroidLimitations =>
      'The other party\'s voice in calls (e.g. WeChat or Tencent Meeting voice/video calls) and apps that forbid capture cannot be recorded. In those cases turn on the speakerphone so the microphone picks it up.';

  @override
  String get systemAudioAndroidUnsupported => 'System audio capture requires Android 10 or later.';

  @override
  String get systemAudioIosHowToStart =>
      'In the system sheet, choose \"DR Meeting\" and tap \"Start Broadcast\". Capture begins after the countdown, and the status bar turns red while recording.';

  @override
  String get systemAudioIosMicHint =>
      'To include your own voice, turn on the microphone in the sheet.';

  @override
  String get systemAudioIosLimitations =>
      'iOS mutes call audio of some apps and protected content, so it cannot be captured. In those cases turn on the speakerphone so the microphone picks it up.';

  @override
  String get systemAudioIosStopHint =>
      'Stop recording in DR Meeting, or tap the red status bar indicator to stop the broadcast.';

  @override
  String get systemAudioIosSimulatorUnsupported =>
      'System audio capture is not available in the simulator. Use a real device.';

  @override
  String get systemAudioErrorUserCancelled => 'System audio capture was not allowed.';

  @override
  String get systemAudioErrorPermissionDenied =>
      'Microphone permission is required for system audio capture. Allow it in Settings.';

  @override
  String get systemAudioErrorUnsupported => 'This device does not support system audio capture.';

  @override
  String get systemAudioErrorBusy =>
      'System audio capture is busy or could not start. Please try again.';

  @override
  String systemAudioErrorPlatform(String detail) {
    return 'System audio capture failed: $detail';
  }

  @override
  String get systemAudioStoppedExternally =>
      'System audio capture was stopped by the system. Recording has ended.';

  @override
  String get systemAudioFallbackToMicrophone => 'Record with microphone only';

  @override
  String updateDialogTitle(String version) {
    return 'New version $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Current version $version';
  }

  @override
  String get updateNotes => 'What\'s new';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateGoToStore => 'Update in the app store';

  @override
  String get updateGoToAppStore => 'Update in the App Store';

  @override
  String updateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateDownloadingUnknown => 'Downloading…';

  @override
  String get updateInstalling => 'Opening the installer…';

  @override
  String get updateForceTitle => 'Update required';

  @override
  String updateForceMessage(String current, String version) {
    return 'Version $current is no longer supported. Update to $version to keep using the app.';
  }

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateUpToDate => 'You are using the latest version';

  @override
  String get updateCheckFailed => 'Could not check for updates. Try again later.';

  @override
  String get updateFailedDownload => 'Download failed. Check your network and try again.';

  @override
  String get updateFailedChecksum => 'The downloaded package is damaged. Try again.';

  @override
  String get updateFailedPermission =>
      'Allow this app to install unknown apps in system settings, then tap \"Update now\" again.';

  @override
  String get updateFailedInstall => 'Could not open the installer. Try again.';

  @override
  String get updateFailedStore => 'Could not open the app store';

  @override
  String get updateFailedSyncing =>
      'Meetings are still syncing in the background. Update a little later.';
}
