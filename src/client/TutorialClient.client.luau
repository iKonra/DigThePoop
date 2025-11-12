local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TutorialClient = {}

-- Get remote events
local TutorialRemotes = ReplicatedStorage:WaitForChild("TutorialRemotes")
local ShowArrowEvent = TutorialRemotes:WaitForChild("ShowTutorialArrow")
local UpdateProgressEvent = TutorialRemotes:WaitForChild("UpdateTutorialProgress")
local ShowTextEvent = TutorialRemotes:WaitForChild("ShowTutorialText")
local HideAllEvent = TutorialRemotes:WaitForChild("HideTutorialElements")

-- GUI Elements
local tutorialGui
local arrow
local textLabel
local progressBar

local function createTutorialGui()
    tutorialGui = Instance.new("ScreenGui")
    tutorialGui.Name = "TutorialGui"
    tutorialGui.ResetOnSpawn = false
    
    -- Create arrow
    arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 80, 0, 80) -- Flecha más grande
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://6431182523" -- Flecha predefinida de Roblox
    arrow.ImageColor3 = Color3.fromRGB(255, 255, 0) -- Color amarillo brillante
    arrow.Visible = false
    
    -- Animación de rebote
    local function animateArrow()
        while arrow.Parent do
            local bounce = TweenService:Create(arrow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Size = UDim2.new(0, 90, 0, 90) -- Rebota entre 80 y 90
            })
            bounce:Play()
            task.wait(1)
        end
    end
    task.spawn(animateArrow)
    
    arrow.Parent = tutorialGui
    
    -- Create text label
    textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 400, 0, 50)
    textLabel.Position = UDim2.new(0.5, -200, 0.8, 0)
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.BackgroundTransparency = 0.5
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 24
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Visible = false
    textLabel.Parent = tutorialGui
    
    -- Create progress bar
    local progressBarFrame = Instance.new("Frame")
    progressBarFrame.Name = "ProgressBarFrame"
    progressBarFrame.Size = UDim2.new(0, 400, 0, 30)
    progressBarFrame.Position = UDim2.new(0.5, -200, 0.9, 0)
    progressBarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBarFrame.Visible = false
    progressBarFrame.Parent = tutorialGui
    
    progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    progressBar.Parent = progressBarFrame
    
    local progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.TextSize = 18
    progressText.Font = Enum.Font.GothamBold
    progressText.Text = "Collect Poops: 0/100"
    progressText.Parent = progressBarFrame
    
    tutorialGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function updateArrowPosition(target)
    if typeof(target) == "Instance" then
        -- Point to a part/model in the world
        local camera = workspace.CurrentCamera
        
        -- Update arrow position every frame
        local connection
        connection = game:GetService("RunService").RenderStepped:Connect(function()
            if not arrow.Visible then
                connection:Disconnect()
                return
            end
            
            local targetPos = target.Position
            local screenPos, isOnScreen = camera:WorldToScreenPoint(targetPos)
            
            if isOnScreen then
                arrow.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
            else
                arrow.Visible = false
            end
        end)
    else
        -- Point to a UI element
        local targetElement = Players.LocalPlayer.PlayerGui:FindFirstChild(target, true)
        if targetElement then
            local targetAbsPos = targetElement.AbsolutePosition
            arrow.Position = UDim2.new(0, targetAbsPos.X, 0, targetAbsPos.Y)
        end
    end
end

function TutorialClient.Initialize()
    createTutorialGui()
    
    ShowArrowEvent.OnClientEvent:Connect(function(target)
        arrow.Visible = true
        updateArrowPosition(target)
    end)
    
    UpdateProgressEvent.OnClientEvent:Connect(function(current, total)
        progressBar.Parent.Visible = true
        local progress = current / total
        local tween = TweenService:Create(progressBar, TweenInfo.new(0.3), {
            Size = UDim2.new(progress, 0, 1, 0)
        })
        tween:Play()
        progressBar.Parent.TextLabel.Text = string.format("Collect Poops: %d/%d", current, total)
    end)
    
    ShowTextEvent.OnClientEvent:Connect(function(text)
        textLabel.Text = text
        textLabel.Visible = true
    end)
    
    HideAllEvent.OnClientEvent:Connect(function()
        arrow.Visible = false
        textLabel.Visible = false
        progressBar.Parent.Visible = false
    end)
end

return TutorialClient