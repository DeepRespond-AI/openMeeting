"""Move meeting audio that still lives on local disk into Aliyun OSS.

    uv run python -m app.scripts.migrate_audio_to_oss --dry-run
    uv run python -m app.scripts.migrate_audio_to_oss

Uses the same OSS config as the server (admin web or OPENMEETING_OSS_* env vars). Safe to re-run:
each meeting is committed on its own, and a failure is reported and skipped.
"""
from __future__ import annotations

import argparse
import asyncio
import logging
import shutil
import sys
from pathlib import Path

from sqlalchemy import select

from meeting_ms.config import get_settings
from meeting_ms.db.models import Meeting
from meeting_ms.db.session import dispose_engine, init_engine, run_migrations, session_factory
from meeting_ms.storage import oss
from meeting_ms.storage.audio import LOCAL, meeting_audio_dir, upload_to_oss

logger = logging.getLogger("migrate_audio_to_oss")


async def migrate(dry_run: bool) -> int:
    settings = get_settings()
    init_engine(settings.database_url)
    try:
        await run_migrations(settings.database_url)
        store = await oss.get_audio_store()
        if store is None:
            logger.error("OSS 未配置（在管理后台「存储」页面或 OPENMEETING_OSS_* 环境变量中配置）")
            return 2
        async with session_factory()() as session:
            ids = (
                await session.execute(
                    select(Meeting.id)
                    .where(Meeting.audio_storage == LOCAL, Meeting.audio_path.is_not(None))
                    .order_by(Meeting.created_at)
                )
            ).scalars().all()
        logger.info("%d meeting(s) with local audio; target %s://%s/%s", len(ids), store.backend, store.cfg.bucket, store.cfg.prefix)

        moved = missing = failed = 0
        for meeting_id in ids:
            async with session_factory()() as session:
                meeting = await session.get(Meeting, meeting_id)
                if meeting is None or meeting.audio_storage != LOCAL or not meeting.audio_path:
                    continue
                path = Path(meeting.audio_path)
                if not path.is_file():
                    logger.warning("[missing] %s %s", meeting.id, path)
                    missing += 1
                    continue
                if dry_run:
                    logger.info("[dry-run] %s %s (%d bytes)", meeting.id, path, path.stat().st_size)
                    moved += 1
                    continue
                try:
                    key = await upload_to_oss(store, meeting, path, path.name)
                    await session.commit()
                except Exception as exc:  # noqa: BLE001
                    await session.rollback()
                    logger.error("[failed] %s %s: %s", meeting.id, path, oss.describe_error(exc))
                    failed += 1
                    continue
                await asyncio.to_thread(shutil.rmtree, meeting_audio_dir(meeting), True)
                path.unlink(missing_ok=True)
                logger.info("[moved] %s -> %s", meeting.id, key)
                moved += 1

        verb = "would move" if dry_run else "moved"
        logger.info("Done: %s %d, missing %d, failed %d", verb, moved, missing, failed)
        return 1 if failed else 0
    finally:
        await dispose_engine()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="only list what would be uploaded")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    logging.getLogger("oss2").setLevel(logging.WARNING)
    sys.exit(asyncio.run(migrate(args.dry_run)))


if __name__ == "__main__":
    main()
