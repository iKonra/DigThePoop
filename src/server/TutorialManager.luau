local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TutorialManager = {}

-- Ensure a WelcomeMessageEvent exists in ReplicatedStorage
local WelcomeEvent = ReplicatedStorage:FindFirstChild("WelcomeMessageEvent")
if not WelcomeEvent then
	WelcomeEvent = Instance.new("RemoteEvent")
	WelcomeEvent.Name = "WelcomeMessageEvent"
	WelcomeEvent.Parent = ReplicatedStorage
end

-- Ensure TutorialRemotes folder and its events exist so clients waiting for them don't infinite-yield
local TutorialRemotes = ReplicatedStorage:FindFirstChild("TutorialRemotes")
if not TutorialRemotes then
	TutorialRemotes = Instance.new("Folder")
	TutorialRemotes.Name = "TutorialRemotes"
	TutorialRemotes.Parent = ReplicatedStorage
end

local function ensureRemote(name)
	if not TutorialRemotes:FindFirstChild(name) then
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = TutorialRemotes
	end
end

ensureRemote("ShowTutorialArrow")
ensureRemote("UpdateTutorialProgress")
ensureRemote("ShowTutorialText")
ensureRemote("HideTutorialElements")
ensureRemote("TutorialAction")
-- Simple initialization: send a welcome message to each joining player
function TutorialManager.Initialize()
	Players.PlayerAdded:Connect(function(player)
		-- small delay so client UI can load
		task.wait(1)
		pcall(function()
			WelcomeEvent:FireClient(player)
		end)
	end)
end

return TutorialManager