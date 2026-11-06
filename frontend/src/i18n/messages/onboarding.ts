import { defineMessages } from '../types';

export default defineMessages({
  en: {
    container: {
      heroHeadline: 'Every meeting, captured and understood',
      heroSubtitle: 'Record locally, transcribe in real time, and get clear summaries from your team server.',
      values: {
        record: 'Record meetings on this device with live transcription',
        server: 'Speech recognition and meeting records are handled by your team server',
        summary: 'Generate smart meeting summaries in one click',
      },
      privacyNote: 'Your data stays within your organization',
      stepOf: 'Step {current} of {total}',
    },
    progress: {
      welcome: 'Welcome',
      account: 'Sign in',
      permissions: 'Permissions',
    },
    welcome: {
      title: 'Welcome to {appName}',
      description: 'Record, transcribe and summarize — all in one place.',
      languageTitle: 'Choose your language',
      languageHint: 'You can change this at any time later.',
      start: 'Get started',
      duration: 'Takes about a minute',
    },
    account: {
      title: 'Sign in with your mobile number',
      description: 'Your meetings are kept in your own account on the server. Sign in, or sign up if this is your first time.',
      signedInAs: 'Signed in as {name}',
      signedInHint: 'You are already signed in on this device.',
      finish: 'Finish setup',
      useAnother: 'Use another account',
    },
    permissions: {
      title: 'Grant permissions',
      description: '{appName} needs access to your microphone and system audio to record meetings.',
      microphone: {
        title: 'Microphone',
        description: 'Required to capture your voice during meetings',
      },
      systemAudio: {
        title: 'System audio',
        description: 'Click Enable to grant Audio Capture permission',
      },
      finish: 'Finish setup',
      later: "I'll do this later",
      warning: "Recording won't work without permissions. You can grant them later in settings.",
      alerts: {
        microphone: 'Please enable microphone access in System Settings → Privacy & Security → Microphone',
        systemAudio: 'Please enable Audio Capture in System Settings → Privacy & Security → Audio Capture',
      },
    },
    status: {
      checking: 'Checking…',
      enable: 'Enable',
      openSettings: 'Open Settings',
      granted: 'Access granted',
      denied: 'Access denied — please grant it in System Settings',
    },
  },
  'zh-CN': {
    container: {
      heroHeadline: '每一场会议，都被完整记录与理解',
      heroSubtitle: '本机录音，实时转写，由团队服务器生成清晰的会议总结。',
      values: {
        record: '在本机录制会议，实时转写',
        server: '语音识别与会议记录由团队服务器统一处理和保存',
        summary: '一键生成智能会议总结',
      },
      privacyNote: '数据始终保留在您的组织内部',
      stepOf: '第 {current} 步，共 {total} 步',
    },
    progress: {
      welcome: '欢迎',
      account: '登录',
      permissions: '权限',
    },
    welcome: {
      title: '欢迎使用{appName}',
      description: '录音、转写、总结，一站完成。',
      languageTitle: '选择界面语言',
      languageHint: '之后可随时在设置中更改。',
      start: '开始设置',
      duration: '只需一分钟',
    },
    account: {
      title: '手机号登录',
      description: '会议记录保存在服务器上您自己的账号中。首次使用请先注册。',
      signedInAs: '已登录：{name}',
      signedInHint: '您已在本设备上登录。',
      finish: '完成设置',
      useAnother: '切换其他账号',
    },
    permissions: {
      title: '授予权限',
      description: '{appName}需要访问麦克风和系统音频才能录制会议。',
      microphone: {
        title: '麦克风',
        description: '用于在会议中采集您的声音',
      },
      systemAudio: {
        title: '系统音频',
        description: '点击“启用”以授予音频捕获权限',
      },
      finish: '完成设置',
      later: '稍后再说',
      warning: '未授予权限将无法录音，您也可以稍后在设置中授予。',
      alerts: {
        microphone: '请在 系统设置 → 隐私与安全性 → 麦克风 中允许访问麦克风',
        systemAudio: '请在 系统设置 → 隐私与安全性 → 音频捕获 中开启音频捕获',
      },
    },
    status: {
      checking: '检查中…',
      enable: '启用',
      openSettings: '打开设置',
      granted: '已授权',
      denied: '已拒绝 — 请在系统设置中授权',
    },
  },
});
