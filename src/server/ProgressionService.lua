--!strict
--[[
	Rank earned by training. Owns each player's service record (XP and sessions
	completed), turns XP into a rank through RankCatalog, and persists it with
	DataStoreService.

	Server only. Clients never send XP; they are told about promotions.

	Persistence rules that avoid the classic data-loss bugs:
	  - A record that failed to load is never saved, so a DataStore outage
	    cannot overwrite real progress with zeros.
	  - Records save on leave, on server shutdown, and on a timer while changed.

	In Studio, DataStores only work with Game Settings -> Security ->
	"Enable Studio Access to API Services" turned on. Without it the service
	still runs (ranks work within a session), it just cannot save, and warns.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local RankCatalog = require(Shared.RankCatalog)

local ProgressionService = {}

type Entry = {
	record: Types.ServiceRecord,
	rankIndex: number,
	-- False when the load failed: never write over data we could not read.
	canSave: boolean,
	dirty: boolean,
}

local entries: { [Player]: Entry } = {}
local store: DataStore? = nil
local warnedNoStore = false

local rankChanged = Instance.new("BindableEvent")
-- Fires (player, rank) whenever a player's rank changes, including on load.
ProgressionService.RankChanged = rankChanged.Event

local function keyFor(player: Player): string
	return ("player_%d"):format(player.UserId)
end

local function getStore(): DataStore?
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Progression.DataStoreName)
	end)
	if ok then
		store = result
	elseif not warnedNoStore then
		warnedNoStore = true
		warn("[Progression] DataStore unavailable; progress will not save. " .. tostring(result))
	end
	return store
end

local function load(player: Player)
	local record: Types.ServiceRecord = { xp = 0, sessions = 0 }
	local canSave = false

	local ds = getStore()
	if ds then
		local key = keyFor(player)
		local ok, data = pcall(function()
			return ds:GetAsync(key)
		end)
		if ok then
			canSave = true
			if typeof(data) == "table" then
				record.xp = tonumber((data :: any).xp) or 0
				record.sessions = tonumber((data :: any).sessions) or 0
			end
		else
			warn(("[Progression] Load failed for %s; running unsaved. %s"):format(player.Name, tostring(data)))
		end
	end

	-- They may have left while GetAsync was yielding.
	if player.Parent == nil then
		return
	end

	local entry: Entry = {
		record = record,
		rankIndex = RankCatalog.indexForXp(record.xp),
		canSave = canSave,
		dirty = false,
	}
	entries[player] = entry
	rankChanged:Fire(player, RankCatalog.get(entry.rankIndex))
end

local function save(player: Player, entry: Entry)
	if not entry.canSave or not entry.dirty then
		return
	end
	local ds = getStore()
	if not ds then
		return
	end

	local key = keyFor(player)
	local snapshot = { xp = entry.record.xp, sessions = entry.record.sessions }
	local ok, err = pcall(function()
		ds:SetAsync(key, snapshot)
	end)
	if ok then
		entry.dirty = false
	else
		warn(("[Progression] Save failed for %s: %s"):format(player.Name, tostring(err)))
	end
end

local function saveAll()
	for player, entry in entries do
		save(player, entry)
	end
end

--[[
	Called once per recruit at the end of a drill session. Returns the XP
	gained and, if it crossed a threshold, the new rank.
]]
function ProgressionService.awardSession(player: Player, score: number, demerits: number): (number, Types.Rank?)
	local entry = entries[player]
	if not entry then
		return 0, nil
	end
	local cfg = Config.Progression

	local gained = math.max(0, math.floor(score * cfg.ScoreToXp))
	if demerits < cfg.CompletionDemeritCap then
		gained += cfg.CompletionXp
	end

	entry.record.xp += gained
	entry.record.sessions += 1
	entry.dirty = true

	local newIndex = RankCatalog.indexForXp(entry.record.xp)
	if newIndex ~= entry.rankIndex then
		entry.rankIndex = newIndex
		local rank = RankCatalog.get(newIndex)
		rankChanged:Fire(player, rank)
		return gained, rank
	end
	return gained, nil
end

function ProgressionService.getRank(player: Player): Types.Rank
	local entry = entries[player]
	return RankCatalog.get(if entry then entry.rankIndex else 1)
end

function ProgressionService.getRecord(player: Player): Types.ServiceRecord?
	local entry = entries[player]
	return if entry then entry.record else nil
end

function ProgressionService.init()
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerAdded:Connect(load)

	Players.PlayerRemoving:Connect(function(player)
		local entry = entries[player]
		if entry then
			save(player, entry)
			entries[player] = nil
		end
	end)

	game:BindToClose(saveAll)

	task.spawn(function()
		while true do
			task.wait(Config.Progression.AutosaveSeconds)
			saveAll()
		end
	end)
end

return ProgressionService
