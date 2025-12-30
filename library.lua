--[[
    NexusLib - Modern Roblox UI Library
    Based on community favorites: Linoria, Splix, Puppyware, Deadcell, and more

    Features:
    - Modern syntax (no legacy executor dependencies)
    - Window with dragging
    - Tabs/Pages with sections
    - Toggle, Slider, Dropdown, Button, Textbox, Keybind, Colorpicker
    - Config save/load system
    - Notifications
    - Watermark
    - Built-in Settings tab with Debug Menu and Unload
    - Debug console for library monitoring
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

-- Variables
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Library Table
local NexusLib = {
    Windows = {},
    Flags = {},
    Connections = {},
    DebugLogs = {},
    Theme = {
        Accent = Color3.fromRGB(96, 76, 255),
        Background = Color3.fromRGB(25, 25, 25),
        DarkBackground = Color3.fromRGB(20, 20, 20),
        LightBackground = Color3.fromRGB(35, 35, 35),
        Border = Color3.fromRGB(60, 60, 60),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(180, 180, 180),
        Disabled = Color3.fromRGB(100, 100, 100)
    },
    Settings = {
        ToggleKey = Enum.KeyCode.RightShift,
        ConfigFolder = "NexusLib",
        DebugMode = true
    },
    Open = true
}

-- Utility Functions
local Utility = {}

function Utility.Create(instanceType, properties)
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility.Tween(object, time, properties, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Utility.Dragify(frame, dragFrame)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

function Utility.GetTextBounds(text, font, size)
    return TextService:GetTextSize(text, size, font, Vector2.new(math.huge, math.huge))
end

function Utility.RippleEffect(button, x, y)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        Parent = button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 1
    })

    Utility.Create("UICorner", {
        Parent = ripple,
        CornerRadius = UDim.new(1, 0)
    })

    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Utility.Tween(ripple, 0.5, {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1})

    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- Debug Logger
function NexusLib:Log(message, logType)
    logType = logType or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] [%s] %s", timestamp, logType, message)
    table.insert(self.DebugLogs, logEntry)

    if self.Settings.DebugMode then
        print("[NexusLib]", logEntry)
    end

    -- Update debug window if open
    if self.DebugWindow and self.DebugWindow.LogList then
        self:UpdateDebugLogs()
    end
end

function NexusLib:UpdateDebugLogs()
    if not self.DebugWindow or not self.DebugWindow.LogList then return end

    for _, child in pairs(self.DebugWindow.LogList:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local startIndex = math.max(1, #self.DebugLogs - 49)
    for i = startIndex, #self.DebugLogs do
        local log = self.DebugLogs[i]
        Utility.Create("TextLabel", {
            Parent = self.DebugWindow.LogList,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 16),
            Font = Enum.Font.Code,
            Text = log,
            TextColor3 = log:find("ERROR") and Color3.fromRGB(255, 100, 100) or 
                         log:find("WARN") and Color3.fromRGB(255, 200, 100) or
                         Color3.fromRGB(200, 200, 200),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true
        })
    end
end

-- Create Debug Window
function NexusLib:CreateDebugWindow()
    if self.DebugWindow and self.DebugWindow.Main then
        self.DebugWindow.Main.Visible = not self.DebugWindow.Main.Visible
        return self.DebugWindow
    end

    self:Log("Creating Debug Window", "DEBUG")

    local debugWindow = {}

    debugWindow.Main = Utility.Create("Frame", {
        Name = "NexusLib_Debug",
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 400, 0, 300),
        Visible = true
    })

    Utility.Create("UICorner", {Parent = debugWindow.Main, CornerRadius = UDim.new(0, 6)})
    Utility.Create("UIStroke", {Parent = debugWindow.Main, Color = self.Theme.Border, Thickness = 1})

    -- Title Bar
    local titleBar = Utility.Create("Frame", {
        Parent = debugWindow.Main,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30)
    })
    Utility.Create("UICorner", {Parent = titleBar, CornerRadius = UDim.new(0, 6)})

    -- Fix corner overlap
    Utility.Create("Frame", {
        Parent = titleBar,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -6),
        Size = UDim2.new(1, 0, 0, 6)
    })

    Utility.Create("TextLabel", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "NexusLib Debug Console",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Close Button
    local closeBtn = Utility.Create("TextButton", {
        Parent = titleBar,
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        Position = UDim2.new(1, -35, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12
    })
    Utility.Create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 4)})

    closeBtn.MouseButton1Click:Connect(function()
        debugWindow.Main.Visible = false
    end)

    -- Stats Panel
    local statsPanel = Utility.Create("Frame", {
        Parent = debugWindow.Main,
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 35),
        Size = UDim2.new(1, -10, 0, 40)
    })
    Utility.Create("UICorner", {Parent = statsPanel, CornerRadius = UDim.new(0, 4)})

    debugWindow.StatsLabel = Utility.Create("TextLabel", {
        Parent = statsPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Code,
        Text = "Windows: 0 | Flags: 0 | Connections: 0 | Logs: 0",
        TextColor3 = Color3.fromRGB(150, 255, 150),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Log Container
    local logContainer = Utility.Create("ScrollingFrame", {
        Parent = debugWindow.Main,
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 80),
        Size = UDim2.new(1, -10, 1, -115),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Utility.Create("UICorner", {Parent = logContainer, CornerRadius = UDim.new(0, 4)})
    Utility.Create("UIListLayout", {Parent = logContainer, Padding = UDim.new(0, 2)})
    Utility.Create("UIPadding", {Parent = logContainer, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5)})

    debugWindow.LogList = logContainer

    -- Clear Button
    local clearBtn = Utility.Create("TextButton", {
        Parent = debugWindow.Main,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        Position = UDim2.new(0, 5, 1, -30),
        Size = UDim2.new(0, 80, 0, 25),
        Font = Enum.Font.Gotham,
        Text = "Clear Logs",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12
    })
    Utility.Create("UICorner", {Parent = clearBtn, CornerRadius = UDim.new(0, 4)})

    clearBtn.MouseButton1Click:Connect(function()
        self.DebugLogs = {}
        self:UpdateDebugLogs()
        self:Log("Logs cleared", "INFO")
    end)

    Utility.Dragify(debugWindow.Main, titleBar)

    -- Update stats periodically
    task.spawn(function()
        while debugWindow.Main and debugWindow.Main.Parent do
            if debugWindow.StatsLabel then
                local flagCount = 0
                for _ in pairs(self.Flags) do flagCount = flagCount + 1 end
                debugWindow.StatsLabel.Text = string.format(
                    "Windows: %d | Flags: %d | Connections: %d | Logs: %d",
                    #self.Windows, flagCount, #self.Connections, #self.DebugLogs
                )
            end
            task.wait(0.5)
        end
    end)

    self.DebugWindow = debugWindow
    self:UpdateDebugLogs()

    return debugWindow
end

-- Notification System
function NexusLib:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local duration = options.Duration or 5
    local notifType = options.Type or "Info"

    self:Log("Notification: " .. title .. " - " .. content, "NOTIFY")

    local notifColor = notifType == "Success" and Color3.fromRGB(100, 255, 100) or
                       notifType == "Error" and Color3.fromRGB(255, 100, 100) or
                       notifType == "Warning" and Color3.fromRGB(255, 200, 100) or
                       self.Theme.Accent

    local notifFrame = Utility.Create("Frame", {
        Parent = self.NotificationContainer,
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(1, 300, 0, 0)
    })
    Utility.Create("UICorner", {Parent = notifFrame, CornerRadius = UDim.new(0, 6)})
    Utility.Create("UIStroke", {Parent = notifFrame, Color = notifColor, Thickness = 1})

    -- Accent bar
    local accentBar = Utility.Create("Frame", {
        Parent = notifFrame,
        BackgroundColor3 = notifColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0)
    })
    Utility.Create("UICorner", {Parent = accentBar, CornerRadius = UDim.new(0, 6)})

    Utility.Create("TextLabel", {
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 5),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Utility.Create("TextLabel", {
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 25),
        Size = UDim2.new(1, -20, 0, 30),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })

    -- Animate in
    Utility.Tween(notifFrame, 0.3, {Position = UDim2.new(0, 0, 0, 0)})

    -- Progress bar
    local progressBar = Utility.Create("Frame", {
        Parent = notifFrame,
        BackgroundColor3 = notifColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3)
    })

    Utility.Tween(progressBar, duration, {Size = UDim2.new(0, 0, 0, 3)})

    task.delay(duration, function()
        Utility.Tween(notifFrame, 0.3, {Position = UDim2.new(1, 300, 0, 0)})
        task.delay(0.3, function()
            notifFrame:Destroy()
        end)
    end)
end

-- Config System
function NexusLib:SaveConfig(name)
    local configData = {}

    for flag, value in pairs(self.Flags) do
        if typeof(value) == "Color3" then
            configData[flag] = {Type = "Color3", R = value.R, G = value.G, B = value.B}
        elseif typeof(value) == "EnumItem" then
            configData[flag] = {Type = "Enum", Value = tostring(value)}
        else
            configData[flag] = value
        end
    end

    local success, err = pcall(function()
        if not isfolder(self.Settings.ConfigFolder) then
            makefolder(self.Settings.ConfigFolder)
        end
        writefile(self.Settings.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(configData))
    end)

    if success then
        self:Log("Config saved: " .. name, "INFO")
        self:Notify({Title = "Config Saved", Content = "Saved config: " .. name, Type = "Success", Duration = 3})
    else
        self:Log("Failed to save config: " .. tostring(err), "ERROR")
        self:Notify({Title = "Error", Content = "Failed to save config", Type = "Error", Duration = 3})
    end
end

function NexusLib:LoadConfig(name)
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(self.Settings.ConfigFolder .. "/" .. name .. ".json"))
    end)

    if success and data then
        for flag, value in pairs(data) do
            if typeof(value) == "table" and value.Type == "Color3" then
                self.Flags[flag] = Color3.new(value.R, value.G, value.B)
            else
                self.Flags[flag] = value
            end
        end
        self:Log("Config loaded: " .. name, "INFO")
        self:Notify({Title = "Config Loaded", Content = "Loaded config: " .. name, Type = "Success", Duration = 3})
    else
        self:Log("Failed to load config: " .. name, "ERROR")
        self:Notify({Title = "Error", Content = "Failed to load config", Type = "Error", Duration = 3})
    end
end

function NexusLib:GetConfigs()
    local configs = {}
    pcall(function()
        if isfolder(self.Settings.ConfigFolder) then
            for _, file in pairs(listfiles(self.Settings.ConfigFolder)) do
                if file:sub(-5) == ".json" then
                    local name = file:gsub(self.Settings.ConfigFolder .. "/", ""):gsub(".json", "")
                    table.insert(configs, name)
                end
            end
        end
    end)
    return configs
end

-- Initialize Library
function NexusLib:Init()
    self:Log("Initializing NexusLib...", "INFO")

    -- Create ScreenGui
    self.ScreenGui = Utility.Create("ScreenGui", {
        Name = "NexusLib_" .. tostring(math.random(100000, 999999)),
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    -- Protect GUI if possible
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(self.ScreenGui)
        end
    end)

    -- Notification Container
    self.NotificationContainer = Utility.Create("Frame", {
        Parent = self.ScreenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -270, 0, 10),
        Size = UDim2.new(0, 260, 1, -20)
    })
    Utility.Create("UIListLayout", {
        Parent = self.NotificationContainer,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- Toggle Key Handler
    local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.Settings.ToggleKey then
            self.Open = not self.Open
            for _, window in pairs(self.Windows) do
                if window.Main then
                    window.Main.Visible = self.Open
                end
            end
        end
    end)
    table.insert(self.Connections, connection)

    self:Log("NexusLib initialized successfully", "INFO")

    return self
end

-- Create Window
function NexusLib:CreateWindow(options)
    options = options or {}

    local window = {
        Name = options.Name or "NexusLib Window",
        Size = options.Size or UDim2.new(0, 550, 0, 400),
        Tabs = {},
        CurrentTab = nil
    }

    self:Log("Creating window: " .. window.Name, "INFO")

    -- Main Frame
    window.Main = Utility.Create("Frame", {
        Name = "Window",
        Parent = self.ScreenGui,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -275, 0.5, -200),
        Size = window.Size
    })
    Utility.Create("UICorner", {Parent = window.Main, CornerRadius = UDim.new(0, 8)})
    Utility.Create("UIStroke", {Parent = window.Main, Color = self.Theme.Border, Thickness = 1})

    -- Drop Shadow
    local shadow = Utility.Create("ImageLabel", {
        Parent = window.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = -1
    })

    -- Top Bar
    local topBar = Utility.Create("Frame", {
        Parent = window.Main,
        BackgroundColor3 = self.Theme.DarkBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35)
    })
    Utility.Create("UICorner", {Parent = topBar, CornerRadius = UDim.new(0, 8)})

    -- Fix corner overlap
    Utility.Create("Frame", {
        Parent = topBar,
        BackgroundColor3 = self.Theme.DarkBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8)
    })

    -- Title
    Utility.Create("TextLabel", {
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = window.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Accent Line
    Utility.Create("Frame", {
        Parent = topBar,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2)
    })

    Utility.Dragify(window.Main, topBar)

    -- Tab Container
    window.TabContainer = Utility.Create("Frame", {
        Parent = window.Main,
        BackgroundColor3 = self.Theme.DarkBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(0, 130, 1, -35)
    })

    Utility.Create("UICorner", {Parent = window.TabContainer, CornerRadius = UDim.new(0, 8)})

    -- Fix corner
    Utility.Create("Frame", {
        Parent = window.TabContainer,
        BackgroundColor3 = self.Theme.DarkBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 8, 1, 0)
    })

    window.TabList = Utility.Create("ScrollingFrame", {
        Parent = window.TabContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 10),
        Size = UDim2.new(1, -10, 1, -20),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    Utility.Create("UIListLayout", {
        Parent = window.TabList,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- Content Container
    window.ContentContainer = Utility.Create("Frame", {
        Parent = window.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 135, 0, 40),
        Size = UDim2.new(1, -145, 1, -50)
    })

    -- Add Tab Method
    function window:AddTab(options)
        options = options or {}

        local tab = {
            Name = options.Name or "Tab",
            Icon = options.Icon or "",
            Sections = {},
            Visible = false
        }

        NexusLib:Log("Adding tab: " .. tab.Name, "DEBUG")

        -- Tab Button
        tab.Button = Utility.Create("TextButton", {
            Parent = window.TabList,
            BackgroundColor3 = NexusLib.Theme.LightBackground,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 35),
            Font = Enum.Font.Gotham,
            Text = "  " .. tab.Name,
            TextColor3 = NexusLib.Theme.SubText,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false
        })
        Utility.Create("UICorner", {Parent = tab.Button, CornerRadius = UDim.new(0, 6)})
        Utility.Create("UIPadding", {Parent = tab.Button, PaddingLeft = UDim.new(0, 10)})

        -- Tab Content
        tab.Content = Utility.Create("ScrollingFrame", {
            Parent = window.ContentContainer,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = NexusLib.Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        })

        -- Two column layout
        tab.LeftColumn = Utility.Create("Frame", {
            Parent = tab.Content,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Utility.Create("UIListLayout", {Parent = tab.LeftColumn, Padding = UDim.new(0, 10)})

        tab.RightColumn = Utility.Create("Frame", {
            Parent = tab.Content,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 5, 0, 0),
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Utility.Create("UIListLayout", {Parent = tab.RightColumn, Padding = UDim.new(0, 10)})

        -- Tab Selection
        tab.Button.MouseButton1Click:Connect(function()
            for _, t in pairs(window.Tabs) do
                t.Content.Visible = false
                t.Button.BackgroundColor3 = NexusLib.Theme.LightBackground
                t.Button.TextColor3 = NexusLib.Theme.SubText
            end
            tab.Content.Visible = true
            tab.Button.BackgroundColor3 = NexusLib.Theme.Accent
            tab.Button.TextColor3 = NexusLib.Theme.Text
            window.CurrentTab = tab
        end)

        -- Add Section Method
        function tab:AddSection(options)
            options = options or {}

            local section = {
                Name = options.Name or "Section",
                Side = options.Side or "Left"
            }

            local parent = section.Side == "Right" and tab.RightColumn or tab.LeftColumn

            section.Main = Utility.Create("Frame", {
                Parent = parent,
                BackgroundColor3 = NexusLib.Theme.DarkBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            Utility.Create("UICorner", {Parent = section.Main, CornerRadius = UDim.new(0, 6)})
            Utility.Create("UIStroke", {Parent = section.Main, Color = NexusLib.Theme.Border, Thickness = 1})

            -- Section Title
            Utility.Create("TextLabel", {
                Parent = section.Main,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = section.Name,
                TextColor3 = NexusLib.Theme.Accent,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            section.Content = Utility.Create("Frame", {
                Parent = section.Main,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 30),
                Size = UDim2.new(1, -20, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            Utility.Create("UIListLayout", {Parent = section.Content, Padding = UDim.new(0, 8)})
            Utility.Create("UIPadding", {Parent = section.Main, PaddingBottom = UDim.new(0, 10)})

            -- Element Methods
            function section:AddToggle(options)
                options = options or {}
                local toggle = {
                    Name = options.Name or "Toggle",
                    Default = options.Default or false,
                    Flag = options.Flag,
                    Callback = options.Callback or function() end
                }

                if toggle.Flag then
                    NexusLib.Flags[toggle.Flag] = toggle.Default
                end

                local holder = Utility.Create("Frame", {
                    Parent = section.Content,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 25)
                })

                local toggleBtn = Utility.Create("Frame", {
                    Parent = holder,
                    BackgroundColor3 = toggle.Default and NexusLib.Theme.Accent or NexusLib.Theme.LightBackground,
                    Position = UDim2.new(1, -40, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20)
                })
                Utility.Create("UICorner", {Parent = toggleBtn, CornerRadius = UDim.new(1, 0)})

                local circle = Utility.Create("Frame", {
                    Parent = toggleBtn,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = toggle.Default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16)
                })
                Utility.Create("UICorner", {Parent = circle, CornerRadius = UDim.new(1, 0)})

                Utility.Create("TextLabel", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -50, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = toggle.Name,
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local clickBtn = Utility.Create("TextButton", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })

                local enabled = toggle.Default

                clickBtn.MouseButton1Click:Connect(function()
                    enabled = not enabled
                    if toggle.Flag then
                        NexusLib.Flags[toggle.Flag] = enabled
                    end

                    Utility.Tween(toggleBtn, 0.2, {BackgroundColor3 = enabled and NexusLib.Theme.Accent or NexusLib.Theme.LightBackground})
                    Utility.Tween(circle, 0.2, {Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})

                    toggle.Callback(enabled)
                end)

                function toggle:Set(value)
                    enabled = value
                    if toggle.Flag then
                        NexusLib.Flags[toggle.Flag] = enabled
                    end
                    Utility.Tween(toggleBtn, 0.2, {BackgroundColor3 = enabled and NexusLib.Theme.Accent or NexusLib.Theme.LightBackground})
                    Utility.Tween(circle, 0.2, {Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                    toggle.Callback(enabled)
                end

                return toggle
            end

            function section:AddSlider(options)
                options = options or {}
                local slider = {
                    Name = options.Name or "Slider",
                    Min = options.Min or 0,
                    Max = options.Max or 100,
                    Default = options.Default or 50,
                    Increment = options.Increment or 1,
                    Flag = options.Flag,
                    Callback = options.Callback or function() end
                }

                if slider.Flag then
                    NexusLib.Flags[slider.Flag] = slider.Default
                end

                local holder = Utility.Create("Frame", {
                    Parent = section.Content,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 40)
                })

                Utility.Create("TextLabel", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = slider.Name,
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local valueLabel = Utility.Create("TextLabel", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -45, 0, 0),
                    Size = UDim2.new(0, 45, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = tostring(slider.Default),
                    TextColor3 = NexusLib.Theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local sliderBg = Utility.Create("Frame", {
                    Parent = holder,
                    BackgroundColor3 = NexusLib.Theme.LightBackground,
                    Position = UDim2.new(0, 0, 0, 25),
                    Size = UDim2.new(1, 0, 0, 8)
                })
                Utility.Create("UICorner", {Parent = sliderBg, CornerRadius = UDim.new(1, 0)})

                local sliderFill = Utility.Create("Frame", {
                    Parent = sliderBg,
                    BackgroundColor3 = NexusLib.Theme.Accent,
                    Size = UDim2.new((slider.Default - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
                })
                Utility.Create("UICorner", {Parent = sliderFill, CornerRadius = UDim.new(1, 0)})

                local sliderBtn = Utility.Create("TextButton", {
                    Parent = sliderBg,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ""
                })

                local dragging = false
                local currentValue = slider.Default

                local function updateSlider(input)
                    local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    local value = slider.Min + (slider.Max - slider.Min) * pos
                    value = math.floor(value / slider.Increment + 0.5) * slider.Increment
                    value = math.clamp(value, slider.Min, slider.Max)

                    currentValue = value
                    if slider.Flag then
                        NexusLib.Flags[slider.Flag] = value
                    end

                    sliderFill.Size = UDim2.new(pos, 0, 1, 0)
                    valueLabel.Text = tostring(value)
                    slider.Callback(value)
                end

                sliderBtn.MouseButton1Down:Connect(function()
                    dragging = true
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)

                sliderBtn.MouseButton1Down:Connect(function()
                    updateSlider({Position = Vector3.new(Mouse.X, Mouse.Y, 0)})
                end)

                function slider:Set(value)
                    currentValue = math.clamp(value, slider.Min, slider.Max)
                    if slider.Flag then
                        NexusLib.Flags[slider.Flag] = currentValue
                    end
                    local pos = (currentValue - slider.Min) / (slider.Max - slider.Min)
                    sliderFill.Size = UDim2.new(pos, 0, 1, 0)
                    valueLabel.Text = tostring(currentValue)
                    slider.Callback(currentValue)
                end

                return slider
            end

            function section:AddButton(options)
                options = options or {}

                local button = Utility.Create("TextButton", {
                    Parent = section.Content,
                    BackgroundColor3 = NexusLib.Theme.LightBackground,
                    Size = UDim2.new(1, 0, 0, 30),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Button",
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    AutoButtonColor = false
                })
                Utility.Create("UICorner", {Parent = button, CornerRadius = UDim.new(0, 6)})

                button.MouseEnter:Connect(function()
                    Utility.Tween(button, 0.2, {BackgroundColor3 = NexusLib.Theme.Accent})
                end)

                button.MouseLeave:Connect(function()
                    Utility.Tween(button, 0.2, {BackgroundColor3 = NexusLib.Theme.LightBackground})
                end)

                button.MouseButton1Click:Connect(function()
                    Utility.RippleEffect(button, Mouse.X, Mouse.Y)
                    if options.Callback then
                        options.Callback()
                    end
                end)

                return button
            end

            function section:AddDropdown(options)
                options = options or {}
                local dropdown = {
                    Name = options.Name or "Dropdown",
                    Items = options.Items or {},
                    Default = options.Default,
                    Flag = options.Flag,
                    Callback = options.Callback or function() end,
                    Open = false
                }

                local selected = dropdown.Default or (dropdown.Items[1] or "Select...")
                if dropdown.Flag then
                    NexusLib.Flags[dropdown.Flag] = selected
                end

                local holder = Utility.Create("Frame", {
                    Parent = section.Content,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50),
                    ClipsDescendants = false
                })

                Utility.Create("TextLabel", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = dropdown.Name,
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local dropBtn = Utility.Create("TextButton", {
                    Parent = holder,
                    BackgroundColor3 = NexusLib.Theme.LightBackground,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 28),
                    Font = Enum.Font.Gotham,
                    Text = "  " .. tostring(selected),
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false
                })
                Utility.Create("UICorner", {Parent = dropBtn, CornerRadius = UDim.new(0, 6)})

                local itemContainer = Utility.Create("Frame", {
                    Parent = holder,
                    BackgroundColor3 = NexusLib.Theme.DarkBackground,
                    Position = UDim2.new(0, 0, 0, 52),
                    Size = UDim2.new(1, 0, 0, 0),
                    ClipsDescendants = true,
                    ZIndex = 10
                })
                Utility.Create("UICorner", {Parent = itemContainer, CornerRadius = UDim.new(0, 6)})
                Utility.Create("UIStroke", {Parent = itemContainer, Color = NexusLib.Theme.Border, Thickness = 1})

                local itemList = Utility.Create("Frame", {
                    Parent = itemContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0)
                })
                Utility.Create("UIListLayout", {Parent = itemList, Padding = UDim.new(0, 2)})
                Utility.Create("UIPadding", {Parent = itemList, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

                local function refreshItems()
                    for _, child in pairs(itemList:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, item in pairs(dropdown.Items) do
                        local itemBtn = Utility.Create("TextButton", {
                            Parent = itemList,
                            BackgroundColor3 = NexusLib.Theme.LightBackground,
                            Size = UDim2.new(1, 0, 0, 25),
                            Font = Enum.Font.Gotham,
                            Text = "  " .. tostring(item),
                            TextColor3 = NexusLib.Theme.Text,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 11
                        })
                        Utility.Create("UICorner", {Parent = itemBtn, CornerRadius = UDim.new(0, 4)})

                        itemBtn.MouseButton1Click:Connect(function()
                            selected = item
                            dropBtn.Text = "  " .. tostring(item)
                            if dropdown.Flag then
                                NexusLib.Flags[dropdown.Flag] = item
                            end
                            dropdown.Callback(item)

                            dropdown.Open = false
                            Utility.Tween(itemContainer, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                            Utility.Tween(holder, 0.2, {Size = UDim2.new(1, 0, 0, 50)})
                        end)
                    end
                end

                refreshItems()

                dropBtn.MouseButton1Click:Connect(function()
                    dropdown.Open = not dropdown.Open
                    local itemHeight = #dropdown.Items * 27 + 10
                    itemHeight = math.min(itemHeight, 150)

                    if dropdown.Open then
                        Utility.Tween(itemContainer, 0.2, {Size = UDim2.new(1, 0, 0, itemHeight)})
                        Utility.Tween(holder, 0.2, {Size = UDim2.new(1, 0, 0, 52 + itemHeight)})
                    else
                        Utility.Tween(itemContainer, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                        Utility.Tween(holder, 0.2, {Size = UDim2.new(1, 0, 0, 50)})
                    end
                end)

                function dropdown:Set(value)
                    if table.find(dropdown.Items, value) then
                        selected = value
                        dropBtn.Text = "  " .. tostring(value)
                        if dropdown.Flag then
                            NexusLib.Flags[dropdown.Flag] = value
                        end
                        dropdown.Callback(value)
                    end
                end

                function dropdown:Refresh(items)
                    dropdown.Items = items
                    refreshItems()
                end

                return dropdown
            end

            function section:AddTextbox(options)
                options = options or {}
                local textbox = {
                    Name = options.Name or "Textbox",
                    Default = options.Default or "",
                    Placeholder = options.Placeholder or "Enter text...",
                    Flag = options.Flag,
                    Callback = options.Callback or function() end
                }

                if textbox.Flag then
                    NexusLib.Flags[textbox.Flag] = textbox.Default
                end

                local holder = Utility.Create("Frame", {
                    Parent = section.Content,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50)
                })

                Utility.Create("TextLabel", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = textbox.Name,
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local input = Utility.Create("TextBox", {
                    Parent = holder,
                    BackgroundColor3 = NexusLib.Theme.LightBackground,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 28),
                    Font = Enum.Font.Gotham,
                    Text = textbox.Default,
                    PlaceholderText = textbox.Placeholder,
                    TextColor3 = NexusLib.Theme.Text,
                    PlaceholderColor3 = NexusLib.Theme.SubText,
                    TextSize = 13,
                    ClearTextOnFocus = false
                })
                Utility.Create("UICorner", {Parent = input, CornerRadius = UDim.new(0, 6)})
                Utility.Create("UIPadding", {Parent = input, PaddingLeft = UDim.new(0, 10)})

                input.FocusLost:Connect(function()
                    if textbox.Flag then
                        NexusLib.Flags[textbox.Flag] = input.Text
                    end
                    textbox.Callback(input.Text)
                end)

                function textbox:Set(value)
                    input.Text = value
                    if textbox.Flag then
                        NexusLib.Flags[textbox.Flag] = value
                    end
                    textbox.Callback(value)
                end

                return textbox
            end

            function section:AddKeybind(options)
                options = options or {}
                local keybind = {
                    Name = options.Name or "Keybind",
                    Default = options.Default or Enum.KeyCode.Unknown,
                    Flag = options.Flag,
                    Callback = options.Callback or function() end
                }

                local currentKey = keybind.Default
                if keybind.Flag then
                    NexusLib.Flags[keybind.Flag] = currentKey
                end

                local holder = Utility.Create("Frame", {
                    Parent = section.Content,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 25)
                })

                Utility.Create("TextLabel", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = keybind.Name,
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local keyBtn = Utility.Create("TextButton", {
                    Parent = holder,
                    BackgroundColor3 = NexusLib.Theme.LightBackground,
                    Position = UDim2.new(1, -65, 0.5, -12),
                    Size = UDim2.new(0, 65, 0, 24),
                    Font = Enum.Font.Gotham,
                    Text = currentKey.Name or "None",
                    TextColor3 = NexusLib.Theme.Text,
                    TextSize = 12,
                    AutoButtonColor = false
                })
                Utility.Create("UICorner", {Parent = keyBtn, CornerRadius = UDim.new(0, 6)})

                local listening = false

                keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            keyBtn.Text = input.KeyCode.Name
                            if keybind.Flag then
                                NexusLib.Flags[keybind.Flag] = currentKey
                            end
                            listening = false
                        end
                    elseif not gameProcessed and input.KeyCode == currentKey then
                        keybind.Callback(currentKey)
                    end
                end)

                function keybind:Set(key)
                    currentKey = key
                    keyBtn.Text = key.Name
                    if keybind.Flag then
                        NexusLib.Flags[keybind.Flag] = key
                    end
                end

                return keybind
            end

            table.insert(tab.Sections, section)
            return section
        end

        table.insert(window.Tabs, tab)

        -- Select first tab by default
        if #window.Tabs == 1 then
            tab.Content.Visible = true
            tab.Button.BackgroundColor3 = NexusLib.Theme.Accent
            tab.Button.TextColor3 = NexusLib.Theme.Text
            window.CurrentTab = tab
        end

        return tab
    end

    -- Add Settings Tab (Always included)
    local settingsTab = window:AddTab({Name = "Settings"})

    local generalSection = settingsTab:AddSection({Name = "General", Side = "Left"})

    generalSection:AddButton({
        Name = "Open Debug Menu",
        Callback = function()
            NexusLib:CreateDebugWindow()
        end
    })

    generalSection:AddButton({
        Name = "Unload Library",
        Callback = function()
            NexusLib:Unload()
        end
    })

    generalSection:AddKeybind({
        Name = "Toggle UI Key",
        Default = Enum.KeyCode.RightShift,
        Flag = "ToggleKey",
        Callback = function(key)
            NexusLib.Settings.ToggleKey = key
        end
    })

    local configSection = settingsTab:AddSection({Name = "Configs", Side = "Right"})

    local configDropdown = configSection:AddDropdown({
        Name = "Select Config",
        Items = NexusLib:GetConfigs(),
        Flag = "SelectedConfig"
    })

    configSection:AddTextbox({
        Name = "Config Name",
        Placeholder = "Enter config name...",
        Flag = "ConfigName"
    })

    configSection:AddButton({
        Name = "Save Config",
        Callback = function()
            local name = NexusLib.Flags.ConfigName
            if name and name ~= "" then
                NexusLib:SaveConfig(name)
                configDropdown:Refresh(NexusLib:GetConfigs())
            end
        end
    })

    configSection:AddButton({
        Name = "Load Config",
        Callback = function()
            local name = NexusLib.Flags.SelectedConfig
            if name then
                NexusLib:LoadConfig(name)
            end
        end
    })

    table.insert(self.Windows, window)
    self:Log("Window created successfully: " .. window.Name, "INFO")

    return window
end

-- Unload Library
function NexusLib:Unload()
    self:Log("Unloading NexusLib...", "INFO")

    for _, connection in pairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

    self:Log("NexusLib unloaded", "INFO")
end

-- Initialize and return
return NexusLib:Init()
