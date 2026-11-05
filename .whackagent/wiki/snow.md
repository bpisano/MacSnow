# Snow — how MacSnow works

How the snow is simulated and drawn, and why. The code is the truth; this page is the shape and the decisions.

## Shape

- **Menu bar** (`Coordinators/MenuBar`, `UI/Views/MenuBar`) — `Let it snow` toggles `SnowStore` (on/off persisted), `Clear snow` asks the overlays to drop everything.
- **Overlay** (`Core/Overlay`) — one transparent, click-through `NSPanel` per screen, above windows, on every Space. `OverlayController` follows screens; each `SnowOverlay` runs a `SnowLoop` on a `CAMetalDisplayLink`.
- **Windows** (`Core/Windows`) — `WindowTracker` polls `CGWindowListCopyWindowInfo` (on-screen, layer 0, front to back); `DockWatch` reads the Dock tile row through Accessibility. Both behind `WindowTracking` / `DockWatching`. Surfaces = Dock (front-most), windows, ground.
- **Simulation** (`Core/Simulation`, `SnowField` per screen) — flakes on closed-form paths, drifts as height-per-column, grains and puffs integrated per frame.
- **Rendering** (`Core/Rendering`, `Snow.metal`) — point-sprite flakes with motion streaks, grains/puffs as lumpy sprites, one shaded quad per drift reading its heights; windows in front clip drifts in the fragment shader.

## Decisions

- **Flakes are analytic.** Position is a closed form of time (`SnowFlake.position`), the same on CPU and GPU, so the buffer is uploaded only when flakes are added or removed. Landings are solved on the CPU against that path, 24 times a second, over the elapsed span.
- **Drifts settle locally.** A deposit spreads as a raised-cosine bump, slumps to a 30° angle of repose and smooths, only near where it landed (`DriftShape`) — the whole-width pass was the 100 % CPU bug.
- **Piles grow slowly and rarely spill.** A column takes in less snow the fuller it is; what still overflows gathers out of sight past an end (`Overhang`) and breaks off as an irregular chunk, then that end rests 15–45 s (overflow meanwhile melts).
- **Motion throws snow.** Shakes (swing reversals), jolts and fast lifts shed part of the pile from every column; knocked-off grains skip their own ledge. Resizing keeps snow where it lies on screen and drops what no longer fits. A fast pointer sweeps a round hollow.
- **Clock rebase.** The field clock is rewound every hour (`SnowField.rewind`) so `Float` time and wind stay precise in a menu-bar app that runs for days.

## Tasks

Sprint Walking skeleton, Snow drifts, Snow physics, Comfort — 12 tasks, all done 2026-11-05 (see `BACKLOG.md`).
