--!strict
--[[
	Division = Team. A recruit has no division until the game gives them one --
	graduation, reassignment, a player DI's call -- so nothing here assigns a
	team on join. What it does do is stop Roblox from doing it: any team marked
	AutoAssignable scatters joiners at random, which is how the first Play test
	put everyone in "Headquarters".

	This replaces the free-model Autoteam script, which assigned teams from
	Roblox group membership and errored for anyone outside those groups.
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local DivisionService = {}

local function lock(team: Instance)
	if team:IsA("Team") then
		team.AutoAssignable = false
	end
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

function DivisionService.clear(player: Player)
	player.Team = nil
end

function DivisionService.init()
	for _, team in Teams:GetTeams() do
		lock(team)
	end
	Teams.ChildAdded:Connect(lock)

	-- Anyone Roblox already auto-assigned before this ran starts clean.
	for _, player in Players:GetPlayers() do
		DivisionService.clear(player)
	end
end

return DivisionService
