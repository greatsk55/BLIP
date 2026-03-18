# Changelog

All notable changes to BLIP are documented here.

---

## v1.7.0 — March 18, 2026
### Universal File Transfer
- **Any file type** — Send PDFs, ZIPs, documents, audio, or any file via encrypted P2P
- File message bubble with icon, filename, size, and download button
- Transfer progress indicator during send/receive
- 200MB max file size (P2P — no server storage)
- Same E2E encryption as images/videos (NaCl + SHA-256 checksum)
- Available on both web and mobile app

## v1.6.0 — March 18, 2026
### Group Chat
- **Ephemeral group chat** — Create a room, share the link, chat with multiple people
- Room admin controls — kick, ban, lock the room, or destroy it instantly
- Participant list — see who's online in real-time
- E2E encryption with symmetric key (NaCl secretbox) derived from room password
- Auto-destruct — room disappears when the last person leaves or admin destroys it
- Available on both web and mobile app

## v1.5.0 — March 14, 2026
### Embeddable Chat Widget
- Embed BLIP chat into any website via iframe — add encrypted chat with a single HTML snippet
- Lightweight embed layout — no ads, no navigation, just the chat
- postMessage API for parent page communication (room created, joined, destroyed events)
- Shared links in embed mode stay within the embed context
- Full E2E encryption maintained in embedded mode

## v1.4.0 — February 28, 2026
### Community Invite Code System
- Rotatable invite codes for communities — share a link that auto-joins without password
- Invite code rotation in admin panel — invalidate old links while existing members keep access
- Separated invite code (shareable) from encryption key (immutable) for stronger security
- Mobile app deep link support for community invite codes

## v1.3.0 — February 26, 2026
### Mobile App & Stability
- Android mobile app launched (Google Play Store)
- Deep link support — open chat rooms directly from shared links in the app
- One-click entry — include password in link for instant connection
- 60-second reconnection grace period — rooms aren't destroyed immediately on exit
- Community dashboard & video attachments in posts
- 10 language support (+German, Traditional Chinese)

## v1.2.0 — February 15, 2026
### Encrypted Media Transfer
- Image & video transfer via encrypted P2P (WebRTC DataChannel)
- TURN-only relay to prevent IP exposure between peers
- Automatic image compression (max 2048px, JPEG 80%)
- Fullscreen image viewer with pinch-to-zoom
- File integrity verification with SHA-256 checksums

## v1.1.0 — February 10, 2026
### Instant Room Destruction & Notifications
- Rooms destroyed immediately when all participants leave
- Browser push notifications for incoming messages
- Rate limiting for room creation (anti-abuse)
- Private community feature with encrypted posts

## v1.0.0 — February 1, 2026
### Initial Release
- E2EE text chat (Curve25519 ECDH + XSalsa20-Poly1305)
- One-click room creation with shareable links
- Zero account requirement — fully anonymous
- 8 language support (EN, KO, JA, ZH, ZH-TW, ES, FR, DE)
- 100% open source codebase
