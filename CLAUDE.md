# MCRD_PARIS_ISLAND — project notes for Claude

A Roblox game simulating USMC recruit training. The goal is *procedural* realism —
the schedule, the drill, the standards, the pressure — not graphical realism.

## Toolchain

- **Rojo 7** syncs `src/` into Roblox Studio. `default.project.json` is the mapping.
- **Rokit** pins tool versions (`rokit.toml`). Aftman works too if that's what's installed.
- **StyLua** formats, **Selene** lints. Run both before committing.

```bash
rokit install          # once, per machine
rojo serve             # then hit Connect in the Studio plugin
rojo build -o game.rbxl   # headless build, no Studio needed
selene src             # lint
stylua src             # format
```

## Layout

| Path | Becomes | Notes |
|---|---|---|
| `src/shared/` | `ReplicatedStorage.Shared` (Folder) | Config, Types, Remotes, CommandCatalog |
| `src/server/` | `ServerScriptService.Server` (Script) | `init.server.lua` is the entry point |
| `src/client/` | `StarterPlayerScripts.Client` (LocalScript) | `init.client.lua` is the entry point |

A folder containing `init.server.lua` / `init.client.lua` becomes a *Script* in Roblox,
with its siblings as children. That's why services are required as `script.FormationService`
from the entry point and `script.Parent.FormationService` from a sibling.

## Conventions

- **`--!strict` at the top of every Luau file.** It catches real bugs at author time.
- **No magic numbers in service code.** Every tunable lives in `src/shared/Config.lua`.
  Playtesting is mostly "make this number bigger", so keep that a one-line edit.
- **Shared types in `src/shared/Types.lua`.** Both sides must agree on remote payload shapes.
- **The server is the only authority.** Clients send *inputs*, never scores, never
  "I was correct", never their own timing. Anything the client is trusted with will
  eventually be exploited.
- **World and UI are built in code, not authored in Studio.** A `.rbxl` full of
  hand-placed parts can't be diffed or merged. Once a layout is settled it can move
  into Studio as an asset, but code-first keeps the project reviewable while it's
  changing daily.
- **Content lives in data, not logic.** `CommandCatalog.lua` is pure data so it can be
  edited without touching a service.

## Current state

Vertical slice only: Receiving — the yellow footprints. One loop of
`Waiting → FallIn → Drill → Debrief`, with facing movements and call-and-response
graded on correctness and speed. See `docs/DESIGN.md` for the roadmap beyond this.

## Tone

Drill instructor dialogue is authentic-flavored but PG — this is built by a parent
and a kid together, and it ships on a platform with a young audience. Intensity comes
from time pressure and standards, not from profanity.
