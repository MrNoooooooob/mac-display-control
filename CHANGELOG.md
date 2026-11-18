# Changelog

## 0.0.2-beta — Stability Foundations (2026-11-18)
- Added independent `DisplayStabilityPolicy` Swift module, with executable unit tests.
- Added a one-click **120 Hz** menu-bar action when native timings are detected.
- Prevented avoidable HiDPI teardown when the requested refresh rate is not natively offered.
- Re-resolve physical display after mirror teardown before re-enabling a virtual session.
- Verify requested refresh rate from measured mode before declaring success; keep rollback.
- Disable unsupported 120/144/240 Hz buttons in the display dashboard.
- Improved wording: 120 Hz is a test profile, not proof of artifact-free operation.
- New safe GitHub update script; macOS CI policy tests.

## 0.0.1-beta — Initial Beta
- Initial SwiftUI interface and 120/144/240 Hz experiments, HiDPI/HDR status, machidpi integration.

**No confirmed HDR pipeline for virtual mirroring.** Full macOS build and hardware tests remain pending for 0.0.2-beta.
