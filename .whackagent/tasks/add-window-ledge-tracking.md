---
title: Add window ledge tracking
summary: window tops and z-order, polled
size: medium
type: feature
sprint: Snow drifts
blocked_by: [add-menu-bar-toggle]
status: done
wiki: "[[pitch]]"
note: "CGWindowListCopyWindowInfo poll, layer 0, alpha > 0, own app excluded. Z-order, CG → panel coords, moved/closed detection (lastFrames, leaving)."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- `Timer` 1/60 s on the main run loop, `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)`.
- Keep entries with `kCGWindowLayer == 0`, `kCGWindowAlpha > 0`, owner pid ≠ own pid, bounds ≥ 40×40 pt. List order = z-order (index 0 = frontmost).
- Model `Listed` → `SnowSurface` (id = window number, pid, frame in Cocoa global coordinates, z, cornerRadius 10 pt default macOS 26 window radius guess). Conversion CG (top-left of primary screen) → Cocoa (bottom-left): `y = primaryScreenMaxY − cgY − height`.
- Diffing vs last poll: `moved` (frame changed), `appeared`, `closed` (gone), reported as a `WindowChanges` value. Consumers: #5 drifts, #9 shake.
- No Accessibility, no Screen Recording permission needed (bounds only, no titles).
- Lives in `Core/Windows/`: `WindowList` (protocol + `CGWindowList` impl, injectable raw source for tests), `WindowTracker` (poll + diff, publishes surfaces), `SnowSurface`. Started/stopped with snowing (no poll when off).
- No UI in this task; a debug overlay is out of scope.

## Acceptance criteria

- [ ] With snow on, tracker exposes on-screen app windows with correct Cocoa frames and front-to-back order (checked in tests with recorded window dictionaries).
- [ ] Own overlay, menu bar, Dock and desktop never listed.
- [ ] Moving, opening, closing a window → one `moved` / `appeared` / `closed` change on the next tick.
- [ ] Snow off → no polling timer running.
- [ ] Unit tests: CG → Cocoa conversion (primary + secondary screen layout), filters, diffing.

## Implementation

- `Snow/Core/Windows/`: `WindowListing` protocol + `CGWindowListing` (options 0x11), `WindowRecord` (Sendable, parsed from CF dict), `ScreenCoordinates` (CG → Cocoa via primary maxY), `SnowSurface` (id, pid, frame, zIndex, cornerRadius 10), `WindowChanges` (appeared/moved/closed).
- `WindowTracker` (@MainActor): `start()` polls now + Timer 1/60 s on main `.common`; `stop()` invalidates, clears surfaces; `surfaces` front→back; `changes: AsyncStream<WindowChanges>` (one per changed tick). Not wired into app (#5 does).
- Deviations: `z` → `zIndex` (lint), protocol `WindowListing` (BRIEF).
- Glossary candidates (code-only): `WindowRecord`, `WindowChanges`, `ScreenCoordinates`.
- build ✅ · tests ✅ (24 total, 20 new).

## Review

<!-- Fill by /wa-validate (and /wa-code when review.when: each_round). Findings tagged by
     lens (style / elegance / structure / correctness) + what autofix changed, one block per
     round. -->

### Round validation — 2026-11-05
- Verifier (per sprint) on each task's own diff, then 3 delta rounds on `wa/review-fixes` (all 12 tasks reviewed together, fixes on one branch because tasks are stacked).
- Blocking found and fixed: flake model, grain outline and drift shading rewritten from a behaviour spec (own model, own constants); drift physics formulas and constants re-derived.
- Should/nits fixed: dda7cef, 51b777b, final nits commit. Last round: 135 tests green, lint clean.
- review: clean

## Verification

manual validation — not run by agent (no macOS UI driver). Build + unit tests = proof.

## Feedback

<!-- Fill by /wa-feedback, one block per round: what you asked (your words), triage
     (defect / adjustment / new scope / rule), what changed, review + verify verdicts,
     any rule promoted into convention module. Rounds append, never overwrite. -->