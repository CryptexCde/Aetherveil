-- AETHERVEIL · Loading screen, toasts and confirmation dialogs

local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.UIKit)
local Animator = require(script.Parent.Animator)
local Sound = require(script.Parent.Sound)

local C = Theme.Colors
local Overlay = {}

local loading, loadingText, stopSpin
local progressBox, progressFill, progressTip, progressDetail, progressPercent
local toastHolder
local dialogLayer

function Overlay.Init(fullLayer, canvas)
	---------------------------------------------------------------- loading
	loading = UI.new("CanvasGroup", {
		Name = "Loading",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Ink,
		GroupTransparency = 0,
		ZIndex = 50,
		Parent = fullLayer,
	})
	local center = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 200),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = loading,
	})
	local spinner = UI.diamond({ Parent = center, Size = 30, Color = C.Accent, Position = UDim2.new(0.5, 0, 0, 40), ZIndex = 52 })
	local outer = UI.diamond({ Parent = center, Size = 48, Color = C.GoldDeep, Position = UDim2.new(0.5, 0, 0, 40), Core = false, ZIndex = 52 })
	outer.BackgroundTransparency = 1
	local title = UI.label({
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 0, 44),
		FontFace = Theme.Fonts.Display,
		Text = "A\u{200C}ETHERVEIL",
		TextSize = 40,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 52,
		Parent = center,
	})
	UI.goldText(title)
	loadingText = UI.label({
		Position = UDim2.fromOffset(0, 140),
		Size = UDim2.new(1, 0, 0, 24),
		FontFace = Theme.Fonts.Label,
		Text = "",
		TextSize = 16,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 52,
		Parent = center,
	})
	-- asset loading bar
	progressBox = UI.new("Frame", {
		Name = "Progress",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 178),
		Size = UDim2.fromOffset(380, 40),
		BackgroundTransparency = 1,
		ZIndex = 52,
		Visible = false,
		Parent = center,
	})
	local track = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
		ZIndex = 52,
		Parent = progressBox,
	})
	UI.stroke(track, C.GoldDeep, 1, 0.4)
	progressFill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 53,
		Parent = track,
	})
	UI.gradient(progressFill, ColorSequence.new(C.Accent:Lerp(Color3.new(0, 0, 0), 0.3), C.Accent2))
	progressTip = UI.diamond({ Parent = track, Size = 10, Color = C.Accent2, Position = UDim2.fromScale(0, 0.5), ZIndex = 54 })
	progressDetail = UI.label({
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, -60, 0, 20),
		FontFace = Theme.Fonts.Body,
		Text = "",
		TextSize = 15,
		TextColor3 = C.TextFaint,
		ZIndex = 52,
		Parent = progressBox,
	})
	progressPercent = UI.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 14),
		Size = UDim2.fromOffset(60, 20),
		FontFace = Theme.Fonts.Number,
		Text = "0%",
		TextSize = 14,
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 52,
		Parent = progressBox,
	})

	stopSpin = Animator.Every(function(_, t)
		if loading.Visible then
			spinner.Rotation = 45 + t * 120
			outer.Rotation = 45 - t * 60
			loadingText.TextTransparency = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(t * 3))
		end
	end)

	---------------------------------------------------------------- toasts
	toastHolder = UI.new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 24),
		Size = UDim2.fromOffset(640, 400),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = canvas,
	})
	UI.new("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = toastHolder,
	})

	---------------------------------------------------------------- dialogs
	dialogLayer = UI.new("Frame", {
		Name = "Dialogs",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = canvas,
	})
end

function Overlay.ShowLoading(text)
	loadingText.Text = Theme.Spaced(text or "Loading", " ")
	progressBox.Visible = false
	loading.Visible = true
	Animator.Tween(loading, 0.35, { GroupTransparency = 0 })
end

-- Loading bar: alpha 0..1, detail like "Loading assets… 12 / 48". Pass nil to hide the bar.
function Overlay.SetProgress(alpha, detail)
	if alpha == nil then
		progressBox.Visible = false
		return
	end
	progressBox.Visible = true
	alpha = math.clamp(alpha, 0, 1)
	Animator.Tween(progressFill, 0.25, { Size = UDim2.fromScale(alpha, 1) })
	Animator.Tween(progressTip, 0.25, { Position = UDim2.fromScale(alpha, 0.5) })
	progressPercent.Text = ("%d%%"):format(math.floor(alpha * 100 + 0.5))
	if detail then
		progressDetail.Text = detail
	end
end

function Overlay.SetLoadingText(text)
	loadingText.Text = Theme.Spaced(text, " ")
end

function Overlay.HideLoading()
	Animator.Tween(loading, 0.6, { GroupTransparency = 1 }).Completed:Connect(function()
		if loading.GroupTransparency > 0.99 then
			loading.Visible = false
		end
	end)
end

local toastOrder = 0
local showing = {}
function Overlay.Toast(text, kind)
	if not text or text == "" or showing[text] then
		return
	end
	showing[text] = true
	task.delay(3.4, function()
		showing[text] = nil
	end)
	toastOrder += 1
	local color = kind == "error" and C.Bad or (kind == "success" and C.Good or C.Accent)
	Sound.Play(kind == "error" and "Error" or "Confirm")
	local frame = UI.new("CanvasGroup", {
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.Panel,
		GroupTransparency = 1,
		LayoutOrder = toastOrder,
		ZIndex = 61,
		Parent = toastHolder,
	})
	UI.corner(frame, 4)
	UI.stroke(frame, color, 1.2, 0.1)
	UI.padding(frame, 40, 22, 0, 0)
	UI.diamond({ Parent = frame, Size = 10, Color = color, Position = UDim2.new(0, -20, 0.5, 0), ZIndex = 62 })
	UI.label({
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Theme.Fonts.Body,
		Text = text,
		TextSize = 19,
		TextColor3 = C.Text,
		ZIndex = 62,
		Parent = frame,
	})
	Animator.Tween(frame, 0.35, { GroupTransparency = 0 })
	task.delay(3.2, function()
		Animator.Tween(frame, 0.5, { GroupTransparency = 1 }).Completed:Connect(function()
			frame:Destroy()
		end)
	end)
end

-- Confirmation dialog. opts = { Title, Body, Confirm, Cancel, Color, OnConfirm }
function Overlay.Confirm(opts)
	local color = opts.Color or C.Accent
	local dim = UI.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 41,
		Parent = dialogLayer,
	})
	local box = UI.new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 20),
		Size = UDim2.fromOffset(560, 270),
		BackgroundColor3 = C.Panel,
		GroupTransparency = 1,
		ZIndex = 42,
		Parent = dim,
	})
	UI.corner(box, 6)
	UI.stroke(box, color, 1.5, 0)
	UI.gradient(box, ColorSequence.new(C.PanelHi, C.Panel), nil, 90)
	local title = UI.label({
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 40),
		FontFace = Theme.Fonts.Display,
		Text = string.upper(opts.Title or "Are you sure?"),
		TextSize = 30,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 43,
		Parent = box,
	})
	UI.goldText(title)
	UI.ornament({ Parent = box, Width = 240, Position = UDim2.new(0.5, 0, 0, 78), Color = color })
	UI.label({
		Position = UDim2.fromOffset(40, 96),
		Size = UDim2.new(1, -80, 0, 70),
		FontFace = Theme.Fonts.Body,
		Text = opts.Body or "",
		TextSize = 20,
		TextWrapped = true,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 43,
		Parent = box,
	})

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		Animator.Tween(dim, 0.25, { BackgroundTransparency = 1 })
		Animator.Tween(box, 0.25, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 14) }).Completed:Connect(function()
			dim:Destroy()
		end)
	end
	UI.Button({
		Parent = box,
		Style = "ghost",
		Text = opts.Cancel or "CANCEL",
		TextColor = C.TextDim,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(0.5, -10, 1, -28),
		Size = UDim2.fromOffset(200, 50),
		ZIndex = 43,
		OnClick = close,
	})
	UI.Button({
		Parent = box,
		Style = "primary",
		Color = color,
		Text = opts.Confirm or "CONFIRM",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, 10, 1, -28),
		Size = UDim2.fromOffset(200, 50),
		ZIndex = 43,
		OnClick = function()
			close()
			if opts.OnConfirm then
				opts.OnConfirm()
			end
		end,
	})
	dim.Activated:Connect(close)
	Animator.Tween(dim, 0.3, { BackgroundTransparency = 0.45 })
	Animator.Tween(box, 0.35, { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) })
end

return Overlay
