-- CoinSpawner.luau
-- Spawns a coin near a random player every 10 seconds.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CoinSpawner = {}

local activeCoins = {}

local MAX_ACTIVE_COINS = 5
local MAP_HALF_SIZE = 100 -- spawn within -100..100 on X/Z (200x200 area)

local function linearMap(x, inMin, inMax, outMin, outMax)
    local t = (x - inMin) / math.max(1e-6, (inMax - inMin))
    return outMin + t * (outMax - outMin)
end

local function makeHighlight(model)
    local ok, highlight = pcall(function()
        local h = Instance.new("Highlight")
        h.FillColor = Color3.fromRGB(255, 215, 0)
        h.OutlineColor = Color3.fromRGB(255, 235, 130)
        h.FillTransparency = 0
        h.OutlineTransparency = 0
        h.Parent = model
        return h
    end)
    if not ok then warn("Couldn't create Highlight for coin") end
end

local function getFirstBasePart(model)
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then return v end
    end
    return nil
end

local function scaleModel(model, scale)
    -- Scale MeshParts via Mesh.Scale, scale Parts by Size
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("MeshPart") then
            if v:FindFirstChildWhichIsA("SpecialMesh") then
                local mesh = v:FindFirstChildWhichIsA("SpecialMesh")
                mesh.Scale = mesh.Scale * scale
            else
                v.Size = v.Size * scale
            end
        elseif v:IsA("BasePart") then
            v.Size = v.Size * scale
        end
    end
end

local function rotateLoop(basePart, speed)
    -- rotate around Y axis by updating CFrame of a BasePart
    if not basePart or not basePart:IsA("BasePart") then return nil end
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not basePart or not basePart.Parent then
            if conn then conn:Disconnect() end
            return
        end
        local cf = basePart.CFrame
        local ang = math.rad(speed * dt)
        basePart.CFrame = CFrame.new(cf.Position) * (cf - cf.Position) * CFrame.Angles(0, ang, 0)
    end)
    return conn
end

local function spawnCoin()
    local coinTemplate = Workspace:FindFirstChild("Coin")
    if not coinTemplate then
        warn("Coin template not found in workspace!")
        return
    end

    -- Respect maximum active coins
    -- Clean up any invalid entries first
    for i = #activeCoins, 1, -1 do
        if not activeCoins[i] or not activeCoins[i].Parent then
            table.remove(activeCoins, i)
        end
    end
    if #activeCoins >= MAX_ACTIVE_COINS then
        return
    end

    -- choose a random position anywhere in the map area (-MAP_HALF_SIZE..MAP_HALF_SIZE)
    local spawnPos = nil
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {}

    for attempt = 1, 10 do  -- Increased attempts to find better spots
        local rx = math.random(-MAP_HALF_SIZE, MAP_HALF_SIZE)
        local rz = math.random(-MAP_HALF_SIZE, MAP_HALF_SIZE)
        local startPos = Vector3.new(rx, 200, rz)
        local ray = Workspace:Raycast(startPos, Vector3.new(0, -400, 0), rayParams)
        if ray and ray.Position then
            local hitInst = ray.Instance
            local normal = ray.Normal
            -- Check if we hit terrain and if there's enough clearance above
            if hitInst and hitInst:IsA("Terrain") then
                -- Check for objects above the spawn point
                local clearanceCheck = Workspace:Raycast(
                    ray.Position + Vector3.new(0, 1, 0),  -- Start slightly above hit
                    Vector3.new(0, 6, 0),  -- Check 6 studs up
                    rayParams
                )
                -- Only spawn if we have clear space above (no trees or structures)
                if not clearanceCheck then
                    spawnPos = Vector3.new(rx, ray.Position.Y + 3, rz)
                    break
                end
            end
        end
    end

    -- fallback: accept any hit or a default low height
    if not spawnPos then
        local rx = math.random(-MAP_HALF_SIZE, MAP_HALF_SIZE)
        local rz = math.random(-MAP_HALF_SIZE, MAP_HALF_SIZE)
        local startPos = Vector3.new(rx, 200, rz)
        local ray = Workspace:Raycast(startPos, Vector3.new(0, -400, 0), rayParams)
        if ray and ray.Position then
            spawnPos = Vector3.new(rx, ray.Position.Y + 3, rz)
        else
            spawnPos = Vector3.new(rx, 5, rz)
        end
    end

    local coin = coinTemplate:Clone()
    coin.Name = "CoinPickup"

    -- Parent early so descendants exist in Workspace
    coin.Parent = Workspace

    -- Determine primary part (works for Model or BasePart clones)
    local primary = nil
    if coin:IsA("Model") then
        if coin.PrimaryPart then
            primary = coin.PrimaryPart
        else
            local p = getFirstBasePart(coin)
            if p then
                coin.PrimaryPart = p
                primary = p
            end
        end
    elseif coin:IsA("BasePart") then
        primary = coin
    end

    -- Value distribution:
    -- 95% chance: common coins between 5 and 50 (uniform)
    --  5% chance: rare coins between 51 and 5000 (skewed so very high values are rarer)
    local roll = math.random()
    local value
    if roll <= 0.95 then
        -- Common pool: uniform 5..50
        value = math.random(5, 50)
    else
        -- Rare pool: 51..5000, skewed towards lower rare values
        -- Use a power curve (r^3) to make very high values much less likely
        local r = math.random()
        local t = 1 - (r ^ 3)
        value = math.floor(51 + (5000 - 51) * t + 0.5)
        -- Small extra chance inside the rare pool for a true jackpot
        if math.random() < 0.005 then
            value = 5000
        end
    end
    coin:SetAttribute("CoinValue", value)

    -- Scale according to value: 5 -> 0.5, 5000 -> 6.0 (very large)
    local scale = linearMap(value, 5, 5000, 0.5, 6.0)
    pcall(function() scaleModel(coin, scale) end)

    -- Make coin visually golden / neon
    for _, part in ipairs(coin:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(255, 200, 50)
                part.Anchored = true
                part.CanCollide = false
            end)
        end
    end

    makeHighlight(coin)

    -- Position the coin
    if coin:IsA("Model") and primary then
        coin:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    elseif primary then
        primary.CFrame = CFrame.new(spawnPos)
    else
        -- fallback: try MoveTo on whatever we have
        pcall(function() coin:MoveTo(spawnPos) end)
    end

    -- Add a ProximityPrompt so players can collect
    if primary then
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Collect"
        prompt.ObjectText = "Coin"
        prompt.HoldDuration = 0.2
        prompt.MaxActivationDistance = 10
        prompt.Parent = primary

    local rotatingConn = rotateLoop(primary, 60) -- degrees per second

            local collectedConn
            collectedConn = prompt.Triggered:Connect(function(player)
            -- Award coins to player's leaderstats.Coins if present
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local coinsStat = leaderstats:FindFirstChild("Coins")
                if coinsStat and typeof(coinsStat.Value) == "number" then
                    coinsStat.Value = coinsStat.Value + value
                end
            end

            -- clean up
            if rotatingConn then rotatingConn:Disconnect() end
            if collectedConn then collectedConn:Disconnect() end
                -- remove from activeCoins
                for i = #activeCoins, 1, -1 do
                    if activeCoins[i] == coin then table.remove(activeCoins, i) end
                end
                coin:Destroy()
        end)
    end

    table.insert(activeCoins, coin)
end

function CoinSpawner.Start()
    task.spawn(function()
        while true do
            spawnCoin()
            task.wait(25)
        end
    end)
end

return CoinSpawner
