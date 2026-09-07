--!strict
--[[
	Tracks who is standing on which formation spot, and where the spots are.

	Two sources for the spots, in priority order:
	  1. Anything in the Workspace tagged Config.Formation.SpotTag. This is the
	     real map: the painted formation boxes on the parade deck. Tag them in
	     Studio (Properties -> Tags) and the code finds them, parts or models.
	     Each box holds Config.Formation.RecruitsPerPad standing spots, laid
	     out inside it by layoutInPad.
	  2. If nothing is tagged, a grid of yellow pads is generated at the
	     FormationOrigin marker (or Config.Formation.Origin) so the game still
	     runs on an empty baseplate.

	Facing: at facing 0 a recruit looks toward the instance tagged
	Config.Formation.FrontTag -- where the DI stands. Without one, each spot's
	own front face is "north".
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local FormationService = {}

type Spot = {
	-- Where a recruit stands (top surface) and which way facing 0 looks.
	cframe: CFrame,
	instance: Instance,
	-- Generated grid: the whole pad glows when claimed.
	highlight: Highlight?,
	-- Tagged pads: a flat marker per standing spot goes solid when claimed.
	marker: BasePart?,
}

local spots: { Spot } = {}
-- spotIndex -> Player currently holding it
local padOwner: { [number]: Player } = {}
-- Player -> spotIndex
local playerPad: { [Player]: number } = {}

local deckFolder: Folder?
local generatedSpawn: SpawnLocation?
local beacon: BillboardGui?

-- Only used by the generated fallback grid.
local originCFrame: CFrame = CFrame.new(Config.Formation.Origin)

-- Strips pitch and roll so a tilted part cannot tilt the formation.
local function yawOnly(cf: CFrame): CFrame
	local look = cf.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	return CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0)
end

-- CFrame and size of a part or model; nil for anything else.
local function pivotOf(inst: Instance): (CFrame?, Vector3?)
	if inst:IsA("BasePart") then
		return inst.CFrame, inst.Size
	elseif inst:IsA("Model") then
		return inst:GetBoundingBox()
	end
	return nil, nil
end

local function flatDistance(a: Vector3, b: Vector3): number
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

-- Rotates a standing CFrame to look at a target on the horizontal plane.
local function faceToward(from: CFrame, target: Vector3?): CFrame
	if not target then
		return from
	end
	local flat = Vector3.new(target.X, from.Position.Y, target.Z)
	if (flat - from.Position).Magnitude < 0.01 then
		return from
	end
	return CFrame.lookAt(from.Position, flat)
end

local function addHighlight(spot: Spot, parent: Instance)
	local cfg = Config.Formation
	local highlight = Instance.new("Highlight")
	highlight.Name = "ClaimHighlight"
	highlight.Adornee = spot.instance
	highlight.FillColor = cfg.PadColor
	highlight.OutlineColor = cfg.PadColor
	highlight.FillTransparency = cfg.ClaimFillTransparency
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = parent
	spot.highlight = highlight
end

local function addMarker(spot: Spot, parent: Instance)
	local cfg = Config.Formation
	local marker = Instance.new("Part")
	marker.Name = "StandingSpot"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	marker.Size = Vector3.new(cfg.SpotMarkerSize, cfg.SpotMarkerThickness, cfg.SpotMarkerSize)
	marker.CFrame = spot.cframe * CFrame.new(0, cfg.SpotMarkerThickness / 2, 0)
	marker.Material = Enum.Material.SmoothPlastic
	marker.Color = cfg.PadColor
	marker.Transparency = cfg.SpotMarkerFreeTransparency
	marker.TopSurface = Enum.SurfaceType.Smooth
	marker.Parent = parent
	spot.marker = marker
end

--[[
	Standing spots inside one tagged pad.

	The pad is a painted box of any rotation. Its "front" is whichever side
	faces the DI (frontPos), or its own front face when there is no DI marker.
	Spots fill a grid that keeps cells roughly square, ordered front rank
	first and then left to right as the recruit sees it, so spot 1 is the
	front-left recruit.
]]
local function layoutInPad(padCFrame: CFrame, padSize: Vector3, frontPos: Vector3?): { CFrame }
	local cfg = Config.Formation
	local count = math.max(1, cfg.RecruitsPerPad)

	local center = padCFrame.Position
	local look = padCFrame.LookVector
	local right = padCFrame.RightVector

	-- Which of the pad's own axes runs toward the front?
	local toFront = if frontPos then Vector3.new(frontPos.X - center.X, 0, frontPos.Z - center.Z) else look
	local alongLook = toFront:Dot(look)
	local alongRight = toFront:Dot(right)

	local frontDir: Vector3
	local deepSize: number
	local acrossSize: number
	if math.abs(alongLook) >= math.abs(alongRight) then
		frontDir = if alongLook >= 0 then look else -look
		deepSize, acrossSize = padSize.Z, padSize.X
	else
		frontDir = if alongRight >= 0 then right else -right
		deepSize, acrossSize = padSize.X, padSize.Z
	end
	-- The recruit's right, standing on the pad and facing the front.
	local acrossDir = frontDir:Cross(Vector3.yAxis)

	local usableAcross = math.max(acrossSize - cfg.SpotInset * 2, 0)
	local usableDeep = math.max(deepSize - cfg.SpotInset * 2, 0)

	-- Choose the column count whose cells are closest to square, preferring
	-- counts that fill every rank evenly: four recruits in a wide box stand
	-- four abreast, not three and one.
	local columns = count
	local bestScore = math.huge
	for candidate = 1, count do
		local candidateRows = math.ceil(count / candidate)
		local cellA = math.max(usableAcross / candidate, 0.01)
		local cellD = math.max(usableDeep / candidateRows, 0.01)
		local score = math.abs(math.log(cellA / cellD))
		if count % candidate ~= 0 then
			score += cfg.RaggedRankPenalty
		end
		if score < bestScore then
			bestScore = score
			columns = candidate
		end
	end
	local rows = math.ceil(count / columns)
	local cellAcross = usableAcross / columns
	local cellDeep = usableDeep / rows

	local out: { CFrame } = {}
	for row = 0, rows - 1 do
		-- A short last rank is centered rather than left-aligned.
		local inRow = math.min(columns, count - row * columns)
		local deepOffset = ((rows - 1) / 2 - row) * cellDeep
		for column = 0, inRow - 1 do
			local acrossOffset = (column - (inRow - 1) / 2) * cellAcross
			local position = center + acrossDir * acrossOffset + frontDir * deepOffset
			local standing = CFrame.lookAt(position, position + frontDir)
			table.insert(out, faceToward(standing, frontPos))
		end
	end
	return out
end

--[[
	Builds the spot list from tagged instances. Returns false if there are none.
	Spots are numbered front rank first (closest to the DI), then left to right,
	so the order is stable between runs.
]]
local function collectTaggedSpots(folder: Folder): boolean
	local cfg = Config.Formation

	local frontPos: Vector3? = nil
	local front = CollectionService:GetTagged(cfg.FrontTag)[1]
	if front then
		local cf = pivotOf(front)
		if cf then
			frontPos = cf.Position
		end
	end

	local found: { Spot } = {}
	for _, inst in CollectionService:GetTagged(cfg.SpotTag) do
		if inst:IsDescendantOf(Workspace) then
			local cf, size = pivotOf(inst)
			if cf and size then
				local top = CFrame.new(cf.Position + Vector3.new(0, size.Y / 2, 0)) * yawOnly(cf).Rotation
				for _, standing in layoutInPad(top, size, frontPos) do
					table.insert(found, { cframe = standing, instance = inst })
				end
			end
		end
	end
	if #found == 0 then
		return false
	end

	local function rowKey(p: Vector3): number
		local along = if frontPos then flatDistance(p, frontPos) else p.Z
		return math.round(along / cfg.RowBucketStuds)
	end
	table.sort(found, function(a, b)
		local pa, pb = a.cframe.Position, b.cframe.Position
		local ra, rb = rowKey(pa), rowKey(pb)
		if ra ~= rb then
			return ra < rb
		end
		if pa.X ~= pb.X then
			return pa.X < pb.X
		end
		return pa.Z < pb.Z
	end)

	if cfg.ShowSpotMarkers then
		for _, spot in found do
			addMarker(spot, folder)
		end
	end
	spots = found
	return true
end

--[[
	Fallback placement: the FormationOrigin marker part if there is one, else
	Config.Formation.Origin, snapped down onto the ground.
]]
local function locateOrigin()
	local cfg = Config.Formation
	local base = CFrame.new(cfg.Origin)
	local exclude: { Instance } = {}

	local marker = Workspace:FindFirstChild(cfg.MarkerName, true)
	if marker and marker:IsA("BasePart") then
		base = yawOnly(marker.CFrame)
		marker.Transparency = 1
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false
		table.insert(exclude, marker)
	end

	if cfg.SnapToGround then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = exclude
		local from = base.Position + Vector3.new(0, cfg.GroundProbeHeight, 0)
		local result = Workspace:Raycast(from, Vector3.new(0, -cfg.GroundProbeHeight * 2, 0), params)
		if result then
			local grounded = Vector3.new(base.Position.X, result.Position.Y + cfg.PadSize.Y / 2, base.Position.Z)
			base = CFrame.new(grounded) * base.Rotation
		end
	end

	originCFrame = base
end

local function generateSpots(folder: Folder)
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

	local found: { Spot } = {}
	for index = 1, cfg.Rows * cfg.Columns do
		local row = math.floor((index - 1) / cfg.Columns)
		local column = (index - 1) % cfg.Columns
		local offsetX = (column - (cfg.Columns - 1) / 2) * cfg.SpacingX
		local offsetZ = (row - (cfg.Rows - 1) / 2) * cfg.SpacingZ
		local padCFrame = originCFrame * CFrame.new(offsetX, 0, offsetZ)

		local pad = Instance.new("Part")
		pad.Name = string.format("Footprints_%02d", index)
		pad.Anchored = true
		pad.CanCollide = false
		pad.Size = cfg.PadSize
		pad.CFrame = padCFrame
		pad.Material = Enum.Material.SmoothPlastic
		pad.Color = cfg.PadColor
		pad.TopSurface = Enum.SurfaceType.Smooth
		pad:SetAttribute("PadIndex", index)
		pad.Parent = folder

		local spot: Spot = { cframe = padCFrame * CFrame.new(0, cfg.PadSize.Y / 2, 0), instance = pad }
		addHighlight(spot, folder)
		table.insert(found, spot)
	end
	spots = found

	-- Recruits arrive at the back of the deck and walk up to the pads.
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
	generatedSpawn = spawn
end

local function buildBeacon(parent: Folder)
	local cfg = Config.Formation
	if #spots == 0 then
		return
	end

	local sum = Vector3.zero
	for _, spot in spots do
		sum += spot.cframe.Position
	end
	local center = sum / #spots

	local anchor = Instance.new("Part")
	anchor.Name = "BeaconAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = center + Vector3.new(0, cfg.BeaconHeight, 0)
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

function FormationService.init()
	if deckFolder then
		return
	end
	local cfg = Config.Formation

	local folder = Instance.new("Folder")
	folder.Name = "ReceivingDeck"
	deckFolder = folder

	if not collectTaggedSpots(folder) then
		if cfg.GenerateIfNoSpots then
			warn(("[Formation] Nothing tagged %q; generating a practice grid instead."):format(cfg.SpotTag))
			locateOrigin()
			generateSpots(folder)
		else
			warn(("[Formation] Nothing tagged %q and generation is off; there is no formation."):format(cfg.SpotTag))
		end
	end

	buildBeacon(folder)
	folder.Parent = Workspace
end

-- The generated grid's bus drop, for SpawnService to fall back on.
function FormationService.fallbackSpawn(): SpawnLocation?
	return generatedSpawn
end

-- Shows or hides the "fall in here" marker over the formation.
function FormationService.setBeacon(visible: boolean)
	if beacon then
		beacon.Enabled = visible
	end
end

function FormationService.padCount(): number
	return #spots
end

function FormationService.getPadPosition(index: number): Vector3
	local spot = spots[index]
	return if spot then spot.cframe.Position else Config.Formation.Origin
end

--[[
	Converts a facing index (0 = toward the front, 1 = right, 2 = about,
	3 = left) into a yaw in radians relative to the spot. A rotation of theta
	about Y turns the LookVector clockwise for negative theta.
]]
function FormationService.facingToYaw(facing: number): number
	return math.rad(-90 * (facing % 4))
end

local function setPadHighlight(index: number, claimed: boolean)
	local spot = spots[index]
	if not spot then
		return
	end
	if spot.highlight then
		spot.highlight.Enabled = claimed
	end
	if spot.marker then
		local cfg = Config.Formation
		spot.marker.Transparency = if claimed
			then cfg.SpotMarkerClaimedTransparency
			else cfg.SpotMarkerFreeTransparency
	end
end

--[[
	Claims the nearest free spot if the player is standing close enough to one.
	Returns the spot index, or nil if there was nothing in reach.
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

	for index, spot in spots do
		if padOwner[index] == nil then
			local distance = flatDistance(spot.cframe.Position, root.Position)
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
	True if the recruit is still standing on the spot they claimed. Used
	mid-drill to catch anyone who wandered off.
]]
function FormationService.isHoldingPad(player: Player): boolean
	local index = playerPad[player]
	local spot = index and spots[index]
	if not spot then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end

	-- Horizontal plane only; jumping is not desertion.
	return flatDistance(spot.cframe.Position, root.Position) <= Config.Formation.DriftTolerance
end

--[[
	Snaps a recruit to face a given direction on their spot. This is the
	visible result of a correctly executed facing movement.
]]
function FormationService.orientOnPad(player: Player, facing: number)
	local index = playerPad[player]
	local spot = index and spots[index]
	if not spot then
		return
	end

	local character = player.Character
	if not character or not character.PrimaryPart then
		return
	end

	local yaw = FormationService.facingToYaw(facing)
	character:PivotTo(spot.cframe * CFrame.new(0, Config.Formation.StandHeight, 0) * CFrame.Angles(0, yaw, 0))
end

function FormationService.occupiedCount(): number
	local count = 0
	for _ in padOwner do
		count += 1
	end
	return count
end

return FormationService
