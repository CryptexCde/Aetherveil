-- AETHERVEIL · Weapon card used by both Weaponry (equip) and Shop (buy)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage:WaitForChild("Aetherveil").Config.Weapons)
local Client = script.Parent.Parent
local Theme = require(Client.Theme)
local UI = require(Client.UIKit)
local Animator = require(Client.Animator)
local Previews = require(Client.Previews)

local C = Theme.Colors

local WeaponCard = {}

WeaponCard.Size = Vector2.new(280, 410)

-- opts = { Parent, Id, LayoutOrder, OnAction(def) }
function WeaponCard.new(opts)
	local def = Weapons.Get(opts.Id)
	local rarity = Weapons.RarityOf(def)
	local card = UI.Card({
		Parent = opts.Parent,
		Name = def.Id,
		Size = UDim2.fromOffset(WeaponCard.Size.X, WeaponCard.Size.Y),
		Color = rarity.Color,
		LayoutOrder = opts.LayoutOrder,
	})
	local body = card.Body
	local entry = { Card = card, Def = def, Steppers = {}, Stops = {} }

	local wash = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = rarity.Color, BackgroundTransparency = 0.78, BorderSizePixel = 0, Parent = body })
	UI.gradient(wash, nil, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	}), 90)

	local _, step = Previews.Weapon(body, def.Id, UDim2.new(1, 0, 0, 180), UDim2.fromOffset(0, 8))
	table.insert(entry.Steppers, step)

	UI.pill({ Parent = body, Text = rarity.Name, Color = rarity.Color, Position = UDim2.fromOffset(12, 12) })
	if def.Exclusive then
		UI.pill({ Parent = body, Text = "Exclusive", Color = C.Accent2, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12) })
	end
	local status, statusText = UI.pill({ Parent = body, Text = "Equipped", Color = C.Good, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, def.Exclusive and 40 or 12) })
	status.Visible = false
	entry.Status, entry.StatusText = status, statusText

	local name = UI.label({
		Position = UDim2.fromOffset(16, 192),
		Size = UDim2.new(1, -32, 0, 30),
		FontFace = Theme.Fonts.Display,
		Text = def.Name,
		TextSize = 24,
		TextScaled = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = body,
	})
	local nameGradient = UI.gradient(name, ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.55)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.3)),
	}))
	UI.label({
		Position = UDim2.fromOffset(16, 224),
		Size = UDim2.new(1, -32, 0, 64),
		FontFace = Theme.Fonts.Body,
		Text = def.Description,
		TextSize = 15,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = C.TextDim,
		Parent = body,
	})

	-- stats row
	local stats = UI.new("Frame", { Position = UDim2.fromOffset(16, 292), Size = UDim2.new(1, -32, 0, 34), BackgroundTransparency = 1, Parent = body })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = stats })
	local function stat(label, value, order)
		local s = UI.new("Frame", { Size = UDim2.fromOffset(76, 34), BackgroundColor3 = C.Ink, BackgroundTransparency = 0.2, LayoutOrder = order, Parent = stats })
		UI.corner(s, 3)
		UI.stroke(s, C.Line, 1, 0.5)
		UI.label({ Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 1), FontFace = Theme.Fonts.Number, Text = value, TextSize = 15, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Center, Parent = s })
		UI.label({ Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 19), FontFace = Theme.Fonts.Label, Text = label, TextSize = 10, TextColor3 = C.TextFaint, TextXAlignment = Enum.TextXAlignment.Center, Parent = s })
	end
	stat("DAMAGE", tostring(def.Damage), 1)
	stat("SPEED", ("%.1f/s"):format(1 / def.Cooldown), 2)
	stat("REACH", tostring(def.Range), 3)

	local button = UI.Button({
		Parent = body,
		Style = "secondary",
		Color = rarity.Color,
		Text = "",
		TextSize = 17,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(1, -32, 0, 46),
		OnClick = function()
			opts.OnAction(def)
		end,
	})
	entry.Button = button

	if rarity.Shimmer then
		local shimmer = UI.gradient(card.Stroke, ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarity.Color),
			ColorSequenceKeypoint.new(0.45, rarity.Color),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.55, rarity.Color),
			ColorSequenceKeypoint.new(1, rarity.Color),
		}))
		card.Stroke.Transparency = 0
		card.Stroke.Thickness = 1.6
		table.insert(entry.Steppers, function(dt)
			shimmer.Rotation = (shimmer.Rotation + dt * 70) % 360
			nameGradient.Offset = Vector2.new(math.sin(os.clock() * 1.5) * 0.4, 0)
		end)
	end

	return entry
end

return WeaponCard
