-- GearManager.luau
-- Manages player gear/tool ownership and upgrades

local GearManager = {}

local Config = require(script.Parent.Config)
local ShovelManager = require(script.Parent.ShovelManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Storage for player gear data
local playerGearData = {} -- {[player.UserId] = {currentGear = "Start_Shovel", ownedGears = {"Start_Shovel"}}}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get gear config by name
local function getGearConfig(gearName)
	for _, gearData in ipairs(Config.Gears) do
		if gearData.name == gearName then
			return gearData
		end
	end
	return nil
end

-- Get player's current gear
function GearManager.GetPlayerGear(player)
	local userId = player.UserId
	if not playerGearData[userId] then
		-- Initialize with starter gear
		playerGearData[userId] = {
			currentGear = "Start_Shovel",
			ownedGears = {"Start_Shovel"}
		}
	end
	return playerGearData[userId].currentGear
end

-- Get all owned gears for a player
function GearManager.GetOwnedGears(player)
	local userId = player.UserId
	if not playerGearData[userId] then
		playerGearData[userId] = {
			currentGear = "Start_Shovel",
			ownedGears = {"Start_Shovel"}
		}
	end
	return playerGearData[userId].ownedGears
end

-- Check if player owns a gear
function GearManager.OwnsGear(player, gearName)
	local ownedGears = GearManager.GetOwnedGears(player)
	for _, gear in ipairs(ownedGears) do
		if gear == gearName then
			return true
		end
	end
	return false
end

-- ============================================
-- GEAR EQUIPPING
-- ============================================

-- Equip a gear for the player
function GearManager.EquipGear(player, gearName)
	print("========================================")
	print("GearManager: Equipping gear", gearName, "for", player.Name)
	print("========================================")

	-- Check if player owns the gear
	if not GearManager.OwnsGear(player, gearName) then
		warn("Player", player.Name, "does not own gear:", gearName)
		return false
	end

	-- Get gear config
	local gearConfig = getGearConfig(gearName)
	if not gearConfig then
		warn("Gear config not found for:", gearName)
		return false
	end

	-- Update current gear
	local userId = player.UserId
	playerGearData[userId].currentGear = gearName

	-- Give the gear to the player
	ShovelManager.GiveShovelToPlayer(player, gearConfig.modelName, gearConfig)

	print("✅ Gear equipped successfully:", gearName)
	return true
end

-- ============================================
-- GEAR PURCHASING
-- ============================================

-- Purchase a gear
function GearManager.PurchaseGear(player, gearName)
	print("========================================")
	print("GearManager: Purchase request for", gearName, "by", player.Name)
	print("========================================")

	-- Check if already owned
	if GearManager.OwnsGear(player, gearName) then
		warn("Player already owns:", gearName)

		-- Send warning to client
		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, "You already own this gear!")
		end

		return false
	end

	-- Get gear config
	local gearConfig = getGearConfig(gearName)
	if not gearConfig then
		warn("Gear config not found for:", gearName)
		return false
	end

	-- Check rebirth requirement
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("Player has no leaderstats")
		return false
	end

	local rebirthValue = leaderstats:FindFirstChild("Rebirths")
	if not rebirthValue then
		warn("Player has no Rebirths stat")
		return false
	end

	if rebirthValue.Value < gearConfig.requiredRebirth then
		warn("Player doesn't meet rebirth requirement:", gearConfig.requiredRebirth)

		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, string.format("Requires Rebirth %d!", gearConfig.requiredRebirth))
		end

		return false
	end

	-- Check if player has enough coins
	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue then
		warn("Player has no Coins stat")
		return false
	end

	if coinsValue.Value < gearConfig.cost then
		warn("Player doesn't have enough coins:", coinsValue.Value, "/", gearConfig.cost)

		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, string.format("Need %d coins! (You have %d)", gearConfig.cost, coinsValue.Value))
		end

		return false
	end

	-- Deduct coins
	coinsValue.Value = coinsValue.Value - gearConfig.cost
	print("✓ Deducted", gearConfig.cost, "coins. Remaining:", coinsValue.Value)

	-- Add to owned gears
	local userId = player.UserId
	if not playerGearData[userId] then
		playerGearData[userId] = {
			currentGear = "Start_Shovel",
			ownedGears = {"Start_Shovel"}
		}
	end

	table.insert(playerGearData[userId].ownedGears, gearName)
	print("✓ Added gear to owned gears:", gearName)

	-- Auto-equip the new gear
	GearManager.EquipGear(player, gearName)

	-- Show success message
	local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
	if showWarningEvent then
		showWarningEvent:FireClient(player, string.format("Purchased %s! (%s)", gearConfig.displayName, gearConfig.icon))
	end

	print("========================================")
	print("✅ PURCHASE SUCCESSFUL!")
	print("  - Gear:", gearName)
	print("  - Cost:", gearConfig.cost)
	print("  - Remaining coins:", coinsValue.Value)
	print("========================================")

	return true
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Give starter gear to a player
function GearManager.GiveStarterGear(player)
	print("GearManager: Giving starter gear to", player.Name)

	local userId = player.UserId
	playerGearData[userId] = {
		currentGear = "Start_Shovel",
		ownedGears = {"Start_Shovel"}
	}

	-- Wait for character to load
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(1)

	-- Equip starter gear
	local starterGearConfig = Config.Gears[1] -- Start_Shovel
	ShovelManager.GiveShovelToPlayer(player, starterGearConfig.modelName, starterGearConfig)
end

-- Setup remote events
function GearManager.SetupRemoteEvents()
	print("GearManager: Setting up remote events...")

	-- Create purchase event
	local purchaseGearEvent = Instance.new("RemoteEvent")
	purchaseGearEvent.Name = "PurchaseGearEvent"
	purchaseGearEvent.Parent = ReplicatedStorage

	purchaseGearEvent.OnServerEvent:Connect(function(player, gearName)
		print("Received purchase request from", player.Name, "for", gearName)
		GearManager.PurchaseGear(player, gearName)
	end)

	-- Create equip event
	local equipGearEvent = Instance.new("RemoteEvent")
	equipGearEvent.Name = "EquipGearEvent"
	equipGearEvent.Parent = ReplicatedStorage

	equipGearEvent.OnServerEvent:Connect(function(player, gearName)
		print("Received equip request from", player.Name, "for", gearName)
		GearManager.EquipGear(player, gearName)
	end)

	print("✓ Remote events created!")
end

-- Setup for all players
function GearManager.SetupPlayers()
	print("========================================")
	print("GearManager: Setting up players...")
	print("========================================")

	-- Setup existing players
	for _, player in ipairs(game.Players:GetPlayers()) do
		GearManager.GiveStarterGear(player)

		-- Re-equip on respawn
		player.CharacterAdded:Connect(function()
			task.wait(1)
			local currentGear = GearManager.GetPlayerGear(player)
			local gearConfig = getGearConfig(currentGear)
			if gearConfig then
				ShovelManager.GiveShovelToPlayer(player, gearConfig.modelName, gearConfig)
			end
		end)
	end

	-- Setup new players
	game.Players.PlayerAdded:Connect(function(player)
		task.wait(0.5)
		GearManager.GiveStarterGear(player)

		-- Re-equip on respawn
		player.CharacterAdded:Connect(function()
			task.wait(1)
			local currentGear = GearManager.GetPlayerGear(player)
			local gearConfig = getGearConfig(currentGear)
			if gearConfig then
				ShovelManager.GiveShovelToPlayer(player, gearConfig.modelName, gearConfig)
			end
		end)
	end)

	print("✅ GearManager player setup complete!")
end

return GearManager
