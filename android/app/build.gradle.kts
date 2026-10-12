import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Check-in device mode (run with --dart-define=FACEPING_DEVICE_TOKEN=fpd_…) gets its own application ID (".device" on
// the end) and name ("FaceCheck Device"), so it installs next to the sandbox app instead of replacing it. Flutter
// hands the --dart-define values to Gradle base64-encoded.
val deviceMode = (findProperty("dart-defines") as String?).orEmpty().split(",").filter { it.isNotBlank() }
    .map { String(Base64.getDecoder().decode(it)) }
    .any { it.startsWith("FACEPING_DEVICE_TOKEN=") && it.length > "FACEPING_DEVICE_TOKEN=".length }

android {
    namespace = "com.example.facecheck"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Change this to your own application ID before you publish (and `namespace` above).
        applicationId = "com.example.facecheck.flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (deviceMode) applicationIdSuffix = ".device"
        manifestPlaceholders["appLabel"] = if (deviceMode) "FaceCheck Device" else "FaceCheck"
    }

    buildTypes {
        release {
            // Signed with the debug key so `flutter run --release` installs straight away.
            // Use your own signing config before you publish.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
