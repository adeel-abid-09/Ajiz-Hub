--[[
    ========================================================================
    🔥 AJIZ HUB - BLOX FRUITS (MODULAR GAME LOGIC) 🔥
    ========================================================================
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- Safe CoreGui Retrieval
local CoreGui = nil
pcall(function()
    CoreGui = game:GetService("CoreGui")
end)

-- Safe Player Acquisition
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

-- Safe Remote Acquisition (Retries in background until found)
local CommF = nil
task.spawn(function()
    while not CommF do
        pcall(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 4)
            if remotes then
                CommF = remotes:WaitForChild("CommF_", 4)
            end
        end)
        if not CommF then
            task.wait(1)
        end
    end
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
    { Level = 190,  Quest = "PrisonerQuest",   Mob = "Prisoner",     LevelReq = 1,  CFrame = CFrame.new(4875, 5, 735) },
    { Level = 225,  Quest = "ColosseumQuest",  Mob = "Gladiator",    LevelReq = 1,  CFrame = CFrame.new(-1425, 7, -2792) },
    { Level = 250,  Quest = "ColosseumQuest",  Mob = "Toga Warrior", LevelReq = 2,  CFrame = CFrame.new(-1425, 7, -2792) },
    { Level = 300,  Quest = "MagmaQuest",      Mob = "Military Soldier", LevelReq = 1, CFrame = CFrame.new(-5245, 8, 8505) },
    { Level = 330,  Quest = "MagmaQuest",      Mob = "Military Spy", LevelReq = 2,  CFrame = CFrame.new(-5245, 8, 8505) },
    { Level = 375,  Quest = "FishmanQuest",    Mob = "Fishman Warrior", LevelReq = 1, CFrame = CFrame.new(61163, 11, 1819) },
    { Level = 400,  Quest = "FishmanQuest",    Mob = "Fishman Commando", LevelReq = 2, CFrame = CFrame.new(61163, 11, 1819) },
    { Level = 450,  Quest = "SkyQuest2",       Mob = "God's Guard",  LevelReq = 1,  CFrame = CFrame.new(-4840, 718, -2620) },
    { Level = 475,  Quest = "SkyQuest2",       Mob = "Shanda",       LevelReq = 2,  CFrame = CFrame.new(-4840, 718, -2620) },
    { Level = 625,  Quest = "FountainQuest",   Mob = "Galleon Pirate", LevelReq = 1, CFrame = CFrame.new(5125, 59, 4105) },
    
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

-- Unified Safe Teleport & Tweening (Supports continuous farm flying)
local currentTween = nil

local function SafeTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    _G.Noclip = true
    EnableFloat(root)

    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 40 then
        root.CFrame = targetCFrame
        DisableFloat()
        _G.Noclip = false
        return
    end

    local speed = 300
    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    currentTween:Play()
    currentTween.Completed:Connect(function()
        DisableFloat()
        _G.Noclip = false
        currentTween = nil
    end)
    return currentTween
end

local function FarmTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 45 then
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        root.CFrame = targetCFrame
        DisableFloat()
        return
    end

    -- If already tweening to target, let it run
    if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end

    _G.Noclip = true
    EnableFloat(root)

    local speed = 300
    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    currentTween:Play()
    currentTween.Completed:Connect(function()
        DisableFloat()
        _G.Noclip = false
        currentTween = nil
    end)
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

    -- Dynamic Level 1 Quest adjustment based on Player Team (Pirate vs Marine)
    if selected.Level == 1 then
        local isMarine = false
        pcall(function()
            if LocalPlayer.Team and string.find(LocalPlayer.Team.Name:lower(), "marine") then
                isMarine = true
            end
        end)
        
        if isMarine then
            return {
                Level = 1,
                Quest = "MarineQuest",
                Mob = "Trainee",
                LevelReq = 1,
                CFrame = CFrame.new(-2572, 7, 2045)
            }
        else
            return {
                Level = 1,
                Quest = "BanditQuest1",
                Mob = "Bandit",
                LevelReq = 1,
                CFrame = CFrame.new(1059, 16, 1549)
            }
        end
    end

    return selected
end

-- Find Target Enemy Mob in Workspace (Checks Enemies folder with Workspace fallback)
local function GetTargetMob(mobName)
    local target = nil
    pcall(function()
        -- 1. Search in Workspace.Enemies
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, mob in ipairs(enemies:GetChildren()) do
                if string.find(mob.Name:lower(), mobName:lower()) then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root then
                        target = mob
                        return
                    end
                end
            end
        end

        -- 2. Fallback: Search directly in Workspace
        for _, mob in ipairs(Workspace:GetChildren()) do
            if mob:IsA("Model") and string.find(mob.Name:lower(), mobName:lower()) then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                local root = mob:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root and not Players:GetPlayerFromCharacter(mob) then
                    target = mob
                    return
                end
            end
        end
    end)
    return target
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

-- 3. Bring Mobs Loop (Magnet with Workspace fallback)
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.BringMobs and _G.AutoLevel then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local qInfo = GetCurrentQuest()
                local list = {}

                -- Gather from Workspace.Enemies
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        table.insert(list, mob)
                    end
                end
                -- Gather from direct children of Workspace
                for _, mob in ipairs(Workspace:GetChildren()) do
                    if mob:IsA("Model") and not Players:GetPlayerFromCharacter(mob) then
                        table.insert(list, mob)
                    end
                end

                for _, mob in ipairs(list) do
                    if string.find(mob.Name:lower(), qInfo.Mob:lower()) then
                        local mRoot = mob:FindFirstChild("HumanoidRootPart")
                        local mHum = mob:FindFirstChildOfClass("Humanoid")
                        if mRoot and mHum and mHum.Health > 0 then
                            local dist = (mRoot.Position - root.Position).Magnitude
                            if dist <= 250 and dist > 4 then
                                mRoot.CFrame = root.CFrame * CFrame.new(0, -6, 0)
                                mRoot.CanCollide = false
                                mHum.WalkSpeed = 0
                                mRoot.Velocity = Vector3.zero
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

                local qInfo = GetCurrentQuest()
                local targetMob = GetTargetMob(qInfo.Mob)

                if targetMob then
                    -- Cancel travel tween if we have a target
                    if currentTween then
                        currentTween:Cancel()
                        currentTween = nil
                    end
                    EnableFloat(root)
                    local mRoot = targetMob:FindFirstChild("HumanoidRootPart")
                    if mRoot then
                        -- Position directly 7 studs above enemy with downward angle
                        root.CFrame = mRoot.CFrame * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        root.Velocity = Vector3.zero
                    end
                else
                    -- Move to mob spawn area using smooth noclip flying to bypass anti-cheat
                    FarmTeleport(qInfo.CFrame * CFrame.new(0, 10, 0))
                end
            end)
        else
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
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
    • Dynamic Name Randomization & Anti-Cheat Hidden CoreGui Parent
    • Robust Executor Polyfills and Compatibility Wrappers
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Safe CoreGui Retrieval
local CoreGui = nil
pcall(function()
    CoreGui = game:GetService("CoreGui")
end)

-- Safe Player Acquisition (No infinite yield)
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    local start = os.clock()
    repeat 
        task.wait(0.1) 
        LocalPlayer = Players.LocalPlayer 
    until LocalPlayer or (os.clock() - start) > 10
end
if not LocalPlayer then
    -- Fallback/fail-safe if still nil
    LocalPlayer = Players.PlayerAdded:Wait()
end

local AjizLib = {}
AjizLib.__index = AjizLib

-- Dynamic Name Generator (Prevents name-based anti-cheat scans)
local function GenerateRandomName(length)
    length = length or math.random(10, 16)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local name = ""
    for i = 1, length do
        local randIndex = math.random(1, #chars)
        name = name .. string.sub(chars, randIndex, randIndex)
    end
    return name
end

-- Safe Container Selector
local function GetGuiContainer()
    if gethui then
        local success, res = pcall(gethui)
        if success and res then return res end
    end
    if CoreGui then
        return CoreGui
    end
    -- Fallback to PlayerGui with a safe wait (to avoid infinite yield)
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        local start = os.clock()
        while not playerGui and (os.clock() - start) < 5 do
            task.wait(0.1)
            playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
    end
    return playerGui or LocalPlayer:WaitForChild("PlayerGui")
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
            local rbxAnalytics = game:GetService("RbxAnalyticsService")
            hwid = rbxAnalytics:GetClientId()
        end
    end)
    if hwid == "" then
        hwid = tostring(LocalPlayer.UserId) .. "_AJIZ_DEV"
    end
    return hwid
end

-- ========================================================================
-- 🛡️ EXECUTOR COMPATIBILITY WRAPPERS & POLYFILLS
-- ========================================================================

function AjizLib:SafeWriteFile(filename, content)
    if writefile then
        local success, err = pcall(function()
            writefile(filename, content)
        end)
        return success, err
    end
    return false, "writefile not supported"
end

function AjizLib:SafeReadFile(filename)
    if readfile then
        local success, content = pcall(readfile, filename)
        if success then return content end
    end
    return nil
end

function AjizLib:SafeIsFile(filename)
    if isfile then
        local success, exists = pcall(isfile, filename)
        return success and exists
    end
    return false
end

function AjizLib:SafeSetClipboard(text)
    if setclipboard then
        pcall(setclipboard, text)
    elseif toclipboard then
        pcall(toclipboard, text)
    else
        print("[AJIZ HUB CLIPBOARD]: " .. tostring(text))
        AjizLib:Notify("Clipboard Warning", "setclipboard not supported. Key output printed to console/chat.", 5)
    end
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
    🖥️ MAIN CHECKBOX PANEL
    ========================================================================
--]]
function AjizLib:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "AJIZ HUB"
    local GameName = config.GameName or ""
    local FullTitle = GameName ~= "" and GameName:upper() or TitleText:upper()
    local FooterText = config.Footer or "Ajiz Hub"

    local container = GetGuiContainer()

    -- Attribute-based safe cleanup (destroys old panels even if names are randomized)
    pcall(function()
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ScreenGui") and child:GetAttribute("AjizHubPanel") then
                child:Destroy()
            end
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GenerateRandomName()
    ScreenGui:SetAttribute("AjizHubPanel", true)
    ScreenGui.ResetOnSpawn = false

    -- Safe protect GUI call
    if syn and syn.protect_gui then 
        pcall(function() syn.protect_gui(ScreenGui) end) 
    end
    
    local success = pcall(function()
        ScreenGui.Parent = container
    end)
    if not success then
        pcall(function()
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    -- Mobile Draggable Toggle Button
    local MobileToggle = Instance.new("ImageButton")
    MobileToggle.Name = GenerateRandomName()
    MobileToggle.Size = UDim2.new(0, 40, 0, 40)
    MobileToggle.Position = UDim2.new(0, 15, 0.45, 0)
    MobileToggle.BackgroundColor3 = Theme.Header
    MobileToggle.BorderSizePixel = 0
    MobileToggle.Active = true
    MobileToggle.Parent = ScreenGui
    Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(0, 8)

    local MobileStroke = Instance.new("UIStroke", MobileToggle)
    MobileStroke.Color = Theme.Accent
    MobileStroke.Thickness = 1.2

    local MobileLabel = Instance.new("TextLabel", MobileToggle)
    MobileLabel.Name = GenerateRandomName()
    MobileLabel.Size = UDim2.new(1, 0, 1, 0)
    MobileLabel.BackgroundTransparency = 1
    MobileLabel.Font = Theme.Font
    MobileLabel.Text = "AJ"
    MobileLabel.TextColor3 = Theme.Accent
    MobileLabel.TextSize = 14

    MakeDraggable(MobileToggle)

    -- Minimize & Height Logic
    local isMin = false
    local isVis = true
    local expandedHeight = 120
    local TeleportFlyout = nil  -- Lexically scoped reference

    -- Main Panel Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = GenerateRandomName()
    MainFrame.Size = UDim2.new(0, 240, 0, 120)
    MainFrame.Position = UDim2.new(0.5, -120, 0.4, -60)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = GenerateRandomName()
    Header.Size = UDim2.new(1, 0, 0, 34)
    Header.BackgroundColor3 = Theme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = GenerateRandomName()
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
    MinBtn.Name = GenerateRandomName()
    MinBtn.Size = UDim2.new(0, 26, 0, 26)
    MinBtn.Position = UDim2.new(1, -32, 0.5, -13)
    MinBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    MinBtn.Text = "▲"
    MinBtn.Font = Theme.Font
    MinBtn.TextColor3 = Theme.TextMuted
    MinBtn.TextSize = 11
    MinBtn.AutoButtonColor = false
    MinBtn.Active = true
    MinBtn.Parent = Header
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

    MakeDraggable(MainFrame, Header)

    -- Scrollable Features List
    local ScrollBody = Instance.new("ScrollingFrame")
    ScrollBody.Name = GenerateRandomName()
    ScrollBody.Size = UDim2.new(1, -12, 0, 60)
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
    Footer.Name = GenerateRandomName()
    Footer.Size = UDim2.new(1, 0, 0, 22)
    Footer.Position = UDim2.new(0, 0, 1, -22)
    Footer.BackgroundColor3 = Theme.Header
    Footer.BorderSizePixel = 0
    Footer.Parent = MainFrame

    local FooterLabel = Instance.new("TextLabel", Footer)
    FooterLabel.Name = GenerateRandomName()
    FooterLabel.Size = UDim2.new(1, 0, 1, 0)
    FooterLabel.BackgroundTransparency = 1
    FooterLabel.Font = Theme.Font
    FooterLabel.Text = FooterText:upper()
    FooterLabel.TextColor3 = Theme.Accent
    FooterLabel.TextSize = 12.5

    -- Auto-scaling height logic based on content size
    local function updateFrameSize()
        if isMin then return end
        local contentHeight = Layout.AbsoluteContentSize.Y
        expandedHeight = math.clamp(contentHeight + 68, 120, 500)
        
        MainFrame.Size = UDim2.new(0, 240, 0, expandedHeight)
        
        local maxScrollHeight = 500 - 68
        ScrollBody.Size = UDim2.new(1, -12, 0, math.min(contentHeight, maxScrollHeight))
    end
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateFrameSize)

    MobileToggle.Activated:Connect(function()
        isVis = not isVis
        MainFrame.Visible = isVis
    end)

    MinBtn.Activated:Connect(function()
        isMin = not isMin
        if isMin then
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 240, 0, 34)
            }):Play()
            MinBtn.Text = "▼"
            if TeleportFlyout then
                TeleportFlyout.Visible = false
            end
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 240, 0, expandedHeight)
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
        ItemFrame.Name = GenerateRandomName()
        ItemFrame.Size = UDim2.new(1, 0, 0, 36)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Name = GenerateRandomName()
        Title.Size = UDim2.new(1, -44, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.TextPrimary
        Title.TextSize = 11.5
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        -- Square Checkbox Box
        local Box = Instance.new("Frame", ItemFrame)
        Box.Name = GenerateRandomName()
        Box.Size = UDim2.new(0, 20, 0, 20)
        Box.Position = UDim2.new(1, -30, 0.5, -10)
        Box.BackgroundColor3 = state and Theme.CheckActive or Theme.CheckInactive
        Box.BorderSizePixel = 0
        Box.ZIndex = 2
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 3)

        local Checkmark = Instance.new("TextLabel", Box)
        Checkmark.Name = GenerateRandomName()
        Checkmark.Size = UDim2.new(1, 0, 1, 0)
        Checkmark.BackgroundTransparency = 1
        Checkmark.Font = Theme.Font
        Checkmark.Text = "✓"
        Checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        Checkmark.TextSize = 12
        Checkmark.TextTransparency = state and 0 or 1
        Checkmark.ZIndex = 3

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = GenerateRandomName()
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Active = true
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

        ItemBtn.Activated:Connect(function()
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
        ItemFrame.Name = GenerateRandomName()
        ItemFrame.Size = UDim2.new(1, 0, 0, 36)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Name = GenerateRandomName()
        Title.Size = UDim2.new(1, -44, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.Accent
        Title.TextSize = 11.5
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        local Arrow = Instance.new("TextLabel", ItemFrame)
        Arrow.Name = GenerateRandomName()
        Arrow.Size = UDim2.new(0, 16, 0, 16)
        Arrow.Position = UDim2.new(1, -30, 0.5, -8)
        Arrow.BackgroundTransparency = 1
        Arrow.Font = Theme.Font
        Arrow.Text = "▶"
        Arrow.TextColor3 = Theme.Accent
        Arrow.TextSize = 10
        Arrow.ZIndex = 2

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = GenerateRandomName()
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Active = true
        ItemBtn.Parent = ItemFrame

        ItemBtn.Activated:Connect(function()
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

        if not TeleportFlyout then
            TeleportFlyout = Instance.new("Frame")
            TeleportFlyout.Name = GenerateRandomName()
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
            FlyHeader.Name = GenerateRandomName()
            FlyHeader.Size = UDim2.new(1, 0, 0, 34)
            FlyHeader.BackgroundColor3 = Theme.Header
            FlyHeader.BorderSizePixel = 0

            local FlyTitle = Instance.new("TextLabel", FlyHeader)
            FlyTitle.Name = GenerateRandomName()
            FlyTitle.Size = UDim2.new(1, -30, 1, 0)
            FlyTitle.Position = UDim2.new(0, 10, 0, 0)
            FlyTitle.BackgroundTransparency = 1
            FlyTitle.Font = Theme.Font
            FlyTitle.Text = "SELECT LOCATION"
            FlyTitle.TextColor3 = Theme.Accent
            FlyTitle.TextSize = 11
            FlyTitle.TextXAlignment = Enum.TextXAlignment.Left

            local FlyClose = Instance.new("TextButton", FlyHeader)
            FlyClose.Name = GenerateRandomName()
            FlyClose.Size = UDim2.new(0, 24, 0, 24)
            FlyClose.Position = UDim2.new(1, -28, 0.5, -12)
            FlyClose.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
            FlyClose.Text = "×"
            FlyClose.Font = Theme.Font
            FlyClose.TextColor3 = Theme.Danger
            FlyClose.TextSize = 13
            FlyClose.AutoButtonColor = false
            FlyClose.Active = true
            Instance.new("UICorner", FlyClose).CornerRadius = UDim.new(0, 4)

            FlyClose.Activated:Connect(function()
                TeleportFlyout.Visible = false
            end)

            -- Flyout Island Scroll List
            local IslandScroll = Instance.new("ScrollingFrame", TeleportFlyout)
            IslandScroll.Name = GenerateRandomName()
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
                IslandBtn.Name = GenerateRandomName()
                IslandBtn.Size = UDim2.new(1, 0, 0, 32)
                IslandBtn.BackgroundColor3 = Theme.ItemBg
                IslandBtn.BorderSizePixel = 0
                IslandBtn.AutoButtonColor = false
                IslandBtn.Font = Theme.FontRegular
                IslandBtn.Text = " " .. item.Name
                IslandBtn.TextColor3 = Theme.TextPrimary
                IslandBtn.TextSize = 10.5
                IslandBtn.TextXAlignment = Enum.TextXAlignment.Left
                IslandBtn.Active = true
                Instance.new("UICorner", IslandBtn).CornerRadius = UDim.new(0, 4)

                IslandBtn.MouseEnter:Connect(function() IslandBtn.BackgroundColor3 = Theme.ItemHover end)
                IslandBtn.MouseLeave:Connect(function() IslandBtn.BackgroundColor3 = Theme.ItemBg end)

                IslandBtn.Activated:Connect(function()
                    if item.Callback then
                        task.spawn(item.Callback)
                    end
                end)
            end
        end

        local ItemFrame = Instance.new("Frame")
        ItemFrame.Name = GenerateRandomName()
        ItemFrame.Size = UDim2.new(1, 0, 0, 36)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Name = GenerateRandomName()
        Title.Size = UDim2.new(1, -44, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title
        Title.TextColor3 = Theme.Accent
        Title.TextSize = 11.5
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        local Arrow = Instance.new("TextLabel", ItemFrame)
        Arrow.Name = GenerateRandomName()
        Arrow.Size = UDim2.new(0, 16, 0, 16)
        Arrow.Position = UDim2.new(1, -30, 0.5, -8)
        Arrow.BackgroundTransparency = 1
        Arrow.Font = Theme.Font
        Arrow.Text = "▶"
        Arrow.TextColor3 = Theme.Accent
        Arrow.TextSize = 10
        Arrow.ZIndex = 2

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = GenerateRandomName()
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Active = true
        ItemBtn.Parent = ItemFrame

        ItemBtn.Activated:Connect(function()
            if TeleportFlyout then
                TeleportFlyout.Visible = not TeleportFlyout.Visible
            end
        end)

        ItemBtn.MouseEnter:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemHover
        end)
        ItemBtn.MouseLeave:Connect(function()
            ItemFrame.BackgroundColor3 = Theme.ItemBg
        end)
    end

    --[[
        ADD SLIDER
    --]]
    function Panel:AddSlider(title, min, max, default, callback)
        min = min or 0
        max = max or 100
        default = default or min
        callback = callback or function() end

        local currentVal = default

        -- Main Container Frame
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Name = GenerateRandomName()
        ItemFrame.Size = UDim2.new(1, 0, 0, 42)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
        Title.Name = GenerateRandomName()
        Title.Size = UDim2.new(1, -20, 0, 20)
        Title.Position = UDim2.new(0, 10, 0, 2)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.Font
        Title.Text = title .. ": " .. tostring(default)
        Title.TextColor3 = Theme.TextPrimary
        Title.TextSize = 10.5
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2

        local Track = Instance.new("TextButton", ItemFrame)
        Track.Name = GenerateRandomName()
        Track.Size = UDim2.new(1, -20, 0, 4)
        Track.Position = UDim2.new(0, 10, 0, 26)
        Track.BackgroundColor3 = Theme.CheckInactive
        Track.BorderSizePixel = 0
        Track.Text = ""
        Track.AutoButtonColor = false
        Track.ZIndex = 2
        Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 2)

        local Fill = Instance.new("Frame", Track)
        Fill.Name = GenerateRandomName()
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Theme.Accent
        Fill.BorderSizePixel = 0
        Fill.ZIndex = 3
        Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 2)

        local Knob = Instance.new("Frame", Fill)
        Knob.Name = GenerateRandomName()
        Knob.Size = UDim2.new(0, 8, 0, 8)
        Knob.Position = UDim2.new(1, -4, 0.5, -4)
        Knob.BackgroundColor3 = Theme.Accent
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 4
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        local function update(val, animate)
            currentVal = math.clamp(val, min, max)
            local displayVal = math.round(currentVal)
            Title.Text = title .. ": " .. tostring(displayVal)
            
            local percentage = (currentVal - min) / (max - min)
            local targetSize = UDim2.new(percentage, 0, 1, 0)
            
            if animate then
                TweenService:Create(Fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = targetSize
                }):Play()
            else
                Fill.Size = targetSize
            end
            task.spawn(callback, displayVal)
        end

        update(default, false)

        local isDragging = false
        local function processInput(input)
            local trackWidth = Track.AbsoluteSize.X
            if trackWidth > 0 then
                local relativeX = math.clamp(input.Position.X - Track.AbsolutePosition.X, 0, trackWidth)
                relativeX = math.max(0, math.min(relativeX, trackWidth))
                local percentage = relativeX / trackWidth
                local newValue = min + (max - min) * percentage
                update(newValue, false)
            end
        end

        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                processInput(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                processInput(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
            end
        end)

        return {
            Set = update,
            Get = function() return currentVal end
        }
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
