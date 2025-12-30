--[[
    GHACK OT UI Library
    Roblox recreation of GMod GHack menu
]]

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Theme = {
    Accent = Color3.fromRGB(0, 170, 255),
    AccentDark = Color3.fromRGB(0, 120, 200),
    
    Background = Color3.fromRGB(22, 22, 22),
    BackgroundDark = Color3.fromRGB(18, 18, 18),
    BackgroundLight = Color3.fromRGB(30, 30, 30),
    
    Panel = Color3.fromRGB(26, 26, 26),
    PanelLight = Color3.fromRGB(35, 35, 35),
    
    Border = Color3.fromRGB(45, 45, 45),
    BorderDark = Color3.fromRGB(15, 15, 15),
    
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 160),
    
    Control = Color3.fromRGB(35, 35, 35),
    ControlHover = Color3.fromRGB(45, 45, 45),
}

Library.Windows = {}
Library.Connections = {}
Library.ToggleKey = Enum.KeyCode.RightShift
Library.Theme = Theme

local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function AddConnection(conn)
    table.insert(Library.Connections, conn)
    return conn
end

function Library:CreateWindow(title)
    local Window = {
        Title = title or "GHACK OT",
        Tabs = {},
        ActiveTab = nil,
        Visible = false,
    }
    
    Window.GUI = Create("ScreenGui", {
        Name = "GHackUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() Window.GUI.Parent = CoreGui end)
    if not Window.GUI.Parent then
        Window.GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    Window.Main = Create("Frame", {
        Size = UDim2.new(0, 580, 0, 420),
        Position = UDim2.new(0.5, -290, 0.5, -210),
        BackgroundColor3 = Theme.BorderDark,
        BorderSizePixel = 0,
        Visible = false,
        Parent = Window.GUI
    })
    
    local inner1 = Create("Frame", {
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
        Parent = inner1
    })
    
    Window.TitleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.BackgroundDark,
        BorderSizePixel = 0,
        Parent = Window.Container
    })
    
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = Window.TitleBar
    })
    
    Create("TextLabel", {
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = Window.Title,
        TextColor3 = Theme.Accent,
        Font = Enum.Font.SourceSansBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Window.TitleBar
    })
    
    Window.TabBar = Create("Frame", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 100, 0, 0),
        BackgroundTransparency = 1,
        Parent = Window.TitleBar
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = Window.TabBar
    })
    Create("UIPadding", {PaddingRight = UDim.new(0, 8), Parent = Window.TabBar})
    
    Window.Sidebar = Create("Frame", {
        Size = UDim2.new(0, 90, 1, -23),
        Position = UDim2.new(0, 0, 0, 23),
        BackgroundColor3 = Theme.BackgroundDark,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Window.Container
    })
    
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = Window.Sidebar
    })
    
    Window.Content = Create("Frame", {
        Size = UDim2.new(1, -91, 1, -23),
        Position = UDim2.new(0, 91, 0, 23),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Window.Container
    })
    
    -- Dragging
    local dragging, dragStart, startPos = false, nil, nil
    AddConnection(Window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Window.Main.Position
        end
    end))
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
    
    AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Window.Visible = not Window.Visible
            Window.Main.Visible = Window.Visible
        end
    end))
    
    function Window:Show() self.Visible = true self.Main.Visible = true end
    function Window:Hide() self.Visible = false self.Main.Visible = false end
    
    function Window:SelectTab(tab)
        if self.ActiveTab == tab then return end
        if self.ActiveTab then
            self.ActiveTab.Button.TextColor3 = Theme.Text
            self.ActiveTab.SubTabHolder.Visible = false
            self.ActiveTab.ContentHolder.Visible = false
        end
        self.ActiveTab = tab
        tab.Button.TextColor3 = Theme.Accent
        tab.SubTabHolder.Visible = true
        tab.ContentHolder.Visible = true
    end
    
    function Window:AddTab(name)
        local Tab = {Name = name, SubTabs = {}, ActiveSubTab = nil, Index = #self.Tabs + 1}
        
        Tab.Button = Create("TextButton", {
            Size = UDim2.new(0, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Tab.Index == 1 and Theme.Accent or Theme.Text,
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            LayoutOrder = Tab.Index,
            Parent = self.TabBar
        })
        
        Tab.SubTabHolder = Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = Tab.Index == 1,
            Parent = self.Sidebar
        })
        Create("UIListLayout", {Padding = UDim.new(0, 1), Parent = Tab.SubTabHolder})
        Create("UIPadding", {PaddingTop = UDim.new(0, 4), Parent = Tab.SubTabHolder})
        
        Tab.ContentHolder = Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = Tab.Index == 1,
            Parent = self.Content
        })
        
        Tab.Button.MouseButton1Click:Connect(function() self:SelectTab(Tab) end)
        Tab.Button.MouseEnter:Connect(function() if self.ActiveTab ~= Tab then Tab.Button.TextColor3 = Theme.Accent end end)
        Tab.Button.MouseLeave:Connect(function() if self.ActiveTab ~= Tab then Tab.Button.TextColor3 = Theme.Text end end)
        
        function Tab:SelectSubTab(subtab)
            if self.ActiveSubTab == subtab then return end
            if self.ActiveSubTab then
                self.ActiveSubTab.AccentLine.BackgroundTransparency = 1
                self.ActiveSubTab.Button.TextColor3 = Theme.TextDim
                self.ActiveSubTab.Content.Visible = false
            end
            self.ActiveSubTab = subtab
            subtab.AccentLine.BackgroundTransparency = 0
            subtab.Button.TextColor3 = Theme.Accent
            subtab.Content.Visible = true
        end
        
        function Tab:AddSubTab(subName)
            local SubTab = {Name = subName, Sections = {}, Index = #self.SubTabs + 1}
            
            SubTab.Holder = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                LayoutOrder = SubTab.Index,
                Parent = self.SubTabHolder
            })
            
            SubTab.AccentLine = Create("Frame", {
                Size = UDim2.new(0, 2, 1, -4),
                Position = UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = SubTab.Index == 1 and 0 or 1,
                BorderSizePixel = 0,
                Parent = SubTab.Holder
            })
            
            SubTab.Button = Create("TextButton", {
                Size = UDim2.new(1, -8, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = subName,
                TextColor3 = SubTab.Index == 1 and Theme.Accent or Theme.TextDim,
                Font = Enum.Font.SourceSans,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SubTab.Holder
            })
            
            SubTab.Content = Create("ScrollingFrame", {
                Size = UDim2.new(1, -8, 1, -8),
                Position = UDim2.new(0, 4, 0, 4),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = SubTab.Index == 1,
                Parent = self.ContentHolder
            })
            
            Create("UIGridLayout", {
                CellSize = UDim2.new(0, 225, 0, 0),
                CellPadding = UDim2.new(0, 8, 0, 8),
                FillDirection = Enum.FillDirection.Horizontal,
                FillDirectionMaxCells = 2,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SubTab.Content
            })
            
            SubTab.Button.MouseButton1Click:Connect(function() self:SelectSubTab(SubTab) end)
            SubTab.Button.MouseEnter:Connect(function() if self.ActiveSubTab ~= SubTab then SubTab.Button.TextColor3 = Theme.Text end end)
            SubTab.Button.MouseLeave:Connect(function() if self.ActiveSubTab ~= SubTab then SubTab.Button.TextColor3 = Theme.TextDim end end)
            
            function SubTab:AddSection(secName)
                local Section = {Name = secName, Controls = {}, Index = #self.Sections + 1}
                
                Section.Frame = Create("Frame", {
                    Size = UDim2.new(0, 225, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    LayoutOrder = Section.Index,
                    Parent = self.Content
                })
                Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = Section.Frame})
                Create("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = Section.Frame})
                Create("TextLabel", {Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 0, 2), BackgroundTransparency = 1, Text = secName, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = Section.Frame})
                Create("Frame", {Size = UDim2.new(1, -8, 0, 1), Position = UDim2.new(0, 4, 0, 20), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = Section.Frame})
                
                Section.Container = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 24),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Parent = Section.Frame
                })
                Create("UIListLayout", {Padding = UDim.new(0, 2), Parent = Section.Container})
                Create("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = Section.Container})
                
                function Section:AddToggle(opts)
                    local Toggle = {Value = opts.Default or false, Callback = opts.Callback}
                    local h = Create("Frame", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = #self.Controls + 1, Parent = self.Container})
                    local box = Create("Frame", {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 0, 0.5, -5), BackgroundColor3 = Toggle.Value and Theme.Accent or Theme.Control, BorderSizePixel = 0, Parent = h})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = box})
                    Create("TextLabel", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1, Text = opts.Name, TextColor3 = opts.Risky and Color3.fromRGB(200, 200, 100) or Theme.Text, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = h})
                    local btn = Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = h})
                    btn.MouseButton1Click:Connect(function()
                        Toggle.Value = not Toggle.Value
                        box.BackgroundColor3 = Toggle.Value and Theme.Accent or Theme.Control
                        if Toggle.Callback then pcall(Toggle.Callback, Toggle.Value) end
                    end)
                    function Toggle:Set(v) self.Value = v box.BackgroundColor3 = v and Theme.Accent or Theme.Control if self.Callback then pcall(self.Callback, v) end end
                    function Toggle:Get() return self.Value end
                    table.insert(self.Controls, Toggle)
                    return Toggle
                end
                
                function Section:AddSlider(opts)
                    local Slider = {Value = opts.Default or opts.Min or 0, Min = opts.Min or 0, Max = opts.Max or 100, Decimals = opts.Decimals or 0, Suffix = opts.Suffix or "", Callback = opts.Callback}
                    local h = Create("Frame", {Size = UDim2.new(1, 0, 0, opts.Name and 30 or 16), BackgroundTransparency = 1, LayoutOrder = #self.Controls + 1, Parent = self.Container})
                    local yOff = 0
                    if opts.Name then
                        Create("TextLabel", {Size = UDim2.new(1, -40, 0, 14), BackgroundTransparency = 1, Text = opts.Name, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = h})
                        yOff = 14
                    end
                    local valueBox = Create("Frame", {Size = UDim2.new(0, 36, 0, 14), Position = UDim2.new(1, -36, 0, yOff), BackgroundColor3 = Theme.Control, BorderSizePixel = 0, Parent = h})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = valueBox})
                    local valueLabel = Create("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(Slider.Value) .. Slider.Suffix, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 12, Parent = valueBox})
                    local bar = Create("Frame", {Size = UDim2.new(1, -44, 0, 12), Position = UDim2.new(0, 0, 0, yOff + 1), BackgroundColor3 = Theme.Control, BorderSizePixel = 0, Parent = h})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = bar})
                    local pct = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    local fill = Create("Frame", {Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar})
                    local function update(input)
                        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        local val = Slider.Min + (Slider.Max - Slider.Min) * rel
                        if Slider.Decimals == 0 then val = math.floor(val + 0.5) else val = math.floor(val * 10^Slider.Decimals + 0.5) / 10^Slider.Decimals end
                        Slider.Value = val
                        fill.Size = UDim2.new(rel, 0, 1, 0)
                        valueLabel.Text = tostring(val) .. Slider.Suffix
                        if Slider.Callback then pcall(Slider.Callback, val) end
                    end
                    local sliding = false
                    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true update(input) end end)
                    AddConnection(UserInputService.InputChanged:Connect(function(input) if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end))
                    AddConnection(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end))
                    function Slider:Set(v) self.Value = math.clamp(v, self.Min, self.Max) local p = (self.Value - self.Min) / (self.Max - self.Min) fill.Size = UDim2.new(p, 0, 1, 0) valueLabel.Text = tostring(self.Value) .. self.Suffix if self.Callback then pcall(self.Callback, self.Value) end end
                    function Slider:Get() return self.Value end
                    table.insert(self.Controls, Slider)
                    return Slider
                end
                
                function Section:AddDropdown(opts)
                    local Dropdown = {Value = opts.Default or (opts.Options and opts.Options[1]) or "", Options = opts.Options or {}, Callback = opts.Callback, Open = false}
                    local h = Create("Frame", {Size = UDim2.new(1, 0, 0, opts.Name and 32 or 16), BackgroundTransparency = 1, ClipsDescendants = false, LayoutOrder = #self.Controls + 1, Parent = self.Container})
                    local yOff = 0
                    if opts.Name then
                        Create("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = opts.Name, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = h})
                        yOff = 14
                    end
                    local box = Create("Frame", {Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, yOff), BackgroundColor3 = Theme.Control, BorderSizePixel = 0, ZIndex = 5, Parent = h})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = box})
                    local sel = Create("TextLabel", {Size = UDim2.new(1, -18, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = Dropdown.Value, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = box})
                    local arrow = Create("TextLabel", {Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, Text = "v", TextColor3 = Theme.TextDim, Font = Enum.Font.SourceSans, TextSize = 10, ZIndex = 6, Parent = box})
                    local dbtn = Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 7, Parent = box})
                    local list = Create("Frame", {Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Options * 16, 80)), Position = UDim2.new(0, 0, 1, 1), BackgroundColor3 = Theme.Control, BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = box})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = list})
                    Create("UIListLayout", {Padding = UDim.new(0, 0), Parent = list})
                    for _, opt in ipairs(Dropdown.Options) do
                        local ob = Create("TextButton", {Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = Theme.Control, BorderSizePixel = 0, Text = "", ZIndex = 11, Parent = list})
                        Create("TextLabel", {Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = opt, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12, Parent = ob})
                        ob.MouseEnter:Connect(function() ob.BackgroundColor3 = Theme.ControlHover end)
                        ob.MouseLeave:Connect(function() ob.BackgroundColor3 = Theme.Control end)
                        ob.MouseButton1Click:Connect(function() Dropdown.Value = opt sel.Text = opt Dropdown.Open = false list.Visible = false arrow.Text = "v" if Dropdown.Callback then pcall(Dropdown.Callback, opt) end end)
                    end
                    dbtn.MouseButton1Click:Connect(function() Dropdown.Open = not Dropdown.Open list.Visible = Dropdown.Open arrow.Text = Dropdown.Open and "^" or "v" end)
                    function Dropdown:Set(v) if table.find(self.Options, v) then self.Value = v sel.Text = v if self.Callback then pcall(self.Callback, v) end end end
                    function Dropdown:Get() return self.Value end
                    table.insert(self.Controls, Dropdown)
                    return Dropdown
                end
                
                function Section:AddColorPicker(opts)
                    local ColorPicker = {Value = opts.Default or Color3.fromRGB(255, 255, 255), Callback = opts.Callback}
                    local h = Create("Frame", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = #self.Controls + 1, Parent = self.Container})
                    Create("TextLabel", {Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = opts.Name, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = h})
                    local colorBox = Create("Frame", {Size = UDim2.new(0, 18, 0, 12), Position = UDim2.new(1, -18, 0.5, -6), BackgroundColor3 = ColorPicker.Value, BorderSizePixel = 0, Parent = h})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = colorBox})
                    function ColorPicker:Set(c) self.Value = c colorBox.BackgroundColor3 = c if self.Callback then pcall(self.Callback, c) end end
                    function ColorPicker:Get() return self.Value end
                    table.insert(self.Controls, ColorPicker)
                    return ColorPicker
                end
                
                function Section:AddButton(opts)
                    local Button = {Callback = opts.Callback}
                    local h = Create("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = #self.Controls + 1, Parent = self.Container})
                    local bg = Create("Frame", {Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = Theme.Control, BorderSizePixel = 0, Parent = h})
                    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = bg})
                    local btn = Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = opts.Name, TextColor3 = Theme.Text, Font = Enum.Font.SourceSans, TextSize = 13, Parent = bg})
                    btn.MouseEnter:Connect(function() bg.BackgroundColor3 = Theme.ControlHover end)
                    btn.MouseLeave:Connect(function() bg.BackgroundColor3 = Theme.Control end)
                    btn.MouseButton1Click:Connect(function() if Button.Callback then pcall(Button.Callback) end end)
                    table.insert(self.Controls, Button)
                    return Button
                end
                
                table.insert(self.Sections, Section)
                return Section
            end
            
            if SubTab.Index == 1 then Tab.ActiveSubTab = SubTab end
            table.insert(self.SubTabs, SubTab)
            return SubTab
        end
        
        if Tab.Index == 1 then self.ActiveTab = Tab end
        table.insert(self.Tabs, Tab)
        return Tab
    end
    
    table.insert(Library.Windows, Window)
    return Window
end

return Library
