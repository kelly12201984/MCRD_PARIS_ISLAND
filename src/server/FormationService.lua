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

	Placement: drop a Part named Config.Formation.MarkerName in the Workspace
	and the whole deck centers on it and faces the way its front faces. No
	marker, and it falls back to Config.Formation.Origin facing -Z.
]]

local Players = game:GetService("Players")
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
local busDrop: SpawnLocation?
local beacon: BillboardGui?

-- Where the formation is centered and which way "north" (facing 0) points.
-- Position and yaw only; never pitched or rolled.
local originCFrame: CFrame = CFrame.new(Config.Formation.Origin)

-- Strips pitch and roll so a carelessly tilted marker cannot tilt the deck.
local function yawOnly(cf: CFrame): CFrame
	local look = cf.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	return CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0)
end

local function padCFrame(index: number): CFrame
	local cfg = Config.Formation
	local row = math.floor((index - 1) / cfg.Columns)
	local column = (index - 1) % cfg.Columns

	-- Center the grid on the origin.
	local offsetX = (column - (cfg.Columns - 1) / 2) * cfg.SpacingX
	local offsetZ = (row - (cfg.Rows - 1) / 2) * cfg.SpacingZ

	return originCFrame * CFrame.new(offsetX, 0, offsetZ)
end

local function padPosition(index: number): Vector3
	return padCFrame(index).Position
end

function FormationService.padCount(): number
	return Config.Formation.Rows * Config.Formation.Columns
end

function FormationService.getPadPosition(index: number): Vector3
	return padPosition(index)
end

--[[
	Converts a facing index (0 = north, 1 = east, 2 = south, 3 = west) into a
	yaw in radians relative to the formation's own north. Roblox's identity
	LookVector is -Z, and a rotation of theta about Y gives LookVector
	(-sin theta, 0, -cos theta), so clockwise quarter-turns are negative.
]]
function FormationService.facingToYaw(facing: number): number
	return math.rad(-90 * (facing % 4))
end

--[[
	Finds the marker part if there is one, then drops a ray from above it and
	rests the formation on whatever ground it finds, so the pads sit flush on
	real pavement without anyone measuring a Y coordinate.
]]
local function locateOrigin()
	local cfg = Config.Formation
	local base = CFrame.new(cfg.Origin)
	local exclude: { Instance } = {}

	local marker = Workspace:FindFirstChild(cfg.MarkerName, true)
	if marker and marker:IsA("BasePart") then
		base = yawOnly(marker.CFrame)
		-- The marker is a Studio-only handle; players never see or touch it.
		marker.Transparency = 1
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false
		table.insert(exclude, marker)
	else
		warn(("[Formation] No part named %q found; using Config.Formation.Origin."):format(cfg.MarkerName))
	end

	if cfg.SnapToGround then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = exclude

		local from = base.Position + Vector3.new(0, cfg.GroundProbeHeight, 0)
		local direction = Vector3.new(0, -cfg.GroundProbeHeight * 2, 0)
		local result = Workspace:Raycast(from, direction, params)
		if result then
			local grounded = Vector3.new(base.Position.X, result.Position.Y + cfg.PadSize.Y / 2, base.Position.Z)
			base = CFrame.new(grounded) * base.Rotation
		else
			warn("[Formation] No ground found under the formation origin; using it as-is.")
		end
	end

	originCFrame = base
end

local function buildBeacon(parent: Folder)
	local cfg = Config.Formation

	local anchor = Instance.new("Part")
	anchor.Name = "BeaconAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = originCFrame.Position + Vector3.new(0, cfg.BeaconHeight, 0)
	anchor.Parent = parent

	local gui = Instance.new("BillboardGui")
	gui.Name = "Beacon"
	gui.Size = UDim2.fromOffset(cfg.BeaconWidthPx, cfg.BeaconHeightPx)
	gui.AlwaysOnTop = true
	gui.MaxDistance = cfg.BeaconMaxDistance
	gui.Enabled = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = cfg.PadColor
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.2
	label.Text = cfg.BeaconText .. "\n\u{25BC}"
	label.Parent = gui

	gui.Parent = anchor
	beacon = gui
end

local function buildDeck()
	local folder = Instance.new("Folder")
	folder.Name = "ReceivingDeck"

	local cfg = Config.Formation
	local width = cfg.Columns * cfg.SpacingX + 20
	local depth = cfg.Rows * cfg.SpacingZ + 36

	if cfg.BuildDeck then
		local deck = Instance.new("Part")
		deck.Name = "Deck"
		deck.Anchored = true
		deck.Size = Vector3.new(width, 1, depth)
		deck.CFrame = originCFrame * CFrame.new(0, -0.6, 0)
		deck.Material = Enum.Material.Concrete
		deck.Color = Color3.fromRGB(103, 105, 104)
		deck.TopSurface = Enum.SurfaceType.Smooth
		deck.Parent = folder
	end

	for index = 1, FormationService.padCount() do
		local pad = Instance.new("Part")
		pad.Name = string.format("Footprints_%02d", index)
		pad.Anchored = true
		pad.CanCollide = false
		pad.Size = cfg.PadSize
		pad.CFrame = padCFrame(index)
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
	spawn.CanCollide = false
	spawn.Size = Vector3.new(12, cfg.PadSize.Y, 6)
	spawn.CFrame = originCFrame * CFrame.new(0, 0, depth / 2 - 6)
	spawn.Material = Enum.Material.Concrete
	spawn.Color = Color3.fromRGB(60, 62, 61)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
	busDrop = spawn

	buildBeacon(folder)

	folder.Parent = Workspace
	deckFolder = folder
end

-- The place still has free-model spawn points scattered around; this makes
-- sure everyone starts at the bus drop regardless.
local function pinSpawn(player: Player)
	if busDrop then
		player.RespawnLocation = busDrop
	end
end

function FormationService.init()
	if deckFolder then
		return
	end
	locateOrigin()
	buildDeck()

	for _, player in Players:GetPlayers() do
		pinSpawn(player)
	end
	Players.PlayerAdded:Connect(pinSpawn)
end

-- Shows or hides the "fall in here" marker over the deck.
function FormationService.setBeacon(visible: boolean)
	if beacon then
		beacon.Enabled = visible
	end
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
	Snaps a recruit to face a given cardinal direction on their pad, relative
	to the formation's own north. This is the visible result of a correctly
	executed facing movement.
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
	character:PivotTo(CFrame.new(position) * originCFrame.Rotation * CFrame.Angles(0, yaw, 0))
end

function FormationService.occupiedCount(): number
	local count = 0
	for _ in padOwner do
		count += 1
	end
	return count
end

return FormationService
