# Parris Island v1 — archived

The first version of the game, built in September 2026. It was archived on
2026-10-10 when Jax started over with the same premise. Everything is here exactly
as it was, plus a guide to what's worth bringing into the new game.

**Reference only.** Don't edit these files, and don't sync them into a game. To
reuse something, copy it out of here into the new game's code and adapt it there.

> **Never pick `parris-island-v1.project.json` in Rojo while the new game is open.**
> It would push every old script, plus its Lighting and Workspace settings, into the
> new game. To see v1 run again, open a brand-new Baseplate in Studio first, then
> connect Rojo to that.

## ⚠️ The place file contains malware

`place/parris_island.rbxl` is the snapshot of the old map from 2026-09-05. It still
contains the backdoors that came in with free Toolbox models:

- copies of the self-spreading **"Anti-Lag"** worm script
- three pickup-truck seat scripts (`DriveSeat.Pickup`) that secretly `require()` code
  from someone else's Roblox assets (`5246683085` and `5402888879`), hidden after a
  fake `--[[ Last synced` comment
- two "duke usmc" hat scripts (`HatScript`) that do the same through an obfuscated
  `getfenv()[...]` call (`5151855975`)

They were cleaned up in Studio, but the cleaned map was never saved back into this
file. (Confirmed by decoding the file on 2026-10-10.) So:

- **Don't publish it and don't press Play in it.**
- **Don't copy models out of it** into the new game without scanning them first.
- **Jax's new game was built the same way**, so it may have picked up the same kits.
  Scan it before building on it (step 0 below).

## What's here

| File | What it is | Reuse |
|---|---|---|
| `src/shared/CommandCatalog.lua` | Everything the drill instructor says: commands, answers, barks | **drop-in** (with `Types`) — remove the `kill` entry first, it isn't PG |
| `src/shared/RankCatalog.lua` | The rank ladder, E-1 Private to E-9 MGySgt, with XP thresholds and chevrons | **drop-in** (with `Types`) |
| `src/shared/Types.lua` | Shapes of the data passed between server and client | **drop-in** — type-only, does nothing at runtime |
| `src/shared/MapInventory.lua` | Studio tool: prints what's in the map, with positions and sizes | **drop-in** |
| `src/server/FormationService.lua` | Finds the tagged formation boxes, lays out standing spots, tracks who holds which | **adapt** — the most portable server code |
| `src/server/ProgressionService.lua` | Saves XP to Roblox DataStores and works out rank from it | **adapt** — fix the save weaknesses first |
| `src/server/OverheadService.lua` | The nametag over each head: chevron, name, rank, division | **adapt** — point it at the new game's rank source |
| `src/server/SpawnService.lua` | Recruits spawn at the bus stop, everyone else in town | **adapt** |
| `src/server/DivisionService.lua` | Division = Roblox Team; stops Roblox auto-assigning teams | **adapt** — imposes place-wide team rules |
| `src/server/RecruitService.lua` | Per-player score, demerits, streak during a drill | **adapt** |
| `src/shared/Config.lua` | Every tunable number, one section per system | **adapt** — copy only the sections you need |
| `src/shared/Remotes.lua` | Creates the server↔client message channels | **adapt** |
| `src/client/DrillHud.lua` | The drill's on-screen display, built in code | **adapt** |
| `src/client/init.client.lua` | Sends key presses to the server | **adapt** — keyboard only |
| `src/shared/SecuritySweep.luau` | Studio tool: finds and removes the malware above | **adapt** — flags *itself* until fixed (see bugs) |
| `src/shared/MapBlockout.luau` | Studio tool: placeholder blocks for real Parris Island landmarks | **adapt** — useful mostly as a landmark list |
| `src/server/DrillService.lua` | The drill loop: fall in → commands → grading → debrief | **reference** — rebuild it, don't copy it |
| `src/server/init.server.lua` | Server start-up order | **reference** |

**drop-in** = copy it and its listed partner and it works. **adapt** = the logic is
good but needs edits to fit another game. **reference** = read it for the approach,
then rebuild.

What has to travel together:

- `CommandCatalog` or `RankCatalog` → needs `Types` next to it.
- `ProgressionService` → `RankCatalog` + `Types` + the `Progression` section of `Config`,
  plus something in the new game that calls `awardSession` (in v1 only the drill did).
- `OverheadService` → `RankCatalog` + `Types` + the `Overhead` section of `Config`, and a
  rank source (`ProgressionService` or the new game's own).
- `FormationService` → the `Formation` section of `Config`, and a caller that claims and
  releases spots.
- `DrillService` → nearly all of the server, the whole client, and `Remotes`. That's why
  it's reference-only.

Full detail on every file — what it needs from the place, what to change, known
issues with line numbers — is in **[CATALOG.md](CATALOG.md)**.

## Order to check for reuse, once the new game is in the repo

0. **Scan the new game first.** Before reusing or building anything, check the
   exported `.rbxlx` for the malware above and for remote `require(<number>)` /
   `require(<variable>)`, `getfenv`, `loadstring` and `InsertService:LoadAsset`.
1. **Content: `CommandCatalog` and `RankCatalog`.** No dependencies, Jax owns them, and
   they fit any design. Compare them with the new game's drill lines and ranks.
2. **Saving.** If the new game saves anything, check it against the rules below. If it
   gets published into the *same* Roblox experience as v1, v1's saved data is still
   there under `ServiceRecords_v1` / `player_<UserId>`; pick a new store name on purpose.
3. **Formation**, if the new map has painted formation boxes.
4. **Nametag**, especially if the new place uses a free-model one (`RankUI`,
   `OverHeadUI`, an `OverheadService` from the Toolbox).
5. **Teams and spawns**, only after looking at how the new place sets up Teams, team
   spawns and any autoteam scripts. These two are the likeliest to clash.
6. **Drill loop as a pattern**, only if the new game doesn't have its own. Rebuild it
   and fix the bugs below.

## v1 bugs — don't carry these over

- **Facing errors never compound.** The design says facing the wrong way should make
  every later command harder. It doesn't: grading compares
  `(facing + commandDelta) % 4` with `(facing + inputDelta) % 4`
  (`DrillService.lua:95-96`), and the current facing cancels out. To make errors
  compound, grade against where the whole formation *should* be facing.
- **Incentive training never actually benches anyone.** The 6-second lockout
  (`RecruitService.lua:119-120`) expires before the next command is graded (at least
  2 s pause + 6 s window later). Instead it can swallow a fast answer to the next
  command, which then scores as no response.
- **Every player gets drafted.** Anyone on the server without a spot, including
  walk-ins in town, late joiners and overflow, is marked "left formation" on every
  command (`DrillService.lua:78, 133`).
- **One error stops the drill for good.** The main loop has no error protection
  (`DrillService.lua:290-303`).
- **Not PG.** `CommandCatalog.lua:58-64` ("WHAT MAKES THE GRASS GROW?" / "SIR, BLOOD
  SIR!") breaks the project's tone rule.
- **Keyboard only.** Phone and console players can see commands but can never answer
  (`init.client.lua:83-99`).
- **Saving can lose progress.** No session lock (a quick server-hop can overwrite newer
  data), no retry after a failed load or a failed save on leave
  (`ProgressionService.lua:70-120, 175-180`).
- **Spots aren't released when a recruit dies** (`FormationService` has no death or
  leave handling of its own).
- **`SecuritySweep` flags itself.** Its own header comment (line 19) matches its malware
  pattern (line 28), so `scan()` reports it and `clean()` breaks it. Skip the module
  itself in the loop at line 42 before using it.
- **Answers are always in the same slot.** 3 of 4 call-and-response answers are option
  2, so players can learn the key instead of the response.

## Lessons learned the hard way (from the git history)

- **Scan any place built with Toolbox models** before building on it; keep only the
  cleaned copy. (`2b90ec7`, `da5fd78`)
- **Find map objects by CollectionService tag**, never by world coordinates or names;
  raycast for ground height. Took three tries to learn. (`e322689`, `e428ad8`, `d637046`)
- **Don't put Lighting or Workspace settings in the Rojo project** for a place built in
  Studio: Rojo overwrites the owner's settings every time it connects. v1 made Jax's map
  too dark to build in. (`a8ab656`)
- **Give players time to read.** A 3-second window for a call plus three answers was
  unreadable; 6 seconds works. Tighten only from playtests. (`b8a4191`)
- **Don't start a countdown until someone has reached the objective**, and make the
  objective visible from spawn (the "FALL IN HERE" sign). (`e322689`)
- **A formation box holds several recruits.** Keep capacity and facing as data. (`e044460`)
- **Set every player's spawn yourself** when free models left stray SpawnLocations
  around the map. (`e322689`, `d637046`)
- **If Teams mean something, turn off AutoAssignable on every Team** and clear teams
  Roblox assigned before your script ran. (`705fced`, `2b56e1d`)
- **Replace each free-model system with one you own**, and test joining with an account
  that isn't in the Roblox group. (`43258ba`, `705fced`, `3e95a1d`)
- **Size things attached to avatars in studs, not pixels**, and copy a known-good
  template's numbers instead of tuning by eye. (`2b56e1d`, `3b0ac77`)
- **Lines that can be hidden need fixed positions**, not a UIListLayout, or the others
  jump around. (`3b0ac77`)
- **Parent a BillboardGui to the part it floats over** (the Head), not to the
  character. (`d15ba86`)
- **Save what was earned (XP), work out rank on load, and never save a record that
  failed to load.** Changing the rank ladder then needs no data migration. (`3e95a1d`)
- **Upload files through git, not GitHub's web upload.** A web upload once dropped a
  full duplicate of the repo, place file included, into `docs/`. (`71049f1`, `4e28250`)

## Worth keeping even if no code is reused

- **Jax's player journey** — [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md). Walk-ins in
  town, recruitment by another player, the bus stop, a player Drill Instructor billet
  with an automatic DI as backup, rank from XP and never from a Roblox group, division
  as a Team. It's the only written record of his design, plus six open questions for
  him. (Its "Built so far" list overstates: the quarterdeck didn't really work.)
- **The rank ladder** and **drill content** in the two catalog files.
- **Playtest-tuned numbers** in `Config.lua`: 6 s response window, 2–3.5 s pauses,
  25 s fall-in that starts only once someone arrives, nametag 4×3 studs, 1.6 above the head.
- **The old place's 8 divisions (Teams):** Headquarters, 1st Marine Division, Military
  Police, Office of the Inspector General, Officer Candidates School, Recruit Training,
  Marine Personnel, Training & Education Command.
- **Free-model kits the old place used**, to look out for in the new one: Autoteam,
  RankUI / OverHeadUI / an OverheadService, Adonis_Loader, ACS_Engine, iTransit,
  GamepassScriptV2, Group Rank Tools, Team Only Gear, the AtEase/Salute tools, the
  "duke usmc" gear and the GMC/Chevy trucks.
- **Real landmark list** — `MapBlockout.luau` lines 31-45: 13 real Parris Island
  landmarks with rough sizes and placement.
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) — the "mental model" section on how
  Roblox works is still good. Its description of the play loop overstates what v1 did.
