-- AETHERVEIL · Elemental abilities (server-authoritative)
-- Fire / Water / Earth / Air / Lightning use the data-driven kit from Config/Elements.
-- Void uses the existing Portal Walker powers (PortalService), so it is skipped here.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Elements = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Elements)
local Combat = require(script.Parent.Combat)
local Purchases = require(script.Parent.Purchases)

local ElementAbilities = {}

local BOOST = 1.15
local MAX_AIM_DISTANCE = 600

local fxFolder = workspace:FindFirstChild("AetherveilFX")
if not fxFolder then
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "AetherveilFX"
	fxFolder.Parent = workspace
end

local cooldowns = {} -- [player] = { [abilityId] = readyAt }

local function now()
	return workspace:GetServerTimeNow()
end

local function getRoot(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hum and root and hum.Health > 0 then
		return root, char, hum
	end
	return nil
end

local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = fxFolder
	return p
end

local function burst(position, color, size, duration)
	local p = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1, Color = color, Transparency = 0.1, CFrame = CFrame.new(position) })
	TweenService:Create(p, TweenInfo.new(duration or 0.35, Enum.EasingStyle.Quint), { Size = Vector3.one * size, Transparency = 1 }):Play()
	Debris:AddItem(p, (duration or 0.35) + 0.05)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = size * 2
	light.Brightness = 3
	light.Parent = p
end

local function ring(position, color, radius, duration)
	local p = fxPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2, 2),
		Color = color,
		Transparency = 0.15,
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(p, TweenInfo.new(duration or 0.45, Enum.EasingStyle.Quint), { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(p, (duration or 0.45) + 0.05)
end

local function push(root, velocity, duration)
	local old = root:FindFirstChild("AetherPush")
	if old then
		old:Destroy()
	end
	local att = root:FindFirstChild("RootAttachment") or root:FindFirstChildOfClass("Attachment")
	if not att then
		att = Instance.new("Attachment")
		att.Parent = root
	end
	local lv = Instance.new("LinearVelocity")
	lv.Name = "AetherPush"
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = velocity
	lv.Parent = root
	Debris:AddItem(lv, duration)
end

local function damageFor(player, base)
	local mult = Purchases.Owns(player, "ElementBoost") and BOOST or 1
	return base * mult
end

local function splash(player, char, position, radius, amount, color, skip)
	if radius <= 0 then
		return
	end
	for _, target in ipairs(Combat.HumanoidsInRadius(position, radius, { char, fxFolder })) do
		if target.Humanoid ~= skip then
			Combat.Damage(player, target.Humanoid, amount)
		end
	end
	burst(position, color, radius * 1.6, 0.4)
end

local function humanoidFromPart(part)
	local model = part and part:FindFirstAncestorOfClass("Model")
	return model and model:FindFirstChildOfClass("Humanoid")
end

---------------------------------------------------------------- ability types
local function castBolt(player, def, ab, root, char, dir)
	local size = ab.Size or 1.8
	local orb = fxPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		Color = def.Color,
		Material = ab.Material and Enum.Material[ab.Material] or Enum.Material.Neon,
		CFrame = CFrame.new(root.Position + Vector3.new(0, 1.2, 0) + dir * 3),
	})
	local light = Instance.new("PointLight")
	light.Color = def.Color
	light.Range = 14
	light.Brightness = 2
	light.Parent = orb
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, size * 0.4, 0)
	a0.Parent = orb
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -size * 0.4, 0)
	a1.Parent = orb
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.25
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(def.Accent, def.Color)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = orb

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, fxFolder }

	local travelled = 0
	local damage = damageFor(player, ab.Damage)
	local conn
	local function finish(position, hitPart)
		if conn then
			conn:Disconnect()
			conn = nil
		end
		local direct = humanoidFromPart(hitPart)
		if direct and direct.Parent ~= char then
			Combat.Damage(player, direct, damage)
		end
		splash(player, char, position, ab.Splash or 0, damage * 0.6, def.Color, direct)
		orb.Transparency = 1
		light.Enabled = false
		Debris:AddItem(orb, 0.3)
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		if not orb.Parent then
			conn:Disconnect()
			return
		end
		local step = ab.Speed * dt
		local pos = orb.Position
		local result = workspace:Raycast(pos, dir * (step + size * 0.5), params)
		if result then
			finish(result.Position, result.Instance)
			return
		end
		orb.CFrame = CFrame.new(pos + dir * step)
		travelled += step
		if travelled >= ab.Range then
			finish(orb.Position, nil)
		end
	end)
end

local function castBeam(player, def, ab, root, char, dir)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, fxFolder }
	local origin = root.Position + Vector3.new(0, 1.2, 0)
	local result = workspace:Raycast(origin, dir * ab.Range, params)
	local finish = result and result.Position or origin + dir * ab.Range

	-- jagged bolt made of a few neon segments
	local points = { origin }
	local segments = 6
	for i = 1, segments - 1 do
		local p = origin:Lerp(finish, i / segments)
		table.insert(points, p + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 3)
	end
	table.insert(points, finish)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local len = (b - a).Magnitude
		local seg = fxPart({
			Size = Vector3.new(0.35, 0.35, len),
			Color = i % 2 == 0 and def.Accent or def.Color,
			CFrame = CFrame.lookAt(a:Lerp(b, 0.5), b),
		})
		TweenService:Create(seg, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.05, 0.05, len) }):Play()
		Debris:AddItem(seg, 0.3)
	end

	local damage = damageFor(player, ab.Damage)
	local direct = result and humanoidFromPart(result.Instance)
	if direct and direct.Parent ~= char then
		Combat.Damage(player, direct, damage)
	end
	splash(player, char, finish, ab.Splash or 0, damage * 0.6, def.Color, direct)
end

local function castNova(player, def, ab, root, char, hum)
	local center = root.Position
	ring(center - Vector3.new(0, 2.5, 0), def.Color, ab.Radius, 0.45)
	ring(center - Vector3.new(0, 2.2, 0), def.Accent, ab.Radius * 0.7, 0.35)
	burst(center, def.Color, 8, 0.3)
	local damage = damageFor(player, ab.Damage)
	for _, target in ipairs(Combat.HumanoidsInRadius(center, ab.Radius, { char, fxFolder })) do
		Combat.Damage(player, target.Humanoid, damage)
		if ab.Knockback and ab.Knockback > 0 then
			local away = target.Root.Position - center
			away = Vector3.new(away.X, 0, away.Z)
			away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, 1)
			push(target.Root, away * ab.Knockback + Vector3.new(0, ab.Knockback * 0.35, 0), 0.2)
		end
	end
	if ab.HealSelf then
		hum.Health = math.min(hum.MaxHealth, hum.Health + ab.HealSelf)
	end
end

local function castDash(player, def, ab, root, dir)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.1 then
		flat = root.CFrame.LookVector
	end
	flat = flat.Unit
	burst(root.Position, def.Color, 6, 0.3)
	push(root, flat * ab.Speed + Vector3.new(0, 4, 0), ab.Duration)
	task.delay(ab.Duration, function()
		if root.Parent then
			burst(root.Position, def.Accent, 5, 0.3)
		end
	end)
end

---------------------------------------------------------------- entry point
function ElementAbilities.Use(player, abilityId, aim)
	if player:GetAttribute("InGame") ~= true then
		return
	end
	local def = Elements.Get(player:GetAttribute("Element"))
	if not def or def.Kit then
		return
	end
	local ab = Elements.GetAbility(def, abilityId)
	if not ab or ab.Type == "Kit" then
		return
	end
	local root, char, hum = getRoot(player)
	if not root then
		return
	end

	cooldowns[player] = cooldowns[player] or {}
	local readyAt = cooldowns[player][ab.Id] or 0
	if now() < readyAt then
		return
	end

	-- validate the aim point sent by the client
	local dir = root.CFrame.LookVector
	if typeof(aim) == "Vector3" and aim.X == aim.X and aim.Y == aim.Y and aim.Z == aim.Z then
		local offset = aim - root.Position
		if offset.Magnitude > 0.5 and offset.Magnitude < MAX_AIM_DISTANCE then
			dir = offset.Unit
		end
	end

	cooldowns[player][ab.Id] = now() + ab.Cooldown
	player:SetAttribute("ECD_" .. ab.Id, now() + ab.Cooldown)

	if ab.Type == "Bolt" then
		castBolt(player, def, ab, root, char, dir)
	elseif ab.Type == "Beam" then
		castBeam(player, def, ab, root, char, dir)
	elseif ab.Type == "Nova" then
		castNova(player, def, ab, root, char, hum)
	elseif ab.Type == "Dash" then
		castDash(player, def, ab, root, dir)
	end
end

function ElementAbilities.Init()
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
end

return ElementAbilities
