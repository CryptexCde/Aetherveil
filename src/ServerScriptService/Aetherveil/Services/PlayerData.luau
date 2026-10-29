-- AETHERVEIL · Player data (DataStoreService)
-- Session-locked loading with retries, autosave, save on leave and on shutdown.
-- If the DataStore can't be reached (e.g. Studio without API access) the player
-- gets a temporary profile that is never saved, so real data is never overwritten.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Aetherveil"):WaitForChild("Config")
local Store = require(Config:WaitForChild("Store"))
local Weapons = require(Config:WaitForChild("Weapons"))
local SettingsConfig = require(Config:WaitForChild("Settings"))

local STORE_NAME = "AetherveilPlayerData_v1"
local SCHEMA = 1
local AUTOSAVE_INTERVAL = 120
local LOCK_EXPIRE = 600 -- a lock older than this is treated as abandoned
local LOAD_ATTEMPTS = 6

local PlayerData = {}

local profiles = {} -- [player] = { Data = table, Persistent = bool }
local changedEvent = Instance.new("BindableEvent")
PlayerData.Changed = changedEvent.Event -- (player)
local loadedEvent = Instance.new("BindableEvent")
PlayerData.Loaded = loadedEvent.Event -- (player)

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Aetherveil] DataStore unavailable, progress will not save: " .. tostring(result))
	end
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = deepCopy(v)
	end
	return out
end

local function template()
	return {
		Schema = SCHEMA,
		Coins = Store.Currency.Starting,
		Elements = {}, -- [elementId] = true for elements unlocked with shards
		Weapons = { [Weapons.StarterWeapon] = true },
		Equipped = { Weapons.StarterWeapon },
		Settings = deepCopy(SettingsConfig.Defaults),
		Receipts = {},
		ReceiptOrder = {},
		Stats = { Kills = 0, Deaths = 0 },
		-- Element = "Fire" (nil until the player chooses one)
	}
end

local function reconcile(data)
	local base = template()
	for k, v in pairs(base) do
		if data[k] == nil then
			data[k] = v
		end
	end
	data.Settings = SettingsConfig.Sanitize(data.Settings)
	if type(data.Coins) ~= "number" or data.Coins ~= data.Coins then
		data.Coins = 0
	end
	data.Coins = math.max(0, math.floor(data.Coins))
	data.Weapons[Weapons.StarterWeapon] = true
	data.Schema = SCHEMA
	return data
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function loadAsync(player)
	if not store then
		return nil, false
	end
	for attempt = 1, LOAD_ATTEMPTS do
		if not player.Parent then
			return nil, false
		end
		local locked = false
		local result
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function(old)
				old = type(old) == "table" and old or {}
				local lock = old.Lock
				local otherServer = lock and lock.JobId ~= game.JobId
				local fresh = lock and (os.time() - (lock.Time or 0)) < LOCK_EXPIRE
				-- respect another server's lock for a few tries, then take over
				if otherServer and fresh and attempt < LOAD_ATTEMPTS - 1 then
					locked = true
					return nil
				end
				locked = false
				old.Lock = { JobId = game.JobId, Time = os.time() }
				result = old.Data
				return old
			end)
		end)
		if ok and not locked then
			return result, true
		end
		if not ok then
			warn(("[Aetherveil] Load attempt %d for %s failed: %s"):format(attempt, player.Name, tostring(err)))
		end
		task.wait(locked and 4 or math.min(2 * attempt, 8))
	end
	return nil, false
end

local function saveAsync(player, release)
	local profile = profiles[player]
	if not profile or not profile.Persistent or not store then
		return false
	end
	local snapshot = deepCopy(profile.Data)
	local saved = false
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(old)
			old = type(old) == "table" and old or {}
			if old.Lock and old.Lock.JobId ~= game.JobId and (os.time() - (old.Lock.Time or 0)) < LOCK_EXPIRE then
				-- another server owns this player now; never overwrite their newer data
				saved = false
				return nil
			end
			old.Data = snapshot
			if release then
				old.Lock = nil
			else
				old.Lock = { JobId = game.JobId, Time = os.time() }
			end
			saved = true
			return old
		end)
	end)
	if not ok then
		warn(("[Aetherveil] Save failed for %s: %s"):format(player.Name, tostring(err)))
		return false
	end
	return saved
end

local function onPlayerAdded(player)
	local data, persistent = loadAsync(player)
	if not player.Parent then
		return
	end
	if data == nil then
		data = template()
	end
	profiles[player] = { Data = reconcile(data), Persistent = persistent }
	loadedEvent:Fire(player)
	changedEvent:Fire(player)
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	saveAsync(player, true)
	profiles[player] = nil
end

function PlayerData.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in pairs(profiles) do
				task.spawn(saveAsync, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				saveAsync(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

function PlayerData.Get(player)
	local profile = profiles[player]
	return profile and profile.Data or nil
end

function PlayerData.IsLoaded(player)
	return profiles[player] ~= nil
end

function PlayerData.IsPersistent(player)
	local profile = profiles[player]
	return profile ~= nil and profile.Persistent
end

function PlayerData.WaitForLoad(player, timeout)
	local started = os.clock()
	while not profiles[player] do
		if not player.Parent or os.clock() - started > (timeout or 30) then
			return false
		end
		task.wait(0.1)
	end
	return true
end

-- Mutate a player's data; fn receives the data table. Returns whatever fn returns.
function PlayerData.Update(player, fn)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local result = fn(profile.Data)
	changedEvent:Fire(player)
	return result
end

function PlayerData.Save(player)
	return saveAsync(player, false)
end

return PlayerData
