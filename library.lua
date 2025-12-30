--[[
    GHACK OT UI Library
    Clean recreation for Roblox
]]

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Theme = {
    Accent = Color3.fromRGB(255, 0, 151),
    Background = Color3.fromRGB(24, 24, 24),
    BackgroundLight = Color3.fromRGB(32, 32, 32),
    Panel = Color3.fromRGB(28, 28, 28),
    PanelLight = Color3.fromRGB(36, 36, 36),
    Border = Color3.fromRGB(50, 50, 50),
    BorderDark = Color3.fromRGB(20, 20, 20),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(170, 170, 170),
    Control = Color3.fromRGB(45, 45, 45),
    ControlHover = Color3.fromRGB(55, 55, 55),
}

Library.Windows = {}
Library.Connections = {}
Library.ToggleKey = Enum.KeyCode.RightShift

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

local function Tween(obj, props, duration)
    local tween = TweenService:Create(obj, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function AddConnection(conn)
    table.insert(Library.Connections, conn)
    return conn
end

local function ApplyGradient(frame, transparency)
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
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
        }),
        Rotation = 90,
        Parent = overlay
    })
    return overlay
end

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

function Library:CreateWindow(title)
    local Window = {
        Title = title or "GHACK OT",
        Tabs = {},
        ActiveTab = nil,
        Visible = false,
        Dragging = false,
    }
    
    Window.GUI = Create("ScreenGui", {
        Name = "GHackUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    
    local success = pcall(function() Window.GUI.Parent = CoreGui end)
    if not success then
        Window.GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    Window.Main = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 560, 0, 400),
        Position = UDim2.new(0.5, -280, 0.5, -200),
        BackgroundColor3 = Theme.BorderDark,
        BorderSizePixel = 0,
        Visible = false,
        Parent = Window.GUI
    })
    
    local innerBorder = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = Window.Main
    })
    
    Window.Container = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = innerBorder
    })
    ApplyGradient(Window.Container, 0.92)
    
    Window.TitleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = Window.Container
    })
    ApplyGradient(Window.TitleBar, 0.88)
    
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Window.TitleBar
    })
    
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
    
    Window.TabBar = Create("Frame", {
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
    
    Window.Sidebar = Create("Frame", {
        Size = UDim2.new(0, 110, 1, -25),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Window.Container
    })
    ApplyGradient(Window.Sidebar, 0.9)
    
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Window.Sidebar
    })
    
    Window.Content = Create("Frame", {
        Size = UDim2.new(1, -111, 1, -25),
        Position = UDim2.new(0, 111, 0, 25),
        BackgroundColor3 = Theme.BackgroundLight,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Window.Container
    })
    ApplyGradient(Window.Content, 0.93)
    
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
            Window.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Window.Dragging = false
        end
    end))
    
    AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Library.ToggleKey then
            Window:Toggle()
        end
    end))
    
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
        
        if self.ActiveTab then
            self.ActiveTab.Button.TextColor3 = Theme.Text
            self.ActiveTab.Underline.Visible = false
            self.ActiveTab.SubTabHolder.Visible = false
            self.ActiveTab.ContentHolder.Visible = false
        end
        
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
        
        Tab.ButtonHolder = Create("Frame", {
            Name = name,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            LayoutOrder = Tab.Index,
            Parent = self.TabBar
        })
        
        Tab.Button = Create("TextButton", {
            Size = UDim2.new(1, 0, 1, -4),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Tab.Index == 1 and Theme.Accent or Theme.Text,
            Font = Enum.Font.Code,
            TextSize = 14,
            Parent = Tab.ButtonHolder
        })
        
        Tab.Underline = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = Tab.Index == 1,
            Parent = Tab.ButtonHolder
        })
        
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
        
        Tab.ContentHolder = Create("Frame", {
            Name = name .. "_Content",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = Tab.Index == 1,
            Parent = self.Content
        })
        
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
            
            SubTab.Holder = Create("Frame", {
                Name = name,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = SubTab.Index,
                Parent = self.SubTabHolder
            })
            
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
            
            SubTab.AccentLine = Create("Frame", {
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Visible = SubTab.Index == 1,
                ZIndex = 2,
                Parent = SubTab.Holder
            })
            
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
            
            function SubTab:AddSection(name)
                local Section = {
                    Name = name,
                    SubTab = self,
                    Controls = {},
                    Index = #self.Sections + 1
                }
                
                Section.Frame = Create("Frame", {
                    Name = name,
                    Size = UDim2.new(0, 205, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Theme.BorderDark,
                    BorderSizePixel = 0,
                    LayoutOrder = Section.Index,
                    Parent = self.Content
                })
                
                local sectionInner = Create("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    Parent = Section.Frame
                })
                
                Section.Background = Create("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    Parent = sectionInner
                })
                ApplyGradient(Section.Background, 0.85)
                
                Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    Parent = Section.Background
                })
                
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
                
                Create("Frame", {
                    Size = UDim2.new(1, -12, 0, 1),
                    Position = UDim2.new(0, 6, 0, 22),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = Section.Background
                })
                
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
                
                function Section:AddToggle(options)
                    local Toggle = {
                        Value = options.Default or false,
                        Callback = options.Callback
                    }
                    
                    local holder = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        LayoutOrder = #self.Controls + 1,
                        Parent = self.Container
                    })
                    
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
                    ApplyGradient(boxFill, 0.85)
                    
                    Create("TextLabel", {
                        Size = UDim2.new(1, -18, 1, 0),
                        Position = UDim2.new(0, 18, 0, 0),
                        BackgroundTransparency = 1,
                        Text = options.Name,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = holder
                    })
                    
                    local btn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = holder
                    })
                    
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
                    
                    function Toggle:Get() return self.Value end
                    
                    table.insert(self.Controls, Toggle)
                    return Toggle
                end
                
                function Section:AddButton(options)
                    local Button = { Callback = options.Callback }
                    
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
                    ApplyGradient(btnBg, 0.88)
                    
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
                    ApplyGradient(boxBg, 0.88)
                    
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
                        Text = "v",
                        TextColor3 = Theme.TextDim,
                        Font = Enum.Font.Code,
                        TextSize = 10,
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
                    
                    Create("UIStroke", {
                        Color = Theme.Border,
                        Thickness = 1,
                        Parent = listHolder
                    })
                    
                    Create("UIListLayout", {
                        Padding = UDim.new(0, 0),
                        Parent = listHolder
                    })
                    
                    local function createOption(text)
                        local optBtn = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 18),
                            BackgroundColor3 = Theme.Control,
                            BorderSizePixel = 0,
                            Text = "",
                            ZIndex = 11,
                            Parent = listHolder
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
                            arrow.Text = "v"
                            if Dropdown.Callback then pcall(Dropdown.Callback, text) end
                        end)
                    end
                    
                    for _, opt in ipairs(Dropdown.Options) do
                        createOption(opt)
                    end
                    
                    dropBtn.MouseButton1Click:Connect(function()
                        Dropdown.Open = not Dropdown.Open
                        listHolder.Visible = Dropdown.Open
                        arrow.Text = Dropdown.Open and "^" or "v"
                    end)
                    
                    function Dropdown:Set(value)
                        if table.find(self.Options, value) then
                            self.Value = value
                            selected.Text = value
                            if self.Callback then pcall(self.Callback, value) end
                        end
                    end
                    
                    function Dropdown:Get() return self.Value end
                    
                    table.insert(self.Controls, Dropdown)
                    return Dropdown
                end
                
                table.insert(self.Sections, Section)
                return Section
            end
            
            if SubTab.Index == 1 then
                Tab.ActiveSubTab = SubTab
            end
            
            table.insert(self.SubTabs, SubTab)
            return SubTab
        end
        
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
