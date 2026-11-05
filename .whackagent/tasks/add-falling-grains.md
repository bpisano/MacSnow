---
title: Add falling grains
summary: clumps and powder puffs fall off
size: medium
type: feature
sprint: Snow physics
blocked_by: [add-dock-and-ground-drifts]
status: done
wiki: "[[pitch]]"
note: "Grains (lumpy sprites, gravity, land back on drifts) + Puffs (fading powder)."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- `Grain` (position, velocity, area, size, lump) and `Puff` (position, velocity, size, alpha, life, age) in `SnowField`, simulated on CPU (gravity ~900 pt/s², air drag), uploaded each frame as sprites.
- Spill API: `SnowField.spill(from drift, columns, impulse)` turns height into grains (volume conserved). Used by overflow at ledge ends (#5), covered snow (#6), shake (#9), sweep (#10), clear (#11).
- Grains land back on ledges below (same landing test) and deposit their volume; hard landing → small puff.
- Render via the sprite path of #3's shader with a `lump` variant: irregular outline (3rd/5th harmonics), directional shading. Puffs = soft fading discs.
- Wire existing losses: overflow at ends and covered snow now spill as grains instead of vanishing.

## Acceptance criteria

- [ ] Snow breaking off a drift's ends is occasional: a full pile takes in less and less falling snow, and what still overflows gathers at its ends and breaks off in irregular chunks (a few grains of mixed sizes falling together), never a steady trickle.
- [ ] After a chunk breaks off a drift's end, that end rests a while (15–45 s, varying) before another can fall; snow overflowing meanwhile melts away instead of building up.
- [ ] Bringing a window over another's pile makes the covered snow fall as clumps.
- [ ] Clumps hitting a pile hard puff a little powder.
- [ ] Unit tests: spill conserves volume; grain lands on lower ledge and deposits.

## Implementation

- stacked on: wa/add-dock-and-ground-drifts @ 9278b72.
- `Grain`, `Puff`, `Spill` models; `SnowField.spill(from:columns:impulse:)`; deposit/hide/spill return `[Spill]` (volume conserved). Overflow spills past nearest end; covered snow spills per column; clumps ≥ 16 pt² merged within 6 pt.
- Grains: gravity 900, drag 1.2/s, Euler (dt ≤ 0.1 s), land via shared `landing(of:path:from:to:)`; > 200 pt/s → puff. Caps 2000 grains / 400 puffs (oldest dropped).
- `SnowDrift.crossing`: path starting inside snow lands at start (fixes grains falling through raised neighbours; also affects flakes).
- Rendering: `snowSpriteVertex` + per-frame `SnowSprite` buffer (24 B, tested); shared fragment gained `lump`/`turn` (irregular outline + shading). Order: drifts, grains/puffs, flakes.
- Known loss: resize past capacity still clips without spill.
- Glossary candidate: `Spill`.
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

### Round 1 — 2026-11-05 (via /wa-feedback on add-window-shake)
- Asked: « on dirait de l'eau qui coule… la neige tombe plus en tas de manière moins uniforme » + « ça lag à mort, 100% CPU ».
- Triage: adjustment (overflow → chunks, criterion replaced) · defect (deposit full-width slump per flake).
- Changes: local deposit window (±24 columns), per-end overhang released at 24–48 pt², spills > clumpArea crumble into 3–6 mixed grains.
- Review: deferred → /wa-validate. Verify: manual — not run by agent. Release CPU ≈ 11–12 % → ≈ 6 %.

### Round 2 — 2026-11-05 (via /wa-feedback)
- Asked: « ça tombe toujours trop fréquemment sur le côté des fenêtres. Ça doit vraiment être occasionnel le fait que ça tombe ».
- Triage: adjustment (criterion updated: overflow occasional).
- Changes (inline): `SnowDrift.room(at:)`; a landing flake adds its snow × (1 − column height / capacity), none on a full column or over a corner. Grains still pile their whole snow. Test `a filling column takes less of a flake's snow, none once full`.
- Inline hunks: SnowDrift.swift `room(at:)`, SnowField.swift flake deposit.
- Review: deferred → /wa-validate. Verify: round 2 manual validation — not run by agent, run: yours. 98 tests green on add-window-shake.

### Round 3 — 2026-11-05 (via /wa-feedback, on add-window-shake)
- Asked: « il faut un système de debounce pour la neige qui tombe … une fenêtre tout en haut de l'écran … ça tombe régulièrement c'est distrayant … cancel si le dernier fall était trop récent ».
- Triage: adjustment. Criterion added: end rests 15–45 s after a chunk, overflow meanwhile melts.
- Changes (implementer): `Overhang.gather(_:at:)` with `restsUntil` (15 + 30 × phase s), excess past one chunk discarded while resting; `SnowDrift` clock from `sway(to:)`. Forced drops (shake, emptied end, leaving, clear) not debounced. 2 tests added, 1 adapted.
- Review: deferred → /wa-validate. Verify: manual — not run by agent, run: yours. 101 tests green.

