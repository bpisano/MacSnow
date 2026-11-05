---
title: Hide covered drifts
summary: front windows mask piles behind
size: quickwin
type: feature
sprint: Snow drifts
blocked_by: [add-window-drifts]
status: done
wiki: "[[pitch]]"
note: "Occluder rects of windows in front, discard in drift shader. Ledge covered → snow there drops."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- Occluders = frames of windows in front of a drift's window (z-order from #4). Passed to the drift shader as rects; fragments inside discard.
- Ledge columns covered by a front window take no landings (already partly in #5's solver) — reuse, don't duplicate.
- Column becomes covered while it holds snow → that snow is removed (grains fall in #8; until then it just vanishes).
- Max 16 occluder rects per drift (front-most first).

## Acceptance criteria

- [ ] Window A partly under window B → A's pile is invisible where B covers it, visible elsewhere.
- [ ] Bring A to front → its pile shows again where uncovered; covered snow from before is gone, not frozen.
- [ ] No flake lands on a covered part of a ledge.
- [ ] Unit test: occluder list for a drift = only windows in front, clipped to its ledge.

## Implementation

- stacked on: wa/add-window-drifts @ 66b9d5a.
- `SnowDrift.occluders` (front windows clipped to drift bounds, ≤ 16), `hide(under:)`, single `isCovered(at:)` used by landing too, private `spill()` seam (zeroes covered columns; #8 hook), also after `deposit`.
- Covered = ledge-top point of column inside a front window (no flicker as pile grows).
- Shader: occluder rects (fragment bytes, 16 slots) → discard. `SnowDriftUniforms.occluders` (stride 28, tested).
- build ✅ · tests ✅ (+ OcclusionTests). Runtime not checked (no UI driver).

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