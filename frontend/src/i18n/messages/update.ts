import { defineMessages } from '../types';

// App updates: optional-update dialog, forced-update screen, Settings → About check button.
export default defineMessages({
  en: {
    dialog: {
      title: 'New version {version}',
      description: 'You are using version {current}. Update now to get the latest improvements.',
      notes: "What's new",
      later: 'Later',
      install: 'Update now',
      installing: 'Updating…',
      restartHint: 'The app restarts automatically when the update is installed.',
    },
    force: {
      title: 'Update required',
      description: 'Version {current} is no longer supported. Update to {version} to keep using {app}.',
      install: 'Update now',
      retry: 'Try again',
    },
    progress: {
      downloading: 'Downloading… {percent}%',
      downloadingUnknown: 'Downloading…',
    },
    about: {
      check: 'Check for updates',
      checking: 'Checking…',
      upToDate: 'You are using the latest version',
      checkFailed: 'Could not check for updates',
    },
    installFailed: 'Update failed',
  },
  'zh-CN': {
    dialog: {
      title: '发现新版本 {version}',
      description: '当前版本 {current}，更新后即可使用最新功能与修复。',
      notes: '更新内容',
      later: '稍后',
      install: '立即更新',
      installing: '正在更新…',
      restartHint: '更新安装完成后应用会自动重启。',
    },
    force: {
      title: '需要更新到新版本',
      description: '当前版本 {current} 已停止支持，请更新到 {version} 后继续使用{app}。',
      install: '立即更新',
      retry: '重试',
    },
    progress: {
      downloading: '正在下载… {percent}%',
      downloadingUnknown: '正在下载…',
    },
    about: {
      check: '检查更新',
      checking: '正在检查…',
      upToDate: '当前已是最新版本',
      checkFailed: '检查更新失败',
    },
    installFailed: '更新失败',
  },
});
