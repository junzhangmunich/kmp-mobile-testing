import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidMultiplatformLibrary)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
}

kotlin {
    
    android {
       namespace = "com.example.kmp_mobile_testing.app.sharedUI"
       compileSdk = libs.versions.android.compileSdk.get().toInt()
       minSdk = libs.versions.android.minSdk.get().toInt()
    
       compilerOptions {
           jvmTarget = JvmTarget.JVM_11
       }
       androidResources {
           enable = true
       }
       withHostTest {
           isIncludeAndroidResources = true
       }
       withDeviceTestBuilder {
           sourceSetTreeName = "test"
       }.configure {
           instrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
       }
    }
    
    sourceSets {
        androidMain.dependencies {
            implementation(libs.compose.uiToolingPreview)
            implementation(libs.compose.uiTooling)
        }
        commonMain.dependencies {
            api(project(":app:sharedLogic"))
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.compose.ui)
            implementation(libs.compose.components.resources)
            implementation(libs.compose.uiToolingPreview)
            implementation(libs.androidx.lifecycle.viewmodelCompose)
            implementation(libs.androidx.lifecycle.runtimeCompose)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
        // Compose snapshot tests: Roborazzi renders through Robolectric on the JVM, no emulator.
        getByName("androidHostTest").dependencies {
            implementation(libs.junit)
            implementation(libs.robolectric)
            implementation(libs.roborazzi)
            implementation(libs.roborazzi.compose)
        }
    }
}

// Roborazzi runs as a plain library: its Gradle plugin hooks into test<Variant>UnitTest tasks,
// which the KMP android library plugin doesn't create (the host tests run in testAndroidHostTest).
// The capture mode is forwarded from -P flags instead:
//   -Proborazzi.record=true  (re)write the goldens in src/androidHostTest/snapshots/
//   -Proborazzi.verify=true  fail when a render differs from its golden (the CI gate)
//   neither                  compare only: render, write diffs to build/outputs/roborazzi, never fail.
//                            With no mode at all captureRoboImage renders nothing, and a plain IDE
//                            run would pass without composing a single screen.
val snapshotGoldens = layout.projectDirectory.dir("src/androidHostTest/snapshots")
tasks.withType<Test>().configureEach {
    val record = providers.gradleProperty("roborazzi.record").getOrElse("false").toBoolean()
    val verify = providers.gradleProperty("roborazzi.verify").getOrElse("false").toBoolean()
    // Roborazzi resolves the pair to VerifyAndRecord, which overwrites the golden it just failed.
    check(!(record && verify)) { "Pass either -Proborazzi.record=true or -Proborazzi.verify=true, not both" }
    systemProperty("roborazzi.test.record", record)
    systemProperty("roborazzi.test.verify", verify)
    systemProperty("roborazzi.test.compare", !record && !verify)
    // The goldens are read and written behind Gradle's back. As an input they keep an up-to-date or
    // cached run from standing in for a comparison against changed goldens; a recording run is never
    // reused, because the goldens it writes are its only real output.
    inputs.files(fileTree(snapshotGoldens))
        .withPropertyName("snapshotGoldens")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    if (record) {
        outputs.upToDateWhen { false }
        outputs.cacheIf { false }
    }
    jvmArgs("--add-exports=java.base/jdk.internal.access=ALL-UNNAMED")
}

dependencies {
    androidRuntimeClasspath(libs.compose.uiTooling)
}