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
	-- The real map: tag each painted formation box in Studio (Properties ->
	-- Tags) with SpotTag and the code uses those. Tag the thing the DI stands
	-- on/at with FrontTag and recruits face it.
	SpotTag = "FormationSpot",
	FrontTag = "FormationFront",
	-- Spots this close (in studs) to the front count as the same rank, for
	-- numbering them front-to-back, left-to-right.
	RowBucketStuds = 4,

	-- Fallback when nothing is tagged: generate a yellow grid so the game still
	-- runs on an empty baseplate. Placed at a Part named MarkerName, else Origin.
	GenerateIfNoSpots = true,
	MarkerName = "FormationOrigin",
	Origin = Vector3.new(-3008, 6, -277),
	SnapToGround = true,
	GroundProbeHeight = 50,
	BuildDeck = false,
	Rows = 4,
	Columns = 5,
	SpacingX = 6,
	SpacingZ = 8,
	PadSize = Vector3.new(3, 0.2, 3),
	PadColor = Color3.fromRGB(255, 204, 0),

	-- How the claimed spot is shown (a Highlight, so nothing is recolored).
	ClaimFillTransparency = 0.6,

	-- How close (horizontally) a recruit must be to a spot to claim it.
	ClaimRadius = 4,
	-- How far a recruit may drift off their spot mid-drill before the DI notices.
	DriftTolerance = 5.5,
	-- Studs above the spot's surface to place the character root when snapping.
	StandHeight = 3,

	-- The marker that floats over the formation during fall-in so nobody has
	-- to hunt for it. Sized in pixels so it reads from any distance.
	BeaconText = "FALL IN HERE",
	BeaconHeight = 14,
	BeaconWidthPx = 300,
	BeaconHeightPx = 70,
	BeaconMaxDistance = 3000,
}

Config.Spawn = {
	-- Tag the bus stop and a spot in town (Properties -> Tags). Recruits --
	-- players who hold a division -- spawn at the bus stop; everyone else
	-- spawns in town.
	BusStopTag = "BusStop",
	TownSpawnTag = "TownSpawn",
}

Config.Drill = {
	-- Seconds recruits get to fall in once the FIRST recruit reaches the deck.
	-- The clock does not start on an empty deck.
	FallInSeconds = 25,

	-- How many commands make up one drill session.
	CommandsPerSession = 12,

	-- Seconds to execute a command before it counts as a no-response. Needs to
	-- cover reading the call AND the options; 3 was not enough for anyone.
	ResponseWindow = 6.0,

	-- Dead air between commands, so it does not feel like a rhythm game.
	MinPauseBetweenCommands = 2.0,
	MaxPauseBetweenCommands = 3.5,

	-- Seconds of scoreboard/debrief before the next session starts.
	DebriefSeconds = 12,

	-- Do not start a session with an empty server.
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

Config.Progression = {
	-- XP per point of session score. A clean 12-command session scores roughly
	-- 1,200-1,500, so this is about 300-375 XP; negative scores earn nothing.
	ScoreToXp = 0.25,
	-- Flat XP for finishing a session with fewer than CompletionDemeritCap demerits.
	CompletionXp = 20,
	CompletionDemeritCap = 3,

	-- DataStore name. Change the suffix to wipe everyone's record on purpose.
	DataStoreName = "ServiceRecords_v1",
	-- Seconds between background saves of records that changed.
	AutosaveSeconds = 120,
}

Config.Overhead = {
	-- Geometry copied from the overhead the game used before: a 4 x 3 stud
	-- billboard whose center sits 1.6 studs above the head, with the content
	-- in the top 70% and the bottom left empty as breathing room.
	WidthStuds = 4,
	HeightStuds = 3,
	StudsAboveHead = 1.6,
	-- Studs beyond which the tag is not drawn at all.
	MaxDistance = 120,

	-- Each line's vertical band: top edge and height, as fractions of the
	-- billboard height, measured from the top. Fixed bands, so nothing shifts
	-- when a line is hidden. Text scales to fit its band.
	Bands = {
		Insignia = { Top = 0.0, Height = 0.2 },
		Name = { Top = 0.17, Height = 0.2 },
		Rank = { Top = 0.36, Height = 0.17 },
		Division = { Top = 0.53, Height = 0.17 },
	},

	Font = Enum.Font.GothamBold,
	NameColor = Color3.fromRGB(255, 221, 82),
	TextColor = Color3.fromRGB(240, 240, 240),
	StrokeColor = Color3.fromRGB(0, 0, 0),
	StrokeTransparency = 0.4,
}

Config.Debug = {
	-- Set true to print drill state transitions to the server console.
	Verbose = false,
}

return Config
