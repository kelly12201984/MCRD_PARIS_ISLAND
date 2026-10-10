--!strict
--[[
	The drill instructor's vocabulary.

	This is the file to hand your son. It is pure data, no logic -- he can add
	commands, reword barks, and retune the mix without touching a single service.
	That is deliberate: it gives him a real, safe surface to own.

	Movement commands use `facingDelta` in quarter-turns clockwise:
	    +1 = right face, -1 = left face, +2 = about face.
	Response commands use `options` plus the index of the correct one.
]]

local Types = require(script.Parent.Types)

local CommandCatalog = {}

local COMMANDS: { Types.Command } = {
	{
		id = "right_face",
		kind = "Movement",
		call = "RIGHT... FACE!",
		facingDelta = 1,
	},
	{
		id = "left_face",
		kind = "Movement",
		call = "LEFT... FACE!",
		facingDelta = -1,
	},
	{
		id = "about_face",
		kind = "Movement",
		call = "ABOUT... FACE!",
		facingDelta = 2,
	},
	{
		id = "eyes",
		kind = "Response",
		call = "EYES!",
		options = { "SNAP, SIR!", "AYE, SIR!", "OPEN, SIR!" },
		answerIndex = 1,
	},
	{
		id = "ears",
		kind = "Response",
		call = "EARS!",
		options = { "SNAP, SIR!", "OPEN, SIR!", "YES, SIR!" },
		answerIndex = 2,
	},
	{
		id = "understand",
		kind = "Response",
		call = "DO YOU UNDERSTAND?",
		options = { "OKAY, SIR!", "SIR, YES SIR!", "SNAP, SIR!" },
		answerIndex = 2,
	},
	{
		id = "kill",
		kind = "Response",
		call = "WHAT MAKES THE GRASS GROW?",
		options = { "RAIN, SIR!", "SIR, BLOOD SIR!", "SUN, SIR!" },
		answerIndex = 2,
	},
}

-- The DI's reaction lines, keyed by grade. Picked server-side so every client
-- on the deck hears the same thing at the same time.
local BARKS: { [string]: { string } } = {
	Crisp = {
		"THAT'S HOW IT'S DONE!",
		"ACCEPTABLE. BARELY.",
		"OUTSTANDING!",
		"DO IT AGAIN, JUST LIKE THAT!",
	},
	Slow = {
		"TOO SLOW, RECRUIT!",
		"MY GRANDMOTHER MOVES FASTER!",
		"WERE YOU WAITING FOR AN INVITATION?",
	},
	Wrong = {
		"WRONG! ARE YOU LISTENING TO ME?",
		"THAT IS NOT WHAT I SAID!",
		"UNBELIEVABLE. RESET!",
	},
	NoResponse = {
		"I DID NOT HEAR YOU!",
		"NOTHING? YOU'RE A STATUE NOW?",
		"WAKE UP, RECRUIT!",
	},
	LeftFormation = {
		"GET BACK ON THOSE FOOTPRINTS!",
		"DID I TELL YOU TO MOVE?",
		"NOBODY DISMISSED YOU!",
	},
}

CommandCatalog.Commands = COMMANDS
CommandCatalog.Barks = BARKS

-- Variety without needing a shared RNG on both sides: the server rolls, the
-- client is just told the result.
function CommandCatalog.pickBark(grade: Types.Grade, rng: Random): string
	local pool = BARKS[grade]
	if not pool or #pool == 0 then
		return ""
	end
	return pool[rng:NextInteger(1, #pool)]
end

function CommandCatalog.pickCommand(rng: Random): Types.Command
	return COMMANDS[rng:NextInteger(1, #COMMANDS)]
end

function CommandCatalog.getById(id: string): Types.Command?
	for _, command in COMMANDS do
		if command.id == id then
			return command
		end
	end
	return nil
end

return CommandCatalog
