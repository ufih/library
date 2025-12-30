--[[
    GHack UI Framework - Roblox Luau Port
    Accurate recreation of GMod GHack menu styling
    
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
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer

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

-- Configuration (EXACT GHack colors from menu.lua)
Library.Config = {
    -- Main accent color (pink/magenta)
    HighlightColor = Color3.fromRGB(255, 0, 151),
    
    -- Background colors
    MainBackground = Color3.fromRGB(30, 30, 30),
    PanelBackground = Color3.fromRGB(40, 40, 40),
    ContentBackground = Color3.fromRGB(25, 25, 25),
    ControlBackground = Color3.fromRGB(41, 41, 41),
    HoverBackground = Color3.fromRGB(50, 50, 50),
    
    -- Border colors (exact from GHack)
    OuterBorder = Color3.fromRGB(29, 29, 29),
    InnerBorder = Color3.fromRGB(19, 19, 19),
    DarkBorder = Color3.fromRGB(20, 20, 20),
    LightBorder = Color3.fromRGB(40, 40, 40),
    
    -- Text colors
    TextColor = Color3.fromRGB(255, 255, 255),
    RiskTextColor = Color3.fromRGB(220, 220, 120),
    DimTextColor = Color3.fromRGB(199, 199, 199),
    SubTabInactive = Color3.fromRGB(230, 230, 230),
    
    -- Dimensions
    WindowSizeX = 550,
    WindowSizeY = 400,
    MinSizeX = 550,
    MinSizeY = 400,
    TabHeight = 22,
    LeftAreaPadding = 120,
    Bezel = 3,
    
    -- Animation
    FadeTime = 0.25,
    TabSwitchTime = 0.20,
    
    -- Font (Tahoma equivalent in Roblox)
    Font = Enum.Font.Code, -- Closest to Tahoma
    FontBold = Enum.Font.GothamBold,
    FontSize = 13,
    FontSizeTiny = 10,
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

-- Create gradient frame (simulates GMod gradient materials)
local function CreateGradient(parent, direction, transparency)
    local gradient = Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, transparency or 0),
            NumberSequenceKeypoint.new(1, 0.5)
        }),
        Rotation = direction == "down" and 90 or (direction == "up" and -90 or 0),
        Parent = parent
    })
    return gradient
end

-- Create the double-border box style from GHack
local function CreateOutlinedBox(parent, size, position, bgColor)
    local outer = Create("Frame", {
        Size = size,
        Position = position,
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    local inner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = outer
    })
    
    local content = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = bgColor or Library.Config.ControlBackground,
        BorderSizePixel = 0,
        Parent = inner
    })
    
    return outer, content
end

-- Debug logging
function Library:Log(level, source, message, data)
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
end

function Library:TrackControlState(controlId, controlType, value)
    self.Debug.ControlStates[controlId] = {
        type = controlType,
        value = value,
        lastUpdated = os.clock() - self.Debug.StartTime
    }
end

--[[ WINDOW CLASS ]]
local Window = {}
Window.__index = Window

function Library:CreateWindow(title)
    local self = setmetatable({}, Window)
    self.Title = title or "GHACK OT"
    self.Visible = false
    self.Tabs = {}
    self.ActiveTab = 1
    self.PreviousTab = 1
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
    
    -- Main Window Frame with bezel
    self.MainFrame = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, Library.Config.WindowSizeX + Library.Config.Bezel * 2, 0, Library.Config.WindowSizeY + Library.Config.Bezel * 2),
        Position = UDim2.new(0.5, -(Library.Config.WindowSizeX + Library.Config.Bezel * 2)/2, 0.5, -(Library.Config.WindowSizeY + Library.Config.Bezel * 2)/2),
        BackgroundColor3 = Library.Config.DarkBorder,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.ScreenGui
    })
    
    -- Outer border
    Create("UIStroke", {
        Color = Library.Config.DarkBorder,
        Thickness = 1,
        Parent = self.MainFrame
    })
    
    -- Inner frame
    local innerFrame = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.LightBorder,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    -- Content frame
    self.ContentFrame = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Parent = innerFrame
    })
    
    -- Title Bar (tabs area)
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, Library.Config.TabHeight),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Parent = self.ContentFrame
    })
    
    -- Title bar bottom line
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Config.LightBorder,
        BorderSizePixel = 0,
        Parent = self.TitleBar
    })
    
    -- Title "GHACK OT" in pink
    self.TitleLabel = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Library.Config.HighlightColor,
        Font = Library.Config.FontBold,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    -- Tab Container (right side of title bar)
    self.TabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 100, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
        Parent = self.TabContainer
    })
    
    Create("UIPadding", {
        PaddingRight = UDim.new(0, 10),
        Parent = self.TabContainer
    })
    
    -- Left Panel (SubTabs area)
    self.LeftPanel = Create("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, Library.Config.LeftAreaPadding - 3, 1, -Library.Config.TabHeight - 1),
        Position = UDim2.new(0, 0, 0, Library.Config.TabHeight + 1),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Parent = self.ContentFrame
    })
    
    -- Left panel separator
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Library.Config.LightBorder,
        BorderSizePixel = 0,
        Parent = self.LeftPanel
    })
    
    -- Content Area (right side, darker)
    self.ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -Library.Config.LeftAreaPadding, 1, -Library.Config.TabHeight - 1),
        Position = UDim2.new(0, Library.Config.LeftAreaPadding, 0, Library.Config.TabHeight + 1),
        BackgroundColor3 = Library.Config.ContentBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ContentFrame
    })
    
    -- Setup dragging
    self:SetupDragging()
    
    -- Toggle keybind (Insert like GMod)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
    end)
    
    Library.Debug.WindowInstance = self
    return self
end

function Window:SetupDragging()
    local dragStart, startPos
    
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)
end

function Window:Toggle()
    self.Visible = not self.Visible
    Library:Log("event", "Window", "Toggled: " .. tostring(self.Visible))
    
    if self.Visible then
        self.MainFrame.Visible = true
        self.MainFrame.BackgroundTransparency = 1
        Tween(self.MainFrame, {BackgroundTransparency = 0}, Library.Config.FadeTime)
    else
        Tween(self.MainFrame, {BackgroundTransparency = 1}, Library.Config.FadeTime).Completed:Connect(function()
            self.MainFrame.Visible = false
        end)
    end
end

function Window:CreateTab(name)
    Library:Log("info", "Tab", "Creating tab: " .. name)
    
    local tab = {}
    tab.Name = name
    tab.Window = self
    tab.SubTabs = {}
    tab.ActiveSubTab = 1
    tab.Index = #self.Tabs + 1
    tab.Library = Library
    
    -- Tab Button (text only, like GMod)
    tab.Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(0, 0, 0, Library.Config.TabHeight - 4),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = tab.Index == 1 and Library.Config.HighlightColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        LayoutOrder = tab.Index,
        Parent = self.TabContainer
    })
    
    -- Active indicator line (pink line under active tab)
    tab.ActiveLine = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 2),
        BackgroundColor3 = Library.Config.HighlightColor,
        BorderSizePixel = 0,
        Visible = tab.Index == 1,
        Parent = tab.Button
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
        Parent = self.LeftPanel
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        Parent = tab.SubTabContainer
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 8),
        Parent = tab.SubTabContainer
    })
    
    -- Content Frame
    tab.ContentFrame = Create("Frame", {
        Name = name .. "_Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = tab.Index == 1,
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
        
        -- SubTab Button
        subtab.Button = Create("TextButton", {
            Name = subName,
            Size = UDim2.new(1, -5, 0, 16),
            BackgroundTransparency = 1,
            Text = subName,
            TextColor3 = subtab.Index == 1 and Library.Config.HighlightColor or Color3.fromRGB(230, 230, 230),
            TextTransparency = subtab.Index == 1 and 0 or 0.4,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.SubTabContainer
        })
        
        -- Content ScrollingFrame
        subtab.Content = Create("ScrollingFrame", {
            Name = subName .. "_Content",
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.Config.HighlightColor,
            Visible = subtab.Index == 1,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = self.ContentFrame
        })
        
        Create("UIGridLayout", {
            CellSize = UDim2.new(0.5, -6, 0, 0),
            CellPadding = UDim2.new(0, 8, 0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = 2,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = subtab.Content
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
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
            
            -- Panel Frame (GHack style with gradient border)
            section.Frame = Create("Frame", {
                Name = sectionName,
                Size = UDim2.new(0.5, -6, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.Config.DarkBorder,
                BorderSizePixel = 0,
                LayoutOrder = section.Index,
                Parent = self.Content
            })
            
            -- Inner border
            local innerBorder = Create("Frame", {
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                BackgroundColor3 = Library.Config.LightBorder,
                BorderSizePixel = 0,
                Parent = section.Frame
            })
            
            -- Panel content
            local panelContent = Create("Frame", {
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                BackgroundColor3 = Library.Config.MainBackground,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = innerBorder
            })
            
            -- Pink accent line at top
            Create("Frame", {
                Name = "AccentLine",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Library.Config.HighlightColor,
                BorderSizePixel = 0,
                Parent = panelContent
            })
            
            -- Title (positioned above panel like in GHack)
            section.TitleLabel = Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -10, 0, 16),
                Position = UDim2.new(0, 10, 0, 2),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = panelContent
            })
            
            -- Controls container
            section.Content = Create("Frame", {
                Name = "Controls",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 20),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = panelContent
            })
            
            Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = section.Content
            })
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
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
            
            section.CreateKeybind = function(s, label, default, callback)
                return Library.Controls.CreateKeybind(s, label, default, callback)
            end
            
            table.insert(self.Sections, section)
            return section
        end
        
        -- SubTab click handler
        subtab.Button.MouseButton1Click:Connect(function()
            tab:SwitchSubTab(subtab.Index)
        end)
        
        -- Hover effect
        subtab.Button.MouseEnter:Connect(function()
            if subtab.Index ~= tab.ActiveSubTab then
                subtab.Button.TextTransparency = 0.1
            end
        end)
        
        subtab.Button.MouseLeave:Connect(function()
            if subtab.Index ~= tab.ActiveSubTab then
                subtab.Button.TextTransparency = 0.4
            end
        end)
        
        table.insert(self.SubTabs, subtab)
        return subtab
    end
    
    -- SwitchSubTab method
    function tab:SwitchSubTab(index)
        if self.ActiveSubTab == index then return end
        
        local current = self.SubTabs[self.ActiveSubTab]
        if current then
            current.Button.TextColor3 = Color3.fromRGB(230, 230, 230)
            current.Button.TextTransparency = 0.4
            current.Content.Visible = false
        end
        
        self.ActiveSubTab = index
        local new = self.SubTabs[index]
        if new then
            new.Button.TextColor3 = Library.Config.HighlightColor
            new.Button.TextTransparency = 0
            new.Content.Visible = true
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
    
    table.insert(self.Tabs, tab)
    return tab
end

function Window:SwitchTab(index)
    if self.ActiveTab == index then return end
    
    -- Deactivate current
    local current = self.Tabs[self.ActiveTab]
    if current then
        current.Button.TextColor3 = Library.Config.TextColor
        current.ActiveLine.Visible = false
        current.SubTabContainer.Visible = false
        current.ContentFrame.Visible = false
    end
    
    self.PreviousTab = self.ActiveTab
    self.ActiveTab = index
    
    -- Activate new
    local new = self.Tabs[index]
    if new then
        new.Button.TextColor3 = Library.Config.HighlightColor
        new.ActiveLine.Visible = true
        new.SubTabContainer.Visible = true
        new.ContentFrame.Visible = true
    end
end

--[[ CONTROL FACTORY ]]
Library.Controls = {}

-- CheckBox (exact GHack style)
function Library.Controls.CreateToggle(section, label, default, callback, options)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or false
    control.Callback = callback
    control.Risk = options.Risk
    control.Type = "Toggle"
    
    Library:Log("info", "Control", "Creating toggle: " .. label)
    Library:TrackControlState(controlId, "Toggle", control.Value)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    -- Checkbox outer border (29, 29, 29)
    local boxOuter = Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = container
    })
    
    -- Inner border (19, 19, 19)
    local boxInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = boxOuter
    })
    
    -- Fill area
    local boxFill = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = control.Value and Library.Config.HighlightColor or Library.Config.ControlBackground,
        BorderSizePixel = 0,
        Parent = boxInner
    })
    
    -- Gradient overlay (like GMod GradientDown)
    CreateGradient(boxFill, "down", 0)
    
    -- Label
    local labelText = Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = control.Risk and Library.Config.RiskTextColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    -- Clickable area
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container
    })
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        if not control.Value then
            boxFill.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
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
        if control.Callback then
            pcall(control.Callback, value)
        end
    end
    
    function control:Get()
        return control.Value
    end
    
    table.insert(section.Controls, control)
    return control
end

-- Slider (exact GHack style)
function Library.Controls.CreateSlider(section, label, options, callback)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Min = options.Min or 0
    control.Max = options.Max or 100
    control.Value = options.Default or control.Min
    control.Decimals = options.Decimals or 0
    control.Suffix = options.Suffix or ""
    control.Callback = callback
    control.Type = "Slider"
    
    Library:TrackControlState(controlId, "Slider", control.Value)
    
    local totalHeight = (options.DrawLabel ~= false) and 26 or 12
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local yOffset = 0
    if options.DrawLabel ~= false then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Library.Config.TextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
        yOffset = 14
    end
    
    -- Track outer (29, 29, 29)
    local trackOuter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 11),
        Position = UDim2.new(0, 0, 0, yOffset),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = container
    })
    
    -- Track inner (19, 19, 19)
    local trackInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = trackOuter
    })
    
    -- Track background (41, 41, 41)
    local trackBg = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.ControlBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = trackInner
    })
    
    -- Fill (pink)
    local initialPos = (control.Value - control.Min) / (control.Max - control.Min)
    local fill = Create("Frame", {
        Size = UDim2.new(initialPos, 0, 1, 0),
        BackgroundColor3 = Library.Config.HighlightColor,
        BorderSizePixel = 0,
        Parent = trackBg
    })
    
    -- Gradient on fill
    CreateGradient(fill, "down", 0)
    
    -- Value label (inside slider)
    local valueLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(control.Value) .. control.Suffix,
        TextColor3 = Library.Config.DimTextColor,
        Font = Enum.Font.Code,
        TextSize = 10,
        Parent = trackBg
    })
    
    -- Drag handling
    local dragging = false
    
    local function update(input)
        local pos = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
        local value = control.Min + (control.Max - control.Min) * pos
        
        if control.Decimals == 0 then
            value = math.floor(value + 0.5)
        else
            value = math.floor(value * 10^control.Decimals + 0.5) / 10^control.Decimals
        end
        
        control.Value = value
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(value) .. control.Suffix
        
        Library:TrackControlState(controlId, "Slider", value)
        
        if control.Callback then
            pcall(control.Callback, value)
        end
    end
    
    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    function control:Set(value)
        control.Value = math.clamp(value, control.Min, control.Max)
        local pos = (control.Value - control.Min) / (control.Max - control.Min)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(control.Value) .. control.Suffix
        Library:TrackControlState(controlId, "Slider", control.Value)
        if control.Callback then
            pcall(control.Callback, control.Value)
        end
    end
    
    function control:Get()
        return control.Value
    end
    
    table.insert(section.Controls, control)
    return control
end

-- Dropdown (GHack style)
function Library.Controls.CreateDropdown(section, label, options, callback)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Options = options.Options or {}
    control.Value = options.Default or control.Options[1] or ""
    control.Callback = callback
    control.Opened = false
    control.Type = "Dropdown"
    
    Library:TrackControlState(controlId, "Dropdown", control.Value)
    
    local totalHeight = (options.DrawLabel ~= false) and 32 or 18
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 5,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local yOffset = 0
    if options.DrawLabel ~= false then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = options.Risk and Library.Config.RiskTextColor or Library.Config.TextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = container
        })
        yOffset = 14
    end
    
    -- Dropdown button (GHack style)
    local btnOuter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, yOffset),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = container
    })
    
    local btnInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = btnOuter
    })
    
    local btnBg = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.PanelBackground,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = btnInner
    })
    
    CreateGradient(btnBg, "down", 0)
    
    local valueText = Create("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(control.Value),
        TextColor3 = Color3.fromRGB(230, 230, 230),
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = btnBg
    })
    
    -- Arrow (triangle)
    local arrow = Create("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -18, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = 8,
        ZIndex = 6,
        Parent = btnBg
    })
    
    -- Button overlay
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 7,
        Parent = btnBg
    })
    
    -- Options frame
    local optionsFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, yOffset + 18),
        BackgroundColor3 = Library.Config.PanelBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 100,
        Visible = false,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.InnerBorder,
        Thickness = 1,
        Parent = optionsFrame
    })
    
    local optionsList = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = optionsFrame
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        Parent = optionsList
    })
    
    local function createOptions()
        for _, child in ipairs(optionsList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        for _, option in ipairs(control.Options) do
            local optBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = Library.Config.PanelBackground,
                BorderSizePixel = 0,
                Text = tostring(option),
                TextColor3 = control.Value == option and Library.Config.HighlightColor or Library.Config.TextColor,
                Font = control.Value == option and Library.Config.FontBold or Library.Config.Font,
                TextSize = Library.Config.FontSize,
                ZIndex = 101,
                Parent = optionsList
            })
            
            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundColor3 = Library.Config.HoverBackground
            end)
            
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundColor3 = Library.Config.PanelBackground
            end)
            
            optBtn.MouseButton1Click:Connect(function()
                control.Value = option
                valueText.Text = tostring(option)
                control.Opened = false
                optionsFrame.Visible = false
                optionsFrame.Size = UDim2.new(1, 0, 0, 0)
                arrow.Text = "▼"
                
                Library:TrackControlState(controlId, "Dropdown", option)
                
                if control.Callback then
                    pcall(control.Callback, option)
                end
                
                -- Update styling
                for _, btn in ipairs(optionsList:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.TextColor3 = btn.Text == tostring(option) and Library.Config.HighlightColor or Library.Config.TextColor
                        btn.Font = btn.Text == tostring(option) and Library.Config.FontBold or Library.Config.Font
                    end
                end
            end)
        end
    end
    
    createOptions()
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        btnBg.BackgroundColor3 = Library.Config.HoverBackground
    end)
    
    button.MouseLeave:Connect(function()
        if not control.Opened then
            btnBg.BackgroundColor3 = Library.Config.PanelBackground
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        control.Opened = not control.Opened
        optionsFrame.Visible = control.Opened
        local targetHeight = control.Opened and math.min(#control.Options * 18, 126) or 0
        optionsFrame.Size = UDim2.new(1, 0, 0, targetHeight)
        arrow.Text = control.Opened and "▲" or "▼"
        btnBg.BackgroundColor3 = control.Opened and Library.Config.HoverBackground or Library.Config.PanelBackground
    end)
    
    function control:Set(value)
        control.Value = value
        valueText.Text = tostring(value)
        Library:TrackControlState(controlId, "Dropdown", value)
        if control.Callback then
            pcall(control.Callback, value)
        end
    end
    
    function control:Refresh(newOptions)
        control.Options = newOptions
        createOptions()
    end
    
    function control:Get()
        return control.Value
    end
    
    table.insert(section.Controls, control)
    return control
end

-- Button (GHack style)
function Library.Controls.CreateButton(section, label, callback)
    local control = {}
    control.Callback = callback
    control.Type = "Button"
    
    -- Button outer
    local btnOuter = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local btnInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = btnOuter
    })
    
    local btnBg = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.PanelBackground,
        BorderSizePixel = 0,
        Parent = btnInner
    })
    
    CreateGradient(btnBg, "down", 0)
    
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        Parent = btnBg
    })
    
    button.MouseEnter:Connect(function()
        btnBg.BackgroundColor3 = Library.Config.HoverBackground
    end)
    
    button.MouseLeave:Connect(function()
        btnBg.BackgroundColor3 = Library.Config.PanelBackground
    end)
    
    button.MouseButton1Click:Connect(function()
        btnBg.BackgroundColor3 = Library.Config.HighlightColor
        task.delay(0.15, function()
            btnBg.BackgroundColor3 = Library.Config.PanelBackground
        end)
        
        if control.Callback then
            pcall(control.Callback)
        end
    end)
    
    table.insert(section.Controls, control)
    return control
end

-- ColorPicker (simplified GHack style)
function Library.Controls.CreateColorPicker(section, label, default, callback)
    local control = {}
    control.Value = default or Library.Config.HighlightColor
    control.Callback = callback
    control.Opened = false
    control.Type = "ColorPicker"
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 3,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = container
    })
    
    -- Color box (GHack style)
    local colorBoxOuter = Create("Frame", {
        Size = UDim2.new(0, 22, 0, 12),
        Position = UDim2.new(1, -22, 0.5, -6),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = container
    })
    
    local colorBoxInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = colorBoxOuter
    })
    
    local colorBox = Create("TextButton", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = control.Value,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 3,
        Parent = colorBoxInner
    })
    
    CreateGradient(colorBox, "down", 0)
    
    -- Picker popup
    local pickerFrame = Create("Frame", {
        Size = UDim2.new(0, 160, 0, 90),
        Position = UDim2.new(1, -160, 0, 16),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.HighlightColor,
        Thickness = 1,
        Parent = pickerFrame
    })
    
    local function createSlider(name, y, color, getValue, setValue)
        Create("TextLabel", {
            Size = UDim2.new(0, 14, 0, 12),
            Position = UDim2.new(0, 5, 0, y),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = color,
            Font = Library.Config.Font,
            TextSize = 10,
            ZIndex = 51,
            Parent = pickerFrame
        })
        
        local sliderBg = Create("Frame", {
            Size = UDim2.new(1, -30, 0, 10),
            Position = UDim2.new(0, 22, 0, y + 1),
            BackgroundColor3 = Library.Config.ControlBackground,
            BorderSizePixel = 0,
            ZIndex = 51,
            Parent = pickerFrame
        })
        
        local fill = Create("Frame", {
            Size = UDim2.new(getValue() / 255, 0, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 52,
            Parent = sliderBg
        })
        
        local dragging = false
        
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                setValue(math.floor(pos * 255))
                colorBox.BackgroundColor3 = control.Value
                if control.Callback then
                    pcall(control.Callback, control.Value)
                end
            end
        end)
        
        return fill
    end
    
    local rFill = createSlider("R", 8, Color3.fromRGB(255, 100, 100),
        function() return control.Value.R * 255 end,
        function(v) control.Value = Color3.fromRGB(v, control.Value.G * 255, control.Value.B * 255) end
    )
    
    local gFill = createSlider("G", 28, Color3.fromRGB(100, 255, 100),
        function() return control.Value.G * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, v, control.Value.B * 255) end
    )
    
    local bFill = createSlider("B", 48, Color3.fromRGB(100, 100, 255),
        function() return control.Value.B * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, control.Value.G * 255, v) end
    )
    
    -- Hex input
    local hexBox = Create("TextBox", {
        Size = UDim2.new(1, -10, 0, 16),
        Position = UDim2.new(0, 5, 0, 68),
        BackgroundColor3 = Library.Config.ControlBackground,
        BorderSizePixel = 0,
        Text = string.format("#%02X%02X%02X", control.Value.R * 255, control.Value.G * 255, control.Value.B * 255),
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = 10,
        ZIndex = 51,
        Parent = pickerFrame
    })
    
    hexBox.FocusLost:Connect(function()
        local hex = hexBox.Text:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16) or 0
            local g = tonumber(hex:sub(3, 4), 16) or 0
            local b = tonumber(hex:sub(5, 6), 16) or 0
            control.Value = Color3.fromRGB(r, g, b)
            colorBox.BackgroundColor3 = control.Value
            rFill.Size = UDim2.new(r / 255, 0, 1, 0)
            gFill.Size = UDim2.new(g / 255, 0, 1, 0)
            bFill.Size = UDim2.new(b / 255, 0, 1, 0)
            if control.Callback then
                pcall(control.Callback, control.Value)
            end
        end
    end)
    
    colorBox.MouseButton1Click:Connect(function()
        control.Opened = not control.Opened
        pickerFrame.Visible = control.Opened
        hexBox.Text = string.format("#%02X%02X%02X", control.Value.R * 255, control.Value.G * 255, control.Value.B * 255)
    end)
    
    function control:Set(color)
        control.Value = color
        colorBox.BackgroundColor3 = color
        rFill.Size = UDim2.new(color.R, 0, 1, 0)
        gFill.Size = UDim2.new(color.G, 0, 1, 0)
        bFill.Size = UDim2.new(color.B, 0, 1, 0)
        if control.Callback then
            pcall(control.Callback, color)
        end
    end
    
    function control:Get()
        return control.Value
    end
    
    table.insert(section.Controls, control)
    return control
end

-- Label
function Library.Controls.CreateLabel(section, text)
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Library.Config.DimTextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    return {
        Set = function(_, newText)
            label.Text = newText
        end,
        Type = "Label"
    }
end

-- TextBox
function Library.Controls.CreateTextBox(section, label, default, callback, options)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or ""
    control.Callback = callback
    control.Type = "TextBox"
    
    local totalHeight = (options.HideLabel) and 18 or 32
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local yOffset = 0
    if not options.HideLabel then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Library.Config.TextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
        yOffset = 14
    end
    
    local boxOuter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, yOffset),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = container
    })
    
    local boxInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = boxOuter
    })
    
    local textBox = Create("TextBox", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.ControlBackground,
        BorderSizePixel = 0,
        Text = control.Value,
        PlaceholderText = options.Placeholder or "",
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        ClearTextOnFocus = false,
        Parent = boxInner
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = textBox
    })
    
    textBox.FocusLost:Connect(function()
        control.Value = textBox.Text
        Library:TrackControlState(controlId, "TextBox", textBox.Text)
        if control.Callback then
            pcall(control.Callback, textBox.Text)
        end
    end)
    
    function control:Set(value)
        control.Value = value
        textBox.Text = value
        Library:TrackControlState(controlId, "TextBox", value)
    end
    
    function control:Get()
        return control.Value
    end
    
    table.insert(section.Controls, control)
    return control
end

--[[ DEBUG GUI ]]
function Library:EnableDebugMode()
    if self.Debug.Enabled then
        if self.Debug.GUI then
            self.Debug.GUI:Destroy()
            self.Debug.GUI = nil
        end
        self.Debug.Enabled = false
        return
    end
    
    self.Debug.Enabled = true
    
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
    
    -- Title
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
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "🔧 DEBUG CONSOLE",
        TextColor3 = Color3.fromRGB(80, 200, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
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
        self:EnableDebugMode()
    end)
    
    -- Logs area
    local logsFrame = Create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -80),
        Position = UDim2.new(0, 8, 0, 36),
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
        Padding = UDim.new(0, 2),
        Parent = logsFrame
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = logsFrame
    })
    
    -- Buttons
    local buttonsFrame = Create("Frame", {
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.new(0, 8, 1, -40),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        Parent = buttonsFrame
    })
    
    local function createDebugButton(text, callback)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 100, 1, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            Parent = buttonsFrame
        })
        
        Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = btn
        })
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    createDebugButton("Copy Logs", function()
        local text = ""
        for _, log in ipairs(self.Debug.Logs) do
            text = text .. log.formatted .. "\n"
        end
        if setclipboard then
            setclipboard(text)
        end
    end)
    
    createDebugButton("Clear Logs", function()
        self.Debug.Logs = {}
        self.Debug.EventLogs = {}
        self.Debug.CallbackErrors = {}
        for _, child in ipairs(logsFrame:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
    end)
    
    createDebugButton("Copy States", function()
        if setclipboard and HttpService then
            local success, json = pcall(function()
                return HttpService:JSONEncode(self.Debug.ControlStates)
            end)
            if success then
                setclipboard(json)
            end
        end
    end)
    
    -- Update function
    local function updateLogs()
        for _, child in ipairs(logsFrame:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        for i = math.max(1, #self.Debug.Logs - 100), #self.Debug.Logs do
            local log = self.Debug.Logs[i]
            if log then
                local color = Library.Config.TextColor
                if log.level == "error" then
                    color = Color3.fromRGB(255, 80, 80)
                elseif log.level == "event" then
                    color = Color3.fromRGB(80, 200, 255)
                elseif log.level == "info" then
                    color = Color3.fromRGB(80, 255, 80)
                end
                
                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
                    BorderSizePixel = 0,
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
    end
    
    self.UpdateDebugGUI = updateLogs
    updateLogs()
    
    -- Make draggable
    local dragging = false
    local dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

return Library
