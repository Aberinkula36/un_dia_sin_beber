import com.android.build.gradle.internal.api.BaseVariantOutputImpl

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.aberinkula.undiasinbeber"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.aberinkula.undiasinbeber"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Configuración para renombrar el APK
    afterEvaluate {
        tasks.matching { it.name.startsWith("package") }.configureEach {
            doLast {
                val variantName = name.replace("package", "").replaceFirstChar { it.lowercase() }
                val versionName = android.defaultConfig.versionName ?: "1.0.0"
                val apkName = "un_dia_sin_beber_v${versionName}.apk"
                
                val sourceFile = file("build/outputs/flutter-apk/app-$variantName.apk")
                val targetFile = file("build/outputs/flutter-apk/$apkName")
                
                if (sourceFile.exists()) {
                    sourceFile.copyTo(targetFile, overwrite = true)
                    println("✅ APK renombrado a: $apkName")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
