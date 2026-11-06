"""Screen sharing and recording must coexist after their branches are merged."""

from meeting_ms.tests.test_room_recording import chunk, wait_job, start_recording
from meeting_ms.tests.test_rooms import ALICE, BOB, join, make_room


async def test_screen_owner_can_be_recorded_and_room_end_finalizes_audio(client, fake_stt):
    room = await make_room(client)
    await start_recording(client, room)
    member = (await join(client, room["code"], BOB())).json()["self"]
    screen_url = f"/api/v1/rooms/{room['id']}/screen-share"
    config = await client.get(screen_url, headers=BOB())
    assert config.status_code == 200
    assert config.headers["cache-control"] == "no-store"
    started = await client.post(f"{screen_url}/start", headers=BOB())
    assert started.status_code == 200
    session_id = started.json()["sessionId"]
    snapshot = (await client.get(f"/api/v1/rooms/{room['id']}", headers=ALICE())).json()
    owner = next(p for p in snapshot["participants"] if p["id"] == member["id"])
    assert owner["screenSharing"] is True and owner["screenShareId"] == session_id

    uploaded = await client.post(
        f"/api/v1/rooms/{room['id']}/recording/chunks",
        headers=ALICE(), json=chunk(member["id"]),
    )
    assert uploaded.status_code == 201
    ended = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert ended.status_code == 200
    meeting_id = ended.json()["meetingId"]
    assert ended.json()["jobId"]
    job = await wait_job(client, meeting_id)
    # No LLM provider is configured: retain the audio and attributed transcript.
    assert job["status"] == "failed" and "大模型" in job["error"]
    details = (await client.get(f"/api/v1/meetings/{meeting_id}", headers=ALICE())).json()
    assert details["transcripts"][0]["speaker"] == "1·bob"
    metadata = (await client.get(f"/api/v1/meetings/{meeting_id}/metadata", headers=ALICE())).json()
    assert metadata["has_audio"] is True
    assert (await client.post(f"{screen_url}/start", headers=BOB())).status_code == 404
