--[[
    GHack UI Framework - Roblox Luau Port
    Original: GMod Lua by GHack
    Ported for Roblox by request
    
    Usage:
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ufih/library/refs/heads/main/library.lua"))()
    local Window = Library:CreateWindow("Window Title")
    local Tab = Window:CreateTab("Tab Name")
    local Section = Tab:CreateSection("Section Name")
    Section:CreateToggle("Toggle Name", false, function(value) end)
]]

local Library = {}
Library.__index = Library

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

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

local function RoundBox(parent, size, position, color, cornerRadius)
    local frame = Create("Frame", {
        Size = size,
        Position = position,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = parent
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, cornerRadius or 4),
        Parent = frame
    })
    return frame
end

local function OutlinedBox(parent, size, position, bgColor, borderColor, thickness)
    local outer = Create("Frame", {
        Size = size,
        Position = position,
        BackgroundColor3 = Library.Config.OuterBorderColor,
        BorderSizePixel = 0,
        Parent = parent
    })
    local inner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = borderColor or Library.Config.BorderColor,
        BorderSizePixel = 0,
        Parent = outer
    })
    local content = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = bgColor,
        BorderSizePixel = 0,
        Parent = inner
    })
    return outer, content
end

local function AddGradient(parent, direction, startColor, endColor)
    local gradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, startColor or Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, endColor or Color3.fromRGB(0, 0, 0))
        }),
        Rotation = direction == "down" and 90 or (direction == "right" and 0 or 90),
        Parent = parent
    })
    return gradient
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
    
    -- Create ScreenGui
    self.ScreenGui = Create("ScreenGui", {
        Name = "GHackUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui
    })
    
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
    
    -- Title Text
    self.TitleLabel = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
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
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
        Parent = self.TabContainer
    })
    
    -- Left Panel (SubTabs)
    self.LeftPanel = Create("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, Library.Config.LeftAreaPadding, 1, -Library.Config.TabHeight),
        Position = UDim2.new(0, 0, 0, Library.Config.TabHeight),
        BackgroundColor3 = Library.Config.BackgroundColor,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    -- Content Area
    self.ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -Library.Config.LeftAreaPadding, 1, -Library.Config.TabHeight),
        Position = UDim2.new(0, Library.Config.LeftAreaPadding, 0, Library.Config.TabHeight),
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
    end)
    
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
    local tab = setmetatable({}, {__index = Tab})
    tab.Name = name
    tab.Window = self
    tab.SubTabs = {}
    tab.ActiveSubTab = 1
    tab.Index = #self.Tabs + 1
    
    -- Tab Button
    tab.Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(0, 0, 1, -4),
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
    tab.SubTabContainer = Create("Frame", {
        Name = name .. "_SubTabs",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
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
    
    -- Tab click handler
    tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab.Index)
    end)
    
    table.insert(self.Tabs, tab)
    return tab
end

function Window:SwitchTab(index)
    if self.ActiveTab == index then return end
    
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

--[[ TAB CLASS ]]
local Tab = {}
Tab.__index = Tab

function Tab:CreateSubTab(name)
    local subtab = {}
    subtab.Name = name
    subtab.Tab = self
    subtab.Index = #self.SubTabs + 1
    subtab.Sections = {}
    
    -- SubTab Button
    subtab.Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = subtab.Index == 1 and Library.Config.HighlightColor or Library.Config.DimTextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize - 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SubTabContainer
    })
    
    -- Content ScrollingFrame
    subtab.Content = Create("ScrollingFrame", {
        Name = name .. "_Content",
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
    
    -- Click handler
    subtab.Button.MouseButton1Click:Connect(function()
        self:SwitchSubTab(subtab.Index)
    end)
    
    table.insert(self.SubTabs, subtab)
    return subtab
end

function Tab:SwitchSubTab(index)
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

-- Shortcut: Create section directly on tab (creates default subtab)
function Tab:CreateSection(name)
    if #self.SubTabs == 0 then
        self:CreateSubTab("Main")
    end
    return self.SubTabs[1]:CreateSection(name)
end

--[[ SECTION/PANEL CLASS ]]
local Section = {}
Section.__index = Section

function Tab:CreateSection(name)
    -- If no subtabs, create default
    if #self.SubTabs == 0 then
        self:CreateSubTab("Main")
    end
    return self.SubTabs[self.ActiveSubTab]:CreateSection(name)
end

-- This allows subtab:CreateSection
local SubTab = {}
SubTab.__index = SubTab

function SubTab:CreateSection(name)
    local section = setmetatable({}, Section)
    section.Name = name
    section.SubTab = self
    section.Controls = {}
    section.Index = #self.Sections + 1
    
    -- Panel Frame (matching GHack style)
    section.Frame = Create("Frame", {
        Name = name,
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
    
    -- Panel header with accent color
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
        Text = name,
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
    
    table.insert(self.Sections, section)
    return section
end

-- Apply CreateSection to subtabs created
local mt = getmetatable(Tab) or {}
mt.__index = function(t, k)
    if k == "CreateSection" then
        return function(self, name)
            if #self.SubTabs == 0 then
                self:CreateSubTab("Main")
            end
            return SubTab.CreateSection(self.SubTabs[self.ActiveSubTab], name)
        end
    end
    return rawget(Tab, k)
end

--[[ CONTROL TYPES ]]

-- CheckBox (Toggle)
function Section:CreateToggle(label, default, callback, options)
    options = options or {}
    local control = {}
    control.Value = default or false
    control.Callback = callback
    control.Risk = options.Risk
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
    local labelText = Create("TextLabel", {
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
        if control.Callback then
            control.Callback(control.Value)
        end
    end)
    
    function control:Set(value)
        control.Value = value
        boxFill.BackgroundColor3 = value and Library.Config.HighlightColor or Library.Config.SecondaryBackground
        if control.Callback then
            control.Callback(value)
        end
    end
    
    table.insert(self.Controls, control)
    return control
end

-- Slider
function Section:CreateSlider(label, options, callback)
    options = options or {}
    local control = {}
    control.Min = options.Min or 0
    control.Max = options.Max or 100
    control.Value = options.Default or control.Min
    control.Decimals = options.Decimals or 0
    control.Suffix = options.Suffix or ""
    control.Callback = callback
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, options.HideLabel and 14 or 28),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
        Size = UDim2.new(1, -4, 0, 9),
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
        Parent = trackInner
    })
    
    -- Fill
    local fill = Create("Frame", {
        Size = UDim2.new((control.Value - control.Min) / (control.Max - control.Min), 0, 1, 0),
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
        
        if control.Callback then
            control.Callback(value)
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
        if control.Callback then
            control.Callback(control.Value)
        end
    end
    
    table.insert(self.Controls, control)
    return control
end

-- Dropdown
function Section:CreateDropdown(label, options, callback)
    options = options or {}
    local control = {}
    control.Options = options.Options or {}
    control.Value = options.Default or control.Options[1] or ""
    control.Callback = callback
    control.Opened = false
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, options.HideLabel and 22 or 36),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
    
    -- Dropdown button
    local button = Create("TextButton", {
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.new(0, 2, 0, yOffset),
        BackgroundColor3 = Library.Config.SecondaryBackground,
        BorderSizePixel = 0,
        Text = "",
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
        Parent = button
    })
    
    -- Options frame
    local optionsFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, yOffset + 18),
        BackgroundColor3 = Library.Config.TertiaryBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
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
        Parent = optionsFrame
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        Parent = optionsList
    })
    
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
            ZIndex = 11,
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
            arrow.Text = "▼"
            if control.Callback then
                control.Callback(option)
            end
        end)
    end
    
    -- Toggle dropdown
    button.MouseButton1Click:Connect(function()
        control.Opened = not control.Opened
        optionsFrame.Visible = control.Opened
        optionsFrame.Size = UDim2.new(1, 0, 0, control.Opened and (#control.Options * 18) or 0)
        arrow.Text = control.Opened and "▲" or "▼"
    end)
    
    function control:Set(value)
        control.Value = value
        valueText.Text = tostring(value)
        if control.Callback then
            control.Callback(value)
        end
    end
    
    function control:Refresh(newOptions)
        control.Options = newOptions
        -- Clear existing
        for _, child in ipairs(optionsList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        -- Recreate
        for _, option in ipairs(newOptions) do
            local optBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = Library.Config.TertiaryBackground,
                BorderSizePixel = 0,
                Text = tostring(option),
                TextColor3 = Library.Config.TextColor,
                Font = Library.Config.Font,
                TextSize = Library.Config.FontSize,
                ZIndex = 11,
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
                if control.Callback then
                    control.Callback(option)
                end
            end)
        end
    end
    
    table.insert(self.Controls, control)
    return control
end

-- ColorPicker
function Section:CreateColorPicker(label, default, callback)
    local control = {}
    control.Value = default or Color3.fromRGB(255, 0, 151)
    control.Callback = callback
    control.Opened = false
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
        Parent = container
    })
    
    -- Color preview box
    local colorBox = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 10),
        Position = UDim2.new(1, -26, 0.5, -5),
        BackgroundColor3 = control.Value,
        BorderSizePixel = 0,
        Text = "",
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.BorderColor,
        Thickness = 1,
        Parent = colorBox
    })
    
    -- Color picker popup (simplified)
    local pickerFrame = Create("Frame", {
        Size = UDim2.new(0, 200, 0, 150),
        Position = UDim2.new(1, -200, 0, 16),
        BackgroundColor3 = Library.Config.TertiaryBackground,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
        Parent = container
    })
    
    Create("UIStroke", {
        Color = Library.Config.HighlightColor,
        Thickness = 1,
        Parent = pickerFrame
    })
    
    -- RGB Sliders
    local function createColorSlider(name, y, color, getValue, setValue)
        Create("TextLabel", {
            Size = UDim2.new(0, 20, 0, 14),
            Position = UDim2.new(0, 5, 0, y),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = color,
            Font = Library.Config.Font,
            TextSize = 12,
            ZIndex = 21,
            Parent = pickerFrame
        })
        
        local slider = Create("Frame", {
            Size = UDim2.new(1, -40, 0, 10),
            Position = UDim2.new(0, 30, 0, y + 2),
            BackgroundColor3 = Library.Config.SecondaryBackground,
            BorderSizePixel = 0,
            ZIndex = 21,
            Parent = pickerFrame
        })
        
        local fill = Create("Frame", {
            Size = UDim2.new(getValue() / 255, 0, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 22,
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
                    control.Callback(control.Value)
                end
            end
        end)
        
        return fill
    end
    
    local rFill = createColorSlider("R", 10, Color3.fromRGB(255, 80, 80), 
        function() return control.Value.R * 255 end,
        function(v) control.Value = Color3.fromRGB(v, control.Value.G * 255, control.Value.B * 255) end
    )
    
    local gFill = createColorSlider("G", 30, Color3.fromRGB(80, 255, 80),
        function() return control.Value.G * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, v, control.Value.B * 255) end
    )
    
    local bFill = createColorSlider("B", 50, Color3.fromRGB(80, 80, 255),
        function() return control.Value.B * 255 end,
        function(v) control.Value = Color3.fromRGB(control.Value.R * 255, control.Value.G * 255, v) end
    )
    
    colorBox.MouseButton1Click:Connect(function()
        control.Opened = not control.Opened
        pickerFrame.Visible = control.Opened
    end)
    
    function control:Set(color)
        control.Value = color
        colorBox.BackgroundColor3 = color
        rFill.Size = UDim2.new(color.R, 0, 1, 0)
        gFill.Size = UDim2.new(color.G, 0, 1, 0)
        bFill.Size = UDim2.new(color.B, 0, 1, 0)
        if control.Callback then
            control.Callback(color)
        end
    end
    
    table.insert(self.Controls, control)
    return control
end

-- Button
function Section:CreateButton(label, callback)
    local control = {}
    control.Callback = callback
    
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
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
        if control.Callback then
            control.Callback()
        end
    end)
    
    table.insert(self.Controls, control)
    return control
end

-- TextBox
function Section:CreateTextBox(label, default, callback, options)
    options = options or {}
    local control = {}
    control.Value = default or ""
    control.Callback = callback
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, options.HideLabel and 18 or 32),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
        if control.Callback then
            control.Callback(textBox.Text)
        end
    end)
    
    function control:Set(value)
        control.Value = value
        textBox.Text = value
    end
    
    table.insert(self.Controls, control)
    return control
end

-- Label
function Section:CreateLabel(text)
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Library.Config.DimTextColor,
        Font = Library.Config.Font,
        TextSize = Library.Config.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
    })
    
    return {
        Set = function(_, newText)
            label.Text = newText
        end
    }
end

-- Keybind
function Section:CreateKeybind(label, default, callback)
    local control = {}
    control.Value = default or Enum.KeyCode.Unknown
    control.Callback = callback
    control.Listening = false
    
    local container = Create("Frame", {
        Name = label,
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Controls + 1,
        Parent = self.Content
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
        TextSize = Library.Config.FontSize - 1,
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
    end)
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if control.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                control.Value = input.KeyCode
                keyButton.Text = input.KeyCode.Name
                control.Listening = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                control.Value = Enum.KeyCode.Unknown
                keyButton.Text = "None"
                control.Listening = false
            end
        elseif input.KeyCode == control.Value and control.Callback and not processed then
            control.Callback(control.Value)
        end
    end)
    
    function control:Set(keycode)
        control.Value = keycode
        keyButton.Text = keycode == Enum.KeyCode.Unknown and "None" or keycode.Name
    end
    
    table.insert(self.Controls, control)
    return control
end

return Library
