---
title: Add multi-screen overlays
summary: one overlay per screen, follows Spaces
size: medium
type: feature
sprint: Comfort
blocked_by: [add-clear-snow]
status: done
wiki: "[[pitch]]"
note: "One SnowScreen per NSScreen, rebuilt on screen change, Space change handled (NSWorkspace notifications)."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- One `SnowOverlay` + its own `SnowField` per `NSScreen`, each with `share` = fraction of total area for flake density.
- Rebuild on `NSApplication.didChangeScreenParametersNotification`; keep piles of unchanged screens.
- Windows routed to the screen containing their top edge; a window spanning two screens gets a ledge segment per screen.
- Ground drift per screen; Dock drift only on the screen hosting the Dock.
- Space change (`NSWorkspace.activeSpaceDidChangeNotification`): drop window piles not on the new Space's window list (they fall), panels already join all Spaces.

## Acceptance criteria

- [ ] Two displays → snow falls and piles on both, same density per area.
- [ ] Unplug / plug a display → overlays follow without restart, no crash.
- [ ] Switch Space → piles of windows not on this Space disappear.
- [ ] Unit test: window ledge split across two screen frames; share by area.

## Implementation

- stacked on: wa/add-clear-snow @ 1ec7bcf.
- `SnowScreen` (displayID, frame, scale), `ScreenWatching` / `NSScreenWatch` (initial + didChangeScreenParameters). `OverlayController` keeps (screen, overlay) pairs: hidden / shown / closing; unchanged screens keep their piles, removed closed, new added; drain, resume, clear apply to all.
- Shared `WindowTracker` + `DockWatch` (`SurfaceTracking`) started once by the controller, stopped when last overlay closes.
- `frontToBack` per screen: window ledge on each screen its top overlaps (full width, not cut); Dock only on its screen; ground per screen.
- Space switch: no new code — off-Space windows leave the on-screen list → piles spill.
- Known gap: window hanging from upper screen onto lower doesn't occlude lower screen piles.
- Glossary candidates: `SnowScreen`, `SurfaceTracking`.
- build ✅ · tests ✅ (120). Runtime not checked.

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
### Round 1 — 2026-11-05 (perf, carried from add-window-shake feedback)
- Asked: « ça lag à mort … 100% CPU ».
- Triage: defect (flake landing search every frame × every ledge).
- Changes: flake landings solved at 20 Hz over the elapsed span, `LandingZone` early rejects for flakes and grains, `Landing` in its own file, drift `peak` computed once per frame in the renderer. Debug ≈ 57 % → ≈ 48 %, Release back-to-back ≈ 35 % → ≈ 25 % (machine load higher than earlier 6 % run).
- Review: deferred → /wa-validate. Verify: yours. 125 tests green.
