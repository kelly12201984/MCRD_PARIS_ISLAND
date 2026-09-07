# Getting Started

Written for someone who can code but has never shipped a Roblox game. Should take
about 30 minutes end to end.

## The mental model

Coming from automation apps, the closest analogy: **Roblox is a distributed
client/server app where the "database" is a live object tree replicated to every
player.**

- The **DataModel** (`game`) is that tree. Services hang off it: `Workspace`,
  `ReplicatedStorage`, `Players`, `ServerScriptService`.
- **Server scripts** run in one trusted process. **LocalScripts** run on each player's
  machine. They talk over **RemoteEvents** — think message queue, not shared memory.
- **Replication is automatic but one-directional in trust.** The server changing
  something in `Workspace` shows up for everyone. A client changing it locally shows
  up for *nobody* — and that's the security model, not a bug.
- The language is **Luau**: Lua 5.1 plus a real gradual type system. `--!strict` is
  worth turning on everywhere.

The single biggest habit to build: **never trust the client.** In this project the
client sends "the player pressed Q" and nothing else. The server decides what that means.

## Why we're not working "in Studio"

Roblox's default workflow is to open Studio and hand-place everything into a binary
`.rbxl` file. That's fine for a solo hobby build and terrible for git — you can't
diff it, you can't merge it, and two people editing at once means someone loses work.

**Rojo** fixes this. It runs a local server that syncs plain `.lua` files on disk into
a running Studio session. So the source of truth is this repo, Studio becomes a
viewer/playtester, and git works normally.

## Setup

### 1. Roblox Studio

Install from <https://create.roblox.com/landing>. Free, Windows/Mac only.

### 2. Rokit (toolchain manager)

Rokit installs pinned versions of Rojo and friends, so your machine and your son's
machine run identical tools. Install it from
<https://github.com/rojo-rbx/rokit>, then in this repo:

```bash
rokit install
```

That reads `rokit.toml` and gives you `rojo`, `stylua`, and `selene`.

(If you already have **Aftman**, the same `[tools]` block works in an `aftman.toml`.)

### 3. The Rojo Studio plugin

```bash
rojo plugin install
```

Then restart Studio. You'll get a Rojo button in the Plugins tab.

### 4. Build and run

First, generate a place file:

```bash
rojo build -o MCRD.rbxl
```

Open `MCRD.rbxl` in Studio. Then, back in the terminal:

```bash
rojo serve
```

In Studio: **Plugins → Rojo → Connect**. Now every save on disk lands in Studio
instantly. Hit **Play** and you should be standing on the receiving deck with a drill
instructor screaming at you.

`MCRD.rbxl` is gitignored on purpose — it's a build artifact, regenerate it any time.

## The play loop you should see

1. You spawn at the back of the deck (`BusDrop`).
2. `GET ON MY YELLOW FOOTPRINTS!` — walk onto any yellow pad. It darkens when claimed.
3. Commands start. Two kinds:
   - **Facing movements** — `RIGHT... FACE!` — press `E` (right), `Q` (left), `X` (about).
     Your character physically turns. Get it wrong and you stay wrong, which makes the
     *next* command harder. That compounding is the point.
   - **Call and response** — `EYES!` — press `1`/`2`/`3` for the right answer.
4. Answer fast for `Crisp` (full points), slow for partial, wrong for a demerit.
5. Three demerits → six seconds of incentive training where your input is ignored.
6. Twelve commands, then a scoreboard, then it runs again.

## Making your first change

Open `src/shared/Config.lua`, set `Drill.ResponseWindow` to `1.5`, save. Rojo pushes
it, hit Play. Suddenly it's brutal. That's the tuning loop — most of game development
is that, over and over.

For a content change, open `src/shared/CommandCatalog.lua` and add a command. It's pure
data; nothing else needs to know.

## Publishing (when you're ready)

In Studio: **File → Publish to Roblox As...**. Set it to Private first — you and your
son can both play it, nobody else. Flip it public only when you actually want an audience.

## Where to look when something breaks

- **Studio Output window** — server `print`s and errors land here. Set
  `Config.Debug.Verbose = true` to see drill phase transitions.
- **Test → Clients and Servers** — run 2 players locally to test the multiplayer path.
  Plenty of bugs only appear with more than one recruit on the deck.
- Rojo says "connected" but nothing changes? You almost certainly opened a different
  `.rbxl` than the one Rojo is serving into. Reconnect.
