-- AETHERVEIL · UI animation helpers

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Animator = {}

function Animator.Tween(inst, time, props, style, direction)
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

-- Runs fn(dt, t) every frame until the returned stop function is called.
local steppers = {}
local nextId = 0
local clock = 0
RunService.RenderStepped:Connect(function(dt)
	clock += dt
	for id, fn in pairs(steppers) do
		local ok, err = pcall(fn, dt, clock)
		if not ok then
			steppers[id] = nil
			warn("[Aetherveil UI] " .. tostring(err))
		end
	end
end)

function Animator.Every(fn)
	nextId += 1
	local id = nextId
	steppers[id] = fn
	return function()
		steppers[id] = nil
	end
end

-- Slowly rotating gradient used on rare items and selected cards.
function Animator.Shimmer(gradient, speed)
	return Animator.Every(function(dt)
		if gradient.Parent then
			gradient.Rotation = (gradient.Rotation + dt * (speed or 90)) % 360
		end
	end)
end

-- Gentle breathing transparency on a stroke.
function Animator.Pulse(stroke, low, high, speed)
	return Animator.Every(function(_, t)
		if stroke.Parent then
			local a = (math.sin(t * (speed or 2.4)) + 1) / 2
			stroke.Transparency = low + (high - low) * a
		end
	end)
end

return Animator
