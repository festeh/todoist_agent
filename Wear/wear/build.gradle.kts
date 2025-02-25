plugins {
    alias(
        libs.plugins.android.application
    )
    alias(
        libs.plugins.kotlin.android
    )
    alias(
        libs.plugins.kotlin.compose
    )
}

android {
    namespace =
        "in.dimalip.todoistwear"
    compileSdk =
        34

    defaultConfig {
        applicationId =
            "in.dimalip.todoistwear"
        minSdk =
            30
        targetSdk =
            34
        versionCode =
            1
        versionName =
            "1.0"

    }

    buildTypes {
        release {
            isMinifyEnabled =
                false
            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_11
        targetCompatibility =
            JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget =
            "11"
    }
    buildFeatures {
        compose =
            true
    }
}

dependencies {

    implementation(
        libs.play.services.wearable
    )
    implementation(
        libs.lifecycle.runtime.ktx
    )
    implementation(
        libs.activity.compose
    )
    implementation(
        platform(
            libs.compose.bom
        )
    )
    implementation(
        libs.ui
    )
    implementation(
        libs.ui.graphics
    )
    implementation(
        libs.ui.tooling.preview
    )
    implementation(
        libs.material3
    )
    androidTestImplementation(
        platform(
            libs.compose.bom
        )
    )
    androidTestImplementation(
        libs.ui.test.junit4
    )
    debugImplementation(
        libs.ui.tooling
    )
    debugImplementation(
        libs.ui.test.manifest
    )
}