import SnapshotTesting
import Testing
@testable import Kmpmobiletesting

/// `ContentView` before and after "Click me!". Compose twin: `AppSnapshotTest`.
///
/// `.serialized` because every capture goes through the host app's one key window.
@MainActor
@Suite(.snapshots(record: snapshotRecordMode), .serialized)
struct ContentViewSnapshotTests {

    @Test func appInitial() {
        assertScreenSnapshot(of: ContentView(), scenario: "app_initial")
    }

    @Test func appExpanded() {
        assertScreenSnapshot(of: ContentView(initialShowContent: true), scenario: "app_expanded")
    }
}
