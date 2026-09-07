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
| `src/shared/` | `ReplicatedStorage.Shared` (Folder) | Config, Types, Remotes, CommandCatalog, RankCatalog, MapInventory |
| `src/server/` | `ServerScriptService.Server` (Script) | `init.server.lua` is the entry point |
| `src/client/` | `StarterPlayerScripts.Client` (LocalScript) | `init.client.lua` is the entry point |

A folder containing `init.server.lua` / `init.client.lua` becomes a *Script* in Roblox,
with its siblings as children. That's why services are required as `script.FormationService`
from the entry point and `script.Parent.FormationService` from a sibling.

Server services: Formation (the spots), Spawn (bus stop vs town), Recruit (per-session
state), Division (teams), Progression (XP, rank, DataStore persistence), Overhead (the
nametag), Drill (the loop).

## The map is the player's, the code finds it by tags

The place is a large hand-built map full of unnamed models. Code never searches it by
name; it uses CollectionService tags (`FormationSpot`, `FormationFront`, `BusStop`,
`TownSpawn`) that are applied in Studio. `docs/HOW_IT_WORKS.md` lists them and holds the
design as the owners describe it. Generated geometry (the yellow practice grid) exists
only as a fallback for an empty baseplate.

## Conventions

- **`--!strict` at the top of every Luau file.** It catches real bugs at author time.
- **No magic numbers in service code.** Every tunable lives in `src/shared/Config.lua`.
  Playtesting is mostly "make this number bigger", so keep that a one-line edit.
- **Shared types in `src/shared/Types.lua`.** Both sides must agree on remote payload shapes.
- **The server is the only authority.** Clients send *inputs*, never scores, never
  "I was correct", never their own timing. Anything the client is trusted with will
  eventually be exploited.
- **Behavior and UI are built in code, not authored in Studio.** The world itself is
  authored in Studio by the owners; code attaches to it through tags.
- **Content lives in data, not logic.** `CommandCatalog.lua` and `RankCatalog.lua` are
  pure data so they can be edited without touching a service.
- **Persistence never overwrites what it could not read.** A DataStore load failure
  marks the record unsaveable for that session. See `ProgressionService`.

## Current state

Vertical slice: Receiving — fall in on the formation, then one loop of
`Waiting → FallIn → Drill → Debrief`, with facing movements and call-and-response
graded on correctness and speed. Each session banks XP into a persistent service
record; rank is earned from XP (`RankCatalog`) and shown on the overhead tag.
See `docs/DESIGN.md` for the roadmap and `docs/HOW_IT_WORKS.md` for the intended
player journey and open questions.

## Tone

Drill instructor dialogue is authentic-flavored but PG — this is built by a parent
and a kid together, and it ships on a platform with a young audience. Intensity comes
from time pressure and standards, not from profanity.
