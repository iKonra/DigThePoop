-- PoopChangerBooth.luau
-- Professional Poop Changer Booth System with Don Poopert NPC
-- Creates a booth where players can sell their poops for coins by holding E

local PoopChangerBooth = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ===============================================
-- CONFIGURATION
-- ===============================================

local BOOTH_POSITION = Vector3.new(25, 3.8, 25) -- Bajado 0.3 desde 4.1
local BOOTH_SCALE = 1.8 -- Scale multiplier for the entire booth (1.8 = 80% bigger)
local BOOTH_HEIGHT_BOOST = 1.15 -- Extra height multiplier to make booth slightly taller (was 1.5, too much)
local POOP_TO_COIN_RATE = 0.1 -- 1 Poop = 0.1 Coin
local SUPERPOOP_TO_COIN_RATE = 1 -- 1 SuperPoop = 1 Coin
local HOLD_DURATION = 1.5 -- Seconds to hold E key
local INTERACTION_DISTANCE = 5 -- Studs

-- ===============================================
-- BOOTH CREATION FUNCTIONS
-- ===============================================

-- Create the wooden booth structure
local function createBoothStructure(boothFolder)
	print("Creating Poop Changer booth structure...")

	-- Helper function to scale size and position
	local function scale(value)
		if typeof(value) == "Vector3" then
			-- Apply height boost to Y component
			return Vector3.new(value.X * BOOTH_SCALE, value.Y * BOOTH_SCALE * BOOTH_HEIGHT_BOOST, value.Z * BOOTH_SCALE)
		end
		return value * BOOTH_SCALE
	end

	-- Base platform
	local basePlatform = Instance.new("Part")
	basePlatform.Name = "BasePlatform"
	basePlatform.Size = scale(Vector3.new(0, 0, 0))
	basePlatform.Position = BOOTH_POSITION + scale(Vector3.new(0, 0.25, 0))
	basePlatform.Anchored = true
	basePlatform.Material = Enum.Material.WoodPlanks
	basePlatform.Color = Color3.fromRGB(163, 116, 81)
	basePlatform.Parent = boothFolder

	-- Counter/Table
	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Size = scale(Vector3.new(0, 0, 0))
	counter.Position = BOOTH_POSITION + scale(Vector3.new(0, 1.5, -3))
	counter.Anchored = true
	counter.Material = Enum.Material.WoodPlanks
	counter.Color = Color3.fromRGB(0, 0, 0)
	counter.Parent = boothFolder

	-- Counter top (polished wood)
	local counterTop = Instance.new("Part")
	counterTop.Name = "CounterTop"
	counterTop.Size = scale(Vector3.new(0, 0, 0))
	counterTop.Position = BOOTH_POSITION + scale(Vector3.new(0, 3.2, -3))
	counterTop.Anchored = true
	counterTop.Material = Enum.Material.Marble
	counterTop.Color = Color3.fromRGB(139, 90, 43)
	counterTop.Parent = boothFolder

	-- Back wall
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Size = scale(Vector3.new(0, 0, 0))
	backWall.Position = BOOTH_POSITION + scale(Vector3.new(0, 3, 2))
	backWall.Anchored = true
	backWall.Material = Enum.Material.WoodPlanks
	backWall.Color = Color3.fromRGB(101, 67, 33)
	backWall.Parent = boothFolder

	-- Left support pillar
	local leftPillar = Instance.new("Part")
	leftPillar.Name = "LeftPillar"
	leftPillar.Size = scale(Vector3.new(0, 0, 0))
	leftPillar.Position = BOOTH_POSITION + scale(Vector3.new(-4.5, 3, -3))
	leftPillar.Anchored = true
	leftPillar.Material = Enum.Material.Wood
	leftPillar.Color = Color3.fromRGB(120, 80, 50)
	leftPillar.Parent = boothFolder

	-- Right support pillar
	local rightPillar = Instance.new("Part")
	rightPillar.Name = "RightPillar"
	rightPillar.Size = scale(Vector3.new(0, 0, 0))
	rightPillar.Position = BOOTH_POSITION + scale(Vector3.new(4.5, 3, -3))
	rightPillar.Anchored = true
	rightPillar.Material = Enum.Material.Wood
	rightPillar.Color = Color3.fromRGB(120, 80, 50)
	rightPillar.Parent = boothFolder

	-- Roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = scale(Vector3.new(0, 0, 0))
	roof.Position = BOOTH_POSITION + scale(Vector3.new(0, 6.3, -0.5))
	roof.Anchored = true
	roof.Material = Enum.Material.Wood
	roof.Color = Color3.fromRGB(100, 70, 45)
	roof.Parent = boothFolder

	-- Sign: "Poop Changer"
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = scale(Vector3.new(0, 0, 0))
	sign.Position = BOOTH_POSITION + scale(Vector3.new(0, 5, -3.5))
	sign.Anchored = true
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(200, 160, 100)
	sign.Parent = boothFolder

	-- Sign text
	local signSurfaceGui = Instance.new("SurfaceGui")
	signSurfaceGui.Face = Enum.NormalId.Front
	signSurfaceGui.Parent = sign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(0, 0, 0, 0)
	signText.BackgroundTransparency = 1
	signText.Font = Enum.Font.FredokaOne
	signText.Text = "Poop Changer"
	signText.TextColor3 = Color3.fromRGB(80, 50, 30)
	signText.TextSize = 60
	signText.TextScaled = true
	signText.Parent = signSurfaceGui

	-- Recycling logo on counter
	local recyclingLogo = Instance.new("Part")
	recyclingLogo.Name = "RecyclingLogo"
	recyclingLogo.Size = scale(Vector3.new(0, 0, 0))
	recyclingLogo.Position = BOOTH_POSITION + scale(Vector3.new(2.5, 3.25, -3))
	recyclingLogo.Anchored = true
	recyclingLogo.Material = Enum.Material.SmoothPlastic
	recyclingLogo.Color = Color3.fromRGB(60, 130, 60)
	recyclingLogo.Parent = boothFolder

	-- Recycling symbol decal
	local logoDecal = Instance.new("Decal")
	logoDecal.Face = Enum.NormalId.Top
	logoDecal.Texture = "rbxassetid://6985915149" -- Recycling symbol
	logoDecal.Parent = recyclingLogo

	print("✓ Booth structure created!")
	return counter
end

-- Create Exchanger model from workspace
local function createExchanger(boothFolder, counter)
	print("Creating Exchanger...")

	-- Helper function to scale (reuse from booth structure)
	local function scale(value)
		if typeof(value) == "Vector3" then
			-- Apply height boost to Y component
			return Vector3.new(value.X * BOOTH_SCALE, value.Y * BOOTH_SCALE * BOOTH_HEIGHT_BOOST, value.Z * BOOTH_SCALE)
		end
		return value * BOOTH_SCALE
	end

		-- Look for exchanger model in workspace
	local tpl = workspace:WaitForChild("Exchanger", 5)
	if not tpl or not tpl:IsA("Model") then
		warn("❌ 'Exchanger' model not found in Workspace (or not a Model)")
		return nil
	end

	local exchanger = tpl:Clone()
	exchanger.Name = "PoopExchanger"
	exchanger.Parent = boothFolder

	-- (Opcional) anclar solo una base si existe; no ancles todo para no romper welds
	local base = exchanger:FindFirstChild("Base") or exchanger:FindFirstChildWhichIsA("BasePart")
	if base then base.Anchored = true end

	-- Posicionar detrás del mostrador: 1.5 arriba, 3 hacia atrás en Z local, mirando al jugador
	local target = counter.CFrame * CFrame.new(-5, 4.5, 10) * CFrame.Angles(0, math.rad(360), 0)
	exchanger:PivotTo(target)

	print("✓ Exchanger positioned!")
	return exchanger

end

-- Create sell zone (invisible interaction trigger)
local function createSellZone(boothFolder)
	print("Creating sell zone...")

	-- Helper function to scale
	local function scale(value)
		if typeof(value) == "Vector3" then
			-- Apply height boost to Y component
			return Vector3.new(value.X * BOOTH_SCALE, value.Y * BOOTH_SCALE * BOOTH_HEIGHT_BOOST, value.Z * BOOTH_SCALE)
		end
		return value * BOOTH_SCALE
	end

	local sellZone = Instance.new("Part")
	sellZone.Name = "SellZone"
	sellZone.Size = scale(Vector3.new(14, 6, 10))
	sellZone.Position = BOOTH_POSITION + scale(Vector3.new(-3, 3, 0))
	sellZone.Anchored = true
	sellZone.CanCollide = false
	sellZone.Transparency = 1
	sellZone.Parent = boothFolder

	-- Add proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "SellPrompt"
	proximityPrompt.ActionText = "Sell Poops"
	proximityPrompt.ObjectText = "Poop Changer"
	proximityPrompt.HoldDuration = HOLD_DURATION
	proximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE * BOOTH_SCALE
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	proximityPrompt.Parent = sellZone

	print("✓ Sell zone created!")
	return sellZone, proximityPrompt
end

-- ===============================================
-- PLAYER DATA & ECONOMY FUNCTIONS
-- ===============================================

-- Setup Coins in leaderstats (doesn't interfere with existing stats)
local function setupCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		warn("❌ Player", player.Name, "has no leaderstats! This shouldn't happen.")
		return
	end

	-- Add Coins if not exists
	if not leaderstats:FindFirstChild("Coins") then
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0
		coins.Parent = leaderstats
		print("✓ Added Coins stat for", player.Name)
	end
end

-- Calculate total sell value
local function calculateSellValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0, 0, 0 end

	local poopsCleared = leaderstats:FindFirstChild("Poops Cleared")
	local superPoops = leaderstats:FindFirstChild("SuperPoops") -- If you track this separately

	-- For now, we'll use "Poops Cleared" as total inventory
	-- You can modify this to differentiate between normal and super poops
	local totalPoops = poopsCleared and poopsCleared.Value or 0

	-- Calculate coins (for simplicity, treating all as normal poops)
	-- You can enhance this to track SuperPoops separately
	local coinsEarned = math.floor(totalPoops * POOP_TO_COIN_RATE)

	return totalPoops, 0, coinsEarned
end

-- Process sell transaction
local function processSell(player, sellZone)
	print("========================================")
	print("💰 Processing sell for:", player.Name)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("❌ Player missing leaderstats!")
		return false
	end

	local poopsCleared = leaderstats:FindFirstChild("Poops Cleared")
	local coins = leaderstats:FindFirstChild("Coins")

	if not poopsCleared or not coins then
		warn("❌ Player missing required stats!")
		return false
	end

	local totalPoops = poopsCleared.Value

	if totalPoops <= 0 then
		print("⚠️ Player has no poops to sell!")
		return false
	end

	-- Calculate earnings
	local coinsEarned = math.floor(totalPoops * POOP_TO_COIN_RATE)

	print("  - Poops to sell:", totalPoops)
	print("  - Coins earned:", coinsEarned)

	-- Execute transaction
	poopsCleared.Value = 0
	coins.Value = coins.Value + coinsEarned

	-- Play effects
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://2697295723" -- Cash register sound
	sound.Volume = 0.5
	sound.Parent = sellZone
	sound:Play()
	task.delay(2, function()
		sound:Destroy()
	end)

	-- Sparkle particles
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 2, 0)
	attachment.Parent = sellZone

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	particles.Size = NumberSequence.new(0.5)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment

	particles.Enabled = true
	task.delay(0.5, function()
		particles.Enabled = false
		task.wait(2)
		attachment:Destroy()
	end)

	print("✅ Sell complete! Player earned", coinsEarned, "coins!")
	print("========================================")

	return true
end

-- ===============================================
-- MAIN INITIALIZATION
-- ===============================================

-- Create poop changer in a specific zone
function PoopChangerBooth.createInZone(position, rotation, parentFolder)
	print("Creating Poop Changer at position:", position)

	-- Temporarily override position
	local originalPos = BOOTH_POSITION
	BOOTH_POSITION = position

	-- Build booth components
	local counter = createBoothStructure(parentFolder)
	local exchanger = createExchanger(parentFolder, counter)

	-- Create sell zone at custom position (same as model + 1 stud up)
	local sellPart = Instance.new("Part")
	sellPart.Name = "SellZone"
	sellPart.Size = Vector3.new(6, 8, 6) * BOOTH_SCALE
	sellPart.Position = position + Vector3.new(0, 1, 0) -- Same position as exchanger, 1 stud up
	sellPart.Transparency = 1
	sellPart.CanCollide = false
	sellPart.Anchored = true
	sellPart.Parent = parentFolder

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Sell Poops"
	proximityPrompt.ObjectText = "Poop Exchanger"
	proximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE * BOOTH_SCALE
	proximityPrompt.HoldDuration = HOLD_DURATION
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = sellPart

	-- Setup proximity prompt handler
	proximityPrompt.Triggered:Connect(function(player)
		print("🎯 Sell prompt triggered by:", player.Name)
		processSell(player, sellPart)
	end)

	-- Restore original position
	BOOTH_POSITION = originalPos

	print("✓ Poop Changer created at custom position")
	return parentFolder
end

function PoopChangerBooth.create()
	print("========================================")
	print("🏪 CREATING POOP CHANGER BOOTH")
	print("========================================")

	-- Create main folder
	local boothFolder = Instance.new("Folder")
	boothFolder.Name = "PoopChangerBooth"
	boothFolder.Parent = workspace

	-- Build booth components
	local counter = createBoothStructure(boothFolder)
	local exchanger = createExchanger(boothFolder, counter)
	local sellZone, proximityPrompt = createSellZone(boothFolder)

	-- Setup proximity prompt handler
	proximityPrompt.Triggered:Connect(function(player)
		print("🎯 Sell prompt triggered by:", player.Name)
		processSell(player, sellZone)
	end)

	-- Setup Coins for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		setupCoins(player)
	end

	-- Setup Coins for new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(1) -- Wait for PlayerManager to create leaderstats first
		setupCoins(player)
	end)

	print("========================================")
	print("✅ POOP CHANGER BOOTH CREATED!")
	print("  - Location:", BOOTH_POSITION)
	print("  - Exchanger: Ready!")
	print("  - Interaction: Hold E to sell")
	print("========================================")

	return boothFolder
end

return PoopChangerBooth
