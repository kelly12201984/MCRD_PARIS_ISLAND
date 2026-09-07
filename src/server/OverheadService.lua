--!strict
--[[
	Overhead nametag: rank insignia, username, rank, division -- stacked above
	the head, built in code so it can be diffed and tuned from Config.

	Where the data comes from:
	  - Rank + insignia: ProgressionService, so it is earned by training and
	    persists. The tag rebuilds the moment a player is promoted.
	  - Division: the player's Team. A recruit has none until the game assigns
	    one, and the line is hidden until then.

	The server builds the GUI inside the character model, so it replicates to
	every client without any client code.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local RankCatalog = require(Shared.RankCatalog)

local ProgressionService = require(script.Parent.ProgressionService)

local OverheadService = {}

local GUI_NAME = "Overhead"
local HEAD_WAIT_SECONDS = 10

local function makeLabel(name: string, text: string, color: Color3, heightFraction: number, order: number): TextLabel
	local cfg = Config.Overhead
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, heightFraction, 0)
	label.Font = cfg.Font
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeColor3 = cfg.StrokeColor
	label.TextStrokeTransparency = cfg.StrokeTransparency
	label.Text = text
	label.LayoutOrder = order
	return label
end

local function build(player: Player, character: Model)
	local head = character:WaitForChild("Head", HEAD_WAIT_SECONDS)
	if not head then
		return
	end

	-- Hide Roblox's default floating name so we do not show two.
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local existing = character:FindFirstChild(GUI_NAME)
	if existing then
		existing:Destroy()
	end

	local cfg = Config.Overhead
	local rank = ProgressionService.getRank(player)
	local team = player.Team

	local gui = Instance.new("BillboardGui")
	gui.Name = GUI_NAME
	gui.Adornee = head
	gui.Size = UDim2.new(cfg.WidthStuds, 0, cfg.HeightStuds, 0)
	gui.StudsOffset = Vector3.new(0, cfg.HeightAboveHead, 0)
	gui.MaxDistance = cfg.MaxDistance
	gui.ResetOnSpawn = false

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	local insignia = Instance.new("ImageLabel")
	insignia.Name = "Insignia"
	insignia.BackgroundTransparency = 1
	insignia.Size = UDim2.new(0, 0, cfg.InsigniaFraction, 0)
	insignia.Image = rank.insignia
	insignia.Visible = rank.insignia ~= ""
	insignia.LayoutOrder = 1
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = insignia
	insignia.Parent = gui

	makeLabel("Username", player.Name, cfg.NameColor, cfg.NameFraction, 2).Parent = gui
	makeLabel("Rank", RankCatalog.displayName(rank), cfg.TextColor, cfg.RankFraction, 3).Parent = gui

	local division = makeLabel(
		"Division",
		if team then team.Name else "",
		if team then team.TeamColor.Color else cfg.TextColor,
		cfg.DivisionFraction,
		4
	)
	division.Visible = team ~= nil
	division.Parent = gui

	gui.Parent = character
end

local function refresh(player: Player)
	local character = player.Character
	if character then
		build(player, character)
	end
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character)
		build(player, character)
	end)
	-- Division changes (assignment, reassignment) refresh the tag in place.
	player:GetPropertyChangedSignal("Team"):Connect(function()
		refresh(player)
	end)
	refresh(player)
end

function OverheadService.init()
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)

	-- Promotions (and the initial load of a saved rank) refresh the tag too.
	ProgressionService.RankChanged:Connect(function(player: Player)
		refresh(player)
	end)
end

return OverheadService
