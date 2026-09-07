--!strict
--[[
	Overhead nametag: rank insignia, username, rank, division -- stacked above
	the head, built in code so it can be diffed and tuned from Config.

	Geometry is a copy of the RankUI template the game used before (4 x 3
	studs, centered 1.6 studs above the head, content in fixed vertical bands),
	because that one sat where a nametag should.

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

type Band = { Top: number, Height: number }

local function makeLabel(name: string, text: string, color: Color3, band: Band): TextLabel
	local cfg = Config.Overhead
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, band.Top)
	label.Size = UDim2.fromScale(1, band.Height)
	label.Font = cfg.Font
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeColor3 = cfg.StrokeColor
	label.TextStrokeTransparency = cfg.StrokeTransparency
	label.Text = text
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
	local bands = cfg.Bands
	local rank = ProgressionService.getRank(player)
	local team = player.Team

	local gui = Instance.new("BillboardGui")
	gui.Name = GUI_NAME
	gui.Adornee = head
	gui.Size = UDim2.new(cfg.WidthStuds, 0, cfg.HeightStuds, 0)
	gui.StudsOffset = Vector3.new(0, cfg.StudsAboveHead, 0)
	gui.MaxDistance = cfg.MaxDistance
	gui.ResetOnSpawn = false

	-- Insignia: a square centered in its band.
	local insigniaBand: Band = bands.Insignia
	local insignia = Instance.new("ImageLabel")
	insignia.Name = "Insignia"
	insignia.BackgroundTransparency = 1
	insignia.AnchorPoint = Vector2.new(0.5, 0)
	insignia.Position = UDim2.fromScale(0.5, insigniaBand.Top)
	insignia.Size = UDim2.fromScale(0, insigniaBand.Height)
	insignia.Image = rank.insignia
	insignia.Visible = rank.insignia ~= ""
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = insignia
	insignia.Parent = gui

	makeLabel("Username", player.Name, cfg.NameColor, bands.Name).Parent = gui
	makeLabel("Rank", RankCatalog.displayName(rank), cfg.TextColor, bands.Rank).Parent = gui

	local division = makeLabel(
		"Division",
		if team then team.Name else "",
		if team then team.TeamColor.Color else cfg.TextColor,
		bands.Division
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
