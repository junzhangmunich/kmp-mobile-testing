#!/usr/bin/env bash
# Verifies or records the snapshot tests (golden images) of both apps.
#
#   scripts/snapshots.sh verify [android|ios]   compare the screens with the committed goldens
#   scripts/snapshots.sh record [android|ios]   re-record the goldens after an intended UI change
#
# Without a platform both run. Review every changed PNG before committing a recording: the
# diff is the test, so never re-record just to silence a failure you don't understand.
#
#   Android  Roborazzi + Robolectric on the JVM, no emulator needed
#            goldens  app/sharedUI/src/androidHostTest/snapshots/
#            diffs    app/sharedUI/build/outputs/roborazzi/*_compare.png
#   iOS      swift-snapshot-testing on the simulator below (IOS_SNAPSHOT_DESTINATION overrides it)
#            goldens  app/iosApp/iosAppTests/__Snapshots__/
#            diffs    open app/iosApp/build/snapshot-tests.xcresult
#
# bitrise.yml runs the same verification; keep its simulator in sync with the one here.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
PLATFORM="${2:-all}"
IOS_DESTINATION="${IOS_SNAPSHOT_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=27.0}"
IOS_MARKER=app/iosApp/iosAppTests/.snapshot-record-mode
IOS_RESULT=app/iosApp/build/snapshot-tests.xcresult

if [[ "$MODE" != verify && "$MODE" != record ]] || [[ "$PLATFORM" != all && "$PLATFORM" != android && "$PLATFORM" != ios ]]; then
  echo "usage: $0 verify|record [android|ios]" >&2
  exit 2
fi

snapshots_android() {
  echo "==> Android snapshots: $MODE"
  if ! ./gradlew :app:sharedUI:testAndroidHostTest -Psnapshots=only "-Proborazzi.$MODE=true"; then
    echo "Diffs: app/sharedUI/build/outputs/roborazzi/*_compare.png" >&2
    return 1
  fi
}

snapshots_ios() {
  echo "==> iOS snapshots: $MODE on $IOS_DESTINATION"
  local xcode=(-project app/iosApp/iosApp.xcodeproj -scheme iosApp -destination "$IOS_DESTINATION")
  # Built on its own, so that a compile error fails a record run too (see the end).
  xcodebuild build-for-testing "${xcode[@]}" -quiet

  # The mode reaches the app-hosted test process through a marker file that SnapshotSupport.swift
  # reads, because environment variables don't. It must not outlive this run.
  trap 'rm -f "$IOS_MARKER"' EXIT
  if [[ "$MODE" == record ]]; then printf all >"$IOS_MARKER"; else printf never >"$IOS_MARKER"; fi
  rm -rf "$IOS_RESULT"
  local status=0
  # Without -collect-test-diagnostics never, xcodebuild spends up to 10 minutes in
  # `simctl diagnose` after a failing run.
  xcodebuild test-without-building "${xcode[@]}" -resultBundlePath "$IOS_RESULT" \
    -collect-test-diagnostics never || status=$?
  rm -f "$IOS_MARKER"

  # swift-snapshot-testing reports every recorded golden as a failure, so a recording exits nonzero.
  if [[ "$MODE" == record ]]; then
    echo "(The failed tests above are expected: each one is a golden that was just recorded.)"
    return 0
  fi
  if [[ $status -ne 0 ]]; then
    echo "Diffs (reference, failure, difference): open $IOS_RESULT" >&2
  fi
  return $status
}

if [[ "$PLATFORM" != ios ]]; then
  snapshots_android
fi
if [[ "$PLATFORM" != android ]]; then
  snapshots_ios
fi

if [[ "$MODE" == record ]]; then
  echo "==> Changed goldens, review them before committing:"
  git status --short -- app/sharedUI/src/androidHostTest/snapshots app/iosApp/iosAppTests/__Snapshots__
fi
