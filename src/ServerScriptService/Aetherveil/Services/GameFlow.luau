-- AETHERVEIL · Menu <-> game flow
-- Players start in the main menu with no character. Pressing Play spawns them
-- with their selected element and weapons; they respawn automatically while
-- playing, and can return to the menu when they're out of combat.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Elements = require(Root.Config.Elements)
local Store = require(Root.Config.Store)
local PlayerData = require(script.Parent.PlayerData)
local Currency = require(script.Parent.Currency)
local Purchases = require(script.Parent.Purchases)
local ElementService = require(script.Parent.ElementService)
local WeaponService = require(script.Parent.WeaponService)

local GameFlow = {}

local RESPAWN_DELAY = 4
local COMBAT_LOCK = 8
local SPAWN_PROTECTION = 3

local lastHurt = {}

local function portal()
	return Purchases.PortalService
end

local function refreshPortalAccess(player)
	local service = portal()
	if service and service.RefreshAccess then
		service.RefreshAccess(player)
	end
end

local function applyAura(player, char)
	if not Purchases.Owns(player, "Cosmetics") then
		return
	end
	local def = Elements.Get(player:GetAttribute("Element"))
	local root = char:FindFirstChild("HumanoidRootPart")
	if not def or not root then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AetherAura"
	emitter.Color = ColorSequence.new(def.Color, def.Accent)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new(0.2, 1)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = 14
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = root

	local a0 = Instance.new("Attachment")
	a0.Name = "AuraTop"
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "AuraBottom"
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "AetherTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(def.Color, def.Accent)
	trail.Transparency = NumberSequence.new(0.5, 1)
	trail.LightEmission = 1
	trail.Lifetime = 0.35
	trail.Parent = root
end

local function onCharacterAdded(player, char)
	if not player:GetAttribute("InGame") then
		return
	end
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then
		return
	end

	local shield = Instance.new("ForceField")
	shield.Parent = char
	Debris:AddItem(shield, SPAWN_PROTECTION)

	local lastHealth = hum.Health
	hum.HealthChanged:Connect(function(health)
		if health < lastHealth then
			lastHurt[player] = os.clock()
		end
		lastHealth = health
	end)

	hum.Died:Connect(function()
		PlayerData.Update(player, function(data)
			data.Stats.Deaths += 1
		end)
		task.delay(RESPAWN_DELAY, function()
			if player.Parent and player:GetAttribute("InGame") and player.Character == char then
				player:LoadCharacter()
			end
		end)
	end)

	player:WaitForChild("Backpack", 5)
	WeaponService.Give(player)
	applyAura(player, char)
end

function GameFlow.Play(player)
	if player:GetAttribute("InGame") then
		return { ok = true }
	end
	local data = PlayerData.Get(player)
	if not data.Element or not ElementService.IsUnlocked(player, data.Element) then
		return { ok = false, code = "NoElement", msg = "Choose an element before entering the Veil." }
	end
	WeaponService.Sanitize(player)
	player:SetAttribute("Element", data.Element)
	player:SetAttribute("InGame", true)
	refreshPortalAccess(player)
	local ok, err = pcall(function()
		player:LoadCharacter()
	end)
	if not ok then
		player:SetAttribute("InGame", false)
		refreshPortalAccess(player)
		warn("[Aetherveil] LoadCharacter failed: " .. tostring(err))
		return { ok = false, msg = "Couldn't spawn you. Try again." }
	end
	return { ok = true }
end

function GameFlow.ReturnToMenu(player)
	if not player:GetAttribute("InGame") then
		return { ok = true }
	end
	if player:GetAttribute("InVoid") then
		return { ok = false, msg = "You can't leave while you're in the Void." }
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and lastHurt[player] and os.clock() - lastHurt[player] < COMBAT_LOCK then
		return { ok = false, msg = "You're in combat. Wait a moment before leaving." }
	end
	player:SetAttribute("InGame", false)
	refreshPortalAccess(player)
	player.Character = nil
	if char then
		char:Destroy()
	end
	return { ok = true }
end

function GameFlow.Init()
	Players.CharacterAutoLoads = false

	local function onPlayer(player)
		player:SetAttribute("InGame", false)
		player.CharacterAdded:Connect(function(char)
			onCharacterAdded(player, char)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end

	PlayerData.Loaded:Connect(function(player)
		local data = PlayerData.Get(player)
		if data and data.Element then
			player:SetAttribute("Element", data.Element)
		end
		refreshPortalAccess(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastHurt[player] = nil
	end)

	-- passive shards while playing
	task.spawn(function()
		while true do
			task.wait(Store.Rewards.PassiveInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("InGame") and PlayerData.IsLoaded(player) then
					local amount = Store.Rewards.Passive
					if Purchases.Owns(player, "VIP") then
						amount = math.floor(amount * Store.Rewards.VIPMultiplier)
					end
					Currency.Add(player, amount)
				end
			end
		end
	end)
end

return GameFlow
