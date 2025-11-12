-- ShovelManager.luau
-- Handles all shovel-related logic (creation, pickup, giving to players)

local ShovelManager = {}

local Config = require(script.Parent.Config)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Storage for the pickup folder
local shovelPickupFolder = nil

-- Function to update gear stats without recreating the tool
local function updateGearStats(tool, gearData)
	if not tool or not gearData then return false end

	-- Update attributes safely
	if gearData.name ~= nil then tool:SetAttribute("GearName", gearData.name) end
	if gearData.poopMultiplier ~= nil then tool:SetAttribute("PoopMultiplier", gearData.poopMultiplier) end
	if gearData.digSpeed ~= nil then tool:SetAttribute("DigSpeed", gearData.digSpeed) end
	if gearData.range ~= nil then tool:SetAttribute("Range", gearData.range) end
	if gearData.autoClick then
		tool:SetAttribute("AutoClick", true)
		tool:SetAttribute("AutoClickInterval", gearData.autoClickInterval)
	end
	if gearData.critChance ~= nil then tool:SetAttribute("CritChance", gearData.critChance) end
	if gearData.specialEffect ~= nil then tool:SetAttribute("SpecialEffect", gearData.specialEffect) end

	-- Update display properties
	tool.Name = gearData.displayName or tool.Name
	tool.ToolTip = gearData.description or tool.ToolTip

	return true
end

-- Function to create a shovel tool
-- modelName parameter allows creating different gear types
function ShovelManager.CreateShovelTool(modelName, gearData)
	modelName = modelName or "Start_Shovel" -- Default to Start_Shovel
	print(">>> createShovelTool() called with model:", modelName)

	-- ALWAYS create a fresh tool to ensure it works
	local tool = Instance.new("Tool")
	tool.Name = gearData and gearData.displayName or "Shovel"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.GripPos = Vector3.new(0, -0.5, 0)
	tool.GripRight = Vector3.new(1, 0, 0)
	tool.GripUp = Vector3.new(0, 1, 0)
	tool.GripForward = Vector3.new(0, 0, -1)
	tool.ToolTip = gearData and gearData.description or "Click to clear poop!"

	-- Store gear stats as attributes
	if gearData then
		tool:SetAttribute("GearName", gearData.name)
		tool:SetAttribute("PoopMultiplier", gearData.poopMultiplier)
		tool:SetAttribute("DigSpeed", gearData.digSpeed)
		tool:SetAttribute("Range", gearData.range)
		if gearData.autoClick then
			tool:SetAttribute("AutoClick", true)
			tool:SetAttribute("AutoClickInterval", gearData.autoClickInterval)
		end
		if gearData.critChance then
			tool:SetAttribute("CritChance", gearData.critChance)
		end
		if gearData.specialEffect then
			tool:SetAttribute("SpecialEffect", gearData.specialEffect)
		end
	end

	print(">>> Created Tool instance")

	-- Check if there's the specified model in workspace to use as visual
	local shovelModel = workspace:FindFirstChild(modelName)

	if shovelModel then
		print(">>> Found Shovel in workspace, type:", shovelModel.ClassName)
		print("⚠️ CRITICAL: Resetting positions to prevent teleportation!")

		if shovelModel:IsA("Model") then
			-- Copy parts from the model
			local parts = {}
			local originalCFrames = {}
			local handlePart = nil

			-- First pass: collect all parts and their relative positions
			print(">>> PASO 1: Recopilando partes del modelo...")
			for _, child in ipairs(shovelModel:GetDescendants()) do
				if child:IsA("BasePart") then
					table.insert(parts, child)
					if not handlePart then
						handlePart = child
						print(">>> Handle será:", child.Name, "Pos:", child.Position)
					end
				end
			end

			if not handlePart then
				warn(">>> No se encontraron partes en el modelo!")
			else
				-- Calculate relative positions from handle
				print(">>> PASO 2: Calculando posiciones relativas al handle...")
				for _, part in ipairs(parts) do
					local relativeCFrame = handlePart.CFrame:ToObjectSpace(part.CFrame)
					originalCFrames[part] = relativeCFrame
					print("  -", part.Name, "offset relativo:", relativeCFrame.Position)
				end

				-- Clone parts with RESET positions
				print(">>> PASO 3: Clonando partes con posiciones reseteadas...")
				local handleClone = nil

				for i, part in ipairs(parts) do
					local partClone = part:Clone()
					partClone.CanCollide = false
					partClone.Anchored = false

					-- Clear all scripts/constraints from cloned parts
					for _, child in ipairs(partClone:GetChildren()) do
						if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Constraint") then
							child:Destroy()
						end
					end

					if i == 1 then
						-- First part is the handle - reset to origin
						partClone.Name = "Handle"
						partClone.CFrame = CFrame.new(0, 0, 0)
						handleClone = partClone
						partClone.Parent = tool
						print("  ✓ Handle clonado en origen:", partClone.Name)
					else
						-- Other parts - position relative to handle
						partClone.Parent = tool

						-- Use the relative CFrame we calculated
						local relativeCFrame = originalCFrames[part]
						partClone.CFrame = handleClone.CFrame:ToWorldSpace(relativeCFrame)

						-- Weld to handle
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = handleClone
						weld.Part1 = partClone
						weld.Parent = handleClone

						print("  ✓ Parte soldada:", partClone.Name, "offset:", relativeCFrame.Position)
					end
				end
			end

			-- Fallback if no parts found
			if not handlePart then
				print(">>> No parts found in model, creating default handle")
				local handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Size = Vector3.new(0.4, 4, 0.4)
				handle.Material = Enum.Material.Wood
				handle.Color = Color3.fromRGB(120, 80, 50)
				handle.CanCollide = false
				handle.CFrame = CFrame.new(0, 0, 0)
				handle.Parent = tool
			end

		elseif shovelModel:IsA("Tool") then
			print(">>> Shovel es una Tool, clonando estructura existente")
			local existingHandle = shovelModel:FindFirstChild("Handle")

			if existingHandle then
				local handleClone = existingHandle:Clone()
				handleClone.CFrame = CFrame.new(0, 0, 0)
				handleClone.CanCollide = false
				handleClone.Anchored = false
				handleClone.Parent = tool

				-- Clone other parts relative to handle
				for _, child in ipairs(shovelModel:GetDescendants()) do
					if child:IsA("BasePart") and child ~= existingHandle then
						local partClone = child:Clone()
						partClone.CanCollide = false
						partClone.Anchored = false

						-- Calculate and apply relative position
						local relativeCFrame = existingHandle.CFrame:ToObjectSpace(child.CFrame)
						partClone.Parent = tool
						partClone.CFrame = handleClone.CFrame:ToWorldSpace(relativeCFrame)

						-- Weld it
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = handleClone
						weld.Part1 = partClone
						weld.Parent = handleClone
					end
				end
			end
		else
			print(">>> Shovel is type:", shovelModel.ClassName, "- creating default")
			-- Create default handle
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.4, 4, 0.4)
			handle.Material = Enum.Material.Wood
			handle.Color = Color3.fromRGB(120, 80, 50)
			handle.CanCollide = false
			handle.CFrame = CFrame.new(0, 0, 0)
			handle.Parent = tool
		end
	else
		print(">>> No Shovel found in workspace, creating default shovel")
		-- Create a simple but nice looking shovel
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 4, 0.4)
		handle.Material = Enum.Material.Wood
		handle.Color = Color3.fromRGB(120, 80, 50)
		handle.CanCollide = false
		handle.Parent = tool

		-- Add a blade
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(1.2, 0.2, 0.8)
		blade.Material = Enum.Material.Metal
		blade.Color = Color3.fromRGB(150, 150, 150)
		blade.CanCollide = false
		blade.Parent = tool

		-- Weld blade to handle
		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = blade
		weld.C0 = CFrame.new(0, -2, 0) * CFrame.Angles(math.rad(10), 0, 0)
		weld.Parent = handle
	end

	-- Verify the tool has a handle
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		warn(">>> CRITICAL: Tool has no Handle! Adding emergency handle...")
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 4, 0.4)
		handle.Material = Enum.Material.Wood
		handle.Color = Color3.fromRGB(120, 80, 50)
		handle.CanCollide = false
		handle.Parent = tool
	else
		print(">>> Tool has Handle:", handle.Name, handle.Size)
	end

	-- Get the ShovelScript from ReplicatedStorage
	print(">>> Buscando ShovelScript en ReplicatedStorage...")
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)

	if not sharedFolder then
		warn("❌ CRITICAL: Shared folder not found in ReplicatedStorage!")
	else
		print("✓ Found Shared folder")

		local shovelScriptTemplate = sharedFolder:WaitForChild("ShovelScript", 5)
		if not shovelScriptTemplate then
			warn("❌ CRITICAL: ShovelScript not found in ReplicatedStorage.Shared!")
		else
			print("✓ Found ShovelScript!")
			local localScript = shovelScriptTemplate:Clone()
			localScript.Parent = tool
			print("✅ Cloned ShovelScript into tool successfully!")
		end

		-- Also clone ShovelParticles script
		local particlesScriptTemplate = sharedFolder:WaitForChild("ShovelParticles", 5)
		if particlesScriptTemplate then
			print("✓ Found ShovelParticles!")
			local particlesScript = particlesScriptTemplate:Clone()
			particlesScript.Parent = tool
			print("✅ Cloned ShovelParticles into tool successfully!")
		else
			warn("⚠️ ShovelParticles script not found (particles won't work)")
		end
	end

	print("========================================")
	print("TOOL CREATION COMPLETE:")
	print("  - Tool name:", tool.Name)
	print("  - Has Handle:", tool:FindFirstChild("Handle") ~= nil)
	print("  - Has LocalScript:", tool:FindFirstChild("ShovelScript") ~= nil)
	print("========================================")

	return tool
end

-- Function to give shovel/gear to a player
function ShovelManager.GiveShovelToPlayer(player, modelName, gearData)
	modelName = modelName or "Start_Shovel"
	print("========================================")
	print("Attempting to give gear to player:", player.Name)
	print("Model:", modelName)
	print("========================================")

	-- Wait for character and backpack to be ready
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(1)

	local starterGear = player:FindFirstChild("StarterGear")
	local backpack = player:FindFirstChild("Backpack")

	if not backpack then
		print("Waiting for Backpack...")
		backpack = player:WaitForChild("Backpack", 10)
	end

	if not backpack then
		warn("❌ Failed to find Backpack for player:", player.Name)
		return
	end

	print("✓ Backpack found for player:", player.Name)

	-- Try to update existing tool in-place to avoid visual flicker
	local existingTool = backpack:FindFirstChildWhichIsA("Tool") or (character and character:FindFirstChildWhichIsA("Tool"))
	if existingTool and existingTool:GetAttribute("GearName") then
		local ok
		pcall(function()
			ok = updateGearStats(existingTool, gearData)
		end)
		if ok then
			print("✓ Existing gear updated in-place, skipping recreate")
			-- Also ensure StarterGear copy exists for respawn
			if starterGear and not starterGear:FindFirstChildWhichIsA("Tool") then
				local cloneForStarter = existingTool:Clone()
				cloneForStarter.Parent = starterGear
			end
			return
		else
			print("⚠️ Failed to update existing gear in-place, will recreate")
		end
	end

	-- Create and give gear
	print(">>> Creating gear tool...")
	local gear = ShovelManager.CreateShovelTool(modelName, gearData)

	if not gear then
		warn("❌ Failed to create gear for player:", player.Name)
		return
	end

	print("✓ Gear created successfully!")

	-- Method 1: Direct to backpack
	local gear1 = gear:Clone()
	gear1.Parent = backpack
	print("✓ Method 1: Added gear to Backpack")

	-- Method 2: To StarterGear
	if starterGear then
		local gear2 = gear:Clone()
		gear2.Parent = starterGear
		print("✓ Method 2: Added gear to StarterGear")
	end

	-- Cleanup original
	gear:Destroy()

	task.wait(0.1)

	print("========================================")
	print("VERIFICATION FOR:", player.Name)
	print("  - Gear in backpack:", backpack:FindFirstChildWhichIsA("Tool") ~= nil)
	print("========================================")
end

-- Function to create pickable shovel at spawn
function ShovelManager.CreatePickableShovel()
	print("Creating pickable starter shovel at spawn...")

	-- Create a folder for the pickable shovel
	if not shovelPickupFolder or not shovelPickupFolder.Parent then
		shovelPickupFolder = Instance.new("Folder")
		shovelPickupFolder.Name = "ShovelPickup"
		shovelPickupFolder.Parent = workspace
		print("Created ShovelPickup folder")
	else
		print("Using existing ShovelPickup folder")
	end

	-- Look for Shovel model in workspace (starter gear)
	local shovelTemplate = workspace:FindFirstChild("Shovel")
	local shovelDisplay = nil
	local handle = nil

	if shovelTemplate then
		print(">>> Found Shovel in workspace, using it for pickup display")

		-- Clone the shovel template
		if shovelTemplate:IsA("Model") then
			shovelDisplay = shovelTemplate:Clone()
			shovelDisplay.Name = "PickableShovel"

			-- Find the main part to use as handle for the prompt
			handle = shovelDisplay:FindFirstChild("Handle") or shovelDisplay:FindFirstChildWhichIsA("BasePart")
			if handle then
				print(">>> Found handle in model:", handle.Name)
			else
				-- If no handle found, create one
				handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Size = Vector3.new(0.5, 5, 0.5)
				handle.Material = Enum.Material.Wood
				handle.Color = Color3.fromRGB(120, 80, 50)
				handle.Anchored = true
				handle.CanCollide = false
				handle.Parent = shovelDisplay
			end

			-- Set primary part
			if not shovelDisplay.PrimaryPart then
				shovelDisplay.PrimaryPart = handle
			end

			-- Anchor all parts and disable collision
			for _, part in ipairs(shovelDisplay:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end

			shovelDisplay.Parent = shovelPickupFolder
			shovelDisplay:MoveTo(Vector3.new(10, 1, 5))

		elseif shovelTemplate:IsA("Tool") then
			print(">>> Shovel is a Tool, converting to Model for display")

			-- Create a model from the tool
			shovelDisplay = Instance.new("Model")
			shovelDisplay.Name = "PickableShovel"

			-- Clone all parts from the tool
			for _, child in ipairs(shovelTemplate:GetDescendants()) do
				if child:IsA("BasePart") then
					local partClone = child:Clone()
					partClone.Anchored = true
					partClone.CanCollide = false
					partClone.Parent = shovelDisplay

					if child.Name == "Handle" or not handle then
						handle = partClone
					end
				end
			end

			if handle then
				shovelDisplay.PrimaryPart = handle
			end

			shovelDisplay.Parent = shovelPickupFolder
			shovelDisplay:MoveTo(Vector3.new(0, 1, 0))
		end
	end

	-- Fallback: Create default shovel if none found
	if not shovelDisplay or not handle then
		print(">>> No valid Shovel found in workspace, creating default display")

		shovelDisplay = Instance.new("Model")
		shovelDisplay.Name = "PickableShovel"

		-- Create handle
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.5, 5, 0.5)
		handle.Material = Enum.Material.Wood
		handle.Color = Color3.fromRGB(120, 80, 50)
		handle.Anchored = true
		handle.CanCollide = false
		handle.Position = Vector3.new(0, 1, 0)
		handle.Parent = shovelDisplay

		-- Create blade
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(1.5, 0.3, 1)
		blade.Material = Enum.Material.Metal
		blade.Color = Color3.fromRGB(150, 150, 150)
		blade.Anchored = true
		blade.CanCollide = false
		blade.Position = Vector3.new(0, 0.5, 0)
		blade.Parent = shovelDisplay

		-- Weld blade to handle
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = blade
		weld.Parent = handle

		shovelDisplay.Parent = shovelPickupFolder
		shovelDisplay.PrimaryPart = handle
	end

	-- Ensure handle is properly configured
	if handle then
		handle.Anchored = true
		handle.CanCollide = false
		handle.Transparency = 0

		-- Add visual effects to the handle
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 2
		pointLight.Color = Color3.fromRGB(255, 255, 150)
		pointLight.Range = 10
		pointLight.Parent = handle

		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 255, 150)
		sparkles.Parent = handle

		-- Add a BillboardGui to show text above the shovel
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = handle

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "🔨 SHOVEL\n[Press E to Pick Up]"
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextStrokeTransparency = 0.5
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextSize = 18
		textLabel.Parent = billboard

		print(">>> Shovel display created with handle")
	else
		warn("❌ CRITICAL: No handle available for proximity prompt!")
	end

	-- Create proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Pick up Shovel"
	proximityPrompt.ObjectText = "Shovel"
	proximityPrompt.MaxActivationDistance = 15
	proximityPrompt.HoldDuration = 0
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.ClickablePrompt = true
	proximityPrompt.Enabled = true
	proximityPrompt.Parent = handle

	print(">>> ProximityPrompt created and parented to handle")

	-- Handle pickup
	proximityPrompt.Triggered:Connect(function(player)
		print("========================================")
		print("🎯 PROXIMITY PROMPT TRIGGERED!")
		print("Player:", player.Name, "is picking up the shovel!")
		print("========================================")

		local backpack = player:FindFirstChild("Backpack")
		local character = player.Character

		if not backpack then
			warn("❌ Player has no backpack!")
			return
		end

		-- Check if already has shovel
		if backpack:FindFirstChild("Shovel") or (character and character:FindFirstChild("Shovel")) then
			print("⚠️ Player already has a shovel!")
			return
		end

		print("✓ Creating and giving starter shovel directly to player...")

		-- Get starter gear config
		local Config = require(script.Parent.Config)
		local starterGearData = {
			name = "Shovel",
			displayName = "Shovel",
			description = "Your trusty shovel",
			poopMultiplier = Config.Shovel.BasePoopMultiplier,
			digSpeed = Config.Shovel.BaseDigSpeed,
			range = Config.Shovel.BaseRange,
		}

		-- Create the starter shovel tool
		local shovelTool = ShovelManager.CreateShovelTool(Config.Shovel.ModelName, starterGearData)

		if shovelTool then
			print("✓ Starter shovel tool created successfully")

			-- Give directly to backpack
			shovelTool.Parent = backpack

			-- Also add to StarterGear
			local starterGear = player:FindFirstChild("StarterGear")
			if starterGear then
				local shovelCopy = shovelTool:Clone()
				shovelCopy.Parent = starterGear
				print("✓ Also added to StarterGear")
			end

			task.wait(0.1)

			if backpack:FindFirstChild("Shovel") then
				print("✅ SUCCESS! Shovel is now in player's backpack!")
			else
				warn("❌ FAILED! Shovel not found in backpack after adding!")
			end
		else
			warn("❌ Failed to create shovel tool!")
		end

		-- Destroy the pickup
		if shovelDisplay then
			shovelDisplay:Destroy()
			print("✓ Shovel pickup destroyed")
		end

		-- Respawn the pickup after configured time
		task.spawn(function()
			task.wait(Config.Shovel.RespawnTime)

			local shovelTemplate = workspace:FindFirstChild("Shovel")
			if not shovelTemplate then
				warn("Cannot respawn shovel - Shovel template not found")
				return
			end

			print("✓ Respawning starter shovel pickup...")
			ShovelManager.CreatePickableShovel()
		end)
	end)

	-- Floating and spinning animation
	local animationRunning = true

	task.spawn(function()
		if not shovelDisplay.PrimaryPart then
			warn("No PrimaryPart for animation!")
			return
		end

		local startPos = shovelDisplay.PrimaryPart.Position
		local time = 0

		while animationRunning and shovelDisplay and shovelDisplay.Parent and shovelDisplay.PrimaryPart do
			time = time + 0.05

			-- Calculate new position (bobbing)
			local bobOffset = math.sin(time * 2) * 1
			local newPos = startPos + Vector3.new(0, bobOffset, 0)

			-- Calculate rotation (spinning)
			local rotation = time * 30

			-- Apply transformations
			local newCFrame = CFrame.new(newPos) * CFrame.Angles(0, math.rad(rotation), 0)

			if shovelDisplay and shovelDisplay.Parent and shovelDisplay.PrimaryPart then
				shovelDisplay:SetPrimaryPartCFrame(newCFrame)
			else
				break
			end

			task.wait(0.05)
		end

		print("Animation stopped for pickable shovel")
	end)

	print("Pickable shovel created at spawn!")
end

return ShovelManager
