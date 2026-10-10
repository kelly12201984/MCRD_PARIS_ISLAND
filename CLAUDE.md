# MCRD_PARIS_ISLAND — project notes for Claude

A Roblox game simulating USMC recruit training at MCRD Parris Island. The goal is
*procedural* realism — the schedule, the drill, the standards, the pressure — not
graphical realism.

## Where things stand

**The game was restarted.** Jax (the owner and builder) abandoned the first version
and started a new game in Roblox Studio with the same premise. Its code has **not been
imported yet**, so there is no game code at the repo root right now.

- `legacy/parris-island-v1/` — the first game, archived intact. **Reference only.**
  Do not edit it, and do not sync it into any place: its project file would push the old
  scripts and lighting into whatever place Rojo is connected to. Its `README.md` is a
  reuse catalog: what each module does, what it depends on, and how portable it is.
  When the new game needs something the old one had, copy it *out* of `legacy/` into
  the new code and adapt it there.
- When the new game's code arrives, it gets its own project file and source tree at the
  root. Learn its structure from the code before assuming anything from v1.

## Working with the owners

- **One task at a time.** Finish, push, report, then wait for the next one.
- **Say exactly where to run things.** "Studio" means Roblox Studio, "VS Code" means
  VS Code. Name the window, the menu, and the command.
- Jax owns the game. Design calls are his; when unsure what he intends, ask.

## Toolchain

- **Rojo 7** syncs code from the repo into Roblox Studio (the VS Code Rojo extension
  or the CLI). There is no root project file until the new game is imported.
- **Rokit** pins tool versions (`rokit.toml`). **StyLua** formats, **Selene** lints.

## Rules that carry over from v1

These were learned on the first game and apply to any version of it:

- **The server is the only authority.** Clients send *inputs*, never scores, never
  "I was correct", never their own timing. Anything the client is trusted with will
  eventually be exploited.
- **Persistence never overwrites what it could not read.** If a DataStore load fails,
  that player's record must not be saved that session, or a hiccup wipes their progress.
- **Find map objects by CollectionService tags, not by name.** The map is hand-built in
  Studio and its models are not named for what they are.
- **Tunables in one config module; content (drill commands, ranks) as pure data.**
  Playtesting is mostly "make this number bigger", and Jax can edit data files safely.
- **`--!strict` at the top of every Luau file.**

Whether behavior and UI are built in code (as v1 did) or in Studio is an open question
for the new game. Follow whatever the new code does.

## Tone

Drill instructor dialogue is authentic-flavored but PG — this is built by a parent
and a kid together, and it ships on a platform with a young audience. Intensity comes
from time pressure and standards, not from profanity.
