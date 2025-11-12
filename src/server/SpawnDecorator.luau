-- SpawnDecorator.luau
-- Handles spawn area decoration (bonfire, logs, spawn location, etc.)

local SpawnDecorator = {}

local Config = require(script.Parent.Config)
local terrain = workspace.Terrain

local SPAWN_HALF_SIZE = Config.Terrain.SpawnSize / 2

-- Helper function to decorate any spawn area with bonfire and logs
local function decorateSpawnArea(spawnCenter, parentFolder, options)
	options = options or {}
	local spawnSizeMultiplier = options.sizeMultiplier or 1
	local heightOffset = options.heightOffset or 0
	local includeShop = options.includeShop or false
	local includeExchanger = options.includeExchanger or false
	local createSpawnLocation = options.createSpawnLocation ~= false -- Default true unless explicitly false

	local SPAWN_HALF_SIZE_LOCAL = (Config.Terrain.SpawnSize / 2) * spawnSizeMultiplier
	print("Decorating spawn area...")

	local spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "SpawnDecoration"
	spawnFolder.Parent = parentFolder or workspace

	-- Create rock floor in spawn area (larger area)
	for x = -SPAWN_HALF_SIZE_LOCAL, SPAWN_HALF_SIZE_LOCAL do
		for z = -SPAWN_HALF_SIZE_LOCAL, SPAWN_HALF_SIZE_LOCAL do
			local worldPos = spawnCenter + Vector3.new(x * 4, heightOffset, z * 4)

			-- Fill with rock from base to ground level
			for y = Config.Terrain.BaseHeight, Config.Terrain.GroundLevel, 4 do
				local position = Vector3.new(worldPos.X, y, worldPos.Z)
				local size = Vector3.new(4, 4, 4)

				if y >= Config.Terrain.GroundLevel - 4 then
					terrain:FillBlock(CFrame.new(position), size, Enum.Material.Rock)
				else
					terrain:FillBlock(CFrame.new(position), size, Enum.Material.Ground)
				end
			end
		end
	end

	-- Create SpawnLocation for proper player spawning (only for default spawn)
	if createSpawnLocation then
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "SpawnLocation"
		spawnLocation.Size = Vector3.new(15, 1, 15)
		spawnLocation.Position = spawnCenter + Vector3.new(0, 0.5 + heightOffset, 0)
		spawnLocation.Anchored = true
		spawnLocation.Transparency = 1
		spawnLocation.CanCollide = false
		spawnLocation.BrickColor = BrickColor.new("Bright green")
		spawnLocation.Material = Enum.Material.SmoothPlastic
		spawnLocation.TopSurface = Enum.SurfaceType.Smooth
		spawnLocation.BottomSurface = Enum.SurfaceType.Smooth
		spawnLocation.Parent = spawnFolder
		print("✓ Created SpawnLocation at", spawnLocation.Position)
	end

	-- Position bonfire next to shovel (relative to spawn center)
	local bonfirePosition = spawnCenter + Vector3.new(-6, 4.7 + heightOffset, -6) -- Bajado 0.3 desde 5
	
	-- Create bonfire base
	local fireBase = Instance.new("Part")
	fireBase.Name = "FireBase"
	fireBase.Size = Vector3.new(2, 0.5, 2)
	fireBase.Position = bonfirePosition + Vector3.new(0, 0.25, 0)
	fireBase.Anchored = true
	fireBase.Material = Enum.Material.Slate
	fireBase.Color = Color3.fromRGB(60, 60, 60)
	fireBase.Parent = spawnFolder

	-- Function to create fire logs
	local function createFireLog(position, rotation)
		local log = Instance.new("Part")
		log.Name = "FireLog"
		log.Size = Vector3.new(0.5, 2, 0.5)
		log.Position = position
		log.Anchored = true
		log.Material = Enum.Material.Wood
		log.Color = Color3.fromRGB(90, 60, 40)
		log.CFrame = CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
		log.Parent = spawnFolder
		return log
	end

	-- Stack logs in the fire
	createFireLog(bonfirePosition + Vector3.new(0, 1, 0), Vector3.new(math.rad(90), 0, 0))
	createFireLog(bonfirePosition + Vector3.new(0, 1, 0), Vector3.new(0, 0, math.rad(90)))
	createFireLog(bonfirePosition + Vector3.new(0, 1.5, 0), Vector3.new(math.rad(90), math.rad(45), 0))

	-- Create actual fire effect
	local firePart = Instance.new("Part")
	firePart.Name = "FireEffect"
	firePart.Size = Vector3.new(4.5, 3, 4.5)
	firePart.Position = bonfirePosition + Vector3.new(0, 1.5, 0)
	firePart.Anchored = true
	firePart.Transparency = 1
	firePart.CanCollide = false
	firePart.Parent = spawnFolder

	-- Add fire effect
	local fire = Instance.new("Fire")
	fire.Size = 10
	fire.Heat = 14
	fire.Color = Color3.fromRGB(255, 120, 0)
	fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
	fire.Parent = firePart

	-- Add light from fire
	local fireLight = Instance.new("PointLight")
	fireLight.Brightness = 3
	fireLight.Range = 25
	fireLight.Color = Color3.fromRGB(255, 150, 50)
	fireLight.Parent = firePart

	-- Create seating logs around the spawn area
	local logDistance = 12
	local logPositions = {
		{pos = Vector3.new(logDistance, 0, 0), rot = 90},
		{pos = Vector3.new(-logDistance, 0, 0), rot = -90},
		{pos = Vector3.new(0, 0, logDistance), rot = 0},
		{pos = Vector3.new(0, 0, -logDistance), rot = 180},
	}

	-- Look for a log model in workspace
	local logTemplate = workspace:FindFirstChild("Tronco Para Sentarte")
		or workspace:FindFirstChild("Tronco")
		or workspace:FindFirstChild("Log")
		or workspace:FindFirstChild("WoodenLog")

	if logTemplate then
		print("✓ Found log template in workspace:", logTemplate.Name)

		for i, data in ipairs(logPositions) do
			local logClone = logTemplate:Clone()

			if logClone then
				local targetPos = bonfirePosition + data.pos

				-- Set all parts to anchored
				for _, part in ipairs(logClone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
					end
				end

				-- Move and rotate the model
				if logClone:IsA("Model") then
					if logClone.PrimaryPart then
						logClone:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, math.rad(data.rot), 0))
					else
						local firstPart = logClone:FindFirstChildWhichIsA("BasePart")
						if firstPart then
							logClone.PrimaryPart = firstPart
							logClone:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, math.rad(data.rot), 0))
						end
					end
				else
					logClone.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(data.rot), 0)
				end

				logClone.Name = "SeatLog" .. i
				logClone.Parent = spawnFolder
				print("✓ Placed log " .. i .. " at position", targetPos)
			end
		end
	else
		warn("❌ No log template found in workspace!")
		warn("Creating fallback logs...")

		-- Fallback: Create simple log benches
		for i, data in ipairs(logPositions) do
			local seatLog = Instance.new("Part")
			seatLog.Name = "SeatLog"
			seatLog.Size = Vector3.new(7, 1.2, 2)
			seatLog.Position = bonfirePosition + data.pos + Vector3.new(0, 0.6, 0)
			seatLog.Anchored = true
			seatLog.Material = Enum.Material.Wood
			seatLog.Color = Color3.fromRGB(120, 80, 50)
			seatLog.CFrame = CFrame.new(bonfirePosition + data.pos + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, math.rad(data.rot), 0)
			seatLog.Parent = spawnFolder

			-- Add seat
			local seat = Instance.new("Seat")
			seat.Size = Vector3.new(4.5, 0.2, 1)
			seat.Anchored = true
			seat.Material = Enum.Material.Wood
			seat.Color = Color3.fromRGB(120, 80, 50)
			seat.Transparency = 0.5
			seat.CFrame = seatLog.CFrame * CFrame.new(0, 0.7, 0)
			seat.Parent = spawnFolder
		end
	end

	-- Create Shop if requested
	if includeShop then
		-- Shop: X=53 (4000+53=4053, acercado 7 studs desde 60), Y=71, Z=-5
		-- heightOffset es -8, necesito Y=71: 74 - 8 + X = 71 → X = 5
		local shopPosition = spawnCenter + Vector3.new(47, heightOffset + 5, -5)
		local ShopManager = require(script.Parent.ShopManager)
		ShopManager.createShopInZone(shopPosition, 0, spawnFolder)
		print("✓ Created Shop in spawn area at", shopPosition)
	end

	-- Create Poop Changer if requested
	if includeExchanger then
		-- Exchanger: Bajado 1.5 studs más desde Y=68.5 a Y=67
		-- heightOffset es -8, necesito Y=67: 74 - 8 + Y = 67 → Y = 1
		-- X: 25, Z: 8 (sin cambios)
		local exchangerPosition = spawnCenter + Vector3.new(25, heightOffset, 8)
		local PoopChangerBooth = require(script.Parent.PoopChangerBooth)
		PoopChangerBooth.createInZone(exchangerPosition, 0, spawnFolder)
		print("✓ Created Poop Changer in spawn area at", exchangerPosition)
	end

	print("Spawn area decorated with bonfire and logs!")
end

-- Function to decorate the main spawn area
function SpawnDecorator.Decorate()
	decorateSpawnArea(Config.Terrain.SpawnCenter, workspace, {})

	-- Create scoreboards in spawn zone
	print("Creating scoreboards in spawn zone...")
	local ScoreboardManager = require(script.Parent.ScoreboardManager)
	ScoreboardManager.CreateInZone(Config.Terrain.SpawnCenter, 150, workspace)
	print("✓ Scoreboards created in spawn zone!")
end

-- Function to decorate the desert spawn area
function SpawnDecorator.DecorateDesertSpawn()
	print("Decorating desert spawn area...")
	local desertSpawnCenter = Vector3.new(4000, 74, 0) -- Bajado de 90 a 74 (16 studs)
	local desertFolder = workspace:FindFirstChild("Desert")

	if not desertFolder then
		warn("⚠️ Desert folder not found! Creating one...")
		desertFolder = Instance.new("Folder")
		desertFolder.Name = "Desert"
		desertFolder.Parent = workspace
	end

	-- Decorate with larger area, lowered by 8 studs, with shop and exchanger
	-- NO crear SpawnLocation aquí (los jugadores deben spawnear en la zona default)
	decorateSpawnArea(desertSpawnCenter, desertFolder, {
		sizeMultiplier = 2,        -- Doble de área de spawn
		heightOffset = -8,          -- Bajar 8 studs (bonfire, logs subidos 2 desde -10)
		includeShop = true,         -- Agregar shop (sin cambios)
		includeExchanger = true,    -- Agregar exchanger (subido 6, movido 5 derecha, 2 atrás)
		createSpawnLocation = false -- NO crear SpawnLocation en el desierto
	})

	-- Try to populate the Desert with many cactus models (user-provided templates named "Cactus").
	-- If templates are oversized we scale them down so they visually match the map.
	local cactusTemplates = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Cactus" and obj:IsA("Model") then
			table.insert(cactusTemplates, obj)
		end
	end

	local function computeMaxPartSize(model)
		local maxSize = 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				local s = d.Size
				maxSize = math.max(maxSize, s.X, s.Y, s.Z)
			end
		end
		return maxSize
	end

	local function scaleModelAroundPrimary(mod, scale)
		local primary = mod.PrimaryPart or mod:FindFirstChildWhichIsA("BasePart")
		if not primary then return end
		local pPos = primary.Position
		for _, d in ipairs(mod:GetDescendants()) do
			if d:IsA("BasePart") then
				local offset = d.Position - pPos
				d.Size = d.Size * scale
				d.Position = pPos + offset * scale
			end
		end
	end

	if #cactusTemplates > 0 then
		local cactiFolder = desertFolder:FindFirstChild("Cacti")
		if not cactiFolder then
			cactiFolder = Instance.new("Folder")
			cactiFolder.Name = "Cacti"
			cactiFolder.Parent = desertFolder
		end

		-- Generate ~50 cactus positions randomly around the desert spawn center,
		-- but avoid placing any within a 20-stud radius square (20x20) around the spawn.
		local total = 50
		local minRadius = 20
		local maxRadius = 160
		math.randomseed(tick())

		local placed = 0
		local attempts = 0
		while placed < total and attempts < total * 8 do
			attempts = attempts + 1
			-- Random angle and radius (donut between minRadius and maxRadius)
			local angle = math.random() * math.pi * 2
			local radius = minRadius + math.random() * (maxRadius - minRadius)
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius

			-- Ensure not inside 20x20 square centered at spawn: both |x| and |z| must not be < 10
			if math.abs(x) < 10 and math.abs(z) < 10 then
				-- skip this position (too close to spawn)
			else
				local tpl = cactusTemplates[((placed) % #cactusTemplates) + 1]
				local ok, clone = pcall(function() return tpl:Clone() end)
				if ok and clone then
					-- Anchor all parts
					for _, d in ipairs(clone:GetDescendants()) do
						if d:IsA("BasePart") then d.Anchored = true end
					end

					-- Scale down oversized templates
					local maxDim = computeMaxPartSize(clone)
					if maxDim > 8 then
						local scaleFactor = 6 / math.max(maxDim, 1)
						scaleFactor = math.clamp(scaleFactor, 0.15, 1)
						pcall(function() scaleModelAroundPrimary(clone, scaleFactor) end)
					end

					-- Position the cactus, lowered by 2 studs to avoid floating
					local targetPos = desertSpawnCenter + Vector3.new(x, -2, z)
					if clone.PrimaryPart then
						clone:SetPrimaryPartCFrame(CFrame.new(targetPos))
					else
						clone:MoveTo(targetPos)
					end

					placed = placed + 1
					clone.Name = "Cactus_" .. placed
					clone.Parent = cactiFolder
				else
					warn("Failed to clone cactus template:", tpl and tpl:GetFullName() or "<unknown>")
				end
			end
		end

		print("✓ Placed", placed, "cacti around Desert spawn (attempts:", attempts, ")")
	else
		warn("No cactus template named 'Cactus' found in workspace; skipping Desert cactus placement")
	end

	print("✓ Desert spawn area decorated!")
end

-- Function to create a tree using the template from workspace
local function createTree(position, height, leafRadius)
	-- Look for tree template in workspace (might be under the map)
	local treeTemplate = workspace:FindFirstChild("tree wood")
		or workspace:FindFirstChild("Tree Wood")
		or workspace:FindFirstChild("TreeWood")
		or workspace:FindFirstChild("arbol realista")
		or workspace:FindFirstChild("Arbol Realista")
		or workspace:FindFirstChild("Tree")
		or workspace:FindFirstChild("TreeModel")
		or workspace:FindFirstChild("Arbol")
		or workspace:FindFirstChild("TreeTemplate")

	if treeTemplate and treeTemplate:IsA("Model") then
		-- Clone the existing tree model
		local tree = treeTemplate:Clone()
		tree.Name = "Tree"

		-- Anchor all parts
		for _, part in ipairs(tree:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		-- Position the tree (raised by 7 studs)
		local adjustedPosition = position + Vector3.new(0, 24, 0)
		if tree.PrimaryPart then
			tree:SetPrimaryPartCFrame(CFrame.new(adjustedPosition))
		else
			local trunk = tree:FindFirstChild("Trunk") or tree:FindFirstChildWhichIsA("BasePart")
			if trunk then
				tree.PrimaryPart = trunk
				tree:SetPrimaryPartCFrame(CFrame.new(adjustedPosition))
			else
				-- Fallback: just move to position
				tree:MoveTo(adjustedPosition)
			end
		end

		return tree
	else
		-- Fallback: create simple tree if template not found
		warn("⚠️ Tree template not found in workspace! Creating fallback tree...")

		local treeFolder = Instance.new("Model")
		treeFolder.Name = "Tree"

		-- Create trunk
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(2, height or 12, 2)
		trunk.Position = position + Vector3.new(0, (height or 12)/2, 0)
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(90, 60, 40)
		trunk.Parent = treeFolder

		-- Create leafy top (sphere-like)
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Size = Vector3.new((leafRadius or 5) * 2, (leafRadius or 5) * 2, (leafRadius or 5) * 2)
		leaves.Position = position + Vector3.new(0, (height or 12) + (leafRadius or 5)/2, 0)
		leaves.Anchored = true
		leaves.Material = Enum.Material.Grass
		leaves.Color = Color3.fromRGB(50, 120, 50)
		leaves.Shape = Enum.PartType.Ball
		leaves.Parent = treeFolder

		return treeFolder
	end
end

-- Function to add trees around the map
function SpawnDecorator.AddTrees()
	print("Adding trees around the map...")

	-- Check for tree template
	local treeTemplate = workspace:FindFirstChild("tree wood")
		or workspace:FindFirstChild("Tree Wood")
		or workspace:FindFirstChild("TreeWood")
		or workspace:FindFirstChild("arbol realista")
		or workspace:FindFirstChild("Arbol Realista")
		or workspace:FindFirstChild("Tree")
		or workspace:FindFirstChild("TreeModel")
		or workspace:FindFirstChild("Arbol")
		or workspace:FindFirstChild("TreeTemplate")

	if treeTemplate then
		print("✓ Found tree template:", treeTemplate.Name)
	else
		warn("⚠️ No tree template found - will use fallback trees")
	end

	local treesFolder = Instance.new("Folder")
	treesFolder.Name = "Trees"
	treesFolder.Parent = workspace

	-- Define tree positions spread across the entire map (avoiding spawn zone which is -37 to 37)
	-- Trees are now more spread out with larger spacing
	local treePositions = {
		-- Dense inner spawn perimeter (40-60 range)
		{pos = Vector3.new(-45, 1, -45), height = 16, radius = 7},
		{pos = Vector3.new(0, 1, -50), height = 15, radius = 6},
		{pos = Vector3.new(45, 1, -45), height = 16, radius = 7},
		{pos = Vector3.new(-50, 1, 0), height = 15, radius = 6},
		{pos = Vector3.new(50, 1, 0), height = 16, radius = 7},
		{pos = Vector3.new(-45, 1, 45), height = 15, radius = 6},
		{pos = Vector3.new(0, 1, 50), height = 16, radius = 7},
		{pos = Vector3.new(45, 1, 45), height = 15, radius = 6},

		-- Near spawn perimeter (60-90 range) - denser placement
		{pos = Vector3.new(-70, 1, -70), height = 14, radius = 6},
		{pos = Vector3.new(-35, 1, -80), height = 13, radius = 5},
		{pos = Vector3.new(0, 1, -80), height = 12, radius = 5},
		{pos = Vector3.new(35, 1, -80), height = 13, radius = 5},
		{pos = Vector3.new(75, 1, -65), height = 15, radius = 6},
		{pos = Vector3.new(-80, 1, -35), height = 14, radius = 6},
		{pos = Vector3.new(-80, 1, 0), height = 13, radius = 5},
		{pos = Vector3.new(-80, 1, 35), height = 14, radius = 6},
		{pos = Vector3.new(80, 1, -35), height = 14, radius = 6},
		{pos = Vector3.new(80, 1, 0), height = 13, radius = 5},
		{pos = Vector3.new(80, 1, 35), height = 14, radius = 6},
		{pos = Vector3.new(-70, 1, 70), height = 15, radius = 6},
		{pos = Vector3.new(-35, 1, 80), height = 14, radius = 6},
		{pos = Vector3.new(0, 1, 85), height = 12, radius = 5},
		{pos = Vector3.new(35, 1, 80), height = 14, radius = 6},
		{pos = Vector3.new(70, 1, 70), height = 15, radius = 6},

		-- Medium distance (120-180 range) - more spacing
		{pos = Vector3.new(130, 1, -140), height = 14, radius = 6},
		{pos = Vector3.new(-145, 1, -130), height = 13, radius = 5},
		{pos = Vector3.new(150, 1, -165), height = 15, radius = 6},
		{pos = Vector3.new(-160, 1, -150), height = 12, radius = 5},
		{pos = Vector3.new(125, 1, 155), height = 14, radius = 6},
		{pos = Vector3.new(-140, 1, 145), height = 13, radius = 5},
		{pos = Vector3.new(165, 1, 135), height = 15, radius = 6},
		{pos = Vector3.new(-155, 1, 120), height = 12, radius = 5},
		{pos = Vector3.new(175, 1, -80), height = 14, radius = 6},
		{pos = Vector3.new(-170, 1, -70), height = 13, radius = 5},
		{pos = Vector3.new(180, 1, 85), height = 15, radius = 6},
		{pos = Vector3.new(-175, 1, 90), height = 12, radius = 5},

		-- Far distance (200-280 range) - well spread
		{pos = Vector3.new(210, 1, -220), height = 16, radius = 7},
		{pos = Vector3.new(-225, 1, -210), height = 14, radius = 6},
		{pos = Vector3.new(240, 1, -240), height = 15, radius = 6},
		{pos = Vector3.new(-235, 1, -225), height = 13, radius = 5},
		{pos = Vector3.new(220, 1, 215), height = 16, radius = 7},
		{pos = Vector3.new(-230, 1, 225), height = 14, radius = 6},
		{pos = Vector3.new(250, 1, 200), height = 15, radius = 6},
		{pos = Vector3.new(-245, 1, 210), height = 13, radius = 5},
		{pos = Vector3.new(260, 1, -100), height = 16, radius = 7},
		{pos = Vector3.new(-265, 1, -90), height = 14, radius = 6},
		{pos = Vector3.new(255, 1, 110), height = 15, radius = 6},
		{pos = Vector3.new(-260, 1, 100), height = 13, radius = 5},
		{pos = Vector3.new(275, 1, 0), height = 16, radius = 7},
		{pos = Vector3.new(-270, 1, 10), height = 14, radius = 6},

		-- Corner positions (well separated)
		{pos = Vector3.new(200, 1, -80), height = 14, radius = 6},
		{pos = Vector3.new(-205, 1, -75), height = 13, radius = 5},
		{pos = Vector3.new(195, 1, 95), height = 15, radius = 6},
		{pos = Vector3.new(-200, 1, 85), height = 13, radius = 5},
		{pos = Vector3.new(115, 1, -200), height = 14, radius = 6},
		{pos = Vector3.new(-120, 1, -195), height = 13, radius = 5},
		{pos = Vector3.new(110, 1, 205), height = 15, radius = 6},
		{pos = Vector3.new(-115, 1, 210), height = 14, radius = 6},
	}

	-- Create all trees
	for i, data in ipairs(treePositions) do
		local tree = createTree(data.pos, data.height, data.radius)
		tree.Name = "Tree" .. i
		tree.Parent = treesFolder
	end

	print("✓ Added", #treePositions, "trees around the map!")
end

return SpawnDecorator
