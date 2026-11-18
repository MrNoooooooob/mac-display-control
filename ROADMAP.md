# Mac Display Control — staged development roadmap

**Publisher:** MrNoooooooob · © 2026. This roadmap lists goals, not shipped features.

| Release | Priority | Intended scope | Acceptance criteria |
|---|---|---|---|
| **0.0.2-beta** | P0 | 120 Hz stability policy, conservative switch, menu shortcut | Source patch+pure Swift tests pass; 120/HiDPI verified on device |
| 0.0.3-beta | P0 | Per-monitor display profiles (Work 120, Native HDR, Gaming) | No automatic profile switch without opt-in and fallback |
| 0.0.4-beta | P1 | Menu Bar Pro, layout customization, quick profiles | Correct rates and HDR manual indicator at each change |
| 0.0.5-beta | P1 | Display Health event log, sleep/wake/connect changes | Diagnostics export with no personal/private data |
| 0.0.6-beta | Research | Native HiDPI + HDR test lab (no forced HDMI HDR claims) | Confirm true output or report unsupported |
| 0.0.7-beta | P1 | Modular first-party CoreGraphics mode/read layer | Unit tests and match existing behavior, MIT notices retained |
| 0.0.8-beta | Design | Liquid Glass interface, Accessibility, localization | Keyboard/VoiceOver/contrast checks |
| 0.0.9-beta | Release | Notarization investigation, signing, updater | CI builds, repeatable releases, user-verified install |
| 1.0 | Goal | Independent maintained display controller | machidpi code replaced only after a functioning replacement is tested |

**Hard limitations:** Display properties must never be fabricated. 120 Hz is a mitigation candidate, not a fix for all flicker. The machidpi virtual mirror has no verified HDR render pipeline. machidpi license (© 2026 ac50, MIT) must stay as long as its code is used.
