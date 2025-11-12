-- RebirthManager.luau
-- Handles all rebirth system logic

local RebirthManager = {}

local Config = require(script.Parent.Config)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents
local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "RebirthEvent"
rebirthEvent.Parent = ReplicatedStorage

local showWarningEvent = Instance.new("RemoteEvent")
showWarningEvent.Name = "ShowWarningEvent"
showWarningEvent.Parent = ReplicatedStorage

local showRebirthSuccessEvent = Instance.new("RemoteEvent")
showRebirthSuccessEvent.Name = "ShowRebirthSuccess"
showRebirthSuccessEvent.Parent = ReplicatedStorage

-- Create RemoteFunction for getting rebirth level
local getRebirthLevelFunc = Instance.new("RemoteFunction")
getRebirthLevelFunc.Name = "GetRebirthLevel"
getRebirthLevelFunc.Parent = ReplicatedStorage

getRebirthLevelFunc.OnServerInvoke = function(player)
	local rebirthValue = player:FindFirstChild("Rebirths")
	return rebirthValue and rebirthValue.Value or 0
end

-- Function to apply speed boost to player
function RebirthManager.ApplySpeedBoost(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local rebirthValue = leaderstats:FindFirstChild("Rebirths")
	if not rebirthValue then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local totalSpeedBoost = 0

	if rebirthValue.Value > 0 then
		local rebirthLevel = math.min(rebirthValue.Value, #Config.RebirthLevels)
		totalSpeedBoost = Config.RebirthLevels[rebirthLevel].speedBoost
	end

	local newSpeed = Config.Player.BaseSpeed * (1 + totalSpeedBoost)
	humanoid.WalkSpeed = newSpeed
	print("✅ Speed set to", newSpeed, "for", player.Name)
end

-- Function to apply visual effects to player
function RebirthManager.ApplyPlayerEffects(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local rebirthValue = leaderstats:FindFirstChild("Rebirths")
	if not rebirthValue or rebirthValue.Value == 0 then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Remove old effects
	local oldEffects = rootPart:FindFirstChild("RebirthEffects")
	if oldEffects then
		oldEffects:Destroy()
	end

	local rebirthLevel = math.min(rebirthValue.Value, #Config.RebirthLevels)
	local levelData = Config.RebirthLevels[rebirthLevel]

	-- Create effects folder
	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "RebirthEffects"
	effectsFolder.Parent = rootPart

	-- Create aura/glow
	local aura = Instance.new("PointLight")
	aura.Name = "RebirthAura"
	aura.Brightness = 3
	aura.Range = 15 + (rebirthLevel * 5)
	aura.Color = levelData.auraColor
	aura.Parent = effectsFolder

	-- Create sparkles
	local sparkles = Instance.new("Sparkles")
	sparkles.Name = "RebirthSparkles"
	sparkles.SparkleColor = levelData.auraColor
	sparkles.Parent = effectsFolder


	-- Disable rebirth trail visuals (set to true if you ever want to reactivate it)
if false then
	-- Create trail attachment
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailAttachment0"
	attachment0.Position = Vector3.new(0, -2, 0)
	attachment0.Parent = rootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailAttachment1"
	attachment1.Position = Vector3.new(0, 2, 0)
	attachment1.Parent = rootPart

	-- Create trail
	local trail = Instance.new("Trail")
	trail.Name = "RebirthTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(levelData.trailColor)
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	trail.Parent = effectsFolder

	-- For rainbow (Rebirth V), add special rainbow rotation
	if rebirthLevel == 5 then
		task.spawn(function()
			while trail and trail.Parent do
				trail.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV((tick() % 5) / 5, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV((tick() % 5 + 2.5) / 5, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV((tick() % 5) / 5, 1, 1))
				})
				aura.Color = Color3.fromHSV((tick() % 5) / 5, 1, 1)
				sparkles.SparkleColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
				task.wait(0.1)
			end
		end)
	end
end

print("✅ Applied visual effects for", player.Name, "- Rebirth", rebirthLevel)
end

-- Server-side handler for rebirth
function RebirthManager.SetupRebirthHandler()
	rebirthEvent.OnServerEvent:Connect(function(player, requestedLevel)
		print("========================================")
		print("🔄 SERVER: RebirthEvent received!")
		print("  - Player:", player.Name)
		print("  - Requested Level:", requestedLevel)
		print("========================================")

		-- Get player stats
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			warn("❌ Player missing leaderstats!")
			return
		end

		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if not rebirthValue then
			warn("❌ Player missing rebirth value!")
			return
		end

		local poopCount = leaderstats:FindFirstChild("Poops Cleared")
		if not poopCount then
			warn("❌ Player missing poop count!")
			return
		end

		-- Validate requested level
		if not requestedLevel or requestedLevel < 1 or requestedLevel > #Config.RebirthLevels then
			warn("❌ Invalid rebirth level requested!")
			return
		end

		-- Check if this is the next rebirth
		if requestedLevel ~= rebirthValue.Value + 1 then
			warn("❌ Player tried to skip rebirth levels!")
			return
		end

		local levelData = Config.RebirthLevels[requestedLevel]

		-- Check if player has enough poops
		if poopCount.Value < levelData.cost then
			warn("❌ Player doesn't have enough poops:", poopCount.Value, "/", levelData.cost)
			return
		end

		print("✓ Player has enough poops for rebirth!")

		-- Perform rebirth
		rebirthValue.Value = requestedLevel
		poopCount.Value = 0

		print("✅ Rebirth successful! New rebirth level:", rebirthValue.Value)

		-- Apply speed boost and visual effects
		RebirthManager.ApplySpeedBoost(player)
		RebirthManager.ApplyPlayerEffects(player)

		-- Fire success event to client with celebration
		local successData = {
			rebirthLevel = requestedLevel,
			rebirthName = levelData.name,
			poopMultiplier = levelData.poopMultiplier,
			speedBoost = levelData.speedBoost
		}

		print("🎉 Firing rebirth success event to client...")
		showRebirthSuccessEvent:FireClient(player, successData)

		print("========================================")
	end)
end

return RebirthManager
