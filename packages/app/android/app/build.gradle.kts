plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wegig.wegig"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.wegig.wegig"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("wegig-release.keystore")
            storePassword = "wegig2025"
            keyAlias = "wegig-key"
            keyPassword = "wegig2025"
        }
    }

    // ===== FLAVORS CONFIGURATION =====
    flavorDimensions.add("environment")
    
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "WeGig DEV")
        }
        
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "WeGig STAGING")
        }
        
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "WeGig")
        }
    }
    // ===== END FLAVORS CONFIGURATION =====

    packaging {
        jniLibs {
            keepDebugSymbols += setOf("**/libflutter.so", "**/libapp.so")
        }
    }

    buildTypes {
        release {
            // Code obfuscation habilitado (temporariamente desabilitado para debug)
            isMinifyEnabled = false  // TODO: Habilitar após corrigir ProGuard rules
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // TikTok Business SDK
    implementation("com.github.tiktok:tiktok-business-android-sdk:1.5.0")
    implementation("androidx.lifecycle:lifecycle-process:2.3.1")
    implementation("androidx.lifecycle:lifecycle-common-java8:2.3.1")
    implementation("com.android.installreferrer:installreferrer:2.2")
}
