print("Hello world, from client!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- Setup welcome message handler
local WelcomeEvent = ReplicatedStorage:WaitForChild("WelcomeMessageEvent")

WelcomeEvent.OnClientEvent:Connect(function()
    -- Create ScreenGui for welcome message
    local welcomeGui = Instance.new("ScreenGui")
    welcomeGui.Name = "WelcomeMessage"
    welcomeGui.ResetOnSpawn = false
    welcomeGui.IgnoreGuiInset = true
    welcomeGui.Parent = playerGui
    
    -- Create main welcome text
    local welcomeText = Instance.new("TextLabel")
    welcomeText.Name = "WelcomeText"
    welcomeText.Size = UDim2.new(0, 600, 0, 100)
    welcomeText.Position = UDim2.new(0.5, -300, 0.3, 0)
    welcomeText.BackgroundTransparency = 1
    welcomeText.Text = "Welcome!"
    welcomeText.Font = Enum.Font.FredokaOne
    welcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    welcomeText.TextSize = 72
    welcomeText.TextTransparency = 1
    welcomeText.Parent = welcomeGui
    
    -- Create instruction text
    local instructionText = Instance.new("TextLabel")
    instructionText.Name = "InstructionText"
    instructionText.Size = UDim2.new(0, 400, 0, 50)
    instructionText.Position = UDim2.new(0.5, -200, 0.4, 0)
    instructionText.BackgroundTransparency = 1
    instructionText.Text = "Mine a shovel to start!"
    instructionText.Font = Enum.Font.GothamBold
    instructionText.TextColor3 = Color3.fromRGB(255, 220, 100)
    instructionText.TextSize = 24
    instructionText.TextTransparency = 1
    instructionText.Parent = welcomeGui
    
    -- Animation sequence
    task.spawn(function()
        -- Fade in welcome text with bounce effect
        welcomeText.Size = UDim2.new(0, 0, 0, 100)
        welcomeText.TextTransparency = 0
        
        local welcomeTween = TweenService:Create(
            welcomeText,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 600, 0, 100)}
        )
        welcomeTween:Play()
        
        -- Rainbow color animation for welcome text
        task.spawn(function()
            for i = 1, 20 do
                welcomeText.TextColor3 = Color3.fromHSV(i/20, 1, 1)
                task.wait(0.1)
            end
        end)
        
        -- Wait and fade in instruction text
        task.wait(0.5)
        TweenService:Create(
            instructionText,
            TweenInfo.new(0.5),
            {TextTransparency = 0}
        ):Play()
        
        -- Subtle bounce animation for instruction text
        while welcomeGui.Parent do
            TweenService:Create(
                instructionText,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = UDim2.new(0.5, -200, 0.4, -10)}
            ):Play()
            task.wait(0.8)
            TweenService:Create(
                instructionText,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = UDim2.new(0.5, -200, 0.4, 0)}
            ):Play()
            task.wait(0.8)
        end
    end)
    
    -- Remove after 5 seconds with fade out
    task.delay(5, function()
        local fadeOut = TweenService:Create(
            welcomeGui,
            TweenInfo.new(1),
            {BackgroundTransparency = 1}
        )
        fadeOut:Play()
        
        TweenService:Create(welcomeText, TweenInfo.new(1), {TextTransparency = 1}):Play()
        TweenService:Create(instructionText, TweenInfo.new(1), {TextTransparency = 1}):Play()
        
        task.wait(1)
        welcomeGui:Destroy()
    end)
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create LoadingScreen
local function createLoadingScreen()
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "LoadingScreen"
    loadingGui.IgnoreGuiInset = true
    loadingGui.DisplayOrder = 999
    loadingGui.Parent = playerGui
    
    -- Background with gradient
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    background.BorderSizePixel = 0
    background.Parent = loadingGui

    -- Gradient para el fondo
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 30, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 20, 50))
    })
    gradient.Parent = background

    -- Animación del gradiente
    spawn(function()
        local rotation = 0
        while true do
            rotation = rotation + 1
            gradient.Rotation = rotation
            task.wait(0.05)
        end
    end)

    -- Partículas de fondo (burbujas/estrellas)
    for i = 1, 20 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromRGB(
            math.random(200, 255),
            math.random(200, 255),
            math.random(200, 255)
        )
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle

        particle.Parent = background

        -- Animación de las partículas
        spawn(function()
            while true do
                local randomTime = math.random(3, 6)
                local newY = math.random() * -1.5
                
                TweenService:Create(particle, TweenInfo.new(randomTime, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(particle.Position.X.Scale, 0, newY, 0)
                }):Play()
                
                task.wait(randomTime)
                particle.Position = UDim2.new(math.random(), 0, 1, 0)
            end
        end)
    end
    
	-- NOTE: Forzar orientación via SetCore PreferredOrientation causa errores en muchos clientes
	-- StarterGui:SetCore("PreferredOrientation", ...) no está registrado en CoreScripts en algunas plataformas.
	-- En lugar de forzar orientación, manejamos el layout de forma responsiva (AnchorPoint / tamaños relativos).
	-- (Anterior llamada removida para evitar SetCore errors)

    -- Container para las letras animadas
    local titleContainer = Instance.new("Frame")
    titleContainer.Name = "TitleContainer"
    titleContainer.Size = UDim2.new(0, 800, 0, 150)
	-- Slight left shift to better center title visually; small pixel tweak
	titleContainer.Position = UDim2.new(0.5, -440, 0.3, 0)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = loadingGui

    -- Colores divertidos para cada letra
    local colors = {
        Color3.fromRGB(255, 100, 200),  -- Rosa
        Color3.fromRGB(100, 200, 255),  -- Azul claro
        Color3.fromRGB(150, 255, 100),  -- Verde lima
        Color3.fromRGB(255, 200, 100),  -- Naranja
        Color3.fromRGB(200, 100, 255),  -- Púrpura
        Color3.fromRGB(255, 255, 100),  -- Amarillo
        Color3.fromRGB(255, 150, 150),  -- Coral
        Color3.fromRGB(100, 255, 200),  -- Turquesa
        Color3.fromRGB(255, 100, 100),  -- Rojo claro
        Color3.fromRGB(150, 150, 255)   -- Azul lavanda
    }

    local letters = {"D", "i", "g", " ", "T", "h", "e", " ", "P", "o", "o", "p"}
    local letterLabels = {}
    
    -- Crear cada letra individual con su propio estilo
    for i, letter in ipairs(letters) do
        local letterLabel = Instance.new("TextLabel")
	letterLabel.Name = "Letter_" .. i
	letterLabel.Size = UDim2.new(0, 70, 0, 100)
	letterLabel.Position = UDim2.new(0, (i-1) * 60 + 60, 0, math.sin(i) * 10) -- Ajuste adicional: -20px más para mover a la izquierda
	letterLabel.BackgroundTransparency = 1
	letterLabel.Font = Enum.Font.GothamBlack
	letterLabel.Text = letter
	letterLabel.TextSize = IS_MOBILE and 60 or 80
        letterLabel.TextColor3 = colors[((i-1) % #colors) + 1]
        letterLabel.Parent = titleContainer
        
        -- Añadir stroke para hacer las letras más llamativas
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 3
        stroke.Parent = letterLabel
        
        -- Añadir sombra para profundidad
        local shadow = Instance.new("TextLabel")
        shadow.Size = UDim2.new(1, 0, 1, 0)
        shadow.Position = UDim2.new(0, 2, 0, 2)
        shadow.BackgroundTransparency = 1
        shadow.Font = letterLabel.Font
        shadow.Text = letter
        shadow.TextSize = letterLabel.TextSize
        shadow.TextColor3 = Color3.fromRGB(40, 40, 40)
        shadow.ZIndex = letterLabel.ZIndex - 1
        shadow.Parent = letterLabel
        
        table.insert(letterLabels, letterLabel)
        
        -- Animación de rebote para cada letra
        spawn(function()
            local offset = i * 0.1
            while true do
                local y = 10 * math.sin(time() * 2 + offset)
                local rotation = 5 * math.sin(time() * 3 + offset)
                local scale = 1 + 0.1 * math.sin(time() * 4 + offset)
                
                TweenService:Create(letterLabel, TweenInfo.new(0.1), {
                    Position = UDim2.new(0, (i-1) * 60 + 100, 0, y),
                    Rotation = rotation,
                    Size = UDim2.new(0, 70 * scale, 0, 100 * scale)
                }):Play()
                
                task.wait(0.03)
            end
        end)
    end
    
    -- Progress Bar Container with fancy style
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(0, 600, 0, 40)
    progressContainer.Position = UDim2.new(0.5, -300, 0.6, 0)
    progressContainer.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = loadingGui

    -- Esquinas redondeadas para el contenedor
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0.3, 0)
    containerCorner.Parent = progressContainer

    -- Stroke para el contenedor
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(255, 255, 255)
    containerStroke.Thickness = 2
    containerStroke.Transparency = 0.7
    containerStroke.Parent = progressContainer
    
    -- Progress Bar con gradiente
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressContainer

    -- Esquinas redondeadas para la barra
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0.3, 0)
    barCorner.Parent = progressBar

    -- Gradiente para la barra de progreso
    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
    })
    barGradient.Parent = progressBar
	barGradient.Parent = progressBar

	-- Animación del gradiente (shimmer contínuo)
	spawn(function()
		local rotation = 0
		while progressBar.Parent do
			rotation = rotation + 2
			barGradient.Rotation = rotation
			task.wait(0.03)
		end
	end)

	-- Emblem removed per user request

	-- Add cobwebs in corners (Halloween decoration)
	local function createCobweb(position)
		local web = Instance.new("TextLabel")
		web.Size = UDim2.new(0, 100, 0, 100)
		web.Position = position
		web.BackgroundTransparency = 1
		web.Text = "🕸️"
		web.TextSize = 80
		web.TextTransparency = 0.2
		web.Rotation = math.random(-15, 15)
		web.ZIndex = 110
		web.Parent = background
	end

	-- Add cobwebs to corners
	createCobweb(UDim2.new(0, -20, 0, -20))  -- Top left
	createCobweb(UDim2.new(1, -80, 0, -20))   -- Top right
	createCobweb(UDim2.new(0, -20, 1, -80))   -- Bottom left
	createCobweb(UDim2.new(1, -80, 1, -80))   -- Bottom right

	-- Halloween falling elements (emojis)
	local halloweenEmojis = {"🎁", "💩", "🎃", "👻", "🕷️", "🍬"}
	for i = 1, 20 do
		local element = Instance.new("TextLabel")
		element.Size = UDim2.new(0, 40, 0, 40)
		element.Position = UDim2.new(math.random(), 0, -0.2 - math.random() * 0.5, 0)
		element.BackgroundTransparency = 1
		element.Text = halloweenEmojis[math.random(1, #halloweenEmojis)]
		element.TextSize = math.random(30, 45)
		element.TextTransparency = 0.1
		element.Rotation = math.random(-25, 25)
		element.ZIndex = 120
		element.Parent = background

		-- Add shadow effect
		local shadow = Instance.new("TextLabel")
		shadow.Size = UDim2.new(1, 0, 1, 0)
		shadow.Position = UDim2.new(0, 2, 0, 2)
		shadow.BackgroundTransparency = 1
		shadow.Text = element.Text
		shadow.TextSize = element.TextSize
		shadow.TextColor3 = Color3.fromRGB(0, 0, 0)
		shadow.TextTransparency = 0.5
		shadow.Rotation = 0
		shadow.ZIndex = 119
		shadow.Parent = element

		spawn(function()
			while element and element.Parent do
				local fallTime = math.random(4, 8)  -- Slower fall for spookier effect
				local wiggle = math.random(-50, 50)  -- Side-to-side movement
				
				TweenService:Create(element, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), {
					Position = UDim2.new(element.Position.X.Scale + wiggle/1000, 0, 1.2, 0),
					Rotation = element.Rotation + math.random(-180, 180)
				}):Play()
				
				if shadow then
					shadow.Rotation = element.Rotation
				end
				
				task.wait(fallTime)
				element.Position = UDim2.new(math.random(), 0, -0.2, 0)
			end
		end)
	end

	-- Confetti / streamers for fun
	for i = 1, 30 do
		local conf = Instance.new("Frame")
		conf.Size = UDim2.new(0, math.random(6, 12), 0, math.random(12, 24))
		conf.Position = UDim2.new(math.random(), 0, -0.2 - math.random() * 0.5, 0)
		conf.BackgroundColor3 = Color3.fromRGB(math.random(80,255), math.random(80,255), math.random(80,255))
		conf.BorderSizePixel = 0
		conf.Rotation = math.random(-25,25)
		conf.ZIndex = 120
		local confCorner = Instance.new("UICorner")
		confCorner.CornerRadius = UDim.new(0, 4)
		confCorner.Parent = conf
		conf.Parent = background
		spawn(function()
			while conf and conf.Parent do
				local fallTime = math.random(3,6)
				TweenService:Create(conf, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), {Position = UDim2.new(conf.Position.X.Scale, 0, 1.2, 0), Rotation = conf.Rotation + math.random(-90,90)}):Play()
				task.wait(fallTime)
				conf.Position = UDim2.new(math.random(), 0, -0.2, 0)
			end
		end)
	end

	-- Tips / micro copy rotating under the bar
	local tips = {
		"Tip: Double-tap to dash!",
		"Pro tip: Sell poops near the shop for bonus coins.",
		"Did you know? Pets gather poops automatically.",
		"Collect special poops for rare rewards!",
		"Try upgrading your shovel to dig farther."
	}
	local tipLabel = Instance.new("TextLabel")
	tipLabel.Name = "TipLabel"
	tipLabel.Size = UDim2.new(0, 600, 0, 30)
	tipLabel.Position = UDim2.new(0.5, -300, 0.75, 0)
	tipLabel.BackgroundTransparency = 1
	tipLabel.Font = Enum.Font.GothamBold
	tipLabel.Text = tips[1]
	tipLabel.TextColor3 = Color3.fromRGB(255, 117, 24) -- Halloween orange
	tipLabel.TextSize = 18
	tipLabel.TextTransparency = 0.2
	tipLabel.ZIndex = 160
	tipLabel.Parent = loadingGui
	spawn(function()
		local idx = 1
		while tipLabel and tipLabel.Parent do
			idx = idx % #tips + 1
			local newText = tips[idx]
			TweenService:Create(tipLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
			task.wait(0.35)
			tipLabel.Text = newText
			TweenService:Create(tipLabel, TweenInfo.new(0.3), {TextTransparency = 0.2}):Play()
			task.wait(3.0)
		end
	end)

	-- Shimmer effect removed per user request

	-- Loading Text con estilo
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(0, 400, 0, 40)
    loadingText.Position = UDim2.new(0.5, -200, 0.7, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Font = Enum.Font.GothamBlack
	loadingText.Text = "🎃 ¡Preparando la Diversión! 👻"
	loadingText.TextColor3 = Color3.fromRGB(255, 140, 0)  -- Halloween orange
    loadingText.TextSize = IS_MOBILE and 22 or 28
    loadingText.Parent = loadingGui

    -- Stroke para el texto
    local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(139, 69, 19)  -- Dark orange / brown
    textStroke.Thickness = 2
    textStroke.Parent = loadingText

    -- Animación del texto
    spawn(function()
        local originalSize = loadingText.TextSize
        while loadingText.Parent do
            local scale = 1 + 0.1 * math.sin(time() * 3)
            loadingText.TextSize = originalSize * scale
            task.wait(0.03)
        end
    end)
    
	-- Return also titleContainer and progressContainer so callers can control them on fade-out
	return loadingGui, progressBar, loadingText, titleContainer, progressContainer
end

-- Sistema de carga inicial
local function startLoading()
	local loadingGui, progressBar, loadingText, titleContainer, progressContainer = createLoadingScreen()
    local totalAssets = 0
    local loadedAssets = 0

    -- Asegurarnos de que la pantalla de carga sea lo último en desaparecer
    local function fadeOutLoadingScreen()
	-- Primero desvanecemos el título, la barra de progreso y elementos decorativos
	local uiElements = {loadingText, progressContainer, titleContainer, loadingGui:FindFirstChild("Emblem"), loadingGui:FindFirstChild("TipLabel")}
        for _, element in ipairs(uiElements) do
            if element then
                local fadeOut = TweenService:Create(element, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1
                })
                fadeOut:Play()
                
                -- Para elementos con texto
                if element:IsA("TextLabel") then
                    TweenService:Create(element, TweenInfo.new(0.5), {
                        TextTransparency = 1
                    }):Play()
                end
                
                -- Para elementos con UIStroke
                local stroke = element:FindFirstChild("UIStroke")
                if stroke then
                    TweenService:Create(stroke, TweenInfo.new(0.5), {
                        Transparency = 1
                    }):Play()
                end
            end
        end

        -- Después de que se desvanezcan los elementos, desvanecemos el fondo
        task.wait(0.5)
        local fadeOutBackground = TweenService:Create(background, TweenInfo.new(0.5), {
            BackgroundTransparency = 1
        })
        fadeOutBackground:Play()
        
        -- Finalmente, eliminamos la GUI
        fadeOutBackground.Completed:Connect(function()
            task.wait(0.1)
            loadingGui:Destroy()
            
			-- NOTE: Restaurar PreferredOrientation fue removido; confiamos en layout responsivo.
			-- (Anterior llamada a StarterGui:SetCore("PreferredOrientation", "Portrait") eliminada)
        end)
    end
    
    -- Precargar todas las texturas del Workspace
    local assets = {}
    local function getAssets(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("BasePart") or child:IsA("Decal") or child:IsA("Texture") then
                table.insert(assets, child)
            end
        end
    end
    
    getAssets(workspace)
    totalAssets = #assets
    
    -- Función para actualizar la barra de progreso
    local function updateProgress()
        loadedAssets += 1
        local progress = loadedAssets / totalAssets
        local progressTween = TweenService:Create(progressBar, 
            TweenInfo.new(0.2), 
            {Size = UDim2.new(progress, 0, 1, 0)}
        )
        progressTween:Play()
		loadingText.Text = string.format("Cargando... (%d%%)", math.floor(progress * 100))

		-- Emblem and particles removed per user request
    end
    
    -- Precargar assets
    ContentProvider:PreloadAsync(assets, updateProgress)
    
    return loadingGui
end

-- Iniciar el sistema de carga
local loadingScreen = startLoading()

    -- Esperar a que todo esté listo (mínimo 5 segundos garantizados)
    local startTime = os.time()
    task.wait(2) -- Espera inicial de 2s
    
    -- Asegurar que al menos pasen 5 segundos totales
    local elapsedTime = os.time() - startTime
    if elapsedTime < 5 then
        task.wait(5 - elapsedTime)
    end-- Función para remover la pantalla de carga
local function removeLoadingScreen()
    if loadingScreen then
        local background = loadingScreen.Background
        local fadeOut = TweenService:Create(background,
            TweenInfo.new(1),
            {BackgroundTransparency = 1}
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            loadingScreen:Destroy()
        end)
    end
end

-- Esperar a que los sistemas críticos estén listos
local function waitForCriticalSystems()
    -- Esperar eventos importantes
    local events = {
        "ShowPoopClearedEvent",
        "PurchaseShovelUpgradeEvent",
        "ShowUpgradeSuccessEvent",
        "ShowWarningEvent"
    }
    
    for _, eventName in ipairs(events) do
        ReplicatedStorage:WaitForChild(eventName, 10)
    end
    
    -- Esperar leaderstats
    local leaderstats = player:WaitForChild("leaderstats", 10)
    if leaderstats then
        leaderstats:WaitForChild("Coins", 5)
        leaderstats:WaitForChild("Poops Cleared", 5)
    end
    
    -- Esperar character
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- Asegurar que el terreno esté cargado
    workspace:WaitForChild("Terrain", 10)
end

    -- Esperar sistemas y luego quitar la pantalla de carga
local function initializeGame()
    print("🎮 Waiting for critical systems...")
    waitForCriticalSystems()
    
    -- Esperar a que haya al menos 3 poops en el workspace
    print("🎮 Waiting for initial poops to spawn...")
    local startWait = os.time()
    local maxWaitTime = 10 -- máximo 10 segundos de espera
    
    repeat
        local poops = workspace:GetChildren()
        local poopCount = 0
        for _, obj in ipairs(poops) do
            if obj.Name == "Poop" then
                poopCount = poopCount + 1
                if poopCount >= 3 then 
                    print("🎮 Found", poopCount, "poops")
                    break 
                end
            end
        end
        if poopCount >= 3 then break end
        task.wait(0.5)
    until os.time() - startWait > maxWaitTime
    
    print("🎮 Removing loading screen...")
    removeLoadingScreen()
    
	-- After loading screen is removed, wait a moment then start tutorial
	print("🎮 Starting tutorial setup...")
	task.wait(1)
    
    -- Ensure RemoteEvents exist
    local TutorialRemotes = ReplicatedStorage:WaitForChild("TutorialRemotes", 5)
    if not TutorialRemotes then
        TutorialRemotes = Instance.new("Folder")
        TutorialRemotes.Name = "TutorialRemotes"
        TutorialRemotes.Parent = ReplicatedStorage
        print("⚠️ Created TutorialRemotes folder")
    end
    
    local ShowArrowEvent = TutorialRemotes:WaitForChild("ShowTutorialArrow", 5)
    local UpdateProgressEvent = TutorialRemotes:WaitForChild("UpdateTutorialProgress", 5)
    local ShowTextEvent = TutorialRemotes:WaitForChild("ShowTutorialText", 5)
    
    if not (ShowArrowEvent and UpdateProgressEvent and ShowTextEvent) then
        warn("⚠️ Some tutorial remotes are missing!")
    end
end

-- Iniciar el juego en un spawn separado
task.spawn(initializeGame)

-- Try to locate the TutorialClient module in several common places and initialize it
local function findTutorialModule()
		local candidates = {}

		-- 1) Module as sibling in the client scripts folder
		table.insert(candidates, script.Parent and script.Parent:FindFirstChild("TutorialClient"))
		table.insert(candidates, script.Parent and script.Parent:FindFirstChild("TutorialClient.luau"))

		-- 2) Directly in ReplicatedStorage (common placement)
		table.insert(candidates, ReplicatedStorage:FindFirstChild("TutorialClient"))

		-- 3) Under ReplicatedStorage.GameModules.Client.TutorialClient
		local gm = ReplicatedStorage:FindFirstChild("GameModules")
		if gm then
			local clientFolder = gm:FindFirstChild("Client")
			if clientFolder then
				table.insert(candidates, clientFolder:FindFirstChild("TutorialClient"))
			end
			table.insert(candidates, gm:FindFirstChild("TutorialClient"))
		end

		-- 4) As a child of PlayerScripts ancestor (unlikely but harmless)
		local playerScripts = script:FindFirstAncestor("PlayerScripts")
		if playerScripts then
			table.insert(candidates, playerScripts:FindFirstChild("TutorialClient"))
		end

		for _, cand in ipairs(candidates) do
			if cand and cand:IsA("ModuleScript") then
				return cand
			end
		end
		return nil
	end

	local success, err = pcall(function()
		local moduleInstance = findTutorialModule()
		if moduleInstance then
			local TutorialClient = require(moduleInstance)
			if TutorialClient and type(TutorialClient.Initialize) == "function" then
				print("Initializing tutorial client from module:", moduleInstance:GetFullName())
				TutorialClient.Initialize()
			else
				warn("Found TutorialClient module but it has no Initialize() function")
			end
		else
			-- Fallback: inline a lightweight TutorialClient implementation so the tutorial can be tested
			print("TutorialClient not found — using inline fallback implementation")
			local TutorialClient = {}
			local TutorialRemotes = ReplicatedStorage:FindFirstChild("TutorialRemotes")
			if not TutorialRemotes then
				-- If server hasn't created the remotes, create client-side placeholders to avoid errors
				TutorialRemotes = Instance.new("Folder")
				TutorialRemotes.Name = "TutorialRemotes"
				TutorialRemotes.Parent = ReplicatedStorage
			end
			local ShowArrowEvent = TutorialRemotes:FindFirstChild("ShowTutorialArrow")
			local UpdateProgressEvent = TutorialRemotes:FindFirstChild("UpdateTutorialProgress")
			local ShowTextEvent = TutorialRemotes:FindFirstChild("ShowTutorialText")
			local HideAllEvent = TutorialRemotes:FindFirstChild("HideTutorialElements")

			local arrowPart
			local billboardGui
			local arrowImage
			local textLabel
			local currentTarget -- Instance
			local keepUpdating = false

			local function makeLocalArrow()
				-- Get the arrow model from assets
				arrowPart = game:GetObjects("rbxassetid://10274272791")[1]
				if not arrowPart then
					warn("❌ Failed to load arrow model!")
					return
				end

				-- Configure the arrow
				arrowPart.Name = "TutorialArrow"
				arrowPart.Anchored = true
				arrowPart.CanCollide = false
				
				-- Make arrow more visible
				for _, part in pairs(arrowPart:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Material = Enum.Material.Neon
						part.Color = Color3.fromRGB(255, 210, 60)
					end
				end
				
				-- Add point light for extra visibility
				local pointLight = Instance.new("PointLight")
				pointLight.Range = 15
				pointLight.Brightness = 5
				pointLight.Color = Color3.fromRGB(255, 210, 60)
				pointLight.Parent = arrowPart:FindFirstChild("Handle") or arrowPart

				-- Add highlight effect for entire model
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(255, 210, 60)
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.3
				highlight.OutlineTransparency = 0
				highlight.Parent = arrowPart
				
				-- Add to workspace
				arrowPart.Parent = workspace
				
				print("✓ Arrow created successfully!")
				
				print("🎯 Tutorial arrow created!")

				-- Simple floating text label (for progress / hints)
				textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(0, 400, 0, 40)
				textLabel.Position = UDim2.new(0.5, -200, 0.85, 0)
				textLabel.BackgroundTransparency = 0.4
				textLabel.TextColor3 = Color3.fromRGB(255,255,255)
				textLabel.TextSize = 22
				textLabel.Font = Enum.Font.GothamBold
				textLabel.Visible = false
				textLabel.Parent = playerGui
			end

			local RunService = game:GetService("RunService")
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
					if pcall(function() targetPos = currentTarget:GetPivot().Position end) then
						-- ok
					elseif currentTarget.PrimaryPart then
						targetPos = currentTarget.PrimaryPart.Position
					end
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
					local arrowPos = targetPos + Vector3.new(0, 8, 0) -- Increased height for better visibility
					
					-- Make arrow point down at target with smooth interpolation
					local currentCF = arrowPart.CFrame
					local targetCF = CFrame.new(arrowPos, targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
					
					-- Smooth interpolation with faster response
					arrowPart.CFrame = currentCF:Lerp(targetCF, 0.2)
					
					-- Add more noticeable bobbing motion
					local offset = math.sin(tick() * 3) * 1
					arrowPart.Position += Vector3.new(0, offset, 0)
					
					-- Ensure arrow and all its parts are visible
					for _, part in pairs(arrowPart:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = 0
						end
					end
					
					-- Update text to show distance
					if textLabel then
						local distance = (targetPos - player.Character.HumanoidRootPart.Position).Magnitude
						textLabel.Text = string.format("¡Sigue la flecha! (%.0f studs)", distance)
					end
					
					-- Print arrow status occasionally for debugging
					if tick() % 5 < 0.1 then
						print("🎯 Arrow updated - Pos:", arrowPart.Position, "Target:", targetPos)
					end
				end
			end

			function TutorialClient.Initialize()
				print("🎯 Initializing tutorial client...")
				
				-- Create arrow first
				makeLocalArrow()
				if not arrowPart then
					warn("❌ Failed to create arrow!")
					return
				end
				print("✓ Arrow created successfully")
				
				-- Create tutorial text
				textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(0, 400, 0, 40)
				textLabel.Position = UDim2.new(0.5, -200, 0.85, 0)
				textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				textLabel.BackgroundTransparency = 0.4
				textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				textLabel.TextSize = 22
				textLabel.Font = Enum.Font.GothamBold
				textLabel.Text = "¡Sigue la flecha!"
				textLabel.TextWrapped = true
				textLabel.ZIndex = 10
				textLabel.Parent = playerGui
				print("✓ Tutorial text created")

				-- Create UI stroke for better visibility
				local uiStroke = Instance.new("UIStroke")
				uiStroke.Color = Color3.fromRGB(255, 210, 60)
				uiStroke.Thickness = 2
				uiStroke.Parent = textLabel
				
				-- Connect to server remotes if they exist
				if ShowArrowEvent then
					ShowArrowEvent.OnClientEvent:Connect(function(target)
						print("🎯 Tutorial target received:", target)
						currentTarget = target
						
						-- Ensure arrow exists
						if not arrowPart or arrowPart.Parent == nil then
							makeLocalArrow()
						end
						
						if currentTarget then
							-- Make everything visible
							textLabel.Visible = true
							if arrowPart then
								for _, part in pairs(arrowPart:GetDescendants()) do
									if part:IsA("BasePart") then
										part.Transparency = 0
									end
								end
							end
						else
							-- Hide tutorial elements
							textLabel.Visible = false
							arrowPart.Transparency = 1
							textLabel.Visible = false
						end
					end)
				end

				if UpdateProgressEvent then
					UpdateProgressEvent.OnClientEvent:Connect(function(current, total)
						textLabel.Text = string.format("Collect Poops: %d/%d", current, total)
						textLabel.Visible = true
						-- When reaching total, give a short delay then notify server that rebirth should be opened
						if current >= total then
							-- small delay so player sees 100/100
							task.delay(0.6, function()
								if ActionRemote and ActionRemote.FireServer then
									pcall(function() ActionRemote:FireServer("CompletedPoops") end)
								end
							end)
						end
					end)
				end

				if ShowTextEvent then
					ShowTextEvent.OnClientEvent:Connect(function(text)
						textLabel.Text = text
						textLabel.Visible = true
					end)
				end

				if HideAllEvent then
					HideAllEvent.OnClientEvent:Connect(function()
						currentTarget = nil
						if billboardGui then billboardGui.Enabled = false end
						if textLabel then textLabel.Visible = false end
					end)
				end

				-- RenderStepped update to keep arrow anchored to world target
				keepUpdating = true
				task.spawn(function()
					while keepUpdating do
						updateArrowPosition()
						RunService.RenderStepped:Wait()
					end
				end)

				print("Inline tutorial fallback initialized (world arrow)")
			end

			-- Initialize tutorial module if available
			if TutorialClient then
				pcall(function() 
					TutorialClient.Initialize()
				end)
			end
		end
	end)

-- Create ScreenGui for floating text first
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PoopClearedGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Function to show floating poop cleared text
local function showPoopClearedText(amount)
	amount = amount or 1 -- Default to 1 if not provided

	-- Create the text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "FloatingText"
	textLabel.Size = UDim2.new(0, 200, 0, 50)
	textLabel.Position = UDim2.new(0.5, -100, 0.5, -25)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Text = "+" .. amount .. " Poop" .. (amount > 1 and "s" or "")
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
	textLabel.TextSize = 48
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextTransparency = 0
	textLabel.ZIndex = 10
	textLabel.Parent = screenGui

	-- Create tweens for animation
	local tweenInfo = TweenInfo.new(
		0.5, -- Duration
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out
	)

	local positionGoal = {
		Position = UDim2.new(0.5, -100, 0.4, -25) -- Move up
	}

	local transparencyGoal = {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}

	local positionTween = TweenService:Create(textLabel, tweenInfo, positionGoal)
	local transparencyTween = TweenService:Create(textLabel, tweenInfo, transparencyGoal)

	-- Play animations
	positionTween:Play()
	transparencyTween:Play()

	-- Remove the text after animation completes
	transparencyTween.Completed:Connect(function()
		textLabel:Destroy()
	end)
end

-- Wait for the RemoteEvent
local showPoopClearedEvent = ReplicatedStorage:WaitForChild("ShowPoopClearedEvent")

-- Listen for poop cleared events from server
showPoopClearedEvent.OnClientEvent:Connect(function(amount)
    showPoopClearedText(amount)
end)

print("✅ Client script initialized successfully!")

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 200, 0, 50)
        button.Position = UDim2.new(0.5, -100, 1, -70)
        button.Text = "BORRAR MI DATA"
        button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BorderSizePixel = 0
        button.Parent = frame

        button.MouseButton1Click:Connect(function()
            clearDataRemote:FireServer()
            warningGui:Destroy()
        end)

-- Create ScreenGui for floating text
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PoopClearedGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui


local function applyMobileScale(guiObject: GuiObject, scaleMobile: number, scaleDesktop: number)
	local s = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	s.Parent = guiObject
	s.Scale = IS_MOBILE and scaleMobile or scaleDesktop
end
local function applyUIScale(guiObject: GuiObject, mobileScale: number, desktopScale: number)
	local s = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	s.Parent = guiObject
	s.Scale = IS_MOBILE and mobileScale or desktopScale
end

-- Mobile icon sizing / spacing constants (adjust here)
local MOBILE_ICON_SIZE = 56
local MOBILE_ICON_SPACING = 6 -- px between icons on mobile (user requested 6px)
local MOBILE_ICON_DELTA = MOBILE_ICON_SIZE + MOBILE_ICON_SPACING

-- Function to show floating poop cleared text
local function showPoopClearedText(amount)
	amount = amount or 1 -- Default to 1 if not provided

	-- Create the text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "FloatingText"
	textLabel.Size = UDim2.new(0, 200, 0, 50)
	textLabel.Position = UDim2.new(0.5, -100, 0.5, -25)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Text = "+" .. amount .. " Poop" .. (amount > 1 and "s" or "")
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
	textLabel.TextSize = 48
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextTransparency = 0
	textLabel.ZIndex = 10
	textLabel.Parent = screenGui

	-- Create tweens for animation (move up and fade out)
	local tweenInfo = TweenInfo.new(
		0.5, -- Duration
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out
	)

	local positionGoal = {
		Position = UDim2.new(0.5, -100, 0.4, -25) -- Move up
	}

	local transparencyGoal = {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}

	local positionTween = TweenService:Create(textLabel, tweenInfo, positionGoal)
	local transparencyTween = TweenService:Create(textLabel, tweenInfo, transparencyGoal)

	-- Play animations
	positionTween:Play()
	transparencyTween:Play()

	-- Remove the text after animation completes
	transparencyTween.Completed:Connect(function()
		textLabel:Destroy()
	end)
end

-- Listen for poop cleared events from server
showPoopClearedEvent.OnClientEvent:Connect(function(amount)
	print("========================================")
	print("🎉 CLIENT: Received ShowPoopClearedEvent!")
	print("  - Amount:", amount or 1)
	print("  - Showing floating text...")
	print("========================================")
	
	-- Mostrar texto flotante
	showPoopClearedText(amount)
	print("✅ Floating text displayed!")

	-- Actualizar contadores visuales
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local poopCount = leaderstats:FindFirstChild("Poops")
		if poopCount then
			local currentPoops = poopCount.Value
			-- Verificar progreso de rebirth
			if currentPoops >= 100 then
				-- Resaltar el botón de rebirth
				local rebirthButton = player.PlayerGui:FindFirstChild("RebirthButton")
				if rebirthButton then
					-- Añadir efecto de brillo
					local uiStroke = rebirthButton:FindFirstChild("UIStroke") or Instance.new("UIStroke")
					uiStroke.Color = Color3.fromRGB(255, 215, 0)
					uiStroke.Thickness = 3
					uiStroke.Parent = rebirthButton
				end
			end
		end
	end

	-- Notificar al sistema de tutorial
	local TutorialRemotes = ReplicatedStorage:FindFirstChild("TutorialRemotes")
	if TutorialRemotes then
		local ActionRemote = TutorialRemotes:FindFirstChild("TutorialAction")
		if ActionRemote and ActionRemote.FireServer then
			pcall(function() ActionRemote:FireServer("CollectedPoop") end)
		end
	end
end)

print("✅ Client script loaded successfully!")
print("  - Listening for ShowPoopClearedEvent")

-- ===============================================
-- WARNING SYSTEM
-- ===============================================

local showWarningEvent = ReplicatedStorage:WaitForChild("ShowWarningEvent")

-- Helper for improved warnings with animation, icon, shadow and nicer visuals
local function showWarning(message)
	-- Container frame so we can animate scale/position independently
	local container = Instance.new("Frame")
	container.Name = "WarningContainer"
	container.Size = UDim2.new(0, 520, 0, 96)
	container.Position = UDim2.new(0.5, -260, 0.42, -48)
	container.BackgroundTransparency = 1
	container.ZIndex = 220
	container.Parent = screenGui

	-- Background with subtle gradient
	local bg = Instance.new("Frame")
	bg.Name = "WarningBackground"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.Position = UDim2.new(0, 0, 0, 0)
	bg.BackgroundColor3 = Color3.fromRGB(45, 12, 12)
	bg.BackgroundTransparency = 0
	bg.BorderSizePixel = 0
	bg.ZIndex = 221
	bg.Parent = container

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 30, 30))
	})
	bgGradient.Rotation = 90
	bgGradient.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 220, 180)
	stroke.Thickness = 2
	stroke.Transparency = 0.6
	stroke.Parent = bg

	-- Shadow (duplicated label technique)
	local shadow = Instance.new("TextLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, -120, 1, 0)
	shadow.Position = UDim2.new(0, 70 + 2, 0, 0 + 2)
	shadow.BackgroundTransparency = 1
	shadow.Font = Enum.Font.FredokaOne
	shadow.Text = message
	shadow.TextSize = 20
	shadow.TextColor3 = Color3.fromRGB(0, 0, 0)
	shadow.TextTransparency = 0.5
	shadow.TextXAlignment = Enum.TextXAlignment.Left
	shadow.ZIndex = 222
	shadow.Parent = container

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 64, 0, 64)
	icon.Position = UDim2.new(0, 10, 0, 16)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.FredokaOne
	icon.Text = "⚠️"
	icon.TextSize = 48
	icon.TextScaled = false
	icon.ZIndex = 223
	icon.Parent = container

	-- Main text
	local label = Instance.new("TextLabel")
	label.Name = "WarningText"
	label.Size = UDim2.new(1, -120, 1, 0)
	label.Position = UDim2.new(0, 70, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = message
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(255, 245, 230)
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 224
	label.Parent = container

	-- Entrance animation (pop + slight bounce)
	container.AnchorPoint = Vector2.new(0, 0)
	container.Size = UDim2.new(0, 520, 0, 0)
	bg.Visible = false
	local tweenIn = TweenService:Create(container, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 520, 0, 96)})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	bg.Visible = true

	-- small pulse to draw attention
	local pulse1 = TweenService:Create(bg, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0})
	local pulse2 = TweenService:Create(bg, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.06})
	pulse1:Play(); task.wait(0.18); pulse2:Play()

	-- Keep visible then fade
	task.spawn(function()
		task.wait(2.4)
		local fadeOut = TweenService:Create(container, TweenInfo.new(0.4), {BackgroundTransparency = 1})
		-- fade children text transparencies manually for nicer effect
		TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(shadow, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(icon, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		fadeOut:Play()
		fadeOut.Completed:Wait()
		container:Destroy()
	end)
end

-- Wire up server event
showWarningEvent.OnClientEvent:Connect(function(message)
	pcall(function() showWarning(message) end)
end)

-- Purchase response handler: server will send a quick response so client can clear pending state
local purchaseResponseEvent = ReplicatedStorage:FindFirstChild("PurchaseShovelUpgradeResponseEvent")
if purchaseResponseEvent then
	purchaseResponseEvent.OnClientEvent:Connect(function(statName, success, message)
		-- Clear pending state and cancel timeout
		if statName and pendingPurchases[statName] then
			pendingPurchases[statName] = nil
			if pendingTimeouts[statName] then
				pendingTimeouts[statName].cancelled = true
				pendingTimeouts[statName] = nil
			end
			-- Update UI to reflect current server state
			updateUpgradeUI()
		end

		-- If failed, show a warning using the same UI pattern
		if not success then
			local msg = message or "Purchase failed or timed out."
			-- Use improved warning helper
			pcall(function() showWarning(msg) end)
		end
	end)
end

-- ===============================================
-- LUCKY SYSTEM UI
-- ===============================================

local showLuckyEvent = ReplicatedStorage:WaitForChild("ShowLuckyEvent", 10)

if showLuckyEvent then
	showLuckyEvent.OnClientEvent:Connect(function(message, multiplier)
		print("🎰 LUCKY! Message:", message, "Multiplier:", multiplier)

		-- Create HUGE lucky text
		local luckyLabel = Instance.new("TextLabel")
		luckyLabel.Name = "LuckyText"
		luckyLabel.Size = UDim2.new(0, 600, 0, 150)
		luckyLabel.Position = UDim2.new(0.5, -300, 0.5, -75)
		luckyLabel.BackgroundTransparency = 1
		luckyLabel.Font = Enum.Font.FredokaOne
		luckyLabel.Text = message
		luckyLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		luckyLabel.TextSize = 60
		luckyLabel.TextStrokeTransparency = 0
		luckyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		luckyLabel.TextScaled = true
		luckyLabel.ZIndex = 300
		luckyLabel.Parent = screenGui

		-- Rainbow color animation
		task.spawn(function()
			for i = 1, 20 do
				luckyLabel.TextColor3 = Color3.fromHSV((i / 20), 1, 1)
				task.wait(0.05)
			end
		end)

		-- Scale up animation
		local startSize = UDim2.new(0, 0, 0, 0)
		luckyLabel.Size = startSize

		TweenService:Create(luckyLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 600, 0, 150)
		}):Play()

		-- Wait then fade out
		task.wait(2)

		TweenService:Create(luckyLabel, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}):Play()

		task.wait(0.5)
		luckyLabel:Destroy()
	end)
end

-- ===============================================
-- REBIRTH SYSTEM UI
-- ===============================================

 
-- Helper: format large numbers into K/M/B for display
local function formatNumberShort(n)
	if type(n) ~= "number" then return tostring(n) end
	local absn = math.abs(n)
	if absn >= 1e12 then
		return string.format("%gT", math.floor(n / 1e12 + 0.5))
	elseif absn >= 1e9 then
		return string.format("%gB", math.floor(n / 1e9 + 0.5))
	elseif absn >= 1e6 then
		return string.format("%gM", math.floor(n / 1e6 + 0.5))
	elseif absn >= 1e3 then
		return string.format("%gK", math.floor(n / 1e3 + 0.5))
	else
		return tostring(n)
	end
end

-- Keep the original first 15 rebirths exactly as requested
local STATIC_REBIRTHS = {
	-- EASY TIER (1-5)
	{cost = 50, poopMultiplier = 2, speedBoost = 0.2, name = "Rebirth I"},
	{cost = 250, poopMultiplier = 3, speedBoost = 0.4, name = "Rebirth II"},
	{cost = 500, poopMultiplier = 4, speedBoost = 0.6, name = "Rebirth III"},
	{cost = 1000, poopMultiplier = 6, speedBoost = 0.8, name = "Rebirth IV"},
	{cost = 2000, poopMultiplier = 8, speedBoost = 1.0, name = "Rebirth V"},
	-- MEDIUM TIER (6-10)
	{cost = 4000, poopMultiplier = 12, speedBoost = 1.3, name = "Rebirth VI"},
	{cost = 7500, poopMultiplier = 16, speedBoost = 1.6, name = "Rebirth VII"},
	{cost = 12500, poopMultiplier = 22, speedBoost = 2.0, name = "Rebirth VIII"},
	{cost = 20000, poopMultiplier = 30, speedBoost = 2.4, name = "Rebirth IX"},
	{cost = 35000, poopMultiplier = 40, speedBoost = 2.8, name = "Rebirth X"},
	-- HARD TIER (11-15)
	{cost = 60000, poopMultiplier = 55, speedBoost = 3.2, name = "Rebirth XI"},
	{cost = 100000, poopMultiplier = 75, speedBoost = 3.6, name = "Rebirth XII"},
	{cost = 175000, poopMultiplier = 100, speedBoost = 4.0, name = "Rebirth XIII"},
	{cost = 300000, poopMultiplier = 150, speedBoost = 4.5, name = "Rebirth XIV"},
	{cost = 500000, poopMultiplier = 200, speedBoost = 5.0, name = "Rebirth XV"},
}

-- Create full 100-level roadmap
local function buildRebirthRoadmap()
	local total = 100
	local levels = {}

	-- First, copy static entries
	for i, v in ipairs(STATIC_REBIRTHS) do
		v.rewardDesc = string.format("%dx Poops, +%.2f speed", v.poopMultiplier, v.speedBoost)
		v.effects = {}
		table.insert(levels, v)
	end

	-- Helpers for costs and rounding
	local function niceRound(n)
		if n <= 0 then return 0 end
		local exp = math.floor(math.log(math.max(n,1)) / math.log(10))
		local pow = 10 ^ exp
		local lead = math.floor(n / pow + 0.5)
		return lead * pow
	end

	local lastCost = STATIC_REBIRTHS[#STATIC_REBIRTHS].cost
	local growth = 1.25

	-- Predefined milestone effects for variety (server must implement these to be authoritative)
	local function specialEffectsForLevel(l)
		local eff = {}
		local desc = nil
		if l >= 16 and l <= 19 then
			-- intentionally no extra effect
			desc = "No new bonus"
		elseif l == 20 then
			eff.sellRate = 5 -- coins sell at 5 Poops per Coin
			desc = "Sell rate improved: 5 Poops per Coin"
		elseif l == 25 then
			eff.upgradeSlot = 1
			desc = "Unlock +1 upgrade slot"
		elseif l == 30 then
			eff.passivePoops = 1
			desc = "+1 passive Poop/sec"
		elseif l == 35 then
			eff.shopDiscount = 0.05
			desc = "5% shop discount"
		elseif l == 40 then
			eff.extraPetSlot = 1
			desc = "+1 pet slot"
		elseif l == 45 then
			eff.shovelEfficiency = 0.10
			desc = "+10% shovel efficiency"
		elseif l == 50 then
			eff.railDiscount = 0.10
			desc = "10% rail shop discount"
		elseif l == 55 then
			eff.sellRate = 4
			desc = "Sell rate improved: 4 Poops per Coin"
		elseif l == 60 then
			eff.passivePoops = 2
			desc = "+2 passive Poops/sec"
		elseif l == 65 then
			eff.upgradeSlot = 1
			desc = "Unlock +1 upgrade slot"
		elseif l == 70 then
			eff.globalMultiplier = 1.05
			desc = "+5% global gains"
		elseif l == 75 then
			eff.cosmetic = "Exclusive Skin"
			desc = "Unlock an exclusive cosmetic skin"
		elseif l == 80 then
			eff.sellRate = 3
			desc = "Sell rate improved: 3 Poops per Coin"
		elseif l == 85 then
			eff.passivePoops = 3
			desc = "+3 passive Poops/sec"
		elseif l == 90 then
			eff.goldenChance = 0.01
			desc = "+1% chance for Golden Poop"
		elseif l == 95 then
			eff.unlockRail = true
			desc = "Unlock a special rail cosmetic"
		elseif l == 100 then
			eff.globalMultiplier = 1.10
			desc = "+10% global gains (permanent)"
		else
			desc = nil
		end
		return eff, desc
	end

	for l = 16, total do
		-- escalate cost and round nicely
		local raw = lastCost * growth
		local cost = niceRound(raw)
		lastCost = cost

		-- Poop multiplier progression: modest linear growth from 200 (lvl15) to 500 (lvl100)
		local t = (l - 16) / math.max(1, (total - 16))
		local poopMult = math.floor(200 + (500 - 200) * t + 0.5)

		-- Speed cap: keep at level 15's value
		local speed = STATIC_REBIRTHS[#STATIC_REBIRTHS].speedBoost

		local eff, desc = specialEffectsForLevel(l)
		local name = "Rebirth " .. tostring(l)
		local rewardDesc = desc or string.format("%dx Poops, +%s speed", poopMult, tostring(speed))

		table.insert(levels, {
			cost = cost,
			poopMultiplier = poopMult,
			speedBoost = speed,
			name = name,
			rewardDesc = rewardDesc,
			effects = eff,
		})
	end

	return levels
end

local REBIRTH_LEVELS = buildRebirthRoadmap()

-- Create main ScreenGui
local rebirthGui = Instance.new("ScreenGui")
rebirthGui.Name = "RebirthGui"
rebirthGui.ResetOnSpawn = false
rebirthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
rebirthGui.Parent = playerGui

-- ===============================================
-- REBIRTH ICON BUTTON (Left side)
-- ===============================================

local iconButton = Instance.new("ImageButton")
iconButton.Name = "RebirthIcon"
iconButton.Size = UDim2.new(0, 64, 0, 64)
iconButton.Position = UDim2.new(0, 20, 0.5, -40)
iconButton.BackgroundColor3 = Color3.fromRGB(60, 20, 100)
iconButton.BorderSizePixel = 0
iconButton.Parent = rebirthGui

-- Create circular icon
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0.5, 0) -- Makes it circular
iconCorner.Parent = iconButton

-- Add gradient to icon
local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 50, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 150))
})
iconGradient.Rotation = 45
iconGradient.Parent = iconButton

-- Add stroke/border to icon
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(200, 100, 255)
iconStroke.Thickness = 4
iconStroke.Parent = iconButton

-- Crown icon (using emoji instead of image to avoid white edges)
local iconImage = Instance.new("ImageLabel")
iconImage.Size = UDim2.new(1, 0, 1, 0)
iconImage.BackgroundTransparency = 1
iconImage.Image = "rbxassetid://80993270685237" -- 👈 Reemplazá con el ID de tu decal “rebirth”
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.ZIndex = 2
iconImage.Parent = iconButton

applyUIScale(iconButton, 0.85, 1.0)
-- Mobile stacking: set rebirth size/position for mobile consistent with other icons
if IS_MOBILE then
	iconButton.Size = UDim2.new(0, MOBILE_ICON_SIZE, 0, MOBILE_ICON_SIZE)
	-- shift icons slightly up on mobile for better visibility
		-- moved up additional 10px for improved spacing on small screens
		iconButton.Position = UDim2.new(0, 16, 0.5, -20)
else
	iconButton.Size = UDim2.new(0, 64, 0, 64)
	iconButton.Position = UDim2.new(0, 20, 0.5, -40)
end




-- ===============================================
-- FULL SCREEN REBIRTH MENU
-- ===============================================

-- Background overlay (darkened)
local menuOverlay = Instance.new("Frame")
menuOverlay.Name = "MenuOverlay"
menuOverlay.Size = UDim2.new(1, 0, 1, 0)
menuOverlay.Position = UDim2.new(0, 0, 0, 0)
menuOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
menuOverlay.BackgroundTransparency = 0.5
menuOverlay.BorderSizePixel = 0
menuOverlay.Visible = false
menuOverlay.ZIndex = 100
menuOverlay.Parent = rebirthGui

-- Main menu container
local mainMenu = Instance.new("Frame")
mainMenu.Name = "MainMenu"
mainMenu.Size = UDim2.new(0, 900, 0, 600)
-- center the menu on desktop using AnchorPoint (0.5,0.5)
mainMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
mainMenu.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
mainMenu.BorderSizePixel = 0
mainMenu.Visible = false
mainMenu.ZIndex = 101
mainMenu.Parent = rebirthGui

-- Use AnchorPoint centering on mobile for better alignment
mainMenu.AnchorPoint = Vector2.new(0.5, 0.5)

if IS_MOBILE then
	mainMenu.Size = UDim2.new(0, 660, 0, 480)  -- antes era 900x600
	-- center using AnchorPoint so it stays truly centered on different screens
	mainMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
end

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 20)
menuCorner.Parent = mainMenu

-- Menu gradient background
local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 25))
})
menuGradient.Rotation = 90
menuGradient.Parent = mainMenu

-- Menu border glow
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(150, 80, 255)
menuStroke.Thickness = 3
menuStroke.Transparency = 0.3
menuStroke.Parent = mainMenu

-- ===============================================
-- HEADER
-- ===============================================

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 100)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1
header.ZIndex = 102
header.Parent = mainMenu

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 400, 0, 60)
titleLabel.Position = UDim2.new(0.5, -200, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Text = "⟳ REBIRTH SYSTEM ⟳"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 255)
titleLabel.TextSize = 42
titleLabel.TextStrokeTransparency = 0.5
titleLabel.ZIndex = 102
titleLabel.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 50, 0, 50)
closeBtn.Position = UDim2.new(1, -70, 0, 25)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 32
closeBtn.TextStrokeTransparency = 0.5
closeBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
closeBtn.ZIndex = 102
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0.5, 0)
closeBtnCorner.Parent = closeBtn

-- ===============================================
-- STATS DISPLAY
-- ===============================================

local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.new(1, -40, 0, 80)
statsPanel.Position = UDim2.new(0, 20, 0, 110)
statsPanel.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
statsPanel.BorderSizePixel = 0
statsPanel.ZIndex = 102
statsPanel.Parent = mainMenu

local statsPanelCorner = Instance.new("UICorner")
statsPanelCorner.CornerRadius = UDim.new(0, 12)
statsPanelCorner.Parent = statsPanel

-- Current Poops Display
local poopsLabel = Instance.new("TextLabel")
poopsLabel.Name = "PoopsLabel"
poopsLabel.Size = UDim2.new(0.5, -10, 1, 0)
poopsLabel.Position = UDim2.new(0, 10, 0, 0)
poopsLabel.BackgroundTransparency = 1
poopsLabel.Font = Enum.Font.FredokaOne
poopsLabel.Text = "💩 Poops: 0"
poopsLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
poopsLabel.TextSize = 28
poopsLabel.TextXAlignment = Enum.TextXAlignment.Left
poopsLabel.ZIndex = 102
poopsLabel.Parent = statsPanel

-- Current Rebirth Level Display
local rebirthLevelLabel = Instance.new("TextLabel")
rebirthLevelLabel.Name = "RebirthLevelLabel"
rebirthLevelLabel.Size = UDim2.new(0.5, -10, 1, 0)
rebirthLevelLabel.Position = UDim2.new(0.5, 0, 0, 0)
rebirthLevelLabel.BackgroundTransparency = 1
rebirthLevelLabel.Font = Enum.Font.FredokaOne
rebirthLevelLabel.Text = "⟳ Level: 0"
rebirthLevelLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
rebirthLevelLabel.TextSize = 28
rebirthLevelLabel.TextXAlignment = Enum.TextXAlignment.Right
rebirthLevelLabel.ZIndex = 102
rebirthLevelLabel.Parent = statsPanel

-- ===============================================
-- PROGRESS BAR
-- ===============================================

local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(1, -40, 0, 60)
progressContainer.Position = UDim2.new(0, 20, 0, 210)
progressContainer.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
progressContainer.BorderSizePixel = 0
progressContainer.ZIndex = 102
progressContainer.Parent = mainMenu

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 10)
progressCorner.Parent = progressContainer

local progressStroke = Instance.new("UIStroke")
progressStroke.Color = Color3.fromRGB(100, 60, 150)
progressStroke.Thickness = 2
progressStroke.Parent = progressContainer

-- Progress bar fill
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 103
progressBar.Parent = progressContainer

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = progressBar

local barGradient = Instance.new("UIGradient")
barGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255))
})
barGradient.Parent = progressBar

-- Progress text
local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Font = Enum.Font.FredokaOne
progressText.Text = "0 / 10"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextSize = 24
progressText.TextStrokeTransparency = 0.5
progressText.ZIndex = 104
progressText.Parent = progressContainer

-- ===============================================
-- REBIRTH LEVELS SCROLL FRAME
-- ===============================================

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "LevelsScroll"
scrollFrame.Size = UDim2.new(1, -40, 0, 280)
scrollFrame.Position = UDim2.new(0, 20, 0, 290)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ZIndex = 102
scrollFrame.Parent = mainMenu

-- Function to create a rebirth level button
local function createRebirthButton(levelData, levelIndex)
	local btn = Instance.new("TextButton")
	btn.Name = "RebirthLevel" .. levelIndex
	btn.Size = UDim2.new(1, -20, 0, 120)
	btn.Position = UDim2.new(0, 10, 0, (levelIndex - 1) * 130)
	btn.BackgroundColor3 = Color3.fromRGB(50, 35, 70)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.ZIndex = 103
	btn.Parent = scrollFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(100, 70, 150)
	btnStroke.Thickness = 2
	btnStroke.Parent = btn

	-- Level name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Text = levelData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 255)
	nameLabel.TextSize = 24
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 104
	nameLabel.Parent = btn

	-- Cost
	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(0, 200, 0, 25)
	costLabel.Position = UDim2.new(0, 10, 0, 45)
	costLabel.BackgroundTransparency = 1
	costLabel.Font = Enum.Font.GothamBold
	costLabel.Text = "💰 Cost: " .. formatNumberShort(levelData.cost) .. " Poops"
	costLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	costLabel.TextSize = 18
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.ZIndex = 104
	costLabel.Parent = btn

	-- Rewards
	local rewardsLabel = Instance.new("TextLabel")
	rewardsLabel.Size = UDim2.new(1, -20, 0, 40)
	rewardsLabel.Position = UDim2.new(0, 10, 0, 70)
	rewardsLabel.BackgroundTransparency = 1
	rewardsLabel.Font = Enum.Font.Gotham
	rewardsLabel.Text = string.format("✨ Rewards: %dx Poops | +%.0f%% Speed", levelData.poopMultiplier, levelData.speedBoost * 100)
	rewardsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	rewardsLabel.TextSize = 16
	rewardsLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardsLabel.TextYAlignment = Enum.TextYAlignment.Top
	rewardsLabel.ZIndex = 104
	rewardsLabel.Parent = btn

	-- Lock icon overlay
	local lockIcon = Instance.new("TextLabel")
	lockIcon.Name = "LockIcon"
	lockIcon.Size = UDim2.new(1, 0, 1, 0)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Font = Enum.Font.FredokaOne
	lockIcon.Text = "🔒"
	lockIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
	lockIcon.TextSize = 60
	lockIcon.TextTransparency = 0.3
	lockIcon.ZIndex = 105
	lockIcon.Visible = false
	lockIcon.Parent = btn

	return btn
end

-- Create all rebirth level buttons
local levelButtons = {}
for i, levelData in ipairs(REBIRTH_LEVELS) do
	levelButtons[i] = createRebirthButton(levelData, i)
end

-- Update canvas size
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #REBIRTH_LEVELS * 130)

-- ===============================================
-- UPDATE FUNCTION
-- ===============================================

local function updateRebirthUI()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local rebirthValue = leaderstats:FindFirstChild("Rebirths")
	if not rebirthValue then return end

	local poopCount = leaderstats:FindFirstChild("Poops Cleared")
	if not poopCount then return end

	local currentPoops = poopCount.Value
	local currentRebirth = rebirthValue.Value

	-- Update stats display
	poopsLabel.Text = "💩 Poops: " .. currentPoops
	rebirthLevelLabel.Text = "⟳ Level: " .. currentRebirth

	-- Determine next rebirth level
	local nextLevel = currentRebirth + 1
	if nextLevel <= #REBIRTH_LEVELS then
		local nextLevelData = REBIRTH_LEVELS[nextLevel]
		local progress = math.min(currentPoops / nextLevelData.cost, 1)

		-- Update progress bar
		progressBar:TweenSize(
			UDim2.new(progress, 0, 1, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.3,
			true
		)

	progressText.Text = formatNumberShort(currentPoops) .. " / " .. formatNumberShort(nextLevelData.cost)
	else
		progressBar.Size = UDim2.new(1, 0, 1, 0)
		progressText.Text = "MAX LEVEL!"
	end

	-- Update buttons (lock/unlock)
	for i, btn in ipairs(levelButtons) do
		local levelData = REBIRTH_LEVELS[i]
		local lockIcon = btn:FindFirstChild("LockIcon")

		if i <= currentRebirth then
			-- Already completed
			btn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
			btn:FindFirstChild("UIStroke").Color = Color3.fromRGB(50, 200, 50)
			lockIcon.Visible = false
			btn.Text = "✓ COMPLETED"
			btn.TextColor3 = Color3.fromRGB(150, 255, 150)
			btn.TextSize = 20
			btn.Font = Enum.Font.FredokaOne
		elseif i == currentRebirth + 1 then
			-- Next available rebirth
			if currentPoops >= levelData.cost then
				-- Can afford
				btn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
				btn:FindFirstChild("UIStroke").Color = Color3.fromRGB(100, 255, 100)
				lockIcon.Visible = false
				btn.Text = "🌟 REBIRTH NOW!"
				btn.TextColor3 = Color3.fromRGB(255, 255, 100)
				btn.TextSize = 20
				btn.Font = Enum.Font.FredokaOne
			else
				-- Cannot afford yet
				btn.BackgroundColor3 = Color3.fromRGB(50, 35, 70)
				btn:FindFirstChild("UIStroke").Color = Color3.fromRGB(100, 70, 150)
				lockIcon.Visible = false
				btn.Text = ""
			end
		else
			-- Locked (future rebirths)
			btn.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
			btn:FindFirstChild("UIStroke").Color = Color3.fromRGB(60, 50, 70)
			lockIcon.Visible = true
			btn.Text = ""
		end
	end
end

-- ===============================================
-- BUTTON CLICK HANDLERS
-- ===============================================

-- Helper: dim other icons when a menu is open so they appear in the background.
local function adjustIconsWhenMenuOpen(isOpen, active)
	-- active: "rebirth" | "upgrade" | "house" | nil
	local dimVal = isOpen and 0.6 or 0

	-- Rebirth icon
	if iconImage and iconImage:IsA("ImageLabel") then
		if isOpen and active ~= "rebirth" then
			iconImage.ImageTransparency = dimVal
			iconStroke.Thickness = 2
		else
			iconImage.ImageTransparency = 0
			iconStroke.Thickness = 4
		end
	end

	-- Upgrade icon
	if upgradeIconImage and upgradeIconImage:IsA("ImageLabel") then
		if isOpen and active ~= "upgrade" then
			upgradeIconImage.ImageTransparency = dimVal
			upgradeIconStroke.Thickness = 2
		else
			upgradeIconImage.ImageTransparency = 0
			upgradeIconStroke.Thickness = 4
		end
	end

	-- House icon (child ImageLabel named 'House Icon 2')
	if teleportButton and teleportButton.FindFirstChild and teleportButton:FindFirstChild("House Icon 2") then
		local h = teleportButton["House Icon 2"]
		if h and h:IsA("ImageLabel") then
			if isOpen and active ~= "house" then
				h.ImageTransparency = dimVal
				teleportButtonStroke.Thickness = 1
			else
				h.ImageTransparency = 0
				teleportButtonStroke.Thickness = 2
			end
		end
	end
end




-- Icon button - open menu
iconButton.MouseButton1Click:Connect(function()
	mainMenu.Visible = not mainMenu.Visible
	menuOverlay.Visible = mainMenu.Visible
	if mainMenu.Visible then
		updateRebirthUI()
		-- Notify tutorial system that rebirth menu was opened (best effort)
		local TutorialRemotes = ReplicatedStorage:FindFirstChild("TutorialRemotes")
		if TutorialRemotes then
			local ActionRemote = TutorialRemotes:FindFirstChild("TutorialAction")
			if ActionRemote and ActionRemote.FireServer then
				pcall(function() ActionRemote:FireServer("OpenedRebirth") end)
			end
		end
	end
	-- Dim other icons when rebirth menu opens
	adjustIconsWhenMenuOpen(mainMenu.Visible, mainMenu.Visible and "rebirth" or nil)
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
	mainMenu.Visible = false
	menuOverlay.Visible = false
	adjustIconsWhenMenuOpen(false, nil)
end)

-- Rebirth level buttons
for i, btn in ipairs(levelButtons) do
	btn.MouseButton1Click:Connect(function()
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if not rebirthValue then return end

		local currentRebirth = rebirthValue.Value

		-- Only allow clicking if this is the next rebirth
		if i == currentRebirth + 1 then
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local poopCount = leaderstats:FindFirstChild("Poops Cleared")
				if poopCount and poopCount.Value >= REBIRTH_LEVELS[i].cost then
					print("🔄 Requesting rebirth level", i)
					-- Get rebirth event when needed
					local rebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent", 5)
					if rebirthEvent then
						rebirthEvent:FireServer(i)
						task.wait(0.5)
						updateRebirthUI()
					end
				end
			end
		end
	end)
end

-- Update UI when stats change (wait for stats in background)
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local poopsCleared = leaderstats:WaitForChild("Poops Cleared", 10)
		local rebirths = leaderstats:WaitForChild("Rebirths", 10)

		if poopsCleared then
			poopsCleared.Changed:Connect(updateRebirthUI)
		end

		if rebirths then
			rebirths.Changed:Connect(updateRebirthUI)
		end

		-- Initial update
		task.wait(1)
		updateRebirthUI()
	end
end)

print("✅ Rebirth UI created!")

-- ===============================================
-- SHOVEL UPGRADE SYSTEM UI
-- ===============================================

-- Create GUI for shovel upgrades
local upgradeGui = Instance.new("ScreenGui")
upgradeGui.Name = "ShovelUpgradeGui"
upgradeGui.ResetOnSpawn = false
upgradeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
upgradeGui.Parent = playerGui

-- Upgrade icon button (Left column above Rebirth)
local upgradeIconButton = Instance.new("ImageButton")
upgradeIconButton.Name = "UpgradeIcon"
upgradeIconButton.Size = UDim2.new(0, 64, 0, 64)
-- default desktop: above rebirth (center-left column)
upgradeIconButton.Position = UDim2.new(0, 20, 0.5, -120)
upgradeIconButton.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
upgradeIconButton.BorderSizePixel = 0
upgradeIconButton.Parent = upgradeGui
applyUIScale(upgradeIconButton, 0.85, 1.0)

if IS_MOBILE then
	-- mobile: stack icons in a column with consistent grid spacing
	upgradeIconButton.Size = UDim2.new(0, MOBILE_ICON_SIZE, 0, MOBILE_ICON_SIZE)
	-- move up by 10px compared to previous layout
	-- move up a bit more on mobile for better vertical fit
	upgradeIconButton.Position = UDim2.new(0, 16, 0.5, -(MOBILE_ICON_DELTA + 20))
else
	upgradeIconButton.Position = UDim2.new(0, 20, 0.5, -120)
	upgradeIconButton.Size = UDim2.new(0, 64, 0, 64)
end

local upgradeIconCorner = Instance.new("UICorner")
upgradeIconCorner.CornerRadius = UDim.new(0.5, 0)
upgradeIconCorner.Parent = upgradeIconButton

local upgradeIconGradient = Instance.new("UIGradient")
upgradeIconGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 80, 20))
})
upgradeIconGradient.Rotation = 45
upgradeIconGradient.Parent = upgradeIconButton

local upgradeIconStroke = Instance.new("UIStroke")
upgradeIconStroke.Color = Color3.fromRGB(255, 200, 100)
upgradeIconStroke.Thickness = 4
upgradeIconStroke.Parent = upgradeIconButton

-- Shovel icon (replaces emoji with your "shovel" decal)
local upgradeIconImage = Instance.new("ImageLabel")
upgradeIconImage.Size = UDim2.new(1, 0, 1, 0)
upgradeIconImage.BackgroundTransparency = 1
upgradeIconImage.Image = "rbxassetid://77414404556243" -- 🔧 Reemplazá con el ID real de tu decal
upgradeIconImage.ScaleType = Enum.ScaleType.Fit
upgradeIconImage.ZIndex = 2
upgradeIconImage.Parent = upgradeIconButton


-- Shovel Upgrade: hover/press animations and tooltip (no positional movement)
local upgradeHoverIn = TweenService:Create(upgradeIconButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 72, 0, 72)})
local upgradeHoverOut = TweenService:Create(upgradeIconButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = upgradeIconButton.Size})
local upgradePress = TweenService:Create(upgradeIconButton, TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(0, 56, 0, 56)})

upgradeIconButton.MouseEnter:Connect(function()
	pcall(function() upgradeHoverIn:Play() end)
	upgradeIconStroke.Thickness = 6
end)
upgradeIconButton.MouseLeave:Connect(function()
	pcall(function() upgradeHoverOut:Play() end)
	upgradeIconStroke.Thickness = 4
end)
upgradeIconButton.MouseButton1Down:Connect(function()
	pcall(function() upgradePress:Play() end)
end)
upgradeIconButton.MouseButton1Up:Connect(function()
	pcall(function() upgradeHoverIn:Play() end)
end)

-- Background overlay
-- Rebirth: hover/press animations and tooltip (no positional movement)
local rebirthHoverIn = TweenService:Create(iconButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 72, 0, 72)})
local rebirthHoverOut = TweenService:Create(iconButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 64, 0, 64)})
local rebirthPress = TweenService:Create(iconButton, TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(0, 56, 0, 56)})

iconButton.MouseEnter:Connect(function()
	pcall(function() rebirthHoverIn:Play() end)
	iconStroke.Thickness = 6
end)
iconButton.MouseLeave:Connect(function()
	pcall(function() rebirthHoverOut:Play() end)
	iconStroke.Thickness = 4
end)
iconButton.MouseButton1Down:Connect(function()
	pcall(function() rebirthPress:Play() end)
end)
iconButton.MouseButton1Up:Connect(function()
	pcall(function() rebirthHoverIn:Play() end)
end)
local upgradeOverlay = Instance.new("Frame")
upgradeOverlay.Name = "UpgradeOverlay"
upgradeOverlay.Size = UDim2.new(1, 0, 1, 0)
upgradeOverlay.Position = UDim2.new(0, 0, 0, 0)
upgradeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
upgradeOverlay.BackgroundTransparency = 0.5
upgradeOverlay.BorderSizePixel = 0
upgradeOverlay.Visible = false
upgradeOverlay.ZIndex = 100
upgradeOverlay.Parent = upgradeGui

-- Main upgrade menu
local upgradeMenu = Instance.new("Frame")
upgradeMenu.Name = "UpgradeMenu"
upgradeMenu.Size = UDim2.new(0, 800, 0, 550)
-- center upgrade menu on desktop using AnchorPoint
upgradeMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
upgradeMenu.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
upgradeMenu.BorderSizePixel = 0
upgradeMenu.Visible = false
upgradeMenu.ZIndex = 101
upgradeMenu.Parent = upgradeGui

-- center on mobile using AnchorPoint
upgradeMenu.AnchorPoint = Vector2.new(0.5, 0.5)

local upgradeMenuCorner = Instance.new("UICorner")
upgradeMenuCorner.CornerRadius = UDim.new(0, 20)
upgradeMenuCorner.Parent = upgradeMenu

local upgradeMenuStroke = Instance.new("UIStroke")
upgradeMenuStroke.Color = Color3.fromRGB(255, 180, 100)
upgradeMenuStroke.Thickness = 3
upgradeMenuStroke.Transparency = 0.3
upgradeMenuStroke.Parent = upgradeMenu

-- Shovel: achicar el menú en mobile
if IS_MOBILE then
	upgradeMenu.Size     = UDim2.new(0, 600, 0, 480)  -- antes 800x550
	upgradeMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
end


-- Header
local upgradeHeader = Instance.new("Frame")
upgradeHeader.Name = "Header"
upgradeHeader.Size = UDim2.new(1, 0, 0, 80)
upgradeHeader.Position = UDim2.new(0, 0, 0, 0)
upgradeHeader.BackgroundTransparency = 1
upgradeHeader.ZIndex = 102
upgradeHeader.Parent = upgradeMenu

local upgradeTitle = Instance.new("TextLabel")
upgradeTitle.Size = UDim2.new(0, 400, 0, 50)
upgradeTitle.Position = UDim2.new(0.5, -200, 0, 15)
upgradeTitle.BackgroundTransparency = 1
upgradeTitle.Font = Enum.Font.FredokaOne
upgradeTitle.Text = "🔨 SHOVEL UPGRADES 🔨"
upgradeTitle.TextColor3 = Color3.fromRGB(255, 220, 150)
upgradeTitle.TextSize = 36
upgradeTitle.TextStrokeTransparency = 0.5
upgradeTitle.ZIndex = 102
upgradeTitle.Parent = upgradeHeader

-- Close button
local upgradeCloseBtn = Instance.new("TextButton")
upgradeCloseBtn.Name = "CloseButton"
upgradeCloseBtn.Size = UDim2.new(0, 50, 0, 50)
upgradeCloseBtn.Position = UDim2.new(1, -65, 0, 15)
upgradeCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
upgradeCloseBtn.BorderSizePixel = 0
upgradeCloseBtn.Font = Enum.Font.FredokaOne
upgradeCloseBtn.Text = "X"
upgradeCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradeCloseBtn.TextSize = 32
upgradeCloseBtn.TextStrokeTransparency = 0.5
upgradeCloseBtn.ZIndex = 102
upgradeCloseBtn.Parent = upgradeHeader

local upgradeCloseBtnCorner = Instance.new("UICorner")
upgradeCloseBtnCorner.CornerRadius = UDim.new(0.5, 0)
upgradeCloseBtnCorner.Parent = upgradeCloseBtn

-- Scroll frame for upgrades
local upgradeScrollFrame = Instance.new("ScrollingFrame")
upgradeScrollFrame.Name = "UpgradeScroll"
upgradeScrollFrame.Size = UDim2.new(1, -40, 1, -100)
upgradeScrollFrame.Position = UDim2.new(0, 20, 0, 90)
upgradeScrollFrame.BackgroundTransparency = 1
upgradeScrollFrame.BorderSizePixel = 0
upgradeScrollFrame.ScrollBarThickness = 8
upgradeScrollFrame.ZIndex = 102
upgradeScrollFrame.Parent = upgradeMenu

local upgradeLayout = Instance.new("UIListLayout")
upgradeLayout.Padding = UDim.new(0, 10)
upgradeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
upgradeLayout.Parent = upgradeScrollFrame

-- Function to create upgrade card
-- cache and pending state for upgrades (used to update UI in-place)
local currentUpgrades = {}
local pendingPurchases = {}
local pendingTimeouts = {} -- map statName -> cancelable task/token

local function updateCard(card, statConfig, currentLevel, playerCoins)
	if not card or not card.Parent then return end
	local icon = card:FindFirstChild("IconLabel")
	local nameLabel = card:FindFirstChild("NameLabel")
	local descLabel = card:FindFirstChild("DescLabel")
	local levelLabel = card:FindFirstChild("LevelLabel")
	local upgradeBtn = card:FindFirstChild("UpgradeButton")

	if icon and statConfig.icon then icon.Text = statConfig.icon end
	if nameLabel and statConfig.displayName then nameLabel.Text = statConfig.displayName end
	if descLabel and statConfig.description then descLabel.Text = statConfig.description end
	if levelLabel then levelLabel.Text = string.format("Level: %d / %d", currentLevel, statConfig.maxLevel) end

	-- Recompute cost
	local exponent = statConfig.costExponent or 1.15
	local cost = math.floor(statConfig.baseCost * ((currentLevel + 1) ^ exponent))

	if upgradeBtn then
		if currentLevel >= statConfig.maxLevel then
			upgradeBtn.Text = "MAX LEVEL"
			upgradeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			upgradeBtn.Active = false
		elseif playerCoins >= cost then
			-- If a pending purchase exists for this stat, show pending state
			if pendingPurchases[statConfig.name] then
				upgradeBtn.Text = "⏳ Purchasing..."
				upgradeBtn.Active = false
			else
				upgradeBtn.Text = "💰 " .. formatNumberShort(cost)
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
				upgradeBtn.Active = true
			end
		else
			upgradeBtn.Text = "💰 " .. formatNumberShort(cost)
			upgradeBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
			upgradeBtn.Active = false
		end
	end
end

local function createUpgradeCard(statConfig, currentLevel, playerCoins)
	local card = Instance.new("Frame")
	card.Name = statConfig.name
	card.Size = UDim2.new(1, -20, 0, 100)
	card.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
	card.BorderSizePixel = 0
	card.ZIndex = 103

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(100, 70, 150)
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "IconLabel"
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0, 20)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.FredokaOne
	icon.Text = statConfig.icon
	icon.TextSize = 48
	icon.ZIndex = 104
	icon.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 250, 0, 25)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Text = statConfig.displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 22
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 104
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(0, 250, 0, 20)
	descLabel.Position = UDim2.new(0, 80, 0, 35)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = statConfig.description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 14
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 104
	descLabel.Parent = card

	-- Level display
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 150, 0, 25)
	levelLabel.Position = UDim2.new(0, 80, 0, 60)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Text = string.format("Level: %d / %d", currentLevel, statConfig.maxLevel)
	levelLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	levelLabel.TextSize = 16
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.ZIndex = 104
	levelLabel.Parent = card

	-- Upgrade button
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeButton"
	upgradeBtn.Size = UDim2.new(0, 200, 0, 50)
	upgradeBtn.Position = UDim2.new(1, -210, 0.5, -25)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
	upgradeBtn.BorderSizePixel = 0
	upgradeBtn.Font = Enum.Font.FredokaOne
	upgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradeBtn.TextSize = 20
	upgradeBtn.ZIndex = 104
	upgradeBtn.Parent = card

	-- Calculate cost using the same formula as server
	local exponent = statConfig.costExponent or 1.15
	local cost = math.floor(statConfig.baseCost * ((currentLevel + 1) ^ exponent))

	-- initialize button text/state using updateCard to keep logic centralized
	updateCard(card, statConfig, currentLevel, playerCoins)

	local upgradeBtnCorner = Instance.new("UICorner")
	upgradeBtnCorner.CornerRadius = UDim.new(0, 10)
	upgradeBtnCorner.Parent = upgradeBtn

	-- Click handler uses currentUpgrades so it always reflects latest levels
	upgradeBtn.MouseButton1Click:Connect(function()
		local curLevel = currentUpgrades[statConfig.name] or currentLevel or 0
		if curLevel >= statConfig.maxLevel then
			return
		end

		-- Prevent client-side spam: if already pending, ignore
		if pendingPurchases[statConfig.name] then
			return
		end

		local purchaseFn = ReplicatedStorage:FindFirstChild("PurchaseShovelUpgradeFunction")
		local legacyEvent = ReplicatedStorage:FindFirstChild("PurchaseShovelUpgradeEvent")
		if purchaseFn and purchaseFn:IsA("RemoteFunction") or legacyEvent then
			-- mark pending and disable this button until server confirms
			pendingPurchases[statConfig.name] = true
			upgradeBtn.AutoButtonColor = false
			upgradeBtn.Text = "⏳ Purchasing..."
			upgradeBtn.Active = false

			-- start a defensive timeout: if server doesn't respond in X seconds, clear pending state
			local TIMEOUT_SECONDS = 6
			-- cancel previous timeout if any
			if pendingTimeouts[statConfig.name] then
				pendingTimeouts[statConfig.name].cancelled = true
			end
			local token = { cancelled = false }
			pendingTimeouts[statConfig.name] = token
			task.spawn(function()
				task.wait(TIMEOUT_SECONDS)
				if token.cancelled then return end
				-- If still pending after timeout, clear and show warning
				if pendingPurchases[statConfig.name] then
					pendingPurchases[statConfig.name] = nil
					-- refresh UI so button is re-enabled
					updateCard(card, statConfig, currentLevel, playerCoins)
					local warnEvt = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
					if warnEvt then pcall(function() warnEvt:FireClient(Players.LocalPlayer, "Purchase timed out. Try again.") end) end
				end
			end)

			-- Prefer RemoteFunction invoke (deterministic). Fall back to RemoteEvent if function missing.
			if purchaseFn and purchaseFn:IsA("RemoteFunction") then
				-- Call server and wait for outcome (pcall to safely catch errors)
				task.spawn(function()
					local ok, s, msg = pcall(function()
						return purchaseFn:InvokeServer(statConfig.name)
					end)
					local success, message
					if ok then
						success = s
						message = msg
					else
						success = false
						message = "Server error"
					end
					-- Clear pending and update UI
					if pendingPurchases[statConfig.name] then
						pendingPurchases[statConfig.name] = nil
						if pendingTimeouts[statConfig.name] then
							pendingTimeouts[statConfig.name].cancelled = true
							pendingTimeouts[statConfig.name] = nil
						end
						updateCard(card, statConfig, (currentUpgrades[statConfig.name] or currentLevel), playerCoins)
					end
					-- If failed, show warning
					if not success then
						local warnEvt = ReplicatedStorage:FindFirstChild("ShowWarningEvent")
						if warnEvt then pcall(function() warnEvt:FireClient(Players.LocalPlayer, message or "Purchase failed or timed out.") end) end
					end
				end)
			elseif legacyEvent then
				legacyEvent:FireServer(statConfig.name)
			end
		end
	end)

	return card
end

-- Function to update the upgrade UI
function updateUpgradeUI()
	-- Get player's current upgrade levels
	-- Wait for the server function that returns player's upgrades (block until available)
	local getUpgradesFunc = ReplicatedStorage:WaitForChild("GetShovelUpgradesFunction")
	if not getUpgradesFunc then
		warn("GetShovelUpgradesFunction not found after wait!")
		return
	end

	local upgrades = getUpgradesFunc:InvokeServer()
	currentUpgrades = upgrades or {}
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins") and leaderstats.Coins.Value or 0

	-- Stats config (client-side copy; must match server)
	local statsConfig = {
		{name = "Distance", displayName = "Distance", description = "Increases digging range (0.08 studs/lvl)", icon = "📏", baseCost = 50, costExponent = 1.15, maxLevel = 100},
		{name = "Multiplier", displayName = "Multiplier", description = "Increases poop rewards", icon = "✖️", baseCost = 100, costExponent = 1.15, maxLevel = 100},
		{name = "CoinsDiscover", displayName = "Coins Discovery", description = "Chance to find bonus coins", icon = "💰", baseCost = 75, costExponent = 1.15, maxLevel = 100},
		{name = "EggsDiscover", displayName = "Eggs Discovery", description = "0.1% chance per level (2% at max)", icon = "🥚", baseCost = 500, costExponent = 1.35, maxLevel = 20},
		{name = "DigSpeed", displayName = "Dig Speed", description = "Dig faster!", icon = "⚡", baseCost = 80, costExponent = 1.15, maxLevel = 100},
		{name = "LuckyChance", displayName = "Lucky Chance", description = "Chance for lucky multiplier", icon = "🍀", baseCost = 200, costExponent = 1.15, maxLevel = 100},
	}

	-- Build a map of existing cards to update them in-place
	local existingCards = {}
	for _, child in ipairs(upgradeScrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name then
			existingCards[child.Name] = child
		end
	end

	for _, statConfig in ipairs(statsConfig) do
		local currentLevel = upgrades[statConfig.name] or 0
		local card = existingCards[statConfig.name]
		if card then
			updateCard(card, statConfig, currentLevel, coins)
		else
			local newCard = createUpgradeCard(statConfig, currentLevel, coins)
			newCard.Parent = upgradeScrollFrame
		end
	end

	-- Update canvas size
	upgradeScrollFrame.CanvasSize = UDim2.new(0, 0, 0, upgradeLayout.AbsoluteContentSize.Y + 10)
end

-- Icon button click - open menu
upgradeIconButton.MouseButton1Click:Connect(function()
	upgradeMenu.Visible = not upgradeMenu.Visible
	upgradeOverlay.Visible = upgradeMenu.Visible
	if upgradeMenu.Visible then
		updateUpgradeUI()
		-- Notify tutorial system that upgrades menu was opened (best effort)
		local TutorialRemotes = ReplicatedStorage:FindFirstChild("TutorialRemotes")
		if TutorialRemotes then
			local ActionRemote = TutorialRemotes:FindFirstChild("TutorialAction")
			if ActionRemote and ActionRemote.FireServer then
				pcall(function() ActionRemote:FireServer("OpenedUpgrades") end)
			end
		end
	end
	-- Dim other icons when upgrade menu opens
	adjustIconsWhenMenuOpen(upgradeMenu.Visible, upgradeMenu.Visible and "upgrade" or nil)
end)

-- Close button
upgradeCloseBtn.MouseButton1Click:Connect(function()
	upgradeMenu.Visible = false
	upgradeOverlay.Visible = false
	adjustIconsWhenMenuOpen(false, nil)
end)

print("✅ Shovel Upgrade UI created!")

-- ===============================================
-- UPGRADE SUCCESS FLOATING TEXT
-- ===============================================

local showUpgradeSuccessEvent = ReplicatedStorage:WaitForChild("ShowUpgradeSuccessEvent", 10)

if showUpgradeSuccessEvent then
	showUpgradeSuccessEvent.OnClientEvent:Connect(function(a, b, c, d)
		-- Standardized server signature: (statKeyOrNil, newLevelOrNil, displayName, message)
		-- But older code may send other variants; handle gracefully.
		local statKey = nil
		local newLevel = nil
		local title = nil
		local message = nil

		if type(a) == "string" and tonumber(b) ~= nil then
			-- a = internal stat key, b = new level
			statKey = a
			newLevel = tonumber(b)
			title = tostring(c or statKey)
			message = tostring(d or "")
		else
			-- treat as generic notification: prefer c (displayName) then a
			title = tostring(c or a or "Notification")
			message = tostring(d or b or "")
		end

		-- If this is an upgrade confirmation for a stat we care about, update local state
		if statKey then
			print("🎉 Upgrade successful:", statKey, "->", newLevel)

			-- Visual floating text
			local upgradeText = Instance.new("TextLabel")
			upgradeText.Name = "UpgradeSuccessText"
			upgradeText.Size = UDim2.new(0, 300, 0, 60)
			upgradeText.Position = UDim2.new(0.5, -150, 0.4, -30)
			upgradeText.BackgroundTransparency = 1
			upgradeText.Font = Enum.Font.FredokaOne
			upgradeText.Text = string.format("⬆️ %s Lv.%s", tostring(title), tostring(newLevel))
			upgradeText.TextColor3 = Color3.fromRGB(100, 255, 100)
			upgradeText.TextSize = 36
			upgradeText.TextStrokeTransparency = 0.5
			upgradeText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			upgradeText.TextTransparency = 0
			upgradeText.ZIndex = 500
			upgradeText.Parent = screenGui

			local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local positionGoal = { Position = UDim2.new(0.5, -150, 0.35, -30) }
			local transparencyGoal = { TextTransparency = 1, TextStrokeTransparency = 1 }
			local positionTween = TweenService:Create(upgradeText, tweenInfo, positionGoal)
			local transparencyTween = TweenService:Create(upgradeText, tweenInfo, transparencyGoal)
			positionTween:Play()
			transparencyTween:Play()
			transparencyTween.Completed:Connect(function() upgradeText:Destroy() end)

			pcall(function()
				currentUpgrades[statKey] = newLevel
				updateUpgradeUI()
				pendingPurchases[statKey] = nil
				-- cancel defensive timeout task if any
				if pendingTimeouts[statKey] then
					pendingTimeouts[statKey].cancelled = true
					pendingTimeouts[statKey] = nil
				end
			end)
		else
			-- Generic notification from Monetization or other server systems
			print("🔔 Notification:", title, message)
			local notif = Instance.new("TextLabel")
			notif.Name = "UpgradeSuccessText"
			notif.Size = UDim2.new(0, 340, 0, 70)
			notif.Position = UDim2.new(0.5, -170, 0.4, -35)
			notif.BackgroundTransparency = 1
			notif.Font = Enum.Font.FredokaOne
			notif.Text = title .. (message ~= "" and ("\n" .. message) or "")
			notif.TextColor3 = Color3.fromRGB(200, 200, 255)
			notif.TextSize = 20
			notif.TextWrapped = true
			notif.ZIndex = 500
			notif.Parent = screenGui

			local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local positionGoal = { Position = UDim2.new(0.5, -170, 0.35, -35) }
			local transparencyGoal = { TextTransparency = 1, TextStrokeTransparency = 1 }
			local positionTween = TweenService:Create(notif, tweenInfo, positionGoal)
			local transparencyTween = TweenService:Create(notif, tweenInfo, transparencyGoal)
			positionTween:Play()
			transparencyTween:Play()
			transparencyTween.Completed:Connect(function() notif:Destroy() end)
		end
	end)
end

-- ===============================================
-- REBIRTH SUCCESS CELEBRATION
-- ===============================================

task.spawn(function()
	local showRebirthSuccessEvent = ReplicatedStorage:WaitForChild("ShowRebirthSuccess", 10)

	if showRebirthSuccessEvent then
		showRebirthSuccessEvent.OnClientEvent:Connect(function(successData)
		print("🎊 REBIRTH SUCCESS!", successData.rebirthName)

		-- Close the rebirth menu so the celebration can be seen
		mainMenu.Visible = false
		menuOverlay.Visible = false

		-- Create full-screen celebration overlay
		local celebrationOverlay = Instance.new("Frame")
		celebrationOverlay.Name = "RebirthCelebration"
		celebrationOverlay.Size = UDim2.new(1, 0, 1, 0)
		celebrationOverlay.Position = UDim2.new(0, 0, 0, 0)
		celebrationOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		celebrationOverlay.BackgroundTransparency = 1
		celebrationOverlay.BorderSizePixel = 0
		celebrationOverlay.ZIndex = 500
		celebrationOverlay.Parent = screenGui

		-- Flash effect background
		local flashFrame = Instance.new("Frame")
		flashFrame.Size = UDim2.new(1, 0, 1, 0)
		flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		flashFrame.BackgroundTransparency = 1
		flashFrame.BorderSizePixel = 0
		flashFrame.ZIndex = 501
		flashFrame.Parent = celebrationOverlay

		-- Main title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(0, 800, 0, 150)
		titleLabel.Position = UDim2.new(0.5, -400, 0.3, -75)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.FredokaOne
		titleLabel.Text = "⟳ REBIRTH SUCCESSFUL! ⟳"
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 72
		titleLabel.TextStrokeTransparency = 0
		titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		titleLabel.TextScaled = true
		titleLabel.TextTransparency = 1
		titleLabel.ZIndex = 502
		titleLabel.Parent = celebrationOverlay

		-- Rebirth level name
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelName"
		levelLabel.Size = UDim2.new(0, 600, 0, 80)
		levelLabel.Position = UDim2.new(0.5, -300, 0.45, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Font = Enum.Font.FredokaOne
		levelLabel.Text = successData.rebirthName
		levelLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
		levelLabel.TextSize = 48
		levelLabel.TextStrokeTransparency = 0
		levelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		levelLabel.TextTransparency = 1
		levelLabel.ZIndex = 502
		levelLabel.Parent = celebrationOverlay

		-- Rewards panel
		local rewardsPanel = Instance.new("Frame")
		rewardsPanel.Name = "RewardsPanel"
		rewardsPanel.Size = UDim2.new(0, 700, 0, 150)
		rewardsPanel.Position = UDim2.new(0.5, -350, 0.6, 0)
		rewardsPanel.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		rewardsPanel.BackgroundTransparency = 1
		rewardsPanel.BorderSizePixel = 0
		rewardsPanel.ZIndex = 502
		rewardsPanel.Parent = celebrationOverlay

		local rewardsPanelCorner = Instance.new("UICorner")
		rewardsPanelCorner.CornerRadius = UDim.new(0, 20)
		rewardsPanelCorner.Parent = rewardsPanel

		local rewardsPanelStroke = Instance.new("UIStroke")
		rewardsPanelStroke.Color = Color3.fromRGB(150, 100, 255)
		rewardsPanelStroke.Thickness = 4
		rewardsPanelStroke.Transparency = 1
		rewardsPanelStroke.Parent = rewardsPanel

		-- Rewards title
		local rewardsTitle = Instance.new("TextLabel")
		rewardsTitle.Size = UDim2.new(1, 0, 0, 40)
		rewardsTitle.Position = UDim2.new(0, 0, 0, 10)
		rewardsTitle.BackgroundTransparency = 1
		rewardsTitle.Font = Enum.Font.FredokaOne
		rewardsTitle.Text = "✨ NEW ABILITIES UNLOCKED ✨"
		rewardsTitle.TextColor3 = Color3.fromRGB(255, 255, 150)
		rewardsTitle.TextSize = 28
		rewardsTitle.TextTransparency = 1
		rewardsTitle.ZIndex = 503
		rewardsTitle.Parent = rewardsPanel

		-- Poop multiplier reward
		local poopMultiplierLabel = Instance.new("TextLabel")
		poopMultiplierLabel.Size = UDim2.new(0.5, -20, 0, 45)
		poopMultiplierLabel.Position = UDim2.new(0, 20, 0, 60)
		poopMultiplierLabel.BackgroundTransparency = 1
		poopMultiplierLabel.Font = Enum.Font.GothamBold
		poopMultiplierLabel.Text = string.format("💩 %dx Poop Gain", successData.poopMultiplier)
		poopMultiplierLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		poopMultiplierLabel.TextSize = 22
		poopMultiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
		poopMultiplierLabel.TextTransparency = 1
		poopMultiplierLabel.ZIndex = 503
		poopMultiplierLabel.Parent = rewardsPanel

		-- Speed boost reward
		local speedBoostLabel = Instance.new("TextLabel")
		speedBoostLabel.Size = UDim2.new(0.5, -20, 0, 45)
		speedBoostLabel.Position = UDim2.new(0.5, 0, 0, 60)
		speedBoostLabel.BackgroundTransparency = 1
		speedBoostLabel.Font = Enum.Font.GothamBold
		speedBoostLabel.Text = string.format("⚡ +%.0f%% Speed", successData.speedBoost * 100)
		speedBoostLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
		speedBoostLabel.TextSize = 22
		speedBoostLabel.TextXAlignment = Enum.TextXAlignment.Right
		speedBoostLabel.TextTransparency = 1
		speedBoostLabel.ZIndex = 503
		speedBoostLabel.Parent = rewardsPanel

		-- Continue button
		local continueButton = Instance.new("TextButton")
		continueButton.Name = "ContinueButton"
		continueButton.Size = UDim2.new(0, 250, 0, 60)
		continueButton.Position = UDim2.new(0.5, -125, 0.8, 0)
		continueButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		continueButton.BorderSizePixel = 0
		continueButton.Font = Enum.Font.FredokaOne
		continueButton.Text = "CONTINUE"
		continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		continueButton.TextSize = 32
		continueButton.TextStrokeTransparency = 0.5
		continueButton.TextTransparency = 1
		continueButton.ZIndex = 502
		continueButton.Parent = celebrationOverlay

		local continueButtonCorner = Instance.new("UICorner")
		continueButtonCorner.CornerRadius = UDim.new(0, 15)
		continueButtonCorner.Parent = continueButton

		-- === ANIMATION SEQUENCE ===

		-- Step 1: Flash effect
		task.spawn(function()
			for i = 1, 3 do
				flashFrame.BackgroundTransparency = 0.5
				task.wait(0.1)
				flashFrame.BackgroundTransparency = 1
				task.wait(0.1)
			end
		end)

		-- Step 2: Fade in dark overlay
		TweenService:Create(celebrationOverlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 0.7
		}):Play()

		-- Step 3: Scale in title (after small delay)
		task.wait(0.4)
		titleLabel.Size = UDim2.new(0, 0, 0, 0)
		titleLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
		titleLabel.TextTransparency = 0

		TweenService:Create(titleLabel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 800, 0, 150),
			Position = UDim2.new(0.5, -400, 0.3, -75)
		}):Play()

		-- Step 4: Rainbow color animation for title
		task.spawn(function()
			for i = 1, 60 do
				titleLabel.TextColor3 = Color3.fromHSV((i / 30) % 1, 1, 1)
				task.wait(0.05)
			end
			titleLabel.TextColor3 = Color3.fromRGB(255, 200, 255) -- Final color
		end)

		-- Step 5: Fade in level name
		task.wait(0.3)
		TweenService:Create(levelLabel, TweenInfo.new(0.4), {
			TextTransparency = 0
		}):Play()

		-- Step 6: Slide in rewards panel
		task.wait(0.3)
		rewardsPanel.Position = UDim2.new(0.5, -350, 1, 0)

		TweenService:Create(rewardsPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.2,
			Position = UDim2.new(0.5, -350, 0.6, 0)
		}):Play()

		TweenService:Create(rewardsPanelStroke, TweenInfo.new(0.5), {
			Transparency = 0.3
		}):Play()

		-- Step 7: Fade in rewards text
		task.wait(0.2)
		TweenService:Create(rewardsTitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
		task.wait(0.15)
		TweenService:Create(poopMultiplierLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
		task.wait(0.15)
		TweenService:Create(speedBoostLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

		-- Step 8: Show continue button
		task.wait(0.3)
		TweenService:Create(continueButton, TweenInfo.new(0.3), {
			TextTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		}):Play()

		-- Button pulse animation
		task.spawn(function()
			while continueButton.Parent do
				TweenService:Create(continueButton, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Size = UDim2.new(0, 260, 0, 65)
				}):Play()
				task.wait(0.5)
				TweenService:Create(continueButton, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Size = UDim2.new(0, 250, 0, 60)
				}):Play()
				task.wait(0.5)
			end
		end)

		-- Handle button click to dismiss
		continueButton.MouseButton1Click:Connect(function()
			-- Fade out everything
			TweenService:Create(celebrationOverlay, TweenInfo.new(0.5), {
				BackgroundTransparency = 1
			}):Play()

			for _, child in ipairs(celebrationOverlay:GetChildren()) do
				if child:IsA("GuiObject") then
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						TweenService:Create(child, TweenInfo.new(0.5), {
							TextTransparency = 1
						}):Play()
					end
					if child:IsA("Frame") then
						TweenService:Create(child, TweenInfo.new(0.5), {
							BackgroundTransparency = 1
						}):Play()
					end
				end
			end

			task.wait(0.5)
			celebrationOverlay:Destroy()
		end)

		-- Auto-dismiss after 10 seconds
		task.spawn(function()
			task.wait(10)
			if celebrationOverlay.Parent then
				continueButton.MouseButton1Click:Fire()
			end
		end)
	end)

	print("✅ Rebirth success handler loaded!")
	end
end)

-- ===============================================
-- SPAWN TELEPORT BUTTON
-- ===============================================

-- Create teleport button GUI
local teleportGui = Instance.new("ScreenGui")
teleportGui.Name = "SpawnTeleportGui"
teleportGui.ResetOnSpawn = false
teleportGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
teleportGui.Parent = playerGui

-- Teleport button (bottom center, below inventory)
-- House button (left column below Rebirth)
local teleportButton = Instance.new("ImageButton")
teleportButton.Name = "SpawnTeleportButton"
teleportButton.Size = UDim2.new(0, 64, 0, 64)
	teleportButton.Position = UDim2.new(0, 20, 0.5, 40) -- restored original vertical offset
teleportButton.BackgroundColor3 = Color3.fromRGB(30, 60, 120) -- Fondo más oscuro
teleportButton.BorderSizePixel = 0
teleportButton.AutoButtonColor = true
teleportButton.Image = "rbxassetid://10814531078"
teleportButton.ScaleType = Enum.ScaleType.Fit
teleportButton.Parent = teleportGui
applyUIScale(teleportButton, 0.9, 1.0)

local teleportButtonCorner = Instance.new("UICorner")
teleportButtonCorner.CornerRadius = UDim.new(0.5, 0) -- Circular como los otros botones
teleportButtonCorner.Parent = teleportButton

-- Añadir gradiente como los otros botones
local teleportGradient = Instance.new("UIGradient")
teleportGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 60, 120))
})
teleportGradient.Rotation = 45
teleportGradient.Parent = teleportButton

local teleportButtonStroke = Instance.new("UIStroke")
teleportButtonStroke.Color = Color3.fromRGB(120, 170, 255)
teleportButtonStroke.Thickness = 4 -- Igual que los otros botones
teleportButtonStroke.Parent = teleportButton

-- Mobile adjustments: move slightly and reduce size to fit
if IS_MOBILE then
	-- put house button in the same left column stack as the other icons
	teleportButton.Size = UDim2.new(0, MOBILE_ICON_SIZE, 0, MOBILE_ICON_SIZE)
	-- move up by 10px so it aligns with the other shifted icons
	-- place it below the other two icons (consistent stacking)
	teleportButton.Position = UDim2.new(0, 16, 0.5, MOBILE_ICON_DELTA - 20)
else
	teleportButton.Size = UDim2.new(0, 64, 0, 64)
	teleportButton.Position = UDim2.new(0, 20, 0.5, 40)
end

-- Ensure the house image is a named child for Explorer: "House Icon 2"
local houseIcon = Instance.new("ImageLabel")
houseIcon.Name = "House Icon 2"
houseIcon.Size = UDim2.new(1, 0, 1, 0)
houseIcon.Position = UDim2.new(0, 0, 0, 0)
houseIcon.BackgroundTransparency = 1
houseIcon.Image = "rbxassetid://279461711"
houseIcon.ScaleType = Enum.ScaleType.Fit
houseIcon.ZIndex = 2
houseIcon.Parent = teleportButton
teleportButton.Image = ""

-- Add emoji fallback centered on the button so the icon shows even if image assets fail to load
local houseEmoji = Instance.new("TextLabel")
-- Replace emoji with image
local houseImage = Instance.new("ImageLabel")
houseImage.Name = "HouseImage" 
houseImage.Size = UDim2.new(0.8, 0, 0.8, 0)
houseImage.Position = UDim2.new(0.1, 0, 0.1, 0)
houseImage.BackgroundTransparency = 1
houseImage.Image = "rbxassetid://12941020168"
houseImage.ScaleType = Enum.ScaleType.Fit
houseImage.ZIndex = 3
houseImage.Parent = teleportButton

-- Hover/tap feedback
local hoverIn = TweenService:Create(teleportButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, teleportButton.Size.X.Offset + 8, 0, teleportButton.Size.Y.Offset + 8)})
local hoverOut = TweenService:Create(teleportButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = teleportButton.Size})
teleportButton.MouseEnter:Connect(function()
	pcall(function() hoverIn:Play() end)
	teleportButtonStroke.Thickness = 6
end)
teleportButton.MouseLeave:Connect(function()
	pcall(function() hoverOut:Play() end)
	teleportButtonStroke.Thickness = 4
end)


-- Function to find nearest spawn point
local function teleportToNearestSpawn()
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local playerPos = humanoidRootPart.Position

	-- Spawn points (Spawn and Desert)
	local spawnPoints = {
		{name = "Spawn", pos = Vector3.new(0, 1, 0), zone = "Spawn"},
		{name = "Desert", pos = Vector3.new(4000, 74, 0), zone = "Desert"}
	}

	-- Find nearest spawn
	local nearestSpawn = nil
	local nearestDistance = math.huge

	for _, spawn in ipairs(spawnPoints) do
		local distance = (spawn.pos - playerPos).Magnitude
		if distance < nearestDistance then
			nearestDistance = distance
			nearestSpawn = spawn
		end
	end

	if nearestSpawn then
		print("🏠 Teleporting to nearest spawn:", nearestSpawn.name)

		-- Teleport using zone system
		local teleportZoneEvent = ReplicatedStorage:FindFirstChild("TeleportZoneEvent")
		if teleportZoneEvent then
			teleportZoneEvent:FireServer(nearestSpawn.zone)
		else
			warn("⚠️ TeleportZoneEvent not found!")
		end
	end
end

-- Button click handler
teleportButton.MouseButton1Click:Connect(function()
	teleportToNearestSpawn()

	-- Visual feedback
	teleportButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	task.wait(0.2)
	teleportButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
end)

print("✅ Spawn Teleport Button created!")


-- Listen for starter pack popup event
local showStarterPackEvent = ReplicatedStorage:WaitForChild("ShowStarterPackEvent")
local purchaseStarterPackEvent = ReplicatedStorage:WaitForChild("PurchaseStarterPackEvent")

showStarterPackEvent.OnClientEvent:Connect(function(price)
	print("Showing Starter Pack popup...")

	-- Create popup GUI
	local starterPackGui = Instance.new("ScreenGui")
	starterPackGui.Name = "StarterPackGui"
	starterPackGui.ResetOnSpawn = false
	starterPackGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	starterPackGui.Parent = playerGui

	-- Dimmed background
	local dimBackground = Instance.new("Frame")
	dimBackground.Name = "DimBackground"
	dimBackground.Size = UDim2.new(1, 0, 1, 0)
	dimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dimBackground.BackgroundTransparency = 0.5
	dimBackground.BorderSizePixel = 0
	dimBackground.Parent = starterPackGui

	-- Main popup frame
	local popupFrame = Instance.new("Frame")
	popupFrame.Name = "PopupFrame"
	popupFrame.Size = UDim2.new(0, 450, 0, 550)
	popupFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
	popupFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	popupFrame.BorderSizePixel = 0
	popupFrame.Parent = starterPackGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 15)
	popupCorner.Parent = popupFrame

	-- Stroke
	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Color3.fromRGB(255, 215, 0)
	popupStroke.Thickness = 4
	popupStroke.Parent = popupFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -40, 0, 70)
	titleLabel.Position = UDim2.new(0, 20, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.Text = "⭐ STARTER PACK ⭐"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextSize = 42
	titleLabel.Parent = popupFrame

	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, -40, 0, 30)
	subtitleLabel.Position = UDim2.new(0, 20, 0, 90)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Text = "Limited Time Offer!"
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleLabel.TextSize = 20
	subtitleLabel.Parent = popupFrame

	-- Rewards container
	local rewardsFrame = Instance.new("Frame")
	rewardsFrame.Name = "RewardsFrame"
	rewardsFrame.Size = UDim2.new(1, -40, 0, 280)
	rewardsFrame.Position = UDim2.new(0, 20, 0, 140)
	rewardsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	rewardsFrame.BorderSizePixel = 0
	rewardsFrame.Parent = popupFrame

	local rewardsCorner = Instance.new("UICorner")
	rewardsCorner.CornerRadius = UDim.new(0, 10)
	rewardsCorner.Parent = rewardsFrame

	-- Reward 1: Coins
	local coinsIcon = Instance.new("TextLabel")
	coinsIcon.Size = UDim2.new(0, 100, 0, 100)
	coinsIcon.Position = UDim2.new(0.5, -50, 0, 20)
	coinsIcon.BackgroundTransparency = 1
	coinsIcon.Font = Enum.Font.FredokaOne
	coinsIcon.Text = "💰"
	coinsIcon.TextSize = 80
	coinsIcon.Parent = rewardsFrame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Size = UDim2.new(1, -20, 0, 40)
	coinsLabel.Position = UDim2.new(0, 10, 0, 120)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Text = "2,000 COINS"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextSize = 28
	coinsLabel.Parent = rewardsFrame

	-- Reward 2: Upgrades
	local upgradesIcon = Instance.new("TextLabel")
	upgradesIcon.Size = UDim2.new(0, 100, 0, 100)
	upgradesIcon.Position = UDim2.new(0.5, -50, 0, 170)
	upgradesIcon.BackgroundTransparency = 1
	upgradesIcon.Font = Enum.Font.FredokaOne
	upgradesIcon.Text = "⚡"
	upgradesIcon.TextSize = 80
	upgradesIcon.Parent = rewardsFrame

	local upgradesLabel = Instance.new("TextLabel")
	upgradesLabel.Size = UDim2.new(1, -20, 0, 40)
	upgradesLabel.Position = UDim2.new(0, 10, 0, 230)
	upgradesLabel.BackgroundTransparency = 1
	upgradesLabel.Font = Enum.Font.GothamBold
	upgradesLabel.Text = "+5 LEVELS ALL UPGRADES"
	upgradesLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	upgradesLabel.TextSize = 22
	upgradesLabel.Parent = rewardsFrame

	-- Purchase button
	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Name = "PurchaseButton"
	purchaseButton.Size = UDim2.new(1, -40, 0, 60)
	purchaseButton.Position = UDim2.new(0, 20, 1, -140)
	purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	purchaseButton.BorderSizePixel = 0
	purchaseButton.Font = Enum.Font.FredokaOne
	purchaseButton.Text = string.format("BUY NOW - %d ROBUX", price)
	purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	purchaseButton.TextSize = 28
	purchaseButton.Parent = popupFrame

	local purchaseCorner = Instance.new("UICorner")
	purchaseCorner.CornerRadius = UDim.new(0, 10)
	purchaseCorner.Parent = purchaseButton

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(1, -40, 0, 50)
	closeButton.Position = UDim2.new(0, 20, 1, -70)
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.Gotham
	closeButton.Text = "Maybe Later"
	closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeButton.TextSize = 18
	closeButton.Parent = popupFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Button handlers
	purchaseButton.MouseButton1Click:Connect(function()
		print("Purchase button clicked")
		purchaseStarterPackEvent:FireServer()
		starterPackGui:Destroy()
	end)

	closeButton.MouseButton1Click:Connect(function()
		print("Popup closed")
		starterPackGui:Destroy()
	end)

	print("✓ Starter Pack popup shown")
end)

print("✅ Starter Pack system initialized!")
