--[[
    GHack UI Framework - Roblox Luau Port
    Original: GMod Lua by GHack
    
    Usage:
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ufih/library/refs/heads/main/library.lua"))()
    local Window = Library:CreateWindow("Window Title")
    
    SECRET DEBUG FLAG:
    Library:EnableDebugMode() -- Opens comprehensive debug GUI
    -- or hold LeftAlt + RightAlt + D while menu is open
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
local Mouse = Player:GetMouse()

-- Debug System
Library.Debug = {
    Enabled = false,
    Logs = {},
    EventLogs = {},
    PerformanceLogs = {},
    ControlStates = {},
    MaxLogs = 500,
    StartTime = os.clock(),
    FrameTimes = {},
    CallbackErrors = {},
    WindowInstance = nil,
}

-- Configuration (matching GHack style)
Library.Config = {
    -- Colors (matching GMod GHack theme)
    HighlightColor = Color3.fromRGB(255, 0, 151),
    BackgroundColor = Color3.fromRGB(30, 30, 30),
    SecondaryBackground = Color3.fromRGB(40, 40, 40),
    TertiaryBackground = Color3.fromRGB(50, 50, 50),
    BorderColor = Color3.fromRGB(19, 19, 19),
    OuterBorderColor = Color3.fromRGB(29, 29, 29),
    TextColor = Color3.fromRGB(255, 255, 255),
    RiskTextColor = Color3.fromRGB(220, 220, 120),
    DimTextColor = Color3.fromRGB(199, 199, 199),
    ErrorColor = Color3.fromRGB(255, 80, 80),
    WarningColor = Color3.fromRGB(255, 200, 80),
    SuccessColor = Color3.fromRGB(80, 255, 80),
    DebugColor = Color3.fromRGB(80, 200, 255),
    
    -- Dimensions (matching GHack defaults)
    WindowSizeX = 550,
    WindowSizeY = 400,
    MinSizeX = 550,
    MinSizeY = 400,
    TabHeight = 22,
    LeftAreaPadding = 120,
    Bezel = 3,
    ScrollBarWidth = 10,
    
    -- Animation
    FadeTime = 0.25,
    TabSwitchTime = 0.20,
    
    -- Fonts
    Font = Enum.Font.Code,
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

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local ms = math.floor((seconds % 1) * 1000)
    return string.format("%02d:%02d.%03d", mins, secs, ms)
end

--[[ DEBUG LOGGING SYSTEM ]]
function Library:Log(level, source, message, data)
    local timestamp = os.clock() - self.Debug.StartTime
    local logEntry = {
        timestamp = timestamp,
        level = level,
        source = source,
        message = message,
        data = data,
        formatted = string.format("[%s] [%s] [%s] %s", FormatTime(timestamp), level:upper(), source, message)
    }
    
    table.insert(self.Debug.Logs, logEntry)
    
    -- Trim logs if over limit
    while #self.Debug.Logs > self.Debug.MaxLogs do
        table.remove(self.Debug.Logs, 1)
    end
    
    -- Also add to specific category
    if level == "event" then
        table.insert(self.Debug.EventLogs, logEntry)
        while #self.Debug.EventLogs > self.Debug.MaxLogs do
            table.remove(self.Debug.EventLogs, 1)
        end
    elseif level == "perf" then
        table.insert(self.Debug.PerformanceLogs, logEntry)
        while #self.Debug.PerformanceLogs > self.Debug.MaxLogs do
            table.remove(self.Debug.PerformanceLogs, 1)
        end
    elseif level == "error" then
        table.insert(self.Debug.CallbackErrors, logEntry)
        while #self.Debug.CallbackErrors > 100 do
            table.remove(self.Debug.CallbackErrors, 1)
        end
    end
    
    if self.Debug.Enabled then
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

--[[ WINDOW CLASS ]]
local Window = {}
Window.__index = Window

function Library:CreateWindow(title)
    local self = setmetatable({}, Window)
    self.Title = title or "GHack UI"
    self.Visible = false
    self.Tabs = {}
    self.ActiveTab = 1
    self.Values = {}
    self.Dragging = false
    self.Resizing = false
    self.Library = Library
    
    Library:Log("info", "Window", "Creating window: " .. title)
    
    -- Create ScreenGui
    self.ScreenGui = Create("ScreenGui", {
        Name = "GHackUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    -- Try CoreGui first, fallback to PlayerGui
    local success = pcall(function()
        self.ScreenGui.Parent = CoreGui
    end)
    if not success then
        self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end
    
    -- Main Window Frame
    self.MainFrame = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, Library.Config.WindowSizeX, 0, Library.Config.WindowSizeY),
        Position = UDim2.new(0.5, -Library.Config.WindowSizeX/2, 0.5, -Library.Config.WindowSizeY/2),
        BackgroundColor3 = Library.Config.BackgroundColor,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.ScreenGui
    })
    
    -- Border
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = self.MainFrame
    })
    
    -- Title Bar
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, Library.Config.TabHeight),
        BackgroundColor3 = Library.Config.BackgroundColor,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    -- Accent line under title
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Library.Config.HighlightColor,
        BorderSizePixel = 0,
        Parent = self.TitleBar
    })
    
    -- Title Text
    self.TitleLabel = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Library.Config.HighlightColor,
        Font = Enum.Font.GothamBold,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    -- Tab Container
    self.TabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -110, 1, 0),
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
    
    -- Left Panel (SubTabs)
    self.LeftPanel = Create("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, Library.Config.LeftAreaPadding, 1, -Library.Config.TabHeight - 1),
        Position = UDim2.new(0, 0, 0, Library.Config.TabHeight + 1),
        BackgroundColor3 = Library.Config.BackgroundColor,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    -- Separator line
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Library.Config.BorderColor,
        BorderSizePixel = 0,
        Parent = self.LeftPanel
    })
    
    -- Content Area
    self.ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -Library.Config.LeftAreaPadding, 1, -Library.Config.TabHeight - 1),
        Position = UDim2.new(0, Library.Config.LeftAreaPadding, 0, Library.Config.TabHeight + 1),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.MainFrame
    })
    
    -- Setup dragging
    self:SetupDragging()
    
    -- Setup toggle keybind (Insert key like GMod)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
            self:Toggle()
        end
        
        -- Secret debug shortcut: LeftAlt + RightAlt + D
        if input.KeyCode == Enum.KeyCode.D then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
                Library:EnableDebugMode()
            end
        end
    end)
    
    -- Store window reference
    Library.Debug.WindowInstance = self
    Library:Log("info", "Window", "Window created successfully")
    
    return self
end

function Window:SetupDragging()
    local dragStart, startPos
    
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            Library:Log("event", "Window", "Drag started")
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
            if self.Dragging then
                Library:Log("event", "Window", "Drag ended")
            end
            self.Dragging = false
        end
    end)
end

function Window:Toggle()
    self.Visible = not self.Visible
    Library:Log("event", "Window", "Toggled visibility: " .. tostring(self.Visible))
    
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
    setmetatable(tab, {__index = tab})
    
    tab.Name = name
    tab.Window = self
    tab.SubTabs = {}
    tab.ActiveSubTab = 1
    tab.Index = #self.Tabs + 1
    tab.Library = Library
    
    -- Tab Button
    tab.Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = tab.Index == 1 and Library.Config.HighlightColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        LayoutOrder = tab.Index,
        Parent = self.TabContainer
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = tab.Button
    })
    
    -- SubTab Container (in left panel)
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
        Padding = UDim.new(0, 2),
        Parent = tab.SubTabContainer
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
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
    
    -- CreateSubTab method for this tab
    function tab:CreateSubTab(subName)
        Library:Log("info", "SubTab", "Creating subtab: " .. subName .. " in tab: " .. name)
        
        local subtab = {}
        subtab.Name = subName
        subtab.Tab = self
        subtab.Index = #self.SubTabs + 1
        subtab.Sections = {}
        subtab.Library = Library
        
        -- SubTab Button
        subtab.Button = Create("TextButton", {
            Name = subName,
            Size = UDim2.new(1, -10, 0, 18),
            BackgroundTransparency = 1,
            Text = subName,
            TextColor3 = subtab.Index == 1 and Library.Config.HighlightColor or Library.Config.DimTextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.SubTabContainer
        })
        
        -- Content ScrollingFrame
        subtab.Content = Create("ScrollingFrame", {
            Name = subName .. "_Content",
            Size = UDim2.new(1, -10, 1, -10),
            Position = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.Config.HighlightColor,
            Visible = subtab.Index == 1,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = self.ContentFrame
        })
        
        Create("UIGridLayout", {
            CellSize = UDim2.new(0.5, -8, 0, 0),
            CellPadding = UDim2.new(0, 10, 0, 10),
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = 2,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = subtab.Content
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            Parent = subtab.Content
        })
        
        -- CreateSection method for this subtab
        function subtab:CreateSection(sectionName)
            Library:Log("info", "Section", "Creating section: " .. sectionName)
            
            local section = {}
            section.Name = sectionName
            section.SubTab = self
            section.Controls = {}
            section.Index = #self.Sections + 1
            section.Library = Library
            
            -- Panel Frame
            section.Frame = Create("Frame", {
                Name = sectionName,
                Size = UDim2.new(0.5, -8, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.Config.BackgroundColor,
                BorderSizePixel = 0,
                LayoutOrder = section.Index,
                Parent = self.Content
            })
            
            -- Outer border
            Create("UIStroke", {
                Color = Library.Config.OuterBorderColor,
                Thickness = 1,
                Parent = section.Frame
            })
            
            -- Panel header
            section.Header = Create("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = Library.Config.BackgroundColor,
                BorderSizePixel = 0,
                Parent = section.Frame
            })
            
            -- Accent line at top
            Create("Frame", {
                Name = "Accent",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Library.Config.HighlightColor,
                BorderSizePixel = 0,
                Parent = section.Header
            })
            
            -- Title
            Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section.Header
            })
            
            -- Content container
            section.Content = Create("Frame", {
                Name = "Content",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 18),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = section.Frame
            })
            
            Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = section.Content
            })
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                Parent = section.Content
            })
            
            -- Add control creation methods to section
            section.CreateToggle = function(self, label, default, callback, options)
                return Library.Controls.CreateToggle(self, label, default, callback, options)
            end
            
            section.CreateSlider = function(self, label, options, callback)
                return Library.Controls.CreateSlider(self, label, options, callback)
            end
            
            section.CreateDropdown = function(self, label, options, callback)
                return Library.Controls.CreateDropdown(self, label, options, callback)
            end
            
            section.CreateColorPicker = function(self, label, default, callback)
                return Library.Controls.CreateColorPicker(self, label, default, callback)
            end
            
            section.CreateButton = function(self, label, callback)
                return Library.Controls.CreateButton(self, label, callback)
            end
            
            section.CreateTextBox = function(self, label, default, callback, options)
                return Library.Controls.CreateTextBox(self, label, default, callback, options)
            end
            
            section.CreateLabel = function(self, text)
                return Library.Controls.CreateLabel(self, text)
            end
            
            section.CreateKeybind = function(self, label, default, callback)
                return Library.Controls.CreateKeybind(self, label, default, callback)
            end
            
            table.insert(self.Sections, section)
            return section
        end
        
        -- Click handler for subtab
        subtab.Button.MouseButton1Click:Connect(function()
            Library:Log("event", "SubTab", "Clicked: " .. subName)
            tab:SwitchSubTab(subtab.Index)
        end)
        
        table.insert(self.SubTabs, subtab)
        return subtab
    end
    
    -- SwitchSubTab method
    function tab:SwitchSubTab(index)
        if self.ActiveSubTab == index then return end
        
        Library:Log("event", "SubTab", "Switching from " .. self.ActiveSubTab .. " to " .. index)
        
        local current = self.SubTabs[self.ActiveSubTab]
        if current then
            current.Button.TextColor3 = Library.Config.DimTextColor
            current.Content.Visible = false
        end
        
        self.ActiveSubTab = index
        local new = self.SubTabs[index]
        if new then
            new.Button.TextColor3 = Library.Config.HighlightColor
            new.Content.Visible = true
        end
    end
    
    -- CreateSection shortcut on tab (auto-creates subtab if needed)
    function tab:CreateSection(sectionName)
        if #self.SubTabs == 0 then
            self:CreateSubTab("Main")
        end
        return self.SubTabs[self.ActiveSubTab]:CreateSection(sectionName)
    end
    
    -- Tab click handler
    tab.Button.MouseButton1Click:Connect(function()
        Library:Log("event", "Tab", "Clicked: " .. name)
        self:SwitchTab(tab.Index)
    end)
    
    table.insert(self.Tabs, tab)
    return tab
end

function Window:SwitchTab(index)
    if self.ActiveTab == index then return end
    
    Library:Log("event", "Tab", "Switching from " .. self.ActiveTab .. " to " .. index)
    
    -- Deactivate current tab
    local currentTab = self.Tabs[self.ActiveTab]
    if currentTab then
        currentTab.Button.TextColor3 = Library.Config.TextColor
        currentTab.SubTabContainer.Visible = false
        currentTab.ContentFrame.Visible = false
    end
    
    -- Activate new tab
    self.ActiveTab = index
    local newTab = self.Tabs[index]
    if newTab then
        newTab.Button.TextColor3 = Library.Config.HighlightColor
        newTab.SubTabContainer.Visible = true
        newTab.ContentFrame.Visible = true
    end
end

--[[ CONTROL FACTORY ]]
Library.Controls = {}

-- Toggle/CheckBox
function Library.Controls.CreateToggle(section, label, default, callback, options)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or false
    control.Callback = callback
    control.Risk = options.Risk
    control.Type = "Toggle"
    control.Id = controlId
    
    Library:Log("info", "Control", "Creating toggle: " .. label)
    Library:TrackControlState(controlId, "Toggle", control.Value)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    -- Checkbox box
    local boxOuter = Create("Frame", {
        Name = "BoxOuter",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Library.Config.OuterBorderColor,
        BorderSizePixel = 0,
        Parent = container
    })
    
    local boxInner = Create("Frame", {
        Name = "BoxInner",
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.BorderColor,
        BorderSizePixel = 0,
        Parent = boxOuter
    })
    
    local boxFill = Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = control.Value and Library.Config.HighlightColor or Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = boxInner
    })
    
    -- Label
    Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -18, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = control.Risk and Library.Config.RiskTextColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    -- Click handler
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container
    })
    
    button.MouseButton1Click:Connect(function()
        control.Value = not control.Value
        boxFill.BackgroundColor3 = control.Value and Library.Config.HighlightColor or Library.Config.SecondaryBackground
        
        Library:Log("event", "Control", string.format("Toggle '%s' changed to: %s", label, tostring(control.Value)))
        Library:TrackControlState(controlId, "Toggle", control.Value)
        
        if control.Callback then
            local success, err = pcall(function()
                control.Callback(control.Value)
            end)
            if not success then
                Library:Log("error", "Callback", string.format("Toggle '%s' callback error: %s", label, tostring(err)))
            end
        end
    end)
    
    function control:Set(value)
        control.Value = value
        boxFill.BackgroundColor3 = value and Library.Config.HighlightColor or Library.Config.SecondaryBackground
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

-- Slider
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
    control.Id = controlId
    
    Library:Log("info", "Control", "Creating slider: " .. label)
    Library:TrackControlState(controlId, "Slider", control.Value)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, options.HideLabel and 14 or 28),
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
    
    -- Slider track
    local trackOuter = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 10),
        Position = UDim2.new(0, 2, 0, yOffset),
        BackgroundColor3 = Library.Config.OuterBorderColor,
        BorderSizePixel = 0,
        Parent = container
    })
    
    local trackInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.BorderColor,
        BorderSizePixel = 0,
        Parent = trackOuter
    })
    
    local trackBg = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = trackInner
    })
    
    -- Fill
    local initialPos = (control.Value - control.Min) / (control.Max - control.Min)
    local fill = Create("Frame", {
        Size = UDim2.new(initialPos, 0, 1, 0),
        BackgroundColor3 = Library.Config.HighlightColor,
        BorderSizePixel = 0,
        Parent = trackBg
    })
    
    -- Value label
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
            local success, err = pcall(function()
                control.Callback(value)
            end)
            if not success then
                Library:Log("error", "Callback", string.format("Slider '%s' callback error: %s", label, tostring(err)))
            end
        end
    end
    
    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Library:Log("event", "Control", "Slider '" .. label .. "' drag started")
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
            if dragging then
                Library:Log("event", "Control", string.format("Slider '%s' set to: %s", label, tostring(control.Value)))
            end
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

-- Dropdown
function Library.Controls.CreateDropdown(section, label, options, callback)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Options = options.Options or {}
    control.Value = options.Default or control.Options[1] or ""
    control.Callback = callback
    control.Opened = false
    control.Type = "Dropdown"
    control.Id = controlId
    
    Library:Log("info", "Control", "Creating dropdown: " .. label)
    Library:TrackControlState(controlId, "Dropdown", control.Value)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, options.HideLabel and 20 or 34),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 5,
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
            ZIndex = 5,
            Parent = container
        })
        yOffset = 14
    end
    
    -- Dropdown button
    local button = Create("TextButton", {
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.new(0, 2, 0, yOffset),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 5,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = button
    })
    
    local valueText = Create("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(control.Value),
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = button
    })
    
    -- Arrow
    local arrow = Create("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -18, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = 10,
        ZIndex = 5,
        Parent = button
    })
    
    -- Options frame
    local optionsFrame = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        Position = UDim2.new(0, 2, 0, yOffset + 18),
        BackgroundColor3 = Library.Config.TertiaryBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 100,
        Visible = false,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.HighlightColor,
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
        -- Clear existing
        for _, child in ipairs(optionsList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Create option buttons
        for i, option in ipairs(control.Options) do
            local optBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = Library.Config.TertiaryBackground,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Text = tostring(option),
                TextColor3 = Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                ZIndex = 101,
                Parent = optionsList
            })
            
            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundColor3 = Library.Config.HighlightColor
            end)
            
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundColor3 = Library.Config.TertiaryBackground
            end)
            
            optBtn.MouseButton1Click:Connect(function()
                control.Value = option
                valueText.Text = tostring(option)
                control.Opened = false
                optionsFrame.Visible = false
                optionsFrame.Size = UDim2.new(1, -4, 0, 0)
                arrow.Text = "▼"
                
                Library:Log("event", "Control", string.format("Dropdown '%s' selected: %s", label, tostring(option)))
                Library:TrackControlState(controlId, "Dropdown", option)
                
                if control.Callback then
                    local success, err = pcall(function()
                        control.Callback(option)
                    end)
                    if not success then
                        Library:Log("error", "Callback", string.format("Dropdown '%s' callback error: %s", label, tostring(err)))
                    end
                end
            end)
        end
    end
    
    createOptions()
    
    -- Toggle dropdown
    button.MouseButton1Click:Connect(function()
        control.Opened = not control.Opened
        optionsFrame.Visible = control.Opened
        local targetHeight = control.Opened and math.min(#control.Options * 18, 150) or 0
        optionsFrame.Size = UDim2.new(1, -4, 0, targetHeight)
        arrow.Text = control.Opened and "▲" or "▼"
        Library:Log("event", "Control", "Dropdown '" .. label .. "' " .. (control.Opened and "opened" or "closed"))
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

-- ColorPicker
function Library.Controls.CreateColorPicker(section, label, default, callback)
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or Color3.fromRGB(255, 0, 151)
    control.Callback = callback
    control.Opened = false
    control.Type = "ColorPicker"
    control.Id = controlId
    
    Library:Log("info", "Control", "Creating colorpicker: " .. label)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 3,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    -- Label
    Create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = container
    })
    
    -- Color preview box
    local colorBox = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 10),
        Position = UDim2.new(1, -26, 0.5, -5),
        BackgroundColor3 = control.Value,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 3,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = colorBox
    })
    
    -- Color picker popup
    local pickerFrame = Create("Frame", {
        Size = UDim2.new(0, 180, 0, 100),
        Position = UDim2.new(1, -180, 0, 16),
        BackgroundColor3 = Library.Config.TertiaryBackground,
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
    
    local rFill, gFill, bFill
    
    -- RGB Sliders
    local function createColorSlider(name, y, color, getValue, setValue)
        Create("TextLabel", {
            Size = UDim2.new(0, 16, 0, 14),
            Position = UDim2.new(0, 5, 0, y),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = color,
            Font = Library.Config.Font,
            TextSize = 11,
            ZIndex = 51,
            Parent = pickerFrame
        })
        
        local slider = Create("Frame", {
            Size = UDim2.new(1, -35, 0, 10),
            Position = UDim2.new(0, 25, 0, y + 2),
            BackgroundColor3 = Library.Config.SecondaryBackground,
            BorderSizePixel = 0,
            ZIndex = 51,
            Parent = pickerFrame
        })
        
        local fill = Create("Frame", {
            Size = UDim2.new(getValue() / 255, 0, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 52,
            Parent = slider
        })
        
        local dragging = false
        
        slider.InputBegan:Connect(function(input)
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
                local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
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
    
    rFill = createColorSlider("R", 10, Color3.fromRGB(255, 100, 100), 
        function() return control.Value.R * 255 end,
        function(v) control.Value = Color3.fromRGB(v, control.Value.G * 255, control.Value.B * 255) end
    )
    
    gFill = createColorSlider("G", 35, Color3.fromRGB(100, 255, 100),
        function() return control.Value.G * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, v, control.Value.B * 255) end
    )
    
    bFill = createColorSlider("B", 60, Color3.fromRGB(100, 100, 255),
        function() return control.Value.B * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, control.Value.G * 255, v) end
    )
    
    -- Hex input
    local hexBox = Create("TextBox", {
        Size = UDim2.new(1, -10, 0, 16),
        Position = UDim2.new(0, 5, 0, 80),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Text = string.format("#%02X%02X%02X", control.Value.R * 255, control.Value.G * 255, control.Value.B * 255),
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = 11,
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
        Library:Log("event", "Control", "ColorPicker '" .. label .. "' " .. (control.Opened and "opened" or "closed"))
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

-- Button
function Library.Controls.CreateButton(section, label, callback)
    local control = {}
    control.Callback = callback
    control.Type = "Button"
    
    Library:Log("info", "Control", "Creating button: " .. label)
    
    local button = Create("TextButton", {
        Name = label,
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.new(0, 2, 0, 0),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = button
    })
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Library.Config.TertiaryBackground
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Library.Config.SecondaryBackground
    end)
    
    button.MouseButton1Click:Connect(function()
        button.BackgroundColor3 = Library.Config.HighlightColor
        task.delay(0.1, function()
            button.BackgroundColor3 = Library.Config.SecondaryBackground
        end)
        
        Library:Log("event", "Control", "Button '" .. label .. "' clicked")
        
        if control.Callback then
            local success, err = pcall(function()
                control.Callback()
            end)
            if not success then
                Library:Log("error", "Callback", string.format("Button '%s' callback error: %s", label, tostring(err)))
            end
        end
    end)
    
    table.insert(section.Controls, control)
    return control
end

-- TextBox
function Library.Controls.CreateTextBox(section, label, default, callback, options)
    options = options or {}
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or ""
    control.Callback = callback
    control.Type = "TextBox"
    control.Id = controlId
    
    Library:Log("info", "Control", "Creating textbox: " .. label)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, options.HideLabel and 18 or 32),
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
    
    local textBox = Create("TextBox", {
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.new(0, 2, 0, yOffset),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Text = control.Value,
        PlaceholderText = options.Placeholder or "",
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        ClearTextOnFocus = false,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = textBox
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = textBox
    })
    
    textBox.FocusLost:Connect(function()
        control.Value = textBox.Text
        Library:Log("event", "Control", string.format("TextBox '%s' changed to: %s", label, textBox.Text))
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

-- Keybind
function Library.Controls.CreateKeybind(section, label, default, callback)
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or Enum.KeyCode.Unknown
    control.Callback = callback
    control.Listening = false
    control.Type = "Keybind"
    control.Id = controlId
    
    Library:Log("info", "Control", "Creating keybind: " .. label)
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local keyButton = Create("TextButton", {
        Size = UDim2.new(0.35, 0, 1, 0),
        Position = UDim2.new(0.65, 0, 0, 0),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Text = control.Value == Enum.KeyCode.Unknown and "None" or control.Value.Name,
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize - 2,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = keyButton
    })
    
    keyButton.MouseButton1Click:Connect(function()
        control.Listening = true
        keyButton.Text = "..."
        Library:Log("event", "Control", "Keybind '" .. label .. "' listening for input")
    end)
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if control.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                control.Value = input.KeyCode
                keyButton.Text = input.KeyCode.Name
                control.Listening = false
                Library:Log("event", "Control", string.format("Keybind '%s' set to: %s", label, input.KeyCode.Name))
                Library:TrackControlState(controlId, "Keybind", input.KeyCode.Name)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                -- Cancel on mouse click
                control.Listening = false
                keyButton.Text = control.Value == Enum.KeyCode.Unknown and "None" or control.Value.Name
            end
        elseif input.KeyCode == control.Value and control.Callback and not processed then
            Library:Log("event", "Control", "Keybind '" .. label .. "' triggered")
            pcall(control.Callback, control.Value)
        end
    end)
    
    function control:Set(keycode)
        control.Value = keycode
        keyButton.Text = keycode == Enum.KeyCode.Unknown and "None" or keycode.Name
        Library:TrackControlState(controlId, "Keybind", keycode.Name)
    end
    
    function control:Get()
        return control.Value
    end
    
    table.insert(section.Controls, control)
    return control
end

--[[ SECRET DEBUG GUI SYSTEM ]]
function Library:EnableDebugMode()
    if self.Debug.Enabled then
        -- Toggle off
        if self.Debug.GUI then
            self.Debug.GUI:Destroy()
            self.Debug.GUI = nil
        end
        self.Debug.Enabled = false
        self:Log("info", "Debug", "Debug mode disabled")
        return
    end
    
    self.Debug.Enabled = true
    self:Log("info", "Debug", "Debug mode enabled")
    
    -- Create Debug GUI
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
    
    -- Main Debug Frame
    local mainFrame = Create("Frame", {
        Name = "DebugWindow",
        Size = UDim2.new(0, 600, 0, 450),
        Position = UDim2.new(0.5, -300, 0.5, -225),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BorderSizePixel = 0,
        Parent = debugGui
    })
    
    Create("UIStroke", {
        Color = Library.Config.DebugColor,
        Thickness = 2,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = mainFrame
    })
    
    -- Title Bar
    local titleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = titleBar
    })
    
    -- Fix corner overlap
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "🔧 GHACK DEBUG CONSOLE",
        TextColor3 = Library.Config.DebugColor,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Close button
    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -28, 0.5, -12),
        BackgroundColor3 = Library.Config.ErrorColor,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = titleBar
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        self:EnableDebugMode() -- Toggle off
    end)
    
    -- Tab Container
    local tabBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 2),
        Parent = tabBar
    })
    
    -- Content Area
    local contentArea = Create("Frame", {
        Size = UDim2.new(1, -10, 1, -68),
        Position = UDim2.new(0, 5, 0, 63),
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = contentArea
    })
    
    -- Debug Tabs
    local debugTabs = {}
    local activeDebugTab = 1
    
    local function createDebugTab(name, index)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 80, 1, 0),
            BackgroundColor3 = index == 1 and Library.Config.DebugColor or Color3.fromRGB(40, 40, 50),
            BackgroundTransparency = index == 1 and 0 or 0.5,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            Parent = tabBar
        })
        
        local content = Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Library.Config.DebugColor,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = index == 1,
            Parent = contentArea
        })
        
        Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = content
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            Parent = content
        })
        
        btn.MouseButton1Click:Connect(function()
            for i, t in ipairs(debugTabs) do
                t.Button.BackgroundColor3 = i == index and Library.Config.DebugColor or Color3.fromRGB(40, 40, 50)
                t.Button.BackgroundTransparency = i == index and 0 or 0.5
                t.Content.Visible = i == index
            end
            activeDebugTab = index
        end)
        
        return {Button = btn, Content = content}
    end
    
    -- Create tabs
    debugTabs[1] = createDebugTab("📋 All Logs", 1)
    debugTabs[2] = createDebugTab("⚡ Events", 2)
    debugTabs[3] = createDebugTab("📊 Controls", 3)
    debugTabs[4] = createDebugTab("❌ Errors", 4)
    debugTabs[5] = createDebugTab("🖥 System", 5)
    debugTabs[6] = createDebugTab("📤 Export", 6)
    
    -- Helper: Create log entry
    local function createLogEntry(parent, log, showLevel)
        local color = Library.Config.TextColor
        if log.level == "error" then
            color = Library.Config.ErrorColor
        elseif log.level == "warning" then
            color = Library.Config.WarningColor
        elseif log.level == "event" then
            color = Library.Config.DebugColor
        elseif log.level == "info" then
            color = Library.Config.SuccessColor
        end
        
        local entry = Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BorderSizePixel = 0,
            Text = log.formatted,
            TextColor3 = color,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = parent
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            Parent = entry
        })
        
        Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = entry
        })
        
        return entry
    end
    
    -- Populate Controls tab
    local function updateControlsTab()
        for _, child in ipairs(debugTabs[3].Content:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        for id, state in pairs(self.Debug.ControlStates) do
            local entry = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Color3.fromRGB(25, 25, 30),
                BorderSizePixel = 0,
                Parent = debugTabs[3].Content
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 3),
                Parent = entry
            })
            
            Create("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = id,
                TextColor3 = Library.Config.DebugColor,
                Font = Enum.Font.Code,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = entry
            })
            
            Create("TextLabel", {
                Size = UDim2.new(0.2, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "[" .. state.type .. "]",
                TextColor3 = Library.Config.WarningColor,
                Font = Enum.Font.Code,
                TextSize = 10,
                Parent = entry
            })
            
            Create("TextLabel", {
                Size = UDim2.new(0.3, -10, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(state.value),
                TextColor3 = Library.Config.SuccessColor,
                Font = Enum.Font.Code,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = entry
            })
        end
    end
    
    -- System Info tab
    local function updateSystemTab()
        for _, child in ipairs(debugTabs[5].Content:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        local sysInfo = {
            {"Uptime", FormatTime(os.clock() - self.Debug.StartTime)},
            {"Total Logs", tostring(#self.Debug.Logs)},
            {"Event Logs", tostring(#self.Debug.EventLogs)},
            {"Error Count", tostring(#self.Debug.CallbackErrors)},
            {"Controls Tracked", tostring(#(function() local c = 0 for _ in pairs(self.Debug.ControlStates) do c = c + 1 end return c end)())},
            {"FPS", tostring(math.floor(1 / RunService.RenderStepped:Wait()))},
            {"Memory (MB)", string.format("%.2f", Stats:GetTotalMemoryUsageMb())},
        }
        
        for _, info in ipairs(sysInfo) do
            local entry = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Color3.fromRGB(25, 25, 30),
                BorderSizePixel = 0,
                Parent = debugTabs[5].Content
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 3),
                Parent = entry
            })
            
            Create("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = info[1],
                TextColor3 = Library.Config.DimTextColor,
                Font = Enum.Font.Code,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = entry
            })
            
            Create("TextLabel", {
                Size = UDim2.new(0.5, -10, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = info[2],
                TextColor3 = Library.Config.SuccessColor,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = entry
            })
        end
    end
    
    -- Export tab
    local function setupExportTab()
        local exportContent = debugTabs[6].Content
        
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = "📤 Export & Copy Functions",
            TextColor3 = Library.Config.DebugColor,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Parent = exportContent
        })
        
        local buttons = {
            {"Copy All Logs", function()
                local text = ""
                for _, log in ipairs(self.Debug.Logs) do
                    text = text .. log.formatted .. "\n"
                end
                setclipboard(text)
                self:Log("info", "Export", "All logs copied to clipboard (" .. #self.Debug.Logs .. " entries)")
            end},
            {"Copy Event Logs", function()
                local text = ""
                for _, log in ipairs(self.Debug.EventLogs) do
                    text = text .. log.formatted .. "\n"
                end
                setclipboard(text)
                self:Log("info", "Export", "Event logs copied to clipboard")
            end},
            {"Copy Error Logs", function()
                local text = ""
                for _, log in ipairs(self.Debug.CallbackErrors) do
                    text = text .. log.formatted .. "\n"
                end
                setclipboard(text)
                self:Log("info", "Export", "Error logs copied to clipboard")
            end},
            {"Copy Control States (JSON)", function()
                local success, json = pcall(function()
                    return HttpService:JSONEncode(self.Debug.ControlStates)
                end)
                if success then
                    setclipboard(json)
                    self:Log("info", "Export", "Control states exported as JSON")
                end
            end},
            {"Copy System Info", function()
                local info = string.format(
                    "GHack UI Debug Report\n" ..
                    "==================\n" ..
                    "Uptime: %s\n" ..
                    "Total Logs: %d\n" ..
                    "Errors: %d\n" ..
                    "Memory: %.2f MB\n",
                    FormatTime(os.clock() - self.Debug.StartTime),
                    #self.Debug.Logs,
                    #self.Debug.CallbackErrors,
                    Stats:GetTotalMemoryUsageMb()
                )
                setclipboard(info)
                self:Log("info", "Export", "System info copied to clipboard")
            end},
            {"Clear All Logs", function()
                self.Debug.Logs = {}
                self.Debug.EventLogs = {}
                self.Debug.CallbackErrors = {}
                self:Log("info", "Debug", "All logs cleared")
                self:UpdateDebugGUI()
            end},
        }
        
        for _, btn in ipairs(buttons) do
            local button = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(40, 40, 55),
                BorderSizePixel = 0,
                Text = btn[1],
                TextColor3 = Library.Config.TextColor,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Parent = exportContent
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = button
            })
            
            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = Library.Config.DebugColor
            end)
            
            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            end)
            
            button.MouseButton1Click:Connect(btn[2])
        end
    end
    
    setupExportTab()
    
    -- Update function for debug GUI
    function self:UpdateDebugGUI()
        if not self.Debug.Enabled or not self.Debug.GUI then return end
        
        -- Update All Logs tab
        for _, child in ipairs(debugTabs[1].Content:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        for i = math.max(1, #self.Debug.Logs - 100), #self.Debug.Logs do
            local log = self.Debug.Logs[i]
            if log then
                createLogEntry(debugTabs[1].Content, log, true)
            end
        end
        
        -- Update Events tab
        for _, child in ipairs(debugTabs[2].Content:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        for i = math.max(1, #self.Debug.EventLogs - 50), #self.Debug.EventLogs do
            local log = self.Debug.EventLogs[i]
            if log then
                createLogEntry(debugTabs[2].Content, log, false)
            end
        end
        
        -- Update Controls tab
        updateControlsTab()
        
        -- Update Errors tab
        for _, child in ipairs(debugTabs[4].Content:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        for _, log in ipairs(self.Debug.CallbackErrors) do
            createLogEntry(debugTabs[4].Content, log, false)
        end
        
        -- Update System tab
        updateSystemTab()
    end
    
    -- Initial update
    self:UpdateDebugGUI()
    
    -- Auto-refresh system tab
    task.spawn(function()
        while self.Debug.Enabled and self.Debug.GUI do
            task.wait(1)
            if activeDebugTab == 5 then
                updateSystemTab()
            end
        end
    end)
    
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
