import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: keystores/<env>/key.properties (see keystores/README.md). Choose the key with
// `-P signingEnv=dev|test|prod` (default prod). In-app updates replace the installed APK, which
// only works when every release of a channel is signed with the same key.
val signingEnv = (project.findProperty("signingEnv") as String?) ?: "prod"
val signingProps = rootProject.file("keystores/$signingEnv/key.properties")
    .takeIf { it.isFile }
    ?.let { file -> Properties().apply { file.inputStream().use { load(it) } } }

val releaseRequested = gradle.startParameter.taskNames.any { name ->
    val task = name.substringAfterLast(':').lowercase()
    task.contains("release") || task in setOf("assemble", "bundle", "build")
}
if (releaseRequested && signingProps == null) {
    throw GradleException("Release signing is missing for '$signingEnv'. Run dart run tool/init_android_keystores.dart --env $signingEnv, or restore the existing release key backup. Debug builds do not require release keys.")
}

android {
    namespace = "cn.deeprespond.meeting"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cn.deeprespond.meeting"
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
    }

    signingConfigs {
        if (signingProps != null) {
            create("release") {
                storeFile = file(signingProps.getProperty("storeFile"))
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            val suffix = System.getenv("OPENMEETING_ANDROID_DEBUG_SUFFIX")
            if (!suffix.isNullOrBlank()) {
                require(Regex("\\.[a-z][a-z0-9_]*").matches(suffix)) { "Invalid debug application suffix" }
                applicationIdSuffix = suffix
            }
        }
        release {
            signingConfig = if (signingProps != null) {
                signingConfigs.getByName("release")
            } else {
                null // Debug-only configuration; release tasks fail above without explicit credentials.
            }
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
