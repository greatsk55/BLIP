# Changelog

All notable changes to BLIP are documented here.

📋 Translations: [한국어](docs/CHANGELOG.ko.md) | [日本語](docs/CHANGELOG.ja.md) | [中文](docs/CHANGELOG.zh.md) | [Español](docs/CHANGELOG.es.md) | [Français](docs/CHANGELOG.fr.md)

---

## v1.7.0 — Universal File Transfer

- **Any file type support**: Send PDFs, documents, archives, code files, and more
- **Smart file icons**: Automatic icon selection based on file extension
- **File size validation**: Per-type limits (images 50MB, videos 100MB, files 200MB)
- **Download button**: One-click download for received files
- **Transfer progress**: Real-time progress indicator during file transfer
- **End-to-end encrypted**: All files encrypted with the same E2E encryption as messages

## v1.6.0 — Group Chat

- **Group rooms**: Create group chat rooms with unlimited participants
- **Admin controls**: Room lock, kick, ban, and destroy capabilities
- **Admin token**: Separate admin authentication for room management
- **Participant sidebar**: Real-time participant list with admin indicators
- **Share links**: Generate invite links with optional embedded password
- **24-hour expiry**: Group rooms auto-expire after 24 hours

## v1.5.0 — Embeddable Chat Widget

- **Embed guide**: Step-by-step guide to embed BLIP chat on any website
- **Widget customization**: Configurable appearance and behavior
- **Cross-origin support**: Secure iframe embedding with proper CSP headers

## v1.4.0 — Community Invite Code System

- **Invite codes**: Generate and share invite codes for communities
- **Community board**: Public board for community discussions
- **Rate limiting**: Protection against spam and abuse

## v1.3.0 — Mobile App & Stability

- **Mobile optimization**: Full responsive design and PWA support
- **Visual viewport handling**: Proper keyboard behavior on mobile devices
- **Performance improvements**: Optimized rendering and memory usage

## v1.2.0 — Encrypted Media Transfer

- **Image transfer**: Send and receive images with E2E encryption
- **Video transfer**: Support for encrypted video sharing with thumbnails
- **Chunk-based transfer**: Large files split into chunks for reliable delivery
- **Checksum verification**: SHA-256 integrity verification for all transfers

## v1.1.0 — Instant Room Destruction & Notifications

- **Room destruction**: Instantly destroy chat rooms when done
- **Browser notifications**: Get notified when messages arrive
- **Screen capture detection**: Alert when screen capture is detected
- **Leave confirmation**: Confirm before leaving a chat room

## v1.0.0 — Initial Release

- **End-to-end encryption**: X25519 key exchange + XSalsa20-Poly1305 encryption
- **Ephemeral rooms**: No message storage, rooms expire automatically
- **Password-based access**: Secure room access with generated passwords
- **Real-time messaging**: WebSocket-based instant messaging via Supabase Realtime
- **Zero-knowledge architecture**: Server never sees plaintext messages
- **Multi-language support**: English, Korean, Japanese, Chinese, Spanish, French
