-- AETHERVEIL · Menu scene builder
-- Run once in Studio (Edit mode, command bar or plugin) to (re)build the title-screen world:
-- a terrain valley with jagged mountains and a cliff, two giant swords planted in the ground,
-- dirt mounds, cracked earth, rocks and the camera markers the menu uses.
-- The client recolours everything per element at runtime (see AetherveilClient/MenuScene).

local Terrain = workspace.Terrain

local ORIGIN = Vector3.new(-6000, 0, -6000) -- far away from the playable map
local S = 2.5 -- concept units -> studs
local RES = 4

---------------------------------------------------------------- height field (concept units)
local function ss(a, b, v)
	local q = math.clamp((v - a) / (b - a), 0, 1)
	return q * q * (3 - 2 * q)
end

local function rid(x, y)
	local s, a, f, w = 0, 0.5, 1, 1
	for k = 0, 6 do
		local n = 1 - math.abs(math.clamp(math.noise(x * f + k * 7.13, y * f + k * 3.31, 0.37) * 1.7, -1, 1))
		n *= n
		s += a * n * w
		w = math.min(1, n * 1.6)
		f *= 2.05
		a *= 0.5
	end
	return s
end

local function hgt0(X, Z)
	local d = ss(30, -150, Z)
	local vw = 10 + 38 * d
	local val = 1 - math.exp(-(((X + 4 + math.sin(Z * 0.04) * 8) / vw) ^ 2))
	local h = rid(X * 0.022 + 3.3, Z * 0.022 + 1.7) * (4 + 60 * d) * (0.18 + 0.82 * val)
	h += ss(14, 40, X) * ss(45, -5, Z) * (34 + rid(X * 0.05 + 0.5, Z * 0.05) * 30)
	h += ss(-14, -40, X) * ss(40, 0, Z) * (6 + rid(X * 0.06 + 9.1, Z * 0.06) * 9)
	h += math.noise(X * 0.4 + 0.1, Z * 0.4 + 0.2, 1.7) * 0.8
	return h
end

local PADS = { { X = -21, Z = 4, R = 11 }, { X = -9, Z = -12, R = 6 } }
for _, p in ipairs(PADS) do
	p.H = hgt0(p.X, p.Z)
end
local function hgt(X, Z)
	local h = hgt0(X, Z)
	for _, p in ipairs(PADS) do
		local q = math.exp(-(((X - p.X) ^ 2) + ((Z - p.Z) ^ 2)) / (p.R * p.R))
		h += (p.H - h) * q
	end
	return h
end

-- world helpers (studs)
local function heightAt(wx, wz)
	return ORIGIN.Y + hgt((wx - ORIGIN.X) / S, (wz - ORIGIN.Z) / S) * S
end
local function W(Xc, Yc, Zc)
	return ORIGIN + Vector3.new(Xc * S, Yc * S, Zc * S)
end

---------------------------------------------------------------- terrain
local X0, X1 = -150, 150
local Z0, Z1 = -200, 70
local minC = Vector3.new(ORIGIN.X + X0 * S, ORIGIN.Y - 16, ORIGIN.Z + Z0 * S)
local maxC = Vector3.new(ORIGIN.X + X1 * S, ORIGIN.Y + 360, ORIGIN.Z + Z1 * S)
Terrain:FillBlock(CFrame.new((minC + maxC) / 2), maxC - minC + Vector3.new(16, 16, 16), Enum.Material.Air)
task.wait()

local nx = math.ceil((maxC.X - minC.X) / RES)
local nz = math.ceil((maxC.Z - minC.Z) / RES)
local maxH = 0
local heights = {}
for i = 0, nx + 1 do
	heights[i] = {}
	for k = 0, nz + 1 do
		local wx = minC.X + (i - 0.5) * RES
		local wz = minC.Z + (k - 0.5) * RES
		local h = heightAt(wx, wz) - ORIGIN.Y
		heights[i][k] = h
		if h > maxH then
			maxH = h
		end
	end
	if i % 20 == 0 then
		task.wait()
	end
end
local ny = math.ceil((maxH + 20) / RES)

local SLICE = 16
for i0 = 1, nx, SLICE do
	local cols = math.min(SLICE, nx - i0 + 1)
	local mats, occs = {}, {}
	for a = 1, cols do
		local i = i0 + a - 1
		mats[a], occs[a] = {}, {}
		for y = 1, ny do
			mats[a][y], occs[a][y] = {}, {}
		end
		for k = 1, nz do
			local h = heights[i][k]
			local dx = (heights[i + 1][k] - heights[i - 1][k]) / (2 * RES)
			local dz = (heights[i][k + 1] - heights[i][k - 1]) / (2 * RES)
			local slope = math.sqrt(dx * dx + dz * dz)
			local wx = minC.X + (i - 0.5) * RES
			local wz = minC.Z + (k - 0.5) * RES
			local patch = math.noise(wx * 0.03, wz * 0.03, 4.2)
			local top
			if slope > 1.0 then
				top = Enum.Material.Rock
			elseif slope > 0.6 then
				top = Enum.Material.Slate
			elseif h > 110 then
				top = Enum.Material.Ground
			elseif patch > 0.18 then
				top = Enum.Material.Ground
			else
				top = Enum.Material.Grass
			end
			for y = 1, ny do
				local yb = -16 + (y - 1) * RES
				local occ = math.clamp((h - yb) / RES, 0, 1)
				local depth = h - (yb + RES)
				local m = Enum.Material.Air
				if occ > 0 then
					m = depth > 8 and Enum.Material.Rock or top
				end
				mats[a][y][k] = m
				occs[a][y][k] = occ
			end
		end
	end
	local rmin = Vector3.new(minC.X + (i0 - 1) * RES, -16 + ORIGIN.Y, minC.Z)
	local rmax = rmin + Vector3.new(cols * RES, ny * RES, nz * RES)
	Terrain:WriteVoxels(Region3.new(rmin, rmax), RES, mats, occs)
	task.wait()
end

---------------------------------------------------------------- scene objects
local old = workspace:FindFirstChild("MenuScene")
if old then
	old:Destroy()
end
local scene = Instance.new("Model")
scene.Name = "MenuScene"
scene.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent or scene
	return p
end

local steel = Color3.fromRGB(150, 146, 138)
local darkSteel = Color3.fromRGB(64, 56, 50)
local leather = Color3.fromRGB(40, 26, 16)

local function sword(name, L, w, Xc, Zc, tilt, yaw, sink)
	L *= S
	w *= S
	local model = Instance.new("Model")
	model.Name = name
	local ground = heightAt(ORIGIN.X + Xc * S, ORIGIN.Z + Zc * S)
	local base = CFrame.new(ORIGIN.X + Xc * S, ground - sink * S, ORIGIN.Z + Zc * S) * CFrame.Angles(0, yaw, tilt)
	local function at(offset)
		return base * offset
	end
	local th = w * 0.26
	-- blade (tip at the origin, pointing down into the ground)
	part({ Name = "Blade", Size = Vector3.new(w * 2, L * 0.86, th), CFrame = at(CFrame.new(0, L * 0.14 + L * 0.43, 0)), Color = steel, Material = Enum.Material.Metal, Reflectance = 0.06 }, model)
	local tipSize = w * 2 / math.sqrt(2)
	part({ Name = "Tip", Size = Vector3.new(tipSize, tipSize, th), CFrame = at(CFrame.new(0, L * 0.14, 0) * CFrame.Angles(0, 0, math.rad(45))), Color = steel, Material = Enum.Material.Metal }, model)
	part({ Name = "Fuller", Size = Vector3.new(w * 0.32, L * 0.68, th + 0.2), CFrame = at(CFrame.new(0, L * 0.62, 0)), Color = darkSteel, Material = Enum.Material.Metal }, model)
	for k = 0, 3 do
		local side = (k % 2 == 0) and 1 or -1
		part({ Name = "Nick", Size = Vector3.new(w * 0.5, w * 0.35, th + 0.3), CFrame = at(CFrame.new(side * w * 0.95, L * (0.3 + k * 0.15), 0) * CFrame.Angles(0, 0, 0.6)), Color = darkSteel, Material = Enum.Material.Metal }, model)
	end
	-- crossguard
	part({ Name = "Guard", Size = Vector3.new(w * 6.5, w * 0.75, w * 1.0), CFrame = at(CFrame.new(0, L + w * 0.35, 0)), Color = darkSteel, Material = Enum.Material.Metal }, model)
	for _, side in ipairs({ -1, 1 }) do
		local spike = part({ Name = "GuardSpike", Shape = Enum.PartType.Ball, Size = Vector3.one * w * 1.1, CFrame = at(CFrame.new(side * w * 3.5, L + w * 0.55, 0)), Color = darkSteel, Material = Enum.Material.Metal }, model)
		spike.Size = Vector3.one * w * 1.1
	end
	-- grip, rings, pommel
	local gripLen = L * 0.17
	part({ Name = "Grip", Shape = Enum.PartType.Cylinder, Size = Vector3.new(gripLen, w * 0.82, w * 0.82), CFrame = at(CFrame.new(0, L + w * 0.75 + gripLen / 2, 0) * CFrame.Angles(0, 0, math.rad(90))), Color = leather, Material = Enum.Material.Fabric }, model)
	for k = 0, 5 do
		part({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(w * 0.14, w * 0.96, w * 0.96), CFrame = at(CFrame.new(0, L + w * 0.9 + k * gripLen / 6, 0) * CFrame.Angles(0, 0, math.rad(90))), Color = darkSteel, Material = Enum.Material.Metal }, model)
	end
	part({ Name = "Pommel", Shape = Enum.PartType.Ball, Size = Vector3.one * w * 1.5, CFrame = at(CFrame.new(0, L + w * 0.75 + gripLen + w * 0.5, 0)), Color = darkSteel, Material = Enum.Material.Metal }, model)
	local gem = part({ Name = "Gem", Shape = Enum.PartType.Ball, Size = Vector3.one * w * 0.8, CFrame = at(CFrame.new(0, L + w * 0.35, w * 0.55)), Color = Color3.fromRGB(194, 124, 255), Material = Enum.Material.Neon }, model)
	local light = Instance.new("PointLight")
	light.Name = "GemLight"
	light.Range = L * 0.6
	light.Brightness = 2.5
	light.Color = gem.Color
	light.Parent = gem
	model.Parent = scene

	-- earth mound, cracked ring and broken rocks around the blade
	local entry = base * Vector3.new(0, sink * S, 0)
	local gy = heightAt(entry.X, entry.Z)
	Terrain:FillBall(Vector3.new(entry.X, gy - w * 2.2, entry.Z), w * 4.6, Enum.Material.Mud)
	Terrain:FillCylinder(CFrame.new(entry.X, gy - 0.6, entry.Z), 2, w * 6.5, Enum.Material.Slate)
	Terrain:FillBall(Vector3.new(entry.X, gy - w * 2.6, entry.Z), w * 4.4, Enum.Material.Ground)
	local rng = Random.new(math.floor(Xc * 100))
	for k = 1, 16 do
		local a = k * 2.4 + rng:NextNumber()
		local r = w * (1.6 + rng:NextNumber() * 5)
		local sz = w * (0.35 + rng:NextNumber() * 1.1)
		local px, pz = entry.X + math.cos(a) * r, entry.Z + math.sin(a) * r
		part({
			Name = "Rock",
			Size = Vector3.new(sz * 1.3, sz * 0.7, sz),
			CFrame = CFrame.new(px, heightAt(px, pz) + sz * 0.1, pz) * CFrame.Angles(rng:NextNumber() * 0.8, rng:NextNumber() * 6.3, rng:NextNumber() * 0.8),
			Color = Color3.fromRGB(70, 64, 72),
			Material = Enum.Material.Slate,
		}, model)
	end
	return model
end

sword("GreatSword", 24, 1.35, -21, 4, -0.2, 0.4, 4.5)
sword("FallenSword", 11, 0.55, -9, -12, 0.2, -0.5, 2.2)

-- camera markers (low, near the ground, looking up past the great sword)
local camGround = heightAt(ORIGIN.X - 6 * S, ORIGIN.Z + 40 * S)
part({ Name = "MenuCamera", Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(ORIGIN.X - 5 * S, camGround + 2.2 * S, ORIGIN.Z + 40 * S) }, scene)
part({ Name = "MenuFocus", Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(ORIGIN.X - 6 * S, camGround + 20 * S, ORIGIN.Z - 60 * S) }, scene)

scene.Parent = workspace
return ("Menu scene built: %d x %d voxels, peak %.0f studs"):format(nx, nz, maxH)
