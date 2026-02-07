--[[
    Break-a-Lucky-Block Auto Farm v4.0
    ✅ Ломает блоки
    ✅ Собирает Brainrot
    ✅ Возвращается на базу
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Настройки
local Settings = {
    AutoFarm = false,
    AutoClick = false,
    AutoCollect = true,
    AutoReturnBase = true,
    ClickSpeed = 0.05,
    MaxBrainrots = 1,
    Running = true
}

local Connections = {}
local NearBlock = false
local BlocksCache = {}
local LastBlockScan = 0
local CollectedBrainrots = 0
local PlayerBase = nil

-- Отключение
local function DisconnectAll()
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    Settings.Running = false
    print("[Script] Отключен")
end

-- Получить персонажа
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end


-- Клик мыши
local function ClickMouse()
    local UserInputService = game:GetService("UserInputService")
    if UserInputService:GetFocusedTextBox() then return end
    
    local mouse = LocalPlayer:GetMouse()
    local mouseTarget = mouse.Target
    
    if mouseTarget and mouseTarget:IsDescendantOf(Workspace) then
        local gui = LocalPlayer.PlayerGui:FindFirstChild("BreakLuckyBlockGUI")
        if gui and gui.Enabled then return end
        
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

-- Найти блоки
local function FindBlocks()
    local currentTime = tick()
    if currentTime - LastBlockScan < 5 and #BlocksCache > 0 then
        return BlocksCache
    end
    
    local blocks = {}
    local luckyBlocksFolder = Workspace:FindFirstChild("LuckyBlocks")
    
    if luckyBlocksFolder then
        for _, obj in pairs(luckyBlocksFolder:GetChildren()) do
            if obj:IsA("BasePart") then
                table.insert(blocks, obj)
            elseif obj:IsA("Model") then
                for _, part in pairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        table.insert(blocks, part)
                        break
                    end
                end
            end
            if #blocks >= 50 then break end
        end
    end
    
    BlocksCache = blocks
    LastBlockScan = currentTime
    return blocks
end


-- Ближайший блок
local function GetNearestBlock()
    local hrp = GetHRP()
    if not hrp then return nil, math.huge end
    
    local blocks = FindBlocks()
    if #blocks == 0 then return nil, math.huge end
    
    local nearest, minDist = nil, math.huge
    for _, block in pairs(blocks) do
        if block and block.Parent then
            local dist = (hrp.Position - block.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = block
            end
        end
    end
    return nearest, minDist
end

-- Найти базу
local function FindPlayerBase()
    if PlayerBase then return PlayerBase end
    
    local basesFolder = Workspace:FindFirstChild("Bases")
    if basesFolder then
        for _, base in pairs(basesFolder:GetChildren()) do
            if base.Name == LocalPlayer.Name or base.Name:find(LocalPlayer.Name) then
                if base:IsA("Model") then
                    local part = base:FindFirstChildOfClass("BasePart")
                    if part then
                        PlayerBase = part.Position
                        return PlayerBase
                    end
                elseif base:IsA("BasePart") then
                    PlayerBase = base.Position
                    return PlayerBase
                end
            end
        end
        
        local firstBase = basesFolder:GetChildren()[1]
        if firstBase then
            if firstBase:IsA("Model") then
                local part = firstBase:FindFirstChildOfClass("BasePart")
                if part then
                    PlayerBase = part.Position
                    return PlayerBase
                end
            elseif firstBase:IsA("BasePart") then
                PlayerBase = firstBase.Position
                return PlayerBase
            end
        end
    end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            PlayerBase = obj.Position
            return PlayerBase
        end
    end
    
    local hrp = GetHRP()
    if hrp then
        PlayerBase = hrp.Position
        return PlayerBase
    end
    
    return nil
end


-- Найти Brainrot
local function FindBrainrots()
    local brainrots = {}
    local hrp = GetHRP()
    if not hrp then return brainrots end
    
    local tempFolder = Workspace:FindFirstChild("TemporaryBrainrots")
    if tempFolder then
        for _, obj in pairs(tempFolder:GetChildren()) do
            if obj and obj.Parent then
                table.insert(brainrots, obj)
            end
        end
    end
    
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("brain") then
            local hasPrompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
            if hasPrompt then
                local alreadyAdded = false
                for _, existing in pairs(brainrots) do
                    if existing == obj then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(brainrots, obj)
                end
            end
        end
    end
    
    return brainrots
end

-- Собрать Brainrot
local function CollectBrainrot()
    local hrp = GetHRP()
    if not hrp then return false end
    
    local brainrots = FindBrainrots()
    if #brainrots == 0 then return false end
    
    local nearest, minDist = nil, math.huge
    
    for _, br in pairs(brainrots) do
        if br and br.Parent then
            local pos = br:IsA("Model") and br:GetPivot().Position or br.Position
            local dist = (hrp.Position - pos).Magnitude
            if dist < minDist and dist < 100 then
                minDist = dist
                nearest = br
            end
        end
    end
    
    if nearest then
        local pos = nearest:IsA("Model") and nearest:GetPivot().Position or nearest.Position
        local char = GetCharacter()
        
        if char then
            pcall(function() char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0))) end)
            pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
            task.wait(0.5)
            
            local proximityPrompt = nearest:FindFirstChildOfClass("ProximityPrompt", true)
            if proximityPrompt then
                fireproximityprompt(proximityPrompt)
                task.wait(0.5)
            end
            
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(2.5)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
            
            CollectedBrainrots = CollectedBrainrots + 1
            print("[Collect] Brainrot собран! Счетчик:", CollectedBrainrots)
            
            task.wait(0.3)
            return true
        end
    end
    
    return false
end


-- Вернуться на базу
local function ReturnToBase()
    local base = FindPlayerBase()
    local char = GetCharacter()
    local hrp = GetHRP()
    if not char or not hrp then return false end
    
    if base then
        print("[Base] Возврат на базу...")
        pcall(function() char:PivotTo(CFrame.new(base + Vector3.new(0, 5, 0))) end)
        pcall(function() hrp.CFrame = CFrame.new(base + Vector3.new(0, 5, 0)) end)
        task.wait(1.5)
    else
        print("[Base] База не найдена")
        task.wait(1)
    end
    
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.5)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    CollectedBrainrots = 0
    print("[Base] Brainrot размещен!")
    return true
end

-- Auto Click Loop
local function AutoClickLoop()
    while Settings.Running do
        if Settings.AutoClick and NearBlock then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("BreakLuckyBlockGUI")
            if not gui or not gui.Enabled then
                pcall(ClickMouse)
            end
        end
        task.wait(Settings.ClickSpeed)
    end
end

-- Auto Farm Loop
local function AutoFarmLoop()
    while Settings.Running do
        if Settings.AutoFarm then
            pcall(function()
                local char = GetCharacter()
                local hrp = GetHRP()
                if not char or not hrp then
                    NearBlock = false
                    return
                end
                
                if Settings.AutoCollect then
                    local brainrots = FindBrainrots()
                    if #brainrots > 0 then
                        print("[Farm] Найдено", #brainrots, "Brainrot")
                        if CollectBrainrot() then
                            if Settings.AutoReturnBase and CollectedBrainrots >= Settings.MaxBrainrots then
                                ReturnToBase()
                                task.wait(2)
                            end
                            task.wait(1)
                            return
                        end
                    end
                end
                
                local block, distance = GetNearestBlock()
                if block then
                    NearBlock = distance <= 20
                    
                    if distance > 15 then
                        local targetPos = block.Position + Vector3.new(0, 15, 0)
                        pcall(function() char:PivotTo(CFrame.new(targetPos)) end)
                        pcall(function() hrp.CFrame = CFrame.new(targetPos) end)
                        task.wait(0.3)
                        NearBlock = true
                    end
                    
                    if NearBlock then
                        for i = 1, 5 do
                            ClickMouse()
                            task.wait(0.05)
                        end
                    end
                else
                    NearBlock = false
                end
            end)
        else
            NearBlock = false
        end
        task.wait(0.5)
    end
end


-- GUI
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BreakLuckyBlockGUI"
    ScreenGui.ResetOnSpawn = false
    
    local existing = LocalPlayer.PlayerGui:FindFirstChild("BreakLuckyBlockGUI")
    if existing then existing:Destroy() end
    
    ScreenGui.Parent = LocalPlayer.PlayerGui
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 300, 0, 230)
    Main.Position = UDim2.new(0.5, -150, 0.5, -115)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.ZIndex = 5
    Main.Parent = ScreenGui
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "🎮 Break Lucky Block v4.0"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 6
    Title.Parent = Main
    
    local Div = Instance.new("Frame")
    Div.Size = UDim2.new(1, -20, 0, 1)
    Div.Position = UDim2.new(0, 10, 0, 45)
    Div.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Div.BorderSizePixel = 0
    Div.ZIndex = 6
    Div.Parent = Main
    
    local function CreateToggle(text, yPos, callback)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, -30, 0, 35)
        Frame.Position = UDim2.new(0, 15, 0, yPos)
        Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        Frame.BorderSizePixel = 0
        Frame.ZIndex = 6
        Frame.Parent = Main
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -55, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 7
        Label.Parent = Frame

        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 40, 0, 20)
        Btn.Position = UDim2.new(1, -45, 0.5, -10)
        Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        Btn.Text = "OFF"
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.TextSize = 10
        Btn.Font = Enum.Font.GothamBold
        Btn.BorderSizePixel = 0
        Btn.ZIndex = 10
        Btn.AutoButtonColor = false
        Btn.Parent = Frame
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
        
        local enabled = false
        Btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            local color = enabled and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(80, 80, 100)
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            Btn.Text = enabled and "ON" or "OFF"
            callback(enabled)
        end)
    end
    
    CreateToggle("🔨 Auto Farm (Всё в одном)", 55, function(enabled)
        Settings.AutoFarm = enabled
        Settings.AutoClick = enabled
        Settings.AutoCollect = enabled
        Settings.AutoReturnBase = enabled
        print("[Auto Farm]", enabled and "ON" or "OFF")
    end)
    
    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, -30, 0, 80)
    Info.Position = UDim2.new(0, 15, 0, 100)
    Info.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Info.Text = "Полный автофарм:\n✅ Ломает блоки\n✅ Собирает 1 Brainrot\n✅ Возврат на базу"
    Info.TextColor3 = Color3.fromRGB(150, 200, 150)
    Info.TextSize = 11
    Info.Font = Enum.Font.Gotham
    Info.TextYAlignment = Enum.TextYAlignment.Top
    Info.ZIndex = 6
    Info.Parent = Main
    Instance.new("UICorner", Info).CornerRadius = UDim.new(0, 6)
    local InfoPadding = Instance.new("UIPadding", Info)
    InfoPadding.PaddingTop = UDim.new(0, 10)
    InfoPadding.PaddingLeft = UDim.new(0, 10)
    
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(1, -30, 0, 30)
    Close.Position = UDim2.new(0, 15, 0, 190)
    Close.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    Close.Text = "❌ Закрыть"
    Close.TextColor3 = Color3.fromRGB(255, 255, 255)
    Close.TextSize = 12
    Close.Font = Enum.Font.GothamBold
    Close.BorderSizePixel = 0
    Close.ZIndex = 10
    Close.AutoButtonColor = false
    Close.Parent = Main
    Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
    
    Close.MouseButton1Click:Connect(function()
        Settings.AutoFarm = false
        Settings.AutoClick = false
        DisconnectAll()
        task.wait(0.1)
        ScreenGui:Destroy()
    end)
    
    Main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 300, 0, 230)
    }):Play()
end


-- INIT
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
end))

task.spawn(AutoFarmLoop)
task.spawn(AutoClickLoop)
CreateGUI()

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Break Lucky Block v4.0";
    Text = "✅ Готов к работе!";
    Duration = 5;
})

print("===========================================")
print("Break-a-Lucky-Block v4.0")
print("✅ Auto Farm - ломает блоки")
print("✅ Auto Click - кликает")
print("✅ Auto Collect - собирает Brainrot")
print("✅ Auto Return Base - возврат на базу")
print("===========================================")
