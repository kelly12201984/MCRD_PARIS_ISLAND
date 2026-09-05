--!strict
--[[
	The drill loop. This is the beating heart of the vertical slice.

		Waiting  -> enough recruits on the server?
		FallIn   -> walk to the yellow footprints and claim a set
		Drill    -> N commands, each graded on correctness and speed
		Debrief  -> scoreboard, then round again

	Design note worth reading before you extend this: the loop is a plain
	sequential coroutine, not a state machine sprayed across event handlers.
	Roblox makes this easy with task.wait, and for a game whose whole structure
	is "a schedule that recruits are marched through", the code reading top to
	bottom like the schedule is a real maintainability win.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Remotes = require(Shared.Remotes)
local CommandCatalog = require(Shared.CommandCatalog)

local FormationService = require(script.Parent.FormationService)
local RecruitService = require(script.Parent.RecruitService)

local DrillService = {}

local rng = Random.new()
local sequence = 0
local running = false

local function log(message: string)
	if Config.Debug.Verbose then
		print(("[Drill] %s"):format(message))
	end
end

local function broadcastPhase(phase: Types.Phase, duration: number?, message: string)
	Remotes.PhaseChanged:FireAllClients({
		phase = phase,
		duration = duration,
		message = message,
	} :: Types.PhasePayload)
	log(("phase -> %s (%s)"):format(phase, message))
end

-- Maps a movement input to a facing change in quarter-turns clockwise.
local MOVEMENT_DELTA: { [string]: number } = {
	Left = -1,
	Right = 1,
	About = 2,
}

--[[
	Grades one recruit against the command that just went out.

	Returns the grade, and mutates the recruit's facing for movement commands --
	including when they get it wrong, because a recruit who faces the wrong way
	stays facing the wrong way. Compounding error is the whole point of drill.

	Returns nil for a recruit who is locked out on the quarterdeck: they are
	serving a penalty, so this command is simply not scored for them either way.
]]
local function gradeRecruit(
	state: Types.RecruitState,
	command: Types.Command,
	issuedAt: number,
	now: number
): Types.Grade?
	if RecruitService.isLockedOut(state.player, now) then
		return nil
	end

	if not FormationService.isHoldingPad(state.player) then
		return "LeftFormation"
	end

	local action = state.pendingAction
	if action == nil then
		return "NoResponse"
	end

	local correct = false

	if command.kind == "Movement" then
		local delta = MOVEMENT_DELTA[tostring(action)]
		if delta == nil then
			return "Wrong"
		end

		local expected = (state.facing + (command.facingDelta or 0)) % 4
		local actual = (state.facing + delta) % 4

		state.facing = actual
		FormationService.orientOnPad(state.player, actual)

		correct = (actual == expected)
	else
		correct = (action == command.answerIndex)
	end

	if not correct then
		return "Wrong"
	end

	local reaction = (state.pendingAt or now) - issuedAt
	local crispWindow = Config.Drill.ResponseWindow * Config.Scoring.CrispFraction
	return if reaction <= crispWindow then "Crisp" else "Slow"
end

local function runCommand()
	sequence += 1
	local command = CommandCatalog.pickCommand(rng)

	RecruitService.clearPending()

	local issuedAt = os.clock()
	Remotes.IssueCommand:FireAllClients({
		sequence = sequence,
		kind = command.kind,
		call = command.call,
		options = command.options,
		window = Config.Drill.ResponseWindow,
	} :: Types.CommandPayload)

	task.wait(Config.Drill.ResponseWindow)

	local now = os.clock()
	for player, state in RecruitService.all() do
		if player.Parent == nil then
			continue
		end

		local grade = gradeRecruit(state, command, issuedAt, now)

		local delta = 0
		local bark = "GET UP! PUSHUPS! YOU ARE NOT DONE!"
		if grade then
			delta = RecruitService.applyGrade(player, grade, now)
			bark = CommandCatalog.pickBark(grade, rng)
		end

		Remotes.Feedback:FireClient(player, {
			sequence = sequence,
			-- A locked-out recruit is shown the penalty, not a grade.
			grade = grade or "Wrong",
			bark = bark,
			delta = delta,
			score = state.score,
			demerits = state.demerits,
			streak = state.streak,
		} :: Types.FeedbackPayload)
	end
end

local function fallInPhase()
	broadcastPhase("FallIn", Config.Drill.FallInSeconds, "GET ON MY YELLOW FOOTPRINTS!")

	local deadline = os.clock() + Config.Drill.FallInSeconds
	while os.clock() < deadline do
		for _, player in Players:GetPlayers() do
			FormationService.tryClaimPad(player)
		end

		-- Everyone present has a set of footprints; no reason to keep waiting.
		if
			FormationService.occupiedCount() >= #Players:GetPlayers()
			and #Players:GetPlayers() > 0
		then
			task.wait(1.5)
			break
		end

		task.wait(0.25)
	end

	-- Square everyone away facing north before the first command.
	for _, player in Players:GetPlayers() do
		local state = RecruitService.get(player)
		if state and FormationService.getPad(player) then
			state.facing = 0
			FormationService.orientOnPad(player, 0)
		end
	end
end

local function drillPhase()
	local total = Config.Drill.CommandsPerSession
	broadcastPhase("Drill", nil, ("%d COMMANDS. EYEBALLS ON ME!"):format(total))

	for index = 1, total do
		log(("command %d/%d"):format(index, total))
		runCommand()

		local pause = rng:NextNumber(
			Config.Drill.MinPauseBetweenCommands,
			Config.Drill.MaxPauseBetweenCommands
		)
		task.wait(pause)
	end
end

local function debriefPhase()
	broadcastPhase("Debrief", Config.Drill.DebriefSeconds, "FALL OUT. WE GO AGAIN.")
	Remotes.Scoreboard:FireAllClients(RecruitService.scoreboard())
	task.wait(Config.Drill.DebriefSeconds)
end

local function waitForRecruits()
	if #Players:GetPlayers() >= Config.Drill.MinimumRecruits then
		return
	end

	broadcastPhase("Waiting", nil, "WAITING ON THE BUS...")
	while #Players:GetPlayers() < Config.Drill.MinimumRecruits do
		task.wait(1)
	end
end

function DrillService.start()
	if running then
		return
	end
	running = true

	-- Recruits who leave mid-session must not keep holding a set of footprints.
	Players.PlayerRemoving:Connect(function(player)
		FormationService.releasePad(player)
	end)

	Remotes.SubmitAction.OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" then
			return
		end

		local submitted = (payload :: any).sequence
		local action = (payload :: any).action

		-- Reject anything that is not answering the command currently on the clock.
		if submitted ~= sequence then
			return
		end
		if typeof(action) ~= "string" and typeof(action) ~= "number" then
			return
		end

		RecruitService.submit(player, action, os.clock())
	end)

	task.spawn(function()
		while true do
			waitForRecruits()

			RecruitService.resetAll()
			for _, player in Players:GetPlayers() do
				FormationService.releasePad(player)
			end

			fallInPhase()
			drillPhase()
			debriefPhase()
		end
	end)
end

return DrillService
