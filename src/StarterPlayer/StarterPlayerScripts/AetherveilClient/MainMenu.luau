-- AETHERVEIL · Main menu (the central navigation hub)
-- Title and menu on the right, like a classic fantasy RPG title screen.
-- The highlight bar slides between items, fades out to the left and ends in a diamond.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Elements = require(Root.Config.Elements)
local Weapons = require(Root.Config.Weapons)
local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.UIKit)
local Animator = require(script.Parent.Animator)
local Sound = require(script.Parent.Sound)
local State = require(script.Parent.State)

local C = Theme.Colors
local player = Players.LocalPlayer

local MainMenu = {}
MainMenu.__index = MainMenu

local ITEMS = {
	{ Id = "Play", Text = "PLAY" },
	{ Id = "Elements", Text = "ELEMENTS" },
	{ Id = "Weaponry", Text = "WEAPONRY" },
	{ Id = "Shop", Text = "SHOP" },
	{ Id = "Settings", Text = "SETTINGS" },
}

local COLUMN_RIGHT = 1500 -- right edge of title + menu (canvas is 1600 wide)
local MENU_WIDTH = 440
local ITEM_HEIGHT = 54
local MENU_TOP = 448

function MainMenu.new(canvas, app)
	local self = setmetatable({}, MainMenu)
	self.App = app
	self.Selected = 1
	self.Visible = false

	local root = UI.new("CanvasGroup", {
		Name = "MainMenu",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = canvas,
	})
	self.Root = root

	---------------------------------------------------------------- title
	local titleBlock = UI.new("Frame", {
		Name = "TitleBlock",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(COLUMN_RIGHT + 30, 150),
		Size = UDim2.fromOffset(700, 190),
		BackgroundTransparency = 1,
		Parent = root,
	})
	self.TitleBlock = titleBlock
	local title = UI.label({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 110),
		FontFace = Theme.Fonts.Display,
		Text = "A\u{200C}ETHERVEIL",
		TextSize = 104,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = titleBlock,
	})
	UI.goldText(title)
	UI.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 0.55, Parent = title })
	self.TitleGlow = UI.label({
		Name = "Glow",
		Size = UDim2.new(1, 0, 0, 110),
		FontFace = Theme.Fonts.Display,
		Text = "A\u{200C}ETHERVEIL",
		TextSize = 104,
		TextColor3 = C.Accent,
		TextTransparency = 0.85,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 0,
		Parent = titleBlock,
	})
	UI.ornament({ Parent = titleBlock, Width = 420, Position = UDim2.new(0.5, 0, 0, 122), Color = C.Gold })
	UI.label({
		Name = "Tagline",
		Position = UDim2.fromOffset(0, 138),
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = Theme.Fonts.Label,
		Text = Theme.Spaced("The veil is thinning", " "),
		TextSize = 18,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = titleBlock,
	})

	---------------------------------------------------------------- menu list
	local list = UI.new("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(COLUMN_RIGHT, MENU_TOP),
		Size = UDim2.fromOffset(MENU_WIDTH, ITEM_HEIGHT * #ITEMS),
		BackgroundTransparency = 1,
		Parent = root,
	})
	self.List = list

	-- highlight bar: fades out to the left, diamond on the right end
	local bar = UI.new("Frame", {
		Name = "Highlight",
		Size = UDim2.new(1, 0, 0, ITEM_HEIGHT - 6),
		Position = UDim2.fromOffset(0, 3),
		BackgroundColor3 = Color3.fromRGB(4, 2, 8),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Parent = list,
	})
	local fade = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.85),
		NumberSequenceKeypoint.new(0.62, 0),
		NumberSequenceKeypoint.new(1, 0),
	})
	UI.gradient(bar, nil, fade)
	local barStroke = UI.stroke(bar, C.Accent, 1.2, 0)
	UI.gradient(barStroke, nil, fade)
	local glow = UI.new("Frame", {
		Name = "Glow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 10, 1, 10),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = bar,
	})
	UI.corner(glow, 6)
	UI.gradient(glow, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.2),
	}))
	UI.diamond({ Parent = bar, Size = 13, Color = C.Accent, Position = UDim2.fromScale(1, 0.5), ZIndex = 3 })
	self.Bar = bar
	self.BarGlow = glow

	self.Items = {}
	for i, item in ipairs(ITEMS) do
		local button = UI.new("TextButton", {
			Name = item.Id,
			Position = UDim2.fromOffset(0, (i - 1) * ITEM_HEIGHT),
			Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 4,
			Parent = list,
		})
		local label = UI.label({
			Name = "Label",
			Size = UDim2.new(1, -30, 1, 0),
			FontFace = Theme.Fonts.Display,
			Text = item.Text,
			TextSize = 30,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
			Parent = button,
		})
		UI.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.5, Parent = label })
		button.MouseEnter:Connect(function()
			if self.Selected ~= i then
				Sound.Play("Hover")
			end
			self:Select(i)
		end)
		button.SelectionGained:Connect(function()
			self:Select(i)
		end)
		button.Activated:Connect(function()
			self:Select(i)
			self:Activate()
		end)
		self.Items[i] = { Id = item.Id, Button = button, Label = label }
	end

	---------------------------------------------------------------- corners
	local shards, amount = UI.ShardCounter({ Parent = root, Position = UDim2.fromOffset(52, 40) })
	self.Shards = amount

	local profile = UI.new("Frame", {
		Name = "Profile",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromOffset(52, 860),
		Size = UDim2.fromOffset(620, 70),
		BackgroundTransparency = 1,
		Parent = root,
	})
	UI.label({
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = Theme.Fonts.Display,
		Text = player.DisplayName,
		TextSize = 24,
		TextColor3 = C.Text,
		Parent = profile,
	})
	self.Loadout = UI.label({
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 24),
		FontFace = Theme.Fonts.Body,
		Text = "",
		TextSize = 19,
		TextColor3 = C.TextDim,
		RichText = true,
		Parent = profile,
	})
	UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(500, 18),
		FontFace = Theme.Fonts.Label,
		Text = Theme.Spaced("© 2026 Aetherveil", " "),
		TextSize = 12,
		TextColor3 = C.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = root,
	})

	State.Changed:Connect(function(data)
		self:Refresh(data)
	end)
	if State.Data then
		self:Refresh(State.Data)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not self.Visible or processed then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Down or key == Enum.KeyCode.S or key == Enum.KeyCode.DPadDown then
			Sound.Play("Hover")
			self:Select(self.Selected % #ITEMS + 1)
		elseif key == Enum.KeyCode.Up or key == Enum.KeyCode.W or key == Enum.KeyCode.DPadUp then
			Sound.Play("Hover")
			self:Select((self.Selected - 2) % #ITEMS + 1)
		elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.ButtonA then
			self:Activate()
		end
	end)

	self:Select(1, true)
	return self
end

function MainMenu:Refresh(data)
	self.Shards.Text = UI.FormatNumber(data.Coins)
	local element = data.Element and Elements.Get(data.Element)
	local elementText = element
			and ('<font color="#%s">%s</font>'):format(element.Color:ToHex(), element.Name)
		or '<font color="#ff8890">None chosen</font>'
	local names = {}
	for _, id in ipairs(data.Equipped or {}) do
		local w = Weapons.Get(id)
		if w then
			table.insert(names, w.Name)
		end
	end
	self.Loadout.Text = ("Element · %s     Weapon · %s"):format(elementText, table.concat(names, ", "))
end

function MainMenu:Select(index, instant)
	self.Selected = index
	local y = (index - 1) * ITEM_HEIGHT + 3
	if instant then
		self.Bar.Position = UDim2.fromOffset(0, y)
	else
		Animator.Tween(self.Bar, 0.28, { Position = UDim2.fromOffset(0, y) }, Enum.EasingStyle.Back)
	end
	for i, item in ipairs(self.Items) do
		local on = i == index
		Animator.Tween(item.Label, 0.2, {
			TextColor3 = on and Color3.new(1, 1, 1) or C.Text,
			TextSize = on and 32 or 30,
			Position = UDim2.fromOffset(on and -6 or 0, 0),
		})
	end
end

function MainMenu:Activate()
	local id = self.Items[self.Selected].Id
	Sound.Play("Click")
	if id == "Play" then
		self.App:Play()
	else
		self.App:Open(id)
	end
end

function MainMenu:Show()
	self.Visible = true
	self.Root.Visible = true
	self.Root.Position = UDim2.fromOffset(18, 0)
	Animator.Tween(self.Root, 0.6, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
	for i, item in ipairs(self.Items) do
		item.Label.TextTransparency = 1
		task.delay(0.08 * i, function()
			Animator.Tween(item.Label, 0.4, { TextTransparency = 0 })
		end)
	end
	if not self.StopGlow then
		self.StopGlow = Animator.Every(function(_, t)
			self.TitleGlow.TextTransparency = 0.78 + 0.12 * math.sin(t * 1.4)
			self.BarGlow.BackgroundTransparency = 0.8 + 0.08 * math.sin(t * 2.2)
		end)
	end
end

function MainMenu:Hide()
	self.Visible = false
	if self.StopGlow then
		self.StopGlow()
		self.StopGlow = nil
	end
	Animator.Tween(self.Root, 0.3, { GroupTransparency = 1, Position = UDim2.fromOffset(24, 0) }).Completed:Connect(function()
		if not self.Visible then
			self.Root.Visible = false
		end
	end)
end

return MainMenu
