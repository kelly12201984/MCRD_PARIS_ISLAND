--!strict
--[[
	Where players spawn.

	  - Recruits -- players who hold a division (a Team) -- spawn at the bus
	    stop tagged Config.Spawn.BusStopTag. They were recruited by another
	    player and know why they are here.
	  - Everyone else spawns in town, at the thing tagged Config.Spawn.TownSpawnTag.

	If a tag is missing, each falls back to the other, then to the generated
	practice deck's bus drop, then to whatever Roblox picks.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local FormationService = require(script.Parent.FormationService)

local SpawnService = {}

local folder: Folder?
local busStop: SpawnLocation?
local town: SpawnLocation?

-- Creates an invisible SpawnLocation on top of a tagged part or model.
local function spawnAt(name: string, inst: Instance): SpawnLocation?
	local cf: CFrame?, size: Vector3?
	if inst:IsA("BasePart") then
		cf, size = inst.CFrame, inst.Size
	elseif inst:IsA("Model") then
		cf, size = inst:GetBoundingBox()
	end
	if not cf or not size then
		return nil
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y / 2 + 0.5, 0))
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
	return spawn
end

local function place(player: Player)
	local target: SpawnLocation? = if player.Team then (busStop or town) else (town or busStop)
	if not target then
		target = FormationService.fallbackSpawn()
	end
	if target then
		player.RespawnLocation = target
	end
end

local function watch(player: Player)
	place(player)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		place(player)
	end)
end

function SpawnService.init()
	local cfg = Config.Spawn

	local container = Instance.new("Folder")
	container.Name = "Spawns"
	container.Parent = Workspace
	folder = container

	local busStopSource = CollectionService:GetTagged(cfg.BusStopTag)[1]
	if busStopSource then
		busStop = spawnAt("BusStop", busStopSource)
	else
		warn(("[Spawn] Nothing tagged %q; recruits will spawn in town or on the practice deck."):format(cfg.BusStopTag))
	end

	local townSource = CollectionService:GetTagged(cfg.TownSpawnTag)[1]
	if townSource then
		town = spawnAt("TownSpawn", townSource)
	else
		warn(("[Spawn] Nothing tagged %q; walk-ins will spawn at the bus stop or practice deck."):format(cfg.TownSpawnTag))
	end

	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
end

return SpawnService
