local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local gui = Instance.new("ScreenGui")
gui.Name = "StructureTransparencyGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
local espEnabled = false
local espObjects = {}
local originalTransparency = {}
local platformPart
local platformConnection
local isPlatformActive = false
local speedBoostActive = false
local speedConn
local effectsActive = false
local effectsConn
local hitboxesHidden = false
local storedHitboxes = {}

local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

local function findStructureBaseHomes(parent)
    local structures = {}
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("BasePart") and string.lower(child.Name) == "structure base home" then
            table.insert(structures, child)
        end
        local nested = findStructureBaseHomes(child)
        for _, v in pairs(nested) do table.insert(structures, v) end
    end
    return structures
end

local function toggleStructureTransparency()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local enabling = next(originalTransparency) == nil
    if enabling then
        for _, plot in pairs(plots:GetChildren()) do
            local dec = plot:FindFirstChild("Decorations")
            if dec then
                for _, s in pairs(findStructureBaseHomes(dec)) do
                    if s and s:IsA("BasePart") and originalTransparency[s] == nil then
                        originalTransparency[s] = s.Transparency
                        pcall(function() s.Transparency = 0.5 end)
                    end
                end
            end
        end
        return true
    else
        for s, val in pairs(originalTransparency) do
            if s and s.Parent then
                pcall(function() s.Transparency = val end)
            end
        end
        originalTransparency = {}
        return false
    end
end

local function resetAllTransparenciesToOne()
    for s, _ in pairs(originalTransparency) do
        if s and s.Parent then
            pcall(function() s.Transparency = 1 end)
        end
    end
    originalTransparency = {}
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        local dec = plot:FindFirstChild("Decorations")
        if dec then
            for _, s in pairs(findStructureBaseHomes(dec)) do
                if s and s.Parent then
                    pcall(function() s.Transparency = 1 end)
                end
            end
        end
    end
end

local function togglePlatform()
    if isPlatformActive then
        if platformConnection then pcall(function() platformConnection:Disconnect() end); platformConnection = nil end
        if platformPart then pcall(function() platformPart:Destroy() end); platformPart = nil end
        isPlatformActive = false
        return false
    else
        if platformConnection then pcall(function() platformConnection:Disconnect() end); platformConnection = nil end
        if platformPart then pcall(function() platformPart:Destroy() end); platformPart = nil end

        platformPart = Instance.new("Part")
        platformPart.Name = "PlayerPlatform"
        platformPart.Size = Vector3.new(8, 0.8, 8)
        platformPart.Anchored = true
        platformPart.CanCollide = true
        platformPart.Material = Enum.Material.Neon
        platformPart.BrickColor = BrickColor.new("Bright blue")
        platformPart.Transparency = 0.3
        platformPart.Parent = workspace

        platformConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local targetY = root.Position.Y - 3.5
            platformPart.Position = Vector3.new(root.Position.X, targetY, root.Position.Z)
        end)

        isPlatformActive = true
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
    local head = character:FindFirstChild("Head")
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
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
        table.insert(espObjects[character], billboard)
    end
    local conn
    conn = character.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") and espEnabled then
            task.wait(0.05)
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
    table.insert(espObjects[character], conn)
    character.Destroying:Connect(function()
        if espObjects[character] then
            for _, o in pairs(espObjects[character]) do pcall(function() safeDestroy(o) end) end
            espObjects[character] = nil
        end
    end)
end

local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then createESP(p.Character, p.Name) end
            p.CharacterAdded:Connect(function(c) if espEnabled then task.wait(0.5); createESP(c, p.Name) end end)
        end
    else
        for _, tbl in pairs(espObjects) do
            for _, o in pairs(tbl) do pcall(function() safeDestroy(o) end) end
        end
        espObjects = {}
    end
    return espEnabled
end

local function enableStealSpeedBoostToggle()
    speedBoostActive = not speedBoostActive
    if speedBoostActive then
        local function applyToChar(c)
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                pcall(function() h.WalkSpeed = 11 end)
                c:WaitForChild("Humanoid").Died:Connect(function() pcall(function() h.WalkSpeed = 16 end) end)
            end
        end
        if LocalPlayer.Character then applyToChar(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.1); applyToChar(c) end)
    else
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.WalkSpeed = 16 end) end
    end
    return speedBoostActive
end

local effectsConnections = {}
local function disableNegativeEffectsToggle()
    effectsActive = not effectsActive
    local lighting = game:GetService("Lighting")
    local camera = workspace.CurrentCamera

    local function scanAndClean(container)
        for _, c in pairs(container:GetChildren()) do
            cleanPossibleEffect(c)
        end
    end

    if effectsActive then
        scanAndClean(LocalPlayer:WaitForChild("PlayerGui"))
        scanAndClean(lighting)
        scanAndClean(workspace)
        if camera then scanAndClean(camera) end

        if effectsConnections.PlayerGuiConn then pcall(function() effectsConnections.PlayerGuiConn:Disconnect() end) end
        effectsConnections.PlayerGuiConn = LocalPlayer.PlayerGui.ChildAdded:Connect(function(c) task.wait(0.02); cleanPossibleEffect(c) end)

        if effectsConnections.LightingConn then pcall(function() effectsConnections.LightingConn:Disconnect() end) end
        effectsConnections.LightingConn = lighting.ChildAdded:Connect(function(c) task.wait(0.02); cleanPossibleEffect(c) end)

        if effectsConnections.WorkspaceConn then pcall(function() effectsConnections.WorkspaceConn:Disconnect() end) end
        effectsConnections.WorkspaceConn = workspace.ChildAdded:Connect(function(c) task.wait(0.02); cleanPossibleEffect(c) end)

        if camera then
            if effectsConnections.CameraConn then pcall(function() effectsConnections.CameraConn:Disconnect() end) end
            effectsConnections.CameraConn = camera.ChildAdded:Connect(function(c) task.wait(0.02); cleanPossibleEffect(c) end)
        end
    else
        if effectsConnections.PlayerGuiConn then pcall(function() effectsConnections.PlayerGuiConn:Disconnect() end); effectsConnections.PlayerGuiConn = nil end
        if effectsConnections.LightingConn then pcall(function() effectsConnections.LightingConn:Disconnect() end); effectsConnections.LightingConn = nil end
        if effectsConnections.WorkspaceConn then pcall(function() effectsConnections.WorkspaceConn:Disconnect() end); effectsConnections.WorkspaceConn = nil end
        if effectsConnections.CameraConn then pcall(function() effectsConnections.CameraConn:Disconnect() end); effectsConnections.CameraConn = nil end
    end

    return effectsActive
end

local function disableNegativeEffectsToggle()
    effectsActive = not effectsActive
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    if effectsActive then
        local function cleanChild(c)
            local n = tostring(c.Name):lower()
            if string.find(n, "boogie") or string.find(n, "paint") or string.find(n, "bee") or string.find(n, "launcher") or string.find(n, "blur") or string.find(n, "vignette") then
                pcall(function() c:Destroy() end)
            end
        end
        for _, c in pairs(pg:GetChildren()) do cleanChild(c) end
        effectsConn = pg.ChildAdded:Connect(function(c) if effectsActive then cleanChild(c) end end)
    else
        if effectsConn then pcall(function() effectsConn:Disconnect() end); effectsConn = nil end
    end
    return effectsActive
end

local function toggleStealHitboxes()
    hitboxesHidden = not hitboxesHidden
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    if hitboxesHidden then
        for _, plot in pairs(plots:GetChildren()) do
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "StealHitbox" then
                    if not storedHitboxes[obj] then storedHitboxes[obj] = obj.Position end
                    pcall(function() obj.Position = obj.Position - Vector3.new(0, 950, 0) end)
                end
            end
        end
    else
        for obj, pos in pairs(storedHitboxes) do
            if obj and obj.Parent then pcall(function() obj.Position = pos end) end
        end
        storedHitboxes = {}
    end
    return hitboxesHidden
end

local function createDesyncEffect()
    local desyncFrame = Instance.new("Frame")
    desyncFrame.Name = "DesyncFrame"
    desyncFrame.Size = UDim2.new(1, 0, 1, 0)
    desyncFrame.Position = UDim2.new(0, 0, 0, 0)
    desyncFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    desyncFrame.BackgroundTransparency = 0
    desyncFrame.BorderSizePixel = 0
    desyncFrame.ZIndex = 1000
    desyncFrame.Parent = gui

    local desyncText = Instance.new("TextLabel")
    desyncText.Size = UDim2.new(1, 0, 0, 80)
    desyncText.Position = UDim2.new(0, 0, 0.38, 0)
    desyncText.BackgroundTransparency = 1
    desyncText.Text = "Exo is Desyncing you..."
    desyncText.TextColor3 = Color3.new(1, 1, 1)
    desyncText.TextScaled = true
    desyncText.Font = Enum.Font.GothamBold
    desyncText.TextStrokeTransparency = 0
    desyncText.TextStrokeColor3 = Color3.new(0, 0, 0)
    desyncText.ZIndex = 1001
    desyncText.Parent = desyncFrame

    local progressBarBackground = Instance.new("Frame")
    progressBarBackground.Size = UDim2.new(0.6, 0, 0, 20)
    progressBarBackground.Position = UDim2.new(0.2, 0, 0.6, 0)
    progressBarBackground.BackgroundColor3 = Color3.fromRGB(72, 72, 72)
    progressBarBackground.BorderSizePixel = 0
    progressBarBackground.ZIndex = 1001
    progressBarBackground.Parent = desyncFrame
    local pbgCorner = Instance.new("UICorner", progressBarBackground); pbgCorner.CornerRadius = UDim.new(0, 10)

    local progressBar = Instance.new("Frame")
    progressBar.Name = "DesyncProgress"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.new(1, 0, 0)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 1002
    progressBar.Parent = progressBarBackground
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 10)

    local progressTween = TweenService:Create(progressBar, TweenInfo.new(4, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
    progressTween:Play()
    progressTween.Completed:Connect(function()
        pcall(function() desyncFrame:Destroy() end)
    end)

    return desyncFrame
end
local function showNotification(text, color)
    color = color or Color3.fromRGB(0,255,0)
    local n = Instance.new("Frame")
    n.Size = UDim2.new(0, 320, 0, 46)
    n.Position = UDim2.new(0.5, -160, 0.06, 0)
    n.AnchorPoint = Vector2.new(0,0)
    n.BackgroundColor3 = Color3.fromRGB(25,25,25)
    n.BackgroundTransparency = 0.25
    n.ZIndex = 1000
    n.Parent = gui
    local corner = Instance.new("UICorner", n); corner.CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", n); stroke.Thickness = 1; stroke.Color = Color3.fromRGB(60,60,60)
    local label = Instance.new("TextLabel", n)
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.ZIndex = 1001
    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
    TweenService:Create(n, TweenInfo.new(0.25), {BackgroundTransparency = 0.25}):Play()
    task.delay(3, function()
        TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
        local t = TweenService:Create(n, TweenInfo.new(0.25), {BackgroundTransparency = 1})
        t:Play()
        t.Completed:Wait()
        pcall(function() n:Destroy() end)
    end)
end

local function clampFramePosition(frame, desired)
    local cam = workspace.CurrentCamera
    if not cam then return desired end
    local vs = cam.ViewportSize
    local fw = frame.AbsoluteSize.X
    local fh = frame.AbsoluteSize.Y
    local x = math.clamp(desired.X, 0, vs.X - fw)
    local y = math.clamp(desired.Y, 0, vs.Y - fh)
    return Vector2.new(x, y)
end

local function updateButtonState(btn, state)
	if state then
		btn.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
	else
		btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	end
end

local function createMainGUI()
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 290)
	frame.Position = UDim2.new(0.5, -110, 0.5, -145)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 35)
	title.BackgroundTransparency = 1
	title.Text = "Exo Hub"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local buttonNames = {
		{ "Transparency", Color3.fromRGB(55, 55, 55) },
		{ "Platform", Color3.fromRGB(55, 55, 55) },
		{ "ESP", Color3.fromRGB(55, 55, 55) },
		{ "Steal Speed Boost", Color3.fromRGB(55, 55, 55) },
		{ "Disable Effects", Color3.fromRGB(55, 55, 55) },
	}

	local buttons = {}
	for i, info in ipairs(buttonNames) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.85, 0, 0, 35)
		btn.Position = UDim2.new(0.075, 0, 0, 35 + (i - 1) * 42)
		btn.BackgroundColor3 = info[2]
		btn.Text = info[1]
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextTransparency = 0
		btn.TextSize = 14
		btn.Font = Enum.Font.GothamBold
		btn.ZIndex = 5
		btn.Parent = frame

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 8)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Thickness = 1
		bStroke.Color = Color3.fromRGB(90, 90, 90)
		bStroke.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = info[2]}):Play()
		end)

		buttons[info[1]] = btn
	end

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 28, 0, 28)
	closeButton.Position = UDim2.new(1, -34, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 16
	closeButton.ZIndex = 10
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		resetAllTransparenciesToOne()
		if platformPart then pcall(function() platformPart:Destroy() end) end
		gui:Destroy()
	end)

	-- кнопки:
	buttons["Transparency"].MouseButton1Click:Connect(function()
		local state = toggleStructureTransparency()
		updateButtonState(buttons["Transparency"], state)
		showNotification("Transparency " .. (state and "enabled" or "disabled"))
	end)

	buttons["Platform"].MouseButton1Click:Connect(function()
		local state = togglePlatform()
		updateButtonState(buttons["Platform"], state)
		showNotification("Platform " .. (state and "enabled" or "disabled"))
	end)

	buttons["ESP"].MouseButton1Click:Connect(function()
		local state = toggleESP()
		updateButtonState(buttons["ESP"], state)
		showNotification("ESP " .. (state and "enabled" or "disabled"))
	end)

buttons["Steal Speed Boost"].MouseButton1Click:Connect(function()
	speedBoostActive = not speedBoostActive
	local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if h then
		h.WalkSpeed = speedBoostActive and 21 or 16
	end
	updateButtonState(buttons["Steal Speed Boost"], speedBoostActive)
	showNotification("Speed " .. (speedBoostActive and "set to 21" or "reset to 16"))
end)

	buttons["Disable Effects"].MouseButton1Click:Connect(function()
		local state = disableNegativeEffectsToggle()
		updateButtonState(buttons["Disable Effects"], state)
		showNotification("Negative Effects " .. (state and "disabled" or "enabled"))
	end)

	return frame, buttons
end

createMainGUI()
