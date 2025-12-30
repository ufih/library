--[[
    GHack UI Framework - Roblox Luau Port
    Accurate recreation of GMod GHack menu styling with proper gradients
    
    Usage:
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ufih/library/refs/heads/main/library.lua"))()
    local Window = Library:CreateWindow("GHACK OT")
]]

local Library = {}
Library.__index = Library

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

-- Library State
Library.Windows = {}
Library.Connections = {}
Library.Unloaded = false

-- Debug System
Library.Debug = {
    Enabled = false,
    Logs = {},
    EventLogs = {},
    ControlStates = {},
    MaxLogs = 500,
    StartTime = os.clock(),
    CallbackErrors = {},
    GUI = nil,
}

-- Watermark System
Library.Watermark = {
    Enabled = false,
    GUI = nil,
    Text = "GHACK OT",
}

-- Configuration (EXACT GHack colors with gradients)
Library.Config = {
    -- Main accent color (pink/magenta)
    HighlightColor = Color3.fromRGB(255, 0, 151),
    
    -- Background colors
    MainBackground = Color3.fromRGB(30, 30, 30),
    PanelBackground = Color3.fromRGB(38, 38, 38),
    PanelBackgroundLight = Color3.fromRGB(48, 48, 48),
    ContentBackground = Color3.fromRGB(22, 22, 22),
    ControlBackground = Color3.fromRGB(41, 41, 41),
    ControlBackgroundLight = Color3.fromRGB(51, 51, 51),
    ControlBackgroundAlt = Color3.fromRGB(35, 35, 35),
    HoverBackground = Color3.fromRGB(55, 55, 55),
    
    -- Selection colors for subtabs
    SelectionBg = Color3.fromRGB(50, 50, 55),
    SelectionGradientStart = Color3.fromRGB(65, 65, 70),
    SelectionGradientEnd = Color3.fromRGB(40, 40, 45),
    
    -- Border colors
    OuterBorder = Color3.fromRGB(29, 29, 29),
    InnerBorder = Color3.fromRGB(19, 19, 19),
    PanelBorder = Color3.fromRGB(50, 50, 50),
    SeparatorColor = Color3.fromRGB(55, 55, 55),
    
    -- Text colors
    TextColor = Color3.fromRGB(255, 255, 255),
    RiskTextColor = Color3.fromRGB(220, 220, 120),
    DimTextColor = Color3.fromRGB(180, 180, 180),
    
    -- Dimensions
    WindowSizeX = 550,
    WindowSizeY = 400,
    TabHeight = 22,
    LeftAreaPadding = 115,
    PanelWidth = 200,
    
    -- Animation
    FadeTime = 0.25,
    
    -- Font
    Font = Enum.Font.Code,
    FontBold = Enum.Font.GothamBold,
    FontSize = 13,
}

-- Utility Functions
local function Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(instance, properties, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local ms = math.floor((seconds % 1) * 1000)
    return string.format("%02d:%02d.%03d", mins, secs, ms)
end

local function AddConnection(connection)
    table.insert(Library.Connections, connection)
    return connection
end

-- Add vertical gradient to frame (top lighter, bottom darker)
local function AddGradient(parent, rotation)
    return Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
        }),
        Rotation = rotation or 90,
        Parent = parent
    })
end

-- Add transparency gradient (top less transparent)
local function AddTransparencyGradient(parent, startTrans, endTrans)
    return Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, startTrans or 0.7),
            NumberSequenceKeypoint.new(1, endTrans or 0.9)
        }),
        Rotation = 90,
        Parent = parent
    })
end

-- Debug logging
function Library:Log(level, source, message)
    if self.Unloaded then return end
    
    local timestamp = os.clock() - self.Debug.StartTime
    local logEntry = {
        timestamp = timestamp,
        level = level,
        source = source,
        message = message,
        formatted = string.format("[%s] [%s] [%s] %s", FormatTime(timestamp), level:upper(), source, message)
    }
    
    table.insert(self.Debug.Logs, logEntry)
    while #self.Debug.Logs > self.Debug.MaxLogs do
        table.remove(self.Debug.Logs, 1)
    end
    
    if level == "event" then
        table.insert(self.Debug.EventLogs, logEntry)
    elseif level == "error" then
        table.insert(self.Debug.CallbackErrors, logEntry)
    end
    
    if self.Debug.Enabled and self.Debug.GUI and self.UpdateDebugGUI then
        self:UpdateDebugGUI()
    end
end

function Library:TrackControlState(controlId, controlType, value)
    self.Debug.ControlStates[controlId] = {
        type = controlType,
        value = value,
        lastUpdated = os.clock() - self.Debug.StartTime
    }
end

--[[ WATERMARK SYSTEM ]]
function Library:CreateWatermark()
    if self.Watermark.GUI then return end
    
    local watermarkGui = Create("ScreenGui", {
        Name = "GHackWatermark",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    
    pcall(function() watermarkGui.Parent = CoreGui end)
    if not watermarkGui.Parent then
        watermarkGui.Parent = Player:WaitForChild("PlayerGui")
    end
    
    local frame = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Visible = self.Watermark.Enabled,
        Parent = watermarkGui
    })
    
    -- Gradient overlay
    local gradientOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = frame
    })
    AddGradient(gradientOverlay, 90)
    
    Create("UIStroke", {
        Color = Library.Config.HighlightColor,
        Thickness = 1,
        Parent = frame
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = frame
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = self.Watermark.Text,
        TextColor3 = Library.Config.HighlightColor,
        Font = Library.Config.FontBold,
        TextSize = 12,
        ZIndex = 2,
        Parent = frame
    })
    
    self.Watermark.GUI = watermarkGui
    self.Watermark.Frame = frame
    self.Watermark.Label = label
end

function Library:SetWatermarkVisible(visible)
    self.Watermark.Enabled = visible
    if self.Watermark.Frame then
        self.Watermark.Frame.Visible = visible
    end
end

function Library:SetWatermarkText(text)
    self.Watermark.Text = text
    if self.Watermark.Label then
        self.Watermark.Label.Text = text
    end
end

--[[ DEBUG GUI ]]
function Library:ToggleDebugConsole()
    if self.Debug.GUI then
        self.Debug.GUI:Destroy()
        self.Debug.GUI = nil
        self.Debug.Enabled = false
        self:Log("info", "Debug", "Debug console closed")
        return
    end
    
    self.Debug.Enabled = true
    self:Log("info", "Debug", "Debug console opened")
    
    local debugGui = Create("ScreenGui", {
        Name = "GHackDebugUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    pcall(function() debugGui.Parent = CoreGui end)
    if not debugGui.Parent then
        debugGui.Parent = Player:WaitForChild("PlayerGui")
    end
    
    self.Debug.GUI = debugGui
    
    local mainFrame = Create("Frame", {
        Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, -250, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BorderSizePixel = 0,
        Parent = debugGui
    })
    
    Create("UIStroke", {
        Color = Color3.fromRGB(80, 200, 255),
        Thickness = 2,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = mainFrame
    })
    
    -- Title bar
    local titleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = titleBar
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "🔧 GHACK DEBUG CONSOLE",
        TextColor3 = Color3.fromRGB(80, 200, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = titleBar
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleDebugConsole()
    end)
    
    -- Stats bar
    local statsBar = Create("Frame", {
        Size = UDim2.new(1, -12, 0, 22),
        Position = UDim2.new(0, 6, 0, 32),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = statsBar
    })
    
    local statsLabel = Create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = "Logs: 0 | Events: 0 | Errors: 0 | Controls: 0",
        TextColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statsBar
    })
    
    -- Logs frame
    local logsFrame = Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -100),
        Position = UDim2.new(0, 6, 0, 58),
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = Color3.fromRGB(80, 200, 255),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = logsFrame
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 1),
        Parent = logsFrame
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = logsFrame
    })
    
    -- Buttons frame
    local buttonsFrame = Create("Frame", {
        Size = UDim2.new(1, -12, 0, 30),
        Position = UDim2.new(0, 6, 1, -36),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        Parent = buttonsFrame
    })
    
    local function createDebugButton(text, callback)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 90, 1, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            Parent = buttonsFrame
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
        
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    createDebugButton("📋 Copy Logs", function()
        local text = ""
        for _, log in ipairs(self.Debug.Logs) do
            text = text .. log.formatted .. "\n"
        end
        if setclipboard then
            setclipboard(text)
            self:Log("info", "Debug", "Logs copied to clipboard")
        end
    end)
    
    createDebugButton("🗑️ Clear", function()
        self.Debug.Logs = {}
        self.Debug.EventLogs = {}
        self.Debug.CallbackErrors = {}
        for _, child in ipairs(logsFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        self:Log("info", "Debug", "Logs cleared")
    end)
    
    createDebugButton("📊 States", function()
        if setclipboard and HttpService then
            local success, json = pcall(function()
                return HttpService:JSONEncode(self.Debug.ControlStates)
            end)
            if success then
                setclipboard(json)
                self:Log("info", "Debug", "Control states copied")
            end
        end
    end)
    
    createDebugButton("🔄 Refresh", function()
        self:UpdateDebugGUI()
    end)
    
    -- Update function
    function self:UpdateDebugGUI()
        if not self.Debug.GUI then return end
        
        local controlCount = 0
        for _ in pairs(self.Debug.ControlStates) do controlCount = controlCount + 1 end
        
        statsLabel.Text = string.format(
            "Logs: %d | Events: %d | Errors: %d | Controls: %d | Uptime: %s",
            #self.Debug.Logs,
            #self.Debug.EventLogs,
            #self.Debug.CallbackErrors,
            controlCount,
            FormatTime(os.clock() - self.Debug.StartTime)
        )
        
        for _, child in ipairs(logsFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        
        local startIdx = math.max(1, #self.Debug.Logs - 100)
        for i = startIdx, #self.Debug.Logs do
            local log = self.Debug.Logs[i]
            if log then
                local color = Library.Config.TextColor
                if log.level == "error" then
                    color = Color3.fromRGB(255, 80, 80)
                elseif log.level == "event" then
                    color = Color3.fromRGB(80, 200, 255)
                elseif log.level == "info" then
                    color = Color3.fromRGB(80, 255, 120)
                elseif log.level == "warn" then
                    color = Color3.fromRGB(255, 200, 80)
                end
                
                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text = log.formatted,
                    TextColor3 = color,
                    Font = Enum.Font.Code,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = logsFrame
                })
            end
        end
        
        logsFrame.CanvasPosition = Vector2.new(0, logsFrame.AbsoluteCanvasSize.Y)
    end
    
    -- Dragging
    local dragging = false
    local dragStart, startPos
    
    AddConnection(titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end))
    
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    
    self:UpdateDebugGUI()
end

--[[ UNLOAD SYSTEM ]]
function Library:Unload()
    self:Log("info", "Library", "Unloading...")
    self.Unloaded = true
    
    for _, connection in ipairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    self.Connections = {}
    
    for _, window in ipairs(self.Windows) do
        if window.ScreenGui then
            window.ScreenGui:Destroy()
        end
    end
    self.Windows = {}
    
    if self.Debug.GUI then
        self.Debug.GUI:Destroy()
        self.Debug.GUI = nil
    end
    
    if self.Watermark.GUI then
        self.Watermark.GUI:Destroy()
        self.Watermark.GUI = nil
    end
    
    self.Debug.Logs = {}
    self.Debug.EventLogs = {}
    self.Debug.CallbackErrors = {}
    self.Debug.ControlStates = {}
    
    print("[GHack] Library unloaded successfully")
end

--[[ WINDOW CLASS ]]
local Window = {}
Window.__index = Window

function Library:CreateWindow(title)
    if self.Unloaded then return end
    
    local self = setmetatable({}, Window)
    self.Title = title or "GHACK OT"
    self.Visible = false
    self.Tabs = {}
    self.ActiveTab = 1
    self.Dragging = false
    self.Library = Library
    
    Library:Log("info", "Window", "Creating window: " .. title)
    
    -- Create ScreenGui
    self.ScreenGui = Create("ScreenGui", {
        Name = "GHackUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    
    pcall(function() self.ScreenGui.Parent = CoreGui end)
    if not self.ScreenGui.Parent then
        self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end
    
    -- Main Window Frame
    self.MainFrame = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, Library.Config.WindowSizeX, 0, Library.Config.WindowSizeY),
        Position = UDim2.new(0.5, -Library.Config.WindowSizeX/2, 0.5, -Library.Config.WindowSizeY/2),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.ScreenGui
    })
    
    -- Inner border frame
    local innerBorder = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.PanelBorder,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    -- Content frame
    self.ContentFrame = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Parent = innerBorder
    })
    
    -- Main gradient overlay for depth
    local mainGradientOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = self.ContentFrame
    })
    AddGradient(mainGradientOverlay, 90)
    
    -- Title Bar
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, Library.Config.TabHeight),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Parent = self.ContentFrame
    })
    
    -- Title bar gradient
    local titleGradient = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Parent = self.TitleBar
    })
    AddGradient(titleGradient, 90)
    
    -- Bottom border of title bar
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Config.PanelBorder,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    
    -- Title "GHACK OT"
    self.TitleLabel = Create("TextLabel", {
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Library.Config.HighlightColor,
        Font = Library.Config.FontBold,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    
    -- Tab Container
    self.TabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 100, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 15),
        Parent = self.TabContainer
    })
    
    Create("UIPadding", {
        PaddingRight = UDim.new(0, 10),
        Parent = self.TabContainer
    })
    
    -- Left Panel (SubTabs)
    self.LeftPanel = Create("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, Library.Config.LeftAreaPadding, 1, -Library.Config.TabHeight - 1),
        Position = UDim2.new(0, 0, 0, Library.Config.TabHeight + 1),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ContentFrame
    })
    
    -- Left panel gradient
    local leftGradient = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Parent = self.LeftPanel
    })
    AddGradient(leftGradient, 0)
    
    -- Left panel right border
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Library.Config.PanelBorder,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.LeftPanel
    })
    
    -- Content Area
    self.ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -Library.Config.LeftAreaPadding - 1, 1, -Library.Config.TabHeight - 1),
        Position = UDim2.new(0, Library.Config.LeftAreaPadding + 1, 0, Library.Config.TabHeight + 1),
        BackgroundColor3 = Library.Config.ContentBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ContentFrame
    })
    
    -- Content area gradient
    local contentGradient = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        Parent = self.ContentArea
    })
    AddGradient(contentGradient, 90)
    
    -- Setup dragging
    self:SetupDragging()
    
    -- Toggle keybind
    AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if Library.Unloaded then return end
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
    end))
    
    -- Create watermark
    Library:CreateWatermark()
    
    -- Store window reference
    table.insert(Library.Windows, self)
    
    -- Create built-in Settings tab
    task.defer(function()
        self:CreateSettingsTab()
    end)
    
    return self
end

function Window:SetupDragging()
    local dragStart, startPos
    
    AddConnection(self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end))
    
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end))
end

function Window:Toggle()
    if Library.Unloaded then return end
    
    self.Visible = not self.Visible
    Library:Log("event", "Window", "Toggled: " .. tostring(self.Visible))
    
    if self.Visible then
        self.MainFrame.Visible = true
        self.MainFrame.BackgroundTransparency = 1
        Tween(self.MainFrame, {BackgroundTransparency = 0}, Library.Config.FadeTime)
    else
        local tween = Tween(self.MainFrame, {BackgroundTransparency = 1}, Library.Config.FadeTime)
        tween.Completed:Connect(function()
            if not self.Visible then
                self.MainFrame.Visible = false
            end
        end)
    end
end

function Window:CreateSettingsTab()
    local settingsTab = self:CreateTab("Settings")
    settingsTab.ButtonFrame.LayoutOrder = 999
    
    local mainSubTab = settingsTab:CreateSubTab("Configuration")
    
    local debugSection = mainSubTab:CreateSection("Debug")
    debugSection:CreateButton("Open Debug Console", function()
        Library:ToggleDebugConsole()
    end)
    
    local otherSection = mainSubTab:CreateSection("Other Settings")
    otherSection:CreateToggle("Watermark", Library.Watermark.Enabled, function(value)
        Library:SetWatermarkVisible(value)
    end)
    otherSection:CreateButton("Unload", function()
        Library:Unload()
    end)
end

function Window:CreateTab(name)
    if Library.Unloaded then return end
    
    Library:Log("info", "Tab", "Creating tab: " .. name)
    
    local tab = {}
    tab.Name = name
    tab.Window = self
    tab.SubTabs = {}
    tab.ActiveSubTab = 1
    tab.Index = #self.Tabs + 1
    tab.Library = Library
    
    -- Tab Button Frame
    tab.ButtonFrame = Create("Frame", {
        Name = name .. "_Frame",
        Size = UDim2.new(0, 0, 0, Library.Config.TabHeight - 4),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = tab.Index,
        ZIndex = 3,
        Parent = self.TabContainer
    })
    
    -- Underline indicator
    tab.Underline = Create("Frame", {
        Name = "Underline",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Config.HighlightColor,
        BorderSizePixel = 0,
        Visible = tab.Index == 1,
        ZIndex = 3,
        Parent = tab.ButtonFrame
    })
    
    tab.Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 1, -2),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = tab.Index == 1 and Library.Config.HighlightColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        ZIndex = 3,
        Parent = tab.ButtonFrame
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = tab.Button
    })
    
    -- SubTab Container
    tab.SubTabContainer = Create("ScrollingFrame", {
        Name = name .. "_SubTabs",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Config.HighlightColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = tab.Index == 1,
        ZIndex = 2,
        Parent = self.LeftPanel
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 2),
        Parent = tab.SubTabContainer
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = tab.SubTabContainer
    })
    
    -- Content Frame
    tab.ContentFrame = Create("Frame", {
        Name = name .. "_Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = tab.Index == 1,
        ZIndex = 2,
        Parent = self.ContentArea
    })
    
    -- CreateSubTab method
    function tab:CreateSubTab(subName)
        Library:Log("info", "SubTab", "Creating: " .. subName)
        
        local subtab = {}
        subtab.Name = subName
        subtab.Tab = self
        subtab.Index = #self.SubTabs + 1
        subtab.Sections = {}
        
        -- SubTab Button Frame
        subtab.ButtonFrame = Create("Frame", {
            Name = subName .. "_Frame",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = subtab.Index,
            ZIndex = 3,
            Parent = self.SubTabContainer
        })
        
        -- Selection background with gradient
        subtab.SelectionBg = Create("Frame", {
            Name = "SelectionBg",
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Library.Config.SelectionBg,
            BorderSizePixel = 0,
            Visible = subtab.Index == 1,
            ZIndex = 3,
            Parent = subtab.ButtonFrame
        })
        
        -- Selection gradient
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library.Config.SelectionGradientStart),
                ColorSequenceKeypoint.new(1, Library.Config.SelectionGradientEnd)
            }),
            Rotation = 0,
            Parent = subtab.SelectionBg
        })
        
        -- Left pink accent line
        subtab.AccentLine = Create("Frame", {
            Name = "AccentLine",
            Size = UDim2.new(0, 2, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Library.Config.HighlightColor,
            BorderSizePixel = 0,
            Visible = subtab.Index == 1,
            ZIndex = 4,
            Parent = subtab.SelectionBg
        })
        
        -- Button text
        subtab.Button = Create("TextButton", {
            Name = subName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = subName,
            TextColor3 = subtab.Index == 1 and Library.Config.HighlightColor or Library.Config.DimTextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 4,
            Parent = subtab.ButtonFrame
        })
        
        subtab.ButtonPadding = Create("UIPadding", {
            PaddingLeft = UDim.new(0, subtab.Index == 1 and 12 or 6),
            PaddingRight = UDim.new(0, 4),
            Parent = subtab.Button
        })
        
        -- Content ScrollingFrame
        subtab.Content = Create("ScrollingFrame", {
            Name = subName .. "_Content",
            Size = UDim2.new(1, -6, 1, -6),
            Position = UDim2.new(0, 3, 0, 3),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.Config.HighlightColor,
            Visible = subtab.Index == 1,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
            Parent = self.ContentFrame
        })
        
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 8),
            Wraps = true,
            Parent = subtab.Content
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            Parent = subtab.Content
        })
        
        -- CreateSection method
        function subtab:CreateSection(sectionName)
            Library:Log("info", "Section", "Creating: " .. sectionName)
            
            local section = {}
            section.Name = sectionName
            section.SubTab = self
            section.Controls = {}
            section.Index = #self.Sections + 1
            
            local panelWidth = Library.Config.PanelWidth
            
            -- Main Panel Frame
            section.Frame = Create("Frame", {
                Name = sectionName,
                Size = UDim2.new(0, panelWidth, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.Config.OuterBorder,
                BorderSizePixel = 0,
                LayoutOrder = section.Index,
                Parent = self.Content
            })
            
            -- Inner border
            local innerBorder = Create("Frame", {
                Name = "InnerBorder",
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                BackgroundColor3 = Library.Config.PanelBorder,
                BorderSizePixel = 0,
                Parent = section.Frame
            })
            
            -- Panel background
            local panelBg = Create("Frame", {
                Name = "Background",
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                BackgroundColor3 = Library.Config.PanelBackground,
                BorderSizePixel = 0,
                Parent = innerBorder
            })
            
            -- Panel gradient overlay for depth
            local panelGradient = Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                Parent = panelBg
            })
            AddGradient(panelGradient, 90)
            
            -- Pink accent line at top
            Create("Frame", {
                Name = "AccentLine",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Library.Config.HighlightColor,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = panelBg
            })
            
            -- Title
            Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -10, 0, 18),
                Position = UDim2.new(0, 5, 0, 2),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 2,
                Parent = panelBg
            })
            
            -- Separator line under title
            Create("Frame", {
                Name = "Separator",
                Size = UDim2.new(1, -10, 0, 1),
                Position = UDim2.new(0, 5, 0, 20),
                BackgroundColor3 = Library.Config.SeparatorColor,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = panelBg
            })
            
            -- Controls container
            section.Content = Create("Frame", {
                Name = "Controls",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 24),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex = 2,
                Parent = panelBg
            })
            
            Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = section.Content
            })
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                Parent = section.Content
            })
            
            -- Add control methods
            section.CreateToggle = function(s, label, default, callback, options)
                return Library.Controls.CreateToggle(s, label, default, callback, options)
            end
            
            section.CreateSlider = function(s, label, options, callback)
                return Library.Controls.CreateSlider(s, label, options, callback)
            end
            
            section.CreateDropdown = function(s, label, options, callback)
                return Library.Controls.CreateDropdown(s, label, options, callback)
            end
            
            section.CreateColorPicker = function(s, label, default, callback)
                return Library.Controls.CreateColorPicker(s, label, default, callback)
            end
            
            section.CreateButton = function(s, label, callback)
                return Library.Controls.CreateButton(s, label, callback)
            end
            
            section.CreateTextBox = function(s, label, default, callback, options)
                return Library.Controls.CreateTextBox(s, label, default, callback, options)
            end
            
            section.CreateLabel = function(s, text)
                return Library.Controls.CreateLabel(s, text)
            end
            
            table.insert(self.Sections, section)
            return section
        end
        
        -- SubTab click handler
        subtab.Button.MouseButton1Click:Connect(function()
            tab:SwitchSubTab(subtab.Index)
        end)
        
        subtab.Button.MouseEnter:Connect(function()
            if subtab.Index ~= tab.ActiveSubTab then
                subtab.Button.TextColor3 = Library.Config.TextColor
            end
        end)
        
        subtab.Button.MouseLeave:Connect(function()
            if subtab.Index ~= tab.ActiveSubTab then
                subtab.Button.TextColor3 = Library.Config.DimTextColor
            end
        end)
        
        table.insert(self.SubTabs, subtab)
        return subtab
    end
    
    -- SwitchSubTab method
    function tab:SwitchSubTab(index)
        if self.ActiveSubTab == index then return end
        
        Library:Log("event", "SubTab", "Switching to: " .. self.SubTabs[index].Name)
        
        local current = self.SubTabs[self.ActiveSubTab]
        if current then
            current.Button.TextColor3 = Library.Config.DimTextColor
            current.SelectionBg.Visible = false
            current.AccentLine.Visible = false
            current.Content.Visible = false
            current.ButtonPadding.PaddingLeft = UDim.new(0, 6)
        end
        
        self.ActiveSubTab = index
        local new = self.SubTabs[index]
        if new then
            new.Button.TextColor3 = Library.Config.HighlightColor
            new.SelectionBg.Visible = true
            new.AccentLine.Visible = true
            new.Content.Visible = true
            new.ButtonPadding.PaddingLeft = UDim.new(0, 12)
        end
    end
    
    -- CreateSection shortcut
    function tab:CreateSection(sectionName)
        if #self.SubTabs == 0 then
            self:CreateSubTab("Main")
        end
        return self.SubTabs[self.ActiveSubTab]:CreateSection(sectionName)
    end
    
    -- Tab click handler
    tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab.Index)
    end)
    
    tab.Button.MouseEnter:Connect(function()
        if tab.Index ~= self.ActiveTab then
            tab.Button.TextColor3 = Library.Config.HighlightColor
        end
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if tab.Index ~= self.ActiveTab then
            tab.Button.TextColor3 = Library.Config.TextColor
        end
    end)
    
    table.insert(self.Tabs, tab)
    return tab
end

function Window:SwitchTab(index)
    if self.ActiveTab == index then return end
    
    Library:Log("event", "Tab", "Switching to: " .. self.Tabs[index].Name)
    
    local current = self.Tabs[self.ActiveTab]
    if current then
        current.Button.TextColor3 = Library.Config.TextColor
        current.Underline.Visible = false
        current.SubTabContainer.Visible = false
        current.ContentFrame.Visible = false
    end
    
    self.ActiveTab = index
    
    local new = self.Tabs[index]
    if new then
        new.Button.TextColor3 = Library.Config.HighlightColor
        new.Underline.Visible = true
        new.SubTabContainer.Visible = true
        new.ContentFrame.Visible = true
    end
end

--[[ CONTROL FACTORY ]]
Library.Controls = {}

-- CheckBox (GHack style with gradient)
function Library.Controls.CreateToggle(section, label, default, callback, options)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or false
    control.Callback = callback
    control.Risk = options.Risk
    control.Type = "Toggle"
    
    Library:TrackControlState(controlId, "Toggle", control.Value)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 15),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    -- Checkbox outer
    local boxOuter = Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = container
    })
    
    -- Inner
    local boxInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = boxOuter
    })
    
    -- Fill
    local boxFill = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = control.Value and Library.Config.HighlightColor or Library.Config.ControlBackground,
        BorderSizePixel = 0,
        Parent = boxInner
    })
    
    -- Checkbox gradient
    local checkGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
        }),
        Rotation = 90,
        Parent = boxFill
    })
    
    -- Label
    Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = control.Risk and Library.Config.RiskTextColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container
    })
    
    -- Click area
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container
    })
    
    button.MouseEnter:Connect(function()
        if not control.Value then
            boxFill.BackgroundColor3 = Library.Config.HoverBackground
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not control.Value then
            boxFill.BackgroundColor3 = Library.Config.ControlBackground
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        control.Value = not control.Value
        boxFill.BackgroundColor3 = control.Value and Library.Config.HighlightColor or Library.Config.ControlBackground
        
        Library:Log("event", "Toggle", label .. " = " .. tostring(control.Value))
        Library:TrackControlState(controlId, "Toggle", control.Value)
        
        if control.Callback then
            local success, err = pcall(control.Callback, control.Value)
            if not success then
                Library:Log("error", "Callback", label .. ": " .. tostring(err))
            end
        end
    end)
    
    function control:Set(value)
        control.Value = value
        boxFill.BackgroundColor3 = value and Library.Config.HighlightColor or Library.Config.ControlBackground
        Library:TrackControlState(controlId, "Toggle", value)
        if control.Callback then pcall(control.Callback, value) end
    end
    
    function control:Get() return control.Value end
    
    table.insert(section.Controls, control)
    return control
end

-- Slider (GHack style with gradient)
function Library.Controls.CreateSlider(section, label, options, callback)
    options = options or {}
    local controlId = section.Name .. "_" .. (label ~= "" and label or "Slider")
    
    local control = {}
    control.Min = options.Min or 0
    control.Max = options.Max or 100
    control.Value = options.Default or control.Min
    control.Decimals = options.Decimals or 0
    control.Suffix = options.Suffix or ""
    control.Callback = callback
    control.Type = "Slider"
    
    Library:TrackControlState(controlId, "Slider", control.Value)
    
    local showLabel = options.DrawLabel ~= false and label ~= ""
    local totalHeight = showLabel and 28 or 14
    
    local container = Create("Frame", {
        Name = label ~= "" and label or "Slider",
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local yOffset = 0
    if showLabel then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = label,
