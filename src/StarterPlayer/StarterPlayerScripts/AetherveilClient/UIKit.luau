-- AETHERVEIL · Reusable UI building blocks
-- Buttons, cards, dividers, pills, page shells and smooth scrolling.

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Animator = require(script.Parent.Animator)
local Sound = require(script.Parent.Sound)

local C = Theme.Colors
local UI = {}

function UI.new(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.label(props)
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = Theme.Fonts.Body,
		TextColor3 = C.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = false,
		RichText = false,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return UI.new("TextLabel", defaults)
end

function UI.corner(parent, radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 4), Parent = parent })
end

function UI.stroke(parent, color, thickness, transparency)
	return UI.new("UIStroke", {
		Color = color or C.Line,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UI.gradient(parent, color, transparency, rotation)
	return UI.new("UIGradient", {
		Color = color or ColorSequence.new(Color3.new(1, 1, 1)),
		Transparency = transparency or NumberSequence.new(0),
		Rotation = rotation or 0,
		Parent = parent,
	})
end

function UI.padding(parent, left, right, top, bottom)
	return UI.new("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or left or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or top or 0),
		Parent = parent,
	})
end

-- Gold vertical gradient used on titles.
function UI.goldText(label)
	return UI.gradient(
		label,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.GoldLight),
			ColorSequenceKeypoint.new(0.45, C.Gold),
			ColorSequenceKeypoint.new(0.55, C.GoldDeep),
			ColorSequenceKeypoint.new(1, C.Gold),
		}),
		nil,
		90
	)
end

-- A rotated square with an optional filled core.
function UI.diamond(props)
	local size = props.Size or 12
	local color = props.Color or C.Accent
	local d = UI.new("Frame", {
		Name = props.Name or "Diamond",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Rotation = 45,
		BackgroundColor3 = props.Fill or C.Ink,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	UI.stroke(d, color, props.Thickness or 1.2)
	if props.Core ~= false then
		UI.new("Frame", {
			Name = "Core",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.45, 0.45),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = (props.ZIndex or 1) + 1,
			Parent = d,
		})
	end
	return d
end

-- Thin line — diamond — line ornament.
function UI.ornament(props)
	local width = props.Width or 300
	local color = props.Color or C.GoldDeep
	local holder = UI.new("Frame", {
		Name = "Ornament",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, 12),
		BackgroundTransparency = 1,
		Parent = props.Parent,
	})
	for _, side in ipairs({ -1, 1 }) do
		local line = UI.new("Frame", {
			AnchorPoint = Vector2.new(side == -1 and 1 or 0, 0.5),
			Position = UDim2.new(0.5, side * 12, 0.5, 0),
			Size = UDim2.new(0.5, -14, 0, 1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = holder,
		})
		UI.gradient(line, nil, NumberSequence.new(side == -1 and 1 or 0, side == -1 and 0 or 1))
	end
	UI.diamond({ Parent = holder, Size = 8, Color = color })
	return holder
end

-- Small coloured tag ("LEGENDARY", "EQUIPPED").
function UI.pill(props)
	local color = props.Color or C.Accent
	local pill = UI.new("Frame", {
		Name = props.Name or "Pill",
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Position = props.Position or UDim2.new(),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.78,
		ZIndex = props.ZIndex or 3,
		Parent = props.Parent,
	})
	UI.corner(pill, 11)
	UI.stroke(pill, color, 1, 0.2)
	UI.padding(pill, 10, 10, 0, 0)
	local text = UI.label({
		Name = "Text",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Theme.Fonts.Label,
		Text = Theme.Spaced(props.Text or "", ""),
		TextSize = 12,
		TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35),
		ZIndex = (props.ZIndex or 3) + 1,
		Parent = pill,
	})
	return pill, text
end

---------------------------------------------------------------- button
-- Styles: "primary" (filled accent), "secondary" (gold outline), "ghost" (text only)
function UI.Button(opts)
	local style = opts.Style or "secondary"
	local color = opts.Color or (style == "primary" and C.Accent or C.Gold)
	local self = { Enabled = true }

	local root = UI.new("TextButton", {
		Name = opts.Name or "Button",
		AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0),
		Position = opts.Position or UDim2.new(),
		Size = opts.Size or UDim2.fromOffset(200, 48),
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = style == "ghost" and 1 or 0,
		ZIndex = opts.ZIndex or 2,
		LayoutOrder = opts.LayoutOrder or 0,
		Selectable = true,
		Parent = opts.Parent,
	})
	UI.corner(root, opts.Radius or 4)
	local scale = UI.new("UIScale", { Parent = root })
	local stroke = UI.stroke(root, color, style == "ghost" and 0 or 1.2, style == "ghost" and 1 or 0.15)
	local fill
	if style == "primary" then
		fill = UI.gradient(root, ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.15), color:Lerp(Color3.new(0, 0, 0), 0.45)), nil, 90)
		root.BackgroundColor3 = Color3.new(1, 1, 1)
	else
		fill = UI.gradient(root, ColorSequence.new(C.PanelHi, C.Panel), nil, 90)
	end

	local label = UI.label({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		FontFace = opts.Font or Theme.Fonts.Display,
		Text = opts.Text or "",
		TextSize = opts.TextSize or 18,
		TextColor3 = style == "primary" and Color3.new(1, 1, 1) or (opts.TextColor or color),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = (opts.ZIndex or 2) + 1,
		Parent = root,
	})
	self.Instance = root
	self.Label = label
	self.Stroke = stroke

	local hovering = false
	local function paint()
		if not self.Enabled then
			Animator.Tween(stroke, 0.2, { Transparency = 0.7 })
			Animator.Tween(label, 0.2, { TextTransparency = 0.5 })
			Animator.Tween(scale, 0.2, { Scale = 1 })
			return
		end
		Animator.Tween(label, 0.2, { TextTransparency = 0 })
		if hovering then
			Animator.Tween(stroke, 0.2, { Transparency = style == "ghost" and 1 or 0, Thickness = style == "ghost" and 0 or 2 })
			Animator.Tween(scale, 0.25, { Scale = 1.04 }, Enum.EasingStyle.Back)
			if style == "ghost" then
				Animator.Tween(label, 0.2, { TextColor3 = C.GoldLight })
			end
		else
			Animator.Tween(stroke, 0.25, { Transparency = style == "ghost" and 1 or 0.15, Thickness = style == "ghost" and 0 or 1.2 })
			Animator.Tween(scale, 0.25, { Scale = 1 })
			if style == "ghost" then
				Animator.Tween(label, 0.2, { TextColor3 = opts.TextColor or color })
			end
		end
	end

	root.MouseEnter:Connect(function()
		hovering = true
		if self.Enabled then
			Sound.Play("Hover")
		end
		paint()
	end)
	root.MouseLeave:Connect(function()
		hovering = false
		paint()
	end)
	root.SelectionGained:Connect(function()
		hovering = true
		paint()
	end)
	root.SelectionLost:Connect(function()
		hovering = false
		paint()
	end)
	root.Activated:Connect(function()
		if not self.Enabled then
			Sound.Play("Error")
			return
		end
		Sound.Play("Click")
		scale.Scale = 0.94
		Animator.Tween(scale, 0.35, { Scale = hovering and 1.04 or 1 }, Enum.EasingStyle.Back)
		if opts.OnClick then
			task.spawn(opts.OnClick)
		end
	end)

	function self:SetText(text)
		label.Text = text
	end
	function self:SetEnabled(enabled)
		self.Enabled = enabled
		paint()
	end
	function self:SetColor(newColor)
		color = newColor
		stroke.Color = newColor
		if style == "primary" then
			fill.Color = ColorSequence.new(newColor:Lerp(Color3.new(1, 1, 1), 0.15), newColor:Lerp(Color3.new(0, 0, 0), 0.45))
		else
			label.TextColor3 = newColor
		end
	end
	function self:SetStyle(newStyle)
		style = newStyle
		if style == "primary" then
			root.BackgroundColor3 = Color3.new(1, 1, 1)
			root.BackgroundTransparency = 0
			fill.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.15), color:Lerp(Color3.new(0, 0, 0), 0.45))
			label.TextColor3 = Color3.new(1, 1, 1)
		else
			root.BackgroundColor3 = C.Panel
			root.BackgroundTransparency = 0
			fill.Color = ColorSequence.new(C.PanelHi, C.Panel)
			label.TextColor3 = color
		end
		paint()
	end
	return self
end

---------------------------------------------------------------- card
-- A card with a hover lift. Put content inside `Body`.
function UI.Card(opts)
	local accent = opts.Color or C.Line
	local root = UI.new("Frame", {
		Name = opts.Name or "Card",
		Size = opts.Size,
		BackgroundTransparency = 1,
		LayoutOrder = opts.LayoutOrder or 0,
		Parent = opts.Parent,
	})
	local body = UI.new("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ClipsDescendants = true,
		Parent = root,
	})
	UI.corner(body, 6)
	UI.gradient(body, ColorSequence.new(Color3.fromRGB(30, 20, 46), Color3.fromRGB(11, 8, 18)), NumberSequence.new(0.04), 90)
	local stroke = UI.stroke(body, accent, 1.2, 0.35)

	local card = { Root = root, Body = body, Stroke = stroke, Color = accent, Selected = false }
	local hovering = false
	local function paint()
		local lifted = hovering
		Animator.Tween(body, 0.3, { Position = UDim2.fromOffset(0, lifted and -8 or 0) })
		if card.Selected then
			Animator.Tween(stroke, 0.3, { Color = card.Color, Thickness = 2.2 })
		else
			Animator.Tween(stroke, 0.3, { Color = lifted and card.Color or C.Line, Thickness = lifted and 1.8 or 1.2, Transparency = lifted and 0 or 0.35 })
		end
	end
	root.MouseEnter:Connect(function()
		hovering = true
		paint()
	end)
	root.MouseLeave:Connect(function()
		hovering = false
		paint()
	end)

	local stopPulse
	function card:SetSelected(selected)
		card.Selected = selected
		if selected and not stopPulse then
			stopPulse = Animator.Pulse(stroke, 0, 0.45, 2.6)
		elseif not selected and stopPulse then
			stopPulse()
			stopPulse = nil
		end
		paint()
	end
	function card:SetColor(color)
		card.Color = color
		paint()
	end
	return card
end

---------------------------------------------------------------- page shell
-- Full-canvas page with a back button, title and subtitle. Content goes in `Content`.
function UI.Page(opts)
	local root = UI.new("CanvasGroup", {
		Name = opts.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = opts.Parent,
	})
	local back = UI.Button({
		Parent = root,
		Name = "Back",
		Style = "ghost",
		Text = "‹  BACK",
		TextSize = 20,
		Position = UDim2.fromOffset(52, 40),
		Size = UDim2.fromOffset(120, 40),
		OnClick = opts.OnBack,
	})
	back.Label.TextXAlignment = Enum.TextXAlignment.Left

	local title = UI.label({
		Name = "Title",
		Position = UDim2.fromOffset(60, 92),
		Size = UDim2.fromOffset(900, 64),
		FontFace = Theme.Fonts.Display,
		Text = string.upper(opts.Title),
		TextSize = 58,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = root,
	})
	UI.goldText(title)
	UI.label({
		Name = "Subtitle",
		Position = UDim2.fromOffset(62, 156),
		Size = UDim2.fromOffset(900, 26),
		FontFace = Theme.Fonts.Body,
		Text = opts.Subtitle or "",
		TextSize = 20,
		TextColor3 = C.TextDim,
		Parent = root,
	})
	local rule = UI.new("Frame", {
		Name = "Rule",
		Position = UDim2.fromOffset(60, 194),
		Size = UDim2.new(1, -120, 0, 1),
		BackgroundColor3 = C.GoldDeep,
		BorderSizePixel = 0,
		Parent = root,
	})
	UI.gradient(rule, nil, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1) }))

	local content = UI.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(60, 214),
		Size = UDim2.new(1, -120, 1, -250),
		BackgroundTransparency = 1,
		Parent = root,
	})

	local page = { Root = root, Content = content, Back = back }
	function page:Show()
		root.Visible = true
		root.Position = UDim2.fromOffset(0, 24)
		Animator.Tween(root, 0.45, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
		Sound.Play("Open")
	end
	function page:Hide()
		Animator.Tween(root, 0.3, { GroupTransparency = 1, Position = UDim2.fromOffset(0, 16) }).Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and root.GroupTransparency > 0.99 then
				root.Visible = false
			end
		end)
	end
	return page
end

---------------------------------------------------------------- smooth wheel scrolling
-- Tweens CanvasPosition on mouse wheel; horizontal frames scroll sideways.
function UI.SmoothScroll(frame, horizontal)
	local target = 0
	frame.ScrollingEnabled = true
	frame.ScrollBarThickness = 4
	frame.ScrollBarImageColor3 = C.GoldDeep
	frame.ElasticBehavior = Enum.ElasticBehavior.Never
	local hovered = false
	frame.MouseEnter:Connect(function()
		hovered = true
	end)
	frame.MouseLeave:Connect(function()
		hovered = false
	end)
	if horizontal then
		frame.ScrollingDirection = Enum.ScrollingDirection.X
	end
	UserInputService.InputChanged:Connect(function(input)
		if not hovered or not frame.Visible or input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end
		local maxX = math.max(0, frame.AbsoluteCanvasSize.X - frame.AbsoluteWindowSize.X)
		local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteWindowSize.Y)
		if horizontal then
			target = math.clamp(frame.CanvasPosition.X - input.Position.Z * 160, 0, maxX)
			Animator.Tween(frame, 0.35, { CanvasPosition = Vector2.new(target, 0) })
		else
			target = math.clamp(frame.CanvasPosition.Y - input.Position.Z * 140, 0, maxY)
			Animator.Tween(frame, 0.35, { CanvasPosition = Vector2.new(0, target) })
		end
	end)
end

---------------------------------------------------------------- shard counter
function UI.ShardCounter(props)
	local holder = UI.new("Frame", {
		Name = "Shards",
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Position = props.Position,
		Size = UDim2.fromOffset(260, 44),
		BackgroundTransparency = 1,
		Parent = props.Parent,
	})
	UI.diamond({ Parent = holder, Size = 18, Color = C.Accent, Position = UDim2.new(0, 14, 0.5, 0) })
	local amount = UI.label({
		Name = "Amount",
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -36, 0, 26),
		FontFace = Theme.Fonts.Number,
		TextSize = 24,
		TextColor3 = C.GoldLight,
		Text = "0",
		Parent = holder,
	})
	UI.label({
		Position = UDim2.fromOffset(37, 25),
		Size = UDim2.new(1, -36, 0, 16),
		FontFace = Theme.Fonts.Label,
		TextSize = 12,
		TextColor3 = C.TextDim,
		Text = Theme.Spaced("Aether Shards", ""),
		Parent = holder,
	})
	if props.AlignRight then
		holder.AnchorPoint = Vector2.new(1, 0)
	end
	return holder, amount
end

function UI.FormatNumber(n)
	local s = tostring(math.floor(n or 0))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

return UI
