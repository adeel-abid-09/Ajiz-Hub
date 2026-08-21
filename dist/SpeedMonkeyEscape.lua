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
_G.SpeedBoost = false
_G.InfJump = false

_G.TrainRemote = nil
_G.TrainArgs = nil
_G.WinRemote = nil
_G.WinArgs = nil
_G.RebirthRemote = nil
_G.RebirthArgs = nil

-- Caching variables to prevent game freezes
local CachedTreadmills = {}
local CachedWinPad = nil
local CachedSpawnCF = nil

-- Safe Table Dump Helper
local function safeDump(tbl)
    if type(tbl) ~= "table" then return tostring(tbl) end
    local parts = {}
    for k, v in pairs(tbl) do
        table.insert(parts, tostring(k) .. ": " .. tostring(v) .. " (" .. typeof(v) .. ")")
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

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

-- Recursive Ancestor Scanner to detect nested parts in Lobby/Obby folders
local function hasAncestorKeyword(instance, keyword1, keyword2, keyword3)
    local parent = instance.Parent
    while parent and parent ~= Workspace do
        local pname = string.lower(parent.Name)
        if pname:find(keyword1) or (keyword2 and pname:find(keyword2)) or (keyword3 and pname:find(keyword3)) then
            return true
        end
        parent = parent.Parent
    end
    return false
end

-- Workspace structure and remote event dumper to local file
local function dumpWorkspace()
    pcall(function()
        if writefile then
            local lines = {}
            table.insert(lines, "=== AJIZ WORKSPACE DUMP ===")
            
            local function scan(instance, depth)
                if depth > 4 then return end
                local indent = string.rep("  ", depth)
                local name = instance.Name
                local className = instance.ClassName
                
                -- Log containers and keywords
                if instance:IsA("Folder") or instance:IsA("Model") or instance:IsA("BasePart") or instance:IsA("BillboardGui") then
                    table.insert(lines, indent .. name .. " (" .. className .. ")")
                    if not instance:IsA("BasePart") then
                        for _, child in ipairs(instance:GetChildren()) do
                            scan(child, depth + 1)
                        end
                    end
                end
            end
            
            for _, child in ipairs(workspace:GetChildren()) do
                scan(child, 0)
            end
            
            writefile("ajiz_sme_dump.txt", table.concat(lines, "\n"))
            print("[AJIZ SYSTEM] Workspace structure successfully dumped to 'ajiz_sme_dump.txt'!")
        end
    end)
end
pcall(dumpWorkspace)

-- ========================================================================
-- 🧠 DUAL-LAYER REMOTE HOOK (C-Level Method Hooks + Metamethod Fallback)
-- ========================================================================
local successHook = false

if hookfunction then
    pcall(function()
        local oldFireServer
        oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not checkcaller() then
                local args = {...}
                local name = string.lower(self.Name)
                local firstArg = tostring(args[1] or ""):lower()
                
                pcall(function()
                    print("[AJIZ HOOK FIRE] Remote: " .. self.Name .. " | Args: " .. safeDump(args))
                end)
                
                if name:find("train") or name:find("click") or name:find("treadmill") or name:find("speed") or firstArg:find("train") or firstArg:find("click") or firstArg:find("treadmill") or firstArg:find("speed") then
                    _G.TrainRemote = self
                    _G.TrainArgs = args
                elseif name:find("win") or name:find("finish") or name:find("obby") or name:find("gate") or firstArg:find("win") or firstArg:find("finish") or firstArg:find("obby") then
                    _G.WinRemote = self
                    _G.WinArgs = args
                elseif name:find("rebirth") or name:find("prestige") or firstArg:find("rebirth") or firstArg:find("prestige") then
                    _G.RebirthRemote = self
                    _G.RebirthArgs = args
                end
            end
            return oldFireServer(self, ...)
        end))

        local oldInvokeServer
        oldInvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, newcclosure(function(self, ...)
            if not checkcaller() then
                local args = {...}
                local name = string.lower(self.Name)
                local firstArg = tostring(args[1] or ""):lower()
                
                pcall(function()
                    print("[AJIZ HOOK INVOKE] Remote: " .. self.Name .. " | Args: " .. safeDump(args))
                end)
                
                if name:find("train") or name:find("click") or name:find("treadmill") or name:find("speed") or firstArg:find("train") or firstArg:find("click") or firstArg:find("treadmill") or firstArg:find("speed") then
                    _G.TrainRemote = self
                    _G.TrainArgs = args
                elseif name:find("win") or name:find("finish") or name:find("obby") or name:find("gate") or firstArg:find("win") or firstArg:find("finish") or firstArg:find("obby") then
                    _G.WinRemote = self
                    _G.WinArgs = args
                elseif name:find("rebirth") or name:find("prestige") or firstArg:find("rebirth") or firstArg:find("prestige") then
                    _G.RebirthRemote = self
                    _G.RebirthArgs = args
                end
            end
            return oldInvokeServer(self, ...)
        end))
        
        successHook = true
        print("[AJIZ SYSTEM] SME C-Level Remote Hooks Applied successfully!")
    end)
end

if not successHook then
    task.spawn(function()
        local success, mt = pcall(function() return getrawmetatable(game) end)
        if success and mt then
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                if not checkcaller() then
                    local method = getnamecallmethod()
                    local args = {...}
                    if method == "FireServer" or method == "InvokeServer" then
                        local name = string.lower(self.Name)
                        local firstArg = tostring(args[1] or ""):lower()
                        
                        pcall(function()
                            print("[AJIZ HOOK NAMECALL] Remote: " .. self.Name .. " | Args: " .. safeDump(args))
                        end)
                        
                        if name:find("train") or name:find("click") or name:find("treadmill") or name:find("speed") or firstArg:find("train") or firstArg:find("click") or firstArg:find("treadmill") or firstArg:find("speed") then
                            _G.TrainRemote = self
                            _G.TrainArgs = args
                        elseif name:find("win") or name:find("finish") or name:find("obby") or name:find("gate") or firstArg:find("win") or firstArg:find("finish") or firstArg:find("obby") then
                            _G.WinRemote = self
                            _G.WinArgs = args
                        elseif name:find("rebirth") or name:find("prestige") or firstArg:find("rebirth") or firstArg:find("prestige") then
                            _G.RebirthRemote = self
                            _G.RebirthArgs = args
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
            print("[AJIZ SYSTEM] SME Metamethod Hook Applied successfully!")
        end
    end)
end

-- Rebirth Remote Auto-Detection (Strict check to prevent tutorial remote mismatch)
local function scanRebirthRemote()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local lname = string.lower(obj.Name)
            if lname == "rebirth" then
                _G.RebirthRemote = obj
                print("[AJIZ SYSTEM] Strict Auto-Detected Rebirth Remote: " .. obj.Name)
                break
            end
        end
    end
end
pcall(scanRebirthRemote)

-- ========================================================================
-- 🏝️ PHYSICS & NO-CLIP PLATFORM CORE
-- ========================================================================

local FloatBody = nil
local function EnableFloat(root)
    if not FloatBody or not FloatBody.Parent then
        FloatBody = Instance.new("BodyVelocity")
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

-- Robust CFrame Lerp (With 4s Fail-Safe Timeout to prevent hangs)
local function moveToCF(targetCF, speed)
    speed = speed or 250
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local dist = (root.Position - targetCF.Position).Magnitude
    if dist < 8 then
        root.CFrame = targetCF
        return true
    end

    EnableFloat(root)
    
    local startCF = root.CFrame
    local duration = dist / speed
    local startTime = os.clock()
    
    while os.clock() - startTime < duration do
        if not _G.AutoWin and not _G.AutoTrain then break end
        
        -- Timeout Fail-safe (Max 4 seconds per movement step to prevent infinite hangs)
        if os.clock() - startTime > 4 then 
            break 
        end
        
        char = LocalPlayer.Character
        local currentRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not currentRoot then break end
        root = currentRoot
        
        local elapsed = os.clock() - startTime
        local t = elapsed / duration
        if t > 1 then t = 1 end
        
        -- Safe linear interpolation
        root.CFrame = startCF:Lerp(targetCF, t)
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
        
        task.wait() -- Wait for frame step
    end
    
    -- Final snap
    if _G.AutoWin or _G.AutoTrain then
        char = LocalPlayer.Character
        local currentRoot = char and char:FindFirstChild("HumanoidRootPart")
        if currentRoot then
            currentRoot.CFrame = targetCF
            currentRoot.Velocity = Vector3.zero
        end
    end
    
    DisableFloat()
    return true
end

-- Trigger Proximity Prompt inside treadmill
local function triggerPrompt(parent)
    local prompt = parent:FindFirstChildOfClass("ProximityPrompt") or parent.Parent:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ProximityPrompt") then
                prompt = child
                break
            end
        end
    end
    if prompt then
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.05)
                prompt:InputHoldEnd()
            end
        end)
        return true
    end
    return false
end

-- ========================================================================
-- 🔍 ENVIRONMENT DETECTOR UTILS & DYNAMIC CACHING (StreamingEnabled Support)
-- ========================================================================

-- Dynamic parser to extract numerical reward values from BillboardGuis / part text labels
local function getWinValue(part)
    local val = 0
    pcall(function()
        local num = tonumber(part.Name:match("%d+"))
        if num then 
            val = num 
        end
        
        for _, child in ipairs(part:GetDescendants()) do
            if child:IsA("TextLabel") or child.ClassName:find("Text") then
                local text = child.Text
                if text then
                    local matchNum = tonumber(text:gsub("%D+", ""))
                    if matchNum then
                        val = math.max(val, matchNum)
                    end
                end
            end
        end
        
        if part.Parent then
            for _, child in ipairs(part.Parent:GetDescendants()) do
                if child:IsA("TextLabel") or child.ClassName:find("Text") then
                    local text = child.Text
                    if text then
                        local matchNum = tonumber(text:gsub("%D+", ""))
                        if matchNum then
                            val = math.max(val, matchNum)
                        end
                    end
                end
            end
        end
    end)
    return val
end

-- Strict Win Pad validation to exclude VIP pads and Speed multiplier platforms
local function isRealWinPad(part)
    local hasWinKeyword = false
    local hasExcludeKeyword = false
    
    local function checkText(text)
        local t = string.lower(text)
        -- Must contain Win keyword
        if t:find("win") then
            hasWinKeyword = true
        end
        -- Strictly exclude VIP, gamepass, speed training multipliers, level zones
        if t:find("speed") or t:find("multiplier") or t:find("x") or t:find("train") or 
           t:find("rebirth") or t:find("level") or t:find("jump") or t:find("vip") or 
           t:find("robux") or t:find("pass") or t:find("premium") or t:find("gp") then
            hasExcludeKeyword = true
        end
    end
    
    checkText(part.Name)
    
    for _, child in ipairs(part:GetDescendants()) do
        if child:IsA("TextLabel") or child.ClassName:find("Text") then
            pcall(function()
                if child.Text then
                    checkText(child.Text)
                end
            end)
        end
    end
    
    if part.Parent then
        checkText(part.Parent.Name)
        for _, child in ipairs(part.Parent:GetChildren()) do
            if child:IsA("TextLabel") or child.ClassName:find("Text") then
                pcall(function()
                    if child.Text then
                        checkText(child.Text)
                    end
                end)
            end
        end
    end
    
    return hasWinKeyword and not hasExcludeKeyword
end

-- Scan Workspace to locate all physical Win Pads
local function findWinPads()
    local pads = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and isRealWinPad(obj) then
                table.insert(pads, obj)
            end
        end
    end)
    return pads
end

local function getBestWinPad()
    local pads = findWinPads()
    if #pads == 0 then return nil end
    
    pcall(function()
        table.sort(pads, function(a, b)
            return getWinValue(a) > getWinValue(b)
        end)
    end)
    
    return pads[1]
end

-- Refresh cached teleport targets for infinite Win/Spawn loops
local function updateWinCaching()
    pcall(function()
        CachedWinPad = getBestWinPad()
        
        -- Locate SpawnLocation (Targeting the exact Lobby Spawn Pad shown in user screenshot)
        local spawnLoc = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawnLoc then
            CachedSpawnCF = spawnLoc.CFrame
        else
            -- Look for parts named "Spawn" or "Lobby"
            local lobbySpawn = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChild("LobbySpawn") or Workspace:FindFirstChild("Lobby")
            if lobbySpawn then
                CachedSpawnCF = lobbySpawn.CFrame
            else
                -- Fallback to current player position on script startup
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    CachedSpawnCF = root.CFrame
                end
            end
        end
    end)
end

-- Background dynamic caching loop (Re-caches every 5 seconds to load newly streamed-in parts)
local function cacheWorkspaceObjects()
    local treadmills = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                -- Scan Treadmills
                local lname = string.lower(obj.Name)
                if lname:find("treadmill") or lname:find("train") or lname:find("run") or
                   hasAncestorKeyword(obj, "treadmill", "train", "run") then
                    if not obj:IsDescendantOf(LocalPlayer.Character) and not obj:IsDescendantOf(Players) then
                        if lname == "belt" or lname == "run" or lname == "platform" or lname == "pad" then
                            table.insert(treadmills, obj)
                        end
                    end
                end
            end
        end
    end)
    CachedTreadmills = treadmills
    
    -- Auto Win loops cache update
    if _G.AutoWin then
        updateWinCaching()
    end
end

-- Spawn background caching loop
task.spawn(function()
    while true do
        pcall(cacheWorkspaceObjects)
        task.wait(5) -- Re-scans every 5 seconds (Extremely lightweight, 60 FPS stable)
    end
end)

local function findTreadmill()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and #CachedTreadmills > 0 then
        local closest = CachedTreadmills[1]
        local minDist = (closest.Position - root.Position).Magnitude
        for i = 2, #CachedTreadmills do
            local t = CachedTreadmills[i]
            local d = (t.Position - root.Position).Magnitude
            if d < minDist then
                minDist = d
                closest = t
            end
        end
        return closest
    end
    return CachedTreadmills[1]
end

local function equipTrainTool()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped then
            return equipped
        end
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                humanoid:EquipTool(item)
                return item
            end
        end
    end
    return nil
end

-- ========================================================================
-- ⚡ AUTOMATION BACKGROUND WORKERS
-- ========================================================================

-- 1. Auto Train Worker
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoTrain then
            pcall(function()
                -- Direct remote fire only if dynamic arguments are captured (guarantees correct remote)
                if _G.TrainRemote and _G.TrainArgs then
                    _G.TrainRemote:FireServer(unpack(_G.TrainArgs))
                else
                    -- Fallback: Equip and activate tool
                    local tool = equipTrainTool()
                    if tool then
                        tool:Activate()
                    end
                    
                    -- Treadmill physical teleport
                    local treadmill = findTreadmill()
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if treadmill and root then
                        local dist = (root.Position - treadmill.Position).Magnitude
                        if dist > 8 then
                            moveToCF(treadmill.CFrame * CFrame.new(0, 3.5, 0), 300)
                            task.wait(0.1)
                            triggerPrompt(treadmill) -- Trigger proximity prompt if any
                        end
                    end
                end
            end)
        end
    end
end)

-- 2. Auto Win Worker (Forced loop: Teleports to Win Pad, then instantly forces back to Lobby Spawn pad)
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoWin then
            pcall(function()
                if not CachedWinPad or not CachedSpawnCF then
                    updateWinCaching()
                end
                
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if root and CachedWinPad and CachedSpawnCF then
                    -- 1. Teleport player directly onto the Win Pad
                    root.CFrame = CachedWinPad.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.25) -- Cooldown to guarantee touch registers on server
                    
                    -- 2. Force-teleport player back to Lobby Spawn pad (Prevents training machines auto-teleport)
                    root.CFrame = CachedSpawnCF * CFrame.new(0, 3, 0)
                    task.wait(0.25) -- Cooldown before next win iteration
                end
            end)
        end
    end
end)

-- 3. Auto Rebirth Worker
task.spawn(function()
    while true do
        task.wait(2.5)
        if _G.AutoRebirth then
            pcall(function()
                if _G.RebirthRemote then
                    local args = _G.RebirthArgs
                    if not args or #args == 0 then
                        args = {1} -- Standard Rebirth fallback parameter
                    end
                    _G.RebirthRemote:FireServer(unpack(args))
                end
            end)
        end
    end
end)

-- WalkSpeed Auto Sync (High Frequency RenderStepped loop to override local scripts)
RunService.RenderStepped:Connect(function()
    if _G.SpeedBoost then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 100
            end
        end)
    end
end)

-- Infinite Jump
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

-- Anti-AFK
pcall(function()
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
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
    MainFrame.ClipsDescendants = true
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
        Notify("Ajiz Hub", "Auto-Train Active! Check dev log if remotes hook.", 4)
    else
        pcall(DisableFloat)
    end
end)

Panel:AddToggle("Auto Win (Infinite)", false, function(state)
    _G.AutoWin = state
    if state then
        Notify("Ajiz Hub", "Infinite Win Teleport Loop Active!", 3)
    else
        pcall(DisableFloat)
    end
end)

Panel:AddToggle("Auto Rebirth", false, function(state)
    _G.AutoRebirth = state
    if state then
        Notify("Ajiz Hub", "Auto-Rebirth Active! Please rebirth manually once to capture remote.", 4)
    end
end)

Panel:AddToggle("Speed Boost (Max)", false, function(state)
    _G.SpeedBoost = state
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = state and 100 or 16
    end
end)

Panel:AddToggle("Infinite Jump", false, function(state)
    _G.InfJump = state
end)

AjizLib:Notify("Ajiz Hub", "Speed Monkey Escape Script Upgraded!", 3)
