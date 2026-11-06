import assert from 'node:assert/strict';
import fs from 'node:fs';

export async function inlineMediaFlow({page,step,sdk,panel,input,dialog,article,videoFile}) {
  const imageUrl='https://im.fixture/file/image',videoUrl='https://im.fixture/file/video';
  const movie='data:video/mp4;base64,'+fs.readFileSync(videoFile).toString('base64');
  const image=(name='产品设计图-长文件名用于验证省略与缩略图布局.png',type='image',size=100)=>({sender:'member-1',type,body:{name,url:imageUrl,size}});
  const film=()=>({sender:'member-1',type:'file',body:{name:'会议录像.mp4',url:videoUrl,size:100}});
  const img=()=>article('产品设计图').locator('img');
  const vid=()=>article('会议录像.mp4').locator('video');
  const clear=async()=>{await sdk({messages:[]});await page.getByTestId('im-meeting-message').waitFor({state:'detached'});};
  const decoded=async locator=>{await locator.waitFor();await locator.evaluate(e=>e.decode());assert.equal(await locator.evaluate(e=>e.naturalWidth),640);};
  const close=async()=>{await dialog().getByRole('button',{name:'关闭',exact:true}).click();await dialog().waitFor({state:'hidden'});};
  const show=async()=>{await clear();await sdk({previewSrc:'',previewDenied:false,pausePreview:false,previewSources:{[videoUrl]:movie},messages:[image(),film()]});await decoded(img());await vid().waitFor();await page.waitForFunction(()=>[...document.querySelectorAll('[data-testid=im-meeting-message] video')].some(v=>v.videoWidth===640&&v.readyState>=2));};
  await step('聊天成功冒烟','会议聊天可发送普通消息',async()=>{await input().fill('确认收到会议资料');await input().press('Enter');await article('确认收到会议资料').waitFor();},'文字消息成功');
  await step('图片和视频直接展示','图片自动解码，视频显示首帧，无重复预览文字且不自动播放',async()=>{
    await show();assert.equal(await article('产品设计图').getByRole('button',{name:'预览 / 播放',exact:true}).count(),0);
    assert.equal(await article('会议录像.mp4').getByRole('button',{name:'预览 / 播放',exact:true}).count(),0);
    assert.equal(await vid().evaluate(v=>v.paused),true);return {image:await img().evaluate(e=>({width:e.naturalWidth,height:e.naturalHeight})),video:await vid().evaluate(v=>({width:v.videoWidth,height:v.videoHeight,paused:v.paused}))};
  },'图片与视频直接展示');
  await step('图片点击放大','图片可放大并关闭，关闭不重复下载行内图片',async()=>{
    const before=await page.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='download').length);
    await article('产品设计图').getByRole('button',{name:/^查看图片/}).click();await dialog().waitFor();await decoded(dialog().locator('img'));
    await close();await decoded(img());assert.equal(await page.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='download').length),before);
    await article('产品设计图').getByRole('button',{name:/^查看图片/}).click();
  },'图片放大');await close();
  await step('聊天小窗点击播放','视频点击后播放时间推进，原生控制条可见',async()=>{
    await article('会议录像.mp4').getByRole('button',{name:/^播放视频/}).click();
    await vid().evaluate(v=>{v.muted=true;void v.play().catch(()=>{});});await page.waitForFunction(()=>document.querySelector('[data-testid=im-meeting-message] video')?.currentTime>.35);
    assert.equal(await vid().evaluate(v=>v.controls),true);return await vid().evaluate(v=>({currentTime:v.currentTime,paused:v.paused}));
  },'视频小窗播放');
  await step('视频放大关闭','放大保留播放位置并暂停原播放器，关闭停止大播放器',async()=>{
    const time=await vid().evaluate(v=>v.currentTime);await article('会议录像.mp4').getByRole('button',{name:'放大视频',exact:true}).click();
    await dialog().waitFor();const big=dialog().locator('video');await big.waitFor();await big.evaluate(v=>new Promise(resolve=>{if(v.readyState>=1)resolve();else v.addEventListener('loadedmetadata',resolve,{once:true});}));
    assert.equal(await vid().evaluate(v=>v.paused),true);assert.ok(Math.abs(await big.evaluate(v=>v.currentTime)-time)<.6);
    await big.evaluate(v=>{window.__expandedVideo=v;v.muted=true;void v.play().catch(()=>{});});
  },'视频放大播放');await close();assert.equal(await page.evaluate(()=>window.__expandedVideo.paused),true);
  await step('下载保持独立','下载图标仍可调用下载，原有行内图片保留',async()=>{
    await article('产品设计图').getByRole('button',{name:'下载',exact:true}).click();await page.waitForFunction(()=>window.__layoutIm.chatCalls.some(c=>c.operation==='download'&&!c.saveTo));await decoded(img());
  });
  await step('文件型图片兼容','按扩展名识别file图片，直接展示',async()=>{await clear();await sdk({messages:[image('文件上传的图片.png','file')]});await decoded(article('文件上传的图片.png').locator('img'));},'文件型图片');
  await step('媒体加载和取消','加载50%可见，取消终止下载并显示重试入口',async()=>{
    await clear();await sdk({pausePreview:true,messages:[image('加载中的图片.png')]});await article('加载中的图片.png').getByRole('status').filter({hasText:'50%'}).waitFor();
  },'加载进度');
  await article('加载中的图片.png').getByRole('button',{name:'取消',exact:true}).click();
  await step('取消后重试','取消请求已有证据，解除夹具后重试可解码',async()=>{
    await article('加载中的图片.png').getByRole('button',{name:'重新加载',exact:true}).waitFor();assert.ok(await page.evaluate(()=>window.__layoutIm.chatCalls.some(c=>c.operation==='downloadCancelled')));
    await sdk({pausePreview:false});await article('加载中的图片.png').getByRole('button',{name:'重新加载',exact:true}).click();await decoded(article('加载中的图片.png').locator('img'));
  },'取消后恢复');
  await step('权限失败原位展示','鉴权拒绝可重试，不破坏聊天输入',async()=>{await clear();await sdk({previewDenied:true,messages:[image('无权限图片.png')]});await article('无权限图片.png').getByRole('alert').filter({hasText:'权限不足'}).waitFor();assert.equal(await input().isEnabled(),true);},'权限错误');
  await step('权限恢复重试','恢复后显式重试成功',async()=>{await sdk({previewDenied:false});await article('无权限图片.png').getByRole('button',{name:'重新加载',exact:true}).click();await decoded(article('无权限图片.png').locator('img'));},'错误恢复');
  await step('损坏图片失败','解码错误可见，不自动无限下载',async()=>{await clear();await sdk({previewSources:{[imageUrl]:'data:image/png;base64,YmFk'},messages:[image('损坏图片.png')]});await article('损坏图片.png').getByRole('alert').filter({hasText:'无法打开'}).waitFor();const before=await page.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='download').length);await page.waitForTimeout(400);assert.equal(await page.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='download').length),before);},'损坏图片');
  await step('大文件限制','超过30MB不自动下载，仍可下载到本地',async()=>{await clear();const before=await page.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='download').length);await sdk({previewSources:{},messages:[image('大图片.png','image',31*1024*1024)]});await article('大图片.png').getByRole('alert').filter({hasText:'30 MB'}).waitFor();assert.equal(await page.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='download').length),before);assert.equal(await article('大图片.png').getByRole('button',{name:'下载',exact:true}).isEnabled(),true);},'大文件限制');
  await step('普通文件成功冒烟','普通文件保留下载，不误作媒体',async()=>{await clear();await sdk({messages:[{sender:'member-1',type:'file',body:{name:'会议材料.zip',url:'https://im.fixture/file/zip',size:1024}}]});await article('会议材料.zip').getByRole('button',{name:'下载',exact:true}).click();},'普通文件');
  await step('文本预览及关闭','文本不执行HTML，长文本可以滚动，关闭释放缓存',async()=>{
    await clear();await sdk({messages:[{sender:'member-1',type:'file',body:{name:'会议说明.txt',url:'https://im.fixture/file/text',size:100}}]});await article('会议说明.txt').getByRole('button',{name:'预览 / 播放',exact:true}).click();await dialog().locator('pre').filter({hasText:'<script>'}).waitFor();await dialog().locator('pre').evaluate(e=>{e.scrollTop=e.scrollHeight;});assert.equal(await dialog().locator('script').count(),0);
  },'文本滚动');await close();
  await step('关闭聊天释放资源','播放中的视频停止，行内缓存释放；重新打开正常加载',async()=>{
    await show();await article('会议录像.mp4').getByRole('button',{name:/^播放视频/}).click();await vid().evaluate(v=>{window.__inlineVideo=v;});
    const before=await page.evaluate(()=>window.__layoutRemovedCache.length);
    await panel().getByRole('button',{name:'关闭',exact:true}).click();await panel().waitFor({state:'hidden'});
    await page.waitForFunction(n=>window.__layoutRemovedCache.length>=n+2,before);assert.equal(await page.evaluate(()=>window.__inlineVideo.paused),true);
    await page.getByRole('button',{name:'聊天',exact:true}).click();await decoded(img());
  },'关闭再打开聊天');
  await step('播放中消息移除清理','放大播放器卸载时停止播放、清空src并释放缓存',async()=>{
    await article('会议录像.mp4').getByRole('button',{name:'放大视频',exact:true}).click();
    await dialog().locator('video').evaluate(v=>{window.__removedVideo=v;v.muted=true;void v.play().catch(()=>{});});
    await page.waitForFunction(()=>window.__removedVideo.currentTime>.1);
    await clear();await dialog().waitFor({state:'hidden'});
    assert.equal(await page.evaluate(()=>window.__removedVideo.paused),true);
    assert.equal(await page.evaluate(()=>window.__removedVideo.getAttribute('src')),null);
  });
}
