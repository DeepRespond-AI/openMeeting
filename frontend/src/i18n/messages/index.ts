// Registry of all message namespaces. Keys are addressed as "<namespace>.<path>", e.g. t('common.actions.save').
import common from './common';
import nav from './nav';
import onboarding from './onboarding';
import settings from './settings';
import server from './server';
import home from './home';
import recording from './recording';
import transcript from './transcript';
import meeting from './meeting';
import summary from './summary';
import importAudio from './importAudio';
import dialogs from './dialogs';
import auth from './auth';
import update from './update';
import liveMeeting from './liveMeeting';
import im from './im';

export const namespaces = {
  common,
  nav,
  onboarding,
  settings,
  server,
  home,
  recording,
  transcript,
  meeting,
  summary,
  importAudio,
  dialogs,
  auth,
  update,
  liveMeeting,
  im,
};
