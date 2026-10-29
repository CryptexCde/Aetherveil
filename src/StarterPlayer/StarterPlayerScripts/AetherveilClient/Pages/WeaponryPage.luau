-- AETHERVEIL · Weaponry: browse and equip owned weapons (buying happens in the Shop)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Weapons)
local Client = script.Parent.Parent
local Theme = require(Client.Theme)
local UI = require(Client.UIKit)
local Animator = require(Client.Animator)
local State = require(Client.State)
local Overlay = require(Client.Overlay)
local WeaponCard = require(script.Parent.WeaponCard)

local C = Theme.Colors

local WeaponryPage = {}
WeaponryPage.__index = WeaponryPage

function WeaponryPage.new(canvas, app)
	local self = setmetatable({}, WeaponryPage)
	self.App = app
	self.Cards = {}

	local page = UI.Page({
		Parent = canvas,
		Name = "Weaponry",
		Title = "Weaponry",
		Subtitle = "Equip the enchanted weapons you own. New weapons can be found in the Shop.",
		OnBack = function()
			app:Back()
		end,
	})
	self.Page = page
	self.SlotsLabel = UI.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(1540, 150),
		Size = UDim2.fromOffset(400, 30),
		FontFace = Theme.Fonts.Label,
		Text = "",
		TextSize = 16,
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = page.Root,
	})
	local _, amount = UI.ShardCounter({ Parent = page.Root, Position = UDim2.fromOffset(1548, 40), AlignRight = true })
	self.Shards = amount

	local scroller = UI.new("ScrollingFrame", {
		Name = "Grid",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = page.Content,
	})
	UI.padding(scroller, 4, 12, 14, 20)
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(WeaponCard.Size.X, WeaponCard.Size.Y),
		CellPadding = UDim2.fromOffset(16, 22),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	UI.SmoothScroll(scroller, false)

	for order, id in ipairs(Weapons.Order) do
		self.Cards[id] = WeaponCard.new({
			Parent = scroller,
			Id = id,
			LayoutOrder = order,
			OnAction = function(def)
				self:OnAction(def)
			end,
		})
	end

	State.Changed:Connect(function(data)
		self:Refresh(data)
	end)
	if State.Data then
		self:Refresh(State.Data)
	end
	return self
end

function WeaponryPage:OnAction(def)
	local data = State.Data
	if not data then
		return
	end
	if not data.Weapons[def.Id] then
		self.App:Open("Shop", { Tab = "Weapons" })
		return
	end
	local res = State.Request("EquipWeapon", def.Id)
	Overlay.Toast(res.msg, res.ok and "success" or "error")
end

function WeaponryPage:Refresh(data)
	self.Shards.Text = UI.FormatNumber(data.Coins)
	local equippedCount = #(data.Equipped or {})
	self.SlotsLabel.Text = Theme.Spaced(("Slots %d / %d"):format(equippedCount, data.Slots or 1), " ")
	for id, entry in pairs(self.Cards) do
		local owned = data.Weapons[id] == true
		local equipped = table.find(data.Equipped or {}, id) ~= nil
		entry.Card:SetSelected(equipped)
		entry.Status.Visible = equipped or not owned
		if equipped then
			entry.StatusText.Text = "EQUIPPED"
			entry.Status.BackgroundColor3 = C.Good
			entry.Button:SetStyle("primary")
			entry.Button:SetText(equippedCount > 1 and "UNEQUIP" or "EQUIPPED")
		elseif owned then
			entry.Button:SetStyle("secondary")
			entry.Button:SetText("EQUIP")
		else
			entry.StatusText.Text = "LOCKED"
			entry.Status.BackgroundColor3 = C.TextFaint
			entry.Button:SetStyle("secondary")
			entry.Button:SetText("FIND IN SHOP  ›")
		end
	end
end

function WeaponryPage:Show()
	self.Page:Show()
	if not self.StopAnim then
		self.StopAnim = Animator.Every(function(dt, t)
			for _, entry in pairs(self.Cards) do
				for _, step in ipairs(entry.Steppers) do
					step(dt, t)
				end
			end
		end)
	end
end

function WeaponryPage:Hide()
	self.Page:Hide()
	if self.StopAnim then
		self.StopAnim()
		self.StopAnim = nil
	end
end

return WeaponryPage
