---
title: Add Dock and ground drifts
summary: snow piles on Dock and screen bottom
size: medium
type: feature
sprint: Snow drifts
blocked_by: [hide-covered-drifts]
status: done
wiki: "[[pitch]]"
note: "Ground drift on screen bottom, Dock rect via Accessibility (Dock pid), drift on its top."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- Ground drift: along the bottom of the main screen, full width, max depth ~22 pt, no corner taper.
- Dock drift: on top of the Dock's visible tile row. Dock rect via Accessibility: `AXUIElementCreateApplication(Dock pid)` → first child list → `AXPosition`/`AXSize`. Re-read every 2 s and on screen change.
- Accessibility not granted → no Dock drift, ground drift still works; no permission prompt in v1 (out of scope: onboarding). Note it in `NOTES:` if the call fails.
- Dock hidden / on left or right side → only bottom Dock gets a drift; side Dock → none.
- Both are `SnowDrift`s, same render path as windows. Front windows occlude them (#6).
- Lives in `Core/Windows/DockWatch` + `SnowField` ledges.

## Acceptance criteria

- [ ] Snow piles along the bottom edge of the screen.
- [ ] With Accessibility granted and Dock at bottom → snow piles on top of the Dock.
- [ ] Dock hidden or on the side → no Dock pile, no crash.
- [ ] The Dock sits in front of app windows: it hides the window piles under it, and no window hides the Dock pile.
- [ ] Unit test: Dock rect conversion AX (top-left) → Cocoa.

## Implementation

- stacked on: wa/hide-covered-drifts @ 2816a36.
- `SnowSurfaceID` enum (`.window(id)`, `.dock`, `.ground`); `SnowSurface.pid` optional; `frontToBack(windows:dockTileRow:screen:)` → windows, Dock, ground.
- Ground: full width at y = 0, 22 pt, no taper. Dock: AX tile row (AXList), 14 pt, radius 16 taper. Windows occlude both; Dock occludes ground.
- `DockReader` / `AXDockReader` (nil if not trusted, no prompt), `DockWatch` (2 s + screen change). Side/hidden Dock → nil.
- ⚠️ This Mac: Dock autohide on → AX row off-screen → no Dock pile while hidden (matches spec "Dock hidden → none").
- build ✅ · tests ✅ (77). Runtime not checked.

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