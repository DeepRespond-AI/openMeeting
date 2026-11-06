// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get authTabLogin => '登录';

  @override
  String get authTabRegister => '注册';

  @override
  String get authPhoneLabel => '手机号';

  @override
  String get authPhoneHint => '请输入 11 位手机号';

  @override
  String get authPhonePrefix => '+86 ';

  @override
  String get authPhoneInvalid => '请输入正确的手机号';

  @override
  String get authCodeLabel => '验证码';

  @override
  String authCodeHint(int length) {
    return '$length 位短信验证码';
  }

  @override
  String authCodeInvalid(int length) {
    return '请输入 $length 位数字验证码';
  }

  @override
  String get authSendCode => '获取验证码';

  @override
  String get authResendCode => '重新获取';

  @override
  String authResendIn(int seconds) {
    return '$seconds 秒后重发';
  }

  @override
  String get authSending => '发送中…';

  @override
  String get authCodeSent => '验证码已发送，请注意查收短信';

  @override
  String authDevCodeHint(String code) {
    return '开发模式验证码：$code（点击填入）';
  }

  @override
  String get authNameLabel => '姓名';

  @override
  String get authNameHint => '你的姓名或昵称';

  @override
  String get authNameRequired => '请输入姓名';

  @override
  String authNameTooLong(int max) {
    return '姓名不能超过 $max 个字';
  }

  @override
  String get authLoginButton => '登录';

  @override
  String get authRegisterButton => '注册并登录';

  @override
  String get authRegistrationClosed => '该服务器暂未开放注册，请联系管理员开通账号。';

  @override
  String get authSmsNotReady => '服务器短信服务尚未配置，暂时无法获取验证码。';

  @override
  String authConfigLoadFailed(String detail) {
    return '无法获取服务器登录配置：$detail';
  }

  @override
  String get authServerRequired => '当前版本未配置服务，暂时无法登录，请联系管理员。';

  @override
  String get authMethodPassword => '密码登录';

  @override
  String get authMethodCode => '验证码登录';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authNewPasswordLabel => '新密码';

  @override
  String authPasswordHint(int min, int max) {
    return '$min-$max 位，需包含字母和数字';
  }

  @override
  String get authConfirmPasswordLabel => '确认密码';

  @override
  String get authConfirmPasswordHint => '请再次输入密码';

  @override
  String get authPasswordRequired => '请输入密码';

  @override
  String authPasswordLength(int min, int max) {
    return '密码长度需为 $min-$max 位';
  }

  @override
  String get authPasswordSpaces => '密码首尾不能有空格';

  @override
  String get authPasswordLetterDigit => '密码需同时包含字母和数字';

  @override
  String get authPasswordMismatch => '两次输入的密码不一致';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authBackToLogin => '返回登录';

  @override
  String get authResetTitle => '重置密码';

  @override
  String get authResetHint => '通过短信验证码验证手机号，然后设置新密码。';

  @override
  String get authResetButton => '重置密码并登录';

  @override
  String get imMessageActions => '消息操作';

  @override
  String get imMessageCopy => '复制';

  @override
  String get imMessageCopied => '已复制';

  @override
  String get imMessageDelete => '删除';

  @override
  String get imMessageCancel => '取消';

  @override
  String get imMessageConfirm => '确定';

  @override
  String get imMessageDeleteTitle => '是否删除该消息？';

  @override
  String get imMessageDeleteDescription => '仅从你的聊天记录中删除，其他参会者仍可看到该消息。';

  @override
  String get imMessageRecalledSelf => '你撤回了一条消息';

  @override
  String imMessageRecalledOther(String name) {
    return '$name撤回了一条消息';
  }

  @override
  String imMessageRecallExpiredMinutes(int minutes) {
    return '无法撤回$minutes分钟前发送的消息';
  }

  @override
  String imMessageRecallExpiredSeconds(int seconds) {
    return '无法撤回$seconds秒前发送的消息';
  }

  @override
  String get imMessageRecallUnavailable => '当前消息无法撤回';

  @override
  String get imMessageSending => '发送中…';

  @override
  String get imMessageSendFailed => '发送失败';

  @override
  String get appName => '深应会议';

  @override
  String commonTextTooLong(int max) {
    return '最多输入 $max 个字符。';
  }

  @override
  String get appTagline => 'AI 会议助手';

  @override
  String get commonOk => '确定';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaving => '保存中…';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonRename => '重命名';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRetry => '重试';

  @override
  String get commonBack => '返回';

  @override
  String get commonNext => '下一步';

  @override
  String get commonContinue => '继续';

  @override
  String get commonDone => '完成';

  @override
  String get commonSkip => '跳过';

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonShare => '分享';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonStart => '开始';

  @override
  String get commonStop => '停止';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonProcessing => '处理中…';

  @override
  String get commonEmpty => '暂无内容';

  @override
  String get commonEnabled => '已开启';

  @override
  String get commonDisabled => '已关闭';

  @override
  String get commonComingSoon => '该功能正在开发中';

  @override
  String get languageLabel => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get timeToday => '今天';

  @override
  String get timeYesterday => '昨天';

  @override
  String get errorGeneric => '出现问题，请重试。';

  @override
  String errorWithDetail(String detail) {
    return '错误：$detail';
  }

  @override
  String get errorNetwork => '无法连接服务器，请检查网络或服务器地址';

  @override
  String get errorTimeout => '请求超时，请稍后重试';

  @override
  String get errorBadRequest => '请求有误';

  @override
  String get errorUnauthorized => '登录已失效，请重新登录';

  @override
  String get errorForbidden => '没有权限执行此操作';

  @override
  String get errorNotFound => '内容不存在或已被删除';

  @override
  String get errorConflict => '操作冲突，请刷新后重试';

  @override
  String get errorPayloadTooLarge => '内容过大，服务器拒绝接收';

  @override
  String get errorInvalidInput => '输入内容无效，请检查后重试';

  @override
  String get errorRateLimited => '操作过于频繁，请稍后再试';

  @override
  String get errorUnavailable => '服务暂不可用，请稍后再试';

  @override
  String get errorServer => '服务器出错，请稍后再试';

  @override
  String get errorCancelled => '已取消';

  @override
  String get errorNotConfigured => '尚未设置服务器地址';

  @override
  String get errorUnknown => '发生未知错误';

  @override
  String get authSessionExpired => '登录已过期，请重新登录';

  @override
  String get navOnboarding => '欢迎';

  @override
  String get navLogin => '登录';

  @override
  String get navMeetings => '会议';

  @override
  String get navMeetingDetail => '会议详情';

  @override
  String get navRecording => '录音';

  @override
  String get navImport => '导入音频';

  @override
  String get navSettings => '设置';

  @override
  String get onboardingGetStarted => '开始使用';

  @override
  String get meetingsEmpty => '还没有会议记录';

  @override
  String get meetingsUntitled => '未命名会议';

  @override
  String transcriptionLanguageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'auto': '自动识别',
      'zh': '中文',
      'en': '英语',
      'ja': '日语',
      'ko': '韩语',
      'yue': '粤语',
      'de': '德语',
      'fr': '法语',
      'es': '西班牙语',
      'ru': '俄语',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get liveMediaConnectingInBackground => '音视频正在后台连接，可先使用聊天和成员功能';

  @override
  String get liveMediaReleasing => '正在等待上一次音视频连接释放…';

  @override
  String get liveMediaReleaseTimedOut => '上一次音视频连接仍在释放，请稍后重试；可退出当前会议';

  @override
  String get liveMediaJoinTimedOut => '音视频服务未能在入会时限内就绪，请稍后重试；成员控制和聊天仍可使用';

  @override
  String get liveChatMessageHint => '发送消息，全体成员可见';

  @override
  String get liveChatEmoji => '表情';

  @override
  String get liveChatEmojiFaces => '笑脸';

  @override
  String get liveChatEmojiGestures => '手势';

  @override
  String get liveChatEmojiSymbols => '符号';

  @override
  String get liveShareStop => '停止共享';

  @override
  String get liveShareStarting => '正在启动共享…';

  @override
  String get liveShareSharing => '正在共享屏幕';

  @override
  String get liveShareCaptureHint => '共享屏幕期间，其他参会者可以看到你选择的画面';

  @override
  String get liveShareDenied => '未获得屏幕采集授权，请重试并允许共享';

  @override
  String get liveShareFailed => '屏幕共享失败，请检查连接后重试';

  @override
  String get liveShareReplaced => '屏幕共享已被其他参会者替换';

  @override
  String get liveShareStopFailed => '画面已停止，请刷新确认共享状态';

  @override
  String get liveShareWaiting => '正在接收共享画面…';

  @override
  String get liveShareReceiveFailed => '暂未收到共享画面，请刷新重试';

  @override
  String liveShareBy(String name) {
    return '共享者：$name';
  }

  @override
  String get liveSpeaking => '正在发言';

  @override
  String get liveNetwork => '网络质量';

  @override
  String get liveNetworkUnknown => '未知';

  @override
  String get liveNetworkGood => '良好';

  @override
  String get liveNetworkFair => '一般';

  @override
  String get liveNetworkPoor => '较差';

  @override
  String get liveNetworkScope => '当前设备到会议媒体服务的 RTC 链路指标；无采样时显示未知';

  @override
  String get liveNetworkRtt => '往返延迟';

  @override
  String get liveNetworkLoss => '丢包率';

  @override
  String get liveNetworkNoData => '暂无数据';

  @override
  String get liveMinimize => '返回首页，会议保持连接';

  @override
  String get liveReturnMeeting => '返回会议';

  @override
  String get liveSessionOngoing => '会议进行中，语音与共享保持连接';

  @override
  String get liveRoomConflict => '你已在会议中，已返回当前会议；请先离开再加入其他会议。';

  @override
  String get imUnknownUser => '用户';

  @override
  String get liveRecordingVersionMismatch => '当前服务不支持自动会议录音，请更新服务后重试。';

  @override
  String get liveSharedRecord => '参会共享记录 · 只读';

  @override
  String get liveSharedSummaryEmpty => '纪要尚未生成，可稍后刷新查看。';

  @override
  String get liveDownloadAudio => '云下载';

  @override
  String get liveDownloadingAudio => '正在下载录音…';

  @override
  String get liveAudioSaved => '录音已保存，可分享或存储到文件。';

  @override
  String get liveExportAudio => '分享或存储录音';

  @override
  String get liveRecordEndedNotice => '会议已结束，录音正在后台处理。';

  @override
  String get liveRecordCompletedNotice => '会议录音与纪要已处理完成。';

  @override
  String get liveRecordFailedNotice => '会议记录处理失败，已保存的录音仍可查看。';

  @override
  String get liveViewRecord => '查看记录';

  @override
  String get liveHome => '首页';

  @override
  String get liveHistory => '会议';

  @override
  String get liveMine => '我的';

  @override
  String get liveMessages => '消息';

  @override
  String get liveWelcome => '开启高效会议';

  @override
  String get liveWelcomeHint => '连接同事，交流想法，留下会议记录';

  @override
  String get liveJoin => '加入会议';

  @override
  String get liveQuick => '快速会议';

  @override
  String get liveSchedule => '预定会议';

  @override
  String get liveRecordingHint => '录制现场声音，转写并生成纪要';

  @override
  String get liveUpcoming => '即将开始';

  @override
  String get liveNoSchedules => '暂无预定会议';

  @override
  String get liveRefresh => '刷新';

  @override
  String get liveCode => '会议号';

  @override
  String get liveCodeHint => '请输入 6 位会议号';

  @override
  String liveCodeValue(String code) {
    return '会议号：$code';
  }

  @override
  String get livePassword => '入会密码';

  @override
  String get livePasswordOptional => '有密码的会议请填写';

  @override
  String get liveMic => '麦克风';

  @override
  String get liveCamera => '摄像头';

  @override
  String get liveJoinNotice => '入会后可开启音视频。会议可能被录制并生成纪要。';

  @override
  String get liveTitle => '会议主题';

  @override
  String get liveTitleRequired => '请输入会议主题';

  @override
  String get livePasswordInvalid => '密码须为 4–6 位数字';

  @override
  String get liveFutureTime => '开始时间须晚于当前时间';

  @override
  String get liveEditSchedule => '修改预定';

  @override
  String get liveStartTime => '开始时间';

  @override
  String get liveDuration => '会议时长';

  @override
  String liveMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get liveRequirePassword => '启用入会密码';

  @override
  String get liveWaitingRoom => '等候室';

  @override
  String liveReminder(int minutes) {
    return '提前$minutes分钟提醒（应用前台）';
  }

  @override
  String get liveSave => '保存';

  @override
  String get liveSaving => '处理中…';

  @override
  String get liveEdit => '编辑';

  @override
  String get liveCancelSchedule => '取消预定';

  @override
  String get liveBack => '取消';

  @override
  String get liveConfirm => '确认';

  @override
  String get liveRoom => '会议房间';

  @override
  String get liveJoining => '正在加入会议…';

  @override
  String get liveWaiting => '请等待主持人准入';

  @override
  String get liveCancelJoin => '取消入会';

  @override
  String get liveBackHome => '返回首页';

  @override
  String get liveEnded => '会议已结束或已离开';

  @override
  String get liveViewNotes => '查看会议记录';

  @override
  String liveMembersCount(int count) {
    return '$count 位成员';
  }

  @override
  String get liveReconnecting => '连接恢复中，请稍候…';

  @override
  String get liveMediaUnavailable => '音视频尚未连接，成员控制和聊天仍可使用';

  @override
  String get liveRetry => '重试';

  @override
  String get liveError => '操作失败';

  @override
  String get liveMe => '我';

  @override
  String get liveMembers => '成员';

  @override
  String get liveChat => '聊天';

  @override
  String get liveMore => '更多';

  @override
  String get liveLeave => '离开';

  @override
  String get liveEnd => '结束会议';

  @override
  String get liveEndHint => '结束前将确认剩余录音上传，随后在后台处理。实际参会者均可查看记录、回放和下载录音。';

  @override
  String get liveLeaveHint => '离开不会结束会议。会议结束后，你仍可在会议记录中查看、回放和下载录音。';

  @override
  String get liveClose => '关闭';

  @override
  String get liveHost => '主持人';

  @override
  String get liveMember => '成员';

  @override
  String get liveAdmit => '准入';

  @override
  String get liveDeny => '拒绝';

  @override
  String get liveMuteAll => '全员静音';

  @override
  String get liveMute => '静音';

  @override
  String get liveUnmute => '解除静音限制';

  @override
  String get liveApproveHand => '同意发言';

  @override
  String get liveRemove => '移出';

  @override
  String get liveTransfer => '转让主持人/群主';

  @override
  String get liveAttach => '添加附件';

  @override
  String get liveMessage => '输入消息';

  @override
  String get liveSend => '发送';

  @override
  String get liveNoMessages => '暂无消息';

  @override
  String get liveRaiseHand => '举手';

  @override
  String get liveLowerHand => '放下手';

  @override
  String get liveSwitchCamera => '切换摄像头';

  @override
  String get liveSpeaker => '使用扬声器';

  @override
  String get liveEarpiece => '使用听筒';

  @override
  String get liveShare => '屏幕共享';

  @override
  String get liveShareUnavailable => '当前移动版本暂不支持屏幕共享';

  @override
  String get liveSettings => '会中设置';

  @override
  String get liveSettingsHint => '修改对之后入会的成员生效，不会移出当前成员。';

  @override
  String get liveHostOnly => '仅主持人可以修改会议设置';

  @override
  String get liveKeepPassword => '留空保留当前密码';

  @override
  String get imConversations => '会话';

  @override
  String get imContacts => '联系人';

  @override
  String get imGroups => '群组';

  @override
  String get imNew => '新建会话';

  @override
  String get imEmpty => '暂无内容';

  @override
  String get imCreateGroup => '新建群聊';

  @override
  String get imGroupName => '群名称';

  @override
  String get imUserId => '用户 ID';

  @override
  String get imMemberIds => '成员用户 ID，以逗号或空格分隔';

  @override
  String get imCreate => '创建';

  @override
  String get imManageGroup => '群管理';

  @override
  String get imPin => '置顶/取消置顶';

  @override
  String get imLoadOlder => '加载更早消息';

  @override
  String get imLoadMore => '加载更多';

  @override
  String get imRecalled => '消息已撤回';

  @override
  String get imAttachment => '附件消息';

  @override
  String get imDownload => '下载';

  @override
  String get imPlay => '播放';

  @override
  String get imRecall => '撤回';

  @override
  String get imImage => '图片';

  @override
  String get imVideo => '视频';

  @override
  String get imFile => '文件';

  @override
  String get imVoice => '语音';

  @override
  String get imStopSend => '结束并发送';

  @override
  String get imVoiceLimit => '已达到录音时长上限，本次录音已取消';

  @override
  String get imStopPlayback => '停止播放';

  @override
  String get imRequests => '好友申请';

  @override
  String get imNoRequests => '暂无待处理申请';

  @override
  String get imAddContact => '添加联系人';

  @override
  String get imAccept => '接受';

  @override
  String get imDecline => '拒绝';

  @override
  String get imRemark => '备注';

  @override
  String get imRemoveContact => '删除联系人';

  @override
  String get imInvitations => '群邀请';

  @override
  String get imAnnouncement => '群公告';

  @override
  String get imInvite => '邀请成员';

  @override
  String get imAdminRole => '设置/取消管理员';

  @override
  String get imDismissGroup => '解散群聊';

  @override
  String get imLeaveGroup => '退出群聊';

  @override
  String liveReminderSoon(String title) {
    return '会议即将开始：$title';
  }

  @override
  String get liveRecordingTitle => '会议录制';

  @override
  String get liveRecordingOff => '自动录音尚未激活';

  @override
  String get liveRecordingShared => '会议正在共享录制';

  @override
  String get liveRecordingActive => '正在录制会议音频';

  @override
  String get liveRecordingUploading => '正在上传会议录音';

  @override
  String get liveRecordingFailed => '会议录音处理失败';

  @override
  String get liveRecordingWaiting => '等待可录制的音轨';

  @override
  String get liveRecordingNoFrames => '未收到音频，请检查麦克风权限和音视频连接';

  @override
  String get liveRecordingBacklog => '录音上传积压，采集已暂停，请重试上传';

  @override
  String liveRecordingError(String message) {
    return '录音失败：$message';
  }

  @override
  String get liveRoomRecordingHint =>
      '会议自动录音，由主持人设备上传已接收的音轨。结束前确认剩余分片上传；实际参会者（包括提前离开者）均可查看记录和下载录音。没有音轨或上传失败时不会显示录音成功。';

  @override
  String get liveRecordingStart => '开始录制';

  @override
  String get liveRecordingStop => '停止录制';

  @override
  String get liveRecordingRequest => '申请录制';

  @override
  String get liveRecordingPending => '等待主持人处理';

  @override
  String get liveRecordingApprovals => '录制申请';

  @override
  String get liveRecordingNoRequests => '暂无待处理录制申请';

  @override
  String get liveRecordingProcessed => '会议录音处理完成';

  @override
  String get liveRecordingProcessing => '正在处理录音、转写和纪要';

  @override
  String get liveHistoryRecords => '历史会议记录';

  @override
  String get liveUpcomingTab => '预定会议';

  @override
  String get liveScheduleActive => '正在开会 · 结束当前场次后可编辑或取消';

  @override
  String get liveScheduleSearch => '搜索主题、会议号或发起人';

  @override
  String get liveScheduleNoMatches => '没有符合条件的预定会议';

  @override
  String liveScheduleHost(String name) {
    return '发起人：$name';
  }

  @override
  String get liveScheduleDate => '会议日期';

  @override
  String get imPause => '暂停';

  @override
  String get liveRecordingTools => '录音转写';

  @override
  String get liveRecordingToolsHint => '开始现场录音，或导入已有音频进行转写';

  @override
  String get liveToday => '今天';

  @override
  String get liveTomorrow => '明天';

  @override
  String get liveAgendaOngoing => '进行中';

  @override
  String get liveAgendaJoined => '已入会';

  @override
  String liveAgendaDay(String day, String date) {
    return '$day $date';
  }

  @override
  String liveAgendaTime(String start, String end) {
    return '$start–$end';
  }

  @override
  String get liveInvite => '邀请参会';

  @override
  String liveInvitation(String title, String code) {
    return '邀请您参加深应会议\n会议主题：$title\n会议号：$code';
  }

  @override
  String get meetingsSearchHint => '搜索会议标题或转写内容';

  @override
  String get meetingsSearchEmpty => '没有找到匹配的内容';

  @override
  String get meetingsSearchClear => '清除搜索';

  @override
  String get meetingsSearchPartialWarning => '转写内容暂时无法搜索，当前仅显示标题匹配结果';

  @override
  String get meetingsEmptyHint => '点击「开始录音」记录你的第一场会议';

  @override
  String get meetingsStartRecording => '开始录音';

  @override
  String get meetingsImportAudio => '导入音频';

  @override
  String get meetingsDeleteTitle => '删除该会议？';

  @override
  String meetingsDeleteMessage(String title) {
    return '“$title”及其转写、总结和录音将被永久删除，且无法恢复。';
  }

  @override
  String get meetingsDeleted => '会议已删除';

  @override
  String meetingsDeleteFailed(String error) {
    return '删除会议失败：$error';
  }

  @override
  String get meetingsSttNotReady => '语音识别暂不可用，暂时无法转写';

  @override
  String get meetingsLlmNotReady => '会议总结暂不可用';

  @override
  String get meetingsOffline => '无法连接服务，显示的可能不是最新内容';

  @override
  String get meetingsTitleHint => '会议标题';

  @override
  String get meetingsTitleEmpty => '会议标题不能为空';

  @override
  String get meetingsRenamed => '会议已重命名';

  @override
  String meetingsRenameFailed(String error) {
    return '重命名失败：$error';
  }

  @override
  String meetingsCreatedAt(String date) {
    return '创建时间 $date';
  }

  @override
  String meetingsDuration(String duration) {
    return '时长 $duration';
  }

  @override
  String get meetingsTabInfo => '会议信息';

  @override
  String get meetingsTabTranscript => '转写';

  @override
  String get meetingsTabSummary => 'AI 总结';

  @override
  String get meetingsActions => '更多操作';

  @override
  String get meetingsTranscriptEmpty => '暂无转写';

  @override
  String get meetingsTranscriptEmptyHint => '该会议没有识别到语音内容。';

  @override
  String get meetingsTranscriptProcessing => '正在处理会议录音…';

  @override
  String get meetingsTranscriptChecking => '正在确认会后处理状态…';

  @override
  String get meetingsTranscriptIncompleteHint => '转写尚未就绪，请查看会后处理状态；已保存的录音仍可下载。';

  @override
  String get meetingsTranscriptStatusUnavailable => '暂时无法确认转写状态';

  @override
  String get meetingsTranscriptProcessingFailed => '会议转写处理未完成';

  @override
  String get meetingsTranscriptProcessingHint => '转写完成后会自动显示在这里。';

  @override
  String get meetingsTranscriptLoadingMore => '正在加载更多…';

  @override
  String meetingsTranscriptShowing(int loaded, int total) {
    return '已显示 $loaded / $total 段';
  }

  @override
  String get meetingsTranscriptLoadMoreFailed => '加载失败，点击重试';

  @override
  String meetingsPlayFrom(String time) {
    return '从 $time 开始播放';
  }

  @override
  String get meetingsAudioLoading => '正在加载录音…';

  @override
  String get meetingsAudioUnavailable => '该会议没有录音';

  @override
  String get meetingsAudioLoadFailed => '录音加载失败';

  @override
  String get meetingsAudioPlay => '播放';

  @override
  String get meetingsAudioPause => '暂停';

  @override
  String meetingsAudioBack(int seconds) {
    return '后退 $seconds 秒';
  }

  @override
  String meetingsAudioForward(int seconds) {
    return '前进 $seconds 秒';
  }

  @override
  String get meetingsAudioSpeed => '播放速度';

  @override
  String meetingsAudioSpeedValue(String speed) {
    return '$speed×';
  }

  @override
  String get meetingsAudioPosition => '播放进度';

  @override
  String get meetingsActionCopyTranscript => '复制转写';

  @override
  String get meetingsActionShare => '分享（Markdown）';

  @override
  String get meetingsActionRetranscribe => '重新转写';

  @override
  String get meetingsActionDelete => '删除会议';

  @override
  String get meetingsTranscriptCopied => '转写内容已复制';

  @override
  String get meetingsTranscriptCopyEmpty => '没有可复制的转写内容';

  @override
  String get meetingsShareEmpty => '没有可分享的内容';

  @override
  String meetingsExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String meetingsMdTranscriptTitle(String title) {
    return '会议转写：$title';
  }

  @override
  String meetingsMdSummaryTitle(String title) {
    return '会议总结：$title';
  }

  @override
  String get meetingsMdDate => '日期';

  @override
  String get meetingsMdDuration => '时长';

  @override
  String get meetingsMdMeetingId => '会议 ID';

  @override
  String get meetingsMdSummary => '总结';

  @override
  String get meetingsMdTranscript => '转写';

  @override
  String get meetingsMdNoSummary => '（暂无总结）';

  @override
  String get meetingsRetranscribeTitle => '重新转写会议';

  @override
  String get meetingsRetranscribeDescription => '使用不同的语言设置重新处理录音，现有转写将被替换。';

  @override
  String get meetingsRetranscribeHint => '将使用服务器当前的语音识别模型。指定语言可提高准确率。';

  @override
  String get meetingsRetranscribeStart => '开始重新转写';

  @override
  String get meetingsRetranscribeRunning => '正在重新转写…';

  @override
  String meetingsRetranscribeComplete(int count) {
    return '重新转写完成，共生成 $count 段';
  }

  @override
  String get meetingsRetranscribeCancelled => '已取消重新转写';

  @override
  String get meetingsRetranscribeAlreadyRunning => '该会议已有正在进行的转写任务';

  @override
  String get meetingsTranscriptionLanguage => '转写语言';

  @override
  String meetingsLanguageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'auto': '自动检测（保留原语言）',
      'zh': '中文',
      'en': '英语',
      'ja': '日语',
      'ko': '韩语',
      'yue': '粤语',
      'de': '德语',
      'fr': '法语',
      'es': '西班牙语',
      'ru': '俄语',
      'it': '意大利语',
      'pt': '葡萄牙语',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String meetingsJobProgress(int percent) {
    return '$percent%';
  }

  @override
  String get summaryCustomPromptLabel => '补充说明（可选）';

  @override
  String get summaryCustomPromptHint => '参会人、会议目标、背景信息等，帮助 AI 生成更准确的总结。';

  @override
  String get summaryGenerate => '生成总结';

  @override
  String get summaryRegenerate => '重新生成';

  @override
  String get summaryStop => '停止';

  @override
  String get summaryGenerating => '正在生成总结…';

  @override
  String get summaryGeneratingHint => '较长的会议可能需要一分钟，期间可以继续查看转写。';

  @override
  String get summaryEmptyTitle => '暂无总结';

  @override
  String get summaryEmptyDescription => '生成 AI 总结，提取会议要点、决策和待办事项。';

  @override
  String get summaryLlmNotReady => '会议总结暂不可用，请稍后再试或联系管理员。';

  @override
  String get summaryFailedGeneration => '生成总结失败';

  @override
  String summaryFailedGenerationDetail(String error) {
    return '生成总结失败：$error';
  }

  @override
  String get summaryFailedEmpty => '生成的总结没有可显示的内容，请重试';

  @override
  String get summaryFailedTimeout => '总结生成时间过长，请稍后刷新查看';

  @override
  String get summaryCompleted => '总结已生成';

  @override
  String get summaryStopped => '已停止生成总结';

  @override
  String summaryStopFailed(String error) {
    return '停止失败：$error';
  }

  @override
  String get summaryEdit => '编辑总结';

  @override
  String get summaryEditTab => '编辑';

  @override
  String get summaryPreviewTab => '预览';

  @override
  String get summaryEditHint => '使用 Markdown 编辑总结';

  @override
  String get summarySaved => '总结已保存';

  @override
  String summarySaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get summaryDiscardTitle => '放弃未保存的修改？';

  @override
  String get summaryDiscard => '放弃';

  @override
  String get summaryCopied => '总结已复制';

  @override
  String get summaryCopyEmpty => '没有可复制的总结内容';

  @override
  String get summaryAutoStarted => '已自动开始生成总结';

  @override
  String get importDescription => '从音频文件创建新会议，文件将上传到服务器并完成转写。';

  @override
  String get importPickFile => '选择音频文件';

  @override
  String importSupportedFormats(String formats) {
    return '支持格式：$formats';
  }

  @override
  String get importChangeFile => '更换文件';

  @override
  String get importMeetingTitle => '会议标题';

  @override
  String get importTitleHint => '请输入会议标题';

  @override
  String get importLanguageHint => '音频将上传到服务器，并使用服务器当前的语音识别模型转写。';

  @override
  String get importStart => '开始导入';

  @override
  String get importUploading => '正在上传音频…';

  @override
  String get importSubmitting => '已上传，正在提交到服务器…';

  @override
  String get importUploadedBackground => '音频已上传，正在后台转写';

  @override
  String get importBackgroundHint => '上传完成后即可离开此页面，服务器会在后台完成转写。';

  @override
  String importTranscribed(String title, int count) {
    return '「$title」转写完成，共 $count 段';
  }

  @override
  String importTranscribeFailed(String title, String message) {
    return '「$title」转写失败：$message';
  }

  @override
  String importTranscribeLost(String title) {
    return '暂时无法获取「$title」的转写进度，请稍后在会议列表中查看';
  }

  @override
  String get importCancelled => '已取消导入';

  @override
  String get importDisabled => '导入音频功能未开启';

  @override
  String importFileSize(String size) {
    return '$size MB · 更换文件';
  }

  @override
  String importFailedDetail(String error) {
    return '导入失败：$error';
  }

  @override
  String onboardingStepProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get onboardingWelcomeTitle => '欢迎使用深应会议';

  @override
  String get onboardingWelcomeBody => '录音、实时转写、AI 会议纪要，一个 App 全部搞定。先选择界面语言。';

  @override
  String get onboardingAccountTitle => '登录或注册';

  @override
  String get onboardingAccountBody => '使用手机号和短信验证码登录，新用户可直接注册。';

  @override
  String onboardingSignedInAs(String name) {
    return '已登录：$name';
  }

  @override
  String get onboardingSwitchAccount => '切换账号';

  @override
  String get onboardingMicTitle => '允许使用麦克风';

  @override
  String get onboardingMicBody => '录制会议需要使用麦克风。音频只上传到你设置的服务器，用于转写和生成纪要。也可以稍后在录音时再授权。';

  @override
  String get onboardingMicAllow => '允许访问麦克风';

  @override
  String get onboardingMicGranted => '已允许使用麦克风';

  @override
  String get onboardingMicDenied => '麦克风权限已被拒绝，请在系统设置中开启。';

  @override
  String get onboardingMicOpenSettings => '打开系统设置';

  @override
  String get onboardingMicSkip => '暂不授权，稍后再说';

  @override
  String recordingMeetingTitle(String timestamp) {
    return '会议 $timestamp';
  }

  @override
  String get recordingNewTitle => '新录音';

  @override
  String get recordingTitleHint => '会议标题';

  @override
  String get recordingRename => '修改标题';

  @override
  String get recordingStatusIdle => '准备就绪';

  @override
  String get recordingStatusPreparing => '准备中…';

  @override
  String get recordingStatusRecording => '录音中';

  @override
  String get recordingStatusPaused => '已暂停';

  @override
  String get recordingStatusInterrupted => '已中断';

  @override
  String get recordingStatusStopping => '正在结束…';

  @override
  String get recordingStatusDone => '已完成';

  @override
  String get recordingStatusError => '出错';

  @override
  String get recordingStart => '开始录音';

  @override
  String get recordingStop => '停止录音';

  @override
  String get recordingPause => '暂停';

  @override
  String get recordingResume => '继续';

  @override
  String get recordingInterruptedHint => '录音被来电或其他应用中断，点击「继续」恢复录音';

  @override
  String get recordingStoppingHint => '正在保存录音…';

  @override
  String recordingPendingUploads(int count) {
    return '$count 段语音待上传，网络恢复后会自动补传';
  }

  @override
  String get recordingTranscriptTitle => '实时转写';

  @override
  String get recordingTranscriptEmpty => '开始录音后，转写内容会实时显示在这里';

  @override
  String get recordingSourceLabel => '录音来源';

  @override
  String get recordingSourceMicrophone => '麦克风';

  @override
  String get recordingSourceSystem => '内录';

  @override
  String get recordingSourceUnsupported => '当前设备不支持内录';

  @override
  String get recordingSourceNeedsPermission => '首次使用需要授权';

  @override
  String get recordingSourceLimitationsLink => '内录说明';

  @override
  String get recordingLimitationsTitle => '关于内录';

  @override
  String get recordingLimitationsMix => '内录会把手机播放的声音和麦克风一起录下来，适合外放的线上会议、视频等场景。';

  @override
  String get recordingLimitationsCalls =>
      '系统不允许录制语音通话中对方的声音（例如微信、腾讯会议的通话），部分应用也禁止被录制。遇到这类场景，请打开免提，改用麦克风收音。';

  @override
  String get recordingLimitationsConsent => '开始内录时系统会请求屏幕录制或直播授权，录制期间系统会显示录制提示。';

  @override
  String get recordingLimitationsDevice => '部分系统版本或设备不支持内录，此时只能使用麦克风。';

  @override
  String get recordingErrorPermission => '没有麦克风权限，请在系统设置中允许「深应会议」使用麦克风。';

  @override
  String get recordingErrorCancelled => '已取消授权，录音未开始。';

  @override
  String get recordingErrorUnsupported => '当前设备不支持所选的录音来源。';

  @override
  String get recordingErrorBusy => '录音设备正被其他应用占用，请稍后再试。';

  @override
  String get recordingErrorPlatform => '无法启动录音，请重试。';

  @override
  String get recordingErrorStartTitle => '无法开始录音';

  @override
  String get recordingErrorUploadTitle => '录音文件上传失败';

  @override
  String get recordingRetryUpload => '重新上传';

  @override
  String get recordingUseMicrophone => '改用麦克风';

  @override
  String get recordingSettingsAction => '打开设置';

  @override
  String get recordingNotificationChannel => '录音';

  @override
  String get recordingNotificationTitle => '深应会议正在录音';

  @override
  String recordingNotificationText(String elapsed) {
    return '已录制 $elapsed';
  }

  @override
  String get recordingBusyLeaveHint => '录音进行中，可在通知栏或本页停止录音';

  @override
  String get recordingLanguageLabel => '转写语言';

  @override
  String get settingsChangeAvatar => '修改头像';

  @override
  String get settingsAvatarPicking => '正在选择图片…';

  @override
  String get settingsAvatarUploading => '正在上传头像…';

  @override
  String get settingsAvatarSaving => '正在保存头像…';

  @override
  String get settingsAvatarSaved => '头像已更新';

  @override
  String settingsAvatarHint(int megabytes) {
    return '支持 PNG、JPG、WebP，最大 $megabytes MB';
  }

  @override
  String settingsAvatarSize(int megabytes) {
    return '图片不能超过 $megabytes MB，请重新选择。';
  }

  @override
  String get settingsAvatarType => '请选择有效的 PNG、JPG 或 WebP 图片。';

  @override
  String get settingsAvatarPickFailed => '无法读取图片，请检查权限后重新选择。';

  @override
  String get settingsAvatarUploadFailed => '头像上传失败，原头像已保留，请重试。';

  @override
  String get settingsAvatarSaveFailed => '头像保存失败，原头像已保留，请重试。';

  @override
  String get settingsAccountSection => '账号';

  @override
  String get settingsEditName => '修改姓名';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLogoutConfirmTitle => '退出登录？';

  @override
  String get settingsLogoutConfirmBody => '退出后需要使用密码或短信验证码重新登录。';

  @override
  String get settingsLockedWhileRecording => '正在录音，结束后才能操作';

  @override
  String get settingsPreferencesSection => '偏好';

  @override
  String get settingsDefaultSource => '默认录音来源';

  @override
  String get settingsSourceMicrophone => '仅麦克风';

  @override
  String get settingsSourceMicrophoneHint => '适合线下会议，录制现场声音。';

  @override
  String get settingsSourceSystem => '允许内录（系统声音 + 麦克风）';

  @override
  String get settingsSourceSystemHintAndroid =>
      '需要 Android 10 及以上，开始录音时需授权录屏。系统不允许录制语音通话中对方的声音（如微信、腾讯会议通话）以及禁止内录的 App，这类场景请开免提用麦克风收音。';

  @override
  String get settingsSourceSystemHintIos =>
      '通过系统「屏幕直播」录制，录音期间状态栏会变红。部分 App 的通话音频和受保护内容会被系统静音；模拟器不支持。';

  @override
  String get settingsTranscriptionLanguage => '转写语言';

  @override
  String get settingsAutoSummary => '自动生成纪要';

  @override
  String get settingsAutoSummaryHint => '录音或导入完成后自动生成 AI 会议纪要';

  @override
  String get settingsKeepLocalAudio => '保留本地录音';

  @override
  String get settingsKeepLocalAudioHint => '上传成功后仍在手机上保留音频文件';

  @override
  String get settingsAboutSection => '关于';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get settingsPassword => '登录密码';

  @override
  String get settingsPasswordIsSet => '已设置';

  @override
  String get settingsPasswordNotSet => '未设置，目前仅可用验证码登录';

  @override
  String get settingsSetPassword => '设置密码';

  @override
  String get settingsChangePassword => '修改密码';

  @override
  String get settingsSetPasswordHint => '设置后可以使用手机号 + 密码登录，验证码登录仍然可用。';

  @override
  String get settingsChangePasswordHint => '修改后，登录此账号的其他设备将退出登录。忘记原密码可退出登录后在登录页「忘记密码？」重置。';

  @override
  String get settingsOldPassword => '原密码';

  @override
  String get settingsOldPasswordRequired => '请输入原密码';

  @override
  String get settingsPasswordSaved => '密码已设置，之后可以使用密码登录';

  @override
  String get settingsPasswordChanged => '密码已修改，其他设备已退出登录';

  @override
  String settingsPasswordFailed(String detail) {
    return '密码保存失败：$detail';
  }

  @override
  String get systemAudioNotificationChannelName => '内录';

  @override
  String get systemAudioNotificationTitle => '深应会议正在内录';

  @override
  String get systemAudioNotificationText => '正在采集手机播放的声音，点按返回应用';

  @override
  String get systemAudioBroadcastStoppedByApp => '录音已结束，内录直播已停止。';

  @override
  String get systemAudioBroadcastNotStartedFromApp => '请先在深应会议的录音页选择「允许内录」并开始录音，再开始直播。';

  @override
  String get systemAudioAndroidConsentTitle => '允许内录';

  @override
  String get systemAudioAndroidConsentBody =>
      '接下来系统会询问是否允许深应会议录制或投放屏幕上的内容。请选择「整个屏幕」并点「开始」。深应会议只采集声音，不录制画面。录音期间通知栏会显示内录通知。';

  @override
  String get systemAudioAndroidLimitations =>
      '通话中对方的声音（例如微信、腾讯会议的语音或视频通话）以及禁止被录制的 App 无法内录。这类场景请打开免提，由麦克风收音。';

  @override
  String get systemAudioAndroidUnsupported => '内录需要 Android 10 及以上版本。';

  @override
  String get systemAudioIosHowToStart => '在弹出的系统面板中选择「深应会议」，点「开始直播」，倒计时结束后开始内录。录音期间状态栏会显示红色指示。';

  @override
  String get systemAudioIosMicHint => '如需同时录入你自己的声音，请在面板中打开麦克风。';

  @override
  String get systemAudioIosLimitations => '部分 App 的通话音频和受保护的内容会被系统静音，无法内录。这类场景请打开免提，由麦克风收音。';

  @override
  String get systemAudioIosStopHint => '可以在深应会议中停止录音，也可以点状态栏的红色指示停止直播。';

  @override
  String get systemAudioIosSimulatorUnsupported => '模拟器不支持内录，请在真机上使用。';

  @override
  String get systemAudioErrorUserCancelled => '已取消内录授权。';

  @override
  String get systemAudioErrorPermissionDenied => '没有录音权限，无法内录。请在系统设置中允许深应会议使用麦克风。';

  @override
  String get systemAudioErrorUnsupported => '当前设备不支持内录。';

  @override
  String get systemAudioErrorBusy => '内录正被占用或无法启动，请稍后重试。';

  @override
  String systemAudioErrorPlatform(String detail) {
    return '内录启动失败：$detail';
  }

  @override
  String get systemAudioStoppedExternally => '内录已在系统中被停止，录音已结束。';

  @override
  String get systemAudioFallbackToMicrophone => '改为仅麦克风录音';

  @override
  String updateDialogTitle(String version) {
    return '发现新版本 $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return '当前版本 $version';
  }

  @override
  String get updateNotes => '更新内容';

  @override
  String get updateLater => '稍后';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateGoToStore => '前往应用商店更新';

  @override
  String get updateGoToAppStore => '前往 App Store 更新';

  @override
  String updateDownloading(int percent) {
    return '正在下载… $percent%';
  }

  @override
  String get updateDownloadingUnknown => '正在下载…';

  @override
  String get updateInstalling => '正在打开安装程序…';

  @override
  String get updateForceTitle => '需要更新到新版本';

  @override
  String updateForceMessage(String current, String version) {
    return '当前版本 $current 已停止支持，请更新到 $version 后继续使用。';
  }

  @override
  String get updateCheck => '检查更新';

  @override
  String get updateUpToDate => '当前已是最新版本';

  @override
  String get updateCheckFailed => '检查更新失败，请稍后再试';

  @override
  String get updateFailedDownload => '下载失败，请检查网络后重试';

  @override
  String get updateFailedChecksum => '安装包校验失败，请重试';

  @override
  String get updateFailedPermission => '请在系统设置中允许本应用安装未知应用，返回后再点「立即更新」';

  @override
  String get updateFailedInstall => '无法打开安装程序，请重试';

  @override
  String get updateFailedStore => '无法打开应用商店';

  @override
  String get updateFailedSyncing => '会议仍在后台同步，请稍后再更新';
}
