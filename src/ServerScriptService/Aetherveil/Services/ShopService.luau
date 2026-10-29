-- AETHERVEIL · Buying weapons with Aether Shards

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Weapons)
local PlayerData = require(script.Parent.PlayerData)
local Currency = require(script.Parent.Currency)
local Purchases = require(script.Parent.Purchases)

local ShopService = {}

function ShopService.BuyWeapon(player, id)
	local def = Weapons.Get(id)
	if not def or def.Starter then
		return { ok = false, msg = "That weapon isn't for sale." }
	end
	local data = PlayerData.Get(player)
	if data.Weapons[id] then
		return { ok = false, msg = "You already own " .. def.Name .. "." }
	end
	if def.Exclusive and not Purchases.Owns(player, "ExclusiveWeapons") then
		return { ok = false, code = "NeedsPass", msg = def.Name .. " requires the Exclusive Armory pass." }
	end
	if not Currency.Spend(player, def.Price) then
		return { ok = false, msg = "Not enough Aether Shards." }
	end
	PlayerData.Update(player, function(d)
		d.Weapons[id] = true
	end)
	return { ok = true, msg = def.Name .. " added to your armory!" }
end

return ShopService
