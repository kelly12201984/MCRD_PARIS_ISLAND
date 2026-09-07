--!strict
--[[
	Division = Team. Every recruit starts in the default division and moves on
	only when the game says so -- graduation, reassignment, a player DI's call.

	This replaces the free-model Autoteam script, which assigned teams from
	Roblox group membership and errored for anyone outside those groups. The
	overhead tag reads the Team, so this is also what fills its division line.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local DivisionService = {}

local function ensureTeam(name: string, color: BrickColor): Team
	local existing = Teams:FindFirstChild(name)
	if existing and existing:IsA("Team") then
		return existing
	end
	local team = Instance.new("Team")
	team.Name = name
	team.TeamColor = color
	team.AutoAssignable = false
	team.Parent = Teams
	return team
end

-- Moves a player to a named team. Returns false if no such team exists.
function DivisionService.assign(player: Player, teamName: string): boolean
	local team = Teams:FindFirstChild(teamName)
	if not (team and team:IsA("Team")) then
		return false
	end
	player.Team = team
	return true
end

function DivisionService.init()
	local cfg = Config.Division
	local default = ensureTeam(cfg.DefaultTeam, cfg.DefaultColor)

	-- Roblox would otherwise scatter joiners across every auto-assignable team.
	for _, team in Teams:GetTeams() do
		team.AutoAssignable = false
	end

	local function place(player: Player)
		if player.Team == nil then
			player.Team = default
		end
	end

	for _, player in Players:GetPlayers() do
		place(player)
	end
	Players.PlayerAdded:Connect(place)
end

return DivisionService
