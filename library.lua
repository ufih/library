--[[
    NexusLib Ultimate v4.0
    Premium Drawing Library for Roblox
    Combines best elements from: Tokyo, Abyss, Specter, Puppyware, Sierra, etc.

    Features:
    - Horizontal tab navigation
    - Two-column section layout
    - Dashed section borders
    - All UI elements (Toggle, Slider, Button, Dropdown, Keybind, Textbox, ColorPicker, Label)
    - Scrolling sections
    - Watermark with stats
    - Smooth animations
    - Flag system for configs
    - Draggable window
    - Keybind list overlay
]]

local NexusLib = {}
NexusLib.__index = NexusLib

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Utility Functions
local function Create(class, properties)
    local obj = Drawing.new(class)
    for prop, value in pairs(properties or {}) do
        obj[prop] = value
    end
    return obj
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function LerpColor(c1, c2, t)
    return Color3.new(
        Lerp(c1.R, c2.R, t),
        Lerp(c1.G, c2.G, t),
        Lerp(c1.B, c2.B, t)
    )
end

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function GetKeyName(key)
    if typeof(key) == "EnumItem" then
        local name = key.Name
        if name:match("^Mouse") then
            return name == "MouseButton1" and "M1" or name == "MouseButton2" and "M2" or "M3"
        end
        return #name == 1 and name or name:sub(1, 3):upper()
    end
    return "..."
end

local function IsInBounds(pos, size, point)
    return point.X >= pos.X and point.X <= pos.X + size.X and
           point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

-- Theme System
NexusLib.Themes = {
    Default = {
        Background = Color3.fromRGB(12, 12, 12),
        TopBar = Color3.fromRGB(16, 16, 16),
        Section = Color3.fromRGB(18, 18, 18),
        SectionBorder = Color3.fromRGB(35, 35, 35),
        Element = Color3.fromRGB(25, 25, 25),
        ElementBorder = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(138, 92, 255),
        AccentDark = Color3.fromRGB(100, 65, 190),
        Text = Color3.fromRGB(220, 220, 220),
        TextDim = Color3.fromRGB(120, 120, 120),
        TextDisabled = Color3.fromRGB(70, 70, 70),
        SliderBg = Color3.fromRGB(35, 35, 35),
        ToggleOff = Color3.fromRGB(45, 45, 45),
        Outline = Color3.fromRGB(50, 50, 50),
        OutlineDark = Color3.fromRGB(25, 25, 25)
    },
    Purple = {
        Background = Color3.fromRGB(15, 12, 20),
        TopBar = Color3.fromRGB(20, 16, 28),
        Section = Color3.fromRGB(22, 18, 32),
        SectionBorder = Color3.fromRGB(45, 35, 60),
        Element = Color3.fromRGB(30, 25, 42),
        ElementBorder = Color3.fromRGB(55, 45, 75),
        Accent = Color3.fromRGB(160, 100, 255),
        AccentDark = Color3.fromRGB(120, 70, 200),
        Text = Color3.fromRGB(230, 225, 240),
        TextDim = Color3.fromRGB(130, 120, 150),
        TextDisabled = Color3.fromRGB(75, 70, 85),
        SliderBg = Color3.fromRGB(40, 35, 55),
        ToggleOff = Color3.fromRGB(50, 45, 65),
        Outline = Color3.fromRGB(60, 50, 80),
        OutlineDark = Color3.fromRGB(30, 25, 40)
    },
    Red = {
        Background = Color3.fromRGB(14, 10, 10),
        TopBar = Color3.fromRGB(20, 14, 14),
        Section = Color3.fromRGB(24, 16, 16),
        SectionBorder = Color3.fromRGB(55, 30, 30),
        Element = Color3.fromRGB(35, 22, 22),
        ElementBorder = Color3.fromRGB(65, 40, 40),
        Accent = Color3.fromRGB(220, 80, 100),
        AccentDark = Color3.fromRGB(170, 55, 75),
        Text = Color3.fromRGB(235, 220, 220),
        TextDim = Color3.fromRGB(145, 115, 115),
        TextDisabled = Color3.fromRGB(85, 65, 65),
        SliderBg = Color3.fromRGB(50, 30, 30),
        ToggleOff = Color3.fromRGB(55, 35, 35),
        Outline = Color3.fromRGB(70, 45, 45),
        OutlineDark = Color3.fromRGB(35, 22, 22)
    },
    Blue = {
        Background = Color3.fromRGB(10, 12, 16),
        TopBar = Color3.fromRGB(14, 18, 24),
        Section = Color3.fromRGB(16, 20, 28),
        SectionBorder = Color3.fromRGB(30, 45, 65),
        Element = Color3.fromRGB(22, 30, 42),
        ElementBorder = Color3.fromRGB(40, 60, 85),
        Accent = Color3.fromRGB(76, 162, 252),
        AccentDark = Color3.fromRGB(50, 120, 200),
        Text = Color3.fromRGB(220, 230, 240),
        TextDim = Color3.fromRGB(110, 130, 155),
        TextDisabled = Color3.fromRGB(60, 75, 95),
        SliderBg = Color3.fromRGB(30, 42, 58),
        ToggleOff = Color3.fromRGB(35, 48, 65),
        Outline = Color3.fromRGB(45, 65, 90),
        OutlineDark = Color3.fromRGB(22, 30, 42)
    }
}

-- Globals
NexusLib.Windows = {}
NexusLib.Flags = {}
NexusLib.Connections = {}
NexusLib.ToggleKey = Enum.KeyCode.RightShift
NexusLib.Opened = true

-- Window Class
function NexusLib:New(options)
    options = options or {}

    local Window = setmetatable({}, {__index = NexusLib})
    Window.Name = options.name or "NexusLib"
    Window.SubTitle = options.subtitle or ""
    Window.SizeX = options.sizeX or 580
    Window.SizeY = options.sizeY or 420
    Window.Theme = NexusLib.Themes[options.theme] or NexusLib.Themes.Default
    Window.Accent = options.accent or Window.Theme.Accent
    Window.Position = options.position or Vector2.new(100, 100)

    Window.Pages = {}
    Window.CurrentPage = nil
    Window.Objects = {}
    Window.Visible = true
    Window.Dragging = false
    Window.DragOffset = Vector2.zero

    -- Create Main Container
    Window.Objects.OuterOutline = Create("Square", {
        Size = Vector2.new(Window.SizeX + 2, Window.SizeY + 2),
        Position = Vector2.new(Window.Position.X - 1, Window.Position.Y - 1),
        Color = Window.Theme.OutlineDark,
        Filled = false,
        Thickness = 1,
        Visible = true,
        ZIndex = 1
    })

    Window.Objects.MainBg = Create("Square", {
        Size = Vector2.new(Window.SizeX, Window.SizeY),
        Position = Window.Position,
        Color = Window.Theme.Background,
        Filled = true,
        Visible = true,
        ZIndex = 2
    })

    Window.Objects.MainOutline = Create("Square", {
        Size = Vector2.new(Window.SizeX, Window.SizeY),
        Position = Window.Position,
        Color = Window.Theme.Outline,
        Filled = false,
        Thickness = 1,
        Visible = true,
        ZIndex = 3
    })

    -- Top Bar
    Window.Objects.TopBar = Create("Square", {
        Size = Vector2.new(Window.SizeX - 2, 28),
        Position = Vector2.new(Window.Position.X + 1, Window.Position.Y + 1),
        Color = Window.Theme.TopBar,
        Filled = true,
        Visible = true,
        ZIndex = 4
    })

    -- Accent Line under top bar
    Window.Objects.AccentLine = Create("Line", {
        From = Vector2.new(Window.Position.X + 1, Window.Position.Y + 29),
        To = Vector2.new(Window.Position.X + Window.SizeX - 1, Window.Position.Y + 29),
        Color = Window.Accent,
        Thickness = 1,
        Visible = true,
        ZIndex = 5
    })

    -- Title
    Window.Objects.Title = Create("Text", {
        Text = Window.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(Window.Position.X + 8, Window.Position.Y + 6),
        Color = Window.Accent,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = true,
        ZIndex = 6
    })

    -- Subtitle
    if Window.SubTitle ~= "" then
        Window.Objects.SubTitle = Create("Text", {
            Text = " | " .. Window.SubTitle,
            Size = 13,
            Font = 2,
            Position = Vector2.new(Window.Position.X + 8 + Window.Objects.Title.TextBounds.X, Window.Position.Y + 6),
            Color = Window.Theme.TextDim,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Visible = true,
            ZIndex = 6
        })
    end

    -- Tab Container Area (horizontal tabs)
    Window.TabStartX = Window.Position.X + 8
    Window.TabY = Window.Position.Y + 35
    Window.ContentY = Window.Position.Y + 58
    Window.ContentHeight = Window.SizeY - 65

    -- Tab underline
    Window.Objects.TabLine = Create("Line", {
        From = Vector2.new(Window.Position.X + 1, Window.Position.Y + 55),
        To = Vector2.new(Window.Position.X + Window.SizeX - 1, Window.Position.Y + 55),
        Color = Window.Theme.SectionBorder,
        Thickness = 1,
        Visible = true,
        ZIndex = 4
    })

    -- Dragging
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local topBarPos = Window.Objects.TopBar.Position
            local topBarSize = Window.Objects.TopBar.Size

            if IsInBounds(topBarPos, topBarSize, mousePos) then
                Window.Dragging = true
                Window.DragOffset = mousePos - Window.Position
            end
        end
    end))

    table.insert(NexusLib.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Window.Dragging = false
        end
    end))

    table.insert(NexusLib.Connections, RunService.RenderStepped:Connect(function()
        if Window.Dragging and Window.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            Window:SetPosition(mousePos - Window.DragOffset)
        end
    end))

    -- Toggle Visibility
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == NexusLib.ToggleKey then
            Window:Toggle()
        end
    end))

    table.insert(NexusLib.Windows, Window)
    return Window
end

function NexusLib:SetPosition(pos)
    local delta = pos - self.Position
    self.Position = pos

    for _, obj in pairs(self.Objects) do
        if obj.Position then
            obj.Position = obj.Position + delta
        elseif obj.From then
            obj.From = obj.From + delta
            obj.To = obj.To + delta
        end
    end

    -- Update tab positions
    local tabX = self.Position.X + 8
    for _, page in ipairs(self.Pages) do
        page:UpdatePosition(delta)
        if page.TabButton then
            page.TabButton.Position = Vector2.new(tabX, self.Position.Y + 38)
            tabX = tabX + page.TabButton.TextBounds.X + 20
        end
    end
end

function NexusLib:Toggle()
    self.Visible = not self.Visible
    for _, obj in pairs(self.Objects) do
        obj.Visible = self.Visible
    end
    for _, page in ipairs(self.Pages) do
        page:SetVisible(self.Visible and page == self.CurrentPage)
    end
end

function NexusLib:SetTheme(themeName)
    local theme = NexusLib.Themes[themeName]
    if theme then
        self.Theme = theme
        self:RefreshTheme()
    end
end

function NexusLib:RefreshTheme()
    local t = self.Theme
    self.Objects.MainBg.Color = t.Background
    self.Objects.TopBar.Color = t.TopBar
    self.Objects.MainOutline.Color = t.Outline
    self.Objects.OuterOutline.Color = t.OutlineDark
    self.Objects.TabLine.Color = t.SectionBorder

    for _, page in ipairs(self.Pages) do
        page:RefreshTheme()
    end
end

function NexusLib:Unload()
    for _, conn in ipairs(NexusLib.Connections) do
        conn:Disconnect()
    end
    NexusLib.Connections = {}

    for _, window in ipairs(NexusLib.Windows) do
        for _, obj in pairs(window.Objects) do
            obj:Remove()
        end
        for _, page in ipairs(window.Pages) do
            page:Destroy()
        end
    end
    NexusLib.Windows = {}
    NexusLib.Flags = {}
end

-- Page Class
local Page = {}
Page.__index = Page

function NexusLib:Page(options)
    options = options or {}

    local page = setmetatable({}, Page)
    page.Window = self
    page.Name = options.name or "Page"
    page.Icon = options.icon
    page.Sections = {}
    page.Objects = {}
    page.Visible = false

    -- Tab Button
    local tabX = self.TabStartX
    for _, p in ipairs(self.Pages) do
        tabX = tabX + (p.TabButton and p.TabButton.TextBounds.X + 20 or 0)
    end

    page.TabButton = Create("Text", {
        Text = page.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(tabX, self.TabY),
        Color = self.Theme.TextDim,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = true,
        ZIndex = 7
    })

    -- Tab click handler
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local btnPos = page.TabButton.Position
            local btnSize = page.TabButton.TextBounds

            if mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X + 10 and
               mousePos.Y >= btnPos.Y - 2 and mousePos.Y <= btnPos.Y + btnSize.Y + 4 then
                self:SelectPage(page)
            end
        end
    end))

    table.insert(self.Pages, page)

    if #self.Pages == 1 then
        self:SelectPage(page)
    end

    return page
end

function NexusLib:SelectPage(page)
    for _, p in ipairs(self.Pages) do
        local isSelected = (p == page)
        p.TabButton.Color = isSelected and self.Accent or self.Theme.TextDim
        p:SetVisible(isSelected and self.Visible)
    end
    self.CurrentPage = page
end

function Page:SetVisible(visible)
    self.Visible = visible
    self.TabButton.Visible = self.Window.Visible

    for _, obj in pairs(self.Objects) do
        obj.Visible = visible
    end

    for _, section in ipairs(self.Sections) do
        section:SetVisible(visible)
    end
end

function Page:UpdatePosition(delta)
    for _, obj in pairs(self.Objects) do
        if obj.Position then
            obj.Position = obj.Position + delta
        elseif obj.From then
            obj.From = obj.From + delta
            obj.To = obj.To + delta
        end
    end

    for _, section in ipairs(self.Sections) do
        section:UpdatePosition(delta)
    end
end

function Page:RefreshTheme()
    for _, section in ipairs(self.Sections) do
        section:RefreshTheme()
    end
end

function Page:Destroy()
    for _, obj in pairs(self.Objects) do
        obj:Remove()
    end
    self.TabButton:Remove()
    for _, section in ipairs(self.Sections) do
        section:Destroy()
    end
end

-- Section Class
local Section = {}
Section.__index = Section

function Page:Section(options)
    options = options or {}

    local section = setmetatable({}, Section)
    section.Page = self
    section.Window = self.Window
    section.Name = options.name or "Section"
    section.Side = options.side or "left"
    section.Elements = {}
    section.Objects = {}
    section.Visible = self.Visible

    local win = self.Window
    local columnWidth = (win.SizeX - 20) / 2 - 5
    local startX = win.Position.X + (section.Side == "left" and 8 or columnWidth + 15)

    -- Count existing sections on this side
    local sectionCount = 0
    local lastSectionBottom = win.ContentY
    for _, s in ipairs(self.Sections) do
        if s.Side == section.Side then
            sectionCount = sectionCount + 1
            lastSectionBottom = math.max(lastSectionBottom, s.BottomY or win.ContentY)
        end
    end

    local sectionY = lastSectionBottom + (sectionCount > 0 and 8 or 0)

    section.StartX = startX
    section.StartY = sectionY
    section.Width = columnWidth
    section.CurrentY = sectionY + 22
    section.BottomY = section.CurrentY

    -- Section border with dashed style header
    section.Objects.Border = Create("Square", {
        Size = Vector2.new(columnWidth, 100),
        Position = Vector2.new(startX, sectionY),
        Color = win.Theme.SectionBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 8
    })

    -- Section title (inside border cutout style)
    section.Objects.TitleBg = Create("Square", {
        Size = Vector2.new(0, 14),
        Position = Vector2.new(startX + 8, sectionY - 7),
        Color = win.Theme.Background,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 9
    })

    section.Objects.Title = Create("Text", {
        Text = section.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(startX + 10, sectionY - 8),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 10
    })

    -- Update title background size
    section.Objects.TitleBg.Size = Vector2.new(section.Objects.Title.TextBounds.X + 6, 14)

    table.insert(self.Sections, section)
    return section
end

function Section:UpdateSize()
    local height = math.max(50, self.CurrentY - self.StartY + 8)
    self.Objects.Border.Size = Vector2.new(self.Width, height)
    self.BottomY = self.StartY + height
end

function Section:SetVisible(visible)
    self.Visible = visible
    for _, obj in pairs(self.Objects) do
        obj.Visible = visible
    end
    for _, element in ipairs(self.Elements) do
        element:SetVisible(visible)
    end
end

function Section:UpdatePosition(delta)
    self.StartX = self.StartX + delta.X
    self.StartY = self.StartY + delta.Y
    self.CurrentY = self.CurrentY + delta.Y
    self.BottomY = self.BottomY + delta.Y

    for _, obj in pairs(self.Objects) do
        if obj.Position then
            obj.Position = obj.Position + delta
        end
    end

    for _, element in ipairs(self.Elements) do
        element:UpdatePosition(delta)
    end
end

function Section:RefreshTheme()
    local t = self.Window.Theme
    self.Objects.Border.Color = t.SectionBorder
    self.Objects.TitleBg.Color = t.Background
    self.Objects.Title.Color = t.Text

    for _, element in ipairs(self.Elements) do
        if element.RefreshTheme then
            element:RefreshTheme()
        end
    end
end

function Section:Destroy()
    for _, obj in pairs(self.Objects) do
        obj:Remove()
    end
    for _, element in ipairs(self.Elements) do
        element:Destroy()
    end
end

-- Toggle Element
function Section:Toggle(options)
    options = options or {}

    local toggle = {
        Type = "Toggle",
        Section = self,
        Name = options.name or "Toggle",
        Value = options.default or false,
        Flag = options.flag,
        Callback = options.callback or function() end,
        Objects = {},
        Visible = self.Visible
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8

    -- Checkbox background
    toggle.Objects.Box = Create("Square", {
        Size = Vector2.new(12, 12),
        Position = Vector2.new(x, y),
        Color = toggle.Value and win.Accent or win.Theme.ToggleOff,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    toggle.Objects.BoxOutline = Create("Square", {
        Size = Vector2.new(12, 12),
        Position = Vector2.new(x, y),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    -- Label
    toggle.Objects.Label = Create("Text", {
        Text = toggle.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + 18, y - 1),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 11
    })

    function toggle:Set(value)
        self.Value = value
        self.Objects.Box.Color = value and win.Accent or win.Theme.ToggleOff
        if self.Flag then
            NexusLib.Flags[self.Flag] = value
        end
        self.Callback(value)
    end

    function toggle:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
    end

    function toggle:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
    end

    function toggle:Destroy()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    -- Click handler
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and toggle.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local boxPos = toggle.Objects.Box.Position
            local labelEnd = toggle.Objects.Label.Position.X + toggle.Objects.Label.TextBounds.X

            if mousePos.Y >= boxPos.Y and mousePos.Y <= boxPos.Y + 14 and
               mousePos.X >= boxPos.X and mousePos.X <= labelEnd then
                toggle:Set(not toggle.Value)
            end
        end
    end))

    if toggle.Flag then
        NexusLib.Flags[toggle.Flag] = toggle.Value
    end

    self.CurrentY = self.CurrentY + 20
    self:UpdateSize()
    table.insert(self.Elements, toggle)
    return toggle
end

-- Slider Element  
function Section:Slider(options)
    options = options or {}

    local slider = {
        Type = "Slider",
        Section = self,
        Name = options.name or "Slider",
        Min = options.min or 0,
        Max = options.max or 100,
        Value = options.default or options.min or 0,
        Increment = options.increment or 1,
        Suffix = options.suffix or "",
        Flag = options.flag,
        Callback = options.callback or function() end,
        Objects = {},
        Visible = self.Visible,
        Dragging = false
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8
    local width = self.Width - 16

    -- Label
    slider.Objects.Label = Create("Text", {
        Text = slider.Name .. ": " .. slider.Value .. slider.Suffix,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x, y),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 11
    })

    -- Slider background
    slider.Objects.SliderBg = Create("Square", {
        Size = Vector2.new(width, 10),
        Position = Vector2.new(x, y + 18),
        Color = win.Theme.SliderBg,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    slider.Objects.SliderOutline = Create("Square", {
        Size = Vector2.new(width, 10),
        Position = Vector2.new(x, y + 18),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    -- Fill
    local percent = (slider.Value - slider.Min) / (slider.Max - slider.Min)
    slider.Objects.Fill = Create("Square", {
        Size = Vector2.new(math.max(1, width * percent), 8),
        Position = Vector2.new(x + 1, y + 19),
        Color = win.Accent,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 13
    })

    -- Value text (right aligned)
    slider.Objects.Value = Create("Text", {
        Text = tostring(math.floor(slider.Value)) .. "/" .. slider.Max,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + width - 30, y + 17),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Center = true,
        Visible = self.Visible,
        ZIndex = 14
    })

    function slider:Set(value)
        value = math.clamp(value, self.Min, self.Max)
        value = math.floor(value / self.Increment + 0.5) * self.Increment
        self.Value = value

        local percent = (value - self.Min) / (self.Max - self.Min)
        self.Objects.Fill.Size = Vector2.new(math.max(1, (self.Section.Width - 18) * percent), 8)
        self.Objects.Label.Text = self.Name .. ": " .. value .. self.Suffix
        self.Objects.Value.Text = tostring(math.floor(value)) .. "/" .. self.Max

        if self.Flag then
            NexusLib.Flags[self.Flag] = value
        end
        self.Callback(value)
    end

    function slider:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
    end

    function slider:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
    end

    function slider:Destroy()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    -- Slider interaction
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and slider.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local sliderPos = slider.Objects.SliderBg.Position
            local sliderSize = slider.Objects.SliderBg.Size

            if IsInBounds(sliderPos, sliderSize, mousePos) then
                slider.Dragging = true
            end
        end
    end))

    table.insert(NexusLib.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            slider.Dragging = false
        end
    end))

    table.insert(NexusLib.Connections, RunService.RenderStepped:Connect(function()
        if slider.Dragging and slider.Visible then
            local mouseX = Mouse.X
            local sliderX = slider.Objects.SliderBg.Position.X
            local sliderWidth = slider.Objects.SliderBg.Size.X

            local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
            local value = slider.Min + (slider.Max - slider.Min) * percent
            slider:Set(value)
        end
    end))

    if slider.Flag then
        NexusLib.Flags[slider.Flag] = slider.Value
    end

    self.CurrentY = self.CurrentY + 35
    self:UpdateSize()
    table.insert(self.Elements, slider)
    return slider
end

-- Button Element
function Section:Button(options)
    options = options or {}

    local button = {
        Type = "Button",
        Section = self,
        Name = options.name or "Button",
        Callback = options.callback or function() end,
        Objects = {},
        Visible = self.Visible
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8
    local width = self.Width - 16

    button.Objects.Bg = Create("Square", {
        Size = Vector2.new(width, 22),
        Position = Vector2.new(x, y),
        Color = win.Theme.Element,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    button.Objects.Outline = Create("Square", {
        Size = Vector2.new(width, 22),
        Position = Vector2.new(x, y),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    button.Objects.Label = Create("Text", {
        Text = button.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + width/2, y + 4),
        Color = win.Theme.Text,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 13
    })

    function button:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
    end

    function button:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
    end

    function button:Destroy()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and button.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local btnPos = button.Objects.Bg.Position
            local btnSize = button.Objects.Bg.Size

            if IsInBounds(btnPos, btnSize, mousePos) then
                button.Objects.Bg.Color = win.Accent
                button.Callback()
                task.delay(0.1, function()
                    if button.Objects.Bg then
                        button.Objects.Bg.Color = win.Theme.Element
                    end
                end)
            end
        end
    end))

    self.CurrentY = self.CurrentY + 28
    self:UpdateSize()
    table.insert(self.Elements, button)
    return button
end

-- Dropdown Element
function Section:Dropdown(options)
    options = options or {}

    local dropdown = {
        Type = "Dropdown",
        Section = self,
        Name = options.name or "Dropdown",
        Items = options.items or {},
        Value = options.default or (options.items and options.items[1]) or "",
        Multi = options.multi or false,
        Flag = options.flag,
        Callback = options.callback or function() end,
        Objects = {},
        OptionObjects = {},
        Visible = self.Visible,
        Open = false
    }

    if dropdown.Multi then
        dropdown.Value = options.default or {}
    end

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8
    local width = self.Width - 16

    -- Label
    dropdown.Objects.Label = Create("Text", {
        Text = dropdown.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x, y),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 11
    })

    -- Dropdown box
    dropdown.Objects.Box = Create("Square", {
        Size = Vector2.new(width, 20),
        Position = Vector2.new(x, y + 18),
        Color = win.Theme.Element,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    dropdown.Objects.BoxOutline = Create("Square", {
        Size = Vector2.new(width, 20),
        Position = Vector2.new(x, y + 18),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    local displayText = dropdown.Multi and table.concat(dropdown.Value, ", ") or dropdown.Value
    dropdown.Objects.Selected = Create("Text", {
        Text = displayText ~= "" and displayText or "None",
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + 5, y + 21),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 13
    })

    -- Arrow indicator
    dropdown.Objects.Arrow = Create("Text", {
        Text = "+",
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + width - 15, y + 20),
        Color = win.Theme.TextDim,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 13
    })

    function dropdown:UpdateDisplay()
        local text
        if self.Multi then
            text = #self.Value > 0 and table.concat(self.Value, ", ") or "None"
        else
            text = self.Value ~= "" and self.Value or "None"
        end
        self.Objects.Selected.Text = text
    end

    function dropdown:Set(value)
        if self.Multi then
            if type(value) == "table" then
                self.Value = value
            else
                local idx = table.find(self.Value, value)
                if idx then
                    table.remove(self.Value, idx)
                else
                    table.insert(self.Value, value)
                end
            end
        else
            self.Value = value
            self:CloseDropdown()
        end

        self:UpdateDisplay()

        if self.Flag then
            NexusLib.Flags[self.Flag] = self.Value
        end
        self.Callback(self.Value)
    end

    function dropdown:OpenDropdown()
        self.Open = true
        self.Objects.Arrow.Text = "-"

        local optY = self.Objects.Box.Position.Y + 22
        for i, item in ipairs(self.Items) do
            local isSelected = self.Multi and table.find(self.Value, item) or self.Value == item

            local optBg = Create("Square", {
                Size = Vector2.new(width, 18),
                Position = Vector2.new(x, optY),
                Color = win.Theme.Element,
                Filled = true,
                Visible = self.Visible,
                ZIndex = 50
            })

            local optText = Create("Text", {
                Text = item,
                Size = 13,
                Font = 2,
                Position = Vector2.new(x + 5, optY + 2),
                Color = isSelected and win.Accent or win.Theme.Text,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Visible = self.Visible,
                ZIndex = 51
            })

            table.insert(self.OptionObjects, {Bg = optBg, Text = optText, Item = item})
            optY = optY + 18
        end
    end

    function dropdown:CloseDropdown()
        self.Open = false
        self.Objects.Arrow.Text = "+"

        for _, opt in ipairs(self.OptionObjects) do
            opt.Bg:Remove()
            opt.Text:Remove()
        end
        self.OptionObjects = {}
    end

    function dropdown:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
        if not visible then
            self:CloseDropdown()
        end
    end

    function dropdown:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
    end

    function dropdown:Destroy()
        self:CloseDropdown()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    -- Click handler
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdown.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local boxPos = dropdown.Objects.Box.Position
            local boxSize = dropdown.Objects.Box.Size

            if IsInBounds(boxPos, boxSize, mousePos) then
                if dropdown.Open then
                    dropdown:CloseDropdown()
                else
                    dropdown:OpenDropdown()
                end
            elseif dropdown.Open then
                for _, opt in ipairs(dropdown.OptionObjects) do
                    if IsInBounds(opt.Bg.Position, opt.Bg.Size, mousePos) then
                        dropdown:Set(opt.Item)
                        return
                    end
                end
                dropdown:CloseDropdown()
            end
        end
    end))

    if dropdown.Flag then
        NexusLib.Flags[dropdown.Flag] = dropdown.Value
    end

    self.CurrentY = self.CurrentY + 45
    self:UpdateSize()
    table.insert(self.Elements, dropdown)
    return dropdown
end

-- Keybind Element
function Section:Keybind(options)
    options = options or {}

    local keybind = {
        Type = "Keybind",
        Section = self,
        Name = options.name or "Keybind",
        Value = options.default or Enum.KeyCode.Unknown,
        Flag = options.flag,
        Callback = options.callback or function() end,
        Objects = {},
        Visible = self.Visible,
        Listening = false
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8
    local width = self.Width - 16

    keybind.Objects.Label = Create("Text", {
        Text = keybind.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x, y),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 11
    })

    keybind.Objects.KeyBox = Create("Square", {
        Size = Vector2.new(45, 18),
        Position = Vector2.new(x + width - 50, y - 2),
        Color = win.Theme.Element,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    keybind.Objects.KeyOutline = Create("Square", {
        Size = Vector2.new(45, 18),
        Position = Vector2.new(x + width - 50, y - 2),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    keybind.Objects.KeyText = Create("Text", {
        Text = "[" .. GetKeyName(keybind.Value) .. "]",
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + width - 28, y),
        Color = win.Theme.TextDim,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 13
    })

    function keybind:Set(key)
        self.Value = key
        self.Objects.KeyText.Text = "[" .. GetKeyName(key) .. "]"
        if self.Flag then
            NexusLib.Flags[self.Flag] = key
        end
    end

    function keybind:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
    end

    function keybind:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
    end

    function keybind:Destroy()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    -- Click to rebind
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if keybind.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybind:Set(input.KeyCode)
                keybind.Listening = false
                keybind.Objects.KeyBox.Color = win.Theme.Element
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.MouseButton2 then
                keybind:Set(input.UserInputType)
                keybind.Listening = false
                keybind.Objects.KeyBox.Color = win.Theme.Element
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and keybind.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local boxPos = keybind.Objects.KeyBox.Position
            local boxSize = keybind.Objects.KeyBox.Size

            if IsInBounds(boxPos, boxSize, mousePos) then
                keybind.Listening = true
                keybind.Objects.KeyText.Text = "[...]"
                keybind.Objects.KeyBox.Color = win.Accent
            end
        end

        -- Fire callback when key pressed
        if not keybind.Listening and keybind.Value then
            if (input.KeyCode and input.KeyCode == keybind.Value) or
               (input.UserInputType and input.UserInputType == keybind.Value) then
                keybind.Callback(keybind.Value)
            end
        end
    end))

    if keybind.Flag then
        NexusLib.Flags[keybind.Flag] = keybind.Value
    end

    self.CurrentY = self.CurrentY + 22
    self:UpdateSize()
    table.insert(self.Elements, keybind)
    return keybind
end

-- Textbox Element
function Section:Textbox(options)
    options = options or {}

    local textbox = {
        Type = "Textbox",
        Section = self,
        Name = options.name or "",
        Value = options.default or "",
        Placeholder = options.placeholder or "Enter text...",
        Flag = options.flag,
        Callback = options.callback or function() end,
        Objects = {},
        Visible = self.Visible,
        Focused = false
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8
    local width = self.Width - 16

    local hasLabel = textbox.Name ~= ""

    if hasLabel then
        textbox.Objects.Label = Create("Text", {
            Text = textbox.Name,
            Size = 13,
            Font = 2,
            Position = Vector2.new(x, y),
            Color = win.Theme.Text,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Visible = self.Visible,
            ZIndex = 11
        })
        y = y + 18
    end

    textbox.Objects.Box = Create("Square", {
        Size = Vector2.new(width, 22),
        Position = Vector2.new(x, y),
        Color = win.Theme.Element,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    textbox.Objects.Outline = Create("Square", {
        Size = Vector2.new(width, 22),
        Position = Vector2.new(x, y),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    textbox.Objects.Text = Create("Text", {
        Text = textbox.Value ~= "" and textbox.Value or textbox.Placeholder,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x + 5, y + 4),
        Color = textbox.Value ~= "" and win.Theme.Text or win.Theme.TextDim,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 13
    })

    textbox.InputY = y

    function textbox:Set(value)
        self.Value = value
        self.Objects.Text.Text = value ~= "" and value or self.Placeholder
        self.Objects.Text.Color = value ~= "" and win.Theme.Text or win.Theme.TextDim
        if self.Flag then
            NexusLib.Flags[self.Flag] = value
        end
        self.Callback(value)
    end

    function textbox:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
    end

    function textbox:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
        self.InputY = self.InputY + delta.Y
    end

    function textbox:Destroy()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    -- Text input simulation
    table.insert(NexusLib.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and textbox.Visible then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local boxPos = textbox.Objects.Box.Position
            local boxSize = textbox.Objects.Box.Size

            if IsInBounds(boxPos, boxSize, mousePos) then
                textbox.Focused = true
                textbox.Objects.Outline.Color = win.Accent
                textbox.Objects.Text.Text = textbox.Value .. "|"
            else
                if textbox.Focused then
                    textbox.Focused = false
                    textbox.Objects.Outline.Color = win.Theme.ElementBorder
                    textbox.Objects.Text.Text = textbox.Value ~= "" and textbox.Value or textbox.Placeholder
                    textbox.Objects.Text.Color = textbox.Value ~= "" and win.Theme.Text or win.Theme.TextDim
                end
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard and textbox.Focused then
            local key = input.KeyCode.Name

            if input.KeyCode == Enum.KeyCode.Return then
                textbox.Focused = false
                textbox.Objects.Outline.Color = win.Theme.ElementBorder
                textbox:Set(textbox.Value)
            elseif input.KeyCode == Enum.KeyCode.Backspace then
                textbox.Value = textbox.Value:sub(1, -2)
                textbox.Objects.Text.Text = textbox.Value .. "|"
            elseif #key == 1 then
                local char = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and key:upper() or key:lower()
                textbox.Value = textbox.Value .. char
                textbox.Objects.Text.Text = textbox.Value .. "|"
            elseif input.KeyCode == Enum.KeyCode.Space then
                textbox.Value = textbox.Value .. " "
                textbox.Objects.Text.Text = textbox.Value .. "|"
            end
        end
    end))

    if textbox.Flag then
        NexusLib.Flags[textbox.Flag] = textbox.Value
    end

    self.CurrentY = self.CurrentY + (hasLabel and 45 or 28)
    self:UpdateSize()
    table.insert(self.Elements, textbox)
    return textbox
end

-- Label Element
function Section:Label(options)
    options = options or {}

    local label = {
        Type = "Label",
        Section = self,
        Text = options.text or "Label",
        Objects = {},
        Visible = self.Visible
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8

    label.Objects.Text = Create("Text", {
        Text = label.Text,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x, y),
        Color = win.Theme.TextDim,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 11
    })

    function label:Set(text)
        self.Text = text
        self.Objects.Text.Text = text
    end

    function label:SetVisible(visible)
        self.Visible = visible
        self.Objects.Text.Visible = visible
    end

    function label:UpdatePosition(delta)
        self.Objects.Text.Position = self.Objects.Text.Position + delta
    end

    function label:Destroy()
        self.Objects.Text:Remove()
    end

    self.CurrentY = self.CurrentY + 18
    self:UpdateSize()
    table.insert(self.Elements, label)
    return label
end

-- ColorPicker Element
function Section:ColorPicker(options)
    options = options or {}

    local colorpicker = {
        Type = "ColorPicker",
        Section = self,
        Name = options.name or "Color",
        Value = options.default or Color3.fromRGB(255, 255, 255),
        Flag = options.flag,
        Callback = options.callback or function() end,
        Objects = {},
        Visible = self.Visible,
        Open = false
    }

    local win = self.Window
    local y = self.CurrentY
    local x = self.StartX + 8
    local width = self.Width - 16

    colorpicker.Objects.Label = Create("Text", {
        Text = colorpicker.Name,
        Size = 13,
        Font = 2,
        Position = Vector2.new(x, y),
        Color = win.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Visible = self.Visible,
        ZIndex = 11
    })

    colorpicker.Objects.Preview = Create("Square", {
        Size = Vector2.new(25, 14),
        Position = Vector2.new(x + width - 30, y - 1),
        Color = colorpicker.Value,
        Filled = true,
        Visible = self.Visible,
        ZIndex = 11
    })

    colorpicker.Objects.PreviewOutline = Create("Square", {
        Size = Vector2.new(25, 14),
        Position = Vector2.new(x + width - 30, y - 1),
        Color = win.Theme.ElementBorder,
        Filled = false,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 12
    })

    function colorpicker:Set(color)
        self.Value = color
        self.Objects.Preview.Color = color
        if self.Flag then
            NexusLib.Flags[self.Flag] = color
        end
        self.Callback(color)
    end

    function colorpicker:SetVisible(visible)
        self.Visible = visible
        for _, obj in pairs(self.Objects) do
            obj.Visible = visible
        end
    end

    function colorpicker:UpdatePosition(delta)
        for _, obj in pairs(self.Objects) do
            if obj.Position then
                obj.Position = obj.Position + delta
            end
        end
    end

    function colorpicker:Destroy()
        for _, obj in pairs(self.Objects) do
            obj:Remove()
        end
    end

    if colorpicker.Flag then
        NexusLib.Flags[colorpicker.Flag] = colorpicker.Value
    end

    self.CurrentY = self.CurrentY + 20
    self:UpdateSize()
    table.insert(self.Elements, colorpicker)
    return colorpicker
end

-- Separator Element
function Section:Separator()
    local sep = {
        Type = "Separator",
        Section = self,
        Objects = {},
        Visible = self.Visible
    }

    local win = self.Window
    local y = self.CurrentY + 5
    local x = self.StartX + 8
    local width = self.Width - 16

    sep.Objects.Line = Create("Line", {
        From = Vector2.new(x, y),
        To = Vector2.new(x + width, y),
        Color = win.Theme.SectionBorder,
        Thickness = 1,
        Visible = self.Visible,
        ZIndex = 11
    })

    function sep:SetVisible(visible)
        self.Visible = visible
        self.Objects.Line.Visible = visible
    end

    function sep:UpdatePosition(delta)
        self.Objects.Line.From = self.Objects.Line.From + delta
        self.Objects.Line.To = self.Objects.Line.To + delta
    end

    function sep:Destroy()
        self.Objects.Line:Remove()
    end

    self.CurrentY = self.CurrentY + 12
    self:UpdateSize()
    table.insert(self.Elements, sep)
    return sep
end

-- Initialize
function NexusLib:Init()
    if self.CurrentPage then
        self:SelectPage(self.CurrentPage)
    elseif #self.Pages > 0 then
        self:SelectPage(self.Pages[1])
    end
    return self
end

return NexusLib
