"""在专用空测试库验证旧 PCM 清理迁移；不连接业务数据库。"""
import asyncio
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "server"))
from alembic import command
from alembic.config import Config
from sqlalchemy import text
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import create_async_engine

url = os.environ["PCM_MIGRATION_DATABASE_URL"]
parsed = make_url(url)
assert parsed.database == "pcm_migration_test" and parsed.host in {"127.0.0.1", "localhost"}, "只允许本机专用迁移测试库"
out = ROOT / ".artifacts/pcm-object-storage"
out.mkdir(parents=True, exist_ok=True)
checks = []


def result(operation, expected, actual):
    row = dict(operation=operation, expected=expected, actual=actual, pass_=True)
    checks.append(row)
    print(json.dumps(row, ensure_ascii=False))


def migrate(revision):
    cfg = Config(str(ROOT / "server/meeting_ms/alembic.ini"))
    cfg.set_main_option("script_location", str(ROOT / "server/meeting_ms/migrations"))
    cfg.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    cfg.attributes["configure_logger"] = False
    command.upgrade(cfg, revision)


async def seed():
    engine = create_async_engine(url)
    try:
        async with engine.begin() as conn:
            await conn.execute(text("""INSERT INTO meetings (id,user_id,title,audio_storage,audio_path)
                VALUES ('migration-meeting','test-user','retained meeting','minio','retained/audio.wav')"""))
            await conn.execute(text("""INSERT INTO transcripts (id,meeting_id,transcript,timestamp,seq)
                VALUES ('migration-transcript','migration-meeting','retained transcript','2026-11-03',0)"""))
            await conn.execute(text("""INSERT INTO summary_processes (meeting_id,status,created_at,updated_at,result)
                VALUES ('migration-meeting','completed',now(),now(),'retained summary')"""))
            await conn.execute(text("""INSERT INTO live_rooms (id,code,title,status,host_participant_id,host_user_id,meeting_id)
                VALUES ('migration-room','123456','old room','ended','test-participant','test-user','migration-meeting')"""))
            await conn.execute(text("""INSERT INTO room_recording_chunks
                (id,room_id,chunk_id,participant_id,speaker_name,start_time,pcm,recording_epoch)
                VALUES ('old-chunk','migration-room','chunk','test-participant','test',0,decode('01000100','hex'),1)"""))
            for job_id, kind, status in [('old-running', 'room_recording', 'running'),
                                         ('old-completed', 'room_recording', 'completed'),
                                         ('other-job', 'retranscribe', 'queued')]:
                await conn.execute(text("""INSERT INTO jobs (id,user_id,kind,status,meeting_id,params)
                    VALUES (:id,'test-user',:kind,:status,'migration-meeting','{"room_id":"migration-room"}')"""),
                    dict(id=job_id, kind=kind, status=status))
    finally:
        await engine.dispose()


async def verify():
    engine = create_async_engine(url)
    try:
        async with engine.connect() as conn:
            assert await conn.scalar(text("SELECT count(*) FROM room_recording_chunks")) == 0
            cols = set(await conn.scalars(text("SELECT column_name FROM information_schema.columns WHERE table_name='room_recording_chunks'")))
            assert 'pcm' not in cols and {'storage', 'storage_key', 'size', 'sha256', 'purged_at'} <= cols
            result('旧分片与旧字段清理', '旧分片0条，pcm字段不存在，对象索引字段存在', '符合预期')
            assert await conn.scalar(text("SELECT audio_path FROM meetings WHERE id='migration-meeting'")) == 'retained/audio.wav'
            assert await conn.scalar(text("SELECT transcript FROM transcripts WHERE id='migration-transcript'")) == 'retained transcript'
            assert await conn.scalar(text("SELECT result FROM summary_processes WHERE meeting_id='migration-meeting'")) == 'retained summary'
            result('完整录音索引、转写、纪要', '全部保留', '全部保留')
            jobs = dict((await conn.execute(text("SELECT id,status FROM jobs"))).all())
            assert jobs == {'old-running': 'failed', 'old-completed': 'completed', 'other-job': 'queued'}
            result('旧任务状态', '旧分片处理任务标记失败；完成任务和其他类型任务不变', jobs)
    finally:
        await engine.dispose()


async def verify_repeated_upgrade(prepare=False):
    engine = create_async_engine(url)
    try:
        async with engine.begin() as conn:
            if prepare:
                await conn.execute(text("""INSERT INTO room_recording_chunks
                    (id,room_id,chunk_id,participant_id,speaker_name,start_time,recording_epoch,storage,storage_key,size,sha256)
                    VALUES ('new-chunk','migration-room','new-chunk','test-participant','test',0,1,'minio','new/chunk.pcm',4,repeat('0',64))"""))
            else:
                assert await conn.scalar(text("SELECT count(*) FROM room_recording_chunks WHERE id='new-chunk'")) == 1
    finally:
        await engine.dispose()


try:
    migrate('e37b21e9f152')
    asyncio.run(seed())
    result('旧版测试数据准备', '旧数据库结构含PCM分片、完整录音、文字记录和任务', '已准备')
    migrate('head')
    asyncio.run(verify())
    asyncio.run(verify_repeated_upgrade(prepare=True))
    migrate('head')
    asyncio.run(verify_repeated_upgrade())
    result('重复启动升级', '已是最新版本，重复升级不重复清理新数据', '升级成功，无新迁移执行')
except Exception as exc:
    checks.append(dict(operation='迁移执行', expected='所有检查通过', actual=str(exc), pass_=False))
    raise
finally:
    (out / 'migration-results.json').write_text(json.dumps(checks, ensure_ascii=False, indent=2), encoding='utf-8')
