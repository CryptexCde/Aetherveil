-- AETHERVEIL · Server bootstrap
-- Starts every service and handles all menu requests from the client.
-- Every request is rate limited, type checked and validated by its service.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Net = require(Root.Shared.Net)
Net.Init()

local Services = script.Parent:WaitForChild("Services")
local Store = require(Root.Config.Store)
local SettingsConfig = require(Root.Config.Settings)
local PlayerData = require(Services.PlayerData)
local Currency = require(Services.Currency)
local Purchases = require(Services.Purchases)
local Notify = require(Services.Notify)
local Combat = require(Services.Combat)
local ElementService = require(Services.ElementService)
local WeaponService = require(Services.WeaponService)
local ShopService = require(Services.ShopService)
local ElementAbilities = require(Services.ElementAbilities)
local GameFlow = require(Services.GameFlow)

GameFlow.Init() -- first, so CharacterAutoLoads is off before anyone spawns
PlayerData.Init()
Purchases.Init()
Combat.Init()
ElementAbilities.Init()

---------------------------------------------------------------- kill rewards
Combat.SetRewardHandler(function(killer, victim)
	if not PlayerData.IsLoaded(killer) then
		return
	end
	local amount = Store.Rewards.Kill
	if Purchases.Owns(killer, "VIP") then
		amount = math.floor(amount * Store.Rewards.VIPMultiplier)
	end
	Currency.Add(killer, amount)
	PlayerData.Update(killer, function(data)
		data.Stats.Kills += 1
	end)
	Notify.Toast(killer, ("+%d %s · Defeated %s"):format(amount, Store.Currency.Short, victim.DisplayName), "success")
end)

---------------------------------------------------------------- snapshots
local function copy(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = type(v) == "table" and copy(v) or v
	end
	return out
end

local function snapshot(player)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end
	return {
		Loaded = true,
		Persistent = PlayerData.IsPersistent(player),
		Coins = data.Coins,
		Element = data.Element,
		Elements = ElementService.UnlockedMap(player),
		Weapons = copy(data.Weapons),
		Equipped = copy(data.Equipped),
		Slots = WeaponService.Slots(player),
		Passes = Purchases.OwnedMap(player),
		Settings = copy(data.Settings),
		Stats = copy(data.Stats),
	}
end

local DataEvent = Net.Get("Data")
local pendingPush = {}
local function push(player)
	if pendingPush[player] then
		return
	end
	pendingPush[player] = true
	task.defer(function()
		pendingPush[player] = nil
		if player.Parent and PlayerData.IsLoaded(player) then
			DataEvent:FireClient(player, snapshot(player))
		end
	end)
end
PlayerData.Changed:Connect(push)
Purchases.Changed:Connect(push)
PlayerData.Loaded:Connect(function(player)
	WeaponService.Sanitize(player)
	if not PlayerData.IsPersistent(player) then
		Notify.Toast(player, "Your progress can't be saved right now. It will be kept for this session only.", "error")
	end
end)

---------------------------------------------------------------- requests
local function isString(v)
	return type(v) == "string" and #v > 0 and #v < 64
end

local handlers = {}

handlers.GetSnapshot = function(player)
	return { ok = true, data = snapshot(player) }
end

handlers.SelectElement = function(player, id)
	if not isString(id) then
		return { ok = false, msg = "Invalid element." }
	end
	return ElementService.Select(player, id)
end

handlers.UnlockElement = function(player, id)
	if not isString(id) then
		return { ok = false, msg = "Invalid element." }
	end
	return ElementService.Unlock(player, id)
end

handlers.EquipWeapon = function(player, id)
	if not isString(id) then
		return { ok = false, msg = "Invalid weapon." }
	end
	return WeaponService.Equip(player, id)
end

handlers.BuyWeapon = function(player, id)
	if not isString(id) then
		return { ok = false, msg = "Invalid weapon." }
	end
	return ShopService.BuyWeapon(player, id)
end

handlers.PromptPass = function(player, key)
	if not isString(key) then
		return { ok = false, msg = "Invalid pass." }
	end
	return Purchases.PromptPass(player, key)
end

handlers.PromptProduct = function(player, key)
	if not isString(key) then
		return { ok = false, msg = "Invalid pack." }
	end
	return Purchases.PromptProduct(player, key)
end

handlers.SaveSettings = function(player, settings)
	local clean = SettingsConfig.Sanitize(settings)
	PlayerData.Update(player, function(data)
		data.Settings = clean
	end)
	return { ok = true }
end

handlers.Play = function(player)
	return GameFlow.Play(player)
end

handlers.ReturnToMenu = function(player)
	return GameFlow.ReturnToMenu(player)
end

local buckets = {}
local function allow(player, cost)
	local t = os.clock()
	local b = buckets[player]
	if not b then
		b = { tokens = 12, last = t }
		buckets[player] = b
	end
	b.tokens = math.min(12, b.tokens + (t - b.last) * 6)
	b.last = t
	if b.tokens < cost then
		return false
	end
	b.tokens -= cost
	return true
end

Net.Get("Request").OnServerInvoke = function(player, action, arg)
	if type(action) ~= "string" or not handlers[action] then
		return { ok = false, msg = "Unknown request." }
	end
	if not allow(player, 1) then
		return { ok = false, msg = "Slow down a little." }
	end
	if action ~= "GetSnapshot" and not PlayerData.IsLoaded(player) then
		return { ok = false, msg = "Your data is still loading." }
	end
	local ok, result = pcall(handlers[action], player, arg)
	if not ok then
		warn(("[Aetherveil] %s failed for %s: %s"):format(action, player.Name, tostring(result)))
		return { ok = false, msg = "Something went wrong. Try again." }
	end
	return result
end

local abilityBuckets = {}
Net.Get("Ability").OnServerEvent:Connect(function(player, abilityId, aim)
	if type(abilityId) ~= "string" then
		return
	end
	local t = os.clock()
	if abilityBuckets[player] and t - abilityBuckets[player] < 0.12 then
		return
	end
	abilityBuckets[player] = t
	ElementAbilities.Use(player, abilityId, aim)
end)

Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
	abilityBuckets[player] = nil
	pendingPush[player] = nil
end)
