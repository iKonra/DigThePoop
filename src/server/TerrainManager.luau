-- TerrainManager.luau
-- Handles all terrain generation logic

local TerrainManager = {
	waterConfigured = false
}

local Config = require(script.Parent.Config)
local terrain = workspace.Terrain

-- Calculated values
local SPAWN_HALF_SIZE = Config.Terrain.SpawnSize / 2
local TERRAIN_HALF_SIZE = Config.Terrain.TerrainSize / 2

-- Function to check if position is in spawn area
local function isInSpawnArea(x, z)
	return math.abs(x) <= SPAWN_HALF_SIZE and math.abs(z) <= SPAWN_HALF_SIZE
end

-- Function to check if a point is within any lake area
local function isInLakeArea(x, z)
	for _, lakeConfig in ipairs(Config.Terrain.Lakes) do
		local dx = x - lakeConfig.Center.X
		local dz = z - lakeConfig.Center.Z
		
		-- Oval/ellipse equation
		local normalizedX = dx / (lakeConfig.Size.X / 2)
		local normalizedZ = dz / (lakeConfig.Size.Y / 2)
		if (normalizedX * normalizedX + normalizedZ * normalizedZ) <= 1 then
			return true, lakeConfig
		end
	end
	return false, nil
end

-- Function to get lake depth at a point
local function getLakeDepth(x, z, lakeConfig)
	local dx = x - lakeConfig.Center.X
	local dz = z - lakeConfig.Center.Z
	
	-- Normalized distance from center (0 to 1)
	local normalizedX = dx / (lakeConfig.Size.X / 2)
	local normalizedZ = dz / (lakeConfig.Size.Y / 2)
	local distanceFromCenter = math.sqrt(normalizedX * normalizedX + normalizedZ * normalizedZ)
	
	-- Fórmula de profundidad base con forma de cuenco suave
	local depthFactor = 1 - math.pow(distanceFromCenter, lakeConfig.EdgeSlope)
	local baseDepth = math.max(0, depthFactor) * lakeConfig.Depth
	
	-- Suavizar los bordes para una transición natural
	if distanceFromCenter > 0.7 then
		local edgeFactor = (1 - distanceFromCenter) / 0.3
		baseDepth = baseDepth * edgeFactor
	end
	
	-- Pequeñas variaciones en el fondo para textura natural
	local variation = 
		math.sin(x/5) * math.cos(z/5) * 0.5 +     -- Ondulaciones suaves
		math.sin((x + z)/8) * 0.3                 -- Diagonales sutiles
	
	-- Asegurar una profundidad mínima cerca del centro
	local centerFactor = math.max(0, 1 - distanceFromCenter * 3)
	local minDepth = lakeConfig.Depth * 0.3 * centerFactor
	
	return math.max(baseDepth + variation, minDepth)
end

-- Function to generate natural height variation
local function getTerrainHeight(x, z)
	local wave1 = math.sin(x / 8) * 3
	local wave2 = math.cos(z / 8) * 3
	local wave3 = math.sin((x + z) / 12) * 2
	local wave4 = math.cos((x - z) / 6) * 2

	-- Base variation
	local variation = wave1 + wave2 + wave3 + wave4
	
	-- If in lake area, apply depression
	local isInLake, activeLakeConfig = isInLakeArea(x, z)
	if isInLake and activeLakeConfig then
		local lakeDepth = getLakeDepth(x, z, activeLakeConfig)
		return activeLakeConfig.WaterLevel - lakeDepth
	end
	
	return math.max(variation, -Config.Terrain.MaxHeightVariation + 2)
end

-- Function to generate uniform grassy terrain
function TerrainManager.GenerateTerrain()
	print("Generating grassy terrain with reliefs...")

	terrain:Clear()

	-- Create the grassy terrain
	for x = -TERRAIN_HALF_SIZE, TERRAIN_HALF_SIZE do
		for z = -TERRAIN_HALF_SIZE, TERRAIN_HALF_SIZE do
			if not isInSpawnArea(x, z) then
				-- Calculate terrain height with natural variations
				local heightVariation = getTerrainHeight(x, z)
				-- Ensure terrain top is always at or above ground level
				local terrainTop = math.max(Config.Terrain.GroundLevel + heightVariation, Config.Terrain.GroundLevel)

				local worldPos = Vector3.new(x * 4, 0, z * 4)

				-- Fill terrain
				for y = Config.Terrain.BaseHeight, terrainTop, 4 do
					local position = Vector3.new(worldPos.X, y, worldPos.Z)
					local size = Vector3.new(4, 4, 4)

					local isInLake, activeLakeConfig = isInLakeArea(x, z)
					if isInLake and activeLakeConfig then
						local depth = getLakeDepth(x, z, activeLakeConfig)
						local bottomHeight = activeLakeConfig.WaterLevel - depth
						local bottomThickness = activeLakeConfig.BaseThickness or 8
						
						if y <= bottomHeight and y >= bottomHeight - bottomThickness then
							-- Base sólida del lago
							terrain:FillBlock(CFrame.new(position), size, Enum.Material.Slate)
						elseif y > bottomHeight and y <= activeLakeConfig.WaterLevel then
							-- Agua del lago
							terrain:FillBlock(CFrame.new(position), size, Enum.Material.Water)
							
							-- Configurar agua una sola vez
							if not TerrainManager.waterConfigured then
								terrain.WaterTransparency = 0.2
								terrain.WaterReflectance = 1
								terrain.WaterWaveSize = 0.15
								terrain.WaterWaveSpeed = 10
								TerrainManager.waterConfigured = true
							end
						elseif y < bottomHeight - bottomThickness then
							-- Relleno bajo el lago para evitar huecos
							terrain:FillBlock(CFrame.new(position), size, Enum.Material.Ground)
						end
					else
						if y >= terrainTop - 4 then
							terrain:FillBlock(CFrame.new(position), size, Enum.Material.Grass)
						else
							terrain:FillBlock(CFrame.new(position), size, Enum.Material.Ground)
						end
					end
				end
			end
		end
	end

	print("Grassy terrain generated!")
end

-- Function to get terrain height at a specific world position (exported for other modules)
function TerrainManager.GetTerrainHeightAtPosition(worldX, worldZ)
	-- Convert world coordinates to grid coordinates
	local gridX = math.floor(worldX / 4)
	local gridZ = math.floor(worldZ / 4)

	-- Calculate the same height as the terrain generation
	local heightVariation = getTerrainHeight(gridX, gridZ)
	local terrainTop = math.max(Config.Terrain.GroundLevel + heightVariation, Config.Terrain.GroundLevel)

	return terrainTop
end

-- Function to check if a position is in spawn area or lake (exported for other modules)
function TerrainManager.IsInSpawnArea(x, z)
	return isInSpawnArea(x, z) or isInLakeArea(x, z) -- También excluye el área del lago
end

return TerrainManager
