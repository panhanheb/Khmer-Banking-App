plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.khmerflutterbank"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.khmerflutterbank"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        // Each flavor reads android/app/src/<flavor>/google-services.json.
        create("dev") {
            dimension = "env"
            applicationId = "com.khmerflutterbank.dev"
            resValue("string", "app_name", "Khmer Bank Dev")
        }
        create("sit") {
            dimension = "env"
            applicationId = "com.khmerflutterbank.sit"
            resValue("string", "app_name", "Khmer Bank SIT")
        }
        create("uat") {
            dimension = "env"
            applicationId = "com.khmerflutterbank.uat"
            resValue("string", "app_name", "Khmer Bank UAT")
        }
        create("preprod") {
            dimension = "env"
            applicationId = "com.khmerflutterbank.preprod"
            resValue("string", "app_name", "Khmer Bank Pre-Prod")
        }
        create("prod") {
            dimension = "env"
            applicationId = "com.khmerflutterbank"
            resValue("string", "app_name", "Khmer Bank")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}
