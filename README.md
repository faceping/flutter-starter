# FacePing Flutter starter

**FaceCheck**: a small Flutter app that enrols your face and verifies it live, on the phone, with a head-turn liveness check. Switch on airplane mode and it still matches. The same app as the Android, iOS, React Native and .NET MAUI starters.

It's the finished app from the [Flutter quickstart](https://docs.faceping.ai/start/flutter/), built on [`faceping`](https://pub.dev/packages/faceping) from pub.dev.

## Run it

You need [Flutter](https://docs.flutter.dev/get-started/install) 3.24 or later, and a phone with a cable: an Android phone (Android 7 or later, 64-bit) with USB debugging on, or an iPhone (iOS 15.1 or later) and a Mac with Xcode 26 or later. Emulators and the simulator have no real front camera.

1. **Get a free sandbox key** at [app.faceping.ai/signup](https://app.faceping.ai/signup) (no card, no approval). In the dashboard: **Developers → Sandbox keys → Create sandbox key**. It starts with `fp_test_`.
2. **iPhone only: set your team and bundle id.** Open `ios/Runner.xcworkspace` in Xcode, select the Runner target, **Signing & Capabilities**, pick your **Team**, and change the bundle identifier `com.example.facecheck.flutter` to your own.
3. **Run it** on your phone, passing your key on the command line (it's never written into the code):

   ```bash
   flutter pub get
   flutter run --dart-define=FACEPING_SANDBOX_KEY=fp_test_yourkey
   ```

   A debug build is fine: the FacePing core inside the SDK is already compiled for speed. On iOS, Flutter fetches the FacePing Swift package from GitHub the first time.

4. Tap **Enrol my face**, then **Verify**, and turn your head when asked: you should see **Match**. Now switch on airplane mode and tap **Verify** again.

Without a key the app shows **Sandbox key problem**.

Before you build your own app from this, change the app id `com.example.facecheck.flutter` to your own: `applicationId` (and `namespace`) in `android/app/build.gradle.kts`, and the bundle identifier in Xcode. Sign Android release builds with your own key (the starter signs them with the debug key so they install straight away).

## What's where

| File | What it does |
|---|---|
| `lib/main.dart` | Turns FacePing on with your sandbox key (`FacePing.init`), the camera (`FaceCamera`), `enroll` and `verifyLive`, and what each result means. |
| `pubspec.yaml` | The FacePing dependency (`faceping: 1.0.0-preview.3`). |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription`, the camera prompt. iOS stops the app without it. |
| `ios/Runner.xcodeproj` | Minimum iOS version 15.1, which FacePing needs. |
| `android/app/build.gradle.kts` | The app id, and the two ABIs FacePing runs on. Android needs nothing else: the SDK adds the camera permission. |

Flutter uses Swift Package Manager for iOS plugins by default. If you've turned it off, CocoaPods works too: `pod install` downloads the same FacePing framework and checks its SHA-256 (set `platform :ios, '15.1'` in the generated `ios/Podfile`).

## The sandbox

Free, for building and testing: up to 25 faces per device, each deleted 24 hours after it was enrolled. Faces never leave the phone. The app needs a connection the first time it runs, to activate your key; after that it works offline for 30 days.

To use FacePing with real people, go live from your [FacePing dashboard](https://app.faceping.ai). Your verify code doesn't change.

## Learn more

- [Flutter quickstart](https://docs.faceping.ai/start/flutter/): this app, step by step
- [Flutter SDK reference](https://docs.faceping.ai/sdk/flutter/): every method, outcome and error
- [How the SDK works](https://docs.faceping.ai/sdk/): liveness, storage, sandbox and production
- [Security](https://docs.faceping.ai/security/): the Rust core, encryption on the device
- [`faceping` on pub.dev](https://pub.dev/packages/faceping)
- Questions: support@faceping.ai

## Licence

This starter app is MIT licensed (see [LICENSE](LICENSE)): copy any of it into your own app. The FacePing SDK it uses has its own licence, the [FacePing SDK licence](https://faceping.ai/legal/sdk-licence).
