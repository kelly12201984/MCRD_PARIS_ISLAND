--!strict
--[[
	One module that both sides require to get the same RemoteEvents.

	The server creates them on first require; the client waits for them. This
	avoids the classic Roblox race where a LocalScript runs before the server has
	finished building ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTE_NAMES = {
	-- Server -> all clients: the DI just issued a command.
	"IssueCommand",
	-- Client -> server: this recruit reacted.
	"SubmitAction",
	-- Server -> one client: how that reaction was graded.
	"Feedback",
	-- Server -> all clients: fall in / drill / debrief transitions.
	"PhaseChanged",
	-- Server -> all clients: the debrief scoreboard.
	"Scoreboard",
}

local folder: Folder

if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		folder = existing :: Folder
	else
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local Remotes: { [string]: RemoteEvent } = {}

for _, name in REMOTE_NAMES do
	Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
