--!strict
--[[
	The rank ladder. Pure data plus a few lookups, so it can be edited without
	touching a service.

	A recruit starts at index 1 with zero XP. Each later entry lists the total XP
	needed to hold that rank. Insignia are decal ids; a Marine private wears no
	chevron, so E-1 has none. Tune the xp column freely -- it is the whole pacing
	of the game.
]]

local Types = require(script.Parent.Types)

local RankCatalog = {}

local RANKS: { Types.Rank } = {
	{ name = "Recruit", short = "Rct", grade = "", xp = 0, insignia = "" },
	{ name = "Private", short = "Pvt", grade = "E-1", xp = 300, insignia = "" },
	{ name = "Private First Class", short = "PFC", grade = "E-2", xp = 900, insignia = "rbxassetid://8891244053" },
	{ name = "Lance Corporal", short = "LCpl", grade = "E-3", xp = 2000, insignia = "rbxassetid://8891244211" },
	{ name = "Corporal", short = "Cpl", grade = "E-4", xp = 4000, insignia = "rbxassetid://8891244331" },
	{ name = "Sergeant", short = "Sgt", grade = "E-5", xp = 7000, insignia = "rbxassetid://8891244441" },
	{ name = "Staff Sergeant", short = "SSgt", grade = "E-6", xp = 11000, insignia = "rbxassetid://8891244559" },
	{ name = "Gunnery Sergeant", short = "GySgt", grade = "E-7", xp = 16000, insignia = "rbxassetid://9431131770" },
	{ name = "Master Sergeant", short = "MSgt", grade = "E-8", xp = 22000, insignia = "rbxassetid://8891244755" },
	{ name = "Master Gunnery Sergeant", short = "MGySgt", grade = "E-9", xp = 30000, insignia = "rbxassetid://8891245013" },
}

RankCatalog.Ranks = RANKS

-- The highest rank whose XP requirement the given total meets.
function RankCatalog.indexForXp(xp: number): number
	local index = 1
	for i, rank in RANKS do
		if xp >= rank.xp then
			index = i
		end
	end
	return index
end

function RankCatalog.get(index: number): Types.Rank
	return RANKS[math.clamp(index, 1, #RANKS)]
end

function RankCatalog.next(index: number): Types.Rank?
	return RANKS[index + 1]
end

-- "[E-3] Lance Corporal", or just "Recruit" for the gradeless first rung.
function RankCatalog.displayName(rank: Types.Rank): string
	if rank.grade == "" then
		return rank.name
	end
	return ("[%s] %s"):format(rank.grade, rank.name)
end

return RankCatalog
