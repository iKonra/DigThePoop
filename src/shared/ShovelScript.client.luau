-- Shovel Tool Script (runs on client)
print("🔧 ShovelScript is running!")

local tool = script.Parent
local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
local cooldown = false

-- Get gear attributes

local poopMultiplier = tool:GetAttribute("PoopMultiplier") or 1
local digSpeed = tool:GetAttribute("DigSpeed") or 1.0
local range = tool:GetAttribute("Range") or 8
local critChance = tool:GetAttribute("CritChance") or 0
local autoClick = tool:GetAttribute("AutoClick") or false
local autoClickInterval = tool:GetAttribute("AutoClickInterval") or 1.5
local gearName = tool:GetAttribute("GearName") or "Unknown"

-- Update local cached stats when server updates attributes to avoid needing to recreate the tool
local function refreshAttributes()
	poopMultiplier = tool:GetAttribute("PoopMultiplier") or poopMultiplier
	digSpeed = tool:GetAttribute("DigSpeed") or digSpeed
	range = tool:GetAttribute("Range") or range
	critChance = tool:GetAttribute("CritChance") or critChance
	autoClick = tool:GetAttribute("AutoClick") or autoClick
	autoClickInterval = tool:GetAttribute("AutoClickInterval") or autoClickInterval
	gearName = tool:GetAttribute("GearName") or gearName
	-- Optionally print debug
	print("🔁 ShovelScript attributes refreshed -> Mult:", poopMultiplier, "Speed:", digSpeed, "Range:", range)
end

-- Connect attribute changed signals
pcall(function()
	tool:GetAttributeChangedSignal("PoopMultiplier"):Connect(refreshAttributes)
	tool:GetAttributeChangedSignal("DigSpeed"):Connect(refreshAttributes)
	tool:GetAttributeChangedSignal("Range"):Connect(refreshAttributes)
	tool:GetAttributeChangedSignal("CritChance"):Connect(refreshAttributes)
	tool:GetAttributeChangedSignal("AutoClick"):Connect(refreshAttributes)
	tool:GetAttributeChangedSignal("AutoClickInterval"):Connect(refreshAttributes)
	tool:GetAttributeChangedSignal("GearName"):Connect(refreshAttributes)
end)

print("🔧 Tool:", tool.Name)
print("🔧 Gear:", gearName)
print("🔧 Stats - Multiplier:", poopMultiplier, "Speed:", digSpeed, "Range:", range)
print("🔧 Handle:", handle and handle.Name or "NO HANDLE")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clearPoopEvent = ReplicatedStorage:WaitForChild("ClearPoopEvent", 10)

if not clearPoopEvent then
	warn("❌ Failed to find ClearPoopEvent!")
	return
end

print("🔧 Found ClearPoopEvent!")

-- Debug equipped/unequipped
tool.Equipped:Connect(function()
	print("🔧 Shovel EQUIPPED!")
end)

tool.Unequipped:Connect(function()
	print("🔧 Shovel UNEQUIPPED!")
end)

-- Animation function
local function playDigAnimation(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Create a simple dig animation by rotating the tool
	local originalGrip = tool.Grip

	-- Swing animation (speed affected by digSpeed)
	local TweenService = game:GetService("TweenService")
	local animSpeed = 0.2 / digSpeed -- Faster animation with higher digSpeed
	local goal1 = {Grip = originalGrip * CFrame.Angles(math.rad(-60), 0, 0)}
	local goal2 = {Grip = originalGrip}

	local tweenInfo = TweenInfo.new(animSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween1 = TweenService:Create(tool, tweenInfo, goal1)
	local tween2 = TweenService:Create(tool, tweenInfo, goal2)

	tween1:Play()
	tween1.Completed:Wait()
	tween2:Play()
end

tool.Activated:Connect(function()
	print("🔨 SHOVEL ACTIVATED!")

	if cooldown then
		print("⏳ Cooldown active, ignoring click")
		return
	end
	cooldown = true

	local character = tool.Parent
	if not character or not character:IsA("Model") then
		print("❌ Tool not in character")
		cooldown = false
		return
	end

	print("✓ Character found:", character.Name)

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		print("❌ No HumanoidRootPart")
		cooldown = false
		return
	end

	print("✓ HumanoidRootPart found, position:", humanoidRootPart.Position)

	-- Play dig animation
	playDigAnimation(character)

	-- Add clearing sound/effect
	if handle then
		local sound = Instance.new("Sound")
		-- Try to locate a Sound instance in a 'sounds' folder (workspace or ReplicatedStorage).
		local chosenSoundId = nil
		local soundsFolder = workspace:FindFirstChild("sounds") or game:GetService("ReplicatedStorage"):FindFirstChild("sounds")
		if soundsFolder then
			-- Prefer a child named 'shovel_hit' or the first Sound instance
			local s = soundsFolder:FindFirstChild("shovel_hit") or soundsFolder:FindFirstChildWhichIsA("Sound")
			if s and s:IsA("Sound") then
				chosenSoundId = s.SoundId
			end
		end
		-- If found, use that SoundId; otherwise fall back to a safe default or skip playing
		if chosenSoundId and chosenSoundId ~= "" then
			sound.SoundId = chosenSoundId
			sound.Volume = 0.5
			sound.Parent = handle
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 1)
		else
			-- No uploaded asset found; warn and skip sound to avoid the temp read error
			warn("⚠️ shovel_hit sound not found in workspace/ReplicatedStorage 'sounds' folder. Please upload the sound to Roblox and set a SoundId (rbxassetid://...) or place a Sound instance named 'shovel_hit' in a 'sounds' folder.")
		end
	end

	-- Check for poops in front of player
	local poopsFolder = workspace:FindFirstChild("BrainrotPoops")

	if not poopsFolder then
		print("❌ BrainrotPoops folder not found in workspace!")
		cooldown = false
		return
	end

	print("✓ Found BrainrotPoops folder")
	print("  - Total poops in folder:", #poopsFolder:GetChildren())

	local playerPos = humanoidRootPart.Position
	local lookVector = humanoidRootPart.CFrame.LookVector

	print("📍 Player position:", playerPos)
	print("👀 Looking direction:", lookVector)

	local nearestPoop = nil
	local nearestDistance = math.huge

	-- Find nearby poops (including super poops and personal poops)
	local poopCount = 0
	for _, poop in ipairs(poopsFolder:GetChildren()) do
		-- Check for all poop types
		if poop.Name == "BrainrotPoop" or poop.Name == "SuperPoop" or poop.Name == "PersonalPoop" then
			poopCount = poopCount + 1

			local poopPos
			if poop:IsA("Model") and poop.PrimaryPart then
				poopPos = poop.PrimaryPart.Position
			elseif poop:IsA("Model") then
				local firstPart = poop:FindFirstChildWhichIsA("BasePart")
				if firstPart then
					poopPos = firstPart.Position
				end
			elseif poop:IsA("BasePart") then
				poopPos = poop.Position
			end

			if poopPos then
				local distance = (poopPos - playerPos).Magnitude

				if distance <= range then
					local poopType = poop.Name
					if poop.Name == "SuperPoop" then
						local superType = poop:GetAttribute("PoopType") or "Super"
						print("  ✨ " .. superType .. " Poop found within range!")
					else
						print("  💩 Poop found within range!")
					end
					print("    - Distance:", distance, "studs")
					print("    - Position:", poopPos)

					if distance < nearestDistance then
						nearestDistance = distance
						nearestPoop = poop
					end
				end
			end
		end
	end

	print("📊 Checked", poopCount, "poops total")

	if nearestPoop then
		print("🎯 Clearing nearest poop at distance:", nearestDistance)
		-- Request server to clear the poop
		clearPoopEvent:FireServer(nearestPoop)
		print("✅ Sent FireServer request to clear poop!")
	else
		print("⚠️ No poops within", range, "studs range")
	end

	-- Cooldown affected by digSpeed
	local cooldownTime = 0.5 / digSpeed
	task.wait(cooldownTime)
	cooldown = false
end)

-- Auto-click functionality for special gears
if autoClick then
	print("🤖 Auto-click enabled! Interval:", autoClickInterval, "seconds")

	task.spawn(function()
		while true do
			task.wait(autoClickInterval)

			-- Only auto-click if tool is equipped
			if tool.Parent and tool.Parent:IsA("Model") then
				local character = tool.Parent
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then
					local playerPos = humanoidRootPart.Position
					local poopsFolder = workspace:FindFirstChild("BrainrotPoops")

					if poopsFolder then
						local nearestPoop = nil
						local nearestDistance = math.huge

						-- Find nearest poop within range
						for _, poop in ipairs(poopsFolder:GetChildren()) do
							if poop.Name == "BrainrotPoop" or poop.Name == "SuperPoop" or poop.Name == "PersonalPoop" then
								local poopPos
								if poop:IsA("Model") and poop.PrimaryPart then
									poopPos = poop.PrimaryPart.Position
								elseif poop:IsA("Model") then
									local firstPart = poop:FindFirstChildWhichIsA("BasePart")
									if firstPart then
										poopPos = firstPart.Position
									end
								elseif poop:IsA("BasePart") then
									poopPos = poop.Position
								end

								if poopPos then
									local distance = (poopPos - playerPos).Magnitude
									if distance <= range and distance < nearestDistance then
										nearestDistance = distance
										nearestPoop = poop
									end
								end
							end
						end

						-- Auto-clear nearest poop
						if nearestPoop then
							clearPoopEvent:FireServer(nearestPoop)
							print("🤖 Auto-cleared poop!")
						end
					end
				end
			end
		end
	end)
end
