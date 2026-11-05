---
title: Add falling snowflakes
summary: flakes fall with sway and motion blur
size: medium
type: feature
sprint: Walking skeleton
blocked_by: [add-snow-overlay]
status: done
wiki: "[[pitch]]"
note: "Analytic flake path (sway 2 harmonics, wind), GPU point sprites, motion-blur streak, own shader."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- Own Metal shader `Core/Rendering/Snow.metal` (compiled at build into the default library).
- Flake model `SnowFlake` (x, top, born, fall, drift, windAtBirth, phase, swayRate, sway, size, alpha, soft, gone) in `Core/Simulation/`. Path is analytic: `y(t)` = top − fall·(age + small periodic term), `x(t)` = x0 + drift·(wind − windAtBirth) + two-harmonic sway; same function in Swift (`SnowField.position(of:at:)`) and shader.
- GPU: one point sprite per flake, instanced from a flake buffer uploaded only when flakes are added/removed; per frame only a uniform (`now`, `wind`, screen size, scale).
- Motion blur: velocity × 1/55 s exposure → short streak, brighter at the head.
- Look: white-blue core (≈ #F6F9FE) to grey-blue edge (≈ #9EABC4), `soft` blurs edge, premultiplied alpha blending.
- Tuning: ~1 flake / 6000 pt² of screen alive at once, size 1–4 pt (15 % large), fall 25–75 pt/s, sway amplitude 6–18 pt/s, swayRate 0.8–1.8 rad/s. Wind: slow random walk −20…20 pt/s. Horizontal wrap across screen width + margin.
- Flakes respawn at top when they leave the bottom (no landing yet — #5).
- Toggle off → stop spawning; existing flakes keep falling out.

## Acceptance criteria

- [ ] Toggle on → flakes fall across the whole screen, swaying, drifting with a slow wind.
- [ ] Fast flakes show a short streak, slow ones a soft dot.
- [ ] Flakes visible over light and dark windows (blue-grey edge).
- [ ] 60 fps, overlay process < 10 % CPU on Apple silicon with default density.
- [ ] Toggle off → no new flakes; the ones in flight fall out, then the overlay closes.
- [ ] Unit tests: `SnowField.position(of:at:)` — known inputs → expected x/y, wrap across width.

## Implementation

- `Core/Simulation/`: `SnowFlake` (`x` → `left`, lint), `Wind` (random walk −20…20 pt/s, wind = distance blown), `SnowField` (analytic `position(of:at:)`, ~1 flake / 6000 pt², spawn spread above top, `gone` bound, drain on stop, injectable RNG).
- `Core/Rendering/Snow.metal` (own shader, point sprites, 1/55 s streak, premultiplied), `SnowUniforms`, renderer pipeline; flake buffer re-uploaded only on add/remove.
- Overlay: drain-then-close on toggle off, resume cancels close. No drain cap (slow flake worst case ~40 s).
- Concurrency: `@preconcurrency CAMetalDisplayLinkDelegate`, main actor, no `@unchecked`.
- Metal Toolchain 27B47 installed (was missing) to compile shader at build.
- Orchestrator check: lldb breakpoint on `SnowRenderer.render` hit → frames driven. CPU ~0.4 %. Look of flakes unverified (screencapture black: no Screen Recording permission).
- build ✅ · tests ✅ (23).

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