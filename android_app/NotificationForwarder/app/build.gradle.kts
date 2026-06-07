plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

import java.util.Properties

val localProps = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProps.load(it) }
}
val paymentWebhookSecret: String = localProps.getProperty("payment.webhook.secret", "")
    .replace("\\", "\\\\")
    .replace("\"", "\\\"")

android {
    namespace = "com.kakiempat.notificationforwarder"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.kakiempat.notificationforwarder"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        // WEBHOOK_URL → payment_webhook.php di api.kakiempat.com
        buildConfigField(
            "String",
            "PAYMENT_WEBHOOK_URL",
            "\"https://www.api.kakiempat.com/payment_webhook.php\"",
        )
        // WEBHOOK_SECRET → payment.webhook.secret di local.properties = .payment_webhook_secret server
        buildConfigField("String", "PAYMENT_WEBHOOK_SECRET", "\"$paymentWebhookSecret\"")
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
