--[[
    ========================================================================
    ⚡ AJIZ HUB - SPEED MONKEY ESCAPE (MODULAR GAME LOGIC) ⚡
    ========================================================================
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

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
    LocalPlayer = Players.PlayerAdded:Wait()
end

-- Global States
_G.AutoTrain = false
_G.AutoWin = false
_G.AutoRebirth = false

_G.TrainRemote = nil
_G.WinRemote = nil
_G.RebirthRemote = nil

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

-- Auto-Detect Remotes
local function detectGameRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local lname = string.lower(obj.Name)
            if (string.find(lname, "train") or string.find(lname, "treadmill") or string.find(lname, "speed") or string.find(lname, "click")) and not string.find(lname, "buy") and not string.find(lname, "shop") then
                _G.TrainRemote = obj
            elseif (string.find(lname, "win") or string.find(lname, "finish") or string.find(lname, "obby") or string.find(lname, "gate")) and not string.find(lname, "buy") then
                _G.WinRemote = obj
            elseif string.find(lname, "rebirth") or string.find(lname, "prestige") then
                _G.RebirthRemote = obj
            end
        end
    end
end
pcall(detectGameRemotes)

-- Floating/Noclip Core for safe teleports
local FloatBody = nil
local function EnableFloat(root)
    if not FloatBody or not FloatBody.Parent then
        FloatBody = Instance.new("BodyVelocity")
        -- Randomized name to bypass simple detection checks
        FloatBody.Name = "AjizV_" .. tostring(math.random(100, 999))
        FloatBody.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        FloatBody.Velocity = Vector3.zero
        FloatBody.Parent = root
    end
end

local function DisableFloat()
    if FloatBody then
        FloatBody:Destroy()
        FloatBody = nil
    end
end

-- Continuous Noclip
RunService.Stepped:Connect(function()
    if _G.AutoTrain or _G.AutoWin then
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

-- Safe Teleport / Tween Handler
local currentTween = nil
local function SafeTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    EnableFloat(root)
    
    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 45 then
        root.CFrame = targetCFrame
        DisableFloat()
        return
    end

    -- Linear Tween to target destination to prevent speed bans
    local speed = 250
    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    currentTween:Play()
    currentTween.Completed:Connect(function()
        DisableFloat()
        currentTween = nil
    end)
end

-- Workspace Object Finder (Scans dynamically for Treadmills and Finish lines)
-- Enhanced with multi-level parent context searching (handles folder-grouped objects)
local function findTreadmill()
    local target = nil
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local lname = string.lower(obj.Name)
                local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
                local gParentName = obj.Parent and obj.Parent.Parent and string.lower(obj.Parent.Parent.Name) or ""
                
                -- Check if part or parent folder contain treadmill/train keywords
                if lname:find("treadmill") or lname:find("train") or lname:find("run") or
                   parentName:find("treadmill") or parentName:find("train") or
                   gParentName:find("treadmill") or gParentName:find("train") then
                    
                    if not obj:IsDescendantOf(LocalPlayer.Character) and not obj:IsDescendantOf(Players) then
                        -- Prioritize interactive parts within models
                        if lname == "belt" or lname == "run" or lname == "platform" or lname == "pad" then
                            target = obj
                            break
                        elseif not target then
                            target = obj
                        end
                    end
                end
            end
        end
    end)
    return target
end

local function findWinPart()
    local target = nil
    pcall(function()
        -- Scan checkpoint parts, checking up to 2 parent directories to support nested map structures
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local lname = string.lower(obj.Name)
                local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
                local gParentName = obj.Parent and obj.Parent.Parent and string.lower(obj.Parent.Parent.Name) or ""
                
                if (lname:find("finish") or lname == "win" or lname:find("^win$") or lname:find("win_") or lname:find("winpad") or lname:find("winpart") or lname:find("endpart") or lname:find("checkpoint") or
                    parentName:find("win") or parentName:find("finish") or parentName:find("stage") or parentName:find("obby") or
                    gParentName:find("win") or gParentName:find("finish") or gParentName:find("stage") or gParentName:find("obby")) and not obj:IsDescendantOf(LocalPlayer.Character) then
                    
                    target = obj
                    break
                end
            end
        end
    end)
    return target
end

-- Diagnostic Startup Logs
pcall(function()
    print("=== AJIZ HUB S.M.E. DIAGNOSTICS ===")
    local t = findTreadmill()
    local w = findWinPart()
    print("Treadmill found: " .. (t and t:GetFullName() or "None"))
    print("Win Part found: " .. (w and w:GetFullName() or "None"))
    print("Train Remote detected: " .. (_G.TrainRemote and _G.TrainRemote:GetFullName() or "None"))
    print("Win Remote detected: " .. (_G.WinRemote and _G.WinRemote:GetFullName() or "None"))
    print("Rebirth Remote detected: " .. (_G.RebirthRemote and _G.RebirthRemote:GetFullName() or "None"))
    print("===================================")
end)

-- ========================================================================
-- 🏝️ AUTOMATION BACKGROUND WORKERS
-- ========================================================================

-- 1. Auto Training Worker
task.spawn(function()
    while true do
        task.wait(0.5) -- Safe rate-limit cooldown
        if _G.AutoTrain then
            pcall(function()
                -- If Train Remote exists, fire it directly
                if _G.TrainRemote then
                    _G.TrainRemote:FireServer()
                else
                    -- Fallback: Teleport onto a treadmill and simulate walking/running
                    local treadmill = findTreadmill()
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if treadmill and root then
                        -- Only teleport if player has walked off the treadmill to prevent physics resetting
                        local dist = (root.Position - treadmill.Position).Magnitude
                        if dist > 8 then
                            root.CFrame = treadmill.CFrame * CFrame.new(0, 3.5, 0)
                        end
                        
                        -- Simulate walking movement inputs to trigger treadmill speed detection
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:Move(Vector3.new(0, 0, -1), true)
                        end
                    else
                        warn("[AJIZ HUB] Auto-Train enabled but no Treadmill found in workspace.")
                    end
                end
            end)
        end
    end
end)

-- 2. Auto Win / Obby Finisher Worker
task.spawn(function()
    while true do
        task.wait(1.5) -- Anti-kick delay limit
        if _G.AutoWin then
            pcall(function()
                if _G.WinRemote then
                    _G.WinRemote:FireServer()
                else
                    local winPart = findWinPart()
                    if winPart then
                        SafeTeleport(winPart.CFrame * CFrame.new(0, 2, 0))
                    else
                        warn("[AJIZ HUB] Auto-Win enabled but no Win/Finish Part found in workspace.")
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Rebirth Worker
task.spawn(function()
    while true do
        task.wait(3) -- Rebirth check interval
        if _G.AutoRebirth then
            pcall(function()
                if _G.RebirthRemote then
                    _G.RebirthRemote:FireServer()
                else
                    warn("[AJIZ HUB] Auto-Rebirth enabled but no Rebirth Remote found.")
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
    Title = "AJIZ HUB",
    GameName = "Monkey Escape",
    Footer = "Ajiz Hub"
})

Panel:AddToggle("Auto Train Speed", false, function(state)
    _G.AutoTrain = state
    if state then
        local t = findTreadmill()
        if not t and not _G.TrainRemote then
            Notify("Ajiz Hub", "No Treadmill or Train Remote found! Run/stand near a treadmill or check developer console.", 5)
        else
            Notify("Ajiz Hub", "Auto-Train Activated!", 2)
        end
    else
        pcall(DisableFloat)
    end
end)

Panel:AddToggle("Auto Win (Obby)", false, function(state)
    _G.AutoWin = state
    if state then
        local w = findWinPart()
        if not w and not _G.WinRemote then
            Notify("Ajiz Hub", "No Finish Line / Win Pad detected! Check developer console.", 5)
        else
            Notify("Ajiz Hub", "Auto-Win Activated!", 2)
        end
    else
        pcall(DisableFloat)
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
    end
end)

Panel:AddToggle("Auto Rebirth", false, function(state)
    _G.AutoRebirth = state
    if state then
        if not _G.RebirthRemote then
            Notify("Ajiz Hub", "No Rebirth Remote detected. Auto-Rebirth might not work in this game.", 5)
        else
            Notify("Ajiz Hub", "Auto-Rebirth Activated!", 2)
        end
    end
end)

AjizLib:Notify("Ajiz Hub", "Speed Monkey Escape Script Loaded!", 3)
