This is a Kotlin Multiplatform project targeting Android, iOS, Server.

* [/app/iosApp](./app/iosApp/iosApp) contains an iOS application. Even if you’re sharing your UI with Compose Multiplatform,
  you need this entry point for your iOS app. This is also where you should add SwiftUI code for your project.

* [/app/sharedLogic](./app/sharedLogic/src) is for the code that will be shared between app targets in the project.
  The most important subfolder is [commonMain](./app/sharedLogic/src/commonMain/kotlin). If preferred, you
  can add code to the platform-specific folders here too.

* [/app/sharedUI](./app/sharedUI/src) is for code that will be shared across your Compose Multiplatform applications.
  It contains several subfolders:
  - [commonMain](./app/sharedUI/src/commonMain/kotlin) is for code that’s common for all targets.
  - Other folders are for Kotlin code that will be compiled for only the platform indicated in the folder name.
    For example, if you want to use Apple’s CoreCrypto for the iOS part of your Kotlin app,
    the [iosMain](./app/sharedUI/src/iosMain/kotlin) folder would be the right place for such calls.
    Similarly, if you want to edit the Desktop (JVM) specific part, the [jvmMain](./app/sharedUI/src/jvmMain/kotlin)
    folder is the appropriate location.

* [/core](./core/src) is for the code that will be shared between all targets in the project.
  The most important subfolder is [commonMain](./core/src/commonMain/kotlin). If preferred, you
  can add code to the platform-specific folders here too.

* [/server](./server/src/main/kotlin) is for the Ktor server application.

### Running the apps

Use the run configurations provided by the run widget in your IDE's toolbar. You can also use these commands and options:

- Android app: `./gradlew :app:androidApp:assembleDebug`
- Server: `./gradlew :server:run`
- iOS app: open the [/app/iosApp](./app/iosApp) directory in Xcode and run it from there.

### Running tests

Use the run button in your IDE's editor gutter, or run tests using Gradle tasks:

- Android tests: `./gradlew :app:sharedUI:testAndroidHostTest :app:sharedLogic:testAndroidHostTest`
- Server tests: `./gradlew :server:test`
- iOS tests: `./gradlew :app:sharedLogic:iosSimulatorArm64Test`

### Snapshot tests

Both UIs have snapshot (golden image) tests: each test renders a screen and compares it with a
committed PNG, so an unintended visual change fails the build.

|         | Android (Compose)                                                                 | iOS (SwiftUI)                                                                                |
|---------|-----------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| Library | [Roborazzi](https://github.com/takahirom/roborazzi) on Robolectric, no emulator   | [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing), simulator    |
| Tests   | [app/sharedUI/src/androidHostTest](./app/sharedUI/src/androidHostTest/kotlin)     | [app/iosApp/iosAppTests](./app/iosApp/iosAppTests)                                           |
| Goldens | `app/sharedUI/src/androidHostTest/snapshots/`                                     | `app/iosApp/iosAppTests/__Snapshots__/`                                                      |

- Verify: `scripts/snapshots.sh verify` (or `verify android` / `verify ios`)
- Re-record after an intended UI change: `scripts/snapshots.sh record`, then review every changed
  PNG before committing it. The diff is the test.

Good to know:

- The iOS goldens belong to one simulator (iPhone 17, iOS 27.0), pinned in `scripts/snapshots.sh`
  and `bitrise.yml`. Keep the two in sync.
- From the IDE: Android Studio renders the snapshots and writes diffs to
  `app/sharedUI/build/outputs/roborazzi/` without ever failing; Xcode's ⌘U records missing
  goldens and fails on changed ones.
- CI verifies both platforms in workflows of their own (`android_snapshots`, `ios_snapshots`),
  in parallel with the unit tests and builds, and keeps the diff images of a failed comparison as
  build artifacts. The Android goldens are recorded on macOS while CI renders on Linux. If CI
  fails with nothing but faint antialiasing differences, replace the goldens with that build's
  `*_actual.png` files.
- `-Psnapshots=only` / `-Psnapshots=skip` runs only the Compose snapshot suites (every subclass
  of `SnapshotTest`) or everything but them.

---

Learn more about [Kotlin Multiplatform](https://www.jetbrains.com/help/kotlin-multiplatform-dev/get-started.html)…