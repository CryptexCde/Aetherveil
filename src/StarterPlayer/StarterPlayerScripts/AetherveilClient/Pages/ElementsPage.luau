-- AETHERVEIL · Elements menu: browse, unlock and equip elements

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Elements = require(Root.Config.Elements)
local Client = script.Parent.Parent
local Theme = require(Client.Theme)
local UI = require(Client.UIKit)
local Animator = require(Client.Animator)
local Previews = require(Client.Previews)
local State = require(Client.State)
local Overlay = require(Client.Overlay)

local C = Theme.Colors

local ElementsPage = {}
ElementsPage.__index = ElementsPage

local CARD_W, CARD_H = 232, 560

function ElementsPage.new(canvas, app)
	local self = setmetatable({}, ElementsPage)
	self.App = app
	self.Cards = {}
	self.Steppers = {}

	local page = UI.Page({
		Parent = canvas,
		Name = "Elements",
		Title = "Elements",
		Subtitle = "Choose the power you carry into the Veil. Your element is saved between sessions.",
		OnBack = function()
			app:Back()
		end,
	})
	self.Page = page
	local _, amount = UI.ShardCounter({ Parent = page.Root, Position = UDim2.fromOffset(1548, 40), AlignRight = true })
	self.Shards = amount

	local scroller = UI.new("ScrollingFrame", {
		Name = "Cards",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = page.Content,
	})
	UI.padding(scroller, 4, 4, 14, 8)
	UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	UI.SmoothScroll(scroller, true)

	for order, id in ipairs(Elements.Order) do
		self.Cards[id] = self:BuildCard(scroller, Elements.Get(id), order)
	end

	State.Changed:Connect(function(data)
		self:Refresh(data)
	end)
	if State.Data then
		self:Refresh(State.Data)
	end
	return self
end

function ElementsPage:BuildCard(parent, def, order)
	local card = UI.Card({ Parent = parent, Name = def.Id, Size = UDim2.fromOffset(CARD_W, CARD_H), Color = def.Color, LayoutOrder = order })
	local body = card.Body

	-- soft colour wash behind the emblem
	local wash = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 220), BackgroundColor3 = def.Color, BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = body })
	UI.gradient(wash, nil, NumberSequence.new(0.2, 1), 90)

	local _, step = Previews.Element(body, def, UDim2.new(1, 0, 0, 200), UDim2.fromOffset(0, 10))
	table.insert(self.Steppers, step)

	local name = UI.label({
		Position = UDim2.fromOffset(0, 206),
		Size = UDim2.new(1, 0, 0, 40),
		FontFace = Theme.Fonts.Display,
		Text = string.upper(def.Name),
		TextSize = 32,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = body,
	})
	UI.gradient(name, ColorSequence.new(def.Accent, def.Color), nil, 90)
	UI.label({
		Position = UDim2.fromOffset(0, 244),
		Size = UDim2.new(1, 0, 0, 18),
		FontFace = Theme.Fonts.Label,
		Text = Theme.Spaced(def.Title, " "),
		TextSize = 12,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = body,
	})
	UI.ornament({ Parent = body, Width = 150, Position = UDim2.new(0.5, 0, 0, 274), Color = def.Color })
	UI.label({
		Position = UDim2.fromOffset(18, 288),
		Size = UDim2.new(1, -36, 0, 96),
		FontFace = Theme.Fonts.Body,
		Text = def.Description,
		TextSize = 16,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.TextDim,
		Parent = body,
	})

	local abilities = UI.new("Frame", { Position = UDim2.fromOffset(20, 392), Size = UDim2.new(1, -40, 0, 92), BackgroundTransparency = 1, Parent = body })
	UI.new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = abilities })
	for i, ab in ipairs(def.Abilities) do
		local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = i, Parent = abilities })
		local key = UI.new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.Ink, Parent = row })
		UI.corner(key, 3)
		UI.stroke(key, def.Color, 1, 0.3)
		UI.label({ Size = UDim2.fromScale(1, 1), FontFace = Theme.Fonts.Number, Text = ab.Key, TextSize = 12, TextColor3 = def.Accent, TextXAlignment = Enum.TextXAlignment.Center, Parent = key })
		UI.label({ Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 1, 0), FontFace = Theme.Fonts.Body, Text = ab.Name, TextSize = 16, TextColor3 = C.Text, Parent = row })
	end

	local badge, badgeText = UI.pill({ Parent = body, Text = "Equipped", Color = def.Color, Position = UDim2.fromOffset(12, 12) })
	badge.Visible = false

	local button = UI.Button({
		Parent = body,
		Style = "secondary",
		Color = def.Color,
		Text = "EQUIP",
		TextSize = 18,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(1, -32, 0, 46),
		OnClick = function()
			self:OnAction(def)
		end,
	})

	return { Card = card, Button = button, Badge = badge, BadgeText = badgeText, Def = def }
end

function ElementsPage:OnAction(def)
	local data = State.Data
	if not data then
		return
	end
	local unlocked = data.Elements[def.Id]
	if unlocked then
		if data.Element == def.Id then
			return
		end
		local res = State.Request("SelectElement", def.Id)
		Overlay.Toast(res.msg, res.ok and "success" or "error")
		return
	end
	local unlock = def.Unlock
	if unlock.Type == "Coins" then
		Overlay.Confirm({
			Title = "Unlock " .. def.Name,
			Body = ("Spend %s Aether Shards to unlock %s forever?"):format(UI.FormatNumber(unlock.Price), def.Name),
			Confirm = "UNLOCK",
			Color = def.Color,
			OnConfirm = function()
				local res = State.Request("UnlockElement", def.Id)
				Overlay.Toast(res.msg, res.ok and "success" or "error")
			end,
		})
	elseif unlock.Type == "Gamepass" then
		local res = State.Request("UnlockElement", def.Id)
		if not res.ok then
			Overlay.Toast(res.msg, "error")
		end
	end
end

function ElementsPage:Refresh(data)
	self.Shards.Text = UI.FormatNumber(data.Coins)
	for id, entry in pairs(self.Cards) do
		local def = entry.Def
		local unlocked = data.Elements[id] == true
		local equipped = data.Element == id
		entry.Card:SetSelected(equipped)
		entry.Badge.Visible = equipped or not unlocked
		if equipped then
			entry.BadgeText.Text = "EQUIPPED"
			entry.Badge.BackgroundColor3 = def.Color
			entry.Button:SetText("EQUIPPED")
			entry.Button:SetStyle("primary")
			entry.Button:SetEnabled(true)
		elseif unlocked then
			entry.Button:SetText("EQUIP")
			entry.Button:SetStyle("secondary")
		else
			entry.BadgeText.Text = "LOCKED"
			entry.Badge.BackgroundColor3 = C.TextFaint
			entry.Button:SetStyle("secondary")
			if def.Unlock.Type == "Coins" then
				entry.Button:SetText(("UNLOCK  ·  %s ◆"):format(UI.FormatNumber(def.Unlock.Price)))
			elseif def.Unlock.Type == "Gamepass" then
				entry.Button:SetText("GET GAME PASS")
			else
				entry.Button:SetText("LOCKED")
			end
		end
	end
end

function ElementsPage:Show()
	self.Page:Show()
	if not self.StopAnim then
		self.StopAnim = Animator.Every(function(dt, t)
			for _, step in ipairs(self.Steppers) do
				step(dt, t)
			end
		end)
	end
end

function ElementsPage:Hide()
	self.Page:Hide()
	if self.StopAnim then
		self.StopAnim()
		self.StopAnim = nil
	end
end

return ElementsPage
