-- Shovel Particles Script (adds particles to shovel based on rebirth level AND upgrade levels)
print("🎨 ShovelParticles script running!")

local tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for services
local getRebirthLevelFunc = ReplicatedStorage:WaitForChild("GetRebirthLevel", 10)
local getUpgradesFunc = ReplicatedStorage:WaitForChild("GetShovelUpgradesFunction", 10)

if not getRebirthLevelFunc then
	warn("❌ GetRebirthLevel function not found!")
	return
end

if not getUpgradesFunc then
	warn("❌ GetShovelUpgradesFunction not found!")
	return
end

-- Rebirth levels particle configuration (must match server)
local REBIRTH_PARTICLES = {
	{ -- Rebirth I - Blue
		color = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
		size = NumberSequence.new(0.3),
		rate = 20
	},
	{ -- Rebirth II - Pink
		color = ColorSequence.new(Color3.fromRGB(255, 150, 255)),
		size = NumberSequence.new(0.4),
		rate = 30
	},
	{ -- Rebirth III - Yellow
		color = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
		size = NumberSequence.new(0.5),
		rate = 40
	},
	{ -- Rebirth IV - Orange/Red gradient
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
		}),
		size = NumberSequence.new(0.6),
		rate = 60
	},
	{ -- Rebirth V - Rainbow
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 127, 0)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 255))
		}),
		size = NumberSequence.new(0.8),
		rate = 100
	}
}

local function applyParticles()
	print("🎨 Applying particles to shovel...")

	-- Get player's rebirth level
	local rebirthLevel = 0
	local success, result = pcall(function()
		return getRebirthLevelFunc:InvokeServer()
	end)

	if success then
		rebirthLevel = result or 0
	else
		warn("❌ Failed to get rebirth level:", result)
		return
	end

	-- Get player's upgrade levels
	local upgrades = {}
	local success2, result2 = pcall(function()
		return getUpgradesFunc:InvokeServer()
	end)

	if success2 then
		upgrades = result2 or {}
	else
		warn("❌ Failed to get upgrades:", result2)
	end

	print("  - Rebirth level:", rebirthLevel)
	print("  - Upgrades:", upgrades)

	-- Find handle
	local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
	if not handle then
		warn("❌ No handle found in tool!")
		return
	end

	print("  - Found handle:", handle.Name)

	-- Remove old particles
	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("ParticleEmitter") or child:IsA("Attachment") and child.Name:find("ParticleAttachment") then
			child:Destroy()
		end
	end

	-- Calculate total upgrade level (for upgrade-based particles)
	local totalUpgradeLevel = 0
	for statName, level in pairs(upgrades) do
		totalUpgradeLevel = totalUpgradeLevel + level
	end

	print("  - Total upgrade level:", totalUpgradeLevel)

	-- REBIRTH PARTICLES (main effect)
	if rebirthLevel > 0 then
		-- Get particle configuration
		local particleConfig = REBIRTH_PARTICLES[math.min(rebirthLevel, #REBIRTH_PARTICLES)]

		-- Create attachment for particles
		local attachment = Instance.new("Attachment")
		attachment.Name = "RebirthParticleAttachment"
		attachment.Position = Vector3.new(0, 2, 0) -- Near the top of the handle
		attachment.Parent = handle

		-- Create particle emitter
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "RebirthParticles"
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = particleConfig.color
		particles.Size = particleConfig.size
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Rate = particleConfig.rate
		particles.Speed = NumberRange.new(2, 4)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.RotSpeed = NumberRange.new(-100, 100)
		particles.Rotation = NumberRange.new(0, 360)
		particles.LightEmission = 1
		particles.LightInfluence = 0
		particles.Parent = attachment

		-- Add glow to handle
		handle.Material = Enum.Material.Neon
		handle.Color = Color3.fromRGB(255, 255, 255)

		-- For rainbow (Rebirth V), animate colors
		if rebirthLevel == 5 then
			task.spawn(function()
				while particles and particles.Parent and tool.Parent do
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV((tick() % 5) / 5, 1, 1)),
						ColorSequenceKeypoint.new(0.5, Color3.fromHSV((tick() % 5 + 2.5) / 5, 1, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV((tick() % 5) / 5, 1, 1))
					})
					handle.Color = Color3.fromHSV((tick() % 5) / 5, 1, 1)
					task.wait(0.1)
				end
			end)
		end

		print("  ✅ Rebirth particles applied!")
	end

	-- UPGRADE PARTICLES (bonus effect based on total upgrade level)
	-- Tiers: 0-50 (none), 51-100 (bronze), 101-200 (silver), 201-300 (gold), 301+ (diamond)
	local upgradeTier = 0
	local upgradeColor = nil
	local upgradeRate = 0

	if totalUpgradeLevel > 300 then
		upgradeTier = 4 -- Diamond
		upgradeColor = ColorSequence.new(Color3.fromRGB(150, 255, 255))
		upgradeRate = 40
	elseif totalUpgradeLevel > 200 then
		upgradeTier = 3 -- Gold
		upgradeColor = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		upgradeRate = 30
	elseif totalUpgradeLevel > 100 then
		upgradeTier = 2 -- Silver
		upgradeColor = ColorSequence.new(Color3.fromRGB(200, 200, 200))
		upgradeRate = 20
	elseif totalUpgradeLevel > 50 then
		upgradeTier = 1 -- Bronze
		upgradeColor = ColorSequence.new(Color3.fromRGB(205, 127, 50))
		upgradeRate = 10
	end

	if upgradeTier > 0 then
		print("  - Upgrade tier:", upgradeTier, "| Total level:", totalUpgradeLevel)

		-- Create attachment for upgrade particles
		local upgradeAttachment = Instance.new("Attachment")
		upgradeAttachment.Name = "UpgradeParticleAttachment"
		upgradeAttachment.Position = Vector3.new(0, -1, 0) -- Near bottom of handle
		upgradeAttachment.Parent = handle

		-- Create upgrade particle emitter
		local upgradeParticles = Instance.new("ParticleEmitter")
		upgradeParticles.Name = "UpgradeParticles"
		upgradeParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
		upgradeParticles.Color = upgradeColor
		upgradeParticles.Size = NumberSequence.new(0.2)
		upgradeParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 1)
		})
		upgradeParticles.Lifetime = NumberRange.new(0.3, 0.6)
		upgradeParticles.Rate = upgradeRate
		upgradeParticles.Speed = NumberRange.new(1, 2)
		upgradeParticles.SpreadAngle = Vector2.new(60, 60)
		upgradeParticles.Rotation = NumberRange.new(0, 360)
		upgradeParticles.LightEmission = 0.5
		upgradeParticles.Parent = upgradeAttachment

		print("  ✅ Upgrade particles applied (Tier", upgradeTier, ")!")
	end

	print("✅ All particles applied!")
end

-- Apply particles when tool is equipped
tool.Equipped:Connect(function()
	print("🔧 Shovel equipped, applying particles...")
	task.wait(0.1) -- Small delay to ensure everything is loaded
	applyParticles()
end)

-- Try to apply particles immediately if already equipped
if tool.Parent and tool.Parent:IsA("Model") then
	task.wait(0.5)
	applyParticles()
end

-- Listen for rebirth level changes and update particles if tool is equipped
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("❌ Could not find leaderstats!")
		return
	end

	local rebirthValue = leaderstats:WaitForChild("Rebirths", 10)

	if rebirthValue then
		print("✅ Listening for rebirth changes...")

		rebirthValue.Changed:Connect(function(newLevel)
			print("🔄 Rebirth level changed to:", newLevel)

			-- Only update if tool is currently equipped
			if tool.Parent and tool.Parent:IsA("Model") then
				print("  - Tool is equipped, updating particles...")
				task.wait(0.1)
				applyParticles()
			else
				print("  - Tool not equipped, will update on next equip")
			end
		end)
	else
		warn("❌ Could not find Rebirths value!")
	end
end)

print("✅ ShovelParticles script loaded!")
