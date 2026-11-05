---
title: Add snow overlay
summary: transparent Metal panel above all windows
size: medium
type: feature
sprint: Walking skeleton
blocked_by: [add-menu-bar-toggle]
status: done
wiki: "[[pitch]]"
note: "NSPanel per main screen: borderless, clear, ignoresMouseEvents, above windows, all Spaces. CAMetalLayer + CAMetalDisplayLink (SnowScreen/SnowLoop). Shown when on."
created: 2026-11-04
---

## Context / Decisions

- Grill self-answered by Claude (autopilot).
- Setup: `NSPanel(contentRect: screen.frame, styleMask: [.nonactivatingPanel] (borderless), backing: .buffered, defer: false)`; `hidesOnDeactivate = false`; `level = .statusBar`; `collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]`; `ignoresMouseEvents = true`; `isOpaque = false`; `backgroundColor = .clear`; `hasShadow = false`; `isReleasedWhenClosed = false`; `animationBehavior = .none`; `orderFrontRegardless()`.
- Content: layer-hosting `NSView` (`layer = CAMetalLayer` set before `wantsLayer = true`). Layer: `pixelFormat .bgra8Unorm`, `isOpaque = false`, `drawableSize` = frame × backing scale, `framebufferOnly = true`.
- Loop: `CAMetalDisplayLink(metalLayer:)`, delegate, `preferredFrameRateRange` 60/60/60, `preferredFrameLatency = 2`, added to a run loop. Each frame clears to transparent and presents (no snow yet).
- v1 this task: main screen only (`NSScreen.main`). Multi-screen = #12.
- Lives in `Core/Overlay/`: `SnowOverlay` (one panel + layer + loop for one screen), `OverlayController` (shows/hides per `SnowStore.isSnowing`), `SnowLoop` (display link wrapper). `Core/Rendering/SnowRenderer` owns `MTLDevice`, command queue; protocol `SnowRendering` injected so the loop is testable.
- `SnowStore.isSnowing` on → overlay ordered front; off → overlay closed, loop stopped.
- Concurrency: display-link callbacks off the main actor; renderer state isolated (lock or actor-free `Sendable` snapshot). Decide in code, no `@unchecked` without a comment-free justification in `NOTES:`.

## Acceptance criteria

- [ ] Toggle on → a click-through transparent panel covers the main screen (clicks reach apps beneath, nothing visible yet).
- [ ] Panel stays above normal windows and follows to every Space and over fullscreen apps.
- [ ] Toggle off → panel gone, display link stopped (no CPU spin in Activity Monitor).
- [ ] Toggle state on at launch → panel shown at launch.
- [ ] Unit test: `OverlayController` shows/hides overlays as `isSnowing` flips (mock overlay factory).

## Implementation

- `Core/Overlay/`: `Overlay` protocol, `SnowOverlay` (NSPanel config: nonactivating, `.statusBar`, behavior 0x151, click-through, clear), `SnowLoop` (CAMetalDisplayLink 60 Hz, latency 2, RunLoop.main `.common`), `OverlayFactory`/`SnowOverlayFactory` (main screen), `OverlayController` (`run()` over `Observations { isSnowing }`, new overlay each start).
- `Core/Rendering/`: `SnowRendering: Sendable`, `SnowRenderer` (failable init, clears transparent + presents).
- `SnowApp` wires store + renderer + controller task.
- Concurrency: display link callbacks on main thread (no lock, no `@unchecked`). Dedicated render thread deferred.
- lldb check: panel level 25, behavior 0x151, ignoresMouseEvents, 2560×1440, CPU ~0.5 %.
- build ✅ · tests ✅ (6).

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