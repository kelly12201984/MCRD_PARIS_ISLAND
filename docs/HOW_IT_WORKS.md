# How the game is supposed to work

A living document. Everything here comes from Jax and Kelly; the code is
built to match it. When something is wrong, fix the doc first and the code
follows.

## The player journey (as Jax describes it)

1. **Walk-ins.** Anyone who joins the game without being recruited spawns
   **in town**. They can look around; nothing is expected of them.
2. **Recruitment.** Another player recruits them. That gives them a division
   and a time to show up. (How recruiting happens in-game is still open --
   see questions below.)
3. **The bus stop.** Recruits spawn at the **bus stop** on the parade deck
   and fall in on the painted formation boxes.
4. **Drill.** A **Drill Instructor** -- a real player who earned the billet
   through a tryout -- runs the drill at the scheduled time. When no DI is
   on duty the automatic DI runs it, so the game is never dead.
5. **Rank.** Every drill session banks XP into the recruit's service record.
   Rank is earned from XP (`src/shared/RankCatalog.lua`) and shown on the
   overhead tag with the real chevron. Rank never comes from a Roblox group.
6. **Division and billet.** Division (1st Battalion, etc.) is the player's
   Team and shows on the tag. Drill Instructor is a *billet*, a job held on
   top of rank -- it will show as its own line. (Billets are not built yet.)

## What the code looks for in the map

Most models in the place are not named for what they are, so the code does
not search by name. It looks for **tags**. Tag a thing in Studio: select it,
Properties panel, scroll to **Tags**, click **+**, type the tag name.

| Tag | Put it on | What happens |
|---|---|---|
| `FormationSpot` | Each painted formation box (the part, or the model if a box is a model) | Becomes a claimable spot. Claimed spots glow yellow. |
| `FormationFront` | The part/model where the DI stands | Recruits face it at "attention". Optional; without it each box's own front is used. |
| `BusStop` | The bus stop | Recruits (players with a division) spawn here. |
| `TownSpawn` | Any part in town | Everyone without a division spawns here. |

With nothing tagged, the game generates a practice grid of yellow pads (at a
part named `FormationOrigin`, or a fixed position) so it still runs on an
empty baseplate. That grid is a development aid, not part of the map.

To see everything in the map with positions and sizes, run this in the
command bar and copy the Output:

```lua
require(game.ReplicatedStorage.Shared.MapInventory).print()
```

## Built so far

- Fall in, facing movements and call-and-response under a clock, grading,
  demerits, quarterdeck, scoreboard (the automatic DI)
- XP, rank ladder, persistence, promotions announced at debrief
- Overhead tag: insignia / username / rank / division
- Formation on the real map via tags; bus stop and town spawns

## Not built yet

- Drill Instructor billet, tryouts, DI-driven sessions
- Recruiting in-game (who can recruit, how it is recorded)
- Divisions assigned by the game (today only `DivisionService.assign()` exists)
- The rest of the schedule: marching, cadence, the range, the Crucible

## Open questions for Jax

1. How does a player get recruited in-game? A recruiter presses something on
   them? A code? A form outside the game?
2. Who can recruit: any DI, any player of a certain rank, or only staff?
3. What can a walk-in do in town before being recruited? Just explore?
4. When a DI runs a drill, do they pick each command, or start a session and
   let the game issue commands while they walk the formation?
5. Does every division use the same parade deck, or does each have its own?
6. What is the very first thing a brand-new recruit should see when they
   spawn at the bus stop?
