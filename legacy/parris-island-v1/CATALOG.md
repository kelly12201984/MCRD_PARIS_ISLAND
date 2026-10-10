# Parris Island v1 — reuse catalog, file by file

The summary, warnings and bug list are in [README.md](README.md). This file holds the detail for each of the 18 source files.


Generated from the reuse review and checked against the source. Line numbers refer to the files in this folder. Where an entry describes what the place file contains, it means the 2026-09-05 snapshot in `place/`, which is two days older than most of this code.

### Foundation: Config, Types, Remotes, server entry

Config, Types and Remotes are leaf modules under ReplicatedStorage.Shared. None of them requires another project module, which makes them the most portable code in v1. The other shared files (MapBlockout, MapInventory, SecuritySweep) don't depend on them either. Config is the table of tunable settings: six server services read it (Drill, Recruit, Progression, Formation, Spawn, Overhead), and the client reads none of it. Every key it defines is used, but it does not hold every tunable: the client HUD and a few service literals are hard-coded. It also carries old-map and old-experience values (Origin, tag names, DataStoreName) that must be revisited. Types is type-only: it returns {} at runtime. CommandCatalog, RankCatalog, three server services (Drill, Recruit, Progression) and both client files require it. Its Command shape lets malformed entries type-check that can never be answered correctly. Remotes creates five RemoteEvents on the server and makes clients wait for them with no timeout. The pattern is reusable, but the name list, the 'Remotes' folder name and the string-indexed export type need adapting. init.server.lua is the server's only Script and holds no game logic. It requires Remotes, then requires seven sibling services by `script.X`, calls init on six of them, and finally calls DrillService.start(), which runs the endless Waiting -> FallIn -> Drill -> Debrief loop. It has no error isolation. Booting it as-is also takes over spawns, teams and nameplates for every player, and drafts every player on the server into the drill. Treat it as a reference for boot order, not code to copy.

<details>
<summary><b><code>src/shared/Config.lua</code></b> — adapt · 174 lines</summary>

The game's settings sheet. It holds every number someone might tweak during playtesting (fall-in time, commands per drill, points for a crisp answer, XP rates, nametag size and colors) plus the tag and part names the map has to use. It has seven sections, each read by the system it belongs to.

**Verdict: adapt.** It has no dependencies and returns a plain table, so mechanically it copies cleanly. But it is one bag of seven sections, and each one only means something next to the v1 service that reads it. Some values are tied to the old map and the old experience: the Origin coordinate, the tag names and the DataStore name. Copy only the sections that go with the services you port.

**Requires:** nothing  
**Required by:** DrillService, RecruitService, ProgressionService, FormationService, SpawnService, OverheadService  
**Config:** `Config.Formation`, `Config.Spawn`, `Config.Drill`, `Config.Scoring`, `Config.Progression`, `Config.Overhead`, `Config.Debug`

**Needs from the place**

- This file looks nothing up itself. It is a plain table of values. Every key it defines is read somewhere; there are no dead settings.
- Consumers expect it at ReplicatedStorage.Shared.Config: each one does ReplicatedStorage:WaitForChild("Shared") and then Shared.Config (for example DrillService.lua:20-21 and FormationService.lua:24-25).
- It names things that other services look up. CollectionService tags: FormationSpot and FormationFront (lines 17-18, used at FormationService.lua:202, 211), BusStop and TownSpawn (lines 79-80, used at SpawnService.lua:80, 87). A Part named FormationOrigin (line 44, looked up at FormationService.lua:260, only when nothing is tagged FormationSpot). The DataStore "ServiceRecords_v1" (line 137, used at ProgressionService.lua:55).

**To reuse it**

- Copy only the sections for the services you actually port. Formation goes with FormationService and Spawn with SpawnService. Drill and Debug go with DrillService (DrillService.lua:37, 111-255). Scoring is shared by RecruitService (RecruitService.lua:95-120) and DrillService (CrispFraction at DrillService.lua:111). Progression goes with ProgressionService, Overhead with OverheadService.
- Replace Formation.Origin (line 45). Vector3.new(-3008, 6, -277) is a position on the old map. Either set it for the new map or put a BasePart named FormationOrigin (line 44) in the new place. This only matters when nothing is tagged FormationSpot.
- Make the tag names (lines 17-18, 79-80) match whatever Jax tags in the new map, or tag the new map's parts with these names.
- Decide on DataStoreName (line 137). Keep "ServiceRecords_v1" only if the new game is published into the SAME experience and old XP should carry over. Otherwise change the suffix so everyone starts clean.
- If the new game keeps shared modules somewhere other than ReplicatedStorage.Shared, update the WaitForChild("Shared") lookup in every consumer.
- If the client HUD is ported, give it a Config section (its colors and timings are hard-coded today) so the 'one-line tuning' rule actually holds.

**Known issues**

- Line 45: Formation.Origin is a hard-coded world position from the old map. If the new place has no FormationSpot tags and no FormationOrigin part, the fallback grid is generated here (FormationService.lua:50, 257, 398-402). The ground snap (FormationService.lua:270-280) only probes 50 studs up and down, so on the new map the grid can end up floating in empty space.
- Line 123: DemeritsBeforeIT is used as a modulo divisor (RecruitService.lua:119, `state.demerits % scoring.DemeritsBeforeIT == 0`). Incentive training therefore fires ON the 3rd demerit and again on every 3rd after that (3, 6, 9...). The comment on line 122 reads like a one-time threshold. Setting the value to 0 makes `n % 0` NaN, the comparison is never true, and incentive training silently never fires.
- Lines 93 and 112: the 'crisp' cutoff is ResponseWindow * CrispFraction (DrillService.lua:111), currently 6.0 * 0.45 = 2.7s. Raising Drill.ResponseWindow to give players more time also quietly loosens what counts as crisp. Reaction time is measured on the server clock, from just before the command is sent (DrillService.lua:121) to when the answer arrives (DrillService.lua:287), so it includes the player's full network round trip. Tightening CrispFraction hurts high-ping players first.
- The file does not hold every tunable. The client requires nothing from it: DrillHud.lua:22-26 hard-codes colors (YELLOW at line 26 duplicates Formation.PadColor from line 54), DrillHud.lua:220 hard-codes the red-timer threshold, and DrillHud.lua:268 hard-codes a 1.6s fade. Numeric literals remain in service code too: SpawnService.lua:47 (spawn size), FormationService.lua:287-288 and 333-336 (deck and bus-drop sizes), DrillService.lua:174/188/192 (poll waits) and OverheadService.lua:37 (HEAD_WAIT_SECONDS). The lockout bark text at DrillService.lua:141 is hard-coded content that belongs in CommandCatalog.
- Line 137: DataStores are shared across the whole experience. If the new game is published into the same experience and keeps this name, it loads v1 players' saved XP, keyed player_<UserId> (ProgressionService.lua:47).

</details>

<details>
<summary><b><code>src/shared/Types.lua</code></b> — drop-in · 106 lines</summary>

A dictionary of data shapes. It describes what a drill command looks like, what the server sends a player's screen after each command, and what a rank or a saved record contains, so the server and the player's screen agree. It has no running code; it only helps the editor catch mistakes before playtesting.

**Verdict: drop-in.** It has no dependencies and no runtime behavior, so copying it can't break anything. CommandCatalog and RankCatalog won't load without it, so it has to come with either of them. Only the types used by the modules you port matter; RecruitState, ServiceRecord and the remote payloads can be trimmed later.

**Requires:** nothing  
**Required by:** CommandCatalog, RankCatalog, DrillService, RecruitService, ProgressionService, DrillHud, init.client.lua  

**Needs from the place**

- Nothing at runtime: the module returns an empty table (line 106).
- It must be a ModuleScript named "Types" that is a sibling of CommandCatalog and RankCatalog, because they require script.Parent.Types (CommandCatalog.lua:14, RankCatalog.lua:12). A missing Types makes those requires error at load. Services and the client reach it as ReplicatedStorage.Shared.Types (DrillService.lua:22, RecruitService.lua:16, ProgressionService.lua:25, DrillHud.lua:18, init.client.lua:16).

**To reuse it**

- Keep it next to CommandCatalog and RankCatalog, or change their script.Parent.Types requires.
- Trim it to the types the ported modules use, and drop RecruitState.padIndex (line 93).
- Add a lockout grade such as "IncentiveTraining" to Grade (line 42). Send it from DrillService instead of the fake "Wrong" at DrillService.lua:150, give it a bark pool in CommandCatalog and a color in DrillHud.lua:247-253, and keep it out of RecruitService.applyGrade (any grade other than Crisp or Slow adds a demerit, RecruitService.lua:107-109).
- Fix the facing comment at line 94. Facing is relative to the formation front, not a compass direction.
- Optionally split Command (lines 13-24) into a MovementCommand | ResponseCommand union, so a missing facingDelta or answerIndex becomes a type error.
- This file never does anything at runtime. In a codebase that isn't type-checked (no --!strict) it is documentation only, but it still records the payload contract between server and client.

**Known issues**

- Line 42: Grade has no variant for a recruit locked out in incentive training. DrillService.lua:150 sends those recruits grade "Wrong" with delta 0 (lines 140-141), so the client colors it as a wrong answer (DrillHud.lua:250) and can only tell it apart by the bark text.
- Line 93: RecruitState.padIndex is dead. RecruitService.lua:25 sets it to nil and nothing else in src reads or writes it; pad ownership lives in FormationService's own maps (FormationService.lua:41-43). That misleads anyone porting the state shape.
- Line 94: the comment says facing 0=north, 1=east, 2=south, 3=west. The code treats facing as relative to the formation's front (FormationService.lua:433-440, '0 = toward the front, 1 = right'), or to each pad's own look direction when nothing is tagged FormationFront (FormationService.lua:136). That is north only by coincidence. DrillService.lua:197 repeats the 'north' wording.
- Lines 13-24: Command is one flat record whose optional fields depend on kind. A Movement entry without facingDelta still type-checks, but it can never be answered correctly: `expected` becomes the current facing (DrillService.lua:95), while every valid input turns the recruit by -1, +1 or +2 (lines 52-56, 96), so every answer grades Wrong. A Response entry without answerIndex is likewise always Wrong (DrillService.lua:103 compares the answer to nil). The client also only binds keys 1-4 (init.client.lua:34-39), so an answerIndex above 4 is unreachable, and the type does not capture that limit. The current CommandCatalog entries are all well-formed.
- Line 75: the comment says grade is 'Empty for Recruit', but no Recruit rank exists. RankCatalog.lua:17 gives Private grade "E-1", so the empty-grade branch in RankCatalog.displayName (RankCatalog.lua:51-53) never runs.
- Line 48: the FeedbackPayload.bark comment says barks are picked so everyone hears the same line. They are picked per recruit (DrillService.lua:144) and sent only to that recruit (line 147).

</details>

<details>
<summary><b><code>src/shared/Remotes.lua</code></b> — adapt · 55 lines</summary>

Sets up the five named 'phone lines' (RemoteEvents) between the server and each player's computer: issue a command, send the player's answer, return the grade, announce phase changes, and show the scoreboard. The server creates them and players' computers wait until they exist, which avoids a common Roblox startup race.

**Verdict: adapt.** The server-creates/client-waits pattern is generic and needs no project modules. But REMOTE_NAMES (lines 13-24) is v1's drill-loop list, only RemoteEvents are supported, and "Remotes" is a very likely folder name in a game built in Studio. If the v1 drill loop is ported whole, it is effectively drop-in.

**Requires:** nothing  
**Required by:** init.server.lua, DrillService, init.client.lua  

**Needs from the place**

- The module must live where both server and client can require it. v1 used ReplicatedStorage.Shared.Remotes. The folder it creates is hard-coded to ReplicatedStorage (lines 29, 35, 46).
- On the server it creates or reuses ReplicatedStorage.Remotes holding RemoteEvents named IssueCommand, SubmitAction, Feedback, PhaseChanged and Scoreboard (lines 13-24, 29-44).
- On the client it calls WaitForChild("Remotes") and then WaitForChild for each name, with no timeout (lines 46, 52).
- Some server Script must require it, or clients block forever. v1 does this at init.server.lua:15, and again through DrillService.lua:23.
- If the new place already has ReplicatedStorage.Remotes (of any class), it is silently adopted and these five events are added into it. Any existing child with one of these five names is reused whatever its class (lines 29-31, 39).

**To reuse it**

- Replace REMOTE_NAMES (lines 13-24) with the new game's remotes.
- Check the new place for an existing ReplicatedStorage.Remotes. If there is one, rename this module's folder (lines 29, 34, 46) or merge the two on purpose.
- Make sure some server script requires this module at boot, as init.server.lua:15 does.
- Add RemoteFunction or UnreliableRemoteEvent support if needed. Line 40 only ever creates a RemoteEvent.
- Consider returning a table with explicit keys instead of `{ [string]: RemoteEvent }` (line 49), so --!strict catches misspelled remote names.
- This module does no validation. Every OnServerEvent handler must check its payload, as DrillService.lua:271-287 does.

**Known issues**

- Line 49: the export is typed `{ [string]: RemoteEvent }`, so a misspelling such as Remotes.Feedbak passes --!strict but is nil at runtime and fails with 'attempt to index nil with FireClient'.
- Lines 29-31, 39, 52: an existing ReplicatedStorage.Remotes is adopted through an unchecked `:: Folder` cast, and an existing child with a matching name is skipped rather than checked. A pre-existing RemoteFunction named "Feedback", for example, would be cast `:: RemoteEvent` at line 52 without complaint, and the failure only shows up later at FireClient or OnServerEvent.
- Lines 46 and 52: the client WaitForChild calls have no timeout. If no server script requires this module, every client script that requires it hangs forever, with only an 'Infinite yield possible' warning.

</details>

<details>
<summary><b><code>src/server/init.server.lua</code></b> — reference-only · 35 lines</summary>

The server's startup script. It makes sure the server-client phone lines exist, switches on six server systems in a set order, and then starts the endless drill loop. It holds no game rules of its own.

**Verdict: reference-only.** It is pure v1 wiring: 35 lines that hard-code seven sibling service names and their boot order. The new game will have its own startup script with an unknown structure. What's worth keeping is the ordering: Remotes first, FormationService before SpawnService, everything else before DrillService.start(), which spawns the endless loop.

**Requires:** `Remotes`, `FormationService`, `SpawnService`, `RecruitService`, `DivisionService`, `ProgressionService`, `OverheadService`, `DrillService`  
**Required by:** nothing  

**Needs from the place**

- It must be a server Script whose children are ModuleScripts named exactly FormationService, SpawnService, RecruitService, DivisionService, ProgressionService, OverheadService and DrillService (lines 17-23 use script.X, which errors immediately if a child is missing). Rojo produced this layout; in Studio it would have to be built by hand.
- ReplicatedStorage needs a child named "Shared", which line 15 waits for with no timeout, so a missing Shared hangs the script silently. Shared must hold a ModuleScript named Remotes; `.Remotes` is dot-indexed and errors at once if it is absent. Through the services, Shared must also hold Config, Types, CommandCatalog and RankCatalog (DrillService.lua:21-24, ProgressionService.lua:24-26, OverheadService.lua:29-30).
- It always creates new Workspace.ReceivingDeck (FormationService.lua:394-409) and Workspace.Spawns (SpawnService.lua:75-78) folders without checking for existing ones, so same-named objects in the new place end up as duplicates. It adopts any existing ReplicatedStorage.Remotes (Remotes.lua:29-31).
- Through the services it boots, it also needs the following. CollectionService tags FormationSpot and FormationFront (FormationService.lua:202, 211) and BusStop and TownSpawn (SpawnService.lua:80, 87); each is optional, with fallbacks and warnings. An optional BasePart named FormationOrigin anywhere in Workspace (FormationService.lua:260-261), used only when nothing is tagged FormationSpot and hidden once found (lines 263-266). Teams in the Teams service if divisions are used. DivisionService forces AutoAssignable=false (DivisionService.lua:39-42), and nothing in v1 calls DivisionService.assign (line 25), so teams must be set by other code. DataStore access for saving XP: a published place, plus 'Enable Studio Access to API Services' when testing in Studio (ProgressionService.lua:14-16, 55). Player characters with a HumanoidRootPart (FormationService.lua:464, 522) and a PrimaryPart (FormationService.lua:543). A Head is optional: OverheadService waits 10s and then skips the tag (OverheadService.lua:58-61).
- The v1 client (StarterPlayerScripts init.client.lua + DrillHud) must also be present. Without it the loop still runs, but nobody can answer, so every recruit gets NoResponse or LeftFormation.

**To reuse it**

- Don't copy it. Write the new game's own bootstrap, or add require/init lines to whatever server script Jax already has.
- If several v1 services are ported, keep the real ordering. Require Remotes first (line 15). Run FormationService.init before SpawnService.init, because SpawnService.place uses FormationService.fallbackSpawn (SpawnService.lua:58), which is only set by FormationService.init (FormationService.lua:340, 413-415). Call DrillService.start last.
- If the services are not ModuleScripts parented under this Script, change the `script.X` requires at lines 17-23 to the real paths, such as script.Parent.X or ServerScriptService.X.
- Wrap each init in pcall/xpcall with a warn so one failing service doesn't take down the rest.
- Booting these services takes over global player state that the new game may manage itself. SpawnService overwrites every player's RespawnLocation (SpawnService.lua:56-61). DivisionService clears every present player's Team and locks AutoAssignable on all teams (DivisionService.lua:39-47). OverheadService hides the default Roblox name display (OverheadService.lua:66). FormationService teleports characters with PivotTo (FormationService.lua:548). Port only the ones that don't conflict.
- Starting the loop as-is drafts every player on the server. Each command grades every player in RecruitService.all() (DrillService.lua:133-138), and anyone not on a pad is graded LeftFormation (DrillService.lua:78-80), so players elsewhere on the map (for example in town) collect demerits and DI barks. Gate it to recruits who are actually in formation before starting it in a bigger game.
- Update the log tag at line 35.

**Known issues**

- Lines 17-33: the requires and inits run one after another on the main thread with no error isolation. If any of them throws, the script stops there and nothing after it runs, including DrillService.start() at line 33. The likeliest trigger when rebuilding this layout by hand in Studio is a missing or renamed child module: `script.FormationService` errors with 'FormationService is not a valid member of Script'. If an init fails part-way, the services before it are live and the rest are not, for example spawns working but no drill loop.
- Line 29: the comment says Division and Progression must be listening before Overhead asks them. OverheadService never requires or calls DivisionService; it reads player.Team directly (OverheadService.lua:81, 134). It does use ProgressionService (OverheadService.lua:32, 80, 147), but not in an init-order-sensitive way: getRank returns rank 1 before any record has loaded (ProgressionService.lua:159-161), and RankChanged exists from the moment the module is required (ProgressionService.lua:42-44). The orderings the code actually relies on are Formation before Spawn (only for players already present at boot, since later joiners resolve fallbackSpawn when they join) and everything before DrillService.start. The comment misleads anyone rewiring the boot.

</details>

### Drill loop

These three files are the drill loop. CommandCatalog is the content: what the DI shouts, the correct answers and the reaction lines. RecruitService is the per-player scorebook: score, demerits, streak, facing, the one answer each recruit gave for the current command, and the timed lockout called incentive training. DrillService is the referee that runs Waiting -> FallIn -> Drill -> Debrief forever. It picks a command from the catalog, broadcasts it over RemoteEvents, waits the response window, and grades each recruit, using FormationService to check they are still on their footprints and to turn them. It writes each result into RecruitService, and at the end hands each score to ProgressionService (and through it RankCatalog and DataStores) for XP and rank. CommandCatalog (drop-in, after removing the non-PG "grass grow / blood" entry) and RecruitService (adapt) depend only on Config and Types and move easily. DrillService needs FormationService, RecruitService, ProgressionService, Remotes and the v1 client, so it is a pattern to copy, not a file to copy. Confirmed gameplay bugs: (1) the incentive-training lockout ends before the next command is graded, so instead of benching the recruit it silently drops their quick answer to the next command and scores it as no response; (2) anyone not standing on a claimed spot is penalized on every command, which includes players who join mid-session, players in town, and overflow when spots run out, because v1 counts every player as a recruit; (3) facing never affects grading, despite the comments and docs promising that errors compound; (4) one error inside the unprotected main loop stops drilling for the rest of the server's life.

<details>
<summary><b><code>src/shared/CommandCatalog.lua</code></b> — drop-in · 124 lines</summary>

The drill instructor's script: the commands he can call (right, left and about face, plus shout-back questions like "EARS!" with multiple-choice answers) and the lines he barks after each grade. It is plain data plus three small helpers: pick a random command, pick a random bark, and look a command up by id.

**Verdict: drop-in.** Pure data plus three small functions. Its only dependency is Types, and only for the `Command` and `Grade` annotations (Types.lua:11-24, 42), which could be pasted in to make it fully standalone. Copied next to Types, it loads and works. It is only useful to a drill loop that understands its command shape (kind / call / facingDelta / options / answerIndex), and Jax's new game has no such loop yet. One entry ("kill") should come out before it ships, which is a one-entry deletion.

**Requires:** `Types`  
**Required by:** DrillService  

**Needs from the place**

- A ModuleScript named `Types` must be in the same parent (line 14: `require(script.Parent.Types)`, a direct index with no WaitForChild). Types is only used for type annotations and returns {} at runtime (Types.lua:106).
- Nothing else: no services, tags, named parts or Studio settings.

**To reuse it**

- Fix the require on line 14 to point at the new game's Types module, or paste the `Command`/`CommandKind`/`Grade` types (Types.lua:11-24, 42) into this file and drop the require.
- Delete or reword the "kill" entry (lines 58-64) to meet the project's PG tone rule.
- Consider keeping it where only the server can see it (ServerStorage or beside the server scripts), not in ReplicatedStorage. Only the server uses it (DrillService:24), and `answerIndex` is the answer key. If you move it, the Types require on line 14 has to follow.
- Add an empty-list guard to pickCommand (lines 111-113) to match the one pickBark has (lines 105-107).
- Optionally validate entries when the module loads: Movement entries need an integer facingDelta that is not a multiple of 4, and Response entries need answerIndex within 1..#options and no more than 4 options (the v1 client only maps keys 1-4).
- Optionally shuffle options each time a command is issued, so players have to read the answers instead of memorizing key positions. The issuing code must then remap answerIndex.
- Rename the BARKS keys (lines 70, 76, 81, 86, 91) if the new game uses different grade names. pickBark silently returns "" for an unknown grade (lines 104-107).
- Drop getById (lines 115-122) unless the new game needs it. Nothing calls it.

**Known issues**

- Lines 58-64: id "kill", call "WHAT MAKES THE GRASS GROW?", correct answer "SIR, BLOOD SIR!". This breaks the project's own rule (CLAUDE.md, Tone) that DI dialogue stays PG for Roblox's young audience.
- pickCommand (lines 111-113) has no empty-list guard, unlike pickBark (line 105). If COMMANDS is emptied, `rng:NextInteger(1, 0)` either errors at line 112 or returns an index into an empty table, and then DrillService:124 (`command.kind`) errors on nil. Either way the error lands inside the unprotected drill loop (DrillService:290-303), which stops for the rest of the server's life.
- The header (lines 5-6, and docs/GETTING_STARTED.md:102) promises he can add commands "without touching a service", but that is only true for Response commands and facing moves. Movement grading is modulo 4 (DrillService:95-96) against the only three inputs Left/Right/About (DrillService:52-56, init.client.lua:28-32). So a facingDelta of -1, 1, 2, 3, -2 or -3 works, but one that is nil, 0, 4 or not a whole number (for example a half-turn) can never be answered correctly and is always graded Wrong. Non-facing movements (for example ATTENTION or PARADE REST) cannot be expressed, and the HUD always shows the same Q/E/X hints (DrillHud.lua:200-202). A Response entry with more than 4 options cannot be answered past option 4 (init.client.lua:34-39). Nothing checks answerIndex against #options.
- Answer positions never change. Options are sent exactly as listed (DrillService:126), and 3 of the 4 Response commands have the right answer at index 2 (lines 49, 56, 63). Players can learn to press 2 instead of learning the response.
- The answer key reaches every client. src/shared maps to ReplicatedStorage.Shared (parris-island-v1.project.json), so any client can require this module and read answerIndex (lines 42, 49, 56, 63), even though only the server requires it (DrillService:24). This is low severity: the server still grades, the options are shown on screen anyway, and the right reply is common knowledge.
- The comment at lines 67-68 says barks are picked so "every client on the deck hears the same thing". In fact DrillService picks a separate bark for each recruit from their own grade (DrillService:144) and sends it only to that recruit (DrillService:147). There is no shared bark.

</details>

<details>
<summary><b><code>src/server/RecruitService.lua</code></b> — adapt · 171 lines</summary>

The server's scorebook for each player: current score, demerits, streak of good answers, which way they are facing, and the one answer they gave for the command on the clock. It applies the scoring rules (points for crisp or slow answers, penalties for wrong, no answer or wandering off) and puts a recruit in a short timed lockout ("incentive training") every few demerits.

**Verdict: adapt.** Easy to move: its only dependencies are Config.Scoring and three types, and it calls no other service. The scoring rules in applyGrade (lines 89-126) and the first-answer-only rule in submit (lines 63-79) are worth keeping. But it is the bookkeeping half of DrillService's cycle (clear answers, take one answer, grade after the window), so it only pays off if the new game uses that same cycle. Its state record also carries a dead field and drill-specific fields. A Studio-built game probably keeps per-player data somewhere already (for example leaderstats), which this would have to merge with or replace.

**Requires:** `Config`, `Types`  
**Required by:** DrillService, init.server.lua  
**Config:** `Config.Scoring`

**Needs from the place**

- ReplicatedStorage must contain an instance named `Shared` (WaitForChild, line 14) with ModuleScripts `Config` and `Types` as children (lines 15-16, indexed directly, not waited on).
- Something must call `RecruitService.init()` once at server start. It registers current players and hooks Players.PlayerAdded and PlayerRemoving (lines 163-169). In v1 this happens at init.server.lua:28.
- No tags, named parts, DataStores or Teams.

**To reuse it**

- Repoint the requires (lines 14-16) to wherever the new game keeps shared modules.
- Copy the Config.Scoring block (Config.lua:106-126) and the RecruitState, Grade and ScoreRow types (Types.lua:42, 65-69, 91-104). Drop `padIndex`, which nothing uses.
- Decide whether this module or the new game's existing player data owns score and demerits. If the new game already has leaderstats or a profile module, move applyGrade's rules into it instead of running two stores.
- Count the lockout in commands (for example, skip the next N commands), or make sure it lasts past the next grading. See known issues.
- If the new game has players who are not recruits (v1's SpawnService treats Team holders as recruits), filter them out in init (lines 164-168) instead of registering everyone.
- Make applyGrade handle each grade explicitly instead of treating every unknown grade as a failure (line 107).
- Consider having all() (lines 44-46) return a copy, or adding a setFacing function, so callers stop editing the state directly.

**Known issues**

- The lockout misfires with the default Config. applyGrade starts it when a command is graded: `itUntil = now + IncentiveTrainingSeconds` (6 s, line 120, Config.lua:125). The next command goes out only 2.0-3.5 s later (Config.lua:96-97) and is graded 6 s after that (Config.lua:93), so the lockout has already ended by the next grading. What it actually does is make submit() reject answers in the first 2.5-4.0 s of the next command (lines 71-74). That is all or nearly all of the 2.7 s crisp window (6.0 x 0.45, Config.lua:112). The client has already marked itself as answered and will not resend (init.client.lua:42-45), so the recruit is graded NoResponse (-40 and another demerit) for an answer they did give. See the DrillService entry.
- Any grade other than Crisp or Slow falls into the failure branch (lines 107-121). A new grade added to Types.Grade (for example Excused or LockedOut) would silently add a demerit, reset the streak, possibly start a lockout, and score 0.
- Line 25: `padIndex` is set to nil and never written anywhere. A search of the archive finds it only here and in Types.lua:93. Spot ownership actually lives in FormationService's own playerPad map (FormationService.lua:43, 462-512), so this field is a misleading second source of truth.
- all() (lines 44-46) returns the live internal table, and DrillService writes `state.facing` directly (DrillService:98, 201). Despite the header's "This service owns the truth" (line 6), RecruitService does not control all writes to its own state.
- init (lines 164-168) registers every player as a recruit, while SpawnService defines recruits as players who hold a Team (SpawnService.lua:5-8, 56). Players who are not recruits still get scored, penalized and listed on the scoreboard (lines 150-156). See the DrillService entry.

</details>

<details>
<summary><b><code>src/server/DrillService.lua</code></b> — reference-only · 306 lines</summary>

The referee that runs the drill session on an endless loop: wait for players, get everyone onto the yellow footprints, call a set of commands and grade each recruit on correctness and speed, then hand out XP and promotions and show the scoreboard. It also receives every player's key press and makes sure each one answers the command that is live right now.

**Verdict: reference-only.** It calls into three sibling services (seven project modules directly, counting Remotes, CommandCatalog, Config and Types, plus RankCatalog through ProgressionService), and through them into CollectionService tags, a generated world and DataStores. Copying it means bringing along nearly all of v1's server. It also assumes it runs the whole game: an endless loop that controls the phases and treats every player as a recruit (lines 250, 185, 133). That is likely to clash with whatever flow Jax built in Studio. It also has several gameplay bugs (below). Three pieces are worth rebuilding by hand: the top-to-bottom phase loop (lines 249-303), gradeRecruit (lines 68-113), and the SubmitAction check that matches each answer to the current command's sequence number (lines 271-288).

**Requires:** `Config`, `Types`, `Remotes`, `CommandCatalog`, `FormationService`, `RecruitService`, `ProgressionService`  
**Required by:** init.server.lua  
**Config:** `Config.Drill`, `Config.Scoring`, `Config.Debug`

**Needs from the place**

- ReplicatedStorage must contain an instance named `Shared` (WaitForChild, line 20) with ModuleScripts Config, Types, Remotes and CommandCatalog (lines 21-24).
- Sibling ModuleScripts FormationService, RecruitService and ProgressionService in the same parent (lines 26-28). Their init() functions must run before DrillService.start() (v1 order: init.server.lua:25-33). Without FormationService.init there are no spots; without RecruitService.init nobody is graded; without ProgressionService.init awardSession returns nothing.
- RemoteEvents IssueCommand, SubmitAction, Feedback, PhaseChanged and Scoreboard in a folder named `Remotes` directly in ReplicatedStorage. Remotes.lua creates them in code when the server requires it (Remotes.lua:28-44), and DrillService's own require (line 23) is enough to do that. Clients wait with WaitForChild and no timeout (Remotes.lua:46, 52), so load order is not critical. If the new game already has a ReplicatedStorage.Remotes folder, Remotes.lua reuses it and adds its events to it (Remotes.lua:29-31, 39).
- A client that listens on IssueCommand, Feedback, PhaseChanged and Scoreboard and fires SubmitAction with {sequence, action} (v1: init.client.lua:41-99 and DrillHud.lua).
- Through FormationService: Workspace parts tagged `FormationSpot`, plus one tagged `FormationFront`, found with CollectionService (FormationService.lua:202, 211). If nothing is tagged, it uses a Part named `FormationOrigin` (FormationService.lua:260), or else generates a grid at Config.Formation.Origin, which is a v1-map coordinate (-3008, 6, -277; Config.lua:45). Characters need a HumanoidRootPart and a PrimaryPart (FormationService.lua:464, 522, 543). FormationService also builds a Workspace folder `ReceivingDeck` of its own parts (FormationService.lua:394-409).
- Through ProgressionService: RankCatalog (ProgressionService.lua:26, with v1 decal asset ids) and DataStoreService, using the store named in Config.Progression.DataStoreName ("ServiceRecords_v1"). To save progress during Studio testing, the place must be published and Game Settings -> Security -> Enable Studio Access to API Services must be on (ProgressionService.lua:14-16, 55, 183).

**To reuse it**

- Do not copy the file. Rebuild the loop on the new game's own systems, using this as a template. What it needs from elsewhere: a formation provider with tryClaimPad/releasePad/getPad/isHoldingPad/orientOnPad/occupiedCount/setBeacon, a progression hook awardSession(player, score, demerits) -> (xp, rank?), RecruitService's interface (clearPending/all/get/submit/isLockedOut/applyGrade/resetAll/scoreboard), and the five RemoteEvents.
- Decide who counts as a recruit (for example `player.Team ~= nil`, as v1's SpawnService did) and use that rule in waitForRecruits (lines 250, 255), the fall-in early exit (line 185) and grading (line 133).
- Let players claim a spot during Drill too (claimPads is only called at lines 173 and 181), or skip grading anyone without a spot. Otherwise late joiners are penalized on every command.
- Fix the lockout: count it in commands, make IncentiveTrainingSeconds longer than MaxPauseBetweenCommands + ResponseWindow, or tell the client its answer was rejected so it can answer again.
- Decide whether facing should compound. If it should, grade movement against an absolute target facing. If not, drop the claim from the comments and docs (see known issues).
- Wrap each pass of the main loop (lines 291-302) in pcall or xpcall with a log line, so one error does not stop drilling for the rest of the server's life. Add a timeout or warning to the first fall-in wait (lines 172-175).
- If the new game already has a ReplicatedStorage.Remotes folder or events with these names, rename v1's folder or events to avoid sharing them by accident.
- Move the hard-coded pushups bark (line 141) into CommandCatalog.Barks, and the poll and settle intervals (lines 174, 188, 192, 256) into Config.Drill, per the project's no-magic-numbers rule. The phase lines (lines 171, 178, 209, 239, 254) are content too.
- Use DisplayName in the promotion message (line 235) to match the scoreboard.

**Known issues**

- The lockout cannot work as designed with the default Config. RecruitService sets `itUntil = now + 6` when a command is graded (RecruitService:120). The next grading comes at least 2.0 s (pause, lines 215-219) plus 6.0 s (window, line 130) later, so `isLockedOut` (line 74) is always false by then, and the nil-grade/pushups branch (lines 74-76, 141-145) never runs. Instead, answers sent in the first 2.5-4.0 s of the next command are rejected in RecruitService.submit, and line 287 ignores its false return. The client will not resend (init.client.lua:42-45), so a recruit who answered quickly is graded NoResponse (-40 and another demerit, which can count toward the next lockout).
- Facing never affects grading, despite the comment at lines 61-63 ("Compounding error is the whole point of drill") and docs/GETTING_STARTED.md:88-90. expected = (facing + facingDelta) % 4 and actual = (facing + delta) % 4 (lines 95-96) are equal exactly when delta = facingDelta mod 4, whatever the current facing. A recruit left facing the wrong way is graded exactly the same on the next command. The only effect is how the character is turned on screen (line 99).
- Spots can only be claimed during fall-in (claimPads is called only at lines 173 and 181). Anyone without a spot during Drill (joined mid-session, never walked over, or found every spot taken; the generated grid has 20, Config.lua:49-50) fails `isHoldingPad` (line 78) and is graded LeftFormation on every command: -60 and a demerit each (Config.lua:116). Because the lockout never takes effect at grading time, all 12 commands are scored: up to -720, with no way back in until the next round.
- Every player counts as a recruit. waitForRecruits (lines 250, 255) and the fall-in early exit (lines 184-186) count `#Players:GetPlayers()`, and grading loops over every registered player (line 133). That contradicts SpawnService's Team-based definition of a recruit (SpawnService.lua:5-8, 56). One player hanging around in town keeps fall-in on its full 25 s timer every round (Config.lua:86) and is penalized LeftFormation on every command.
- The main loop (lines 290-303) runs in task.spawn with no pcall. Any error inside a phase permanently stops the drill on that server, and `running` (line 264) stays true, so start() cannot restart it. One example: an empty CommandCatalog fails in pickCommand (CommandCatalog:112) or on `command.kind` at line 124.
- If the formation has no spots (nothing tagged and GenerateIfNoSpots turned off, FormationService.lua:398-405), fall-in waits forever at lines 172-175. The only sign is one warn in the server output.
- Speed is timed on the server, from just before the command is sent (line 121) to when the answer arrives (line 287, stored at RecruitService:77; used at line 110). Both network legs therefore count against the 2.7 s crisp window. An answer sent just before the deadline that arrives after the 6 s wait ends (line 130) is graded NoResponse. Players with high ping are graded more harshly.
- Latent, because the branch is unreachable with the default Config (see the first issue): a locked-out recruit is sent `grade = "Wrong"` (line 150) with a hard-coded bark (line 141). The client cannot tell a penalty from a mistake (Types.Grade, Types.lua:42, has no lockout value), and the bark bypasses CommandCatalog.Barks.
- The promotion message uses `player.Name`, the username (line 235), while the scoreboard uses `player.DisplayName` (RecruitService:152), so the same recruit appears under two different names in the same debrief.
- Lines 229-233: debrief calls ProgressionService.awardSession for every player in RecruitService.all(), including people who never fell in. ProgressionService.lua:146-147 then counts a session and marks the record dirty, so `sessions` means 'debriefs while connected', and every idle player is written to the DataStore on each autosave.

</details>

### Formation

FormationService is the only file in this group. It holds the state for where recruits stand. It finds the boxes tagged FormationSpot, or generates a fallback grid at a FormationOrigin part or a hardcoded v1 coordinate, and tracks which player holds which spot. init.server.lua calls init() first, because SpawnService reads fallbackSpawn() for the generated BusDrop. DrillService drives everything else: setBeacon during fall-in, polling tryClaimPad every 0.25 s, occupiedCount to decide when to start, isHoldingPad to catch drifting, orientOnPad (a PivotTo teleport) to snap facing, and releasePad on leave and at the start of each session. The module knows nothing about drill, scoring or remotes, so its core logic is the most reusable server code in v1. It is still 'adapt', not 'drop-in'. The Config path is hardcoded. The default fallback points at an old-map coordinate and creates a Neutral spawn. And whatever the new game uses to drive it has to handle releasing pads on death and on leaving, which the module does not do itself.

<details>
<summary><b><code>src/server/FormationService.lua</code></b> — adapt · 559 lines</summary>

Manages the yellow footprints. It finds the spots where recruits stand (from tagged boxes on the map, or a generated practice grid if nothing is tagged), gives each player the nearest free spot when the game checks who is standing near one, reports whether they are still on it, and snaps their character back onto the spot facing the right way after a facing command. It also owns the floating "FALL IN HERE" sign over the formation.

**Verdict: adapt.** Its only project dependency is Config.Formation. It has no remotes, Types, DataStores or calls into sibling services, so the core logic (laying spots out inside a box, claiming the nearest free spot, the drift check, the facing snap) is the most portable server code in v1. Copying it unchanged into a Studio-built game would still not just work. The config path ReplicatedStorage.Shared.Config is hardcoded (lines 24-25), and the real Config.lua carries every other v1 section. With nothing tagged, the default fallback builds the grid at a v1-map coordinate (Config.lua line 45). There it floats over the void with non-collidable pads, and it adds a Neutral BusDrop SpawnLocation that can take over the new game's spawns. The module also does nothing on its own: a caller has to poll tryClaimPad and release pads on leave, on death and at each reset. The edits are small, but they are edits, so this is 'adapt' rather than 'drop-in'.

**Requires:** `Config`  
**Required by:** init.server.lua (server entry; require at line 17, calls FormationService.init() at line 25), SpawnService (require at line 22; uses fallbackSpawn() at line 58), DrillService (require at line 26; uses isHoldingPad L78, orientOnPad L99/L202, tryClaimPad L162, setBeacon L167/L195, occupiedCount L172/L185, getPad L200, releasePad L268/L296)  
**Config:** `Config.Formation`

**Needs from the place**

- A child of ReplicatedStorage named "Shared" with a ModuleScript "Config" that returns a table with a Formation field. Line 24 calls WaitForChild("Shared") (if it is missing the server waits forever) and line 25 calls require(Shared.Config).
- Tagged mode (preferred): CollectionService tag "FormationSpot" (Config.Formation.SpotTag) on each formation box. Each box must be a BasePart or Model under Workspace (lines 211-213), lie flat with its local Y axis pointing up (see known_issues), and gets RecruitsPerPad (4) standing spots.
- Optional: CollectionService tag "FormationFront" (Config.Formation.FrontTag) on the BasePart or Model where the DI stands. Only the first GetTagged result is used (line 202), and it is not limited to Workspace. Only tagged mode reads it; the generated grid ignores it.
- Fallback-grid placement: a BasePart named "FormationOrigin" (Config.Formation.MarkerName) anywhere in Workspace. Line 260 uses recursive FindFirstChild, which returns only the first match. If that match is not a BasePart (for example a Model with the same name), line 261 ignores it and the grid goes to the v1 coordinate in Config.Formation.Origin. The marker is made invisible, non-collidable, non-queryable and non-touchable (lines 263-266).
- Fallback grid with SnapToGround: there must be ground within GroundProbeHeight (50) studs of the origin. The ray starts 50 studs above (line 274) and takes the first surface it hits (line 275), so a roof, canopy or tree over the origin catches the grid. If nothing is hit, the pads float at the origin's Y.
- Creates Workspace.ReceivingDeck (lines 394-409). Both modes: BeaconAnchor part with a BillboardGui named "Beacon". Tagged mode: StandingSpot marker parts if ShowSpotMarkers is on (lines 242-246). Generated mode: Footprints_NN pads with a PadIndex attribute, ClaimHighlight Highlights, a BusDrop SpawnLocation, and a "Deck" part when BuildDeck is true. Only the top-level folder name could clash with the new map.
- Generated mode adds a SpawnLocation called BusDrop to Workspace that is Neutral and enabled (lines 329-339). Any player without a RespawnLocation can spawn on it at random, alongside the new game's own spawns.
- Generated mode adds one Highlight per pad (line 323, default 4x5 = 20). Claimed pads turn theirs on (line 448), and those count against the client's 31-Highlight limit together with any Highlights the new game uses.
- Player characters need a HumanoidRootPart (lines 464, 522) and a PrimaryPart (line 543). StandHeight=3 (line 548) assumes a default-scale R6/R15 rig.
- Must run on the server. Call init() once before anything reads fallbackSpawn().

**To reuse it**

- Lines 24-25: point them at the new game's config module, or create ReplicatedStorage.Shared.Config containing only the Config.Formation block (Config.lua lines 13-73) rather than the whole v1 Config.
- Tag the new map's formation boxes "FormationSpot" and the DI's stand "FormationFront". Failing that, put a BasePart named "FormationOrigin" where the practice grid should go. Either way, replace Config.Formation.Origin (Config.lua line 45, Vector3.new(-3008, 6, -277)), because it is a coordinate on the OLD map. getPadPosition also falls back to it (line 430).
- If you rely on the generated grid on a map with no ground at the origin, set Config.Formation.BuildDeck = true (Config.lua line 48). Making BusDrop collidable (line 332) is not enough on its own, because the pads are non-collidable (line 313) and recruits fall the moment they step off the BusDrop. To skip the fallback entirely, set GenerateIfNoSpots = false (Config.lua line 43).
- If v1 SpawnService is not being ported, decide what happens to the generated BusDrop (lines 329-339). Set Enabled = false or remove it, otherwise it becomes a random Neutral spawn for every player.
- Wire up the contract that v1 DrillService provided. Call init() once at server start, before any spawn logic. Call tryClaimPad(player) on a loop during fall-in: claiming is polled, not triggered by touch (DrillService lines 160-164, called every 0.25 s at 172-192). Call releasePad(player) on Players.PlayerRemoving (DrillService line 268) and at the start of each session (line 296). Also release on CharacterRemoving or on death (see known_issues).
- Move the hardcoded literals in generateSpots into Config, to match the project rule. These are the deck margins +20/+36 (lines 287-288), the deck offset -0.6 and colour (lines 295, 297), and the BusDrop size, offset and colour (lines 333-334, 336). If the new game's formation is not the Receiving deck, also rename the folder "ReceivingDeck" (line 395).
- The module holds one formation in module-level state (lines 39-47) and builds one ReceivingDeck folder (line 395). If the new game has more than one formation area (several platoons or squad bays), refactor it into a per-formation object.
- getPadPosition and padCount (lines 424-431) have no callers in v1; keep them or drop them. facingToYaw (line 438) is public but only used internally at line 547.
- Tune Config.Formation.ClaimRadius (4) and DriftTolerance (5.5) to the new map. In tagged mode, spot spacing is (box side - 2*SpotInset)/columns (lines 153-176). For a 2x2 layout in any box narrower than about 12.5 studs, the 5.5-stud DriftTolerance is larger than the spacing between spots. In that case a recruit can stand on a neighbour's spot and still count as holding their own. (The generated grid is mostly safe: its pads are 6 studs apart, so only the near edge of a neighbour's pad still counts.)
- Line 187 points every tagged spot at the DI's position, so the outer recruits in a wide formation turn inward. If the new game wants parallel ranks, use frontDir for every spot instead of faceToward(frontPos).

**Known issues**

- Fallback grid with no tags and no FormationOrigin part is unusable on any map but v1. Lines 50 and 257 fall back to Config.Formation.Origin = (-3008, 6, -277). That point is about 3020 studs from world origin, off the default 2048x2048 Baseplate (which spans -1024 to 1024), so the header claim at lines 11-13 ('still runs on an empty baseplate') does not hold. The raycast at line 275 hits nothing, so the pads stay at Y=6. The pads (line 313) and BusDrop (line 332) are non-collidable, and BuildDeck is false (line 290; Config.lua line 48), so there is nothing to stand on. If BusStop and TownSpawn are not tagged either, v1 SpawnService makes BusDrop every player's RespawnLocation (SpawnService lines 56-61), so recruits fall into the void and respawn in a loop. Minor related point: BeaconMaxDistance is 3000 (line 370, Config.lua line 72), less than the roughly 3020-stud distance, so a player at a world-origin spawn cannot see the beacon.
- Tagged pads assume the part's local Y axis points up. Line 215 adds size.Y/2 straight up, and lines 145/148 treat size.X and size.Z as the footprint, even though yawOnly (lines 53-56) throws away pitch and roll. Take a pad rolled 90 degrees, such as a Cylinder disc with Size (0.2, 6, 6) and Orientation (0, 0, 90). Its spots sit about 2.9 studs above the real surface, so markers float and orientOnPad (line 548) drops the recruit each time. The 0.2-stud axis is treated as one side of the footprint, so usableAcross or usableDeep clamps to 0 (lines 153-154). The column search (lines 159-173) then puts all four spots in a single line about 1.1 studs apart, closer than a character is wide, instead of a 2x2 grid.
- Line 202 takes CollectionService:GetTagged(FrontTag)[1] without the IsDescendantOf(Workspace) check that spots get at line 212. A FormationFront-tagged instance in ServerStorage or ReplicatedStorage, or a second tagged instance (GetTagged order is not guaranteed), moves the DI position to an arbitrary point, and every spot faces it (lines 136, 187).
- Spot numbering does not match the comments at lines 123-125 and 195-196 ('front rank first, then left to right'; 'spot 1 is the front-left recruit'). rowKey (line 227) buckets the straight-line distance to the DI point, so in a wide formation the outer front-rank spots sort after the inner second-rank spots. The left/right tiebreak (line 236) uses world X, so the order is mirrored when the formation faces +Z, and when it faces plus or minus X the order within a rank comes down to float noise in X before Z. With no DI, rowKey uses world Z (line 227), so pads facing +Z are numbered back to front. Nothing in v1 uses the index order (Types.padIndex is never set; getPadPosition is unused), but new code that treats spot 1 as the guide or the front-left recruit would get it wrong.
- Spots are collected once, in init() (lines 398, 211). Boxes tagged, inserted or loaded after init are never picked up, because there is no GetInstanceAddedSignal listener. A tagged box that moves later leaves stale spot positions.
- The module never listens to PlayerRemoving, CharacterRemoving or Humanoid.Died. padOwner and playerPad (lines 41-43) keep the claim and the Player reference until a caller runs releasePad (line 496). A recruit who dies respawns away from the pad but still holds it, so nobody else can claim it, and isHoldingPad (line 514) reports them as drifted (DrillService line 78 scores LeftFormation on every command). tryClaimPad returns the existing pad without checking distance (lines 469-472), so they cannot claim a nearer one either.
- Generated mode adds a Neutral, enabled SpawnLocation named BusDrop to Workspace (lines 329-339). In v1 this is harmless because SpawnService sets every player's RespawnLocation. In a game without that service, Roblox randomly spawns players on BusDrop as well as the game's own spawns, and on a map where the fallback origin is wrong (first issue) they spawn over the void.
- SnapToGround casts down from 50 studs above the origin (lines 274-275) and takes the first hit. A roof, awning, tree or overhead part within 50 studs above the FormationOrigin puts the whole grid on top of it. Only the marker is excluded (line 267).
- In generated mode the DI marker is ignored. frontPos is only computed in collectTaggedSpots (lines 201-208), and generated spots take the origin's rotation (lines 308, 322). Facing 0 is therefore the FormationOrigin part's front face, or world -Z with no marker, not toward the FormationFront-tagged DI that the header (lines 15-17) describes.
- orientOnPad has no distance check (lines 535-548). It calls character:PivotTo onto the spot from wherever the character is, so it is a teleport, not a turn in place. v1 relies on this deliberately to square everyone away (DrillService lines 198-203), and checks isHoldingPad before orienting during drill (DrillService line 78 before 99). New code that calls it as a 'turn' helper will yank players across the map.
- Claiming and the drift check use horizontal distance only (lines 479, 528). A player on a floor, roof or ledge directly above a spot, within ClaimRadius horizontally, claims it and counts as holding it.
- Generated mode can enable up to Rows*Columns Highlights at once (line 323 creates them; line 448 turns them on). With the defaults that is 20 (Config.lua lines 49-50). They share the client's 31-Highlight limit with any Highlights the new game uses, so raising the grid size or adding other Highlights can stop claimed pads from glowing.

</details>

### Spawns and divisions

These two files implement Jax's rule of walk-ins versus recruits. DivisionService turns off Roblox's automatic team assignment, makes everyone present at startup teamless, and offers assign()/clear() helpers. SpawnService sets each player's RespawnLocation to the tagged bus stop if they have any Team, or to the tagged town spot if not, and updates it whenever their Team changes. It never moves an already-spawned character. Neither file requires the other: they connect only through Player.Team. SpawnService's one sibling dependency is FormationService.fallbackSpawn(), which is a dev-grid fallback. Nothing in src ever calls DivisionService.assign(). In the archived Studio place, an old free-model Autoteam script was still enabled and assigning teams by group, and the BusStop/TownSpawn tags were never placed, so everyone actually spawned at the generated practice-grid bus drop. Both files are small (150 lines total). SpawnService is a good adapt candidate once the FormationService fallback is cut. DivisionService's startup policy (no auto-teams, everyone teamless) must be checked against how Jax's new Studio-built place uses Teams, team spawns and any autoteam scripts before reuse.

<details>
<summary><b><code>src/server/SpawnService.lua</code></b> — adapt · 100 lines</summary>

Decides where each player will appear the next time their character spawns. Players on a team (a "division", meaning a recruit) are sent to the bus stop and everyone else to town. It finds both spots from tags that the map builder puts on parts in Studio. It only sets where the next spawn happens and never moves a character that is already standing in the world.

**Verdict: adapt.** The core is generic and small: turn a tagged part into a SpawnLocation and set Player.RespawnLocation by team (lines 31-70), using only Config.Spawn. Two things tie it to v1. It requires the sibling FormationService only for the dev-grid fallback (lines 22, 57-59). Its rule that any Team means recruit (line 56) bakes in v1's division policy. Jax's new Studio-built place may use Teams differently; the v1 place itself had 8 group-style teams.

**Requires:** `Config`, `FormationService`  
**Required by:** src/server/init.server.lua  
**Config:** `Config.Spawn`

**Needs from the place**

- ReplicatedStorage.Shared folder containing the Config ModuleScript (WaitForChild at line 19, require at line 20). There is no timeout, so requiring this module waits forever if Shared is missing.
- A sibling ModuleScript named FormationService under the same parent (line 22). It must expose fallbackSpawn() (called at line 58), and that only returns something after FormationService.init() has generated its practice grid (FormationService.lua:329-340, 413-415). Requiring it also drags in FormationService's own Config.Formation needs.
- CollectionService tag "BusStop" (Config.Spawn.BusStopTag, Config.lua:79) on one BasePart or Model (line 80). If it is missing, the code warns (line 84) and falls back.
- CollectionService tag "TownSpawn" (Config.Spawn.TownSpawnTag, Config.lua:80) on one BasePart or Model (line 87). If it is missing, the code warns (line 91) and falls back.
- The tagged part, or whatever sits under it, has to be solid. The generated SpawnLocation is CanCollide=false (line 45) and sits 0.5 studs above the tagged part's top (line 48), so players drop onto the tagged part and fall through it if it is non-collidable.
- At runtime it creates a Folder named "Spawns" in Workspace holding invisible, non-colliding, Neutral SpawnLocations named "BusStop" and "TownSpawn" (lines 42-51, 75-78)
- Reads Player.Team (line 56) and listens for changes to it (line 67), so the recruit path needs something else to put players on Teams

**To reuse it**

- Delete the FormationService require (line 22) and the fallback at lines 57-59, or point the fallback at a SpawnLocation the new place already has. After that, Config is the only dependency.
- Carry Config.Spawn {BusStopTag, TownSpawnTag} into the new game's config, or inline the two tag strings
- Re-decide the recruit test at line 56. v1 treats having any Team as being a recruit. If the new game has teams like Visitors or Drill Instructors, replace it with an explicit check (team names, a player attribute, etc.).
- If a player's division can change mid-session, also respawn or move them in the Team-changed handler (lines 67-69), e.g. player:LoadCharacter() or PivotTo. Today only RespawnLocation changes.
- Check the new place for hand-placed SpawnLocations. This module leaves them in place and only overrides them through RespawnLocation, and when no tag is found Roblox picks among them. Team-only ones (Neutral=false) are never used for teamless players.
- Tag a solid floor or pad part of the bus stop, not a whole shelter model and not an invisible non-collidable marker. Or change line 48 to raycast down to the ground.
- Move the hard-coded spawn size (6x1x6, line 47) and the 0.5-stud lift (line 48) into Config, per the project's convention of keeping tunables out of service code
- Call SpawnService.init() from the new server entry after the map exists. Tags are read only once, at init (lines 80, 87).

**Known issues**

- Line 56 together with DivisionService.lua:25: nothing in src calls DivisionService.assign(), so from src alone no player gets a Team and the bus-stop branch is unreachable. The archived place is different in two ways. (a) place/parris_island.rbxl still has an enabled Script ServerScriptService.Autoteam that sets player.Team from Roblox group membership on PlayerAdded, so group members there did get Teams. (b) That place has no instance tagged BusStop or TownSpawn (none of its tag strings match). So busStop and town were both nil, and every player, with or without a team, got FormationService's generated "BusDrop" (FormationService.lua:329-340; Config.Formation.GenerateIfNoSpots = true at Config.lua:43), not the town spawn.
- Lines 61, 67-69 and 94-96: on a Team change, and for players already in the server when init() runs (common in Studio Play Solo), it only sets RespawnLocation. The current character is not moved or respawned, so the new spot takes effect only after the next death or LoadCharacter.
- Lines 36 and 48: for a tagged Model, the spawn goes at the top of the model's whole bounding box (cf.Position + size.Y/2). Tagging a whole bus-shelter model with a roof would put players on the roof. For a BasePart, size.Y is the part's local height, so a part rotated onto its side gives the wrong height. Line 48 also drops the part's rotation (CFrame.new(position)), so players always spawn facing the same world direction.
- Lines 45 and 48: the SpawnLocation is non-collidable and floats 0.5 studs above the tagged part. If the tagged part is CanCollide=false (a typical invisible marker), players fall through it.
- Lines 33-39 with 82/89: if the tagged instance is neither a BasePart nor a Model (for example a Folder or an Attachment), spawnAt returns nil and busStop/town stay nil with no warning. The missing-tag case warns at lines 84/91, but this case is silent.
- Lines 80 and 87: only GetTagged(...)[1] is used. If several instances carry BusStop or TownSpawn, one is picked with no guaranteed order and the rest are ignored. It never chooses between them per spawn.
- Lines 80 and 87: tags are read once in init() and there is no GetInstanceAddedSignal. Anything tagged or parented in afterward is never picked up (e.g. map pieces cloned in from ServerStorage at runtime).

</details>

<details>
<summary><b><code>src/server/DivisionService.lua</code></b> — adapt · 50 lines</summary>

Treats a Roblox Team as a recruit's "division". It stops Roblox from automatically putting new players on random teams, takes everyone already in the server off their team, and gives other server code a one-line way to put a player on a named team or take them off.

**Verdict: adapt.** Mechanically it has no project requires and no Config, so the file copies cleanly. Calling init(), though, imposes a place-wide policy: AutoAssignable is forced off on every team (lines 18-22, 39-42) and every current player is made teamless (lines 45-47). A Studio-built military game, as the v1 place shows, usually relies on AutoAssignable teams, team-only SpawnLocations and group autoteam scripts. Dropping this in would leave players teamless, unable to use team spawns, and racing other team scripts. assign() also does nothing until a caller is written, so in practice it needs a deliberate edit (exempt teams, or skip init) plus new wiring.

**Requires:** nothing  
**Required by:** src/server/init.server.lua  

**Needs from the place**

- Team objects under the Teams service, created in Studio or by other code. This module never creates teams. assign(teamName) looks them up by exact, case-sensitive Name with Teams:FindFirstChild (line 26) and returns false if there is no match.
- Turns AutoAssignable off on every Team that exists at init and every Team added later (lines 18-22, 39-42), which overrides the AutoAssignable checkbox set in Studio. Nothing stops another script from turning it back on later.
- At least one SpawnLocation with Neutral = true (or SpawnService's generated ones, which are Neutral at SpawnService.lua:49). Players are left teamless, and Roblox will not spawn them at team-only SpawnLocations (Neutral = false). 3 of the 4 SpawnLocations in the v1 place were team-only.
- No other script in the place may assign teams. The header (lines 9-10) says this replaced the free-model "Autoteam" script, but the archived v1 place file still contains that script, enabled, at ServerScriptService.Autoteam. It assigns teams by group membership on PlayerAdded and errors for team names the place lacks (Visitors, Special Operations Command, "Training and Education Command" vs the place's "Training & Education Command").

**To reuse it**

- Use init() only if the new game wants players to start teamless. If Jax's new place auto-assigns a starting team on purpose (e.g. Visitors or Recruits), skip init() or make lock() exempt that team.
- Remove or disable any free-model Autoteam or team-assignment scripts in the new place (v1's place still had one enabled), or they will override this module for every player who joins after init
- Make sure the place has a Neutral SpawnLocation (or use SpawnService), since teamless players cannot use team-only spawns
- Wire a real caller to assign(). v1 never called it (that recruiting flow was never built).
- If divisions get saved in a DataStore, restore them after init(), because init() clears the teams of everyone present at that moment (lines 45-47)
- Optionally check teamName against a list in Config so a typo fails loudly instead of quietly returning false (lines 26-28)

**Known issues**

- Line 25: assign() has no callers anywhere in src (grep confirms), so v1's own code never gave anyone a division (docs/HOW_IT_WORKS.md:62 says the same). Whether players actually had Teams in play depended on the place. The archived place/parris_island.rbxl still runs an enabled ServerScriptService.Autoteam script that sets player.Team on PlayerAdded for group members, which would feed SpawnService.lua:56 and OverheadService.lua:81/116.
- Lines 38-48: the "nobody has a division" guarantee only holds against Roblox's own auto-assign. init() clears only players present when it runs (lines 45-47) and adds no PlayerAdded hook, so any other script that sets Team on join (like the place's Autoteam) wins for every later joiner.
- Lines 45-47: clearing Team only changes the next spawn point through SpawnService's Team-changed hook (SpawnService.lua:67, which runs earlier at init.server.lua:27 vs :30). A player whose character already spawned at a team spawn stays there until they respawn.

</details>

### XP, rank and saving

ProgressionService keeps each player's service record ({xp, sessions}) in the DataStore named by Config.Progression.DataStoreName ("ServiceRecords_v1", Config.lua:137), under keys "player_<UserId>" (line 47). It uses RankCatalog to turn total XP into a rank index. Its public members are awardSession, getRank, getRecord, init, and a RankChanged event that fires on load (line 99) and on promotion (line 153). getRecord is not called anywhere in v1. In v1, DrillService.debriefPhase calls awardSession at DrillService.lua:233 and announces any promotion. OverheadService reads getRank, RankCatalog.displayName and rank.insignia to build the overhead nametag (OverheadService.lua:80-108), and redraws it when RankChanged fires (OverheadService.lua:147-149). Neither file requires a sibling service: ProgressionService needs only the shared modules Config, Types and RankCatalog, and RankCatalog needs only Types. That makes this pair one of the easiest parts of v1 to reuse (CommandCatalog is the other one that depends only on Types). RankCatalog can be copied as is, together with Types. ProgressionService needs new require paths, a Config.Progression block, and a call from whatever ends an activity in the new game. Its save logic has known weak spots: no session lock, no retry after a failed load or leave-save, and a possible double write on shutdown. These are worth fixing before the new game depends on it. The 'Recruit' rung was removed on purpose after the first playtest (commit 2b56e1d), so starting everyone as 'E-1 Private' is by design. All eight chevron images were confirmed as Image assets uploaded in 2022 by the Roblox user 'iGriffn'.

<details>
<summary><b><code>src/server/ProgressionService.lua</code></b> — adapt · 193 lines</summary>

Saves each player's XP and the number of drill sessions they've finished to Roblox's cloud save (DataStores), so their Marine rank carries over between visits. Other code calls it at the end of a drill to hand out XP, and listens to it to find out when someone gets promoted.

**Verdict: adapt.** The save logic is self-contained and does not require any sibling service. Its only dependencies are three shared modules plus a Config.Progression table. The edits needed are small but required: the require paths are hard-wired to ReplicatedStorage.Shared (lines 23-26), the awardSession(score, demerits) signature (line 133) and the ScoreToXp tuning assume v1's drill scoring, and the saved record shape is hard-coded in two places (load at lines 79-80, save snapshot at line 112). The save logic also has the weaknesses listed under known_issues (no session lock, no retry after a failed load or leave-save). Fix these before relying on it.

**Requires:** `Config`, `Types`, `RankCatalog`  
**Required by:** init.server (Server entry, line 21; calls init() at line 31), DrillService (line 28; awardSession at line 233), OverheadService (line 32; getRank at line 80, RankChanged at line 147)  
**Config:** `Config.Progression`

**Needs from the place**

- DataStoreService access. There are two ways it can fail. (a) If the place has never been published, GetDataStore at line 55 fails: one warning prints at line 61, every player loads with canSave=false (lines 68-85), and no per-player warning appears. (b) If the place is published but Studio's Game Settings -> Security -> 'Enable Studio Access to API Services' is off (see the comment at lines 14-16), GetAsync fails at line 74 and each player gets a 'running unsaved' warning at line 83. Either way ranks still work during the visit, but nothing is saved.
- ReplicatedStorage must contain a child named 'Shared' (WaitForChild at line 23) holding ModuleScripts named Config, Types and RankCatalog (direct indexing at lines 24-26). RankCatalog in turn needs Types as its sibling (RankCatalog.lua:12).
- Config must define the Progression table with all five keys: DataStoreName (line 55), ScoreToXp (line 140), CompletionDemeritCap (line 141), CompletionXp (line 142) and AutosaveSeconds (line 187). A missing number key causes a nil-arithmetic or nil-comparison error inside awardSession. A missing AutosaveSeconds is worse because there is no error: task.wait(nil) waits only one frame, so the autosave loop runs every frame instead of every 120 seconds.
- A DataStore named Config.Progression.DataStoreName ('ServiceRecords_v1', Config.lua:137) with keys 'player_<UserId>' (line 47). Studio playtests with API access turned on read and write this same live store.
- Must run on the server (a ModuleScript under ServerScriptService or similar), because DataStoreService and game:BindToClose (line 183) are server-only. init() must be called exactly once from a server Script (v1: init.server.lua:31). Calling it twice would double every handler and the autosave loop.

**To reuse it**

- Lines 23-26: point the requires at wherever the new game keeps its config, types and rank list. Or make the module standalone by pasting the Rank and ServiceRecord types (Types.lua:72-87) and the Progression constants (Config.lua:128-140) into it.
- Copy the Config.Progression block (Config.lua:128-140) into the new game's config, with all five keys, and choose a fresh DataStoreName for the new game. ScoreToXp = 0.25 was tuned for v1's drill score of roughly 1,200-1,500 per session (comment at Config.lua:129-130), so retune it for whatever the new game scores.
- Lines 133-157: wire awardSession to whatever ends a training activity in the new game. If the new game has no score/demerits concept, simplify it to awardXp(player, amount) and keep the rank-change check at lines 149-155.
- Call ProgressionService.init() once from a server Script (v1 orders it at init.server.lua:29-32). Init order alone does not protect listeners. RankChanged fires once per player on load (line 99), and when no DataStore is available, load never yields, so that fire happens synchronously inside init (lines 170-172) before later services connect. Any RankChanged listener should therefore also call getRank(player) when a player joins or spawns. OverheadService already does this: refresh at OverheadService.lua:137, listener at line 147.
- To save anything new (for example, which training phases are complete), add it to Types.ServiceRecord, to the load parsing (lines 79-80) AND to the save snapshot (line 112). The save writes only xp and sessions, so any other field is silently dropped.
- Replace GetAsync/SetAsync (lines 74, 114) with UpdateAsync plus a session lock, or use a community library such as ProfileStore. This is especially important if the new game will teleport players between places or servers, or have more than one server.
- Add a retry with backoff around the join-time GetAsync (lines 73-84) and the leave-time save (lines 175-180), so one transient DataStore error does not cost a whole visit's progress.
- v1's saved records will not carry over unless the new game is published into the same Roblox experience (universe), because DataStores are scoped per experience. Expect everyone to start at zero.

**Known issues**

- Lines 74 and 114: plain GetAsync on join and SetAsync on leave, with no session lock and no UpdateAsync. If a player leaves server A and quickly joins server B (or rejoins the same server), B can read the record before A's leave-save lands. When B later saves a dirty record (autosave or leave), it overwrites A's progress with the older value plus B's gains.
- Lines 70-85 and 103: a failed load is never retried. If GetAsync fails (line 74), or the store could not be obtained at all (ds == nil at line 71, which prints no per-player warning; only the one-time warn at line 61), canSave stays false for the whole visit. awardSession still adds XP and fires promotions in memory, so the player sees a promotion that disappears when they rejoin. The only signal is a server-side warn(); the player is never told.
- Lines 175-180 together with 113-120: if the leave-time SetAsync fails, the handler still clears entries[player] (line 179). Progress since the last successful save, up to AutosaveSeconds = 120 s (Config.lua:139), is lost without any retry. In contrast, a failed autosave keeps dirty = true and is retried on the next pass.
- Lines 134-136: awardSession returns (0, nil) if the player's load is still waiting on GetAsync, because entries[player] is set only at line 98. That session's XP and its session count are dropped, not queued. The chance is small, since it needs a player who joined seconds before debrief.
- Lines 175-183: on server shutdown, PlayerRemoving's save(player) and BindToClose's saveAll() can both run while the other's SetAsync is still in progress. dirty is cleared only after SetAsync returns (line 117), and entries[player] only after save returns (line 179), so the same key can get two SetAsync calls. Writing one key twice within the per-key limit triggers DataStore queue/throttle warnings. saveAll (lines 123-127) also saves one player at a time, all inside BindToClose's 30-second shutdown budget.
- Line 166: getRecord returns the live record table, not a copy. A caller that edits it does not set dirty, so the change is saved only if a later awardSession marks the entry dirty. getRecord is unused in v1, but a new caller could hit this.

</details>

<details>
<summary><b><code>src/shared/RankCatalog.lua</code></b> — drop-in · 57 lines</summary>

The rank ladder: nine enlisted Marine ranks from Private (E-1) to Master Gunnery Sergeant (E-9), the total XP needed for each, and the chevron image for each rank above Private (E-1 has none, matching the real insignia). It also has small helpers that answer 'what rank is this much XP?' and 'what is this rank's display name?'.

**Verdict: drop-in.** Pure data plus four tiny lookup functions, with no services, no Instances and no Config. Copying it together with Types.lua as a sibling makes it work unchanged in any codebase. Types.lua is pure type declarations with no requires, so the only extra file needed is Types.lua itself, or just the 10-line Rank type (Types.lua:72-81). It lives in shared storage, so client UI can require it too.

**Requires:** `Types`  
**Required by:** ProgressionService (line 26; indexForXp at lines 94 and 149, get at lines 99, 152 and 161), OverheadService (line 30; displayName at line 108)  

**Needs from the place**

- Must sit as a sibling of a ModuleScript named 'Types' (require(script.Parent.Types) at line 12). Types.lua requires nothing itself.
- The insignia images at lines 18-25 must stay available on Roblox. Checked via the Roblox economy API (economy.roblox.com/v2/assets/<id>/details): all eight are Image assets (AssetTypeId 1, which is what ImageLabel.Image at OverheadService.lua:99 needs), named 'Images/E2-private-first-class' through 'Images/E9-master-gunnery-sergeant'. They were uploaded by the Roblox user 'iGriffn' in Feb 2022 (E-7, id 9431131770, in Apr 2022), an account not mentioned anywhere in this repo.

**To reuse it**

- Line 12: to make it fully standalone, replace require(script.Parent.Types) with an inline copy of the Rank type (Types.lua:72-81).
- Lines 17-25: retune the xp column to the new game's XP earn rate. The header comment (lines 8-9) notes this column sets the whole pacing of the game.
- Optional: bring back a 'Recruit' starting rung. It was removed on purpose in commit 2b56e1d after the first playtest, so the ladder starts at 'E-1 Private'. The row removed then was { name = "Recruit", short = "Rct", grade = "", xp = 0, insignia = "" }, with Private at 300 XP and every higher threshold one step further up. Include the short field: Types.Rank requires it (Types.lua:74), and leaving it out is a --!strict type error. displayName already handles an empty grade (lines 51-53).
- Keep RANKS sorted by ascending xp. indexForXp (lines 31-39) takes the last entry whose threshold is met and does not check the order.
- Consider re-uploading the chevron images under the family's own account or group, so the game does not depend on a stranger's assets staying up.
- Unused in v1 but ready for a 'next promotion at N XP' progress bar: RankCatalog.Ranks (line 28), RankCatalog.next (line 45), and the 'short' field.

**Known issues**

- Lines 51-53 and Types.lua:75: the rank.grade == "" branch is dead code, and the Types comment 'Empty for Recruit' is out of date. Every entry at lines 17-25 has a grade, because commit 2b56e1d removed the Recruit rung on purpose. Every player starts as 'E-1 Private' by design, not by bug. The leftovers are harmless, but they suggest a Recruit rung exists when it does not.
- Line 7 (and Types.lua:79) describe insignia as 'decal ids', but the ids are actually Image assets (confirmed via the Roblox economy API). Image assets are what ImageLabel.Image needs (OverheadService.lua:99). Someone who follows the comment and pastes a Toolbox Decal id would get a blank chevron.
- Lines 18-25: all eight insignia images belong to a third-party Roblox user ('iGriffn'). If those assets are moderated or deleted, the chevrons silently go blank.

</details>

### Overhead nametag

OverheadService is the only file in this group, and it only reads from other systems. It gets the rank and insignia from ProgressionService (which turns XP from DrillService into a rank using RankCatalog and saves it to a DataStore), the division from player.Team, and all sizes, layout bands and colors from Config.Overhead. No v1 code ever assigned a Team, so the division line was always hidden. It is started once from init.server.lua:32, after ProgressionService.init(). It rebuilds a BillboardGui inside the character's Head on the server whenever the player respawns, changes team, or RankChanged fires. Its ties to the rest of v1 are small: ProgressionService.getRank, ProgressionService.RankChanged and RankCatalog.displayName. That makes it a good candidate to adapt once we know how the new game tracks rank. Carrying ProgressionService over unchanged would not be enough, because only v1's drill loop ever awarded XP. Before installing it, remove any free-model overhead (the 'RankUI' tag) from the new Studio place, or players will show two tags.

<details>
<summary><b><code>src/server/OverheadService.lua</code></b> — adapt · 152 lines</summary>

Puts a floating name tag above every player's head showing their rank badge, username, rank title (e.g. "E-3 Lance Corporal") and division (their Team). The server builds the tag, so every player sees it without any client code. It rebuilds when the player respawns, gets promoted, or changes team.

**Verdict: adapt.** The tag-building logic is self-contained and portable: a code-built BillboardGui parented to the Head, fixed vertical bands from Config.Overhead, the division line driven by player.Team, and the default name hidden. It reaches into v1 at only three points: ProgressionService.getRank (line 80), ProgressionService.RankChanged (line 147) and RankCatalog.displayName (line 108). Copying ProgressionService along unchanged is not a real drop-in. Its only XP source is DrillService.awardSession (DrillService.lua:233), so without v1's drill loop every player would stay 'E-1 Private' forever. The realistic path is to keep this file and repoint those calls at whatever rank source the new game has.

**Requires:** `Config`, `RankCatalog`, `ProgressionService`  
**Required by:** src/server/init.server.lua (line 22 require, line 32 OverheadService.init())  
**Config:** `Config.Overhead`

**Needs from the place**

- ReplicatedStorage must contain an instance named "Shared" holding the Config and RankCatalog ModuleScripts (lines 28-30). Line 28's WaitForChild has no timeout, so if Shared is missing the script never gets past it: Roblox prints an 'Infinite yield possible' warning and waits forever. RankCatalog in turn requires a sibling Types module (RankCatalog.lua:12).
- A ModuleScript named "ProgressionService" must sit next to this one, under the same parent (script.Parent, line 32), and expose getRank(player) and a RankChanged signal (used at lines 80 and 147). Through that module it also needs DataStoreService, the Config.Progression section and Shared.Types (ProgressionService.lua:19-26, 55). Ranks only save in Studio if 'Enable Studio Access to API Services' is turned on (ProgressionService.lua:14-16).
- Each player's character needs a child named "Head" within 10 seconds of spawning (line 58; HEAD_WAIT_SECONDS at line 37). Standard R6 and R15 rigs have one. A custom StarterCharacter without a Head never gets a tag.
- A Humanoid in the character is optional (line 64, FindFirstChildOfClass). It is only used to hide Roblox's default name and health display (line 66).
- Teams are optional (player.Team at lines 81 and 112-116, and the Team-changed signal at line 134). The Division line stays hidden while a player has no Team. Note that v1 never actually set a Team: DivisionService.assign (DivisionService.lua:25) is never called anywhere, and DivisionService.init turns AutoAssignable off and clears teams (lines 39-47). So in v1 the Division line was always hidden. In a new game, any Team assignment shows here, including Studio AutoAssignable teams, but those scatter joiners at random (DivisionService.lua:5-7; commit 2b56e1d).
- The insignia image ids at RankCatalog.lua:18-25 must load as images when set on ImageLabel.Image (line 99). They are the same ids the old free-model overhead in the v1 place set from a script (ui.RankInsignia.Image = v.ImageID in the decoded place/parris_island.rbxl), so they probably work. Still, look at one promoted rank in a Play test.
- Must run from a server Script (v1: ServerScriptService.Server). The GUI is parented into the character's Head on the server so it replicates to every client (line 119), and the ProgressionService it depends on uses DataStores, which only work on the server.

**To reuse it**

- Change the require paths for the new place. Line 28 assumes ReplicatedStorage.Shared, and line 32 assumes ProgressionService is a sibling under the same parent (script.Parent). Point them at wherever the new game keeps its modules.
- Replace the rank source. Line 80 needs something with an .insignia image id ("" for none) that RankCatalog.displayName (line 108) can turn into a title. Line 147 needs a signal that fires (player) when the rank changes. If the new game stores rank in leaderstats, an Attribute or a Roblox group rank, read that instead and connect to its .Changed / GetAttributeChangedSignal.
- If you do carry ProgressionService over, you also need Types.lua, RankCatalog.lua and the Config.Progression block. Something in the new game must also call ProgressionService.awardSession, because v1 only did that from DrillService.lua:233. Also, DataStores belong to a single experience, so if the new game is a separate experience, ranks saved in the old game will not carry over.
- If RankCatalog is not brought over, replace RankCatalog.displayName(rank) at line 108 with the new game's rank-name lookup. Or copy RankCatalog.lua, which depends only on Types.
- Copy the Config.Overhead block (Config.lua:142-167: WidthStuds, HeightStuds, StudsAboveHead, MaxDistance, Bands, Font, colors, stroke) into the new game's config, or inline it as a local table at the top of the file.
- Call OverheadService.init() once from a server Script, after the rank system has started. v1 did this at init.server.lua:32, right after ProgressionService.init() at line 31.
- Before installing, search the new Studio-built place for an existing free-model overhead and remove it. Commit 43258ba records two in the v1 place, "OverheadService" and "OverHeadUI", and both are still in the v1 place snapshot. The free model names its tag "RankUI" and parents it to the character on CharacterAppearanceLoaded. This file's cleanup loop (lines 71-76) only removes "Overhead", so leaving the free model in would show two stacked tags. A second script named OverheadService in the same folder would also make the require paths ambiguous.
- Decide between username and display name. Line 107 uses player.Name; swap to player.DisplayName if wanted, since line 66 hides Roblox's own name label.
- Optional cleanup: lines 69-76 also search the character for an old-style tag ('Older builds parented it to the character'). A fresh game only needs the Head check. Line 89 (ResetOnSpawn) has no effect on a GUI that is not in PlayerGui and can be dropped.
- If the new game has health or damage (e.g. an obstacle course), do not use DisplayDistanceType.None at line 66, because it hides the health bar too. Hide only the name another way, for example leave DisplayDistanceType at Viewer and set Humanoid.NameDisplayDistance = 0, and check in a Play test that health bars still show.
- The comments at RankCatalog.lua:7 and Types.lua:79 call the insignia 'decal ids'. ImageLabel.Image needs an image id. These particular ids were already used that way by the old free model, but any new insignia must be image ids: paste a decal into a Studio ImageLabel to get the converted id.

**Known issues**

- Line 66: Humanoid.DisplayDistanceType = None hides Roblox's default health bar as well as the name, but the comment at line 63 mentions only the name. Any health or damage mechanic in the new game would have no visible health bar.
- Lines 58-61: if the character's Head does not appear within HEAD_WAIT_SECONDS (10, line 37), build() returns silently with no warn(). The player gets no tag, nothing is logged, and it is not retried until the next respawn, team change or rank change.
- Lines 80 + 147: on join, ProgressionService loads the saved record with a yielding GetAsync (ProgressionService.lua:73-75). If the character spawns before that finishes, getRank falls back to index 1 (ProgressionService.lua:161), so a high-ranked player briefly shows 'E-1 Private' with no insignia. The RankChanged fired at the end of the load (ProgressionService.lua:99) then rebuilds the tag, so it fixes itself. It is a brief visual glitch, not lost data.

</details>

### Client (HUD and input)

init.client.lua is v1's only client script. It mounts DrillHud and listens on four server-to-client RemoteEvents from Shared.Remotes (IssueCommand, Feedback, PhaseChanged, Scoreboard). It sends key presses to the server as {sequence, action} on SubmitAction: Q/E/X are the facing movements and 1-4 answer the call-and-response questions. It never grades, scores or times anything itself. DrillHud.lua is a passive display built in code, with an imperative API (mount/setPhase/showCommand/markSubmitted/clearCommand/showFeedback/showScoreboard/hideScoreboard). Its only project dependency is Shared.Types, used for annotations only, though the require still runs. The client half is small and self-contained: Remotes and Types plus these two files. It does nothing, though, unless a server fires those five events with v1's payload shapes and a server script has required Shared.Remotes to create them. In v1 that server is DrillService, which drags in FormationService, RecruitService, ProgressionService (and through it RankCatalog), CommandCatalog and Config. Sharp edges for reuse: input is keyboard-only (no touch or gamepad); layout is fixed-pixel (long calls and debrief text overflow, the scoreboard overflows past 8 players); the timer bar's red threshold (0.4) does not match the server's crisp cutoff (0.45) and lags by the network delay; late joiners get no state sync; and the script must stay in StarterPlayerScripts, or respawns will stack duplicate HUDs.

<details>
<summary><b><code>src/client/DrillHud.lua</code></b> — adapt · 302 lines</summary>

Draws the drill's on-screen display: the phase banner, the drill instructor's shouted command, a countdown bar, the answer choices, the instructor's reaction to your last move, your score/demerits/streak, and an end-of-round scoreboard. It only shows what the server tells it and makes no decisions.

**Verdict: adapt.** Its only dependency is Types, and only for annotations. The public API (mount/setPhase/showCommand/markSubmitted/clearCommand/showFeedback/showScoreboard/hideScoreboard) is a clean seam any game could call. But it is hard-wired to v1's payload shapes (PhasePayload, CommandPayload, FeedbackPayload, ScoreRow), v1's grade names (GRADE_COLORS lines 247-253) and v1's Q/E/X key hints (lines 200-202), and it uses a fixed-pixel layout that assumes a keyboard. If the new game's HUD was built in Studio, the useful parts are the API shape and the countdown-bar and fading-bark logic, not the Instance.new layout.

**Requires:** `Types`  
**Required by:** init.client.lua  

**Needs from the place**

- ReplicatedStorage.Shared folder (WaitForChild at line 17, no timeout) containing a Types ModuleScript (indexed directly as Shared.Types at line 18). Types returns {} at runtime (Types.lua line 106), so only the annotations use it. The require still runs, though, and errors if Types is missing.
- Must run on the client: it uses Players.LocalPlayer:WaitForChild('PlayerGui') (line 58) and RunService.RenderStepped (line 216).
- Builds its own ScreenGui named 'DrillHud' in PlayerGui with ResetOnSpawn = false (lines 60-65), so no Studio-authored UI is needed. A Studio ScreenGui with the same name in the new game would sit alongside it and would not be reused.

**To reuse it**

- Replace `require(Shared.Types)` (lines 16-18) with the new game's types location, or inline the four payload types. The return value is unused at runtime, but the require call still executes and errors (or yields forever at line 17) if the path does not exist.
- If the new game already has a Studio-built ScreenGui, rewrite mount() (lines 53-161) to find existing elements with WaitForChild instead of creating them, and keep the setPhase/showCommand/showFeedback/showScoreboard API.
- Move the movement key hints (lines 200-202) into one shared key-binding table that the input script also reads. init.client.lua lines 28-32 currently duplicate them.
- Update the GRADE_COLORS keys (lines 247-253) to match the new game's grade names. Unknown grades silently fall back to KHAKI (line 257).
- Make it work on phones: turn the option TextLabels (lines 39, 180-186) into TextButtons that call back into the input script. Switch the fixed pixel sizes (lines 87, 105, 127, 137, 182) to scale plus UISizeConstraint, and use TextWrapped/TextScaled (newLabel forces TextScaled = false at line 47). Move the stats readout (line 126) away from the bottom-left corner, where the mobile thumbstick sits.
- Make the scoreboard a ScrollingFrame (or cap the rows) and truncate names (lines 151-160, 280-291).
- Optionally show PhasePayload.duration as a countdown. The server sends it (DrillService.lua lines 178, 244), but setPhase ignores it (lines 163-171).
- Drive the timer-bar color threshold (line 220) from a value the server sends, such as the crisp fraction, instead of the hardcoded 0.4.
- Reconsider IgnoreGuiInset = true (line 63) together with the banner at y=24 (line 69), or move the banner below the Roblox top bar.

**Known issues**

- Line 220 vs Config.Scoring.CrispFraction = 0.45 (Config.lua line 112) and DrillService.lua line 111: the bar turns red when remaining < 0.4, which is after 60% of the 6s window has passed (3.6s). The server's Crisp cutoff comes at 45% (2.7s). Between about 2.7s and 3.6s the bar is still yellow, but the answer already grades as Slow, so the color misrepresents the scoring.
- Line 215: the countdown starts at the client's os.clock() when IssueCommand arrives. The server starts its window at issuedAt (DrillService.lua line 121), timestamps answers when they arrive (line 287), and grades after task.wait(window) (lines 130-132). The bar therefore runs behind the server by the network delay. An input in roughly the last round-trip of a bar that still looks non-empty arrives after grading and counts as NoResponse. RecruitService.clearPending at DrillService.lua line 119 then discards it.
- Lines 68-73: phaseLabel is a single 24px-tall line, with TextScaled = false (line 47) and no TextWrapped. The debrief message joins every promotion into one string (DrillService.lua lines 239-242), so with several promotions the centered text runs off both edges of the screen.
- Lines 76-80: callLabel uses TextSize 52, with no wrapping or scaling. A call like 'WHAT MAKES THE GRASS GROW?' (CommandCatalog.lua line 61) is about 850-900px wide at that size, likely wider than a phone's landscape width in Roblox UI units, so it overflows on small screens.
- Lines 137, 154, 159, 280-291: the scoreboard list area is 300-74 = 226px tall, and each row takes 24px plus 4px padding, so 8 rows fit. RecruitService.scoreboard() (RecruitService.lua lines 148-161) returns every player. With 9 or more players, rows draw below the list and past the bottom of the frame, because there is no ScrollingFrame and ClipsDescendants is not set.
- Line 285: '%-16s' pads names to line up the columns, but GothamBold is a proportional font, so the columns do not line up. Display names longer than 16 characters (up to 20 are allowed) are not truncated and push the columns out further.
- Lines 39 and 180-186: 'optionButtons' are TextLabels created by newLabel (line 42) and have no click handling, so the answer choices cannot be tapped. Together with keyboard-only input in init.client.lua, this means mobile and console players cannot answer.
- Lines 163-171, 188-245 and 255-294: every public function except hideScoreboard (guarded at line 297) dereferences module locals that only mount() assigns, so calling any of them before mount() throws an 'attempt to index nil' error. It works in v1 only because init.client.lua calls mount() first (line 20).
- Lines 63 and 69: with IgnoreGuiInset = true, y=0 is the top of the screen, so the 24-48px phase banner sits inside Roblox's top-bar strip. Short centered messages clear the corner buttons, but long ones (the debrief promotions) run underneath them.

</details>

<details>
<summary><b><code>src/client/init.client.lua</code></b> — adapt · 99 lines</summary>

The game's client-side starting script. It puts the drill display on screen, listens for the server's commands, results, phase changes and scoreboard, and tells the server which key the player pressed. It never decides whether an answer was right or how fast it was; the server does.

**Verdict: adapt.** It is small and depends only on self-contained modules: Remotes has no project requires, and Types is used only for annotations. The client half can be copied as a unit (this file, DrillHud, Remotes, Types). It is pure glue for v1's five-event drill protocol, though. Without a server that speaks that protocol (v1's DrillService, which pulls in Formation/Recruit/Progression services, Config, CommandCatalog and RankCatalog) it does nothing. The parts worth keeping are the patterns: a one-shot submit gated on the command's sequence number (lines 41-53), key-to-action maps, and no client-side grading.

**Requires:** `Remotes`, `Types`, `DrillHud`  
**Required by:** nothing  

**Needs from the place**

- Must be a LocalScript with a ModuleScript child named 'DrillHud' (script.DrillHud, line 18). In v1 this is StarterPlayerScripts.Client, which runs once per session. Keep it there. In StarterGui or StarterCharacterScripts it would re-run on every respawn, and because DrillHud's ScreenGui has ResetOnSpawn = false (DrillHud.lua line 62) while each new clone gets a fresh DrillHud module (so the `if gui` guard at line 54 does not help), every respawn would leave a stale, frozen copy of the HUD behind.
- ReplicatedStorage.Shared folder (WaitForChild at line 14) containing Remotes and Types ModuleScripts (lines 15-16).
- A ReplicatedStorage.Remotes folder holding RemoteEvents named IssueCommand, SubmitAction, Feedback, PhaseChanged and Scoreboard. On the client, Remotes.lua waits for these with WaitForChild and no timeout (Remotes.lua lines 46, 52), so a server script must have required Shared.Remotes, which creates them (Remotes.lua lines 28-44; v1 does this at init.server.lua line 15). Otherwise this script yields forever at line 15.
- A server-side script that fires those events with v1's payload shapes and listens on SubmitAction (v1: DrillService.lua lines 43, 122, 147, 245, 271).

**To reuse it**

- Change `require(script.DrillHud)` (line 18) to wherever the HUD module lives in the new game, e.g. a ModuleScript in ReplicatedStorage if the client entry is a Studio LocalScript.
- Rename or rewire the remote names (lines 47, 55, 64, 75, 79) to the new game's events, or bring Shared/Remotes.lua along and make sure a server script requires it at startup.
- Before bringing Remotes.lua along, check the new game for an existing ReplicatedStorage child named 'Remotes'. Remotes.lua reuses it (lines 29-31), only adds events whose names are missing (lines 38-43), and casts whatever it finds to RemoteEvent (line 52). An existing 'Feedback' or 'Scoreboard' object would be silently shared or would break.
- Add touch and gamepad input, either with ContextActionService and on-screen buttons or with clickable HUD options that call submit(). Input today is UserInputService.InputBegan with KeyCodes only (lines 83-99).
- Define the movement action strings 'Left'/'Right'/'About' (lines 28-32) once in shared code, or as a literal union in Types. The server matches them by string (DrillService.lua lines 52-56, 90), and Types.ActionPayload.action is plain `string | number` (Types.lua line 39), so strict mode will not catch a typo.
- Also clear activeSequence/activeKind/hasSubmitted in the PhaseChanged handler (lines 75-77), not only on a matching Feedback.
- Extend RESPONSE_KEYS (lines 34-39) if any command can have more than 4 options.
- Add an initial-state sync, such as a RemoteFunction or a server-side PlayerAdded send of the current phase and command, so late joiners are not left with a blank HUD.

**Known issues**

- Lines 83-99: input is keyboard-only (Q/E/X, then 1-4 via KeyCode), with no touch or gamepad path. Mobile and console players can see commands but never answer, so every command grades as NoResponse for them (or LeftFormation if they are off a pad).
- Lines 34-39 and 95: only keys 1-4 are mapped, but DrillHud.showCommand gives every option a number label (DrillHud.lua lines 196-198). A Response command with 5 or more options in CommandCatalog would show a '[5]' choice the player can never select. This is latent today, since every v1 command has 3 options (CommandCatalog.lua lines 41-62).
- Lines 28-32 duplicate the key bindings that DrillHud hardcodes as hint text (DrillHud.lua lines 200-202). Changing a key in one file and not the other makes the on-screen hints wrong.
- Lines 64-77: client state (activeSequence/activeKind) is reset only by a Feedback whose sequence matches. PhaseChanged clears the prompt on screen (DrillHud.lua lines 168-170) but leaves this state set. v1 gets away with it because DrillService sends Feedback to every recruit after every command (DrillService.lua lines 133-157) and rejects stale sequences (line 280). A server that skips Feedback for some players would leave this client accepting keys for a command that is no longer on screen.
- Lines 75-77: the client only learns the phase from transitions. The server broadcasts PhaseChanged only at phase changes (DrillService.lua lines 42-49, called at 171, 178, 209, 244, 254), and nothing sends the current state to a new player. Someone who joins mid-session sees an empty banner (DrillHud.lua line 73) until the next transition. They can also receive a Feedback (shown unconditionally at line 72) for a command they never saw, because DrillService grades every player in RecruitService.all().
- Lines 34-39: keys One-Four are also Roblox's default Backpack hotbar keys. v1 gives no tools, but if the new game does (with the backpack CoreGui enabled), pressing 1-4 to answer would also equip or unequip hotbar tools.

</details>

### Studio command-bar tools

These are three standalone Studio Command Bar utilities. None requires another module and nothing requires them; the only outside reference is docs/HOW_IT_WORKS.md:47, which mentions MapInventory. The game never loads them at runtime. They sat in src/shared so Rojo would put them in ReplicatedStorage.Shared, where the Command Bar usage lines could require them. They don't touch Config, Types, Remotes or any service, so they are the most portable code in v1, but each has caveats before it goes into Jax's new game.

MapInventory (drop-in) prints the Workspace map with positions and sizes. It is good for a quick look at the new map's layout, but it does not list scripts outside Workspace. For the new game's code structure, the planned .rbxlx export into the repo's place/ folder is the right tool.

MapBlockout (adapt) stamps landmark placeholder blocks at fixed coordinates around origin for an empty baseplate. Its LANDMARKS table is the reusable part. Running build() again wipes hand-adjusted blocks.

SecuritySweep (adapt) scans and repairs scripts for the specific v1 malware. Don't run it as-is: its own header (line 19) matches its own `getfenv()[` marker, so scan() flags itself and clean() truncates itself into a syntax error. With the one-line self-exclusion fix, scan() is a sensible read-only first check on the new place. Its generic patterns are narrow, and clean() is tuned to the v1 snapshot.

The archived place file is CONFIRMED still infected (see the warning at the top of this README). Scan anything before copying it out.

<details>
<summary><b><code>src/shared/MapInventory.lua</code></b> — drop-in · 102 lines</summary>

A helper you run by hand in Roblox Studio. It prints a text list of what is in the game world (Workspace): each building or model, how many pieces and scripts it holds, where it sits and how big it is. Someone who can't see the map can still follow it.

**Verdict: drop-in.** It requires nothing, and nothing requires it. The only reference anywhere in the repo is docs/HOW_IT_WORKS.md:47. It reads only Workspace, so copying the ModuleScript into any place works with no other edits. It gives a quick text overview of the new game's MAP (positions and sizes). It does not cover the new game's CODE: scripts in ServerScriptService, StarterPlayer, ReplicatedStorage and so on are not listed, and only scripts inside Workspace models are counted. An .rbxlx export into the repo's place/ folder (see place/README.md) is the better way to learn the new game's code structure.

**Requires:** nothing  
**Required by:** nothing  

**Needs from the place**

- Reads only `workspace` and its descendants (line 92, `collect(workspace, ...)`). It skips Terrain and Camera (line 79) and needs no tags, named parts or services.
- Meant to be run from the Studio Command Bar in Edit mode (header line 6). The usage comment assumes the path ReplicatedStorage.Shared.MapInventory (lines 7, 11), which only exists while Rojo syncs src/shared. If it is run from a client in Play mode in a place with StreamingEnabled, Workspace holds only the parts streamed in so far, and the list comes out partial.

**To reuse it**

- Put it in the new place as a ModuleScript. ServerStorage is better than ReplicatedStorage, because a dev tool doesn't need to be sent to every player. Update the require path in the usage comment (lines 7, 11), e.g. `require(game.ServerStorage.MapInventory).print(2)`.
- Optional accuracy fix at lines 33-34: work out each part's box from `part.CFrame` (rotation plus position) instead of `Position +/- Size/2`, so rotated parts report their real footprint.
- Optional at line 82: when siblings share a name, add the sibling index to the path (e.g. `Part#3`) so each line points at exactly one object.
- Optional at line 93: sort children inside collect() (by name, per parent) instead of sorting the whole formatted output, so children always print right under their parent.
- Optional: to list code as well as the map, call collect() on ServerScriptService, ReplicatedStorage and StarterPlayer too (line 92).

**Known issues**

- Lines 33-34: each part's box is `part.Position +/- part.Size/2` in world axes, so rotation is ignored. A 100x1x10 road turned 90 degrees reports as 100 wide along X when it actually runs along Z. One rotated part still reports the correct center (its Position) but the wrong size. A model built from rotated parts can report both the wrong size and the wrong center.
- Line 82: paths are built only from `child.Name` joined with '.'. Siblings with the same name (dozens of 'Part' or 'Model' from free models are common) print identical paths. A name that itself contains '.' makes the path ambiguous.
- Line 93: `table.sort(lines)` sorts whole formatted lines byte by byte. At depth 2 or more, a sibling whose name sorts in between can separate a child from its parent. For example the order comes out 'Workspace.A [', then 'Workspace.A-2 [', then 'Workspace.A.Child [', because '-' (0x2D) sorts between ' ' and '.'. The sort is also case-sensitive, so all capitalized names come first.
- Line 79: Terrain is always skipped, so a map built mostly from Terrain looks nearly empty in the output. Only parts and models are reported.

</details>

<details>
<summary><b><code>src/shared/MapBlockout.luau</code></b> — adapt · 100 lines</summary>

A one-time helper you run by hand in Roblox Studio. It drops labeled, colored placeholder blocks into an empty world, one for each real Parris Island landmark (causeway, main gate, Receiving, yellow footprints, parade deck, Iron Mike, three barracks, mess hall, chapel, confidence course, rifle range), as a rough guide for where to build.

**Verdict: adapt.** It has no dependencies and runs in any place as-is. But every coordinate (lines 32-44) is an absolute world position laid out around world origin for an empty baseplate (about 1600 studs across, per lines 17-18). In Jax's new Studio-built map the blocks land wherever origin happens to be and may overlap existing buildings. It is only worth running if the new map still needs a blockout. Otherwise the LANDMARKS table is useful as a reference list of real landmarks and their rough relative sizes and placement.

**Requires:** nothing  
**Required by:** nothing  

**Needs from the place**

- Creates, and looks up by name, a Workspace child folder called "MapBlockout" (lines 23, 88, 93).
- Must be run in Studio Edit mode from the Command Bar, and the place saved afterwards for the blocks to persist (header lines 6-12).
- Assumes the ground surface is at Y=0, as on the default Baseplate. Every landmark has pos.Y = 0 (lines 32-44), and blocks are placed at `lm.pos + (0, size.Y/2, 0)` (line 79).

**To reuse it**

- First check whether the new map already has these buildings. If it does, keep the LANDMARKS table (lines 31-45) as a reference and skip the tool.
- If it will be used: add an origin parameter, or anchor to a named marker part, in build() (lines 68, 79), so the footprints line up with the new map's coordinates and scale.
- Remove the `MapBlockout.clear()` call at line 69, or make build() stop if the folder already exists, so running it again can't erase blocks someone positioned by hand.
- Add `--!strict` at line 1 (project convention; the file currently has none).
- Store it in ServerStorage rather than ReplicatedStorage (players don't need it), and update the usage paths on lines 9 and 15.
- Before publishing, delete Workspace.MapBlockout, or give the blocks CanCollide=false and remove the labels once the layout is settled.

**Known issues**

- Line 69: build() starts by calling clear(), which destroys the whole Workspace.MapBlockout folder (lines 93-95). The header (lines 11-12) tells you to move and resize the blocks to match the satellite photo, so running build() a second time throws away all that hand alignment. The only notice is a 'MapBlockout: cleared.' print (line 96); nothing asks for confirmation. Blocks deleted because their building was finished also come back.
- Lines 32-44 with line 79: positions are hard-coded world coordinates around (0,0,0), the ground is assumed to be at Y=0, and there is no offset or scale input. In a map that isn't an empty default baseplate, the blocks can overlap or be buried in existing geometry.
- Lines 52-53, 77, 88: the blocks are real anchored parts, collidable by default, saved into Workspace, each carrying an AlwaysOnTop BillboardGui visible up to 800 studs. Any block left in place ships to players as a gray collidable box with a floating label that shows through walls.

</details>

<details>
<summary><b><code>src/shared/SecuritySweep.luau</code></b> — adapt · 112 lines</summary>

A virus scanner and cleaner you run by hand in Roblox Studio. It looks through every script in the game for the specific hidden 'backdoor' malware that came in with free Toolbox models in the old map (the 'Anti-Lag' worm, and code injected into truck seats and a hat). scan() only reports; clean() deletes or rewrites scripts.

**Verdict: adapt.** It has no dependencies and scans the whole place, but it is not safe to drop in as-is. Its own header comment (line 19) contains the text `getfenv()[`, which matches its own injection marker (line 28). Wherever the module sits in the place, scan() reports SecuritySweep itself as [BACKDOOR], and clean() 'repairs' it by cutting its source off at line 19, leaving an unterminated comment, so the tool breaks itself. scan() is still read-only and worth running on Jax's new game once its own script is excluded (a one-line fix). Its generic REVIEW patterns (lines 31-35) cover only three literal strings, though, and clean() is tuned to the exact malware in the 2026-09-05 v1 snapshot, so a clean result on the new game is weak evidence.

**Requires:** nothing  
**Required by:** nothing  

**Needs from the place**

- Needs plugin-level permission to read and write Script.Source (read at line 45, write at line 97), so it must be run from the Studio Command Bar or a plugin. Use Edit mode so the changes can be saved.
- Walks every instance in the whole game via `game:GetDescendants()` (line 42), including the SecuritySweep ModuleScript itself.
- Finds the worm only by an exact script name of "Anti-Lag" (lines 68, 92).
- The place must be saved or published after clean() for the fix to stick (header line 11).

**To reuse it**

- At line 43, skip the module itself (`if inst ~= script and inst:IsA("LuaSourceContainer") then`), or reword header line 19 so it no longer contains the literal `getfenv()[`. Otherwise scan() flags itself and clean() truncates itself.
- Paste it into the new place as a ModuleScript (ServerStorage), then run `require(game.ServerStorage.SecuritySweep).scan()` from the Command Bar in Edit mode. Read every [REVIEW] line before running clean(). Update the usage paths on lines 8 and 10.
- At lines 44-49, count the scripts whose Source couldn't be read and print a warning (e.g. 'could not read N scripts: run from the Command Bar') instead of skipping them silently.
- At line 97, cut only the injected statement, or at least print the text being removed, rather than deleting everything from the marker to the end of the file.
- At line 68, also detect the worm by a fingerprint in its source, not only by its exact name.
- Widen REPORT_PATTERNS (lines 31-35) to cover other common loaders, e.g. `InsertService:LoadAsset`, `require(` followed by a variable or `tonumber(`, and long runs of `\ddd` escape strings.
- Add `--!strict` at line 1 and give the `callback` parameter a type at line 41 (project convention).

**Known issues**

- Line 19 with lines 28, 43 and 97: the module's own header comment contains `getfenv()['\114...'](5151855975)`, which matches INJECTION_MARKERS[2] (`getfenv%(%)%[`). game:GetDescendants() includes the SecuritySweep ModuleScript, so scan() prints '[BACKDOOR] ...SecuritySweep' and counts a false backdoor. clean() rewrites its own Source to `string.sub(src, 1, cut - 1)`. Simulated on the file: the result ends mid-comment at line 19 with no closing `]]`, so the next require() fails with a syntax error. If the place is then saved as step 4 says, the broken module is saved with it.
- Lines 44-49: if reading `.Source` fails, the pcall swallows the error and the script is skipped completely, including the name-only 'Anti-Lag' check at line 68. Run from an ordinary game Script, which isn't allowed to read Source, it skips every script, and line 84 reports '0 worm scripts, 0 injected backdoors, 0 to review': a false all-clear instead of an error.
- Line 97: clean() keeps only `string.sub(src, 1, cut - 1)`, deleting everything from the first marker to the end of the file. That only works if the injected code is always at the end. If a marker appears mid-script, or a legitimate script contains `getfenv()[` (line 28) or `--[[ Last synced` (line 27), all the real code after it is deleted too.
- Lines 68 and 92: worms are found by exact name only (`inst.Name == "Anti-Lag"`). A renamed copy or variant ('AntiLag', 'Anti Lag') is missed, and any script that happens to be named 'Anti-Lag' is queued and deleted at lines 103-106 without its contents being inspected.
- Lines 26-29 with 88-110: clean() only acts on the two snapshot-specific INJECTION_MARKERS. Scripts flagged by REPORT_PATTERNS (lines 31-35) are never touched or even mentioned, so 'repaired 0' from clean() (line 108) does not mean the place is clean. You have to review scan()'s [REVIEW] lines by hand.
- Lines 31-35: the generic REVIEW check matches only three literal patterns. `require(someVariable)`, `require(tonumber("..."))` and `InsertService:LoadAsset(...)` loaders are not reported, so a quiet scan of an unfamiliar place does not rule out a backdoor.

</details>

