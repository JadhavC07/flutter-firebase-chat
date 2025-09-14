plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.transbuzz.chatapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8  // Changed to Java 8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"  // Changed to match Java 8
    }

    defaultConfig {
        applicationId = "com.transbuzz.chatapp"
        minSdk = flutter.minSdkVersion  
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true
        
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isShrinkResources = false  // Disable for debugging
            isMinifyEnabled = false    // Disable for debugging
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")  // Use debug signing
        }
        
        debug {
            isDebuggable = true
        }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/gradle/incremental.annotation.processors"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:32.7.4"))  // Use stable version

    // Firebase dependencies (without -ktx suffix for Flutter)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-analytics")
    
    // Google Play Services
    implementation("com.google.android.gms:play-services-auth:20.7.0")  // Stable version
    implementation("com.google.android.gms:play-services-base:18.3.0")   // Stable version
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Core Android dependencies
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
}