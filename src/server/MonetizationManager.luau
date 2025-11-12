-- MonetizationManager.luau (SERVER)
-- Game Passes: Starter Pack, Premium Rails, Multiplier x5
-- - PromptGamePassPurchase / PromptGamePassPurchaseFinished
-- - UserOwnsGamePassAsync
-- - Evita re-otorgar Starter Pack con DataStore (PassGrants_v1)

local MonetizationManager = {}

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Dependencias (server)
local RailManager = require(script.Parent:WaitForChild("RailManager"))
local ShovelUpgradeManager = require(script.Parent:WaitForChild("ShovelUpgradeManager"))

-- DataManager es OPCIONAL
local hasDM, DataManager = pcall(function()
	return require(script.Parent:FindFirstChild("DataManager"))
end)
if not hasDM then DataManager = nil end

-- =========================
-- CONFIG (IDs reales de tus pases)
-- =========================
local GAME_PASSES = {
	StarterPack      = 1545562478, -- ⭐ Starter Pack
	Premium_Turbo    = 1549108691, -- 🚄 Rail premium
	Premium_Fortune  = 1545224589, -- 🚄 Rail premium
	Premium_Ultimate = 1548456942, -- 🚄 Rail premium
	MultiplierX5     = 1549228826, -- ⚡ x5 Multiplier
}

function MonetizationManager.GetPassIdByName(name: string)
	return GAME_PASSES[name]
end

-- =========================
-- REMOTOS (asegurados)
-- =========================
local function ensureRemoteEvent(name: string)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
	end
	return ev
end

local function ensureRemoteFunction(name: string)
	local fn = ReplicatedStorage:FindFirstChild(name)
	if not fn then
		fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = ReplicatedStorage
	end
	return fn
end

-- Se crean/aseguran en Setup()
local ShowStarterPackEvent
local ShowWarningEvent
local ShowUpgradeSuccessEvent
local PromptPassPurchaseEvent
local GetPassInfoFunction

-- =========================
-- DATASTORE: evitar re-otorgar SP
-- =========================
local passGrantsStore = DataStoreService:GetDataStore("PassGrants_v1")

local function wasPassGranted(userId: number, passName: string): boolean
	local key = ("%d:%s"):format(userId, passName)
	local ok, val = pcall(function() return passGrantsStore:GetAsync(key) end)
	if not ok then
		warn("[Monetization] GetAsync err:", val)
		return false
	end
	return val == true
end

local function markPassGranted(userId: number, passName: string)
	local key = ("%d:%s"):format(userId, passName)
	local ok, err = pcall(function() passGrantsStore:SetAsync(key, true) end)
	if not ok then
		warn("[Monetization] SetAsync err:", err)
	end
end

-- =========================
-- Helpers Leaderstats
-- =========================
local function ensureLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	return ls
end

local function ensureMultiplierStat(player: Player, value: number?)
	-- crea/actualiza leaderstats.Multiplier (NumberValue)
	local leaderstats = ensureLeaderstats(player)
	local mult = leaderstats:FindFirstChild("Multiplier")
	if not mult then
		mult = Instance.new("NumberValue")
		mult.Name = "Multiplier"
		mult.Value = 1
		mult.Parent = leaderstats
	end
	if value and value > mult.Value then
		mult.Value = value
	end
end

-- =========================
-- Multiplier x5
-- =========================
function MonetizationManager.HasMultiplierX5(player: Player): boolean
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASSES.MultiplierX5)
	end)
	return ok and owns
end

local function grantMultiplierX5(player: Player)
	-- Persistencia opcional en DataManager
	if DataManager and typeof(DataManager.Get) == "function" then
		local okGet, data = pcall(function() return DataManager.Get(player) end)
		if okGet and data then
			data.Perks = data.Perks or {}
			data.Perks.MultiplierX5 = true
			pcall(function() DataManager.SaveAsync(player) end)
		end
	end

	ensureMultiplierStat(player, 5)

	-- Feedback UI (use standardized signature: statKeyOrNil, newLevelOrNil, displayName, message)
	if ShowUpgradeSuccessEvent then
		ShowUpgradeSuccessEvent:FireClient(player, nil, nil, "⚡ x5 Multiplier", "Activated!")
	end
	print("✅ x5 Multiplier activado para", player.Name)
end

-- =========================
-- Starter Pack (beneficios)
-- =========================
local function grantStarterPack(player: Player): boolean
	local leaderstats = ensureLeaderstats(player)
	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue then
		coinsValue = Instance.new("IntValue") -- usa IntValue para Coins de forma consistente
		coinsValue.Name = "Coins"
		coinsValue.Value = 0
		coinsValue.Parent = leaderstats
	end

	coinsValue.Value += 2000
	print(("✓ StarterPack: +%d Coins -> %d"):format(2000, coinsValue.Value))

	-- +5 niveles a TODAS las shovel upgrades (cliente usa estos nombres)
	local upgradeNames = { "Distance","Multiplier","CoinsDiscover","EggsDiscover","DigSpeed","LuckyChance" }
	for _, upg in ipairs(upgradeNames) do
		for i = 1, 5 do
			local ok = ShovelUpgradeManager.PurchaseUpgrade(player, upg, true) -- true = gratis
			if not ok then
				warn(("[Monetization] StarterPack lvl %d %s fail"):format(i, upg))
				break
			end
		end
	end

	if ShowUpgradeSuccessEvent then
		ShowUpgradeSuccessEvent:FireClient(player, nil, nil, "⭐ STARTER PACK", "2000 Coins + +5 All Upgrades")
	end
	return true
end

-- =========================
-- POPUP del Starter Pack
-- =========================
function MonetizationManager.ShowStarterPackPopup(player: Player)
	local passId = GAME_PASSES.StarterPack

	-- si ya lo tiene, nada
	local owns = false
	pcall(function()
		owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if owns then return end

	-- precio para la UI
	local priceText = "?"
	local okInfo, info = pcall(function()
		return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
	end)
	if okInfo and info and info.PriceInRobux then
		priceText = tostring(info.PriceInRobux)
	end

	if ShowStarterPackEvent then
		ShowStarterPackEvent:FireClient(player, priceText)
	end
end

-- =========================
-- SETUP
-- =========================
function MonetizationManager.Setup()
	print("[Monetization] Setup…")

	-- 1) Crear/asegurar remotos
	ShowStarterPackEvent    = ensureRemoteEvent("ShowStarterPackEvent")
	ShowWarningEvent        = ensureRemoteEvent("ShowWarningEvent")
	ShowUpgradeSuccessEvent = ensureRemoteEvent("ShowUpgradeSuccessEvent")
	PromptPassPurchaseEvent = ensureRemoteEvent("PromptPassPurchaseEvent")
	GetPassInfoFunction     = ensureRemoteFunction("GetPassInfoFunction")

	-- (opcional: si tu UI de upgrades cliente los usa, asegurarlos acá evita carreras)
	ensureRemoteEvent("PurchaseShovelUpgradeEvent")
	ensureRemoteFunction("GetShovelUpgradesFunction")

	-- 2) Confirmación de compra (server)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if not wasPurchased then return end

		-- Starter Pack
		if passId == GAME_PASSES.StarterPack then
			if not wasPassGranted(player.UserId, "StarterPack") then
				if grantStarterPack(player) then
					markPassGranted(player.UserId, "StarterPack")
					print("✅ Starter Pack otorgado por compra de PASS")
				end
			end
			return
		end

		-- Multiplier X5
		if passId == GAME_PASSES.MultiplierX5 then
			grantMultiplierX5(player)
			return
		end

		-- Rails premium
		for railName, id in pairs(GAME_PASSES) do
			if (railName ~= "StarterPack") and (railName ~= "MultiplierX5") and id == passId then
				RailManager.GrantPremiumRail(player, railName) -- idempotente + persiste
				if ShowUpgradeSuccessEvent then
					ShowUpgradeSuccessEvent:FireClient(player, nil, nil, "🎟️ " .. railName, "Unlocked!")
				end
				print("✅ Premium rail otorgado (pass):", railName)
				return
			end
		end
	end)

	-- 3) Auto-otorgar al entrar si ya posee pases
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			-- Starter Pack (una sola vez)
			local ownsSP = false
			pcall(function()
				ownsSP = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASSES.StarterPack)
			end)
			if ownsSP and not wasPassGranted(player.UserId, "StarterPack") then
				if grantStarterPack(player) then
					markPassGranted(player.UserId, "StarterPack")
					print("✓ Starter Pack otorgado al entrar (ya tenía el pase)")
				end
			end

			-- Multiplier X5
			local okM, ownsM = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASSES.MultiplierX5)
			end)
			if okM and ownsM then
				grantMultiplierX5(player)
			else
				ensureMultiplierStat(player, 1) -- garantizar estat base
			end

			-- Rails premium
			for railName, passId in pairs(GAME_PASSES) do
				if railName ~= "StarterPack" and railName ~= "MultiplierX5" then
					local owns = false
					pcall(function()
						owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
					end)
					if owns then
						RailManager.UnlockRail(player, railName)
					end
				end
			end
		end)
	end)

	-- 4) Remotos para UI cliente
	-- a) Pedir prompt por nombre
	PromptPassPurchaseEvent.OnServerEvent:Connect(function(player, passName: string)
		local passId = GAME_PASSES[passName]
		if not passId then
			if ShowWarningEvent then ShowWarningEvent:FireClient(player, "Pass no configurado.") end
			return
		end

		-- si ya lo posee, otorgar directamente
		local owns = false
		pcall(function()
			owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if owns then
			if passName == "StarterPack" and not wasPassGranted(player.UserId, "StarterPack") then
				if grantStarterPack(player) then markPassGranted(player.UserId, "StarterPack") end
			elseif passName == "MultiplierX5" then
				grantMultiplierX5(player)
			else
				RailManager.GrantPremiumRail(player, passName)
				if ShowUpgradeSuccessEvent then
					ShowUpgradeSuccessEvent:FireClient(player, nil, nil, "🎟️ " .. passName, "Unlocked!")
				end
			end
			return
		end

		-- abrir prompt
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end)

	-- b) Info/precio de un pase
	GetPassInfoFunction.OnServerInvoke = function(_, passName: string)
		local id = GAME_PASSES[passName]
		if not id then return nil end
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
		end)
		if ok then return info end
		return nil
	end

	print("✓ MonetizationManager listo.")
end

return MonetizationManager
