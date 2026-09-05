-- Runs on the server. Greets every player who joins.
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print("Recruit " .. player.Name .. " has arrived at Parris Island!")
end)
