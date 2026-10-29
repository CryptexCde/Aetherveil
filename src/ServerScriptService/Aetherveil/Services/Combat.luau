-- AETHERVEIL · Shared damage, kill credit and kill rewards
-- Uses the standard "creator" tag (also used by the Portal Walker powers),
-- so every kill from any source pays out the same way.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Store)

local Combat = {}

local rewardHandler -- set by Main: function(killer, victim)

function Combat.SetRewardHandler(fn)
	rewardHandler = fn
end

function Combat.Damage(attacker, humanoid, amount)
	if not humanoid or humanoid.Health <= 0 or amount <= 0 then
		return
	end
	local victimPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
	if victimPlayer == attacker then
		return
	end
	local tag = humanoid:FindFirstChild("creator")
	if not tag then
		tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Parent = humanoid
	end
	tag.Value = attacker
	Debris:AddItem(tag, 5)
	humanoid:TakeDamage(amount)
end

-- Finds living humanoids near a point (excluding one character).
function Combat.HumanoidsInRadius(position, radius, exclude)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude or {}
	local found, out = {}, {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(position, radius, params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 and not found[hum] then
			found[hum] = true
			table.insert(out, { Humanoid = hum, Root = root, Model = model })
		end
	end
	return out
end

local function watchCharacter(player, char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then
		return
	end
	hum.Died:Connect(function()
		local tag = hum:FindFirstChild("creator")
		local killer = tag and tag.Value
		if killer and killer:IsA("Player") and killer ~= player and killer.Parent and rewardHandler then
			rewardHandler(killer, player)
		end
	end)
end

function Combat.Init()
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char)
			watchCharacter(player, char)
		end)
		if player.Character then
			task.spawn(watchCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
end

Combat.KillReward = Store.Rewards.Kill

return Combat
