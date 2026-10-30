-- AETHERVEIL · App controller: layers, navigation, play and return-to-menu

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Animator = require(script.Parent.Animator)
local UI = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Backdrop = require(script.Parent.Backdrop)
local Overlay = require(script.Parent.Overlay)
local SettingsApplier = require(script.Parent.SettingsApplier)
local HUD = require(script.Parent.HUD)
local MainMenu = require(script.Parent.MainMenu)
local Pages = script.Parent:WaitForChild("Pages")

local player = Players.LocalPlayer
local DESIGN = Vector2.new(1600, 900)

local App = {}
App.__index = App

function App.Start(gui)
	local self = setmetatable({}, App)
	self.Current = nil
	self.Busy = false

	-- full-screen layers
	local backdropLayer = UI.new("Frame", { Name = "BackdropLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = gui })
	local hudLayer = UI.new("Frame", { Name = "HUDLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = gui })
	local dim = UI.new("Frame", { Name = "PageDim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Colors.Ink, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = gui })
	self.Dim = dim

	-- the canvas is designed at 1600x900 and scaled to fit any screen
	local canvas = UI.new("Frame", {
		Name = "Canvas",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN.X, DESIGN.Y),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = gui,
	})
	local scale = UI.new("UIScale", { Parent = canvas })
	local hudScale = UI.new("UIScale", { Parent = hudLayer })
	local overlayLayer = UI.new("Frame", { Name = "OverlayLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 10, Parent = gui })
	local function fit()
		local vs = gui.AbsoluteSize
		if vs.X < 1 or vs.Y < 1 then
			return
		end
		scale.Scale = math.min(vs.X / DESIGN.X, vs.Y / DESIGN.Y)
		-- HUD keeps its corners on any aspect ratio, so it scales on its own
		hudScale.Scale = math.clamp(math.min(vs.X / DESIGN.X, vs.Y / DESIGN.Y), 0.6, 1.25)
		hudLayer.Size = UDim2.fromOffset(vs.X / hudScale.Scale, vs.Y / hudScale.Scale)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	Backdrop.Init(backdropLayer)
	Overlay.Init(overlayLayer, canvas)
	HUD.Init(hudLayer, self)
	Overlay.ShowLoading("Awakening the veil")
	Overlay.SetProgress(0, "Loading assets…")

	self.Main = MainMenu.new(canvas, self)
	self.Pages = {
		Elements = require(Pages.ElementsPage).new(canvas, self),
		Weaponry = require(Pages.WeaponryPage).new(canvas, self),
		Shop = require(Pages.ShopPage).new(canvas, self),
		Settings = require(Pages.SettingsPage).new(canvas, self),
	}

	-- back with Backspace or gamepad B
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not self.Current then
			return
		end
		if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB then
			self:Back()
		end
	end)

	-- server messages
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Net = require(ReplicatedStorage:WaitForChild("Aetherveil").Shared.Net)
	Net.Get("Toast").OnClientEvent:Connect(function(text, kind)
		Overlay.Toast(text, kind)
	end)

	-- loading: everything must be ready before the menu shows (unless the player skips)
	local skipped = false
	Overlay.SetSkip(function()
		skipped = true
	end)
	local function waitUntil(check, timeout)
		local started = os.clock()
		while not skipped and not check() and os.clock() - started < (timeout or 60) do
			task.wait(0.1)
		end
	end

	-- 1. the game itself
	Overlay.SetProgress(0, "Loading the game…")
	waitUntil(function()
		return game:IsLoaded()
	end)

	-- 2. every asset: the menu world, sounds, interface and the place's own content
	local ContentProvider = game:GetService("ContentProvider")
	local assets = Backdrop.Assets()
	for _, s in ipairs(require(script.Parent.Sound).Preload()) do
		table.insert(assets, s)
	end
	local CONTENT_CLASSES = { "Decal", "Texture", "MeshPart", "SpecialMesh", "Sound", "ParticleEmitter", "Beam", "Trail", "SurfaceAppearance", "Sky", "ImageLabel", "ImageButton", "Animation" }
	local seen = {}
	for _, a in ipairs(assets) do
		seen[a] = true
	end
	for _, root in ipairs({ workspace, game:GetService("Lighting"), game:GetService("SoundService"), game:GetService("ReplicatedStorage"), player:WaitForChild("PlayerGui") }) do
		for _, d in ipairs(root:GetDescendants()) do
			if not seen[d] then
				for _, class in ipairs(CONTENT_CLASSES) do
					if d:IsA(class) then
						seen[d] = true
						table.insert(assets, d)
						break
					end
				end
			end
		end
	end
	local total = #assets
	local done = 0
	local BATCH = 12
	for i = 1, total, BATCH do
		if skipped then
			break
		end
		local batch = {}
		for j = i, math.min(i + BATCH - 1, total) do
			table.insert(batch, assets[j])
		end
		pcall(function()
			ContentProvider:PreloadAsync(batch)
		end)
		done = math.min(total, i + BATCH - 1)
		Overlay.SetProgress(0.7 * done / math.max(total, 1), ("Loading assets… %d / %d"):format(done, total))
	end

	-- 3. the menu world around the camera
	if not skipped then
		Overlay.SetProgress(0.72, "Preparing the world…")
		Backdrop.StreamWorld()
	end

	-- 4. anything else still downloading
	if not skipped then
		local startQueue = math.max(1, ContentProvider.RequestQueueSize)
		waitUntil(function()
			local left = ContentProvider.RequestQueueSize
			Overlay.SetProgress(0.8 + 0.1 * (1 - math.min(left, startQueue) / startQueue), ("Finishing up… %d left"):format(left))
			return left == 0
		end, 45)
	end

	-- 5. the player's profile (needed even when skipping)
	Overlay.SetProgress(0.92, "Summoning your profile…")
	local data = State.WaitForData()
	SettingsApplier.Apply(data.Settings)
	Backdrop.SetElement(data.Element)
	State.Changed:Connect(function(d)
		Backdrop.SetElement(d.Element)
	end)
	Overlay.SetSkip(nil)
	Overlay.SetProgress(1, skipped and "Skipped" or "Ready")
	task.wait(skipped and 0.1 or 0.5)

	if player:GetAttribute("InGame") then
		self:EnterGame()
	else
		self:ShowMenu()
	end
	Overlay.HideLoading()
	return self
end

function App:ShowMenu()
	Backdrop.SetActive(true)
	HUD.Hide()
	self.Current = nil
	self.Main:Show()
end

function App:Open(name, arg)
	local page = self.Pages[name]
	if not page or self.Current == name then
		return
	end
	if self.Current then
		self.Pages[self.Current]:Hide()
	else
		self.Main:Hide()
	end
	self.Current = name
	Animator.Tween(self.Dim, 0.4, { BackgroundTransparency = 0.45 })
	page:Show(arg)
end

function App:Back()
	if not self.Current then
		return
	end
	self.Pages[self.Current]:Hide()
	self.Current = nil
	Animator.Tween(self.Dim, 0.4, { BackgroundTransparency = 1 })
	self.Main:Show()
end

function App:PreviewElement(id)
	Backdrop.Preview(id)
end

function App:EnterGame()
	self.Main:Hide()
	Backdrop.SetActive(false)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		workspace.CurrentCamera.CameraSubject = hum
	end
	HUD.Show()
end

function App:Play()
	if self.Busy then
		return
	end
	local data = State.Data
	if not data or not data.Element then
		Overlay.Toast("Choose an element before entering the Veil.", "error")
		self:Open("Elements")
		return
	end
	self.Busy = true
	Overlay.ShowLoading("Entering the veil")
	local res = State.Request("Play")
	if not res.ok then
		Overlay.HideLoading()
		Overlay.Toast(res.msg, "error")
		self.Busy = false
		if res.code == "NoElement" then
			self:Open("Elements")
		end
		return
	end
	local started = os.clock()
	while not (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) and os.clock() - started < 10 do
		task.wait(0.1)
	end
	self:EnterGame()
	task.wait(0.3)
	Overlay.HideLoading()
	self.Busy = false
end

function App:ReturnToMenu()
	if self.Busy then
		return
	end
	Overlay.Confirm({
		Title = "Return to menu",
		Body = "Leave the battlefield and return to the main menu?",
		Confirm = "LEAVE",
		OnConfirm = function()
			self.Busy = true
			local res = State.Request("ReturnToMenu")
			self.Busy = false
			if not res.ok then
				Overlay.Toast(res.msg, "error")
				return
			end
			self:ShowMenu()
		end,
	})
end

return App
