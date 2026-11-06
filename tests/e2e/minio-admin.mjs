import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {createRequire} from 'node:module';
import {mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.join(root,'.artifacts/minio-object-storage');
const require=createRequire(path.join(root,'frontend/package.json'));
const {chromium}=require('playwright');
const base=process.env.MINIO_ADMIN_URL||'http://127.0.0.1:39110';
const report={scope:'运行中的真实管理端、网关和 MinIO；错误及加载 UI 为明确的浏览器拦截夹具。连接失败已先由真实错误凭据单独冒烟。',startedAt:new Date().toISOString(),checks:[],screenshots:[],cleanup:[]};
mkdirSync(path.join(out,'screenshots'),{recursive:true});
const backend=JSON.parse(readFileSync(path.join(out,'api-results.json'),'utf8'));
assert(backend.checks.length>=10&&backend.checks.every(r=>r.pass),'先完成真实 API 和失败夹具冒烟');
function row(operation,expected,actual,pass=true){const value={operation,expected,actual,pass,screenshot:null};report.checks.push(value);console.log(JSON.stringify(value));}
let browser,page;
try{
  browser=await chromium.launch({headless:true});
  const context=await browser.newContext({viewport:{width:1440,height:960},locale:'zh-CN'});
  // 密码仅在内存中使用，不记录登录 trace、storageState 或请求头。
  const python=path.join(root,'server/.venv/Scripts/python.exe');
  const password=execFileSync(python,['-X','utf8','-c',"from dotenv import dotenv_values;print(dotenv_values('.env')['OPENMEETING_ADMIN_PASSWORD'])"],{cwd:path.join(root,'server')}).toString('utf8').trim();
  const login=await context.request.post(base+'/admin/api/login',{data:{password}});
  assert.equal(login.status(),200);row('管理端登录现有服务','200；不发送短信、不保存凭据',login.status());
  page=await context.newPage();page.setDefaultTimeout(10000);
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto(base+'/admin/object-storage');
  await page.getByRole('heading',{name:'对象存储',exact:true}).waitFor();
  await page.getByText('MinIO 已配置',{exact:true}).waitFor();
  assert.equal(await page.locator('input:disabled').count()>=6,true);
  assert.equal(await page.getByRole('button',{name:'保存配置',exact:true}).isDisabled(),true);
  row('全局 MinIO 配置','显示 MinIO、参数由 env 锁定、下载地址可见','一致');
  const test=()=>page.getByRole('button',{name:'测试连接',exact:true});
  await test().click();await page.getByText('连接成功，读写正常',{exact:true}).waitFor();
  row('管理端真实连接流程','网关代理 → MinIO 写入/读取/删除成功','连接成功，读写正常');
  const failure={ok:false,error:'测试夹具：MinIO 认证失败，请检查访问密钥'};
  await page.route('**/admin/api/object-storage/test',route=>route.fulfill({status:200,contentType:'application/json',body:JSON.stringify(failure)}));
  await test().click();await page.getByText(failure.error,{exact:true}).waitFor();
  assert.equal(await test().isEnabled(),true);
  row('连接错误展示与重试入口','显示确定性错误，按钮恢复可用','一致');
  await page.unroute('**/admin/api/object-storage/test');
  await test().click();await page.getByText('连接成功，读写正常',{exact:true}).waitFor();
  row('失败后重试真实连接','恢复真实接口后成功','一致');
  await page.goto(base+'/admin/storage');
  await page.getByRole('heading',{name:'音频存储',exact:true}).waitFor();
  await page.getByText('MinIO 中的会议',{exact:true}).waitFor();
  await page.getByText('OSS 中的会议',{exact:true}).waitFor();
  await page.getByText('MinIO 已配置',{exact:true}).waitFor();
  row('录音统计','本地、MinIO、OSS 分组展示','一致');
  assert.deepEqual(errors,[]);row('浏览器运行时异常','0',errors.length);
  // 以上断言通过后，统一重放状态、截图；视觉结论需实际查看后再写入。
  let number=0;
  async function shot(state,viewport){
    await page.evaluate(async()=>Promise.all(document.getAnimations().filter(a=>a.effect?.getTiming().iterations!==Infinity).map(a=>a.finished.catch(()=>{}))));
    const file=`${String(++number).padStart(2,'0')}-${viewport}-${state}.png`;
    await page.screenshot({path:path.join(out,'screenshots',file),fullPage:true});
    report.screenshots.push({path:'screenshots/'+file,state,viewport:page.viewportSize(),inspected:false});
  }
  for(const [name,size] of [['desktop',{width:1440,height:960}],['narrow',{width:390,height:844}]]){
    await page.setViewportSize(size);
    await page.goto(base+'/admin/object-storage');
    await page.getByText('MinIO 已配置',{exact:true}).waitFor();
    if(name==='narrow'){
      const aside=page.locator('.aside');
      if((await aside.boundingBox())?.width>100)await page.locator('.header-left .el-button').first().click();
    }
    await shot('正常及环境变量权限',name);
    await test().click();await page.getByText('连接成功，读写正常',{exact:true}).waitFor();await shot('连接成功',name);
    await page.route('**/admin/api/object-storage/test',route=>route.fulfill({status:200,contentType:'application/json',body:JSON.stringify(failure)}));
    await test().click();await page.getByText(failure.error,{exact:true}).waitFor();await shot('连接错误',name);
    await page.unroute('**/admin/api/object-storage/test');
    let release;
    await page.route('**/admin/api/object-storage',async route=>{const response=await route.fetch();await new Promise(resolve=>release=resolve);await route.fulfill({response});});
    await page.getByRole('button',{name:'刷新',exact:true}).click();
    await page.locator('button.is-loading').first().waitFor();await shot('加载',name);
    assert.equal(typeof release,'function');release();await page.getByRole('button',{name:'刷新',exact:true}).waitFor();
    await page.unroute('**/admin/api/object-storage');
    await page.locator('.main').evaluate(el=>el.scrollTop=el.scrollHeight);await shot('长说明滚动',name);
    await page.goto(base+'/admin/storage');await page.getByText('MinIO 中的会议',{exact:true}).waitFor();await page.getByText('MinIO 已配置',{exact:true}).waitFor();await shot('录音存储统计',name);
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
    row(`${name} 横向溢出检查`,'无溢出','无溢出');
  }
  assert.deepEqual(errors,[]);
}catch(error){row('执行异常','断言通过',String(error.stack||error),false);process.exitCode=1;if(page)await page.screenshot({path:path.join(out,'browser-failure.png'),fullPage:true});}
finally{
  if(browser){await browser.close();report.cleanup.push({service:'headless Chromium',stopped:true});}
  report.finishedAt=new Date().toISOString();
  writeFileSync(path.join(out,'browser-results.json'),JSON.stringify(report,null,2));
}
