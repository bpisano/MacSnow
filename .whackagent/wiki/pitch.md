# Pitch — MacSnow

App macOS menu bar, pour moi : de la neige tombe sur l'écran et s'accumule sur les fenêtres et le Dock.

## Problem

- Projet perso, fun : ambiance hivernale sur le bureau, la neige tombe et s'accumule sur les fenêtres.

## Core loop

- Clic sur l'icône ❄ menu bar → `Let it snow` → la neige tombe et s'accumule.
- Re-clic → arrêt : plus de flocons, les tas fondent.

## v1

- Menu bar — icône ❄ (pleine si actif), menu `Let it snow` · `Clear snow` · `Quit MacSnow`.
- Overlay — `NSPanel` transparent par écran, au-dessus de tout, clics traversants.
- Chute — flocons à trajectoire analytique (balancement, vent), rendu Metal avec flou de mouvement.
- Tas sur fenêtres — neige posée sur le bord haut de chaque fenêtre, masquée par les fenêtres devant.
- Tas sur Dock et sol — neige sur le Dock et le bas de l'écran.
- Fenêtre bougée — le tas suit en ressort ; secousse, fermeture ou fenêtre couverte → la neige tombe en morceaux.
- Curseur — le pointeur balaie les tas, morceaux + poudre.
- Multi-écran — un overlay par écran, suit les Spaces.

## Screens

- Menu bar menu — toggle `Let it snow`, `Clear snow`, `Quit MacSnow`.
- Overlay — pas d'UI, que la neige.

## Data

- `UserDefaults` : on/off seul, repris au relancement.
- Tas en mémoire, perdus à l'arrêt. Aucun compte, aucun réseau.

## Stack

- macOS 26+, Swift 6, Xcode 27.
- SwiftUI `MenuBarExtra`, `LSUIElement` (pas d'icône Dock).
- AppKit `NSPanel` + `CAMetalLayer`, `CAMetalDisplayLink`, shaders `.metal` compilés au build.
- Fenêtres : `CGWindowListCopyWindowInfo` (polling). Dock : Accessibility (`AXUIElement`).
- Architecture `architecture-app.md` :

```
MacSnow/
├─ MacSnowApp.swift       MenuBarExtra
├─ Coordinators/MenuBar/  menu + toggle
├─ Core/
│  ├─ Stores/Snow/        SnowStore (on/off, clear)
│  ├─ Windows/            CGWindowList poll, Dock rect
│  ├─ Overlay/            NSPanel par écran, display link
│  ├─ Simulation/         flocons, tas, grains, curseur
│  └─ Rendering/          renderer Metal + Snow.metal
├─ Resources/             Assets, Localizable.xcstrings (en, fr)
└─ Utils/Extensions/
```

## Out of scope

- Autres météos : pluie, feuilles, lucioles, étoiles.
- Réglages : densité, vent, lancement au login.
- Distribution : App Store, notarisation, mises à jour auto, onboarding.
- Neige sur la barre de menus ou la notch.

## Later

- Réglages densité / vent dans le menu.
- Lancement au login.

## Preview

- [pitch](protos/pitch.html) · https://claude.ai/artifact/KK6u4yTDaY7QoJqt24AWsD
