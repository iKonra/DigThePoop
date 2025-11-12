-- Minimal Multiplier X5 UI
-- Solo un botón de trébol (☘️). Al tocarlo dispara el evento para abrir la compra (PromptPassPurchaseEvent).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local PASS_NAME = "MultiplierX5"
local PromptPassPurchaseEvent = ReplicatedStorage:WaitForChild("PromptPassPurchaseEvent", 10)

local function mountSimpleButton()
	local hud = PLAYER_GUI:FindFirstChild("MultiplierX5HUD")
	if not hud then
		hud = Instance.new("ScreenGui")
		hud.Name = "MultiplierX5HUD"
		hud.ResetOnSpawn = false
		hud.IgnoreGuiInset = true
		hud.Parent = PLAYER_GUI
	end

	-- Remove any previous complex UI to avoid duplicates
	local oldCard = hud:FindFirstChild("MultiplierX5Card")
	if oldCard then oldCard:Destroy() end
	local existing = hud:FindFirstChild("MultiplierX5Button")
	if existing then return existing end

	local btn = Instance.new("TextButton")
	btn.Name = "MultiplierX5Button"
	btn.Size = UDim2.new(0, 48, 0, 48)
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.Position = UDim2.new(1, -16, 1, -16) -- bottom-right
	btn.BackgroundColor3 = Color3.fromRGB(45, 47, 60)
	btn.BorderSizePixel = 0
	btn.Text = "☘️"
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 28
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = hud

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if PromptPassPurchaseEvent then
			PromptPassPurchaseEvent:FireServer(PASS_NAME)
		end
	end)

	return btn
end

-- Mount initially and when PlayerGui changes
mountSimpleButton()
PLAYER_GUI.ChildAdded:Connect(function()
	mountSimpleButton()
end)
