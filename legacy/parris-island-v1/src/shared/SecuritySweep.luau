--[[
	SecuritySweep — finds and removes the malware discovered in the
	place snapshot (free-model backdoors and the "Anti-Lag" worm).

	HOW TO USE (Roblox Studio, EDIT mode — not Play — with Rojo connected):
	  1. View tab -> Command Bar
	  2. Report only (changes nothing):
	       require(game.ReplicatedStorage.Shared.SecuritySweep).scan()
	  3. Remove/repair everything found:
	       require(game.ReplicatedStorage.Shared.SecuritySweep).clean()
	  4. File -> Save to Roblox (or Publish) to keep the cleaned version.

	What it targets (verified in the 2026-09-05 snapshot):
	  - "Anti-Lag" (33 copies): self-replicating worm. Deleted outright.
	  - Truck DriveSeat "Pickup" scripts (3 copies): hidden
	    `require(5246683085)` backdoor after a fake "Last synced" comment.
	    Repaired by cutting the injected tail; the seat still works.
	  - "duke usmc" equipment HatScript (2 copies): obfuscated
	    `getfenv()['\114...'](5151855975)` backdoor. Repaired the same way.
	  - Reports (but does not touch) any other script calling
	    require(<asset id>), getfenv, or loadstring, for manual review.
]]

local SecuritySweep = {}

local INJECTION_MARKERS = {
	"%-%-%[%[ Last synced", -- fake comment hiding a require() off-screen
	"getfenv%(%)%[", -- escaped-string require obfuscation
}

local REPORT_PATTERNS = {
	"require%s*%(%s*%d", -- require(assetId) loads remote code
	"getfenv",
	"loadstring",
}

local function fullPath(inst: Instance): string
	return inst:GetFullName()
end

local function forEachScript(callback)
	for _, inst in game:GetDescendants() do
		if inst:IsA("LuaSourceContainer") then
			local ok, src = pcall(function()
				return (inst :: any).Source
			end)
			if ok then
				callback(inst, src or "")
			end
		end
	end
end

local function findInjection(src: string): number?
	local first: number? = nil
	for _, marker in INJECTION_MARKERS do
		local i = string.find(src, marker)
		if i and (first == nil or i < first) then
			first = i
		end
	end
	return first
end

function SecuritySweep.scan()
	local worms, injected, review = 0, 0, 0
	forEachScript(function(inst, src)
		if inst.Name == "Anti-Lag" then
			worms += 1
			print("[WORM]     " .. fullPath(inst))
		elseif findInjection(src) then
			injected += 1
			print("[BACKDOOR] " .. fullPath(inst))
		else
			for _, pat in REPORT_PATTERNS do
				if string.find(src, pat) then
					review += 1
					print("[REVIEW]   " .. fullPath(inst) .. "  (matches: " .. pat .. ")")
					break
				end
			end
		end
	end)
	print(("SecuritySweep: %d worm scripts, %d injected backdoors, %d to review. Nothing changed — run .clean() to fix."):format(
		worms, injected, review))
end

function SecuritySweep.clean()
	local destroyed, repaired = 0, 0
	local toDestroy = {}
	forEachScript(function(inst, src)
		if inst.Name == "Anti-Lag" then
			table.insert(toDestroy, inst)
		else
			local cut = findInjection(src)
			if cut then
				(inst :: any).Source = string.gsub(string.sub(src, 1, cut - 1), "%s+$", "") .. "\n"
				repaired += 1
				print("[REPAIRED] " .. fullPath(inst))
			end
		end
	end)
	for _, inst in toDestroy do
		print("[DELETED]  " .. fullPath(inst))
		inst:Destroy()
		destroyed += 1
	end
	print(("SecuritySweep: deleted %d worm scripts, repaired %d backdoored scripts. Now SAVE/PUBLISH the place."):format(
		destroyed, repaired))
end

return SecuritySweep
