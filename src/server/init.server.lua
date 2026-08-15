--!strict
--[[
	Server entry point.

	Rojo turns this folder into a single Script named "Server" under
	ServerScriptService, with every sibling module as its child. So this file is
	the one thing that runs on its own, and its whole job is ordering: build the
	world, register players, then start the loop.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Requiring Remotes on the server is what creates them, so do it before any
-- client can possibly ask for them.
require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local FormationService = require(script.FormationService)
local RecruitService = require(script.RecruitService)
local DrillService = require(script.DrillService)

FormationService.init()
RecruitService.init()
DrillService.start()

print("[MCRD] Receiving deck is open.")
