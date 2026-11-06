"""Real TCP/process-death regression; identity/platform boundaries are fixtures."""
import asyncio
import json
import socket
import sys
import time

import uvicorn
from websockets.asyncio.client import connect

from meeting_ms.config import get_settings
from meeting_ms.infrastructure import room_presence
from meeting_ms.main import app
from meeting_ms.tests.test_meeting_im_chat import platform  # noqa: F401 -- shared explicit IM fixture
from meeting_ms.tests.test_rooms import ALICE, BOB, room_with_member


async def test_process_kill_reaches_live_observer_in_under_five_seconds(client, monkeypatch, platform):
    room, member, _ = await room_with_member(client)
    settings = get_settings()
    # Production defaults, not artificially shortened timer values.
    monkeypatch.setattr(settings, "room_disconnect_grace_seconds", 3)
    monkeypatch.setattr(settings, "room_sweep_interval_seconds", 1)
    listener = socket.socket()
    listener.bind(("127.0.0.1", 0))
    port = listener.getsockname()[1]
    server = uvicorn.Server(uvicorn.Config(app, lifespan="off", log_level="error"))
    serving = asyncio.create_task(server.serve(sockets=[listener]))
    sweeping = asyncio.create_task(room_presence.run())
    child = None
    started = time.monotonic()
    try:
        while not server.started:
            if serving.done():
                await serving
            assert time.monotonic() - started < 5
            await asyncio.sleep(0.01)
        url = f"ws://127.0.0.1:{port}/api/v1/rooms/{room['id']}/ws"
        async with connect(url, additional_headers=ALICE()) as observer:
            await observer.recv()
            program = """
import asyncio, json, sys
from websockets.asyncio.client import connect
async def main():
    async with connect(sys.argv[1], additional_headers=json.loads(sys.argv[2])) as ws:
        await ws.recv()
        print('connected', flush=True)
        await asyncio.Event().wait()
asyncio.run(main())
"""
            child = await asyncio.create_subprocess_exec(
                sys.executable, "-c", program, url, json.dumps(BOB()),
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            assert (await asyncio.wait_for(child.stdout.readline(), 5)).strip() == b"connected"
            killed = time.monotonic()
            child.kill()  # No REST leave, no WS close handshake, no app cleanup.
            await child.wait()
            while True:
                event = json.loads(await asyncio.wait_for(observer.recv(), 5))
                if event["type"] == "room_state" and all(
                    p["id"] != member["id"] for p in event["data"]["room"]["participants"]
                ):
                    break
            elapsed = time.monotonic() - killed
            assert 3 <= elapsed < 5
            print(json.dumps({"operation": "kill-websocket-client-process", "expected": "observer removes member in 3–5 seconds",
                              "actualSeconds": round(elapsed, 3), "pass": True, "screenshot": None}))
    finally:
        if child and child.returncode is None:
            child.kill()
            await child.wait()
        sweeping.cancel()
        await asyncio.gather(sweeping, return_exceptions=True)
        server.should_exit = True
        await asyncio.wait_for(serving, 5)
        listener.close()
