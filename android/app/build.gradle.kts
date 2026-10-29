import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.budgetseal.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.budgetseal.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "BudgetSeal"
    }

    buildTypes {
        // Debug builds install next to the Play Store app (own data). Google
        // Sign-In needs its own Android OAuth client for this id + the debug
        // keystore's SHA-1.
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "BudgetSeal Dev"
        }
        // Flutter creates "profile" from debug before the suffix above is
        // set, so it would build as the Play Store app's id. Profile builds
        // (speed checks) replace the dev app instead.
        maybeCreate("profile").apply {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "BudgetSeal Dev"
        }
        release {
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Drive picker (DrivePicker.kt); same version google_sign_in brings.
    implementation("com.google.android.gms:play-services-auth:21.6.0")
}

flutter {
    source = "../.."
}
