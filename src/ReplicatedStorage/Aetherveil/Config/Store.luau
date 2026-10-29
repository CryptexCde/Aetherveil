-- AETHERVEIL · Store, currency and rewards
-- ============================================================================
-- PASTE YOUR IDS HERE. Create game passes and developer products on the
-- Creator Dashboard, then replace the 0s below. While an Id is 0 the item is
-- shown in the Shop as "Not on sale yet" and cannot be bought.
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = {}

Store.Currency = {
	Name = "Aether Shards",
	Short = "Shards",
	Starting = 300,
}

Store.Rewards = {
	Kill = 30, -- shards for defeating a player
	Passive = 10, -- shards every PassiveInterval seconds while playing
	PassiveInterval = 60,
	VIPMultiplier = 1.5,
}

-- The Portal Walker pass already exists in PortalConfig; it unlocks the Void element.
local portalPassId = 0
local voidMusic = ""
local portalConfig = ReplicatedStorage:FindFirstChild("PortalConfig")
if portalConfig then
	local ok, cfg = pcall(require, portalConfig)
	if ok and type(cfg) == "table" then
		portalPassId = cfg.GAMEPASS_ID or 0
		voidMusic = cfg.SOUNDS and cfg.SOUNDS.VoidMusic or ""
	end
end

Store.MenuMusicId = voidMusic -- swap for your own menu track if you like

Store.Gamepasses = {
	{
		Key = "VIP",
		Name = "VIP",
		Id = 0, -- PASTE GAME PASS ID
		Description = "+50% Aether Shards from every source and a golden VIP title.",
		Color = Color3.fromRGB(255, 196, 70),
	},
	{
		Key = "ExtraSlots",
		Name = "Extra Equipment Slot",
		Id = 0, -- PASTE GAME PASS ID
		Description = "Carry two weapons into battle at once.",
		Color = Color3.fromRGB(120, 200, 255),
	},
	{
		Key = "ElementBoost",
		Name = "Element Boost",
		Id = 0, -- PASTE GAME PASS ID
		Description = "+15% damage on all elemental abilities.",
		Color = Color3.fromRGB(255, 120, 60),
	},
	{
		Key = "ExclusiveWeapons",
		Name = "Exclusive Armory",
		Id = 0, -- PASTE GAME PASS ID
		Description = "Lets you buy Mythic weapons in the Shop, starting with Oblivion's Edge.",
		Color = Color3.fromRGB(255, 70, 130),
	},
	{
		Key = "Cosmetics",
		Name = "Aether Aura",
		Id = 0, -- PASTE GAME PASS ID
		Description = "A shimmering aura and trail in your element's colours.",
		Color = Color3.fromRGB(150, 255, 220),
	},
	{
		Key = "PortalWalker",
		Name = "Portal Walker",
		Id = portalPassId, -- set in ReplicatedStorage.PortalConfig.GAMEPASS_ID
		Description = "Unlocks the Void element and its four dimensional powers.",
		Color = Color3.fromRGB(176, 96, 255),
	},
}

Store.Products = {
	{ Key = "Pouch", Name = "Pouch of Shards", Amount = 500, Id = 0 }, -- PASTE DEVELOPER PRODUCT ID
	{ Key = "Satchel", Name = "Satchel of Shards", Amount = 1200, Bonus = "+20% bonus", Id = 0 }, -- PASTE DEVELOPER PRODUCT ID
	{ Key = "Chest", Name = "Chest of Shards", Amount = 2600, Bonus = "+30% bonus", Id = 0 }, -- PASTE DEVELOPER PRODUCT ID
	{ Key = "Hoard", Name = "Dragon's Hoard", Amount = 5500, Bonus = "+38% bonus", Id = 0 }, -- PASTE DEVELOPER PRODUCT ID
	{ Key = "Vault", Name = "Vault of the Veil", Amount = 12000, Bonus = "Best value", Id = 0 }, -- PASTE DEVELOPER PRODUCT ID
}

function Store.GetPass(key)
	for _, def in ipairs(Store.Gamepasses) do
		if def.Key == key then
			return def
		end
	end
	return nil
end

function Store.GetPassById(id)
	if id == 0 then
		return nil
	end
	for _, def in ipairs(Store.Gamepasses) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

function Store.GetProduct(key)
	for _, def in ipairs(Store.Products) do
		if def.Key == key then
			return def
		end
	end
	return nil
end

function Store.GetProductById(id)
	if id == 0 then
		return nil
	end
	for _, def in ipairs(Store.Products) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

return Store
