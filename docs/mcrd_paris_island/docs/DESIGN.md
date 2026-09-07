# Design Notes

## The premise

Marine Corps recruit training at MCRD Parris Island, simulated procedurally. The
fantasy the player is buying is **being processed by a system that does not care who
you are** — and then earning your way out of it.

> **Note on the name:** the real depot is **Parris Island** (two R's). The repo is
> currently `MCRD_PARIS_ISLAND`. Worth fixing early if the goal is realism — renaming
> a GitHub repo is painless now and annoying later once links exist.

## What "realistic" should mean here

Your son said realistic. That word can mean four completely different games, and
which one he means determines basically every decision downstream. Ask him (see
`QUESTIONS_FOR_YOUR_RECRUIT.md`), but here's the map:

| Reading | What it actually is | Feasible? |
|---|---|---|
| **Procedural realism** | The real 13-week schedule, real drill commands, real standards and consequences | Yes — this is what the slice does, and it's the strongest version |
| **Simulation depth** | Stamina, sleep, injury, marksmanship ballistics, squad cohesion modeled as systems | Yes, incrementally, on top of the above |
| **Graphical realism** | Photoreal uniforms, faces, terrain | No — fighting the platform, and it's not where the fun is |
| **Harshness** | Authentic DI language and hazing | No — Roblox moderation will remove it, and it isn't the interesting part |

The first two are where the game lives. The pressure should come from **the clock, the
standard, and the fact that everyone else is watching** — not from shock value.

## Why drill is the right vertical slice

Close order drill is the perfect first mechanic, and not by accident:

- **It's a real skill with a real fail state.** You can be objectively out of step.
- **Errors compound.** Face the wrong way and every subsequent command is harder. That
  produces the panic loop that boot camp actually feels like, for free.
- **It's multiplayer-native.** A formation where one recruit is visibly wrong is
  instantly readable and instantly funny/tense to everyone else.
- **It needs no art.** Two colors and a timer and it works.

If drill isn't fun, no amount of rifle qualification or Crucible will save the game.
So prove it first.

## Roadmap

Ordered by *what teaches you the most per hour*, not by chronology in the real depot.

### Phase 0 — Receiving *(done: vertical slice)*
Yellow footprints, fall in, facing movements, call-and-response, demerits, incentive
training, scoreboard.

### Phase 1 — Make drill deep
- Marching, not just facing: `FORWARD MARCH`, `COLUMN RIGHT`, `TO THE REAR`, `HALT`.
- Cadence. A tempo you must stay on step with, rather than discrete prompts.
- A DI NPC that actually walks the formation and stops in front of whoever is wrong.
- Squad scoring — the whole platoon is punished for one recruit. This is the single
  highest-value social mechanic in the entire design.

### Phase 2 — The schedule
Persistence and progression. This is where it becomes a *game* and not a minigame.
- Training days that advance. Save with `DataStoreService`.
- Real events on real days: IST, confidence course, MCMAP belts, swim qual, gas
  chamber, Grass Week, Table 1 & 2 qualification, Basic Warrior Training.
- A record book: your scores, your demerits, your qualification badges.

### Phase 3 — The Crucible and graduation
- 54-hour culminating event, compressed. Sleep and food as depleting resources.
- Warrior stations as team obstacles requiring genuine coordination.
- The Emblem Ceremony as the payoff. **This is the emotional core of the whole game.**
  Everything before it exists to make this moment land.

### Phase 4 — Social systems
- Persistent platoons. Recruits who started together graduate together.
- Player DIs — graduated players earning the right to run a platoon. Enormous
  retention value, and enormous moderation risk. Design carefully.

## Systems worth deciding early

**Failure.** Can you wash out? Recycling a recruit back a week is thematically perfect
and mechanically brutal. Probably: yes, but only for repeated failure, never a single bad day.

**Session length.** Real boot camp is 13 weeks; a Roblox session is 20 minutes. Decide
the compression ratio now — one training day per session is a clean answer and makes
"come back tomorrow" the retention hook.

**Solo vs. platoon.** The game is dramatically better with 10 recruits on the deck and
dramatically worse if it *requires* 10 to be playable. Everything should degrade
gracefully to one player plus NPC recruits.

## Anti-goals

Things to deliberately not build, so scope doesn't eat the project:

- Combat. This is a *training* game. Adding shooting turns it into every other Roblox
  military game and throws away the only thing that makes it distinctive.
- Photorealism.
- Punishment that isn't recoverable within one session.
- Anything requiring voice chat to function.
