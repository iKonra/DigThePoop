-- CastleWalls.luau
-- Handles castle wall construction

local CastleWalls = {}

local Config = require(script.Parent.Config)

local TERRAIN_HALF_SIZE = Config.Terrain.TerrainSize / 2

-- Enhanced wall creation with textures and lighting
local function createEnhancedWall(wallData, wallFolder)
	local wall = Instance.new("Part")
	wall.Name = wallData.name
	wall.Size = wallData.size
	wall.Position = wallData.pos
	wall.Anchored = true
	wall.Material = Enum.Material.Slate
	wall.Color = Color3.fromRGB(90, 95, 100)
	
	-- Add stone texture
	local texture = Instance.new("Texture")
	texture.Texture = "rbxassetid://7028887168" -- Stone texture
	texture.StudsPerTileU = 8
	texture.StudsPerTileV = 8
	texture.Transparency = 0.1
	texture.Parent = wall
	
	-- Add subtle ambient lighting
	local pointLight = Instance.new("PointLight")
	pointLight.Range = 20
	pointLight.Brightness = 0.5
	pointLight.Color = Color3.fromRGB(255, 200, 100)
	pointLight.Parent = wall
	
	wall.Parent = wallFolder
	return wall
end

-- Create corner tower with decorative elements
local function createTower(position, size, index, wallFolder)
	local tower = Instance.new("Part")
	tower.Name = "Tower" .. index
	tower.Size = size
	tower.Position = position
	tower.Anchored = true
	tower.Material = Enum.Material.Slate
	tower.Color = Color3.fromRGB(80, 85, 90)
	
	-- Tower texture
	local texture = Instance.new("Texture")
	texture.Texture = "rbxassetid://7028887168"
	texture.StudsPerTileU = 4
	texture.StudsPerTileV = 12
	texture.Transparency = 0.1
	texture.Parent = tower
	
	-- Tower top decoration
	local top = Instance.new("Part")
	top.Name = "TowerTop" .. index
	top.Size = Vector3.new(size.X * 1.2, Config.Castle.WallThickness, size.Z * 1.2)
	top.Position = Vector3.new(position.X, position.Y * 1.9, position.Z)
	top.Anchored = true
	top.Material = Enum.Material.Slate
	top.Color = Color3.fromRGB(70, 75, 80)
	
	-- Dramatic tower lighting
	local spotLight = Instance.new("SpotLight")
	spotLight.Range = 30
	spotLight.Brightness = 2
	spotLight.Color = Color3.fromRGB(255, 170, 80)
	spotLight.Angle = 45
	spotLight.Parent = top
	
	tower.Parent = wallFolder
	top.Parent = wallFolder
	return tower
end

-- Function to create castle wall around the perimeter
function CastleWalls.Build()
	print("Building castle walls...")

	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "CastleWalls"
	wallFolder.Parent = workspace

	-- Enhanced wall parameters
	local wallDistance = TERRAIN_HALF_SIZE * 4 - Config.Castle.WallThickness/2
	local wallLength = Config.Terrain.TerrainSize * 10
	local towerHeight = Config.Castle.WallHeight * 1.5
	local towerWidth = Config.Castle.WallThickness * 3

	-- Create four walls with towers at corners (North, South, East, West)
	local walls = {
		{name = "NorthWall", size = Vector3.new(wallLength, Config.Castle.WallHeight * 1.2, Config.Castle.WallThickness * 1.5),
		 pos = Vector3.new(0, Config.Castle.WallHeight/2 * 1.2, wallDistance)},
		{name = "SouthWall", size = Vector3.new(wallLength, Config.Castle.WallHeight * 1.2, Config.Castle.WallThickness * 1.5),
		 pos = Vector3.new(0, Config.Castle.WallHeight/2 * 1.2, -wallDistance)},
		{name = "EastWall", size = Vector3.new(Config.Castle.WallThickness * 1.5, Config.Castle.WallHeight * 1.2, wallLength),
		 pos = Vector3.new(wallDistance, Config.Castle.WallHeight/2 * 1.2, 0)},
		{name = "WestWall", size = Vector3.new(Config.Castle.WallThickness * 1.5, Config.Castle.WallHeight * 1.2, wallLength),
		 pos = Vector3.new(-wallDistance, Config.Castle.WallHeight/2 * 1.2, 0)},
	}
	
	-- Tower positions at corners
	local towers = {
		{pos = Vector3.new(-wallDistance, towerHeight/2, -wallDistance)},
		{pos = Vector3.new(-wallDistance, towerHeight/2, wallDistance)},
		{pos = Vector3.new(wallDistance, towerHeight/2, -wallDistance)},
		{pos = Vector3.new(wallDistance, towerHeight/2, wallDistance)},
	}

	-- Build main walls
	for _, wallData in ipairs(walls) do
		local wall = Instance.new("Part")
		wall.Name = wallData.name
		wall.Size = wallData.size
		wall.Position = wallData.pos
		wall.Anchored = true
		wall.Material = Enum.Material.Cobblestone
		wall.Color = Color3.fromRGB(120, 120, 120)
		wall.Parent = wallFolder
	end

	-- Add battlements (crenellations) on top of walls
	local function addBattlements(wallPos, wallSize, isVertical)
		local battlementY = Config.Castle.WallHeight + Config.Castle.BattlementHeight/2
		local length = isVertical and wallSize.Z or wallSize.X
		local numBattlements = math.floor(length / (Config.Castle.BattlementWidth + Config.Castle.BattlementGap))

		for i = 0, numBattlements do
			local offset = -length/2 + i * (Config.Castle.BattlementWidth + Config.Castle.BattlementGap) + Config.Castle.BattlementWidth/2
			local battlement = Instance.new("Part")
			battlement.Name = "Battlement"
			battlement.Size = Vector3.new(
				isVertical and Config.Castle.WallThickness or Config.Castle.BattlementWidth,
				Config.Castle.BattlementHeight,
				isVertical and Config.Castle.BattlementWidth or Config.Castle.WallThickness
			)

			if isVertical then
				battlement.Position = Vector3.new(wallPos.X, battlementY, wallPos.Z + offset)
			else
				battlement.Position = Vector3.new(wallPos.X + offset, battlementY, wallPos.Z)
			end

			battlement.Anchored = true
			battlement.Material = Enum.Material.Cobblestone
			battlement.Color = Color3.fromRGB(100, 100, 100)
			battlement.Parent = wallFolder
		end
	end

	-- Add battlements to all walls
	addBattlements(walls[1].pos, walls[1].size, false) -- North
	addBattlements(walls[2].pos, walls[2].size, false) -- South
	addBattlements(walls[3].pos, walls[3].size, true)  -- East
	addBattlements(walls[4].pos, walls[4].size, true)  -- West

	-- Create corner towers
	local corners = {
		Vector3.new(wallDistance, Config.Castle.TowerHeight/2, wallDistance),
		Vector3.new(wallDistance, Config.Castle.TowerHeight/2, -wallDistance),
		Vector3.new(-wallDistance, Config.Castle.TowerHeight/2, wallDistance),
		Vector3.new(-wallDistance, Config.Castle.TowerHeight/2, -wallDistance),
	}

	for i, cornerPos in ipairs(corners) do
		-- Main tower
		local tower = Instance.new("Part")
		tower.Name = "CornerTower" .. i
		tower.Size = Vector3.new(Config.Castle.TowerSize, Config.Castle.TowerHeight, Config.Castle.TowerSize)
		tower.Position = cornerPos
		tower.Anchored = true
		tower.Material = Enum.Material.Brick
		tower.Color = Color3.fromRGB(110, 110, 110)
		tower.Parent = wallFolder

		-- Tower roof (pyramid)
		local roof = Instance.new("Part")
		roof.Name = "TowerRoof"
		roof.Size = Vector3.new(Config.Castle.TowerSize + 2, 6, Config.Castle.TowerSize + 2)
		roof.Position = cornerPos + Vector3.new(0, Config.Castle.TowerHeight/2 + 3, 0)
		roof.Anchored = true
		roof.Material = Enum.Material.Slate
		roof.Color = Color3.fromRGB(80, 50, 50)
		roof.Shape = Enum.PartType.Ball
		roof.Parent = wallFolder

		-- Tower battlements
		for bx = -1, 1, 2 do
			for bz = -1, 1, 2 do
				local towerBattlement = Instance.new("Part")
				towerBattlement.Name = "TowerBattlement"
				towerBattlement.Size = Vector3.new(3, 4, 3)
				towerBattlement.Position = cornerPos + Vector3.new(bx * Config.Castle.TowerSize/2.5, Config.Castle.TowerHeight/2 + 2, bz * Config.Castle.TowerSize/2.5)
				towerBattlement.Anchored = true
				towerBattlement.Material = Enum.Material.Cobblestone
				towerBattlement.Color = Color3.fromRGB(100, 100, 100)
				towerBattlement.Parent = wallFolder
			end
		end
	end

	print("Castle walls completed!")
end

-- Function to build castle walls at a specific location (for zones)
function CastleWalls.BuildAtLocation(centerPosition, size, parentFolder)
	print("Building castle walls at custom location...")

	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "CastleWalls"
	wallFolder.Parent = parentFolder or workspace

	-- Wall parameters (scaled based on size)
	local halfSize = size / 2
	local wallDistance = halfSize - Config.Castle.WallThickness / 2
	local wallLength = size * 2.5

	-- Create four walls (North, South, East, West)
	local walls = {
		{name = "NorthWall", size = Vector3.new(wallLength, Config.Castle.WallHeight, Config.Castle.WallThickness),
		 pos = centerPosition + Vector3.new(0, Config.Castle.WallHeight/2, wallDistance)},
		{name = "SouthWall", size = Vector3.new(wallLength, Config.Castle.WallHeight, Config.Castle.WallThickness),
		 pos = centerPosition + Vector3.new(0, Config.Castle.WallHeight/2, -wallDistance)},
		{name = "EastWall", size = Vector3.new(Config.Castle.WallThickness, Config.Castle.WallHeight, wallLength),
		 pos = centerPosition + Vector3.new(wallDistance, Config.Castle.WallHeight/2, 0)},
		{name = "WestWall", size = Vector3.new(Config.Castle.WallThickness, Config.Castle.WallHeight, wallLength),
		 pos = centerPosition + Vector3.new(-wallDistance, Config.Castle.WallHeight/2, 0)},
	}

	-- Build main walls
	for _, wallData in ipairs(walls) do
		local wall = Instance.new("Part")
		wall.Name = wallData.name
		wall.Size = wallData.size
		wall.Position = wallData.pos
		wall.Anchored = true
		wall.Material = Enum.Material.Cobblestone
		wall.Color = Color3.fromRGB(120, 120, 120)
		wall.Parent = wallFolder
	end

	-- Add battlements (crenellations) on top of walls
	local function addBattlements(wallPos, wallSize, isVertical)
		local battlementY = Config.Castle.WallHeight + Config.Castle.BattlementHeight/2
		local length = isVertical and wallSize.Z or wallSize.X
		local numBattlements = math.floor(length / (Config.Castle.BattlementWidth + Config.Castle.BattlementGap))

		for i = 0, numBattlements do
			local offset = -length/2 + i * (Config.Castle.BattlementWidth + Config.Castle.BattlementGap) + Config.Castle.BattlementWidth/2
			local battlement = Instance.new("Part")
			battlement.Name = "Battlement"
			battlement.Size = Vector3.new(
				isVertical and Config.Castle.WallThickness or Config.Castle.BattlementWidth,
				Config.Castle.BattlementHeight,
				isVertical and Config.Castle.BattlementWidth or Config.Castle.WallThickness
			)

			if isVertical then
				battlement.Position = Vector3.new(wallPos.X, battlementY, wallPos.Z + offset)
			else
				battlement.Position = Vector3.new(wallPos.X + offset, battlementY, wallPos.Z)
			end

			battlement.Anchored = true
			battlement.Material = Enum.Material.Cobblestone
			battlement.Color = Color3.fromRGB(100, 100, 100)
			battlement.Parent = wallFolder
		end
	end

	-- Add battlements to all walls
	addBattlements(walls[1].pos, walls[1].size, false) -- North
	addBattlements(walls[2].pos, walls[2].size, false) -- South
	addBattlements(walls[3].pos, walls[3].size, true)  -- East
	addBattlements(walls[4].pos, walls[4].size, true)  -- West

	-- Create corner towers
	local corners = {
		centerPosition + Vector3.new(wallDistance, Config.Castle.TowerHeight/2, wallDistance),
		centerPosition + Vector3.new(wallDistance, Config.Castle.TowerHeight/2, -wallDistance),
		centerPosition + Vector3.new(-wallDistance, Config.Castle.TowerHeight/2, wallDistance),
		centerPosition + Vector3.new(-wallDistance, Config.Castle.TowerHeight/2, -wallDistance),
	}

	for i, cornerPos in ipairs(corners) do
		-- Main tower
		local tower = Instance.new("Part")
		tower.Name = "CornerTower" .. i
		tower.Size = Vector3.new(Config.Castle.TowerSize, Config.Castle.TowerHeight, Config.Castle.TowerSize)
		tower.Position = cornerPos
		tower.Anchored = true
		tower.Material = Enum.Material.Brick
		tower.Color = Color3.fromRGB(110, 110, 110)
		tower.Parent = wallFolder

		-- Tower roof (pyramid)
		local roof = Instance.new("Part")
		roof.Name = "TowerRoof"
		roof.Size = Vector3.new(Config.Castle.TowerSize + 2, 6, Config.Castle.TowerSize + 2)
		roof.Position = cornerPos + Vector3.new(0, Config.Castle.TowerHeight/2 + 3, 0)
		roof.Anchored = true
		roof.Material = Enum.Material.Slate
		roof.Color = Color3.fromRGB(80, 50, 50)
		roof.Shape = Enum.PartType.Ball
		roof.Parent = wallFolder

		-- Tower battlements
		for bx = -1, 1, 2 do
			for bz = -1, 1, 2 do
				local towerBattlement = Instance.new("Part")
				towerBattlement.Name = "TowerBattlement"
				towerBattlement.Size = Vector3.new(3, 4, 3)
				towerBattlement.Position = cornerPos + Vector3.new(bx * Config.Castle.TowerSize/2.5, Config.Castle.TowerHeight/2 + 2, bz * Config.Castle.TowerSize/2.5)
				towerBattlement.Anchored = true
				towerBattlement.Material = Enum.Material.Cobblestone
				towerBattlement.Color = Color3.fromRGB(100, 100, 100)
				towerBattlement.Parent = wallFolder
			end
		end
	end

	print("Castle walls at custom location completed!")
	return wallFolder
end

return CastleWalls


