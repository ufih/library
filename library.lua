--[[
    GHack UI Framework - Roblox Luau Port (FIXED)
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

-- Configuration (EXACT GHack colors)
Library.Config = {
    -- Main accent color (pink/magenta)
    HighlightColor = Color3.fromRGB(255, 0, 151),
    
    -- Background colors
    MainBackground = Color3.fromRGB(30, 30, 30),
    PanelBackground = Color3.fromRGB(38, 38, 38),
    ContentBackground = Color3.fromRGB(22, 22, 22),
    ControlBackground = Color3.fromRGB(41, 41, 41),
    ControlBackgroundAlt = Color3.fromRGB(35, 35, 35),
    HoverBackground = Color3.fromRGB(55, 55, 55),
    
    -- Border colors (exact from GHack)
    OuterBorder = Color3.fromRGB(29, 29, 29),
    InnerBorder = Color3.fromRGB(19, 19, 19),
    PanelBorder = Color3.fromRGB(45, 45, 45),
    
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

-- Debug logging
function Library:Log(level, source, message)
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
    
    if self.Debug.Enabled and self.UpdateDebugGUI then
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
    
    -- Title Bar
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, Library.Config.TabHeight),
        BackgroundColor3 = Library.Config.MainBackground,
        BorderSizePixel = 0,
        Parent = self.ContentFrame
    })
    
    -- Bottom border of title bar
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Config.PanelBorder,
        BorderSizePixel = 0,
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
        Parent = self.TitleBar
    })
    
    -- Tab Container
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
        Parent = self.ContentFrame
    })
    
    -- Left panel right border
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Library.Config.PanelBorder,
        BorderSizePixel = 0,
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
    
    -- Setup dragging
    self:SetupDragging()
    
    -- Toggle keybind
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
        Tween(self.MainFrame, {BackgroundTransparency = 0}, Library.Config.FadeTime or 0.25)
    else
        local tween = Tween(self.MainFrame, {BackgroundTransparency = 1}, Library.Config.FadeTime or 0.25)
        tween.Completed:Connect(function()
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
    
    -- Tab Button
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
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
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
        Padding = UDim.new(0, 2),
        Parent = tab.SubTabContainer
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
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
            TextColor3 = subtab.Index == 1 and Library.Config.HighlightColor or Library.Config.DimTextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.SubTabContainer
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
            
            -- Calculate panel width (roughly half the content area minus padding)
            local panelWidth = Library.Config.PanelWidth
            
            -- Main Panel Frame with proper borders
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
            
            -- Pink accent line at top
            Create("Frame", {
                Name = "AccentLine",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Library.Config.HighlightColor,
                BorderSizePixel = 0,
                Parent = panelBg
            })
            
            -- Title
            Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -8, 0, 16),
                Position = UDim2.new(0, 8, 0, 3),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = panelBg
            })
            
            -- Controls container
            section.Content = Create("Frame", {
                Name = "Controls",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 20),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = panelBg
            })
            
            Create("UIListLayout", {
                Padding = UDim.new(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = section.Content
            })
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
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
    
    local current = self.Tabs[self.ActiveTab]
    if current then
        current.Button.TextColor3 = Library.Config.TextColor
        current.SubTabContainer.Visible = false
        current.ContentFrame.Visible = false
    end
    
    self.ActiveTab = index
    
    local new = self.Tabs[index]
    if new then
        new.Button.TextColor3 = Library.Config.HighlightColor
        new.SubTabContainer.Visible = true
        new.ContentFrame.Visible = true
    end
end

--[[ CONTROL FACTORY ]]
Library.Controls = {}

-- CheckBox (GHack style)
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
        Size = UDim2.new(1, 0, 0, 13),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    -- Checkbox outer (29, 29, 29)
    local boxOuter = Create("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 0, 0.5, -5),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = container
    })
    
    -- Inner (19, 19, 19)
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
    
    -- Label
    Create("TextLabel", {
        Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.new(0, 13, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = control.Risk and Library.Config.RiskTextColor or Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
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

-- Slider (GHack style)
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
    
    local showLabel = options.DrawLabel ~= false and label ~= ""
    local totalHeight = showLabel and 24 or 11
    
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
            Size = UDim2.new(1, 0, 0, 13),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Library.Config.TextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
        yOffset = 13
    end
    
    -- Track outer
    local trackOuter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, yOffset),
        BackgroundColor3 = Library.Config.OuterBorder,
        BorderSizePixel = 0,
        Parent = container
    })
    
    local trackInner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.InnerBorder,
        BorderSizePixel = 0,
        Parent = trackOuter
    })
    
    local trackBg = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.Config.ControlBackgroundAlt,
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
        Size = UDim2.new(1, -4, 1, 0),
        Position = UDim2.new(0, 2, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(control.Value) .. control.Suffix,
        TextColor3 = Library.Config.DimTextColor,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = trackBg
    })
    
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
        
        if control.Callback then pcall(control.Callback, value) end
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
        if control.Callback then pcall(control.Callback, control.Value) end
    end
    
    function control:Get() return control.Value end
    
    table.insert(section.Controls, control)
    return control
end

-- Dropdown (GHack style)
function Library.Controls.CreateDropdown(section, label, options, callback)
    options = options or {}
    local controlId = section.Name .. "_" .. (label ~= "" and label or "Dropdown")
    
    local control = {}
    control.Options = options.Options or {}
    control.Value = options.Default or control.Options[1] or ""
    control.Callback = callback
    control.Opened = false
    control.Type = "Dropdown"
    
    Library:TrackControlState(controlId, "Dropdown", control.Value)
    
    local showLabel = options.DrawLabel ~= false and label ~= ""
    local totalHeight = showLabel and 30 or 16
    
    local container = Create("Frame", {
        Name = label ~= "" and label or "Dropdown",
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 5,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local yOffset = 0
    if showLabel then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 13),
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
    
    -- Button outer
    local btnOuter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
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
        BackgroundColor3 = Library.Config.ControlBackgroundAlt,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = btnInner
    })
    
    local valueText = Create("TextLabel", {
        Size = UDim2.new(1, -18, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(control.Value),
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = btnBg
    })
    
    local arrow = Create("TextLabel", {
        Size = UDim2.new(0, 14, 1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = 8,
        ZIndex = 6,
        Parent = btnBg
    })
    
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
        Position = UDim2.new(0, 0, 0, yOffset + 16),
        BackgroundColor3 = Library.Config.ControlBackgroundAlt,
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
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundColor3 = Library.Config.ControlBackgroundAlt,
                BorderSizePixel = 0,
                Text = tostring(option),
                TextColor3 = control.Value == option and Library.Config.HighlightColor or Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                ZIndex = 101,
                Parent = optionsList
            })
            
            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundColor3 = Library.Config.HoverBackground
            end)
            
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundColor3 = Library.Config.ControlBackgroundAlt
            end)
            
            optBtn.MouseButton1Click:Connect(function()
                control.Value = option
                valueText.Text = tostring(option)
                control.Opened = false
                optionsFrame.Visible = false
                optionsFrame.Size = UDim2.new(1, 0, 0, 0)
                arrow.Text = "▼"
                
                Library:TrackControlState(controlId, "Dropdown", option)
                
                if control.Callback then pcall(control.Callback, option) end
                
                for _, btn in ipairs(optionsList:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.TextColor3 = btn.Text == tostring(option) and Library.Config.HighlightColor or Library.Config.TextColor
                    end
                end
            end)
        end
    end
    
    createOptions()
    
    button.MouseEnter:Connect(function()
        btnBg.BackgroundColor3 = Library.Config.HoverBackground
    end)
    
    button.MouseLeave:Connect(function()
        if not control.Opened then
            btnBg.BackgroundColor3 = Library.Config.ControlBackgroundAlt
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        control.Opened = not control.Opened
        optionsFrame.Visible = control.Opened
        local targetHeight = control.Opened and math.min(#control.Options * 16, 112) or 0
        optionsFrame.Size = UDim2.new(1, 0, 0, targetHeight)
        arrow.Text = control.Opened and "▲" or "▼"
        btnBg.BackgroundColor3 = control.Opened and Library.Config.HoverBackground or Library.Config.ControlBackgroundAlt
    end)
    
    function control:Set(value)
        control.Value = value
        valueText.Text = tostring(value)
        Library:TrackControlState(controlId, "Dropdown", value)
        if control.Callback then pcall(control.Callback, value) end
    end
    
    function control:Refresh(newOptions)
        control.Options = newOptions
        createOptions()
    end
    
    function control:Get() return control.Value end
    
    table.insert(section.Controls, control)
    return control
end

-- ColorPicker (GHack style - inline with label)
function Library.Controls.CreateColorPicker(section, label, default, callback)
    local controlId = section.Name .. "_" .. label
    
    local control = {}
    control.Value = default or Library.Config.HighlightColor
    control.Callback = callback
    control.Opened = false
    control.Type = "ColorPicker"
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 13),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 3,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    -- Label
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
    
    -- Color box outer
    local colorBoxOuter = Create("Frame", {
        Size = UDim2.new(0, 20, 0, 10),
        Position = UDim2.new(1, -20, 0.5, -5),
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
        ZIndex = 4,
        Parent = colorBoxInner
    })
    
    -- Picker popup
    local pickerFrame = Create("Frame", {
        Size = UDim2.new(0, 150, 0, 85),
        Position = UDim2.new(1, -150, 0, 15),
        BackgroundColor3 = Library.Config.PanelBackground,
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
    
    local function createSlider(name, y, color, getValue, setValue)
        Create("TextLabel", {
            Size = UDim2.new(0, 12, 0, 10),
            Position = UDim2.new(0, 4, 0, y),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = color,
            Font = Library.Config.Font,
            TextSize = 9,
            ZIndex = 51,
            Parent = pickerFrame
        })
        
        local sliderBg = Create("Frame", {
            Size = UDim2.new(1, -25, 0, 8),
            Position = UDim2.new(0, 18, 0, y + 1),
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
                if control.Callback then pcall(control.Callback, control.Value) end
            end
        end)
        
        return fill
    end
    
    rFill = createSlider("R", 6, Color3.fromRGB(255, 100, 100),
        function() return control.Value.R * 255 end,
        function(v) control.Value = Color3.fromRGB(v, control.Value.G * 255, control.Value.B * 255) end
    )
    
    gFill = createSlider("G", 22, Color3.fromRGB(100, 255, 100),
        function() return control.Value.G * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, v, control.Value.B * 255) end
    )
    
    bFill = createSlider("B", 38, Color3.fromRGB(100, 100, 255),
        function() return control.Value.B * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, control.Value.G * 255, v) end
    )
    
    -- Hex input
    local hexBox = Create("TextBox", {
        Size = UDim2.new(1, -8, 0, 14),
        Position = UDim2.new(0, 4, 0, 56),
        BackgroundColor3 = Library.Config.ControlBackground,
        BorderSizePixel = 0,
        Text = string.format("#%02X%02X%02X", control.Value.R * 255, control.Value.G * 255, control.Value.B * 255),
        TextColor3 = Library.Config.TextColor,
        Font = Library.Config.Font,
        TextSize = 10,
        ZIndex = 51,
        Parent = pickerFrame
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        Parent = hexBox
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
            if control.Callback then pcall(control.Callback, control.Value) end
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
        if control.Callback then pcall(control.Callback, color) end
    end
    
    function control:Get() return control.Value end
    
    table.insert(section.Controls, control)
    return control
end

-- Button (GHack style)
function Library.Controls.CreateButton(section, label, callback)
    local control = {}
    control.Callback = callback
    control.Type = "Button"
    
    local btnOuter = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 16),
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
        BackgroundColor3 = Library.Config.ControlBackgroundAlt,
        BorderSizePixel = 0,
        Parent = btnInner
    })
    
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
        btnBg.BackgroundColor3 = Library.Config.ControlBackgroundAlt
    end)
    
    button.MouseButton1Click:Connect(function()
        btnBg.BackgroundColor3 = Library.Config.HighlightColor
        task.delay(0.12, function()
            btnBg.BackgroundColor3 = Library.Config.ControlBackgroundAlt
        end)
        
        if control.Callback then pcall(control.Callback) end
    end)
    
    table.insert(section.Controls, control)
    return control
end

-- Label
function Library.Controls.CreateLabel(section, text)
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 13),
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
        Set = function(_, newText) label.Text = newText end,
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
    
    local showLabel = not options.HideLabel
    local totalHeight = showLabel and 28 or 16
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundTransparency = 1,
        LayoutOrder = #section.Controls + 1,
        Parent = section.Content
    })
    
    local yOffset = 0
    if showLabel then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 13),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Library.Config.TextColor,
            Font = Library.Config.Font,
            TextSize = Library.Config.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
        yOffset = 13
    end
    
    local boxOuter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 15),
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
        BackgroundColor3 = Library.Config.ControlBackgroundAlt,
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
        PaddingLeft = UDim.new(0, 5),
        Parent = textBox
    })
    
    textBox.FocusLost:Connect(function()
        control.Value = textBox.Text
        Library:TrackControlState(controlId, "TextBox", textBox.Text)
        if control.Callback then pcall(control.Callback, textBox.Text) end
    end)
    
    function control:Set(value)
        control.Value = value
        textBox.Text = value
        Library:TrackControlState(controlId, "TextBox", value)
    end
    
    function control:Get() return control.Value end
    
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
        Size = UDim2.new(0, 450, 0, 300),
        Position = UDim2.new(0.5, -225, 0.5, -150),
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
    
    local titleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = titleBar
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, -35, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "🔧 DEBUG CONSOLE",
        TextColor3 = Color3.fromRGB(80, 200, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -24, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = titleBar
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        self:EnableDebugMode()
    end)
    
    local logsFrame = Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -70),
        Position = UDim2.new(0, 6, 0, 32),
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
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
        PaddingTop = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3),
        Parent = logsFrame
    })
    
    local buttonsFrame = Create("Frame", {
        Size = UDim2.new(1, -12, 0, 28),
        Position = UDim2.new(0, 6, 1, -34),
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
            Size = UDim2.new(0, 85, 1, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.Gotham,
            TextSize = 10,
            Parent = buttonsFrame
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
        btn.MouseButton1Click:Connect(callback)
    end
    
    createDebugButton("Copy Logs", function()
        local text = ""
        for _, log in ipairs(self.Debug.Logs) do
            text = text .. log.formatted .. "\n"
        end
        if setclipboard then setclipboard(text) end
    end)
    
    createDebugButton("Clear Logs", function()
        self.Debug.Logs = {}
        self.Debug.EventLogs = {}
        self.Debug.CallbackErrors = {}
        for _, child in ipairs(logsFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
    end)
    
    createDebugButton("Copy States", function()
        if setclipboard and HttpService then
            local success, json = pcall(function()
                return HttpService:JSONEncode(self.Debug.ControlStates)
            end)
            if success then setclipboard(json) end
        end
    end)
    
    function self:UpdateDebugGUI()
        for _, child in ipairs(logsFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        
        for i = math.max(1, #self.Debug.Logs - 80), #self.Debug.Logs do
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
                    BackgroundTransparency = 1,
                    Text = log.formatted,
                    TextColor3 = color,
                    Font = Enum.Font.Code,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = logsFrame
                })
            end
        end
    end
    
    self:UpdateDebugGUI()
    
    -- Dragging
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
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

return Library
