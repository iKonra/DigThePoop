-- TutorialClient.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TutorialClient = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local arrowPart
local textLabel
local currentTarget
local keepUpdating = false

local function createArrow()
    -- Create arrow model
    arrowPart = Instance.new("Model")
    arrowPart.Name = "TutorialArrow"
    
    -- Create main arrow part
    local mainPart = Instance.new("Part")
    mainPart.Name = "Handle"
    mainPart.Size = Vector3.new(1, 3, 1)
    mainPart.CFrame = CFrame.new(0, 0, 0)
    mainPart.Anchored = true
    mainPart.CanCollide = false
    mainPart.Material = Enum.Material.Neon
    mainPart.Color = Color3.fromRGB(255, 210, 60)
    mainPart.Parent = arrowPart
    
    -- Create arrow head parts
    local head1 = Instance.new("Part")
    head1.Name = "Head1"
    head1.Size = Vector3.new(0.5, 1, 0.5)
    head1.CFrame = mainPart.CFrame * CFrame.new(0.5, 1.5, 0)
    head1.Anchored = true
    head1.CanCollide = false
    head1.Material = Enum.Material.Neon
    head1.Color = Color3.fromRGB(255, 210, 60)
    head1.Parent = arrowPart
    
    local head2 = Instance.new("Part")
    head2.Name = "Head2"
    head2.Size = Vector3.new(0.5, 1, 0.5)
    head2.CFrame = mainPart.CFrame * CFrame.new(-0.5, 1.5, 0)
    head2.Anchored = true
    head2.CanCollide = false
    head2.Material = Enum.Material.Neon
    head2.Color = Color3.fromRGB(255, 210, 60)
    head2.Parent = arrowPart
    
    -- Add point light for extra visibility
    local pointLight = Instance.new("PointLight")
    pointLight.Range = 15
    pointLight.Brightness = 5
    pointLight.Color = Color3.fromRGB(255, 210, 60)
    pointLight.Parent = mainPart

    -- Add highlight effect
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 210, 60)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.Parent = arrowPart
    
    arrowPart.Parent = workspace
    print("✓ Tutorial arrow created!")
    
    -- Create simple floating text label
    textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 400, 0, 40)
    textLabel.Position = UDim2.new(0.5, -200, 0.85, 0)
    textLabel.BackgroundTransparency = 0.4
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 22
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Visible = false
    textLabel.Text = "¡Sigue la flecha!"
    textLabel.Parent = playerGui
end

local function updateArrowPosition()
    if not (arrowPart and currentTarget) then return end
    
    -- Get target position
    local targetPos
    if typeof(currentTarget) == "string" then
        -- If it's a GUI element name (like "RebirthButton"), position in front of player
        local char = player.Character
        if char and char.PrimaryPart then
            local forward = char.PrimaryPart.CFrame.LookVector
            targetPos = char.PrimaryPart.Position + forward * 5 + Vector3.new(0, 2, 0)
        end
    elseif currentTarget:IsA("Model") then
        targetPos = currentTarget:GetPivot().Position
    elseif currentTarget:IsA("BasePart") then
        targetPos = currentTarget.Position
    elseif currentTarget:IsA("GuiObject") then
        -- Para elementos GUI, posicionar frente al jugador
        local char = player.Character
        if char and char.PrimaryPart then
            local forward = char.PrimaryPart.CFrame.LookVector
            targetPos = char.PrimaryPart.Position + forward * 5 + Vector3.new(0, 2, 0)
        end
    end

    if targetPos then
        -- Position arrow above target
        local arrowPos = targetPos + Vector3.new(0, 8, 0)
        
        -- Make arrow point down at target with smooth interpolation
        local currentCF = arrowPart:GetPivot()
        local targetCF = CFrame.new(arrowPos, targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
        
        -- Smooth interpolation with faster response
        arrowPart:PivotTo(currentCF:Lerp(targetCF, 0.2))
        
        -- Add bobbing motion
        local offset = math.sin(tick() * 3) * 1
        arrowPart:PivotTo(arrowPart:GetPivot() + Vector3.new(0, offset, 0))
        
        -- Update text to show distance
        if textLabel and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (targetPos - player.Character.HumanoidRootPart.Position).Magnitude
            textLabel.Text = string.format("¡Sigue la flecha! (%d studs)", math.floor(distance))
        end
    end
end

function TutorialClient.Initialize()
    print("🎮 Initializing tutorial client...")
    
    -- Create arrow
    createArrow()
    
    -- Wait for remotes
    local TutorialRemotes = ReplicatedStorage:WaitForChild("TutorialRemotes", 10)
    if not TutorialRemotes then
        warn("❌ TutorialRemotes not found!")
        return
    end
    
    local ShowArrowEvent = TutorialRemotes:WaitForChild("ShowTutorialArrow", 5)
    local UpdateProgressEvent = TutorialRemotes:WaitForChild("UpdateTutorialProgress", 5)
    local ShowTextEvent = TutorialRemotes:WaitForChild("ShowTutorialText", 5)
    local HideAllEvent = TutorialRemotes:WaitForChild("HideTutorialElements", 5)
    
    if not (ShowArrowEvent and UpdateProgressEvent and ShowTextEvent and HideAllEvent) then
        warn("❌ Some tutorial events are missing!")
        return
    end
    
    -- Setup events
    ShowArrowEvent.OnClientEvent:Connect(function(target)
        print("🎯 Tutorial target received:", target)
        currentTarget = target
        
        -- Ensure arrow exists
        if not arrowPart or arrowPart.Parent == nil then
            createArrow()
        end
        
        if currentTarget then
            -- Make everything visible
            if textLabel then textLabel.Visible = true end
            if arrowPart then
                for _, part in pairs(arrowPart:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 0
                    end
                end
            end
            -- Start arrow update loop if not already running
            if not keepUpdating then
                keepUpdating = true
                task.spawn(function()
                    while keepUpdating and task.wait() do
                        updateArrowPosition()
                    end
                end)
            end
        else
            -- Hide tutorial elements
            if textLabel then textLabel.Visible = false end
            if arrowPart then arrowPart:Destroy() end
            keepUpdating = false
        end
    end)

    -- Progress bar
    UpdateProgressEvent.OnClientEvent:Connect(function(current, total)
        textLabel.Text = string.format("Poops recolectados: %d/%d", current, total)
        textLabel.Visible = true
        -- When reaching total, give a short delay then notify server that rebirth should be opened
        if current >= total then
            task.wait(0.6)
            local ActionEvent = TutorialRemotes:FindFirstChild("TutorialAction")
            if ActionEvent then
                ActionEvent:FireServer("CompletedPoops")
            end
        end
    end)

    ShowTextEvent.OnClientEvent:Connect(function(text)
        if not textLabel then return end
        textLabel.Text = text
        textLabel.Visible = true
    end)

    HideAllEvent.OnClientEvent:Connect(function()
        currentTarget = nil
        keepUpdating = false
        if textLabel then textLabel.Visible = false end
        if arrowPart then arrowPart:Destroy() end
    end)

    print("✅ Tutorial client initialized!")
end

return TutorialClient