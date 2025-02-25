plugins {
    alias(
        libs.plugins.android.application
    )
    alias(
        libs.plugins.kotlin.android
    )
}

android {
    namespace =
        "in.dimalip.todoistphone"
    compileSdk =
        34

    defaultConfig {
        applicationId =
            "in.dimalip.todoistphone"
        minSdk =
            30
        targetSdk =
            34
        versionCode =
            1
        versionName =
            "1.0"

        testInstrumentationRunner =
            "androidx.test.runner.AndroidJUnitRunner"
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
}

dependencies {

    implementation(
        libs.core.ktx
    )
    implementation(
        libs.appcompat
    )
    implementation(
        libs.material
    )
    testImplementation(
        libs.junit
    )
    androidTestImplementation(
        libs.ext.junit
    )
    androidTestImplementation(
        libs.espresso.core
    )
}