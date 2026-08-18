--[[
    ========================================================================
    🔥 AJIZ HUB - BLOX FRUITS (DIRECT NO-KEY & UNOBFUSCATED BUILD) 🔥
    ========================================================================
    • Pure Direct Launch: No Key Required (Instant Access)
    • Unobfuscated & Clean: 100% Transparent, Fast & Reliable
    • Delta & Mobile Optimized: Safe PlayerGui / gethui / CoreGui Container
    • Clean Checkbox Controls: Auto Level, Auto Quest, Fast Attack, Bring Mobs, Buso, Auto Teleport
    • Header & Footer: Glowing Sky Blue (+ AJIZ HUB - BLOX FRUITS)
    ========================================================================
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- Safe Player Acquisition (Never hangs)
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local CommF = nil
pcall(function()
    CommF = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("CommF_", 5)
end)

-- Configuration Settings
local CONFIG = {
    FlyHeight = 7,     -- Safe farm height above enemies
    AttackSpeed = 0.08 -- Fast attack cooldown
}

-- ========================================================================
-- 🎨 AJIZ UI FRAMEWORK
-- ========================================================================
local AjizLib = {}
AjizLib.__index = AjizLib

-- Safe Container Selector (Compatible with Delta, Codex, Arceus X, Solara, Wave, PC)
local function GetGuiContainer()
    local container = nil
    
    -- 1. Try gethui() (Standard across Delta, Codex, Fluxus)
    pcall(function()
        if gethui then
            container = gethui()
        end
    end)
    if container then return container end

    -- 2. Try PlayerGui (100% accessible on Delta Mobile)
    pcall(function()
        local lp = Players.LocalPlayer
        if lp then
            container = lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 3)
        end
    end)
    if container then return container end

    -- 3. Try CoreGui (PC executors)
    pcall(function()
        container = CoreGui
    end)

    return container or CoreGui
end

-- Theme Palette
local Theme = {
    Background = Color3.fromRGB(15, 17, 24),
    Header = Color3.fromRGB(20, 23, 32),
    Border = Color3.fromRGB(32, 38, 52),
    Accent = Color3.fromRGB(0, 170, 255),       -- Sky Blue
    CheckActive = Color3.fromRGB(235, 60, 60),  -- Red Checkbox [✓]
    CheckInactive = Color3.fromRGB(28, 32, 44),
    ItemBg = Color3.fromRGB(22, 25, 36),
    ItemHover = Color3.fromRGB(30, 35, 50),
    TextPrimary = Color3.fromRGB(245, 248, 255),
    TextMuted = Color3.fromRGB(140, 148, 165),
    Font = Enum.Font.GothamBold,
    FontRegular = Enum.Font.GothamMedium
}

-- Dragging Helper (Touch & Mouse)
local function MakeDraggable(gui, handle)
    handle = handle or gui
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Notification Helper
function AjizLib:Notify(title, message, duration)
    duration = duration or 3
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration
        })
    end)
end

-- ========================================================================
-- 🖥️ MAIN CHECKBOX PANEL
-- ========================================================================
function AjizLib:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "+ AJIZ HUB"
    local GameName = config.GameName or ""
    local FullTitle = TitleText .. (GameName ~= "" and (" - " .. GameName:upper()) or "")
    local FooterText = config.Footer or "Ajiz Hub"

    local container = GetGuiContainer()
    pcall(function()
        if container:FindFirstChild("AjizHub_Panel") then
            container.AjizHub_Panel:Destroy()
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AjizHub_Panel"
    ScreenGui.ResetOnSpawn = false
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    end)
    ScreenGui.Parent = container

    -- Mobile Draggable Toggle Button
    local MobileToggle = Instance.new("ImageButton")
    MobileToggle.Name = "MobileToggle"
    MobileToggle.Size = UDim2.new(0, 36, 0, 36)
    MobileToggle.Position = UDim2.new(0, 15, 0.45, 0)
    MobileToggle.BackgroundColor3 = Theme.Header
    MobileToggle.BorderSizePixel = 0
    MobileToggle.AutoButtonColor = false
    MobileToggle.Parent = ScreenGui
    Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(0, 8)

    local MobileStroke = Instance.new("UIStroke", MobileToggle)
    MobileStroke.Color = Theme.Accent
    MobileStroke.Thickness = 1.2

    local MobileLabel = Instance.new("TextLabel", MobileToggle)
    MobileLabel.Size = UDim2.new(1, 0, 1, 0)
    MobileLabel.BackgroundTransparency = 1
    MobileLabel.Font = Theme.Font
    MobileLabel.Text = "AJ"
    MobileLabel.TextColor3 = Theme.Accent
    MobileLabel.TextSize = 13

    MakeDraggable(MobileToggle)

    -- Main Panel
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 240, 0, 290)
    MainFrame.Position = UDim2.new(0.5, -120, 0.4, -145)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 34)
    Header.BackgroundColor3 = Theme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.Size = UDim2.new(1, -38, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Theme.Font
    TitleLabel.Text = FullTitle
    TitleLabel.TextColor3 = Theme.Accent
    TitleLabel.TextSize = 11.5
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 22, 0, 22)
    MinBtn.Position = UDim2.new(1, -28, 0.5, -11)
    MinBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    MinBtn.Text = "▲"
    MinBtn.Font = Theme.Font
    MinBtn.TextColor3 = Theme.TextMuted
    MinBtn.TextSize = 10
    MinBtn.AutoButtonColor = false
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

    MakeDraggable(MainFrame, Header)

    -- Scrollable Features List
    local ScrollBody = Instance.new("ScrollingFrame")
    ScrollBody.Name = "ScrollBody"
    ScrollBody.Size = UDim2.new(1, -12, 1, -62)
    ScrollBody.Position = UDim2.new(0, 6, 0, 38)
    ScrollBody.BackgroundTransparency = 1
    ScrollBody.BorderSizePixel = 0
    ScrollBody.ScrollBarThickness = 2
    ScrollBody.ScrollBarImageColor3 = Theme.Accent
    ScrollBody.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollBody.Parent = MainFrame

    local Layout = Instance.new("UIListLayout", ScrollBody)
    Layout.Padding = UDim.new(0, 4)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Footer
    local Footer = Instance.new("Frame", MainFrame)
    Footer.Size = UDim2.new(1, 0, 0, 22)
    Footer.Position = UDim2.new(0, 0, 1, -22)
    Footer.BackgroundColor3 = Theme.Header
    Footer.BorderSizePixel = 0

    local FooterLabel = Instance.new("TextLabel", Footer)
    FooterLabel.Size = UDim2.new(1, 0, 1, 0)
    FooterLabel.BackgroundTransparency = 1
    FooterLabel.Font = Theme.Font
    FooterLabel.Text = FooterText
    FooterLabel.TextColor3 = Theme.Accent
    FooterLabel.TextSize = 11

    -- Minimize & Toggle Logic
    local isMin = false
    local isVis = true

    MobileToggle.MouseButton1Click:Connect(function()
        isVis = not isVis
        MainFrame.Visible = isVis
    end)

    MinBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        if isMin then
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 240, 0, 34)
            }):Play()
            MinBtn.Text = "▼"
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 240, 0, 290)
            }):Play()
            MinBtn.Text = "▲"
        end
    end)

    local Panel = {}

    -- Checkbox Toggle Builder
    function Panel:AddToggle(title, default, callback)
        callback = callback or function() end
        local state = default or false

        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = title .. "_Item"
        ItemBtn.Size = UDim2.new(1, 0, 0, 32)
        ItemBtn.BackgroundColor3 = Theme.ItemBg
        ItemBtn.BorderSizePixel = 0
        ItemBtn.AutoButtonColor = false
        ItemBtn.Text = ""
        ItemBtn.Parent = ScrollBody
        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemBtn)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemBtn)
        Title.Size = UDim2.new(1, -38, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.TextPrimary
        Title.TextSize = 11
        Title.TextXAlignment = Enum.TextXAlignment.Left

        -- Square Checkbox Box
        local Box = Instance.new("Frame", ItemBtn)
        Box.Size = UDim2.new(0, 16, 0, 16)
        Box.Position = UDim2.new(1, -26, 0.5, -8)
        Box.BackgroundColor3 = state and Theme.CheckActive or Theme.CheckInactive
        Box.BorderSizePixel = 0
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 3)

        local Checkmark = Instance.new("TextLabel", Box)
        Checkmark.Size = UDim2.new(1, 0, 1, 0)
        Checkmark.BackgroundTransparency = 1
        Checkmark.Font = Theme.Font
        Checkmark.Text = "✓"
        Checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        Checkmark.TextSize = 10
        Checkmark.TextTransparency = state and 0 or 1

        local function update(newState)
            state = newState
            TweenService:Create(Box, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = state and Theme.CheckActive or Theme.CheckInactive
            }):Play()
            TweenService:Create(Checkmark, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = state and 0 or 1
            }):Play()
            task.spawn(callback, state)
        end

        ItemBtn.MouseButton1Click:Connect(function()
            update(not state)
        end)

        ItemBtn.MouseEnter:Connect(function()
            ItemBtn.BackgroundColor3 = Theme.ItemHover
        end)
        ItemBtn.MouseLeave:Connect(function()
            ItemBtn.BackgroundColor3 = Theme.ItemBg
        end)

        return {
            Set = update,
            Get = function() return state end
        }
    end

    return Panel
end

-- ========================================================================
-- 🚀 MAIN BLOX FRUITS GAME ENGINE
-- ========================================================================
local function LaunchMainHub()
    -- Global Feature States
    _G.AutoLevel = false
    _G.AutoQuest = false
    _G.FastAttack = false
    _G.BringMobs = false
    _G.AutoBuso = false
    _G.AutoTeleport = false

    -- Quest & Mob Database (Sea 1, Sea 2, Sea 3)
    local QuestData = {
        { Level = 1,    Quest = "BanditQuest1",    Mob = "Bandit",       LevelReq = 1,    CFrame = CFrame.new(1059, 16, 1549) },
        { Level = 10,   Quest = "JungleQuest",     Mob = "Monkey",       LevelReq = 1,    CFrame = CFrame.new(-1601, 37, 153) },
        { Level = 15,   Quest = "JungleQuest",     Mob = "Gorilla",      LevelReq = 2,    CFrame = CFrame.new(-1237, 6, -486) },
        { Level = 30,   Quest = "BuggyQuest",      Mob = "Pirate",       LevelReq = 1,    CFrame = CFrame.new(-1203, 4, 3915) },
        { Level = 60,   Quest = "DesertQuest",     Mob = "Desert Bandit",LevelReq = 1,    CFrame = CFrame.new(900, 6, 4390) },
        { Level = 90,   Quest = "SnowQuest",       Mob = "Snow Bandit",  LevelReq = 1,    CFrame = CFrame.new(1385, 87, -1298) },
        { Level = 120,  Quest = "MarineQuest2",    Mob = "Chief Petty Officer", LevelReq = 1, CFrame = CFrame.new(-5035, 29, 4325) },
        { Level = 150,  Quest = "SkyQuest",        Mob = "Sky Bandit",   LevelReq = 1,    CFrame = CFrame.new(-4840, 718, -2620) },
        { Level = 200,  Quest = "PrisonerQuest",   Mob = "Prisoner",     LevelReq = 1,    CFrame = CFrame.new(4875, 5, 735) },
        { Level = 700,  Quest = "Area1Quest",      Mob = "Raider",       LevelReq = 1,    CFrame = CFrame.new(-425, 73, 1836) },
        { Level = 1500, Quest = "PortQuest1",      Mob = "Pirate Millionaire", LevelReq = 1, CFrame = CFrame.new(-290, 44, 5580) }
    }

    local function GetPlayerLevel()
        local data = LocalPlayer:FindFirstChild("Data")
        if data and data:FindFirstChild("Level") then
            return data.Level.Value
        end
        return 1
    end

    local function GetCurrentQuestInfo()
        local myLvl = GetPlayerLevel()
        local selected = QuestData[1]
        for _, q in ipairs(QuestData) do
            if myLvl >= q.Level then
                selected = q
            end
        end
        return selected
    end

    local function SafeTweenTo(targetCFrame)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local dist = (root.Position - targetCFrame.Position).Magnitude
        if dist < 15 then
            root.CFrame = targetCFrame
            return
        end

        local speed = 300
        local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
        tween:Play()
        return tween
    end

    local function AutoEquipBestWeapon()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item.ToolTip == "Melee" or item.ToolTip == "Sword" or item.ToolTip == "Blox Fruit") then
                return
            end
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool.ToolTip == "Blox Fruit") then
                    hum:EquipTool(tool)
                    break
                end
            end
        end
    end

    local function FindTargetMob(mobName)
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return nil end

        for _, mob in ipairs(enemies:GetChildren()) do
            if mob.Name == mobName then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                local root = mob:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    return mob
                end
            end
        end
        return nil
    end

    -- Fast Attack Engine
    task.spawn(function()
        while true do
            task.wait(CONFIG.AttackSpeed)
            if _G.FastAttack or _G.AutoLevel then
                pcall(function()
                    local CombatFramework = require(LocalPlayer.PlayerScripts.CombatFramework)
                    local ActiveController = CombatFramework.activeController
                    if ActiveController and ActiveController.equipped then
                        ActiveController.timeToNextAttack = 0
                        ActiveController.hitboxMagnitude = 60
                        ActiveController:attack()
                    else
                        VirtualUser:ClickButton1(Vector2.new(0, 0))
                    end
                end)
            end
        end
    end)

    -- Auto Buso Haki
    task.spawn(function()
        while true do
            task.wait(2)
            if _G.AutoBuso and CommF then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char and not char:FindFirstChild("HasBuso") then
                        CommF:InvokeServer("Buso")
                    end
                end)
            end
        end
    end)

    -- Bring Mobs (Magnet)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if _G.BringMobs and _G.AutoLevel then
                pcall(function()
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local enemies = Workspace:FindFirstChild("Enemies")
                    local qInfo = GetCurrentQuestInfo()
                    if root and enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            if mob.Name == qInfo.Mob then
                                local mRoot = mob:FindFirstChild("HumanoidRootPart")
                                local mHum = mob:FindFirstChildOfClass("Humanoid")
                                if mRoot and mHum and mHum.Health > 0 then
                                    local dist = (mRoot.Position - root.Position).Magnitude
                                    if dist <= 250 and dist > 5 then
                                        mRoot.CFrame = root.CFrame * CFrame.new(0, -CONFIG.FlyHeight, 0)
                                        mRoot.CanCollide = false
                                        mHum.WalkSpeed = 0
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Quest Loop
    task.spawn(function()
        while true do
            task.wait(1)
            if (_G.AutoQuest or _G.AutoLevel) and CommF then
                pcall(function()
                    local gui = LocalPlayer.PlayerGui:FindFirstChild("Main")
                    local questFrame = gui and gui:FindFirstChild("Quest")
                    local hasActiveQuest = questFrame and questFrame.Visible

                    if not hasActiveQuest then
                        local qInfo = GetCurrentQuestInfo()
                        CommF:InvokeServer("StartQuest", qInfo.Quest, qInfo.LevelReq)
                    end
                end)
            end
        end
    end)

    -- Auto Level Master Loop
    task.spawn(function()
        while true do
            task.wait(0.1)
            if _G.AutoLevel then
                pcall(function()
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if not root or not hum or hum.Health <= 0 then return end

                    AutoEquipBestWeapon()
                    local qInfo = GetCurrentQuestInfo()
                    local targetMob = FindTargetMob(qInfo.Mob)

                    if targetMob then
                        local mRoot = targetMob:FindFirstChild("HumanoidRootPart")
                        if mRoot then
                            local safeFarmCF = mRoot.CFrame * CFrame.new(0, CONFIG.FlyHeight, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            root.CFrame = safeFarmCF
                            root.Velocity = Vector3.zero
                        end
                    else
                        if _G.AutoTeleport then
                            SafeTweenTo(qInfo.CFrame)
                        else
                            root.CFrame = qInfo.CFrame
                        end
                    end
                end)
            end
        end
    end)

    -- Build Checkbox UI Panel
    local Panel = AjizLib:CreateWindow({
        Title = "+ AJIZ HUB",
        GameName = "Blox Fruits",
        Footer = "Ajiz Hub"
    })

    Panel:AddToggle("Auto Level", false, function(state)
        _G.AutoLevel = state
        if state then
            _G.AutoQuest = true
            _G.FastAttack = true
            _G.BringMobs = true
            _G.AutoBuso = true
            _G.AutoTeleport = true
        end
    end)

    Panel:AddToggle("Auto Quest", false, function(state)
        _G.AutoQuest = state
    end)

    Panel:AddToggle("Fast Attack", false, function(state)
        _G.FastAttack = state
    end)

    Panel:AddToggle("Bring Mobs (Magnet)", false, function(state)
        _G.BringMobs = state
    end)

    Panel:AddToggle("Auto Buso Haki", false, function(state)
        _G.AutoBuso = state
    end)

    Panel:AddToggle("Auto Teleport", false, function(state)
        _G.AutoTeleport = state
    end)

    AjizLib:Notify("Ajiz Hub", "Ajiz Hub Blox Fruits Loaded!", 3)
end

-- DIRECT LAUNCH (NO KEY REQUIRED FOR NOW)
LaunchMainHub()
