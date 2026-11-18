# BLIP release setup

Use a clean checkout. Keep production keys and SDK configuration out of Git.

## Mobile configuration

- `mobile/.env`: `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` only. Never put the Supabase service-role key in the app.
- Firebase project: `blip-e1129`. Restore native SDK config using the authenticated official Firebase CLI:
  - Android app `1:1069876456121:android:749d73075d9afe6ddb8968` → `mobile/android/app/google-services.json`.
  - iOS app `1:1069876456121:ios:4b6ddc461eca33f2db8968` → `mobile/ios/Runner/GoogleService-Info.plist`.
- Run `flutter pub get` before building. Generate translations with `flutter gen-l10n`.
- Run platform builds sequentially within a checkout. Concurrent Flutter builds can rewrite the shared generated plugin registry with conflicting debug/release dependencies.

## Android signing

The existing upload keystore is `/Users/sunggookkim/upload-keystore.jks`. Its working configuration was recovered from an external backup and saved privately at `/Users/sunggookkim/.config/blip/signing/key.properties` (mode 0600). Copy that configuration to `mobile/android/key.properties` on this Mac. Do not commit either file or put passwords in shell commands/logs. The original keystore was preserved; no upload-key reset was performed.

Run `flutter build appbundle --release`. Release tasks fail with an explicit message if the signing configuration is missing. Upload the resulting AAB as an update to `com.bakkum.blip`, never as a new app. Verify that Play accepts the existing upload certificate.

## iOS

Bundle ID `com.bakkum.blip`, team `95ERD9S934`. The project and Pods have a consistent iOS 15 minimum. Use the existing paired iPhone simulator UDID `8862F754-FCC1-417C-8B54-E51090FB0B18` explicitly for simulator builds and execution. Do not erase or clone it. Build the signed archive only after simulator validation. The uploaded build version must match the App Store version being submitted.

## Store declarations and runtime checks

- AdMob/Firebase identifiers, approximate location, app interactions and diagnostics must be disclosed. iOS also uses Apple account ID/email for authentication.
- Optional abuse evidence is sent only after the user selects it. Ordinary 1:1 text remains ephemeral. Moderation reports use the private `abuse-reports` bucket; public bucket configuration fails closed.
- Publish the updated privacy/deletion page before submitting the data-safety change.
- Mainland China sales were excluded by the owner on 2026-11-18. Do not submit fictitious regulatory certificates.
- Advertising and simulated betting with non-cash points are present. The iOS age questionnaire must reflect both. Current computed rating is 18+.
- The iOS review notes must explain native Sign in with Apple and invitation-only room setup. Do not invent a demo username/password or remove authentication to match old metadata.
- Recheck room authentication, invitation links, encrypted messages, safety reports, ending a room, startup without advertising SDK availability and points identity persistence before release.

### Current Mac iOS signing

The App Store profile `BLIP AppStore 2026-11-19` uses the existing BAKKUM distribution certificate and expires on 2027-05-19. The ignored file `mobile/ios/Flutter/Signing.xcconfig` supplies manual signing to the Runner release configuration only. Do not pass a provisioning profile globally to `xcodebuild`: Pods/framework targets do not use app provisioning profiles.

The existing App Store Connect key is at `/Users/sunggookkim/.private_keys/AuthKey_9TA7V35A5U.p8`; access to BLIP was verified. Do not copy its contents into source or logs. Store submission also requires the owner's real review contact details.

### Apple account deletion

The server requires `APPLE_TEAM_ID`, `APPLE_CLIENT_ID` (`com.bakkum.blip`), `APPLE_KEY_ID` and `APPLE_PRIVATE_KEY` for Apple token revocation. Use a Sign in with Apple key configured for BLIP's primary App ID; APNs keys and keys configured for another primary app are not substitutes. A new BLIP key needs the owner's final security confirmation before registration. JWT signatures use raw 64-byte ES256 format, and Apple network calls have a timeout so an outage cannot leave deletion requests hanging.
