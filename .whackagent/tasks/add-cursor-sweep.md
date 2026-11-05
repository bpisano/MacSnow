---
title: Add cursor sweep
summary: pointer sweeps snow off piles
size: quickwin
type: feature
sprint: Snow physics
blocked_by: [add-window-shake]
status: done
wiki: "[[pitch]]"
note: "Global mouse position (no clicks captured), fast pass over a drift removes snow → grains + puffs."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- Pointer read each frame via `NSEvent.mouseLocation` (no event tap, no permission, overlay stays click-through).
- Pointer speed > 120 pt/s crossing a drift's surface (within 5 pt above the pile top down to the ledge) → removes ~70 % of the columns under a ~12 pt brush, spills as grains with ~35 % of the pointer velocity plus a lift, spawns puffs.
- Slow hover does nothing.
- Works on window, Dock and ground drifts, not on covered parts.

## Acceptance criteria

- [ ] Fast pass of the pointer over a pile throws snow off in the pointer's direction, with powder.
- [ ] Slow hover over a pile leaves it intact.
- [ ] The hollow a sweep leaves is round at once: slopes to the angle of repose, no sharp steps.
- [ ] Clicks still reach the app under the pile.
- [ ] Unit test: sweep removes snow only around the brush and above speed threshold.

## Implementation

- stacked on: wa/add-window-shake @ 0754d9d.
- `Pointer` (last sample → `Sweep?`), `Sweep` (> 120 pt/s, brush 12 pt, reach 5 pt above snow, share 0.7, carry 0.35, lift 160 pt/s, segment entry test).
- `SnowDrift.sweep(_:)` (covered columns skipped), `SnowField.movePointer(to:)` → grains + one puff per grain. Clumping moved to `Spill.clumps` (lint body length).
- Overlay: `NSEvent.mouseLocation` per frame → overlay coords; panel still click-through.
- Glossary candidates: `Pointer`, `Sweep`.
- build ✅ · tests ✅ (99). Runtime not checked.

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

### Round 1 — 2026-11-05 (via /wa-feedback)
- Asked: « quand je balaye la neige, c'est très anguleux puis ça arrondit les angles. Je voudrais que ce soit de base arrondi directement ».
- Triage: adjustment. Criterion added: sweep hollow round at once; unit-test criterion reworded (around the brush).
- Changes (inline): `SnowDrift.sweep` slumps + smooths (`DriftShape`) the swept columns ±24 right after the sweep. Tests: changed columns stay within brush ±24, centre lowered, slopes ≤ repose (5 % margin: slump not fully converged on a deep hollow).
- Inline hunks: SnowDrift.swift `sweep`, CursorSweepTests.swift.
- Review: deferred → /wa-validate. Verify: manual — not run by agent, run: yours. 110 tests green.

