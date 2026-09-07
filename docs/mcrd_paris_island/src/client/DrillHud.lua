--!strict
--[[
	The recruit's heads-up display.

	Built in code rather than as a Studio-authored ScreenGui for the same reason
	the deck is: a .rbxmx full of nested Frames is unreadable in a diff and
	unmergeable when two people touch it. Once the layout settles you can move it
	into Studio -- but code-first keeps the project reviewable while it is still
	changing every day.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)

local DrillHud = {}

local KHAKI = Color3.fromRGB(214, 200, 160)
local OLIVE = Color3.fromRGB(58, 66, 48)
local RED = Color3.fromRGB(196, 60, 48)
local GREEN = Color3.fromRGB(110, 190, 110)
local YELLOW = Color3.fromRGB(255, 204, 0)

local gui: ScreenGui
local callLabel: TextLabel
local phaseLabel: TextLabel
local barkLabel: TextLabel
local statsLabel: TextLabel
local optionsFrame: Frame
local timerBar: Frame
local scoreboardFrame: Frame
local scoreboardList: Frame

local timerConnection: RBXScriptConnection?
local optionButtons: { TextLabel } = {}

local function newLabel(name: string, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = KHAKI
	label.TextScaled = false
	label.RichText = false
	label.Parent = parent
	return label
end

function DrillHud.mount()
	if gui then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "DrillHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- Phase banner, top of screen.
	phaseLabel = newLabel("Phase", gui)
	phaseLabel.Position = UDim2.new(0, 0, 0, 24)
	phaseLabel.Size = UDim2.new(1, 0, 0, 24)
	phaseLabel.TextSize = 18
	phaseLabel.TextColor3 = YELLOW
	phaseLabel.Text = ""

	-- The drill instructor's call.
	callLabel = newLabel("Call", gui)
	callLabel.Position = UDim2.new(0, 0, 0, 60)
	callLabel.Size = UDim2.new(1, 0, 0, 64)
	callLabel.TextSize = 52
	callLabel.Text = ""

	-- Countdown bar under the call.
	local timerTrack = Instance.new("Frame")
	timerTrack.Name = "TimerTrack"
	timerTrack.AnchorPoint = Vector2.new(0.5, 0)
	timerTrack.Position = UDim2.new(0.5, 0, 0, 128)
	timerTrack.Size = UDim2.new(0, 360, 0, 6)
	timerTrack.BackgroundColor3 = OLIVE
	timerTrack.BorderSizePixel = 0
	timerTrack.Visible = false
	timerTrack.Parent = gui

	timerBar = Instance.new("Frame")
	timerBar.Name = "TimerBar"
	timerBar.Size = UDim2.new(1, 0, 1, 0)
	timerBar.BackgroundColor3 = YELLOW
	timerBar.BorderSizePixel = 0
	timerBar.Parent = timerTrack

	-- Response options / movement key hints.
	optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.AnchorPoint = Vector2.new(0.5, 0)
	optionsFrame.Position = UDim2.new(0.5, 0, 0, 150)
	optionsFrame.Size = UDim2.new(0, 560, 0, 120)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = optionsFrame

	-- The DI's reaction to your last execution.
	barkLabel = newLabel("Bark", gui)
	barkLabel.AnchorPoint = Vector2.new(0.5, 1)
	barkLabel.Position = UDim2.new(0.5, 0, 1, -80)
	barkLabel.Size = UDim2.new(1, 0, 0, 34)
	barkLabel.TextSize = 28
	barkLabel.Text = ""

	-- Score readout, bottom left.
	statsLabel = newLabel("Stats", gui)
	statsLabel.AnchorPoint = Vector2.new(0, 1)
	statsLabel.Position = UDim2.new(0, 18, 1, -18)
	statsLabel.Size = UDim2.new(0, 320, 0, 22)
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextSize = 18
	statsLabel.Text = "SCORE 0   DEMERITS 0   STREAK 0"

	-- Debrief scoreboard.
	scoreboardFrame = Instance.new("Frame")
	scoreboardFrame.Name = "Scoreboard"
	scoreboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	scoreboardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	scoreboardFrame.Size = UDim2.new(0, 420, 0, 300)
	scoreboardFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 16)
	scoreboardFrame.BackgroundTransparency = 0.15
	scoreboardFrame.BorderSizePixel = 0
	scoreboardFrame.Visible = false
	scoreboardFrame.Parent = gui

	local heading = newLabel("Heading", scoreboardFrame)
	heading.Position = UDim2.new(0, 0, 0, 12)
	heading.Size = UDim2.new(1, 0, 0, 30)
	heading.TextSize = 24
	heading.TextColor3 = YELLOW
	heading.Text = "DRILL EVALUATION"

	scoreboardList = Instance.new("Frame")
	scoreboardList.Name = "List"
	scoreboardList.Position = UDim2.new(0, 20, 0, 54)
	scoreboardList.Size = UDim2.new(1, -40, 1, -74)
	scoreboardList.BackgroundTransparency = 1
	scoreboardList.Parent = scoreboardFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scoreboardList
end

function DrillHud.setPhase(payload: Types.PhasePayload)
	phaseLabel.Text = payload.message
	if payload.phase ~= "Debrief" then
		DrillHud.hideScoreboard()
	end
	if payload.phase ~= "Drill" then
		DrillHud.clearCommand()
	end
end

local function clearOptions()
	for _, label in optionButtons do
		label:Destroy()
	end
	table.clear(optionButtons)
end

local function addOption(key: string, text: string)
	local label = newLabel("Option" .. key, optionsFrame)
	label.Size = UDim2.new(0, 520, 0, 30)
	label.TextSize = 24
	label.Text = ("[%s]  %s"):format(key, text)
	table.insert(optionButtons, label)
end

function DrillHud.showCommand(payload: Types.CommandPayload)
	callLabel.Text = payload.call
	callLabel.TextColor3 = KHAKI
	barkLabel.Text = ""

	clearOptions()

	if payload.kind == "Response" and payload.options then
		for index, option in payload.options do
			addOption(tostring(index), option)
		end
	else
		addOption("Q", "LEFT FACE")
		addOption("E", "RIGHT FACE")
		addOption("X", "ABOUT FACE")
	end

	-- Drain the countdown bar over the response window.
	local track = timerBar.Parent :: Frame
	track.Visible = true
	timerBar.Size = UDim2.new(1, 0, 1, 0)
	timerBar.BackgroundColor3 = YELLOW

	if timerConnection then
		timerConnection:Disconnect()
	end

	local started = os.clock()
	timerConnection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - started
		local remaining = math.clamp(1 - elapsed / payload.window, 0, 1)
		timerBar.Size = UDim2.new(remaining, 0, 1, 0)
		if remaining < 0.4 then
			timerBar.BackgroundColor3 = RED
		end
		if remaining <= 0 then
			if timerConnection then
				timerConnection:Disconnect()
				timerConnection = nil
			end
		end
	end)
end

function DrillHud.markSubmitted()
	callLabel.TextColor3 = Color3.fromRGB(150, 150, 140)
end

function DrillHud.clearCommand()
	callLabel.Text = ""
	clearOptions()
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
	local track = timerBar.Parent :: Frame
	track.Visible = false
end

local GRADE_COLORS: { [string]: Color3 } = {
	Crisp = GREEN,
	Slow = YELLOW,
	Wrong = RED,
	NoResponse = RED,
	LeftFormation = RED,
}

function DrillHud.showFeedback(payload: Types.FeedbackPayload)
	barkLabel.Text = payload.bark
	barkLabel.TextColor3 = GRADE_COLORS[payload.grade] or KHAKI
	barkLabel.TextTransparency = 0

	statsLabel.Text = ("SCORE %d   DEMERITS %d   STREAK %d"):format(
		payload.score,
		payload.demerits,
		payload.streak
	)

	TweenService:Create(
		barkLabel,
		TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }
	):Play()
end

function DrillHud.showScoreboard(rows: { Types.ScoreRow })
	for _, child in scoreboardList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	for index, row in rows do
		local label = newLabel("Row" .. index, scoreboardList)
		label.Size = UDim2.new(1, 0, 0, 24)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextSize = 18
		label.Text = ("%d. %-16s  %5d pts   %d demerits"):format(
			index,
			row.name,
			row.score,
			row.demerits
		)
	end

	scoreboardFrame.Visible = true
end

function DrillHud.hideScoreboard()
	if scoreboardFrame then
		scoreboardFrame.Visible = false
	end
end

return DrillHud
