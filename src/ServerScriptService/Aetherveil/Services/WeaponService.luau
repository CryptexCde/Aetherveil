-- AETHERVEIL · Equipping weapons and giving them to the player as tools

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Weapons = require(Root.Config.Weapons)
local WeaponModel = require(Root.Shared.WeaponModel)
local PlayerData = require(script.Parent.PlayerData)
local Purchases = require(script.Parent.Purchases)
local Combat = require(script.Parent.Combat)

local WeaponService = {}

function WeaponService.Slots(player)
	return Purchases.Owns(player, "ExtraSlots") and 2 or 1
end

-- Removes anything the player doesn't own and trims to their slot count.
function WeaponService.Sanitize(player)
	local slots = WeaponService.Slots(player)
	PlayerData.Update(player, function(data)
		local clean = {}
		for _, id in ipairs(data.Equipped) do
			if Weapons.Get(id) and data.Weapons[id] and not table.find(clean, id) then
				table.insert(clean, id)
			end
		end
		while #clean > slots do
			table.remove(clean, 1)
		end
		if #clean == 0 then
			table.insert(clean, Weapons.StarterWeapon)
		end
		data.Equipped = clean
	end)
end

function WeaponService.Equip(player, id)
	local def = Weapons.Get(id)
	if not def then
		return { ok = false, msg = "That weapon doesn't exist." }
	end
	if player:GetAttribute("InGame") then
		return { ok = false, msg = "Return to the main menu to change weapons." }
	end
	local data = PlayerData.Get(player)
	if not data.Weapons[id] then
		return { ok = false, msg = "You don't own " .. def.Name .. " yet." }
	end
	local slots = WeaponService.Slots(player)
	local index = table.find(data.Equipped, id)
	if index then
		if #data.Equipped <= 1 then
			return { ok = false, msg = "Keep at least one weapon equipped." }
		end
		PlayerData.Update(player, function(d)
			table.remove(d.Equipped, index)
		end)
		return { ok = true, msg = def.Name .. " unequipped." }
	end
	PlayerData.Update(player, function(d)
		table.insert(d.Equipped, id)
		while #d.Equipped > slots do
			table.remove(d.Equipped, 1)
		end
	end)
	return { ok = true, msg = def.Name .. " equipped." }
end

local function buildTool(id)
	local def = Weapons.Get(id)
	local model = WeaponModel.Build(id)
	local tool = Instance.new("Tool")
	tool.Name = def.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = Weapons.Grip
	tool.ToolTip = Weapons.RarityOf(def).Name .. " · " .. def.Damage .. " damage"
	tool:SetAttribute("WeaponId", id)
	for _, child in ipairs(model:GetChildren()) do
		child.Parent = tool
	end
	model:Destroy()

	local handle = tool:FindFirstChild("Handle")
	local swing = Instance.new("Sound")
	swing.Name = "Swing"
	swing.SoundId = "rbxasset://sounds/swordslash.wav"
	swing.Volume = 0.6
	swing.Parent = handle
	local equipSound = Instance.new("Sound")
	equipSound.Name = "Unsheath"
	equipSound.SoundId = "rbxasset://sounds/unsheath.wav"
	equipSound.Volume = 0.5
	equipSound.Parent = handle

	local lastSwing = 0
	tool.Equipped:Connect(function()
		equipSound:Play()
	end)
	tool.Activated:Connect(function()
		local char = tool.Parent
		local player = char and game:GetService("Players"):GetPlayerFromCharacter(char)
		if not player then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then
			return
		end
		local t = os.clock()
		if t - lastSwing < def.Cooldown then
			return
		end
		lastSwing = t

		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		Debris:AddItem(anim, 1)
		swing:Play()
		local trail = handle:FindFirstChild("SwingTrail")
		if trail then
			trail.Enabled = true
			task.delay(0.3, function()
				trail.Enabled = false
			end)
		end

		task.delay(0.12, function()
			if tool.Parent ~= char or hum.Health <= 0 then
				return
			end
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local boxCF = root.CFrame * CFrame.new(0, 0, -def.Range / 2)
			local parts = workspace:GetPartBoundsInBox(boxCF, Vector3.new(6, 6, def.Range), params)
			local hit = {}
			for _, part in ipairs(parts) do
				local model = part:FindFirstAncestorOfClass("Model")
				local victim = model and model:FindFirstChildOfClass("Humanoid")
				if victim and not hit[victim] and victim.Health > 0 then
					hit[victim] = true
					Combat.Damage(player, victim, def.Damage)
				end
			end
		end)
	end)
	return tool
end

function WeaponService.Give(player)
	local data = PlayerData.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, id in ipairs(data.Equipped) do
		if Weapons.Get(id) and data.Weapons[id] then
			buildTool(id).Parent = backpack
		end
	end
end

return WeaponService
