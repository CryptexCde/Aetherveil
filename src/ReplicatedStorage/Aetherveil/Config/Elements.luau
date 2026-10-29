-- AETHERVEIL · Elements
-- To add an element: add an entry to Elements.List and put its id in Elements.Order.
-- Unlock types:
--   { Type = "Free" }                         always unlocked
--   { Type = "Coins", Price = 750 }           bought with Aether Shards in the Elements menu
--   { Type = "Gamepass", Pass = "PassKey" }   unlocked by a game pass from Config/Store
-- Ability types (handled by ServerScriptService.Aetherveil.Services.ElementAbilities):
--   Bolt  = projectile        (Damage, Speed, Range, Splash, Size)
--   Beam  = instant strike    (Damage, Range, Splash)
--   Nova  = burst around you  (Damage, Radius, Knockback, HealSelf)
--   Dash  = quick dash        (Speed, Duration)
-- An element with Kit = "PortalWalker" uses the existing Portal Walker powers instead.

local Elements = {}

Elements.Order = { "Fire", "Water", "Earth", "Air", "Lightning", "Void" }

Elements.List = {
	Fire = {
		Name = "Fire",
		Title = "Pyromancer",
		Color = Color3.fromRGB(255, 120, 40),
		Accent = Color3.fromRGB(255, 214, 130),
		Description = "Roaring flame given form. Hurl fireballs, erupt in a blazing nova and dash on a trail of embers.",
		Unlock = { Type = "Free" },
		Abilities = {
			{ Id = "Bolt", Key = "Q", Name = "Fireball", Type = "Bolt", Cooldown = 2.5, Damage = 18, Speed = 120, Range = 140, Splash = 6, Size = 1.8 },
			{ Id = "Nova", Key = "E", Name = "Inferno Nova", Type = "Nova", Cooldown = 9, Damage = 26, Radius = 16, Knockback = 50 },
			{ Id = "Dash", Key = "R", Name = "Ember Dash", Type = "Dash", Cooldown = 6, Speed = 110, Duration = 0.22 },
		},
	},
	Water = {
		Name = "Water",
		Title = "Tidecaller",
		Color = Color3.fromRGB(60, 190, 255),
		Accent = Color3.fromRGB(200, 245, 255),
		Description = "The patient strength of the deep. Crash enemies away with tidal surges that also mend your wounds.",
		Unlock = { Type = "Free" },
		Abilities = {
			{ Id = "Bolt", Key = "Q", Name = "Tide Orb", Type = "Bolt", Cooldown = 2.2, Damage = 15, Speed = 100, Range = 130, Splash = 8, Size = 2 },
			{ Id = "Nova", Key = "E", Name = "Tidal Surge", Type = "Nova", Cooldown = 10, Damage = 18, Radius = 20, Knockback = 85, HealSelf = 15 },
			{ Id = "Dash", Key = "R", Name = "Riptide", Type = "Dash", Cooldown = 6, Speed = 105, Duration = 0.24 },
		},
	},
	Earth = {
		Name = "Earth",
		Title = "Stonewarden",
		Color = Color3.fromRGB(176, 140, 80),
		Accent = Color3.fromRGB(150, 220, 110),
		Description = "Unbreakable and slow to anger. Heavy boulders and ground-splitting quakes crush anything in your path.",
		Unlock = { Type = "Coins", Price = 750 },
		Abilities = {
			{ Id = "Bolt", Key = "Q", Name = "Boulder", Type = "Bolt", Cooldown = 3.5, Damage = 26, Speed = 80, Range = 120, Splash = 7, Size = 2.6, Material = "Slate" },
			{ Id = "Nova", Key = "E", Name = "Quake", Type = "Nova", Cooldown = 11, Damage = 32, Radius = 18, Knockback = 40 },
			{ Id = "Dash", Key = "R", Name = "Rockslide", Type = "Dash", Cooldown = 7, Speed = 90, Duration = 0.25 },
		},
	},
	Air = {
		Name = "Air",
		Title = "Skydancer",
		Color = Color3.fromRGB(200, 236, 255),
		Accent = Color3.fromRGB(255, 255, 255),
		Description = "Faster than sight. Slice with gale blades, hurl foes skyward with cyclones and vanish on the wind.",
		Unlock = { Type = "Coins", Price = 750 },
		Abilities = {
			{ Id = "Bolt", Key = "Q", Name = "Gale Blade", Type = "Bolt", Cooldown = 1.6, Damage = 12, Speed = 180, Range = 150, Splash = 3, Size = 1.2 },
			{ Id = "Nova", Key = "E", Name = "Cyclone", Type = "Nova", Cooldown = 8, Damage = 14, Radius = 22, Knockback = 110 },
			{ Id = "Dash", Key = "R", Name = "Tailwind", Type = "Dash", Cooldown = 4, Speed = 160, Duration = 0.2 },
		},
	},
	Lightning = {
		Name = "Lightning",
		Title = "Stormbringer",
		Color = Color3.fromRGB(255, 226, 80),
		Accent = Color3.fromRGB(170, 140, 255),
		Description = "Strike first, strike once. Instant chain bolts, a deafening thunderclap and a flash-step nobody can follow.",
		Unlock = { Type = "Coins", Price = 1500 },
		Abilities = {
			{ Id = "Bolt", Key = "Q", Name = "Chain Bolt", Type = "Beam", Cooldown = 3, Damage = 20, Range = 120, Splash = 5 },
			{ Id = "Nova", Key = "E", Name = "Thunderclap", Type = "Nova", Cooldown = 9, Damage = 22, Radius = 15, Knockback = 45 },
			{ Id = "Dash", Key = "R", Name = "Flash Step", Type = "Dash", Cooldown = 5, Speed = 200, Duration = 0.15 },
		},
	},
	Void = {
		Name = "Void",
		Title = "Portal Walker",
		Color = Color3.fromRGB(176, 96, 255),
		Accent = Color3.fromRGB(255, 92, 224),
		Description = "Nothing escapes. Tear open portals that drag enemies into the Void, teleport at will and summon singularities.",
		Unlock = { Type = "Gamepass", Pass = "PortalWalker" },
		Kit = "PortalWalker",
		Abilities = {
			{ Id = "Void", Key = "Q", Name = "Void Portal", Type = "Kit" },
			{ Id = "Teleport", Key = "E", Name = "Teleport", Type = "Kit" },
			{ Id = "Lance", Key = "R", Name = "Void Lance", Type = "Kit" },
			{ Id = "Singularity", Key = "F", Name = "Singularity", Type = "Kit" },
		},
	},
}

for id, def in pairs(Elements.List) do
	def.Id = id
end

function Elements.Get(id)
	if type(id) ~= "string" then
		return nil
	end
	return Elements.List[id]
end

function Elements.GetAbility(def, abilityId)
	if not def then
		return nil
	end
	for _, ability in ipairs(def.Abilities) do
		if ability.Id == abilityId then
			return ability
		end
	end
	return nil
end

return Elements
