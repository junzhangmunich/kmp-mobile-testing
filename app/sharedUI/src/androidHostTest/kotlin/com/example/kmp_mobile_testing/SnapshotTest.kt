package com.example.kmp_mobile_testing

import androidx.compose.runtime.Composable
import com.github.takahirom.roborazzi.RoborazziOptions
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Base class for Compose snapshot tests: each capture is rendered on the JVM by Robolectric's
 * native graphics and compared with its golden in `src/androidHostTest/snapshots/`. The mode
 * (record / verify / compare) comes from Gradle, see `app/sharedUI/build.gradle.kts`.
 *
 * The render environment is pinned, so that a golden only changes when the UI does:
 * - `sdk = [36]` is the Android version Robolectric emulates (the greeting prints it, too).
 * - `w390dp-h844dp-mdpi` is the logical size of the iOS goldens (iPhone 13, 390x844pt) at 1x,
 *   so both platforms' images line up and stay small.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w390dp-h844dp-mdpi")
abstract class SnapshotTest {

    /** Renders [content] full screen and compares it with the golden `<name>.png`. */
    protected fun snapshot(name: String, content: @Composable () -> Unit) {
        captureRoboImage("src/androidHostTest/snapshots/$name.png", options, content)
    }

    private companion object {
        /**
         * Up to 0.1% of the pixels (~330 at 390x844) may differ, the same budget as the iOS goldens.
         * They are recorded on macOS but CI renders on Linux, and Robolectric doesn't promise
         * identical antialiasing across operating systems; the budget absorbs that noise and still
         * catches a changed button label. Don't raise it to 1%: "Click me!" -> "Tap me!" passes there.
         */
        val options = RoborazziOptions(
            compareOptions = RoborazziOptions.CompareOptions(changeThreshold = 0.001F),
        )
    }
}
