-- AETHERVEIL · Shop: Weapons (shards), Game Passes and Currency (Robux)
-- The client only asks; the server checks prices, ownership and receipts.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Weapons = require(Root.Config.Weapons)
local Store = require(Root.Config.Store)
local Client = script.Parent.Parent
local Theme = require(Client.Theme)
local UI = require(Client.UIKit)
local Animator = require(Client.Animator)
local Sound = require(Client.Sound)
local State = require(Client.State)
local Overlay = require(Client.Overlay)
local WeaponCard = require(script.Parent.WeaponCard)

local C = Theme.Colors

local ShopPage = {}
ShopPage.__index = ShopPage

local TABS = { "Weapons", "Gamepasses", "Currency" }
local TAB_TEXT = { Weapons = "WEAPONS", Gamepasses = "GAME PASSES", Currency = "AETHER SHARDS" }

local priceCache = {}
local function fetchPrice(id, infoType, callback)
	if id == 0 then
		callback(nil)
		return
	end
	local key = tostring(infoType) .. id
	if priceCache[key] then
		callback(priceCache[key])
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and info and info.PriceInRobux then
			priceCache[key] = info.PriceInRobux
			callback(info.PriceInRobux)
		else
			callback(nil)
		end
	end)
end

function ShopPage.new(canvas, app)
	local self = setmetatable({}, ShopPage)
	self.App = app
	self.WeaponCards = {}
	self.PassCards = {}
	self.Tab = "Weapons"

	local page = UI.Page({
		Parent = canvas,
		Name = "Shop",
		Title = "Shop",
		Subtitle = "Enchanted weapons, game passes and Aether Shards.",
		OnBack = function()
			app:Back()
		end,
	})
	self.Page = page
	local _, amount = UI.ShardCounter({ Parent = page.Root, Position = UDim2.fromOffset(1548, 40), AlignRight = true })
	self.Shards = amount

	---------------------------------------------------------------- tabs
	local tabBar = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = page.Content })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabBar })
	self.TabButtons = {}
	for i, tab in ipairs(TABS) do
		self.TabButtons[tab] = UI.Button({
			Parent = tabBar,
			LayoutOrder = i,
			Style = "secondary",
			Color = C.Gold,
			Text = TAB_TEXT[tab],
			TextSize = 17,
			Size = UDim2.fromOffset(210, 44),
			OnClick = function()
				self:SetTab(tab)
			end,
		})
	end

	self.Panels = {}
	local function panel(name, direction)
		local s = UI.new("ScrollingFrame", {
			Name = name,
			Position = UDim2.fromOffset(0, 60),
			Size = UDim2.new(1, 0, 1, -60),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = direction == "X" and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
			ScrollingDirection = direction == "X" and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
			Visible = false,
			Parent = page.Content,
		})
		UI.padding(s, 4, 12, 14, 20)
		UI.SmoothScroll(s, direction == "X")
		self.Panels[name] = s
		return s
	end

	---------------------------------------------------------------- weapons
	local weaponsPanel = panel("Weapons", "Y")
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(WeaponCard.Size.X, WeaponCard.Size.Y),
		CellPadding = UDim2.fromOffset(16, 22),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = weaponsPanel,
	})
	local order = 0
	for _, id in ipairs(Weapons.Order) do
		local def = Weapons.Get(id)
		if not def.Starter then
			order += 1
			self.WeaponCards[id] = WeaponCard.new({
				Parent = weaponsPanel,
				Id = id,
				LayoutOrder = order,
				OnAction = function(d)
					self:BuyWeapon(d)
				end,
			})
		end
	end

	---------------------------------------------------------------- game passes
	local passPanel = panel("Gamepasses", "Y")
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(470, 210),
		CellPadding = UDim2.fromOffset(18, 18),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = passPanel,
	})
	for i, def in ipairs(Store.Gamepasses) do
		self.PassCards[def.Key] = self:BuildPassCard(passPanel, def, i)
	end

	---------------------------------------------------------------- currency
	local currencyPanel = panel("Currency", "X")
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = currencyPanel })
	for i, def in ipairs(Store.Products) do
		self:BuildPackCard(currencyPanel, def, i)
	end

	State.Changed:Connect(function(data)
		self:Refresh(data)
	end)
	if State.Data then
		self:Refresh(State.Data)
	end
	self:SetTab("Weapons")
	return self
end

function ShopPage:BuildPassCard(parent, def, order)
	local card = UI.Card({ Parent = parent, Name = def.Key, Size = UDim2.fromOffset(470, 210), Color = def.Color, LayoutOrder = order })
	local body = card.Body
	local emblem = UI.new("Frame", { Position = UDim2.fromOffset(26, 34), Size = UDim2.fromOffset(110, 110), BackgroundTransparency = 1, Parent = body })
	local outer = UI.diamond({ Parent = emblem, Size = 76, Color = def.Color, Core = false })
	outer.BackgroundColor3 = C.Ink
	local inner = UI.diamond({ Parent = emblem, Size = 44, Color = def.Color, Fill = def.Color })
	inner.BackgroundTransparency = 0.55
	UI.label({
		Position = UDim2.fromOffset(160, 26),
		Size = UDim2.new(1, -180, 0, 34),
		FontFace = Theme.Fonts.Display,
		Text = string.upper(def.Name),
		TextSize = 26,
		TextColor3 = def.Color:Lerp(Color3.new(1, 1, 1), 0.4),
		Parent = body,
	})
	UI.label({
		Position = UDim2.fromOffset(160, 64),
		Size = UDim2.new(1, -184, 0, 66),
		FontFace = Theme.Fonts.Body,
		Text = def.Description,
		TextSize = 17,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = C.TextDim,
		Parent = body,
	})
	local price = UI.label({
		Position = UDim2.fromOffset(160, 150),
		Size = UDim2.fromOffset(120, 40),
		FontFace = Theme.Fonts.Number,
		Text = "",
		TextSize = 18,
		TextColor3 = C.Gold,
		Parent = body,
	})
	local button = UI.Button({
		Parent = body,
		Style = "primary",
		Color = def.Color,
		Text = "BUY",
		TextSize = 17,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(170, 44),
		OnClick = function()
			local res = State.Request("PromptPass", def.Key)
			if not res.ok then
				Overlay.Toast(res.msg, "error")
			end
		end,
	})
	if def.Id == 0 then
		price.Text = "Not on sale yet"
		price.TextColor3 = C.TextFaint
		price.FontFace = Theme.Fonts.Body
		price.Size = UDim2.fromOffset(150, 40)
	else
		price.Text = "…"
		fetchPrice(def.Id, Enum.InfoType.GamePass, function(robux)
			price.Text = robux and ("R$ " .. UI.FormatNumber(robux)) or "Unavailable"
		end)
	end
	return { Card = card, Button = button, Def = def, Price = price }
end

function ShopPage:BuildPackCard(parent, def, order)
	local card = UI.Card({ Parent = parent, Name = def.Key, Size = UDim2.fromOffset(276, 470), Color = C.Accent, LayoutOrder = order })
	local body = card.Body
	local wash = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 200), BackgroundColor3 = C.Accent, BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = body })
	UI.gradient(wash, nil, NumberSequence.new(0.2, 1), 90)

	-- a pile of shards that grows with the pack size
	local pile = UI.new("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 160), BackgroundTransparency = 1, Parent = body })
	local count = 1 + order * 2
	for i = 1, count do
		local row = math.floor((i - 1) / 4)
		local col = (i - 1) % 4
		local size = 40 - row * 6
		local x = 0.5 + (col - 1.5) * 0.15 + (row % 2) * 0.07
		local y = 0.78 - row * 0.2
		local d = UI.diamond({ Parent = pile, Size = size, Color = (i % 3 == 0) and C.Accent2 or C.Accent, Position = UDim2.fromScale(x, y), Fill = C.Ink })
		d.Core.Size = UDim2.fromScale(0.6, 0.6)
	end

	UI.label({
		Position = UDim2.fromOffset(0, 206),
		Size = UDim2.new(1, 0, 0, 44),
		FontFace = Theme.Fonts.Number,
		Text = UI.FormatNumber(def.Amount),
		TextSize = 38,
		TextColor3 = C.GoldLight,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = body,
	})
	UI.label({
		Position = UDim2.fromOffset(0, 252),
		Size = UDim2.new(1, 0, 0, 18),
		FontFace = Theme.Fonts.Label,
		Text = Theme.Spaced("Aether Shards", " "),
		TextSize = 12,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = body,
	})
	UI.ornament({ Parent = body, Width = 160, Position = UDim2.new(0.5, 0, 0, 290), Color = C.Accent })
	UI.label({
		Position = UDim2.fromOffset(12, 304),
		Size = UDim2.new(1, -24, 0, 30),
		FontFace = Theme.Fonts.Display,
		Text = def.Name,
		TextSize = 22,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = body,
	})
	if def.Bonus then
		UI.pill({ Parent = body, Text = def.Bonus, Color = C.Good, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 340) })
	end
	local button = UI.Button({
		Parent = body,
		Style = "primary",
		Color = C.Accent,
		Text = "",
		TextSize = 18,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(1, -32, 0, 48),
		OnClick = function()
			local res = State.Request("PromptProduct", def.Key)
			if not res.ok then
				Overlay.Toast(res.msg, "error")
			end
		end,
	})
	if def.Id == 0 then
		button:SetText("NOT ON SALE YET")
		button:SetEnabled(false)
	else
		button:SetText("…")
		fetchPrice(def.Id, Enum.InfoType.Product, function(robux)
			button:SetText(robux and ("R$ " .. UI.FormatNumber(robux)) or "BUY")
		end)
	end
end

function ShopPage:BuyWeapon(def)
	local data = State.Data
	if not data or data.Weapons[def.Id] then
		return
	end
	if def.Exclusive and not (data.Passes and data.Passes.ExclusiveWeapons) then
		Overlay.Confirm({
			Title = "Exclusive weapon",
			Body = def.Name .. " can only be bought with the Exclusive Armory game pass.",
			Confirm = "VIEW PASS",
			Color = C.Accent2,
			OnConfirm = function()
				self:SetTab("Gamepasses")
			end,
		})
		return
	end
	if data.Coins < def.Price then
		Overlay.Confirm({
			Title = "Not enough shards",
			Body = ("You need %s more Aether Shards for %s."):format(UI.FormatNumber(def.Price - data.Coins), def.Name),
			Confirm = "GET SHARDS",
			OnConfirm = function()
				self:SetTab("Currency")
			end,
		})
		return
	end
	local rarity = Weapons.RarityOf(def)
	Overlay.Confirm({
		Title = "Buy " .. def.Name,
		Body = ("Spend %s Aether Shards on this %s weapon?"):format(UI.FormatNumber(def.Price), string.lower(rarity.Name)),
		Confirm = "BUY",
		Color = rarity.Color,
		OnConfirm = function()
			local res = State.Request("BuyWeapon", def.Id)
			Overlay.Toast(res.msg, res.ok and "success" or "error")
		end,
	})
end

function ShopPage:Refresh(data)
	self.Shards.Text = UI.FormatNumber(data.Coins)
	for id, entry in pairs(self.WeaponCards) do
		local def = entry.Def
		local owned = data.Weapons[id] == true
		entry.Status.Visible = owned
		entry.StatusText.Text = "OWNED"
		entry.Card:SetSelected(false)
		if owned then
			entry.Button:SetStyle("secondary")
			entry.Button:SetText("OWNED")
			entry.Button:SetEnabled(false)
		else
			entry.Button:SetStyle("primary")
			entry.Button:SetEnabled(true)
			if def.Exclusive and not (data.Passes and data.Passes.ExclusiveWeapons) then
				entry.Button:SetText(("LOCKED  ·  %s ◆"):format(UI.FormatNumber(def.Price)))
			else
				entry.Button:SetText(("BUY  ·  %s ◆"):format(UI.FormatNumber(def.Price)))
			end
		end
	end
	for key, entry in pairs(self.PassCards) do
		local owns = data.Passes and data.Passes[key]
		entry.Card:SetSelected(owns == true)
		if owns then
			entry.Button:SetText("OWNED")
			entry.Button:SetEnabled(false)
		elseif entry.Def.Id == 0 then
			entry.Button:SetText("COMING SOON")
			entry.Button:SetEnabled(false)
		else
			entry.Button:SetText("BUY")
			entry.Button:SetEnabled(true)
		end
	end
end

function ShopPage:SetTab(tab)
	self.Tab = tab
	for name, panel in pairs(self.Panels) do
		panel.Visible = name == tab
		if name == tab then
			panel.CanvasPosition = Vector2.new()
		end
	end
	for name, button in pairs(self.TabButtons) do
		button:SetStyle(name == tab and "primary" or "secondary")
	end
end

function ShopPage:Show(arg)
	if arg and arg.Tab then
		self:SetTab(arg.Tab)
	end
	self.Page:Show()
	if not self.StopAnim then
		self.StopAnim = Animator.Every(function(dt, t)
			if self.Tab ~= "Weapons" then
				return
			end
			for _, entry in pairs(self.WeaponCards) do
				for _, step in ipairs(entry.Steppers) do
					step(dt, t)
				end
			end
		end)
	end
end

function ShopPage:Hide()
	self.Page:Hide()
	if self.StopAnim then
		self.StopAnim()
		self.StopAnim = nil
	end
end

return ShopPage
