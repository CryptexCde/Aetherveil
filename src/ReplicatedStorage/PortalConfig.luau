-- PORTAL WALKER settings. Tweak numbers here to balance the power.
local Config = {}

-- Paste your Portal Walker game pass ID here once you create it on the Creator Dashboard.
Config.GAMEPASS_ID = 0
Config.FREE_IN_STUDIO = true
-- While GAMEPASS_ID is still 0, EVERYONE gets the power everywhere (Team Test, live servers)
-- so you and your friends can test it. Once you paste a real pass ID, only buyers get it.
Config.FREE_UNTIL_PASS_SET = true
-- People who always get the power for testing, even after the pass exists (add your friend's UserId).
-- The game's owner always has it too.
Config.TESTER_USER_IDS = {}

-- KEYS: Q = Void Portal, E = Teleport, R = Void Lance, F = Singularity

Config.PORTAL_SIZE = 13          -- portal height (they stand on the ground)
Config.MAX_RANGE = 90            -- how far you can throw/place a portal
Config.THROW_TIME = 0.35         -- how long the thrown orb flies

-- Void portal (Q) - dimensional travel. In the world it drags people into the Void;
-- used INSIDE the Void by a Portal Walker, it tears a way back out (anyone can use that one).
Config.VOID_PORTAL_COOLDOWN = 25
Config.VOID_PORTAL_LIFETIME = 4  -- how long the trap portal stays open
Config.PULL_DURATION = 1         -- the first second sucks players in
Config.PULL_RADIUS = 28
Config.PULL_STRENGTH = 55
Config.CAPTURE_RADIUS = 5.5      -- touching distance that drags you into the Void

-- Exit portals inside the Void
Config.ESCAPE_PORTAL_LIFETIME = 10
Config.ESCAPE_IMMUNITY = 5       -- seconds you can't be re-trapped after escaping

-- Rare escape portals that open by themselves (truly rare now)
Config.RANDOM_ESCAPE_CHECK = 30  -- seconds between rolls
Config.RANDOM_ESCAPE_CHANCE = 0.07

-- Safety net: if someone is stuck this long, a portal opens for them. Set to 0 to turn off.
Config.SAFETY_MAX_TRAP_TIME = 900

-- VOID SOULS: every player you banish makes you stronger (resets when you die)
Config.SOUL_MAX = 10
Config.SOUL_SPEED = 0.03      -- +3% walk speed per soul
Config.SOUL_COOLDOWN = 0.05   -- -5% void portal cooldown per soul
Config.SOUL_PULL = 0.06       -- +6% pull range per soul
Config.SOUL_DAMAGE = 0.05     -- +5% damage per soul (used by attacks)

-- TIME IN THE VOID: after this long inside, you slowly turn to grey stone
Config.GREY_START = 300       -- 5 minutes: greying begins
Config.GREY_FULL = 600        -- 10 minutes: fully grey
Config.GREY_SLOW = 0.35       -- fully grey players move 35% slower
Config.PETRIFY_AT = 720       -- 12 minutes: they turn to stone (the statue stays until they leave the server)
-- Grey players STAY grey after escaping, until they die/respawn.

-- Void Lance (R) - a piercing beam of void energy
Config.LANCE_COOLDOWN = 5
Config.LANCE_RANGE = 95
Config.LANCE_DAMAGE = 22

-- Singularity (F) - a mini black hole that drags enemies in, then implodes
Config.SINGULARITY_COOLDOWN = 16
Config.SINGULARITY_RANGE = 75
Config.SINGULARITY_RADIUS = 20
Config.SINGULARITY_DURATION = 2.4
Config.SINGULARITY_TICK = 1.2   -- damage every 0.1s while pulled in
Config.SINGULARITY_BURST = 14   -- damage when it implodes

-- Teleport portals (E) - place one, then its exit
Config.TELEPORT_COOLDOWN = 12
Config.TELEPORT_PENDING_TIME = 5  -- each teleport portal vanishes 5 seconds after you place it
Config.TELEPORT_PAIR_LIFETIME = 5

-- Where the Void Dimension floats (top center of the island)
Config.VOID_CENTER = Vector3.new(6000, 600, 6000)
Config.VOID_RADIUS = 280

-- Sounds (licensed Roblox audio: Pro Sound Effects / APM Music)
Config.SOUNDS = {
	Throw = "rbxassetid://9126228629",
	PortalOpen = "rbxassetid://108306323478967",
	PortalClose = "rbxassetid://9119386959",
	Teleport = "rbxassetid://9126228631",
	Lance = "rbxassetid://9114238609",
	Singularity = "rbxassetid://9119388384",
	Petrify = "rbxassetid://9120479831",
	VoidMusic = "rbxassetid://1844251391",
	VoidAmbience = "rbxassetid://9112775414",
}

return Config
