-- MiniEventManager.luau
-- Handles server-wide mini-events (Poop Rain)

local MiniEventManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- RemoteEvent to notify clients about event start/stop
local miniEventRemote = Instance.new("RemoteEvent")
miniEventRemote.Name = "MiniEventStarted"
miniEventRemote.Parent = ReplicatedStorage

-- Internal state
local active = false
local currentEvent = nil
local multiplier = 1
local endsAt = 0

-- Configuration
local DEFAULT_DURATION = 60 * 5 -- 5 minutes
local POOP_RAIN_MULTIPLIER = 3

-- Server world-effect state
local effectsFolderName = "MiniEventEffects"
local effectsInstances = {}

-- Try to read map size from Config if available
local MAP_SIZE = 500
do
    local ok, Config = pcall(function() return require(script.Parent.Config) end)
    if ok and Config and Config.Terrain and Config.Terrain.TerrainSize then
        MAP_SIZE = Config.Terrain.TerrainSize
    end
end

-- Utility: clear any previously spawned world effects
local function clearWorldEffects()
    for _, inst in ipairs(effectsInstances) do
        if inst and inst.Parent then
            pcall(function() inst:Destroy() end)
        end
    end
    effectsInstances = {}
    local folder = workspace:FindFirstChild(effectsFolderName)
    if folder then
        pcall(function() folder:Destroy() end)
    end
end

-- Spawn server-side decorative effects so all players see them
local function spawnWorldEffects(duration)
    clearWorldEffects()

    local root = Instance.new("Folder")
    root.Name = effectsFolderName
    root.Parent = workspace
    table.insert(effectsInstances, root)

    -- Create a bunch of rainbow trees using existing Tree model if available
    local treeCount = 20
    -- look for a tree template in workspace or ServerStorage
    local treeTemplate = workspace:FindFirstChild("tree wood")
        or workspace:FindFirstChild("Tree Wood")
        or workspace:FindFirstChild("TreeWood")
        or workspace:FindFirstChild("Tree")
        or workspace:FindFirstChild("TreeModel")
        or workspace:FindFirstChild("TreeTemplate")
    if not treeTemplate then
        local ss = game:GetService("ServerStorage")
        treeTemplate = ss:FindFirstChild("tree wood")
            or ss:FindFirstChild("Tree Wood")
            or ss:FindFirstChild("TreeWood")
            or ss:FindFirstChild("Tree")
            or ss:FindFirstChild("TreeModel")
            or ss:FindFirstChild("TreeTemplate")
    end

    for i = 1, treeCount do
        local x = (math.random() - 0.5) * MAP_SIZE
        local z = (math.random() - 0.5) * MAP_SIZE
        local y = 6

        if treeTemplate and treeTemplate:IsA("Model") then
            local ok, treeClone = pcall(function() return treeTemplate:Clone() end)
            if ok and treeClone then
                treeClone.Name = "MiniEventTree"
                -- try to position using PrimaryPart if available
                if treeClone.PrimaryPart then
                    treeClone:SetPrimaryPartCFrame(CFrame.new(Vector3.new(x, y, z)))
                else
                    -- attempt to move first BasePart
                    local firstPart = treeClone:FindFirstChildWhichIsA("BasePart")
                    if firstPart then
                        firstPart.CFrame = CFrame.new(Vector3.new(x, y, z))
                    end
                end
                -- recolor canopy parts (non-destructive)
                local hue = (i / treeCount)
                for _, part in ipairs(treeClone:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name:lower():find("leaf") or part.Name:lower():find("canopy") then
                        pcall(function()
                            part.Color = Color3.fromHSV(hue, 0.9, 0.95)
                            part.Material = Enum.Material.Neon
                        end)
                    end
                end
                -- add a rainbow aura emitter attached to the tree's primary part (visual contour)
                pcall(function()
                    local attachTarget = treeClone.PrimaryPart or treeClone:FindFirstChildWhichIsA("BasePart")
                    if attachTarget then
                        local attach = Instance.new("Attachment")
                        attach.Name = "MiniEventAuraAttach"
                        attach.Parent = attachTarget

                        local aura = Instance.new("ParticleEmitter")
                        aura.Name = "RainbowAura"
                        aura.Texture = "rbxassetid://284205403" -- small sparkle texture fallback
                        aura.Rate = 40
                        aura.Lifetime = NumberRange.new(0.8, 1.4)
                        aura.Speed = NumberRange.new(0.5, 2)
                        aura.SpreadAngle = Vector2.new(360, 360)
                        aura.Size = NumberSequence.new(0.5)
                        aura.LightEmission = 0.8
                        aura.LockedToPart = true
                        aura.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(0.0, 1, 1)),
                            ColorSequenceKeypoint.new(0.25, Color3.fromHSV(0.2, 1, 1)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.45, 1, 1)),
                            ColorSequenceKeypoint.new(0.75, Color3.fromHSV(0.7, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(0.95, 1, 1)),
                        })
                        aura.Parent = attach
                        table.insert(effectsInstances, attach)
                        table.insert(effectsInstances, aura)
                    end
                end)
                treeClone.Parent = root
                table.insert(effectsInstances, treeClone)
            end
        else
            -- fallback: spawn simple neon spheres as canopies
            local canopy = Instance.new("Part")
            canopy.Name = "RainbowCanopy"
            canopy.Anchored = true
            canopy.CanCollide = false
            canopy.Shape = Enum.PartType.Ball
            canopy.Size = Vector3.new(6, 6, 6)
            canopy.Position = Vector3.new(x, y + 4, z)
            local hue = (i / treeCount)
            canopy.Color = Color3.fromHSV(hue, 0.9, 0.95)
            canopy.Material = Enum.Material.Neon
            canopy.Parent = root
            table.insert(effectsInstances, canopy)
        end
    end

    -- Spawn magical pillars (neon columns) around the map center
    local pillarCount = 6
    local TweenService = game:GetService("TweenService")
    for i = 1, pillarCount do
        local angle = (i / pillarCount) * math.pi * 2
        local radius = MAP_SIZE * 0.35
        local px = math.cos(angle) * radius
        local pz = math.sin(angle) * radius
        local pillar = Instance.new("Part")
        pillar.Name = "MagicPillar"
        pillar.Anchored = true
        pillar.CanCollide = false
        pillar.Size = Vector3.new(4, 40, 4)
        pillar.Position = Vector3.new(px, 20, pz)
        pillar.Material = Enum.Material.Neon
        pillar.Color = Color3.fromHSV((i / pillarCount), 0.9, 0.9)
        pillar.Parent = root
        table.insert(effectsInstances, pillar)

        local pLight = Instance.new("PointLight")
        pLight.Color = pillar.Color
        pLight.Range = MAP_SIZE * 0.8
        pLight.Brightness = 2
        pLight.Parent = pillar
        table.insert(effectsInstances, pLight)

        -- Tween color pulse
        spawn(function()
            while active and pillar.Parent do
                local t1 = TweenService:Create(pillar, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2})
                local t2 = TweenService:Create(pillar, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8})
                t1:Play()
                t1.Completed:Wait()
                t2:Play()
                t2.Completed:Wait()
            end
        end)
    end

    -- Create a few world-space rain emitters (server-side) to make rain visible to all
    local emitterPositions = { Vector3.new(0, 120, 0) }
    -- spread in quadrants for coverage
    local half = MAP_SIZE / 2
    table.insert(emitterPositions, Vector3.new(half, 120, half))
    table.insert(emitterPositions, Vector3.new(-half, 120, half))
    table.insert(emitterPositions, Vector3.new(half, 120, -half))
    table.insert(emitterPositions, Vector3.new(-half, 120, -half))

    for idx, pos in ipairs(emitterPositions) do
        local p = Instance.new("Part")
        p.Name = "MiniEventRainEmitterPart"
        p.Anchored = true
        p.CanCollide = false
        p.Transparency = 1
        p.Size = Vector3.new(2,2,2)
        p.Position = pos
        p.Parent = root
        table.insert(effectsInstances, p)

        local attach = Instance.new("Attachment")
        attach.Parent = p
        table.insert(effectsInstances, attach)

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ServerPoopRain"
        emitter.Texture = "rbxassetid://15572844338"
        emitter.Rate = 300
        emitter.Lifetime = NumberRange.new(1.5, 2.5)
        emitter.Speed = NumberRange.new(100, 160)
        emitter.VelocitySpread = 30
        emitter.Size = NumberSequence.new(2.5)
        emitter.LockedToPart = false
        emitter.Acceleration = Vector3.new(0, -600, 0)
        emitter.Parent = attach
        table.insert(effectsInstances, emitter)
    end

    -- central beacon (visible marker)
    local beacon = Instance.new("Part")
    beacon.Name = "MiniEventBeacon"
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.Size = Vector3.new(6, 60, 6)
    beacon.Position = Vector3.new(0, 30, 0)
    beacon.Material = Enum.Material.Neon
    beacon.Color = Color3.fromRGB(255, 120, 0)
    beacon.Parent = root
    table.insert(effectsInstances, beacon)

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 180, 60)
    light.Range = MAP_SIZE
    light.Brightness = 4
    light.Parent = beacon
    table.insert(effectsInstances, light)

    -- Schedule cleanup after duration
    spawn(function()
        wait(duration or DEFAULT_DURATION)
        clearWorldEffects()
    end)
end

-- Start a Poop Rain event
local function startPoopRain(duration)
    if active then return false end
    active = true
    currentEvent = "PoopRain"
    multiplier = POOP_RAIN_MULTIPLIER
    endsAt = os.time() + (duration or DEFAULT_DURATION)

    -- Notify all clients
    miniEventRemote:FireAllClients(currentEvent, true, duration or DEFAULT_DURATION, multiplier)

    -- Spawn server-visible world effects
    pcall(function()
        spawnWorldEffects(duration or DEFAULT_DURATION)
    end)

    -- End the event after duration
    spawn(function()
        wait(duration or DEFAULT_DURATION)
        active = false
        currentEvent = nil
        multiplier = 1
        endsAt = 0
        miniEventRemote:FireAllClients("PoopRain", false)
        -- ensure world effects cleared
        pcall(function() clearWorldEffects() end)
    end)

    return true
end

-- Try to trigger an event (called when a player clears a poop). Returns true if event started.
function MiniEventManager.TryTrigger(player, probability, duration)
    probability = probability or 0.5
    duration = duration or DEFAULT_DURATION

    if active then
        return false
    end

    if math.random() < probability then
        return startPoopRain(duration)
    end

    return false
end

function MiniEventManager.IsActive()
    return active
end

function MiniEventManager.GetMultiplier()
    return multiplier or 1
end

function MiniEventManager.GetCurrentEvent()
    return currentEvent
end

function MiniEventManager.GetTimeRemaining()
    if not active then return 0 end
    return math.max(0, endsAt - os.time())
end

return MiniEventManager
