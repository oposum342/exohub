local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "StructureTransparencyGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local originalTransparency = {}
local platformPart = nil
local platformConnection = nil
local isPlatformActive = false

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

-- Функция для переключения прозрачности structure base home
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
        -- Создаем платформу
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

local function createMainGUI()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 160) 
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

  
    local transparencyButton = Instance.new("TextButton")
    transparencyButton.Name = "TransparencyButton"
    transparencyButton.Size = UDim2.new(0.8, 0, 0, 35)
    transparencyButton.Position = UDim2.new(0.1, 0, 0.2, 0)
    transparencyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    transparencyButton.Text = "Toggle Transparency"
    transparencyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    transparencyButton.TextSize = 12
    transparencyButton.Font = Enum.Font.Gotham
    transparencyButton.Parent = frame

    local transparencyButtonCorner = Instance.new("UICorner")
    transparencyButtonCorner.CornerRadius = UDim.new(0, 6)
    transparencyButtonCorner.Parent = transparencyButton

 
    local platformButton = Instance.new("TextButton")
    platformButton.Name = "PlatformButton"
    platformButton.Size = UDim2.new(0.8, 0, 0, 35)
    platformButton.Position = UDim2.new(0.1, 0, 0.55, 0)
    platformButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    platformButton.Text = "Enable Platform"
    platformButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    platformButton.TextSize = 12
    platformButton.Font = Enum.Font.Gotham
    platformButton.Parent = frame

    local platformButtonCorner = Instance.new("UICorner")
    platformButtonCorner.CornerRadius = UDim.new(0, 6)
    platformButtonCorner.Parent = platformButton

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

    addDragging(frame)
    animateIn(frame)
    return frame
end

createMainGUI()
