import { defineMessages } from '../types';

// Service availability warnings (sidebar indicator, problem descriptions) and upload toasts.
// Service internals (models, versions, server addresses) are never shown to users.
export default defineMessages({
  en: {
    status: {
      offline: 'Service unreachable',
      unavailable: 'Service unavailable',
    },
    tooltip: {
      recheck: 'Click to check again',
    },
    problems: {
      noStatus: 'Unable to check the service',
      notConfigured: 'The service is not available in this build',
      cannotConnect: 'Cannot connect to the service. Check your network connection.',
      notLoggedIn: 'You are not signed in. Please sign in with your mobile number.',
      sessionInvalid: 'Your sign-in session is no longer valid. Please sign in again.',
      sttNotReady: 'Speech recognition is temporarily unavailable. Please try again later or contact your administrator.',
      llmNotReady: 'Meeting summaries are temporarily unavailable. Please try again later or contact your administrator.',
    },
    upload: {
      progress: 'Uploading recording… {pct}%',
      done: 'Recording uploaded',
      failed: 'Recording upload failed',
    },
  },
  'zh-CN': {
    status: {
      offline: '无法连接服务',
      unavailable: '服务暂不可用',
    },
    tooltip: {
      recheck: '点击重新检查',
    },
    problems: {
      noStatus: '暂时无法检查服务状态',
      notConfigured: '当前版本未配置服务，请联系管理员',
      cannotConnect: '无法连接服务，请检查网络连接',
      notLoggedIn: '尚未登录，请使用手机号登录',
      sessionInvalid: '登录状态已失效，请重新登录',
      sttNotReady: '语音识别暂不可用，请稍后再试或联系管理员',
      llmNotReady: '会议总结暂不可用，请稍后再试或联系管理员',
    },
    upload: {
      progress: '正在上传录音… {pct}%',
      done: '录音已上传',
      failed: '录音上传失败',
    },
  },
});
