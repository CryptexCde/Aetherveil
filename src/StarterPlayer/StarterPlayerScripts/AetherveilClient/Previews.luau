-- AETHERVEIL · 3D previews for cards (element emblems and weapon models)
-- Each preview returns a Step(dt, t) function; pages only animate while open.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local WeaponModel = require(Root.Shared.WeaponModel)
local Weapons = require(Root.Config.Weapons)

local Previews = {}

local function viewport(parent, size, position)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Preview"
	vp.BackgroundTransparency = 1
	vp.Size = size
	vp.Position = position or UDim2.new()
	vp.Ambient = Color3.fromRGB(150, 140, 170)
	vp.LightColor = Color3.fromRGB(255, 244, 230)
	vp.LightDirection = Vector3.new(-1, -1.2, -0.6)
	vp.Parent = parent
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp, cam
end

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Glowing orb with a tilted ring and orbiting shards in the element's colours.
function Previews.Element(parent, def, size, position)
	local vp, cam = viewport(parent, size, position)
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local isVoid = def.Id == "Void"

	local core = part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 2.2,
		Color = isVoid and Color3.fromRGB(6, 4, 10) or def.Color,
		Material = isVoid and Enum.Material.SmoothPlastic or Enum.Material.Neon,
	}, world)
	local ring = {}
	local SEGMENTS = 28
	for i = 1, SEGMENTS do
		ring[i] = part({
			Size = Vector3.new(0.07, 0.07, 0.42),
			Color = i % 4 == 0 and def.Color or def.Accent,
			Material = Enum.Material.Neon,
		}, world)
	end
	local shards = {}
	for i = 1, 5 do
		shards[i] = part({
			Size = Vector3.new(0.22, 0.5, 0.22),
			Color = i % 2 == 0 and def.Accent or def.Color,
			Material = Enum.Material.Neon,
		}, world)
	end
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.6, 9.5), Vector3.new(0, 0, 0))

	local function step(_, t)
		local pulse = 1 + math.sin(t * 2.2) * 0.04
		core.Size = Vector3.one * 2.2 * pulse
		local tilt = CFrame.Angles(math.rad(72), 0, math.rad(16))
		for i, seg in ipairs(ring) do
			local a = t * 0.5 + i * (math.pi * 2 / SEGMENTS)
			local p = Vector3.new(math.cos(a) * 2.1, math.sin(a) * 2.1, 0)
			local tangent = Vector3.new(-math.sin(a), math.cos(a), 0)
			seg.CFrame = tilt * CFrame.lookAt(p, p + tangent)
		end
		for i, s in ipairs(shards) do
			local a = t * 0.9 + i * (math.pi * 2 / #shards)
			local r = 2.6 + math.sin(t * 1.3 + i) * 0.15
			s.CFrame = CFrame.new(math.cos(a) * r, math.sin(a * 1.3 + i) * 0.6, math.sin(a) * r) * CFrame.Angles(t + i, t * 0.7, 0)
		end
	end
	step(0, 0)
	return vp, step
end

-- A slowly turning weapon on a soft rarity glow.
function Previews.Weapon(parent, id, size, position)
	local vp, cam = viewport(parent, size, position)
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local model = WeaponModel.Build(id)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	model.Parent = world
	local _, extents = model:GetBoundingBox()
	local length = math.max(extents.X, extents.Y, extents.Z)
	local def = Weapons.Get(id)
	local center = model:GetPivot() * CFrame.new(0, (def.Look.BladeLength - (def.Look.GripLength or 1.1)) / 2, 0)
	local offset = center:Inverse() * model:GetPivot()
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, length * 1.85 + 1), Vector3.new())

	local base = CFrame.Angles(0, 0, math.rad(-38))
	local function step(_, t)
		model:PivotTo(base * CFrame.Angles(0, t * 0.8, 0) * offset)
	end
	step(0, 0)
	return vp, step
end

return Previews
