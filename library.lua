--[[
    Custom UI Library
    A comprehensive drawing-based UI library combining the best design patterns
    Features: Theming, Notifications, Watermark, Indicators, Full Element Suite
]]

local library = {
    windows = {},
    flags = {},
    options = {},
    connections = {},
    drawings = {},
    notifications = {},
    themes = {},
    open = false,
    hasInit = false,
    toggleKey = Enum.KeyCode.RightShift,
    cheatname = "CustomLib",
    gamename = "Universal"
}

-- Services
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local runservice = game:GetService("RunService")
local tweenservice = game:GetService("TweenService")
local httpservice = game:GetService("HttpService")
local coregui = game:GetService("CoreGui")

local localplayer = players.LocalPlayer
local mouse = localplayer:GetMouse()
local camera = workspace.CurrentCamera

-- Math shortcuts
local floor, ceil, clamp, huge = math.floor, math.ceil, math.clamp, math.huge
local fromRGB, fromHSV, newColor3 = Color3.fromRGB, Color3.fromHSV, Color3.new

-- Default Theme
library.theme = {
    Accent = fromRGB(138, 92, 224),
    AccentDark = fromRGB(98, 62, 184),
    Background = fromRGB(18, 18, 22),
    BackgroundAlt = fromRGB(24, 24, 30),
    Topbar = fromRGB(12, 12, 16),
    Section = fromRGB(20, 20, 26),
    Element = fromRGB(28, 28, 36),
    ElementBorder = fromRGB(40, 40, 52),
    Text = fromRGB(240, 240, 240),
    SubText = fromRGB(180, 180, 180),
    Disabled = fromRGB(100, 100, 100),
    Success = fromRGB(80, 200, 120),
    Warning = fromRGB(255, 180, 50),
    Error = fromRGB(240, 80, 80),
    Outline = fromRGB(45, 45, 60),
    Shadow = fromRGB(0, 0, 0)
}

-- Preset Themes
library.themes = {
    {
        name = "Default",
        theme = {
            Accent = fromRGB(138, 92, 224),
            AccentDark = fromRGB(98, 62, 184),
            Background = fromRGB(18, 18, 22),
            BackgroundAlt = fromRGB(24, 24, 30),
            Topbar = fromRGB(12, 12, 16),
            Section = fromRGB(20, 20, 26),
            Element = fromRGB(28, 28, 36),
            ElementBorder = fromRGB(40, 40, 52),
            Text = fromRGB(240, 240, 240),
            SubText = fromRGB(180, 180, 180),
            Disabled = fromRGB(100, 100, 100),
            Outline = fromRGB(45, 45, 60)
        }
    },
    {
        name = "Midnight",
        theme = {
            Accent = fromRGB(103, 89, 179),
            AccentDark = fromRGB(73, 59, 149),
            Background = fromRGB(22, 22, 31),
            BackgroundAlt = fromRGB(28, 28, 40),
            Topbar = fromRGB(16, 16, 24),
            Section = fromRGB(24, 25, 37),
            Element = fromRGB(32, 33, 48),
            ElementBorder = fromRGB(50, 50, 70),
            Text = fromRGB(235, 235, 235),
            SubText = fromRGB(175, 175, 185),
            Disabled = fromRGB(95, 95, 110),
            Outline = fromRGB(50, 50, 65)
        }
    },
    {
        name = "Rose",
        theme = {
            Accent = fromRGB(226, 80, 130),
            AccentDark = fromRGB(186, 50, 100),
            Background = fromRGB(20, 18, 20),
            BackgroundAlt = fromRGB(28, 24, 28),
            Topbar = fromRGB(14, 12, 14),
            Section = fromRGB(24, 20, 24),
            Element = fromRGB(34, 28, 34),
            ElementBorder = fromRGB(55, 45, 55),
            Text = fromRGB(245, 240, 245),
            SubText = fromRGB(190, 180, 190),
            Disabled = fromRGB(110, 100, 110),
            Outline = fromRGB(50, 42, 50)
        }
    },
    {
        name = "Ocean",
        theme = {
            Accent = fromRGB(60, 165, 220),
            AccentDark = fromRGB(40, 125, 180),
            Background = fromRGB(16, 20, 26),
            BackgroundAlt = fromRGB(22, 28, 36),
            Topbar = fromRGB(10, 14, 20),
            Section = fromRGB(18, 24, 32),
            Element = fromRGB(26, 34, 44),
            ElementBorder = fromRGB(42, 54, 68),
            Text = fromRGB(235, 245, 255),
            SubText = fromRGB(170, 190, 210),
            Disabled = fromRGB(90, 105, 120),
            Outline = fromRGB(40, 52, 65)
        }
    },
    {
        name = "Emerald",
        theme = {
            Accent = fromRGB(80, 200, 120),
            AccentDark = fromRGB(50, 160, 90),
            Background = fromRGB(16, 22, 18),
            BackgroundAlt = fromRGB(22, 30, 24),
            Topbar = fromRGB(10, 16, 12),
            Section = fromRGB(18, 26, 20),
            Element = fromRGB(26, 36, 28),
            ElementBorder = fromRGB(42, 58, 46),
            Text = fromRGB(235, 250, 240),
            SubText = fromRGB(170, 200, 180),
            Disabled = fromRGB(90, 115, 100),
            Outline = fromRGB(38, 55, 42)
        }
    }
}

-- Utility Functions
local utility = {}
library.utility = utility

function utility:Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in next, properties or {} do
        pcall(function()
            instance[prop] = value
        end)
    end
    return instance
end

function utility:Tween(object, properties, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = tweenservice:Create(object, info, properties)
    tween:Play()
    return tween
end

function utility:Lerp(a, b, t)
    return a + (b - a) * t
end

function utility:RGBToTable(color)
    return {
        R = floor(color.R * 255),
        G = floor(color.G * 255),
        B = floor(color.B * 255)
    }
end

function utility:TableToRGB(tbl)
    return fromRGB(tbl.R or 255, tbl.G or 255, tbl.B or 255)
end

function utility:Darken(color, amount)
    local h, s, v = color:ToHSV()
    return fromHSV(h, s, clamp(v - amount, 0, 1))
end

function utility:Lighten(color, amount)
    local h, s, v = color:ToHSV()
    return fromHSV(h, s, clamp(v + amount, 0, 1))
end

function utility:MouseOverFrame(frame)
    local mousePos = uis:GetMouseLocation()
    local framePos = frame.AbsolutePosition
    local frameSize = frame.AbsoluteSize
    return mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X
       and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
end

function utility:Ripple(button, color)
    local ripple = utility:Create("Frame", {
        Name = "Ripple",
        Parent = button,
        BackgroundColor3 = color or library.theme.Accent,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, mouse.X - button.AbsolutePosition.X, 0, mouse.Y - button.AbsolutePosition.Y - 36),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = button.ZIndex + 1,
        AnchorPoint = Vector2.new(0.5, 0.5)
    })

    utility:Create("UICorner", {Parent = ripple, CornerRadius = UDim.new(1, 0)})

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    utility:Tween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)

    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- Dragging System
function utility:Dragify(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    uis.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Notification System
function library:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 4
    local notifType = config.Type or "Info"

    local typeColors = {
        Info = library.theme.Accent,
        Success = library.theme.Success,
        Warning = library.theme.Warning,
        Error = library.theme.Error
    }

    local screenGui = coregui:FindFirstChild("CustomLibNotifications") or utility:Create("ScreenGui", {
        Name = "CustomLibNotifications",
        Parent = coregui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local holder = screenGui:FindFirstChild("Holder") or utility:Create("Frame", {
        Name = "Holder",
        Parent = screenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -40),
        AnchorPoint = Vector2.new(1, 1)
    })

    if not holder:FindFirstChild("UIListLayout") then
        utility:Create("UIListLayout", {
            Parent = holder,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8)
        })
    end

    local notification = utility:Create("Frame", {
        Name = "Notification",
        Parent = holder,
        BackgroundColor3 = library.theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        LayoutOrder = -tick()
    })

    utility:Create("UICorner", {Parent = notification, CornerRadius = UDim.new(0, 6)})
    utility:Create("UIStroke", {Parent = notification, Color = library.theme.Outline, Thickness = 1})

    local accentBar = utility:Create("Frame", {
        Name = "AccentBar",
        Parent = notification,
        BackgroundColor3 = typeColors[notifType] or library.theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0)
    })

    utility:Create("UICorner", {Parent = accentBar, CornerRadius = UDim.new(0, 6)})

    local titleLabel = utility:Create("TextLabel", {
        Name = "Title",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = library.theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local contentLabel = utility:Create("TextLabel", {
        Name = "Content",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -24, 0, 30),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = library.theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })

    local progressBar = utility:Create("Frame", {
        Name = "Progress",
        Parent = notification,
        BackgroundColor3 = typeColors[notifType] or library.theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2)
    })

    -- Animate in
    utility:Tween(notification, {Size = UDim2.new(1, 0, 0, 70)}, 0.3)

    -- Progress and close
    utility:Tween(progressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration)

    task.delay(duration, function()
        utility:Tween(notification, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        notification:Destroy()
    end)

    return notification
end

-- Window Creation
function library:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Custom Library"
    local windowSize = config.Size or UDim2.new(0, 620, 0, 480)
    local windowPosition = config.Position or UDim2.new(0.5, -310, 0.5, -240)

    local window = {
        tabs = {},
        selectedTab = nil,
        open = true,
        objects = {}
    }

    table.insert(library.windows, window)

    -- Create Main GUI
    local screenGui = utility:Create("ScreenGui", {
        Name = "CustomLibrary_" .. windowTitle,
        Parent = coregui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    end

    window.screenGui = screenGui

    -- Main Frame
    local mainFrame = utility:Create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        BackgroundColor3 = library.theme.Background,
        BorderSizePixel = 0,
        Position = windowPosition,
        Size = windowSize,
        ClipsDescendants = true
    })
    window.objects.mainFrame = mainFrame

    utility:Create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0, 8)})
    utility:Create("UIStroke", {Parent = mainFrame, Color = library.theme.Outline, Thickness = 1})

    -- Shadow
    local shadow = utility:Create("ImageLabel", {
        Name = "Shadow",
        Parent = mainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = 0,
        Image = "rbxassetid://6014261993",
        ImageColor3 = library.theme.Shadow,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450)
    })

    -- Topbar
    local topbar = utility:Create("Frame", {
        Name = "Topbar",
        Parent = mainFrame,
        BackgroundColor3 = library.theme.Topbar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36)
    })

    utility:Create("UICorner", {Parent = topbar, CornerRadius = UDim.new(0, 8)})

    -- Cover bottom corners of topbar
    utility:Create("Frame", {
        Name = "CornerCover",
        Parent = topbar,
        BackgroundColor3 = library.theme.Topbar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8)
    })

    -- Accent line under topbar
    local accentLine = utility:Create("Frame", {
        Name = "AccentLine",
        Parent = topbar,
        BackgroundColor3 = library.theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2)
    })
    window.objects.accentLine = accentLine

    -- Title
    local titleLabel = utility:Create("TextLabel", {
        Name = "Title",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = windowTitle,
        TextColor3 = library.theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Close button
    local closeBtn = utility:Create("TextButton", {
        Name = "CloseBtn",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -36, 0, 0),
        Size = UDim2.new(0, 36, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = library.theme.SubText,
        TextSize = 24
    })

    closeBtn.MouseEnter:Connect(function()
        utility:Tween(closeBtn, {TextColor3 = library.theme.Error}, 0.15)
    end)

    closeBtn.MouseLeave:Connect(function()
        utility:Tween(closeBtn, {TextColor3 = library.theme.SubText}, 0.15)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        window:SetVisible(false)
    end)

    -- Minimize button
    local minBtn = utility:Create("TextButton", {
        Name = "MinBtn",
        Parent = topbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -68, 0, 0),
        Size = UDim2.new(0, 32, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = library.theme.SubText,
        TextSize = 16
    })

    minBtn.MouseEnter:Connect(function()
        utility:Tween(minBtn, {TextColor3 = library.theme.Warning}, 0.15)
    end)

    minBtn.MouseLeave:Connect(function()
        utility:Tween(minBtn, {TextColor3 = library.theme.SubText}, 0.15)
    end)

    -- Make draggable
    utility:Dragify(mainFrame, topbar)

    -- Tab Container (left side)
    local tabContainer = utility:Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = mainFrame,
        BackgroundColor3 = library.theme.BackgroundAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(0, 140, 1, -36),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    utility:Create("UIListLayout", {
        Parent = tabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })

    utility:Create("UIPadding", {
        Parent = tabContainer,
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    })

    window.objects.tabContainer = tabContainer

    -- Content Container
    local contentContainer = utility:Create("Frame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 148, 0, 44),
        Size = UDim2.new(1, -156, 1, -52)
    })

    window.objects.contentContainer = contentContainer

    -- Tab creation function
    function window:CreateTab(config)
        config = config or {}
        local tabName = config.Name or "Tab"
        local tabIcon = config.Icon or ""

        local tab = {
            name = tabName,
            sections = {},
            objects = {}
        }

        table.insert(window.tabs, tab)

        -- Tab Button
        local tabButton = utility:Create("TextButton", {
            Name = tabName,
            Parent = tabContainer,
            BackgroundColor3 = library.theme.Element,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.Gotham,
            Text = "",
            AutoButtonColor = false
        })
        tab.objects.button = tabButton

        utility:Create("UICorner", {Parent = tabButton, CornerRadius = UDim.new(0, 6)})

        -- Tab Icon (optional)
        if tabIcon ~= "" then
            utility:Create("ImageLabel", {
                Name = "Icon",
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = tabIcon,
                ImageColor3 = library.theme.SubText
            })
        end

        -- Tab Label
        local tabLabel = utility:Create("TextLabel", {
            Name = "Label",
            Parent = tabButton,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, tabIcon ~= "" and 32 or 12, 0, 0),
            Size = UDim2.new(1, tabIcon ~= "" and -44 or -24, 1, 0),
            Font = Enum.Font.Gotham,
            Text = tabName,
            TextColor3 = library.theme.SubText,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        tab.objects.label = tabLabel

        -- Accent indicator
        local accentIndicator = utility:Create("Frame", {
            Name = "Indicator",
            Parent = tabButton,
            BackgroundColor3 = library.theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.1, 0),
            Size = UDim2.new(0, 3, 0.8, 0),
            Visible = false
        })
        tab.objects.indicator = accentIndicator

        utility:Create("UICorner", {Parent = accentIndicator, CornerRadius = UDim.new(0, 2)})

        -- Tab Content Frame
        local tabContent = utility:Create("ScrollingFrame", {
            Name = tabName .. "Content",
            Parent = contentContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = library.theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        })
        tab.objects.content = tabContent

        -- Two column layout
        local leftColumn = utility:Create("Frame", {
            Name = "LeftColumn",
            Parent = tabContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0.5, -6, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })

        utility:Create("UIListLayout", {
            Parent = leftColumn,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12)
        })

        local rightColumn = utility:Create("Frame", {
            Name = "RightColumn",
            Parent = tabContent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 6, 0, 0),
            Size = UDim2.new(0.5, -6, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        })

        utility:Create("UIListLayout", {
            Parent = rightColumn,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12)
        })

        tab.objects.leftColumn = leftColumn
        tab.objects.rightColumn = rightColumn

        -- Tab selection
        local function selectTab()
            -- Deselect all tabs
            for _, t in ipairs(window.tabs) do
                t.objects.content.Visible = false
                t.objects.indicator.Visible = false
                utility:Tween(t.objects.button, {BackgroundColor3 = library.theme.Element}, 0.15)
                utility:Tween(t.objects.label, {TextColor3 = library.theme.SubText}, 0.15)
            end

            -- Select this tab
            tab.objects.content.Visible = true
            tab.objects.indicator.Visible = true
            utility:Tween(tab.objects.button, {BackgroundColor3 = library.theme.Section}, 0.15)
            utility:Tween(tab.objects.label, {TextColor3 = library.theme.Text}, 0.15)

            window.selectedTab = tab
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        tabButton.MouseEnter:Connect(function()
            if window.selectedTab ~= tab then
                utility:Tween(tabButton, {BackgroundColor3 = utility:Lighten(library.theme.Element, 0.05)}, 0.15)
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if window.selectedTab ~= tab then
                utility:Tween(tabButton, {BackgroundColor3 = library.theme.Element}, 0.15)
            end
        end)

        -- Select first tab by default
        if #window.tabs == 1 then
            selectTab()
        end

        -- Section creation
        function tab:CreateSection(config)
            config = config or {}
            local sectionName = config.Name or "Section"
            local sectionSide = config.Side or "Left"

            local section = {
                name = sectionName,
                elements = {},
                objects = {}
            }

            table.insert(tab.sections, section)

            local column = sectionSide == "Right" and rightColumn or leftColumn

            -- Section Frame
            local sectionFrame = utility:Create("Frame", {
                Name = sectionName,
                Parent = column,
                BackgroundColor3 = library.theme.Section,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            section.objects.frame = sectionFrame

            utility:Create("UICorner", {Parent = sectionFrame, CornerRadius = UDim.new(0, 6)})
            utility:Create("UIStroke", {Parent = sectionFrame, Color = library.theme.ElementBorder, Thickness = 1})

            -- Section Header
            local header = utility:Create("Frame", {
                Name = "Header",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 32)
            })

            utility:Create("TextLabel", {
                Name = "Title",
                Parent = header,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = sectionName,
                TextColor3 = library.theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            -- Accent line under header
            utility:Create("Frame", {
                Name = "HeaderLine",
                Parent = header,
                BackgroundColor3 = library.theme.Accent,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 1, -1),
                Size = UDim2.new(0, 40, 0, 2)
            })

            -- Element Container
            local elementContainer = utility:Create("Frame", {
                Name = "Elements",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            section.objects.elements = elementContainer

            utility:Create("UIListLayout", {
                Parent = elementContainer,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            })

            utility:Create("UIPadding", {
                Parent = elementContainer,
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10)
            })

            -- Toggle Element
            function section:CreateToggle(config)
                config = config or {}
                local toggleName = config.Name or "Toggle"
                local toggleDefault = config.Default or false
                local toggleCallback = config.Callback or function() end
                local toggleFlag = config.Flag

                local toggle = {
                    value = toggleDefault,
                    objects = {}
                }

                table.insert(section.elements, toggle)

                if toggleFlag then
                    library.flags[toggleFlag] = toggleDefault
                    library.options[toggleFlag] = toggle
                end

                local toggleFrame = utility:Create("Frame", {
                    Name = toggleName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })

                local toggleButton = utility:Create("TextButton", {
                    Name = "Button",
                    Parent = toggleFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    AutoButtonColor = false
                })

                local toggleBox = utility:Create("Frame", {
                    Name = "Box",
                    Parent = toggleButton,
                    BackgroundColor3 = toggleDefault and library.theme.Accent or library.theme.Element,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0.5, -9),
                    Size = UDim2.new(0, 18, 0, 18)
                })
                toggle.objects.box = toggleBox

                utility:Create("UICorner", {Parent = toggleBox, CornerRadius = UDim.new(0, 4)})
                utility:Create("UIStroke", {Parent = toggleBox, Color = library.theme.ElementBorder, Thickness = 1})

                -- Checkmark
                local checkmark = utility:Create("ImageLabel", {
                    Name = "Checkmark",
                    Parent = toggleBox,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, -6, 0.5, -6),
                    Size = UDim2.new(0, 12, 0, 12),
                    Image = "rbxassetid://6031094678",
                    ImageColor3 = library.theme.Text,
                    ImageTransparency = toggleDefault and 0 or 1
                })
                toggle.objects.checkmark = checkmark

                local toggleLabel = utility:Create("TextLabel", {
                    Name = "Label",
                    Parent = toggleButton,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 28, 0, 0),
                    Size = UDim2.new(1, -28, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = toggleName,
                    TextColor3 = library.theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                function toggle:Set(value)
                    toggle.value = value
                    if toggleFlag then
                        library.flags[toggleFlag] = value
                    end

                    utility:Tween(toggleBox, {
                        BackgroundColor3 = value and library.theme.Accent or library.theme.Element
                    }, 0.15)
                    utility:Tween(checkmark, {
                        ImageTransparency = value and 0 or 1
                    }, 0.15)

                    pcall(toggleCallback, value)
                end

                toggleButton.MouseButton1Click:Connect(function()
                    toggle:Set(not toggle.value)
                end)

                toggleButton.MouseEnter:Connect(function()
                    utility:Tween(toggleLabel, {TextColor3 = library.theme.Text}, 0.15)
                end)

                toggleButton.MouseLeave:Connect(function()
                    utility:Tween(toggleLabel, {TextColor3 = library.theme.SubText}, 0.15)
                end)

                return toggle
            end

            -- Slider Element
            function section:CreateSlider(config)
                config = config or {}
                local sliderName = config.Name or "Slider"
                local sliderMin = config.Min or 0
                local sliderMax = config.Max or 100
                local sliderDefault = config.Default or sliderMin
                local sliderIncrement = config.Increment or 1
                local sliderSuffix = config.Suffix or ""
                local sliderCallback = config.Callback or function() end
                local sliderFlag = config.Flag

                local slider = {
                    value = sliderDefault,
                    min = sliderMin,
                    max = sliderMax,
                    objects = {}
                }

                table.insert(section.elements, slider)

                if sliderFlag then
                    library.flags[sliderFlag] = sliderDefault
                    library.options[sliderFlag] = slider
                end

                local sliderFrame = utility:Create("Frame", {
                    Name = sliderName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 42)
                })

                local sliderLabel = utility:Create("TextLabel", {
                    Name = "Label",
                    Parent = sliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(0.6, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = sliderName,
                    TextColor3 = library.theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local valueLabel = utility:Create("TextLabel", {
                    Name = "Value",
                    Parent = sliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.6, 0, 0, 0),
                    Size = UDim2.new(0.4, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = tostring(sliderDefault) .. sliderSuffix,
                    TextColor3 = library.theme.Accent,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                slider.objects.valueLabel = valueLabel

                local sliderBar = utility:Create("Frame", {
                    Name = "Bar",
                    Parent = sliderFrame,
                    BackgroundColor3 = library.theme.Element,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 24),
                    Size = UDim2.new(1, 0, 0, 14)
                })
                slider.objects.bar = sliderBar

                utility:Create("UICorner", {Parent = sliderBar, CornerRadius = UDim.new(0, 6)})

                local sliderFill = utility:Create("Frame", {
                    Name = "Fill",
                    Parent = sliderBar,
                    BackgroundColor3 = library.theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((sliderDefault - sliderMin) / (sliderMax - sliderMin), 0, 1, 0)
                })
                slider.objects.fill = sliderFill

                utility:Create("UICorner", {Parent = sliderFill, CornerRadius = UDim.new(0, 6)})

                -- Slider interaction
                local dragging = false

                local function updateSlider(input)
                    local barPos = sliderBar.AbsolutePosition.X
                    local barSize = sliderBar.AbsoluteSize.X
                    local mouseX = input.Position.X

                    local percent = clamp((mouseX - barPos) / barSize, 0, 1)
                    local value = sliderMin + (sliderMax - sliderMin) * percent
                    value = math.floor(value / sliderIncrement + 0.5) * sliderIncrement

                    slider:Set(value)
                end

                sliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateSlider(input)
                    end
                end)

                uis.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                uis.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                        updateSlider(input)
                    end
                end)

                function slider:Set(value)
                    value = clamp(value, sliderMin, sliderMax)
                    slider.value = value

                    if sliderFlag then
                        library.flags[sliderFlag] = value
                    end

                    local percent = (value - sliderMin) / (sliderMax - sliderMin)
                    utility:Tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
                    valueLabel.Text = tostring(value) .. sliderSuffix

                    pcall(sliderCallback, value)
                end

                return slider
            end

            -- Dropdown Element
            function section:CreateDropdown(config)
                config = config or {}
                local dropdownName = config.Name or "Dropdown"
                local dropdownOptions = config.Options or {}
                local dropdownDefault = config.Default
                local dropdownMulti = config.Multi or false
                local dropdownCallback = config.Callback or function() end
                local dropdownFlag = config.Flag

                local dropdown = {
                    value = dropdownMulti and {} or dropdownDefault,
                    options = dropdownOptions,
                    open = false,
                    objects = {}
                }

                table.insert(section.elements, dropdown)

                if dropdownFlag then
                    library.flags[dropdownFlag] = dropdown.value
                    library.options[dropdownFlag] = dropdown
                end

                local dropdownFrame = utility:Create("Frame", {
                    Name = dropdownName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 54),
                    ClipsDescendants = false
                })
                dropdown.objects.frame = dropdownFrame

                local dropdownLabel = utility:Create("TextLabel", {
                    Name = "Label",
                    Parent = dropdownFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = dropdownName,
                    TextColor3 = library.theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local dropdownButton = utility:Create("TextButton", {
                    Name = "Button",
                    Parent = dropdownFrame,
                    BackgroundColor3 = library.theme.Element,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 28),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    AutoButtonColor = false
                })
                dropdown.objects.button = dropdownButton

                utility:Create("UICorner", {Parent = dropdownButton, CornerRadius = UDim.new(0, 4)})
                utility:Create("UIStroke", {Parent = dropdownButton, Color = library.theme.ElementBorder, Thickness = 1})

                local selectedLabel = utility:Create("TextLabel", {
                    Name = "Selected",
                    Parent = dropdownButton,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -36, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = dropdownDefault or "Select...",
                    TextColor3 = dropdownDefault and library.theme.Text or library.theme.Disabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                dropdown.objects.selected = selectedLabel

                local arrowIcon = utility:Create("ImageLabel", {
                    Name = "Arrow",
                    Parent = dropdownButton,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -24, 0.5, -6),
                    Size = UDim2.new(0, 12, 0, 12),
                    Image = "rbxassetid://6031091004",
                    ImageColor3 = library.theme.SubText,
                    Rotation = 0
                })
                dropdown.objects.arrow = arrowIcon

                -- Options container
                local optionsFrame = utility:Create("Frame", {
                    Name = "Options",
                    Parent = dropdownFrame,
                    BackgroundColor3 = library.theme.Element,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 54),
                    Size = UDim2.new(1, 0, 0, 0),
                    ClipsDescendants = true,
                    ZIndex = 10,
                    Visible = false
                })
                dropdown.objects.optionsFrame = optionsFrame

                utility:Create("UICorner", {Parent = optionsFrame, CornerRadius = UDim.new(0, 4)})
                utility:Create("UIStroke", {Parent = optionsFrame, Color = library.theme.Accent, Thickness = 1})

                local optionsList = utility:Create("Frame", {
                    Name = "List",
                    Parent = optionsFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0)
                })

                utility:Create("UIListLayout", {
                    Parent = optionsList,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2)
                })

                utility:Create("UIPadding", {
                    Parent = optionsList,
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4)
                })

                local function refreshOptions()
                    for _, child in ipairs(optionsList:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for i, option in ipairs(dropdown.options) do
                        local optionButton = utility:Create("TextButton", {
                            Name = option,
                            Parent = optionsList,
                            BackgroundColor3 = library.theme.Section,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 24),
                            Font = Enum.Font.Gotham,
                            Text = option,
                            TextColor3 = library.theme.SubText,
                            TextSize = 12,
                            LayoutOrder = i,
                            AutoButtonColor = false
                        })

                        utility:Create("UICorner", {Parent = optionButton, CornerRadius = UDim.new(0, 4)})

                        optionButton.MouseEnter:Connect(function()
                            utility:Tween(optionButton, {
                                BackgroundTransparency = 0,
                                TextColor3 = library.theme.Text
                            }, 0.1)
                        end)

                        optionButton.MouseLeave:Connect(function()
                            local isSelected = dropdownMulti and table.find(dropdown.value, option) or dropdown.value == option
                            utility:Tween(optionButton, {
                                BackgroundTransparency = isSelected and 0.5 or 1,
                                TextColor3 = isSelected and library.theme.Accent or library.theme.SubText
                            }, 0.1)
                        end)

                        optionButton.MouseButton1Click:Connect(function()
                            if dropdownMulti then
                                if table.find(dropdown.value, option) then
                                    table.remove(dropdown.value, table.find(dropdown.value, option))
                                else
                                    table.insert(dropdown.value, option)
                                end
                                selectedLabel.Text = #dropdown.value > 0 and table.concat(dropdown.value, ", ") or "Select..."
                            else
                                dropdown.value = option
                                selectedLabel.Text = option
                                dropdown:Toggle()
                            end

                            selectedLabel.TextColor3 = library.theme.Text

                            if dropdownFlag then
                                library.flags[dropdownFlag] = dropdown.value
                            end

                            pcall(dropdownCallback, dropdown.value)
                        end)
                    end
                end

                refreshOptions()

                function dropdown:Toggle()
                    dropdown.open = not dropdown.open

                    local targetHeight = dropdown.open and math.min(#dropdown.options * 26 + 10, 200) or 0

                    optionsFrame.Visible = true
                    utility:Tween(optionsFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
                    utility:Tween(arrowIcon, {Rotation = dropdown.open and 180 or 0}, 0.2)
                    utility:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, dropdown.open and 54 + targetHeight + 4 or 54)}, 0.2)

                    if not dropdown.open then
                        task.delay(0.2, function()
                            optionsFrame.Visible = false
                        end)
                    end
                end

                function dropdown:Set(value)
                    dropdown.value = value
                    if dropdownMulti then
                        selectedLabel.Text = #value > 0 and table.concat(value, ", ") or "Select..."
                    else
                        selectedLabel.Text = value or "Select..."
                    end
                    selectedLabel.TextColor3 = value and library.theme.Text or library.theme.Disabled

                    if dropdownFlag then
                        library.flags[dropdownFlag] = value
                    end
                    pcall(dropdownCallback, value)
                end

                function dropdown:Refresh(options)
                    dropdown.options = options
                    refreshOptions()
                end

                dropdownButton.MouseButton1Click:Connect(function()
                    dropdown:Toggle()
                end)

                return dropdown
            end

            -- Button Element
            function section:CreateButton(config)
                config = config or {}
                local buttonName = config.Name or "Button"
                local buttonCallback = config.Callback or function() end

                local button = {
                    objects = {}
                }

                table.insert(section.elements, button)

                local buttonFrame = utility:Create("Frame", {
                    Name = buttonName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32)
                })

                local buttonObj = utility:Create("TextButton", {
                    Name = "Button",
                    Parent = buttonFrame,
                    BackgroundColor3 = library.theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = buttonName,
                    TextColor3 = library.theme.Text,
                    TextSize = 13,
                    AutoButtonColor = false,
                    ClipsDescendants = true
                })
                button.objects.button = buttonObj

                utility:Create("UICorner", {Parent = buttonObj, CornerRadius = UDim.new(0, 6)})

                buttonObj.MouseEnter:Connect(function()
                    utility:Tween(buttonObj, {BackgroundColor3 = utility:Lighten(library.theme.Accent, 0.1)}, 0.15)
                end)

                buttonObj.MouseLeave:Connect(function()
                    utility:Tween(buttonObj, {BackgroundColor3 = library.theme.Accent}, 0.15)
                end)

                buttonObj.MouseButton1Click:Connect(function()
                    utility:Ripple(buttonObj)
                    pcall(buttonCallback)
                end)

                return button
            end

            -- Textbox Element
            function section:CreateTextbox(config)
                config = config or {}
                local textboxName = config.Name or "Textbox"
                local textboxDefault = config.Default or ""
                local textboxPlaceholder = config.Placeholder or "Enter text..."
                local textboxCallback = config.Callback or function() end
                local textboxFlag = config.Flag

                local textbox = {
                    value = textboxDefault,
                    objects = {}
                }

                table.insert(section.elements, textbox)

                if textboxFlag then
                    library.flags[textboxFlag] = textboxDefault
                    library.options[textboxFlag] = textbox
                end

                local textboxFrame = utility:Create("Frame", {
                    Name = textboxName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 54)
                })

                utility:Create("TextLabel", {
                    Name = "Label",
                    Parent = textboxFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = textboxName,
                    TextColor3 = library.theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local inputFrame = utility:Create("Frame", {
                    Name = "InputFrame",
                    Parent = textboxFrame,
                    BackgroundColor3 = library.theme.Element,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 28)
                })

                utility:Create("UICorner", {Parent = inputFrame, CornerRadius = UDim.new(0, 4)})
                local stroke = utility:Create("UIStroke", {Parent = inputFrame, Color = library.theme.ElementBorder, Thickness = 1})

                local inputBox = utility:Create("TextBox", {
                    Name = "Input",
                    Parent = inputFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = textboxDefault,
                    PlaceholderText = textboxPlaceholder,
                    PlaceholderColor3 = library.theme.Disabled,
                    TextColor3 = library.theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false
                })
                textbox.objects.input = inputBox

                inputBox.Focused:Connect(function()
                    utility:Tween(stroke, {Color = library.theme.Accent}, 0.15)
                end)

                inputBox.FocusLost:Connect(function(enterPressed)
                    utility:Tween(stroke, {Color = library.theme.ElementBorder}, 0.15)
                    textbox.value = inputBox.Text

                    if textboxFlag then
                        library.flags[textboxFlag] = inputBox.Text
                    end

                    pcall(textboxCallback, inputBox.Text, enterPressed)
                end)

                function textbox:Set(value)
                    textbox.value = value
                    inputBox.Text = value
                    if textboxFlag then
                        library.flags[textboxFlag] = value
                    end
                end

                return textbox
            end

            -- Keybind Element
            function section:CreateKeybind(config)
                config = config or {}
                local keybindName = config.Name or "Keybind"
                local keybindDefault = config.Default or Enum.KeyCode.Unknown
                local keybindCallback = config.Callback or function() end
                local keybindFlag = config.Flag

                local keybind = {
                    value = keybindDefault,
                    binding = false,
                    objects = {}
                }

                table.insert(section.elements, keybind)

                if keybindFlag then
                    library.flags[keybindFlag] = keybindDefault
                    library.options[keybindFlag] = keybind
                end

                local keybindFrame = utility:Create("Frame", {
                    Name = keybindName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })

                utility:Create("TextLabel", {
                    Name = "Label",
                    Parent = keybindFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = keybindName,
                    TextColor3 = library.theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local keybindButton = utility:Create("TextButton", {
                    Name = "Keybind",
                    Parent = keybindFrame,
                    BackgroundColor3 = library.theme.Element,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.6, 0, 0, 0),
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = keybindDefault.Name ~= "Unknown" and keybindDefault.Name or "None",
                    TextColor3 = library.theme.SubText,
                    TextSize = 11,
                    AutoButtonColor = false
                })
                keybind.objects.button = keybindButton

                utility:Create("UICorner", {Parent = keybindButton, CornerRadius = UDim.new(0, 4)})
                utility:Create("UIStroke", {Parent = keybindButton, Color = library.theme.ElementBorder, Thickness = 1})

                keybindButton.MouseButton1Click:Connect(function()
                    keybind.binding = true
                    keybindButton.Text = "..."
                    utility:Tween(keybindButton, {BackgroundColor3 = library.theme.Accent}, 0.15)
                end)

                uis.InputBegan:Connect(function(input, processed)
                    if keybind.binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                keybind.value = Enum.KeyCode.Unknown
                                keybindButton.Text = "None"
                            else
                                keybind.value = input.KeyCode
                                keybindButton.Text = input.KeyCode.Name
                            end

                            keybind.binding = false
                            utility:Tween(keybindButton, {BackgroundColor3 = library.theme.Element}, 0.15)

                            if keybindFlag then
                                library.flags[keybindFlag] = keybind.value
                            end
                        end
                    elseif not processed and input.KeyCode == keybind.value then
                        pcall(keybindCallback, keybind.value)
                    end
                end)

                function keybind:Set(key)
                    keybind.value = key
                    keybindButton.Text = key.Name ~= "Unknown" and key.Name or "None"
                    if keybindFlag then
                        library.flags[keybindFlag] = key
                    end
                end

                return keybind
            end

            -- Colorpicker Element
            function section:CreateColorpicker(config)
                config = config or {}
                local colorName = config.Name or "Color"
                local colorDefault = config.Default or Color3.fromRGB(255, 255, 255)
                local colorCallback = config.Callback or function() end
                local colorFlag = config.Flag

                local colorpicker = {
                    value = colorDefault,
                    open = false,
                    objects = {}
                }

                table.insert(section.elements, colorpicker)

                if colorFlag then
                    library.flags[colorFlag] = colorDefault
                    library.options[colorFlag] = colorpicker
                end

                local colorFrame = utility:Create("Frame", {
                    Name = colorName,
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })
                colorpicker.objects.frame = colorFrame

                utility:Create("TextLabel", {
                    Name = "Label",
                    Parent = colorFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = colorName,
                    TextColor3 = library.theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local colorButton = utility:Create("TextButton", {
                    Name = "ColorButton",
                    Parent = colorFrame,
                    BackgroundColor3 = colorDefault,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -34, 0.5, -10),
                    Size = UDim2.new(0, 34, 0, 20),
                    Text = "",
                    AutoButtonColor = false
                })
                colorpicker.objects.button = colorButton

                utility:Create("UICorner", {Parent = colorButton, CornerRadius = UDim.new(0, 4)})
                utility:Create("UIStroke", {Parent = colorButton, Color = library.theme.ElementBorder, Thickness = 1})

                -- Color picker panel
                local pickerFrame = utility:Create("Frame", {
                    Name = "Picker",
                    Parent = colorFrame,
                    BackgroundColor3 = library.theme.Section,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -200, 0, 32),
                    Size = UDim2.new(0, 200, 0, 180),
                    Visible = false,
                    ZIndex = 100
                })
                colorpicker.objects.picker = pickerFrame

                utility:Create("UICorner", {Parent = pickerFrame, CornerRadius = UDim.new(0, 6)})
                utility:Create("UIStroke", {Parent = pickerFrame, Color = library.theme.Accent, Thickness = 1})

                -- Saturation/Value picker
                local svPicker = utility:Create("ImageLabel", {
                    Name = "SVPicker",
                    Parent = pickerFrame,
                    BackgroundColor3 = Color3.fromHSV(colorDefault:ToHSV()),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 10),
                    Size = UDim2.new(0, 150, 0, 120),
                    Image = "rbxassetid://4155801252",
                    ZIndex = 101
                })
                colorpicker.objects.svPicker = svPicker

                utility:Create("UICorner", {Parent = svPicker, CornerRadius = UDim.new(0, 4)})

                local svCursor = utility:Create("Frame", {
                    Name = "Cursor",
                    Parent = svPicker,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.5, -4, 0.5, -4),
                    Size = UDim2.new(0, 8, 0, 8),
                    ZIndex = 102
                })
                colorpicker.objects.svCursor = svCursor

                utility:Create("UICorner", {Parent = svCursor, CornerRadius = UDim.new(1, 0)})
                utility:Create("UIStroke", {Parent = svCursor, Color = Color3.new(0, 0, 0), Thickness = 1})

                -- Hue slider
                local huePicker = utility:Create("ImageLabel", {
                    Name = "HuePicker",
                    Parent = pickerFrame,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 170, 0, 10),
                    Size = UDim2.new(0, 20, 0, 120),
                    Image = "rbxassetid://3570695787",
                    ScaleType = Enum.ScaleType.Stretch,
                    ZIndex = 101
                })
                colorpicker.objects.huePicker = huePicker

                utility:Create("UICorner", {Parent = huePicker, CornerRadius = UDim.new(0, 4)})

                local hueCursor = utility:Create("Frame", {
                    Name = "Cursor",
                    Parent = huePicker,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, -2, 0, -2),
                    Size = UDim2.new(1, 4, 0, 4),
                    ZIndex = 102
                })
                colorpicker.objects.hueCursor = hueCursor

                utility:Create("UICorner", {Parent = hueCursor, CornerRadius = UDim.new(0, 2)})
                utility:Create("UIStroke", {Parent = hueCursor, Color = Color3.new(0, 0, 0), Thickness = 1})

                -- RGB inputs
                local rgbFrame = utility:Create("Frame", {
                    Name = "RGB",
                    Parent = pickerFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 140),
                    Size = UDim2.new(1, -20, 0, 30),
                    ZIndex = 101
                })

                local h, s, v = colorDefault:ToHSV()
                local currentHue = h
                local currentSat = s
                local currentVal = v

                local function updateColor()
                    local newColor = Color3.fromHSV(currentHue, currentSat, currentVal)
                    colorpicker.value = newColor
                    colorButton.BackgroundColor3 = newColor
                    svPicker.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)

                    if colorFlag then
                        library.flags[colorFlag] = newColor
                    end

                    pcall(colorCallback, newColor)
                end

                -- SV Picker interaction
                local svDragging = false

                svPicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = true
                    end
                end)

                uis.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = false
                    end
                end)

                uis.InputChanged:Connect(function(input)
                    if svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mousePos = uis:GetMouseLocation()
                        local relX = clamp((mousePos.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
                        local relY = clamp((mousePos.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)

                        currentSat = relX
                        currentVal = 1 - relY

                        svCursor.Position = UDim2.new(relX, -4, relY, -4)
                        updateColor()
                    end
                end)

                -- Hue Picker interaction
                local hueDragging = false

                huePicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                    end
                end)

                uis.InputChanged:Connect(function(input)
                    if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mousePos = uis:GetMouseLocation()
                        local relY = clamp((mousePos.Y - huePicker.AbsolutePosition.Y) / huePicker.AbsoluteSize.Y, 0, 1)

                        currentHue = 1 - relY
                        hueCursor.Position = UDim2.new(0, -2, relY, -2)
                        updateColor()
                    end
                end)

                -- Set initial positions
                svCursor.Position = UDim2.new(s, -4, 1 - v, -4)
                hueCursor.Position = UDim2.new(0, -2, 1 - h, -2)

                colorButton.MouseButton1Click:Connect(function()
                    colorpicker.open = not colorpicker.open
                    pickerFrame.Visible = colorpicker.open
                end)

                function colorpicker:Set(color)
                    colorpicker.value = color
                    colorButton.BackgroundColor3 = color

                    local h, s, v = color:ToHSV()
                    currentHue = h
                    currentSat = s
                    currentVal = v

                    svPicker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    svCursor.Position = UDim2.new(s, -4, 1 - v, -4)
                    hueCursor.Position = UDim2.new(0, -2, 1 - h, -2)

                    if colorFlag then
                        library.flags[colorFlag] = color
                    end
                    pcall(colorCallback, color)
                end

                return colorpicker
            end

            -- Label Element
            function section:CreateLabel(config)
                config = config or {}
                local labelText = config.Text or "Label"

                local label = {
                    objects = {}
                }

                local labelFrame = utility:Create("Frame", {
                    Name = "Label",
                    Parent = elementContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20)
                })

                local labelObj = utility:Create("TextLabel", {
                    Name = "Text",
                    Parent = labelFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = labelText,
                    TextColor3 = library.theme.Disabled,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                label.objects.text = labelObj

                function label:Set(text)
                    labelObj.Text = text
                end

                return label
            end

            -- Separator Element
            function section:CreateSeparator()
                local separator = utility:Create("Frame", {
                    Name = "Separator",
                    Parent = elementContainer,
                    BackgroundColor3 = library.theme.ElementBorder,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1)
                })

                return separator
            end

            return section
        end

        return tab
    end

    -- Window visibility
    function window:SetVisible(visible)
        window.open = visible

        if visible then
            mainFrame.Visible = true
            utility:Tween(mainFrame, {
                Size = windowSize,
                BackgroundTransparency = 0
            }, 0.3)
        else
            utility:Tween(mainFrame, {
                Size = UDim2.new(0, windowSize.X.Offset, 0, 0),
                BackgroundTransparency = 1
            }, 0.3)
            task.delay(0.3, function()
                mainFrame.Visible = false
            end)
        end
    end

    function window:Toggle()
        window:SetVisible(not window.open)
    end

    -- Toggle keybind
    uis.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == library.toggleKey then
            window:Toggle()
        end
    end)

    return window
end

-- Set theme
function library:SetTheme(theme)
    for key, value in pairs(theme) do
        library.theme[key] = value
    end
end

-- Unload
function library:Unload()
    for _, window in ipairs(library.windows) do
        if window.screenGui then
            window.screenGui:Destroy()
        end
    end

    for _, connection in pairs(library.connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end

    table.clear(library.windows)
    table.clear(library.connections)
    table.clear(library.flags)
    table.clear(library.options)
end

return library
