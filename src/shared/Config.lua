--!strict
--[[
	Every tunable number in the vertical slice lives here.

	Rule for this project: no magic numbers in service code. If you find yourself
	typing a literal that someone might want to tweak during playtesting, it goes
	in this file instead. Playtesting with your son will be a lot of "make the
	timer shorter" / "make the DI meaner" and you want that to be a one-line edit.
]]

local Config = {}

Config.Formation = {
	-- Where the receiving deck sits in the world.
	Origin = Vector3.new(0, 4, 0),

	-- The famous yellow footprints: 4 rows of 5, heels together, 45 degrees out.
	Rows = 4,
	Columns = 5,
	SpacingX = 6,
	SpacingZ = 8,

	PadSize = Vector3.new(3, 0.2, 3),
	PadColor = Color3.fromRGB(255, 204, 0),

	-- How close a recruit must be to a pad to claim it.
	ClaimRadius = 4,

	-- How far a recruit may drift off their pad mid-drill before the DI notices.
	DriftTolerance = 5.5,
}

Config.Drill = {
	-- Seconds recruits get to fall in before the first command.
	FallInSeconds = 25,

	-- How many commands make up one drill session.
	CommandsPerSession = 12,

	-- Seconds to execute a command before it counts as a no-response.
	ResponseWindow = 3.0,

	-- Dead air between commands, so it does not feel like a rhythm game.
	MinPauseBetweenCommands = 1.2,
	MaxPauseBetweenCommands = 2.8,

	-- Seconds of scoreboard/debrief before the next session starts.
	DebriefSeconds = 12,

	-- Do not start a session with an empty deck.
	MinimumRecruits = 1,
}

Config.Scoring = {
	-- Executed correctly and inside the crisp window.
	CorrectCrisp = 100,
	-- Correct, but slow (still inside the response window).
	CorrectSlow = 45,
	-- Fraction of the response window that still counts as "crisp".
	CrispFraction = 0.45,

	Wrong = -25,
	NoResponse = -40,
	LeftFormation = -60,

	-- Consecutive crisp executions needed before the streak bonus kicks in.
	StreakThreshold = 3,
	StreakBonus = 25,

	-- Demerits before the recruit gets sent to the quarterdeck.
	DemeritsBeforeIT = 3,
	-- Seconds of incentive training (a lockout, mechanically).
	IncentiveTrainingSeconds = 6,
}

Config.Overhead = {
	-- Roblox group whose ranks show over players' heads. This is where ranks
	-- live today; in-game progression will replace it once recruits can earn
	-- rank by training. Players outside the group show NoGroupRank.
	GroupId = 9436889,
	NoGroupRank = "Civilian",
	-- Shown when a player has no Team yet.
	NoDivision = "Unassigned",

	-- Layout. Sizes are in pixels; HeightAboveHead is in studs.
	Width = 260,
	Height = 110,
	HeightAboveHead = 2.6,
	MaxDistance = 120,
	InsigniaSize = 28,
	NameTextSize = 22,
	TextSize = 16,
	LinePadding = 1,

	Font = Enum.Font.GothamBold,
	NameColor = Color3.fromRGB(255, 221, 82),
	TextColor = Color3.fromRGB(240, 240, 240),
	StrokeColor = Color3.fromRGB(0, 0, 0),
	StrokeTransparency = 0.4,

	-- Group rank id -> insignia decal. Reused from the previous overhead system;
	-- ranks with no entry show no insignia.
	Insignia = {
		[3] = "rbxassetid://8891244053", -- E2
		[4] = "rbxassetid://8891244211", -- E3
		[5] = "rbxassetid://8891244331", -- E4
		[6] = "rbxassetid://8891244441", -- E5
		[7] = "rbxassetid://8891244559", -- E6
		[8] = "rbxassetid://9431131770", -- E7
		[9] = "rbxassetid://8891244755", -- E8A
		[10] = "rbxassetid://8891244887", -- E8B
		[11] = "rbxassetid://8891245013", -- E9A
		[12] = "rbxassetid://8891245103", -- E9B
		[14] = "rbxassetid://8891246033", -- O1
		[15] = "rbxassetid://8891246191", -- O2
		[16] = "rbxassetid://8891246376", -- O3
		[17] = "rbxassetid://8891246608", -- O4
		[18] = "rbxassetid://8891247576", -- O5
		[19] = "rbxassetid://8891246805", -- O6
		[20] = "rbxassetid://8891246920", -- O7
		[21] = "rbxassetid://8891247017", -- O8
		[22] = "rbxassetid://8891247134", -- O9
		[24] = "rbxassetid://8891247017", -- IG O8
		[25] = "rbxassetid://8891247134", -- DMCS O9
		[26] = "rbxassetid://8891245222", -- SMMC E9C
		[27] = "rbxassetid://8891248325", -- ACMC O10
		[29] = "rbxassetid://13328264459", -- CMC O10
		[255] = "rbxassetid://13328277177", -- SECDEF
	},
}

Config.Debug = {
	-- Set true to print drill state transitions to the server console.
	Verbose = false,
}

return Config
