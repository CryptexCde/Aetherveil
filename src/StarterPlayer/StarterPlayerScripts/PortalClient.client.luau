-- PORTAL WALKER controls, HUD, pull effect and Void visuals.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("PortalConfig"))
local Remotes = ReplicatedStorage:WaitForChild("PortalRemotes")
local Action = Remotes:WaitForChild("Action")
local Pull = Remotes:WaitForChild("Pull")
local Notify = Remotes:WaitForChild("Notify")

local PURPLE = Color3.fromRGB(150, 90, 255)
local BLUE = Color3.fromRGB(90, 170, 255)
local CYAN = Color3.fromRGB(150, 255, 235)

---------------------------------------------------------------- aiming
local function getAimPoint(screenPos)
	local camera = workspace.CurrentCamera
	local pos = screenPos or UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local ap = workspace:FindFirstChild("ActivePortals")
	if ap then
		table.insert(ignore, ap)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if hit then
		return hit.Position
	end
	return ray.Origin + ray.Direction * Config.MAX_RANGE
end

local function use(action, fromButton)
	if not player:GetAttribute("PortalWalker") then
		return
	end
	local target
	if fromButton then
		target = getAimPoint(workspace.CurrentCamera.ViewportSize / 2)
	else
		target = getAimPoint()
	end
	Action:FireServer(action, target)
end

local KEYS = {
	[Enum.KeyCode.Q] = "Void",
	[Enum.KeyCode.E] = "Teleport",
	[Enum.KeyCode.R] = "Lance",
	[Enum.KeyCode.F] = "Singularity",
}

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local a = KEYS[input.KeyCode]
	if a then
		use(a, false)
	end
end)

---------------------------------------------------------------- HUD
local gui = Instance.new("ScreenGui")
gui.Name = "PortalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "Abilities"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -24)
bar.Size = UDim2.fromOffset(400, 92)
bar.BackgroundTransparency = 1
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = bar

local buttons = {}
local function makeButton(action, title, key, color)
	local b = Instance.new("TextButton")
	b.Name = action
	b.Size = UDim2.fromOffset(88, 88)
	b.BackgroundColor3 = Color3.fromRGB(14, 8, 26)
	b.BackgroundTransparency = 0.15
	b.AutoButtonColor = true
	b.Text = ""
	b.Parent = bar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2.5
	stroke.Parent = b

	local icon = Instance.new("Frame")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 10)
	icon.Size = UDim2.fromOffset(30, 30)
	icon.BackgroundColor3 = Color3.new(0, 0, 0)
	icon.Parent = b
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = color
	iconStroke.Thickness = 3
	iconStroke.Parent = icon

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 0, 0, 46)
	name.Size = UDim2.new(1, 0, 0, 18)
	name.Font = Enum.Font.GothamBold
	name.Text = title
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextSize = 12
	name.TextScaled = false
	name.Parent = b

	local keyLabel = Instance.new("TextLabel")
	keyLabel.BackgroundTransparency = 1
	keyLabel.Position = UDim2.new(0, 0, 0, 64)
	keyLabel.Size = UDim2.new(1, 0, 0, 16)
	keyLabel.Font = Enum.Font.Gotham
	keyLabel.Text = "[" .. key .. "]"
	keyLabel.TextColor3 = color
	keyLabel.TextSize = 12
	keyLabel.Parent = b

	local cd = Instance.new("TextLabel")
	cd.Name = "Cooldown"
	cd.Size = UDim2.fromScale(1, 1)
	cd.BackgroundColor3 = Color3.new(0, 0, 0)
	cd.BackgroundTransparency = 0.35
	cd.Font = Enum.Font.GothamBlack
	cd.TextColor3 = Color3.new(1, 1, 1)
	cd.TextSize = 26
	cd.Visible = false
	cd.ZIndex = 5
	cd.Parent = b
	Instance.new("UICorner", cd).CornerRadius = UDim.new(0, 16)

	b.Activated:Connect(function()
		use(action, true)
	end)
	buttons[action] = cd
	return b
end

makeButton("Void", "VOID PORTAL", "Q", PURPLE)
makeButton("Teleport", "TELEPORT", "E", BLUE)
makeButton("Lance", "VOID LANCE", "R", Color3.fromRGB(200, 90, 255))
makeButton("Singularity", "SINGULARITY", "F", Color3.fromRGB(120, 40, 220))

-- unlock button for players without the pass
local buy = Instance.new("TextButton")
buy.Name = "BuyPortalWalker"
buy.AnchorPoint = Vector2.new(0.5, 1)
buy.Position = UDim2.new(0.5, 0, 1, -24)
buy.Size = UDim2.fromOffset(260, 54)
buy.BackgroundColor3 = Color3.fromRGB(70, 30, 140)
buy.Font = Enum.Font.GothamBlack
buy.Text = "UNLOCK PORTAL WALKER"
buy.TextColor3 = Color3.new(1, 1, 1)
buy.TextSize = 18
buy.Visible = false
buy.Parent = gui
Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 14)
local buyStroke = Instance.new("UIStroke")
buyStroke.Color = CYAN
buyStroke.Thickness = 2
buyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
buyStroke.Parent = buy
buy.Activated:Connect(function()
	Action:FireServer("Buy")
end)

local function refreshOwnership()
	local owns = player:GetAttribute("PortalWalker") == true
	bar.Visible = owns
	-- AETHERVEIL: only offer the pass while playing as Void
	buy.Visible = (not owns) and Config.GAMEPASS_ID ~= 0 and player:GetAttribute("Element") == "Void" and player:GetAttribute("InGame") == true
end
player:GetAttributeChangedSignal("PortalWalker"):Connect(refreshOwnership)
player:GetAttributeChangedSignal("Element"):Connect(refreshOwnership)
player:GetAttributeChangedSignal("InGame"):Connect(refreshOwnership)
refreshOwnership()

RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	for action, cd in pairs(buttons) do
		local ends = player:GetAttribute("CD_" .. action)
		local left = ends and (ends - t) or 0
		if left > 0 then
			cd.Visible = true
			cd.Text = tostring(math.ceil(left))
		else
			cd.Visible = false
		end
	end
end)

---------------------------------------------------------------- notifications
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 70)
toast.Size = UDim2.fromOffset(560, 40)
toast.BackgroundColor3 = Color3.fromRGB(14, 8, 26)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextTransparency = 1
toast.TextWrapped = true
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)

local toastId = 0
Notify.OnClientEvent:Connect(function(text)
	toastId += 1
	local id = toastId
	toast.Text = text
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.25
	task.delay(3, function()
		if id == toastId then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
end)

---------------------------------------------------------------- pull effect
Pull.OnClientEvent:Connect(function(center, duration)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or typeof(center) ~= "Vector3" then
		return
	end
	local endTime = os.clock() + math.clamp(duration or 1, 0, 1.5)
	local camera = workspace.CurrentCamera
	TweenService:Create(camera, TweenInfo.new(0.2), { FieldOfView = 88 }):Play()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if os.clock() > endTime or not root.Parent then
			conn:Disconnect()
			TweenService:Create(camera, TweenInfo.new(0.4), { FieldOfView = 70 }):Play()
			return
		end
		local offset = center - root.Position
		local dist = offset.Magnitude
		if dist < 0.5 then
			return
		end
		local closeness = 1 - math.clamp(dist / Config.PULL_RADIUS, 0, 1)
		local speed = Config.PULL_STRENGTH * (0.65 + 0.5 * closeness)
		root.AssemblyLinearVelocity = offset.Unit * speed
	end)
end)

---------------------------------------------------------------- Void visuals
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "VoidTint"
tint.Enabled = false
tint.TintColor = Color3.fromRGB(205, 175, 255)
tint.Saturation = -0.15
tint.Contrast = 0.2
tint.Brightness = 0
tint.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Name = "VoidBlur"
blur.Size = 0
blur.Parent = Lighting

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 16)
banner.Size = UDim2.fromOffset(520, 46)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.GothamBlack
banner.Text = "TRAPPED IN THE VOID"
banner.TextColor3 = Color3.fromRGB(200, 150, 255)
banner.TextStrokeTransparency = 0.3
banner.TextSize = 34
banner.Visible = false
banner.Parent = gui

local saved = nil
local savedAtmo = nil
local savedSky = nil
local createdAtmo = nil
local function setVoidLook(inVoid)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if inVoid and not atmo then
		createdAtmo = Instance.new("Atmosphere")
		createdAtmo.Parent = Lighting
		atmo = createdAtmo
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	banner.Text = player:GetAttribute("VoidVisitor") and "YOU WALK THE VOID" or "TRAPPED IN THE VOID"
	if inVoid then
		if sky and not savedSky then
			savedSky = { StarCount = sky.StarCount, CelestialBodiesShown = sky.CelestialBodiesShown }
			sky.StarCount = 0
			sky.CelestialBodiesShown = false
		end
		if not saved then
			saved = {
				ClockTime = Lighting.ClockTime,
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
				Brightness = Lighting.Brightness,
				EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
				EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
				ExposureCompensation = Lighting.ExposureCompensation,
			}
			if atmo then
				savedAtmo = { Density = atmo.Density, Color = atmo.Color, Decay = atmo.Decay, Glare = atmo.Glare, Haze = atmo.Haze, Offset = atmo.Offset }
			end
		end
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(88, 58, 120)
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 100, 185)
		Lighting.Brightness = 1.4
		-- remove the blue daytime sky light so everything takes the purple tone (but stays visible)
		Lighting.EnvironmentDiffuseScale = 0.25
		Lighting.EnvironmentSpecularScale = 0.3
		Lighting.ExposureCompensation = 0.15
		-- dark purple haze of the Fallen Realm: moody, but you can still see far
		if atmo then
			atmo.Density = 0.3
			atmo.Offset = 0
			atmo.Color = Color3.fromRGB(88, 45, 130)
			atmo.Decay = Color3.fromRGB(32, 12, 58)
			atmo.Glare = 0
			atmo.Haze = 0.8
		end
		tint.Enabled = true
		banner.Visible = true
		blur.Size = 24
		TweenService:Create(blur, TweenInfo.new(0.8), { Size = 0 }):Play()
	else
		if saved then
			for k, v in pairs(saved) do
				Lighting[k] = v
			end
			saved = nil
		end
		if savedAtmo and atmo then
			for k, v in pairs(savedAtmo) do
				atmo[k] = v
			end
			savedAtmo = nil
		end
		if createdAtmo then
			createdAtmo:Destroy()
			createdAtmo = nil
		end
		if savedSky and sky then
			sky.StarCount = savedSky.StarCount
			sky.CelestialBodiesShown = savedSky.CelestialBodiesShown
			savedSky = nil
		end
		tint.Enabled = false
		banner.Visible = false
		blur.Size = 18
		TweenService:Create(blur, TweenInfo.new(0.6), { Size = 0 }):Play()
	end
end

player:GetAttributeChangedSignal("InVoid"):Connect(function()
	setVoidLook(player:GetAttribute("InVoid") == true)
end)
if player:GetAttribute("InVoid") then
	setVoidLook(true)
end

-- soul counter (grows with every player you banish)
local soulsLabel = Instance.new("TextLabel")
soulsLabel.AnchorPoint = Vector2.new(0.5, 1)
soulsLabel.Position = UDim2.new(0.5, 0, 1, -122)
soulsLabel.Size = UDim2.fromOffset(260, 26)
soulsLabel.BackgroundTransparency = 1
soulsLabel.Font = Enum.Font.GothamBlack
soulsLabel.TextSize = 20
soulsLabel.TextColor3 = Color3.fromRGB(200, 140, 255)
soulsLabel.TextStrokeTransparency = 0.3
soulsLabel.Visible = false
soulsLabel.Parent = gui
local function refreshSouls()
	local n = player:GetAttribute("VoidSouls") or 0
	soulsLabel.Visible = n > 0
	local mult = player:GetAttribute("DamageMultiplier") or 1
	soulsLabel.Text = string.format("VOID SOULS %d  |  POWER x%.2f", n, mult)
	if n > 0 then
		soulsLabel.TextSize = 26
		TweenService:Create(soulsLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back), { TextSize = 20 }):Play()
	end
end
player:GetAttributeChangedSignal("VoidSouls"):Connect(refreshSouls)
refreshSouls()

-- pulse the banner while trapped
RunService.RenderStepped:Connect(function()
	if banner.Visible then
		banner.TextTransparency = 0.15 + 0.25 * math.sin(os.clock() * 3)
	end
end)

---------------------------------------------------------------- eerie Void music
local SoundService = game:GetService("SoundService")
local function loopSound(name, id, vol)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s:SetAttribute("TargetVolume", vol)
	s.Parent = SoundService
	return s
end
local voidMusic = loopSound("VoidMusic", Config.SOUNDS.VoidMusic, 0.55)
local voidAmbience = loopSound("VoidAmbience", Config.SOUNDS.VoidAmbience, 0.45)
local echo = Instance.new("ReverbSoundEffect")
echo.DecayTime = 4
echo.WetLevel = -4
echo.Parent = voidMusic

local function setVoidMusic(on)
	for _, s in ipairs({ voidMusic, voidAmbience }) do
		if on then
			if not s.IsPlaying then
				s:Play()
			end
			TweenService:Create(s, TweenInfo.new(2.5), { Volume = s:GetAttribute("TargetVolume") }):Play()
		else
			local tw = TweenService:Create(s, TweenInfo.new(1.5), { Volume = 0 })
			tw:Play()
			tw.Completed:Connect(function()
				if not player:GetAttribute("InVoid") then
					s:Pause()
				end
			end)
		end
	end
end
player:GetAttributeChangedSignal("InVoid"):Connect(function()
	setVoidMusic(player:GetAttribute("InVoid") == true)
end)
if player:GetAttribute("InVoid") then
	setVoidMusic(true)
end
