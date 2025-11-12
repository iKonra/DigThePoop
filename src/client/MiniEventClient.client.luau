-- MiniEventClient.client.luau
-- Listens for MiniEventStarted and shows a simple sky + rain effect that actually works client-side

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the MiniEvent remote
local miniEventRemote = ReplicatedStorage:WaitForChild("MiniEventStarted", 10)
if not miniEventRemote then
    warn("MiniEventStarted RemoteEvent not found in ReplicatedStorage")
    return
end

-- State
local gui = nil
local rainPart = nil
local originalSky = nil
local timerConnection = nil
local running = false

-- Assets requested by user
local SKY_ASSET = "rbxassetid://12376964583"
local RAIN_TEXTURE = "rbxassetid://15572844338"
-- Map coverage (user reported map ~500x500)
local MAP_SIZE = 500

-- Internal tracking for sky restoration
local originalSkyProperties = nil
local createdSky = false

-- Debug helper
-- Debug helper
local function safePrint(...)
    local args = { ... }
    local ok, err = pcall(function()
        print(table.unpack(args))
    end)
    if not ok then warn("MiniEventClient print error:", err) end
end

-- Create a simple top-center timer GUI that shows "xN EVENT — MM:SS"
local function createTimerGui()
    if gui and gui.Parent then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "MiniEventTimerGui"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Name = "EventTimer"
    label.Size = UDim2.new(0, 360, 0, 48)
    label.Position = UDim2.new(0.5, -180, 0, 16)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = Color3.fromRGB(40, 20, 10)
    label.BorderSizePixel = 0
    label.Font = Enum.Font.FredokaOne
    label.Text = "x3 EVENT — 05:00"
    label.TextColor3 = Color3.fromRGB(255, 230, 120)
    label.TextSize = IS_MOBILE and 18 or 22
    label.TextStrokeTransparency = 0
    label.ZIndex = 200
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label

    return label
end

-- Helper to create a client-only anchored part covering the map and add a ParticleEmitter
local function createRainAnchor()
    safePrint("MiniEventClient: creating rain anchor...")
    -- Destroy previous if exists
    if rainPart and rainPart.Parent then
        rainPart:Destroy()
        rainPart = nil
    end

    local ok, err = pcall(function()
        -- Make a large invisible part above the map; client-only instance sized to MAP_SIZE
        rainPart = Instance.new("Part")
        rainPart.Name = "MiniEventRainAnchor"
        rainPart.Anchored = true
        rainPart.CanCollide = false
        rainPart.Transparency = 1
        rainPart.Size = Vector3.new(MAP_SIZE, 2, MAP_SIZE)
        -- place high above so particles fall across the map
        local cam = workspace.CurrentCamera
        local baseY = 200
        if cam and cam.Focus and cam.Focus.p then
            baseY = cam.Focus.p.Y or 200
        end
        rainPart.CFrame = CFrame.new(0, baseY + 140, 0)
        rainPart.Parent = workspace

        -- Attachment for particles
        local attach = Instance.new("Attachment")
        attach.Parent = rainPart

        -- Particle emitter using requested texture
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "MiniEventRainEmitter"
        emitter.Texture = RAIN_TEXTURE
        -- Scale rate by map area so density feels consistent
        local areaScale = math.clamp((MAP_SIZE / 500), 0.5, 3)
        emitter.Rate = math.floor(200 * areaScale)
        emitter.Lifetime = NumberRange.new(1.2, 2.2)
        emitter.Speed = NumberRange.new(80, 140)
        emitter.VelocitySpread = 20
        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.2 * areaScale), NumberSequenceKeypoint.new(1, 2.2 * areaScale)})
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = NumberRange.new(0, 0)
        emitter.LightEmission = 0
        emitter.LockedToPart = false
        -- Apply downward acceleration so particles fall across the map
        emitter.Acceleration = Vector3.new(0, -400, 0)
        emitter.Parent = attach

        safePrint("MiniEventClient: emitter created; Texture=", emitter.Texture, "Rate=", emitter.Rate)
    end)

    if not ok then
        safePrint("MiniEventClient:createRainAnchor failed:", err)
    else
        safePrint("MiniEventClient: rain anchor created")
    end

    return rainPart
end

local function startSimpleEvent(duration, multiplier)
    if running then return end
    running = true
    safePrint("MiniEventClient: startSimpleEvent", duration, multiplier)

    -- Save/replace existing sky in-place (preferred) to avoid multiple Sky objects
    local existingSky = Lighting:FindFirstChildOfClass("Sky")
    if existingSky then
        -- store original properties so we can restore them later
        originalSkyProperties = {
            SkyboxBk = existingSky.SkyboxBk,
            SkyboxDn = existingSky.SkyboxDn,
            SkyboxFt = existingSky.SkyboxFt,
            SkyboxLf = existingSky.SkyboxLf,
            SkyboxRt = existingSky.SkyboxRt,
            SkyboxUp = existingSky.SkyboxUp,
        }
        createdSky = false
        local ok, err = pcall(function()
            existingSky.SkyboxBk = SKY_ASSET
            existingSky.SkyboxDn = SKY_ASSET
            existingSky.SkyboxFt = SKY_ASSET
            existingSky.SkyboxLf = SKY_ASSET
            existingSky.SkyboxRt = SKY_ASSET
            existingSky.SkyboxUp = SKY_ASSET
        end)
        if not ok then safePrint("MiniEventClient: failed to overwrite existing sky:", err) end
    else
        -- No existing sky -> create one and remember to delete it later
        local ok, err = pcall(function()
            local newSky = Instance.new("Sky")
            newSky.Name = "MiniEventSky"
            newSky.SkyboxBk = SKY_ASSET
            newSky.SkyboxDn = SKY_ASSET
            newSky.SkyboxFt = SKY_ASSET
            newSky.SkyboxLf = SKY_ASSET
            newSky.SkyboxRt = SKY_ASSET
            newSky.SkyboxUp = SKY_ASSET
            newSky.Parent = Lighting
        end)
        if not ok then safePrint("MiniEventClient: failed to create sky:", err) end
        createdSky = true
        originalSkyProperties = nil
    end

    -- Create rain anchor and emitter
    createRainAnchor()

    -- Create timer gui and update
    local label = createTimerGui()
    local endsAt = os.time() + duration
    if timerConnection then timerConnection:Disconnect() end
    timerConnection = RunService.Heartbeat:Connect(function()
        local remaining = math.max(0, endsAt - os.time())
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        if label and label.Parent then
            label.Text = string.format("x%d EVENT — %02d:%02d", multiplier or 1, minutes, seconds)
        end
    end)
end

local function stopSimpleEvent()
    safePrint("MiniEventClient: stopSimpleEvent")
    running = false
    -- restore sky
    if originalSkyProperties then
        local existing = Lighting:FindFirstChildOfClass("Sky")
        if existing then
            pcall(function()
                existing.SkyboxBk = originalSkyProperties.SkyboxBk
                existing.SkyboxDn = originalSkyProperties.SkyboxDn
                existing.SkyboxFt = originalSkyProperties.SkyboxFt
                existing.SkyboxLf = originalSkyProperties.SkyboxLf
                existing.SkyboxRt = originalSkyProperties.SkyboxRt
                existing.SkyboxUp = originalSkyProperties.SkyboxUp
            end)
        end
        originalSkyProperties = nil
    else
        -- if we created the sky instance, remove it
        local miniSky = Lighting:FindFirstChild("MiniEventSky")
        if miniSky then miniSky:Destroy() end
    end

    -- destroy rain part
    if rainPart and rainPart.Parent then
        rainPart:Destroy()
        rainPart = nil
    end

    -- destroy gui
    if gui and gui.Parent then
        gui:Destroy()
        gui = nil
    end

    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
end

miniEventRemote.OnClientEvent:Connect(function(eventName, isStarting, duration, multiplier)
    duration = duration or 60 * 5
    multiplier = multiplier or 1
    if isStarting then
        startSimpleEvent(duration, multiplier)
    else
        stopSimpleEvent()
    end
end)

safePrint("MiniEventClient loaded: simple sky+rain event listener")
