-- AETHERVEIL · In-game HUD
-- Menu button + shard counter, and the ability bar for Fire/Water/Earth/Air/Lightning.
-- (Void uses the Portal Walker HUD that already exists.)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("Aetherveil")
local Elements = require(Root.Config.Elements)
local Net = require(Root.Shared.Net)
local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.UIKit)
local Animator = require(script.Parent.Animator)
local State = require(script.Parent.State)

local C = Theme.Colors
local player = Players.LocalPlayer

local HUD = {}

local layer, abilityBar, shardsLabel
local slots = {}
local currentElement
local stopCooldowns

local function aimPoint(screenPos)
	local camera = workspace.CurrentCamera
	local pos = screenPos or UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local fx = workspace:FindFirstChild("AetherveilFX")
	if fx then
		table.insert(ignore, fx)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	return hit and hit.Position or (ray.Origin + ray.Direction * 200)
end

local function cast(abilityId, fromButton)
	if not player:GetAttribute("InGame") then
		return
	end
	local target = fromButton and aimPoint(workspace.CurrentCamera.ViewportSize / 2) or aimPoint()
	Net.Get("Ability"):FireServer(abilityId, target)
end

local function buildAbilityBar(def)
	for _, s in pairs(slots) do
		s.Frame:Destroy()
	end
	table.clear(slots)
	currentElement = def and def.Id or nil
	if not def or def.Kit then
		abilityBar.Visible = false
		return
	end
	abilityBar.Visible = true
	for i, ab in ipairs(def.Abilities) do
		local b = UI.new("TextButton", {
			Name = ab.Id,
			Size = UDim2.fromOffset(92, 92),
			BackgroundColor3 = C.Panel,
			BackgroundTransparency = 0.1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = i,
			Parent = abilityBar,
		})
		UI.corner(b, 6)
		UI.stroke(b, def.Color, 1.6, 0.1)
		UI.gradient(b, ColorSequence.new(C.PanelHi, C.Panel), nil, 90)
		UI.diamond({ Parent = b, Size = 22, Color = def.Color, Position = UDim2.new(0.5, 0, 0, 24) })
		UI.label({ Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 20), FontFace = Theme.Fonts.Display, Text = string.upper(ab.Name), TextSize = 12, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Center, Parent = b })
		UI.label({ Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 18), FontFace = Theme.Fonts.Number, Text = "[" .. ab.Key .. "]", TextSize = 13, TextColor3 = def.Accent, TextXAlignment = Enum.TextXAlignment.Center, Parent = b })
		local cd = UI.label({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, FontFace = Theme.Fonts.Number, Text = "", TextSize = 28, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 5, Parent = b })
		UI.corner(cd, 6)
		b.Activated:Connect(function()
			cast(ab.Id, true)
		end)
		slots[ab.Id] = { Frame = b, Cooldown = cd, Key = Enum.KeyCode[ab.Key] }
	end
end

function HUD.Init(parent, app)
	layer = UI.new("Frame", {
		Name = "HUD",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = parent,
	})
	UI.Button({
		Parent = layer,
		Name = "MenuButton",
		Style = "secondary",
		Color = C.Gold,
		Text = "◆  MENU",
		TextSize = 17,
		Position = UDim2.fromOffset(52, 40),
		Size = UDim2.fromOffset(150, 44),
		OnClick = function()
			app:ReturnToMenu()
		end,
	})
	local _, amount = UI.ShardCounter({ Parent = layer, Position = UDim2.fromOffset(222, 40) })
	shardsLabel = amount

	abilityBar = UI.new("Frame", {
		Name = "Abilities",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -30),
		Size = UDim2.fromOffset(310, 92),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = layer,
	})
	UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = abilityBar,
	})

	State.Changed:Connect(function(data)
		shardsLabel.Text = UI.FormatNumber(data.Coins)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not layer.Visible then
			return
		end
		for id, slot in pairs(slots) do
			if slot.Key == input.KeyCode then
				cast(id, false)
			end
		end
	end)
end

function HUD.Show()
	layer.Visible = true
	buildAbilityBar(Elements.Get(player:GetAttribute("Element")))
	if not stopCooldowns then
		stopCooldowns = Animator.Every(function()
			local t = workspace:GetServerTimeNow()
			for id, slot in pairs(slots) do
				local ends = player:GetAttribute("ECD_" .. id)
				local left = ends and ends - t or 0
				slot.Cooldown.Visible = left > 0
				if left > 0 then
					slot.Cooldown.Text = left >= 1 and tostring(math.ceil(left)) or ("%.1f"):format(left)
				end
			end
		end)
	end
end

function HUD.Hide()
	layer.Visible = false
	if stopCooldowns then
		stopCooldowns()
		stopCooldowns = nil
	end
end

return HUD
