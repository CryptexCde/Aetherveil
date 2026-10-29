-- AETHERVEIL · Weapons
-- To add a weapon: add an entry to Weapons.List and its id to Weapons.Order.
-- Price is in Aether Shards. Exclusive = true means it needs the "ExclusiveWeapons" game pass to buy.
-- Look controls the 3D model (used for the tool and the menu previews).

local Weapons = {}

Weapons.Rarities = {
	Common = { Order = 1, Name = "Common", Color = Color3.fromRGB(176, 176, 186) },
	Uncommon = { Order = 2, Name = "Uncommon", Color = Color3.fromRGB(96, 214, 120) },
	Rare = { Order = 3, Name = "Rare", Color = Color3.fromRGB(80, 160, 255) },
	Epic = { Order = 4, Name = "Epic", Color = Color3.fromRGB(186, 96, 255), Shimmer = true },
	Legendary = { Order = 5, Name = "Legendary", Color = Color3.fromRGB(255, 176, 50), Shimmer = true },
	Mythic = { Order = 6, Name = "Mythic", Color = Color3.fromRGB(255, 70, 130), Shimmer = true },
}

Weapons.StarterWeapon = "Rustblade"

-- How the tool sits in the hand (adjust if a model points the wrong way).
Weapons.Grip = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)

Weapons.Order = {
	"Rustblade",
	"Ironoath",
	"EmberCutlass",
	"Tidefang",
	"Stormcaller",
	"Gravewarden",
	"Aetherbrand",
	"Veilrender",
	"OblivionsEdge",
}

local metal = Color3.fromRGB(150, 146, 140)
local darkMetal = Color3.fromRGB(70, 62, 56)
local leather = Color3.fromRGB(52, 32, 20)

Weapons.List = {
	Rustblade = {
		Name = "Rustblade",
		Rarity = "Common",
		Price = 0,
		Starter = true,
		Description = "A pitted blade pulled from an old battlefield. Every hero starts somewhere.",
		Damage = 14,
		Cooldown = 0.55,
		Range = 7,
		Look = { BladeLength = 3.4, BladeWidth = 0.42, Blade = Color3.fromRGB(140, 110, 90), Guard = darkMetal, GuardWidth = 1.3, Grip = leather },
	},
	Ironoath = {
		Name = "Ironoath Longsword",
		Rarity = "Common",
		Price = 250,
		Description = "Honest steel, forged for knights who keep their word.",
		Damage = 16,
		Cooldown = 0.55,
		Range = 7.5,
		Look = { BladeLength = 3.9, BladeWidth = 0.4, Blade = metal, Guard = darkMetal, GuardWidth = 1.5, Grip = leather },
	},
	EmberCutlass = {
		Name = "Ember Cutlass",
		Rarity = "Uncommon",
		Price = 600,
		Description = "Its edge never cools. Leaves a trail of sparks with every swing.",
		Damage = 18,
		Cooldown = 0.5,
		Range = 7,
		Look = { BladeLength = 3.4, BladeWidth = 0.5, Blade = Color3.fromRGB(120, 60, 40), Edge = Color3.fromRGB(255, 120, 40), Guard = Color3.fromRGB(160, 110, 50), GuardWidth = 1.2, Grip = leather },
	},
	Tidefang = {
		Name = "Tidefang Saber",
		Rarity = "Uncommon",
		Price = 600,
		Description = "Carved from the tooth of a leviathan. Cold, light and quick.",
		Damage = 15,
		Cooldown = 0.42,
		Range = 7,
		Look = { BladeLength = 3.6, BladeWidth = 0.36, Blade = Color3.fromRGB(190, 230, 240), Edge = Color3.fromRGB(60, 190, 255), Guard = Color3.fromRGB(40, 90, 130), GuardWidth = 1.2, Grip = Color3.fromRGB(20, 40, 60) },
	},
	Stormcaller = {
		Name = "Stormcaller Blade",
		Rarity = "Rare",
		Price = 1500,
		Description = "Thunder answers whoever holds it. The blade hums before a storm.",
		Damage = 20,
		Cooldown = 0.48,
		Range = 7.5,
		Look = { BladeLength = 3.9, BladeWidth = 0.44, Blade = Color3.fromRGB(60, 60, 80), Edge = Color3.fromRGB(255, 226, 80), Guard = Color3.fromRGB(120, 110, 160), GuardWidth = 1.6, Grip = Color3.fromRGB(30, 26, 50), Gem = Color3.fromRGB(255, 226, 80) },
	},
	Gravewarden = {
		Name = "Gravewarden Greatsword",
		Rarity = "Rare",
		Price = 1800,
		Description = "A slab of black iron that once guarded a king's tomb. Slow, brutal, final.",
		Damage = 30,
		Cooldown = 0.9,
		Range = 9,
		Look = { BladeLength = 4.8, BladeWidth = 0.7, Blade = Color3.fromRGB(46, 44, 50), Edge = Color3.fromRGB(120, 255, 170), Guard = Color3.fromRGB(30, 28, 34), GuardWidth = 2.1, Grip = Color3.fromRGB(26, 20, 18), GripLength = 1.5 },
	},
	Aetherbrand = {
		Name = "Aetherbrand",
		Rarity = "Epic",
		Price = 4000,
		Description = "Forged where the veil is thinnest. Its runes glow brighter near magic.",
		Damage = 24,
		Cooldown = 0.45,
		Range = 8,
		Look = { BladeLength = 4.2, BladeWidth = 0.46, Blade = Color3.fromRGB(220, 214, 240), Edge = Color3.fromRGB(150, 230, 255), Guard = Color3.fromRGB(200, 170, 100), GuardWidth = 1.7, Grip = Color3.fromRGB(60, 40, 90), Gem = Color3.fromRGB(150, 230, 255) },
	},
	Veilrender = {
		Name = "Veilrender",
		Rarity = "Legendary",
		Price = 9000,
		Description = "The sword that first cut the veil between worlds. Reality flickers along its edge.",
		Damage = 28,
		Cooldown = 0.42,
		Range = 8.5,
		Look = { BladeLength = 4.5, BladeWidth = 0.5, Blade = Color3.fromRGB(24, 16, 36), Edge = Color3.fromRGB(196, 110, 255), Guard = Color3.fromRGB(220, 190, 120), GuardWidth = 1.9, Grip = Color3.fromRGB(40, 20, 60), Gem = Color3.fromRGB(255, 92, 224) },
	},
	OblivionsEdge = {
		Name = "Oblivion's Edge",
		Rarity = "Mythic",
		Price = 15000,
		Exclusive = true,
		Description = "A blade of pure absence. Only members of the Exclusive Armory may claim it.",
		Damage = 32,
		Cooldown = 0.4,
		Range = 9,
		Look = { BladeLength = 4.8, BladeWidth = 0.56, Blade = Color3.fromRGB(8, 6, 12), Edge = Color3.fromRGB(255, 70, 130), Guard = Color3.fromRGB(255, 70, 130), GuardWidth = 2, Grip = Color3.fromRGB(10, 8, 14), Gem = Color3.fromRGB(255, 255, 255) },
	},
}

for id, def in pairs(Weapons.List) do
	def.Id = id
end

function Weapons.Get(id)
	if type(id) ~= "string" then
		return nil
	end
	return Weapons.List[id]
end

function Weapons.RarityOf(def)
	return Weapons.Rarities[def.Rarity] or Weapons.Rarities.Common
end

return Weapons
