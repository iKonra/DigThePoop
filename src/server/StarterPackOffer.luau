-- StarterPackOffer.luau
-- Manages the Starter Pack popup offer for new players

local StarterPackOffer = {}

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================
-- CONFIGURATION
-- ============================================

local STARTER_PACK_PRODUCT_ID = 1545562478 -- REPLACE WITH YOUR ACTUAL PRODUCT ID FROM ROBLOX
local STARTER_PACK_PRICE = 79 -- Robux

local STARTER_PACK_REWARDS = {
	Coins = 2000,
	UpgradeLevels = 5, -- 5 levels in each upgrade
	Upgrades = {"PoopCapacity", "WalkSpeed", "PoopMultiplier", "Luck"}
}

-- Track which players have purchased the starter pack
local purchasedPlayers = {}

-- ============================================
-- PRODUCT PURCHASE HANDLER
-- ============================================

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		-- Player left, grant later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Check if it's the starter pack
	if receiptInfo.ProductId == STARTER_PACK_PRODUCT_ID then
		-- Give rewards
		local success = StarterPackOffer.GrantRewards(player)

		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ============================================
-- REWARD GRANTING
-- ============================================

function StarterPackOffer.GrantRewards(player)
	print("========================================")
	print("Granting Starter Pack rewards to", player.Name)
	print("========================================")

	-- Give coins
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + STARTER_PACK_REWARDS.Coins
			print("✓ Granted", STARTER_PACK_REWARDS.Coins, "coins")
		end
	end

	-- Give upgrade levels
	local upgrades = player:FindFirstChild("Upgrades")
	if upgrades then
		for _, upgradeName in ipairs(STARTER_PACK_REWARDS.Upgrades) do
			local upgrade = upgrades:FindFirstChild(upgradeName)
			if upgrade then
				upgrade.Value = upgrade.Value + STARTER_PACK_REWARDS.UpgradeLevels
				print("✓ Granted", STARTER_PACK_REWARDS.UpgradeLevels, "levels to", upgradeName)
			end
		end
	end

	-- Mark as purchased
	purchasedPlayers[player.UserId] = true

	-- Show success message
	local showUpgradeEvent = ReplicatedStorage:FindFirstChild("ShowUpgradeSuccessEvent")
	if showUpgradeEvent then
		showUpgradeEvent:FireClient(player, "STARTER PACK!", "Received 2000 Coins + 5 Levels!")
	end

	print("========================================")
	print("✅ STARTER PACK GRANTED!")
	print("========================================")

	return true
end

-- ============================================
-- CLIENT GUI CREATION
-- ============================================

function StarterPackOffer.ShowPopup(player)
	-- Don't show if already purchased
	if purchasedPlayers[player.UserId] then
		return
	end

	-- Fire event to show popup on client
	local showStarterPackEvent = ReplicatedStorage:FindFirstChild("ShowStarterPackEvent")
	if showStarterPackEvent then
		showStarterPackEvent:FireClient(player, STARTER_PACK_PRICE)
	end
end

-- ============================================
-- SETUP
-- ============================================

function StarterPackOffer.Setup()
	print("========================================")
	print("Setting up Starter Pack Offer...")
	print("========================================")

	-- Set up product purchase handler
	MarketplaceService.ProcessReceipt = processReceipt

	-- Create remote events
	local showStarterPackEvent = Instance.new("RemoteEvent")
	showStarterPackEvent.Name = "ShowStarterPackEvent"
	showStarterPackEvent.Parent = ReplicatedStorage

	local purchaseStarterPackEvent = Instance.new("RemoteEvent")
	purchaseStarterPackEvent.Name = "PurchaseStarterPackEvent"
	purchaseStarterPackEvent.Parent = ReplicatedStorage

	-- Handle purchase requests
	purchaseStarterPackEvent.OnServerEvent:Connect(function(player)
		print("Player", player.Name, "attempting to purchase Starter Pack")

		if purchasedPlayers[player.UserId] then
			warn("Player already purchased Starter Pack")
			return
		end

		-- Prompt purchase
		local success, message = pcall(function()
			if STARTER_PACK_PRODUCT_ID == 0 then
				warn("⚠️ STARTER_PACK_PRODUCT_ID not set! Please configure it in StarterPackOffer.luau")
				-- For testing, grant rewards directly
				StarterPackOffer.GrantRewards(player)
			else
				MarketplaceService:PromptProductPurchase(player, STARTER_PACK_PRODUCT_ID)
			end
		end)

		if not success then
			warn("Failed to prompt purchase:", message)
		end
	end)

	-- Show popup when new players join (after a delay)
	Players.PlayerAdded:Connect(function(player)
		task.wait(5) -- Wait 5 seconds after join

		if player.Parent == Players then
			StarterPackOffer.ShowPopup(player)
		end
	end)

	print("✅ Starter Pack Offer setup complete!")
	print("  - Price:", STARTER_PACK_PRICE, "Robux")
	print("  - Rewards: 2000 Coins + 5 Upgrade Levels")
	if STARTER_PACK_PRODUCT_ID == 0 then
		print("  - ⚠️ WARNING: Product ID not configured!")
	end
	print("========================================")
end

return StarterPackOffer
