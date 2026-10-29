-- AETHERVEIL · Server -> client notifications

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Aetherveil"):WaitForChild("Shared"):WaitForChild("Net"))

local Notify = {}

-- kind: "info" | "success" | "error"
function Notify.Toast(player, text, kind)
	if player and player.Parent then
		Net.Get("Toast"):FireClient(player, tostring(text), kind or "info")
	end
end

return Notify
