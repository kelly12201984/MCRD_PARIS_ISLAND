--!strict
--[[
	Builds the receiving deck and tracks who is standing on which set of
	footprints.

	Everything here is generated from Config at runtime rather than modeled in
	Studio. That is a deliberate early-project choice: it means the game is fully
	playable from a clean `rojo build`, with no .rbxl full of hand-placed parts
	that git cannot merge. When you and your son start doing real art passes,
	you will swap this for real models -- but by then the gameplay will already
	be proven.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local FormationService = {}

local padParts: { BasePart } = {}
-- padIndex -> Player currently holding it
local padOwner: { [number]: Player } = {}
-- Player -> padIndex
local playerPad: { [Player]: number } = {}

local deckFolder: Folder?

local function padPosition(index: number): Vector3
	local cfg = Config.Formation
	local row = math.floor((index - 1) / cfg.Columns)
	local column = (index - 1) % cfg.Columns

	-- Center the grid on the origin.
	local offsetX = (column - (cfg.Columns - 1) / 2) * cfg.SpacingX
	local offsetZ = (row - (cfg.Rows - 1) / 2) * cfg.SpacingZ

	return cfg.Origin + Vector3.new(offsetX, 0, offsetZ)
end

function FormationService.padCount(): number
	return Config.Formation.Rows * Config.Formation.Columns
end

function FormationService.getPadPosition(index: number): Vector3
	return padPosition(index)
end

--[[
	Converts a facing index (0 = north, 1 = east, 2 = south, 3 = west) into a
	yaw in radians. Roblox's identity LookVector is -Z, and a rotation of theta
	about Y gives LookVector (-sin theta, 0, -cos theta), so clockwise
	quarter-turns are negative.
]]
function FormationService.facingToYaw(facing: number): number
	return math.rad(-90 * (facing % 4))
end

local function buildDeck()
	local folder = Instance.new("Folder")
	folder.Name = "ReceivingDeck"

	local cfg = Config.Formation
	local width = cfg.Columns * cfg.SpacingX + 20
	local depth = cfg.Rows * cfg.SpacingZ + 36

	local deck = Instance.new("Part")
	deck.Name = "Deck"
	deck.Anchored = true
	deck.Size = Vector3.new(width, 1, depth)
	deck.Position = cfg.Origin - Vector3.new(0, 0.6, 0)
	deck.Material = Enum.Material.Concrete
	deck.Color = Color3.fromRGB(103, 105, 104)
	deck.TopSurface = Enum.SurfaceType.Smooth
	deck.Parent = folder

	for index = 1, FormationService.padCount() do
		local pad = Instance.new("Part")
		pad.Name = string.format("Footprints_%02d", index)
		pad.Anchored = true
		pad.CanCollide = false
		pad.Size = cfg.PadSize
		pad.Position = padPosition(index)
		pad.Material = Enum.Material.SmoothPlastic
		pad.Color = cfg.PadColor
		pad.TopSurface = Enum.SurfaceType.Smooth
		pad:SetAttribute("PadIndex", index)
		pad.Parent = folder

		padParts[index] = pad
	end

	-- Recruits arrive at the back of the deck and have to walk up to the pads,
	-- rather than being teleported into formation. Falling in is the first test.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BusDrop"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 6)
	spawn.Position = cfg.Origin + Vector3.new(0, 0, depth / 2 - 6)
	spawn.Material = Enum.Material.Concrete
	spawn.Color = Color3.fromRGB(60, 62, 61)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	folder.Parent = Workspace
	deckFolder = folder
end

function FormationService.init()
	if deckFolder then
		return
	end
	buildDeck()
end

local function setPadHighlight(index: number, claimed: boolean)
	local pad = padParts[index]
	if not pad then
		return
	end
	pad.Color = claimed and Color3.fromRGB(198, 158, 0) or Config.Formation.PadColor
end

--[[
	Claims the nearest free pad if the player is standing close enough to one.
	Returns the pad index, or nil if there was nothing in reach.
]]
function FormationService.tryClaimPad(player: Player): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end

	local existing = playerPad[player]
	if existing then
		return existing
	end

	local bestIndex: number? = nil
	local bestDistance = Config.Formation.ClaimRadius

	for index = 1, FormationService.padCount() do
		if padOwner[index] == nil then
			local distance = (padPosition(index) - root.Position).Magnitude
			if distance <= bestDistance then
				bestDistance = distance
				bestIndex = index
			end
		end
	end

	if bestIndex then
		padOwner[bestIndex] = player
		playerPad[player] = bestIndex
		setPadHighlight(bestIndex, true)
	end

	return bestIndex
end

function FormationService.releasePad(player: Player)
	local index = playerPad[player]
	if not index then
		return
	end
	padOwner[index] = nil
	playerPad[player] = nil
	setPadHighlight(index, false)
end

function FormationService.getPad(player: Player): number?
	return playerPad[player]
end

--[[
	True if the recruit is still standing on the pad they claimed. Used mid-drill
	to catch anyone who wandered off.
]]
function FormationService.isHoldingPad(player: Player): boolean
	local index = playerPad[player]
	if not index then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end

	local offset = padPosition(index) - root.Position
	-- Compare on the horizontal plane only; jumping is not desertion.
	local flat = Vector3.new(offset.X, 0, offset.Z)
	return flat.Magnitude <= Config.Formation.DriftTolerance
end

--[[
	Snaps a recruit to face a given cardinal direction on their pad. This is the
	visible result of a correctly executed facing movement.
]]
function FormationService.orientOnPad(player: Player, facing: number)
	local index = playerPad[player]
	if not index then
		return
	end

	local character = player.Character
	if not character or not character.PrimaryPart then
		return
	end

	local position = padPosition(index) + Vector3.new(0, 3, 0)
	local yaw = FormationService.facingToYaw(facing)
	character:PivotTo(CFrame.new(position) * CFrame.Angles(0, yaw, 0))
end

function FormationService.occupiedCount(): number
	local count = 0
	for _ in padOwner do
		count += 1
	end
	return count
end

return FormationService
