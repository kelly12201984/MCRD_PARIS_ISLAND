# MCRD_PARIS_ISLAND

A Roblox game simulating USMC recruit training at Marine Corps Recruit Depot
Parris Island. The target is **procedural realism** — the real schedule, the real
drill, real standards and real consequences — not graphical realism.

<img width="639" height="678" alt="image" src="https://github.com/user-attachments/assets/703957b9-3412-4ffa-bacb-d6e04f061881" />

## Status

**Vertical slice: Receiving — the yellow footprints.** Playable end to end.

Fall in on the footprints, then execute drill under a clock: facing movements
(`RIGHT... FACE!`) and call-and-response (`EYES!` → `SNAP, SIR!`). Graded on
correctness *and* speed. Wrong answers earn demerits; three demerits sends you to
the quarterdeck. Twelve commands, then a scoreboard, then again.

Face the wrong way and you *stay* facing the wrong way — so the next command is
harder. That compounding pressure is the design thesis of the whole game.

## Quick start

```bash
rokit install              # get the pinned toolchain (rojo, stylua, selene)
rojo build -o MCRD.rbxl    # generate a place file
rojo serve                 # then Plugins → Rojo → Connect in Studio, and hit Play
```

Never touched Roblox before? → **[docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)**

## Controls

| Key | Action |
|---|---|
| `W A S D` | Walk to the footprints during fall-in |
| `Q` | Left face |
| `E` | Right face |
| `X` | About face |
| `1` `2` `3` | Pick a verbal response |

## Docs

| | |
|---|---|
| [GETTING_STARTED.md](docs/GETTING_STARTED.md) | Toolchain setup, the Roblox mental model, first change |
| [DESIGN.md](docs/DESIGN.md) | What "realistic" should mean, and the roadmap through graduation |
| [QUESTIONS_FOR_YOUR_RECRUIT.md](docs/QUESTIONS_FOR_YOUR_RECRUIT.md) | Structured questions to pin down the design with your son |
| [SETUP.md](SETUP.md) | Alternate no-CLI setup (VS Code Rojo extension) and exporting place snapshots for Claude |
| [CLAUDE.md](CLAUDE.md) | Architecture and conventions |

## Layout

```
src/shared/    ReplicatedStorage.Shared — Config, Types, Remotes, CommandCatalog
src/server/    ServerScriptService.Server — Formation, Recruit, Drill services
src/client/    StarterPlayerScripts.Client — HUD and input
```

Two files are meant to be edited constantly, by anyone, without touching a service:
`src/shared/Config.lua` (every tunable number) and `src/shared/CommandCatalog.lua`
(everything the drill instructor says). Start there.
