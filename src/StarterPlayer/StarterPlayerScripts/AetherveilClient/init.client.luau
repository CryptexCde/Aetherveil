-- AETHERVEIL · Client entry point
-- Builds the whole interface (main menu, Elements, Weaponry, Shop, Settings, HUD).

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local State = require(script:WaitForChild("State"))
local SettingsApplier = require(script:WaitForChild("SettingsApplier"))
local App = require(script:WaitForChild("App"))

State.Init()
SettingsApplier.Init()
State.Changed:Connect(function(data)
	if not SettingsApplier.Pending then
		SettingsApplier.Apply(data.Settings)
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AetherveilUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

App.Start(gui)
