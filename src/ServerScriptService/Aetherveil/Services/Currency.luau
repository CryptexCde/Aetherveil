-- AETHERVEIL · Aether Shards (server-authoritative)

local PlayerData = require(script.Parent.PlayerData)

local Currency = {}

function Currency.Get(player)
	local data = PlayerData.Get(player)
	return data and data.Coins or 0
end

function Currency.Add(player, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return 0
	end
	PlayerData.Update(player, function(data)
		data.Coins += amount
	end)
	return amount
end

-- Removes shards only if the player can afford it. Returns true on success.
function Currency.Spend(player, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 0 then
		return false
	end
	return PlayerData.Update(player, function(data)
		if data.Coins >= amount then
			data.Coins -= amount
			return true
		end
		return false
	end) == true
end

return Currency
