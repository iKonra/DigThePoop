-- init.server.luau
-- Main server initialization script
-- This script orchestrates all game systems by using modular managers

print("Hello world, from server!")
print("🚀 Initializing Agarrini game systems...")

-- Ensure common RemoteEvents exist early so modules/clients can bind safely
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function ensureRemote(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
		print("✓ Created RemoteEvent:", name)
	end
	return ev
end

ensureRemote("ShowWarningEvent")
ensureRemote("ShowLuckyEvent")

-- Setup shared modules first
-- (removed SetupModules automation — modules should be placed in ReplicatedStorage in Studio)

local TerrainManager = require(script.TerrainManager)
local SpawnDecorator = require(script.SpawnDecorator)
local CastleWalls = require(script.CastleWalls)
local PoopManager = require(script.PoopManager)
PoopManager.Initialize() -- Initialize PoopManager first
local RebirthManager = require(script.RebirthManager)
local ShovelManager = require(script.ShovelManager)
local PlayerManager = require(script.PlayerManager)
local ShovelUpgradeManager = require(script.ShovelUpgradeManager)
local RailManager = require(script.RailManager)
local AdminCommands = require(script.AdminCommands)
local TutorialManager = require(script.TutorialManager)
local CoinSpawner = require(script.CoinSpawner)
local MonetizationManager = require(script.MonetizationManager)
local ZoneManager = require(script.ZoneManager)
local DataManager = require(script.DataManager)

-- ============================================
-- WORLD GENERATION
-- ============================================
print("========================================")
print("PHASE 1: WORLD GENERATION")
print("========================================")

print("Starting terrain generation...")
TerrainManager.GenerateTerrain()

print("Decorating spawn area...")
SpawnDecorator.Decorate()

print("Adding trees around the map...")
SpawnDecorator.AddTrees()

print("Starting castle wall creation...")
CastleWalls.Build()

print("Setting up zones...")
ZoneManager.Setup()

-- ============================================
-- GAME SYSTEMS INITIALIZATION
-- ============================================
print("========================================")
print("PHASE 2: GAME SYSTEMS")
print("========================================")

print("Starting poop spawning system...")
PoopManager.StartSpawner()

print("Setting up poop clearing handlers...")
PoopManager.SetupClearingHandler()

print("Setting up rebirth system...")
RebirthManager.SetupRebirthHandler()

print("Setting up shovel upgrade system...")
ShovelUpgradeManager.SetupRemoteEvents()

print("Setting up rail system...")
RailManager.SetupRemoteEvents()

print("Starting coin spawner...")
CoinSpawner.Start()

-- Removed pickable shovel - players get shovel via Starter Pack or upgrade system
-- print("Creating pickable shovel...")
-- ShovelManager.CreatePickableShovel()

-- ============================================
-- PLAYER MANAGEMENT
-- ============================================
print("========================================")
print("PHASE 3: PLAYER MANAGEMENT")
print("========================================")

print("Starting player setup...")
PlayerManager.SetupPlayers()

print("Setting up shovel upgrades for players...")
ShovelUpgradeManager.SetupPlayers()

print("Setting up rails for players...")
RailManager.SetupPlayers()

print("Setting up zones for players...")
ZoneManager.SetupPlayers()

print("Setting up admin commands...")
AdminCommands.Setup()

print("Setting up monetization (Robux products)...")
MonetizationManager.Setup()

print("Setting up data persistence (DataStore)...")
DataManager.Setup()

print("Setting up tutorial system...")
TutorialManager.Initialize()

-- ============================================
-- INITIALIZATION COMPLETE
-- ============================================
print("========================================")
print("✅ ALL SYSTEMS INITIALIZED!")
print("========================================")
print("Game is ready to play!")
print("Systems active:")
print("  ✓ Terrain Generation")
print("  ✓ Spawn Decoration")
print("  ✓ Trees")
print("  ✓ Castle Walls")
print("  ✓ Zone System")
print("  ✓ Poop Spawning & Management")
print("  ✓ Rebirth System")
print("  ✓ Shovel System")
print("  ✓ Shovel Upgrade System")
print("  ✓ Rail System")
print("  ✓ Player Management")
print("  ✓ Admin Commands")
print("  ✓ Monetization (Robux Products)")
print("  ✓ Data Persistence (DataStore)")
print("========================================")

-- ============================================
-- POOP CHANGER BOOTH & SHOP
-- ============================================
print("========================================")
print("PHASE 4: POOP CHANGER BOOTH & SHOP")
print("========================================")

local PoopChangerBooth = require(script.PoopChangerBooth)
local ShopManager = require(script.ShopManager)

print("Initializing Poop Changer Booth...")
PoopChangerBooth.create()

print("Initializing Shop...")
ShopManager.create()
