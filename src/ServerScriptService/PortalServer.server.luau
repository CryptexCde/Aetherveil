-- Wires player input to the Portal Walker powers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("PortalConfig"))
local Service = require(ServerStorage:WaitForChild("PortalService"))
local Action = ReplicatedStorage:WaitForChild("PortalRemotes"):WaitForChild("Action")

Service.Init()

local lastUse = {}
Action.OnServerEvent:Connect(function(player, action, target)
	local t = os.clock()
	if lastUse[player] and t - lastUse[player] < 0.15 then
		return
	end
	lastUse[player] = t

	if action == "Void" then
		Service.ThrowVoid(player, target)
	elseif action == "Teleport" then
		Service.PlaceTeleport(player, target)
	elseif action == "Lance" then
		Service.Lance(player, target)
	elseif action == "Singularity" then
		Service.Singularity(player, target)
	elseif action == "Buy" then
		if Config.GAMEPASS_ID ~= 0 and not Service.HasPass(player) then
			MarketplaceService:PromptGamePassPurchase(player, Config.GAMEPASS_ID)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)

-- Studio-only test hook (lets the builder test traps without a second player)
if game:GetService("RunService"):IsStudio() then
	local debug = Instance.new("BindableFunction")
	debug.Name = "PortalDebug"
	debug.OnInvoke = function(cmd, player, arg)
		if cmd == "trap" then
			Service.Trap(player, nil, arg)
		elseif cmd == "visit" then
			Service.Trap(player, player, arg, true)
		elseif cmd == "free" then
			Service.Free(player)
		elseif cmd == "exit" then
			Service.OpenNaturalExit()
		elseif cmd == "void" then
			Service.ThrowVoid(player, arg)
		elseif cmd == "tele" then
			Service.PlaceTeleport(player, arg)
		elseif cmd == "lance" then
			Service.Lance(player, arg)
		elseif cmd == "singularity" then
			Service.Singularity(player, arg)
		elseif cmd == "petrify" then
			Service.Petrify(player)
		elseif cmd == "trapped" then
			return Service.IsTrapped(player)
		elseif cmd == "age" then
			Service.DebugAge(player, arg)
		elseif cmd == "souls" then
			Service.DebugSouls(player, arg)
		end
		return true
	end
	debug.Parent = ServerStorage
end
