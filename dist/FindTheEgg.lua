--[[
    ========================================================================
    ⚡ AJIZ HUB - FIND THE EGG [BRAINROT] ⚡
    ========================================================================
    • Premium Sky Blue & Dark Theme
    • Pure Checkbox & Clean Button Controls
    • Mobile "AJ" Draggable Floating Button & Touch Support
    • 100% Working Logic: Auto Train Speed, Auto Hatch, TP Best Egg, TP Base, Noclip
    • Delta & Mobile Optimized (gethui / PlayerGui / CoreGui)
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

-- Global States
_G.AutoTrain = false
_G.AutoHatch = false
_G.AutoCollectEggs = false
_G.NoclipActive = false
_G.SpeedBoost = false
_G.NoclipConnection = nil

-- Safe Container Selector
local function GetGuiContainer()
    local container = nil
    pcall(function()
        if gethui then container = gethui() end
    end)
    if container then return container end

    pcall(function()
        local lp = Players.LocalPlayer
        if lp then container = lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 3) end
    end)
    if container then return container end

    pcall(function() container = CoreGui end)
    return container or CoreGui
end

-- Ajiz Hub Theme Palette
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

-- Notification Helper
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
-- 🧠 GAME LOGIC HELPERS (FIND THE EGG FOR A BRAINROT)
-- ========================================================================

-- Helper function to find in-game speed stat value
local function getInGameSpeed()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local stat = leaderstats:FindFirstChild("Speed") or leaderstats:FindFirstChild("WalkSpeed") or leaderstats:FindFirstChild("Clicks")
        if stat and (stat:IsA("NumberValue") or stat:IsA("IntValue") or stat:IsA("DoubleConstrainedValue")) then
            return tonumber(stat.Value)
        end
    end
    for _, obj in ipairs(LocalPlayer:GetDescendants()) do
        if (obj:IsA("NumberValue") or obj:IsA("IntValue")) and (obj.Name == "Speed" or obj.Name == "WalkSpeed") then
            return tonumber(obj.Value)
        end
    end
    return nil
end

-- Helper function to find the Cauldron Part (Deposit Point)
local function getCauldronPart()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name == "cauldron" or name:find("cauldron") then
                if not obj:IsDescendantOf(LocalPlayer.Character) and not obj:IsDescendantOf(Players) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- Helper function to find Cauldron/Village CFrame
local function getVillageCFrame()
    local cauldron = getCauldronPart()
    if cauldron then
        return cauldron.CFrame
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name == "village" or name:find("spawnpoint") or name:find("spawn") then
            if not obj:IsDescendantOf(LocalPlayer.Character) and not obj:IsDescendantOf(Players) then
                if obj:IsA("BasePart") then
                    return obj.CFrame
                elseif obj:IsA("Model") then
                    return obj:GetPivot()
                end
            end
        end
    end
    return CFrame.new(0, 10, 0)
end

-- Helper function to automatically equip the Treadmill tool from Backpack
local function equipTreadmillTool()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped and (equipped.Name:lower():find("treadmill") or equipped.Name:lower():find("train") or equipped.Name:lower():find("run")) then
            return true
        end
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("treadmill") or item.Name:lower():find("run") or item.Name:lower():find("speed") or item.Name:lower():find("train")) then
                humanoid:EquipTool(item)
                return true
            end
        end
    end
    return false
end

-- Helper function to find the absolute BEST egg currently spawned on the map
local function getBestEgg()
    local eggs = {}
    local char = LocalPlayer.Character
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") and not obj:IsDescendantOf(char) and not obj:IsDescendantOf(Players) then
            local name = obj.Name:lower()
            local priority = 100
            
            if name:find("colossal") then
                priority = 1
            elseif name:find("giant") then
                priority = 2
            elseif name:find("legendary") then
                priority = 3
            elseif name:find("epic") then
                priority = 4
            elseif name:find("rare") then
                priority = 5
            elseif name:find("uncommon") then
                priority = 6
            elseif name:find("common") then
                priority = 7
            end
            
            table.insert(eggs, {Part = obj, Priority = priority})
        end
    end
    
    if #eggs > 0 then
        table.sort(eggs, function(a, b)
            return a.Priority < b.Priority
        end)
        return eggs[1].Part
    end
    return nil
end

-- Teleport Actions
local function TeleportToBestEgg()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local targetEgg = getBestEgg()
        if targetEgg then
            root.CFrame = targetEgg.CFrame * CFrame.new(0, 1.5, 0)
            Notify("Ajiz Hub", "Teleported to: " .. targetEgg.Name, 2)
        else
            Notify("Ajiz Hub", "No Eggs Found on Map!", 2)
        end
    end
end

local function TeleportToBase()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local cauldron = getCauldronPart()
        if cauldron then
            root.CFrame = cauldron.CFrame * CFrame.new(0, 3, 0)
            task.wait(0.1)
            pcall(function()
                if firetouchinterest then
                    firetouchinterest(cauldron, root, 0)
                    task.wait(0.05)
                    firetouchinterest(cauldron, root, 1)
                end
            end)
            Notify("Ajiz Hub", "Deposited Eggs at Cauldron Base!", 2)
        else
            root.CFrame = getVillageCFrame() * CFrame.new(0, 3, 0)
            Notify("Ajiz Hub", "Teleported to Village Spawn!", 2)
        end
    end
end

-- ========================================================================
-- ⚡ ADVANCED METAMETHOD HOOK (Traces and locks remote names)
-- ========================================================================
task.spawn(function()
    local success, mt = pcall(function() return getrawmetatable(game) end)
    if success and mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "FireServer" or method == "InvokeServer" then
                local name = string.lower(self.Name)
                if string.find(name, "train") or string.find(name, "click") or string.find(name, "speed") or string.find(name, "run") then
                    _G.TrainRemote = self
                    _G.TrainArgs = args
                elseif string.find(name, "hatch") or string.find(name, "buy") or string.find(name, "open") or string.find(name, "cauldron") then
                    _G.HatchRemote = self
                    _G.HatchArgs = args
                end
            end
            
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- WalkSpeed Auto Sync Loop
task.spawn(function()
    while true do
        task.wait(0.8)
        if _G.AutoTrain or _G.SpeedBoost then
            pcall(function()
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    local currentSpeed = getInGameSpeed()
                    if currentSpeed and currentSpeed > 16 then
                        humanoid.WalkSpeed = currentSpeed
                    elseif _G.SpeedBoost then
                        humanoid.WalkSpeed = 100
                    end
                end
            end)
        end
    end
end)

-- Auto Collect Best Eggs Loop
task.spawn(function()
    while true do
        task.wait(1.2)
        if _G.AutoCollectEggs then
            pcall(function()
                TeleportToBestEgg()
                task.wait(0.3)
                TeleportToBase()
            end)
        end
    end
end)

-- ========================================================================
-- 🎨 AJIZ HUB UI BUILDER (FIND THE EGG)
-- ========================================================================
local container = GetGuiContainer()
pcall(function()
    if container:FindFirstChild("AjizHub_FindTheEgg") then
        container.AjizHub_FindTheEgg:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AjizHub_FindTheEgg"
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

-- Main Frame
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
TitleLabel.Text = "+ AJIZ HUB - FIND THE EGG"
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

-- Scrollable Feature List
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
FooterLabel.Text = "Ajiz Hub"
FooterLabel.TextColor3 = Theme.Accent
FooterLabel.TextSize = 11

-- Checkbox Component Builder
local function AddToggle(title, default, callback)
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

    ItemBtn.MouseEnter:Connect(function() ItemBtn.BackgroundColor3 = Theme.ItemHover end)
    ItemBtn.MouseLeave:Connect(function() ItemBtn.BackgroundColor3 = Theme.ItemBg end)

    return { Set = update, Get = function() return state end }
end

-- Button Component Builder
local function AddButton(title, callback)
    local ItemBtn = Instance.new("TextButton")
    ItemBtn.Name = title .. "_Btn"
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
    Title.TextColor3 = Theme.Accent
    Title.TextSize = 11
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Arrow = Instance.new("TextLabel", ItemBtn)
    Arrow.Size = UDim2.new(0, 16, 0, 16)
    Arrow.Position = UDim2.new(1, -26, 0.5, -8)
    Arrow.BackgroundTransparency = 1
    Arrow.Font = Theme.Font
    Arrow.Text = "▶"
    Arrow.TextColor3 = Theme.Accent
    Arrow.TextSize = 10

    ItemBtn.MouseButton1Click:Connect(function()
        local clickTween = TweenService:Create(ItemBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        })
        clickTween:Play()
        clickTween.Completed:Connect(function()
            TweenService:Create(ItemBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.ItemBg
            }):Play()
        end)
        task.spawn(callback)
    end)

    ItemBtn.MouseEnter:Connect(function() ItemBtn.BackgroundColor3 = Theme.ItemHover end)
    ItemBtn.MouseLeave:Connect(function() ItemBtn.BackgroundColor3 = Theme.ItemBg end)
end

-- ========================================================================
-- 📌 REGISTER FEATURES TO AJIZ HUB
-- ========================================================================

-- 1. Auto Train Speed (Checkbox)
AddToggle("Auto Train Speed", false, function(state)
    _G.AutoTrain = state
    if state then
        equipTreadmillTool()
        
        -- Virtual Clicker Loop
        task.spawn(function()
            pcall(function() VirtualUser:CaptureController() end)
            while _G.AutoTrain do
                task.wait(0.01)
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait()
                    VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end
        end)

        -- Remote & WalkSpeed Syncer
        task.spawn(function()
            while _G.AutoTrain do
                task.wait(0.5)
                if _G.TrainRemote then
                    _G.TrainRemote:FireServer(unpack(_G.TrainArgs or {}))
                end
                
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    local cur = getInGameSpeed()
                    if cur and cur > 16 then hum.WalkSpeed = cur end
                end
            end
        end)
        Notify("Ajiz Hub", "Auto Train Speed Active!", 2)
    else
        Notify("Ajiz Hub", "Auto Train Speed Stopped.", 2)
    end
end)

-- 2. Auto Hatch Eggs (Checkbox)
AddToggle("Auto Hatch Eggs", false, function(state)
    _G.AutoHatch = state
    if state then
        task.spawn(function()
            while _G.AutoHatch do
                task.wait(0.5)
                if _G.HatchRemote then
                    _G.HatchRemote:FireServer(unpack(_G.HatchArgs or {}))
                else
                    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local name = string.lower(v.Name)
                            if name:find("hatch") or name:find("buyegg") or name:find("openegg") or name:find("cauldron") then
                                v:FireServer()
                            end
                        end
                    end
                end
            end
        end)
        Notify("Ajiz Hub", "Auto Hatch Active!", 2)
    else
        Notify("Ajiz Hub", "Auto Hatch Stopped.", 2)
    end
end)

-- 3. Auto Farm/Collect Eggs (Checkbox)
AddToggle("Auto Farm Eggs (Loop)", false, function(state)
    _G.AutoCollectEggs = state
    if state then
        Notify("Ajiz Hub", "Auto Egg Farm Loop Active!", 2)
    else
        Notify("Ajiz Hub", "Auto Egg Farm Loop Stopped.", 2)
    end
end)

-- 4. Speed Boost (Checkbox)
AddToggle("Speed Boost (Max)", false, function(state)
    _G.SpeedBoost = state
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.WalkSpeed = state and 100 or 16
    end
end)

-- 5. Noclip (Checkbox)
AddToggle("Noclip", false, function(state)
    _G.NoclipActive = state
    if state then
        _G.NoclipConnection = RunService.Stepped:Connect(function()
            if _G.NoclipActive and LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if _G.NoclipConnection then
            _G.NoclipConnection:Disconnect()
            _G.NoclipConnection = nil
        end
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

-- 6. TP to Best Egg (Action Button)
AddButton("TP to Best Egg", function()
    TeleportToBestEgg()
end)

-- 7. TP to Base / Cauldron (Action Button)
AddButton("TP to Base (Deposit)", function()
    TeleportToBase()
end)

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

Notify("Ajiz Hub", "Find the Egg [Brainrot] Script Loaded!", 3)
