--[[
    GHACK OT UI Library - Complete Rewrite
    Clean recreation of GMod GHack menu for Roblox
    
    Usage:
        local Library = loadstring(...)()
        local Window = Library:CreateWindow("GHACK OT")
        local Tab = Window:AddTab("Aimbot")
        local SubTab = Tab:AddSubTab("Players")
        local Section = SubTab:AddSection("Chams")
        Section:AddToggle({Name = "Enabled", Default = false, Callback = function(v) end})
]]

local Library = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Theme
local Theme = {
    Accent = Color3.fromRGB(255, 0, 151),
    
    Background = Color3.fromRGB(24, 24, 24),
    BackgroundLight = Color3.fromRGB(32, 32, 32),
    BackgroundLighter = Color3.fromRGB(40, 40, 40),
    
    Panel = Color3.fromRGB(28, 28, 28),
    PanelLight = Color3.fromRGB(36, 36, 36),
    PanelLighter = Color3.fromRGB(44, 44, 44),
    
    Border = Color3.fromRGB(50, 50, 50),
    BorderDark = Color3.fromRGB(20, 20, 20),
    
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(170, 170, 170),
    TextDisabled = Color3.fromRGB(100, 100, 100),
    
    Control = Color3.fromRGB(45, 45, 45),
    ControlHover = Color3.fromRGB(55, 55, 55),
    ControlActive = Color3.fromRGB(65, 65, 65),
}

-- State
Library.Windows = {}
Library.Connections = {}
Library.ToggleKey = Enum.KeyCode.RightShift

-- Utilities
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    if props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function Tween(obj, props, duration, style, direction)
    local tween = TweenService:Create(obj, TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function AddConnection(conn)
    table.insert(Library.Connections, conn)
    return conn
end

local function ApplyGradient(frame, topColor, bottomColor, transparency)
    local overlay = Create("Frame", {
        Name = "Gradient",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = transparency or 0.9,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex,
        Parent = frame
    })
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, topColor or Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, bottomColor or Color3.fromRGB(150, 150, 150))
        }),
        Rotation = 90,
        Parent = overlay
    })
    return overlay
end

local function CreateStroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Parent = parent
    })
end

-- Unload
function Library:Unload()
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    for _, window in ipairs(self.Windows) do
        if window.GUI then window.GUI:Destroy() end
    end
    self.Windows = {}
    self.Connections = {}
end

--[[ WINDOW ]]--
function Library:CreateWindow(title)
    local Window = {
        Title = title or "GHACK OT",
        Tabs = {},
        ActiveTab = nil,
        Visible = false,
        Dragging = false,
    }
    
    -- ScreenGui
    Window.GUI = Create("ScreenGui", {
        Name = "GHackUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    pcall(function() Window.GUI.Parent = CoreGui end)
    if not Window.GUI.Parent then
        Window.GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame (outer border)
    Window.Main = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 560, 0, 400),
        Position = UDim2.new(0.5, -280, 0.5, -200),
        BackgroundColor3 = Theme.BorderDark,
        BorderSizePixel = 0,
        Visible = false,
        Parent = Window.GUI
    })
    
    -- Inner border
    local innerBorder = Create("Frame", {
        Name = "InnerBorder",
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = Window.Main
    })
    
    -- Content container
    Window.Container = Create("Frame", {
        Name = "Container",
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = innerBorder
    })
    ApplyGradient(Window.Container, Color3.fromRGB(50, 50, 50), Color3.fromRGB(20, 20, 20), 0.92)
    
    -- Title Bar
    Window.TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = Window.Container
    })
    ApplyGradient(Window.TitleBar, Color3.fromRGB(60, 60, 60), Color3.fromRGB(30, 30, 30), 0.88)
    
    -- Title bar bottom line
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Window.TitleBar
    })
    
    -- Title text
    Window.TitleLabel = Create("TextLabel", {
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = Window.Title,
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = Window.TitleBar
    })
    
    -- Tab container (right side of title bar)
    Window.TabBar = Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = Window.TitleBar
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 20),
        Parent = Window.TabBar
    })
    
    Create("UIPadding", {
        PaddingRight = UDim.new(0, 15),
        Parent = Window.TabBar
    })
    
    -- Sidebar (left panel for subtabs)
    Window.Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 110, 1, -25),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Window.Container
    })
    ApplyGradient(Window.Sidebar, Color3.fromRGB(45, 45, 45), Color3.fromRGB(25, 25, 25), 0.9)
    
    -- Sidebar right border
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Window.Sidebar
    })
    
    -- Content area
    Window.Content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -111, 1, -25),
        Position = UDim2.new(0, 111, 0, 25),
        BackgroundColor3 = Theme.BackgroundLight,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Window.Container
    })
    ApplyGradient(Window.Content, Color3.fromRGB(40, 40, 40), Color3.fromRGB(20, 20, 20), 0.93)
    
    -- Dragging
    local dragStart, startPos
    
    AddConnection(Window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Window.Dragging = true
            dragStart = input.Position
            startPos = Window.Main.Position
        end
    end))
    
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if Window.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Window.Dragging = false
        end
    end))
    
    -- Toggle keybind
    AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Library.ToggleKey then
            Window:Toggle()
        end
    end))
    
    -- Methods
    function Window:Toggle()
        self.Visible = not self.Visible
        self.Main.Visible = self.Visible
    end
    
    function Window:Show()
        self.Visible = true
        self.Main.Visible = true
    end
    
    function Window:Hide()
        self.Visible = false
        self.Main.Visible = false
    end
    
    function Window:SelectTab(tab)
        if self.ActiveTab == tab then return end
        
        -- Deselect old tab
        if self.ActiveTab then
            self.ActiveTab.Button.TextColor3 = Theme.Text
            self.ActiveTab.Underline.Visible = false
            self.ActiveTab.SubTabHolder.Visible = false
            self.ActiveTab.ContentHolder.Visible = false
        end
        
        -- Select new tab
        self.ActiveTab = tab
        tab.Button.TextColor3 = Theme.Accent
        tab.Underline.Visible = true
        tab.SubTabHolder.Visible = true
        tab.ContentHolder.Visible = true
    end
    
    function Window:AddTab(name)
        local Tab = {
            Name = name,
            Window = self,
            SubTabs = {},
            ActiveSubTab = nil,
            Index = #self.Tabs + 1
        }
        
        -- Tab button container
        Tab.ButtonHolder = Create("Frame", {
            Name = name,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            LayoutOrder = Tab.Index,
            Parent = self.TabBar
        })
        
        -- Tab button
        Tab.Button = Create("TextButton", {
            Size = UDim2.new(1, 0, 1, -4),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Tab.Index == 1 and Theme.Accent or Theme.Text,
            Font = Enum.Font.Code,
            TextSize = 14,
            Parent = Tab.ButtonHolder
        })
        
        -- Underline
        Tab.Underline = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = Tab.Index == 1,
            Parent = Tab.ButtonHolder
        })
        
        -- SubTab holder (in sidebar)
        Tab.SubTabHolder = Create("ScrollingFrame", {
            Name = name .. "_SubTabs",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = Tab.Index == 1,
            Parent = self.Sidebar
        })
        
        Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = Tab.SubTabHolder
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            Parent = Tab.SubTabHolder
        })
        
        -- Content holder
        Tab.ContentHolder = Create("Frame", {
            Name = name .. "_Content",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = Tab.Index == 1,
            Parent = self.Content
        })
        
        -- Tab button events
        Tab.Button.MouseButton1Click:Connect(function()
            self:SelectTab(Tab)
        end)
        
        Tab.Button.MouseEnter:Connect(function()
            if self.ActiveTab ~= Tab then
                Tab.Button.TextColor3 = Theme.Accent
            end
        end)
        
        Tab.Button.MouseLeave:Connect(function()
            if self.ActiveTab ~= Tab then
                Tab.Button.TextColor3 = Theme.Text
            end
        end)
        
        -- SubTab selection
        function Tab:SelectSubTab(subtab)
            if self.ActiveSubTab == subtab then return end
            
            if self.ActiveSubTab then
                self.ActiveSubTab.Background.Visible = false
                self.ActiveSubTab.AccentLine.Visible = false
                self.ActiveSubTab.Button.TextColor3 = Theme.TextDim
                self.ActiveSubTab.Content.Visible = false
            end
            
            self.ActiveSubTab = subtab
            subtab.Background.Visible = true
            subtab.AccentLine.Visible = true
            subtab.Button.TextColor3 = Theme.Accent
            subtab.Content.Visible = true
        end
        
        function Tab:AddSubTab(name)
            local SubTab = {
                Name = name,
                Tab = self,
                Sections = {},
                Index = #self.SubTabs + 1
            }
            
            -- SubTab button holder
            SubTab.Holder = Create("Frame", {
                Name = name,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = SubTab.Index,
                Parent = self.SubTabHolder
            })
            
            -- Selection background
            SubTab.Background = Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Theme.PanelLight,
                BorderSizePixel = 0,
                Visible = SubTab.Index == 1,
                Parent = SubTab.Holder
            })
            
            Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 75)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 50))
                }),
                Rotation = 0,
                Parent = SubTab.Background
            })
            
            -- Accent line
            SubTab.AccentLine = Create("Frame", {
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Visible = SubTab.Index == 1,
                ZIndex = 2,
                Parent = SubTab.Holder
            })
            
            -- Button
            SubTab.Button = Create("TextButton", {
                Size = UDim2.new(1, -8, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = SubTab.Index == 1 and Theme.Accent or Theme.TextDim,
                Font = Enum.Font.Code,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 3,
                Parent = SubTab.Holder
            })
            
            -- Content scroll frame
            SubTab.Content = Create("ScrollingFrame", {
                Name = name .. "_Content",
                Size = UDim2.new(1, -10, 1, -10),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = SubTab.Index == 1,
                Parent = self.ContentHolder
            })
            
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 8),
                Wraps = true,
                Parent = SubTab.Content
            })
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                Parent = SubTab.Content
            })
            
            -- Events
            SubTab.Button.MouseButton1Click:Connect(function()
                self:SelectSubTab(SubTab)
            end)
            
            SubTab.Button.MouseEnter:Connect(function()
                if self.ActiveSubTab ~= SubTab then
                    SubTab.Button.TextColor3 = Theme.Text
                end
            end)
            
            SubTab.Button.MouseLeave:Connect(function()
                if self.ActiveSubTab ~= SubTab then
                    SubTab.Button.TextColor3 = Theme.TextDim
                end
            end)
            
            -- Section creation
            function SubTab:AddSection(name)
                local Section = {
                    Name = name,
                    SubTab = self,
                    Controls = {},
                    Index = #self.Sections + 1
                }
                
                -- Section frame
                Section.Frame = Create("Frame", {
                    Name = name,
                    Size = UDim2.new(0, 205, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Theme.BorderDark,
                    BorderSizePixel = 0,
                    LayoutOrder = Section.Index,
                    Parent = self.Content
                })
                
                -- Inner border
                local sectionInner = Create("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    Parent = Section.Frame
                })
                
                -- Background
                Section.Background = Create("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    Parent = sectionInner
                })
                ApplyGradient(Section.Background, Color3.fromRGB(55, 55, 55), Color3.fromRGB(35, 35, 35), 0.85)
                
                -- Accent line at top
                Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    Parent = Section.Background
                })
                
                -- Title
                Create("TextLabel", {
                    Size = UDim2.new(1, -12, 0, 20),
                    Position = UDim2.new(0, 6, 0, 2),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Code,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 2,
                    Parent = Section.Background
                })
                
                -- Separator
                Create("Frame", {
                    Size = UDim2.new(1, -12, 0, 1),
                    Position = UDim2.new(0, 6, 0, 22),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = Section.Background
                })
                
                -- Controls container
                Section.Container = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 26),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    Parent = Section.Background
                })
                
                Create("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    Parent = Section.Container
                })
                
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 3),
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    Parent = Section.Container
                })
                
                --[[ TOGGLE ]]--
                function Section:AddToggle(options)
                    local Toggle = {
                        Value = options.Default or false,
                        Callback = options.Callback,
                        Flag = options.Flag
                    }
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
                    -- Checkbox outer
                    local boxOuter = Create("Frame", {
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0, 0, 0.5, -6),
                        BackgroundColor3 = Theme.BorderDark,
                        BorderSizePixel = 0,
                        Parent = holder
                    })
                    
                    local boxInner = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        Parent = boxOuter
                    })
                    
                    local boxFill = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Toggle.Value and Theme.Accent or Theme.Control,
                        BorderSizePixel = 0,
                        Parent = boxInner
                    })
                    ApplyGradient(boxFill, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 0.85)
                    
                    -- Label
                    Create("TextLabel", {
                        Size = UDim2.new(1, -18, 1, 0),
                        Position = UDim2.new(0, 18, 0, 0),
                        BackgroundTransparency = 1,
                        Text = options.Name,
                        TextColor3 = options.Risky and Color3.fromRGB(220, 220, 120) or Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = holder
                    })
                    
                    -- Click detection
                    local btn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = holder
                    })
                    
                    btn.MouseEnter:Connect(function()
                        if not Toggle.Value then
                            Tween(boxFill, {BackgroundColor3 = Theme.ControlHover}, 0.1)
                        end
                    end)
                    
                    btn.MouseLeave:Connect(function()
                        if not Toggle.Value then
                            Tween(boxFill, {BackgroundColor3 = Theme.Control}, 0.1)
                        end
                    end)
                    
                    btn.MouseButton1Click:Connect(function()
                        Toggle.Value = not Toggle.Value
                        Tween(boxFill, {BackgroundColor3 = Toggle.Value and Theme.Accent or Theme.Control}, 0.1)
                        if Toggle.Callback then
                            pcall(Toggle.Callback, Toggle.Value)
                        end
                    end)
                    
                    function Toggle:Set(value)
                        self.Value = value
                        boxFill.BackgroundColor3 = value and Theme.Accent or Theme.Control
                        if self.Callback then pcall(self.Callback, value) end
                    end
                    
                    function Toggle:Get()
                        return self.Value
                    end
                    
                    table.insert(self.Controls, Toggle)
                    return Toggle
                end
                
                --[[ SLIDER ]]--
                function Section:AddSlider(options)
                    local Slider = {
                        Value = options.Default or options.Min or 0,
                        Min = options.Min or 0,
                        Max = options.Max or 100,
                        Decimals = options.Decimals or 0,
                        Suffix = options.Suffix or "",
                        Callback = options.Callback
                    }
                    
                    local hasLabel = options.Name and options.Name ~= ""
                    local height = hasLabel and 32 or 16
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, height),
                        BackgroundTransparency = 1,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
                    local yOffset = 0
                    if hasLabel then
                        Create("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 16),
                            BackgroundTransparency = 1,
                            Text = options.Name,
                            TextColor3 = Theme.Text,
                            Font = Enum.Font.Code,
                            TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            Parent = holder
                        })
                        yOffset = 16
                    end
                    
                    -- Slider bar
                    local barOuter = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 14),
                        Position = UDim2.new(0, 0, 0, yOffset),
                        BackgroundColor3 = Theme.BorderDark,
                        BorderSizePixel = 0,
                        Parent = holder
                    })
                    
                    local barInner = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        Parent = barOuter
                    })
                    
                    local barBg = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Control,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        Parent = barInner
                    })
                    ApplyGradient(barBg, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 0.88)
                    
                    local fillPercent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    local barFill = Create("Frame", {
                        Size = UDim2.new(fillPercent, 0, 1, 0),
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        Parent = barBg
                    })
                    ApplyGradient(barFill, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 0.7)
                    
                    local valueLabel = Create("TextLabel", {
                        Size = UDim2.new(1, -6, 1, 0),
                        Position = UDim2.new(0, 3, 0, 0),
                        BackgroundTransparency = 1,
                        Text = tostring(Slider.Value) .. Slider.Suffix,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 3,
                        Parent = barBg
                    })
                    
                    local dragging = false
                    
                    local function update(input)
                        local relX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                        local value = Slider.Min + (Slider.Max - Slider.Min) * relX
                        
                        if Slider.Decimals == 0 then
                            value = math.floor(value + 0.5)
                        else
                            value = math.floor(value * 10^Slider.Decimals + 0.5) / 10^Slider.Decimals
                        end
                        
                        Slider.Value = value
                        barFill.Size = UDim2.new(relX, 0, 1, 0)
                        valueLabel.Text = tostring(value) .. Slider.Suffix
                        
                        if Slider.Callback then pcall(Slider.Callback, value) end
                    end
                    
                    barBg.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            update(input)
                        end
                    end)
                    
                    AddConnection(UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            update(input)
                        end
                    end))
                    
                    AddConnection(UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end))
                    
                    function Slider:Set(value)
                        value = math.clamp(value, self.Min, self.Max)
                        self.Value = value
                        local percent = (value - self.Min) / (self.Max - self.Min)
                        barFill.Size = UDim2.new(percent, 0, 1, 0)
                        valueLabel.Text = tostring(value) .. self.Suffix
                        if self.Callback then pcall(self.Callback, value) end
                    end
                    
                    function Slider:Get()
                        return self.Value
                    end
                    
                    table.insert(self.Controls, Slider)
                    return Slider
                end
                
                --[[ DROPDOWN ]]--
                function Section:AddDropdown(options)
                    local Dropdown = {
                        Value = options.Default or (options.Options and options.Options[1]) or "",
                        Options = options.Options or {},
                        Callback = options.Callback,
                        Open = false
                    }
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 36),
                        BackgroundTransparency = 1,
                        ClipsDescendants = false,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
                    -- Label
                    Create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 16),
                        BackgroundTransparency = 1,
                        Text = options.Name,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = holder
                    })
                    
                    -- Dropdown box
                    local boxOuter = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 18),
                        Position = UDim2.new(0, 0, 0, 16),
                        BackgroundColor3 = Theme.BorderDark,
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        Parent = holder
                    })
                    
                    local boxInner = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        Parent = boxOuter
                    })
                    
                    local boxBg = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Control,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        ZIndex = 5,
                        Parent = boxInner
                    })
                    ApplyGradient(boxBg, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 0.88)
                    
                    local selected = Create("TextLabel", {
                        Size = UDim2.new(1, -20, 1, 0),
                        Position = UDim2.new(0, 6, 0, 0),
                        BackgroundTransparency = 1,
                        Text = Dropdown.Value,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 6,
                        Parent = boxBg
                    })
                    
                    local arrow = Create("TextLabel", {
                        Size = UDim2.new(0, 14, 1, 0),
                        Position = UDim2.new(1, -16, 0, 0),
                        BackgroundTransparency = 1,
                        Text = "▼",
                        TextColor3 = Theme.TextDim,
                        Font = Enum.Font.Code,
                        TextSize = 8,
                        ZIndex = 6,
                        Parent = boxBg
                    })
                    
                    local dropBtn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        ZIndex = 7,
                        Parent = boxBg
                    })
                    
                    -- Options list
                    local listHolder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Options * 18, 108)),
                        Position = UDim2.new(0, 0, 1, 2),
                        BackgroundColor3 = Theme.Control,
                        BorderSizePixel = 0,
                        Visible = false,
                        ClipsDescendants = true,
                        ZIndex = 10,
                        Parent = boxOuter
                    })
                    CreateStroke(listHolder, Theme.Border)
                    ApplyGradient(listHolder, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 0.88)
                    
                    local listScroll = Create("ScrollingFrame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Theme.Accent,
                        CanvasSize = UDim2.new(0, 0, 0, #Dropdown.Options * 18),
                        ZIndex = 10,
                        Parent = listHolder
                    })
                    
                    Create("UIListLayout", {
                        Padding = UDim.new(0, 0),
                        Parent = listScroll
                    })
                    
                    local function createOption(text)
                        local optBtn = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 18),
                            BackgroundColor3 = Theme.Control,
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            Text = "",
                            ZIndex = 11,
                            Parent = listScroll
                        })
                        
                        Create("TextLabel", {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 6, 0, 0),
                            BackgroundTransparency = 1,
                            Text = text,
                            TextColor3 = Theme.Text,
                            Font = Enum.Font.Code,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 12,
                            Parent = optBtn
                        })
                        
                        optBtn.MouseEnter:Connect(function()
                            optBtn.BackgroundColor3 = Theme.ControlHover
                        end)
                        
                        optBtn.MouseLeave:Connect(function()
                            optBtn.BackgroundColor3 = Theme.Control
                        end)
                        
                        optBtn.MouseButton1Click:Connect(function()
                            Dropdown.Value = text
                            selected.Text = text
                            Dropdown.Open = false
                            listHolder.Visible = false
                            arrow.Text = "▼"
                            if Dropdown.Callback then pcall(Dropdown.Callback, text) end
                        end)
                    end
                    
                    for _, opt in ipairs(Dropdown.Options) do
                        createOption(opt)
                    end
                    
                    dropBtn.MouseButton1Click:Connect(function()
                        Dropdown.Open = not Dropdown.Open
                        listHolder.Visible = Dropdown.Open
                        arrow.Text = Dropdown.Open and "▲" or "▼"
                    end)
                    
                    function Dropdown:Set(value)
                        if table.find(self.Options, value) then
                            self.Value = value
                            selected.Text = value
                            if self.Callback then pcall(self.Callback, value) end
                        end
                    end
                    
                    function Dropdown:Get()
                        return self.Value
                    end
                    
                    function Dropdown:Refresh(newOptions)
                        self.Options = newOptions
                        for _, child in ipairs(listScroll:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        for _, opt in ipairs(newOptions) do
                            createOption(opt)
                        end
                        listScroll.CanvasSize = UDim2.new(0, 0, 0, #newOptions * 18)
                        listHolder.Size = UDim2.new(1, 0, 0, math.min(#newOptions * 18, 108))
                    end
                    
                    table.insert(self.Controls, Dropdown)
                    return Dropdown
                end
                
                --[[ BUTTON ]]--
                function Section:AddButton(options)
                    local Button = {
                        Callback = options.Callback
                    }
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundTransparency = 1,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
                    local btnOuter = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3 = Theme.BorderDark,
                        BorderSizePixel = 0,
                        Parent = holder
                    })
                    
                    local btnInner = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        Parent = btnOuter
                    })
                    
                    local btnBg = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Control,
                        BorderSizePixel = 0,
                        Parent = btnInner
                    })
                    ApplyGradient(btnBg, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 0.88)
                    
                    local btn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = options.Name,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = btnBg
                    })
                    
                    btn.MouseEnter:Connect(function()
                        Tween(btnBg, {BackgroundColor3 = Theme.ControlHover}, 0.1)
                    end)
                    
                    btn.MouseLeave:Connect(function()
                        Tween(btnBg, {BackgroundColor3 = Theme.Control}, 0.1)
                    end)
                    
                    btn.MouseButton1Click:Connect(function()
                        if Button.Callback then pcall(Button.Callback) end
                    end)
                    
                    table.insert(self.Controls, Button)
                    return Button
                end
                
                --[[ COLOR PICKER ]]--
                function Section:AddColorPicker(options)
                    local ColorPicker = {
                        Value = options.Default or Color3.new(1, 1, 1),
                        Callback = options.Callback
                    }
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
                    -- Label
                    Create("TextLabel", {
                        Size = UDim2.new(1, -30, 1, 0),
                        BackgroundTransparency = 1,
                        Text = options.Name,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = holder
                    })
                    
                    -- Color preview
                    local previewOuter = Create("Frame", {
                        Size = UDim2.new(0, 24, 0, 12),
                        Position = UDim2.new(1, -24, 0.5, -6),
                        BackgroundColor3 = Theme.BorderDark,
                        BorderSizePixel = 0,
                        Parent = holder
                    })
                    
                    local previewInner = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        Parent = previewOuter
                    })
                    
                    local preview = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = ColorPicker.Value,
                        BorderSizePixel = 0,
                        Parent = previewInner
                    })
                    
                    local previewBtn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = previewOuter
                    })
                    
                    local pickerOpen = false
                    local pickerFrame = nil
                    
                    previewBtn.MouseButton1Click:Connect(function()
                        if pickerOpen and pickerFrame then
                            pickerFrame:Destroy()
                            pickerFrame = nil
                            pickerOpen = false
                            return
                        end
                        
                        pickerOpen = true
                        
                        pickerFrame = Create("Frame", {
                            Size = UDim2.new(0, 140, 0, 115),
                            Position = UDim2.new(0, -116, 0, -2),
                            BackgroundColor3 = Theme.Panel,
                            BorderSizePixel = 0,
                            ZIndex = 20,
                            Parent = previewOuter
                        })
                        CreateStroke(pickerFrame, Theme.Border)
                        ApplyGradient(pickerFrame, Color3.fromRGB(60, 60, 60), Color3.fromRGB(35, 35, 35), 0.85)
                        
                        -- Saturation/Value picker
                        local svPicker = Create("Frame", {
                            Size = UDim2.new(0, 100, 0, 100),
                            Position = UDim2.new(0, 5, 0, 5),
                            BackgroundColor3 = Color3.fromHSV(select(1, ColorPicker.Value:ToHSV()), 1, 1),
                            BorderSizePixel = 0,
                            ZIndex = 21,
                            Parent = pickerFrame
                        })
                        CreateStroke(svPicker, Theme.BorderDark)
                        
                        -- White to color gradient
                        Create("UIGradient", {
                            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(select(1, ColorPicker.Value:ToHSV()), 1, 1)),
                            Transparency = NumberSequence.new(0, 1),
                            Parent = svPicker
                        })
                        
                        -- Black overlay
                        local blackOverlay = Create("Frame", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundColor3 = Color3.new(0, 0, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            ZIndex = 22,
                            Parent = svPicker
                        })
                        Create("UIGradient", {
                            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
                            Transparency = NumberSequence.new(0, 1),
                            Rotation = -90,
                            Parent = blackOverlay
                        })
                        
                        -- Hue bar
                        local huePicker = Create("Frame", {
                            Size = UDim2.new(0, 15, 0, 100),
                            Position = UDim2.new(0, 110, 0, 5),
                            BorderSizePixel = 0,
                            ZIndex = 21,
                            Parent = pickerFrame
                        })
                        CreateStroke(huePicker, Theme.BorderDark)
                        
                        Create("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                                ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                                ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                            }),
                            Rotation = 90,
                            Parent = huePicker
                        })
                        
                        local h, s, v = ColorPicker.Value:ToHSV()
                        
                        local function updateColor()
                            ColorPicker.Value = Color3.fromHSV(h, s, v)
                            preview.BackgroundColor3 = ColorPicker.Value
                            svPicker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            if ColorPicker.Callback then pcall(ColorPicker.Callback, ColorPicker.Value) end
                        end
                        
                        -- SV dragging
                        local svDragging = false
                        svPicker.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                svDragging = true
                            end
                        end)
                        
                        AddConnection(UserInputService.InputChanged:Connect(function(input)
                            if svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                s = math.clamp((input.Position.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
                                v = 1 - math.clamp((input.Position.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)
                                updateColor()
                            end
                        end))
                        
                        AddConnection(UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                svDragging = false
                            end
                        end))
                        
                        -- Hue dragging
                        local hueDragging = false
                        huePicker.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                hueDragging = true
                            end
                        end)
                        
                        AddConnection(UserInputService.InputChanged:Connect(function(input)
                            if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                h = math.clamp((input.Position.Y - huePicker.AbsolutePosition.Y) / huePicker.AbsoluteSize.Y, 0, 0.999)
                                updateColor()
                            end
                        end))
                        
                        AddConnection(UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                hueDragging = false
                            end
                        end))
                    end)
                    
                    function ColorPicker:Set(color)
                        self.Value = color
                        preview.BackgroundColor3 = color
                        if self.Callback then pcall(self.Callback, color) end
                    end
                    
                    function ColorPicker:Get()
                        return self.Value
                    end
                    
                    table.insert(self.Controls, ColorPicker)
                    return ColorPicker
                end
                
                --[[ LABEL ]]--
                function Section:AddLabel(text)
                    local Label = {}
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 16),
                        BackgroundTransparency = 1,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
                    local label = Create("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = text,
                        TextColor3 = Theme.TextDim,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = holder
                    })
                    
                    function Label:Set(newText)
                        label.Text = newText
                    end
                    
                    table.insert(self.Controls, Label)
                    return Label
                end
                
                table.insert(self.Sections, Section)
                return Section
            end
            
            -- Auto-select first subtab
            if SubTab.Index == 1 then
                Tab.ActiveSubTab = SubTab
            end
            
            table.insert(self.SubTabs, SubTab)
            return SubTab
        end
        
        -- Auto-select first tab
        if Tab.Index == 1 then
            self.ActiveTab = Tab
        end
        
        table.insert(self.Tabs, Tab)
        return Tab
    end
    
    table.insert(Library.Windows, Window)
    return Window
end

return Library
