-- test_shovel_upgrades_harness.luau
-- Simple server-side test harness for ShovelUpgradeManager pricing and stat values

local Config = require(script.Parent:WaitForChild("Config"))
local ShovelUpgradeManager = require(script.Parent:WaitForChild("ShovelUpgradeManager"))

print("===== Shovel Upgrade Test Harness =====")

local stats = Config.ShovelUpgradeStats or {}
if #stats == 0 then
	warn("No shovel stats configured in Config.ShovelUpgradeStats")
	return
end

for _, stat in ipairs(stats) do
	print(string.format("--- Stat: %s (%s) ---", tostring(stat.name), tostring(stat.displayName or "")))
	-- Print sample values for levels 0,1,2,5,10,25,50,80,99
	local levels = {0,1,2,5,10,25,50,80,99}
	for _, lvl in ipairs(levels) do
		local val = ShovelUpgradeManager and ShovelUpgradeManager.GetCompiledStats and (function()
			-- Use internal calculation function by calling calculateStatValue via a thin wrapper (we'll replicate expected behavior)
			-- Since calculateStatValue is local inside the module, we use the public API: simulate by creating a fake player is hard here.
			-- Instead we'll call GetUpgradeMetadata if available and compute cost/value via that path.
			local meta = ShovelUpgradeManager.GetUpgradeMetadata and ShovelUpgradeManager.GetUpgradeMetadata({})
			return nil
		end)() or nil
		-- For cost, call the module function directly by simulating currentLevel
		local ok, cost = pcall(function()
			return ShovelUpgradeManager and ShovelUpgradeManager._internal and ShovelUpgradeManager._internal.calculateUpgradeCost
		end)
		-- We can't reliably reach private functions; instead, print cost by using our own calc using config
		local function calcCost(cfg, curLevel)
			if curLevel >= cfg.maxLevel then return nil end
			local nextLevel = curLevel + 1
			local mode = cfg.costMode or "exp"
			if mode == "power" then
				local exponent = cfg.costExponent or 1.15
				return math.floor(cfg.baseCost * (nextLevel ^ exponent))
			else
				local multiplier = cfg.costMultiplier or 1.15
				local offset = cfg.costOffset or 0
				return math.floor(cfg.baseCost * (multiplier ^ (nextLevel + offset)))
			end
		end

		local costVal = calcCost(stat, lvl)
		-- Calculate stat value using same formula as module
		local rawValue = stat.baseValue + (stat.valuePerLevel * lvl)
		local roundedInt = math.floor(rawValue + 0.5)
		local displayVal
		if math.abs(rawValue - roundedInt) < 1e-9 then
			displayVal = roundedInt
		else
			local decimals = stat.roundDecimals or 2
			local m = 10 ^ decimals
			displayVal = math.floor(rawValue * m + 0.5) / m
		end

		print(string.format("Level %3d -> Value: %s    NextCost: %s", lvl, tostring(displayVal), tostring(costVal)))
	end
end

print("===== End of harness =====")
