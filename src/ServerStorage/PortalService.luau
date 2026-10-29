-- PORTAL WALKER (server)
-- Q Void Portal | E Teleport Portals | R Void Lance | F Singularity
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("PortalConfig"))
local Remotes = ReplicatedStorage:WaitForChild("PortalRemotes")
local PullEvent = Remotes:WaitForChild("Pull")
local NotifyEvent = Remotes:WaitForChild("Notify")
local FxEvent = Remotes:WaitForChild("Fx")

local Service = {}

local portalFolder = workspace:FindFirstChild("ActivePortals")
if not portalFolder then
	portalFolder = Instance.new("Folder")
	portalFolder.Name = "ActivePortals"
	portalFolder.Parent = workspace
end

local passCache = {}
local trapped = {} -- [player] = { returnCF, since, owner, visitor, ... }
local immuneUntil = {}
local cooldowns = {}
local portals = {}
local telePairs = {}
local teleLock = {}
local souls = {}
local statues = {} -- [player] = { statue models }

local BASE_SPEED = 16
local GREY = Color3.fromRGB(118, 118, 122)
local STONE = Color3.fromRGB(108, 104, 110)
local GROUND_SINK = 0.82

local function now()
	return workspace:GetServerTimeNow()
end

local function insidePortal(rec, pos)
	local l = rec.cf:PointToObjectSpace(pos)
	local r = Config.PORTAL_SIZE * 0.5 * 0.85
	return math.abs(l.Z) <= 2.2 and (l.X * l.X + l.Y * l.Y) <= r * r
end

local function notify(player, text)
	if player and player.Parent then
		NotifyEvent:FireClient(player, text)
	end
end

local function getRoot(player)
	local char = player.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart"), char
end

local function statueFolder()
	local parent = workspace:FindFirstChild("VoidDimension") or workspace
	local f = parent:FindFirstChild("Statues")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Statues"
		f.Parent = parent
	end
	return f
end

----------------------------------------------------------------- access (game pass / testers)
local function hasFreeAccess(player)
	if RunService:IsStudio() and Config.FREE_IN_STUDIO then
		return true
	end
	if Config.GAMEPASS_ID == 0 and Config.FREE_UNTIL_PASS_SET then
		return true -- no pass exists yet: everyone can test (Team Test, friends, etc.)
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(Config.TESTER_USER_IDS, player.UserId) ~= nil
end

-- AETHERVEIL: the powers are only active while playing with the Void element equipped
function Service.RefreshAccess(player)
	local active = passCache[player] == true
		and player:GetAttribute("Element") == "Void"
		and player:GetAttribute("InGame") == true
	player:SetAttribute("PortalWalker", active)
end

function Service.HasPass(player)
	if passCache[player] ~= nil then
		return passCache[player]
	end
	local owns = hasFreeAccess(player)
	if not owns and Config.GAMEPASS_ID ~= 0 then
		local ok, res = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GAMEPASS_ID)
		end)
		owns = ok and res == true
	end
	passCache[player] = owns
	Service.RefreshAccess(player)
	return owns
end

function Service.GrantPass(player)
	passCache[player] = true
	Service.RefreshAccess(player)
	notify(player, "You are now a PORTAL WALKER!  Q Void Portal  |  E Teleport  |  R Void Lance  |  F Singularity")
end

----------------------------------------------------------------- cooldowns
local function cooldownLeft(player, key)
	local t = cooldowns[player] and cooldowns[player][key]
	if t and t > now() then
		return t - now()
	end
	return 0
end

local function setCooldown(player, key, secs)
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][key] = now() + secs
	player:SetAttribute("CD_" .. key, now() + secs)
end

----------------------------------------------------------------- souls & speed
local function greyFactor(player)
	local data = trapped[player]
	if not data then
		return 0
	end
	local span = math.max(1, Config.GREY_FULL - Config.GREY_START)
	return math.clamp((now() - data.since - Config.GREY_START) / span, 0, 1)
end

local function powerMult(player)
	return 1 + Config.SOUL_DAMAGE * (souls[player] or 0)
end

local function updateSpeed(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local data = trapped[player]
	if data and data.petrifying then
		return
	end
	local n = souls[player] or 0
	hum.WalkSpeed = BASE_SPEED * (1 + Config.SOUL_SPEED * n) * (1 - Config.GREY_SLOW * greyFactor(player))
end

local function setSouls(player, n)
	n = math.clamp(n, 0, Config.SOUL_MAX)
	souls[player] = n
	player:SetAttribute("VoidSouls", n)
	player:SetAttribute("DamageMultiplier", 1 + Config.SOUL_DAMAGE * n)
	updateSpeed(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local aura = root:FindFirstChild("SoulAura")
		if n > 0 and not aura then
			aura = Instance.new("ParticleEmitter")
			aura.Name = "SoulAura"
			aura.Texture = "rbxasset://textures/particles/smoke_main.dds"
			aura.Color = ColorSequence.new(Color3.fromRGB(120, 40, 200), Color3.fromRGB(15, 5, 25))
			aura.LightEmission = 0.4
			aura.LightInfluence = 0
			aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3) })
			aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) })
			aura.Lifetime = NumberRange.new(0.8, 1.4)
			aura.Speed = NumberRange.new(1, 3)
			aura.SpreadAngle = Vector2.new(180, 180)
			aura.Acceleration = Vector3.new(0, 4, 0)
			aura.Rotation = NumberRange.new(0, 360)
			aura.Parent = root
		end
		if aura then
			aura.Rate = n * 4
			aura.Enabled = n > 0
		end
	end
end

----------------------------------------------------------------- greying
local function applyGrey(player, f)
	local data = trapped[player]
	local char = player.Character
	if not data or not char then
		return
	end
	if data.origChar ~= char then
		data.origChar = char
		data.orig = {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				data.orig[d] = d.Color
			elseif d:IsA("Clothing") or d:IsA("Decal") then
				data.orig[d] = d.Color3
			end
		end
	end
	for inst, c in pairs(data.orig) do
		if inst.Parent then
			if inst:IsA("BasePart") then
				inst.Color = c:Lerp(GREY, f)
			else
				inst.Color3 = c:Lerp(GREY, f)
			end
		end
	end
	local h = char:FindFirstChild("VoidGrey")
	if f > 0 then
		if not h then
			h = Instance.new("Highlight")
			h.Name = "VoidGrey"
			h.FillColor = GREY
			h.OutlineTransparency = 1
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Parent = char
		end
		h.FillTransparency = math.min(h.FillTransparency, 1 - 0.8 * f)
	end
	updateSpeed(player)
end

----------------------------------------------------------------- portals
local function spawnPortal(kind, cf, owner, lifetime, extra)
	local model = Instance.new("Part")
	model.Name = kind .. "Portal"
	model.Anchored = true
	model.CanCollide = false
	model.CanQuery = false
	model.CanTouch = false
	model.Transparency = 1
	model.Size = Vector3.one
	model.CFrame = cf
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Size", Config.PORTAL_SIZE)
	if extra and extra.label then
		model:SetAttribute("Label", extra.label)
	end
	model.Parent = portalFolder
	local rec = {
		kind = kind,
		model = model,
		center = cf.Position,
		cf = cf,
		owner = owner,
		born = now(),
		expires = lifetime and (now() + lifetime) or math.huge,
		alive = true,
	}
	if extra then
		for k, v in pairs(extra) do
			rec[k] = v
		end
	end
	table.insert(portals, rec)
	return rec
end

local function closePortal(rec)
	if not rec or not rec.alive then
		return
	end
	rec.alive = false
	rec.model:SetAttribute("CloseAt", now())
	Debris:AddItem(rec.model, 1.5)
end

local function groundParams(extraIgnore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { portalFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	if extraIgnore then
		table.insert(ignore, extraIgnore)
	end
	params.FilterDescendantsInstances = ignore
	return params
end

-- where a portal goes: on the ground at the aim point, facing the caster
local function placementCF(root, target, allowVoid)
	if typeof(target) ~= "Vector3" or target.X ~= target.X or target.Y ~= target.Y or target.Z ~= target.Z then
		return nil
	end
	local origin = root.Position
	local offset = target - origin
	if offset.Magnitude < 1 then
		target = origin + root.CFrame.LookVector * 12
		offset = target - origin
	end
	if offset.Magnitude > Config.MAX_RANGE then
		target = origin + offset.Unit * Config.MAX_RANGE
	end
	if not allowVoid and (target - Config.VOID_CENTER).Magnitude < 700 then
		return nil
	end
	local hit = workspace:Raycast(target + Vector3.new(0, 15, 0), Vector3.new(0, -300, 0), groundParams())
	local groundY = hit and hit.Position.Y or (origin.Y - 3)
	local center = Vector3.new(target.X, groundY + Config.PORTAL_SIZE * 0.5 * GROUND_SINK, target.Z)
	local face = Vector3.new(origin.X, center.Y, origin.Z)
	if (face - center).Magnitude < 0.5 then
		face = center + Vector3.new(0, 0, 1)
	end
	return CFrame.lookAt(center, face)
end

local function voidSpawnCF()
	local vd = workspace:FindFirstChild("VoidDimension")
	local folder = vd and vd:FindFirstChild("SpawnPoints")
	if folder then
		local list = folder:GetChildren()
		if #list > 0 then
			return CFrame.new(list[math.random(#list)].Position + Vector3.new(0, 4, 0))
		end
	end
	return CFrame.new(Config.VOID_CENTER + Vector3.new(0, 6, 0))
end

local function randomVoidPortalCF()
	local vd = workspace:FindFirstChild("VoidDimension")
	local spots = vd and vd:FindFirstChild("ExitSpots")
	if spots then
		local list = spots:GetChildren()
		if #list > 0 then
			local s = list[math.random(#list)]
			local center = s.Position + Vector3.new(0, Config.PORTAL_SIZE * 0.5 * GROUND_SINK, 0)
			return CFrame.lookAt(center, center + s.CFrame.LookVector)
		end
	end
	local ang = math.random() * math.pi * 2
	local pos = Config.VOID_CENTER + Vector3.new(math.cos(ang) * 60, Config.PORTAL_SIZE * 0.5 * GROUND_SINK, math.sin(ang) * 60)
	return CFrame.lookAt(pos, Vector3.new(Config.VOID_CENTER.X, pos.Y, Config.VOID_CENTER.Z))
end

----------------------------------------------------------------- trap / free
function Service.IsTrapped(player)
	return trapped[player] ~= nil
end

function Service.Trap(player, owner, portalCenter, visitor)
	if trapped[player] then
		return
	end
	local root, char = getRoot(player)
	if not root then
		return
	end
	local back = portalCenter and Vector3.new(portalCenter.X, root.Position.Y, portalCenter.Z) or root.Position
	trapped[player] = { returnCF = CFrame.new(back), since = now(), owner = owner, visitor = visitor }
	player:SetAttribute("InVoid", true)
	player:SetAttribute("VoidVisitor", visitor == true)
	FxEvent:FireAllClients("swallow", root.Position)
	local dest = voidSpawnCF()
	char:PivotTo(dest)
	FxEvent:FireAllClients("blink", dest.Position)
	if visitor then
		notify(player, "You stepped into the Void. Throw a Void Portal (Q) here to tear a way back out.")
	else
		notify(player, "You were dragged into the VOID...")
		if owner and owner ~= player and owner.Parent then
			setSouls(owner, (souls[owner] or 0) + 1)
			notify(owner, player.DisplayName .. " was banished! +1 Void Soul (" .. souls[owner] .. "/" .. Config.SOUL_MAX .. ")")
		end
	end
end

function Service.Free(player)
	local data = trapped[player]
	if not data or data.petrifying then
		return
	end
	trapped[player] = nil -- note: grey skin is kept on purpose; it fades only when they respawn
	player:SetAttribute("InVoid", false)
	player:SetAttribute("VoidVisitor", false)
	updateSpeed(player)
	immuneUntil[player] = now() + Config.ESCAPE_IMMUNITY
	local _, char = getRoot(player)
	if char then
		local dest = data.returnCF + Vector3.new(0, 3, 0)
		char:PivotTo(dest)
		FxEvent:FireAllClients("blink", dest.Position)
	end
	if data.wasGrey then
		notify(player, "You escaped... but the Void left its mark on you.")
	else
		notify(player, "You escaped the Void!")
	end
end

----------------------------------------------------------------- petrification
local function stoneify(part)
	part.Material = Enum.Material.Slate
	part.Color = STONE:Lerp(Color3.fromRGB(78, 75, 82), math.random() * 0.45)
	if part:IsA("MeshPart") then
		part.TextureID = ""
	end
	local sm = part:FindFirstChildOfClass("SpecialMesh")
	if sm then
		sm.TextureId = ""
	end
end

-- R15: down on one knee, head thrown back, one arm reaching for the sky, the other shielding the face
local POSE_R15 = {
	Waist = CFrame.Angles(math.rad(14), math.rad(14), 0),
	Neck = CFrame.Angles(math.rad(35), math.rad(-12), 0),
	RightShoulder = CFrame.Angles(math.rad(155), 0, math.rad(-12)),
	RightElbow = CFrame.Angles(math.rad(18), 0, 0),
	RightWrist = CFrame.Angles(math.rad(-25), 0, 0),
	LeftShoulder = CFrame.Angles(math.rad(80), 0, math.rad(38)),
	LeftElbow = CFrame.Angles(math.rad(75), 0, 0),
	RightHip = CFrame.Angles(math.rad(-8), 0, 0),
	RightKnee = CFrame.Angles(math.rad(-95), 0, 0),
	RightAnkle = CFrame.Angles(math.rad(-30), 0, 0),
	LeftHip = CFrame.Angles(math.rad(85), 0, 0),
	LeftKnee = CFrame.Angles(math.rad(-88), 0, 0),
}
-- R6: arms flung up in terror
local POSE_R6 = {
	["Right Shoulder"] = CFrame.Angles(0, 0, math.rad(150)),
	["Left Shoulder"] = CFrame.Angles(0, 0, math.rad(-80)),
	Neck = CFrame.Angles(math.rad(-30), 0, 0),
}

-- Places every limb directly (no physics needed), so the statue is frozen exactly in the pose.
local function poseStatue(statue)
	local hrp = statue:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local r15 = statue:FindFirstChild("UpperTorso") ~= nil
	local POSE = r15 and POSE_R15 or POSE_R6
	for _, d in ipairs(statue:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	if r15 then
		hrp.CFrame = hrp.CFrame - Vector3.new(0, 1.15, 0)
	end
	-- collect joints: classic Motor6D/Welds, or the newer AnimationConstraints avatars use
	local joints = {}
	for _, d in ipairs(statue:GetDescendants()) do
		if d:IsA("JointInstance") and d.Part0 and d.Part1 then
			table.insert(joints, { p0 = d.Part0, p1 = d.Part1, c0 = d.C0, c1 = d.C1, rot = (d:IsA("Motor6D") and POSE[d.Name]) or CFrame.new() })
		elseif d:IsA("WeldConstraint") and d.Part0 and d.Part1 then
			-- keep whatever offset it has right now
			table.insert(joints, { p0 = d.Part0, p1 = d.Part1, c0 = d.Part0.CFrame:Inverse() * d.Part1.CFrame, c1 = CFrame.new(), rot = CFrame.new() })
		elseif (d:IsA("AnimationConstraint") or d:IsA("RigidConstraint")) and d.Attachment0 and d.Attachment1 then
			local a0, a1 = d.Attachment0, d.Attachment1
			if a0.Parent:IsA("BasePart") and a1.Parent:IsA("BasePart") then
				table.insert(joints, { p0 = a0.Parent, p1 = a1.Parent, c0 = a0.CFrame, c1 = a1.CFrame, rot = POSE[d.Name] or CFrame.new() })
			end
		end
	end
	local known = { [hrp] = true }
	local progress = true
	while progress do
		progress = false
		for _, j in ipairs(joints) do
			if known[j.p0] and not known[j.p1] then
				j.p1.CFrame = j.p0.CFrame * j.c0 * j.rot * j.c1:Inverse()
				known[j.p1] = true
				progress = true
			elseif known[j.p1] and not known[j.p0] then
				j.p0.CFrame = j.p1.CFrame * j.c1 * j.rot:Inverse() * j.c0:Inverse()
				known[j.p0] = true
				progress = true
			end
		end
	end
end

function Service.Petrify(player)
	local data = trapped[player]
	if not data or data.petrifying then
		return
	end
	local root, char = getRoot(player)
	if not root then
		return
	end
	data.petrifying = true
	local hum = char:FindFirstChildOfClass("Humanoid")
	notify(player, "Time has caught up with you...")
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0
	hum.AutoRotate = false
	root.Anchored = true
	FxEvent:FireAllClients("petrify", root.Position)

	-- stone creeps up from the feet
	local parts = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			table.insert(parts, d)
		end
	end
	table.sort(parts, function(a, b)
		return a.Position.Y < b.Position.Y
	end)
	local step = 2.6 / math.max(1, #parts)
	for _, p in ipairs(parts) do
		if p.Parent then
			stoneify(p)
		end
		task.wait(step)
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("Decal") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	task.wait(0.5)

	-- the statue left behind
	local statue
	if char.Parent then
		char.Archivable = true
		statue = char:Clone()
	end
	if statue then
		-- strike the pose first (it reads the joints), then strip everything that isn't stone
		poseStatue(statue)
		for _, d in ipairs(statue:GetDescendants()) do
			if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Highlight") or d:IsA("BillboardGui")
				or d:IsA("ForceField") or d:IsA("Constraint") or d:IsA("Clothing") or d:IsA("Decal") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				stoneify(d)
				d.Anchored = true
				d.CanCollide = d.Name ~= "HumanoidRootPart"
				d.CanTouch = false
			end
		end
		local sh = statue:FindFirstChildOfClass("Humanoid")
		if sh then
			sh:Destroy()
		end
		statue.Name = player.Name .. "'s Statue"
		statue:SetAttribute("StatueOf", player.UserId)
		local shrp = statue:FindFirstChild("HumanoidRootPart")
		if shrp then
			shrp.Anchored = true
			shrp.Transparency = 1
		end
		statue.Parent = statueFolder()
		statues[player] = statues[player] or {}
		table.insert(statues[player], statue)
	end
	FxEvent:FireAllClients("petrifyDone", root.Position)
	for _, p in ipairs(Players:GetPlayers()) do
		notify(p, player.DisplayName .. " was lost to time in the Void. Only stone remains.")
	end

	-- the player wakes up back in the world
	trapped[player] = nil
	player:SetAttribute("InVoid", false)
	player:SetAttribute("VoidVisitor", false)
	if char.Parent then
		char:Destroy()
	end
	player:LoadCharacter()
end

----------------------------------------------------------------- combat helpers
local function humanoidsNear(pos, radius, excludeChar)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = { portalFolder, excludeChar }
	local found, out = {}, {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, radius, op)) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not found[model] then
			found[model] = true
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				table.insert(out, { hum = hum, root = root, model = model })
			end
		end
	end
	return out
end

local function dealDamage(attacker, hum, amount)
	local tag = hum:FindFirstChild("creator")
	if not tag then
		tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Parent = hum
	end
	tag.Value = attacker
	Debris:AddItem(tag, 5)
	hum:TakeDamage(amount)
end

local function push(root, velocity, duration)
	local old = root:FindFirstChild("VoidPush")
	if old then
		old:Destroy()
	end
	local att = root:FindFirstChild("RootAttachment") or root:FindFirstChildOfClass("Attachment")
	if not att then
		att = Instance.new("Attachment")
		att.Parent = root
	end
	local lv = Instance.new("LinearVelocity")
	lv.Name = "VoidPush"
	lv.Attachment0 = att
	lv.MaxForce = 1e6
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = velocity
	lv.Parent = root
	Debris:AddItem(lv, duration)
end

----------------------------------------------------------------- abilities
local function canUse(player)
	if not Service.HasPass(player) or player:GetAttribute("PortalWalker") ~= true then
		return false
	end
	local data = trapped[player]
	if data and (not data.visitor or data.petrifying) then
		notify(player, "Your powers don't work while you're trapped in the Void!")
		return false
	end
	return getRoot(player) ~= nil
end

-- Q: Void Portal
function Service.ThrowVoid(player, target)
	if not canUse(player) or cooldownLeft(player, "Void") > 0 then
		return
	end
	local root = getRoot(player)
	local inVoid = trapped[player] ~= nil
	local cf = placementCF(root, target, inVoid)
	if not cf then
		return
	end
	setCooldown(player, "Void", Config.VOID_PORTAL_COOLDOWN * (1 - Config.SOUL_COOLDOWN * (souls[player] or 0)))
	FxEvent:FireAllClients("orb", root.Position, cf.Position, Config.THROW_TIME)
	if inVoid then
		-- inside the Void this portal tears a way back to the world (anyone can slip through it)
		task.delay(Config.THROW_TIME, function()
			spawnPortal("escape", cf, player, Config.ESCAPE_PORTAL_LIFETIME, { openAt = now() + 0.6 })
			for p in pairs(trapped) do
				if p ~= player then
					notify(p, "Somewhere in the realm, a portal has been torn open...")
				end
			end
		end)
		return
	end
	task.delay(Config.THROW_TIME, function()
		local openAt = now() + 0.25
		spawnPortal("void", cf, player, Config.VOID_PORTAL_LIFETIME + 0.25, {
			openAt = openAt,
			pullUntil = openAt + Config.PULL_DURATION,
			pulled = {},
		})
	end)
end

-- natural / safety-net exits
function Service.OpenNaturalExit()
	spawnPortal("escape", randomVoidPortalCF(), nil, Config.ESCAPE_PORTAL_LIFETIME, { openAt = now() + 0.6, label = "RARE EXIT" })
	for p in pairs(trapped) do
		notify(p, "A rare portal flickered open on its own! RUN to it!")
	end
end

-- E: Teleport portals
function Service.PlaceTeleport(player, target)
	if not canUse(player) then
		return
	end
	local root = getRoot(player)
	local pair = telePairs[player]
	if pair and (not pair.a.alive or (pair.b and not pair.b.alive)) then
		closePortal(pair.a)
		closePortal(pair.b)
		telePairs[player] = nil
		pair = nil
	end
	if pair and pair.b then
		if cooldownLeft(player, "Teleport") > 0 then
			return
		end
		closePortal(pair.a)
		closePortal(pair.b)
		telePairs[player] = nil
		pair = nil
	end
	local cf = placementCF(root, target, trapped[player] ~= nil)
	if not cf then
		return
	end
	if not pair then
		if cooldownLeft(player, "Teleport") > 0 then
			return
		end
		local rec = spawnPortal("tele", cf, player, Config.TELEPORT_PENDING_TIME, { openAt = now() + 0.6 })
		telePairs[player] = { a = rec }
		FxEvent:FireAllClients("sound", "Teleport", root.Position)
		notify(player, "Portal placed. Press E again to place its exit!")
	else
		if (cf.Position - pair.a.center).Magnitude < Config.PORTAL_SIZE * 1.5 then
			notify(player, "Too close to your other portal.")
			return
		end
		local rec = spawnPortal("tele", cf, player, Config.TELEPORT_PAIR_LIFETIME, { openAt = now() + 0.6 })
		pair.b = rec
		rec.partner = pair.a
		pair.a.partner = rec
		setCooldown(player, "Teleport", Config.TELEPORT_COOLDOWN)
		FxEvent:FireAllClients("sound", "Teleport", root.Position)
	end
end

-- R: Void Lance - a piercing beam of void energy
function Service.Lance(player, target)
	if not canUse(player) or cooldownLeft(player, "Lance") > 0 or typeof(target) ~= "Vector3" then
		return
	end
	local root, char = getRoot(player)
	setCooldown(player, "Lance", Config.LANCE_COOLDOWN)
	local origin = root.Position + Vector3.new(0, 1.2, 0) + root.CFrame.LookVector * 1.5
	local dir = target - origin
	if dir.Magnitude < 1 then
		dir = root.CFrame.LookVector
	end
	dir = dir.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, portalFolder }
	local hit = workspace:Spherecast(origin, 1.8, dir * Config.LANCE_RANGE, params)
	local endPos = hit and hit.Position or (origin + dir * Config.LANCE_RANGE)
	local victim
	if hit then
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			victim = hum
		end
	end
	FxEvent:FireAllClients("lance", origin, endPos, victim ~= nil)
	if victim then
		dealDamage(player, victim, Config.LANCE_DAMAGE * powerMult(player))
		local vroot = victim.Parent:FindFirstChild("HumanoidRootPart")
		if vroot then
			push(vroot, dir * 65 + Vector3.new(0, 28, 0), 0.18)
		end
	end
end

-- F: Singularity - a mini black hole that drags enemies in, then implodes
function Service.Singularity(player, target)
	if not canUse(player) or cooldownLeft(player, "Singularity") > 0 or typeof(target) ~= "Vector3" then
		return
	end
	local root, char = getRoot(player)
	local offset = target - root.Position
	if offset.Magnitude > Config.SINGULARITY_RANGE then
		target = root.Position + offset.Unit * Config.SINGULARITY_RANGE
	end
	local hit = workspace:Raycast(target + Vector3.new(0, 10, 0), Vector3.new(0, -200, 0), groundParams())
	local center = (hit and hit.Position or target) + Vector3.new(0, 5, 0)
	setCooldown(player, "Singularity", Config.SINGULARITY_COOLDOWN)
	FxEvent:FireAllClients("singularity", center, Config.SINGULARITY_DURATION, Config.SINGULARITY_RADIUS)
	local mult = powerMult(player)
	task.spawn(function()
		local endT = os.clock() + Config.SINGULARITY_DURATION
		while os.clock() < endT do
			for _, h in ipairs(humanoidsNear(center, Config.SINGULARITY_RADIUS, char)) do
				local to = center - h.root.Position
				if to.Magnitude > 1.5 then
					push(h.root, to.Unit * math.clamp(to.Magnitude * 3, 12, 48), 0.15)
				end
				dealDamage(player, h.hum, Config.SINGULARITY_TICK * mult)
			end
			task.wait(0.1)
		end
		for _, h in ipairs(humanoidsNear(center, Config.SINGULARITY_RADIUS + 4, char)) do
			local away = h.root.Position - center
			away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 1, 0)
			push(h.root, away * 75 + Vector3.new(0, 45, 0), 0.22)
			dealDamage(player, h.hum, Config.SINGULARITY_BURST * mult)
		end
	end)
end

----------------------------------------------------------------- main loop
local function tick()
	local t = now()
	local roots = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local root = getRoot(p)
		if root then
			roots[p] = root
		end
	end

	for i = #portals, 1, -1 do
		local rec = portals[i]
		if not rec.alive then
			table.remove(portals, i)
		elseif t >= rec.expires then
			closePortal(rec)
			table.remove(portals, i)
		elseif t >= (rec.openAt or rec.born) then
			if rec.kind == "void" then
				local pullRange = Config.PULL_RADIUS * (1 + Config.SOUL_PULL * (souls[rec.owner] or 0))
				for p, root in pairs(roots) do
					if p == rec.owner then
						if not trapped[p] and t >= rec.pullUntil and insidePortal(rec, root.Position) then
							Service.Trap(p, p, rec.center, true)
						end
					elseif not trapped[p] and (immuneUntil[p] or 0) <= t then
						local d = (root.Position - rec.center).Magnitude
						if insidePortal(rec, root.Position) then
							Service.Trap(p, rec.owner, rec.center)
						elseif t < rec.pullUntil and d <= pullRange and not rec.pulled[p] then
							rec.pulled[p] = true
							PullEvent:FireClient(p, rec.center, rec.pullUntil - t)
						end
					end
				end
			elseif rec.kind == "escape" then
				for p, root in pairs(roots) do
					if trapped[p] and insidePortal(rec, root.Position) then
						Service.Free(p)
					end
				end
			elseif rec.kind == "tele" and rec.partner and rec.partner.alive then
				for p, root in pairs(roots) do
					if (teleLock[p] or 0) <= t and insidePortal(rec, root.Position) then
						teleLock[p] = t + 1.5
						local out = rec.partner.cf * CFrame.new(0, -(Config.PORTAL_SIZE * 0.5 * GROUND_SINK) + 3, -5)
						FxEvent:FireAllClients("blink", root.Position)
						p.Character:PivotTo(CFrame.lookAt(out.Position, out.Position + rec.partner.cf.LookVector))
						FxEvent:FireAllClients("blink", out.Position)
					end
				end
			end
		end
	end

	for p, data in pairs(trapped) do
		if not p.Parent then
			trapped[p] = nil
		elseif not data.petrifying then
			local root = roots[p]
			if root and root.Position.Y < Config.VOID_CENTER.Y - 80 then
				p.Character:PivotTo(voidSpawnCF())
			end
			if Config.SAFETY_MAX_TRAP_TIME > 0 and not data.safetyOpened and t - data.since > Config.SAFETY_MAX_TRAP_TIME then
				data.safetyOpened = true
				Service.OpenNaturalExit()
			end
		end
	end
end

function Service.Init()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.05 then
			return
		end
		acc = 0
		local ok, err = pcall(tick)
		if not ok then
			warn("[Portals] " .. tostring(err))
		end
	end)

	-- time flows differently in the Void
	task.spawn(function()
		while true do
			task.wait(0.5)
			local t = now()
			for p, data in pairs(trapped) do
				if p.Parent and not data.petrifying then
					local inside = t - data.since
					local f = greyFactor(p)
					if f > 0 then
						if not data.wasGrey then
							data.wasGrey = true
							notify(p, "Your body feels heavy... time here is wearing you away.")
						end
						local ok, err = pcall(applyGrey, p, f)
						if not ok then
							warn("[Portals] grey: " .. tostring(err))
						end
					end
					if inside >= Config.PETRIFY_AT - 60 and not data.stoneWarned then
						data.stoneWarned = true
						notify(p, "Your skin is hardening into stone... get out while you still can!")
					end
					if inside >= Config.PETRIFY_AT then
						task.spawn(function()
							local ok, err = pcall(Service.Petrify, p)
							if not ok then
								warn("[Portals] petrify: " .. tostring(err))
							end
						end)
					end
				end
			end
		end
	end)

	-- rare portals that open on their own
	task.spawn(function()
		while true do
			task.wait(Config.RANDOM_ESCAPE_CHECK)
			local anyone = false
			for _, data in pairs(trapped) do
				if not data.visitor then
					anyone = true
				end
			end
			if anyone and math.random() < Config.RANDOM_ESCAPE_CHANCE then
				Service.OpenNaturalExit()
			end
		end
	end)

	local function onCharacter(player, char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				if (souls[player] or 0) > 0 then
					souls[player] = 0
					player:SetAttribute("VoidSouls", 0)
					player:SetAttribute("DamageMultiplier", 1)
				end
			end)
		end
		task.defer(updateSpeed, player)
		local data = trapped[player]
		if data and not data.petrifying then
			local root = char:WaitForChild("HumanoidRootPart", 5)
			if root then
				task.wait(0.1)
				char:PivotTo(voidSpawnCF())
			end
		end
	end

	local function onPlayer(player)
		task.spawn(Service.HasPass, player)
		player:SetAttribute("InVoid", false)
		player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end

	Players.PlayerRemoving:Connect(function(player)
		local stranded = false
		for _, data in pairs(trapped) do
			if data.owner == player and not data.visitor then
				stranded = true
			end
		end
		local pair = telePairs[player]
		if pair then
			closePortal(pair.a)
			closePortal(pair.b)
		end
		-- their stone statues crumble away when they leave
		if statues[player] then
			for _, s in ipairs(statues[player]) do
				if s.Parent then
					local pivot = s:GetPivot()
					FxEvent:FireAllClients("petrifyDone", pivot.Position)
					s:Destroy()
				end
			end
		end
		statues[player] = nil
		trapped[player] = nil
		telePairs[player] = nil
		souls[player] = nil
		passCache[player] = nil
		cooldowns[player] = nil
		immuneUntil[player] = nil
		teleLock[player] = nil
		if stranded then
			Service.OpenNaturalExit()
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == Config.GAMEPASS_ID then
			Service.GrantPass(player)
		end
	end)
end

-- Studio testing helpers
function Service.DebugAge(player, secs)
	local data = trapped[player]
	if data then
		data.since -= secs
	end
end

function Service.DebugSouls(player, n)
	setSouls(player, n)
end

return Service
