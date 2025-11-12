-- Configuration module for the game
-- Contains all constants and configuration values

local Config = {}

-- ============================================
-- TERRAIN CONFIGURATION
-- ============================================
Config.Terrain = {
	SpawnCenter = Vector3.new(0, 0.1, 0),
	SpawnSize = 21, -- Increased from 20 to 35 blocks radius
	TerrainSize = 256,
	BaseHeight = -40, -- Más profundo para el fondo de los lagos
	GroundLevel = 0,
	MaxHeightVariation = 5,
	
	-- Lakes configuration
	Lakes = {
		{
			Center = Vector3.new(45, 0, 45),
			Size = Vector2.new(30, 25),
			Depth = 15,  -- Profundidad más balanceada
			EdgeSlope = 1.8,
			WaterLevel = 1,  -- Agua ligeramente sobre el suelo
			BaseThickness = 8, -- Grosor del fondo del lago
		},
		{
			Center = Vector3.new(-35, 0, 60),
			Size = Vector2.new(25, 20),
			Depth = 13,
			EdgeSlope = 1.8,
			WaterLevel = 1,
			BaseThickness = 8,
		},
		{
			Center = Vector3.new(60, 0, -30),
			Size = Vector2.new(28, 22),
			Depth = 14,
			EdgeSlope = 1.8,
			WaterLevel = 1,
			BaseThickness = 8,
		},
		{
			Center = Vector3.new(-50, 0, -45),
			Size = Vector2.new(22, 18),
			Depth = 12,
			EdgeSlope = 1.8,
			WaterLevel = 1,
			BaseThickness = 8,
		},
	},
	
	-- Tree zones configuration (for denser forest areas)
	Trees = {
		SpawnRadius = 90,    -- Increased from previous value
		MinDistance = 8,     -- Minimum distance between trees
		DenseZones = {       -- Areas of particularly dense tree coverage
			{center = Vector3.new(30, 0, 70), radius = 25},
			{center = Vector3.new(-60, 0, 40), radius = 30},
			{center = Vector3.new(70, 0, -50), radius = 28},
			{center = Vector3.new(-40, 0, -65), radius = 25},
		},
		HeightVariation = {
			min = 12,
			max = 18
		},
		ScaleVariation = {
			min = 0.85,
			max = 1.15
		},
	},
}

-- ============================================
-- CASTLE WALLS CONFIGURATION
-- ============================================
Config.Castle = {
	WallHeight = 30,
	WallThickness = 4,
	BattlementHeight = 3,
	BattlementWidth = 6,
	BattlementGap = 8,
	TowerHeight = 28,
	TowerSize = 12,
}

-- ============================================
-- POOP SPAWNING CONFIGURATION
-- ============================================
Config.Poop = {
	TargetPoops = 600,
	TargetSuperPoops = 50,
	InitialSpawnInterval = 0.2,
	RespawnInterval = 0.5,
	MinDistance = 5, -- Minimum distance between poops
}

-- Super Poop types configuration (ordered by rarity)
Config.SuperPoopTypes = {
	{
		name = "Neon",
		material = Enum.Material.Neon,
		color = Color3.fromRGB(0, 255, 255),
		requiredRebirth = 2,
		reward = 5,
		spawnChance = 50, -- 50% of super poops
		lightColor = Color3.fromRGB(0, 255, 255),
		sparkleColor = Color3.fromRGB(0, 255, 255)
	},
	{
		name = "Gold",
		material = Enum.Material.Neon,
		color = Color3.fromRGB(255, 215, 0),
		requiredRebirth = 2,
		reward = 10,
		spawnChance = 30, -- 30% of super poops
		lightColor = Color3.fromRGB(255, 215, 0),
		sparkleColor = Color3.fromRGB(255, 215, 0),
		reflectance = 0.5
	},
	{
		name = "Ruby",
		material = Enum.Material.Neon,
		color = Color3.fromRGB(224, 17, 95),
		requiredRebirth = 3,
		reward = 20,
		spawnChance = 12, -- 12% of super poops
		lightColor = Color3.fromRGB(224, 17, 95),
		sparkleColor = Color3.fromRGB(255, 100, 150),
		reflectance = 0.6
	},
	{
		name = "Diamond",
		material = Enum.Material.Glass,
		color = Color3.fromRGB(185, 242, 255),
		requiredRebirth = 3,
		reward = 50,
		spawnChance = 5, -- 5% of super poops
		lightColor = Color3.fromRGB(200, 255, 255),
		sparkleColor = Color3.fromRGB(255, 255, 255),
		reflectance = 1,
		transparency = 0.3
	},
	{
		name = "Rainbow",
		material = Enum.Material.Neon,
		color = Color3.fromRGB(255, 0, 0),
		requiredRebirth = 4,
		reward = 100,
		spawnChance = 3, -- 3% of super poops (ultra rare!)
		lightColor = Color3.fromRGB(255, 255, 255),
		sparkleColor = Color3.fromRGB(255, 255, 255),
		animated = true
	}
}

-- ============================================
-- REBIRTH CONFIGURATION
-- ============================================
-- 15 Rebirths total - Easy start, gets harder progressively
Config.RebirthLevels = {
	-- EASY TIER (1-5)
	{
		cost = 50,
		poopMultiplier = 2,
		speedBoost = 0.2,
		particleColor = ColorSequence.new(Color3.fromRGB(150, 200, 255)),
		trailColor = Color3.fromRGB(150, 200, 255),
		auraColor = Color3.fromRGB(150, 200, 255),
		name = "Rebirth I"
	},
	{
		cost = 250,
		poopMultiplier = 3,
		speedBoost = 0.4,
		particleColor = ColorSequence.new(Color3.fromRGB(100, 255, 200)),
		trailColor = Color3.fromRGB(100, 255, 200),
		auraColor = Color3.fromRGB(100, 255, 200),
		name = "Rebirth II"
	},
	{
		cost = 500,
		poopMultiplier = 4,
		speedBoost = 0.6,
		particleColor = ColorSequence.new(Color3.fromRGB(255, 150, 255)),
		trailColor = Color3.fromRGB(255, 150, 255),
		auraColor = Color3.fromRGB(255, 150, 255),
		name = "Rebirth III"
	},
	{
		cost = 1000,
		poopMultiplier = 6,
		speedBoost = 0.8,
		particleColor = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
		trailColor = Color3.fromRGB(255, 255, 100),
		auraColor = Color3.fromRGB(255, 255, 100),
		name = "Rebirth IV"
	},
	{
		cost = 2000,
		poopMultiplier = 8,
		speedBoost = 1.0,
		particleColor = ColorSequence.new(Color3.fromRGB(255, 200, 100)),
		trailColor = Color3.fromRGB(255, 200, 100),
		auraColor = Color3.fromRGB(255, 200, 100),
		name = "Rebirth V"
	},
	-- MEDIUM TIER (6-10)
	{
		cost = 4000,
		poopMultiplier = 12,
		speedBoost = 1.3,
		particleColor = ColorSequence.new(Color3.fromRGB(255, 100, 150)),
		trailColor = Color3.fromRGB(255, 100, 150),
		auraColor = Color3.fromRGB(255, 100, 150),
		name = "Rebirth VI"
	},
	{
		cost = 7500,
		poopMultiplier = 16,
		speedBoost = 1.6,
		particleColor = ColorSequence.new(Color3.fromRGB(200, 100, 255)),
		trailColor = Color3.fromRGB(200, 100, 255),
		auraColor = Color3.fromRGB(200, 100, 255),
		name = "Rebirth VII"
	},
	{
		cost = 12500,
		poopMultiplier = 22,
		speedBoost = 2.0,
		particleColor = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
		trailColor = Color3.fromRGB(100, 200, 255),
		auraColor = Color3.fromRGB(100, 200, 255),
		name = "Rebirth VIII"
	},
	{
		cost = 20000,
		poopMultiplier = 30,
		speedBoost = 2.4,
		particleColor = ColorSequence.new(Color3.fromRGB(255, 150, 50)),
		trailColor = Color3.fromRGB(255, 150, 50),
		auraColor = Color3.fromRGB(255, 150, 50),
		name = "Rebirth IX"
	},
	{
		cost = 35000,
		poopMultiplier = 40,
		speedBoost = 2.8,
		particleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 255))
		}),
		trailColor = Color3.fromRGB(200, 0, 200),
		auraColor = Color3.fromRGB(200, 0, 200),
		name = "Rebirth X"
	},
	-- HARD TIER (11-15)
	{
		cost = 60000,
		poopMultiplier = 55,
		speedBoost = 3.2,
		particleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
		}),
		trailColor = Color3.fromRGB(255, 100, 0),
		auraColor = Color3.fromRGB(255, 100, 0),
		name = "Rebirth XI"
	},
	{
		cost = 100000,
		poopMultiplier = 75,
		speedBoost = 3.6,
		particleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
		}),
		trailColor = Color3.fromRGB(128, 128, 255),
		auraColor = Color3.fromRGB(128, 128, 255),
		name = "Rebirth XII"
	},
	{
		cost = 175000,
		poopMultiplier = 100,
		speedBoost = 4.0,
		particleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
		}),
		trailColor = Color3.fromRGB(255, 165, 0),
		auraColor = Color3.fromRGB(255, 165, 0),
		name = "Rebirth XIII"
	},
	{
		cost = 300000,
		poopMultiplier = 150,
		speedBoost = 4.5,
		particleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 100))
		}),
		trailColor = Color3.fromRGB(200, 200, 255),
		auraColor = Color3.fromRGB(200, 200, 255),
		name = "Rebirth XIV"
	},
	{
		cost = 500000,
		poopMultiplier = 200,
		speedBoost = 5.0,
		particleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 127, 0)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 255))
		}),
		trailColor = Color3.fromRGB(255, 255, 255),
		auraColor = Color3.fromRGB(255, 255, 255),
		name = "Rebirth XV"
	},
}

-- If we want more than the 15 static rebirths, auto-generate levels 16..100
do
	local desiredTotal = 100
	local current = #Config.RebirthLevels
	if current < desiredTotal then
		local last = Config.RebirthLevels[current]
		local lastCost = last and last.cost or 500000
		local growth = 1.25

		local function niceColor()
			return ColorSequence.new(Color3.fromRGB(200, 200, 255))
		end

		local function specialEffectsForLevel(l)
			local eff = {}
			if l >= 16 and l <= 19 then
				-- intentionally nothing
			elseif l == 20 then eff.sellRate = 5
			elseif l == 25 then eff.upgradeSlot = 1
			elseif l == 30 then eff.passivePoops = 1
			elseif l == 35 then eff.shopDiscount = 0.05
			elseif l == 40 then eff.extraPetSlot = 1
			elseif l == 45 then eff.shovelEfficiency = 0.10
			elseif l == 50 then eff.railDiscount = 0.10
			elseif l == 55 then eff.sellRate = 4
			elseif l == 60 then eff.passivePoops = 2
			elseif l == 65 then eff.upgradeSlot = 1
			elseif l == 70 then eff.globalMultiplier = 1.05
			elseif l == 75 then eff.cosmetic = "Exclusive Skin"
			elseif l == 80 then eff.sellRate = 3
			elseif l == 85 then eff.passivePoops = 3
			elseif l == 90 then eff.goldenChance = 0.01
			elseif l == 95 then eff.unlockRail = true
			elseif l == 100 then eff.globalMultiplier = 1.10
			end
			return eff
		end

		for l = current + 1, desiredTotal do
			-- escalate and round cost
			local raw = lastCost * growth
			-- round to 1 or 2 significant digits
			local exp = math.floor(math.log(math.max(raw,1)) / math.log(10))
			local pow = 10 ^ exp
			local lead = math.floor(raw / pow + 0.5)
			local cost = lead * pow
			lastCost = cost

			-- simple poop multiplier progression
			local t = (l - 16) / math.max(1, (desiredTotal - 16))
			local poopMult = math.floor(200 + (500 - 200) * t + 0.5)

			-- speed capped to the last static level's speed
			local speed = Config.RebirthLevels[#Config.RebirthLevels].speedBoost

			local effects = specialEffectsForLevel(l)

			table.insert(Config.RebirthLevels, {
				cost = cost,
				poopMultiplier = poopMult,
				speedBoost = speed,
				particleColor = niceColor(),
				trailColor = Color3.fromRGB(200, 200, 255),
				auraColor = Color3.fromRGB(200, 200, 255),
				name = "Rebirth " .. tostring(l),
				effects = effects,
			})
		end
	end
end

-- ============================================
-- PETS CONFIGURATION
-- ============================================
Config.Pets = {
	{name = "Dog", rarity = "Common", boost = 1.5, color = Color3.fromRGB(139, 69, 19), emoji = "🐕"},
	{name = "Cat", rarity = "Common", boost = 1.5, color = Color3.fromRGB(255, 165, 0), emoji = "🐈"},
	{name = "Bunny", rarity = "Common", boost = 2, color = Color3.fromRGB(255, 192, 203), emoji = "🐰"},
	{name = "Penguin", rarity = "Rare", boost = 3, color = Color3.fromRGB(0, 0, 0), emoji = "🐧"},
	{name = "Fox", rarity = "Rare", boost = 3.5, color = Color3.fromRGB(255, 69, 0), emoji = "🦊"},
	{name = "Unicorn", rarity = "Epic", boost = 5, color = Color3.fromRGB(255, 0, 255), emoji = "🦄"},
	{name = "Dragon", rarity = "Epic", boost = 6, color = Color3.fromRGB(255, 0, 0), emoji = "🐉"},
	{name = "Phoenix", rarity = "Legendary", boost = 10, color = Color3.fromRGB(255, 165, 0), emoji = "🔥"},
	{name = "Galaxy Cat", rarity = "Legendary", boost = 15, color = Color3.fromRGB(138, 43, 226), emoji = "🌌"}
}

-- Egg types configuration
Config.Eggs = {
	{
		name = "Basic Egg",
		cost = 100,
		pets = {
			{petIndex = 1, chance = 50}, -- Dog
			{petIndex = 2, chance = 50}, -- Cat
		}
	},
	{
		name = "Rare Egg",
		cost = 500,
		pets = {
			{petIndex = 3, chance = 40}, -- Bunny
			{petIndex = 4, chance = 35}, -- Penguin
			{petIndex = 5, chance = 25}, -- Fox
		}
	},
	{
		name = "Epic Egg",
		cost = 2000,
		pets = {
			{petIndex = 4, chance = 30}, -- Penguin
			{petIndex = 5, chance = 30}, -- Fox
			{petIndex = 6, chance = 25}, -- Unicorn
			{petIndex = 7, chance = 15}, -- Dragon
		}
	},
	{
		name = "Legendary Egg",
		cost = 10000,
		pets = {
			{petIndex = 6, chance = 30}, -- Unicorn
			{petIndex = 7, chance = 30}, -- Dragon
			{petIndex = 8, chance = 25}, -- Phoenix
			{petIndex = 9, chance = 15}, -- Galaxy Cat
		}
	}
}

-- ============================================
-- PLAYER CONFIGURATION
-- ============================================
Config.Player = {
	BaseSpeed = 16,
}

-- ============================================
-- SHOVEL CONFIGURATION
-- ============================================
Config.Shovel = {
	PickupPosition = Vector3.new(0, 3, 0),
	RespawnTime = 30,
	ModelName = "Shovel", -- The one shovel model to use
	BasePoopMultiplier = 1,
	BaseDigSpeed = 1.0,
	BaseRange = 8,
}

-- ============================================
-- SHOVEL UPGRADE STATS CONFIGURATION
-- ============================================
-- Cost formula: baseCost * (level ^ costExponent)
-- Different stats have different max levels and progression curves
Config.ShovelUpgradeStats = {
	{
		name = "Distance",
		displayName = "Distance",
		description = "Increases digging range",
		icon = "📏",
		baseCost = 50,
		costExponent = 1.15,
		maxLevel = 100,
		baseValue = 8,
		valuePerLevel = 0.08, -- 0.08 studs per level = 8 studs at level 100 (total: 16 studs = 8x8 area)
		statKey = "Range",
		particleEffect = true,
		roundDecimals = 1
	},
	{
		name = "Multiplier",
		displayName = "Multiplier",
		description = "Increases poop rewards",
		icon = "✖️",
		baseCost = 100,
		costExponent = 1.15,
		maxLevel = 100,
		baseValue = 1,
		valuePerLevel = 0.1,
		statKey = "PoopMultiplier",
		roundDecimals = 1, -- Round to 1 decimal place (e.g., 5.3x instead of 5.300001x)
		particleEffect = true
	},
	{
		name = "CoinsDiscover",
		displayName = "Coins Discovery",
		description = "Chance to find bonus coins",
		icon = "💰",
		baseCost = 75,
		costExponent = 1.15,
		maxLevel = 100,
		baseValue = 0,
		valuePerLevel = 0.5,
		statKey = "CoinChance",
		roundDecimals = 1
	},
	{
		name = "EggsDiscover",
		displayName = "Eggs Discovery",
		description = "Chance to find pet eggs (0.1% per level)",
		icon = "🥚",
		baseCost = 500, -- Much higher base cost
		costExponent = 1.35, -- Exponential scaling (gets EXPENSIVE fast!)
		maxLevel = 20, -- Only 20 levels!
		baseValue = 0,
		valuePerLevel = 0.1, -- 0.1% per level = 2% at level 20
		statKey = "EggChance",
		roundDecimals = 2,
		particleEffect = true
	},
	{
		name = "DigSpeed",
		displayName = "Dig Speed",
		description = "Dig faster!",
		icon = "⚡",
		baseCost = 80,
		costExponent = 1.15,
		maxLevel = 100,
		baseValue = 1.0,
		valuePerLevel = 0.02,
		statKey = "DigSpeed",
		roundDecimals = 2,
		particleEffect = true
	},
	{
		name = "LuckyChance",
		displayName = "Lucky Chance",
		description = "Chance for lucky multiplier",
		icon = "🍀",
		baseCost = 200,
		costExponent = 1.15,
		maxLevel = 100,
		baseValue = 0,
		valuePerLevel = 0.3,
		statKey = "LuckyChance",
		roundDecimals = 1
	}
}

-- ============================================
-- RAILS CONFIGURATION
-- ============================================
-- 25 unique rails with different stats and visual effects
Config.Rails = {
	-- STARTER & COMMON RAILS (1-5)
	{
		name = "None",
		displayName = "No Trail",
		description = "No trail effect",
		icon = "❌",
		cost = 0,
		requiredRebirth = 0,
		isStarter = true,
		-- No stats bonuses
	},
	{
		name = "Basic_White",
		displayName = "White Trail",
		description = "Simple white trail",
		icon = "⚪",
		cost = 100,
		requiredRebirth = 0,
		color = Color3.fromRGB(255, 255, 255),
		trailWidth = 0.5,
		trailLifetime = 1,
		-- small, subtle sparkles
		particleEffect = "sparkles",
		particleRate = 6,
		particleSize = 2,
		particleColor = Color3.fromRGB(255, 255, 255)
	},
	{
		name = "Blue_Speed",
		displayName = "Blue Speedster",
		description = "+5% movement speed",
		icon = "🔵",
		cost = 500,
		requiredRebirth = 1,
		color = Color3.fromRGB(100, 150, 255),
		trailWidth = 0.6,
		trailLifetime = 1.2,
		speedBoost = 0.05, -- +5% speed
		particleEffect = "streak",
		particleRate = 10,
		particleSize = 2.5,
		particleColor = Color3.fromRGB(160, 200, 255),
		trailTexture = "rbxassetid://131072" -- subtle streak texture
	},
	{
		name = "Green_Lucky",
		displayName = "Lucky Clover",
		description = "+2% lucky chance",
		icon = "🍀",
		cost = 1000,
		requiredRebirth = 1,
		color = Color3.fromRGB(100, 255, 100),
		trailWidth = 0.6,
		trailLifetime = 1.5,
		luckyBonus = 2, -- +2% lucky chance
		particleEffect = "clover",
		particleRate = 8,
		particleSize = 2.5
	},
	{
		name = "Yellow_Coins",
		displayName = "Gold Rush",
		description = "+3% coin discovery",
		icon = "💰",
		cost = 1500,
		requiredRebirth = 2,
		color = Color3.fromRGB(255, 215, 0),
		trailWidth = 0.7,
		trailLifetime = 1.5,
		coinBonus = 3, -- +3% coin chance
		particleEffect = "sparkles",
		particleRate = 12,
		particleSize = 3,
		particleColor = Color3.fromRGB(255, 230, 130)
	},

	-- UNCOMMON RAILS (6-10)
	{
		name = "Red_Power",
		displayName = "Red Power",
		description = "+8% poop multiplier",
		icon = "🔴",
		cost = 3000,
		requiredRebirth = 3,
		color = Color3.fromRGB(255, 50, 50),
		trailWidth = 0.8,
		trailLifetime = 2,
		poopMultiplier = 1.08, -- +8% poops
		particleEffect = "embers",
		particleRate = 14,
		particleSize = 3,
		particleColor = Color3.fromRGB(255, 100, 80)
	},
	{
		name = "Purple_Mystery",
		displayName = "Purple Mystery",
		description = "+5% lucky + +5% coins",
		icon = "🟣",
		cost = 5000,
		requiredRebirth = 4,
		color = Color3.fromRGB(150, 50, 200),
		trailWidth = 0.8,
		trailLifetime = 2,
		luckyBonus = 5,
		coinBonus = 5,
		particleEffect = "glow",
		particleRate = 10,
		particleSize = 3,
		particleColor = Color3.fromRGB(200, 120, 255)
	},
	{
		name = "Cyan_Ice",
		displayName = "Ice Trail",
		description = "+10% speed",
		icon = "🧊",
		cost = 7500,
		requiredRebirth = 4,
		color = Color3.fromRGB(100, 255, 255),
		trailWidth = 0.9,
		trailLifetime = 2.5,
		speedBoost = 0.10,
		particleEffect = "ice",
		particleRate = 18,
		particleSize = 3.5,
		particleColor = Color3.fromRGB(200, 255, 255),
		trailTexture = "rbxassetid://1095708"
	},
	{
		name = "Pink_Heart",
		displayName = "Lovely Trail",
		description = "+1% egg discovery",
		icon = "💗",
		cost = 10000,
		requiredRebirth = 5,
		color = Color3.fromRGB(255, 150, 200),
		trailWidth = 0.9,
		trailLifetime = 2,
		eggBonus = 1, -- +1% egg chance
		particleEffect = "hearts",
		particleRate = 16,
		particleSize = 3.5
	},
	{
		name = "Orange_Fire",
		displayName = "Fire Trail",
		description = "+12% multiplier",
		icon = "🔥",
		cost = 15000,
		requiredRebirth = 6,
		color = Color3.fromRGB(255, 100, 0),
		trailWidth = 1.0,
		trailLifetime = 2,
		poopMultiplier = 1.12,
		particleEffect = "fire",
		particleRate = 24,
		particleSize = 4,
		particleColor = Color3.fromRGB(255, 120, 40),
		trailTexture = "rbxassetid://131073"
	},

	-- RARE RAILS (11-15)
	{
		name = "Rainbow_Basic",
		displayName = "Rainbow Trail",
		description = "+10% all stats",
		icon = "🌈",
		cost = 25000,
		requiredRebirth = 7,
		colorAnimated = true,
		trailWidth = 1.2,
		trailLifetime = 3,
		speedBoost = 0.10,
		luckyBonus = 10,
		coinBonus = 10,
		poopMultiplier = 1.10,
		particleEffect = "rainbow_bits",
		particleRate = 30,
		particleSize = 3.5,
		trailTexture = "rbxassetid://131074"
	},
	{
		name = "Electric_Yellow",
		displayName = "Lightning Trail",
		description = "+15% speed + +5% lucky",
		icon = "⚡",
		cost = 35000,
		requiredRebirth = 8,
		color = Color3.fromRGB(255, 255, 100),
		trailWidth = 1.0,
		trailLifetime = 2.5,
		speedBoost = 0.15,
		luckyBonus = 5,
		particleEffect = "lightning",
		particleRate = 28,
		particleSize = 3.5,
		particleColor = Color3.fromRGB(255, 240, 150),
		trailTexture = "rbxassetid://131075"
	},
	{
		name = "Galaxy_Purple",
		displayName = "Galaxy Trail",
		description = "+20% multiplier",
		icon = "🌌",
		cost = 50000,
		requiredRebirth = 9,
		color = Color3.fromRGB(100, 50, 150),
		trailWidth = 1.3,
		trailLifetime = 3.5,
		poopMultiplier = 1.20,
		particleEffect = "stars",
		particleRate = 36,
		particleSize = 4,
		particleTexture = "rbxassetid://241517" -- star texture
	},
	{
		name = "Emerald_Green",
		displayName = "Emerald Trail",
		description = "+15% coins + +10% lucky",
		icon = "💎",
		cost = 75000,
		requiredRebirth = 10,
		color = Color3.fromRGB(50, 200, 100),
		trailWidth = 1.2,
		trailLifetime = 3,
		coinBonus = 15,
		luckyBonus = 10,
		particleEffect = "gems",
		particleRate = 32,
		particleSize = 4,
		particleTexture = "rbxassetid://241518"
	},
	{
		name = "Blood_Red",
		displayName = "Blood Moon",
		description = "+25% multiplier",
		icon = "🌙",
		cost = 100000,
		requiredRebirth = 11,
		color = Color3.fromRGB(150, 0, 0),
		trailWidth = 1.4,
		trailLifetime = 3,
		poopMultiplier = 1.25,
		particleEffect = "blood",
		particleRate = 28,
		particleSize = 4,
		particleColor = Color3.fromRGB(180, 30, 30)
	},

	-- EPIC RAILS (16-20)
	{
		name = "Diamond_Trail",
		displayName = "Diamond Luxury",
		description = "+2% eggs + +20% coins",
		icon = "💠",
		cost = 150000,
		requiredRebirth = 12,
		color = Color3.fromRGB(185, 242, 255),
		trailWidth = 1.5,
		trailLifetime = 4,
		eggBonus = 2,
		coinBonus = 20,
		particleEffect = "diamonds",
		particleRate = 40,
		particleSize = 5,
		particleTexture = "rbxassetid://241519",
		trailTexture = "rbxassetid://131076",
		lightEmission = 0.7
	},
	{
		name = "Lava_Trail",
		displayName = "Lava Flow",
		description = "+30% multiplier + +10% speed",
		icon = "🌋",
		cost = 200000,
		requiredRebirth = 13,
		colorGradient = {
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(255, 0, 0)
		},
		trailWidth = 1.6,
		trailLifetime = 4,
		poopMultiplier = 1.30,
		speedBoost = 0.10,
		particleEffect = "lava",
		particleRate = 48,
		particleSize = 5.5,
		particleTexture = "rbxassetid://241520",
		trailTexture = "rbxassetid://131077",
		lightEmission = 0.6
	},
	{
		name = "Aurora_Trail",
		displayName = "Aurora Borealis",
		description = "+15% all stats",
		icon = "✨",
		cost = 300000,
		requiredRebirth = 14,
		colorAnimated = true,
		trailWidth = 1.8,
		trailLifetime = 5,
		speedBoost = 0.15,
		luckyBonus = 15,
		coinBonus = 15,
		eggBonus = 1.5,
		poopMultiplier = 1.15,
		particleEffect = "aurora",
		particleRate = 60,
		particleSize = 5,
		particleTexture = "rbxassetid://241521",
		trailTexture = "rbxassetid://131078",
		lightEmission = 0.8
	},
	{
		name = "Shadow_Trail",
		displayName = "Shadow Walker",
		description = "+20% lucky + +25% multiplier",
		icon = "🌑",
		cost = 400000,
		requiredRebirth = 14,
		color = Color3.fromRGB(50, 50, 80),
		trailWidth = 1.5,
		trailLifetime = 4,
		luckyBonus = 20,
		poopMultiplier = 1.25,
		particleEffect = "shadows",
		particleRate = 36,
		particleSize = 5,
		particleColor = Color3.fromRGB(70, 70, 100),
		trailTexture = "rbxassetid://131079"
	},
	{
		name = "Golden_Royal",
		displayName = "Royal Gold",
		description = "+25% coins + +30% multiplier",
		icon = "👑",
		cost = 500000,
		requiredRebirth = 15,
		color = Color3.fromRGB(255, 215, 0),
		trailWidth = 2.0,
		trailLifetime = 5,
		coinBonus = 25,
		poopMultiplier = 1.30,
		particleEffect = "crown",
		particleRate = 72,
		particleSize = 6,
		particleTexture = "rbxassetid://241522",
		trailTexture = "rbxassetid://131080",
		lightEmission = 0.95
	},

	-- LEGENDARY RAILS (21-25)
	{
		name = "Nebula_Trail",
		displayName = "Cosmic Nebula",
		description = "+3% eggs + +20% lucky + +35% multiplier",
		icon = "🌠",
		cost = 750000,
		requiredRebirth = 15,
		colorAnimated = true,
		trailWidth = 2.2,
		trailLifetime = 6,
		eggBonus = 3,
		luckyBonus = 20,
		poopMultiplier = 1.35,
		particleEffect = "nebula",
		particleRate = 90,
		particleSize = 6,
		particleTexture = "rbxassetid://241523",
		trailTexture = "rbxassetid://131081",
		lightEmission = 0.9
	},
	{
		name = "Void_Trail",
		displayName = "Void Walker",
		description = "+25% speed + +40% multiplier",
		icon = "⚫",
		cost = 1000000,
		requiredRebirth = 15,
		color = Color3.fromRGB(20, 20, 40),
		trailWidth = 2.0,
		trailLifetime = 5,
		speedBoost = 0.25,
		poopMultiplier = 1.40,
		particleEffect = "void",
		particleRate = 100,
		particleSize = 6.5,
		particleTexture = "rbxassetid://241524",
		trailTexture = "rbxassetid://131082",
		lightEmission = 0.85
	},
	{
		name = "Rainbow_Legendary",
		displayName = "Rainbow Infinity",
		description = "+20% all stats + +4% eggs",
		icon = "🎨",
		cost = 1500000,
		requiredRebirth = 15,
		colorAnimated = true,
		trailWidth = 2.5,
		trailLifetime = 7,
		speedBoost = 0.20,
		luckyBonus = 20,
		coinBonus = 20,
		eggBonus = 4,
		poopMultiplier = 1.20,
		particleEffect = "rainbow_infinity",
		particleRate = 140,
		particleSize = 7,
		particleTexture = "rbxassetid://241525",
		trailTexture = "rbxassetid://131083",
		lightEmission = 1.0
	},
	{
		name = "Phoenix_Trail",
		displayName = "Phoenix Rebirth",
		description = "+30% speed + +50% multiplier",
		icon = "🔥",
		cost = 2000000,
		requiredRebirth = 15,
		colorGradient = {
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(255, 200, 0),
			Color3.fromRGB(255, 50, 50)
		},
		trailWidth = 2.8,
		trailLifetime = 8,
		speedBoost = 0.30,
		poopMultiplier = 1.50,
		particleEffect = "phoenix",
		particleRate = 160,
		particleSize = 7.5,
		particleTexture = "rbxassetid://241526",
		trailTexture = "rbxassetid://131084",
		lightEmission = 1.0
	},
	{
		name = "Celestial_Divine",
		displayName = "Divine Celestial",
		description = "MAX STATS: +30% speed, +30% lucky, +30% coins, +5% eggs, +60% multiplier",
		icon = "⭐",
		cost = 3000000,
		requiredRebirth = 15,
		colorAnimated = true,
		trailWidth = 3.0,
		trailLifetime = 10,
		speedBoost = 0.30,
		luckyBonus = 30,
		coinBonus = 30,
		eggBonus = 5,
		poopMultiplier = 1.60,
		particleEffect = "celestial",
		particleRate = 220,
		particleSize = 8,
		particleTexture = "rbxassetid://241527",
		trailTexture = "rbxassetid://131085",
		lightEmission = 1.0
	},

	-- PREMIUM RAILS (Robux only)
	{
		name = "Premium_Turbo",
		displayName = "Turbo Boost",
		description = "PREMIUM: +15% speed, +10% lucky, +20% multiplier",
		icon = "⚡",
		cost = 29, -- 29 Robux
		requiredRebirth = 0,
		isPremium = true,
		robuxPrice = 29,
		color = Color3.fromRGB(255, 220, 0),
		trailWidth = 1.5,
		trailLifetime = 4,
		speedBoost = 0.15,
		luckyBonus = 10,
		poopMultiplier = 1.20,
		particleEffect = "lightning",
		particleRate = 40,
		particleSize = 5,
		trailTexture = "rbxassetid://131086"
	},
	{
		name = "Premium_Fortune",
		displayName = "Fortune Master",
		description = "PREMIUM: +20% coins, +15% lucky, +3% eggs, +25% multiplier",
		icon = "💎",
		cost = 49, -- 49 Robux
		requiredRebirth = 0,
		isPremium = true,
		robuxPrice = 49,
		colorGradient = {
			Color3.fromRGB(0, 200, 255),
			Color3.fromRGB(150, 50, 255),
			Color3.fromRGB(255, 100, 200)
		},
		trailWidth = 1.8,
		trailLifetime = 5,
		coinBonus = 20,
		luckyBonus = 15,
		eggBonus = 3,
		poopMultiplier = 1.25,
		particleEffect = "diamond",
		particleRate = 60,
		particleSize = 6,
		trailTexture = "rbxassetid://131087",
		particleTexture = "rbxassetid://241528"
	},
	{
		name = "Premium_Ultimate",
		displayName = "Ultimate Power",
		description = "PREMIUM MAX: +25% speed, +25% lucky, +25% coins, +4% eggs, +40% multiplier",
		icon = "🌟",
		cost = 69, -- 69 Robux
		requiredRebirth = 0,
		isPremium = true,
		robuxPrice = 69,
		colorAnimated = true,
		trailWidth = 2.5,
		trailLifetime = 7,
		speedBoost = 0.25,
		luckyBonus = 25,
		coinBonus = 25,
		eggBonus = 4,
		poopMultiplier = 1.40,
		particleEffect = "ultimate",
		particleRate = 120,
		particleSize = 7,
		particleTexture = "rbxassetid://241529",
		trailTexture = "rbxassetid://131088",
		lightEmission = 1.0
	}
}

-- ============================================
-- PET EGG RARITIES CONFIGURATION
-- ============================================
-- When a player discovers an egg, this determines which egg type they get
Config.EggRarities = {
	{
		name = "Common Egg",
		icon = "🥚",
		color = Color3.fromRGB(200, 200, 200),
		chance = 50, -- 50% of all egg drops
		coinsValue = 100, -- Can sell for coins
		petMultiplier = 1.2 -- Pets from this egg give 1.2x boost
	},
	{
		name = "Uncommon Egg",
		icon = "🥚",
		color = Color3.fromRGB(100, 255, 100),
		chance = 30, -- 30%
		coinsValue = 300,
		petMultiplier = 1.5
	},
	{
		name = "Rare Egg",
		icon = "🥚",
		color = Color3.fromRGB(100, 150, 255),
		chance = 12, -- 12%
		coinsValue = 800,
		petMultiplier = 2.0
	},
	{
		name = "Epic Egg",
		icon = "🥚",
		color = Color3.fromRGB(200, 100, 255),
		chance = 6, -- 6%
		coinsValue = 2000,
		petMultiplier = 3.0
	},
	{
		name = "Legendary Egg",
		icon = "🥚",
		color = Color3.fromRGB(255, 200, 50),
		chance = 2, -- 2% (very rare!)
		coinsValue = 10000,
		petMultiplier = 5.0
	}
}

return Config
