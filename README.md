# BLIP

**Talk. Then vanish.**

🌐 [한국어](docs/README.ko.md) | [English](#) | [日本語](docs/README.ja.md) | [中文](docs/README.zh.md) | [Español](docs/README.es.md) | [Français](docs/README.fr.md)

---

BLIP is an ephemeral chat service that leaves no trace.
No accounts. No history. No profiles. Start with a single link, and when it's over, everything disappears.

> "This conversation doesn't need to be saved." — Built for exactly those moments.

---

📋 **[Changelog](CHANGELOG.md)** — Full version history

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

## Group Chat ✨ NEW

BLIP now supports **ephemeral group chat** — same philosophy, multiple people.

```
1. Create a group room  →  Set a title, get a link
2. Share the link       →  Anyone with the password can join
3. Chat together        →  Real-time E2E encrypted group messaging
4. Done                 →  Room vanishes when everyone leaves or admin destroys it
```

### Admin Controls
- 👢 **Kick** — Remove a participant instantly
- 🚫 **Ban** — Block re-entry
- 🔒 **Lock** — Prevent new joins
- 💣 **Destroy** — Nuke the room immediately

### How It Stays Ephemeral
- Messages are **never stored** — memory only, same as 1:1
- Room auto-deletes when the last person leaves
- Admin can destroy the room at any time
- No chat history, no logs, no traces

## File Transfer ✨ NEW

Send **any file** — PDFs, ZIPs, documents, audio, anything — via encrypted P2P.

- 📎 All file types supported (200MB max)
- 🔐 Same E2E encryption as messages (NaCl + SHA-256 checksum)
- 🚀 P2P transfer — files never touch our servers
- 📊 Real-time transfer progress
- ⬇️ Explicit download button — nothing auto-saves

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

## Security Architecture

> **Zero-Knowledge by Design** — We can't read your messages. We can't store them. We can't hand them over. Because we never have them.

```
┌─────────────┐                                    ┌─────────────┐
│   User A    │                                    │   User B    │
│             │                                    │             │
│  plaintext  │                                    │  plaintext  │
│     ↓       │                                    │     ↑       │
│  encrypt()  │    ┌──────────────────────┐        │  decrypt()  │
│     ↓       │───→│   Server (Relay)     │───────→│     ↑       │
│ ciphertext  │    │                      │        │ ciphertext  │
│             │    │  • No DB for msgs    │        │             │
│  Curve25519 │    │  • No logs           │        │  Curve25519 │
│  ECDH keys  │    │  • RAM only          │        │  ECDH keys  │
│             │    │  • Broadcast relay   │        │             │
└─────────────┘    └──────────────────────┘        └─────────────┘
                              │
                    Room close / disconnect
                              ↓
                   ┌─────────────────────┐
                   │  All state erased   │
                   │  Nothing to recover │
                   └─────────────────────┘
```

### Why Messages Can Never Be Stored

| Layer | Protection | Verifiable in Code |
|-------|-----------|-------------------|
| **Database** | No `messages` table exists | [`001_rooms.sql`](web/supabase/001_rooms.sql) — only `rooms` metadata |
| **Supabase Client** | Broadcast-only mode, DB features explicitly disabled | [`client.ts`](web/src/lib/supabase/client.ts) |
| **Chat Hook** | `channel.send()` only — zero DB INSERT calls | [`useChat.ts`](web/src/hooks/useChat.ts) |
| **API Routes** | No message storage/retrieval endpoints exist | [`/api/room/*`](web/src/app/api/room/) |
| **Memory** | Max 4 messages in RAM, older ones auto-shredded | `limitMessages()` in useChat.ts |
| **Encryption** | E2EE with ephemeral ECDH keys — server sees only ciphertext | [`lib/crypto/`](web/src/lib/crypto/) |
| **Room Lifecycle** | On disconnect: keys destroyed, state wiped, room deleted | `user_left` handler in useChat.ts |

> For full security details, see [SECURITY.md](SECURITY.md).

## Tech Stack

- WebSocket-based real-time communication
- End-to-End Encryption (E2E — Curve25519 ECDH + XSalsa20-Poly1305)
- Server acts only as a relay
- On room close: unrecoverable on both server and client
- Auto-shred: messages beyond the visible window are destroyed with blob URLs released
- Capture protection: visibility change, keyboard shortcut, and context-menu detection

## BLIP me — Disposable Contact Link

Share a single link on your profile. When someone clicks it, an instant 1:1 encrypted chat starts — no accounts, no friend requests.

- **Your own link** — Create a unique URL (e.g. `blip.me/yourname`)
- **Real-time alert** — Get notified the moment someone connects
- **Link control** — Change or delete your URL anytime
- **No account needed** — Device-based token proves ownership
- Visit `/blipme` on web, or tap the **BLIP me** tab on mobile

## My Chat Rooms

Your recently created or joined rooms are saved locally — no server storage.

- **Auto-save**: rooms are stored in localStorage (web) or SecureStorage (mobile) when created or joined
- **One-click rejoin**: saved password lets you re-enter rooms without typing it again
- **Admin persistence**: group chat admin tokens are stored so you keep admin privileges
- **Unified list**: both 1:1 and group chats in one place
- Visit `/my-rooms` on web, or tap the **Chat** tab on mobile

> Passwords and admin tokens never leave your device. Clearing browser data removes them permanently.

## Embed

Add BLIP chat to any website with a single iframe:

```html
<iframe
  src="https://blip-blip.vercel.app/embed"
  width="400"
  height="600"
  style="border: none;"
  allow="clipboard-write"
></iframe>
```

Listen for events from the embed:

```js
window.addEventListener('message', (e) => {
  if (e.origin !== 'https://blip-blip.vercel.app') return;

  switch (e.data.type) {
    case 'blip:ready':         // Widget loaded
    case 'blip:room-created':  // Room created (roomId, shareUrl)
    case 'blip:room-joined':   // Entered chat
    case 'blip:room-destroyed': // Room destroyed
  }
});
```

- Lightweight layout — no ads, no navigation
- Full E2E encryption maintained
- Share links stay within the embed context
- See [embed-example.html](web/public/embed-example.html) for a full demo

## Download

<a href="https://play.google.com/store/apps/details?id=com.bakkum.blip" target="_blank"><img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" width="200"></a>

## Support

If you like this project, buy me a coffee!

<a href="https://buymeacoffee.com/ryokai" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

## License

MIT
