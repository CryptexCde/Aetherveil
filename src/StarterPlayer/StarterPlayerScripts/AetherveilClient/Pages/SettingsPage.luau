-- AETHERVEIL · Settings: graphics, VFX quality and volume
-- Changes apply instantly and are saved to the server shortly after.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsConfig = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Settings)
local Client = script.Parent.Parent
local Theme = require(Client.Theme)
local UI = require(Client.UIKit)
local Animator = require(Client.Animator)
local Sound = require(Client.Sound)
local State = require(Client.State)
local SettingsApplier = require(Client.SettingsApplier)

local C = Theme.Colors

local SettingsPage = {}
SettingsPage.__index = SettingsPage

local DESCRIPTIONS = {
	Graphics = "Lighting effects, bloom, sun rays, depth of field and shadows.",
	VFX = "How many particles and magical effects are shown.",
}

function SettingsPage.new(canvas, app)
	local self = setmetatable({}, SettingsPage)
	self.App = app
	self.Settings = SettingsConfig.Sanitize(nil)
	self.Segments = {}
	self.Sliders = {}

	local page = UI.Page({
		Parent = canvas,
		Name = "Settings",
		Title = "Settings",
		Subtitle = "Changes apply instantly and are saved to your profile.",
		OnBack = function()
			app:Back()
		end,
	})
	self.Page = page

	local panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(1000, 600),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = page.Content,
	})
	UI.corner(panel, 6)
	UI.gradient(panel, ColorSequence.new(Color3.fromRGB(26, 18, 40), Color3.fromRGB(10, 7, 16)), NumberSequence.new(0.08), 90)
	UI.stroke(panel, C.Line, 1.2, 0.3)

	local y = 34
	local function section(title)
		UI.label({
			Position = UDim2.fromOffset(48, y),
			Size = UDim2.fromOffset(400, 30),
			FontFace = Theme.Fonts.Display,
			Text = string.upper(title),
			TextSize = 24,
			TextColor3 = C.Gold,
			Parent = panel,
		})
		local rule = UI.new("Frame", { Position = UDim2.fromOffset(48, y + 34), Size = UDim2.new(1, -96, 0, 1), BackgroundColor3 = C.GoldDeep, BorderSizePixel = 0, Parent = panel })
		UI.gradient(rule, nil, NumberSequence.new(0, 1))
		y += 48
	end

	local function segmented(key, options)
		UI.label({
			Position = UDim2.fromOffset(48, y),
			Size = UDim2.fromOffset(330, 50),
			FontFace = Theme.Fonts.Body,
			Text = DESCRIPTIONS[key],
			TextSize = 17,
			TextWrapped = true,
			TextColor3 = C.TextDim,
			Parent = panel,
		})
		local row = UI.new("Frame", { Position = UDim2.fromOffset(400, y), Size = UDim2.fromOffset(552, 48), BackgroundTransparency = 1, Parent = panel })
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
		local buttons = {}
		for i, option in ipairs(options) do
			buttons[option] = UI.Button({
				Parent = row,
				LayoutOrder = i,
				Style = "secondary",
				Color = C.Accent,
				Text = string.upper(option),
				TextSize = 16,
				Size = UDim2.fromOffset(132, 46),
				OnClick = function()
					self.Settings[key] = option
					self:Changed()
				end,
			})
		end
		self.Segments[key] = buttons
		y += 70
	end

	local function slider(key, title)
		UI.label({
			Position = UDim2.fromOffset(48, y),
			Size = UDim2.fromOffset(300, 40),
			FontFace = Theme.Fonts.Display,
			Text = title,
			TextSize = 20,
			TextColor3 = C.Text,
			Parent = panel,
		})
		local track = UI.new("TextButton", {
			Position = UDim2.fromOffset(400, y + 14),
			Size = UDim2.fromOffset(452, 12),
			BackgroundColor3 = C.Ink,
			AutoButtonColor = false,
			Text = "",
			Parent = panel,
		})
		UI.corner(track, 6)
		UI.stroke(track, C.Line, 1, 0.3)
		local fill = UI.new("Frame", { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track })
		UI.corner(fill, 6)
		UI.gradient(fill, ColorSequence.new(C.Accent:Lerp(Color3.new(0, 0, 0), 0.4), C.Accent))
		local knob = UI.diamond({ Parent = track, Size = 20, Color = C.Gold, Position = UDim2.fromScale(0.5, 0.5), Fill = C.Panel, ZIndex = 3 })
		local value = UI.label({
			Position = UDim2.fromOffset(876, y),
			Size = UDim2.fromOffset(80, 40),
			FontFace = Theme.Fonts.Number,
			Text = "50%",
			TextSize = 18,
			TextColor3 = C.GoldLight,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = panel,
		})

		local dragging = false
		local function setFromX(x)
			local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			self.Settings[key] = math.floor(rel * 100 + 0.5) / 100
			self:Changed(true)
		end
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setFromX(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				setFromX(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				Sound.Play("Click")
			end
		end)
		self.Sliders[key] = { Fill = fill, Knob = knob, Value = value }
		y += 56
	end

	section("Graphics")
	segmented("Graphics", SettingsConfig.Graphics)
	section("Visual effects")
	segmented("VFX", SettingsConfig.VFX)
	section("Volume")
	slider("Master", "Master")
	slider("Music", "Music")
	slider("SFX", "Sound Effects")

	self.SavedLabel = UI.label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -48, 1, -20),
		Size = UDim2.fromOffset(300, 24),
		FontFace = Theme.Fonts.Label,
		Text = "",
		TextSize = 14,
		TextColor3 = C.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})

	State.Changed:Connect(function(data)
		if not self.Dirty then
			self.Settings = SettingsConfig.Sanitize(data.Settings)
			self:Paint(true)
		end
	end)
	if State.Data then
		self.Settings = SettingsConfig.Sanitize(State.Data.Settings)
		self:Paint(true)
	end
	return self
end

function SettingsPage:Paint(instant)
	for key, buttons in pairs(self.Segments) do
		for option, button in pairs(buttons) do
			button:SetStyle(self.Settings[key] == option and "primary" or "secondary")
		end
	end
	for key, s in pairs(self.Sliders) do
		local v = self.Settings[key]
		if instant then
			s.Fill.Size = UDim2.fromScale(v, 1)
			s.Knob.Position = UDim2.fromScale(v, 0.5)
		else
			Animator.Tween(s.Fill, 0.12, { Size = UDim2.fromScale(v, 1) })
			Animator.Tween(s.Knob, 0.12, { Position = UDim2.fromScale(v, 0.5) })
		end
		s.Value.Text = ("%d%%"):format(math.floor(v * 100 + 0.5))
	end
end

-- Apply immediately, save after the player stops fiddling for a moment.
function SettingsPage:Changed(fromSlider)
	self.Settings = SettingsConfig.Sanitize(self.Settings)
	self:Paint(fromSlider)
	SettingsApplier.Apply(self.Settings)
	self.Dirty = true
	SettingsApplier.Pending = true
	self.SavedLabel.Text = "Saving…"
	self.SaveToken = (self.SaveToken or 0) + 1
	local token = self.SaveToken
	task.delay(0.8, function()
		if token ~= self.SaveToken then
			return
		end
		local res = State.Request("SaveSettings", self.Settings)
		self.Dirty = false
		SettingsApplier.Pending = false
		self.SavedLabel.Text = res.ok and "Saved" or "Couldn't save — will retry"
		if not res.ok then
			task.delay(3, function()
				if token == self.SaveToken then
					self:Changed()
				end
			end)
		end
	end)
end

function SettingsPage:Show()
	self.Page:Show()
end

function SettingsPage:Hide()
	self.Page:Hide()
end

return SettingsPage
