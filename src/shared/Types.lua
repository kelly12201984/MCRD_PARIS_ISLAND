--!strict
--[[
	Shared Luau types. Keeping these in one place means the server and the client
	agree on the shape of every payload that crosses a RemoteEvent.

	Import with:  local Types = require(Shared.Types)
	Annotate with: local cmd: Types.Command = ...
]]

-- A command is either something you shout back, or something you do with your feet.
export type CommandKind = "Movement" | "Response"

export type Command = {
	id: string,
	kind: CommandKind,
	-- What the drill instructor actually shouts.
	call: string,
	-- Facing change in quarter-turns, clockwise. Movement commands only.
	facingDelta: number?,
	-- Index into `options` that is correct. Response commands only.
	answerIndex: number?,
	-- What the recruit may shout back. Response commands only.
	options: { string }?,
}

-- Sent server -> client when the DI issues a command.
export type CommandPayload = {
	sequence: number,
	kind: CommandKind,
	call: string,
	options: { string }?,
	window: number,
}

-- Sent client -> server when the recruit reacts.
-- `action` is "Left" | "Right" | "About" for Movement, or an option index for Response.
export type ActionPayload = {
	sequence: number,
	action: string | number,
}

export type Grade = "Crisp" | "Slow" | "Wrong" | "NoResponse" | "LeftFormation"

-- Sent server -> client after each command is evaluated.
export type FeedbackPayload = {
	sequence: number,
	grade: Grade,
	-- The DI's reaction, already picked server-side so everyone hears the same line.
	bark: string,
	delta: number,
	score: number,
	demerits: number,
	streak: number,
}

export type Phase = "Waiting" | "FallIn" | "Drill" | "Debrief"

export type PhasePayload = {
	phase: Phase,
	-- Seconds this phase is expected to last. Nil for open-ended phases.
	duration: number?,
	message: string,
}

export type ScoreRow = {
	name: string,
	score: number,
	demerits: number,
}

-- One recruit's server-side state. Server only, but declared here so it is
-- documented alongside everything else.
export type RecruitState = {
	player: Player,
	padIndex: number?,
	-- 0 = north, 1 = east, 2 = south, 3 = west.
	facing: number,
	score: number,
	demerits: number,
	streak: number,
	-- Set while the recruit is locked out doing incentive training.
	itUntil: number,
	-- Response to the command currently on the clock, if any.
	pendingAction: (string | number)?,
	pendingAt: number?,
}

return {}
