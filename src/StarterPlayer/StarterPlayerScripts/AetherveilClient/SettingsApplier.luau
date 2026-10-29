-- AETHERVEIL · Applies graphics, VFX and volume settings on this client

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsConfig = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Settings)
local Sound = require(script.Parent.Sound)

local SettingsApplier = {}
SettingsApplier.Current = SettingsConfig.Sanitize(nil)

local baseRates = setmetatable({}, { __mode = "k" })
local original = nil
local vfxScale = 1

local GRAPHICS_LEVEL = { Low = 1, Medium = 2, High = 3, Ultra = 4 }

local function captureLighting()
	if original then
		return
	end
	original = { GlobalShadows = Lighting.GlobalShadows, Effects = {} }
	for _, e in ipairs(Lighting:GetChildren()) do
		if e:IsA("PostEffect") and e.Name ~= "AetherveilMenuGrade" then
			original.Effects[e] = e.Enabled
		end
	end
end

local function scaleEmitter(emitter)
	if baseRates[emitter] == nil then
		baseRates[emitter] = emitter.Rate
	end
	emitter.Rate = baseRates[emitter] * vfxScale
end

local MUSIC_HINTS = { "music", "ambience", "ambient", "theme" }
local function groupSound(sound)
	if sound.SoundGroup ~= nil then
		return
	end
	local name = string.lower(sound.Name)
	for _, hint in ipairs(MUSIC_HINTS) do
		if string.find(name, hint, 1, true) then
			sound.SoundGroup = Sound.Music
			return
		end
	end
	sound.SoundGroup = Sound.SFX
end

local function watch(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			scaleEmitter(d)
		elseif d:IsA("Sound") then
			groupSound(d)
		end
	end
	container.DescendantAdded:Connect(function(d)
		if d:IsA("ParticleEmitter") then
			task.defer(scaleEmitter, d)
		elseif d:IsA("Sound") then
			task.defer(groupSound, d)
		end
	end)
end

function SettingsApplier.Init()
	captureLighting()
	task.defer(function()
		watch(workspace)
		watch(SoundService)
		watch(Players.LocalPlayer:WaitForChild("PlayerGui"))
	end)
end

function SettingsApplier.Apply(settings)
	settings = SettingsConfig.Sanitize(settings)
	SettingsApplier.Current = settings

	-- volume
	Sound.Music.Volume = settings.Music * settings.Master
	Sound.SFX.Volume = settings.SFX * settings.Master

	-- graphics: post effects and shadows
	captureLighting()
	local level = GRAPHICS_LEVEL[settings.Graphics] or 3
	Lighting.GlobalShadows = level >= 2 and original.GlobalShadows
	for effect, wasEnabled in pairs(original.Effects) do
		if effect.Parent then
			local need = 2
			if effect:IsA("SunRaysEffect") then
				need = 3
			elseif effect:IsA("DepthOfFieldEffect") then
				need = 4
			elseif effect:IsA("ColorCorrectionEffect") then
				need = 1
			end
			effect.Enabled = wasEnabled and level >= need
		end
	end

	-- VFX: particle density
	local newScale = SettingsConfig.VFXScale[settings.VFX] or 1
	if newScale ~= vfxScale then
		vfxScale = newScale
		for emitter in pairs(baseRates) do
			if emitter.Parent then
				emitter.Rate = baseRates[emitter] * vfxScale
			end
		end
	end
end

return SettingsApplier
