# FacePing Flutter starter

**FaceCheck**: a small Flutter app that enrols your face and verifies it live, on the phone, with a head-turn liveness check. Switch on airplane mode and it still matches. The same app as the Android, iOS, React Native and .NET MAUI starters.

It's a fuller version of the app you build in the [Flutter guide](https://docs.faceping.ai/start/flutter/) (it also runs as a check-in device and shows what each sync found), built on [`faceping`](https://pub.dev/packages/faceping) from pub.dev.

## Run it

You need [Flutter](https://docs.flutter.dev/get-started/install) 3.24 or later, and a phone with a cable: an Android phone (Android 7 or later, 64-bit) with USB debugging on, or an iPhone (iOS 15.1 or later) and a Mac with Xcode 26 or later. Emulators and the simulator have no real front camera.

1. **Get a free sandbox key** at [app.faceping.ai/signup](https://app.faceping.ai/signup) (no card, no approval). In the dashboard: **Developers → Sandbox keys → Create sandbox key**. It starts with `fp_test_`.
2. **iPhone only: set your team and bundle id.** The project has no team set. Open `ios/Runner.xcworkspace` in Xcode, select the Runner target, **Signing & Capabilities**, pick your **Team**, and change the bundle identifier `com.example.facecheck.flutter` to your own. (Or, from the command line, set it for one build: `FLUTTER_XCODE_DEVELOPMENT_TEAM=YOURTEAMID flutter build ios --release`.)
3. **Run it** on your phone, passing your key on the command line (it's never written into the code):

   ```bash
   flutter pub get
   flutter run --dart-define=FACEPING_SANDBOX_KEY=fp_test_yourkey
   ```

   A debug build is fine: the FacePing core inside the SDK is already compiled for speed. On iOS, Flutter fetches the FacePing Swift package from GitHub the first time.

   For an APK to install or share, build one per ABI, for the two ABIs FacePing runs on:

   ```bash
   flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 --dart-define=FACEPING_SANDBOX_KEY=fp_test_yourkey
   ```

   Install `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (about 48 MB) on a phone; `app-x86_64-release.apk` is for emulators. Without `--split-per-abi` you get one APK for both, about twice the size.

4. Tap **Enrol my face**, then **Verify**, and turn your head when asked: you should see **Match**. Now switch on airplane mode and tap **Verify** again.

Without a key the app shows **Sandbox key problem**.

Before you build your own app from this, change the app id `com.example.facecheck.flutter` to your own: `applicationId` (and `namespace`) in `android/app/build.gradle.kts`, and the bundle identifier in Xcode. Sign Android release builds with your own key (the starter signs them with the debug key so they install straight away).

## Try it as a check-in device

Once you've tried the server side with your sandbox key (a practice check-in list, an enrolment link, a device), this app can be the check-in device:

1. In the dashboard, open your practice list's **Devices** tab and add a device (or call `POST /v1/lists/{listId}/devices`). Copy the `fpd_` token.
2. Run the app with the token and the person to verify (the `personId` you enrolled on the practice list, through an enrolment link or from your server):

   ```bash
   flutter run --release --dart-define=FACEPING_DEVICE_TOKEN=fpd_yourtoken --dart-define=FACEPING_PERSON_ID=ACME-000123
   ```

   With a device token, the sandbox key is ignored. On Android, the build gets its own app id (`com.example.facecheck.flutter.device`) and name (**FaceCheck Device**), so it installs next to the sandbox app instead of replacing it. On an iPhone, do the same by adding two settings in front of the command (the bundle id must be one your team can sign):

   ```bash
   FLUTTER_XCODE_PRODUCT_BUNDLE_IDENTIFIER=com.yourcompany.facecheck.device FLUTTER_XCODE_FACECHECK_DISPLAY_NAME="FaceCheck Device" \
     flutter run --release --dart-define=FACEPING_DEVICE_TOKEN=fpd_yourtoken --dart-define=FACEPING_PERSON_ID=ACME-000123
   ```

   Without them, the device build replaces the sandbox app on the iPhone.
3. The app downloads the list, hides **Enrol my face** (a check-in device gets its people from the server) and opens **Verify** once that person is on the phone. After each sync it says what it found: how many people, or that the token isn't valid, the list has finished, or it couldn't connect.

See [Devices and offline sync](https://docs.faceping.ai/devices/).

## What's where

| File | What it does |
|---|---|
| `lib/main.dart` | Turns FacePing on with your sandbox key or a device token (`FacePing.init`), the camera (`FaceCamera`), `enroll`, `verifyLive` and `sync`, and what each result means. |
| `pubspec.yaml` | The FacePing dependency (`faceping: 1.0.0-preview.5`). |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription`, the camera prompt. iOS stops the app without it. |
| `ios/Runner.xcodeproj` | Minimum iOS version 15.1, which FacePing needs, and the bundle id. |
| `ios/Flutter/Debug.xcconfig`, `Release.xcconfig` | The app's name on the iPhone (`FACECHECK_DISPLAY_NAME`). |
| `android/app/build.gradle.kts` | The app id, with `.device` added for a check-in device build. Android needs nothing else: the SDK adds the camera permission. |
| `android/app/src/main/res/xml/data_extraction_rules.xml`, `backup_rules.xml` | Keep FacePing's face store (`files/faceping/`) and its wrapped key (`faceping.keys.xml`) out of backups and transfers to a new phone: the key can't work on another device. |

Flutter uses Swift Package Manager for iOS plugins by default. If you've turned it off, CocoaPods works too: `pod install` downloads the same FacePing framework and checks its SHA-256 (set `platform :ios, '15.1'` in the generated `ios/Podfile`).

## The sandbox

Free, for building and testing: up to 25 faces per device, each deleted 24 hours after it was enrolled. Faces you enrol in the app never leave the phone. People on your practice list (see above) are held by FacePing, each for 24 hours. The app needs a connection the first time it runs, to activate your key; after that it works offline for 30 days.

To use FacePing with real people, go live from your [FacePing dashboard](https://app.faceping.ai). Your verify code doesn't change.

## Learn more

- [Get started with Flutter](https://docs.faceping.ai/start/flutter/): the app, step by step
- [Flutter SDK reference](https://docs.faceping.ai/sdk/flutter/): every method, outcome and error
- [How the SDK works](https://docs.faceping.ai/sdk/): liveness, storage, sandbox and production
- [Security](https://docs.faceping.ai/security/): the Rust core, encryption on the device
- [`faceping` on pub.dev](https://pub.dev/packages/faceping)
- Questions: support@faceping.ai

## Licence

This starter app is MIT licensed (see [LICENSE](LICENSE)): copy any of it into your own app. The FacePing SDK it uses has its own licence, the [FacePing SDK licence](https://faceping.ai/legal/sdk-licence).
