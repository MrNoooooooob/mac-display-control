# Mac Display Control v0.0.2-beta — Stability Foundations

© 2026 MrNoooooooob · Open-source beta for Apple Silicon on macOS 26+

**What's new**
- Dedicated 120 Hz menu-bar action if the physical monitor reports a compatible mode.
- Safer refresh changes: non-offered modes are rejected without tearing down working HiDPI.
- Refresh confirmation and recovery use the actually measured panel rate.
- Improved LG UltraGear 3440×1440 display identity and virtual-display filtering (carried over).
- Independent `DisplayStabilityPolicy.swift` core module with unit tests.
- Human-readable HiDPI / HDR* / Hz status and dark SwiftUI dashboard.

**Known limitations**
- Pixel artifacts cannot be automatically detected; 120 Hz has appeared more stable than 240 Hz on one LG OLED test configuration, but is not guaranteed flicker-free.
- `HDR ✓*` is a manual HDR-switch confirmation, not validation of HDMI HDR pixels. The upstream virtual display does **not** provide a verified HDR render path.
- Changing refresh rate can briefly blank the screen; ad-hoc signing, not notarized.
- macOS native compilation and attached-monitor testing remain required.

**Dependencies and rights:** Independent UI/policy by © 2026 MrNoooooooob; virtual HiDPI core by © 2026 ac50 (`machidpi`, MIT). This is not an official machidpi release.
