# BLIP

**Talk. Then vanish.**

🌐 [한국어](docs/README.ko.md) | [English](#) | [日本語](docs/README.ja.md) | [中文](docs/README.zh.md) | [Español](docs/README.es.md) | [Français](docs/README.fr.md)

---

BLIP is an ephemeral chat service that leaves no trace.
No accounts. No history. No profiles. Start with a single link, and when it's over, everything disappears.

> "This conversation doesn't need to be saved." — Built for exactly those moments.

---

## Why BLIP?

Every messenger today keeps too much. Accounts, friend lists, chat logs, notifications...
But most conversations in life are just **quick talks that don't need to last**.

| Traditional Messengers | BLIP |
|---|---|
| Account required | No accounts |
| Chat history stored forever | Zero history — unrecoverable |
| Need to add friends | Join instantly via link |
| Data stored on servers | No server storage, E2E encrypted |

## Core Concept

- **Zero setup** — Start instantly with a single link
- **Zero persistence** — Unrecoverable after it ends
- **Zero identity** — No accounts, friends, or profiles
- **100% consent-based** — Exists only while all parties agree
- **Auto-shred** — Only the last few messages remain visible; older ones are destroyed in real time
- **Capture guard** — Screenshot and screen-recording attempts are detected and messages are blurred instantly

## How It Works

```
1. Create a room  →  One button press
2. Share the link  →  Send it to anyone
3. Chat            →  Real-time E2E encrypted messaging
4. Done            →  All data instantly destroyed
```

## Use Cases

- "Quick chat, then blow up the room"
- "Strategy meeting, then erase all traces"
- "One link, instant gathering"
- Game party coordination, event staff comms, one-time sensitive conversations

## Philosophy

BLIP is not a messenger.
It's a **disposable communication tool**.

It doesn't exist to keep people engaged.
It exists to remove friction, talk, and disappear.

### Non-goals

This service intentionally does **NOT** do the following:

- ~~Friend requests~~
- ~~Chat history~~
- ~~User profiles~~
- ~~Conversation archives~~
- ~~Social features~~

> We never sacrifice philosophy for convenience.

## Tech Stack

- WebSocket-based real-time communication
- End-to-End Encryption (E2E — Curve25519 ECDH + XSalsa20-Poly1305)
- Server acts only as a relay
- On room close: unrecoverable on both server and client
- Auto-shred: messages beyond the visible window are destroyed with blob URLs released
- Capture protection: visibility change, keyboard shortcut, and context-menu detection

## Support

If you like this project, buy me a coffee!

<a href="https://buymeacoffee.com/ryokai" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

## License

MIT
