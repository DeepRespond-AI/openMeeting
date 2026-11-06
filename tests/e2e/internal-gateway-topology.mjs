import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdirSync,writeFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../../',import.meta.url));
const out=process.env.GATEWAY_TEST_OUTPUT||path.join(root,'.artifacts/internal-gateway-routing');
mkdirSync(out,{recursive:true});
const project=process.env.GATEWAY_TEST_PROJECT||'openmeeting-gateway-acceptance';
const result={started:new Date().toISOString(),checks:[],instances:[]};
const env={...process.env,INTERNAL_SERVICE_TOKEN:'compose-check-only',OPENMEETING_ADMIN_PASSWORD:'compose-check-only',POSTGRES_PASSWORD:'gateway-test-db'};
const docker=args=>execFileSync('docker',args,{cwd:path.join(root,'server'),env,encoding:'utf8',windowsHide:true}).trim();
for(const overlays of [[],['docker-compose.dev.yml'],['docker-compose.gpu.yml'],['docker-compose.dev.yml','docker-compose.gpu.yml'],['docker-compose.gateway-test.yml']]){
  const flags=['docker-compose.yml',...overlays].flatMap(file=>['-f',file]);
  const config=JSON.parse(docker(['compose','-p',project,...flags,'config','--format','json']));
  const services=config.services,volumes=[];
  for(const domain of ['user','meeting','stt']){
    const db=services[domain+'-postgres'];assert.ok(db);
    const app=services[domain+'_ms'],network=domain+'-backend';
    assert.equal(config.networks[network].internal,true);
    assert.deepEqual(Object.keys(app.networks),[network]);
    const dbNetworks=overlays.includes('docker-compose.gateway-test.yml')?[network,domain+'-test-access']:[network];
    assert.deepEqual(Object.keys(db.networks).sort(),dbNetworks.sort());
    if(overlays.includes('docker-compose.gateway-test.yml')){
      assert.equal(db.ports[0].host_ip,'127.0.0.1');
      assert.equal(config.networks[domain+'-test-access'].internal||false,false);
    }
    assert.equal(app.environment.OPENMEETING_EGRESS_PROXY_URL,'http://gateway_ms:39111');
    assert.ok(app.cap_drop.includes('NET_ADMIN')&&app.cap_drop.includes('NET_RAW'));
    if(overlays.includes('docker-compose.dev.yml')){
      assert.ok(app.volumes.some(x=>x.target==='/srv/service_net'));
      assert.ok(app.command.includes('/srv/service_net'));
    }
    assert.equal(db.environment.POSTGRES_DB,'openmeeting_'+domain);
    const mount=db.volumes.find(x=>x.target==='/var/lib/postgresql/data');assert.ok(mount);volumes.push(mount.source);
    assert.ok(services[domain+'_ms'].environment.OPENMEETING_DATABASE_URL.includes('@'+domain+'-postgres:5432/openmeeting_'+domain));
    assert.ok(services[domain+'_ms'].depends_on[domain+'-postgres']);
    assert.equal(db.ports?.length||0,overlays.includes('docker-compose.gateway-test.yml')?1:0);
  }
  assert.equal(new Set(volumes).size,3);
  assert.equal(config.networks.edge.internal||false,false);
  assert.equal(services.gateway_ms.environment.OPENMEETING_EGRESS_ENABLED,'true');
  assert.deepEqual(Object.keys(services.gateway_ms.networks).sort(),['edge','meeting-backend','stt-backend','user-backend']);
  assert.ok(!services.gateway_ms.ports.some(x=>x.target===39111));
  assert.ok(services.gateway_ms.environment.OPENMEETING_DATABASE_URL.includes('@user-postgres:5432/openmeeting_user'));
  for(const domain of ['user','meeting']){
    const settings=services[domain+'_ms'].environment;
    assert.equal(settings.OPENMEETING_GATEWAY_MS_URL,'http://gateway_ms:39110');
    for(const key of ['OPENMEETING_USER_MS_URL','OPENMEETING_MEETING_MS_URL','OPENMEETING_STT_MS_URL'])assert.equal(settings[key],undefined);
  }
  const visiting=new Set(),done=new Set();
  function visit(name){assert.ok(!visiting.has(name),'Compose startup dependency cycle');if(done.has(name))return;visiting.add(name);for(const child of Object.keys(services[name].depends_on||{}))visit(child);visiting.delete(name);done.add(name);}
  for(const name of Object.keys(services))visit(name);
  result.checks.push({operation:'Compose '+(overlays.join(' + ')||'base'),expected:'三容器/三卷/各自内部网络/仅网关出站/共享模块热重载/无启动环',actual:'全部断言通过',pass:true});
}
if(process.argv.includes('--inspect')){
  for(const domain of ['user','meeting','stt']){
    const name=project+'-'+domain+'-postgres-1';
    const info=JSON.parse(docker(['inspect',name]))[0];
    assert.equal(info.State.Running,true);
    const volume=info.Mounts.find(x=>x.Destination==='/var/lib/postgresql/data').Name;
    const cluster=docker(['exec',name,'psql','-U','openmeeting','-d','openmeeting_'+domain,'-tAc','SELECT system_identifier FROM pg_control_system()']);
    const databases=docker(['exec',name,'psql','-U','openmeeting','-d','openmeeting_'+domain,'-tAc',"SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname"]).split('\n');
    assert.ok(databases.includes('openmeeting_'+domain));
    for(const other of ['user','meeting','stt'].filter(x=>x!==domain))assert.ok(!databases.includes('openmeeting_'+other));
    result.instances.push({container:name,volume,cluster,databases,pass:true});
  }
  assert.equal(new Set(result.instances.map(x=>x.cluster)).size,3);
  assert.equal(new Set(result.instances.map(x=>x.volume)).size,3);
}
writeFileSync(path.join(out,'topology.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
