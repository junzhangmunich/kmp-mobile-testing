import Foundation
import SnapshotTesting
import SwiftUI
import UIKit

// Snapshot testing for the SwiftUI screens: each capture is compared with its golden in
// `__Snapshots__/<Suite>/`. The Compose counterpart is `SnapshotTest` in
// `app/sharedUI/src/androidHostTest`.

/// Up to 0.1% of the pixels may differ (the budget of the Compose goldens), and a pixel still
/// counts as equal while it is perceptually within 2%, which absorbs antialiasing noise.
private let snapshotPrecision: Float = 0.999
private let snapshotPerceptualPrecision: Float = 0.98

/// Record mode for every suite's `.snapshots(record:)` trait.
///
/// `scripts/snapshots.sh` passes it in the marker file `iosAppTests/.snapshot-record-mode` (`all`
/// to re-record, `never` to verify), because environment variables from `xcodebuild` don't reach
/// this app-hosted test process. `SNAPSHOT_TESTING_RECORD` still works from the Xcode scheme.
/// With neither (⌘U in Xcode) the mode is `.missing`: new goldens are recorded, changed ones fail.
let snapshotRecordMode: SnapshotTestingConfiguration.Record = {
    let marker = URL(fileURLWithPath: "\(#filePath)")
        .deletingLastPathComponent()
        .appendingPathComponent(".snapshot-record-mode")
    let requested = (try? String(contentsOf: marker, encoding: .utf8))
        ?? ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"]
    return requested
        .flatMap { SnapshotTestingConfiguration.Record(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        ?? .missing
}()

/// Renders `view` as a full iPhone 13 screen (390x844pt, the size of the Compose goldens too) in
/// light mode and compares it with the golden `<scenario>.ios<major>.png`.
///
/// The iOS major version is part of the name because a new iOS renders differently: a run on a
/// newer simulator records a parallel golden and fails, instead of failing every comparison.
@MainActor
func assertScreenSnapshot<V: View>(
    of view: V,
    scenario: String,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    // A capture taken while an animation runs picks a random frame of it.
    UIView.setAnimationsEnabled(false)
    let iosMajor = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    assertSnapshot(
        of: UIHostingController(rootView: view),
        as: .image(
            on: .iPhone13,
            // Renders through the host app's key window, so the simulator's screen must be at least
            // 390x844pt; anything outside it comes back blank.
            drawHierarchyInKeyWindow: true,
            precision: snapshotPrecision,
            perceptualPrecision: snapshotPerceptualPrecision,
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                // 1x keeps the PNGs small. sRGB keeps an iOS 26+ simulator from writing 16-bit
                // Display P3, which is 3x the bytes.
                UITraitCollection(displayScale: 1),
                UITraitCollection(displayGamut: .SRGB),
            ])
        ),
        named: "ios\(iosMajor)",
        fileID: fileID,
        file: filePath,
        testName: scenario,
        line: line,
        column: column
    )
}
