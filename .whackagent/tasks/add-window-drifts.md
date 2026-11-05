---
title: Add window drifts
summary: snow piles on window top edges
size: medium
type: feature
sprint: Snow drifts
blocked_by: [add-falling-snowflakes, add-window-ledge-tracking]
status: done
wiki: "[[pitch]]"
note: "SnowDrift per window: height per column, capacity, rounded corners, flake landing (CPU solves same path). Drift shader: slope light, depth tint, sparkles."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- `SnowDrift` per window ledge (keyed by window id): heights per column (column width 2 pt), `bed`, `capacity` per column tapering at both ends (rounded window corners: 0 over cornerRadius, ramp to full over ~16 pt), max depth ~14 pt.
- Landing: when a flake spawns, CPU solves where its analytic path first crosses a ledge top (window top edge minus current height) not covered by a window in front → schedules `landing (drift, x, time)`; at that time the flake is retired and its volume (∝ size²) added to the column + neighbours. Same path math as shader (#3).
- Settle: slump between neighbours when slope > ~1 (angle of repose), overflow past capacity at ends → snow lost (grains come in #8).
- Window moved (from #4 changes): drift translates with the window (spring polish = #9). Window closed → drift removed.
- Render: own drift shader — one quad per drift, heights buffer, AA edge, normal from slope → lighting, deeper = bluer, fine grain noise, rare twinkles.
- Lives in `Core/Simulation/` (`SnowField` owns flakes + drifts) and `Core/Rendering/`.
- Occlusion by front windows = #6 (this task may draw piles under front windows).

## Acceptance criteria

- [ ] Snow accumulates on the top edge of app windows, thicker over time, tapering at rounded corners.
- [ ] Drift tops are smooth and rounded, no sharp peaks.
- [ ] Drifts grow slowly: a window's pile takes minutes, not seconds, to fill.
- [ ] Resizing a window keeps its snow where it lies on screen; the snow that no longer fits (columns past the new edges, or above the new capacity near the corners) falls as grains.
- [ ] Piles look lit: bright top, blue-grey depth, faint twinkle.
- [ ] Moving a window carries its pile; closing it removes the pile.
- [ ] Flakes that hit a ledge stop there (no flake falls through a pile).
- [ ] Unit tests: landing solver (flake path vs ledge), deposit + slump keep total volume, capacity taper.

## Implementation

- stacked on: wa/add-falling-snowflakes @ 21103ff + merge wa/add-window-ledge-tracking.
- `SnowDrift` (2 pt columns, capacity 0 over cornerRadius → 14 pt over 16 pt, deposit 2·size² split ½/¼/¼, slump at repose 1, overflow lost, translate/resize). `bed` dropped (YAGNI).
- Landing solved each frame on the shared analytic path (bisection, 12 steps) — deviation from "scheduled at spawn": wind is a random walk, so future x unknowable. Covered ledge tops skipped. Landed flakes reborn above.
- Drift pipeline: quad per drift, heights buffer per frame, slope lighting, blue depth, crust, grain, ~0.8 % twinkles. `SnowDriftUniforms` layout tested.
- `WindowTracker` wired: start on overlay show, stop on close; surfaces read each frame (z-order matters), global → overlay coords.
- Runtime: screen locked during run → not checked. Orchestrator: `snowDriftVertex/Fragment` present in built metallib.
- build ✅ · tests ✅ (61, 18 new).

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

### Round 1 — 2026-11-05 (via /wa-feedback, on add-window-shake)
- Asked: « la neige fait pas mal de pics. Est-ce qu'on pourrait arrondir plus pour une forme plus smooth ? » (screenshot: jagged peaks).
- Triage: adjustment. Criterion added: "Drift tops are smooth and rounded, no sharp peaks."
- Changes (inline + Overhang moved to its own file for file_length): deposit spread as a tent over 2–24 columns (radius √(area/2)), angle of repose 1 → 0.5, 3 smoothing passes (0.3) near the landing. Test `scattered snow piles into a smooth surface, no spikes`: interior roughness 1.89 pt before → < 0.25 pt after.
- Review: deferred → /wa-validate. Verify: manual — not run by agent, run: yours.

### Round 2 — 2026-11-05 (via /wa-feedback, on add-window-shake)
- Asked: « je trouve que la neige grossit un peu trop vite. Ce serait bien que ce soit un peu plus lent ».
- Triage: adjustment. Criterion added: drifts grow slowly.
- Changes (inline): `SnowField.packing` 2 → 1.1 → ~45 % slower; grains ~35 % larger for the same area.
- Review: deferred → /wa-validate. Verify: manual — not run by agent, run: yours.

### Round 3 — 2026-11-05 (via /wa-feedback, on add-window-shake)
- Asked: « quand je resize une fenêtre, la neige diminue mais ne tombe pas ».
- Triage: adjustment. Criterion added: resize keeps snow in place, what no longer fits falls.
- Changes (implementer): `SnowDrift.move(onto:)` returns spills, columns re-mapped by screen x (shift = round(Δleft / columnWidth)), cut columns + excess over new capacity spill; `SnowField.surfaces` releases them with `from: surface.id`. Review note: release happens inside the `surfaces.enumerated().map` closure (type_body_length budget).
- Review: deferred → /wa-validate. Verify: manual — not run by agent, run: yours. 104 tests green.

