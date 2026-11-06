import {installMediaProbe} from './media-input.mjs';

/** Optional synthetic capture in dedicated native clients; IM/RTC stays real. */
export async function prepareNativeInput(context) {
  if(process.env.MEETING_READY_SYNTHETIC!=='1')return;
  await context.addInitScript(installMediaProbe,{synthetic:true});
  for(const page of context.pages()) {
    try {
      if(await page.evaluate(()=>!!navigator.mediaDevices&&!window.__meetingE2E))await page.evaluate(installMediaProbe,{synthetic:true});
    } catch(error) {
      // The context init script already covers the document being navigated to.
      if(!String(error).includes('Execution context was destroyed'))throw error;
    }
  }
}
