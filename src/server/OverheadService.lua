--!strict
--[[
	Overhead nametag: rank insignia, username, rank, division -- stacked above
	the head, built in code so it can be diffed and tuned from Config.

	Where the data comes from today:
	  - Rank + insignia: the Roblox group in Config.Overhead.GroupId. That is where
	    the current ranks live. Once recruits can earn rank in-game, swap the body
	    of getRank() and nothing else changes.
	  - Division: the player's Team, which Autoteam (and later our own graduation
	    logic) assigns. The line is tinted with the team color.

	The server builds the GUI inside the character model, so it replicates to
	every client without any client code.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local OverheadService = {}

local GUI_NAME = "Overhead"
local HEAD_WAIT_SECONDS = 10

local function getRank(player: Player): (string, number)
	local cfg = Config.Overhead
	local okRank, rankId = pcall(player.GetRankInGroup, player, cfg.GroupId)
	local okRole, roleName = pcall(player.GetRoleInGroup, player, cfg.GroupId)

	local rank: number = if okRank and typeof(rankId) == "number" then rankId else 0
	local name: string = cfg.NoGroupRank
	if rank > 0 and okRole and typeof(roleName) == "string" then
		name = roleName
	end
	return name, rank
end

local function getDivision(player: Player): (string, Color3)
	local team = player.Team
	if team then
		return team.Name, team.TeamColor.Color
	end
	return Config.Overhead.NoDivision, Config.Overhead.TextColor
end

local function makeLabel(name: string, text: string, color: Color3, textSize: number, order: number): TextLabel
	local cfg = Config.Overhead
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, textSize)
	label.Font = cfg.Font
	label.TextSize = textSize
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
	local rankName, rankId = getRank(player)
	local divisionName, divisionColor = getDivision(player)

	local gui = Instance.new("BillboardGui")
	gui.Name = GUI_NAME
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(cfg.Width, cfg.Height)
	gui.StudsOffset = Vector3.new(0, cfg.HeightAboveHead, 0)
	gui.MaxDistance = cfg.MaxDistance
	gui.ResetOnSpawn = false

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, cfg.LinePadding)
	layout.Parent = gui

	local insigniaImage = cfg.Insignia[rankId]
	local insignia = Instance.new("ImageLabel")
	insignia.Name = "Insignia"
	insignia.BackgroundTransparency = 1
	insignia.Size = UDim2.fromOffset(cfg.InsigniaSize, cfg.InsigniaSize)
	insignia.Image = insigniaImage or ""
	insignia.Visible = insigniaImage ~= nil
	insignia.LayoutOrder = 1
	insignia.Parent = gui

	makeLabel("Username", player.Name, cfg.NameColor, cfg.NameTextSize, 2).Parent = gui
	makeLabel("Rank", rankName, cfg.TextColor, cfg.TextSize, 3).Parent = gui
	makeLabel("Division", divisionName, divisionColor, cfg.TextSize, 4).Parent = gui

	gui.Parent = character
end

local function watch(player: Player)
	local function rebuild()
		local character = player.Character
		if character then
			build(player, character)
		end
	end

	player.CharacterAdded:Connect(function(character)
		build(player, character)
	end)
	-- Division changes (promotion, reassignment) refresh the tag in place.
	player:GetPropertyChangedSignal("Team"):Connect(rebuild)
	rebuild()
end

function OverheadService.init()
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
end

return OverheadService
