-- AETHERVEIL · Builds a weapon model from its Look in Config/Weapons.
-- The same model is used for the in-game tool and the 3D menu previews.
-- The grip runs along the Handle's Y axis and the blade points up (+Y).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = require(ReplicatedStorage:WaitForChild("Aetherveil"):WaitForChild("Config"):WaitForChild("Weapons"))

local WeaponModel = {}

local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

function WeaponModel.Build(id)
	local def = Weapons.Get(id)
	if not def then
		return nil
	end
	local L = def.Look
	local rarity = Weapons.RarityOf(def)
	local gripLen = L.GripLength or 1.1
	local bladeLen = L.BladeLength
	local bladeW = L.BladeWidth
	local thick = 0.12

	local model = Instance.new("Model")
	model.Name = id

	local handle = newPart({
		Name = "Handle",
		Size = Vector3.new(0.3, gripLen, 0.3),
		Color = L.Grip,
		Material = Enum.Material.Fabric,
	})
	handle.CFrame = CFrame.new()
	handle.Parent = model

	local function attach(part, offset)
		part.CFrame = handle.CFrame * offset
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
		return part
	end

	-- grip wraps
	for i = 1, 3 do
		attach(newPart({ Name = "Wrap", Size = Vector3.new(0.34, 0.07, 0.34), Color = L.Guard, Material = Enum.Material.Metal }), CFrame.new(0, -gripLen / 2 + gripLen * (i / 4), 0))
	end

	local guardY = gripLen / 2 + 0.11
	attach(newPart({ Name = "Guard", Size = Vector3.new(L.GuardWidth, 0.22, 0.42), Color = L.Guard, Material = Enum.Material.Metal }), CFrame.new(0, guardY, 0))
	attach(newPart({ Name = "GuardTipL", Size = Vector3.new(0.26, 0.26, 0.26), Color = L.Guard, Material = Enum.Material.Metal }), CFrame.new(-L.GuardWidth / 2, guardY + 0.05, 0) * CFrame.Angles(0, 0, math.rad(45)))
	attach(newPart({ Name = "GuardTipR", Size = Vector3.new(0.26, 0.26, 0.26), Color = L.Guard, Material = Enum.Material.Metal }), CFrame.new(L.GuardWidth / 2, guardY + 0.05, 0) * CFrame.Angles(0, 0, math.rad(45)))

	local bladeBase = guardY + 0.11
	attach(newPart({ Name = "Blade", Size = Vector3.new(bladeW, bladeLen, thick), Color = L.Blade, Material = Enum.Material.Metal, Reflectance = 0.08 }), CFrame.new(0, bladeBase + bladeLen / 2, 0))
	local tip = bladeW / math.sqrt(2)
	attach(newPart({ Name = "Tip", Size = Vector3.new(tip, tip, thick), Color = L.Blade, Material = Enum.Material.Metal, Reflectance = 0.08 }), CFrame.new(0, bladeBase + bladeLen, 0) * CFrame.Angles(0, 0, math.rad(45)))

	if L.Edge then
		attach(newPart({ Name = "Rune", Size = Vector3.new(bladeW * 0.22, bladeLen * 0.82, thick + 0.03), Color = L.Edge, Material = Enum.Material.Neon }), CFrame.new(0, bladeBase + bladeLen * 0.45, 0))
	end

	attach(newPart({ Name = "Pommel", Shape = Enum.PartType.Ball, Size = Vector3.new(0.42, 0.42, 0.42), Color = L.Guard, Material = Enum.Material.Metal }), CFrame.new(0, -gripLen / 2 - 0.16, 0))

	if L.Gem then
		attach(newPart({ Name = "Gem", Shape = Enum.PartType.Ball, Size = Vector3.new(0.24, 0.24, 0.24), Color = L.Gem, Material = Enum.Material.Neon }), CFrame.new(0, guardY, -0.2))
	end

	-- swing trail (enabled by the server while swinging)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = Vector3.new(0, bladeBase + 0.2, 0)
	a0.Parent = handle
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, bladeBase + bladeLen, 0)
	a1.Parent = handle
	local trail = Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.18
	trail.LightEmission = 1
	trail.FaceCamera = true
	local trailColor = L.Edge or rarity.Color
	trail.Color = ColorSequence.new(trailColor)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	trail.Enabled = false
	trail.Parent = handle

	model.PrimaryPart = handle
	return model
end

return WeaponModel
