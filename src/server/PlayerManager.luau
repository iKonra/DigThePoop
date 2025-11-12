-- PlayerManager.luau
-- Handles player setup, leaderstats, upgrades, and lifecycle management

local PlayerManager = {}

-- =========================
-- DEPENDENCIAS
-- =========================
local Config = require(script.Parent:WaitForChild("Config"))
local RebirthManager = require(script.Parent:WaitForChild("RebirthManager"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

-- =========================
-- CREAR LEADERSTATS
-- =========================
local BadgeManager = require(script.Parent:WaitForChild("BadgeManager"))

local function setupLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local poopCount = leaderstats:FindFirstChild("Poops Cleared")
	if not poopCount then
		poopCount = Instance.new("IntValue")
		poopCount.Name = "Poops Cleared"
		poopCount.Value = 0
		poopCount.Parent = leaderstats
	end

	-- Otorgar emblema de 10k poops al llegar por primera vez
	poopCount.Changed:Connect(function(newValue)
		if typeof(newValue) == "number" and newValue >= 10000 then
			BadgeManager.Award10kPoopsBadge(player)
		end
	end)

	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if not rebirths then
		rebirths = Instance.new("IntValue")
		rebirths.Name = "Rebirths"
		rebirths.Value = 0
		rebirths.Parent = leaderstats
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0
		coins.Parent = leaderstats
	end

	print(("[Leaderstats] Set for %s (Poops, Rebirths, Coins)"):format(player.Name))
end

-- =========================
-- ASEGURAR UPGRADES
-- =========================
local function ensureUpgradesFolder(player: Player)
	local up = player:FindFirstChild("Upgrades")
	if not up then
		up = Instance.new("Folder")
		up.Name = "Upgrades"
		up.Parent = player
	end

	-- Nombres que usa el cliente (init.client.luau)
	local names = {"Distance","Multiplier","CoinsDiscover","EggsDiscover","DigSpeed","LuckyChance"}
	for _, n in ipairs(names) do
		if not up:FindFirstChild(n) then
			local v = Instance.new("IntValue")
			v.Name = n
			v.Value = 0
			v.Parent = up
		end
	end

	-- Opcional: compatibilidad con los nombres viejos
	for _, n in ipairs({"PoopCapacity","WalkSpeed","PoopMultiplier","Luck"}) do
		if not up:FindFirstChild(n) then
			local v = Instance.new("IntValue")
			v.Name = n
			v.Value = 0
			v.Parent = up
		end
	end
end

-- =========================
-- CARGAR Y GUARDAR DATOS
-- =========================
local function safeLoadPlayerData(player: Player)
	if DataManager.LoadPlayerData then
		DataManager.LoadPlayerData(player)
		return
	end

	local data = DataManager.LoadData(player)
	ensureUpgradesFolder(player) -- ✅ aseguramos antes de aplicar
	task.wait(0.1)
	DataManager.ApplyData(player, data)
	DataManager.StartAutoSave(player)
end

local function safeSavePlayerData(player: Player)
	if DataManager.SavePlayerData then
		DataManager.SavePlayerData(player)
		return
	end
	DataManager.StopAutoSave(player)
	DataManager.SaveData(player)
end

-- =========================
-- EFECTOS DE REBIRTH
-- =========================
local function hookCharacterEffects(player: Player)
	if player.Character then
		RebirthManager.ApplySpeedBoost(player)
		RebirthManager.ApplyPlayerEffects(player)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		RebirthManager.ApplySpeedBoost(player)
		RebirthManager.ApplyPlayerEffects(player)
	end)
end

-- =========================
-- CONFIGURAR JUGADORES
-- =========================
function PlayerManager.SetupPlayers()
	print("========== PLAYER SETUP START ==========")

	for _, player in ipairs(game.Players:GetPlayers()) do
		setupLeaderstats(player)
		ensureUpgradesFolder(player)
		safeLoadPlayerData(player)
		hookCharacterEffects(player)
	end

	game.Players.PlayerAdded:Connect(function(player)
		print("[PlayerJoin]", player.Name)
		setupLeaderstats(player)
		ensureUpgradesFolder(player)
		safeLoadPlayerData(player)
		hookCharacterEffects(player)
	end)

	game.Players.PlayerRemoving:Connect(function(player)
		safeSavePlayerData(player)
	end)

	game:BindToClose(function()
		for _, p in ipairs(game.Players:GetPlayers()) do
			safeSavePlayerData(p)
		end
	end)

	print("========== PLAYER SETUP COMPLETE ==========")
end

return PlayerManager
