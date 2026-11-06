// Compatibility entry. Current screen media is IM RTC; the P2P regression remains in git history.
if(process.env.MEETING_SESSION_OUTPUT&&!process.env.IM_RTC_SCREEN_OUTPUT)process.env.IM_RTC_SCREEN_OUTPUT=process.env.MEETING_SESSION_OUTPUT;
await import('./im-rtc-screen-share.mjs');
