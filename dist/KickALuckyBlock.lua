--[[
    ========================================================================
    ⚡ AJIZ HUB - KICK A LUCKY BLOCK (MODULAR GAME LOGIC) ⚡
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

-- Diagnostic Tool for Game Remotes and Folders
pcall(function()
    print("=== AJIZ HUB DIAGNOSTICS ===")
    
    -- 1. Tools Check
    local toolsFound = {}
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        table.insert(toolsFound, t.Name)
    end
    for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
        if t:IsA("Tool") then
            table.insert(toolsFound, t.Name .. " (Equipped)")
        end
    end
    print("Tools found: " .. (#toolsFound > 0 and table.concat(toolsFound, ", ") or "None"))

    -- 2. Workspace Folders & Models Check
    local wsChildren = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Folder") then
            table.insert(wsChildren, obj.Name .. " (Folder)")
        elseif obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            table.insert(wsChildren, obj.Name .. " (Model)")
        end
    end
    print("Workspace Children: " .. (#wsChildren > 0 and table.concat(wsChildren, ", ") or "None"))

    -- 3. Debris Scan
    local debrisFolder = Workspace:FindFirstChild("Debris")
    if debrisFolder then
        local deb = {}
        for _, child in ipairs(debrisFolder:GetChildren()) do
            table.insert(deb, child.Name)
        end
        print("Debris children: " .. (#deb > 0 and table.concat(deb, ", ") or "None"))
    end

    -- 4. All Remotes Check (Comma Separated for screenshot copy-paste ease)
    local remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj.Name)
        end
    end
    print("All Remotes: " .. table.concat(remotes, ", "))
    print("==============================")
end)

-- Global States
_G.AutoLift = false
_G.AutoKick = false
_G.AutoCollect = false
_G.AutoRebirth = false

_G.LiftRemote = nil
_G.LiftArgs = nil
_G.KickRemote = nil
_G.KickArgs = nil
_G.RebirthRemote = nil
_G.RebirthArgs = nil

-- Auto-Detect Remotes at Startup
local function autoDetectRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            -- 1. Kick Remote (Matches kick, hits, but avoids purchases)
            if name:find("kick") and not name:find("purchase") and not name:find("gamepass") and not name:find("buy") then
                _G.KickRemote = obj
                _G.KickArgs = {}
            -- 2. Rebirth Remote
            elseif name:find("rebirth") or name:find("prestige") then
                _G.RebirthRemote = obj
                _G.RebirthArgs = {}
            -- 3. Lift/Train Remote (Matches swing, click, lift, strength, but avoids purchases/shops)
            elseif (name:find("lift") or name:find("train") or name:find("strength") or name:find("click") or name:find("swing")) and not name:find("shop") and not name:find("buy") then
                _G.LiftRemote = obj
                _G.LiftArgs = {}
            end
        end
    end
    
    -- Real-time observers to scan newly spawned items in Workspace and Debris
    pcall(function()
        Workspace.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if child and child.Parent then
                print("[SPAWNED WORKSPACE] Name: " .. child.Name .. " | Class: " .. child.ClassName .. " | Path: " .. child:GetFullName())
            end
        end)
        
        local debrisFolder = Workspace:FindFirstChild("Debris")
        if debrisFolder then
            debrisFolder.ChildAdded:Connect(function(child)
                task.wait(0.1)
                if child and child.Parent then
                    print("[SPAWNED DEBRIS] Name: " .. child.Name .. " | Class: " .. child.ClassName .. " | Path: " .. child:GetFullName())
                end
            end)
        end
    end)
end
pcall(autoDetectRemotes)

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

-- Safe Table Dump Helper (to avoid JSON serialization crashes on userdata)
local function safeDump(tbl)
    if type(tbl) ~= "table" then return tostring(tbl) end
    local parts = {}
    for k, v in pairs(tbl) do
        table.insert(parts, tostring(k) .. ": " .. tostring(v) .. " (" .. typeof(v) .. ")")
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

-- Safe Spawn CFrame tracking
local SpawnCFrame = nil
local function getSafeSpawn()
    if SpawnCFrame then return SpawnCFrame end
    
    -- 1. Look for SpawnLocation
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            SpawnCFrame = obj.CFrame * CFrame.new(0, 3, 0)
            return SpawnCFrame
        end
    end
    
    -- 2. Fallback: Player initial loading CFrame
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        SpawnCFrame = root.CFrame
        return SpawnCFrame
    end
    
    return CFrame.new(0, 10, 0)
end

-- ========================================================================
-- 🧠 METAMETHOD HOOK (Intercepts training/kicking/rebirthing events)
-- ========================================================================
task.spawn(function()
    local success, mt = pcall(function() return getrawmetatable(game) end)
    if success and mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            if checkcaller() then
                return oldNamecall(self, ...)
            end
            
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "FireServer" or method == "InvokeServer" then
                local name = string.lower(self.Name)
                if string.find(name, "lift") or string.find(name, "weight") or string.find(name, "strength") or string.find(name, "train") or string.find(name, "gain") or string.find(name, "click") then
                    _G.LiftRemote = self
                    _G.LiftArgs = args
                    pcall(function()
                        print("[AJIZ HOOK] Captured LIFT: " .. self.Name .. " | Args: " .. safeDump(args))
                    end)
                elseif string.find(name, "kick") or string.find(name, "hit") or string.find(name, "block") or string.find(name, "launch") then
                    _G.KickRemote = self
                    _G.KickArgs = args
                    pcall(function()
                        print("[AJIZ HOOK] Captured KICK: " .. self.Name .. " | Args: " .. safeDump(args))
                    end)
                elseif string.find(name, "rebirth") or string.find(name, "prestige") or string.find(name, "ascend") then
                    _G.RebirthRemote = self
                    _G.RebirthArgs = args
                    pcall(function()
                        print("[AJIZ HOOK] Captured REBIRTH: " .. self.Name .. " | Args: " .. safeDump(args))
                    end)
                end
            end
            
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- ========================================================================
-- 🏝️ GAMEPLAY AUTOMATION SYSTEMS
-- ========================================================================

-- 1. Auto Lift (Equip Weight/Stick and Train Strength)
local function equipWeightTool()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped then
            return equipped
        end
        -- Fallback to first tool in Backpack (e.g. Wooden Stick)
        local firstTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if firstTool then
            humanoid:EquipTool(firstTool)
            return firstTool
        end
    end
    return nil
end

task.spawn(function()
    local wasActive = false
    while true do
        task.wait(0.02)
        if _G.AutoLift then
            wasActive = true
            pcall(function()
                if _G.LiftRemote then
                    _G.LiftRemote:FireServer(unpack(_G.LiftArgs or {}))
                else
                    local tool = equipWeightTool()
                    if tool then
                        tool:Activate()
                    end
                end
            end)
        else
            if wasActive then
                wasActive = false
                pcall(function()
                    local char = LocalPlayer.Character
                    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
                    if humanoid then
                        humanoid:UnequipTools()
                    end
                end)
            end
        end
    end
end)

-- Helper to safely resolve a ProximityPrompt's world position
local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    
    if parent:IsA("BasePart") then
        return parent.Position
    elseif parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent:IsA("Model") then
        local prim = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
        if prim then
            return prim.Position
        end
    end
    return nil
end

-- 2. Auto Kick Block (Using Proximity Prompts near player)
local function triggerNearestPrompt()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local nearestPrompt = nil
    local minDistance = 50 -- Increased detection radius to 50 studs
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local pos = getPromptPosition(obj)
            if pos then
                local dist = (root.Position - pos).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestPrompt = obj
                end
            end
        end
    end
    
    if nearestPrompt then
        pcall(function()
            fireproximityprompt(nearestPrompt, 1)
        end)
    end
end

-- Helper to check if a block is nearby
local function isBlockNearby()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local minDistance = 35 -- 35 studs detection limit
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local pos = getPromptPosition(obj)
            if pos then
                local dist = (root.Position - pos).Magnitude
                if dist < minDistance then
                    return true
                end
            end
        end
    end
    return false
end

task.spawn(function()
    while true do
        task.wait(1.5) -- Safe rate-limit cooldown to prevent server bans
        if _G.AutoKick then
            pcall(function()
                if isBlockNearby() then
                    if _G.KickRemote and _G.KickArgs then
                        -- Extract captured accuracy, zone, and time values
                        local accuracy = _G.KickArgs[1] or 0.8
                        local zone = _G.KickArgs[2] or 1
                        
                        -- Dynamic timestamp matching game timing
                        local serverTime = pcall(function() return workspace:GetServerTimeNow() end) and workspace:GetServerTimeNow() or tick()
                        
                        if _G.KickRemote:IsA("RemoteEvent") then
                            _G.KickRemote:FireServer(accuracy, zone, serverTime)
                        elseif _G.KickRemote:IsA("RemoteFunction") then
                            _G.KickRemote:InvokeServer(accuracy, zone, serverTime)
                        end
                    else
                        -- Safe Proximity Prompt fallback if no remote is captured yet
                        triggerNearestPrompt()
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Collect & Teleport (Tsunami Bypass)
local function getDroppedItems()
    local list = {}
    
    -- Scan Debris Folder
    local debrisFolder = Workspace:FindFirstChild("Debris")
    if debrisFolder then
        for _, obj in ipairs(debrisFolder:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local lname = obj.Name:lower()
                if not lname:find("tsunami") and not lname:find("wave") and not lname:find("wall") then
                    table.insert(list, obj)
                end
            end
        end
    end
    
    -- Scan Workspace Child Layer
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local lname = obj.Name:lower()
            if (lname:find("brainrot") or lname:find("item") or lname:find("drop") or lname:find("block")) and not lname:find("tsunami") and not lname:find("wave") and not lname:find("wall") then
                if not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
                    table.insert(list, obj)
                end
            end
        end
    end
    return list
end

local function collectItem(item)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local targetPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
    if not targetPart then return end
    
    -- 1. Teleport to target item
    root.CFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
    task.wait(0.05)
    
    -- 2. Trigger TouchInterest
    if firetouchinterest then
        pcall(function()
            firetouchinterest(root, targetPart, 0)
            task.wait()
            firetouchinterest(root, targetPart, 1)
        end)
    end
    
    -- 3. Trigger ProximityPrompt
    local prompt = item:FindFirstChildOfClass("ProximityPrompt") or item:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    end
    
    task.wait(0.05)
    
    -- 4. Instantly teleport back to safe zone (Dodge tsunami!)
    root.CFrame = getSafeSpawn()
end

task.spawn(function()
    while true do
        task.wait(0.4)
        if _G.AutoCollect then
            pcall(function()
                local items = getDroppedItems()
                for _, item in ipairs(items) do
                    if not _G.AutoCollect then break end
                    if item and item.Parent then
                        collectItem(item)
                        task.wait(0.15)
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Rebirth Loop
task.spawn(function()
    while true do
        task.wait(2)
        if _G.AutoRebirth and _G.RebirthRemote then
            pcall(function()
                _G.RebirthRemote:FireServer(unpack(_G.RebirthArgs or {}))
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
    GameName = "Kick a Lucky Block",
    Footer = "Ajiz Hub"
})

-- 1. Auto Lift
Panel:AddToggle("Auto Lift Weights", false, function(state)
    _G.AutoLift = state
    if state then
        Notify("Ajiz Hub", "Auto Lifting activated! Lift manually once to unlock raw speed.", 2)
    else
        Notify("Ajiz Hub", "Auto Lifting deactivated.", 2)
    end
end)

-- 2. Auto Kick Block
Panel:AddToggle("Auto Kick Block", false, function(state)
    _G.AutoKick = state
    if state then
        Notify("Ajiz Hub", "Auto Kick activated! Kick manually once to trigger speed.", 2)
    else
        Notify("Ajiz Hub", "Auto Kick deactivated.", 2)
    end
end)

-- 3. Auto Collect & Spawn Dodge
Panel:AddToggle("Auto Collect (Tsunami Bypass)", false, function(state)
    _G.AutoCollect = state
    if state then
        -- Force initialize spawn location
        getSafeSpawn()
        Notify("Ajiz Hub", "Tsunami-Bypass Collect Activated!", 2)
    else
        Notify("Ajiz Hub", "Auto Collect deactivated.", 2)
    end
end)

-- 4. Auto Rebirth
Panel:AddToggle("Auto Rebirth", false, function(state)
    _G.AutoRebirth = state
    if state then
        Notify("Ajiz Hub", "Auto Rebirth activated! Rebirth manually once to hook.", 2)
    else
        Notify("Ajiz Hub", "Auto Rebirth deactivated.", 2)
    end
end)

Notify("Ajiz Hub", "Kick a Lucky Block Script Loaded!", 3)
