# Setup: Rojo + Roblox Studio

One-time setup on the computer that runs Roblox Studio (Windows or Mac).
Takes ~20–30 minutes.

## 1. Install the tools

1. Install **Roblox Studio**: https://create.roblox.com → "Start Creating"
   (your son signs in with his Roblox account — the game publishes under whoever is signed in).
2. Clone this repo on that machine:
   ```
   git clone https://github.com/kelly12201984/mcrd_paris_island.git
   ```
3. Open the repo folder in **VS Code** (or Cursor) and install the extension
   **"Rojo" by evaera** (`evaera.vscode-rojo`).
   - When prompted, let it install the Rojo binary AND the Roblox Studio plugin.
     It handles both — no manual downloads.

## 2. Connect it

1. In VS Code: click **Rojo** in the bottom status bar → select `default.project.json` → server starts.
2. In Roblox Studio: open your place (or create a new Baseplate) →
   **Plugins tab → Rojo → Connect**.
3. You should see the scripts from this repo appear:
   - `ServerScriptService.Server.Welcome`
   - `ReplicatedStorage.Shared.GameConfig`
   - `StarterPlayer.StarterPlayerScripts.Client.Hello`

## 3. Test it

Hit **Play** in Studio and open the Output window (View tab → Output).
You should see:

```
Recruit <name> has arrived at Parris Island!
MCRD Parris Island client loaded. Welcome, recruit.
```

If you see both lines, the pipeline works end to end.

## The rules that keep Claude in the loop

Rojo syncs ONE WAY: repo → Studio. So:

1. **All code is written in the repo** (VS Code files under `src/`), never typed
   into Studio. Studio-side script edits get overwritten and Claude never sees them.
2. **Buildings/terrain are built in Studio** and live in the place file — that's
   fine, they're not code.
3. **Toolbox models with scripts inside:** open the model in Studio's Explorer,
   copy each script's contents into a new file under `src/`, and delete the
   script from the model. Now Claude can read (and vet) it. Free models
   sometimes hide malicious scripts — this step is also your security check.
4. Commit + push after each session so Claude sees the latest.

## Daily workflow

1. `git pull` in the repo folder
2. Start Rojo server in VS Code, Connect in Studio
3. Build/play; code changes from the repo hot-sync into Studio
4. `git add -A && git commit -m "..." && git push` when done
