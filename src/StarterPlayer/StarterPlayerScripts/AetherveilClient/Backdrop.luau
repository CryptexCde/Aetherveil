-- AETHERVEIL · Menu backdrop
-- The title-screen world from the concept: a ground-level shot of a mountain valley with
-- two giant swords planted in the earth (workspace.MenuScene, built by tools/BuildMenuScene),
-- light glowing from behind the mountains, fog, drifting embers and, for Void, a black hole.
-- Everything is recoloured per element, locally, and the game's normal lighting is restored
-- the moment the player enters the world.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Store = require(Root.Config.Store)
local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.UIKit)
local Animator = require(script.Parent.Animator)
local Sound = require(script.Parent.Sound)

local player = Players.LocalPlayer
local C = Theme.Colors

local Backdrop = {}

---------------------------------------------------------------- element looks (match the concept)
local function hex(s)
	return Color3.fromHex(s)
end
local LOOKS = {
	Void = { sky = { "#140a24", "#3a1d55", "#8a4a9a", "#2a1440" }, glow = "#c27cff", ember = "#e6b8ff", rock = "#7a6290", dark = "#140c20", grass = "#2a1a36", haze = "#5a3a72" },
	Fire = { sky = { "#2a0c04", "#7a2a0c", "#e08a2a", "#3a1606" }, glow = "#ff9a3c", ember = "#ffc070", rock = "#8a5a38", dark = "#1e0c06", grass = "#3a2410", haze = "#9a4a1c" },
	Water = { sky = { "#06142a", "#1a3a5a", "#6aa8c0", "#0a2036" }, glow = "#6ad8ff", ember = "#d8f6ff", rock = "#5a7a8a", dark = "#08141e", grass = "#12302e", haze = "#3a6a82" },
	Earth = { sky = { "#1a1408", "#5a4a1e", "#c9a75a", "#2a2010" }, glow = "#d8c070", ember = "#f6e2a8", rock = "#8a7448", dark = "#1a1208", grass = "#36361a", haze = "#8a7440" },
	Air = { sky = { "#1a2430", "#4a6070", "#c8d8e0", "#2a3644" }, glow = "#e8f6ff", ember = "#ffffff", rock = "#8a96a0", dark = "#141a22", grass = "#2a3a36", haze = "#8a9cac" },
	Lightning = { sky = { "#0c0a20", "#2a2a5a", "#8a8ac8", "#141236" }, glow = "#ffe45c", ember = "#fff3a0", rock = "#6a6a92", dark = "#0c0a1e", grass = "#1e1c34", haze = "#4a4a7a" },
}
for _, look in pairs(LOOKS) do
	for i, v in ipairs(look.sky) do
		look.sky[i] = hex(v)
	end
	for _, k in ipairs({ "glow", "ember", "rock", "dark", "grass", "haze" }) do
		look[k] = hex(look[k])
	end
end
Backdrop.Looks = LOOKS

local MATERIALS = { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Ground, Enum.Material.Grass, Enum.Material.Mud }

-- the values we drive for a look, as a flat table that can be blended
local function targetsFor(look)
	local white = Color3.new(1, 1, 1)
	return {
		Ambient = look.dark:Lerp(look.rock, 0.35),
		OutdoorAmbient = look.rock:Lerp(look.haze, 0.5),
		AtmosphereColor = look.haze:Lerp(look.sky[3], 0.4),
		AtmosphereDecay = look.sky[2],
		Tint = white:Lerp(look.ember, 0.18),
		Rock = look.rock,
		Slate = look.rock:Lerp(look.dark, 0.35),
		Ground = look.grass:Lerp(look.rock, 0.45),
		Grass = look.grass,
		Mud = look.dark:Lerp(look.rock, 0.3),
		Clouds = look.sky[2]:Lerp(look.sky[3], 0.35),
		Glow = look.glow,
		Ember = look.ember,
		SkyTop = look.sky[1],
		SkyMid = look.sky[2],
		Sun = look.sky[3],
	}
end

local function blend(a, b, t)
	local out = {}
	for k, v in pairs(b) do
		out[k] = a[k] and a[k]:Lerp(v, t) or v
	end
	return out
end

---------------------------------------------------------------- state
local active = false
local layer, skyTop, sunGlow, voidHole, voidRing, boltLayer
local motes = {}
local stopStep
local music
local grade
local saved -- original lighting, restored when leaving the menu
local created = {}
local current = targetsFor(LOOKS.Void)
local currentId = "Void"
local fromVals, toVals, blendT = nil, nil, 1
local previewId, baseId = nil, "Void"
local flash = 0
local mouse = Vector2.new()

local function scene()
	return workspace:FindFirstChild("MenuScene")
end

---------------------------------------------------------------- UI layer (sky tint, sun glow, black hole, motes)
function Backdrop.Init(parent)
	layer = UI.new("CanvasGroup", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 0,
		Parent = parent,
	})

	skyTop = UI.new("Frame", { Name = "SkyTint", Size = UDim2.fromScale(1, 0.62), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = layer })
	UI.gradient(skyTop, ColorSequence.new(current.SkyTop, current.SkyMid), NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.55, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	}), 90)

	sunGlow = UI.new("Frame", {
		Name = "SunGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.42, 0.5),
		Size = UDim2.fromScale(0.9, 0.9),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = current.Sun,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Parent = layer,
	})
	UI.corner(sunGlow, 10000)
	local glowGradient = UI.gradient(sunGlow, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	}))
	glowGradient.Rotation = 90
	sunGlow.Visible = false -- the 3D sun + atmosphere do this; kept for low graphics

	-- black hole (Void only), drawn like the concept: dark core with a tilted accretion ring
	voidHole = UI.new("Frame", {
		Name = "BlackHole",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.4, 0.15),
		Size = UDim2.fromScale(0.12, 0.12),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Parent = layer,
	})
	-- soft glow: stacked circles that fade outwards
	for i, size in ipairs({ 2.2, 1.7, 1.3, 0.95 }) do
		local glow = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(size, size * 0.55),
			BackgroundColor3 = hex("#ff5ce0"),
			BackgroundTransparency = 0.9 - i * 0.04,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = voidHole,
		})
		UI.corner(glow, 10000)
	end
	local core = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.42, 0.42), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3, Parent = voidHole })
	UI.corner(core, 10000)
	UI.new("UIStroke", { Color = hex("#ff8af0"), Thickness = 2, Transparency = 0.2, Parent = core })
	voidRing = {}
	for i = 1, 40 do
		local dot = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = (i % 3 == 0) and hex("#ffffff") or hex("#ff5ce0"), BorderSizePixel = 0, ZIndex = 2, Parent = voidHole })
		UI.corner(dot, 4)
		voidRing[i] = dot
	end

	boltLayer = UI.new("Frame", { Name = "Bolts", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = layer })

	-- vignettes for legibility (right side behind the menu, top and bottom)
	local right = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Ink, BorderSizePixel = 0, Parent = layer })
	UI.gradient(right, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.35),
	}))
	local edges = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = layer })
	UI.gradient(edges, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.18, 1),
		NumberSequenceKeypoint.new(0.78, 1),
		NumberSequenceKeypoint.new(1, 0.25),
	}), 90)

	for i = 1, 60 do
		local size = math.random(2, 5)
		local m = UI.new("Frame", {
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = current.Ember,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Parent = layer,
		})
		UI.corner(m, size)
		table.insert(motes, { Frame = m, X = math.random(), Y = math.random(), Speed = 0.012 + math.random() * 0.03, Phase = math.random() * 6.28, Sway = 0.004 + math.random() * 0.01 })
	end

	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "AetherveilMenuGrade"
	grade.Enabled = false
	grade.Contrast = 0.16
	grade.Saturation = 0.12
	grade.Parent = Lighting

	music = Instance.new("Sound")
	music.Name = "MenuMusic"
	music.SoundId = Store.MenuMusicId
	music.Looped = true
	music.Volume = 0
	music.SoundGroup = Sound.Music
	music.Parent = SoundService

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local vs = workspace.CurrentCamera.ViewportSize
			mouse = Vector2.new(input.Position.X / vs.X - 0.5, input.Position.Y / vs.Y - 0.5)
		end
	end)
end

-- Assets the loading screen preloads.
function Backdrop.Assets()
	local list = { music }
	local s = scene()
	if s then
		for _, d in ipairs(s:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(list, d)
			end
		end
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		table.insert(list, sky)
	end
	return list
end

-- Streams the menu world in around the camera (StreamingEnabled).
function Backdrop.StreamWorld()
	local s = scene()
	local cam = s and s:FindFirstChild("MenuCamera")
	if not cam then
		s = workspace:WaitForChild("MenuScene", 10)
		cam = s and s:WaitForChild("MenuCamera", 5)
	end
	if cam and workspace.StreamingEnabled then
		pcall(function()
			player:RequestStreamAroundAsync(cam.Position, 8)
		end)
		local focus = s:FindFirstChild("MenuFocus")
		if focus then
			pcall(function()
				player:RequestStreamAroundAsync(focus.Position + Vector3.new(0, 0, -200), 8)
			end)
		end
	end
end

---------------------------------------------------------------- lighting save / apply / restore
local function save()
	if saved then
		return
	end
	local terrain = workspace.Terrain
	saved = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		GeographicLatitude = Lighting.GeographicLatitude,
		Materials = {},
		Props = {},
	}
	for _, m in ipairs(MATERIALS) do
		saved.Materials[m] = terrain:GetMaterialColor(m)
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
		created.Atmosphere = atmosphere
	end
	saved.Atmosphere = { Density = atmosphere.Density, Offset = atmosphere.Offset, Color = atmosphere.Color, Decay = atmosphere.Decay, Glare = atmosphere.Glare, Haze = atmosphere.Haze }
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	if not clouds then
		clouds = Instance.new("Clouds")
		clouds.Enabled = false
		clouds.Parent = terrain
		created.Clouds = clouds
	end
	saved.Clouds = { Cover = clouds.Cover, Density = clouds.Density, Color = clouds.Color, Enabled = clouds.Enabled }
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then
		saved.SunRays = { Intensity = sunRays.Intensity, Spread = sunRays.Spread }
	end
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		saved.DOF = { FarIntensity = dof.FarIntensity, FocusDistance = dof.FocusDistance, InFocusRadius = dof.InFocusRadius, NearIntensity = dof.NearIntensity }
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		saved.Sky = { CelestialBodiesShown = sky.CelestialBodiesShown, StarCount = sky.StarCount }
	end
end

local function restore()
	if not saved then
		return
	end
	local terrain = workspace.Terrain
	Lighting.Ambient = saved.Ambient
	Lighting.OutdoorAmbient = saved.OutdoorAmbient
	Lighting.Brightness = saved.Brightness
	Lighting.ClockTime = saved.ClockTime
	Lighting.GeographicLatitude = saved.GeographicLatitude
	for m, color in pairs(saved.Materials) do
		terrain:SetMaterialColor(m, color)
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		for k, v in pairs(saved.Atmosphere) do
			atmosphere[k] = v
		end
	end
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		for k, v in pairs(saved.Clouds) do
			clouds[k] = v
		end
	end
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays and saved.SunRays then
		for k, v in pairs(saved.SunRays) do
			sunRays[k] = v
		end
	end
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof and saved.DOF then
		for k, v in pairs(saved.DOF) do
			dof[k] = v
		end
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky and saved.Sky then
		for k, v in pairs(saved.Sky) do
			sky[k] = v
		end
	end
	if created.Atmosphere then
		created.Atmosphere:Destroy()
		created.Atmosphere = nil
	end
	if created.Clouds then
		created.Clouds:Destroy()
		created.Clouds = nil
	end
	saved = nil
end

-- Put the sun low behind the mountains, slightly left of centre (like the concept).
local sunSetting
local function placeSun()
	local s = scene()
	local camPart = s and s:FindFirstChild("MenuCamera")
	local focus = s and s:FindFirstChild("MenuFocus")
	if not camPart or not focus then
		return
	end
	if not sunSetting then
		local flat = focus.Position - camPart.Position
		flat = Vector3.new(flat.X, 0, flat.Z).Unit
		local right = flat:Cross(Vector3.yAxis)
		local want = (flat - right * 0.12 + Vector3.new(0, 0.2, 0)).Unit
		local best, bestDot = nil, -2
		for lat = -85, 85, 5 do
			Lighting.GeographicLatitude = lat
			for clock = 0, 24, 0.25 do
				Lighting.ClockTime = clock
				local d = Lighting:GetSunDirection():Dot(want)
				if d > bestDot then
					bestDot = d
					best = { lat, clock }
				end
			end
		end
		sunSetting = best
	end
	Lighting.GeographicLatitude = sunSetting[1]
	Lighting.ClockTime = sunSetting[2]
end

local function applyValues(v)
	local terrain = workspace.Terrain
	Lighting.Ambient = v.Ambient
	Lighting.OutdoorAmbient = v.OutdoorAmbient
	grade.TintColor = v.Tint
	terrain:SetMaterialColor(Enum.Material.Rock, v.Rock)
	terrain:SetMaterialColor(Enum.Material.Slate, v.Slate)
	terrain:SetMaterialColor(Enum.Material.Ground, v.Ground)
	terrain:SetMaterialColor(Enum.Material.Grass, v.Grass)
	terrain:SetMaterialColor(Enum.Material.Mud, v.Mud)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = v.AtmosphereColor
		atmosphere.Decay = v.AtmosphereDecay
	end
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds.Color = v.Clouds
	end
	local s = scene()
	if s then
		for _, d in ipairs(s:GetDescendants()) do
			if d.Name == "Gem" and d:IsA("BasePart") then
				d.Color = v.Glow
				local light = d:FindFirstChildOfClass("PointLight")
				if light then
					light.Color = v.Glow
				end
			end
		end
	end
	local gradient = skyTop:FindFirstChildOfClass("UIGradient")
	gradient.Color = ColorSequence.new(v.SkyTop, v.SkyMid)
	for _, m in ipairs(motes) do
		m.Frame.BackgroundColor3 = v.Ember
	end
end

local function applyStatic()
	Lighting.Brightness = 2.4
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0.36
		atmosphere.Offset = 0.12
		atmosphere.Glare = 1.2
		atmosphere.Haze = 2.2
	end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds.Enabled = true
		clouds.Cover = 0.62
		clouds.Density = 0.55
	end
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then
		sunRays.Intensity = 0.14
		sunRays.Spread = 0.7
	end
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.FocusDistance = 120
		dof.InFocusRadius = 140
		dof.FarIntensity = 0.12
		dof.NearIntensity = 0
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.StarCount = 0
	end
	placeSun()
end

---------------------------------------------------------------- themes
local function lookFor(id)
	return LOOKS[id] or LOOKS.Void
end

local function transitionTo(id)
	if id == currentId and blendT >= 1 then
		return
	end
	currentId = id
	fromVals = current
	toVals = targetsFor(lookFor(id))
	blendT = 0
end

-- The element the player has equipped (or Void before they choose).
function Backdrop.SetElement(id)
	baseId = LOOKS[id] and id or "Void"
	if not previewId then
		transitionTo(baseId)
	end
end

-- Temporarily show another element's look (hovering a card in the Elements menu).
function Backdrop.Preview(id)
	previewId = LOOKS[id] and id or nil
	transitionTo(previewId or baseId)
end

local function spawnBolt(color)
	local x = 0.35 + math.random() * 0.35
	local y = 0
	for _ = 1, 9 do
		local nx = x + (math.random() - 0.5) * 0.05
		local ny = y + 0.055
		local seg = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale((x + nx) / 2, (y + ny) / 2),
			Size = UDim2.new(0, 3, ny - y, 8),
			Rotation = math.deg(math.atan2(-(nx - x) * 16, 9)),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = boltLayer,
		})
		UI.new("UIStroke", { Color = color, Thickness = 3, Transparency = 0.3, Parent = seg })
		Animator.Tween(seg, 0.35, { BackgroundTransparency = 1 }).Completed:Connect(function()
			seg:Destroy()
		end)
		x, y = nx, ny
	end
end

---------------------------------------------------------------- camera + per-frame
local function startLoop()
	local camera = workspace.CurrentCamera
	local smoothMouse = Vector2.new()
	stopStep = Animator.Every(function(dt, t)
		-- theme blend
		if blendT < 1 then
			blendT = math.min(1, blendT + dt / 0.7)
			local e = 1 - (1 - blendT) ^ 3
			current = blend(fromVals, toVals, e)
			applyValues(current)
		end

		-- camera: low, near the ground, slow drift and a little mouse parallax
		local s = scene()
		local camPart = s and s:FindFirstChild("MenuCamera")
		local focus = s and s:FindFirstChild("MenuFocus")
		camera.CameraType = Enum.CameraType.Scriptable
		if camPart and focus then
			smoothMouse = smoothMouse:Lerp(mouse, math.min(1, dt * 2))
			local right = (focus.Position - camPart.Position):Cross(Vector3.yAxis).Unit
			local pos = camPart.Position
				+ right * (math.sin(t * 0.2) * 3 + smoothMouse.X * 6)
				+ Vector3.new(0, math.sin(t * 0.13) * 0.6 - smoothMouse.Y * 1.5, 0)
			local look = focus.Position + right * (smoothMouse.X * 12) + Vector3.new(0, -smoothMouse.Y * 4, 0)
			camera.CFrame = CFrame.lookAt(pos, look)
			camera.FieldOfView = 56
		end

		-- black hole for Void
		local voidAmount = currentId == "Void" and 1 or 0
		voidHole.Visible = voidAmount > 0
		if voidHole.Visible then
			for i, dot in ipairs(voidRing) do
				local a = t * 0.6 + i * (math.pi * 2 / #voidRing)
				dot.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.62, 0.5 + math.sin(a) * 0.2)
				dot.BackgroundTransparency = 0.15 + 0.5 * (0.5 + 0.5 * math.sin(a))
				dot.ZIndex = math.sin(a) > 0 and 4 or 2
			end
		end

		-- lightning storms
		if currentId == "Lightning" and math.random() < dt * 0.35 then
			flash = 1
			spawnBolt(current.Glow)
		end
		if flash > 0 then
			flash = math.max(0, flash - dt * 3)
			grade.Brightness = flash * 0.35
		else
			grade.Brightness = 0
		end

		-- embers
		for _, m in ipairs(motes) do
			m.Y -= m.Speed * dt * (currentId == "Air" and 0.6 or 1)
			m.X += (currentId == "Air" and dt * 0.03 or 0)
			if m.Y < -0.02 then
				m.Y = 1.02
				m.X = math.random()
			end
			if m.X > 1.02 then
				m.X = -0.02
			end
			m.Frame.Position = UDim2.fromScale(m.X + math.sin(t * 0.8 + m.Phase) * m.Sway, m.Y)
			m.Frame.BackgroundTransparency = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(t * 1.7 + m.Phase))
		end
	end)
end

function Backdrop.SetActive(on)
	if on == active then
		return
	end
	active = on
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, not on)
	end)
	if on then
		save()
		applyStatic()
		current = targetsFor(lookFor(currentId))
		applyValues(current)
		grade.Enabled = true
		startLoop()
		Animator.Tween(layer, 0.8, { GroupTransparency = 0 })
		if music.SoundId ~= "" then
			music:Play()
			Animator.Tween(music, 2.5, { Volume = 0.5 })
		end
	else
		if stopStep then
			stopStep()
			stopStep = nil
		end
		grade.Enabled = false
		grade.Brightness = 0
		restore()
		layer.GroupTransparency = 1
		local fade = Animator.Tween(music, 1.2, { Volume = 0 })
		fade.Completed:Connect(function()
			if not active then
				music:Stop()
			end
		end)
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
	end
end

function Backdrop.IsActive()
	return active
end

return Backdrop
