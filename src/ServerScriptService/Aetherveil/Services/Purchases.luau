-- AETHERVEIL · Game passes and developer products (MarketplaceService)
-- Ownership is checked on the server; currency packs go through ProcessReceipt
-- and are recorded per purchase id so a receipt is never granted twice.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Store = require(Root.Config.Store)
local PlayerData = require(script.Parent.PlayerData)
local Notify = require(script.Parent.Notify)

local Purchases = {}

local changedEvent = Instance.new("BindableEvent")
Purchases.Changed = changedEvent.Event -- (player)

local owned = {} -- [player] = { [passKey] = true }

local portalService
do
	local module = ServerStorage:FindFirstChild("PortalService")
	if module then
		local ok, result = pcall(require, module)
		if ok then
			portalService = result
		end
	end
end
Purchases.PortalService = portalService

function Purchases.Owns(player, key)
	if key == "PortalWalker" then
		return portalService ~= nil and portalService.HasPass(player) == true
	end
	local t = owned[player]
	return t ~= nil and t[key] == true
end

function Purchases.OwnedMap(player)
	local map = {}
	for _, def in ipairs(Store.Gamepasses) do
		map[def.Key] = Purchases.Owns(player, def.Key)
	end
	return map
end

local function refreshOwnership(player)
	owned[player] = owned[player] or {}
	for _, def in ipairs(Store.Gamepasses) do
		if def.Key ~= "PortalWalker" and def.Id ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.Id)
			end)
			if ok and result then
				owned[player][def.Key] = true
			end
		end
	end
	changedEvent:Fire(player)
end

function Purchases.PromptPass(player, key)
	local def = Store.GetPass(key)
	if not def then
		return { ok = false, msg = "That pass doesn't exist." }
	end
	if Purchases.Owns(player, key) then
		return { ok = false, msg = "You already own " .. def.Name .. "." }
	end
	if def.Id == 0 then
		return { ok = false, msg = def.Name .. " isn't on sale yet." }
	end
	MarketplaceService:PromptGamePassPurchase(player, def.Id)
	return { ok = true, prompted = true }
end

function Purchases.PromptProduct(player, key)
	local def = Store.GetProduct(key)
	if not def then
		return { ok = false, msg = "That pack doesn't exist." }
	end
	if def.Id == 0 then
		return { ok = false, msg = def.Name .. " isn't on sale yet." }
	end
	MarketplaceService:PromptProductPurchase(player, def.Id)
	return { ok = true, prompted = true }
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not PlayerData.WaitForLoad(player, 20) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = Store.GetProductById(info.ProductId)
	if not product then
		warn("[Aetherveil] Unknown developer product: " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(info.PurchaseId)
	local data = PlayerData.Get(player)
	if data.Receipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	PlayerData.Update(player, function(d)
		d.Coins += product.Amount
		d.Receipts[purchaseId] = true
		table.insert(d.ReceiptOrder, purchaseId)
		while #d.ReceiptOrder > 100 do
			local oldest = table.remove(d.ReceiptOrder, 1)
			d.Receipts[oldest] = nil
		end
	end)

	if PlayerData.IsPersistent(player) and not PlayerData.Save(player) then
		-- the receipt is recorded in memory, so a retry will be granted without paying out twice
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Notify.Toast(player, ("+%s %s. Thank you!"):format(product.Amount, Store.Currency.Name), "success")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Purchases.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local def = Store.GetPassById(passId)
		if not def then
			return
		end
		if def.Key ~= "PortalWalker" then
			owned[player] = owned[player] or {}
			owned[player][def.Key] = true
		end
		Notify.Toast(player, def.Name .. " unlocked!", "success")
		task.delay(0.5, function()
			changedEvent:Fire(player)
		end)
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(refreshOwnership, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(refreshOwnership, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

return Purchases
