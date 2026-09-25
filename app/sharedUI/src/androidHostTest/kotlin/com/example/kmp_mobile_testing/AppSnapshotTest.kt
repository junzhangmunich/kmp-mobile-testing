package com.example.kmp_mobile_testing

import kotlin.test.Test

/** [App] before and after "Click me!". iOS twin: `ContentViewSnapshotTests`. */
class AppSnapshotTest : SnapshotTest() {

    @Test
    fun appInitial() = snapshot("app_initial") {
        App()
    }

    @Test
    fun appExpanded() = snapshot("app_expanded") {
        App(initialShowContent = true)
    }
}
