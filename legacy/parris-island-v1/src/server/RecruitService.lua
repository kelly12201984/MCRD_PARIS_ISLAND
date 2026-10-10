--!strict
--[[
	Per-player state: score, demerits, streak, current facing, and the action
	they submitted for the command currently on the clock.

	This service owns the truth. The client never sends a score, only an input --
	which is the single most important habit to build early in a Roblox project,
	because anything the client is trusted with will eventually be exploited.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)

local RecruitService = {}

local recruits: { [Player]: Types.RecruitState } = {}

function RecruitService.add(player: Player)
	recruits[player] = {
		player = player,
		padIndex = nil,
		facing = 0,
		score = 0,
		demerits = 0,
		streak = 0,
		itUntil = 0,
		pendingAction = nil,
		pendingAt = nil,
	}
end

function RecruitService.remove(player: Player)
	recruits[player] = nil
end

function RecruitService.get(player: Player): Types.RecruitState?
	return recruits[player]
end

function RecruitService.all(): { [Player]: Types.RecruitState }
	return recruits
end

--[[
	Clears the per-command scratch state. Called just before each new command
	goes out so a recruit cannot bank an answer ahead of the call.
]]
function RecruitService.clearPending()
	for _, state in recruits do
		state.pendingAction = nil
		state.pendingAt = nil
	end
end

--[[
	Records a recruit's reaction. Only the first submission per command counts --
	otherwise you could spam every option and always be right.
]]
function RecruitService.submit(player: Player, action: string | number, at: number): boolean
	local state = recruits[player]
	if not state then
		return false
	end
	if state.pendingAction ~= nil then
		return false
	end
	if at < state.itUntil then
		-- Locked out on the quarterdeck; input is ignored.
		return false
	end

	state.pendingAction = action
	state.pendingAt = at
	return true
end

function RecruitService.isLockedOut(player: Player, now: number): boolean
	local state = recruits[player]
	return state ~= nil and now < state.itUntil
end

--[[
	Applies a graded result. Returns the score delta so the caller can report it.
]]
function RecruitService.applyGrade(player: Player, grade: Types.Grade, now: number): number
	local state = recruits[player]
	if not state then
		return 0
	end

	local scoring = Config.Scoring
	local delta = 0

	if grade == "Crisp" then
		delta = scoring.CorrectCrisp
		state.streak += 1
		if state.streak >= scoring.StreakThreshold then
			delta += scoring.StreakBonus
		end
	elseif grade == "Slow" then
		delta = scoring.CorrectSlow
		state.streak = 0
	else
		state.streak = 0
		state.demerits += 1

		if grade == "Wrong" then
			delta = scoring.Wrong
		elseif grade == "NoResponse" then
			delta = scoring.NoResponse
		elseif grade == "LeftFormation" then
			delta = scoring.LeftFormation
		end

		if state.demerits % scoring.DemeritsBeforeIT == 0 then
			state.itUntil = now + scoring.IncentiveTrainingSeconds
		end
	end

	state.score += delta
	return delta
end

function RecruitService.resetSession(player: Player)
	local state = recruits[player]
	if not state then
		return
	end
	state.score = 0
	state.demerits = 0
	state.streak = 0
	state.facing = 0
	state.itUntil = 0
	state.pendingAction = nil
	state.pendingAt = nil
end

function RecruitService.resetAll()
	for player in recruits do
		RecruitService.resetSession(player)
	end
end

function RecruitService.scoreboard(): { Types.ScoreRow }
	local rows: { Types.ScoreRow } = {}
	for player, state in recruits do
		table.insert(rows, {
			name = player.DisplayName,
			score = state.score,
			demerits = state.demerits,
		})
	end
	table.sort(rows, function(a, b)
		return a.score > b.score
	end)
	return rows
end

function RecruitService.init()
	for _, player in Players:GetPlayers() do
		RecruitService.add(player)
	end
	Players.PlayerAdded:Connect(RecruitService.add)
	Players.PlayerRemoving:Connect(RecruitService.remove)
end

return RecruitService
