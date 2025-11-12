-- TrailEffects.client.luau
-- Handles visual trail effects for equipped rails

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Current trail instances
local currentTrail = nil
local currentParticles = {}
local particleSpawnThread = nil
local createdAttachments = {}

-- Forward declaration
local createParticleEffect

-- ============================================
-- TRAIL CREATION
-- ============================================

local function clearCurrentEffects()
	-- Stop particle spawn thread
	if particleSpawnThread then
		task.cancel(particleSpawnThread)
		particleSpawnThread = nil
	end

	-- Remove existing trail (do NOT remove server-created attachments)
	if currentTrail then
		if currentTrail.Parent then
			-- Only remove attachments that this client created
			for name, created in pairs(createdAttachments) do
				if created then
					local a = humanoidRootPart:FindFirstChild(name)
					if a and a:IsA("Attachment") then a:Destroy() end
				end
			end
			createdAttachments = {}
		end
		currentTrail:Destroy()
		currentTrail = nil
	end

	-- Remove existing particles
	for _, particle in ipairs(currentParticles) do
		if particle and particle.Parent then
			particle:Destroy()
		end
	end
	currentParticles = {}
end

local function createTrail(railConfig)
	clearCurrentEffects()

	if railConfig.name == "None" then
		return -- No trail
	end

	-- Create or reuse trail attachment points
	local attachment0 = humanoidRootPart:FindFirstChild("TrailAttachment0")
	if not attachment0 then
		attachment0 = Instance.new("Attachment")
		attachment0.Name = "TrailAttachment0"
		attachment0.Position = Vector3.new(-1, 0, 0)
		attachment0.Parent = humanoidRootPart
		createdAttachments["TrailAttachment0"] = true
	else
		createdAttachments["TrailAttachment0"] = false
	end

	local attachment1 = humanoidRootPart:FindFirstChild("TrailAttachment1")
	if not attachment1 then
		attachment1 = Instance.new("Attachment")
		attachment1.Name = "TrailAttachment1"
		attachment1.Position = Vector3.new(1, 0, 0)
		attachment1.Parent = humanoidRootPart
		createdAttachments["TrailAttachment1"] = true
	else
		createdAttachments["TrailAttachment1"] = false
	end

	-- If the server already created a trail on the HumanoidRootPart, don't create a duplicate Trail
	local serverTrail = humanoidRootPart:FindFirstChild("PlayerRailTrail")
	if serverTrail then
		-- Server handles the authoritative trail (visible to all). Only add particle effects locally.
		if railConfig.particleEffect then
			createParticleEffect(railConfig.particleEffect, attachment0)
		end
		print("✓ Server-side trail detected; skipping client Trail creation")
		return
	end

	-- Create the trail
	local trail = Instance.new("Trail")
	trail.Name = "RailTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1

	-- Set trail properties
	trail.Lifetime = railConfig.trailLifetime or 1
	trail.MinLength = 0.1
	trail.WidthScale = NumberSequence.new(railConfig.trailWidth or 0.5)

	-- Set transparency (more opaque for rainbow trails)
	if railConfig.colorAnimated then
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0.8)
		})
	else
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
	end

	-- Set color
	if railConfig.colorAnimated then
		-- Animated rainbow trail with smooth gradient
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),      -- Red
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)),  -- Orange
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),  -- Yellow
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),     -- Green
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 127, 255)),  -- Light Blue
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(0, 0, 255)),    -- Blue
			ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 255))      -- Purple
		})
	elseif railConfig.colorGradient then
		-- Gradient trail
		local keypoints = {}
		for i, color in ipairs(railConfig.colorGradient) do
			local time = (i - 1) / (#railConfig.colorGradient - 1)
			table.insert(keypoints, ColorSequenceKeypoint.new(time, color))
		end
		trail.Color = ColorSequence.new(keypoints)
	else
		-- Solid color trail
		local color = railConfig.color or Color3.fromRGB(255, 255, 255)
		trail.Color = ColorSequence.new(color)
	end

	trail.Parent = humanoidRootPart
	currentTrail = trail

	-- Add particle effects if specified
	if railConfig.particleEffect then
		createParticleEffect(railConfig.particleEffect, attachment0)
	end

	print("✓ Trail created:", railConfig.displayName)
end

createParticleEffect = function(effectType, attachment)
	-- Map effect types to emojis
	local emojiMap = {
		sparkles = "✨",
		clover = "🍀",
		lightning = "⚡",
		fire = "🔥",
		ice = "❄️",
		diamond = "💎",
		crown = "👑",
		nebula = "🌠",
		void = "⚫",
		rainbow_infinity = "🌈",
		phoenix = "🔥",
		celestial = "⭐",
		ultimate = "🌟"
	}

	local emoji = emojiMap[effectType] or "✨"

	-- Create emoji particles using BillboardGui (only when moving)
	particleSpawnThread = task.spawn(function()
		while currentTrail do
			-- Check if player is moving
			local velocity = humanoidRootPart.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

			if speed > 1 then -- Only spawn particles when moving
				local part = Instance.new("Part")
				part.Size = Vector3.new(0.1, 0.1, 0.1)
				part.Transparency = 1
				part.CanCollide = false
				part.Anchored = true
				part.Position = attachment.WorldPosition
				part.Parent = workspace

				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.new(0, 50, 0, 50)
				billboard.StudsOffset = Vector3.new(0, 0, 0)
				billboard.AlwaysOnTop = false
				billboard.Parent = part

				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = emoji
				textLabel.TextSize = 40
				textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				textLabel.Parent = billboard

				table.insert(currentParticles, part)

				-- Animate and destroy
				task.spawn(function()
					local startPos = part.Position
					for i = 0, 20 do
						if part and part.Parent then
							part.Position = startPos + Vector3.new(
								math.random(-1, 1) * 0.1,
								i * 0.1,
								math.random(-1, 1) * 0.1
							)
							textLabel.TextTransparency = i / 20
							task.wait(0.05)
						else
							break
						end
					end
					if part and part.Parent then
						part:Destroy()
					end
				end)
			end

			task.wait(0.1) -- Check rate
		end
	end)

	-- Also add traditional particle effects for some types
	if effectType == "sparkles" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
		sparkles.Parent = attachment
		table.insert(currentParticles, sparkles)

	elseif effectType == "fire" then
		local fire = Instance.new("Fire")
		fire.Size = 5
		fire.Heat = 10
		fire.Color = Color3.fromRGB(255, 100, 0)
		fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
		fire.Parent = attachment
		table.insert(currentParticles, fire)
	end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Listen for rail updates from server
local updateRailEvent = ReplicatedStorage:WaitForChild("UpdatePlayerRailEvent", 10)
if updateRailEvent then
	updateRailEvent.OnClientEvent:Connect(function(railConfig)
		print("Received rail update:", railConfig.displayName)
		createTrail(railConfig)
	end)
	print("✓ TrailEffects: Listening for rail updates")
else
	warn("❌ UpdatePlayerRailEvent not found!")
end

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Clear effects on respawn
	clearCurrentEffects()

	-- Request current rail from server
	-- The server should send the equipped rail on spawn
	print("Character respawned, waiting for rail update...")
end)

print("✅ TrailEffects initialized!")
