--[[ 
    GHACK OT UI Library
    Converted to Reusable Library
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // Configuration
local Config = {
    MenuKey = Enum.KeyCode.Insert,
    FadeTime = 0.2,
    FontMain = Enum.Font.Arial, 
    FontBold = Enum.Font.ArialBold,
    FontTiny = Enum.Font.Code,
    TextSize = 13,
    TinySize = 11
}

-- // Theme System
local Theme = {
    Accent = Color3.fromRGB(65, 140, 255),
    Main = Color3.fromRGB(20, 20, 20),
    Header = Color3.fromRGB(25, 25, 25),
    Sidebar = Color3.fromRGB(18, 18, 18),
    PanelBG = Color3.fromRGB(40, 40, 40),
    PanelTransparency = 0.5,
    BorderOuter = Color3.fromRGB(20, 20, 20),
    BorderInner = Color3.fromRGB(40, 40, 40),
    ElementBG = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(230, 230, 230),
    TextDim = Color3.fromRGB(130, 130, 130),
    GradientStart = Color3.fromRGB(50, 50, 50),
    GradientEnd = Color3.fromRGB(50, 50, 50)
}

local ThemeRegistry = {
    AccentFills = {},
    AccentTexts = {},
    ActiveTabButtons = {}
}

-- // Utility Functions
local function Create(class, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function AddStroke(parent, thickness, color)
    return Create("UIStroke", {
        Parent = parent,
        Thickness = thickness or 1,
        Color = color or Theme.BorderOuter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

local function AddTextOutline(textLabel)
    return Create("UIStroke", {
        Parent = textLabel,
        Thickness = 1,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    })
end

local function MakeDraggable(topbar, object)
    local Dragging, DragInput, DragStart, StartPosition

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
        end
    end)

    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = input end
    end)

    RunService.RenderStepped:Connect(function()
        if Dragging and DragInput then
            local Delta = DragInput.Position - DragStart
            object.Position = UDim2.new(
                StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
                StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
            )
        end
    end)
end

local function UpdateTheme(newColor)
    Theme.Accent = newColor
    -- Update Fills (Checkboxes, Slider bars)
    for _, item in pairs(ThemeRegistry.AccentFills) do
        if item.Instance and item.Instance.Parent then
            if item.Condition() then
                item.Instance.BackgroundColor3 = newColor
            end
        end
    end
    -- Update Texts (Titles, Active Items)
    for _, item in pairs(ThemeRegistry.AccentTexts) do
        if item.Instance and item.Instance.Parent then
            item.Instance.TextColor3 = newColor
        end
    end
    -- Update Tabs
    for _, item in pairs(ThemeRegistry.ActiveTabButtons) do
        if item.Button and item.Button.Parent and item.IsActive() then
            item.Button.TextColor3 = newColor
        end
    end
end

-- // Library
local Library = {}
Library.Open = true
Library.Gui = nil
Library.Theme = Theme 

function Library:Window(options)
    local Title = options.Title or "GHACK OT"
    local Keybind = options.Key or Config.MenuKey
    
    if game.CoreGui:FindFirstChild("GHackOT") then game.CoreGui.GHackOT:Destroy() end

    local ScreenGui = Create("ScreenGui", {
        Name = "GHackOT",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })
    Library.Gui = ScreenGui

    -- Main Container
    local Main = Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Main,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -325, 0.5, -225),
        Size = UDim2.new(0, 650, 0, 450)
    })
    AddStroke(Main, 2, Theme.BorderOuter)

    -- Top Bar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = Main,
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35)
    })
    
    -- Separator Line
    Create("Frame", {
        Parent = TopBar,
        BackgroundColor3 = Theme.BorderInner,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 5
    })

    -- Title
    local TitleLabel = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Font = Config.FontBold,
        Text = Title,
        TextColor3 = Theme.Accent,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    })
    AddTextOutline(TitleLabel)
    table.insert(ThemeRegistry.AccentTexts, {Instance = TitleLabel})

    -- Tabs Container
    local TabContainer = Create("Frame", {
        Name = "Tabs",
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 5),
        Size = UDim2.new(1, -5, 1, -5)
    })
    
    Create("UIListLayout", {
        Parent = TabContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })

    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Parent = Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 1, -35)
    })

    MakeDraggable(TopBar, Main)

    local function Toggle()
        Library.Open = not Library.Open
        ScreenGui.Enabled = Library.Open
    end

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Keybind then Toggle() end
    end)

    local Window = { Tabs = {}, ActiveTab = nil }

    function Window:Tab(name)
        local Tab = { SubTabs = {}, ActiveSubTab = nil }

        -- Tab Button
        local TabBtn = Create("TextButton", {
            Name = name,
            Parent = TabContainer,
            BackgroundColor3 = Theme.Main,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Config.FontMain,
            Text = "  " .. name .. "  ",
            TextColor3 = Theme.TextDim,
            TextSize = Config.TextSize,
            AutoButtonColor = false,
            ZIndex = 6
        })
        AddTextOutline(TabBtn)

        -- Tab Border Stroke
        local TabStroke = Create("UIStroke", {
            Parent = TabBtn,
            Thickness = 1,
            Color = Theme.BorderOuter,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Enabled = false
        })
        
        -- Cover Line (Hides separator)
        local CoverLine = Create("Frame", {
            Parent = TabBtn,
            BackgroundColor3 = Theme.Main,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 1, -1),
            Size = UDim2.new(1, -2, 0, 2),
            Visible = false,
            ZIndex = 10
        })

        local TabContent = Create("Frame", {
            Name = name .. "_Content",
            Parent = ContentArea,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false
        })

        -- Sidebar
        local Sidebar = Create("Frame", {
            Name = "Sidebar",
            Parent = TabContent,
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 130, 1, 0),
            ZIndex = 2
        })
        
        Create("Frame", {
            Parent = Sidebar,
            BackgroundColor3 = Theme.BorderInner,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -1, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 5
        })

        local SidebarButtonContainer = Create("Frame", {
            Name = "ButtonContainer",
            Parent = Sidebar,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -1, 1, 0)
        })

        Create("UIListLayout", {
            Parent = SidebarButtonContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0)
        })
        Create("UIPadding", { Parent = SidebarButtonContainer, PaddingTop = UDim.new(0, 10) })

        local PagesContainer = Create("Frame", {
            Name = "Pages",
            Parent = TabContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 140, 0, 10),
            Size = UDim2.new(1, -150, 1, -20)
        })

        TabBtn.MouseButton1Click:Connect(function()
            if Window.ActiveTab then
                Window.ActiveTab.Btn.TextColor3 = Theme.TextDim
                Window.ActiveTab.Btn.BackgroundTransparency = 1
                Window.ActiveTab.Stroke.Enabled = false
                Window.ActiveTab.Cover.Visible = false
                Window.ActiveTab.Content.Visible = false
            end
            
            Window.ActiveTab = { Btn = TabBtn, Content = TabContent, Stroke = TabStroke, Cover = CoverLine }
            
            TabBtn.TextColor3 = Theme.Accent
            TabBtn.BackgroundTransparency = 0
            TabStroke.Enabled = true
            CoverLine.Visible = true
            TabContent.Visible = true
        end)
        
        table.insert(ThemeRegistry.ActiveTabButtons, {
            Button = TabBtn,
            IsActive = function() return Window.ActiveTab and Window.ActiveTab.Btn == TabBtn end
        })

        if #Window.Tabs == 0 then
            Window.ActiveTab = { Btn = TabBtn, Content = TabContent, Stroke = TabStroke, Cover = CoverLine }
            TabBtn.TextColor3 = Theme.Accent
            TabBtn.BackgroundTransparency = 0
            TabStroke.Enabled = true
            CoverLine.Visible = true
            TabContent.Visible = true
        end
        table.insert(Window.Tabs, Tab)

        function Tab:SubTab(subName)
            local SubTab = {}
            
            local SubBtn = Create("TextButton", {
                Name = subName,
                Parent = SidebarButtonContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                Font = Config.FontMain,
                Text = "   " .. subName,
                TextColor3 = Theme.TextDim,
                TextSize = Config.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                ZIndex = 3
            })
            AddTextOutline(SubBtn)
            
            local GradientFrame = Create("Frame", {
                Parent = SubBtn,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 2
            })
            
            Create("UIGradient", {
                Parent = GradientFrame,
                Rotation = 0,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.GradientStart),
                    ColorSequenceKeypoint.new(1, Theme.GradientEnd)
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.4),
                    NumberSequenceKeypoint.new(1, 1)
                })
            })

            local Page = Create("ScrollingFrame", {
                Name = subName .. "_Page",
                Parent = PagesContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Accent,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(0, 0, 0, 0)
            })
            table.insert(ThemeRegistry.AccentFills, {Instance = Page, Condition = function() return false end}) -- Just to register Scrollbar, actually needs separate handling or simple ignore.

            local LeftCol = Create("Frame", {
                Name = "Left", Parent = Page, BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0, 0, 0, 0)
            })
            local RightCol = Create("Frame", {
                Name = "Right", Parent = Page, BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0)
            })

            Create("UIListLayout", { Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })
            Create("UIListLayout", { Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })

            local function UpdateSubTabVisuals()
                for _, child in pairs(SidebarButtonContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        local isThis = (child == SubBtn and Tab.ActiveSubTab and Tab.ActiveSubTab.Btn == SubBtn)
                        local grad = child:FindFirstChild("Frame")
                        if grad then grad.Visible = isThis end
                        child.TextColor3 = isThis and Color3.fromRGB(255, 255, 255) or Theme.TextDim
                    end
                end
            end

            SubBtn.MouseButton1Click:Connect(function()
                if Tab.ActiveSubTab then Tab.ActiveSubTab.Page.Visible = false end
                Tab.ActiveSubTab = { Btn = SubBtn, Page = Page }
                Page.Visible = true
                UpdateSubTabVisuals()
            end)

            if not Tab.ActiveSubTab then
                Tab.ActiveSubTab = { Btn = SubBtn, Page = Page }
                Page.Visible = true
                UpdateSubTabVisuals()
            end

            function SubTab:Section(secName, side)
                local ParentCol = (side == "Right") and RightCol or LeftCol
                
                local SectionFrame = Create("Frame", {
                    Name = secName,
                    Parent = ParentCol,
                    BackgroundColor3 = Theme.PanelBG,
                    BackgroundTransparency = Theme.PanelTransparency,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 20)
                })
                
                AddStroke(SectionFrame, 1, Theme.BorderOuter)
                local InnerBorder = Create("Frame", {
                    Parent = SectionFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    ZIndex = 2
                })
                AddStroke(InnerBorder, 1, Theme.BorderInner)

                local Title = Create("TextLabel", {
                    Parent = SectionFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -16, 0, 22),
                    Font = Config.FontBold,
                    Text = secName,
                    TextColor3 = Theme.Text,
                    TextSize = Config.TextSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 3
                })
                AddTextOutline(Title)

                Create("Frame", {
                    Parent = SectionFrame,
                    BackgroundColor3 = Theme.BorderInner,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 1),
                    ZIndex = 3
                })

                local Items = Create("Frame", {
                    Parent = SectionFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 28),
                    Size = UDim2.new(1, -16, 0, 0),
                    ZIndex = 3
                })
                
                local ItemLayout = Create("UIListLayout", {
                    Parent = Items,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5)
                })

                ItemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    Items.Size = UDim2.new(1, -16, 0, ItemLayout.AbsoluteContentSize.Y)
                    SectionFrame.Size = UDim2.new(1, 0, 0, ItemLayout.AbsoluteContentSize.Y + 34)
                    local maxH = math.max(LeftCol.UIListLayout.AbsoluteContentSize.Y, RightCol.UIListLayout.AbsoluteContentSize.Y)
                    Page.CanvasSize = UDim2.new(0, 0, 0, maxH + 10)
                end)

                local Elements = {}

                function Elements:OpenColorPicker(startColor, callback, relativeFrame)
                    if ScreenGui:FindFirstChild("ColorPickerWindow") then ScreenGui.ColorPickerWindow:Destroy() end
                    
                    local PickerWin = Create("Frame", {
                        Name = "ColorPickerWindow",
                        Parent = ScreenGui,
                        BackgroundColor3 = Theme.Main,
                        BorderSizePixel = 1,
                        BorderColor3 = Theme.BorderOuter,
                        Size = UDim2.new(0, 200, 0, 170),
                        Position = UDim2.new(0, relativeFrame.AbsolutePosition.X + 25, 0, relativeFrame.AbsolutePosition.Y),
                        ZIndex = 105
                    })
                    
                    local SV = Create("ImageButton", {
                        Parent = PickerWin, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, 10),
                        Size = UDim2.new(0, 150, 0, 150), Image = "rbxassetid://4155801252"
                    })
                    
                    local Hue = Create("ImageButton", {
                        Parent = PickerWin, BorderSizePixel = 0, Position = UDim2.new(0, 170, 0, 10),
                        Size = UDim2.new(0, 20, 0, 150), Image = "rbxassetid://4155801252"
                    })
                    Create("UIGradient", {
                        Parent = Hue, Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(1,1,1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(0,1,1))
                        })
                    })

                    local h, s, v = Color3.toHSV(startColor)
                    local draggingHue, draggingSV = false, false

                    local function Update()
                        local newColor = Color3.fromHSV(h, s, v)
                        SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        callback(newColor)
                    end

                    Hue.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end end)
                    SV.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true end end)
                    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false draggingSV = false end end)
                    
                    UserInputService.InputChanged:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseMovement then
                            if draggingHue then
                                local y = math.clamp((i.Position.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
                                h = 1 - y
                                Update()
                            elseif draggingSV then
                                local x = math.clamp((i.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                                local y = math.clamp((i.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                                s = x
                                v = 1 - y
                                Update()
                            end
                        end
                    end)
                    
                    local CloseBtn = Create("TextButton", {
                        Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ZIndex = 104, Text = ""
                    })
                    CloseBtn.MouseButton1Click:Connect(function() PickerWin:Destroy() CloseBtn:Destroy() end)
                end

                function Elements:Checkbox(text, default, callback)
                    local state = default or false
                    callback = callback or function() end

                    local CheckFrame = Create("TextButton", {
                        Parent = Items,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                        Text = "",
                        AutoButtonColor = false
                    })

                    local Box = Create("Frame", {
                        Parent = CheckFrame,
                        BackgroundColor3 = Theme.ElementBG,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0, 0, 0.5, -6)
                    })
                    AddStroke(Box, 1, Theme.BorderOuter)

                    local Label = Create("TextLabel", {
                        Parent = CheckFrame,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 18, 0, 0),
                        Size = UDim2.new(1, -18, 1, 0),
                        Font = Config.FontMain,
                        Text = text,
                        TextColor3 = Theme.TextDim,
                        TextSize = Config.TextSize,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    AddTextOutline(Label)

                    local function Update()
                        Box.BackgroundColor3 = state and Theme.Accent or Theme.ElementBG
                        Label.TextColor3 = state and Theme.Text or Theme.TextDim
                        callback(state)
                    end
                    
                    table.insert(ThemeRegistry.AccentFills, {
                        Instance = Box,
                        Condition = function() return state end
                    })

                    CheckFrame.MouseButton1Click:Connect(function()
                        state = not state
                        Update()
                    end)
                    Update()

                    local CheckboxAPI = {}
                    function CheckboxAPI:ColorPicker(defaultColor, colorCallback)
                        local color = defaultColor or Color3.new(1,1,1)
                        colorCallback = colorCallback or function() end
                        
                        local PickerBtn = Create("TextButton", {
                            Parent = CheckFrame,
                            BackgroundColor3 = color,
                            BorderSizePixel = 0,
                            Position = UDim2.new(1, -20, 0.5, -5),
                            Size = UDim2.new(0, 20, 0, 10),
                            Text = "",
                            AutoButtonColor = false
                        })
                        AddStroke(PickerBtn, 1, Theme.BorderOuter)

                        PickerBtn.MouseButton1Click:Connect(function()
                            Elements:OpenColorPicker(color, function(newC)
                                color = newC
                                PickerBtn.BackgroundColor3 = newC
                                colorCallback(newC)
                            end, PickerBtn)
                        end)
                    end
                    return CheckboxAPI
                end

                function Elements:Slider(text, min, max, default, suffix, callback)
                    local value = default or min
                    callback = callback or function() end
                    suffix = suffix or ""

                    local SliderFrame = Create("Frame", {
                        Parent = Items,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 32)
                    })

                    local Label = Create("TextLabel", {
                        Parent = SliderFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Font = Config.FontMain,
                        Text = text,
                        TextColor3 = Theme.TextDim,
                        TextSize = Config.TextSize,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    AddTextOutline(Label)

                    local Bar = Create("Frame", {
                        Parent = SliderFrame,
                        BackgroundColor3 = Theme.ElementBG,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0, 16),
                        Size = UDim2.new(1, 0, 0, 10)
                    })
                    AddStroke(Bar, 1, Theme.BorderOuter)

                    local Fill = Create("Frame", {
                        Parent = Bar,
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0,
                        Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
                    })
                    table.insert(ThemeRegistry.AccentFills, {Instance = Fill, Condition = function() return true end})

                    local ValLabel = Create("TextLabel", {
                        Parent = Bar,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = Config.FontTiny, 
                        Text = tostring(value) .. suffix,
                        TextColor3 = Color3.new(1,1,1),
                        TextSize = Config.TinySize,
                        ZIndex = 2
                    })
                    AddTextOutline(ValLabel)

                    local Trigger = Create("TextButton", {
                        Parent = Bar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = ""
                    })

                    local dragging = false
                    local function Update(input)
                        local percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        value = math.floor(min + (max - min) * percent)
                        Fill.Size = UDim2.new(percent, 0, 1, 0)
                        ValLabel.Text = tostring(value) .. suffix
                        callback(value)
                    end

                    Trigger.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            Update(input)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
                    end)
                end

                function Elements:Dropdown(text, items, default, callback)
                    local selected = default or items[1]
                    callback = callback or function() end
                    local open = false

                    local DropFrame = Create("Frame", {
                        Parent = Items,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        ZIndex = 10
                    })

                    local Label = Create("TextLabel", {
                        Parent = DropFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Font = Config.FontMain,
                        Text = text,
                        TextColor3 = Theme.TextDim,
                        TextSize = Config.TextSize,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    AddTextOutline(Label)

                    local Bar = Create("TextButton", {
                        Parent = DropFrame,
                        BackgroundColor3 = Theme.ElementBG,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0, 16),
                        Size = UDim2.new(1, 0, 0, 20),
                        AutoButtonColor = false,
                        Text = ""
                    })
                    AddStroke(Bar, 1, Theme.BorderOuter)

                    local SelectedText = Create("TextLabel", {
                        Parent = Bar,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 5, 0, 0),
                        Size = UDim2.new(1, -20, 1, 0),
                        Font = Config.FontMain,
                        Text = selected,
                        TextColor3 = Theme.Text,
                        TextSize = Config.TextSize,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    AddTextOutline(SelectedText)
                    
                    local Arrow = Create("TextLabel", {
                        Parent = Bar, BackgroundTransparency = 1, Position = UDim2.new(1, -15, 0, 0),
                        Size = UDim2.new(0, 15, 1, 0), Text = "v", TextColor3 = Theme.TextDim, TextSize = 10, Font = Config.FontMain
                    })
                    AddTextOutline(Arrow)

                    local List = Create("Frame", {
                        Parent = ScreenGui,
                        BackgroundColor3 = Theme.ElementBG,
                        BorderSizePixel = 1,
                        BorderColor3 = Theme.BorderOuter,
                        Visible = false,
                        ZIndex = 100
                    })
                    
                    Create("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder })

                    local function Toggle()
                        open = not open
                        List.Visible = open
                        if open then
                            for _, v in pairs(List:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                            List.Position = UDim2.new(0, Bar.AbsolutePosition.X, 0, Bar.AbsolutePosition.Y + Bar.AbsoluteSize.Y + 2)
                            List.Size = UDim2.new(0, Bar.AbsoluteSize.X, 0, #items * 20)

                            for _, item in pairs(items) do
                                local ItemBtn = Create("TextButton", {
                                    Parent = List,
                                    BackgroundColor3 = Theme.ElementBG,
                                    BorderSizePixel = 0,
                                    Size = UDim2.new(1, 0, 0, 20),
                                    Font = Config.FontMain,
                                    Text = "  " .. item,
                                    TextColor3 = (item == selected) and Theme.Accent or Theme.Text,
                                    TextSize = Config.TextSize,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    AutoButtonColor = false
                                })
                                AddTextOutline(ItemBtn)
                                
                                ItemBtn.MouseButton1Click:Connect(function()
                                    selected = item
                                    SelectedText.Text = item
                                    callback(item)
                                    Toggle()
                                end)
                            end
                        end
                    end
                    Bar.MouseButton1Click:Connect(Toggle)
                end

                function Elements:ColorPicker(text, default, callback)
                    local color = default or Color3.new(1,1,1)
                    callback = callback or function() end

                    local PickerFrame = Create("Frame", {
                        Parent = Items,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18)
                    })

                    local Label = Create("TextLabel", {
                        Parent = PickerFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -30, 1, 0),
                        Font = Config.FontMain,
                        Text = text,
                        TextColor3 = Theme.TextDim,
                        TextSize = Config.TextSize,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    AddTextOutline(Label)

                    local Preview = Create("TextButton", {
                        Parent = PickerFrame,
                        BackgroundColor3 = color,
                        BorderSizePixel = 0,
                        Position = UDim2.new(1, -25, 0, 2),
                        Size = UDim2.new(0, 25, 0, 14),
                        Text = "",
                        AutoButtonColor = false
                    })
                    AddStroke(Preview, 1, Theme.BorderOuter)

                    Preview.MouseButton1Click:Connect(function()
                        Elements:OpenColorPicker(color, function(newC)
                            color = newC
                            Preview.BackgroundColor3 = newC
                            callback(newC)
                        end, Preview)
                    end)
                end

                function Elements:Button(text, callback)
                    callback = callback or function() end
                    local BtnFrame = Create("Frame", {
                        Parent = Items,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 24)
                    })

                    local Btn = Create("TextButton", {
                        Parent = BtnFrame,
                        BackgroundColor3 = Theme.ElementBG,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = Config.FontMain,
                        Text = text,
                        TextColor3 = Theme.Text,
                        TextSize = Config.TextSize,
                        AutoButtonColor = false
                    })
                    AddStroke(Btn, 1, Theme.BorderOuter)
                    AddTextOutline(Btn)

                    Btn.MouseButton1Click:Connect(callback)
                    Btn.MouseButton1Down:Connect(function() Btn.BackgroundColor3 = Theme.Accent end)
                    Btn.MouseButton1Up:Connect(function() Btn.BackgroundColor3 = Theme.ElementBG end)
                end

                return Elements
            end
            return SubTab
        end
        return Tab
    end
    
    function Library:Unload()
        if Library.Gui then Library.Gui:Destroy() end
        Library.Open = false
    end

    function Library:SetAccent(color)
        UpdateTheme(color)
    end

    return Window
end

return Library
