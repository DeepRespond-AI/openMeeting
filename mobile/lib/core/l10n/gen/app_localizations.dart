import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('zh')];

  /// Phone auth form tab
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get authTabLogin;

  /// Phone auth form tab
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get authTabRegister;

  /// No description provided for @authPhoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入 11 位手机号'**
  String get authPhoneHint;

  /// Country code shown before the phone field (mainland China only)
  ///
  /// In zh, this message translates to:
  /// **'+86 '**
  String get authPhonePrefix;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入正确的手机号'**
  String get authPhoneInvalid;

  /// No description provided for @authCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get authCodeLabel;

  /// No description provided for @authCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'{length} 位短信验证码'**
  String authCodeHint(int length);

  /// No description provided for @authCodeInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入 {length} 位数字验证码'**
  String authCodeInvalid(int length);

  /// No description provided for @authSendCode.
  ///
  /// In zh, this message translates to:
  /// **'获取验证码'**
  String get authSendCode;

  /// No description provided for @authResendCode.
  ///
  /// In zh, this message translates to:
  /// **'重新获取'**
  String get authResendCode;

  /// No description provided for @authResendIn.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒后重发'**
  String authResendIn(int seconds);

  /// No description provided for @authSending.
  ///
  /// In zh, this message translates to:
  /// **'发送中…'**
  String get authSending;

  /// No description provided for @authCodeSent.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送，请注意查收短信'**
  String get authCodeSent;

  /// Only shown against dev servers
  ///
  /// In zh, this message translates to:
  /// **'开发模式验证码：{code}（点击填入）'**
  String authDevCodeHint(String code);

  /// No description provided for @authNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get authNameLabel;

  /// No description provided for @authNameHint.
  ///
  /// In zh, this message translates to:
  /// **'你的姓名或昵称'**
  String get authNameHint;

  /// No description provided for @authNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入姓名'**
  String get authNameRequired;

  /// No description provided for @authNameTooLong.
  ///
  /// In zh, this message translates to:
  /// **'姓名不能超过 {max} 个字'**
  String authNameTooLong(int max);

  /// No description provided for @authLoginButton.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In zh, this message translates to:
  /// **'注册并登录'**
  String get authRegisterButton;

  /// No description provided for @authRegistrationClosed.
  ///
  /// In zh, this message translates to:
  /// **'该服务器暂未开放注册，请联系管理员开通账号。'**
  String get authRegistrationClosed;

  /// No description provided for @authSmsNotReady.
  ///
  /// In zh, this message translates to:
  /// **'服务器短信服务尚未配置，暂时无法获取验证码。'**
  String get authSmsNotReady;

  /// No description provided for @authConfigLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法获取服务器登录配置：{detail}'**
  String authConfigLoadFailed(String detail);

  /// No description provided for @authServerRequired.
  ///
  /// In zh, this message translates to:
  /// **'当前版本未配置服务，暂时无法登录，请联系管理员。'**
  String get authServerRequired;

  /// No description provided for @authMethodPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码登录'**
  String get authMethodPassword;

  /// No description provided for @authMethodCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码登录'**
  String get authMethodCode;

  /// No description provided for @authPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get authPasswordLabel;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'新密码'**
  String get authNewPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'{min}-{max} 位，需包含字母和数字'**
  String authPasswordHint(int min, int max);

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'请再次输入密码'**
  String get authConfirmPasswordHint;

  /// No description provided for @authPasswordRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordLength.
  ///
  /// In zh, this message translates to:
  /// **'密码长度需为 {min}-{max} 位'**
  String authPasswordLength(int min, int max);

  /// No description provided for @authPasswordSpaces.
  ///
  /// In zh, this message translates to:
  /// **'密码首尾不能有空格'**
  String get authPasswordSpaces;

  /// No description provided for @authPasswordLetterDigit.
  ///
  /// In zh, this message translates to:
  /// **'密码需同时包含字母和数字'**
  String get authPasswordLetterDigit;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致'**
  String get authPasswordMismatch;

  /// No description provided for @authShowPassword.
  ///
  /// In zh, this message translates to:
  /// **'显示密码'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In zh, this message translates to:
  /// **'隐藏密码'**
  String get authHidePassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码？'**
  String get authForgotPassword;

  /// No description provided for @authBackToLogin.
  ///
  /// In zh, this message translates to:
  /// **'返回登录'**
  String get authBackToLogin;

  /// No description provided for @authResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get authResetTitle;

  /// No description provided for @authResetHint.
  ///
  /// In zh, this message translates to:
  /// **'通过短信验证码验证手机号，然后设置新密码。'**
  String get authResetHint;

  /// No description provided for @authResetButton.
  ///
  /// In zh, this message translates to:
  /// **'重置密码并登录'**
  String get authResetButton;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'消息操作'**
  String get imMessageActions;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get imMessageCopy;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get imMessageCopied;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get imMessageDelete;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get imMessageCancel;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get imMessageConfirm;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'是否删除该消息？'**
  String get imMessageDeleteTitle;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'仅从你的聊天记录中删除，其他参会者仍可看到该消息。'**
  String get imMessageDeleteDescription;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'你撤回了一条消息'**
  String get imMessageRecalledSelf;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'{name}撤回了一条消息'**
  String imMessageRecalledOther(String name);

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'无法撤回{minutes}分钟前发送的消息'**
  String imMessageRecallExpiredMinutes(int minutes);

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'无法撤回{seconds}秒前发送的消息'**
  String imMessageRecallExpiredSeconds(int seconds);

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'当前消息无法撤回'**
  String get imMessageRecallUnavailable;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'发送中…'**
  String get imMessageSending;

  /// Chat message layout and actions
  ///
  /// In zh, this message translates to:
  /// **'发送失败'**
  String get imMessageSendFailed;

  /// App name
  ///
  /// In zh, this message translates to:
  /// **'深应会议'**
  String get appName;

  /// No description provided for @commonTextTooLong.
  ///
  /// In zh, this message translates to:
  /// **'最多输入 {max} 个字符。'**
  String commonTextTooLong(int max);

  /// Short tagline under the logo
  ///
  /// In zh, this message translates to:
  /// **'AI 会议助手'**
  String get appTagline;

  /// No description provided for @commonOk.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In zh, this message translates to:
  /// **'保存中…'**
  String get commonSaving;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get commonRename;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get commonNext;

  /// No description provided for @commonContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get commonContinue;

  /// No description provided for @commonDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get commonDone;

  /// No description provided for @commonSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get commonSkip;

  /// No description provided for @commonCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get commonCopied;

  /// No description provided for @commonShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get commonShare;

  /// No description provided for @commonSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get commonSearch;

  /// No description provided for @commonRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get commonRefresh;

  /// No description provided for @commonStart.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get commonStart;

  /// No description provided for @commonStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get commonStop;

  /// No description provided for @commonLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get commonLoading;

  /// No description provided for @commonProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get commonProcessing;

  /// No description provided for @commonEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容'**
  String get commonEmpty;

  /// No description provided for @commonEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get commonEnabled;

  /// No description provided for @commonDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get commonDisabled;

  /// Shown on placeholder pages
  ///
  /// In zh, this message translates to:
  /// **'该功能正在开发中'**
  String get commonComingSoon;

  /// No description provided for @languageLabel.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// Name of Chinese, shown in its own language
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// Name of English, shown in its own language
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @timeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String timeDaysAgo(int count);

  /// No description provided for @timeToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get timeToday;

  /// No description provided for @timeYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get timeYesterday;

  /// No description provided for @errorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'出现问题，请重试。'**
  String get errorGeneric;

  /// No description provided for @errorWithDetail.
  ///
  /// In zh, this message translates to:
  /// **'错误：{detail}'**
  String errorWithDetail(String detail);

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务器，请检查网络或服务器地址'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'请求超时，请稍后重试'**
  String get errorTimeout;

  /// No description provided for @errorBadRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求有误'**
  String get errorBadRequest;

  /// No description provided for @errorUnauthorized.
  ///
  /// In zh, this message translates to:
  /// **'登录已失效，请重新登录'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In zh, this message translates to:
  /// **'没有权限执行此操作'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In zh, this message translates to:
  /// **'内容不存在或已被删除'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In zh, this message translates to:
  /// **'操作冲突，请刷新后重试'**
  String get errorConflict;

  /// No description provided for @errorPayloadTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'内容过大，服务器拒绝接收'**
  String get errorPayloadTooLarge;

  /// No description provided for @errorInvalidInput.
  ///
  /// In zh, this message translates to:
  /// **'输入内容无效，请检查后重试'**
  String get errorInvalidInput;

  /// No description provided for @errorRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'操作过于频繁，请稍后再试'**
  String get errorRateLimited;

  /// No description provided for @errorUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'服务暂不可用，请稍后再试'**
  String get errorUnavailable;

  /// No description provided for @errorServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器出错，请稍后再试'**
  String get errorServer;

  /// No description provided for @errorCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get errorCancelled;

  /// No description provided for @errorNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'尚未设置服务器地址'**
  String get errorNotConfigured;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'发生未知错误'**
  String get errorUnknown;

  /// No description provided for @authSessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get authSessionExpired;

  /// No description provided for @navOnboarding.
  ///
  /// In zh, this message translates to:
  /// **'欢迎'**
  String get navOnboarding;

  /// No description provided for @navLogin.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get navLogin;

  /// No description provided for @navMeetings.
  ///
  /// In zh, this message translates to:
  /// **'会议'**
  String get navMeetings;

  /// No description provided for @navMeetingDetail.
  ///
  /// In zh, this message translates to:
  /// **'会议详情'**
  String get navMeetingDetail;

  /// No description provided for @navRecording.
  ///
  /// In zh, this message translates to:
  /// **'录音'**
  String get navRecording;

  /// No description provided for @navImport.
  ///
  /// In zh, this message translates to:
  /// **'导入音频'**
  String get navImport;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In zh, this message translates to:
  /// **'开始使用'**
  String get onboardingGetStarted;

  /// No description provided for @meetingsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有会议记录'**
  String get meetingsEmpty;

  /// No description provided for @meetingsUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名会议'**
  String get meetingsUntitled;

  /// Name of a transcription language code (AppConfig.transcription.languages)
  ///
  /// In zh, this message translates to:
  /// **'{code, select, auto{自动识别} zh{中文} en{英语} ja{日语} ko{韩语} yue{粤语} de{德语} fr{法语} es{西班牙语} ru{俄语} other{{code}}}'**
  String transcriptionLanguageName(String code);

  /// No description provided for @liveMediaConnectingInBackground.
  ///
  /// In zh, this message translates to:
  /// **'音视频正在后台连接，可先使用聊天和成员功能'**
  String get liveMediaConnectingInBackground;

  /// No description provided for @liveMediaReleasing.
  ///
  /// In zh, this message translates to:
  /// **'正在等待上一次音视频连接释放…'**
  String get liveMediaReleasing;

  /// No description provided for @liveMediaReleaseTimedOut.
  ///
  /// In zh, this message translates to:
  /// **'上一次音视频连接仍在释放，请稍后重试；可退出当前会议'**
  String get liveMediaReleaseTimedOut;

  /// No description provided for @liveMediaJoinTimedOut.
  ///
  /// In zh, this message translates to:
  /// **'音视频服务未能在入会时限内就绪，请稍后重试；成员控制和聊天仍可使用'**
  String get liveMediaJoinTimedOut;

  /// No description provided for @liveChatMessageHint.
  ///
  /// In zh, this message translates to:
  /// **'发送消息，全体成员可见'**
  String get liveChatMessageHint;

  /// No description provided for @liveChatEmoji.
  ///
  /// In zh, this message translates to:
  /// **'表情'**
  String get liveChatEmoji;

  /// No description provided for @liveChatEmojiFaces.
  ///
  /// In zh, this message translates to:
  /// **'笑脸'**
  String get liveChatEmojiFaces;

  /// No description provided for @liveChatEmojiGestures.
  ///
  /// In zh, this message translates to:
  /// **'手势'**
  String get liveChatEmojiGestures;

  /// No description provided for @liveChatEmojiSymbols.
  ///
  /// In zh, this message translates to:
  /// **'符号'**
  String get liveChatEmojiSymbols;

  /// No description provided for @liveShareStop.
  ///
  /// In zh, this message translates to:
  /// **'停止共享'**
  String get liveShareStop;

  /// No description provided for @liveShareStarting.
  ///
  /// In zh, this message translates to:
  /// **'正在启动共享…'**
  String get liveShareStarting;

  /// No description provided for @liveShareSharing.
  ///
  /// In zh, this message translates to:
  /// **'正在共享屏幕'**
  String get liveShareSharing;

  /// No description provided for @liveShareCaptureHint.
  ///
  /// In zh, this message translates to:
  /// **'共享屏幕期间，其他参会者可以看到你选择的画面'**
  String get liveShareCaptureHint;

  /// No description provided for @liveShareDenied.
  ///
  /// In zh, this message translates to:
  /// **'未获得屏幕采集授权，请重试并允许共享'**
  String get liveShareDenied;

  /// No description provided for @liveShareFailed.
  ///
  /// In zh, this message translates to:
  /// **'屏幕共享失败，请检查连接后重试'**
  String get liveShareFailed;

  /// No description provided for @liveShareReplaced.
  ///
  /// In zh, this message translates to:
  /// **'屏幕共享已被其他参会者替换'**
  String get liveShareReplaced;

  /// No description provided for @liveShareStopFailed.
  ///
  /// In zh, this message translates to:
  /// **'画面已停止，请刷新确认共享状态'**
  String get liveShareStopFailed;

  /// No description provided for @liveShareWaiting.
  ///
  /// In zh, this message translates to:
  /// **'正在接收共享画面…'**
  String get liveShareWaiting;

  /// No description provided for @liveShareReceiveFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂未收到共享画面，请刷新重试'**
  String get liveShareReceiveFailed;

  /// No description provided for @liveShareBy.
  ///
  /// In zh, this message translates to:
  /// **'共享者：{name}'**
  String liveShareBy(String name);

  /// No description provided for @liveSpeaking.
  ///
  /// In zh, this message translates to:
  /// **'正在发言'**
  String get liveSpeaking;

  /// No description provided for @liveNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络质量'**
  String get liveNetwork;

  /// No description provided for @liveNetworkUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get liveNetworkUnknown;

  /// No description provided for @liveNetworkGood.
  ///
  /// In zh, this message translates to:
  /// **'良好'**
  String get liveNetworkGood;

  /// No description provided for @liveNetworkFair.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get liveNetworkFair;

  /// No description provided for @liveNetworkPoor.
  ///
  /// In zh, this message translates to:
  /// **'较差'**
  String get liveNetworkPoor;

  /// No description provided for @liveNetworkScope.
  ///
  /// In zh, this message translates to:
  /// **'当前设备到会议媒体服务的 RTC 链路指标；无采样时显示未知'**
  String get liveNetworkScope;

  /// No description provided for @liveNetworkRtt.
  ///
  /// In zh, this message translates to:
  /// **'往返延迟'**
  String get liveNetworkRtt;

  /// No description provided for @liveNetworkLoss.
  ///
  /// In zh, this message translates to:
  /// **'丢包率'**
  String get liveNetworkLoss;

  /// No description provided for @liveNetworkNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get liveNetworkNoData;

  /// No description provided for @liveMinimize.
  ///
  /// In zh, this message translates to:
  /// **'返回首页，会议保持连接'**
  String get liveMinimize;

  /// No description provided for @liveReturnMeeting.
  ///
  /// In zh, this message translates to:
  /// **'返回会议'**
  String get liveReturnMeeting;

  /// No description provided for @liveSessionOngoing.
  ///
  /// In zh, this message translates to:
  /// **'会议进行中，语音与共享保持连接'**
  String get liveSessionOngoing;

  /// No description provided for @liveRoomConflict.
  ///
  /// In zh, this message translates to:
  /// **'你已在会议中，已返回当前会议；请先离开再加入其他会议。'**
  String get liveRoomConflict;

  /// No description provided for @imUnknownUser.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get imUnknownUser;

  /// No description provided for @liveRecordingVersionMismatch.
  ///
  /// In zh, this message translates to:
  /// **'当前服务不支持自动会议录音，请更新服务后重试。'**
  String get liveRecordingVersionMismatch;

  /// No description provided for @liveSharedRecord.
  ///
  /// In zh, this message translates to:
  /// **'参会共享记录 · 只读'**
  String get liveSharedRecord;

  /// No description provided for @liveSharedSummaryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'纪要尚未生成，可稍后刷新查看。'**
  String get liveSharedSummaryEmpty;

  /// No description provided for @liveDownloadAudio.
  ///
  /// In zh, this message translates to:
  /// **'云下载'**
  String get liveDownloadAudio;

  /// No description provided for @liveDownloadingAudio.
  ///
  /// In zh, this message translates to:
  /// **'正在下载录音…'**
  String get liveDownloadingAudio;

  /// No description provided for @liveAudioSaved.
  ///
  /// In zh, this message translates to:
  /// **'录音已保存，可分享或存储到文件。'**
  String get liveAudioSaved;

  /// No description provided for @liveExportAudio.
  ///
  /// In zh, this message translates to:
  /// **'分享或存储录音'**
  String get liveExportAudio;

  /// No description provided for @liveRecordEndedNotice.
  ///
  /// In zh, this message translates to:
  /// **'会议已结束，录音正在后台处理。'**
  String get liveRecordEndedNotice;

  /// No description provided for @liveRecordCompletedNotice.
  ///
  /// In zh, this message translates to:
  /// **'会议录音与纪要已处理完成。'**
  String get liveRecordCompletedNotice;

  /// No description provided for @liveRecordFailedNotice.
  ///
  /// In zh, this message translates to:
  /// **'会议记录处理失败，已保存的录音仍可查看。'**
  String get liveRecordFailedNotice;

  /// No description provided for @liveViewRecord.
  ///
  /// In zh, this message translates to:
  /// **'查看记录'**
  String get liveViewRecord;

  /// Mobile meeting or messaging: liveHome
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get liveHome;

  /// Mobile meeting or messaging: liveHistory
  ///
  /// In zh, this message translates to:
  /// **'会议'**
  String get liveHistory;

  /// Mobile meeting or messaging: liveMine
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get liveMine;

  /// Mobile meeting or messaging: liveMessages
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get liveMessages;

  /// Mobile meeting or messaging: liveWelcome
  ///
  /// In zh, this message translates to:
  /// **'开启高效会议'**
  String get liveWelcome;

  /// Mobile meeting or messaging: liveWelcomeHint
  ///
  /// In zh, this message translates to:
  /// **'连接同事，交流想法，留下会议记录'**
  String get liveWelcomeHint;

  /// Mobile meeting or messaging: liveJoin
  ///
  /// In zh, this message translates to:
  /// **'加入会议'**
  String get liveJoin;

  /// Mobile meeting or messaging: liveQuick
  ///
  /// In zh, this message translates to:
  /// **'快速会议'**
  String get liveQuick;

  /// Mobile meeting or messaging: liveSchedule
  ///
  /// In zh, this message translates to:
  /// **'预定会议'**
  String get liveSchedule;

  /// Mobile meeting or messaging: liveRecordingHint
  ///
  /// In zh, this message translates to:
  /// **'录制现场声音，转写并生成纪要'**
  String get liveRecordingHint;

  /// Mobile meeting or messaging: liveUpcoming
  ///
  /// In zh, this message translates to:
  /// **'即将开始'**
  String get liveUpcoming;

  /// Mobile meeting or messaging: liveNoSchedules
  ///
  /// In zh, this message translates to:
  /// **'暂无预定会议'**
  String get liveNoSchedules;

  /// Mobile meeting or messaging: liveRefresh
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get liveRefresh;

  /// Mobile meeting or messaging: liveCode
  ///
  /// In zh, this message translates to:
  /// **'会议号'**
  String get liveCode;

  /// Mobile meeting or messaging: liveCodeHint
  ///
  /// In zh, this message translates to:
  /// **'请输入 6 位会议号'**
  String get liveCodeHint;

  /// Mobile meeting or messaging: liveCodeValue
  ///
  /// In zh, this message translates to:
  /// **'会议号：{code}'**
  String liveCodeValue(String code);

  /// Mobile meeting or messaging: livePassword
  ///
  /// In zh, this message translates to:
  /// **'入会密码'**
  String get livePassword;

  /// Mobile meeting or messaging: livePasswordOptional
  ///
  /// In zh, this message translates to:
  /// **'有密码的会议请填写'**
  String get livePasswordOptional;

  /// Mobile meeting or messaging: liveMic
  ///
  /// In zh, this message translates to:
  /// **'麦克风'**
  String get liveMic;

  /// Mobile meeting or messaging: liveCamera
  ///
  /// In zh, this message translates to:
  /// **'摄像头'**
  String get liveCamera;

  /// Mobile meeting or messaging: liveJoinNotice
  ///
  /// In zh, this message translates to:
  /// **'入会后可开启音视频。会议可能被录制并生成纪要。'**
  String get liveJoinNotice;

  /// Mobile meeting or messaging: liveTitle
  ///
  /// In zh, this message translates to:
  /// **'会议主题'**
  String get liveTitle;

  /// Mobile meeting or messaging: liveTitleRequired
  ///
  /// In zh, this message translates to:
  /// **'请输入会议主题'**
  String get liveTitleRequired;

  /// Mobile meeting or messaging: livePasswordInvalid
  ///
  /// In zh, this message translates to:
  /// **'密码须为 4–6 位数字'**
  String get livePasswordInvalid;

  /// Mobile meeting or messaging: liveFutureTime
  ///
  /// In zh, this message translates to:
  /// **'开始时间须晚于当前时间'**
  String get liveFutureTime;

  /// Mobile meeting or messaging: liveEditSchedule
  ///
  /// In zh, this message translates to:
  /// **'修改预定'**
  String get liveEditSchedule;

  /// Mobile meeting or messaging: liveStartTime
  ///
  /// In zh, this message translates to:
  /// **'开始时间'**
  String get liveStartTime;

  /// Mobile meeting or messaging: liveDuration
  ///
  /// In zh, this message translates to:
  /// **'会议时长'**
  String get liveDuration;

  /// Mobile meeting or messaging: liveMinutes
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟'**
  String liveMinutes(int count);

  /// Mobile meeting or messaging: liveRequirePassword
  ///
  /// In zh, this message translates to:
  /// **'启用入会密码'**
  String get liveRequirePassword;

  /// Mobile meeting or messaging: liveWaitingRoom
  ///
  /// In zh, this message translates to:
  /// **'等候室'**
  String get liveWaitingRoom;

  /// Foreground reminder lead time
  ///
  /// In zh, this message translates to:
  /// **'提前{minutes}分钟提醒（应用前台）'**
  String liveReminder(int minutes);

  /// Mobile meeting or messaging: liveSave
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get liveSave;

  /// Mobile meeting or messaging: liveSaving
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get liveSaving;

  /// Mobile meeting or messaging: liveEdit
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get liveEdit;

  /// Mobile meeting or messaging: liveCancelSchedule
  ///
  /// In zh, this message translates to:
  /// **'取消预定'**
  String get liveCancelSchedule;

  /// Mobile meeting or messaging: liveBack
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get liveBack;

  /// Mobile meeting or messaging: liveConfirm
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get liveConfirm;

  /// Mobile meeting or messaging: liveRoom
  ///
  /// In zh, this message translates to:
  /// **'会议房间'**
  String get liveRoom;

  /// Mobile meeting or messaging: liveJoining
  ///
  /// In zh, this message translates to:
  /// **'正在加入会议…'**
  String get liveJoining;

  /// Mobile meeting or messaging: liveWaiting
  ///
  /// In zh, this message translates to:
  /// **'请等待主持人准入'**
  String get liveWaiting;

  /// Mobile meeting or messaging: liveCancelJoin
  ///
  /// In zh, this message translates to:
  /// **'取消入会'**
  String get liveCancelJoin;

  /// Mobile meeting or messaging: liveBackHome
  ///
  /// In zh, this message translates to:
  /// **'返回首页'**
  String get liveBackHome;

  /// Mobile meeting or messaging: liveEnded
  ///
  /// In zh, this message translates to:
  /// **'会议已结束或已离开'**
  String get liveEnded;

  /// Mobile meeting or messaging: liveViewNotes
  ///
  /// In zh, this message translates to:
  /// **'查看会议记录'**
  String get liveViewNotes;

  /// Mobile meeting or messaging: liveMembersCount
  ///
  /// In zh, this message translates to:
  /// **'{count} 位成员'**
  String liveMembersCount(int count);

  /// Mobile meeting or messaging: liveReconnecting
  ///
  /// In zh, this message translates to:
  /// **'连接恢复中，请稍候…'**
  String get liveReconnecting;

  /// Mobile meeting or messaging: liveMediaUnavailable
  ///
  /// In zh, this message translates to:
  /// **'音视频尚未连接，成员控制和聊天仍可使用'**
  String get liveMediaUnavailable;

  /// Mobile meeting or messaging: liveRetry
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get liveRetry;

  /// Mobile meeting or messaging: liveError
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get liveError;

  /// Mobile meeting or messaging: liveMe
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get liveMe;

  /// Mobile meeting or messaging: liveMembers
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get liveMembers;

  /// Mobile meeting or messaging: liveChat
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get liveChat;

  /// Mobile meeting or messaging: liveMore
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get liveMore;

  /// Mobile meeting or messaging: liveLeave
  ///
  /// In zh, this message translates to:
  /// **'离开'**
  String get liveLeave;

  /// Mobile meeting or messaging: liveEnd
  ///
  /// In zh, this message translates to:
  /// **'结束会议'**
  String get liveEnd;

  /// Mobile meeting or messaging: liveEndHint
  ///
  /// In zh, this message translates to:
  /// **'结束前将确认剩余录音上传，随后在后台处理。实际参会者均可查看记录、回放和下载录音。'**
  String get liveEndHint;

  /// Mobile meeting or messaging: liveLeaveHint
  ///
  /// In zh, this message translates to:
  /// **'离开不会结束会议。会议结束后，你仍可在会议记录中查看、回放和下载录音。'**
  String get liveLeaveHint;

  /// Mobile meeting or messaging: liveClose
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get liveClose;

  /// Mobile meeting or messaging: liveHost
  ///
  /// In zh, this message translates to:
  /// **'主持人'**
  String get liveHost;

  /// Mobile meeting or messaging: liveMember
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get liveMember;

  /// Mobile meeting or messaging: liveAdmit
  ///
  /// In zh, this message translates to:
  /// **'准入'**
  String get liveAdmit;

  /// Mobile meeting or messaging: liveDeny
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get liveDeny;

  /// Mobile meeting or messaging: liveMuteAll
  ///
  /// In zh, this message translates to:
  /// **'全员静音'**
  String get liveMuteAll;

  /// Mobile meeting or messaging: liveMute
  ///
  /// In zh, this message translates to:
  /// **'静音'**
  String get liveMute;

  /// Mobile meeting or messaging: liveUnmute
  ///
  /// In zh, this message translates to:
  /// **'解除静音限制'**
  String get liveUnmute;

  /// Mobile meeting or messaging: liveApproveHand
  ///
  /// In zh, this message translates to:
  /// **'同意发言'**
  String get liveApproveHand;

  /// Mobile meeting or messaging: liveRemove
  ///
  /// In zh, this message translates to:
  /// **'移出'**
  String get liveRemove;

  /// Mobile meeting or messaging: liveTransfer
  ///
  /// In zh, this message translates to:
  /// **'转让主持人/群主'**
  String get liveTransfer;

  /// Mobile meeting or messaging: liveAttach
  ///
  /// In zh, this message translates to:
  /// **'添加附件'**
  String get liveAttach;

  /// Mobile meeting or messaging: liveMessage
  ///
  /// In zh, this message translates to:
  /// **'输入消息'**
  String get liveMessage;

  /// Mobile meeting or messaging: liveSend
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get liveSend;

  /// Mobile meeting or messaging: liveNoMessages
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get liveNoMessages;

  /// Mobile meeting or messaging: liveRaiseHand
  ///
  /// In zh, this message translates to:
  /// **'举手'**
  String get liveRaiseHand;

  /// Mobile meeting or messaging: liveLowerHand
  ///
  /// In zh, this message translates to:
  /// **'放下手'**
  String get liveLowerHand;

  /// Mobile meeting or messaging: liveSwitchCamera
  ///
  /// In zh, this message translates to:
  /// **'切换摄像头'**
  String get liveSwitchCamera;

  /// Mobile meeting or messaging: liveSpeaker
  ///
  /// In zh, this message translates to:
  /// **'使用扬声器'**
  String get liveSpeaker;

  /// Mobile meeting or messaging: liveEarpiece
  ///
  /// In zh, this message translates to:
  /// **'使用听筒'**
  String get liveEarpiece;

  /// Mobile meeting or messaging: liveShare
  ///
  /// In zh, this message translates to:
  /// **'屏幕共享'**
  String get liveShare;

  /// Mobile meeting or messaging: liveShareUnavailable
  ///
  /// In zh, this message translates to:
  /// **'当前移动版本暂不支持屏幕共享'**
  String get liveShareUnavailable;

  /// Mobile meeting or messaging: liveSettings
  ///
  /// In zh, this message translates to:
  /// **'会中设置'**
  String get liveSettings;

  /// Mobile meeting or messaging: liveSettingsHint
  ///
  /// In zh, this message translates to:
  /// **'修改对之后入会的成员生效，不会移出当前成员。'**
  String get liveSettingsHint;

  /// Mobile meeting or messaging: liveHostOnly
  ///
  /// In zh, this message translates to:
  /// **'仅主持人可以修改会议设置'**
  String get liveHostOnly;

  /// Mobile meeting or messaging: liveKeepPassword
  ///
  /// In zh, this message translates to:
  /// **'留空保留当前密码'**
  String get liveKeepPassword;

  /// Mobile meeting or messaging: imConversations
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get imConversations;

  /// Mobile meeting or messaging: imContacts
  ///
  /// In zh, this message translates to:
  /// **'联系人'**
  String get imContacts;

  /// Mobile meeting or messaging: imGroups
  ///
  /// In zh, this message translates to:
  /// **'群组'**
  String get imGroups;

  /// Mobile meeting or messaging: imNew
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get imNew;

  /// Mobile meeting or messaging: imEmpty
  ///
  /// In zh, this message translates to:
  /// **'暂无内容'**
  String get imEmpty;

  /// Mobile meeting or messaging: imCreateGroup
  ///
  /// In zh, this message translates to:
  /// **'新建群聊'**
  String get imCreateGroup;

  /// Mobile meeting or messaging: imGroupName
  ///
  /// In zh, this message translates to:
  /// **'群名称'**
  String get imGroupName;

  /// Mobile meeting or messaging: imUserId
  ///
  /// In zh, this message translates to:
  /// **'用户 ID'**
  String get imUserId;

  /// Mobile meeting or messaging: imMemberIds
  ///
  /// In zh, this message translates to:
  /// **'成员用户 ID，以逗号或空格分隔'**
  String get imMemberIds;

  /// Mobile meeting or messaging: imCreate
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get imCreate;

  /// Mobile meeting or messaging: imManageGroup
  ///
  /// In zh, this message translates to:
  /// **'群管理'**
  String get imManageGroup;

  /// Mobile meeting or messaging: imPin
  ///
  /// In zh, this message translates to:
  /// **'置顶/取消置顶'**
  String get imPin;

  /// Mobile meeting or messaging: imLoadOlder
  ///
  /// In zh, this message translates to:
  /// **'加载更早消息'**
  String get imLoadOlder;

  /// Mobile meeting or messaging: imLoadMore
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get imLoadMore;

  /// Mobile meeting or messaging: imRecalled
  ///
  /// In zh, this message translates to:
  /// **'消息已撤回'**
  String get imRecalled;

  /// Mobile meeting or messaging: imAttachment
  ///
  /// In zh, this message translates to:
  /// **'附件消息'**
  String get imAttachment;

  /// Mobile meeting or messaging: imDownload
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get imDownload;

  /// Mobile meeting or messaging: imPlay
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get imPlay;

  /// Mobile meeting or messaging: imRecall
  ///
  /// In zh, this message translates to:
  /// **'撤回'**
  String get imRecall;

  /// Mobile meeting or messaging: imImage
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get imImage;

  /// Mobile meeting or messaging: imVideo
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get imVideo;

  /// Mobile meeting or messaging: imFile
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get imFile;

  /// Mobile meeting or messaging: imVoice
  ///
  /// In zh, this message translates to:
  /// **'语音'**
  String get imVoice;

  /// Mobile meeting or messaging: imStopSend
  ///
  /// In zh, this message translates to:
  /// **'结束并发送'**
  String get imStopSend;

  /// Mobile meeting or messaging: imVoiceLimit
  ///
  /// In zh, this message translates to:
  /// **'已达到录音时长上限，本次录音已取消'**
  String get imVoiceLimit;

  /// Mobile meeting or messaging: imStopPlayback
  ///
  /// In zh, this message translates to:
  /// **'停止播放'**
  String get imStopPlayback;

  /// Mobile meeting or messaging: imRequests
  ///
  /// In zh, this message translates to:
  /// **'好友申请'**
  String get imRequests;

  /// Mobile meeting or messaging: imNoRequests
  ///
  /// In zh, this message translates to:
  /// **'暂无待处理申请'**
  String get imNoRequests;

  /// Mobile meeting or messaging: imAddContact
  ///
  /// In zh, this message translates to:
  /// **'添加联系人'**
  String get imAddContact;

  /// Mobile meeting or messaging: imAccept
  ///
  /// In zh, this message translates to:
  /// **'接受'**
  String get imAccept;

  /// Mobile meeting or messaging: imDecline
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get imDecline;

  /// Mobile meeting or messaging: imRemark
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get imRemark;

  /// Mobile meeting or messaging: imRemoveContact
  ///
  /// In zh, this message translates to:
  /// **'删除联系人'**
  String get imRemoveContact;

  /// Mobile meeting or messaging: imInvitations
  ///
  /// In zh, this message translates to:
  /// **'群邀请'**
  String get imInvitations;

  /// Mobile meeting or messaging: imAnnouncement
  ///
  /// In zh, this message translates to:
  /// **'群公告'**
  String get imAnnouncement;

  /// Mobile meeting or messaging: imInvite
  ///
  /// In zh, this message translates to:
  /// **'邀请成员'**
  String get imInvite;

  /// Mobile meeting or messaging: imAdminRole
  ///
  /// In zh, this message translates to:
  /// **'设置/取消管理员'**
  String get imAdminRole;

  /// Mobile meeting or messaging: imDismissGroup
  ///
  /// In zh, this message translates to:
  /// **'解散群聊'**
  String get imDismissGroup;

  /// Mobile meeting or messaging: imLeaveGroup
  ///
  /// In zh, this message translates to:
  /// **'退出群聊'**
  String get imLeaveGroup;

  /// Foreground schedule reminder
  ///
  /// In zh, this message translates to:
  /// **'会议即将开始：{title}'**
  String liveReminderSoon(String title);

  /// No description provided for @liveRecordingTitle.
  ///
  /// In zh, this message translates to:
  /// **'会议录制'**
  String get liveRecordingTitle;

  /// No description provided for @liveRecordingOff.
  ///
  /// In zh, this message translates to:
  /// **'自动录音尚未激活'**
  String get liveRecordingOff;

  /// No description provided for @liveRecordingShared.
  ///
  /// In zh, this message translates to:
  /// **'会议正在共享录制'**
  String get liveRecordingShared;

  /// No description provided for @liveRecordingActive.
  ///
  /// In zh, this message translates to:
  /// **'正在录制会议音频'**
  String get liveRecordingActive;

  /// No description provided for @liveRecordingUploading.
  ///
  /// In zh, this message translates to:
  /// **'正在上传会议录音'**
  String get liveRecordingUploading;

  /// No description provided for @liveRecordingFailed.
  ///
  /// In zh, this message translates to:
  /// **'会议录音处理失败'**
  String get liveRecordingFailed;

  /// No description provided for @liveRecordingWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待可录制的音轨'**
  String get liveRecordingWaiting;

  /// No description provided for @liveRecordingNoFrames.
  ///
  /// In zh, this message translates to:
  /// **'未收到音频，请检查麦克风权限和音视频连接'**
  String get liveRecordingNoFrames;

  /// No description provided for @liveRecordingBacklog.
  ///
  /// In zh, this message translates to:
  /// **'录音上传积压，采集已暂停，请重试上传'**
  String get liveRecordingBacklog;

  /// No description provided for @liveRecordingError.
  ///
  /// In zh, this message translates to:
  /// **'录音失败：{message}'**
  String liveRecordingError(String message);

  /// No description provided for @liveRoomRecordingHint.
  ///
  /// In zh, this message translates to:
  /// **'会议自动录音，由主持人设备上传已接收的音轨。结束前确认剩余分片上传；实际参会者（包括提前离开者）均可查看记录和下载录音。没有音轨或上传失败时不会显示录音成功。'**
  String get liveRoomRecordingHint;

  /// No description provided for @liveRecordingStart.
  ///
  /// In zh, this message translates to:
  /// **'开始录制'**
  String get liveRecordingStart;

  /// No description provided for @liveRecordingStop.
  ///
  /// In zh, this message translates to:
  /// **'停止录制'**
  String get liveRecordingStop;

  /// No description provided for @liveRecordingRequest.
  ///
  /// In zh, this message translates to:
  /// **'申请录制'**
  String get liveRecordingRequest;

  /// No description provided for @liveRecordingPending.
  ///
  /// In zh, this message translates to:
  /// **'等待主持人处理'**
  String get liveRecordingPending;

  /// No description provided for @liveRecordingApprovals.
  ///
  /// In zh, this message translates to:
  /// **'录制申请'**
  String get liveRecordingApprovals;

  /// No description provided for @liveRecordingNoRequests.
  ///
  /// In zh, this message translates to:
  /// **'暂无待处理录制申请'**
  String get liveRecordingNoRequests;

  /// No description provided for @liveRecordingProcessed.
  ///
  /// In zh, this message translates to:
  /// **'会议录音处理完成'**
  String get liveRecordingProcessed;

  /// No description provided for @liveRecordingProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在处理录音、转写和纪要'**
  String get liveRecordingProcessing;

  /// No description provided for @liveHistoryRecords.
  ///
  /// In zh, this message translates to:
  /// **'历史会议记录'**
  String get liveHistoryRecords;

  /// No description provided for @liveUpcomingTab.
  ///
  /// In zh, this message translates to:
  /// **'预定会议'**
  String get liveUpcomingTab;

  /// No description provided for @liveScheduleActive.
  ///
  /// In zh, this message translates to:
  /// **'正在开会 · 结束当前场次后可编辑或取消'**
  String get liveScheduleActive;

  /// No description provided for @liveScheduleSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索主题、会议号或发起人'**
  String get liveScheduleSearch;

  /// No description provided for @liveScheduleNoMatches.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的预定会议'**
  String get liveScheduleNoMatches;

  /// No description provided for @liveScheduleHost.
  ///
  /// In zh, this message translates to:
  /// **'发起人：{name}'**
  String liveScheduleHost(String name);

  /// No description provided for @liveScheduleDate.
  ///
  /// In zh, this message translates to:
  /// **'会议日期'**
  String get liveScheduleDate;

  /// No description provided for @imPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get imPause;

  /// No description provided for @liveRecordingTools.
  ///
  /// In zh, this message translates to:
  /// **'录音转写'**
  String get liveRecordingTools;

  /// No description provided for @liveRecordingToolsHint.
  ///
  /// In zh, this message translates to:
  /// **'开始现场录音，或导入已有音频进行转写'**
  String get liveRecordingToolsHint;

  /// No description provided for @liveToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get liveToday;

  /// No description provided for @liveTomorrow.
  ///
  /// In zh, this message translates to:
  /// **'明天'**
  String get liveTomorrow;

  /// No description provided for @liveAgendaOngoing.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get liveAgendaOngoing;

  /// No description provided for @liveAgendaJoined.
  ///
  /// In zh, this message translates to:
  /// **'已入会'**
  String get liveAgendaJoined;

  /// No description provided for @liveAgendaDay.
  ///
  /// In zh, this message translates to:
  /// **'{day} {date}'**
  String liveAgendaDay(String day, String date);

  /// No description provided for @liveAgendaTime.
  ///
  /// In zh, this message translates to:
  /// **'{start}–{end}'**
  String liveAgendaTime(String start, String end);

  /// No description provided for @liveInvite.
  ///
  /// In zh, this message translates to:
  /// **'邀请参会'**
  String get liveInvite;

  /// No description provided for @liveInvitation.
  ///
  /// In zh, this message translates to:
  /// **'邀请您参加深应会议\n会议主题：{title}\n会议号：{code}'**
  String liveInvitation(String title, String code);

  /// No description provided for @meetingsSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索会议标题或转写内容'**
  String get meetingsSearchHint;

  /// No description provided for @meetingsSearchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的内容'**
  String get meetingsSearchEmpty;

  /// No description provided for @meetingsSearchClear.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索'**
  String get meetingsSearchClear;

  /// No description provided for @meetingsSearchPartialWarning.
  ///
  /// In zh, this message translates to:
  /// **'转写内容暂时无法搜索，当前仅显示标题匹配结果'**
  String get meetingsSearchPartialWarning;

  /// No description provided for @meetingsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点击「开始录音」记录你的第一场会议'**
  String get meetingsEmptyHint;

  /// No description provided for @meetingsStartRecording.
  ///
  /// In zh, this message translates to:
  /// **'开始录音'**
  String get meetingsStartRecording;

  /// No description provided for @meetingsImportAudio.
  ///
  /// In zh, this message translates to:
  /// **'导入音频'**
  String get meetingsImportAudio;

  /// No description provided for @meetingsDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除该会议？'**
  String get meetingsDeleteTitle;

  /// No description provided for @meetingsDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'“{title}”及其转写、总结和录音将被永久删除，且无法恢复。'**
  String meetingsDeleteMessage(String title);

  /// No description provided for @meetingsDeleted.
  ///
  /// In zh, this message translates to:
  /// **'会议已删除'**
  String get meetingsDeleted;

  /// No description provided for @meetingsDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除会议失败：{error}'**
  String meetingsDeleteFailed(String error);

  /// No description provided for @meetingsSttNotReady.
  ///
  /// In zh, this message translates to:
  /// **'语音识别暂不可用，暂时无法转写'**
  String get meetingsSttNotReady;

  /// No description provided for @meetingsLlmNotReady.
  ///
  /// In zh, this message translates to:
  /// **'会议总结暂不可用'**
  String get meetingsLlmNotReady;

  /// No description provided for @meetingsOffline.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务，显示的可能不是最新内容'**
  String get meetingsOffline;

  /// No description provided for @meetingsTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'会议标题'**
  String get meetingsTitleHint;

  /// No description provided for @meetingsTitleEmpty.
  ///
  /// In zh, this message translates to:
  /// **'会议标题不能为空'**
  String get meetingsTitleEmpty;

  /// No description provided for @meetingsRenamed.
  ///
  /// In zh, this message translates to:
  /// **'会议已重命名'**
  String get meetingsRenamed;

  /// No description provided for @meetingsRenameFailed.
  ///
  /// In zh, this message translates to:
  /// **'重命名失败：{error}'**
  String meetingsRenameFailed(String error);

  /// No description provided for @meetingsCreatedAt.
  ///
  /// In zh, this message translates to:
  /// **'创建时间 {date}'**
  String meetingsCreatedAt(String date);

  /// No description provided for @meetingsDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长 {duration}'**
  String meetingsDuration(String duration);

  /// No description provided for @meetingsTabInfo.
  ///
  /// In zh, this message translates to:
  /// **'会议信息'**
  String get meetingsTabInfo;

  /// No description provided for @meetingsTabTranscript.
  ///
  /// In zh, this message translates to:
  /// **'转写'**
  String get meetingsTabTranscript;

  /// No description provided for @meetingsTabSummary.
  ///
  /// In zh, this message translates to:
  /// **'AI 总结'**
  String get meetingsTabSummary;

  /// No description provided for @meetingsActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get meetingsActions;

  /// No description provided for @meetingsTranscriptEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无转写'**
  String get meetingsTranscriptEmpty;

  /// No description provided for @meetingsTranscriptEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'该会议没有识别到语音内容。'**
  String get meetingsTranscriptEmptyHint;

  /// No description provided for @meetingsTranscriptProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在处理会议录音…'**
  String get meetingsTranscriptProcessing;

  /// No description provided for @meetingsTranscriptChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在确认会后处理状态…'**
  String get meetingsTranscriptChecking;

  /// No description provided for @meetingsTranscriptIncompleteHint.
  ///
  /// In zh, this message translates to:
  /// **'转写尚未就绪，请查看会后处理状态；已保存的录音仍可下载。'**
  String get meetingsTranscriptIncompleteHint;

  /// No description provided for @meetingsTranscriptStatusUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法确认转写状态'**
  String get meetingsTranscriptStatusUnavailable;

  /// No description provided for @meetingsTranscriptProcessingFailed.
  ///
  /// In zh, this message translates to:
  /// **'会议转写处理未完成'**
  String get meetingsTranscriptProcessingFailed;

  /// No description provided for @meetingsTranscriptProcessingHint.
  ///
  /// In zh, this message translates to:
  /// **'转写完成后会自动显示在这里。'**
  String get meetingsTranscriptProcessingHint;

  /// No description provided for @meetingsTranscriptLoadingMore.
  ///
  /// In zh, this message translates to:
  /// **'正在加载更多…'**
  String get meetingsTranscriptLoadingMore;

  /// No description provided for @meetingsTranscriptShowing.
  ///
  /// In zh, this message translates to:
  /// **'已显示 {loaded} / {total} 段'**
  String meetingsTranscriptShowing(int loaded, int total);

  /// No description provided for @meetingsTranscriptLoadMoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，点击重试'**
  String get meetingsTranscriptLoadMoreFailed;

  /// No description provided for @meetingsPlayFrom.
  ///
  /// In zh, this message translates to:
  /// **'从 {time} 开始播放'**
  String meetingsPlayFrom(String time);

  /// No description provided for @meetingsAudioLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载录音…'**
  String get meetingsAudioLoading;

  /// No description provided for @meetingsAudioUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'该会议没有录音'**
  String get meetingsAudioUnavailable;

  /// No description provided for @meetingsAudioLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'录音加载失败'**
  String get meetingsAudioLoadFailed;

  /// No description provided for @meetingsAudioPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get meetingsAudioPlay;

  /// No description provided for @meetingsAudioPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get meetingsAudioPause;

  /// No description provided for @meetingsAudioBack.
  ///
  /// In zh, this message translates to:
  /// **'后退 {seconds} 秒'**
  String meetingsAudioBack(int seconds);

  /// No description provided for @meetingsAudioForward.
  ///
  /// In zh, this message translates to:
  /// **'前进 {seconds} 秒'**
  String meetingsAudioForward(int seconds);

  /// No description provided for @meetingsAudioSpeed.
  ///
  /// In zh, this message translates to:
  /// **'播放速度'**
  String get meetingsAudioSpeed;

  /// No description provided for @meetingsAudioSpeedValue.
  ///
  /// In zh, this message translates to:
  /// **'{speed}×'**
  String meetingsAudioSpeedValue(String speed);

  /// No description provided for @meetingsAudioPosition.
  ///
  /// In zh, this message translates to:
  /// **'播放进度'**
  String get meetingsAudioPosition;

  /// No description provided for @meetingsActionCopyTranscript.
  ///
  /// In zh, this message translates to:
  /// **'复制转写'**
  String get meetingsActionCopyTranscript;

  /// No description provided for @meetingsActionShare.
  ///
  /// In zh, this message translates to:
  /// **'分享（Markdown）'**
  String get meetingsActionShare;

  /// No description provided for @meetingsActionRetranscribe.
  ///
  /// In zh, this message translates to:
  /// **'重新转写'**
  String get meetingsActionRetranscribe;

  /// No description provided for @meetingsActionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除会议'**
  String get meetingsActionDelete;

  /// No description provided for @meetingsTranscriptCopied.
  ///
  /// In zh, this message translates to:
  /// **'转写内容已复制'**
  String get meetingsTranscriptCopied;

  /// No description provided for @meetingsTranscriptCopyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有可复制的转写内容'**
  String get meetingsTranscriptCopyEmpty;

  /// No description provided for @meetingsShareEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有可分享的内容'**
  String get meetingsShareEmpty;

  /// No description provided for @meetingsExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String meetingsExportFailed(String error);

  /// No description provided for @meetingsMdTranscriptTitle.
  ///
  /// In zh, this message translates to:
  /// **'会议转写：{title}'**
  String meetingsMdTranscriptTitle(String title);

  /// No description provided for @meetingsMdSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'会议总结：{title}'**
  String meetingsMdSummaryTitle(String title);

  /// No description provided for @meetingsMdDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get meetingsMdDate;

  /// No description provided for @meetingsMdDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get meetingsMdDuration;

  /// No description provided for @meetingsMdMeetingId.
  ///
  /// In zh, this message translates to:
  /// **'会议 ID'**
  String get meetingsMdMeetingId;

  /// No description provided for @meetingsMdSummary.
  ///
  /// In zh, this message translates to:
  /// **'总结'**
  String get meetingsMdSummary;

  /// No description provided for @meetingsMdTranscript.
  ///
  /// In zh, this message translates to:
  /// **'转写'**
  String get meetingsMdTranscript;

  /// No description provided for @meetingsMdNoSummary.
  ///
  /// In zh, this message translates to:
  /// **'（暂无总结）'**
  String get meetingsMdNoSummary;

  /// No description provided for @meetingsRetranscribeTitle.
  ///
  /// In zh, this message translates to:
  /// **'重新转写会议'**
  String get meetingsRetranscribeTitle;

  /// No description provided for @meetingsRetranscribeDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用不同的语言设置重新处理录音，现有转写将被替换。'**
  String get meetingsRetranscribeDescription;

  /// No description provided for @meetingsRetranscribeHint.
  ///
  /// In zh, this message translates to:
  /// **'将使用服务器当前的语音识别模型。指定语言可提高准确率。'**
  String get meetingsRetranscribeHint;

  /// No description provided for @meetingsRetranscribeStart.
  ///
  /// In zh, this message translates to:
  /// **'开始重新转写'**
  String get meetingsRetranscribeStart;

  /// No description provided for @meetingsRetranscribeRunning.
  ///
  /// In zh, this message translates to:
  /// **'正在重新转写…'**
  String get meetingsRetranscribeRunning;

  /// No description provided for @meetingsRetranscribeComplete.
  ///
  /// In zh, this message translates to:
  /// **'重新转写完成，共生成 {count} 段'**
  String meetingsRetranscribeComplete(int count);

  /// No description provided for @meetingsRetranscribeCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消重新转写'**
  String get meetingsRetranscribeCancelled;

  /// No description provided for @meetingsRetranscribeAlreadyRunning.
  ///
  /// In zh, this message translates to:
  /// **'该会议已有正在进行的转写任务'**
  String get meetingsRetranscribeAlreadyRunning;

  /// No description provided for @meetingsTranscriptionLanguage.
  ///
  /// In zh, this message translates to:
  /// **'转写语言'**
  String get meetingsTranscriptionLanguage;

  /// No description provided for @meetingsLanguageName.
  ///
  /// In zh, this message translates to:
  /// **'{code, select, auto{自动检测（保留原语言）} zh{中文} en{英语} ja{日语} ko{韩语} yue{粤语} de{德语} fr{法语} es{西班牙语} ru{俄语} it{意大利语} pt{葡萄牙语} other{{code}}}'**
  String meetingsLanguageName(String code);

  /// No description provided for @meetingsJobProgress.
  ///
  /// In zh, this message translates to:
  /// **'{percent}%'**
  String meetingsJobProgress(int percent);

  /// No description provided for @summaryCustomPromptLabel.
  ///
  /// In zh, this message translates to:
  /// **'补充说明（可选）'**
  String get summaryCustomPromptLabel;

  /// No description provided for @summaryCustomPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'参会人、会议目标、背景信息等，帮助 AI 生成更准确的总结。'**
  String get summaryCustomPromptHint;

  /// No description provided for @summaryGenerate.
  ///
  /// In zh, this message translates to:
  /// **'生成总结'**
  String get summaryGenerate;

  /// No description provided for @summaryRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get summaryRegenerate;

  /// No description provided for @summaryStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get summaryStop;

  /// No description provided for @summaryGenerating.
  ///
  /// In zh, this message translates to:
  /// **'正在生成总结…'**
  String get summaryGenerating;

  /// No description provided for @summaryGeneratingHint.
  ///
  /// In zh, this message translates to:
  /// **'较长的会议可能需要一分钟，期间可以继续查看转写。'**
  String get summaryGeneratingHint;

  /// No description provided for @summaryEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无总结'**
  String get summaryEmptyTitle;

  /// No description provided for @summaryEmptyDescription.
  ///
  /// In zh, this message translates to:
  /// **'生成 AI 总结，提取会议要点、决策和待办事项。'**
  String get summaryEmptyDescription;

  /// No description provided for @summaryLlmNotReady.
  ///
  /// In zh, this message translates to:
  /// **'会议总结暂不可用，请稍后再试或联系管理员。'**
  String get summaryLlmNotReady;

  /// No description provided for @summaryFailedGeneration.
  ///
  /// In zh, this message translates to:
  /// **'生成总结失败'**
  String get summaryFailedGeneration;

  /// No description provided for @summaryFailedGenerationDetail.
  ///
  /// In zh, this message translates to:
  /// **'生成总结失败：{error}'**
  String summaryFailedGenerationDetail(String error);

  /// No description provided for @summaryFailedEmpty.
  ///
  /// In zh, this message translates to:
  /// **'生成的总结没有可显示的内容，请重试'**
  String get summaryFailedEmpty;

  /// No description provided for @summaryFailedTimeout.
  ///
  /// In zh, this message translates to:
  /// **'总结生成时间过长，请稍后刷新查看'**
  String get summaryFailedTimeout;

  /// No description provided for @summaryCompleted.
  ///
  /// In zh, this message translates to:
  /// **'总结已生成'**
  String get summaryCompleted;

  /// No description provided for @summaryStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止生成总结'**
  String get summaryStopped;

  /// No description provided for @summaryStopFailed.
  ///
  /// In zh, this message translates to:
  /// **'停止失败：{error}'**
  String summaryStopFailed(String error);

  /// No description provided for @summaryEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑总结'**
  String get summaryEdit;

  /// No description provided for @summaryEditTab.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get summaryEditTab;

  /// No description provided for @summaryPreviewTab.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get summaryPreviewTab;

  /// No description provided for @summaryEditHint.
  ///
  /// In zh, this message translates to:
  /// **'使用 Markdown 编辑总结'**
  String get summaryEditHint;

  /// No description provided for @summarySaved.
  ///
  /// In zh, this message translates to:
  /// **'总结已保存'**
  String get summarySaved;

  /// No description provided for @summarySaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String summarySaveFailed(String error);

  /// No description provided for @summaryDiscardTitle.
  ///
  /// In zh, this message translates to:
  /// **'放弃未保存的修改？'**
  String get summaryDiscardTitle;

  /// No description provided for @summaryDiscard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get summaryDiscard;

  /// No description provided for @summaryCopied.
  ///
  /// In zh, this message translates to:
  /// **'总结已复制'**
  String get summaryCopied;

  /// No description provided for @summaryCopyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有可复制的总结内容'**
  String get summaryCopyEmpty;

  /// No description provided for @summaryAutoStarted.
  ///
  /// In zh, this message translates to:
  /// **'已自动开始生成总结'**
  String get summaryAutoStarted;

  /// No description provided for @importDescription.
  ///
  /// In zh, this message translates to:
  /// **'从音频文件创建新会议，文件将上传到服务器并完成转写。'**
  String get importDescription;

  /// No description provided for @importPickFile.
  ///
  /// In zh, this message translates to:
  /// **'选择音频文件'**
  String get importPickFile;

  /// No description provided for @importSupportedFormats.
  ///
  /// In zh, this message translates to:
  /// **'支持格式：{formats}'**
  String importSupportedFormats(String formats);

  /// No description provided for @importChangeFile.
  ///
  /// In zh, this message translates to:
  /// **'更换文件'**
  String get importChangeFile;

  /// No description provided for @importMeetingTitle.
  ///
  /// In zh, this message translates to:
  /// **'会议标题'**
  String get importMeetingTitle;

  /// No description provided for @importTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入会议标题'**
  String get importTitleHint;

  /// No description provided for @importLanguageHint.
  ///
  /// In zh, this message translates to:
  /// **'音频将上传到服务器，并使用服务器当前的语音识别模型转写。'**
  String get importLanguageHint;

  /// No description provided for @importStart.
  ///
  /// In zh, this message translates to:
  /// **'开始导入'**
  String get importStart;

  /// No description provided for @importUploading.
  ///
  /// In zh, this message translates to:
  /// **'正在上传音频…'**
  String get importUploading;

  /// No description provided for @importSubmitting.
  ///
  /// In zh, this message translates to:
  /// **'已上传，正在提交到服务器…'**
  String get importSubmitting;

  /// No description provided for @importUploadedBackground.
  ///
  /// In zh, this message translates to:
  /// **'音频已上传，正在后台转写'**
  String get importUploadedBackground;

  /// No description provided for @importBackgroundHint.
  ///
  /// In zh, this message translates to:
  /// **'上传完成后即可离开此页面，服务器会在后台完成转写。'**
  String get importBackgroundHint;

  /// No description provided for @importTranscribed.
  ///
  /// In zh, this message translates to:
  /// **'「{title}」转写完成，共 {count} 段'**
  String importTranscribed(String title, int count);

  /// No description provided for @importTranscribeFailed.
  ///
  /// In zh, this message translates to:
  /// **'「{title}」转写失败：{message}'**
  String importTranscribeFailed(String title, String message);

  /// No description provided for @importTranscribeLost.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法获取「{title}」的转写进度，请稍后在会议列表中查看'**
  String importTranscribeLost(String title);

  /// No description provided for @importCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消导入'**
  String get importCancelled;

  /// No description provided for @importDisabled.
  ///
  /// In zh, this message translates to:
  /// **'导入音频功能未开启'**
  String get importDisabled;

  /// No description provided for @importFileSize.
  ///
  /// In zh, this message translates to:
  /// **'{size} MB · 更换文件'**
  String importFileSize(String size);

  /// No description provided for @importFailedDetail.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{error}'**
  String importFailedDetail(String error);

  /// Onboarding progress, e.g. 2/4
  ///
  /// In zh, this message translates to:
  /// **'{current}/{total}'**
  String onboardingStepProgress(int current, int total);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用深应会议'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In zh, this message translates to:
  /// **'录音、实时转写、AI 会议纪要，一个 App 全部搞定。先选择界面语言。'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录或注册'**
  String get onboardingAccountTitle;

  /// No description provided for @onboardingAccountBody.
  ///
  /// In zh, this message translates to:
  /// **'使用手机号和短信验证码登录，新用户可直接注册。'**
  String get onboardingAccountBody;

  /// No description provided for @onboardingSignedInAs.
  ///
  /// In zh, this message translates to:
  /// **'已登录：{name}'**
  String onboardingSignedInAs(String name);

  /// No description provided for @onboardingSwitchAccount.
  ///
  /// In zh, this message translates to:
  /// **'切换账号'**
  String get onboardingSwitchAccount;

  /// No description provided for @onboardingMicTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许使用麦克风'**
  String get onboardingMicTitle;

  /// No description provided for @onboardingMicBody.
  ///
  /// In zh, this message translates to:
  /// **'录制会议需要使用麦克风。音频只上传到你设置的服务器，用于转写和生成纪要。也可以稍后在录音时再授权。'**
  String get onboardingMicBody;

  /// No description provided for @onboardingMicAllow.
  ///
  /// In zh, this message translates to:
  /// **'允许访问麦克风'**
  String get onboardingMicAllow;

  /// No description provided for @onboardingMicGranted.
  ///
  /// In zh, this message translates to:
  /// **'已允许使用麦克风'**
  String get onboardingMicGranted;

  /// No description provided for @onboardingMicDenied.
  ///
  /// In zh, this message translates to:
  /// **'麦克风权限已被拒绝，请在系统设置中开启。'**
  String get onboardingMicDenied;

  /// No description provided for @onboardingMicOpenSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开系统设置'**
  String get onboardingMicOpenSettings;

  /// No description provided for @onboardingMicSkip.
  ///
  /// In zh, this message translates to:
  /// **'暂不授权，稍后再说'**
  String get onboardingMicSkip;

  /// Generated meeting title; timestamp formatted with AppConfig.recording.titleFormat
  ///
  /// In zh, this message translates to:
  /// **'会议 {timestamp}'**
  String recordingMeetingTitle(String timestamp);

  /// No description provided for @recordingNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新录音'**
  String get recordingNewTitle;

  /// No description provided for @recordingTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'会议标题'**
  String get recordingTitleHint;

  /// No description provided for @recordingRename.
  ///
  /// In zh, this message translates to:
  /// **'修改标题'**
  String get recordingRename;

  /// No description provided for @recordingStatusIdle.
  ///
  /// In zh, this message translates to:
  /// **'准备就绪'**
  String get recordingStatusIdle;

  /// No description provided for @recordingStatusPreparing.
  ///
  /// In zh, this message translates to:
  /// **'准备中…'**
  String get recordingStatusPreparing;

  /// No description provided for @recordingStatusRecording.
  ///
  /// In zh, this message translates to:
  /// **'录音中'**
  String get recordingStatusRecording;

  /// No description provided for @recordingStatusPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get recordingStatusPaused;

  /// No description provided for @recordingStatusInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'已中断'**
  String get recordingStatusInterrupted;

  /// No description provided for @recordingStatusStopping.
  ///
  /// In zh, this message translates to:
  /// **'正在结束…'**
  String get recordingStatusStopping;

  /// No description provided for @recordingStatusDone.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get recordingStatusDone;

  /// No description provided for @recordingStatusError.
  ///
  /// In zh, this message translates to:
  /// **'出错'**
  String get recordingStatusError;

  /// No description provided for @recordingStart.
  ///
  /// In zh, this message translates to:
  /// **'开始录音'**
  String get recordingStart;

  /// No description provided for @recordingStop.
  ///
  /// In zh, this message translates to:
  /// **'停止录音'**
  String get recordingStop;

  /// No description provided for @recordingPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get recordingPause;

  /// No description provided for @recordingResume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get recordingResume;

  /// No description provided for @recordingInterruptedHint.
  ///
  /// In zh, this message translates to:
  /// **'录音被来电或其他应用中断，点击「继续」恢复录音'**
  String get recordingInterruptedHint;

  /// No description provided for @recordingStoppingHint.
  ///
  /// In zh, this message translates to:
  /// **'正在保存录音…'**
  String get recordingStoppingHint;

  /// No description provided for @recordingPendingUploads.
  ///
  /// In zh, this message translates to:
  /// **'{count} 段语音待上传，网络恢复后会自动补传'**
  String recordingPendingUploads(int count);

  /// No description provided for @recordingTranscriptTitle.
  ///
  /// In zh, this message translates to:
  /// **'实时转写'**
  String get recordingTranscriptTitle;

  /// No description provided for @recordingTranscriptEmpty.
  ///
  /// In zh, this message translates to:
  /// **'开始录音后，转写内容会实时显示在这里'**
  String get recordingTranscriptEmpty;

  /// No description provided for @recordingSourceLabel.
  ///
  /// In zh, this message translates to:
  /// **'录音来源'**
  String get recordingSourceLabel;

  /// No description provided for @recordingSourceMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'麦克风'**
  String get recordingSourceMicrophone;

  /// No description provided for @recordingSourceSystem.
  ///
  /// In zh, this message translates to:
  /// **'内录'**
  String get recordingSourceSystem;

  /// No description provided for @recordingSourceUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前设备不支持内录'**
  String get recordingSourceUnsupported;

  /// No description provided for @recordingSourceNeedsPermission.
  ///
  /// In zh, this message translates to:
  /// **'首次使用需要授权'**
  String get recordingSourceNeedsPermission;

  /// No description provided for @recordingSourceLimitationsLink.
  ///
  /// In zh, this message translates to:
  /// **'内录说明'**
  String get recordingSourceLimitationsLink;

  /// No description provided for @recordingLimitationsTitle.
  ///
  /// In zh, this message translates to:
  /// **'关于内录'**
  String get recordingLimitationsTitle;

  /// No description provided for @recordingLimitationsMix.
  ///
  /// In zh, this message translates to:
  /// **'内录会把手机播放的声音和麦克风一起录下来，适合外放的线上会议、视频等场景。'**
  String get recordingLimitationsMix;

  /// No description provided for @recordingLimitationsCalls.
  ///
  /// In zh, this message translates to:
  /// **'系统不允许录制语音通话中对方的声音（例如微信、腾讯会议的通话），部分应用也禁止被录制。遇到这类场景，请打开免提，改用麦克风收音。'**
  String get recordingLimitationsCalls;

  /// No description provided for @recordingLimitationsConsent.
  ///
  /// In zh, this message translates to:
  /// **'开始内录时系统会请求屏幕录制或直播授权，录制期间系统会显示录制提示。'**
  String get recordingLimitationsConsent;

  /// No description provided for @recordingLimitationsDevice.
  ///
  /// In zh, this message translates to:
  /// **'部分系统版本或设备不支持内录，此时只能使用麦克风。'**
  String get recordingLimitationsDevice;

  /// No description provided for @recordingErrorPermission.
  ///
  /// In zh, this message translates to:
  /// **'没有麦克风权限，请在系统设置中允许「深应会议」使用麦克风。'**
  String get recordingErrorPermission;

  /// No description provided for @recordingErrorCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消授权，录音未开始。'**
  String get recordingErrorCancelled;

  /// No description provided for @recordingErrorUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前设备不支持所选的录音来源。'**
  String get recordingErrorUnsupported;

  /// No description provided for @recordingErrorBusy.
  ///
  /// In zh, this message translates to:
  /// **'录音设备正被其他应用占用，请稍后再试。'**
  String get recordingErrorBusy;

  /// No description provided for @recordingErrorPlatform.
  ///
  /// In zh, this message translates to:
  /// **'无法启动录音，请重试。'**
  String get recordingErrorPlatform;

  /// No description provided for @recordingErrorStartTitle.
  ///
  /// In zh, this message translates to:
  /// **'无法开始录音'**
  String get recordingErrorStartTitle;

  /// No description provided for @recordingErrorUploadTitle.
  ///
  /// In zh, this message translates to:
  /// **'录音文件上传失败'**
  String get recordingErrorUploadTitle;

  /// No description provided for @recordingRetryUpload.
  ///
  /// In zh, this message translates to:
  /// **'重新上传'**
  String get recordingRetryUpload;

  /// No description provided for @recordingUseMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'改用麦克风'**
  String get recordingUseMicrophone;

  /// No description provided for @recordingSettingsAction.
  ///
  /// In zh, this message translates to:
  /// **'打开设置'**
  String get recordingSettingsAction;

  /// No description provided for @recordingNotificationChannel.
  ///
  /// In zh, this message translates to:
  /// **'录音'**
  String get recordingNotificationChannel;

  /// No description provided for @recordingNotificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'深应会议正在录音'**
  String get recordingNotificationTitle;

  /// No description provided for @recordingNotificationText.
  ///
  /// In zh, this message translates to:
  /// **'已录制 {elapsed}'**
  String recordingNotificationText(String elapsed);

  /// No description provided for @recordingBusyLeaveHint.
  ///
  /// In zh, this message translates to:
  /// **'录音进行中，可在通知栏或本页停止录音'**
  String get recordingBusyLeaveHint;

  /// No description provided for @recordingLanguageLabel.
  ///
  /// In zh, this message translates to:
  /// **'转写语言'**
  String get recordingLanguageLabel;

  /// No description provided for @settingsChangeAvatar.
  ///
  /// In zh, this message translates to:
  /// **'修改头像'**
  String get settingsChangeAvatar;

  /// No description provided for @settingsAvatarPicking.
  ///
  /// In zh, this message translates to:
  /// **'正在选择图片…'**
  String get settingsAvatarPicking;

  /// No description provided for @settingsAvatarUploading.
  ///
  /// In zh, this message translates to:
  /// **'正在上传头像…'**
  String get settingsAvatarUploading;

  /// No description provided for @settingsAvatarSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存头像…'**
  String get settingsAvatarSaving;

  /// No description provided for @settingsAvatarSaved.
  ///
  /// In zh, this message translates to:
  /// **'头像已更新'**
  String get settingsAvatarSaved;

  /// No description provided for @settingsAvatarHint.
  ///
  /// In zh, this message translates to:
  /// **'支持 PNG、JPG、WebP，最大 {megabytes} MB'**
  String settingsAvatarHint(int megabytes);

  /// No description provided for @settingsAvatarSize.
  ///
  /// In zh, this message translates to:
  /// **'图片不能超过 {megabytes} MB，请重新选择。'**
  String settingsAvatarSize(int megabytes);

  /// No description provided for @settingsAvatarType.
  ///
  /// In zh, this message translates to:
  /// **'请选择有效的 PNG、JPG 或 WebP 图片。'**
  String get settingsAvatarType;

  /// No description provided for @settingsAvatarPickFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取图片，请检查权限后重新选择。'**
  String get settingsAvatarPickFailed;

  /// No description provided for @settingsAvatarUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'头像上传失败，原头像已保留，请重试。'**
  String get settingsAvatarUploadFailed;

  /// No description provided for @settingsAvatarSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'头像保存失败，原头像已保留，请重试。'**
  String get settingsAvatarSaveFailed;

  /// No description provided for @settingsAccountSection.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get settingsAccountSection;

  /// No description provided for @settingsEditName.
  ///
  /// In zh, this message translates to:
  /// **'修改姓名'**
  String get settingsEditName;

  /// No description provided for @settingsLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出登录？'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'退出后需要使用密码或短信验证码重新登录。'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @settingsLockedWhileRecording.
  ///
  /// In zh, this message translates to:
  /// **'正在录音，结束后才能操作'**
  String get settingsLockedWhileRecording;

  /// No description provided for @settingsPreferencesSection.
  ///
  /// In zh, this message translates to:
  /// **'偏好'**
  String get settingsPreferencesSection;

  /// No description provided for @settingsDefaultSource.
  ///
  /// In zh, this message translates to:
  /// **'默认录音来源'**
  String get settingsDefaultSource;

  /// No description provided for @settingsSourceMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'仅麦克风'**
  String get settingsSourceMicrophone;

  /// No description provided for @settingsSourceMicrophoneHint.
  ///
  /// In zh, this message translates to:
  /// **'适合线下会议，录制现场声音。'**
  String get settingsSourceMicrophoneHint;

  /// No description provided for @settingsSourceSystem.
  ///
  /// In zh, this message translates to:
  /// **'允许内录（系统声音 + 麦克风）'**
  String get settingsSourceSystem;

  /// No description provided for @settingsSourceSystemHintAndroid.
  ///
  /// In zh, this message translates to:
  /// **'需要 Android 10 及以上，开始录音时需授权录屏。系统不允许录制语音通话中对方的声音（如微信、腾讯会议通话）以及禁止内录的 App，这类场景请开免提用麦克风收音。'**
  String get settingsSourceSystemHintAndroid;

  /// No description provided for @settingsSourceSystemHintIos.
  ///
  /// In zh, this message translates to:
  /// **'通过系统「屏幕直播」录制，录音期间状态栏会变红。部分 App 的通话音频和受保护内容会被系统静音；模拟器不支持。'**
  String get settingsSourceSystemHintIos;

  /// No description provided for @settingsTranscriptionLanguage.
  ///
  /// In zh, this message translates to:
  /// **'转写语言'**
  String get settingsTranscriptionLanguage;

  /// No description provided for @settingsAutoSummary.
  ///
  /// In zh, this message translates to:
  /// **'自动生成纪要'**
  String get settingsAutoSummary;

  /// No description provided for @settingsAutoSummaryHint.
  ///
  /// In zh, this message translates to:
  /// **'录音或导入完成后自动生成 AI 会议纪要'**
  String get settingsAutoSummaryHint;

  /// No description provided for @settingsKeepLocalAudio.
  ///
  /// In zh, this message translates to:
  /// **'保留本地录音'**
  String get settingsKeepLocalAudio;

  /// No description provided for @settingsKeepLocalAudioHint.
  ///
  /// In zh, this message translates to:
  /// **'上传成功后仍在手机上保留音频文件'**
  String get settingsKeepLocalAudioHint;

  /// No description provided for @settingsAboutSection.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAboutSection;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsPassword.
  ///
  /// In zh, this message translates to:
  /// **'登录密码'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordIsSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get settingsPasswordIsSet;

  /// No description provided for @settingsPasswordNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置，目前仅可用验证码登录'**
  String get settingsPasswordNotSet;

  /// No description provided for @settingsSetPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置密码'**
  String get settingsSetPassword;

  /// No description provided for @settingsChangePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get settingsChangePassword;

  /// No description provided for @settingsSetPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'设置后可以使用手机号 + 密码登录，验证码登录仍然可用。'**
  String get settingsSetPasswordHint;

  /// No description provided for @settingsChangePasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'修改后，登录此账号的其他设备将退出登录。忘记原密码可退出登录后在登录页「忘记密码？」重置。'**
  String get settingsChangePasswordHint;

  /// No description provided for @settingsOldPassword.
  ///
  /// In zh, this message translates to:
  /// **'原密码'**
  String get settingsOldPassword;

  /// No description provided for @settingsOldPasswordRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入原密码'**
  String get settingsOldPasswordRequired;

  /// No description provided for @settingsPasswordSaved.
  ///
  /// In zh, this message translates to:
  /// **'密码已设置，之后可以使用密码登录'**
  String get settingsPasswordSaved;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In zh, this message translates to:
  /// **'密码已修改，其他设备已退出登录'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsPasswordFailed.
  ///
  /// In zh, this message translates to:
  /// **'密码保存失败：{detail}'**
  String settingsPasswordFailed(String detail);

  /// Android notification channel name for the system-audio capture foreground service
  ///
  /// In zh, this message translates to:
  /// **'内录'**
  String get systemAudioNotificationChannelName;

  /// Android foreground-service notification title while capturing system audio
  ///
  /// In zh, this message translates to:
  /// **'深应会议正在内录'**
  String get systemAudioNotificationTitle;

  /// Android foreground-service notification body while capturing system audio
  ///
  /// In zh, this message translates to:
  /// **'正在采集手机播放的声音，点按返回应用'**
  String get systemAudioNotificationText;

  /// iOS: message of the system alert shown when the app ends the screen broadcast
  ///
  /// In zh, this message translates to:
  /// **'录音已结束，内录直播已停止。'**
  String get systemAudioBroadcastStoppedByApp;

  /// iOS: shown when the broadcast was started from Control Center instead of from the app
  ///
  /// In zh, this message translates to:
  /// **'请先在深应会议的录音页选择「允许内录」并开始录音，再开始直播。'**
  String get systemAudioBroadcastNotStartedFromApp;

  /// Title of the explanation shown before the Android screen-capture consent dialog
  ///
  /// In zh, this message translates to:
  /// **'允许内录'**
  String get systemAudioAndroidConsentTitle;

  /// Explanation shown before the Android MediaProjection consent dialog
  ///
  /// In zh, this message translates to:
  /// **'接下来系统会询问是否允许深应会议录制或投放屏幕上的内容。请选择「整个屏幕」并点「开始」。深应会议只采集声音，不录制画面。录音期间通知栏会显示内录通知。'**
  String get systemAudioAndroidConsentBody;

  /// Android system-audio capture limitations
  ///
  /// In zh, this message translates to:
  /// **'通话中对方的声音（例如微信、腾讯会议的语音或视频通话）以及禁止被录制的 App 无法内录。这类场景请打开免提，由麦克风收音。'**
  String get systemAudioAndroidLimitations;

  /// Shown on Android 9 and below
  ///
  /// In zh, this message translates to:
  /// **'内录需要 Android 10 及以上版本。'**
  String get systemAudioAndroidUnsupported;

  /// iOS: how to start the broadcast for system-audio capture
  ///
  /// In zh, this message translates to:
  /// **'在弹出的系统面板中选择「深应会议」，点「开始直播」，倒计时结束后开始内录。录音期间状态栏会显示红色指示。'**
  String get systemAudioIosHowToStart;

  /// iOS: the broadcast picker's microphone toggle controls whether the mic is mixed in
  ///
  /// In zh, this message translates to:
  /// **'如需同时录入你自己的声音，请在面板中打开麦克风。'**
  String get systemAudioIosMicHint;

  /// iOS system-audio capture limitations
  ///
  /// In zh, this message translates to:
  /// **'部分 App 的通话音频和受保护的内容会被系统静音，无法内录。这类场景请打开免提，由麦克风收音。'**
  String get systemAudioIosLimitations;

  /// iOS: how the broadcast can be stopped
  ///
  /// In zh, this message translates to:
  /// **'可以在深应会议中停止录音，也可以点状态栏的红色指示停止直播。'**
  String get systemAudioIosStopHint;

  /// iOS simulator cannot run broadcast extensions
  ///
  /// In zh, this message translates to:
  /// **'模拟器不支持内录，请在真机上使用。'**
  String get systemAudioIosSimulatorUnsupported;

  /// User declined the consent dialog or did not start the broadcast
  ///
  /// In zh, this message translates to:
  /// **'已取消内录授权。'**
  String get systemAudioErrorUserCancelled;

  /// RECORD_AUDIO / microphone permission denied
  ///
  /// In zh, this message translates to:
  /// **'没有录音权限，无法内录。请在系统设置中允许深应会议使用麦克风。'**
  String get systemAudioErrorPermissionDenied;

  /// System-audio capture unsupported on this device
  ///
  /// In zh, this message translates to:
  /// **'当前设备不支持内录。'**
  String get systemAudioErrorUnsupported;

  /// Capture already running or audio input busy
  ///
  /// In zh, this message translates to:
  /// **'内录正被占用或无法启动，请稍后重试。'**
  String get systemAudioErrorBusy;

  /// Generic native failure
  ///
  /// In zh, this message translates to:
  /// **'内录启动失败：{detail}'**
  String systemAudioErrorPlatform(String detail);

  /// The projection/broadcast was stopped outside the app
  ///
  /// In zh, this message translates to:
  /// **'内录已在系统中被停止，录音已结束。'**
  String get systemAudioStoppedExternally;

  /// Action offered when system-audio capture cannot start
  ///
  /// In zh, this message translates to:
  /// **'改为仅麦克风录音'**
  String get systemAudioFallbackToMicrophone;

  /// No description provided for @updateDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {version}'**
  String updateDialogTitle(String version);

  /// No description provided for @updateCurrentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本 {version}'**
  String updateCurrentVersion(String version);

  /// No description provided for @updateNotes.
  ///
  /// In zh, this message translates to:
  /// **'更新内容'**
  String get updateNotes;

  /// No description provided for @updateLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In zh, this message translates to:
  /// **'立即更新'**
  String get updateNow;

  /// No description provided for @updateGoToStore.
  ///
  /// In zh, this message translates to:
  /// **'前往应用商店更新'**
  String get updateGoToStore;

  /// No description provided for @updateGoToAppStore.
  ///
  /// In zh, this message translates to:
  /// **'前往 App Store 更新'**
  String get updateGoToAppStore;

  /// No description provided for @updateDownloading.
  ///
  /// In zh, this message translates to:
  /// **'正在下载… {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateDownloadingUnknown.
  ///
  /// In zh, this message translates to:
  /// **'正在下载…'**
  String get updateDownloadingUnknown;

  /// No description provided for @updateInstalling.
  ///
  /// In zh, this message translates to:
  /// **'正在打开安装程序…'**
  String get updateInstalling;

  /// No description provided for @updateForceTitle.
  ///
  /// In zh, this message translates to:
  /// **'需要更新到新版本'**
  String get updateForceTitle;

  /// No description provided for @updateForceMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前版本 {current} 已停止支持，请更新到 {version} 后继续使用。'**
  String updateForceMessage(String current, String version);

  /// No description provided for @updateCheck.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get updateCheck;

  /// No description provided for @updateUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本'**
  String get updateUpToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请稍后再试'**
  String get updateCheckFailed;

  /// No description provided for @updateFailedDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载失败，请检查网络后重试'**
  String get updateFailedDownload;

  /// No description provided for @updateFailedChecksum.
  ///
  /// In zh, this message translates to:
  /// **'安装包校验失败，请重试'**
  String get updateFailedChecksum;

  /// No description provided for @updateFailedPermission.
  ///
  /// In zh, this message translates to:
  /// **'请在系统设置中允许本应用安装未知应用，返回后再点「立即更新」'**
  String get updateFailedPermission;

  /// No description provided for @updateFailedInstall.
  ///
  /// In zh, this message translates to:
  /// **'无法打开安装程序，请重试'**
  String get updateFailedInstall;

  /// No description provided for @updateFailedStore.
  ///
  /// In zh, this message translates to:
  /// **'无法打开应用商店'**
  String get updateFailedStore;

  /// No description provided for @updateFailedSyncing.
  ///
  /// In zh, this message translates to:
  /// **'会议仍在后台同步，请稍后再更新'**
  String get updateFailedSyncing;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
