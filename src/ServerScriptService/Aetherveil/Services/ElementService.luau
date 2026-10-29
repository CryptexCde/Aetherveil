-- AETHERVEIL · Element unlocking and selection

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Elements = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Elements)
local PlayerData = require(script.Parent.PlayerData)
local Currency = require(script.Parent.Currency)
local Purchases = require(script.Parent.Purchases)

local ElementService = {}

function ElementService.IsUnlocked(player, id)
	local def = Elements.Get(id)
	local data = PlayerData.Get(player)
	if not def or not data then
		return false
	end
	local unlock = def.Unlock
	if unlock.Type == "Free" then
		return true
	elseif unlock.Type == "Coins" then
		return data.Elements[id] == true
	elseif unlock.Type == "Gamepass" then
		return data.Elements[id] == true or Purchases.Owns(player, unlock.Pass)
	end
	return false
end

function ElementService.UnlockedMap(player)
	local map = {}
	for _, id in ipairs(Elements.Order) do
		map[id] = ElementService.IsUnlocked(player, id)
	end
	return map
end

function ElementService.Select(player, id)
	local def = Elements.Get(id)
	if not def then
		return { ok = false, msg = "That element doesn't exist." }
	end
	if player:GetAttribute("InGame") then
		return { ok = false, msg = "Return to the main menu to change your element." }
	end
	if not ElementService.IsUnlocked(player, id) then
		return { ok = false, msg = def.Name .. " is still locked." }
	end
	PlayerData.Update(player, function(data)
		data.Element = id
	end)
	player:SetAttribute("Element", id)
	return { ok = true, msg = def.Name .. " equipped." }
end

function ElementService.Unlock(player, id)
	local def = Elements.Get(id)
	if not def then
		return { ok = false, msg = "That element doesn't exist." }
	end
	if ElementService.IsUnlocked(player, id) then
		return { ok = false, msg = "You already have " .. def.Name .. "." }
	end
	local unlock = def.Unlock
	if unlock.Type == "Coins" then
		if not Currency.Spend(player, unlock.Price) then
			return { ok = false, msg = "Not enough Aether Shards." }
		end
		PlayerData.Update(player, function(data)
			data.Elements[id] = true
		end)
		return { ok = true, msg = def.Name .. " unlocked!" }
	elseif unlock.Type == "Gamepass" then
		return Purchases.PromptPass(player, unlock.Pass)
	end
	return { ok = false, msg = "This element can't be unlocked right now." }
end

return ElementService
