-- PORTAL VISUALS (smoke portals). Drawn on each player's screen so it's smooth and cheap.
-- Built from a handful of particle emitters instead of hundreds of parts, so it doesn't lag.
-- Opening: a rift tears -> flash + smoke puff -> a swirling smoke ring spins open from the ground.
-- Idle: churning smoke vortex, glowing blue haze inside, electric crackles, drifting sparks, ground dust.
-- Closing: it tightens, spins faster, collapses inward, then puffs out into smoke that fades into thin air.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("PortalRemotes")
local Fx = Remotes:WaitForChild("Fx")
local Config = require(ReplicatedStorage:WaitForChild("PortalConfig"))
local SOUNDS = Config.SOUNDS or {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local COL = {
	smokeA = Color3.fromRGB(88, 40, 140),
	smokeB = Color3.fromRGB(16, 6, 26),
	energy = Color3.fromRGB(165, 70, 255),
	energy2 = Color3.fromRGB(90, 20, 190),
	core = Color3.fromRGB(140, 55, 255),
	spark = Color3.fromRGB(220, 175, 255),
	void = Color3.fromRGB(0, 0, 0),
}

local RING_POINTS = 14
local BOLTS = 4
local GROUND_SINK = 0.82 -- center height as a fraction of the radius (bottom sinks into the floor)

local visFolder = Instance.new("Folder")
visFolder.Name = "PortalVisuals"
visFolder.Parent = workspace

local function kp(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = visFolder
	return p
end

-- 3D sound at a position (cleans itself up)
local function playAt(name, pos, volume, pitch, range)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	p.Parent = visFolder
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.8
	s.PlaybackSpeed = (pitch or 1) * (0.94 + math.random() * 0.12)
	s.RollOffMaxDistance = range or 220
	s.RollOffMinDistance = 12
	s.Parent = p
	s:Play()
	Debris:AddItem(p, 9)
	return s
end

local function tween(inst, t, props, style)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function makeEmitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = parent
	return e
end

local function smokeProps(r)
	return {
		Texture = SMOKE,
		Color = ColorSequence.new(COL.smokeA, COL.smokeB),
		LightEmission = 0,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, r * 0.38), kp(1, r * 0.72) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.15, 0.22), kp(0.7, 0.5), kp(1, 1) }),
		Lifetime = NumberRange.new(1.1, 1.7),
		Speed = NumberRange.new(r * 0.35, r * 0.6),
		SpreadAngle = Vector2.new(25, 25),
		Drag = 1.2,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-50, 50),
		EmissionDirection = Enum.NormalId.Top,
		Rate = 0,
	}
end

---------------------------------------------------------------- one-shot effects
local function flash(pos, size, color, t)
	t = t or 0.3
	local b = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.4, Material = Enum.Material.Neon, Color = color or COL.spark, CFrame = CFrame.new(pos) })
	tween(b, t, { Size = Vector3.one * size, Transparency = 1 }, Enum.EasingStyle.Quart)
	Debris:AddItem(b, t + 0.1)
end

local function groundRing(pos, size, t)
	t = t or 0.6
	local d = fxPart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 2, 2), Material = Enum.Material.Neon, Color = COL.energy, Transparency = 0.3, CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2) })
	tween(d, t, { Size = Vector3.new(0.12, size, size), Transparency = 1 }, Enum.EasingStyle.Quart)
	Debris:AddItem(d, t + 0.1)
end

local function oneShot(pos, props, count, life)
	local p = fxPart({ Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(pos) })
	props.Enabled = false
	local e = makeEmitter(p, props)
	e:Emit(count)
	Debris:AddItem(p, life + 0.3)
end

local function sparks(pos, count, speed)
	oneShot(pos, {
		Texture = SPARK,
		Speed = NumberRange.new(speed * 0.4, speed),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.3, 0.7),
		Drag = 4,
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 0.5), kp(1, 0) }),
		Color = ColorSequence.new(COL.spark, COL.energy),
		Transparency = NumberSequence.new(0, 1),
		Acceleration = Vector3.new(0, -12, 0),
	}, count, 0.7)
end

local function puff(pos, count, size)
	oneShot(pos, {
		Texture = SMOKE,
		Speed = NumberRange.new(size * 0.6, size * 1.4),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(1, 1.8),
		Drag = 2.5,
		Acceleration = Vector3.new(0, 1.5, 0),
		LightEmission = 0,
		LightInfluence = 0.25,
		Size = NumberSequence.new({ kp(0, size * 0.35), kp(1, size * 0.9) }),
		Color = ColorSequence.new(COL.smokeA, COL.smokeB),
		Transparency = NumberSequence.new({ kp(0, 0.35), kp(0.6, 0.6), kp(1, 1) }),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40),
	}, count, 1.8)
end

local function lightFlare(pos, brightness, range, t)
	local p = fxPart({ Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(pos) })
	local l = Instance.new("PointLight")
	l.Color = COL.core
	l.Brightness = brightness
	l.Range = range
	l.Parent = p
	tween(l, t, { Brightness = 0 })
	Debris:AddItem(p, t + 0.1)
end

local function easeOutBack(x)
	local c1 = 1.6
	local c3 = c1 + 1
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

---------------------------------------------------------------- portals
local active = {}

local function addLabel(parent, text, R)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(170, 42)
	gui.StudsOffsetWorldSpace = Vector3.new(0, R * 1.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 400
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COL.spark
	label.TextStrokeColor3 = Color3.fromRGB(10, 30, 80)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = parent
end

local function startPortal(marker)
	if active[marker] or not marker:IsA("BasePart") then
		return
	end
	local closeAt = marker:GetAttribute("CloseAt")
	if closeAt and workspace:GetServerTimeNow() >= closeAt then
		return
	end
	local size = marker:GetAttribute("Size") or 13
	local R = size * 0.5
	local cf = marker.CFrame

	local root = fxPart({ Name = "PortalRoot", Size = Vector3.one, Transparency = 1, CFrame = cf })

	-- swirling smoke ring + inner energy layer
	local ring = {}
	for i = 1, RING_POINTS do
		local att = Instance.new("Attachment")
		att.Parent = root
		local smoke = makeEmitter(att, smokeProps(R))
		local energy
		if i % 2 == 0 then
			energy = makeEmitter(att, {
				Texture = SMOKE,
				Color = ColorSequence.new(COL.energy, COL.energy2),
				LightEmission = 1,
				LightInfluence = 0,
				Size = NumberSequence.new({ kp(0, R * 0.22), kp(1, R * 0.08) }),
				Transparency = NumberSequence.new({ kp(0, 1), kp(0.2, 0.68), kp(1, 1) }),
				Lifetime = NumberRange.new(0.5, 0.8),
				Speed = NumberRange.new(R * 0.5, R * 0.8),
				SpreadAngle = Vector2.new(15, 15),
				Rotation = NumberRange.new(0, 360),
				EmissionDirection = Enum.NormalId.Top,
				ZOffset = -0.5,
				Rate = 0,
			})
		end
		ring[i] = { att = att, smoke = smoke, energy = energy, base = (i - 1) / RING_POINTS * math.pi * 2 }
	end

	-- pitch black void in the middle: a black disk plus soft black smoke around its edge
	local voidDisk = fxPart({ Name = "VoidDisk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 0.1, 0.1), Material = Enum.Material.Neon, Color = COL.void, CFrame = cf * CFrame.Angles(0, math.pi / 2, 0) })
	local center = Instance.new("Attachment")
	center.Parent = root
	local haze = makeEmitter(center, {
		Texture = SMOKE,
		Color = ColorSequence.new(COL.void),
		LightEmission = 0,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, R * 0.9), kp(1, R * 1.2) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.3, 0.25), kp(1, 1) }),
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(0, 0.5),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-25, 25),
		ZOffset = -1,
		Rate = 0,
	})
	local light = Instance.new("PointLight")
	light.Color = COL.core
	light.Range = math.min(R * 3.5, 40)
	light.Brightness = 0
	light.Shadows = false
	light.Parent = center

	-- electric specks drifting inside
	local area = fxPart({ Name = "SpeckArea", Size = Vector3.new(R * 1.3, R * 1.3, 0.8), Transparency = 1, CFrame = cf })
	local specks = makeEmitter(area, {
		Texture = SPARK,
		Shape = Enum.ParticleEmitterShape.Box,
		Color = ColorSequence.new(COL.spark, COL.energy),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 0.3), kp(0.5, 0.22), kp(1, 0) }),
		Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) }),
		Lifetime = NumberRange.new(0.3, 0.8),
		Speed = NumberRange.new(0.5, 2.5),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 0,
	})

	-- electric crackle arcs (reused beams, no new parts)
	local bolts = {}
	for i = 1, BOLTS do
		local a0 = Instance.new("Attachment")
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Parent = root
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Color = ColorSequence.new(COL.spark, COL.energy)
		b.Width0 = 0.12
		b.Width1 = 0.04
		b.Segments = 8
		b.Enabled = false
		b.Parent = root
		bolts[i] = { a0 = a0, a1 = a1, beam = b, nextT = 0 }
	end

	-- dust creeping along the ground at the base
	local baseY = -R * GROUND_SINK
	local dustAtt = Instance.new("Attachment")
	dustAtt.Position = Vector3.new(0, baseY + 0.4, 0)
	dustAtt.Parent = root
	local dust = makeEmitter(dustAtt, {
		Texture = SMOKE,
		Color = ColorSequence.new(COL.smokeA, COL.smokeB),
		LightInfluence = 0.4,
		Size = NumberSequence.new({ kp(0, R * 0.3), kp(1, R * 0.75) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.2, 0.55), kp(1, 1) }),
		Lifetime = NumberRange.new(1.2, 2),
		Speed = NumberRange.new(R * 0.25, R * 0.5),
		SpreadAngle = Vector2.new(85, 85),
		Drag = 2,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-20, 20),
		Rate = 0,
	})

	local groundPos = (cf * CFrame.new(0, baseY + 0.05, 0)).Position
	local glow = fxPart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.08, R * 2.6, R * 2.6), Material = Enum.Material.Neon, Color = COL.energy, Transparency = 1, CFrame = CFrame.new(groundPos) * CFrame.Angles(0, 0, math.pi / 2) })
	tween(glow, 0.6, { Transparency = 0.85 })

	local label = marker:GetAttribute("Label")
	if label then
		addLabel(root, label, R)
	end

	-- opening: rift tear, then burst
	local tear = fxPart({ Size = Vector3.new(0.2, 0.1, 0.2), Material = Enum.Material.Neon, Color = COL.spark, CFrame = cf * CFrame.new(0, baseY * 0.4, 0) })
	tween(tear, 0.12, { Size = Vector3.new(0.2, R * 1.9, 0.2), CFrame = cf }, Enum.EasingStyle.Quint)
	playAt("PortalOpen", cf.Position, 0.9, 0.85)
	task.delay(0.12, function()
		tween(tear, 0.3, { Size = Vector3.new(R * 1.2, R * 1.9, 0.2), Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(tear, 0.35)
		flash(cf.Position, R * 2, COL.spark, 0.3)
		groundRing(groundPos, R * 5, 0.7)
		sparks(cf.Position, 30, R * 4)
		puff(groundPos + Vector3.new(0, 1, 0), 12, R)
		lightFlare(cf.Position, 10, R * 4, 0.5)
	end)

	active[marker] = {
		voidDisk = voidDisk,
		root = root,
		area = area,
		ring = ring,
		haze = haze,
		light = light,
		specks = specks,
		bolts = bolts,
		dust = dust,
		glow = glow,
		R = R,
		cf = cf,
		groundPos = groundPos,
		born = os.clock(),
		spin = 0,
		k = 0,
		phase = "open",
	}
end

local function setRates(s, k)
	local f = math.clamp(k, 0, 1.1)
	for _, p in ipairs(s.ring) do
		p.smoke.Rate = 10 * f
		if p.energy then
			p.energy.Rate = 8 * f
		end
	end
	s.haze.Rate = 5 * f
	s.specks.Rate = 35 * f
	s.dust.Rate = 5 * f
end

local function finish(s)
	-- final puff: the portal bursts into smoke and fades away
	setRates(s, 0)
	for _, p in ipairs(s.ring) do
		p.smoke.Speed = NumberRange.new(s.R * 0.8, s.R * 1.5)
		p.smoke:Emit(3)
	end
	s.haze:Emit(4)
	for _, b in ipairs(s.bolts) do
		b.beam.Enabled = false
	end
	flash(s.cf.Position, s.R * 1.2, COL.spark, 0.2)
	sparks(s.cf.Position, 40, s.R * 3)
	puff(s.cf.Position, 10, s.R * 0.8)
	lightFlare(s.cf.Position, 8, s.R * 3, 0.6)
	tween(s.light, 0.3, { Brightness = 0 })
	tween(s.glow, 0.4, { Transparency = 1 })
	s.voidDisk:Destroy()
	playAt("PortalClose", s.cf.Position, 0.9, 0.9)
	Debris:AddItem(s.root, 2.2)
	Debris:AddItem(s.area, 2.2)
	Debris:AddItem(s.glow, 0.5)
end

RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	local serverT = workspace:GetServerTimeNow()
	for marker, s in pairs(active) do
		local age = t - s.born
		local closeAt = marker:GetAttribute("CloseAt")
		if s.phase ~= "closing" and (not marker.Parent or (closeAt and serverT >= closeAt)) then
			s.phase = "closing"
			s.closeStart = t
		end

		local k, spinSpeed = 1, 1.1
		if s.phase == "open" then
			local a = math.clamp((age - 0.1) / 0.55, 0, 1)
			k = easeOutBack(a)
			spinSpeed = 1.1 + 6 * (1 - a) ^ 2
			if a >= 1 then
				s.phase = "idle"
			end
		elseif s.phase == "idle" then
			k = 1 + 0.03 * math.sin(t * 3)
		else
			local c = t - s.closeStart
			if c < 0.15 then
				k = 1 + 0.08 * math.sin(c / 0.15 * math.pi / 2)
				spinSpeed = 1.1 + c / 0.15 * 3
			elseif c < 0.6 then
				local kk = (c - 0.15) / 0.45
				k = 1.08 * (1 - kk) ^ 2
				spinSpeed = 4 + kk * 10
			else
				active[marker] = nil
				finish(s)
				continue
			end
		end
		s.k = k
		s.spin += spinSpeed * dt

		-- move the ring emitters around the circle (this is what makes the smoke swirl)
		local r = s.R * 0.8 * k
		for _, p in ipairs(s.ring) do
			local ang = p.base + s.spin
			p.att.CFrame = CFrame.new(math.cos(ang) * r, math.sin(ang) * r, 0) * CFrame.Angles(0, 0, ang)
		end
		local d = math.max(0.05, s.R * 1.3 * k)
		s.voidDisk.Size = Vector3.new(0.1, d, d)
		setRates(s, k)
		s.light.Brightness = (2.4 + math.random() * 1.4) * math.clamp(k, 0, 1.2)

		-- electric crackles
		for _, b in ipairs(s.bolts) do
			if t >= b.nextT then
				b.nextT = t + 0.05 + math.random() * 0.12
				if k > 0.3 and math.random() < 0.6 then
					local ang = math.random() * math.pi * 2
					local rad = r * (0.5 + math.random() * 0.5)
					local p0 = Vector3.new(math.cos(ang) * rad, math.sin(ang) * rad, (math.random() - 0.5) * 0.8)
					local d = math.random() * math.pi * 2
					local len = 0.6 + math.random() * 1.6
					b.a0.Position = p0
					b.a1.Position = p0 + Vector3.new(math.cos(d) * len, math.sin(d) * len, 0)
					b.beam.CurveSize0 = (math.random() - 0.5) * 2
					b.beam.CurveSize1 = (math.random() - 0.5) * 2
					b.beam.Width0 = 0.06 + math.random() * 0.1
					b.beam.Enabled = true
				else
					b.beam.Enabled = false
				end
			end
		end
	end
end)

local portalFolder = workspace:WaitForChild("ActivePortals")
portalFolder.ChildAdded:Connect(function(marker)
	task.defer(startPortal, marker)
end)
for _, marker in ipairs(portalFolder:GetChildren()) do
	startPortal(marker)
end

---------------------------------------------------------------- one-shot effects from the server
local function orb(from, to, t)
	local o = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.3, Material = Enum.Material.Neon, Color = COL.spark, CFrame = CFrame.new(from) })
	local l = Instance.new("PointLight")
	l.Color = COL.core
	l.Range = 14
	l.Brightness = 3
	l.Parent = o
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.6, 0)
	a0.Parent = o
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.6, 0)
	a1.Parent = o
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Color = ColorSequence.new(COL.spark, COL.energy)
	tr.Lifetime = 0.3
	tr.LightEmission = 1
	tr.Transparency = NumberSequence.new(0, 1)
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Parent = o
	makeEmitter(o, {
		Texture = SMOKE,
		Color = ColorSequence.new(COL.smokeA, COL.smokeB),
		LightInfluence = 0.3,
		Size = NumberSequence.new({ kp(0, 1.2), kp(1, 2.4) }),
		Transparency = NumberSequence.new({ kp(0, 0.4), kp(1, 1) }),
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(0, 1),
		Rate = 60,
		Rotation = NumberRange.new(0, 360),
	})
	local info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(o, info, { CFrame = CFrame.new(to) }):Play()
	task.delay(t, function()
		o:Destroy()
	end)
end

local function blink(pos)
	playAt("Teleport", pos, 0.7, 0.9)
	flash(pos, 6, COL.spark, 0.25)
	sparks(pos, 22, 16)
	puff(pos, 8, 4)
	groundRing(pos - Vector3.new(0, 2.9, 0), 11, 0.5)
end

local function swallow(pos)
	flash(pos, 6, COL.energy, 0.3)
	sparks(pos, 25, 12)
	puff(pos, 6, 3.5)
end

---------------------------------------------------------------- VOID LANCE (R)
local function lance(origin, endPos, hit)
	playAt("Lance", origin, 0.8, 1.15)
	playAt("Throw", origin, 0.6, 1.3)
	local dir = endPos - origin
	local len = math.max(dir.Magnitude, 0.5)
	local cf = CFrame.lookAt(origin, endPos) * CFrame.new(0, 0, -len / 2)
	local core = fxPart({ Size = Vector3.new(0.7, 0.7, len), Material = Enum.Material.Neon, Color = COL.void, CFrame = cf })
	local glow = fxPart({ Size = Vector3.new(1.8, 1.8, len), Material = Enum.Material.Neon, Color = COL.energy, Transparency = 0.45, CFrame = cf })
	local haze = fxPart({ Size = Vector3.new(3.6, 3.6, len), Material = Enum.Material.ForceField, Color = COL.energy2, Transparency = 0.2, CFrame = cf })
	tween(core, 0.35, { Size = Vector3.new(0.05, 0.05, len) }, Enum.EasingStyle.Quart)
	tween(glow, 0.3, { Size = Vector3.new(0.1, 0.1, len), Transparency = 1 }, Enum.EasingStyle.Quart)
	tween(haze, 0.4, { Size = Vector3.new(6, 6, len), Transparency = 1 }, Enum.EasingStyle.Quart)
	Debris:AddItem(core, 0.4)
	Debris:AddItem(glow, 0.4)
	Debris:AddItem(haze, 0.45)
	flash(origin, 3.5, COL.energy, 0.2)
	local n = math.clamp(math.floor(len / 8), 1, 10)
	for i = 1, n do
		puff(origin + dir * (i / n), 1, 2.2)
	end
	flash(endPos, hit and 9 or 6, hit and COL.spark or COL.energy, 0.3)
	sparks(endPos, hit and 40 or 22, 20)
	puff(endPos, 6, 3.5)
	lightFlare(endPos, 8, 20, 0.35)
	if hit then
		playAt("PortalClose", endPos, 0.7, 1.4)
	end
end

---------------------------------------------------------------- SINGULARITY (F)
local function singularity(center, duration, radius)
	playAt("PortalOpen", center, 1, 0.6)
	local root = fxPart({ Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(center) })
	local hole = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.2, Material = Enum.Material.Neon, Color = COL.void, CFrame = CFrame.new(center) })
	local shell = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.2, Material = Enum.Material.ForceField, Color = COL.energy, CFrame = CFrame.new(center) })
	tween(hole, 0.4, { Size = Vector3.one * 5.5 }, Enum.EasingStyle.Back)
	tween(shell, 0.4, { Size = Vector3.one * 9 }, Enum.EasingStyle.Back)
	local light = Instance.new("PointLight")
	light.Color = COL.core
	light.Range = radius * 1.4
	light.Brightness = 3
	light.Parent = root
	local ring = {}
	for i = 1, 10 do
		local att = Instance.new("Attachment")
		att.Parent = root
		local e = makeEmitter(att, {
			Texture = SMOKE,
			Color = ColorSequence.new(COL.energy, COL.smokeB),
			LightEmission = 0.5,
			LightInfluence = 0,
			Size = NumberSequence.new({ kp(0, 2.5), kp(1, 0.5) }),
			Transparency = NumberSequence.new({ kp(0, 1), kp(0.2, 0.35), kp(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.8),
			Speed = NumberRange.new(8, 12),
			EmissionDirection = Enum.NormalId.Top,
			Rotation = NumberRange.new(0, 360),
			Rate = 18,
		})
		ring[i] = { att = att, base = i / 10 * math.pi * 2, e = e }
	end
	local suckPart = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * radius * 2, Transparency = 1, CFrame = CFrame.new(center) })
	local suck = makeEmitter(suckPart, {
		Texture = SPARK,
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Color = ColorSequence.new(COL.spark, COL.energy),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 0.6), kp(1, 0.1) }),
		Lifetime = NumberRange.new(0.6, 0.9),
		Speed = NumberRange.new(radius * 1.1, radius * 1.5),
		Rate = 90,
	})
	local dust = makeEmitter(suckPart, {
		Texture = SMOKE,
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Color = ColorSequence.new(COL.smokeA, COL.smokeB),
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 4), kp(1, 1) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.3, 0.55), kp(1, 1) }),
		Lifetime = NumberRange.new(0.7, 1),
		Speed = NumberRange.new(radius * 0.9, radius * 1.2),
		Rotation = NumberRange.new(0, 360),
		Rate = 22,
	})
	groundRing(center - Vector3.new(0, 4.9, 0), radius * 2, 0.6)
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local spin = t * (4 + t * 3)
		for _, r in ipairs(ring) do
			local a = r.base + spin
			r.att.CFrame = CFrame.Angles(math.rad(70), 0, 0) * CFrame.new(math.cos(a) * 6.5, math.sin(a) * 6.5, 0) * CFrame.Angles(0, 0, a)
		end
		if hole.Parent then
			hole.Size = Vector3.one * (5.5 + math.sin(t * 22) * 0.35)
		end
		light.Brightness = 3 + math.random() * 2
		if t >= duration then
			conn:Disconnect()
			suck.Enabled = false
			dust.Enabled = false
			for _, r in ipairs(ring) do
				r.e.Enabled = false
			end
			tween(hole, 0.15, { Size = Vector3.one * 0.3 }, Enum.EasingStyle.Quint)
			tween(shell, 0.15, { Size = Vector3.one * 0.3, Transparency = 1 }, Enum.EasingStyle.Quint)
			task.delay(0.15, function()
				playAt("Singularity", center, 1.2, 0.9, 300)
				flash(center, radius * 1.2, COL.spark, 0.25)
				task.delay(0.05, function()
					flash(center, radius * 2, COL.energy, 0.45)
				end)
				local wave = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one, Material = Enum.Material.ForceField, Color = COL.energy, CFrame = CFrame.new(center) })
				tween(wave, 0.5, { Size = Vector3.one * radius * 3, Transparency = 1 }, Enum.EasingStyle.Quart)
				Debris:AddItem(wave, 0.6)
				groundRing(center - Vector3.new(0, 4.9, 0), radius * 3.5, 0.7)
				sparks(center, 70, radius * 2.5)
				puff(center, 14, radius * 0.5)
				lightFlare(center, 14, radius * 3, 0.6)
				hole:Destroy()
				shell:Destroy()
				Debris:AddItem(root, 1.2)
				Debris:AddItem(suckPart, 1.2)
			end)
		end
	end)
end

---------------------------------------------------------------- PETRIFICATION
local function petrify(pos)
	playAt("Petrify", pos, 0.6, 0.7, 160)
	oneShot(pos - Vector3.new(0, 2.5, 0), {
		Texture = SMOKE,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(60, 60),
		EmissionDirection = Enum.NormalId.Top,
		Lifetime = NumberRange.new(1.5, 2.5),
		Acceleration = Vector3.new(0, 1, 0),
		LightInfluence = 0.5,
		Size = NumberSequence.new({ kp(0, 1.5), kp(1, 4) }),
		Color = ColorSequence.new(Color3.fromRGB(120, 115, 125)),
		Transparency = NumberSequence.new({ kp(0, 0.4), kp(1, 1) }),
		Rotation = NumberRange.new(0, 360),
	}, 18, 2.5)
end

local function petrifyDone(pos)
	playAt("Petrify", pos, 1, 0.9, 200)
	flash(pos, 8, Color3.fromRGB(200, 195, 205), 0.25)
	oneShot(pos, {
		Texture = SMOKE,
		Speed = NumberRange.new(6, 14),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
		Lifetime = NumberRange.new(1.2, 2),
		LightInfluence = 0.5,
		Size = NumberSequence.new({ kp(0, 2), kp(1, 6) }),
		Color = ColorSequence.new(Color3.fromRGB(130, 125, 135)),
		Transparency = NumberSequence.new({ kp(0, 0.3), kp(1, 1) }),
		Rotation = NumberRange.new(0, 360),
	}, 24, 2)
	oneShot(pos, {
		Texture = SPARK,
		Speed = NumberRange.new(10, 22),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -40, 0),
		Lifetime = NumberRange.new(0.6, 1),
		Size = NumberSequence.new({ kp(0, 0.6), kp(1, 0.2) }),
		Color = ColorSequence.new(Color3.fromRGB(150, 145, 150)),
		LightInfluence = 1,
	}, 30, 1)
end

Fx.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "orb" then
		playAt("Throw", a, 0.7, 0.85)
		orb(a, b, c)
	elseif kind == "blink" then
		blink(a)
	elseif kind == "swallow" then
		swallow(a)
	elseif kind == "lance" then
		lance(a, b, c)
	elseif kind == "singularity" then
		singularity(a, b, c)
	elseif kind == "petrify" then
		petrify(a)
	elseif kind == "petrifyDone" then
		petrifyDone(a)
	elseif kind == "sound" then
		playAt(a, b, 0.7)
	end
end)
