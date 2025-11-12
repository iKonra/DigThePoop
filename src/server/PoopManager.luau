-- PoopManager.luau
-- Handles all poop spawning, clearing, and management logic

local PoopManager = {}

local Config = require(script.Parent.Config)
local TerrainManager = require(script.Parent.TerrainManager)
local MiniEventManager = require(script.Parent.MiniEventManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TERRAIN_HALF_SIZE = Config.Terrain.TerrainSize / 2

function PoopManager.Initialize()
    -- Create poop folder if it doesn't exist
    poopFolder = workspace:FindFirstChild("Poops")
    if not poopFolder then
        poopFolder = Instance.new("Folder")
        poopFolder.Name = "Poops"
        poopFolder.Parent = workspace
    end
    
    -- Find poop template
    poopTemplate = workspace:FindFirstChild("Poop")
    if not poopTemplate then
        warn("⚠️ Poop template not found in workspace!")
    end
    
    return PoopManager
end

-- Reference to the template poop model
local poopTemplate = nil
local poopFolder = nil

-- Events
local clearPoopEvent = Instance.new("RemoteEvent")
clearPoopEvent.Name = "ClearPoopEvent"
clearPoopEvent.Parent = ReplicatedStorage

local OnPoopCollected = Instance.new("BindableEvent")
PoopManager.OnPoopCollected = OnPoopCollected.Event

function PoopManager.GetNearestPoop(player)
    if not poopFolder then return nil end
    
    local character = player.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local playerPos = humanoidRootPart.Position
    local nearestPoop = nil
    local nearestDistance = math.huge
    
    for _, poop in ipairs(poopFolder:GetChildren()) do
        if poop:IsA("Model") then
            local distance = (poop:GetPivot().Position - playerPos).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPoop = poop
            end
        end
    end
    
    return nearestPoop
end

local showPoopClearedEvent = Instance.new("RemoteEvent")
showPoopClearedEvent.Name = "ShowPoopClearedEvent"
showPoopClearedEvent.Parent = ReplicatedStorage

-- Ensure jackpot/lucky remote exists at server startup so clients can bind listeners reliably
local showLuckyEvent = ReplicatedStorage:FindFirstChild("ShowLuckyEvent")
if not showLuckyEvent then
	showLuckyEvent = Instance.new("RemoteEvent")
	showLuckyEvent.Name = "ShowLuckyEvent"
	showLuckyEvent.Parent = ReplicatedStorage
	print("✓ Created RemoteEvent: ShowLuckyEvent")
end

-- Ensure ShowWarningEvent exists so callers can FireClient without race
local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
if not showWarningEvent then
	showWarningEvent = Instance.new("RemoteEvent")
	showWarningEvent.Name = "ShowWarningEvent"
	showWarningEvent.Parent = ReplicatedStorage
	print("✓ Created RemoteEvent: ShowWarningEvent")
end

-- Function to create a brainrot poop object
local function createBrainrotPoop(position)
	-- Find the template poop if not already found
	if not poopTemplate then
		poopTemplate = workspace:FindFirstChild("Poop")
		if not poopTemplate then
			warn("Poop template not found in workspace! Please add a model named 'Poop'")
			-- Fallback: create a simple poop
			local poop = Instance.new("Part")
			poop.Name = "BrainrotPoop"
			poop.Size = Vector3.new(2, 2.5, 2)
			poop.Position = position
			poop.Anchored = true
			poop.Material = Enum.Material.SmoothPlastic
			poop.Color = Color3.fromRGB(101, 67, 33)
			poop.Shape = Enum.PartType.Ball
			poop.Parent = workspace
			return poop
		end
	end

	-- Clone the poop template
	local poop = poopTemplate:Clone()
	poop.Name = "BrainrotPoop"

	-- Set position and make sure it's anchored
	if poop:IsA("Model") then
		if not poop.PrimaryPart then
			local firstPart = poop:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				poop.PrimaryPart = firstPart
			end
		end

		-- Anchor all parts in the model
		for _, part in ipairs(poop:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		poop.Parent = workspace
		poop:MoveTo(position)
	elseif poop:IsA("BasePart") then
		poop.Position = position
		poop.Anchored = true
		poop.Parent = workspace
	end

	return poop
end

-- Function to create golden poop (for Desert zone)
local function createGoldenPoop(position)
	-- Get zone to use correct multiplier
	local zone = ZoneManager.GetZoneAtPosition(position)
	local zoneMultiplier = (zone and zone.poopMultiplier) or 10 -- Default x10 for golden

	-- Clone the normal poop template but color it golden
	if not poopTemplate then
		poopTemplate = workspace:FindFirstChild("Poop")
		if not poopTemplate then
			warn("Poop template not found in workspace!")
			-- Fallback: create a simple golden poop
			local poop = Instance.new("Part")
			poop.Name = "GoldenPoop"
			poop.Size = Vector3.new(2, 2.5, 2)
			poop.Position = position
			poop.Anchored = true
			poop.Material = Enum.Material.SmoothPlastic
			poop.Color = Color3.fromRGB(255, 220, 100) -- Golden yellow
			poop.Shape = Enum.PartType.Ball
			poop:SetAttribute("PoopType", "golden")
			poop:SetAttribute("ValueMultiplier", zoneMultiplier) -- Use zone multiplier
			poop.Parent = workspace
			return poop
		end
	end

	-- Clone the poop template
	local poop = poopTemplate:Clone()
	poop.Name = "GoldenPoop"

	-- Set position and make sure it's anchored
	if poop:IsA("Model") then
		if not poop.PrimaryPart then
			local firstPart = poop:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				poop.PrimaryPart = firstPart
			end
		end

		-- Anchor all parts and color them golden
		for _, part in ipairs(poop:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.Color = Color3.fromRGB(255, 220, 100) -- Golden yellow
				part.Material = Enum.Material.Neon -- Make it shiny
			end
		end

		poop.Parent = workspace
		poop:MoveTo(position)
	elseif poop:IsA("BasePart") then
		poop.Position = position
		poop.Anchored = true
		poop.Color = Color3.fromRGB(255, 220, 100) -- Golden yellow
		poop.Material = Enum.Material.Neon
		poop.Parent = workspace
	end

	-- Set attributes
	poop:SetAttribute("PoopType", "golden")
	poop:SetAttribute("ValueMultiplier", zoneMultiplier) -- Use zone multiplier (x10)

	return poop
end

-- Function to create golden super poop (for Desert zone - x100 value, 4x size)
local function createGoldenSuperPoop(position)
	-- Get zone to use correct multiplier
	local zone = ZoneManager.GetZoneAtPosition(position)
	local zoneMultiplier = (zone and zone.poopMultiplier) or 10 -- Default x10 for golden
	local superMultiplier = zoneMultiplier * 10 -- x100 (10x the golden poop value)

	-- Clone the normal poop template
	if not poopTemplate then
		poopTemplate = workspace:FindFirstChild("Poop")
	end

	local poop
	if poopTemplate then
		poop = poopTemplate:Clone()
	else
		-- Fallback: create a simple golden super poop
		poop = Instance.new("Part")
		poop.Size = Vector3.new(8, 10, 8) -- 4x bigger (2x2.5x2 * 4)
		poop.Shape = Enum.PartType.Ball
	end

	poop.Name = "GoldenSuperPoop"

	-- Set position and make sure it's anchored
	if poop:IsA("Model") then
		if not poop.PrimaryPart then
			local firstPart = poop:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				poop.PrimaryPart = firstPart
			end
		end

		-- Anchor all parts and make them 4x bigger and golden with effects
		for _, part in ipairs(poop:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.Size = part.Size * 4 -- 4x bigger
				part.Color = Color3.fromRGB(255, 215, 0) -- Bright gold
				part.Material = Enum.Material.Neon -- Shiny and glowing
			end
		end

		poop.Parent = workspace
		poop:MoveTo(position)

		-- Add glow effect
		local targetPart = poop.PrimaryPart or poop:FindFirstChildWhichIsA("BasePart")
		if targetPart then
			local light = Instance.new("PointLight")
			light.Brightness = 5
			light.Range = 30
			light.Color = Color3.fromRGB(255, 215, 0)
			light.Parent = targetPart
		end
	elseif poop:IsA("BasePart") then
		poop.Position = position
		poop.Anchored = true
		poop.Size = poop.Size * 4 -- 4x bigger
		poop.Color = Color3.fromRGB(255, 215, 0)
		poop.Material = Enum.Material.Neon
		poop.Parent = workspace

		-- Add glow
		local light = Instance.new("PointLight")
		light.Brightness = 5
		light.Range = 30
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Parent = poop
	end

	-- Set attributes
	poop:SetAttribute("PoopType", "golden_super")
	poop:SetAttribute("ValueMultiplier", superMultiplier) -- x100

	return poop
end

-- Function to select super poop type based on weighted chances
local function selectSuperPoopType()
	local totalChance = 0
	for _, poopType in ipairs(Config.SuperPoopTypes) do
		totalChance = totalChance + poopType.spawnChance
	end

	local roll = math.random() * totalChance
	local currentChance = 0

	for _, poopType in ipairs(Config.SuperPoopTypes) do
		currentChance = currentChance + poopType.spawnChance
		if roll <= currentChance then
			return poopType
		end
	end

	return Config.SuperPoopTypes[1] -- Fallback
end

-- Function to create a super poop (uses Poop template with special effects)
local function createSuperPoop(position)
	-- Select poop type based on weighted chances
	local poopType = selectSuperPoopType()

	-- Find the template poop if not already found
	local poopTemplate = workspace:FindFirstChild("Poop")
	local superPoop

	if poopTemplate then
		-- Clone the poop template
		superPoop = poopTemplate:Clone()
		superPoop.Name = "SuperPoop"

		-- Set position and make sure it's anchored
		if superPoop:IsA("Model") then
			if not superPoop.PrimaryPart then
				local firstPart = superPoop:FindFirstChildWhichIsA("BasePart")
				if firstPart then
					superPoop.PrimaryPart = firstPart
				end
			end

			-- First, anchor all parts
			for _, part in ipairs(superPoop:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end

			-- Parent to workspace first
			superPoop.Parent = workspace
			superPoop:MoveTo(position)

			-- THEN apply visual effects
			for _, part in ipairs(superPoop:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Material = poopType.material
					part.Color = poopType.color
					part.BrickColor = BrickColor.new(poopType.color)
					part.Reflectance = poopType.reflectance or 0
					part.Transparency = poopType.transparency or 0

					if poopType.material == Enum.Material.Neon then
						local originalSize = part.Size
						part.Size = originalSize * 1.1
					end
				end
			end

			-- Add visual effects to the primary part or first part
			local targetPart = superPoop.PrimaryPart or superPoop:FindFirstChildWhichIsA("BasePart")
			if targetPart then
				-- Point light for glow
				local light = Instance.new("PointLight")
				light.Name = "SuperPoopLight"
				light.Brightness = 3
				light.Range = 12
				light.Color = poopType.lightColor
				light.Shadows = false
				light.Parent = targetPart

				-- Sparkles for extra flair
				local sparkles = Instance.new("Sparkles")
				sparkles.Name = "SuperPoopSparkles"
				sparkles.SparkleColor = poopType.sparkleColor
				sparkles.Parent = targetPart

				-- Add bloom effect with a highlight
				local highlight = Instance.new("Highlight")
				highlight.Name = "SuperPoopHighlight"
				highlight.FillColor = poopType.color
				highlight.OutlineColor = poopType.lightColor
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = superPoop

				-- Animate for rainbow type
				if poopType.animated then
					task.spawn(function()
						while superPoop and superPoop.Parent do
							local hue = (tick() % 5) / 5
							local rainbowColor = Color3.fromHSV(hue, 1, 1)

							for _, part in ipairs(superPoop:GetDescendants()) do
								if part:IsA("BasePart") then
									part.Color = rainbowColor
									part.BrickColor = BrickColor.new(rainbowColor)
								end
							end

							light.Color = rainbowColor
							sparkles.SparkleColor = rainbowColor
							highlight.FillColor = rainbowColor
							highlight.OutlineColor = rainbowColor

							task.wait(0.1)
						end
					end)
				end
			end
		elseif superPoop:IsA("BasePart") then
			superPoop.Position = position
			superPoop.Anchored = true
			superPoop.Parent = workspace
			superPoop.Material = poopType.material
			superPoop.Color = poopType.color
			superPoop.BrickColor = BrickColor.new(poopType.color)
			superPoop.Reflectance = poopType.reflectance or 0
			superPoop.Transparency = poopType.transparency or 0

			-- Add effects
			local light = Instance.new("PointLight")
			light.Name = "SuperPoopLight"
			light.Brightness = 3
			light.Range = 12
			light.Color = poopType.lightColor
			light.Shadows = false
			light.Parent = superPoop

			local sparkles = Instance.new("Sparkles")
			sparkles.Name = "SuperPoopSparkles"
			sparkles.SparkleColor = poopType.sparkleColor
			sparkles.Parent = superPoop

			-- Animate for rainbow type
			if poopType.animated then
				task.spawn(function()
					while superPoop and superPoop.Parent do
						local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
						superPoop.Color = rainbowColor
						superPoop.BrickColor = BrickColor.new(rainbowColor)
						light.Color = rainbowColor
						sparkles.SparkleColor = rainbowColor
						task.wait(0.1)
					end
				end)
			end
		end
	else
		-- Fallback: create simple poop
		superPoop = Instance.new("Part")
		superPoop.Name = "SuperPoop"
		superPoop.Size = Vector3.new(2, 2.5, 2)
		superPoop.Position = position
		superPoop.Anchored = true
		superPoop.Material = poopType.material
		superPoop.Color = poopType.color
		superPoop.BrickColor = BrickColor.new(poopType.color)
		superPoop.Shape = Enum.PartType.Ball
		superPoop.Parent = workspace
		superPoop.Reflectance = poopType.reflectance or 0
		superPoop.Transparency = poopType.transparency or 0

		local light = Instance.new("PointLight")
		light.Name = "SuperPoopLight"
		light.Brightness = 3
		light.Range = 12
		light.Color = poopType.lightColor
		light.Shadows = false
		light.Parent = superPoop

		local sparkles = Instance.new("Sparkles")
		sparkles.Name = "SuperPoopSparkles"
		sparkles.SparkleColor = poopType.sparkleColor
		sparkles.Parent = superPoop

		if poopType.animated then
			task.spawn(function()
				while superPoop and superPoop.Parent do
					local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
					superPoop.Color = rainbowColor
					superPoop.BrickColor = BrickColor.new(rainbowColor)
					light.Color = rainbowColor
					sparkles.SparkleColor = rainbowColor
					task.wait(0.1)
				end
			end)
		end
	end

	-- Set attributes
	superPoop:SetAttribute("RequiredRebirth", poopType.requiredRebirth)
	superPoop:SetAttribute("PoopType", poopType.name)
	superPoop:SetAttribute("Reward", poopType.reward)

	return superPoop
end

-- Function to check if a position is too close to existing poops
local function isTooCloseToExistingPoop(position, minDistance)
	minDistance = minDistance or Config.Poop.MinDistance

	for _, poop in ipairs(poopFolder:GetChildren()) do
		local poopPos
		if poop:IsA("Model") and poop.PrimaryPart then
			poopPos = poop.PrimaryPart.Position
		elseif poop:IsA("Model") then
			local firstPart = poop:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				poopPos = firstPart.Position
			end
		elseif poop:IsA("BasePart") then
			poopPos = poop.Position
		end

		if poopPos then
			local distance = (Vector3.new(position.X, 0, position.Z) - Vector3.new(poopPos.X, 0, poopPos.Z)).Magnitude
			if distance < minDistance then
				return true
			end
		end
	end

	return false
end

-- Function to check if a position is too close to trees
local function isTooCloseToTree(position, minDistance)
	minDistance = minDistance or 15 -- Stay at least 15 studs away from trees

	local treesFolder = workspace:FindFirstChild("Trees")
	if not treesFolder then
		return false -- No trees folder means no trees to avoid
	end

	for _, tree in ipairs(treesFolder:GetChildren()) do
		if tree:IsA("Model") then
			-- Get tree position (trunk or first part)
			local treePos
			if tree.PrimaryPart then
				treePos = tree.PrimaryPart.Position
			else
				local trunk = tree:FindFirstChild("Trunk")
				if trunk and trunk:IsA("BasePart") then
					treePos = trunk.Position
				else
					local firstPart = tree:FindFirstChildWhichIsA("BasePart")
					if firstPart then
						treePos = firstPart.Position
					end
				end
			end

			if treePos then
				-- Check horizontal distance (ignore Y to check ground distance)
				local distance = (Vector3.new(position.X, 0, position.Z) - Vector3.new(treePos.X, 0, treePos.Z)).Magnitude
				if distance < minDistance then
					return true -- Too close to a tree
				end
			end
		end
	end

	return false -- Safe distance from all trees
end

-- Function to spawn a single poop at random location
local function spawnSinglePoop(isSuper, targetZone)
	targetZone = targetZone or nil -- Optional zone parameter

	local spawnBoundary = (TERRAIN_HALF_SIZE - 10) * 4
	local maxAttempts = 10
	local attempt = 0

	-- Get ZoneManager
	local ZoneManager = require(script.Parent.ZoneManager)

	while attempt < maxAttempts do
		attempt = attempt + 1

		local randomX, randomZ

		-- If spawning in a specific zone, use zone boundaries
		if targetZone then
			local halfSize = targetZone.size / 2
			randomX = targetZone.position.X + math.random(-halfSize.X, halfSize.X)
			randomZ = targetZone.position.Z + math.random(-halfSize.Z, halfSize.Z)
		else
			-- Spawn anywhere
			randomX = math.random(-spawnBoundary, spawnBoundary)
			randomZ = math.random(-spawnBoundary, spawnBoundary)
		end

		-- Check if not in spawn area (unless intentionally spawning there)
		local gridX = math.floor(randomX / 4)
		local gridZ = math.floor(randomZ / 4)

		local canSpawn = true
		if not targetZone then
			canSpawn = not TerrainManager.IsInSpawnArea(gridX, gridZ)
		end

		if canSpawn then
			-- Get the terrain height at this position
			local terrainHeight = TerrainManager.GetTerrainHeightAtPosition(randomX, randomZ)

			-- Spawn the poop on top of the terrain (+4 unidades para compensar el terreno elevado)
			local spawnPos = Vector3.new(randomX, terrainHeight + 5.5, randomZ)

			-- Check if too close to existing poops or trees
			if not isTooCloseToExistingPoop(spawnPos) and not isTooCloseToTree(spawnPos) then
				-- Determine what type of poop to spawn based on zone
				local zone = targetZone or ZoneManager.GetZoneAtPosition(spawnPos)

				if zone and zone.poopType == "golden" then
					-- Desert zone: spawn golden or golden super poop
					if isSuper then
						-- Spawn golden super poop (4x size, x100 value)
						local poop = createGoldenSuperPoop(spawnPos)
						poop.Parent = poopFolder
						return poop
					else
						-- Spawn normal golden poop (x10 value)
						local poop = createGoldenPoop(spawnPos)
						poop.Parent = poopFolder
						return poop
					end
				elseif isSuper then
					-- Spawn normal super poop (spawn zone)
					local superPoop = createSuperPoop(spawnPos)
					superPoop.Parent = poopFolder
					return superPoop
				else
					-- Spawn normal brown poop
					local poop = createBrainrotPoop(spawnPos)
					poop.Parent = poopFolder
					return poop
				end
			end
		end
	end

	return nil
end

-- Function to spawn brainrot poop objects around the map
function PoopManager.StartSpawner()
	print("Starting brainrot poop spawner...")

	poopFolder = Instance.new("Folder")
	poopFolder.Name = "BrainrotPoops"
	poopFolder.Parent = workspace

	-- Initial spawn phase
	task.spawn(function()
		print("Phase 1: Initial poop spawning...")
		local currentPoops = 0
		local currentSuperPoops = 0

		while currentPoops < Config.Poop.TargetPoops do
			-- 2% chance to spawn a super poop
			if currentSuperPoops < Config.Poop.TargetSuperPoops and math.random() < 0.05 then
				local superPoop = spawnSinglePoop(true)
				if superPoop then
					currentSuperPoops = currentSuperPoops + 1
					currentPoops = currentPoops + 1
					local poopType = superPoop:GetAttribute("PoopType")
					print("Spawned Super Poop! Type:", poopType)
				end
			else
				local poop = spawnSinglePoop(false)
				if poop then
					currentPoops = currentPoops + 1
				end
			end

			if currentPoops % 50 == 0 then
				print("Spawned", currentPoops, "poops (", currentSuperPoops, "super)...")
			end

			task.wait(Config.Poop.InitialSpawnInterval)
		end

		print("Finished initial spawning:", Config.Poop.TargetPoops, "poops! (", currentSuperPoops, "super poops)")
		print("Phase 2: Continuous respawning active...")
	end)

	-- Continuous respawn phase
	task.spawn(function()
		task.wait(5)

		-- Get ZoneManager for checking desert zone
		local ZoneManager = require(script.Parent.ZoneManager)
		local Players = game:GetService("Players")

		while true do
			task.wait(Config.Poop.RespawnInterval)

			-- Count current poops by zone
			local normalPoopCount = 0
			local superPoopCount = 0
			local goldenPoopCount = 0
			local goldenSuperPoopCount = 0

			for _, poop in ipairs(poopFolder:GetChildren()) do
				if poop.Name == "BrainrotPoop" then
					normalPoopCount = normalPoopCount + 1
				elseif poop.Name == "SuperPoop" then
					superPoopCount = superPoopCount + 1
				elseif poop.Name == "GoldenPoop" then
					local poopType = poop:GetAttribute("PoopType")
					if poopType == "golden_super" then
						goldenSuperPoopCount = goldenSuperPoopCount + 1
					else
						goldenPoopCount = goldenPoopCount + 1
					end
				end
			end

			local totalPoops = normalPoopCount + superPoopCount + goldenPoopCount + goldenSuperPoopCount

			-- Check if there are players in the desert zone
			local playersInDesert = false
			local desertZone = nil
			for _, zone in ipairs(ZoneManager.GetAllZones()) do
				if zone.name == "Desert" then
					desertZone = zone
					break
				end
			end

			if desertZone then
				for _, player in ipairs(Players:GetPlayers()) do
					local character = player.Character
					if character then
						local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
						if humanoidRootPart then
							local zone = ZoneManager.GetZoneAtPosition(humanoidRootPart.Position)
							if zone and zone.name == "Desert" then
								playersInDesert = true
								break
							end
						end
					end
				end
			end

			-- Respawn missing poops
			if totalPoops < Config.Poop.TargetPoops then
				local poopsToSpawn = math.min(10, Config.Poop.TargetPoops - totalPoops)

				for i = 1, poopsToSpawn do
					-- If players are in desert, spawn golden poops there
					if playersInDesert and desertZone then
						-- 5% chance for golden super poop in desert
						if goldenSuperPoopCount < 5 and math.random() < 0.05 then
							local superPoop = spawnSinglePoop(true, desertZone)
							if superPoop then
								goldenSuperPoopCount = goldenSuperPoopCount + 1
							end
						else
							-- Spawn normal golden poop in desert
							spawnSinglePoop(false, desertZone)
						end
					elseif superPoopCount < Config.Poop.TargetSuperPoops and math.random() < 0.02 then
						-- Spawn normal super poop in spawn zone
						local superPoop = spawnSinglePoop(true)
						if superPoop then
							superPoopCount = superPoopCount + 1
						end
					else
						-- Spawn normal brown poop
						spawnSinglePoop(false)
					end
				end

				print("🔄 Respawned poops. Total:", totalPoops + poopsToSpawn, "(super:", superPoopCount, "golden:", goldenPoopCount, "golden_super:", goldenSuperPoopCount, ")")
			end
		end
	end)
end

-- Function to get poop multiplier for a player (exported for use in handler)
-- Includes both rebirth multiplier and gear multiplier
function PoopManager.GetPoopMultiplier(player)
	local rebirthMultiplier = 1
	local gearMultiplier = 1

	-- Get rebirth multiplier
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if rebirthValue and rebirthValue.Value > 0 then
			local rebirthLevel = math.min(rebirthValue.Value, #Config.RebirthLevels)
			rebirthMultiplier = Config.RebirthLevels[rebirthLevel].poopMultiplier
		end
	end

	-- Get gear multiplier from equipped tool
	local character = player.Character
	if character then
		local tool = character:FindFirstChildWhichIsA("Tool")
		if tool then
			gearMultiplier = tool:GetAttribute("PoopMultiplier") or 1
			print("  🔧 Gear multiplier:", gearMultiplier, "from tool:", tool.Name)
		end
	end

	-- Also check backpack if not equipped
	if gearMultiplier == 1 then
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			local tool = backpack:FindFirstChildWhichIsA("Tool")
			if tool then
				gearMultiplier = tool:GetAttribute("PoopMultiplier") or 1
				print("  🔧 Gear multiplier:", gearMultiplier, "from backpack tool:", tool.Name)
			end
		end
	end

	local totalMultiplier = rebirthMultiplier * gearMultiplier
	print("  📊 Total multiplier:", totalMultiplier, "(Rebirth:", rebirthMultiplier, "× Gear:", gearMultiplier, ")")

	return totalMultiplier
end

-- Server-side handler for poop clearing
function PoopManager.SetupClearingHandler()
	clearPoopEvent.OnServerEvent:Connect(function(player, poopInstance)
		print("========================================")
		print("🎯 SERVER: ClearPoopEvent received!")
		print("  - Player:", player.Name)
		print("  - Poop instance:", poopInstance)
		print("========================================")

		-- Validate the request
		if not poopInstance or not poopInstance:IsDescendantOf(workspace) then
			warn("❌ Invalid poop instance from player:", player.Name)
			return
		end

		-- Check if it's actually a poop
		local isNormalPoop = poopInstance.Name == "BrainrotPoop"
		local isSuperPoop = poopInstance.Name == "SuperPoop"
		local isPersonalPoop = poopInstance.Name == "PersonalPoop"

		if not isNormalPoop and not isSuperPoop and not isPersonalPoop then
			warn("❌ Player tried to clear non-poop object:", player.Name)
			return
		end

		-- Check if it's a personal poop that belongs to someone else
		if isPersonalPoop then
			local ownerUserId = poopInstance:GetAttribute("OwnerUserId")
			if ownerUserId and ownerUserId ~= player.UserId then
				warn("❌ Player tried to mine someone else's personal poop!")
				local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
				if showWarningEvent then
					showWarningEvent:FireClient(player, "🔒 This is someone else's poop!")
				end
				return
			end
		end

		-- Check if player can break super poops
		if isSuperPoop then
			local requiredRebirth = poopInstance:GetAttribute("RequiredRebirth") or 3
			local leaderstats = player:FindFirstChild("leaderstats")
			local playerRebirth = leaderstats and leaderstats:FindFirstChild("Rebirths")

			if not playerRebirth or playerRebirth.Value < requiredRebirth then
				local poopType = poopInstance:GetAttribute("PoopType") or "Super"
				local currentRebirth = playerRebirth and playerRebirth.Value or 0
				warn("❌ Player needs rebirth level", requiredRebirth)

				local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
				if showWarningEvent then
					local message = string.format("🔒 %s Poop Locked!\nRequires Rebirth %d to collect.\nYou: %d. Open Rebirth menu to unlock.", poopType, requiredRebirth, currentRebirth)
					showWarningEvent:FireClient(player, message)
				end
				return
			end
		end

		-- Get player position for distance check
		local character = player.Character
		if not character then return end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end

		-- Get poop position
		local poopPos
		if poopInstance:IsA("Model") and poopInstance.PrimaryPart then
			poopPos = poopInstance.PrimaryPart.Position
		elseif poopInstance:IsA("Model") then
			local firstPart = poopInstance:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				poopPos = firstPart.Position
			end
		elseif poopInstance:IsA("BasePart") then
			poopPos = poopInstance.Position
		end

		if not poopPos then return end

		-- Verify distance (anti-exploit check)
		local distance = (poopPos - humanoidRootPart.Position).Magnitude
		if distance > 10 then
			warn("❌ Player too far from poop:", player.Name, "Distance:", distance)
			return
		end

		-- Try triggering a server-wide mini-event (Poop Rain)
		-- 50% chance by default; non-stackable (if an event is active, TryTrigger will return false)
		local triggered = false
		pcall(function()
			-- 0.5% chance per poop (0.005 probability)
			triggered = MiniEventManager.TryTrigger(player, 0.005, 60 * 3)
		end)

		-- Clear the poop and fire collection event
		poopInstance:Destroy()
		OnPoopCollected:Fire(player)

		-- Calculate poop gain
		local poopsToAdd = PoopManager.GetPoopMultiplier(player)

		-- Super poops give custom rewards
		if isSuperPoop then
			local rewardMultiplier = poopInstance:GetAttribute("Reward") or 10
			poopsToAdd = poopsToAdd * rewardMultiplier
		end

		-- Golden poops (Desert zone) give multiplied value
		local valueMultiplier = poopInstance:GetAttribute("ValueMultiplier")
		if valueMultiplier and valueMultiplier > 1 then
			poopsToAdd = poopsToAdd * valueMultiplier
			print("💰 Golden Poop! Value x" .. valueMultiplier .. "!")
		end

		-- LUCKY CHANCES SYSTEM
		local luckyRoll = math.random()
		local luckyMultiplier = 1
		local luckyMessage = nil

		if luckyRoll < 0.001 then
			luckyMultiplier = 1000
			luckyMessage = "🌟 MEGA JACKPOT! 1000x LUCKY! 🌟"
		elseif luckyRoll < 0.005 then
			luckyMultiplier = 100
			luckyMessage = "💎 SUPER LUCKY! 100x! 💎"
		elseif luckyRoll < 0.02 then
			luckyMultiplier = 50
			luckyMessage = "⭐ ULTRA LUCKY! 50x! ⭐"
		elseif luckyRoll < 0.05 then
			luckyMultiplier = 10
			luckyMessage = "✨ LUCKY! 10x! ✨"
		elseif luckyRoll < 0.15 then
			luckyMultiplier = 5
			luckyMessage = "🍀 Lucky! 5x! 🍀"
		elseif luckyRoll < 0.3 then
			luckyMultiplier = 2
			luckyMessage = "⚡ Mini Lucky! 2x! ⚡"
		end

		if luckyMultiplier > 1 then
			poopsToAdd = poopsToAdd * luckyMultiplier
			print("🎰 LUCKY HIT!", luckyMessage, "Total:", poopsToAdd)

			local luckyEvent = ReplicatedStorage:FindFirstChild("ShowLuckyEvent")
			if not luckyEvent then
				luckyEvent = Instance.new("RemoteEvent")
				luckyEvent.Name = "ShowLuckyEvent"
				luckyEvent.Parent = ReplicatedStorage
			end
			luckyEvent:FireClient(player, luckyMessage, luckyMultiplier)
		end

		-- Increment poop counter
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local poopCount = leaderstats:FindFirstChild("Poops Cleared")
			if poopCount then
				-- If a mini-event is active (or just triggered), apply its multiplier
				if MiniEventManager.IsActive() then
					local m = MiniEventManager.GetMultiplier() or 1
					print("🌧️ MiniEvent active! Applying multiplier x"..tostring(m))
					poopsToAdd = poopsToAdd * m
				end
				poopCount.Value = poopCount.Value + poopsToAdd
			end
		end

		-- Send feedback to client
		showPoopClearedEvent:FireClient(player, poopsToAdd)
	end)
end

return PoopManager
