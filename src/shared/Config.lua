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

Config.Debug = {
	-- Set true to print drill state transitions to the server console.
	Verbose = false,
}

return Config
