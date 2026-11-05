# Glossary

> whackagent convention module. One word per thing, same word everywhere: UI strings, conversation, tasks, reports, PRs, wiki, code. Yours to edit — every skill and both agents read it. Rules below are plugin text, refreshed by `/wa-update`.

## Rules

- **One thing, one term.** Listed → use it. Never a word from `Never`.
- **Also** = words people say for it. Understand them, never write them.
- **Code** = its name in source. New type, file, variable for it → that name. Existing code named otherwise → never rename unasked.
- **Means** = one line, ≤ 12 words. Detail → `→ [[wiki page]]`.
- **Missing term** → propose the row, add on yes. Never coin a second word for a listed thing.
- Short: what users see or the team argues about. Not a dictionary.
- Review: UI string with a `Never` word → `correctness`. New type or variable off `Code`, or a `Never` word in code → `style`.

## Concepts

Product objects and notions, their states, roles, plans. Users see these: one column per UI language, source first.

| en | fr | Also | Never | Code | Means |
|---|---|---|---|---|---|
| Snowflake | Flocon | flake | | `SnowFlake` | one flake falling, analytic path |
| Drift | Tas | pile, accumulation | | `SnowDrift` | snow pile on a ledge, height per column |
| Ledge | Rebord | surface | | `SnowSurface` | surface catching snow: window top, Dock, ground |
| Grain | Morceau | clump, chunk | | `Grain` | clump falling off a drift |
| Puff | Poudre | powder | | `Puff` | powder cloud on impact or sweep |
| Overlay | Overlay | panel | | `SnowOverlay` | transparent panel per screen, draws the snow |
<!-- | Inbox | mailbox | Messages | `Inbox` | received mail, not archived, all accounts | -->
<!-- | Message | mail | Email | `Message` | one mail. States: Draft, Sent, Pending | -->

## Screens

One precise screen. Team names, in the discussion language. UI projects only.

| Name | Also | Code | Means |
|---|---|---|---|
| Menu bar menu | menu ❄ | `MenuBarCoordinator` | Let it snow, Clear snow, Quit MacSnow |
<!-- | Login screen | login page | `LoginView` | email + password, forgot-password link | -->

## Parts

A named piece of UI, reused or talked about on its own. UI projects only.

| Name | Also | Code | On | Means |
|---|---|---|---|---|
<!-- | Composer | editor | `ComposerView` | Inbox, Thread | writes or replies to a message | -->

## Flows

Screens chained for one goal. Steps name **Screens**. UI projects only.

| Name | Also | Steps | Means |
|---|---|---|---|
| Snow toggle | on/off | ❄ icon → Menu bar menu → Let it snow | start / stop snow |
<!-- | Login flow | sign-in | Welcome → Login screen → 2FA → Inbox | first sign-in, until Inbox | -->
