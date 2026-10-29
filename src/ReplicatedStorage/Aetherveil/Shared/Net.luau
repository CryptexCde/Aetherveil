-- AETHERVEIL · Remote communication
-- Server calls Net.Init() once; both sides use Net.Get(name).
--   Request (RemoteFunction)  client -> server menu actions, returns { ok, msg, ... }
--   Data    (RemoteEvent)     server -> client player snapshot
--   Toast   (RemoteEvent)     server -> client notifications
--   Ability (RemoteEvent)     client -> server elemental ability casts

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local FOLDER_NAME = "AetherveilRemotes"
local DEFS = {
	Request = "RemoteFunction",
	Data = "RemoteEvent",
	Toast = "RemoteEvent",
	Ability = "RemoteEvent",
}

local folder

function Net.Init()
	folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
	end
	for name, class in pairs(DEFS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new(class)
			remote.Name = name
			remote.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
end

function Net.Get(name)
	if not folder then
		folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	end
	return folder:WaitForChild(name)
end

return Net
