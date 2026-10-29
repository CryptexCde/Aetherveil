-- AETHERVEIL · Sound groups and UI sounds
-- Music and SFX sound groups are controlled by the volume settings.

local SoundService = game:GetService("SoundService")

local Sound = {}

local function group(name)
	local g = SoundService:FindFirstChild(name)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Parent = SoundService
	end
	return g
end

Sound.Music = group("AetherveilMusic")
Sound.SFX = group("AetherveilSFX")

local UI_SOUNDS = {
	Hover = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.18, Speed = 1.4 },
	Click = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Speed = 0.7 },
	Confirm = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4, Speed = 1 },
	Error = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Speed = 0.45 },
	Open = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.15, Speed = 1.3 },
}

local cache = {}
local function get(name)
	local def = UI_SOUNDS[name]
	if not def then
		return nil
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.Name = "UI_" .. name
		s.SoundId = def.Id
		s.Volume = def.Volume
		s.PlaybackSpeed = def.Speed
		s.SoundGroup = Sound.SFX
		s.Parent = SoundService
		cache[name] = s
	end
	return s
end

function Sound.Play(name)
	local s = get(name)
	if s then
		s.TimePosition = 0
		s:Play()
	end
end

-- All UI sounds, for the loading screen to preload.
function Sound.Preload()
	local list = {}
	for name in pairs(UI_SOUNDS) do
		table.insert(list, get(name))
	end
	return list
end

return Sound
