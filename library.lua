--[[

╔═══════════════════════════════════════════════════════════════════════════╗
║                           NexusLib v4.3.5                                 ║
║              Enhanced Drawing UI Library for Roblox                       ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ Features:                                                                 ║
║   • Modern dark theme with multiple color schemes                         ║
║   • Draggable windows, watermark, and keybind list                        ║
║   • Full element set: Toggle, Slider, Button, Dropdown, Keybind,          ║
║     ColorPicker, Textbox, Label, Separator                                ║
║   • Notification system with animations                                   ║
║   • Config save/load system                                               ║
║   • Real-time theme and accent color switching                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ v4.3.5 FIXES:                                                             ║
║   • Fixed section overlap when switching between sections                 ║
║   • Added Separator element for visual dividers                           ║
║   • Keybind list dragging works properly                                  ║
╚═══════════════════════════════════════════════════════════════════════════╝

]]

--============================================================================--
--                              SAFETY CHECK                                  --
--============================================================================--

if not Drawing or not Drawing.new then
    warn("NexusLib: Drawing API not supported")
    return {
        New = function()
            return {
                Page = function()
                    return {
                        Section = function()
                            return {}
                        end
                    }
                end,
                Init = function() end,
                Unload = function() end
            }
        end,
        watermark = { SetEnabled = function() end },
        keybindList = { SetEnabled = function() end }
    }
end

--============================================================================--
--                              LIBRARY CORE                                  --
--============================================================================--

local library = {
    -- Storage
    drawings = {},
    connections = {},
    flags = {},
    pointers = {},
    notifications = {},
    windows = {},

    -- Tracking for dynamic updates
    accentObjects = {},
    themeObjects = {},
    tabTextObjects = {},
    toggleObjects = {},
    colorPickerPreviews = {},

    -- State
    open = true,
    blockingInput = false,

    -- Appearance
    accent = Color3.fromRGB(76, 162, 252),
    menuKeybind = Enum.KeyCode.RightShift,

    -- Default theme colors
    theme = {
        background = Color3.fromRGB(12, 12, 12),
        topbar = Color3.fromRGB(16, 16, 16),
        sidebar = Color3.fromRGB(14, 14, 14),
        section = Color3.fromRGB(16, 16, 16),
        sectionheader = Color3.fromRGB(18, 18, 18),
        outline = Color3.fromRGB(32, 32, 32),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(120, 120, 120),
        elementbg = Color3.fromRGB(22, 22, 22),
        success = Color3.fromRGB(80, 200, 120),
        warning = Color3.fromRGB(255, 180, 50),
        error = Color3.fromRGB(240, 80, 80)
    }
}

--============================================================================--
--                             THEME PRESETS                                  --
--============================================================================--

library.themes = {
    Default = {
        accent = Color3.fromRGB(76, 162, 252),
        background = Color3.fromRGB(12, 12, 12),
        topbar = Color3.fromRGB(16, 16, 16),
        sidebar = Color3.fromRGB(14, 14, 14),
        section = Color3.fromRGB(16, 16, 16),
        sectionheader = Color3.fromRGB(18, 18, 18),
        outline = Color3.fromRGB(32, 32, 32),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(120, 120, 120),
        elementbg = Color3.fromRGB(22, 22, 22)
    },
    Midnight = {
        accent = Color3.fromRGB(138, 92, 224),
        background = Color3.fromRGB(14, 14, 20),
        topbar = Color3.fromRGB(18, 18, 26),
        sidebar = Color3.fromRGB(16, 16, 24),
        section = Color3.fromRGB(16, 16, 24),
        sectionheader = Color3.fromRGB(20, 20, 30),
        outline = Color3.fromRGB(40, 40, 55),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(100, 100, 130),
        elementbg = Color3.fromRGB(24, 24, 34)
    },
    Rose = {
        accent = Color3.fromRGB(226, 80, 130),
        background = Color3.fromRGB(14, 12, 14),
        topbar = Color3.fromRGB(20, 16, 20),
        sidebar = Color3.fromRGB(18, 14, 18),
        section = Color3.fromRGB(18, 14, 18),
        sectionheader = Color3.fromRGB(24, 18, 24),
        outline = Color3.fromRGB(45, 38, 45),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(130, 100, 120),
        elementbg = Color3.fromRGB(28, 22, 28)
    },
    Ocean = {
        accent = Color3.fromRGB(60, 180, 220),
        background = Color3.fromRGB(10, 14, 18),
        topbar = Color3.fromRGB(14, 20, 26),
        sidebar = Color3.fromRGB(12, 18, 24),
        section = Color3.fromRGB(12, 18, 24),
        sectionheader = Color3.fromRGB(16, 24, 32),
        outline = Color3.fromRGB(30, 42, 52),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(90, 120, 140),
        elementbg = Color3.fromRGB(18, 26, 34)
    },
    Emerald = {
        accent = Color3.fromRGB(80, 200, 120),
        background = Color3.fromRGB(10, 14, 12),
        topbar = Color3.fromRGB(14, 20, 16),
        sidebar = Color3.fromRGB(12, 18, 14),
        section = Color3.fromRGB(12, 18, 14),
        sectionheader = Color3.fromRGB(16, 24, 18),
        outline = Color3.fromRGB(32, 48, 40),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(90, 130, 110),
        elementbg = Color3.fromRGB(18, 28, 22)
    }
}

--============================================================================--
--                        PRE-INITIALIZED COMPONENTS                          --
--============================================================================--

library.watermark = {
    enabled = false,
    objects = {},
    position = Vector2.new(10, 10),
    dragging = false,
    dragOffset = Vector2.new(0, 0),
    _initialized = false
}

function library.watermark:SetEnabled(state)
    library.watermark.enabled = state
    if library.watermark._initialized then
        for _, obj in pairs(library.watermark.objects) do
            pcall(function() obj.Visible = state end)
        end
    end
end

library.keybindList = {
    enabled = false,
    objects = {},
    items = {},
    position = Vector2.new(10, 50),
    dragging = false,
    dragOffset = Vector2.new(0, 0),
    _initialized = false
}

function library.keybindList:SetEnabled(state)
    library.keybindList.enabled = state
    if library.keybindList._initialized then
        for _, obj in pairs(library.keybindList.objects) do
            pcall(function() obj.Visible = state end)
        end
        for _, item in pairs(library.keybindList.items) do
            if item.active then
                for _, obj in pairs(item.objects) do
                    pcall(function() obj.Visible = state end)
                end
            end
        end
    end
end

--============================================================================--
--                                SERVICES                                    --
--============================================================================--

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

--============================================================================--
--                            UTILITY FUNCTIONS                               --
--============================================================================--

local function createDrawing(class, properties)
    local success, obj = pcall(function()
        return Drawing.new(class)
    end)
    if not success or not obj then
        return {
            Remove = function() end,
            Visible = false,
            Position = Vector2.new(0, 0),
            Size = Vector2.new(0, 0),
            Color = Color3.new(1, 1, 1),
            Text = ""
        }
    end
    for key, value in pairs(properties or {}) do
        pcall(function()
            obj[key] = value
        end)
    end
    table.insert(library.drawings, obj)
    return obj
end

local function removeDrawing(obj)
    if not obj then return end
    for i, v in pairs(library.drawings) do
        if v == obj then
            table.remove(library.drawings, i)
            break
        end
    end
    pcall(function()
        obj:Remove()
    end)
end

local function getTextBounds(text, size)
    local success, result = pcall(function()
        local textObj = Drawing.new("Text")
        textObj.Text = text or ""
        textObj.Size = size or 13
        textObj.Font = 2
        local bounds = textObj.TextBounds
        textObj:Remove()
        return bounds
    end)
    return success and result or Vector2.new(50, 13)
end

local function isMouseOver(x, y, width, height)
    local success, mouse = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not success then return false end
    return mouse.X >= x and mouse.X <= x + width and mouse.Y >= y and mouse.Y <= y + height
end

local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    s = max == 0 and 0 or d / max
    if max ~= min then
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end

local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local keyNames = {
    [Enum.KeyCode.LeftShift] = "LShift",
    [Enum.KeyCode.RightShift] = "RShift",
    [Enum.KeyCode.LeftControl] = "LCtrl",
    [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftAlt] = "LAlt",
    [Enum.KeyCode.RightAlt] = "RAlt",
    [Enum.KeyCode.CapsLock] = "Caps",
    [Enum.KeyCode.Tab] = "Tab",
    [Enum.KeyCode.Backspace] = "Back",
    [Enum.KeyCode.Return] = "Enter",
    [Enum.KeyCode.Space] = "Space",
    [Enum.KeyCode.Escape] = "Esc",
    [Enum.UserInputType.MouseButton1] = "M1",
    [Enum.UserInputType.MouseButton2] = "M2",
    [Enum.UserInputType.MouseButton3] = "M3"
}

local function getKeyName(key)
    if keyNames[key] then
        return keyNames[key]
    end
    if typeof(key) == "EnumItem" then
        return key.Name
    end
    return "None"
end

--============================================================================--
--                          REGISTRATION FUNCTIONS                            --
--============================================================================--

local function registerAccent(obj, property)
    table.insert(library.accentObjects, {
        obj = obj,
        property = property
    })
end

local function registerTheme(obj, property, themeKey)
    table.insert(library.themeObjects, {
        obj = obj,
        property = property,
        themeKey = themeKey
    })
end

local function registerTabText(obj, page)
    table.insert(library.tabTextObjects, {
        obj = obj,
        page = page
    })
end

local function registerToggle(obj, toggle)
    table.insert(library.toggleObjects, {
        obj = obj,
        toggle = toggle
    })
end

--============================================================================--
--                            THEME FUNCTIONS                                 --
--============================================================================--

function library:SetAccent(color)
    library.accent = color
    for _, data in pairs(library.accentObjects) do
        pcall(function()
            if data.obj and data.property then
                data.obj[data.property] = color
            end
        end)
    end
    for _, data in pairs(library.tabTextObjects) do
        pcall(function()
            if data.page and data.page.visible and data.obj then
                data.obj.Color = color
            end
        end)
    end
    for _, data in pairs(library.toggleObjects) do
        pcall(function()
            if data.toggle and data.toggle.value and data.obj then
                data.obj.Color = color
            end
        end)
    end
    for _, data in pairs(library.colorPickerPreviews) do
        pcall(function()
            if data.trackAccent and data.obj then
                data.obj.Color = color
                if data.colorpicker then
                    data.colorpicker.value = color
                end
            end
        end)
    end
end

function library:SetTheme(themeName)
    local themeData = library.themes[themeName]
    if not themeData then return end
    for key, value in pairs(themeData) do
        if key == "accent" then
            library:SetAccent(value)
        elseif library.theme[key] then
            library.theme[key] = value
        end
    end
    for _, data in pairs(library.themeObjects) do
        pcall(function()
            if data.obj and data.property and data.themeKey then
                data.obj[data.property] = library.theme[data.themeKey]
            end
        end)
    end
    for _, data in pairs(library.tabTextObjects) do
        pcall(function()
            if data.page and not data.page.visible and data.obj then
                data.obj.Color = library.theme.dimtext
            end
        end)
    end
    for _, data in pairs(library.toggleObjects) do
        pcall(function()
            if data.toggle and not data.toggle.value and data.obj then
                data.obj.Color = library.theme.elementbg
            end
        end)
    end
end

--============================================================================--
--                               WATERMARK                                    --
--============================================================================--

function library:CreateWatermark(config)
    config = config or {}
    local title = config.title or "NexusLib"
    local watermark = library.watermark
    local initialText = title .. " | 0 fps | 0ms | 00:00:00"
    local width = getTextBounds(initialText, 13).X + 20
    local pos = watermark.position

    watermark.objects.outline = createDrawing("Square", {
        Size = Vector2.new(width, 24),
        Position = pos,
        Color = library.theme.outline,
        Filled = true,
        Visible = false,
        ZIndex = 100
    })
    registerTheme(watermark.objects.outline, "Color", "outline")

    watermark.objects.background = createDrawing("Square", {
        Size = Vector2.new(width - 2, 22),
        Position = pos + Vector2.new(1, 1),
        Color = library.theme.background,
        Filled = true,
        Visible = false,
        ZIndex = 101
    })
    registerTheme(watermark.objects.background, "Color", "background")

    watermark.objects.accent = createDrawing("Square", {
        Size = Vector2.new(width - 4, 2),
        Position = pos + Vector2.new(2, 2),
        Color = library.accent,
        Filled = true,
        Visible = false,
        ZIndex = 102
    })
    registerAccent(watermark.objects.accent, "Color")

    watermark.objects.text = createDrawing("Text", {
        Text = initialText,
        Size = 13,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = pos + Vector2.new(8, 6),
        Visible = false,
        ZIndex = 103
    })
    registerTheme(watermark.objects.text, "Color", "text")

    watermark.title = title
    watermark.width = width
    watermark._initialized = true

    if watermark.enabled then
        for _, obj in pairs(watermark.objects) do
            pcall(function() obj.Visible = true end)
        end
    end

    function watermark:UpdatePositions()
        local p = watermark.position
        local w = watermark.width
        pcall(function()
            watermark.objects.outline.Position = p
            watermark.objects.outline.Size = Vector2.new(w, 24)
        end)
        pcall(function()
            watermark.objects.background.Position = p + Vector2.new(1, 1)
            watermark.objects.background.Size = Vector2.new(w - 2, 22)
        end)
        pcall(function()
            watermark.objects.accent.Position = p + Vector2.new(2, 2)
            watermark.objects.accent.Size = Vector2.new(w - 4, 2)
        end)
        pcall(function()
            watermark.objects.text.Position = p + Vector2.new(8, 6)
        end)
    end

    local lastUpdate = 0
    local fpsBuffer = {}
    table.insert(library.connections, RunService.RenderStepped:Connect(function(deltaTime)
        if not watermark.enabled then return end
        table.insert(fpsBuffer, 1 / deltaTime)
        if #fpsBuffer > 30 then
            table.remove(fpsBuffer, 1)
        end
        if tick() - lastUpdate < 0.5 then return end
        lastUpdate = tick()
        local avgFps = 0
        for _, v in ipairs(fpsBuffer) do
            avgFps = avgFps + v
        end
        avgFps = math.floor(avgFps / #fpsBuffer)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local timeStr = os.date("%H:%M:%S")
        local newText = watermark.title .. " | " .. avgFps .. " fps | " .. ping .. "ms | " .. timeStr
        pcall(function()
            watermark.objects.text.Text = newText
            watermark.width = getTextBounds(newText, 13).X + 20
            watermark:UpdatePositions()
        end)
    end))

    table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and watermark.enabled then
            local pos = watermark.position
            if isMouseOver(pos.X, pos.Y, watermark.width, 24) then
                watermark.dragging = true
                local success, mouse = pcall(function()
                    return UserInputService:GetMouseLocation()
                end)
                if success then
                    watermark.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
                end
            end
        end
    end))

    table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            watermark.dragging = false
        end
    end))

    table.insert(library.connections, RunService.RenderStepped:Connect(function()
        if watermark.dragging then
            local success, mouse = pcall(function()
                return UserInputService:GetMouseLocation()
            end)
            if success then
                watermark.position = Vector2.new(
                    mouse.X - watermark.dragOffset.X,
                    mouse.Y - watermark.dragOffset.Y
                )
                watermark:UpdatePositions()
            end
        end
    end))

    return watermark
end

--============================================================================--
--                              NOTIFICATIONS                                 --
--============================================================================--

function library:Notify(config)
    config = config or {}
    local title = config.title or "Notification"
    local message = config.message or ""
    local duration = config.duration or 4
    local notifType = config.type or "info"

    local typeColors = {
        info = library.accent,
        success = library.theme.success,
        warning = library.theme.warning,
        error = library.theme.error
    }
    local accentColor = typeColors[notifType] or library.accent

    local notification = {
        objects = {},
        startTime = tick()
    }

    local titleWidth = getTextBounds(title, 13).X
    local msgWidth = getTextBounds(message, 13).X
    local width = math.max(math.max(titleWidth, msgWidth) + 30, 220)
    local height = message ~= "" and 52 or 34

    local screenSize = workspace.CurrentCamera.ViewportSize
    local yOffset = 10
    for _, notif in pairs(library.notifications) do
        if notif.objects.outline and notif.objects.outline.Visible then
            yOffset = yOffset + notif.height + 8
        end
    end
    local startX = screenSize.X + width
    local targetX = screenSize.X - width - 10
    local posY = screenSize.Y - height - yOffset
    notification.height = height

    notification.objects.outline = createDrawing("Square", {
        Size = Vector2.new(width, height),
        Position = Vector2.new(startX, posY),
        Color = library.theme.outline,
        Filled = true,
        Visible = true,
        ZIndex = 200
    })

    notification.objects.background = createDrawing("Square", {
        Size = Vector2.new(width - 2, height - 2),
        Position = Vector2.new(startX + 1, posY + 1),
        Color = library.theme.background,
        Filled = true,
        Visible = true,
        ZIndex = 201
    })

    notification.objects.accent = createDrawing("Square", {
        Size = Vector2.new(3, height - 6),
        Position = Vector2.new(startX + 3, posY + 3),
        Color = accentColor,
        Filled = true,
        Visible = true,
        ZIndex = 202
    })

    notification.objects.title = createDrawing("Text", {
        Text = title,
        Size = 13,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(startX + 14, posY + 8),
        Visible = true,
        ZIndex = 203
    })

    if message ~= "" then
        notification.objects.message = createDrawing("Text", {
            Text = message,
            Size = 13,
            Font = 2,
            Color = library.theme.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = Vector2.new(startX + 14, posY + 26),
            Visible = true,
            ZIndex = 203
        })
    end

    notification.objects.progress = createDrawing("Square", {
        Size = Vector2.new(width - 6, 2),
        Position = Vector2.new(startX + 3, posY + height - 5),
        Color = accentColor,
        Filled = true,
        Visible = true,
        ZIndex = 202
    })

    table.insert(library.notifications, notification)

    local currentX = startX
    task.spawn(function()
        while currentX > targetX do
            currentX = lerp(currentX, targetX, 0.12)
            if math.abs(currentX - targetX) < 1 then
                currentX = targetX
            end
            pcall(function()
                notification.objects.outline.Position = Vector2.new(currentX, posY)
                notification.objects.background.Position = Vector2.new(currentX + 1, posY + 1)
                notification.objects.accent.Position = Vector2.new(currentX + 3, posY + 3)
                notification.objects.title.Position = Vector2.new(currentX + 14, posY + 8)
                if notification.objects.message then
                    notification.objects.message.Position = Vector2.new(currentX + 14, posY + 26)
                end
                notification.objects.progress.Position = Vector2.new(currentX + 3, posY + height - 5)
            end)
            task.wait()
        end

        local elapsed = 0
        while elapsed < duration do
            elapsed = tick() - notification.startTime
            local progress = 1 - (elapsed / duration)
            pcall(function()
                notification.objects.progress.Size = Vector2.new((width - 6) * progress, 2)
            end)
            task.wait()
        end

        local outTarget = screenSize.X + width
        while currentX < outTarget do
            currentX = lerp(currentX, outTarget, 0.12)
            if math.abs(currentX - outTarget) < 1 then
                currentX = outTarget
            end
            pcall(function()
                notification.objects.outline.Position = Vector2.new(currentX, posY)
                notification.objects.background.Position = Vector2.new(currentX + 1, posY + 1)
                notification.objects.accent.Position = Vector2.new(currentX + 3, posY + 3)
                notification.objects.title.Position = Vector2.new(currentX + 14, posY + 8)
                if notification.objects.message then
                    notification.objects.message.Position = Vector2.new(currentX + 14, posY + 26)
                end
                notification.objects.progress.Position = Vector2.new(currentX + 3, posY + height - 5)
            end)
            task.wait()
        end

        for _, obj in pairs(notification.objects) do
            removeDrawing(obj)
        end
        for i, n in pairs(library.notifications) do
            if n == notification then
                table.remove(library.notifications, i)
                break
            end
        end
    end)

    return notification
end

--============================================================================--
--                              KEYBIND LIST                                  --
--============================================================================--

function library:CreateKeybindList(config)
    config = config or {}
    local title = config.title or "Active Keybinds"
    local list = library.keybindList
    local width = 160

    list.objects.outline = createDrawing("Square", {
        Size = Vector2.new(width, 26),
        Position = list.position,
        Color = library.theme.outline,
        Filled = true,
        Visible = false,
        ZIndex = 90
    })
    registerTheme(list.objects.outline, "Color", "outline")

    list.objects.background = createDrawing("Square", {
        Size = Vector2.new(width - 2, 24),
        Position = list.position + Vector2.new(1, 1),
        Color = library.theme.background,
        Filled = true,
        Visible = false,
        ZIndex = 91
    })
    registerTheme(list.objects.background, "Color", "background")

    list.objects.accent = createDrawing("Square", {
        Size = Vector2.new(width - 4, 2),
        Position = list.position + Vector2.new(2, 2),
        Color = library.accent,
        Filled = true,
        Visible = false,
        ZIndex = 92
    })
    registerAccent(list.objects.accent, "Color")

    list.objects.title = createDrawing("Text", {
        Text = title,
        Size = 13,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = list.position + Vector2.new(8, 7),
        Visible = false,
        ZIndex = 93
    })
    registerTheme(list.objects.title, "Color", "text")

    list.width = width
    list._initialized = true

    if list.enabled then
        for _, obj in pairs(list.objects) do
            pcall(function() obj.Visible = true end)
        end
    end

    function list:UpdatePositions()
        local p = list.position
        pcall(function()
            list.objects.outline.Position = p
            list.objects.background.Position = p + Vector2.new(1, 1)
            list.objects.accent.Position = p + Vector2.new(2, 2)
            list.objects.title.Position = p + Vector2.new(8, 7)
        end)
        list:UpdateHeight()
    end

    function list:AddKeybind(name, key)
        local item = {
            name = name,
            key = key,
            active = false,
            objects = {}
        }
        local yOffset = 26 + (#list.items * 20)

        item.objects.background = createDrawing("Square", {
            Size = Vector2.new(width - 2, 20),
            Position = list.position + Vector2.new(1, yOffset),
            Color = library.theme.elementbg,
            Filled = true,
            Visible = false,
            ZIndex = 91
        })

        item.objects.name = createDrawing("Text", {
            Text = name,
            Size = 13,
            Font = 2,
            Color = library.theme.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = list.position + Vector2.new(8, yOffset + 3),
            Visible = false,
            ZIndex = 93
        })

        local keyText = "[" .. key .. "]"
        item.objects.key = createDrawing("Text", {
            Text = keyText,
            Size = 13,
            Font = 2,
            Color = library.accent,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = list.position + Vector2.new(width - 10 - getTextBounds(keyText, 13).X, yOffset + 3),
            Visible = false,
            ZIndex = 93
        })
        registerAccent(item.objects.key, "Color")

        function item:SetActive(state)
            item.active = state
            for _, obj in pairs(item.objects) do
                pcall(function()
                    obj.Visible = list.enabled and state
                end)
            end
            list:UpdateHeight()
        end

        table.insert(list.items, item)
        return item
    end

    function list:UpdateHeight()
        local activeCount = 0
        for _, item in pairs(list.items) do
            if item.active then
                activeCount = activeCount + 1
            end
        end
        local totalHeight = 26 + (activeCount * 20)
        pcall(function()
            list.objects.outline.Size = Vector2.new(width, totalHeight)
            list.objects.background.Size = Vector2.new(width - 2, totalHeight - 2)
        end)
        local yOffset = 26
        for _, item in pairs(list.items) do
            if item.active then
                pcall(function()
                    item.objects.background.Position = list.position + Vector2.new(1, yOffset)
                    item.objects.name.Position = list.position + Vector2.new(8, yOffset + 3)
                    local keyText = "[" .. item.key .. "]"
                    item.objects.key.Position = list.position + Vector2.new(
                        width - 10 - getTextBounds(keyText, 13).X,
                        yOffset + 3
                    )
                end)
                yOffset = yOffset + 20
            end
        end
    end

    table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and list.enabled then
            local pos = list.position
            if isMouseOver(pos.X, pos.Y, width, 26) then
                list.dragging = true
                local success, mouse = pcall(function()
                    return UserInputService:GetMouseLocation()
                end)
                if success then
                    list.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
                end
            end
        end
    end))

    table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            list.dragging = false
        end
    end))

    table.insert(library.connections, RunService.RenderStepped:Connect(function()
        if list.dragging then
            local success, mouse = pcall(function()
                return UserInputService:GetMouseLocation()
            end)
            if success then
                list.position = Vector2.new(
                    mouse.X - list.dragOffset.X,
                    mouse.Y - list.dragOffset.Y
                )
                list:UpdatePositions()
            end
        end
    end))

    return list
end

--============================================================================--
--                              CONFIG SYSTEM                                 --
--============================================================================--

function library:SaveConfig(name, folder)
    folder = folder or "NexusLib"
    pcall(function()
        if not isfolder(folder) then
            makefolder(folder)
        end
    end)
    local data = {}
    for flag, value in pairs(library.flags) do
        if typeof(value) == "Color3" then
            data[flag] = {
                type = "Color3",
                R = value.R,
                G = value.G,
                B = value.B
            }
        elseif typeof(value) == "EnumItem" then
            data[flag] = {
                type = "Enum",
                value = tostring(value)
            }
        else
            data[flag] = value
        end
    end
    pcall(function()
        writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    library:Notify({
        title = "Config Saved",
        message = name,
        type = "success",
        duration = 3
    })
end

function library:LoadConfig(name, folder)
    folder = folder or "NexusLib"
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(folder .. "/" .. name .. ".json"))
    end)
    if not success then
        library:Notify({
            title = "Config Error",
            message = "Failed to load: " .. name,
            type = "error",
            duration = 3
        })
        return
    end
    for flag, value in pairs(data) do
        if typeof(value) == "table" and value.type == "Color3" then
            library.flags[flag] = Color3.new(value.R, value.G, value.B)
        else
            library.flags[flag] = value
        end
        if library.pointers[flag] and library.pointers[flag].Set then
            pcall(function()
                library.pointers[flag]:Set(library.flags[flag])
            end)
        end
    end
    library:Notify({
        title = "Config Loaded",
        message = name,
        type = "success",
        duration = 3
    })
end

--============================================================================--
--                              MAIN WINDOW                                   --
--============================================================================--

function library:New(config)
    config = config or {}
    local windowName = config.name or "NexusLib"
    local sizeX = config.sizeX or 580
    local sizeY = config.sizeY or 460

    if config.accent then
        library.accent = config.accent
    end

    local window = {
        pos = Vector2.new(100, 50),
        size = Vector2.new(sizeX, sizeY),
        dragging = false,
        dragOffset = Vector2.new(0, 0),
        pages = {},
        currentPage = nil,
        objects = {},
        activeDropdown = nil,
        activeColorPicker = nil
    }

    -- Window elements
    window.objects.outerGlow = createDrawing("Square", {
        Size = Vector2.new(sizeX + 2, sizeY + 2),
        Position = window.pos - Vector2.new(1, 1),
        Color = library.accent,
        Transparency = 0.1,
        Filled = true,
        ZIndex = 0,
        Visible = true
    })
    registerAccent(window.objects.outerGlow, "Color")

    window.objects.outline = createDrawing("Square", {
        Size = window.size,
        Position = window.pos,
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 1,
        Visible = true
    })
    registerTheme(window.objects.outline, "Color", "outline")

    window.objects.background = createDrawing("Square", {
        Size = Vector2.new(sizeX - 2, sizeY - 2),
        Position = window.pos + Vector2.new(1, 1),
        Color = library.theme.background,
        Filled = true,
        ZIndex = 2,
        Visible = true
    })
    registerTheme(window.objects.background, "Color", "background")

    window.objects.topbar = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, 24),
        Position = window.pos + Vector2.new(2, 2),
        Color = library.theme.topbar,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })
    registerTheme(window.objects.topbar, "Color", "topbar")

    window.objects.accentLine = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, 2),
        Position = window.pos + Vector2.new(2, 26),
        Color = library.accent,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })
    registerAccent(window.objects.accentLine, "Color")

    window.objects.title = createDrawing("Text", {
        Text = windowName,
        Size = 14,
        Font = 2,
        Color = library.accent,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(10, 6),
        Visible = true,
        ZIndex = 5
    })
    registerAccent(window.objects.title, "Color")

    window.objects.contentOutline = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, sizeY - 54),
        Position = window.pos + Vector2.new(2, 28),
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })
    registerTheme(window.objects.contentOutline, "Color", "outline")

    window.objects.content = createDrawing("Square", {
        Size = Vector2.new(sizeX - 6, sizeY - 56),
        Position = window.pos + Vector2.new(3, 29),
        Color = library.theme.section,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })
    registerTheme(window.objects.content, "Color", "section")

    window.objects.sidebarOutline = createDrawing("Square", {
        Size = Vector2.new(118, sizeY - 58),
        Position = window.pos + Vector2.new(4, 30),
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 5,
        Visible = true
    })
    registerTheme(window.objects.sidebarOutline, "Color", "outline")

    window.objects.sidebar = createDrawing("Square", {
        Size = Vector2.new(116, sizeY - 60),
        Position = window.pos + Vector2.new(5, 31),
        Color = library.theme.sidebar,
        Filled = true,
        ZIndex = 6,
        Visible = true
    })
    registerTheme(window.objects.sidebar, "Color", "sidebar")

    window.objects.bottomOutline = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, 24),
        Position = window.pos + Vector2.new(2, sizeY - 26),
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })
    registerTheme(window.objects.bottomOutline, "Color", "outline")

    window.objects.bottombar = createDrawing("Square", {
        Size = Vector2.new(sizeX - 6, 22),
        Position = window.pos + Vector2.new(3, sizeY - 25),
        Color = library.theme.topbar,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })
    registerTheme(window.objects.bottombar, "Color", "topbar")

    window.objects.version = createDrawing("Text", {
        Text = "v4.3.5",
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(10, sizeY - 21),
        Visible = true,
        ZIndex = 5
    })
    registerTheme(window.objects.version, "Color", "dimtext")

    window.objects.fpsText = createDrawing("Text", {
        Text = "0 fps",
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX - 55, sizeY - 21),
        Visible = true,
        ZIndex = 5
    })
    registerTheme(window.objects.fpsText, "Color", "dimtext")

    window.objects.toggleHint = createDrawing("Text", {
        Text = "[" .. getKeyName(library.menuKeybind) .. "] to toggle",
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX / 2 - 50, sizeY - 21),
        Visible = true,
        ZIndex = 5
    })
    registerTheme(window.objects.toggleHint, "Color", "dimtext")

    -- FPS counter
    local fpsBuffer = {}
    table.insert(library.connections, RunService.RenderStepped:Connect(function(deltaTime)
        if not library.open then return end
        table.insert(fpsBuffer, 1 / deltaTime)
        if #fpsBuffer > 20 then
            table.remove(fpsBuffer, 1)
        end
        local avg = 0
        for _, v in ipairs(fpsBuffer) do
            avg = avg + v
        end
        pcall(function()
            window.objects.fpsText.Text = math.floor(avg / #fpsBuffer) .. " fps"
        end)
    end))

    function window:UpdateToggleHint()
        pcall(function()
            window.objects.toggleHint.Text = "[" .. getKeyName(library.menuKeybind) .. "] to toggle"
        end)
    end

    function window:UpdatePositions()
        local p = window.pos
        pcall(function() window.objects.outerGlow.Position = p - Vector2.new(1, 1) end)
        pcall(function() window.objects.outline.Position = p end)
        pcall(function() window.objects.background.Position = p + Vector2.new(1, 1) end)
        pcall(function() window.objects.topbar.Position = p + Vector2.new(2, 2) end)
        pcall(function() window.objects.accentLine.Position = p + Vector2.new(2, 26) end)
        pcall(function() window.objects.title.Position = p + Vector2.new(10, 6) end)
        pcall(function() window.objects.contentOutline.Position = p + Vector2.new(2, 28) end)
        pcall(function() window.objects.content.Position = p + Vector2.new(3, 29) end)
        pcall(function() window.objects.sidebarOutline.Position = p + Vector2.new(4, 30) end)
        pcall(function() window.objects.sidebar.Position = p + Vector2.new(5, 31) end)
        pcall(function() window.objects.bottomOutline.Position = p + Vector2.new(2, sizeY - 26) end)
        pcall(function() window.objects.bottombar.Position = p + Vector2.new(3, sizeY - 25) end)
        pcall(function() window.objects.version.Position = p + Vector2.new(10, sizeY - 21) end)
        pcall(function() window.objects.fpsText.Position = p + Vector2.new(sizeX - 55, sizeY - 21) end)
        pcall(function() window.objects.toggleHint.Position = p + Vector2.new(sizeX / 2 - 50, sizeY - 21) end)
        for _, page in pairs(window.pages) do
            if page.UpdatePositions then
                page:UpdatePositions()
            end
        end
    end

    function window:SetVisible(state)
        library.open = state
        for _, obj in pairs(window.objects) do
            pcall(function() obj.Visible = state end)
        end
        for _, page in pairs(window.pages) do
            pcall(function() page.objects.tabText.Visible = state end)
            if page.SetVisible then
                page:SetVisible(state and page == window.currentPage)
            end
        end
        if not state then
            if window.activeDropdown then
                window.activeDropdown:Close()
            end
            if window.activeColorPicker then
                window.activeColorPicker:Close()
            end
        end
    end

    function window:Toggle()
        window:SetVisible(not library.open)
    end

    function window:ClosePopups()
        if window.activeDropdown then
            window.activeDropdown:Close()
            window.activeDropdown = nil
        end
        if window.activeColorPicker then
            window.activeColorPicker:Close()
            window.activeColorPicker = nil
        end
        library.blockingInput = false
    end

    --========================================================================--
    --                                PAGE                                    --
    --========================================================================--

    function window:Page(config)
        config = config or {}
        local pageName = config.name or "Page"

        local page = {
            name = pageName,
            visible = false,
            sections = {},
            sectionButtons = {},
            currentSection = nil,
            objects = {},
            window = window
        }

        local tabWidth = getTextBounds(pageName, 13).X + 14

        page.objects.tabBg = createDrawing("Square", {
            Size = Vector2.new(tabWidth, 21),
            Position = window.pos + Vector2.new(0, 4),
            Color = library.theme.section,
            Filled = true,
            Visible = false,
            ZIndex = 4
        })
        registerTheme(page.objects.tabBg, "Color", "section")

        page.objects.tabAccent = createDrawing("Square", {
            Size = Vector2.new(tabWidth - 4, 2),
            Position = window.pos + Vector2.new(2, 5),
            Color = library.accent,
            Filled = true,
            Visible = false,
            ZIndex = 5
        })
        registerAccent(page.objects.tabAccent, "Color")

        page.objects.tabText = createDrawing("Text", {
            Text = pageName,
            Size = 13,
            Font = 2,
            Color = library.theme.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = window.pos + Vector2.new(7, 8),
            Visible = library.open,
            ZIndex = 6
        })
        registerTabText(page.objects.tabText, page)

        page.tabWidth = tabWidth
        page.tabX = 0

        function page:UpdatePositions()
            local p = window.pos
            pcall(function() page.objects.tabBg.Position = p + Vector2.new(page.tabX, 4) end)
            pcall(function() page.objects.tabAccent.Position = p + Vector2.new(page.tabX + 2, 5) end)
            pcall(function() page.objects.tabText.Position = p + Vector2.new(page.tabX + 7, 8) end)
            for _, btn in pairs(page.sectionButtons) do
                if btn.UpdatePositions then
                    btn:UpdatePositions()
                end
            end
            for _, section in pairs(page.sections) do
                if section.UpdatePositions then
                    section:UpdatePositions()
                end
            end
        end

        function page:SetVisible(state)
            page.visible = state
            pcall(function() page.objects.tabBg.Visible = state end)
            pcall(function() page.objects.tabAccent.Visible = state end)
            pcall(function() page.objects.tabText.Visible = library.open end)
            pcall(function()
                page.objects.tabText.Color = state and library.accent or library.theme.dimtext
            end)
            for _, btn in pairs(page.sectionButtons) do
                if btn.SetVisible then
                    btn:SetVisible(state)
                end
            end
            for _, section in pairs(page.sections) do
                if section.SetVisible then
                    section:SetVisible(state and section == page.currentSection)
                end
            end
        end

        -- FIX: Set currentSection BEFORE calling SetVisible
        function page:Show()
            window:ClosePopups()
            for _, p in pairs(window.pages) do
                if p.SetVisible then
                    p:SetVisible(false)
                end
            end

            -- CRITICAL FIX: Set currentSection before SetVisible
            if not page.currentSection and page.sections[1] then
                page.currentSection = page.sections[1]
            end

            page:SetVisible(true)
            window.currentPage = page
        end

        --====================================================================--
        --                            SECTION                                 --
        --====================================================================--

        function page:Section(config)
            config = config or {}
            local sectionName = config.name or "Section"
            local leftTitle = config.left or "general"
            local rightTitle = config.right or "general"

            local section = {
                name = sectionName,
                leftTitle = leftTitle,
                rightTitle = rightTitle,
                visible = false,
                leftElements = {},
                rightElements = {},
                leftOffset = 28,
                rightOffset = 28,
                objects = {},
                page = page,
                window = window
            }

            local btnY = 10 + (#page.sections * 24)
            local sectionBtn = {
                yOffset = btnY,
                objects = {}
            }

            sectionBtn.objects.accent = createDrawing("Square", {
                Size = Vector2.new(2, 18),
                Position = window.pos + Vector2.new(7, 32 + btnY),
                Color = library.accent,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })
            registerAccent(sectionBtn.objects.accent, "Color")

            sectionBtn.objects.text = createDrawing("Text", {
                Text = sectionName,
                Size = 13,
                Font = 2,
                Color = library.theme.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(16, 34 + btnY),
                Visible = page.visible,
                ZIndex = 7
            })

            function sectionBtn:UpdatePositions()
                local p = window.pos
                pcall(function()
                    sectionBtn.objects.accent.Position = p + Vector2.new(7, 32 + sectionBtn.yOffset)
                end)
                pcall(function()
                    sectionBtn.objects.text.Position = p + Vector2.new(16, 34 + sectionBtn.yOffset)
                end)
            end

            function sectionBtn:SetVisible(state)
                pcall(function()
                    sectionBtn.objects.accent.Visible = state and section == page.currentSection
                end)
                pcall(function()
                    sectionBtn.objects.text.Visible = state
                end)
                pcall(function()
                    sectionBtn.objects.text.Color = (section == page.currentSection)
                        and Color3.new(1, 1, 1)
                        or library.theme.dimtext
                end)
            end

            table.insert(page.sectionButtons, sectionBtn)
            section.button = sectionBtn

            local contentX = 126
            local contentWidth = (sizeX - 136) / 2 - 6
            local contentY = 32
            local rightX = contentX + contentWidth + 8
            local contentHeight = sizeY - 90

            -- Left column
            section.objects.leftOutline = createDrawing("Square", {
                Size = Vector2.new(contentWidth + 2, contentHeight),
                Position = window.pos + Vector2.new(contentX, contentY),
                Color = library.theme.outline,
                Filled = true,
                Visible = false,
                ZIndex = 5
            })
            registerTheme(section.objects.leftOutline, "Color", "outline")

            section.objects.left = createDrawing("Square", {
                Size = Vector2.new(contentWidth, contentHeight - 2),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = library.theme.sidebar,
                Filled = true,
                Visible = false,
                ZIndex = 6
            })
            registerTheme(section.objects.left, "Color", "sidebar")

            section.objects.leftHeader = createDrawing("Square", {
                Size = Vector2.new(contentWidth, 22),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = library.theme.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })
            registerTheme(section.objects.leftHeader, "Color", "sectionheader")

            section.objects.leftHeaderAccent = createDrawing("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 23),
                Color = library.accent,
                Transparency = 0.5,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })
            registerAccent(section.objects.leftHeaderAccent, "Color")

            section.objects.leftTitle = createDrawing("Text", {
                Text = leftTitle:upper(),
                Size = 12,
                Font = 2,
                Color = library.theme.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(contentX + 10, contentY + 6),
                Visible = false,
                ZIndex = 8
            })
            registerTheme(section.objects.leftTitle, "Color", "dimtext")

            -- Right column
            section.objects.rightOutline = createDrawing("Square", {
                Size = Vector2.new(contentWidth + 2, contentHeight),
                Position = window.pos + Vector2.new(rightX, contentY),
                Color = library.theme.outline,
                Filled = true,
                Visible = false,
                ZIndex = 5
            })
            registerTheme(section.objects.rightOutline, "Color", "outline")

            section.objects.right = createDrawing("Square", {
                Size = Vector2.new(contentWidth, contentHeight - 2),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = library.theme.sidebar,
                Filled = true,
                Visible = false,
                ZIndex = 6
            })
            registerTheme(section.objects.right, "Color", "sidebar")

            section.objects.rightHeader = createDrawing("Square", {
                Size = Vector2.new(contentWidth, 22),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = library.theme.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })
            registerTheme(section.objects.rightHeader, "Color", "sectionheader")

            section.objects.rightHeaderAccent = createDrawing("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 23),
                Color = library.accent,
                Transparency = 0.5,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })
            registerAccent(section.objects.rightHeaderAccent, "Color")

            section.objects.rightTitle = createDrawing("Text", {
                Text = rightTitle:upper(),
                Size = 12,
                Font = 2,
                Color = library.theme.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(rightX + 10, contentY + 6),
                Visible = false,
                ZIndex = 8
            })
            registerTheme(section.objects.rightTitle, "Color", "dimtext")

            section.contentX = contentX
            section.rightX = rightX
            section.contentY = contentY
            section.contentWidth = contentWidth
            section.contentHeight = contentHeight

            function section:UpdatePositions()
                local p = window.pos
                pcall(function() section.objects.leftOutline.Position = p + Vector2.new(contentX, contentY) end)
                pcall(function() section.objects.left.Position = p + Vector2.new(contentX + 1, contentY + 1) end)
                pcall(function() section.objects.leftHeader.Position = p + Vector2.new(contentX + 1, contentY + 1) end)
                pcall(function() section.objects.leftHeaderAccent.Position = p + Vector2.new(contentX + 1, contentY + 23) end)
                pcall(function() section.objects.leftTitle.Position = p + Vector2.new(contentX + 10, contentY + 6) end)
                pcall(function() section.objects.rightOutline.Position = p + Vector2.new(rightX, contentY) end)
                pcall(function() section.objects.right.Position = p + Vector2.new(rightX + 1, contentY + 1) end)
                pcall(function() section.objects.rightHeader.Position = p + Vector2.new(rightX + 1, contentY + 1) end)
                pcall(function() section.objects.rightHeaderAccent.Position = p + Vector2.new(rightX + 1, contentY + 23) end)
                pcall(function() section.objects.rightTitle.Position = p + Vector2.new(rightX + 10, contentY + 6) end)
                for _, elem in pairs(section.leftElements) do
                    if elem.UpdatePositions then elem:UpdatePositions() end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.UpdatePositions then elem:UpdatePositions() end
                end
            end

            function section:SetVisible(state)
                section.visible = state
                for _, obj in pairs(section.objects) do
                    pcall(function() obj.Visible = state end)
                end
                pcall(function() section.button.objects.accent.Visible = state end)
                pcall(function()
                    section.button.objects.text.Color = state and Color3.new(1, 1, 1) or library.theme.dimtext
                end)
                for _, elem in pairs(section.leftElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
            end

            function section:Show()
                window:ClosePopups()
                for _, s in pairs(page.sections) do
                    if s.SetVisible then s:SetVisible(false) end
                end
                section:SetVisible(true)
                page.currentSection = section
            end

            --============================================================--
            --                          TOGGLE                            --
            --============================================================--

            function section:Toggle(config)
                config = config or {}
                local toggleName = config.name or "Toggle"
                local side = (config.side or "left"):lower()
                local default = config.default or false
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local elemWidth = section.contentWidth - 24

                local toggle = {
                    value = default,
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                toggle.objects.box = createDrawing("Square", {
                    Size = Vector2.new(10, 10),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(toggle.objects.box, "Color", "outline")

                toggle.objects.fill = createDrawing("Square", {
                    Size = Vector2.new(8, 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 3),
                    Color = default and library.accent or library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerToggle(toggle.objects.fill, toggle)

                toggle.objects.label = createDrawing("Text", {
                    Text = toggleName,
                    Size = 13,
                    Font = 2,
                    Color = default and library.theme.text or library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 18, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                toggle.baseX = baseX
                toggle.baseY = section.contentY + offset
                toggle.width = elemWidth

                function toggle:UpdatePositions()
                    local p = window.pos
                    pcall(function() toggle.objects.box.Position = p + Vector2.new(toggle.baseX, toggle.baseY + 2) end)
                    pcall(function() toggle.objects.fill.Position = p + Vector2.new(toggle.baseX + 1, toggle.baseY + 3) end)
                    pcall(function() toggle.objects.label.Position = p + Vector2.new(toggle.baseX + 18, toggle.baseY) end)
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function toggle:Set(value, noCallback)
                    toggle.value = value
                    pcall(function() toggle.objects.fill.Color = value and library.accent or library.theme.elementbg end)
                    pcall(function() toggle.objects.label.Color = value and library.theme.text or library.theme.dimtext end)
                    if flag then library.flags[flag] = value end
                    if not noCallback then pcall(callback, value) end
                end

                function toggle:Get()
                    return toggle.value
                end

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            local pos = toggle.objects.box.Position
                            if isMouseOver(pos.X - 2, pos.Y - 2, toggle.width, 16) then
                                toggle:Set(not toggle.value)
                            end
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = toggle
                end
                if default then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, toggle)
                return toggle
            end

            --============================================================--
            --                          SLIDER                            --
            --============================================================--

            function section:Slider(config)
                config = config or {}
                local sliderName = config.name or "Slider"
                local side = (config.side or "left"):lower()
                local min = config.min or 0
                local max = config.max or 100
                local default = config.default or min
                local increment = config.increment or 1
                local suffix = config.suffix or ""
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local sliderWidth = section.contentWidth - 24

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                slider.objects.label = createDrawing("Text", {
                    Text = sliderName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(slider.objects.label, "Color", "dimtext")

                local valText = tostring(default) .. suffix
                slider.objects.value = createDrawing("Text", {
                    Text = valText,
                    Size = 13,
                    Font = 2,
                    Color = library.accent,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + sliderWidth - getTextBounds(valText, 13).X, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerAccent(slider.objects.value, "Color")

                slider.objects.trackOutline = createDrawing("Square", {
                    Size = Vector2.new(sliderWidth, 12),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(slider.objects.trackOutline, "Color", "outline")

                slider.objects.track = createDrawing("Square", {
                    Size = Vector2.new(sliderWidth - 2, 10),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(slider.objects.track, "Color", "elementbg")

                local pct = (default - min) / (max - min)
                slider.objects.fill = createDrawing("Square", {
                    Size = Vector2.new(math.max((sliderWidth - 2) * pct, 0), 10),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = library.accent,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerAccent(slider.objects.fill, "Color")

                slider.baseX = baseX
                slider.baseY = section.contentY + offset
                slider.width = sliderWidth
                slider.suffix = suffix

                function slider:UpdatePositions()
                    local p = window.pos
                    local valText = tostring(slider.value) .. slider.suffix
                    pcall(function() slider.objects.label.Position = p + Vector2.new(slider.baseX, slider.baseY) end)
                    pcall(function() slider.objects.value.Position = p + Vector2.new(slider.baseX + slider.width - getTextBounds(valText, 13).X, slider.baseY) end)
                    pcall(function() slider.objects.trackOutline.Position = p + Vector2.new(slider.baseX, slider.baseY + 18) end)
                    pcall(function() slider.objects.track.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 19) end)
                    pcall(function() slider.objects.fill.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 19) end)
                end

                function slider:SetVisible(state)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function slider:Set(value, noCallback)
                    value = math.clamp(value, min, max)
                    value = math.floor(value / increment + 0.5) * increment
                    slider.value = value
                    local pct = (value - min) / (max - min)
                    pcall(function() slider.objects.fill.Size = Vector2.new(math.max((slider.width - 2) * pct, 0), 10) end)
                    local valText = tostring(value) .. slider.suffix
                    pcall(function()
                        slider.objects.value.Text = valText
                        slider.objects.value.Position = window.pos + Vector2.new(slider.baseX + slider.width - getTextBounds(valText, 13).X, slider.baseY)
                    end)
                    if flag then library.flags[flag] = value end
                    if not noCallback then pcall(callback, value) end
                end

                function slider:Get()
                    return slider.value
                end

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            local pos = slider.objects.trackOutline.Position
                            if isMouseOver(pos.X, pos.Y, slider.width, 12) then
                                slider.dragging = true
                            end
                        end
                    end
                end))

                table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        slider.dragging = false
                    end
                end))

                table.insert(library.connections, RunService.RenderStepped:Connect(function()
                    if slider.dragging and library.open then
                        local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
                        if success then
                            local pos = slider.objects.trackOutline.Position
                            local pct = math.clamp((mouse.X - pos.X) / slider.width, 0, 1)
                            slider:Set(min + (max - min) * pct)
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = slider
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 36
                else
                    section.rightOffset = section.rightOffset + 36
                end

                table.insert(elements, slider)
                return slider
            end

            --============================================================--
            --                          BUTTON                            --
            --============================================================--

            function section:Button(config)
                config = config or {}
                local buttonName = config.name or "Button"
                local side = (config.side or "left"):lower()
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local btnWidth = section.contentWidth - 24

                local button = {
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                button.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(btnWidth, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(button.objects.outline, "Color", "outline")

                button.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(btnWidth - 2, 20),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 1),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(button.objects.bg, "Color", "elementbg")

                button.objects.label = createDrawing("Text", {
                    Text = buttonName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Center = true,
                    Position = window.pos + Vector2.new(baseX + btnWidth / 2, section.contentY + offset + 4),
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerTheme(button.objects.label, "Color", "dimtext")

                button.baseX = baseX
                button.baseY = section.contentY + offset
                button.width = btnWidth

                function button:UpdatePositions()
                    local p = window.pos
                    pcall(function() button.objects.outline.Position = p + Vector2.new(button.baseX, button.baseY) end)
                    pcall(function() button.objects.bg.Position = p + Vector2.new(button.baseX + 1, button.baseY + 1) end)
                    pcall(function() button.objects.label.Position = p + Vector2.new(button.baseX + button.width / 2, button.baseY + 4) end)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            local pos = button.objects.outline.Position
                            if isMouseOver(pos.X, pos.Y, button.width, 22) then
                                pcall(function()
                                    button.objects.bg.Color = library.accent
                                    button.objects.label.Color = library.theme.text
                                end)
                                pcall(callback)
                                task.delay(0.15, function()
                                    pcall(function()
                                        button.objects.bg.Color = library.theme.elementbg
                                        button.objects.label.Color = library.theme.dimtext
                                    end)
                                end)
                            end
                        end
                    end
                end))

                if side == "left" then
                    section.leftOffset = section.leftOffset + 28
                else
                    section.rightOffset = section.rightOffset + 28
                end

                table.insert(elements, button)
                return button
            end

            --============================================================--
            --                          LABEL                             --
            --============================================================--

            function section:Label(config)
                config = config or {}
                local labelText = config.text or "Label"
                local side = (config.side or "left"):lower()

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)

                local label = {
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                label.objects.text = createDrawing("Text", {
                    Text = labelText,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(label.objects.text, "Color", "dimtext")

                label.baseX = baseX
                label.baseY = section.contentY + offset

                function label:UpdatePositions()
                    local p = window.pos
                    pcall(function() label.objects.text.Position = p + Vector2.new(label.baseX, label.baseY + 2) end)
                end

                function label:SetVisible(state)
                    for _, obj in pairs(label.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function label:SetText(text)
                    pcall(function() label.objects.text.Text = text end)
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, label)
                return label
            end

            --============================================================--
            --                        SEPARATOR                           --
            --============================================================--

            function section:Separator(config)
                config = config or {}
                local side = (config.side or "left"):lower()

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local sepWidth = section.contentWidth - 24

                local separator = {
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                separator.objects.line = createDrawing("Square", {
                    Size = Vector2.new(sepWidth, 1),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 8),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(separator.objects.line, "Color", "outline")

                separator.baseX = baseX
                separator.baseY = section.contentY + offset
                separator.width = sepWidth

                function separator:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        separator.objects.line.Position = p + Vector2.new(separator.baseX, separator.baseY + 8)
                    end)
                end

                function separator:SetVisible(state)
                    for _, obj in pairs(separator.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 16
                else
                    section.rightOffset = section.rightOffset + 16
                end

                table.insert(elements, separator)
                return separator
            end

            --============================================================--
            --                        DROPDOWN                            --
            --============================================================--

            function section:Dropdown(config)
                config = config or {}
                local dropdownName = config.name or "Dropdown"
                local side = (config.side or "left"):lower()
                local items = config.items or {}
                local default = config.default or (items[1] or "")
                local multi = config.multi or false
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local ddWidth = section.contentWidth - 24

                local dropdown = {
                    value = multi and {} or default,
                    items = items,
                    multi = multi,
                    open = false,
                    side = side,
                    yOffset = offset,
                    objects = {},
                    itemObjects = {},
                    blockArea = nil
                }

                dropdown.objects.label = createDrawing("Text", {
                    Text = dropdownName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(dropdown.objects.label, "Color", "dimtext")

                dropdown.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(ddWidth, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(dropdown.objects.outline, "Color", "outline")

                dropdown.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(ddWidth - 2, 20),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(dropdown.objects.bg, "Color", "elementbg")

                local displayText = multi and (#dropdown.value > 0 and table.concat(dropdown.value, ", ") or "None") or default
                dropdown.objects.selected = createDrawing("Text", {
                    Text = displayText,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 8, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerTheme(dropdown.objects.selected, "Color", "text")

                dropdown.objects.arrow = createDrawing("Text", {
                    Text = "v",
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + ddWidth - 14, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerTheme(dropdown.objects.arrow, "Color", "dimtext")

                dropdown.baseX = baseX
                dropdown.baseY = section.contentY + offset
                dropdown.width = ddWidth

                function dropdown:UpdatePositions()
                    local p = window.pos
                    pcall(function() dropdown.objects.label.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY) end)
                    pcall(function() dropdown.objects.outline.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY + 18) end)
                    pcall(function() dropdown.objects.bg.Position = p + Vector2.new(dropdown.baseX + 1, dropdown.baseY + 19) end)
                    pcall(function() dropdown.objects.selected.Position = p + Vector2.new(dropdown.baseX + 8, dropdown.baseY + 22) end)
                    pcall(function() dropdown.objects.arrow.Position = p + Vector2.new(dropdown.baseX + dropdown.width - 14, dropdown.baseY + 22) end)
                end

                function dropdown:SetVisible(state)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                    if not state then dropdown:Close() end
                end

                function dropdown:Close()
                    dropdown.open = false
                    library.blockingInput = false
                    dropdown.blockArea = nil
                    for _, obj in pairs(dropdown.itemObjects) do
                        pcall(function() obj:Remove() end)
                    end
                    dropdown.itemObjects = {}
                    if window.activeDropdown == dropdown then
                        window.activeDropdown = nil
                    end
                end

                function dropdown:Open()
                    if dropdown.open then
                        dropdown:Close()
                        return
                    end
                    window:ClosePopups()
                    dropdown.open = true
                    window.activeDropdown = dropdown
                    library.blockingInput = true
                    local pos = dropdown.objects.outline.Position
                    local listH = math.min(#items * 20 + 4, 164)
                    dropdown.blockArea = { x = pos.X, y = pos.Y + 24, w = dropdown.width, h = listH }

                    local listBg = createDrawing("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 24),
                        Color = library.theme.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(dropdown.itemObjects, listBg)

                    local listOutline = createDrawing("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 24),
                        Color = library.theme.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 51
                    })
                    table.insert(dropdown.itemObjects, listOutline)

                    for i, item in ipairs(items) do
                        local isSelected = multi and table.find(dropdown.value, item) or dropdown.value == item
                        local itemText = createDrawing("Text", {
                            Text = item,
                            Size = 13,
                            Font = 2,
                            Color = isSelected and library.accent or library.theme.text,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = Vector2.new(pos.X + 8, pos.Y + 28 + (i - 1) * 20),
                            Visible = true,
                            ZIndex = 52
                        })
                        table.insert(dropdown.itemObjects, itemText)
                    end
                end

                function dropdown:Set(value, noCallback)
                    if multi then
                        dropdown.value = type(value) == "table" and value or {value}
                        pcall(function() dropdown.objects.selected.Text = #dropdown.value > 0 and table.concat(dropdown.value, ", ") or "None" end)
                    else
                        dropdown.value = value
                        pcall(function() dropdown.objects.selected.Text = value end)
                    end
                    if flag then library.flags[flag] = dropdown.value end
                    if not noCallback then pcall(callback, dropdown.value) end
                end

                function dropdown:Get()
                    return dropdown.value
                end

                function dropdown:Refresh(newItems)
                    dropdown.items = newItems
                    items = newItems
                    if dropdown.open then
                        dropdown:Close()
                        dropdown:Open()
                    end
                end

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible then
                            local pos = dropdown.objects.outline.Position
                            if isMouseOver(pos.X, pos.Y, dropdown.width, 22) then
                                dropdown:Open()
                                return
                            end
                            if dropdown.open then
                                for i, item in ipairs(items) do
                                    local itemY = pos.Y + 24 + (i - 1) * 20
                                    if isMouseOver(pos.X, itemY, dropdown.width, 20) then
                                        if multi then
                                            local idx = table.find(dropdown.value, item)
                                            if idx then table.remove(dropdown.value, idx) else table.insert(dropdown.value, item) end
                                            dropdown:Set(dropdown.value)
                                            dropdown:Close()
                                            dropdown:Open()
                                        else
                                            dropdown:Set(item)
                                            dropdown:Close()
                                        end
                                        return
                                    end
                                end
                                if dropdown.blockArea and not isMouseOver(dropdown.blockArea.x, dropdown.blockArea.y, dropdown.blockArea.w, dropdown.blockArea.h) then
                                    dropdown:Close()
                                end
                            end
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = multi and {} or default
                    library.pointers[flag] = dropdown
                end
                if not multi and default ~= "" then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 46
                else
                    section.rightOffset = section.rightOffset + 46
                end

                table.insert(elements, dropdown)
                return dropdown
            end

            --============================================================--
            --                         KEYBIND                            --
            --============================================================--

            function section:Keybind(config)
                config = config or {}
                local keybindName = config.name or "Keybind"
                local side = (config.side or "left"):lower()
                local default = config.default or Enum.KeyCode.Unknown
                local flag = config.flag
                local callback = config.callback or function() end
                local isMenuToggle = config.isMenuToggle or false

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local kbWidth = section.contentWidth - 24

                local keybind = {
                    value = default,
                    listening = false,
                    side = side,
                    yOffset = offset,
                    objects = {},
                    ignoreNextClick = false
                }

                keybind.objects.label = createDrawing("Text", {
                    Text = keybindName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(keybind.objects.label, "Color", "dimtext")

                local keyText = "[" .. getKeyName(default) .. "]"
                keybind.objects.key = createDrawing("Text", {
                    Text = keyText,
                    Size = 13,
                    Font = 2,
                    Color = library.accent,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + kbWidth - getTextBounds(keyText, 13).X, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerAccent(keybind.objects.key, "Color")

                keybind.baseX = baseX
                keybind.baseY = section.contentY + offset
                keybind.width = kbWidth

                function keybind:UpdatePositions()
                    local p = window.pos
                    local keyText = "[" .. getKeyName(keybind.value) .. "]"
                    pcall(function() keybind.objects.label.Position = p + Vector2.new(keybind.baseX, keybind.baseY + 2) end)
                    pcall(function() keybind.objects.key.Position = p + Vector2.new(keybind.baseX + keybind.width - getTextBounds(keyText, 13).X, keybind.baseY + 2) end)
                end

                function keybind:SetVisible(state)
                    for _, obj in pairs(keybind.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function keybind:Set(key)
                    keybind.value = key
                    local keyText = "[" .. getKeyName(key) .. "]"
                    pcall(function()
                        keybind.objects.key.Text = keyText
                        keybind.objects.key.Position = window.pos + Vector2.new(keybind.baseX + keybind.width - getTextBounds(keyText, 13).X, keybind.baseY + 2)
                        keybind.objects.key.Color = library.accent
                    end)
                    if flag then library.flags[flag] = key end
                    if isMenuToggle then
                        library.menuKeybind = key
                        window:UpdateToggleHint()
                    end
                end

                function keybind:Get()
                    return keybind.value
                end

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            if not keybind.listening then
                                local pos = keybind.objects.label.Position
                                if isMouseOver(pos.X - 10, pos.Y - 4, keybind.width, 22) then
                                    keybind.listening = true
                                    keybind.ignoreNextClick = true
                                    pcall(function()
                                        keybind.objects.key.Text = "[...]"
                                        keybind.objects.key.Color = library.theme.warning
                                    end)
                                    return
                                end
                            end
                        end
                    end

                    if keybind.listening then
                        if keybind.ignoreNextClick and input.UserInputType == Enum.UserInputType.MouseButton1 then return end
                        local key = nil
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then key = Enum.KeyCode.Unknown else key = input.KeyCode end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            if not keybind.ignoreNextClick then key = input.UserInputType end
                        end
                        if key then
                            keybind:Set(key)
                            keybind.listening = false
                            keybind.ignoreNextClick = false
                        end
                        return
                    end

                    if keybind.value ~= Enum.KeyCode.Unknown and not keybind.listening then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(callback, keybind.value)
                        end
                    end
                end))

                table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and keybind.ignoreNextClick then
                        task.delay(0.1, function() keybind.ignoreNextClick = false end)
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = keybind
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, keybind)
                return keybind
            end

            --============================================================--
            --                        TEXTBOX                             --
            --============================================================--

            function section:Textbox(config)
                config = config or {}
                local textboxName = config.name or "Textbox"
                local side = (config.side or "left"):lower()
                local default = config.default or ""
                local placeholder = config.placeholder or "Enter text..."
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local tbWidth = section.contentWidth - 24

                local textbox = {
                    value = default,
                    focused = false,
                    side = side,
                    yOffset = offset,
                    placeholder = placeholder,
                    objects = {}
                }

                textbox.objects.label = createDrawing("Text", {
                    Text = textboxName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(textbox.objects.label, "Color", "dimtext")

                textbox.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(tbWidth, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(textbox.objects.outline, "Color", "outline")

                textbox.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(tbWidth - 2, 20),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(textbox.objects.bg, "Color", "elementbg")

                textbox.objects.text = createDrawing("Text", {
                    Text = default ~= "" and default or placeholder,
                    Size = 13,
                    Font = 2,
                    Color = default ~= "" and library.theme.text or library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 8, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 11
                })

                textbox.baseX = baseX
                textbox.baseY = section.contentY + offset
                textbox.width = tbWidth

                function textbox:UpdatePositions()
                    local p = window.pos
                    pcall(function() textbox.objects.label.Position = p + Vector2.new(textbox.baseX, textbox.baseY) end)
                    pcall(function() textbox.objects.outline.Position = p + Vector2.new(textbox.baseX, textbox.baseY + 18) end)
                    pcall(function() textbox.objects.bg.Position = p + Vector2.new(textbox.baseX + 1, textbox.baseY + 19) end)
                    pcall(function() textbox.objects.text.Position = p + Vector2.new(textbox.baseX + 8, textbox.baseY + 22) end)
                end

                function textbox:SetVisible(state)
                    for _, obj in pairs(textbox.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function textbox:Set(value, noCallback)
                    textbox.value = value
                    pcall(function()
                        textbox.objects.text.Text = value ~= "" and value or textbox.placeholder
                        textbox.objects.text.Color = value ~= "" and library.theme.text or library.theme.dimtext
                    end)
                    if flag then library.flags[flag] = value end
                    if not noCallback then pcall(callback, value) end
                end

                function textbox:Get()
                    return textbox.value
                end

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible then
                            local pos = textbox.objects.outline.Position
                            if isMouseOver(pos.X, pos.Y, textbox.width, 22) then
                                textbox.focused = true
                                library.blockingInput = true
                                pcall(function() textbox.objects.outline.Color = library.accent end)
                            else
                                if textbox.focused then
                                    textbox.focused = false
                                    library.blockingInput = false
                                    pcall(function() textbox.objects.outline.Color = library.theme.outline end)
                                end
                            end
                        end
                    end

                    if textbox.focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Escape then
                            textbox.focused = false
                            library.blockingInput = false
                            pcall(function() textbox.objects.outline.Color = library.theme.outline end)
                        elseif input.KeyCode == Enum.KeyCode.Backspace then
                            textbox:Set(textbox.value:sub(1, -2))
                        else
                            local char = UserInputService:GetStringForKeyCode(input.KeyCode)
                            if char and #char == 1 then
                                local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
                                if shift then char = char:upper() else char = char:lower() end
                                textbox:Set(textbox.value .. char)
                            end
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = textbox
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 46
                else
                    section.rightOffset = section.rightOffset + 46
                end

                table.insert(elements, textbox)
                return textbox
            end

            -- Section button click handler
            table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if library.open and page.visible and not library.blockingInput then
                        local btnPos = sectionBtn.objects.text.Position
                        if isMouseOver(btnPos.X - 10, btnPos.Y - 4, 100, 22) then
                            section:Show()
                        end
                    end
                end
            end))

            -- Set as first section if none selected
            if #page.sections == 0 then
                page.currentSection = section
            end

            table.insert(page.sections, section)
            return section
        end

        -- Tab click handler
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if library.open and not library.blockingInput then
                    local pos = page.objects.tabText.Position
                    if isMouseOver(pos.X - 5, pos.Y - 5, page.tabWidth, 20) then
                        page:Show()
                    end
                end
            end
        end))

        -- Calculate tab position
        local tabOffset = 125
        for _, p in pairs(window.pages) do
            tabOffset = tabOffset + p.tabWidth + 4
        end
        page.tabX = tabOffset

        table.insert(window.pages, page)

        -- Show first page
        if #window.pages == 1 then
            page:Show()
        end

        return page
    end

    --========================================================================--
    --                           WINDOW INIT                                  --
    --========================================================================--

    function window:Init()
        -- Dragging
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if library.open and not library.blockingInput then
                    local pos = window.pos
                    if isMouseOver(pos.X, pos.Y, sizeX, 26) then
                        window.dragging = true
                        local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
                        if success then
                            window.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
                        end
                    end
                end
            end
        end))

        table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                window.dragging = false
            end
        end))

        table.insert(library.connections, RunService.RenderStepped:Connect(function()
            if window.dragging then
                local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
                if success then
                    window.pos = Vector2.new(mouse.X - window.dragOffset.X, mouse.Y - window.dragOffset.Y)
                    window:UpdatePositions()
                end
            end
        end))

        -- Menu toggle
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == library.menuKeybind then
                window:Toggle()
            end
        end))

        table.insert(library.windows, window)
        return window
    end

    function window:Unload()
        for _, conn in pairs(library.connections) do
            pcall(function() conn:Disconnect() end)
        end
        for _, drawing in pairs(library.drawings) do
            pcall(function() drawing:Remove() end)
        end
        library.connections = {}
        library.drawings = {}
        library.flags = {}
        library.pointers = {}
    end

    return window
end

return library
