-- CameraController.client.luau
-- Controls camera zoom limits and behavior

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UserInputService = game:GetService("UserInputService")
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()

-- Camera zoom limits
local MIN_ZOOM = 1  -- Minimum distance from character (can't zoom too close)
local MAX_ZOOM = 20  -- Maximum distance from character (can't zoom too far)

-- First-person config
local FIRST_PERSON_ZOOM = 0.5
local DEFAULT_CAMERA_MODE = Enum.CameraMode.Classic
local FIRST_PERSON_MODE = Enum.CameraMode.LockFirstPerson
local firstPersonEnabled = false

print("CameraController: Setting up camera limits...")

-- Function to apply zoom limits
local function setupCameraLimits()
	if player.CameraMaxZoomDistance ~= MAX_ZOOM then
		player.CameraMaxZoomDistance = MAX_ZOOM
		print("✓ Camera max zoom set to:", MAX_ZOOM)
	end

	if player.CameraMinZoomDistance ~= MIN_ZOOM then
		player.CameraMinZoomDistance = MIN_ZOOM
		print("✓ Camera min zoom set to:", MIN_ZOOM)
	end
end

-- Apply initially
setupCameraLimits()

-- Helper to enable / disable first person
local function enableFirstPerson()
	if firstPersonEnabled then return end
	firstPersonEnabled = true
	-- Force camera mode and tight zoom to simulate first-person
	pcall(function()
		player.CameraMode = FIRST_PERSON_MODE
		player.CameraMinZoomDistance = FIRST_PERSON_ZOOM
		player.CameraMaxZoomDistance = FIRST_PERSON_ZOOM
	end)
	print("✓ First-person enabled")
end

local function disableFirstPerson()
	if not firstPersonEnabled then return end
	firstPersonEnabled = false
	pcall(function()
		player.CameraMode = DEFAULT_CAMERA_MODE
		player.CameraMinZoomDistance = MIN_ZOOM
		player.CameraMaxZoomDistance = MAX_ZOOM
	end)
	print("✓ First-person disabled")
end

-- Toggle function
local function toggleFirstPerson()
	if firstPersonEnabled then
		disableFirstPerson()
	else
		enableFirstPerson()
	end
end

-- Simple UI button so player can toggle first-person
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local playerGui = player:WaitForChild("PlayerGui")

local function createToggleButton()
	-- Avoid creating multiple times
	if playerGui:FindFirstChild("FirstPersonToggle") then return end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FirstPersonToggle"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local btn = Instance.new("TextButton")
	btn.Name = "FPBtn"

	-- On mobile we want a compact "logo" anchored to the top-right
	if IS_MOBILE then
		btn.Size = UDim2.new(0, 35, 0, 35)
		btn.AnchorPoint = Vector2.new(1, 0)
		btn.Position = UDim2.new(1, 0, 0, -33) -- 12px padding from top-right
		btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		btn.Text = "" -- prefer icon-only look on mobile; label below toggles state

		-- small label overlay to show state (on/off) if needed
		local stateLabel = Instance.new("TextLabel")
		stateLabel.Name = "StateLabel"
		stateLabel.Size = UDim2.new(1, 0, 1, 0)
		stateLabel.Position = UDim2.new(0, 0, 0, 0)
		stateLabel.BackgroundTransparency = 1
		stateLabel.Font = Enum.Font.FredokaOne
		stateLabel.TextSize = 14
		stateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		stateLabel.Text = firstPersonEnabled and "1P" or "1P"
		stateLabel.Parent = btn
	else
		-- Desktop: keep small toggle button (left as before but fixed position)
		btn.Size = UDim2.new(0, 39, 0, 39)
		btn.Position = UDim2.new(1, -79, 0, 12)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = 18
		btn.Text = "1P: Off"
	end

	btn.Parent = screenGui

	btn.MouseButton1Click:Connect(function()
		toggleFirstPerson()
		-- Update visible state
		if IS_MOBILE then
			local s = btn:FindFirstChild("StateLabel")
			if s then s.Text = firstPersonEnabled and "1P" or "1P" end
		else
			btn.Text = firstPersonEnabled and "1P: On" or "1P: Off"
		end
	end)
end

createToggleButton()

-- Keybind: press V to toggle
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.V then
		toggleFirstPerson()
		local btn = playerGui:FindFirstChild("FirstPersonToggle") and playerGui.FirstPersonToggle:FindFirstChild("FPBtn")
		if btn then btn.Text = firstPersonEnabled and "1P: On" or "1P: Off" end
	end
end)

-- Toggle to first-person when player scrolls the mouse wheel forward strongly
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		-- input.Position.Z typically holds wheel delta on some platforms; use input.Position.Z and input.Position.Y as fallback
		local delta = 0
		if input.Position and typeof(input.Position) == "Vector3" then
			delta = input.Position.Z or input.Position.Y or 0
		elseif input.Delta and typeof(input.Delta) == "Vector3" then
			delta = input.Delta.Z or input.Delta.Y or 0
		end
		-- On many setups, forward scroll is positive or negative; detect a sufficiently large absolute delta
		if delta and math.abs(delta) > 0 then
			-- If player scrolls forward (towards camera) — treat positive delta as forward on most platforms
			-- Use a threshold to avoid accidental toggles; player must scroll several 'notches'
			local threshold = 1
			if delta >= threshold then
				enableFirstPerson()
				local btn = playerGui:FindFirstChild("FirstPersonToggle") and playerGui.FirstPersonToggle:FindFirstChild("FPBtn")
				if btn then btn.Text = "1P: On" end
			elseif delta <= -threshold then
				-- backward scroll: disable
				disableFirstPerson()
				local btn = playerGui:FindFirstChild("FirstPersonToggle") and playerGui.FirstPersonToggle:FindFirstChild("FPBtn")
				if btn then btn.Text = "1P: Off" end
			end
		end
	end
end)

-- Keep enforcing the limits (in case something tries to change them)
player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(setupCameraLimits)
player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(setupCameraLimits)

-- Re-apply on respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	task.wait(0.1)
	setupCameraLimits()
	-- Re-apply first-person if it was enabled
	if firstPersonEnabled then
		enableFirstPerson()
	end
end)

print("✅ CameraController initialized!")
