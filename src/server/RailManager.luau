-- RailManager.luau
-- Manages player rail/trail ownership, equipping and persistence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent:WaitForChild("Config"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local RailManager = {}

-- Estructura en memoria:
-- playerRailData[userId] = { currentRail = "None", ownedRails = {"None"} }
local playerRailData: {[number]: {currentRail: string, ownedRails: {string}}} = {}

-- ============================================
-- HELPERS
-- ============================================

local function getRailConfig(railName: string)
	for _, railData in ipairs(Config.Rails) do
		if railData.name == railName then
			return railData
		end
	end
	return nil
end

local function ensurePlayerSlot(player: Player)
	local uid = player.UserId
	if not playerRailData[uid] then
		playerRailData[uid] = {
			currentRail = "None",
			ownedRails = {"None"},
		}
	end
	return playerRailData[uid]
end

-- Crea/actualiza el Trail en el personaje (servidor -> todos lo ven)
local function applyRailToCharacter(player: Player, railConfig)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Limpieza agresiva: borra TODOS los trails previos
	for _, inst in ipairs(character:GetDescendants()) do
		if inst:IsA("Trail") then
			inst:Destroy()
		end
	end

	-- Limpieza de partículas/efectos previos parented a las attachments (si existen).
	-- Esto evita que al cambiar de rail queden Sparkles/Fire/ParticleEmitters duplicados.
	local function clearAttachmentEffects(att)
		if not att then return end
		for _, c in ipairs(att:GetChildren()) do
			if c:IsA("ParticleEmitter") or c:IsA("Sparkles") or c:IsA("Fire") or c:IsA("Beam")
				or c:IsA("PointLight") or c:IsA("SurfaceLight") or c:IsA("SpotLight") then
				c:Destroy()
			end
		end
	end

	local oldA0 = hrp:FindFirstChild("TrailAttachment0")
	local oldA1 = hrp:FindFirstChild("TrailAttachment1")
	clearAttachmentEffects(oldA0)
	clearAttachmentEffects(oldA1)

	-- Si no hay config o el rail es "None", sacar attachments y salir
	if (not railConfig) or railConfig.name == "None" then
		local a0 = hrp:FindFirstChild("TrailAttachment0"); if a0 then a0:Destroy() end
		local a1 = hrp:FindFirstChild("TrailAttachment1"); if a1 then a1:Destroy() end
		return
	end

	-- Attachments propios (nombres consistentes con cliente)
	local a0 = hrp:FindFirstChild("TrailAttachment0")
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = "TrailAttachment0"
		a0.Position = Vector3.new(-1, 0, 0)
		a0.Parent = hrp
	end

	local a1 = hrp:FindFirstChild("TrailAttachment1")
	if not a1 then
		a1 = Instance.new("Attachment")
		a1.Name = "TrailAttachment1"
		a1.Position = Vector3.new(1, 0, 0)
		a1.Parent = hrp
	end

	-- Color seguro (fallbacks: colorAnimated -> colorSequence -> color -> white)
	local colorSeq = nil
	if railConfig.colorAnimated then
		colorSeq = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 127, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 255))
		})
	elseif railConfig.colorSequence then
		colorSeq = railConfig.colorSequence
	elseif railConfig.colorGradient and type(railConfig.colorGradient) == "table" then
		-- build a ColorSequence from a gradient table
		local items = {}
		local count = #railConfig.colorGradient
		if count == 0 then
			colorSeq = ColorSequence.new(Color3.fromRGB(255,255,255))
		else
			for i, c in ipairs(railConfig.colorGradient) do
				local t = (i - 1) / math.max(1, count - 1)
				table.insert(items, ColorSequenceKeypoint.new(t, c))
			end
			colorSeq = ColorSequence.new(items)
		end
	elseif railConfig.color then
		colorSeq = ColorSequence.new(railConfig.color)
	else
		colorSeq = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	end

	local trail = Instance.new("Trail")
	trail.Name = "PlayerRailTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = railConfig.trailLifetime or railConfig.lifetime or 0.8
	trail.Color = colorSeq
	-- Transparency can be provided as NumberSequence or a single number
	if type(railConfig.transparency) == "number" then
		trail.Transparency = NumberSequence.new(railConfig.transparency)
	elseif typeof(railConfig.transparency) == "Instance" then
		trail.Transparency = railConfig.transparency
	else
		trail.Transparency = railConfig.transparency or NumberSequence.new(0.2)
	end
	trail.LightEmission = railConfig.lightEmission or 0.4
	trail.FaceCamera = railConfig.faceCamera == nil and true or railConfig.faceCamera
	-- WidthScale supports either a number (uniform) or a NumberSequence
	if type(railConfig.trailWidth) == "number" then
		trail.WidthScale = NumberSequence.new(railConfig.trailWidth)
	else
		trail.WidthScale = railConfig.trailWidth or NumberSequence.new(0.5)
	end
	trail.MinLength = railConfig.minLength or 0.1
	-- Optional trail texture for stripey/neon effects
	if railConfig.trailTexture then
		pcall(function() trail.Texture = railConfig.trailTexture end)
	end
	-- Parent the Trail to the HumanoidRootPart so it replicates correctly to all clients
	trail.Parent = hrp
	-- If the rail has particleEffect configured, create server-side replicated effects
	if railConfig.particleEffect then
		local effect = railConfig.particleEffect
		if effect == "sparkles" then
			local s1 = Instance.new("Sparkles")
			s1.SparkleColor = railConfig.particleColor or Color3.fromRGB(255, 215, 0)
			s1.Parent = a0
			local s2 = s1:Clone()
			s2.Parent = a1
		elseif effect == "fire" then
			local f1 = Instance.new("Fire")
			f1.Size = railConfig.particleSize or 5
			f1.Heat = railConfig.particleHeat or 10
			f1.Color = railConfig.particleColor or Color3.fromRGB(255, 100, 0)
			f1.SecondaryColor = railConfig.particleSecondaryColor or Color3.fromRGB(255, 200, 0)
			f1.Parent = a0
			local f2 = f1:Clone()
			f2.Parent = a1
		else
			-- Generic ParticleEmitter (best-effort) -- texture can be provided in config.particleTexture
			local pe1 = Instance.new("ParticleEmitter")
			pe1.Rate = railConfig.particleRate or 20
			pe1.Lifetime = railConfig.particleLifetime or NumberRange.new(0.6, 1.8)
			pe1.Speed = railConfig.particleSpeed or NumberRange.new(1, 3)
			-- Size
			if railConfig.particleSize then
				pe1.Size = NumberSequence.new(railConfig.particleSize)
			else
				pe1.Size = NumberSequence.new(2)
			end
			-- Color
			if railConfig.particleColor then
				pe1.Color = ColorSequence.new(railConfig.particleColor)
			end
			-- Light and texture
			pe1.LightEmission = railConfig.particleLightEmission or 0
			if railConfig.particleTexture then pe1.Texture = railConfig.particleTexture end
			pe1.Parent = a0
			local pe2 = pe1:Clone()
			pe2.Parent = a1
		end
	end
end

-- ============================================
-- PERSISTENCIA
-- ============================================

-- Blob que guardamos
function RailManager.GetSaveData(player: Player)
	local slot = ensurePlayerSlot(player)
	return {
		currentRail = slot.currentRail,
		ownedRails  = slot.ownedRails,
	}
end

-- Restaura desde el blob
function RailManager.LoadSaveData(player: Player, blob: any)
	if type(blob) ~= "table" then return end
	RailManager.SetOwnedRails(
		player,
		blob.ownedRails or {"None"},
		blob.currentRail or "None"
	)
end

-- Guarda el blob usando la API que tenga tu DataManager
local function saveRails(player: Player)
	local ok, err = pcall(function()
		-- Modo 1: DataManager mantiene un "blob completo"
		if DataManager.GetPlayerData and DataManager.SavePlayerData then
			local all = DataManager.GetPlayerData(player) or {}
			all.rails = RailManager.GetSaveData(player)
			DataManager.SavePlayerData(player, all)
			return
		end

		-- Modo 2: DataManager permite setear un campo puntual
		if DataManager.SetPlayerField then
			DataManager.SetPlayerField(player, "rails", RailManager.GetSaveData(player))
			return
		end

		-- Modo 3: Sólo SaveData(player). Intentamos pasarle info si expone SetTempSection,
		-- de lo contrario al menos invocamos SaveData.
		if DataManager.SetTempSection then
			DataManager.SetTempSection(player, "rails", RailManager.GetSaveData(player))
		end
		if DataManager.SaveData then
			DataManager.SaveData(player)
		end
	end)
	if not ok then
		warn("[RailManager] saveRails error:", err)
	end
end

-- Carga desde DataManager en PlayerAdded
local function loadRails(player: Player)
	local ok, dataOrErr = pcall(function()
		-- Prefer explicit LoadData if DataManager exposes it (returns full player blob)
		if DataManager.LoadData then
			return DataManager.LoadData(player)
		end

		-- Legacy hooks some DataManagers might expose
		if DataManager.GetPlayerData then
			local all = DataManager.GetPlayerData(player)
			return all
		end

		if DataManager.GetPlayerField then
			return { OwnedRails = DataManager.GetPlayerField(player, "rails") }
		end

		return nil
	end)

	if ok and dataOrErr then
		-- If we received a full player blob (DataManager.LoadData), it likely uses OwnedRails/CurrentRail
		if type(dataOrErr) == "table" then
			if dataOrErr.OwnedRails or dataOrErr.CurrentRail then
				RailManager.SetOwnedRails(player, dataOrErr.OwnedRails or {"None"}, dataOrErr.CurrentRail or "None")
				return
			end

			-- If DataManager.GetPlayerData returned a table with .rails section
			if dataOrErr.rails then
				RailManager.LoadSaveData(player, dataOrErr.rails)
				return
			end

			-- Fallback: assume dataOrErr is already the rails blob (ownedRails/currentRail)
			RailManager.LoadSaveData(player, dataOrErr)
			return
		end
	else
		if not ok then
			warn("[RailManager] loadRails error:", dataOrErr)
		end
		-- primera vez => slot por defecto ya queda con "None"
	end
end

-- ============================================
-- PUBLIC READ APIS
-- ============================================

function RailManager.GetPlayerRail(player: Player): string
	local slot = ensurePlayerSlot(player)
	return slot.currentRail
end

-- Devuelve copia con el actual primero (compat UI)
function RailManager.GetOwnedRails(player: Player): {string}
	local slot = ensurePlayerSlot(player)
	local current = slot.currentRail
	local sorted = {}

	table.insert(sorted, current)
	for _, r in ipairs(slot.ownedRails) do
		if r ~= current then
			table.insert(sorted, r)
		end
	end
	return sorted
end

function RailManager.OwnsRail(player: Player, railName: string): boolean
	local slot = ensurePlayerSlot(player)
	for _, r in ipairs(slot.ownedRails) do
		if r == railName then return true end
	end
	return false
end

function RailManager.GetRailStats(player: Player)
	local cfg = getRailConfig(RailManager.GetPlayerRail(player))
	if not cfg then return {} end
	return {
		speedBoost     = cfg.speedBoost or 0,
		luckyBonus     = cfg.luckyBonus or 0,
		coinBonus      = cfg.coinBonus or 0,
		eggBonus       = cfg.eggBonus or 0,
		poopMultiplier = cfg.poopMultiplier or 1.0,
	}
end

-- ============================================
-- EQUIP / UNLOCK / SET
-- ============================================

function RailManager.EquipRail(player: Player, railName: string): boolean
	print("========================================")
	print("RailManager: Equipping rail", railName, "for", player.Name)
	print("========================================")

	local cfg = getRailConfig(railName)
	if not cfg then
		warn("Rail config not found for:", railName)
		return false
	end

	local slot = ensurePlayerSlot(player)

	-- Garantizá ownership por si viene de restore/cambio
	local owned = false
	for _, r in ipairs(slot.ownedRails) do
		if r == railName then owned = true break end
	end
	if not owned then
		table.insert(slot.ownedRails, railName)
	end

	slot.currentRail = railName

	applyRailToCharacter(player, cfg)

	local updateRailEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerRailEvent")
	if updateRailEvent then
		updateRailEvent:FireClient(player, cfg)
	end

	saveRails(player) -- 🔒 persistimos inmediatamente
	print("✅ Rail equipped successfully:", railName)
	return true
end

-- Desbloquea un rail sin equipar (evita duplicados)
function RailManager.UnlockRail(player: Player, railName: string): boolean
	local slot = ensurePlayerSlot(player)
	for _, r in ipairs(slot.ownedRails) do
		if r == railName then return true end
	end
	table.insert(slot.ownedRails, railName)
	saveRails(player)
	return true
end

-- Restaura toda la lista y el actual de una (preferido en load)
function RailManager.SetOwnedRails(player: Player, ownedList: {string}?, currentRail: string?)
	local slot = ensurePlayerSlot(player)

	ownedList = ownedList or {"None"}

	-- garantizar "None"
	local hasNone = false
	for _, r in ipairs(ownedList) do
		if r == "None" then hasNone = true break end
	end
	if not hasNone then
		table.insert(ownedList, 1, "None")
	end

	slot.ownedRails = ownedList
	slot.currentRail = currentRail or "None"

	local cfg = getRailConfig(slot.currentRail)
	if cfg then
		applyRailToCharacter(player, cfg)
		local updateRailEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerRailEvent")
		if updateRailEvent then
			updateRailEvent:FireClient(player, cfg)
		end
	end

	saveRails(player)
end

-- ============================================
-- PURCHASE / PREMIUM
-- ============================================

function RailManager.GrantPremiumRail(player: Player, railName: string): boolean
	print("========================================")
	print("RailManager: Granting premium rail", railName, "to", player.Name)
	print("========================================")

	if RailManager.OwnsRail(player, railName) then
		warn("Player already owns:", railName)
		return false
	end

	local cfg = getRailConfig(railName)
	if not cfg then
		warn("Rail config not found for:", railName); return false
	end
	if not cfg.isPremium then
		warn("Rail is not premium:", railName); return false
	end

	local slot = ensurePlayerSlot(player)
	table.insert(slot.ownedRails, railName)
	print("✓ Added premium rail to owned rails:", railName)

	RailManager.EquipRail(player, railName) -- esto ya guarda
	print("========================================")
	print("✅ PREMIUM RAIL GRANTED!")
	print("  - Rail:", railName)
	print("========================================")
	return true
end

function RailManager.PurchaseRail(player: Player, railName: string): boolean
	print("========================================")
	print("RailManager: Purchase request for", railName, "by", player.Name)
	print("========================================")

	if RailManager.OwnsRail(player, railName) then
		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, "You already own this rail!")
		end
		return false
	end

	local cfg = getRailConfig(railName)
	if not cfg then
		warn("Rail config not found for:", railName); return false
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then warn("Player has no leaderstats"); return false end

	local rebirthValue = leaderstats:FindFirstChild("Rebirths")
	if not rebirthValue then warn("Player has no Rebirths stat"); return false end
	if rebirthValue.Value < (cfg.requiredRebirth or 0) then
		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, string.format("Requires Rebirth %d!", cfg.requiredRebirth or 0))
		end
		return false
	end

	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue then warn("Player has no Coins stat"); return false end
	if coinsValue.Value < (cfg.cost or 0) then
		local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
		if showWarningEvent then
			showWarningEvent:FireClient(player, string.format("Need %d coins! (You have %d)", cfg.cost or 0, coinsValue.Value))
		end
		return false
	end

	-- pagar
	coinsValue.Value -= (cfg.cost or 0)
	print("✓ Deducted", cfg.cost or 0, "coins. Remaining:", coinsValue.Value)

	-- agregar a owned y equipar (EquipRail ya guarda)
	local slot = ensurePlayerSlot(player)
	table.insert(slot.ownedRails, railName)
	print("✓ Added rail to owned rails:", railName)

	RailManager.EquipRail(player, railName)

	-- feedback
	local showUpgradeEvent = ReplicatedStorage:FindFirstChild("ShowUpgradeSuccessEvent")
	if showUpgradeEvent then
		showUpgradeEvent:FireClient(player, "Rail Purchased", cfg.displayName or railName)
	end

	print("========================================")
	print("✅ PURCHASE SUCCESSFUL!")
	print("  - Rail:", railName)
	print("  - Cost:", cfg.cost or 0)
	print("========================================")
	return true
end

-- ============================================
-- REMOTES & SETUP
-- ============================================

function RailManager.SetupRemoteEvents()
	print("RailManager: Setting up remote events...")

	local purchaseRailEvent = Instance.new("RemoteEvent")
	purchaseRailEvent.Name = "PurchaseRailEvent"
	purchaseRailEvent.Parent = ReplicatedStorage
	purchaseRailEvent.OnServerEvent:Connect(function(player, railName)
		RailManager.PurchaseRail(player, railName)
	end)

	local equipRailEvent = Instance.new("RemoteEvent")
	equipRailEvent.Name = "EquipRailEvent"
	equipRailEvent.Parent = ReplicatedStorage
	equipRailEvent.OnServerEvent:Connect(function(player, railName)
		RailManager.EquipRail(player, railName)
	end)

	local getOwnedRailsFunc = Instance.new("RemoteFunction")
	getOwnedRailsFunc.Name = "GetOwnedRailsFunction"
	getOwnedRailsFunc.Parent = ReplicatedStorage
	getOwnedRailsFunc.OnServerInvoke = function(player)
		return RailManager.GetOwnedRails(player)
	end

	local updateRailEvent = Instance.new("RemoteEvent")
	updateRailEvent.Name = "UpdatePlayerRailEvent"
	updateRailEvent.Parent = ReplicatedStorage

	print("✓ Remote events created!")
end

function RailManager.SetupPlayers()
	print("========================================")
	print("RailManager: Setting up players...")
	print("========================================")

	-- Jugadores existentes
	for _, player in ipairs(Players:GetPlayers()) do
		ensurePlayerSlot(player)
		loadRails(player)

		player.CharacterAdded:Connect(function()
			task.wait(1)
			local railName = RailManager.GetPlayerRail(player)
			local cfg = getRailConfig(railName)
			applyRailToCharacter(player, cfg)

			local updateRailEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerRailEvent")
			if updateRailEvent and cfg then
				updateRailEvent:FireClient(player, cfg)
				print("✓ Sent initial rail to", player.Name, ":", railName)
			end
		end)
	end

	-- Nuevos jugadores
	Players.PlayerAdded:Connect(function(player)
		ensurePlayerSlot(player)
		loadRails(player)

		player.CharacterAdded:Connect(function()
			task.wait(1)
			local railName = RailManager.GetPlayerRail(player)
			local cfg = getRailConfig(railName)
			applyRailToCharacter(player, cfg)

			local updateRailEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerRailEvent")
			if updateRailEvent and cfg then
				updateRailEvent:FireClient(player, cfg)
				print("✓ Sent initial rail to", player.Name, ":", railName)
			end
		end)
	end)

	-- Guardar al salir / cerrar
	Players.PlayerRemoving:Connect(function(p) saveRails(p) end)
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do
			saveRails(p)
		end
	end)

	print("✅ RailManager player setup complete!")
end

return RailManager
