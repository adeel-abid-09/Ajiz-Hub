--[[
    ========================================================================
    🔥 AJIZ HUB - BLOX FRUITS (MODULAR GAME LOGIC) 🔥
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

-- Safe Player Acquisition
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

-- Safe Remote Acquisition
local CommF = nil
pcall(function()
    CommF = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("CommF_", 5)
end)

-- Global Feature Toggles
_G.AutoLevel = false
_G.AutoQuest = false
_G.FastAttack = false
_G.BringMobs = false
_G.AutoBuso = false
_G.Noclip = false

-- In-game Notification Helper
local function Notify(title, msg, dur)
    dur = dur or 3
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = msg,
            Duration = dur
        })
    end)
end

-- ========================================================================
-- 🏝️ ISLAND & QUEST DATABASE (SEA 1)
-- ========================================================================
local Islands = {
    { Name = "Windmill (Starter)", CFrame = CFrame.new(1059, 16, 1549) },
    { Name = "Marine Starter",    CFrame = CFrame.new(-2572, 7, 2045) },
    { Name = "Jungle Island",     CFrame = CFrame.new(-1601, 37, 153) },
    { Name = "Pirate Village",    CFrame = CFrame.new(-1203, 4, 3915) },
    { Name = "Desert Island",     CFrame = CFrame.new(900, 6, 4390) },
    { Name = "Frozen Village",    CFrame = CFrame.new(1385, 87, -1298) },
    { Name = "Marine Fortress",   CFrame = CFrame.new(-5035, 29, 4325) },
    { Name = "Skylands",          CFrame = CFrame.new(-4840, 718, -2620) },
    { Name = "Prison",            CFrame = CFrame.new(4875, 5, 735) },
    { Name = "Colosseum",         CFrame = CFrame.new(-1425, 7, -2792) },
    { Name = "Magma Village",     CFrame = CFrame.new(-5245, 8, 8505) },
    { Name = "Underwater City",   CFrame = CFrame.new(61163, 11, 1819) },
    { Name = "Fountain City",     CFrame = CFrame.new(5125, 59, 4105) }
}

local QuestDatabase = {
    { Level = 1,    Quest = "BanditQuest1",    Mob = "Bandit",       LevelReq = 1,  CFrame = CFrame.new(1059, 16, 1549) },
    { Level = 10,   Quest = "JungleQuest",     Mob = "Monkey",       LevelReq = 1,  CFrame = CFrame.new(-1601, 37, 153) },
    { Level = 15,   Quest = "JungleQuest",     Mob = "Gorilla",      LevelReq = 2,  CFrame = CFrame.new(-1237, 6, -486) },
    { Level = 30,   Quest = "BuggyQuest",      Mob = "Pirate",       LevelReq = 1,  CFrame = CFrame.new(-1203, 4, 3915) },
    { Level = 60,   Quest = "DesertQuest",     Mob = "Desert Bandit",LevelReq = 1,  CFrame = CFrame.new(900, 6, 4390) },
    { Level = 90,   Quest = "SnowQuest",       Mob = "Snow Bandit",  LevelReq = 1,  CFrame = CFrame.new(1385, 87, -1298) },
    { Level = 120,  Quest = "MarineQuest2",    Mob = "Chief Petty Officer", LevelReq = 1, CFrame = CFrame.new(-5035, 29, 4325) },
    { Level = 150,  Quest = "SkyQuest",        Mob = "Sky Bandit",   LevelReq = 1,  CFrame = CFrame.new(-4840, 718, -2620) },
    { Level = 200,  Quest = "PrisonerQuest",   Mob = "Prisoner",     LevelReq = 1,  CFrame = CFrame.new(4875, 5, 735) },
    { Level = 700,  Quest = "Area1Quest",      Mob = "Raider",       LevelReq = 1,  CFrame = CFrame.new(-425, 73, 1836) },
    { Level = 1500, Quest = "PortQuest1",      Mob = "Pirate Millionaire", LevelReq = 1, CFrame = CFrame.new(-290, 44, 5580) }
}

-- Safe Float & Anti-Physics Fall BodyVelocity
local FloatBodyVelocity = nil
local function EnableFloat(root)
    if not FloatBodyVelocity or not FloatBodyVelocity.Parent then
        FloatBodyVelocity = Instance.new("BodyVelocity")
        FloatBodyVelocity.Name = "AjizFloat"
        FloatBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        FloatBodyVelocity.Velocity = Vector3.zero
        FloatBodyVelocity.Parent = root
    end
end

local function DisableFloat()
    if FloatBodyVelocity then
        FloatBodyVelocity:Destroy()
        FloatBodyVelocity = nil
    end
end

-- Continuous Noclip Engine
RunService.Stepped:Connect(function()
    if _G.AutoLevel or _G.Noclip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Safe Teleport / Tween
local function SafeTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    _G.Noclip = true
    EnableFloat(root)

    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 40 then
        root.CFrame = targetCFrame
        DisableFloat()
        _G.Noclip = false
        return
    end

    local speed = 350
    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Connect(function()
        DisableFloat()
        _G.Noclip = false
    end)
    return tween
end

-- Equip Best Attack Tool
local function AutoEquipWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then return end
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

-- Get Current Quest Info for Player Level
local function GetPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then
        return data.Level.Value
    end
    return 1
end

local function GetCurrentQuest()
    local myLvl = GetPlayerLevel()
    local selected = QuestDatabase[1]
    for _, q in ipairs(QuestDatabase) do
        if myLvl >= q.Level then
            selected = q
        end
    end
    return selected
end

-- Find Target Enemy Mob in Workspace
local function GetTargetMob(mobName)
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(mob.Name:lower(), mobName:lower()) then
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                return mob
            end
        end
    end
    return nil
end

-- ========================================================================
-- ⚡ AUTOMATION BACKGROUND WORKERS
-- ========================================================================

-- 1. Fast Attack Loop
task.spawn(function()
    while true do
        task.wait(0.08)
        if _G.FastAttack or _G.AutoLevel then
            pcall(function()
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end

                -- Delta / PC Controller Virtual Click
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(999, 999))
                VirtualUser:Button1Up(Vector2.new(999, 999))
            end)
        end
    end
end)

-- 2. Auto Buso Haki Loop
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

-- 3. Bring Mobs Loop (Magnet)
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.BringMobs and _G.AutoLevel then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local enemies = Workspace:FindFirstChild("Enemies")
                local qInfo = GetCurrentQuest()

                if root and enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        if string.find(mob.Name:lower(), qInfo.Mob:lower()) then
                            local mRoot = mob:FindFirstChild("HumanoidRootPart")
                            local mHum = mob:FindFirstChildOfClass("Humanoid")
                            if mRoot and mHum and mHum.Health > 0 then
                                local dist = (mRoot.Position - root.Position).Magnitude
                                if dist <= 250 and dist > 4 then
                                    mRoot.CFrame = root.CFrame * CFrame.new(0, -6, 0)
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

-- 4. Auto Quest Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if (_G.AutoQuest or _G.AutoLevel) and CommF then
            pcall(function()
                local gui = LocalPlayer.PlayerGui:FindFirstChild("Main")
                local questFrame = gui and gui:FindFirstChild("Quest")
                local hasQuest = questFrame and questFrame.Visible

                if not hasQuest then
                    local qInfo = GetCurrentQuest()
                    CommF:InvokeServer("StartQuest", qInfo.Quest, qInfo.LevelReq)
                end
            end)
        end
    end
end)

-- 5. Auto Level Master Farm Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoLevel then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not root or not hum or hum.Health <= 0 then return end

                AutoEquipWeapon()
                EnableFloat(root)

                local qInfo = GetCurrentQuest()
                local targetMob = GetTargetMob(qInfo.Mob)

                if targetMob then
                    local mRoot = targetMob:FindFirstChild("HumanoidRootPart")
                    if mRoot then
                        -- Position directly 7 studs above enemy with downward angle
                        root.CFrame = mRoot.CFrame * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        root.Velocity = Vector3.zero
                    end
                else
                    -- Move to mob spawn area
                    local dist = (root.Position - qInfo.CFrame.Position).Magnitude
                    if dist > 30 then
                        root.CFrame = qInfo.CFrame * CFrame.new(0, 10, 0)
                    end
                end
            end)
        else
            DisableFloat()
        end
    end
end)

-- ========================================================================
-- 🎨 GUI INTERFACE DELEGATED TO AJIZLIB
-- ========================================================================
local AjizLib = (function()
--[[
    ========================================================================
    🌟 AJIZ HUB - COMPLETE UI & 24H HWID KEY SYSTEM FRAMEWORK (LUAU) 🌟
    ========================================================================
    • 24-Hour HWID Device-Locked Key System with Auto-Save Cache
    • Direct Chrome / Browser Launch on "Get Key" button click (openurl)
    • Clean Checkbox-Only Panel (No sliders, No number inputs, Zero clutter)
    • Header & Footer in Glowing Sky Blue
    • Mobile Draggable "AJ" Toggle Icon & PC Mouse Support
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local AjizLib = {}
AjizLib.__index = AjizLib

-- Safe Container Selector
local function GetGuiContainer()
    if gethui then
        return gethui()
    elseif CoreGui then
        return CoreGui
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Sleek Theme
local Theme = {
    Background = Color3.fromRGB(15, 17, 24),
    Header = Color3.fromRGB(20, 23, 32),
    Border = Color3.fromRGB(32, 38, 52),
    Accent = Color3.fromRGB(0, 170, 255),       -- Sky Blue
    CheckActive = Color3.fromRGB(235, 60, 60),  -- Red Checkbox [✓]
    CheckInactive = Color3.fromRGB(28, 32, 44),
    ItemBg = Color3.fromRGB(22, 25, 36),
    ItemHover = Color3.fromRGB(30, 35, 50),
    InputBg = Color3.fromRGB(11, 13, 18),
    TextPrimary = Color3.fromRGB(245, 248, 255),
    TextMuted = Color3.fromRGB(140, 148, 165),
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(231, 76, 60),
    Font = Enum.Font.GothamBold,
    FontRegular = Enum.Font.GothamMedium
}

-- Dragging Helper
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

-- Get Unique Device HWID
local function GetDeviceHWID()
    local hwid = ""
    pcall(function()
        if gethwid then
            hwid = gethwid()
        else
            hwid = RbxAnalyticsService:GetClientId()
        end
    end)
    if hwid == "" then
        hwid = tostring(LocalPlayer.UserId) .. "_AJIZ_DEV"
    end
    return hwid
end

-- Notification Helper
function AjizLib:Notify(title, message, duration)
    duration = duration or 4
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration
        })
    end)
end

--[[
    ========================================================================
    🔑 KEY SYSTEM BYPASSED
    ========================================================================
--]]
function AjizLib:ValidateKey(config)
    config = config or {}
    AjizLib:Notify("Ajiz Hub", "Key System Bypassed! Loading script...", 3)
    if config.OnSuccess then
        config.OnSuccess()
    end
end

--[[
    ========================================================================
    🖥️ MAIN CHECKBOX PANEL
    ========================================================================
--]]
function AjizLib:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "+ AJIZ HUB"
    local GameName = config.GameName or ""
    local FullTitle = TitleText .. (GameName ~= "" and (" - " .. GameName:upper()) or "")
    local FooterText = config.Footer or "Ajiz Hub"

    local container = GetGuiContainer()

    if container:FindFirstChild("AjizHub_Panel") then
        container.AjizHub_Panel:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AjizHub_Panel"
    ScreenGui.ResetOnSpawn = false
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(ScreenGui) end) end
    ScreenGui.Parent = container

    -- Mobile Draggable Toggle Button
    local MobileToggle = Instance.new("ImageButton")
    MobileToggle.Name = "MobileToggle"
    MobileToggle.Size = UDim2.new(0, 36, 0, 36)
    MobileToggle.Position = UDim2.new(0, 15, 0.45, 0)
    MobileToggle.BackgroundColor3 = Theme.Header
    MobileToggle.BorderSizePixel = 0
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

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -38, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Theme.Font
    TitleLabel.Text = FullTitle
    TitleLabel.TextColor3 = Theme.Accent
    TitleLabel.TextSize = 11.5
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 22, 0, 22)
    MinBtn.Position = UDim2.new(1, -28, 0.5, -11)
    MinBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    MinBtn.Text = "▲"
    MinBtn.Font = Theme.Font
    MinBtn.TextColor3 = Theme.TextMuted
    MinBtn.TextSize = 10
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Header
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
    local Footer = Instance.new("Frame")
    Footer.Size = UDim2.new(1, 0, 0, 22)
    Footer.Position = UDim2.new(0, 0, 1, -22)
    Footer.BackgroundColor3 = Theme.Header
    Footer.BorderSizePixel = 0
    Footer.Parent = MainFrame

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
            local flyout = MainFrame:FindFirstChild("TeleportFlyout")
            if flyout then
                flyout.Visible = false
            end
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 240, 0, 290)
            }):Play()
            MinBtn.Text = "▲"
        end
    end)

    local Panel = {}

    --[[
        ADD TOGGLE / CHECKBOX (Reference Style)
    --]]
    function Panel:AddToggle(title, default, callback)
        callback = callback or function() end
        local state = default or false

        -- Main Container Frame
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 32)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Size = UDim2.new(1, -38, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.TextPrimary
        Title.TextSize = 11
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        -- Square Checkbox Box
        local Box = Instance.new("Frame", ItemFrame)
        Box.Size = UDim2.new(0, 16, 0, 16)
        Box.Position = UDim2.new(1, -26, 0.5, -8)
        Box.BackgroundColor3 = state and Theme.CheckActive or Theme.CheckInactive
        Box.BorderSizePixel = 0
        Box.ZIndex = 2
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 3)

        local Checkmark = Instance.new("TextLabel", Box)
        Checkmark.Size = UDim2.new(1, 0, 1, 0)
        Checkmark.BackgroundTransparency = 1
        Checkmark.Font = Theme.Font
        Checkmark.Text = "✓"
        Checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        Checkmark.TextSize = 10
        Checkmark.TextTransparency = state and 0 or 1
        Checkmark.ZIndex = 3

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = title .. "_ItemBtn"
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Parent = ItemFrame

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
            ItemFrame.BackgroundColor3 = Theme.ItemHover
        end)
        ItemBtn.MouseLeave:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemBg
        end)

        return {
            Set = update,
            Get = function() return state end
        }
    end

    --[[
        ADD ACTION BUTTON
    --]]
    function Panel:AddButton(title, callback)
        callback = callback or function() end

        -- Main Container Frame
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 32)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Size = UDim2.new(1, -38, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.Accent
        Title.TextSize = 11
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        local Arrow = Instance.new("TextLabel", ItemFrame)
        Arrow.Size = UDim2.new(0, 16, 0, 16)
        Arrow.Position = UDim2.new(1, -26, 0.5, -8)
        Arrow.BackgroundTransparency = 1
        Arrow.Font = Theme.Font
        Arrow.Text = "▶"
        Arrow.TextColor3 = Theme.Accent
        Arrow.TextSize = 10
        Arrow.ZIndex = 2

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = title .. "_ItemBtn"
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Parent = ItemFrame

        ItemBtn.MouseButton1Click:Connect(function()
            local clickTween = TweenService:Create(ItemFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.Accent
            })
            clickTween:Play()
            clickTween.Completed:Connect(function()
                TweenService:Create(ItemFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.ItemBg
                }):Play()
            end)
            task.spawn(callback)
        end)

        ItemBtn.MouseEnter:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemHover
        end)
        ItemBtn.MouseLeave:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemBg
        end)
    end

    --[[
        ADD TELEPORT BUTTON & FLYOUT
    --]]
    function Panel:AddTeleportButton(title, items)
        items = items or {}

        local TeleportFlyout = MainFrame:FindFirstChild("TeleportFlyout")
        if not TeleportFlyout then
            TeleportFlyout = Instance.new("Frame")
            TeleportFlyout.Name = "TeleportFlyout"
            TeleportFlyout.Size = UDim2.new(0, 200, 0, 290)
            TeleportFlyout.Position = UDim2.new(1, 8, 0, 0)
            TeleportFlyout.BackgroundColor3 = Theme.Background
            TeleportFlyout.BorderSizePixel = 0
            TeleportFlyout.Visible = false
            TeleportFlyout.Parent = MainFrame
            Instance.new("UICorner", TeleportFlyout).CornerRadius = UDim.new(0, 8)
            Instance.new("UIStroke", TeleportFlyout).Color = Theme.Border

            -- Flyout Header
            local FlyHeader = Instance.new("Frame", TeleportFlyout)
            FlyHeader.Size = UDim2.new(1, 0, 0, 34)
            FlyHeader.BackgroundColor3 = Theme.Header
            FlyHeader.BorderSizePixel = 0

            local FlyTitle = Instance.new("TextLabel", FlyHeader)
            FlyTitle.Size = UDim2.new(1, -30, 1, 0)
            FlyTitle.Position = UDim2.new(0, 10, 0, 0)
            FlyTitle.BackgroundTransparency = 1
            FlyTitle.Font = Theme.Font
            FlyTitle.Text = "SELECT LOCATION"
            FlyTitle.TextColor3 = Theme.Accent
            FlyTitle.TextSize = 11
            FlyTitle.TextXAlignment = Enum.TextXAlignment.Left

            local FlyClose = Instance.new("TextButton", FlyHeader)
            FlyClose.Size = UDim2.new(0, 20, 0, 20)
            FlyClose.Position = UDim2.new(1, -26, 0.5, -10)
            FlyClose.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
            FlyClose.Text = "×"
            FlyClose.Font = Theme.Font
            FlyClose.TextColor3 = Theme.Danger
            FlyClose.TextSize = 12
            FlyClose.AutoButtonColor = false
            Instance.new("UICorner", FlyClose).CornerRadius = UDim.new(0, 4)

            FlyClose.MouseButton1Click:Connect(function()
                TeleportFlyout.Visible = false
            end)

            -- Flyout Island Scroll List
            local IslandScroll = Instance.new("ScrollingFrame", TeleportFlyout)
            IslandScroll.Name = "IslandScroll"
            IslandScroll.Size = UDim2.new(1, -10, 1, -40)
            IslandScroll.Position = UDim2.new(0, 5, 0, 36)
            IslandScroll.BackgroundTransparency = 1
            IslandScroll.BorderSizePixel = 0
            IslandScroll.ScrollBarThickness = 2
            IslandScroll.ScrollBarImageColor3 = Theme.Accent
            IslandScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            IslandScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

            local IslandLayout = Instance.new("UIListLayout", IslandScroll)
            IslandLayout.Padding = UDim.new(0, 3)
            IslandLayout.SortOrder = Enum.SortOrder.LayoutOrder

            -- Populate buttons
            for _, item in ipairs(items) do
                local IslandBtn = Instance.new("TextButton", IslandScroll)
                IslandBtn.Size = UDim2.new(1, 0, 0, 26)
                IslandBtn.BackgroundColor3 = Theme.ItemBg
                IslandBtn.BorderSizePixel = 0
                IslandBtn.AutoButtonColor = false
                IslandBtn.Font = Theme.FontRegular
                IslandBtn.Text = " " .. item.Name
                IslandBtn.TextColor3 = Theme.TextPrimary
                IslandBtn.TextSize = 10
                IslandBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UICorner", IslandBtn).CornerRadius = UDim.new(0, 4)

                IslandBtn.MouseEnter:Connect(function() IslandBtn.BackgroundColor3 = Theme.ItemHover end)
                IslandBtn.MouseLeave:Connect(function() IslandBtn.BackgroundColor3 = Theme.ItemBg end)

                IslandBtn.MouseButton1Click:Connect(function()
                    if item.Callback then
                        task.spawn(item.Callback)
                    end
                end)
            end
        end

        local ItemFrame = Instance.new("Frame")
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 32)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Size = UDim2.new(1, -38, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.Accent
        Title.TextSize = 11
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        local Arrow = Instance.new("TextLabel", ItemFrame)
        Arrow.Size = UDim2.new(0, 16, 0, 16)
        Arrow.Position = UDim2.new(1, -26, 0.5, -8)
        Arrow.BackgroundTransparency = 1
        Arrow.Font = Theme.Font
        Arrow.Text = "▶"
        Arrow.TextColor3 = Theme.Accent
        Arrow.TextSize = 10
        Arrow.ZIndex = 2

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = title .. "_ItemBtn"
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Parent = ItemFrame

        ItemBtn.MouseButton1Click:Connect(function()
            TeleportFlyout.Visible = not TeleportFlyout.Visible
        end)

        ItemBtn.MouseEnter:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemHover
        end)
        ItemBtn.MouseLeave:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemBg
        end)
    end

    return Panel
end

return AjizLib

end)()

local Panel = AjizLib:CreateWindow({
    Title = "+ AJIZ HUB",
    GameName = "Blox Fruits",
    Footer = "Ajiz Hub"
})

-- Auto Level
Panel:AddToggle("Auto Level", false, function(state)
    _G.AutoLevel = state
    if state then
        _G.AutoQuest = true
        _G.FastAttack = true
        _G.BringMobs = true
        _G.AutoBuso = true
        Notify("Ajiz Hub", "Auto Farm Started!", 2)
    else
        Notify("Ajiz Hub", "Auto Farm Stopped.", 2)
    end
end)

-- Auto Quest
Panel:AddToggle("Auto Quest", false, function(state)
    _G.AutoQuest = state
end)

-- Fast Attack
Panel:AddToggle("Fast Attack", false, function(state)
    _G.FastAttack = state
end)

-- Bring Mobs (Magnet)
Panel:AddToggle("Bring Mobs (Magnet)", false, function(state)
    _G.BringMobs = state
end)

-- Auto Buso Haki
Panel:AddToggle("Auto Buso Haki", false, function(state)
    _G.AutoBuso = state
end)

-- Teleport Feature (Populates side flyout)
local TeleportItems = {}
for _, island in ipairs(Islands) do
    table.insert(TeleportItems, {
        Name = island.Name,
        Callback = function()
            Notify("Ajiz Teleport", "Teleporting to: " .. island.Name, 2)
            SafeTeleport(island.CFrame)
        end
    })
end
Panel:AddTeleportButton("Teleport", TeleportItems)

Notify("Ajiz Hub", "Ajiz Hub Blox Fruits Loaded!", 3)
