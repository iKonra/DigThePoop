-- ScoreboardManager.luau
-- Manages leaderboard displays in zones showing top 50 players (GLOBAL via OrderedDataStore)

local ScoreboardManager = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- ============================================
-- CONFIGURATION
-- ============================================

local BOARD_SIZE = Vector3.new(14, 20, 0.5)  -- Made boards larger
local UPDATE_INTERVAL = 60
local MAX_PLAYERS_SHOWN = 100  -- Increased to show top 100 players
local ENTRY_HEIGHT = 45

-- OrderedDataStore names (tienen que matchear lo que actualices desde DataManager)
local ODS_NAMES = {
	["Coins"] = "Global_Coins",
	["Poops Cleared"] = "Global_PoopsCleared",
}

-- Cache simple de nombres para no abusar de GetNameFromUserIdAsync
local NameCache = {}

local function safeGetNameFromUserId(userId)
	if NameCache[userId] then return NameCache[userId] end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and name then
		NameCache[userId] = name
		return name
	end
	return ("User_%d"):format(userId)
end

-- ============================================
-- HELPERS
-- ============================================

local function formatNumber(num)
	if num >= 1_000_000_000 then
		return string.format("%.1fB", num / 1_000_000_000):gsub("%.0", "")
	elseif num >= 1_000_000 then
		return string.format("%.1fM", num / 1_000_000):gsub("%.0", "")
	elseif num >= 1_000 then
		return string.format("%.1fK", num / 1_000):gsub("%.0", "")
	else
		return tostring(num)
	end
end

-- Lee el TOP global desde OrderedDataStore
local function getGlobalTopPlayers(statName, maxCount)
	local odsName = ODS_NAMES[statName]
	if not odsName then
		warn("ODS name not configured for stat:", statName)
		return {}
	end

	local ods = DataStoreService:GetOrderedDataStore(odsName)

	-- ascending=false para traer los mayores primero
	local pages
	local ok, err = pcall(function()
		pages = ods:GetSortedAsync(false, maxCount)
	end)
	if not ok then
		warn(("Failed to read ODS %s: %s"):format(odsName, tostring(err)))
		return {}
	end

	local top = {}
	local page = pages:GetCurrentPage()
	for _, item in ipairs(page) do
		local userId = tonumber(item.key)
		local value = tonumber(item.value) or 0
		if userId then
			table.insert(top, {
				Name = safeGetNameFromUserId(userId),
				UserId = userId,
				Value = value,
			})
		end
	end

	return top
end

-- ============================================
-- UI CREATION
-- ============================================

local function createScoreboardStructure(position, title, parentFolder)
	local board = Instance.new("Part")
	board.Name = title .. "Board"
	board.Size = BOARD_SIZE
	board.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)
	board.Anchored = true
	board.Material = Enum.Material.SmoothPlastic
	board.Color = Color3.fromRGB(30, 30, 35)
	board.CanCollide = false
	board.Transparency = 0.1  -- Slightly transparent for better visibility
	board.Parent = parentFolder

	local borderPart = Instance.new("Part")
	borderPart.Name = "Border"
	borderPart.Size = BOARD_SIZE + Vector3.new(0.3, 0.3, -0.1)
	borderPart.CFrame = board.CFrame * CFrame.new(0, 0, 0.15)
	borderPart.Anchored = true
	borderPart.Material = Enum.Material.Wood
	borderPart.Color = Color3.fromRGB(101, 67, 33)
	borderPart.CanCollide = false
	borderPart.Parent = parentFolder

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
	surfaceGui.AlwaysOnTop = false
	surfaceGui.MaxDistance = 100
	surfaceGui.Parent = board

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.BorderSizePixel = 0
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.Text = title .. " ⬆⬇"  -- Añadido indicador de scroll
	titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextSize = 36
	titleLabel.TextScaled = false
	titleLabel.Parent = surfaceGui

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerList"
	scrollFrame.Size = UDim2.new(1, -8, 1, -60)  -- Added padding for scrollbar
	scrollFrame.Position = UDim2.new(0, 4, 0, 60)  -- Centered with padding
	scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8  -- Slimmer but visible scrollbar
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)  -- Gold scrollbar
	scrollFrame.ScrollBarImageTransparency = 0.2  -- More visible
	scrollFrame.ScrollingEnabled = true
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y  -- Auto-adjust canvas
	scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always  -- Smooth elastic scrolling
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = surfaceGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "ListLayout"
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)

	return board, scrollFrame
end

local function createPlayerEntry(rank, playerData, statType)
	local entry = Instance.new("Frame")
	entry.Name = "Player_" .. rank
	entry.Size = UDim2.new(1, -4, 0, ENTRY_HEIGHT)
	entry.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	entry.BorderSizePixel = 0
	entry.LayoutOrder = rank

	if rank == 1 then
		entry.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	elseif rank == 2 then
		entry.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	elseif rank == 3 then
		entry.BackgroundColor3 = Color3.fromRGB(205, 127, 50)
	end

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "Rank"
	rankLabel.Size = UDim2.new(0, 45, 1, 0)
	rankLabel.Position = UDim2.new(0, 3, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.FredokaOne
	rankLabel.Text = "#" .. rank
	rankLabel.TextColor3 = rank <= 3 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
	rankLabel.TextSize = 20
	rankLabel.TextXAlignment = Enum.TextXAlignment.Center
	rankLabel.Parent = entry

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Size = UDim2.new(0, 36, 0, 36)
	avatarImage.Position = UDim2.new(0, 50, 0, 4.5)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. playerData.UserId .. "&w=150&h=150"
	avatarImage.Parent = entry
	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 6)
	imageCorner.Parent = avatarImage

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, -200, 0, 22)
	nameLabel.Position = UDim2.new(0, 90, 0, 3)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = playerData.Name
	nameLabel.TextColor3 = rank <= 3 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = entry

	local statLabel = Instance.new("TextLabel")
	statLabel.Name = "StatValue"
	statLabel.Size = UDim2.new(1, -200, 0, 18)
	statLabel.Position = UDim2.new(0, 90, 0, 24)
	statLabel.BackgroundTransparency = 1
	statLabel.Font = Enum.Font.Gotham
	local statText = (statType == "Coins")
		and string.format("💰 %s", formatNumber(playerData.Value))
		or  string.format("💩 %s", formatNumber(playerData.Value))
	statLabel.Text = statText
	statLabel.TextColor3 = rank <= 3 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
	statLabel.TextSize = 15
	statLabel.TextXAlignment = Enum.TextXAlignment.Left
	statLabel.Parent = entry

	return entry
end

local function updateScoreboard(scrollFrame, statName)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local topPlayers = getGlobalTopPlayers(statName, MAX_PLAYERS_SHOWN)
	for rank, playerData in ipairs(topPlayers) do
		local entry = createPlayerEntry(rank, playerData, statName)
		entry.Parent = scrollFrame
	end

	print("✓ Updated GLOBAL", statName, "scoreboard with", #topPlayers, "players")
end

-- ============================================
-- ZONE CREATION
-- ============================================

function ScoreboardManager.CreateInZone(zonePosition, zoneSize, parentFolder)
	print("========================================")
	print("Creating GLOBAL scoreboards in zone...")
	print("========================================")

	local coinsPosition = zonePosition + Vector3.new(-20, 14, -40)  -- Raised to be more visible
	local poopsPosition = zonePosition + Vector3.new(-35, 14, -40)  -- Raised to be more visible

	local coinsBoard, coinsScrollFrame = createScoreboardStructure(coinsPosition, "🏆 TOP COINS", parentFolder)
	local poopsBoard, poopsScrollFrame = createScoreboardStructure(poopsPosition, "💩 TOP POOPS", parentFolder)

	updateScoreboard(coinsScrollFrame, "Coins")
	updateScoreboard(poopsScrollFrame, "Poops Cleared")

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			updateScoreboard(coinsScrollFrame, "Coins")
			updateScoreboard(poopsScrollFrame, "Poops Cleared")
		end
	end)

	print("========================================")
	print("✅ GLOBAL SCOREBOARDS CREATED!")
	print("========================================")

	return {coinsBoard, poopsBoard}
end

return ScoreboardManager
