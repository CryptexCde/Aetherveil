-- AETHERVEIL · Client copy of the player's data + server requests
-- The server is the source of truth; this only mirrors the latest snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Aetherveil"):WaitForChild("Shared"):WaitForChild("Net"))

local State = {}
State.Data = nil

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

local function set(snapshot)
	if type(snapshot) == "table" then
		State.Data = snapshot
		changed:Fire(snapshot)
	end
end

function State.Init()
	Net.Get("Data").OnClientEvent:Connect(set)
	task.spawn(function()
		while not State.Data do
			local res = State.Request("GetSnapshot")
			if res and res.ok and res.data then
				set(res.data)
				break
			end
			task.wait(1)
		end
	end)
end

-- Calls the server. Always returns a table with at least `ok` and maybe `msg`.
function State.Request(action, arg)
	local remote = Net.Get("Request")
	local ok, result = pcall(function()
		return remote:InvokeServer(action, arg)
	end)
	if not ok then
		return { ok = false, msg = "Connection problem. Try again." }
	end
	if type(result) ~= "table" then
		return { ok = false, msg = "No response from the server." }
	end
	return result
end

function State.WaitForData()
	while not State.Data do
		State.Changed:Wait()
	end
	return State.Data
end

return State
