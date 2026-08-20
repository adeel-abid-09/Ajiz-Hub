--[[
    ========================================================================
    ⚡ AJIZ HUB - ESCAPE HUSS VALLEY (MODULAR GAME LOGIC) ⚡
    ========================================================================
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- Global States
_G.AutoCollectCoins = false
_G.AutoSafeZone = false
_G.FreezeMonsters = false
_G.MonsterESP = false
_G.SpeedBoost = false
_G.JumpBoost = false
_G.InfJump = false

-- Local Variables
local SafePlatform = nil
local MonsterHighlights = {}

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
-- 🧠 UTILITIES & DETECTOR FUNCTIONS
-- ========================================================================

local ActiveCoins = {}
local ActiveMonsters = {}

local function isCoin(v)
    if not v:IsA("BasePart") then return false end
    if v:IsDescendantOf(LocalPlayer.Character) or v:IsDescendantOf(Players) then return false end
    
    local name = v.Name:lower()
    local parentName = v.Parent and v.Parent.Name:lower() or ""
    return name:find("coin") or parentName:find("coin") or name:find("token") or v:FindFirstChild("TouchInterest")
end

local function isMonster(v)
    if not v:IsA("Model") then return false end
    if v == LocalPlayer.Character or Players:GetPlayerFromCharacter(v) then return false end
    
    -- Check if it contains a humanoid or is named like a monster
    local hum = v:FindFirstChildOfClass("Humanoid")
    if hum then return true end
    
    local name = v.Name:lower()
    if name:find("monster") or name:find("killer") or name:find("pursuer") or name:find("npc") then
        return true
    end
    return false
end

local function registerObject(v)
    pcall(function()
        if isCoin(v) then
            if not table.find(ActiveCoins, v) then
                table.insert(ActiveCoins, v)
            end
        elseif isMonster(v) then
            if not table.find(ActiveMonsters, v) then
                table.insert(ActiveMonsters, v)
            end
        end
    end)
end

-- Initial Scan
for _, v in ipairs(Workspace:GetDescendants()) do
    registerObject(v)
end

-- Dynamic Tracking
Workspace.DescendantAdded:Connect(function(v)
    task.wait()
    if v and v.Parent then
        registerObject(v)
        if v:IsA("Humanoid") and v.Parent:IsA("Model") then
            registerObject(v.Parent)
        end
    end
end)

local function getMonsters()
    local list = {}
    local temp = {}
    for _, m in ipairs(ActiveMonsters) do
        if m and m.Parent and m:FindFirstChildOfClass("Humanoid") then
            table.insert(list, m)
            table.insert(temp, m)
        end
    end
    ActiveMonsters = temp
    return list
end

-- Find all Huss Coins currently spawned in Workspace (using cached tracker)
local function findCoins()
    local list = {}
    local temp = {}
    for _, c in ipairs(ActiveCoins) do
        if c and c.Parent and c:IsDescendantOf(Workspace) then
            table.insert(list, c)
            table.insert(temp, c)
        end
    end
    ActiveCoins = temp
    return list
end

-- Find a safe spawn point in the game to teleport to when safe zone is disabled
local function getSpawnCFrame()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj.CFrame * CFrame.new(0, 3, 0)
        end
    end
    return CFrame.new(0, 10, 0)
end

-- ========================================================================
-- ⚡ CHEAT MECHANICS LOOPS
-- ========================================================================

-- 1. Auto Collect Huss Coins Loop
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoCollectCoins then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                local coins = findCoins()
                for _, coin in ipairs(coins) do
                    if not _G.AutoCollectCoins then break end
                    if coin and coin.Parent then
                        if firetouchinterest then
                            -- Instant collection without moving character
                            firetouchinterest(coin, root, 0)
                            task.wait(0.01)
                            firetouchinterest(coin, root, 1)
                        else
                            -- Teleport fallback
                            local oldPos = root.CFrame
                            root.CFrame = coin.CFrame
                            task.wait(0.1)
                            root.CFrame = oldPos
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- 2. Freeze Monsters Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.FreezeMonsters then
            pcall(function()
                local monsters = getMonsters()
                for _, monster in ipairs(monsters) do
                    local root = monster:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Anchored = true
                    end
                    local hum = monster:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.WalkSpeed = 0
                    end
                end
            end)
        end
    end
end)

-- 3. Monster ESP Outline Loop
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if _G.MonsterESP then
                local monsters = getMonsters()
                for _, monster in ipairs(monsters) do
                    if monster and monster.Parent and not MonsterHighlights[monster] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 50, 50)
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineTransparency = 0
                        hl.Adornee = monster
                        hl.Parent = monster
                        MonsterHighlights[monster] = hl
                    end
                end
            else
                -- Remove all active highlights
                for monster, hl in pairs(MonsterHighlights) do
                    if hl and hl.Parent then
                        hl:Destroy()
                    end
                end
                table.clear(MonsterHighlights)
            end
        end)
    end
end)

-- 4. Persistent WalkSpeed / JumpPower Setup
local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        -- Enforce stats when values change (bypasses resets)
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if _G.SpeedBoost and hum.WalkSpeed ~= 80 then
                hum.WalkSpeed = 80
            end
        end)
        hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if _G.JumpBoost and hum.JumpPower ~= 100 then
                hum.JumpPower = 100
                hum.UseJumpPower = true
            end
        end)

        -- Initial application
        if _G.SpeedBoost then
            hum.WalkSpeed = 80
        end
        if _G.JumpBoost then
            hum.JumpPower = 100
            hum.UseJumpPower = true
        end
    end
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- Periodic safety net loop for WalkSpeed/JumpPower
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if _G.SpeedBoost and hum.WalkSpeed ~= 80 then
                    hum.WalkSpeed = 80
                end
                if _G.JumpBoost and hum.JumpPower ~= 100 then
                    hum.JumpPower = 100
                    hum.UseJumpPower = true
                end
            end
        end)
    end
end)

-- 5. Infinite Jump Handler
UserInputService.JumpRequest:Connect(function()
    if _G.InfJump then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- 6. Persistent Auto Safe Zone Platform Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoSafeZone then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                if not SafePlatform or not SafePlatform.Parent then
                    SafePlatform = Instance.new("Part")
                    SafePlatform.Name = "AjizSafePlatform"
                    SafePlatform.Size = Vector3.new(30, 1, 30)
                    SafePlatform.Position = Vector3.new(root.Position.X, 800, root.Position.Z)
                    SafePlatform.Anchored = true
                    SafePlatform.BrickColor = BrickColor.new("Baby blue")
                    SafePlatform.Material = Enum.Material.Neon
                    SafePlatform.Parent = Workspace
                end

                -- Keep player teleported to safe platform if they fall or reset
                if math.abs(root.Position.Y - SafePlatform.Position.Y) > 8 then
                    root.CFrame = SafePlatform.CFrame * CFrame.new(0, 3, 0)
                end
            end)
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
    local TitleText = config.Title or "AJIZ HUB"
    local GameName = config.GameName or ""
    local FullTitle = GameName ~= "" and GameName:upper() or TitleText:upper()
    local FooterText = config.Footer or "Ajiz Hub"

    local container = GetGuiContainer()

    if container:FindFirstChild("AjizHub_Panel") then
        container.AjizHub_Panel:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AjizHub_Panel"
    ScreenGui.ResetOnSpawn = false
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(ScreenGui) end) end
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
    MobileToggle.Name = "MobileToggle"
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

    -- Main Panel Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
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
    ScrollBody.Name = "ScrollBody"
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
    Footer.Size = UDim2.new(1, 0, 0, 22)
    Footer.Position = UDim2.new(0, 0, 1, -22)
    Footer.BackgroundColor3 = Theme.Header
    Footer.BorderSizePixel = 0
    Footer.Parent = MainFrame

    local FooterLabel = Instance.new("TextLabel", Footer)
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
            local flyout = MainFrame:FindFirstChild("TeleportFlyout")
            if flyout then
                flyout.Visible = false
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
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 36)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
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
        Box.Size = UDim2.new(0, 20, 0, 20)
        Box.Position = UDim2.new(1, -30, 0.5, -10)
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
        Checkmark.TextSize = 12
        Checkmark.TextTransparency = state and 0 or 1
        Checkmark.ZIndex = 3

        -- Transparent Click/Touch Button Overlay (On top of everything)
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = title .. "_ItemBtn"
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
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 36)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
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
        ItemBtn.Name = title .. "_ItemBtn"
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
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 36)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
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
        ItemBtn.Name = title .. "_ItemBtn"
        ItemBtn.Size = UDim2.new(1, 0, 1, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 10
        ItemBtn.Active = true
        ItemBtn.Parent = ItemFrame

        ItemBtn.Activated:Connect(function()
            TeleportFlyout.Visible = not TeleportFlyout.Visible
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
        ItemFrame.Name = title .. "_Container"
        ItemFrame.Size = UDim2.new(1, 0, 0, 42)
        ItemFrame.BackgroundColor3 = Theme.ItemBg
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollBody
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 5)

        local ItemStroke = Instance.new("UIStroke", ItemFrame)
        ItemStroke.Color = Theme.Border
        ItemStroke.Thickness = 0.8

        local Title = Instance.new("TextLabel", ItemFrame)
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
        Track.Name = "Track"
        Track.Size = UDim2.new(1, -20, 0, 4)
        Track.Position = UDim2.new(0, 10, 0, 26)
        Track.BackgroundColor3 = Theme.CheckInactive
        Track.BorderSizePixel = 0
        Track.Text = ""
        Track.AutoButtonColor = false
        Track.ZIndex = 2
        Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 2)

        local Fill = Instance.new("Frame", Track)
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Theme.Accent
        Fill.BorderSizePixel = 0
        Fill.ZIndex = 3
        Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 2)

        local Knob = Instance.new("Frame", Fill)
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
    GameName = "Escape Huss Valley",
    Footer = "Ajiz Hub"
})

-- 1. Auto Collect Huss Coins
Panel:AddToggle("Auto Farm Coins", false, function(state)
    _G.AutoCollectCoins = state
    if state then
        Notify("Ajiz Hub", "Auto Coin Farmer Activated!", 2)
    else
        Notify("Ajiz Hub", "Auto Coin Farmer Deactivated.", 2)
    end
end)

-- 2. Auto Safe Zone Platform
Panel:AddToggle("Auto Safe Zone (Sky)", false, function(state)
    _G.AutoSafeZone = state
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if state then
            -- Create high-altitude neon safe spot
            if not SafePlatform or not SafePlatform.Parent then
                SafePlatform = Instance.new("Part")
                SafePlatform.Name = "AjizSafePlatform"
                SafePlatform.Size = Vector3.new(30, 1, 30)
                SafePlatform.Position = Vector3.new(root.Position.X, 800, root.Position.Z)
                SafePlatform.Anchored = true
                SafePlatform.BrickColor = BrickColor.new("Baby blue")
                SafePlatform.Material = Enum.Material.Neon
                SafePlatform.Parent = Workspace
            end
            root.CFrame = SafePlatform.CFrame * CFrame.new(0, 3, 0)
            Notify("Ajiz Hub", "Teleported to Sky Safe Zone!", 2)
        else
            -- Destroy safe spot and teleport back to ground
            if SafePlatform then
                SafePlatform:Destroy()
                SafePlatform = nil
            end
            task.wait(0.1)
            root.CFrame = getSpawnCFrame()
            Notify("Ajiz Hub", "Safe Zone Disabled. Teleported to Spawn.", 2)
        end
    end)
end)

-- 3. Freeze Monsters
Panel:AddToggle("Freeze Monsters", false, function(state)
    _G.FreezeMonsters = state
    if state then
        Notify("Ajiz Hub", "Monsters Frozen locally!", 2)
    else
        -- Unanchor monsters safely (only the RootPart)
        pcall(function()
            local monsters = getMonsters()
            for _, monster in ipairs(monsters) do
                local root = monster:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Anchored = false
                end
                local hum = monster:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = 16
                end
            end
        end)
        Notify("Ajiz Hub", "Monsters Unfrozen.", 2)
    end
end)

-- 4. Monster ESP
Panel:AddToggle("Monster ESP Outline", false, function(state)
    _G.MonsterESP = state
    if state then
        Notify("Ajiz Hub", "Monster ESP Outline Enabled!", 2)
    else
        Notify("Ajiz Hub", "Monster ESP Outline Disabled.", 2)
    end
end)

-- 5. Speed Boost
Panel:AddToggle("WalkSpeed (Max)", false, function(state)
    _G.SpeedBoost = state
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = state and 80 or 16
        end
    end)
end)

-- 6. Jump Boost
Panel:AddToggle("JumpPower (Max)", false, function(state)
    _G.JumpBoost = state
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if state then
                hum.JumpPower = 100
                hum.UseJumpPower = true
            else
                hum.UseJumpPower = false
                hum.JumpPower = 50
            end
        end
    end)
end)

-- 7. Infinite Jump
Panel:AddToggle("Infinite Jump", false, function(state)
    _G.InfJump = state
end)

Notify("Ajiz Hub", "Escape Huss Valley Script Loaded!", 3)
