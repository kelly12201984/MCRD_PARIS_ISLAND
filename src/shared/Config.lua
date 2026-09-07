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
	-- Easiest way to place the deck: put a Part named this anywhere in the
	-- Workspace, move and rotate it in Studio, done. The formation centers on
	-- it and recruits face the way its front face points.
	MarkerName = "FormationOrigin",
	-- Used only when no marker part exists.
	Origin = Vector3.new(-3008, 6, -277),
	-- Raycast down from above the origin and put the pads on whatever it hits.
	SnapToGround = true,
	GroundProbeHeight = 50,
	-- Generate a concrete slab under the pads. Useful on an empty baseplate,
	-- ugly on real pavement.
	BuildDeck = false,

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

	-- The marker that floats over the deck during fall-in so nobody has to
	-- hunt for the footprints. Sized in pixels so it reads from any distance.
	BeaconText = "FALL IN HERE",
	BeaconHeight = 14,
	BeaconWidthPx = 300,
	BeaconHeightPx = 70,
	BeaconMaxDistance = 3000,
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
	-- The tag is sized in studs so it scales with the world like the avatar
	-- does. (Pixel sizing stays the same size on screen and looks enormous
	-- from a distance.)
	WidthStuds = 4.5,
	HeightStuds = 1.8,
	-- Gap between the top of the head and the bottom edge of the tag, in studs.
	ClearanceStuds = 0.9,
	-- Studs beyond which the tag is not drawn at all.
	MaxDistance = 120,

	-- Share of the tag's height each line gets. Text scales to fit.
	InsigniaFraction = 0.30,
	NameFraction = 0.26,
	RankFraction = 0.20,
	DivisionFraction = 0.20,

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
