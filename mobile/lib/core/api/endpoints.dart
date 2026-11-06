/// Every server path used by the app (server/API.md §1). Feature code must not
/// build paths inline — add them here.
///
/// Paths are relative to the server base URL (the Dio `baseUrl`), so they include
/// the `/api/v1` prefix. Path parameters are URI-encoded.
abstract final class Endpoints {
  static const String imTicket = '$apiPrefix/im/ticket';
  static const String schedules = '$apiPrefix/scheduled-meetings';
  static String schedule(String id) => '$schedules/${_e(id)}';
  static const String rooms = '$apiPrefix/rooms';
  static const String roomJoin = '$rooms/join';
  static String room(String id) => '$rooms/${_e(id)}';
  static String roomAction(String id, String action) => '${room(id)}/$action';
  static String roomParticipant(String id, String participant, String action) =>
      '${room(id)}/participants/${_e(participant)}/$action';
  static String roomChat(String id) => '${room(id)}/chat';
  static String roomChatSession(String id) => '${room(id)}/chat-session';
  static String roomRecordingControl(String id) => '${room(id)}/recording/control';
  static String roomRecordingChunks(String id) => '${room(id)}/recording/chunks';
  static String roomScreenStart(String id) => '${room(id)}/screen-share/start';
  static String roomScreenStop(String id) => '${room(id)}/screen-share/stop';
  static String roomAttachment(String id, String attachment) =>
      '${roomChat(id)}/attachments/${_e(attachment)}';
  static String roomWs(String id) => '${room(id)}/ws';
  static const String apiPrefix = '/api/v1';

  // §1.0 Phone authentication — public (no Authorization header) unless noted.
  static const String authConfig = '$apiPrefix/auth/config';
  static const String authSendCode = '$apiPrefix/auth/sms/send';
  static const String authRegister = '$apiPrefix/auth/register';
  static const String authLogin = '$apiPrefix/auth/login';

  /// Forgot password: `{"phone","code","password","client"}` → AuthResult.
  static const String authPasswordReset = '$apiPrefix/auth/password/reset';

  /// Bearer.
  static const String authLogout = '$apiPrefix/auth/logout';

  /// Bearer. GET = current user, PATCH `{"name"}` = rename.
  static const String authMe = '$apiPrefix/auth/me';

  /// Bearer. PUT `{"old_password"?, "password"}` = set / change the password.
  static const String authMePassword = '$apiPrefix/auth/me/password';

  /// Endpoints that must be called WITHOUT the session token. The auth interceptor
  /// skips them, and a 401 from them never expires the session.
  static const Set<String> publicPaths = {
    authConfig,
    authSendCode,
    authRegister,
    authLogin,
    authPasswordReset,
  };

  static bool isPublic(String path) => publicPaths.contains(path);

  /// Path prefixes that are public as well (package downloads, which may redirect to OSS:
  /// the session token must never travel there).
  static const Set<String> publicPrefixes = {updatesDownloadPrefix};

  // §1.8 Updates — public; a session token (when present) only feeds the rollout allow-list.
  /// GET `?platform=&version=&arch=&channel=&client_id=`.
  static const String updatesCheck = '$apiPrefix/updates/check';

  /// Prefix of the absolute `download_url` returned by [updatesCheck].
  static const String updatesDownloadPrefix = '$apiPrefix/updates/download/';

  // §1.1 Connection
  static const String heartbeat = '$apiPrefix/client/heartbeat';
  static const String capabilities = '$apiPrefix/client/capabilities';

  // §1.2 / §1.3 Meetings & transcripts
  /// GET list (`[{"id","title"}]`), POST create (`{"title"}`).
  static const String meetings = '$apiPrefix/meetings';

  /// GET details, PATCH `{"title"}`, DELETE.
  static String meeting(String id) => '$meetings/${_e(id)}';
  static String meetingMetadata(String id) => '${meeting(id)}/metadata';

  /// GET `?limit=&offset=`, POST bulk insert `{"transcripts":[...]}`.
  static String meetingTranscripts(String id) => '${meeting(id)}/transcripts';

  /// POST raw PCM16 with query `seq`, `start`, `end`, `language?`.
  static String meetingSegments(String id) => '${meeting(id)}/segments';

  /// GET `?q=`.
  static const String transcriptSearch = '$apiPrefix/transcripts/search';

  // §1.4 Audio — PUT `?filename=` raw body, GET (Range; may 302 to OSS).
  static String meetingAudio(String id) => '${meeting(id)}/audio';
  static String meetingRecording(String id) => '${meeting(id)}/recording';
  static String meetingRecordingRetry(String id) => '${meetingRecording(id)}/retry';

  // §1.5 Jobs
  /// POST multipart `file`, `title`, `language?`.
  static const String jobsImport = '$apiPrefix/jobs/import';

  /// POST `{"meeting_id","language"}`.
  static const String jobsRetranscribe = '$apiPrefix/jobs/retranscribe';

  /// GET status, DELETE cancel.
  static String job(String id) => '$apiPrefix/jobs/${_e(id)}';

  // §1.6 Summary — POST start, GET status, DELETE cancel, PUT `{"summary": json}` save.
  static String meetingSummary(String id) => '${meeting(id)}/summary';
  static String meetingSummaryLanguage(String id) => '${meeting(id)}/summary-language';

  // §1.7 Notes
  static String meetingNotes(String id) => '${meeting(id)}/notes';

  static String _e(String segment) => Uri.encodeComponent(segment);
}

/// Query parameter names used with the endpoints above.
abstract final class QueryParams {
  static const String limit = 'limit';
  static const String offset = 'offset';
  static const String query = 'q';
  static const String seq = 'seq';
  static const String start = 'start';
  static const String end = 'end';
  static const String language = 'language';
  static const String filename = 'filename';
}
