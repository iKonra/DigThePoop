-- ShopManager.luau
-- Manages the main shop with GUI for buying Gears, Rails, and Zones

local ShopManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(script.Parent.Config)
local MonetizationManager = require(script.Parent.MonetizationManager)

-- ===============================================
-- CONFIGURATION
-- ===============================================

local SHOP_POSITION = Vector3.new(35, 8.2, 10) -- Bajado 0.3 desde 8.5
local SHOP_ROTATION = 0 -- Rotation in degrees (0 = same direction as Poop Changer)
local SHOP_SCALE = 2
local INTERACTION_DISTANCE = 5

-- Shop categories
local CATEGORIES = {"Shovel Upgrades", "Rails", "Zones"}

-- ===============================================
-- HELPER FUNCTIONS
-- ===============================================

-- Format large numbers (1000 -> 1K, 1000000 -> 1M, etc)
local function formatNumber(num)
	if num >= 1000000000 then
		return string.format("%.1fB", num / 1000000000):gsub("%.0", "")
	elseif num >= 1000000 then
		return string.format("%.1fM", num / 1000000):gsub("%.0", "")
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000):gsub("%.0", "")
	else
		return tostring(num)
	end
end

-- ===============================================
-- SHOP STRUCTURE CREATION
-- ===============================================

local function createShopStructure(shopFolder)
	print("Creating shop structure...")

	-- Helper function to scale
	local function scale(value)
		if typeof(value) == "Vector3" then
			return value * SHOP_SCALE
		end
		return value * SHOP_SCALE
	end

	-- Look for Shop model in workspace
	local shopTemplate = workspace:FindFirstChild("Shop")

	if shopTemplate then
		print("✓ Found Shop model in workspace, cloning...")
		local shopModel = shopTemplate:Clone()
		shopModel.Name = "ShopBuilding"

		-- Anchor all parts
		for _, part in ipairs(shopModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		-- Position and rotate the shop
		local rotationCFrame = CFrame.Angles(0, math.rad(SHOP_ROTATION), 0)

		if shopModel:IsA("Model") and shopModel.PrimaryPart then
			shopModel:SetPrimaryPartCFrame(CFrame.new(SHOP_POSITION) * rotationCFrame)
		elseif shopModel:IsA("Model") then
			local firstPart = shopModel:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				shopModel.PrimaryPart = firstPart
				shopModel:SetPrimaryPartCFrame(CFrame.new(SHOP_POSITION) * rotationCFrame)
			end
		end

		shopModel.Parent = shopFolder
		print("✓ Shop building positioned and rotated!")

		return shopModel
	else
		warn("❌ Shop model not found in workspace! Creating basic shop...")

		-- Fallback: create basic shop structure
		local basePlatform = Instance.new("Part")
		basePlatform.Name = "BasePlatform"
		basePlatform.Size = scale(Vector3.new(14, 0.5, 12))
		basePlatform.Position = SHOP_POSITION + scale(Vector3.new(0, 0.25, 0))
		basePlatform.Anchored = true
		basePlatform.Material = Enum.Material.WoodPlanks
		basePlatform.Color = Color3.fromRGB(163, 116, 81)
		basePlatform.Parent = shopFolder

		-- Back wall
		local backWall = Instance.new("Part")
		backWall.Name = "BackWall"
		backWall.Size = scale(Vector3.new(12, 8, 0.5))
		backWall.Position = SHOP_POSITION + scale(Vector3.new(0, 4, 5))
		backWall.Anchored = true
		backWall.Material = Enum.Material.WoodPlanks
		backWall.Color = Color3.fromRGB(101, 67, 33)
		backWall.Parent = shopFolder

		-- Side walls
		local leftWall = Instance.new("Part")
		leftWall.Name = "LeftWall"
		leftWall.Size = scale(Vector3.new(0.5, 8, 10))
		leftWall.Position = SHOP_POSITION + scale(Vector3.new(-6, 4, 0))
		leftWall.Anchored = true
		leftWall.Material = Enum.Material.WoodPlanks
		leftWall.Color = Color3.fromRGB(101, 67, 33)
		leftWall.Parent = shopFolder

		local rightWall = Instance.new("Part")
		rightWall.Name = "RightWall"
		rightWall.Size = scale(Vector3.new(0.5, 8, 10))
		rightWall.Position = SHOP_POSITION + scale(Vector3.new(6, 4, 0))
		rightWall.Anchored = true
		rightWall.Material = Enum.Material.WoodPlanks
		rightWall.Color = Color3.fromRGB(101, 67, 33)
		rightWall.Parent = shopFolder

		-- Roof
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = scale(Vector3.new(13, 0.6, 11))
		roof.Position = SHOP_POSITION + scale(Vector3.new(0, 8.3, 0))
		roof.Anchored = true
		roof.Material = Enum.Material.Slate
		roof.Color = Color3.fromRGB(70, 50, 40)
		roof.Parent = shopFolder

		-- Sign
		local sign = Instance.new("Part")
		sign.Name = "Sign"
		sign.Size = scale(Vector3.new(8, 2, 0.3))
		sign.Position = SHOP_POSITION + scale(Vector3.new(0, 6, -5.2))
		sign.Anchored = true
		sign.Material = Enum.Material.Wood
		sign.Color = Color3.fromRGB(200, 160, 100)
		sign.Parent = shopFolder

		-- Sign text
		local signSurfaceGui = Instance.new("SurfaceGui")
		signSurfaceGui.Face = Enum.NormalId.Front
		signSurfaceGui.Parent = sign

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Font = Enum.Font.FredokaOne
		signText.Text = "SHOP"
		signText.TextColor3 = Color3.fromRGB(80, 50, 30)
		signText.TextSize = 80
		signText.TextScaled = true
		signText.Parent = signSurfaceGui

		return shopFolder
	end
end

-- Create interaction zone
local function createInteractionZone(shopFolder)
	print("Creating shop interaction zone...")

	local function scale(value)
		if typeof(value) == "Vector3" then
			return value * SHOP_SCALE
		end
		return value * SHOP_SCALE
	end

	local interactionZone = Instance.new("Part")
	interactionZone.Name = "InteractionZone"
	interactionZone.Size = scale(Vector3.new(12, 6, 5))
	interactionZone.Position = SHOP_POSITION + scale(Vector3.new(-2, 0.5, 4))
	interactionZone.Anchored = true
	interactionZone.CanCollide = false
	interactionZone.Transparency = 1
	interactionZone.Parent = shopFolder

	-- Add proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "ShopPrompt"
	proximityPrompt.ActionText = "Open Shop"
	proximityPrompt.ObjectText = "Shop"
	proximityPrompt.HoldDuration = 0
	proximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE * SHOP_SCALE
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	proximityPrompt.Parent = interactionZone

	print("✓ Interaction zone created!")
	return interactionZone, proximityPrompt
end

-- ===============================================
-- GUI CREATION
-- ===============================================

-- Create RemoteEvent for GUI communication
local openShopEvent = Instance.new("RemoteEvent")
openShopEvent.Name = "OpenShopEvent"
openShopEvent.Parent = ReplicatedStorage

local closeShopEvent = Instance.new("RemoteEvent")
closeShopEvent.Name = "CloseShopEvent"
closeShopEvent.Parent = ReplicatedStorage

-- RemoteEvent to ask client to open the Game Pass prompt
local promptPassPurchaseEvent = ReplicatedStorage:FindFirstChild("PromptPassPurchaseEvent") or Instance.new("RemoteEvent")
promptPassPurchaseEvent.Name = "PromptPassPurchaseEvent"
promptPassPurchaseEvent.Parent = ReplicatedStorage

-- Function to create shop GUI for a player
local function createShopGUI(player)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Check if GUI already exists
	if playerGui:FindFirstChild("ShopGUI") then
		return playerGui.ShopGUI
	end

	-- Create ScreenGui
	local shopGUI = Instance.new("ScreenGui")
	shopGUI.Name = "ShopGUI"
	shopGUI.ResetOnSpawn = false
	shopGUI.Enabled = false
	shopGUI.Parent = playerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = shopGUI

	-- Add corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 60)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 15)
	titleCorner.Parent = titleBar

	-- Title text
	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -120, 1, 0)
	titleText.Position = UDim2.new(0, 20, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Font = Enum.Font.FredokaOne
	titleText.Text = "🛒 SHOP"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextSize = 32
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0.5, -20)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.FredokaOne
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Category buttons frame
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = "CategoryFrame"
	categoryFrame.Size = UDim2.new(1, -40, 0, 60)
	categoryFrame.Position = UDim2.new(0, 20, 0, 80)
	categoryFrame.BackgroundTransparency = 1
	categoryFrame.Parent = mainFrame

	local categoryLayout = Instance.new("UIListLayout")
	categoryLayout.FillDirection = Enum.FillDirection.Horizontal
	categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	categoryLayout.Padding = UDim.new(0, 10)
	categoryLayout.Parent = categoryFrame

	-- Content frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -40, 1, -180)
	contentFrame.Position = UDim2.new(0, 20, 0, 160)
	contentFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 10)
	contentCorner.Parent = contentFrame

	-- ScrollingFrame for items
	local itemsScrollFrame = Instance.new("ScrollingFrame")
	itemsScrollFrame.Name = "ItemsScrollFrame"
	itemsScrollFrame.Size = UDim2.new(1, -20, 1, -20)
	itemsScrollFrame.Position = UDim2.new(0, 10, 0, 10)
	itemsScrollFrame.BackgroundTransparency = 1
	itemsScrollFrame.BorderSizePixel = 0
	itemsScrollFrame.ScrollBarThickness = 8
	itemsScrollFrame.Visible = false
	itemsScrollFrame.Parent = contentFrame

	local itemsLayout = Instance.new("UIGridLayout")
	itemsLayout.CellSize = UDim2.new(0, 300, 0, 140)
	itemsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	itemsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	itemsLayout.Parent = itemsScrollFrame

	-- Empty message
	local emptyMessage = Instance.new("TextLabel")
	emptyMessage.Name = "EmptyMessage"
	emptyMessage.Size = UDim2.new(1, -40, 1, -40)
	emptyMessage.Position = UDim2.new(0, 20, 0, 20)
	emptyMessage.BackgroundTransparency = 1
	emptyMessage.Font = Enum.Font.Gotham
	emptyMessage.Text = "Select a category above"
	emptyMessage.TextColor3 = Color3.fromRGB(150, 150, 150)
	emptyMessage.TextSize = 24
	emptyMessage.TextWrapped = true
	emptyMessage.Parent = contentFrame

	-- Function to create gear item card
	local function createGearCard(gearData)
		local card = Instance.new("Frame")
		card.Name = gearData.name
		card.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		card.BorderSizePixel = 0

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(100, 100, 110)
		cardStroke.Thickness = 2
		cardStroke.Parent = card

		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 50, 0, 50)
		iconLabel.Position = UDim2.new(0, 10, 0, 10)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.FredokaOne
		iconLabel.Text = gearData.icon
		iconLabel.TextSize = 40
		iconLabel.Parent = card

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -70, 0, 25)
		nameLabel.Position = UDim2.new(0, 65, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.Text = gearData.displayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 20
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -70, 0, 20)
		descLabel.Position = UDim2.new(0, 65, 0, 35)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = gearData.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = card

		-- Stats
		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(1, -20, 0, 30)
		statsLabel.Position = UDim2.new(0, 10, 0, 65)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Font = Enum.Font.Gotham
		statsLabel.Text = string.format("×%d Poops | %.1fx Speed | %d Range",
			gearData.poopMultiplier, gearData.digSpeed, gearData.range)
		statsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		statsLabel.TextSize = 11
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = card

		-- Buy button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(1, -20, 0, 35)
		buyButton.Position = UDim2.new(0, 10, 1, -45)
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
		buyButton.BorderSizePixel = 0
		buyButton.Font = Enum.Font.FredokaOne
		buyButton.Text = string.format("💰 %d Coins", gearData.cost)
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 18
		buyButton.Parent = card

		if gearData.isStarter then
			buyButton.Text = "STARTER GEAR"
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton

		-- Rebirth requirement label
		if gearData.requiredRebirth > 0 then
			local rebirthLabel = Instance.new("TextLabel")
			rebirthLabel.Size = UDim2.new(0, 80, 0, 20)
			rebirthLabel.Position = UDim2.new(1, -90, 0, 5)
			rebirthLabel.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
			rebirthLabel.BorderSizePixel = 0
			rebirthLabel.Font = Enum.Font.GothamBold
			rebirthLabel.Text = string.format("R%d+", gearData.requiredRebirth)
			rebirthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			rebirthLabel.TextSize = 12
			rebirthLabel.Parent = card

			local rebirthCorner = Instance.new("UICorner")
			rebirthCorner.CornerRadius = UDim.new(0, 5)
			rebirthCorner.Parent = rebirthLabel
		end

		-- Buy button click handler
		buyButton.MouseButton1Click:Connect(function()
			if gearData.isStarter then
				return
			end

			-- Fire purchase event to server
			local purchaseEvent = ReplicatedStorage:FindFirstChild("PurchaseGearEvent")
			if purchaseEvent then
				purchaseEvent:FireServer(gearData.name)
			end
		end)

		return card
	end

	-- Forward declarations
	local displayRails
	local displayZones

	-- Function to create rail item card
	local function createRailCard(railData, isOwned, isEquipped, playerCoins, playerRebirths)
		local card = Instance.new("Frame")
		card.Name = railData.name
		card.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		card.BorderSizePixel = 0

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(100, 100, 110)
		cardStroke.Thickness = 2
		cardStroke.Parent = card

		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 50, 0, 50)
		iconLabel.Position = UDim2.new(0, 10, 0, 10)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.FredokaOne
		iconLabel.Text = railData.icon
		iconLabel.TextSize = 40
		iconLabel.Parent = card

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -70, 0, 25)
		nameLabel.Position = UDim2.new(0, 65, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.Text = railData.displayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 20
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -70, 0, 40)
		descLabel.Position = UDim2.new(0, 65, 0, 35)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = railData.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = card

		-- Stats preview (if has bonuses)
		local statsText = ""
		if railData.speedBoost then statsText = statsText .. string.format("+%.0f%% Speed ", railData.speedBoost * 100) end
		if railData.luckyBonus then statsText = statsText .. string.format("+%d%% Lucky ", railData.luckyBonus) end
		if railData.coinBonus then statsText = statsText .. string.format("+%d%% Coins ", railData.coinBonus) end
		if railData.eggBonus then statsText = statsText .. string.format("+%.1f%% Eggs ", railData.eggBonus) end
		if railData.poopMultiplier and railData.poopMultiplier > 1 then
			statsText = statsText .. string.format("+%.0f%% Mult", (railData.poopMultiplier - 1) * 100)
		end

		if statsText ~= "" then
			local statsLabel = Instance.new("TextLabel")
			statsLabel.Size = UDim2.new(1, -20, 0, 20)
			statsLabel.Position = UDim2.new(0, 10, 0, 80)
			statsLabel.BackgroundTransparency = 1
			statsLabel.Font = Enum.Font.GothamBold
			statsLabel.Text = statsText
			statsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
			statsLabel.TextSize = 11
			statsLabel.TextXAlignment = Enum.TextXAlignment.Left
			statsLabel.Parent = card
		end

		-- Buy/Equip button
		local actionButton = Instance.new("TextButton")
		actionButton.Name = "ActionButton"
		actionButton.Size = UDim2.new(1, -20, 0, 35)
		actionButton.Position = UDim2.new(0, 10, 1, -45)
		actionButton.BorderSizePixel = 0
		actionButton.Font = Enum.Font.FredokaOne
		actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		actionButton.TextSize = 18
		actionButton.Parent = card

		-- Check if player can afford and has rebirth
		local canAfford = (playerCoins >= railData.cost) or railData.isPremium
		local hasRebirth = (playerRebirths >= railData.requiredRebirth)
		local canPurchase = canAfford and hasRebirth

		if isEquipped then
			actionButton.Text = "✓ EQUIPPED"
			actionButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			cardStroke.Color = Color3.fromRGB(100, 255, 100)
			cardStroke.Thickness = 3
		elseif isOwned then
			actionButton.Text = "EQUIP"
			actionButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
		elseif railData.isStarter then
			actionButton.Text = "FREE - EQUIP"
			actionButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
		else
			-- Display price with formatted numbers
			if railData.isPremium then
				-- Real regional Game Pass price via ProductInfo
				local passId = MonetizationManager.GetPassIdByName(railData.name)
				local priceText = "BUY"
				if passId and passId ~= 0 then
					local ok, info = pcall(function()
						return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
					end)
					if ok and info and info.PriceInRobux then
						priceText = string.format("BUY - %d R$", info.PriceInRobux)
					end
				end
				actionButton.Text = priceText .. " (Regional Price)"
			else
				actionButton.Text = string.format("BUY - %s Coins", formatNumber(railData.cost))
			end

			-- Set color based on if can purchase
			if canPurchase then
				if railData.isPremium then
					actionButton.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
				else
					actionButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
				end
			else
				if railData.isPremium then
					actionButton.Text = string.format("🔒 %s", actionButton.Text)
				else
					actionButton.Text = string.format("🔒 %s Coins", formatNumber(railData.cost))
				end
				actionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				actionButton.TextColor3 = Color3.fromRGB(120, 120, 120)
				cardStroke.Color = Color3.fromRGB(60, 60, 60)
			end
		end

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = actionButton

		-- Rebirth requirement label
		if railData.requiredRebirth > 0 then
			local rebirthLabel = Instance.new("TextLabel")
			rebirthLabel.Size = UDim2.new(0, 80, 0, 20)
			rebirthLabel.Position = UDim2.new(1, -90, 0, 5)
			rebirthLabel.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
			rebirthLabel.BorderSizePixel = 0
			rebirthLabel.Font = Enum.Font.GothamBold
			rebirthLabel.Text = string.format("R%d+", railData.requiredRebirth)
			rebirthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			rebirthLabel.TextSize = 12
			rebirthLabel.Parent = card

			local rebirthCorner = Instance.new("UICorner")
			rebirthCorner.CornerRadius = UDim.new(0, 5)
			rebirthCorner.Parent = rebirthLabel
		end

-- Button click handler (REEMPLAZA TODO EL HANDLER POR ESTO)
actionButton.MouseButton1Click:Connect(function()
	-- Si ya está equipado, no hagas nada
	if isEquipped then
		return
	end

	-- Estamos en el server: usamos RailManager directo
	local RailManager = require(script.Parent.RailManager)

	-- Si ya es dueño (o es starter), solo equipar
	if isOwned or railData.isStarter then
		local success = RailManager.EquipRail(player, railData.name)
		if success then
			displayRails()
		end
		return
	end

	-- Si no cumple requisitos, mostrar aviso y salir
	if not canPurchase then
		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			if not hasRebirth then
				showWarningEvent:FireClient(player, string.format("Need Rebirth %d!", railData.requiredRebirth))
			elseif not canAfford and not railData.isPremium then
				showWarningEvent:FireClient(player, string.format("Need %d coins!", railData.cost))
			end
		end
		return
	end

	-- Buy rail (premium o normal)
	if railData.isPremium then
		-- 1) PassId por nombre del rail
		local passId = MonetizationManager.GetPassIdByName(railData.name)
		if not passId or passId == 0 then
			warn("Game Pass ID not configured for:", railData.name)
			return
		end

		-- 2) Si YA lo posee, desbloquear/equipar sin abrir prompt
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok and owns then
			if RailManager.GrantPremiumRail then
				RailManager.GrantPremiumRail(player, railData.name)
			elseif RailManager.UnlockRail then
				RailManager.UnlockRail(player, railData.name)
			end
			if RailManager.EquipRail then
				RailManager.EquipRail(player, railData.name)
			end

			local okEvt = ReplicatedStorage:FindFirstChild("ShowUpgradeSuccessEvent")
			if okEvt then
				okEvt:FireClient(player, "🎟️ " .. (railData.displayName or railData.name), "Unlocked!")
			end

			displayRails()
			return
		end

		-- 3) Si NO lo posee, pedir al cliente que abra el prompt
		local evt = ReplicatedStorage:FindFirstChild("PromptPassPurchaseEvent")
		if evt then
			evt:FireClient(player, passId)
		else
			warn("PromptPassPurchaseEvent not found in ReplicatedStorage")
		end
	else
		-- Compra con coins (no premium)
		local success = RailManager.PurchaseRail(player, railData.name)
		if success then
			displayRails()
		end
	end
end)


				

		return card
	end

	-- Function to create zone item card
	local function createZoneCard(zoneData, isOwned, playerCoins)
		local card = Instance.new("Frame")
		card.Name = zoneData.name
		card.Size = UDim2.new(1, -20, 0, 140)
		card.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		card.BorderSizePixel = 0

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(100, 100, 110)
		cardStroke.Thickness = 2
		cardStroke.Parent = card

		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 50, 0, 50)
		iconLabel.Position = UDim2.new(0, 10, 0, 10)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.FredokaOne
		iconLabel.Text = zoneData.icon or "🗺️"
		iconLabel.TextSize = 40
		iconLabel.Parent = card

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -70, 0, 25)
		nameLabel.Position = UDim2.new(0, 65, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.Text = zoneData.displayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 20
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -70, 0, 40)
		descLabel.Position = UDim2.new(0, 65, 0, 35)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = zoneData.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = card

		-- Zone bonuses info
		local bonusText = string.format("×%d Poop Value", zoneData.poopMultiplier or 1)
		local bonusLabel = Instance.new("TextLabel")
		bonusLabel.Size = UDim2.new(1, -20, 0, 20)
		bonusLabel.Position = UDim2.new(0, 10, 0, 80)
		bonusLabel.BackgroundTransparency = 1
		bonusLabel.Font = Enum.Font.GothamBold
		bonusLabel.Text = bonusText
		bonusLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Golden
		bonusLabel.TextSize = 13
		bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
		bonusLabel.Parent = card

		-- Create buttons based on ownership
		if isOwned and zoneData.spawnPoint then
			local teleportButton = Instance.new("TextButton")
			teleportButton.Name = "TeleportButton"
			teleportButton.Size = UDim2.new(0.5, -15, 0, 35)
			teleportButton.Position = UDim2.new(0, 10, 1, -45)
			-- Improved aesthetics: gradient, rounded corners, stroke, icon and scaled text
			teleportButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			teleportButton.BorderSizePixel = 0
			teleportButton.Font = Enum.Font.FredokaOne
			teleportButton.Text = ""
			teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			teleportButton.TextSize = 16
			teleportButton.AutoButtonColor = true

			local teleportCorner = Instance.new("UICorner")
			teleportCorner.CornerRadius = UDim.new(0, 12)
			teleportCorner.Parent = teleportButton

			local teleportStroke = Instance.new("UIStroke")
			teleportStroke.Color = Color3.fromRGB(60, 120, 255)
			teleportStroke.Thickness = 2
			teleportStroke.Parent = teleportButton

			local teleportGradient = Instance.new("UIGradient")
			teleportGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 160, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 100, 220)),
			})
			teleportGradient.Rotation = 90
			teleportGradient.Parent = teleportButton

			-- Icon (left)
			local icon = Instance.new("ImageLabel")
			icon.Name = "TeleportIcon"
			icon.Size = UDim2.new(0, 32, 0, 32)
			icon.Position = UDim2.new(0, 8, 0.5, -16)
			icon.BackgroundTransparency = 1
			icon.Image = "rbxassetid://12941020168" -- use requested house/teleport texture
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Parent = teleportButton

			-- Label (center)
			local tbLabel = Instance.new("TextLabel")
			tbLabel.Name = "TeleportLabel"
			tbLabel.Size = UDim2.new(1, -56, 1, 0)
			tbLabel.Position = UDim2.new(0, 48, 0, 0)
			tbLabel.BackgroundTransparency = 1
			tbLabel.Font = Enum.Font.FredokaOne
			tbLabel.Text = "TELEPORT"
			tbLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			tbLabel.TextSize = 16
			tbLabel.TextXAlignment = Enum.TextXAlignment.Left
			tbLabel.Parent = teleportButton

			-- Subtle hover animation (server side connection; client will still handle visuals)
			teleportButton.MouseEnter:Connect(function()
				pcall(function()
					teleportButton.Size = UDim2.new(0.5, -12, 0, 38)
				end)
			end)
			teleportButton.MouseLeave:Connect(function()
				pcall(function()
					teleportButton.Size = UDim2.new(0.5, -15, 0, 35)
				end)
			end)
			teleportButton.Parent = card

			teleportButton.MouseButton1Click:Connect(function()
				local ZoneManager = require(script.Parent.ZoneManager)
				ZoneManager.TeleportToZone(player, zoneData.name)
			end)

			local ownedLabel = Instance.new("TextLabel")
			ownedLabel.Name = "OwnedLabel"
			ownedLabel.Size = UDim2.new(0.5, -15, 0, 35)
			ownedLabel.Position = UDim2.new(0.5, 5, 1, -45)
			ownedLabel.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			ownedLabel.BorderSizePixel = 0
			ownedLabel.Font = Enum.Font.FredokaOne
			ownedLabel.Text = "✓ OWNED"
			ownedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			ownedLabel.TextSize = 16
			ownedLabel.Parent = card

			local ownedCorner = Instance.new("UICorner")
			ownedCorner.CornerRadius = UDim.new(0, 8)
			ownedCorner.Parent = ownedLabel

			cardStroke.Color = Color3.fromRGB(100, 255, 100)
			cardStroke.Thickness = 3

		else
			-- Show buy button or free zone label
			local actionButton = Instance.new("TextButton")
			actionButton.Name = "ActionButton"
			actionButton.Size = UDim2.new(1, -20, 0, 35)
			actionButton.Position = UDim2.new(0, 10, 1, -45)
			actionButton.BorderSizePixel = 0
			actionButton.Font = Enum.Font.FredokaOne
			actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionButton.TextSize = 18
			actionButton.Parent = card

			if zoneData.cost == 0 or zoneData.unlocked then
				actionButton.Text = "FREE ZONE"
				actionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				-- Check if player can afford
				local canAfford = (playerCoins >= zoneData.cost)

				if canAfford then
					actionButton.Text = string.format("BUY - %s Coins", formatNumber(zoneData.cost))
					actionButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
				else
					actionButton.Text = string.format("🔒 %s Coins", formatNumber(zoneData.cost))
					actionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					actionButton.TextColor3 = Color3.fromRGB(120, 120, 120)
					cardStroke.Color = Color3.fromRGB(60, 60, 60)
				end
			end

			local buyCorner = Instance.new("UICorner")
			buyCorner.CornerRadius = UDim.new(0, 8)
			buyCorner.Parent = actionButton

			-- Button click handler
			actionButton.MouseButton1Click:Connect(function()
				if zoneData.cost == 0 or zoneData.unlocked then
					return -- Free zone, nothing to buy
				end

				-- Check if player can afford
				if playerCoins < zoneData.cost then
					return -- Can't afford, ignore click
				end

				-- We're on the server, so access ZoneManager directly
				local ZoneManager = require(script.Parent.ZoneManager)
				ZoneManager.PurchaseZone(player, zoneData.name)
				task.wait(0.1)
				displayZones()
			end)
		end

		return card
	end

	-- Function to display zones
	displayZones = function()
		-- Clear existing items
		for _, child in ipairs(itemsScrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		-- Get owned zones from ZoneManager (we're on server, so access directly)
		local ZoneManager = require(script.Parent.ZoneManager)
		local ownedZones = ZoneManager.GetOwnedZones(player)

		-- Get player's current coins
		local playerCoins = 0
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coinsValue = leaderstats:FindFirstChild("Coins")
			if coinsValue then
				playerCoins = coinsValue.Value
			end
		end

		-- Helper to check if owned
		local function isOwned(zoneName)
			for _, zone in ipairs(ownedZones) do
				if zone == zoneName then
					return true
				end
			end
			return false
		end

		-- Get all zones directly from ZoneManager
		local allZones = ZoneManager.GetAllZones()

		-- Sort zones by cost (lowest to highest)
		local sortedZones = {}
		for _, zoneData in ipairs(allZones) do
			table.insert(sortedZones, zoneData)
		end

		table.sort(sortedZones, function(a, b)
			return a.cost < b.cost
		end)

		-- Add all zones in sorted order
		for _, zoneData in ipairs(sortedZones) do
			local owned = isOwned(zoneData.name)
			local card = createZoneCard(zoneData, owned, playerCoins)
			card.Parent = itemsScrollFrame
		end

		-- Update canvas size
		itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 20)
		end)
		itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 20)
	end

	-- Function to display rails
	displayRails = function()
		-- Clear existing items
		for _, child in ipairs(itemsScrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		-- Get owned rails from RailManager (we're on server, so access directly)
		local RailManager = require(script.Parent.RailManager)
		local ownedRails = RailManager.GetOwnedRails(player)

		-- Get current equipped rail (first one in list is current)
		local currentRail = ownedRails[1] or "None"

		-- Get player's current coins and rebirths
		local playerCoins = 0
		local playerRebirths = 0
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coinsValue = leaderstats:FindFirstChild("Coins")
			if coinsValue then
				playerCoins = coinsValue.Value
			end

			local rebirthValue = leaderstats:FindFirstChild("Rebirths")
			if rebirthValue then
				playerRebirths = rebirthValue.Value
			end
		end

		-- Helper to check if owned
		local function isOwned(railName)
			for _, owned in ipairs(ownedRails) do
				if owned == railName then
					return true
				end
			end
			return false
		end

		-- Separate premium and normal rails
		local premiumRails = {}
		local normalRails = {}

		for _, railData in ipairs(Config.Rails) do
			if railData.isPremium then
				table.insert(premiumRails, railData)
			else
				table.insert(normalRails, railData)
			end
		end

		-- Sort normal rails by cost (lowest to highest)
		table.sort(normalRails, function(a, b)
			return a.cost < b.cost
		end)

		-- Sort premium rails by robux price (lowest to highest)
		table.sort(premiumRails, function(a, b)
			return (a.robuxPrice or 0) < (b.robuxPrice or 0)
		end)

		-- Add premium rails first (at the top)
		for _, railData in ipairs(premiumRails) do
			local owned = isOwned(railData.name)
			local equipped = (railData.name == currentRail)
			local card = createRailCard(railData, owned, equipped, playerCoins, playerRebirths)
			card.Parent = itemsScrollFrame
		end

		-- Add normal rails after premium
		for _, railData in ipairs(normalRails) do
			local owned = isOwned(railData.name)
			local equipped = (railData.name == currentRail)
			local card = createRailCard(railData, owned, equipped, playerCoins, playerRebirths)
			card.Parent = itemsScrollFrame
		end

		-- Update canvas size
		itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 20)
		end)
		itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 20)
	end

	-- Function to display gears (kept for compatibility, but unused now)
	local function displayGears()
		-- Clear existing items
		for _, child in ipairs(itemsScrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		-- Sort gears by cost (lowest to highest)
		local sortedGears = {}
		for _, gearData in ipairs(Config.Gears) do
			table.insert(sortedGears, gearData)
		end

		table.sort(sortedGears, function(a, b)
			return a.cost < b.cost
		end)

		-- Add all gears in sorted order
		for _, gearData in ipairs(sortedGears) do
			local card = createGearCard(gearData)
			card.Parent = itemsScrollFrame
		end

		-- Update canvas size
		itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 20)
		end)
		itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 20)
	end

	-- Create category buttons
	for i, categoryName in ipairs(CATEGORIES) do
		local categoryButton = Instance.new("TextButton")
		categoryButton.Name = categoryName .. "Button"
		categoryButton.Size = UDim2.new(0, 200, 1, 0)
		categoryButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
		categoryButton.BorderSizePixel = 0
		categoryButton.Font = Enum.Font.FredokaOne
		categoryButton.Text = categoryName
		categoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		categoryButton.TextSize = 22
		categoryButton.Parent = categoryFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 10)
		buttonCorner.Parent = categoryButton

		-- Button click handler
		categoryButton.MouseButton1Click:Connect(function()
			-- Update all buttons
			for _, button in ipairs(categoryFrame:GetChildren()) do
				if button:IsA("TextButton") then
					button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
				end
			end

			-- Highlight selected
			categoryButton.BackgroundColor3 = Color3.fromRGB(100, 180, 220)

			-- Update content
			if categoryName == "Shovel Upgrades" then
				emptyMessage.Visible = true
				itemsScrollFrame.Visible = false
				emptyMessage.Text = "Shovel Upgrades\n\n(Open upgrade menu with right icon 🔨)"
			elseif categoryName == "Rails" then
				emptyMessage.Visible = false
				itemsScrollFrame.Visible = true
				displayRails()
			elseif categoryName == "Zones" then
				emptyMessage.Visible = false
				itemsScrollFrame.Visible = true
				displayZones()
			end
		end)
	end

	-- Close button handler
	closeButton.MouseButton1Click:Connect(function()
		shopGUI.Enabled = false
	end)

	return shopGUI
end

-- ===============================================
-- MAIN INITIALIZATION
-- ===============================================

-- Create shop in a specific zone
function ShopManager.createShopInZone(position, rotation, parentFolder)
	print("Creating shop at position:", position)

	-- Temporarily override position
	local originalPos = SHOP_POSITION
	SHOP_POSITION = position

	-- Create shop structure
	local shopBuilding = createShopStructure(parentFolder)

	-- Create interaction zone at custom position (same as model + 1 stud up)
	local interactionPart = Instance.new("Part")
	interactionPart.Name = "ShopInteraction"
	interactionPart.Size = Vector3.new(8, 8, 8) * SHOP_SCALE
	interactionPart.Position = position + Vector3.new(0, 1, 0) -- Same position as shop, 1 stud up
	interactionPart.Transparency = 1
	interactionPart.CanCollide = false
	interactionPart.Anchored = true
	interactionPart.Parent = parentFolder

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Open Shop"
	proximityPrompt.ObjectText = "Shop"
	proximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE * SHOP_SCALE
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = interactionPart

	-- Setup proximity prompt handler
	proximityPrompt.Triggered:Connect(function(player)
		print("🛒 Player", player.Name, "opened shop")
		local shopGUI = createShopGUI(player)
		shopGUI.Enabled = true
	end)

	-- Restore original position
	SHOP_POSITION = originalPos

	print("✓ Shop created at custom position")
	return parentFolder
end

function ShopManager.create()
	print("========================================")
	print("🏪 CREATING SHOP")
	print("========================================")

	-- Create main folder
	local shopFolder = Instance.new("Folder")
	shopFolder.Name = "Shop"
	shopFolder.Parent = workspace

	-- Build shop
	local shopBuilding = createShopStructure(shopFolder)
	local interactionZone, proximityPrompt = createInteractionZone(shopFolder)

	-- Setup proximity prompt handler
	proximityPrompt.Triggered:Connect(function(player)
		print("🛒 Player", player.Name, "opened shop")

		-- Create GUI if it doesn't exist
		local shopGUI = createShopGUI(player)

		-- Open the GUI
		shopGUI.Enabled = true
	end)

	-- Setup GUI for all players
	for _, player in ipairs(Players:GetPlayers()) do
		createShopGUI(player)
	end

	-- Setup GUI for new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(1)
		createShopGUI(player)
	end)

	print("========================================")
	print("✅ SHOP CREATED!")
	print("  - Location:", SHOP_POSITION)
	print("  - Categories:", table.concat(CATEGORIES, ", "))
	print("========================================")

	return shopFolder
end

return ShopManager
