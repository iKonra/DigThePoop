-- AdminCommands.luau
-- Simple admin command system for testing and development

local AdminCommands = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================
-- ADMIN LIST (Add your Roblox username here!)
-- ============================================
local ADMINS = {
	"SanchopeXXL",
	"bocharosa",
	-- Add admin usernames here
	-- Add more usernames as needed
}

-- Check if player is admin
local function isAdmin(player)
	for _, adminName in ipairs(ADMINS) do
		if player.Name == adminName or adminName == "YourUsernameHere" then
			-- Allow everyone if default username not changed (for testing)
			if adminName == "YourUsernameHere" then
				return true
			end
			if player.Name == adminName then
				return true
			end
		end
	end
	return false
end

-- Send message to player
local function sendMessage(player, message)
	local showWarningEvent = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
	if showWarningEvent then
		showWarningEvent:FireClient(player, message)
	end
end

-- ============================================
-- COMMAND HANDLERS
-- ============================================

local commands = {}

-- /give poops [amount]
commands.give = function(player, args)
	if not args[2] then
		sendMessage(player, "Usage: /give [poops/coins/rebirths] [amount]")
		return
	end

	local resourceType = args[2]:lower()
	local amount = tonumber(args[3]) or 1000

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		sendMessage(player, "❌ Error: No leaderstats found")
		return
	end

	if resourceType == "poops" or resourceType == "poop" then
		local poops = leaderstats:FindFirstChild("Poops Cleared")
		if poops then
			poops.Value = poops.Value + amount
			sendMessage(player, string.format("✅ Added %d poops! (Total: %d)", amount, poops.Value))
			print(string.format("Admin %s gave themselves %d poops", player.Name, amount))
		end

	elseif resourceType == "coins" or resourceType == "coin" then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + amount
			sendMessage(player, string.format("✅ Added %d coins! (Total: %d)", amount, coins.Value))
			print(string.format("Admin %s gave themselves %d coins", player.Name, amount))
		end

	elseif resourceType == "rebirths" or resourceType == "rebirth" then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = rebirths.Value + amount
			sendMessage(player, string.format("✅ Added %d rebirths! (Total: %d)", amount, rebirths.Value))
			print(string.format("Admin %s gave themselves %d rebirths", player.Name, amount))
		end

	else
		sendMessage(player, "❌ Unknown resource type. Use: poops, coins, or rebirths")
	end
end

-- /set [poops/coins/rebirths] [amount]
commands.set = function(player, args)
	if not args[2] or not args[3] then
		sendMessage(player, "Usage: /set [poops/coins/rebirths] [amount]")
		return
	end

	local resourceType = args[2]:lower()
	local amount = tonumber(args[3]) or 0

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		sendMessage(player, "❌ Error: No leaderstats found")
		return
	end

	if resourceType == "poops" or resourceType == "poop" then
		local poops = leaderstats:FindFirstChild("Poops Cleared")
		if poops then
			poops.Value = amount
			sendMessage(player, string.format("✅ Set poops to %d", amount))
			print(string.format("Admin %s set poops to %d", player.Name, amount))
		end

	elseif resourceType == "coins" or resourceType == "coin" then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = amount
			sendMessage(player, string.format("✅ Set coins to %d", amount))
			print(string.format("Admin %s set coins to %d", player.Name, amount))
		end

	elseif resourceType == "rebirths" or resourceType == "rebirth" then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = amount
			sendMessage(player, string.format("✅ Set rebirths to %d", amount))
			print(string.format("Admin %s set rebirths to %d", player.Name, amount))

			-- Reapply rebirth effects
			local RebirthManager = require(script.Parent.RebirthManager)
			RebirthManager.ApplySpeedBoost(player)
			RebirthManager.ApplyPlayerEffects(player)
		end

	else
		sendMessage(player, "❌ Unknown resource type. Use: poops, coins, or rebirths")
	end
end

-- /clear - Clear all poops
commands.clear = function(player, args)
	local poopsFolder = workspace:FindFirstChild("BrainrotPoops")
	if poopsFolder then
		local count = #poopsFolder:GetChildren()
		poopsFolder:ClearAllChildren()
		sendMessage(player, string.format("✅ Cleared %d poops from workspace", count))
		print(string.format("Admin %s cleared all poops", player.Name))
	else
		sendMessage(player, "❌ No poops folder found")
	end
end

-- /spawn poops [amount]
commands.spawn = function(player, args)
	if not args[2] then
		sendMessage(player, "Usage: /spawn [poops/superpoops] [amount]")
		return
	end

	local spawnType = args[2]:lower()
	local amount = tonumber(args[3]) or 10

	local PoopManager = require(script.Parent.PoopManager)

	if spawnType == "poops" or spawnType == "poop" then
		for i = 1, amount do
			PoopManager.SpawnPoop()
		end
		sendMessage(player, string.format("✅ Spawned %d poops", amount))
		print(string.format("Admin %s spawned %d poops", player.Name, amount))

	elseif spawnType == "superpoops" or spawnType == "superpoop" then
		for i = 1, amount do
			PoopManager.SpawnSuperPoop()
		end
		sendMessage(player, string.format("✅ Spawned %d super poops", amount))
		print(string.format("Admin %s spawned %d super poops", player.Name, amount))

	else
		sendMessage(player, "❌ Unknown spawn type. Use: poops or superpoops")
	end
end

-- /help - Show available commands
commands.help = function(player, args)
	local helpText = [[
🔧 ADMIN COMMANDS:
/give [poops/coins/rebirths] [amount]
/set [poops/coins/rebirths] [amount]
/spawn [poops/superpoops] [amount]
/clear - Clear all poops
/help - Show this message

Examples:
/give poops 10000000
/set coins 50000
/spawn poops 100
]]
	sendMessage(player, helpText)
	print(string.format("Admin %s requested help", player.Name))
end

-- ============================================
-- COMMAND PROCESSOR
-- ============================================

local function processCommand(player, message)
	-- Check if message starts with /
	if not message:sub(1, 1) == "/" then
		return false
	end

	-- Check if player is admin
	if not isAdmin(player) then
		return false
	end

	-- Parse command
	local args = message:split(" ")
	local commandName = args[1]:sub(2):lower() -- Remove / and convert to lowercase

	-- Execute command
	if commands[commandName] then
		print(string.format("========================================"))
		print(string.format("Admin Command: %s from %s", message, player.Name))
		print(string.format("========================================"))

		commands[commandName](player, args)
		return true -- Command was processed, don't show in chat
	end

	return false -- Not a valid command, show in chat normally
end

-- ============================================
-- SETUP
-- ============================================

function AdminCommands.Setup()
	print("========================================")
	print("🔧 ADMIN COMMANDS SYSTEM")
	print("========================================")

	-- Setup for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			processCommand(player, message)
		end)

		if isAdmin(player) then
			print(string.format("  ✅ Admin detected: %s", player.Name))
			task.wait(2)
			sendMessage(player, "👑 Admin commands enabled! Type /help for commands")
		end
	end

	-- Setup for new players
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			processCommand(player, message)
		end)

		if isAdmin(player) then
			print(string.format("  ✅ Admin joined: %s", player.Name))
			task.wait(2)
			sendMessage(player, "👑 Admin commands enabled! Type /help for commands")
		end
	end)

	print("========================================")
	print("✅ Admin Commands Ready!")
	print("  - Commands available: /give, /set, /spawn, /clear, /help")
	print("  - Admins configured:", #ADMINS)
	print("========================================")
end

return AdminCommands
