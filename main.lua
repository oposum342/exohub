local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local espEnabled = false
local espObjects = {}

local gui = Instance.new("ScreenGui")
gui.Name = "StructureTransparencyGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local originalTransparency = {}
local platformPart = nil
local platformConnection = nil
local isPlatformActive = false

-- Функция для создания эффекта Desync
local function createDesyncEffect()
    -- Создаем черный фон на весь экран
    local desyncFrame = Instance.new("Frame")
    desyncFrame.Size = UDim2.new(1, 0, 1, 0)
    desyncFrame.Position = UDim2.new(0, 0, 0, 0)
    desyncFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    desyncFrame.BackgroundTransparency = 0
    desyncFrame.BorderSizePixel = 0
    desyncFrame.ZIndex = 100
    desyncFrame.Parent = gui

    -- Текст "Exo is Desyning you..."
    local desyncText = Instance.new("TextLabel")
    desyncText.Size = UDim2.new(1, 0, 0, 50)
    desyncText.Position = UDim2.new(0, 0, 0.4, 0)
    desyncText.BackgroundTransparency = 1
    desyncText.Text = "Exo is Desyning you..."
    desyncText.TextColor3 = Color3.new(1, 1, 1)
    desyncText.TextSize = 24
    desyncText.Font = Enum.Font.GothamBold
    desyncText.ZIndex = 101
    desyncText.Parent = desyncFrame

    -- Прогресс бар
    local progressBarBackground = Instance.new("Frame")
    progressBarBackground.Size = UDim2.new(0.6, 0, 0, 20)
    progressBarBackground.Position = UDim2.new(0.2, 0, 0.6, 0)
    progressBarBackground.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    progressBarBackground.BorderSizePixel = 0
    progressBarBackground.ZIndex = 101
    progressBarBackground.Parent = desyncFrame

    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 10)
    progressBarCorner.Parent = progressBarBackground

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.new(1, 0, 0)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 102
    progressBar.Parent = progressBarBackground

    local progressBarInnerCorner = Instance.new("UICorner")
    progressBarInnerCorner.CornerRadius = UDim.new(0, 10)
    progressBarInnerCorner.Parent = progressBar

    -- Анимация прогресс бара (5 секунд)
    local progressTweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local progressTween = TweenService:Create(progressBar, progressTweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
    
    -- Запускаем анимацию
    progressTween:Play()
    
    -- Ждем 5 секунд и удаляем все
    progressTween.Completed:Connect(function()
        wait(0.1)
        desyncFrame:Destroy()
    end)
    
    return desyncFrame
end

local function animateIn(frame)
    frame.Position = UDim2.new(0.5, -frame.Size.X.Offset / 2, -0.5, 0)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -frame.Size.X.Offset / 2, 0.5, -frame.Size.Y.Offset / 2)})
    tween:Play()
end

local function animateOut(frame, callback)
    local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -frame.Size.X.Offset / 2, 1.5, 0)})
    tween.Completed:Connect(function()
        if callback then callback() end
        frame:Destroy()
    end)
    tween:Play()
end

local function addDragging(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function findStructureBaseHomes(parent)
    local structures = {}
    
    for _, child in pairs(parent:GetChildren()) do
        if child.Name == "structure base home" and child:IsA("BasePart") then
            table.insert(structures, child)
        end
        local childStructures = findStructureBaseHomes(child)
        for _, structure in pairs(childStructures) do
            table.insert(structures, structure)
        end
    end
    
    return structures
end

local function toggleStructureTransparency()
    local workspace = game:GetService("Workspace")
    local plotsFolder = workspace:FindFirstChild("Plots")
    
    if not plotsFolder then
        warn("Папка 'Plots' не найдена в Workspace")
        return
    end
    
    local shouldReset = next(originalTransparency) ~= nil
    local objectsChanged = 0
    
    for _, plot in pairs(plotsFolder:GetChildren()) do
        local decorationsFolder = plot:FindFirstChild("Decorations")
        
        if decorationsFolder then
            local allStructures = findStructureBaseHomes(decorationsFolder)
            
            for _, structure in pairs(allStructures) do
                if shouldReset then
                    if originalTransparency[structure] then
                        structure.Transparency = originalTransparency[structure]
                        originalTransparency[structure] = nil
                        objectsChanged += 1
                    end
                else
                    if not originalTransparency[structure] then
                        originalTransparency[structure] = structure.Transparency
                    end
                    structure.Transparency = 0.5
                    objectsChanged += 1
                end
            end
        end
    end
    
    if shouldReset then
        print("Прозрачность сброшена для " .. objectsChanged .. " объектов structure base home")
    else
        print("Прозрачность установлена на 0.5 для " .. objectsChanged .. " объектов structure base home")
    end
    
    return shouldReset, objectsChanged
end

local function togglePlatform()
    if isPlatformActive then
        
        if platformConnection then
            platformConnection:Disconnect()
            platformConnection = nil
        end
        if platformPart then
            platformPart:Destroy()
            platformPart = nil
        end
        isPlatformActive = false
        print("Платформа отключена")
        return false
    else
      
        platformPart = Instance.new("Part")
        platformPart.Name = "PlayerPlatform"
        platformPart.Size = Vector3.new(8, 1, 8)
        platformPart.Anchored = true
        platformPart.CanCollide = true
        platformPart.Material = Enum.Material.Neon
        platformPart.BrickColor = BrickColor.new("Bright blue")
        platformPart.Transparency = 0.3
        platformPart.Parent = workspace
        
        
        platformConnection = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character
            if not character then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not rootPart then return end
            
           
            if character:GetAttribute("Stealing") or humanoid:GetAttribute("Stealing") then
                
                if platformPart then
                    platformPart:Destroy()
                    platformPart = nil
                end
                if platformConnection then
                    platformConnection:Disconnect()
                    platformConnection = nil
                end
                isPlatformActive = false
                print("Платформа убрана из-за атрибута Stealing")
                return
            end
            
           
            local currentPos = rootPart.Position
            local platformY = currentPos.Y - 5
            
     
            local rayOrigin = Vector3.new(currentPos.X, platformY + 2, currentPos.Z)
            local rayDirection = Vector3.new(0, -10, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {character, platformPart}
            
            local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            
            if raycastResult and raycastResult.Instance == platformPart then
           
                platformPart.Position = platformPart.Position + Vector3.new(0, 0.1, 0)
            else
       
                platformPart.Position = Vector3.new(currentPos.X, platformY, currentPos.Z)
            end
            
        
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
            if rootPart.Position.Y < platformPart.Position.Y + 3 then
                rootPart.Position = Vector3.new(rootPart.Position.X, platformPart.Position.Y + 3, rootPart.Position.Z)
            end
        end)
        
        isPlatformActive = true
        print("Платформа активирована")
        return true
    end
end

local function createESP(character, playerName)
    if espObjects[character] then return end
    
    espObjects[character] = {}
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "ESPBox"
            box.Adornee = part
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Size = part.Size
            box.Color3 = Color3.fromRGB(255, 165, 0)
            box.Transparency = 0.3
            box.Parent = part
            
          
            local fill = Instance.new("BoxHandleAdornment")
            fill.Name = "ESPFill"
            fill.Adornee = part
            fill.AlwaysOnTop = false
            fill.ZIndex = 5
            fill.Size = part.Size * 0.9
            fill.Color3 = Color3.fromRGB(255, 140, 0)
            fill.Transparency = 0.7
            fill.Parent = part
            
            table.insert(espObjects[character], box)
            table.insert(espObjects[character], fill)
        end
    end
    
    local head = character:WaitForChild("Head", 5)
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPLabel"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = playerName
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard
        
        table.insert(espObjects[character], billboard)
    end
    
    local connection
    connection = character.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") and espEnabled then
            wait(0.1)
            
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "ESPBox"
            box.Adornee = part
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Size = part.Size
            box.Color3 = Color3.fromRGB(255, 165, 0)
            box.Transparency = 0.3
            box.Parent = part
            
            local fill = Instance.new("BoxHandleAdornment")
            fill.Name = "ESPFill"
            fill.Adornee = part
            fill.AlwaysOnTop = false
            fill.ZIndex = 5
            fill.Size = part.Size * 0.9
            fill.Color3 = Color3.fromRGB(255, 140, 0)
            fill.Transparency = 0.7
            fill.Parent = part
            
            table.insert(espObjects[character], box)
            table.insert(espObjects[character], fill)
        end
    end)
    
    table.insert(espObjects[character], connection)
    
    character.Destroying:Connect(function()
        if espObjects[character] then
            for _, espObject in pairs(espObjects[character]) do
                if espObject then
                    pcall(function()
                        espObject:Destroy()
                    end)
                end
            end
            espObjects[character] = nil
        end
    end)
end

local function toggleESP()
    espEnabled = not espEnabled
    
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character then
                    createESP(player.Character, player.Name)
                end
                player.CharacterAdded:Connect(function(character)
                    if espEnabled then
                        wait(1)
                        createESP(character, player.Name)
                    end
                end)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                if espEnabled then
                    wait(1)
                    createESP(character, player.Name)
                end
            end)
        end)
    else
        
        for character, espTable in pairs(espObjects) do
            if espTable then
                for _, espObject in pairs(espTable) do
                    if espObject then
                        pcall(function()
                            espObject:Destroy()
                        end)
                    end
                end
            end
        end
        espObjects = {}
        print("ESP выключен")
    end
    
    return espEnabled
end

local function createMainGUI()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 250) -- Увеличили высоту для новой кнопки
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Exo Hub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- Кнопка Transparency
    local transparencyButton = Instance.new("TextButton")
    transparencyButton.Name = "TransparencyButton"
    transparencyButton.Size = UDim2.new(0.8, 0, 0, 30)
    transparencyButton.Position = UDim2.new(0.1, 0, 0.15, 0)
    transparencyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    transparencyButton.Text = "Toggle Transparency"
    transparencyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    transparencyButton.TextSize = 12
    transparencyButton.Font = Enum.Font.Gotham
    transparencyButton.Parent = frame

    local transparencyButtonCorner = Instance.new("UICorner")
    transparencyButtonCorner.CornerRadius = UDim.new(0, 6)
    transparencyButtonCorner.Parent = transparencyButton

    -- Кнопка Platform
    local platformButton = Instance.new("TextButton")
    platformButton.Name = "PlatformButton"
    platformButton.Size = UDim2.new(0.8, 0, 0, 30)
    platformButton.Position = UDim2.new(0.1, 0, 0.30, 0)
    platformButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    platformButton.Text = "Enable Platform"
    platformButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    platformButton.TextSize = 12
    platformButton.Font = Enum.Font.Gotham
    platformButton.Parent = frame

    local platformButtonCorner = Instance.new("UICorner")
    platformButtonCorner.CornerRadius = UDim.new(0, 6)
    platformButtonCorner.Parent = platformButton

    -- Кнопка для ESP
    local espButton = Instance.new("TextButton")
    espButton.Name = "ESPButton"
    espButton.Size = UDim2.new(0.8, 0, 0, 30)
    espButton.Position = UDim2.new(0.1, 0, 0.45, 0)
    espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    espButton.Text = "Enable ESP"
    espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    espButton.TextSize = 12
    espButton.Font = Enum.Font.Gotham
    espButton.Parent = frame

    local espButtonCorner = Instance.new("UICorner")
    espButtonCorner.CornerRadius = UDim.new(0, 6)
    espButtonCorner.Parent = espButton

    -- НОВАЯ КНОПКА DESYNC
    local desyncButton = Instance.new("TextButton")
    desyncButton.Name = "DesyncButton"
    desyncButton.Size = UDim2.new(0.8, 0, 0, 30)
    desyncButton.Position = UDim2.new(0.1, 0, 0.60, 0)
    desyncButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    desyncButton.Text = "Desync"
    desyncButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    desyncButton.TextSize = 12
    desyncButton.Font = Enum.Font.GothamBold
    desyncButton.Parent = frame

    local desyncButtonCorner = Instance.new("UICorner")
    desyncButtonCorner.CornerRadius = UDim.new(0, 6)
    desyncButtonCorner.Parent = desyncButton

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame

    local closeButtonCorner = Instance.new("UICorner")
    closeButtonCorner.CornerRadius = UDim.new(0, 12)
    closeButtonCorner.Parent = closeButton
  
    local function setupButtonAnimation(button)
        button.MouseButton1Down:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end)
        button.MouseButton1Up:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
    end

    setupButtonAnimation(transparencyButton)
    setupButtonAnimation(platformButton)
    setupButtonAnimation(espButton)

    -- Отдельная анимация для кнопки Desync
    desyncButton.MouseButton1Down:Connect(function()
        desyncButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    end)
    desyncButton.MouseButton1Up:Connect(function()
        desyncButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    end)
    desyncButton.MouseLeave:Connect(function()
        desyncButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    end)

    closeButton.MouseButton1Down:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    closeButton.MouseButton1Up:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        animateOut(frame)
    end)
   
    transparencyButton.Activated:Connect(function()
        local wasReset, objectsChanged = toggleStructureTransparency()
        if wasReset then
            transparencyButton.Text = "Toggle Transparency"
        else
            transparencyButton.Text = "Reset Transparency"
        end
    end)
  
    platformButton.Activated:Connect(function()
        local isNowActive = togglePlatform()
        if isNowActive then
            platformButton.Text = "Disable Platform"
            platformButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        else
            platformButton.Text = "Enable Platform"
            platformButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)

    espButton.Activated:Connect(function()
        local isNowActive = toggleESP()
        if isNowActive then
            espButton.Text = "Disable ESP"
            espButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        else
            espButton.Text = "Enable ESP"
            espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)

    -- Функция для кнопки Desync
    desyncButton.Activated:Connect(function()
        -- Сохраняем оригинальный текст
        local originalText = desyncButton.Text
        
        -- Создаем эффект Desync
        createDesyncEffect()
        
        -- Меняем текст кнопки на 1 секунду
        desyncButton.Text = "Desync Successfly"
        desyncButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        
        -- Ждем 1 секунду и возвращаем оригинальный текст
        wait(7)
        desyncButton.Text = originalText
        desyncButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    end)

    addDragging(frame)
    animateIn(frame)
    return frame
end

createMainGUI()
