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

Google rejected `/Users/sunggookkim/upload-keystore.jks` for BLIP: its SHA-1 starts `A6:22:9C`, while BLIP requires `95:CF:51:71:9D:53:D0:F9:C2:3B:90:E7:27:CC:A0:E7:66:13:ED:67`. Its recovered configuration is retained privately as `~/.config/blip/signing/rejected-home-key.properties`; do not use it for BLIP releases. The original keystore is unchanged.

A BLIP-only replacement key and its private configuration are prepared at `~/.config/blip/signing/blip-upload-20261119.jks` and `pending-key.properties` (mode 0600). Its public certificate is `~/Downloads/BLIP-upload-certificate-20261119.pem` (SHA-1 `50:D3:6E:F4:71:8B:DD:CB:84:BF:EC:93:1C:82:00:E0:28:48:76:4E`). No reset has been submitted. The owner must upload the public certificate and submit the prepared Play Console reset form. Wait for Google to confirm activation before copying the pending configuration to `mobile/android/key.properties` and rebuilding. Never commit signing secrets or print passwords in logs.

Run `flutter build appbundle --release`. Release tasks fail with an explicit message if the signing configuration is missing. Upload the resulting AAB as an update to `com.bakkum.blip`, never as a new app. Verify that Play accepts the registered upload certificate. The rejected build did not publish an Android update.

## iOS

Bundle ID `com.bakkum.blip`, team `95ERD9S934`. The project and Pods have a consistent iOS 15 minimum. Use the existing paired iPhone simulator UDID `8862F754-FCC1-417C-8B54-E51090FB0B18` explicitly for simulator builds and execution. Do not erase or clone it. Build the signed archive only after simulator validation. The uploaded build version must match the App Store version being submitted.

## Store declarations and runtime checks

- AdMob/Firebase identifiers, approximate location, app interactions and diagnostics must be disclosed. iOS also uses Apple account ID/email for authentication.
- Optional abuse evidence is sent only after the user selects it. Ordinary 1:1 text remains ephemeral. Moderation reports use the private `abuse-reports` bucket; public bucket configuration fails closed.
- Publish the updated privacy/deletion page before submitting the data-safety change.
- Mainland China sales were excluded by the owner on 2026-11-18. Do not submit fictitious regulatory certificates.
- Advertising and simulated betting with non-cash points are present. The iOS age questionnaire must reflect both. Current computed rating is 18+.
- BLIP 1.13 no longer requires an Apple account. History inspection found the gate was added with group chat, but no chat/board/points operation depends on the Apple identity. Existing sessions retain account-deletion controls; do not delete existing account records. Review notes must explain accountless invitation-only access and legacy deletion. See Apple guideline 5.1.1(v): https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage .
- Recheck room authentication, invitation links, encrypted messages, safety reports, ending a room, startup without advertising SDK availability and points identity persistence before release.

### Current Mac iOS signing

The App Store profile `BLIP AppStore 2026-11-19` uses the existing BAKKUM distribution certificate and expires on 2027-05-19. The ignored file `mobile/ios/Flutter/Signing.xcconfig` supplies manual signing to the Runner release configuration only. Do not pass a provisioning profile globally to `xcodebuild`: Pods/framework targets do not use app provisioning profiles.

The existing App Store Connect key is at `/Users/sunggookkim/.private_keys/AuthKey_9TA7V35A5U.p8`; access to BLIP was verified. Do not copy its contents into source or logs. Store submission also requires the owner's real review contact details.

### Apple account deletion

The server requires `APPLE_TEAM_ID`, `APPLE_CLIENT_ID` (`com.bakkum.blip`), `APPLE_KEY_ID` and `APPLE_PRIVATE_KEY` for Apple token revocation. Use a Sign in with Apple key configured for BLIP's primary App ID; APNs keys and keys configured for another primary app are not substitutes. The owner approved registering a BLIP-only key on 2026-11-19 for legacy account deletion. Registration still needs a valid Apple Developer session. JWT signatures use raw 64-byte ES256 format, and Apple network calls have a timeout so an outage cannot leave deletion requests hanging.
