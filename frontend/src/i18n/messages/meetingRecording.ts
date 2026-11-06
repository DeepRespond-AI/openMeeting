/** Embedded under liveMeeting.room.recording. */
export const recordingMessages = {
  en: {
    start:'Record', stop:'Stop recording', request:'Request recording', active:'Recording', pending:'Pending', busy:'Processing…',
    approvals:'Recording requests', review:'Review recording requests ({count})',
    sharedHint:'Approval starts one shared meeting audio recording on the host’s device. The recording is saved with the meeting and can be transcribed.',
    noRequests:'No pending recording requests', approve:'Approve and record', deny:'Decline',
    startedNotice:'Meeting audio recording is enabled · audio is saved for transcription and meeting notes',
    stoppedNotice:'Recording stopped · saved audio will be processed when the meeting ends',
    off:'This meeting is not being recorded', waitingApproval:'Recording requested · waiting for the host’s approval',
    denied:'The host declined your recording request. You can request again.',
    waitingAudio:'Recording is enabled · waiting for meeting audio',
    failed:'Recording action failed: {message}', retryUpload:'Retry upload',
    unavailable:'Update the server to use meeting recording controls.', requestNotice:'{name} requested meeting recording',
  },
  'zh-CN': {
    start:'录制', stop:'停止录制', request:'申请录制', active:'录制中', pending:'待批准', busy:'处理中…',
    approvals:'录制审批', review:'查看录制申请（{count}）',
    sharedHint:'批准后由主持人统一录制会议音频，录音保存至会议记录，可用于转写与会议纪要。',
    noRequests:'暂无待处理的录制申请', approve:'允许并录制', deny:'拒绝',
    startedNotice:'会议音频录制已开启 · 音频将保存并用于转写与会议纪要',
    stoppedNotice:'录制已停止 · 已保存的音频将在会议结束后处理',
    off:'当前会议未录制', waitingApproval:'已申请录制 · 等待主持人批准',
    denied:'主持人已拒绝本次录制申请，你可以重新申请。',
    waitingAudio:'录制已开启 · 等待会议音频',
    failed:'录制操作失败：{message}', retryUpload:'重试上传',
    unavailable:'请更新服务器以使用会议录制控制。', requestNotice:'{name} 申请录制会议',
  },
};
