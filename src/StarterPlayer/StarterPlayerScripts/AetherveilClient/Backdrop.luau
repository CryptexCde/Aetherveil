-- AETHERVEIL · Menu backdrop
-- A slow cinematic camera over the Void Dimension, colour grading, soft vignettes,
-- drifting motes and the menu music. Active only while the menu is open.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
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

local active = false
local layer
local motes = {}
local stopStep
local music
local grade

local function focusPoint()
	local cfg = ReplicatedStorage:FindFirstChild("PortalConfig")
	if cfg and workspace:FindFirstChild("VoidDimension") then
		local ok, config = pcall(require, cfg)
		if ok and config.VOID_CENTER then
			return config.VOID_CENTER, (config.VOID_RADIUS or 280)
		end
	end
	return Vector3.new(0, 20, 0), 120
end

function Backdrop.Init(parent)
	layer = UI.new("CanvasGroup", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 0,
		Parent = parent,
	})
	-- darken the right side behind the menu, and the top and bottom edges
	local right = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Ink, BorderSizePixel = 0, Parent = layer })
	UI.gradient(right, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 0.85),
		NumberSequenceKeypoint.new(1, 0.25),
	}))
	local bottom = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Ink, BorderSizePixel = 0, Parent = layer })
	UI.gradient(bottom, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.2, 1),
		NumberSequenceKeypoint.new(0.75, 1),
		NumberSequenceKeypoint.new(1, 0.2),
	}), 90)
	local tint = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Accent, BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = layer })
	UI.gradient(tint, nil, NumberSequence.new(1, 0), 120)

	for i = 1, 46 do
		local size = math.random(2, 5)
		local m = UI.new("Frame", {
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = (i % 3 == 0) and C.Accent2 or C.Accent,
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
	grade.TintColor = Color3.fromRGB(226, 212, 255)
	grade.Contrast = 0.12
	grade.Saturation = 0.08
	grade.Brightness = -0.02
	grade.Parent = Lighting

	music = Instance.new("Sound")
	music.Name = "MenuMusic"
	music.SoundId = Store.MenuMusicId
	music.Looped = true
	music.Volume = 0
	music.SoundGroup = Sound.Music
	music.Parent = SoundService
end

local function startCamera()
	local center, radius = focusPoint()
	if workspace.StreamingEnabled then
		task.spawn(function()
			pcall(function()
				player:RequestStreamAroundAsync(center)
			end)
		end)
	end
	local camera = workspace.CurrentCamera
	local orbit = radius * 0.62
	stopStep = Animator.Every(function(dt, t)
		camera.CameraType = Enum.CameraType.Scriptable
		local a = t * 0.035
		local pos = center + Vector3.new(math.cos(a) * orbit, radius * 0.16 + math.sin(t * 0.12) * 6, math.sin(a) * orbit)
		local look = center + Vector3.new(math.cos(a + 2.2) * radius * 0.12, radius * 0.08, math.sin(a + 2.2) * radius * 0.12)
		camera.CFrame = CFrame.lookAt(pos, look)
		camera.FieldOfView = 62
		for _, m in ipairs(motes) do
			m.Y -= m.Speed * dt
			if m.Y < -0.02 then
				m.Y = 1.02
				m.X = math.random()
			end
			m.Frame.Position = UDim2.fromScale(m.X + math.sin(t * 0.8 + m.Phase) * m.Sway, m.Y)
			m.Frame.BackgroundTransparency = 0.25 + 0.6 * (0.5 + 0.5 * math.sin(t * 1.7 + m.Phase))
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
		startCamera()
		grade.Enabled = true
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
		Animator.Tween(layer, 0.5, { GroupTransparency = 1 })
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
