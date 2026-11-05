---
title: Add Clear snow
summary: menu empties piles, stop melts them
size: quickwin
type: feature
sprint: Comfort
blocked_by: [add-cursor-sweep]
status: done
wiki: "[[pitch]]"
note: "Clear snow → every drift sheds as grains. Toggle off → no new flakes, piles melt."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- `Clear snow` menu item enabled when snowing; action → every drift spills fully as grains (they fall off-screen past the ground: ground drift also emptied, its grains removed).
- Toggle off: no new flakes, in-flight flakes fall out, piles melt (height decreases ~2 pt/s) then overlay closes once empty.
- Quit → immediate close, no animation.

## Acceptance criteria

- [ ] `Clear snow` (menu) → all piles fall away within ~2 s; snow keeps falling.
- [ ] `Clear snow` disabled when snow is off.
- [ ] Toggle off → flakes stop spawning, piles melt, overlay disappears when empty.
- [ ] Unit test: clear leaves every drift empty; melt reaches zero.

## Implementation

- stacked on: wa/add-cursor-sweep @ 62db79e.
- `SnowStore.clearRequests: AsyncStream<Void>`; `OverlayController` follows snowing + clear requests (`async let`), forwards clear only while shown and not closing. Chain → `SnowOverlay` → `SnowLoop` → `SnowField.clear()`.
- Clear: every drift (ground too) → grains marked `lands = false`, fall off-screen; flakes keep falling. Menu `canClearSnow = isSnowing`.
- Stop: drifts melt 2 pt/s alongside in-flight flakes; `isEmpty` waits for drifts too → overlay closes when all gone.
- Flake path math moved to `SnowFlake.position(at:wind:width:)` (SnowField near lint body limit, ~247/250).
- build ✅ · tests ✅. Runtime not checked.

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