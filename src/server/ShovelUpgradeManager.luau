-- ShovelUpgradeManager.luau
-- Manages progressive shovel upgrades (persistentes via player.Upgrades IntValues)

local ShovelUpgradeManager = {}

local Config = require(script.Parent.Config)
local ShovelManager = require(script.Parent.ShovelManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Control de guardado por lotes
ShovelUpgradeManager._pendingSaves = {}
ShovelUpgradeManager._lastSaveTime = {}
ShovelUpgradeManager._saveDebounce = {}
ShovelUpgradeManager._recentPurchases = {}
ShovelUpgradeManager._purchaseLocks = {}
ShovelUpgradeManager._lockTimers = {}

-- DataManager opcional para forzar guardado
local hasDM, DataManager = pcall(function()
	return require(script.Parent:FindFirstChild("DataManager"))
end)
if not hasDM then DataManager = nil end

-- ============================================
-- REMOTOS (asegurados)
-- ============================================

-- Función para forzar guardado
local function forceSavePlayer(player: Player)
    if not player or not player.Parent then return end
    
    if DataManager and typeof(DataManager.SaveData) == "function" and ShovelUpgradeManager._pendingSaves[player] then
        task.spawn(function()
            pcall(function()
                DataManager.SaveData(player)
                print("✓ Force save completed for player:", player.Name)
            end)
            ShovelUpgradeManager._pendingSaves[player] = nil
            ShovelUpgradeManager._saveDebounce[player] = nil
        end)
    end
end

local function ensureRemoteEvent(name: string)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
		print("✓ Created RemoteEvent:", name)
	end
	return ev
end

local function ensureRemoteFunction(name: string)
	local fn = ReplicatedStorage:FindFirstChild(name)
	if not fn then
		fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = ReplicatedStorage
		print("✓ Created RemoteFunction:", name)
	end
	return fn
end

-- Lista de todos los eventos remotos necesarios
local remoteEvents = {
    "PurchaseShovelUpgradeEvent",
    "ShowUpgradeSuccessEvent",
    "ShowWarningEvent",
    "PromptPassPurchaseEvent",
    "PurchaseStarterPackEvent",
	"ShovelUpgradeMenuClosedEvent", -- Nuevo evento para el cierre del menú
	"PurchaseShovelUpgradeResponseEvent" -- Respuesta rápida para el cliente
}

-- Crear todos los eventos al inicio
for _, eventName in ipairs(remoteEvents) do
    ensureRemoteEvent(eventName)
end

-- Asegurar las funciones remotas
local PurchaseUpgradeEvent = ReplicatedStorage:WaitForChild("PurchaseShovelUpgradeEvent")
local GetUpgradesFunction = ensureRemoteFunction("GetShovelUpgradesFunction")
local ShowUpgradeSuccessEvent = ReplicatedStorage:WaitForChild("ShowUpgradeSuccessEvent")
local ShowWarningEvent = ReplicatedStorage:WaitForChild("ShowWarningEvent")

-- ============================================
-- HELPERS: Upgrades/Coins
-- ============================================

-- Crea/asegura la carpeta Upgrades y los IntValues de cada stat (nombres del cliente)
local function ensureUpgradesFolder(player: Player): Folder
	local up = player:FindFirstChild("Upgrades")
	if not up then
		up = Instance.new("Folder")
		up.Name = "Upgrades"
		up.Parent = player
	end
	-- A partir de tu UI: Distance, Multiplier, CoinsDiscover, EggsDiscover, DigSpeed, LuckyChance
	for _, statConfig in ipairs(Config.ShovelUpgradeStats) do
		if not up:FindFirstChild(statConfig.name) then
			local v = Instance.new("IntValue")
			v.Name = statConfig.name
			v.Value = 0
			v.Parent = up
		end
	end
	return up
end

local function getStatValueObject(player: Player, statName: string): IntValue
	local up = ensureUpgradesFolder(player)
	local v = up:FindFirstChild(statName)
	if not v then
		v = Instance.new("IntValue"); v.Name = statName; v.Value = 0; v.Parent = up
	end
	return v
end

local function ensureLeaderstats(player: Player): Folder
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	end
	return ls
end

local function ensureCoins(player: Player): IntValue
	local ls = ensureLeaderstats(player)
	local coins = ls:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0
		coins.Parent = ls
	end
	return coins
end

-- ============================================
-- COSTOS / VALORES
-- ============================================

local function calculateUpgradeCost(statConfig, currentLevel)
	if currentLevel >= statConfig.maxLevel then
		return nil
	end
	local nextLevel = currentLevel + 1

	-- Support multiple scaling modes for clearer, more dynamic pricing
	-- Modes:
	--  - "power": baseCost * (nextLevel ^ costExponent)  (classic, matches client UI)
	--  - "exp":   baseCost * (costMultiplier ^ nextLevel) (alternate)
	-- Default to "power" so server pricing matches the client-side display (Config uses power-style comments).
	local mode = statConfig.costMode or "power"
	if mode == "power" then
		local exponent = statConfig.costExponent or 1.15
		local cost = math.floor(statConfig.baseCost * (nextLevel ^ exponent))
		return cost
	else
		local multiplier = statConfig.costMultiplier or 1.15
		-- allow optional offset to tune mid/late game
		local offset = statConfig.costOffset or 0
		local cost = math.floor(statConfig.baseCost * (multiplier ^ (nextLevel + offset)))
		return cost
	end
end

local function calculateStatValue(statConfig, level)
	local rawValue = statConfig.baseValue + (statConfig.valuePerLevel * level)

	-- If value is effectively an integer (within tiny epsilon), return integer
	local roundedInt = math.floor(rawValue + 0.5)
	if math.abs(rawValue - roundedInt) < 1e-9 then
		return roundedInt
	end

	-- Otherwise round to a reasonable number of decimals (default 2)
	local decimals = statConfig.roundDecimals or 2
	local m = 10 ^ decimals
	return math.floor(rawValue * m + 0.5) / m
end

-- ============================================
-- API PARA UI
-- ============================================

function ShovelUpgradeManager.GetPlayerUpgrades(player: Player)
    -- Lee SIEMPRE de los IntValue (persistentes)
    local up = ensureUpgradesFolder(player)
    local result = {}
    
    -- Solo devolver los niveles actuales
    for _, statConfig in ipairs(Config.ShovelUpgradeStats) do
        local v = up:FindFirstChild(statConfig.name)
        result[statConfig.name] = v and v.Value or 0
    end
    
    return result
end

-- Función separada para obtener metadata completa
function ShovelUpgradeManager.GetUpgradeMetadata(player: Player)
    local up = ensureUpgradesFolder(player)
    local metadata = {}
    
    for _, statConfig in ipairs(Config.ShovelUpgradeStats) do
        local v = up:FindFirstChild(statConfig.name)
        local currentLevel = v and v.Value or 0
        
        metadata[statConfig.name] = {
            currentLevel = currentLevel,
            nextCost = calculateUpgradeCost(statConfig, currentLevel),
            maxLevel = statConfig.maxLevel,
            currentValue = calculateStatValue(statConfig, currentLevel)
        }
    end
    
    return metadata
end

function ShovelUpgradeManager.GetCompiledStats(player: Player)
	local stats = {}
	
	-- Ensure player still exists and is connected
	if not player or not player.Parent then
		return stats
	end
	
	-- Get upgrades folder with validation
	local upgradesFolder = player:FindFirstChild("Upgrades")
	if not upgradesFolder then
		warn("Upgrades folder not found for player:", player.Name)
		upgradesFolder = ensureUpgradesFolder(player)
	end
	
	for _, statConfig in ipairs(Config.ShovelUpgradeStats) do
		-- Safe value retrieval with validation
		local statValue = upgradesFolder:FindFirstChild(statConfig.name)
		local lvl = (statValue and statValue:IsA("IntValue")) and statValue.Value or 0
		
		-- Calculate and validate the value
		local value = calculateStatValue(statConfig, lvl)
		if value then
			stats[statConfig.statKey] = value
			print(("Compiled stat %s = %s (level %d)"):format(statConfig.statKey, tostring(value), lvl))
		else
			warn(("Failed to calculate value for %s"):format(statConfig.name))
			stats[statConfig.statKey] = statConfig.baseValue or 1
		end
	end
	
	return stats
end

-- ============================================
-- COMPRAS
-- ============================================

function ShovelUpgradeManager.PurchaseUpgrade(player: Player, statName: string, skipCost: boolean?)
	skipCost = skipCost or false

	-- Validar que el jugador existe
	if not player or not player.Parent then
		return false
	end
	
	ShovelUpgradeManager._purchaseLocks[player] = true
	ShovelUpgradeManager._lockTimers[player] = os.time()

	print("========================================")
	print("ShovelUpgradeManager: Purchase upgrade request")
	print("  - Player:", player.Name)
	print("  - Stat:", statName)
	print("  - Skip cost:", skipCost and "YES" or "NO")
	print("========================================")

	-- Buscar config
	local statConfig = nil
	for _, cfg in ipairs(Config.ShovelUpgradeStats) do
		if cfg.name == statName then statConfig = cfg; break end
	end
	if not statConfig then
		warn("Invalid stat name:", statName)
		if ShowWarningEvent then ShowWarningEvent:FireClient(player, "Invalid upgrade") end
		ShovelUpgradeManager._purchaseLocks[player] = nil
		return false
	end

	-- Nivel actual (IntValue con validación!)
	local v = getStatValueObject(player, statName)
	if not v then
		warn("Failed to get stat value object for:", statName)
		if ShowWarningEvent then ShowWarningEvent:FireClient(player, "Error accessing upgrade data") end
		ShovelUpgradeManager._purchaseLocks[player] = nil
		return false
	end

	local currentLevel = v.Value
	if not currentLevel then currentLevel = 0 end -- Asegurar que siempre sea número

	if currentLevel >= (statConfig.maxLevel or 100) then
		if ShowWarningEvent then ShowWarningEvent:FireClient(player, "Already maxed!") end
		ShovelUpgradeManager._purchaseLocks[player] = nil
		return false
	end

	local cost = 0
	local coinsValue: IntValue? = nil
	if not skipCost then
		cost = calculateUpgradeCost(statConfig, currentLevel) or 0
		coinsValue = ensureCoins(player)
		if coinsValue.Value < cost then
			if ShowWarningEvent then
				ShowWarningEvent:FireClient(player, string.format("Need %d coins! (You have %d)", cost, coinsValue.Value))
			end
			return false
		end
		coinsValue.Value -= cost
		print(("✓ Deducted %d coins. Remaining: %d"):format(cost, coinsValue.Value))
	else
		print("✓ Skipping cost (FREE upgrade, e.g. Starter Pack)")
	end

	-- Subir nivel (persistente)
	v.Value = currentLevel + 1
	print(("✓ Upgraded %s to level %d"):format(statName, v.Value))

	-- Refrescar pala en segundo plano para no bloquear la respuesta al cliente
	task.spawn(function()
		local ok, err = pcall(function()
			ShovelUpgradeManager.RefreshPlayerShovel(player)
		end)
		if not ok then
			warn(("Background shovel refresh failed for %s: %s"):format(player.Name, tostring(err)))
		end
	end)

	-- Feedback: Fire the internal stat name first so the client can clear pendingPurchases[statName]
	local displayName = statConfig.displayName or statName
	if ShowUpgradeSuccessEvent then
		ShowUpgradeSuccessEvent:FireClient(player, statConfig.name, v.Value, displayName)
	end

	-- Marcar para guardado posterior
	ShovelUpgradeManager._pendingSaves[player] = true
	
	-- Guardar inmediatamente
	if DataManager and typeof(DataManager.SaveData) == "function" then
		task.spawn(function()
			pcall(function()
				DataManager.SaveData(player)
			end)
		end)
	end

	print("========================================")
	print("✅ UPGRADE SUCCESSFUL!")
	print("  - Stat:", statName)
	print("  - New Level:", v.Value)
	if not skipCost then
		print("  - Cost:", cost)
		print("  - Remaining coins:", coinsValue and coinsValue.Value or 0)
	else
		print("  - Cost: FREE (Starter Pack)")
	end
	print("========================================")

	return true
end

-- ============================================
-- SHOVEL
-- ============================================

function ShovelUpgradeManager.RefreshPlayerShovel(player: Player)
	print("Refreshing shovel for player:", player.Name)
	
	-- Validate player
	if not player or not player.Parent then
		warn("Cannot refresh shovel - player is invalid")
		return
	end
	
	-- Get current stats with validation
	local stats = ShovelUpgradeManager.GetCompiledStats(player)
	if not stats.PoopMultiplier or not stats.DigSpeed or not stats.Range then
		warn("Invalid stats compilation for player:", player.Name)
		-- Use default values if stats are invalid
		stats = {
			PoopMultiplier = Config.Shovel.BasePoopMultiplier,
			DigSpeed = Config.Shovel.BaseDigSpeed,
			Range = Config.Shovel.BaseRange
		}
	end
	
	local gearData = {
		name = "Shovel",
		displayName = "Shovel",
		description = "Your upgraded shovel",
		poopMultiplier = stats.PoopMultiplier,
		digSpeed = stats.DigSpeed,
		range = stats.Range,
	}
	
	-- Dar pala inmediatamente y manejar posibles errores correctamente
	local ok, ret = pcall(function()
		-- GiveShovelToPlayer puede devolver true/false o lanzar error; lo capturamos
		return ShovelManager.GiveShovelToPlayer(player, Config.Shovel.ModelName, gearData)
	end)

	if ok then
		print(("✓ Shovel refreshed for %s with stats:"):format(player.Name))
		for k, v in pairs(stats) do
			print(("  - %s: %s"):format(k, tostring(v)))
		end
		return true
	else
		-- ret puede ser el error arrojado por pcall; lo mostramos para depuración
		warn(("❌ Failed to refresh shovel for %s: %s"):format(player.Name, tostring(ret)))
		return false
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function ShovelUpgradeManager.GiveStarterShovel(player: Player)
	print("ShovelUpgradeManager: Giving starter shovel to", player.Name)
	-- Asegurá estructuras persistentes
	ensureUpgradesFolder(player)
	
	-- Asegurar que los leaderstats y upgrades estén listos
	local function setupShovel()
		local leaderstats = player:WaitForChild("leaderstats", 15) -- Increased timeout
		local upgrades = ensureUpgradesFolder(player)
		
		-- Validar componentes críticos
		if not leaderstats or not upgrades then
			warn("Critical components not ready for player:", player.Name)
			task.delay(1, function() setupShovel() end) -- Retry after delay
			return
		end
		
		-- Esperar character con sistema de retry
		local function waitForChar()
			local char = player.Character or player.CharacterAdded:Wait()
			if not char or not char:IsDescendantOf(game) then
				warn("Character not ready, retrying in 1s...")
				task.delay(1, waitForChar)
				return
			end
			
			task.wait(1) -- Increased from 0.5 to ensure all systems are ready
			
			if char and char.Parent and upgrades then
				local success = pcall(function()
					ShovelUpgradeManager.RefreshPlayerShovel(player)
				end)
				if not success then
					warn("Failed to refresh shovel, retrying in 1s...")
					task.delay(1, waitForChar)
				end
			end
		end
		
		task.spawn(waitForChar)
	end
	
	task.spawn(setupShovel) -- Run in separate thread to not block
end

function ShovelUpgradeManager.SetupRemoteEvents()
	print("ShovelUpgradeManager: Setting up remote events...")
	
	-- Asegurar que los eventos existan antes de continuar
	PurchaseUpgradeEvent = ensureRemoteEvent("PurchaseShovelUpgradeEvent")
	GetUpgradesFunction = ensureRemoteFunction("GetShovelUpgradesFunction")
	ShowUpgradeSuccessEvent = ensureRemoteEvent("ShowUpgradeSuccessEvent")
	ShowWarningEvent = ensureRemoteEvent("ShowWarningEvent")
	
	-- Evento para cuando se cierra el menú
	local menuClosedEvent = ensureRemoteEvent("ShovelUpgradeMenuClosedEvent")
	menuClosedEvent.OnServerEvent:Connect(function(player)
		forceSavePlayer(player)
	end)
	
	-- Provide a RemoteFunction for deterministic purchases (client calls InvokeServer)
	local purchaseFunction = ensureRemoteFunction("PurchaseShovelUpgradeFunction")
	purchaseFunction.OnServerInvoke = function(player, statName)
		if typeof(statName) ~= "string" then
			return false, "Invalid upgrade request"
		end

		-- Anti-duplicate: ignore repeated requests for same stat within 0.15s
		local now = os.clock()
		local userRecent = ShovelUpgradeManager._recentPurchases[player.UserId] or {}
		if userRecent[statName] and (now - userRecent[statName]) < 0.15 then
			return false, "Too many requests"
		end
		userRecent[statName] = now
		ShovelUpgradeManager._recentPurchases[player.UserId] = userRecent

		-- Run the purchase logic safely
		local ok, res = pcall(function()
			return ShovelUpgradeManager.PurchaseUpgrade(player, statName)
		end)

		local success = ok and res
		if not success then
			warn(("Purchase request failed for %s (ok=%s, res=%s)"):format(player.Name, tostring(ok), tostring(res)))
		end

		-- Optionally still fire a response event for legacy clients
		local responseEvent = ReplicatedStorage:FindFirstChild("PurchaseShovelUpgradeResponseEvent")
		if responseEvent then
			pcall(function()
				responseEvent:FireClient(player, statName, success, success and nil or "Purchase failed or timed out.")
			end)
		end

		return success, success and nil or "Purchase failed or timed out."
	end

	GetUpgradesFunction.OnServerInvoke = function(player)
		return ShovelUpgradeManager.GetPlayerUpgrades(player)
	end

	print("✓ Remote events ready!")
end

function ShovelUpgradeManager.SetupPlayers()
	print("========================================")
	print("ShovelUpgradeManager: Setting up players...")
	print("========================================")

	local function initializePlayer(player)
		-- Asegurar que todas las estructuras existan primero
		local up = ensureUpgradesFolder(player)
		local ls = ensureLeaderstats(player)
		
		-- Pre-inicializar todos los valores para que estén disponibles inmediatamente
		for _, statConfig in ipairs(Config.ShovelUpgradeStats) do
			local v = up:FindFirstChild(statConfig.name)
			if not v then
				v = Instance.new("IntValue")
				v.Name = statConfig.name
				v.Value = 0
				v.Parent = up
			end
		end
		
		-- Notificar al cliente que los datos están listos
		if ShowUpgradeSuccessEvent then
			ShowUpgradeSuccessEvent:FireClient(player, "INIT_COMPLETE", 0)
		end
		
		-- Setup character handling
		local function onCharacterAdded()
			task.wait(0.5) -- Reduced wait time
			if player and player.Parent then -- Verify player still exists
				ShovelUpgradeManager.RefreshPlayerShovel(player)
			end
		end
		
		player.CharacterAdded:Connect(onCharacterAdded)
		
		-- Initial setup with retry mechanism
		local function attemptStarterShovel()
			local success = pcall(function()
				ShovelUpgradeManager.GiveStarterShovel(player)
			end)
			if not success and player and player.Parent then
				warn("Failed to give starter shovel, retrying in 1s...")
				task.delay(1, attemptStarterShovel)
			end
		end
		
		task.spawn(attemptStarterShovel)
	end

	-- Setup existing players with validation
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player and player.Parent then
			task.spawn(function()
				initializePlayer(player)
			end)
		end
	end

	-- Setup for new players
	game.Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			initializePlayer(player)
		end)
	end)

	print("✅ ShovelUpgradeManager player setup complete!")
end

return ShovelUpgradeManager
