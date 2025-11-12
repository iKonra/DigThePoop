-- DataManager.luau
-- Manages saving and loading player data using DataStoreService

local DataManager = {}
local BadgeManager = require(script.Parent:WaitForChild("BadgeManager"))

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Function to clear specific player data
function DataManager.ClearPlayerData(userId: string)
	if USE_DATASTORE and playerDataStore then
		local success, err = pcall(function()
			playerDataStore:RemoveAsync(userId)
		end)
		if success then
			print("Successfully cleared data for user:", userId)
			return true
		else
			warn("Failed to clear data for user:", userId, "Error:", err)
			return false
		end
	end
	return false
end

-- Try to require Config so we can dynamically handle shovel upgrade keys
local Config = nil
pcall(function()
	Config = require(script.Parent:WaitForChild("Config"))
end)

-- ============================================
-- CONFIGURATION
-- ============================================

local DATASTORE_NAME = "PlayerData_V1" -- bump to reset schema
local AUTO_SAVE_INTERVAL = 10 -- seconds (reduced from 120 to persist frequently)

-- Try to open DataStore (works in Studio if API Services enabled)
local USE_DATASTORE = true
local playerDataStore

do
	local ok, dsOrErr = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok and dsOrErr then
		playerDataStore = dsOrErr
		USE_DATASTORE = true
	else
		warn("⚠️ DataStore no disponible. Usando almacenamiento local. Detalle:", dsOrErr)
		USE_DATASTORE = false
	end
end

-- Local storage fallback (Studio sin API Services)
local localPlayerData: {[string]: any} = {}

-- ============================================
-- DATA STRUCTURE
-- ============================================

local function getDefaultData()
	local shovelUpgrades = {}
	-- If Config is available, seed upgrade keys from Config.ShovelUpgradeStats
	if Config and type(Config.ShovelUpgradeStats) == "table" then
		for _, stat in ipairs(Config.ShovelUpgradeStats) do
			shovelUpgrades[stat.name] = 0
		end
	else
		-- Fallback legacy keys
		shovelUpgrades = {
			PoopCapacity = 0,
			WalkSpeed = 0,
			PoopMultiplier = 0,
			Luck = 0,
		}
	end

	return {
		-- Stats
		Coins = 0,
		PoopsCleared = 0,
		Rebirths = 0,

		-- Inventory
		OwnedGears = {},
		CurrentGear = "None",
		OwnedRails = {"None"},
		CurrentRail = "None",
		OwnedZones = {"Spawn"},

		-- Upgrades (dynamic)
		ShovelUpgrades = shovelUpgrades,

		-- Metadata
		LastSave = os.time(),
		TotalPlayTime = 0,
	}
end

-- ============================================
-- RUNTIME EFFECTS (rebirth speed, upgrades, etc.)
-- ============================================

local function applyRuntimeEffects(player: Player, data)
	local function applyToCharacter(char: Model)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		local base = 16
		local upg = data.ShovelUpgrades or {}
		local wsFromUpg = (upg.WalkSpeed or 0) * 0.5  -- ajustá a tu diseño
		local wsFromRebirth = (data.Rebirths or 0) * 1

		hum.WalkSpeed = base + wsFromUpg + wsFromRebirth
	end

	if player.Character then applyToCharacter(player.Character) end
	player.CharacterAdded:Connect(applyToCharacter)
end

-- ============================================
-- SAVE & LOAD FUNCTIONS
-- ============================================

function DataManager.LoadData(player: Player)
	local userIdKey = "Player_" .. player.UserId

	if not USE_DATASTORE then
		local existing = localPlayerData[userIdKey]
		if existing then
			print("✓ Loaded local data for", player.Name, "(local mode)")
			return existing
		end
		local fresh = getDefaultData()
		localPlayerData[userIdKey] = fresh
		print("✓ Created local data for", player.Name, "(local mode)")
		return fresh
	end

	local success, data
	for attempt = 1, 3 do
		success, data = pcall(function()
			return playerDataStore:GetAsync(userIdKey)
		end)
		if success then break end
		warn(("Load fail for %s (try %d/3)"):format(player.Name, attempt))
		task.wait(1)
	end

	if success and data then
		-- merge defaults to avoid nil fields
		local def = getDefaultData()
		for k, v in pairs(def) do
			if data[k] == nil then data[k] = v end
		end
		if not table.find(data.OwnedRails, "None") then
			table.insert(data.OwnedRails, 1, "None")
		end
		if not table.find(data.OwnedZones, "Spawn") then
			table.insert(data.OwnedZones, 1, "Spawn")
		end
		print("✓ Loaded data for", player.Name)
		return data
	else
		warn("⚠️ Could not load data for", player.Name, "- using defaults")
		return getDefaultData()
	end
end

function DataManager.SaveData(player: Player)
	local userIdKey = "Player_" .. player.UserId

	-- Snapshot current state
	local data = {
		Coins = 0,
		PoopsCleared = 0,
		Rebirths = 0,
		OwnedGears = {},
		CurrentGear = "None",
		OwnedRails = {},
		CurrentRail = "None",
		OwnedZones = {},
		ShovelUpgrades = {
			PoopCapacity = 0,
			WalkSpeed = 0,
			PoopMultiplier = 0,
			Luck = 0,
		},
		LastSave = os.time(),
	}

	-- leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		local poops = leaderstats:FindFirstChild("Poops Cleared")
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if coins then data.Coins = coins.Value end
		if poops then data.PoopsCleared = poops.Value end
		if rebirths then data.Rebirths = rebirths.Value end
	end

	-- rails
	local RailManager = require(script.Parent:WaitForChild("RailManager"))
	data.OwnedRails = RailManager.GetOwnedRails(player)
	data.CurrentRail = RailManager.GetPlayerRail(player) or "None"

	-- zones
	local ZoneManager = require(script.Parent:WaitForChild("ZoneManager"))
	data.OwnedZones = ZoneManager.GetOwnedZones(player)

	-- upgrades: read all IntValues inside player.Upgrades dynamically
	local upgrades = player:FindFirstChild("Upgrades")
	if upgrades then
		for _, child in ipairs(upgrades:GetChildren()) do
			if child:IsA("IntValue") then
				data.ShovelUpgrades[child.Name] = child.Value
			end
		end
	end

	-- ✅ Actualizar OrderedDataStores para scoreboards globales
	if USE_DATASTORE then
		local okODS, errODS = pcall(function()
			local odsCoins = DataStoreService:GetOrderedDataStore("Global_Coins")
			odsCoins:SetAsync(tostring(player.UserId), tonumber(data.Coins) or 0)

			local odsPoops = DataStoreService:GetOrderedDataStore("Global_PoopsCleared")
			odsPoops:SetAsync(tostring(player.UserId), tonumber(data.PoopsCleared) or 0)
		end)
		if not okODS then
			warn("Failed to update global ODS for", player.Name, errODS)
		end
	end

	-- Modo local (Studio sin API Services)
	if not USE_DATASTORE then
		localPlayerData[userIdKey] = data
		print("✓ Saved (local) for", player.Name)
		return true
	end

	-- Guardar DataStore normal
	local ok = false
	for attempt = 1, 3 do
		ok = pcall(function()
			playerDataStore:SetAsync(userIdKey, data)
		end)
		if ok then break end
		warn(("Save fail for %s (try %d/3)"):format(player.Name, attempt))
		task.wait(1)
	end

	if ok then
		print("✓ Saved data for", player.Name)
	else
		warn("❌ Failed to save data for", player.Name)
	end
	return ok
end


function DataManager.ApplyData(player: Player, data)
	print("Applying data for", player.Name)

	-- leaderstats (espera hasta 10s)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("❌ No leaderstats found for", player.Name)
		return
	end

	local coins = leaderstats:FindFirstChild("Coins")
	local poops = leaderstats:FindFirstChild("Poops Cleared")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if coins then coins.Value = data.Coins end
	if poops then poops.Value = data.PoopsCleared end
	if rebirths then rebirths.Value = data.Rebirths end

	-- upgrades -> valores internos: ensure IntValues exist and set values
	if data.ShovelUpgrades then
		local upgradesFolder = player:FindFirstChild("Upgrades")
		if not upgradesFolder then
			upgradesFolder = Instance.new("Folder")
			upgradesFolder.Name = "Upgrades"
			upgradesFolder.Parent = player
		end

		for k, v in pairs(data.ShovelUpgrades) do
			local intv = upgradesFolder:FindFirstChild(k)
			if not intv then
				intv = Instance.new("IntValue")
				intv.Name = k
				intv.Parent = upgradesFolder
			end
			if typeof(v) == "number" then
				intv.Value = v
			end
		end
	end

	-- aplicar efectos runtime (speed, etc.) ahora y en cada respawn
	applyRuntimeEffects(player, data)

	print("✓ Data applied for", player.Name)
end

-- ============================================
-- AUTO-SAVE SYSTEM
-- ============================================

local autoSaveCoroutines: {[number]: thread} = {}

function DataManager.StartAutoSave(player: Player)
	DataManager.StopAutoSave(player)

	local autoSave = coroutine.create(function()
		while player.Parent == Players do
			task.wait(AUTO_SAVE_INTERVAL)
			if player.Parent == Players then
				print("⏰ Auto-saving data for", player.Name)
				DataManager.SaveData(player)
			end
		end
	end)

	autoSaveCoroutines[player.UserId] = autoSave
	coroutine.resume(autoSave)
	print("✓ Auto-save started for", player.Name)
end

function DataManager.StopAutoSave(player: Player)
	if autoSaveCoroutines[player.UserId] then
		autoSaveCoroutines[player.UserId] = nil
		print("✓ Auto-save stopped for", player.Name)
	end
end

-- ============================================
-- INITIALIZATION
-- ============================================

function DataManager.Setup()
	print("========================================")
	print("Setting up DataManager...")
	print("========================================")

	Players.PlayerAdded:Connect(function(player)
		print("📥 Loading data for", player.Name)

		local data = DataManager.LoadData(player)

		-- Otorgar emblema si es primer ingreso (solo si los datos son nuevos)
		if data and (data.TotalPlayTime or 0) == 0 and (data.PoopsCleared or 0) == 0 and (data.Rebirths or 0) == 0 then
			BadgeManager.AwardFirstJoinBadge(player)
		end

		-- Esperá a que otro manager cree leaderstats/Upgrades
		task.wait(1)

		DataManager.ApplyData(player, data)

		-- ✅ RAILS: restaurar TODO de una con SetOwnedRails (evita duplicados/equips extra)
		task.spawn(function()
			local RailManager = require(script.Parent:WaitForChild("RailManager"))
			task.wait(0.5)
			RailManager.SetOwnedRails(player, data.OwnedRails, data.CurrentRail)
		end)

		-- Zones
		task.spawn(function()
			local ZoneManager = require(script.Parent:WaitForChild("ZoneManager"))
			task.wait(0.5)
			if ZoneManager.RestoreOwnedZones then
				ZoneManager.RestoreOwnedZones(player, data.OwnedZones)
			end
		end)

		DataManager.StartAutoSave(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		print("📤 Saving data for", player.Name)
		DataManager.StopAutoSave(player)
		DataManager.SaveData(player)
	end)

	game:BindToClose(function()
		print("🛑 Server shutting down - saving all player data...")
		for _, p in ipairs(Players:GetPlayers()) do
			DataManager.SaveData(p)
		end
		task.wait(2)
	end)



	print("✅ DataManager setup complete!")
	print("  - Mode:", USE_DATASTORE and "DataStore (Production)" or "Local Storage (Studio)")
	print("  - Auto-save interval:", AUTO_SAVE_INTERVAL, "seconds")
	if USE_DATASTORE then
		print("  - DataStore:", DATASTORE_NAME)
	else
		print("  - ⚠️ Data will NOT persist between sessions in Studio mode")
		print("  - Enable: Game Settings > Security > Enable Studio Access to API Services")
	end
	print("========================================")
end

return DataManager
