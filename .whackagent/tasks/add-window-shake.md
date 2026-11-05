---
title: Add window shake
summary: moved or shaken window sheds snow
size: medium
type: feature
sprint: Snow physics
blocked_by: [add-falling-grains]
status: done
wiki: "[[pitch]]"
note: "Drift follows window with spring (offset, offsetVelocity), shake = swing reversals → spill at ends, closed window → all falls."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- Drift follows its window with a spring: `offset`, `offsetVelocity` (pile lags then catches up, slight lean opposite to motion).
- Shake = ≥ 3 horizontal direction reversals within 0.8 s with speed > 250 pt/s (`swingDirection`, `swingPeak`) → spill a fraction per swing, growing with agitation, from the leading end.
- Sharp jolt (|acceleration| above ~6000 pt/s² from polled frames) → partial spill even without shake. Moving up fast → snow slides off the back.
- Window closed or minimized → whole pile falls as grains from where it was.
- Inputs from #4 `WindowChanges` at 60 Hz; acceleration from successive frames.

## Acceptance criteria

- [ ] Dragging a window slowly carries its pile, which lags a little and leans.
- [ ] Shaking a window left-right sheds snow as falling clumps; enough shaking empties it.
- [ ] Closing or minimizing a snowy window drops its whole pile.
- [ ] Unit tests: shake detector (reversal count/window), spring converges, close → full spill.

## Implementation

- stacked on: wa/add-falling-grains @ 120df3a.
- `DriftMotion` (critically damped spring ω 18, lag ≤ 6 pt, velocity measured on real moves, smoothed τ 0.05 s), `SwingDetector` (≥ 3 reversals / 0.8 s > 250 pt/s), `Shake` (share + impulse).
- Shed: per reversal min(0.03·(n−2), 0.15) from leading end; jolt > 6000 pt/s² → 15 % (0.5 s cooldown); lift > 1500 pt/s → 15 % each end. Spills placed past the end (no fall-back).
- Surface gone (close, minimize, other Space/screen, Dock autohide) → whole pile spills.
- Shader: drift lean via `offset` (uniforms 8 floats, tested).
- Constants guessed , `static let` in `DriftMotion`.
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

### Round 1 — 2026-11-05
- Asked: « le shake de la fenêtre ne semble pas fonctionner. Ou alors c'est juste parce que ça lag trop » + « ça lag à mort, 100% CPU ».
- Triage: defect (first shake threw 3 % from one end → invisible; snow re-landed on its own pile) · defect (perf, see add-falling-grains round 1).
- Changes: first shake 25 % of a full drift, +10 %/reversal, cap 60 %; jolt 25 %; swingSpeed 200 pt/s, memory 1.0 s; `shed` takes from every column proportionally; `Grain.origin` → shaken snow skips its own pile. Implementation notes above (3 %, 15 %, 250 pt/s, 0.8 s, end-first) superseded.
- Review: deferred → /wa-validate. Verify: round 1 manual validation — not run by agent, run: yours. 97 tests green.

