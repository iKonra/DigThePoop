-- ZoneManager.luau
-- Manages purchasable zones and zone-specific poops

local ZoneManager = {}

local Config = require(script.Parent.Config)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Storage for player zone data
-- {[player.UserId] = {ownedZones = {"Spawn"}}}
local playerZoneData = {}

-- ============================================
-- ZONE CONFIGURATION
-- ============================================

local ZONES = {
	{
		name = "Spawn",
		displayName = "Spawn Zone",
		description = "The starting area",
		icon = "🏠",
		cost = 0, -- Free
		position = Vector3.new(0, 0, 0), -- Center of spawn
		size = Vector3.new(150, 50, 150), -- Zone boundaries
		spawnPoint = Vector3.new(0, 4.5, 0), -- Subido desde 1 para evitar spawneo bajo el terreno
		poopType = "normal", -- brown poops
		poopMultiplier = 1, -- x1 normal value
		unlocked = true -- Always unlocked
	},
	{
		name = "Desert",
		displayName = "Desert Zone",
		description = "A sandy wasteland with golden poops",
		icon = "🏜️",
		cost = 1000000, -- 1 million coins
		position = Vector3.new(4000, -10, 0), -- Very far to the right, completely separated
		size = Vector3.new(800, 0, 800), -- Large zone (widened)
		spawnPoint = Vector3.new(4000, 74, 0), -- Where players teleport to
		shopPosition = Vector3.new(4053, 71, -5), -- Shop: X=4053 (acercado 7 studs desde 4060), Y=71, Z=-5
		poopChangerPosition = Vector3.new(4027, 67, 8), -- Poop Changer: Y=67 (bajado 1.5 studs más desde 68.5)
		poopType = "golden", -- yellow/golden poops
		poopMultiplier = 10, -- x10 value (cambio de 5 a 10)
		unlocked = false -- Needs to be purchased
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get zone config by name
local function getZoneConfig(zoneName)
	for _, zoneData in ipairs(ZONES) do
		if zoneData.name == zoneName then
			return zoneData
		end
	end
	return nil
end

-- Check if a position is inside a zone
function ZoneManager.GetZoneAtPosition(position)
	for _, zone in ipairs(ZONES) do
		local zoneMin = zone.position - (zone.size / 2)
		local zoneMax = zone.position + (zone.size / 2)

		if position.X >= zoneMin.X and position.X <= zoneMax.X and
		   position.Z >= zoneMin.Z and position.Z <= zoneMax.Z then
			return zone
		end
	end
	return nil -- Not in any zone
end

-- Get all available zones
function ZoneManager.GetAllZones()
	return ZONES
end

-- Get player's owned zones
function ZoneManager.GetOwnedZones(player)
	local userId = player.UserId
	if not playerZoneData[userId] then
		playerZoneData[userId] = {
			ownedZones = {"Spawn"} -- Everyone starts with Spawn
		}
	end
	return playerZoneData[userId].ownedZones
end

-- Check if player owns a zone
function ZoneManager.OwnsZone(player, zoneName)
	local ownedZones = ZoneManager.GetOwnedZones(player)
	for _, zone in ipairs(ownedZones) do
		if zone == zoneName then
			return true
		end
	end
	return false
end

-- ============================================
-- ZONE TELEPORTATION
-- ============================================

function ZoneManager.TeleportToZone(player, zoneName)
	print("========================================")
	print("ZoneManager: Teleport request to", zoneName, "by", player.Name)
	print("========================================")

	-- Check if player owns the zone
	if not ZoneManager.OwnsZone(player, zoneName) then
		warn("Player doesn't own:", zoneName)

		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, "You don't own this zone!")
		end

		return false
	end

	-- Get zone config
	local zoneConfig = getZoneConfig(zoneName)
	if not zoneConfig then
		warn("Zone config not found for:", zoneName)
		return false
	end

	-- Check if zone has spawn point
	if not zoneConfig.spawnPoint then
		warn("Zone has no spawn point:", zoneName)
		return false
	end

	-- Teleport player
	local character = player.Character
	if not character then
		warn("Player has no character")
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("Player has no HumanoidRootPart")
		return false
	end

	humanoidRootPart.CFrame = CFrame.new(zoneConfig.spawnPoint)
	print("✓ Teleported", player.Name, "to", zoneName)

	return true
end

-- ============================================
-- ZONE PURCHASING
-- ============================================

function ZoneManager.PurchaseZone(player, zoneName)
	print("========================================")
	print("ZoneManager: Purchase request for", zoneName, "by", player.Name)
	print("========================================")

	-- Check if already owned
	if ZoneManager.OwnsZone(player, zoneName) then
		warn("Player already owns:", zoneName)

		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, "You already own this zone!")
		end

		return false
	end

	-- Get zone config
	local zoneConfig = getZoneConfig(zoneName)
	if not zoneConfig then
		warn("Zone config not found for:", zoneName)
		return false
	end

	-- Check if zone can be purchased
	if zoneConfig.cost == 0 or zoneConfig.unlocked then
		warn("Zone is free/unlocked, cannot be purchased:", zoneName)
		return false
	end

	-- Check if player has enough coins
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("Player has no leaderstats")
		return false
	end

	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue then
		warn("Player has no Coins stat")
		return false
	end

	if coinsValue.Value < zoneConfig.cost then
		warn("Player doesn't have enough coins:", coinsValue.Value, "/", zoneConfig.cost)

		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, string.format("Need %d coins! (You have %d)", zoneConfig.cost, coinsValue.Value))
		end

		return false
	end

	-- Deduct coins
	coinsValue.Value = coinsValue.Value - zoneConfig.cost
	print("✓ Deducted", zoneConfig.cost, "coins. Remaining:", coinsValue.Value)

	-- Add to owned zones
	local userId = player.UserId
	if not playerZoneData[userId] then
		playerZoneData[userId] = {
			ownedZones = {"Spawn"}
		}
	end

	table.insert(playerZoneData[userId].ownedZones, zoneName)
	print("✓ Added zone to owned zones:", zoneName)

	-- Notify client to unlock zone visibility
	local unlockZoneEvent = ReplicatedStorage:FindFirstChild("UnlockZoneEvent")
	if unlockZoneEvent then
		unlockZoneEvent:FireClient(player, zoneName)
	end

	-- Show success message
	local showUpgradeEvent = ReplicatedStorage:FindFirstChild("ShowUpgradeSuccessEvent")
	if showUpgradeEvent then
		showUpgradeEvent:FireClient(player, "Zone Unlocked", zoneConfig.displayName)
	end

	print("========================================")
	print("✅ ZONE PURCHASE SUCCESSFUL!")
	print("  - Zone:", zoneName)
	print("  - Cost:", zoneConfig.cost)
	print("  - Remaining coins:", coinsValue.Value)
	print("========================================")

	return true
end

-- ============================================
-- ZONE GENERATION
-- ============================================

-- Generate terrain and structures for a zone
function ZoneManager.GenerateZone(zone)
	print("Generating zone:", zone.displayName)

	-- Create zone folder
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = zone.name
	zoneFolder.Parent = workspace

	-- Generate terrain based on zone type
	if zone.name == "Desert" then
		print("Generating desert terrain similar to spawn...")
		local TerrainManager = require(script.Parent.TerrainManager)
		local terrain = workspace.Terrain

		-- Calculate zone boundaries
		local zoneCenterX = zone.position.X / 4 -- Convert to grid coords
		local zoneCenterZ = zone.position.Z / 4
		local zoneHalfSize = zone.size.X / 8 -- Half size in grid units

		-- Generate terrain similar to spawn but with sand (very flat)
		for x = -zoneHalfSize, zoneHalfSize do
			for z = -zoneHalfSize, zoneHalfSize do
				local gridX = math.floor(zoneCenterX + x)
				local gridZ = math.floor(zoneCenterZ + z)

				-- Generate minimal height variation for flat desert
				local height = 15 + math.random(0, 1) -- Very flat terrain (0-1 variation instead of 0-5)

				-- Fill from bottom to height with sand
				for y = 0, height do
					terrain:FillBlock(
						CFrame.new(gridX * 4, y * 4, gridZ * 4),
						Vector3.new(4, 4, 4),
						Enum.Material.Sand
					)
				end
			end
		end

		print("✓ Generated desert terrain with sand")

		-- Build castle walls around the desert zone
		local CastleWalls = require(script.Parent.CastleWalls)
		CastleWalls.BuildAtLocation(zone.position, zone.size.X, zoneFolder)
		print("✓ Built castle walls around desert zone")

		-- Decorate desert spawn with bonfire, logs, rock floor, shop and exchanger
		-- (This includes everything: spawn platform, bonfire, logs, shop, poop changer)
		local SpawnDecorator = require(script.Parent.SpawnDecorator)
		SpawnDecorator.DecorateDesertSpawn()
	end

	-- Create invisible boundary walls if zone is locked
	if not zone.unlocked then
		local boundaryFolder = Instance.new("Folder")
		boundaryFolder.Name = "Boundary"
		boundaryFolder.Parent = zoneFolder

		-- Create walls around the zone
		-- TODO: Create invisible/semi-transparent walls
	end

	print("✓ Zone generated:", zone.displayName)
end

-- ============================================
-- INITIALIZATION
-- ============================================

function ZoneManager.Setup()
	print("ZoneManager: Setting up...")

	-- Generate all zones
	for _, zone in ipairs(ZONES) do
		ZoneManager.GenerateZone(zone)
	end

	-- Create purchase event
	local purchaseZoneEvent = Instance.new("RemoteEvent")
	purchaseZoneEvent.Name = "PurchaseZoneEvent"
	purchaseZoneEvent.Parent = ReplicatedStorage

	purchaseZoneEvent.OnServerEvent:Connect(function(player, zoneName)
		print("Received zone purchase request from", player.Name, "for", zoneName)
		ZoneManager.PurchaseZone(player, zoneName)
	end)

	-- Create teleport event
	local teleportZoneEvent = Instance.new("RemoteEvent")
	teleportZoneEvent.Name = "TeleportZoneEvent"
	teleportZoneEvent.Parent = ReplicatedStorage

	teleportZoneEvent.OnServerEvent:Connect(function(player, zoneName)
		print("Received zone teleport request from", player.Name, "for", zoneName)
		ZoneManager.TeleportToZone(player, zoneName)
	end)

	-- Create get owned zones function
	local getOwnedZonesFunc = Instance.new("RemoteFunction")
	getOwnedZonesFunc.Name = "GetOwnedZonesFunction"
	getOwnedZonesFunc.Parent = ReplicatedStorage

	getOwnedZonesFunc.OnServerInvoke = function(player)
		return ZoneManager.GetOwnedZones(player)
	end

	-- Create get all zones function
	local getAllZonesFunc = Instance.new("RemoteFunction")
	getAllZonesFunc.Name = "GetAllZonesFunction"
	getAllZonesFunc.Parent = ReplicatedStorage

	getAllZonesFunc.OnServerInvoke = function(player)
		return ZONES
	end

	-- Create unlock zone event (for client)
	local unlockZoneEvent = Instance.new("RemoteEvent")
	unlockZoneEvent.Name = "UnlockZoneEvent"
	unlockZoneEvent.Parent = ReplicatedStorage

	print("✓ ZoneManager setup complete!")
end

function ZoneManager.SetupPlayers()
	print("========================================")
	print("ZoneManager: Setting up players...")
	print("========================================")

	-- Setup existing players
	for _, player in ipairs(Players:GetPlayers()) do
		local userId = player.UserId
		playerZoneData[userId] = {
			ownedZones = {"Spawn"}
		}
	end

	-- Setup new players
	Players.PlayerAdded:Connect(function(player)
		local userId = player.UserId
		playerZoneData[userId] = {
			ownedZones = {"Spawn"}
		}
	end)

	print("✅ ZoneManager player setup complete!")
end

-- ============================================
-- DATA PERSISTENCE
-- ============================================

-- Restore owned zones from saved data
function ZoneManager.RestoreOwnedZones(player, ownedZones)
	local userId = player.UserId

	if not playerZoneData[userId] then
		playerZoneData[userId] = {
			ownedZones = {"Spawn"}
		}
	end

	-- Restore owned zones
	playerZoneData[userId].ownedZones = ownedZones or {"Spawn"}

	-- Ensure Spawn is always owned
	if not table.find(playerZoneData[userId].ownedZones, "Spawn") then
		table.insert(playerZoneData[userId].ownedZones, 1, "Spawn")
	end

	print("✓ Restored", #playerZoneData[userId].ownedZones, "zones for", player.Name)
end

return ZoneManager
