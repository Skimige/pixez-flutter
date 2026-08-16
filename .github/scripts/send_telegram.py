"""Send build artifacts to Telegram over MTProto.

The HTTP Bot API caps bot uploads at 50 MiB, which the universal APK sits just
under and will eventually exceed. That limit belongs to the HTTP layer, not to
the bot identity: logging the same bot token in over MTProto raises the ceiling
to 2 GB while keeping the bot's permissions, so no account-level credential ends
up in CI.

cryptg is installed alongside telethon and picked up automatically. Without it
telethon falls back to a pure Python AES implementation and the transfer becomes
CPU bound rather than network bound, which is what the first MTProto run showed.

Telethon uploads a single file over one connection, so there is a ceiling here
that cryptg does not lift. Parallel chunked uploads exist as a third party
addition, but they invite FloodWait handling that these file sizes do not
justify.

Delivery is best effort. The APKs are uploaded as workflow artifacts regardless,
so a failure here is reported and does not stop the build.
"""

import asyncio
import os
import sys

from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.tl.types import InputPeerUser

FILES = [
    ("app-universal-release.apk", "Fat APK"),
    ("app-arm64-v8a-release.apk", "arm64-v8a"),
]


async def resolve(client, chat_id):
    """Bots start with an empty session, so the usual entity cache is not there.

    get_input_entity works when the peer is already known to the account; for a
    private chat a bot may use access_hash 0 for a user that has started it,
    which is the case that matters here.
    """
    try:
        return await client.get_input_entity(chat_id)
    except (ValueError, TypeError):
        return InputPeerUser(chat_id, 0)


async def main():
    api_id = int(os.environ["TG_API_ID"])
    api_hash = os.environ["TG_API_HASH"]
    bot_token = os.environ["BOT_TOKEN"]
    chat_id = int(os.environ["CHAT_ID"])
    apk_dir = os.environ["APK_DIR"]
    sha = os.environ.get("GITHUB_SHA", "")

    client = TelegramClient(StringSession(), api_id, api_hash)
    await client.start(bot_token=bot_token)

    failed = False
    try:
        peer = await resolve(client, chat_id)
        for name, label in FILES:
            path = os.path.join(apk_dir, name)
            size = os.path.getsize(path)
            try:
                await client.send_file(
                    peer, path, caption=f"[{label}] {sha}", force_document=True
                )
                print(f"sent {name} ({size / 1048576:.1f} MiB)")
            except Exception as exc:
                failed = True
                print(f"::error::failed to send {name}: {exc}")
    finally:
        await client.disconnect()

    # Surfaces in the run without failing the job; the step is continue-on-error.
    if failed:
        sys.exit(1)


asyncio.run(main())
