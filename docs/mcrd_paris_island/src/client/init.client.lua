--!strict
--[[
	Client entry point: mount the HUD, listen to the server, forward keystrokes.

	Note what this file does NOT do: it never decides whether an answer was
	right, never touches a score, and never trusts its own timer. It reports an
	input and waits to be told. Keep that boundary and exploiters have nothing
	to work with.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

local DrillHud = require(script.DrillHud)

DrillHud.mount()

-- The command currently on the clock, as far as this client knows.
local activeSequence: number? = nil
local activeKind: Types.CommandKind? = nil
local activeOptionCount = 0
local hasSubmitted = false

local MOVEMENT_KEYS: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.Q] = "Left",
	[Enum.KeyCode.E] = "Right",
	[Enum.KeyCode.X] = "About",
}

local RESPONSE_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
}

local function submit(action: string | number)
	if hasSubmitted or activeSequence == nil then
		return
	end
	hasSubmitted = true

	Remotes.SubmitAction:FireServer({
		sequence = activeSequence,
		action = action,
	} :: Types.ActionPayload)

	DrillHud.markSubmitted()
end

Remotes.IssueCommand.OnClientEvent:Connect(function(payload: Types.CommandPayload)
	activeSequence = payload.sequence
	activeKind = payload.kind
	activeOptionCount = payload.options and #payload.options or 0
	hasSubmitted = false

	DrillHud.showCommand(payload)
end)

Remotes.Feedback.OnClientEvent:Connect(function(payload: Types.FeedbackPayload)
	-- Only clear the prompt if this feedback is for the command we are showing.
	if payload.sequence == activeSequence then
		activeSequence = nil
		activeKind = nil
		DrillHud.clearCommand()
	end

	DrillHud.showFeedback(payload)
end)

Remotes.PhaseChanged.OnClientEvent:Connect(function(payload: Types.PhasePayload)
	DrillHud.setPhase(payload)
end)

Remotes.Scoreboard.OnClientEvent:Connect(function(rows: { Types.ScoreRow })
	DrillHud.showScoreboard(rows)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or activeSequence == nil then
		return
	end

	if activeKind == "Movement" then
		local action = MOVEMENT_KEYS[input.KeyCode]
		if action then
			submit(action)
		end
	elseif activeKind == "Response" then
		local index = RESPONSE_KEYS[input.KeyCode]
		if index and index <= activeOptionCount then
			submit(index)
		end
	end
end)
