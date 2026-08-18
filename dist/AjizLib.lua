--[[
    ========================================================================
    🌟 AJIZ LIB - COMPLETE UI FRAMEWORK (CLEAN & UNOBFUSCATED) 🌟
    ========================================================================
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local AjizLib = {}
AjizLib.__index = AjizLib

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

    pcall(function()
        container = CoreGui
    end)
    return container or CoreGui
end

local Theme = {
    Background = Color3.fromRGB(15, 17, 24),
    Header = Color3.fromRGB(20, 23, 32),
    Border = Color3.fromRGB(32, 38, 52),
    Accent = Color3.fromRGB(0, 170, 255),
    CheckActive = Color3.fromRGB(235, 60, 60),
    CheckInactive = Color3.fromRGB(28, 32, 44),
    ItemBg = Color3.fromRGB(22, 25, 36),
    ItemHover = Color3.fromRGB(30, 35, 50),
    TextPrimary = Color3.fromRGB(245, 248, 255),
    TextMuted = Color3.fromRGB(140, 148, 165),
    Font = Enum.Font.GothamBold,
    FontRegular = Enum.Font.GothamMedium
}

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

    -- Mobile Toggle
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

    -- Features Scroll
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

return AjizLib
