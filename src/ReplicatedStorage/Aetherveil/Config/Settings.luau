-- AETHERVEIL · Player settings (saved per player)

local Settings = {}

Settings.Graphics = { "Low", "Medium", "High", "Ultra" }
Settings.VFX = { "Off", "Low", "Medium", "High" }
Settings.VFXScale = { Off = 0, Low = 0.35, Medium = 0.7, High = 1 }

Settings.Defaults = {
	Graphics = "High",
	VFX = "High",
	Master = 0.8,
	Music = 0.6,
	SFX = 0.8,
}

local function clamp01(v, fallback)
	if type(v) ~= "number" or v ~= v then
		return fallback
	end
	return math.clamp(v, 0, 1)
end

-- Returns a clean settings table; never trusts the input.
function Settings.Sanitize(input)
	local out = {}
	input = type(input) == "table" and input or {}
	out.Graphics = table.find(Settings.Graphics, input.Graphics) and input.Graphics or Settings.Defaults.Graphics
	out.VFX = table.find(Settings.VFX, input.VFX) and input.VFX or Settings.Defaults.VFX
	out.Master = clamp01(input.Master, Settings.Defaults.Master)
	out.Music = clamp01(input.Music, Settings.Defaults.Music)
	out.SFX = clamp01(input.SFX, Settings.Defaults.SFX)
	return out
end

return Settings
