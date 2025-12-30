--[[
╔═══════════════════════════════════════════════════════════════════════════╗
║                            NexusLib v4.3.5                                ║
║              Enhanced Drawing UI Library for Roblox                       ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Features:                                                                ║
║  • Modern dark theme with multiple color schemes                          ║
║  • Draggable windows, watermark, and keybind list                         ║
║  • Full element set: Toggle, Slider, Button, Dropdown, Keybind,           ║
║    ColorPicker, Textbox, Label                                            ║
║  • Notification system with animations                                    ║
║  • Config save/load system                                                ║
║  • Real-time theme and accent color switching                             ║
║  • Tabs on RIGHT side of topbar                                           ║
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
--                               SERVICES                                     --
--============================================================================--
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

--============================================================================--
--                           UTILITY FUNCTIONS                                --
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
        pcall(function() obj[key] = value end)
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
    pcall(function() obj:Remove() end)
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
    if keyNames[key] then return keyNames[key] end
    if typeof(key) == "EnumItem" then return key.Name end
    return "None"
end

--============================================================================--
--                         REGISTRATION FUNCTIONS                             --
--============================================================================--
local function registerAccent(obj, property)
    table.insert(library.accentObjects, { obj = obj, property = property })
end

local function registerTheme(obj, property, themeKey)
    table.insert(library.themeObjects, { obj = obj, property = property, themeKey = themeKey })
end

local function registerTabText(obj, page)
    table.insert(library.tabTextObjects, { obj = obj, page = page })
end

local function registerToggle(obj, toggle)
    table.insert(library.toggleObjects, { obj = obj, toggle = toggle })
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
--                              WATERMARK                                     --
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
        if #fpsBuffer > 30 then table.remove(fpsBuffer, 1) end
        if tick() - lastUpdate < 0.5 then return end
        lastUpdate = tick()
        local avgFps = 0
        for _, v in ipairs(fpsBuffer) do avgFps = avgFps + v end
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
                local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
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
            local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
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
--                            NOTIFICATIONS                                   --
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

    local notification = { objects = {}, startTime = tick() }
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
            if math.abs(currentX - targetX) < 1 then currentX = targetX end
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
            if math.abs(currentX - outTarget) < 1 then currentX = outTarget end
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
--                             KEYBIND LIST                                   --
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
        local item = { name = name, key = key, active = false, objects = {} }
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
                pcall(function() obj.Visible = list.enabled and state end)
            end
            list:UpdateHeight()
        end

        table.insert(list.items, item)
        return item
    end

    function list:UpdateHeight()
        local activeCount = 0
        for _, item in pairs(list.items) do
            if item.active then activeCount = activeCount + 1 end
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
                local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
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
            local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
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
--                             CONFIG SYSTEM                                  --
--============================================================================--
function library:SaveConfig(name, folder)
    folder = folder or "NexusLib"
    pcall(function()
        if not isfolder(folder) then makefolder(folder) end
    end)
    local data = {}
    for flag, value in pairs(library.flags) do
        if typeof(value) == "Color3" then
            data[flag] = { type = "Color3", R = value.R, G = value.G, B = value.B }
        elseif typeof(value) == "EnumItem" then
            data[flag] = { type = "Enum", value = tostring(value) }
        else
            data[flag] = value
        end
    end
    pcall(function()
        writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    library:Notify({ title = "Config Saved", message = name, type = "success", duration = 3 })
end

function library:LoadConfig(name, folder)
    folder = folder or "NexusLib"
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(folder .. "/" .. name .. ".json"))
    end)
    if not success then
        library:Notify({ title = "Config Error", message = "Failed to load: " .. name, type = "error", duration = 3 })
        return
    end
    for flag, value in pairs(data) do
        if typeof(value) == "table" and value.type == "Color3" then
            library.flags[flag] = Color3.new(value.R, value.G, value.B)
        else
            library.flags[flag] = value
        end
        if library.pointers[flag] and library.pointers[flag].Set then
            pcall(function() library.pointers[flag]:Set(library.flags[flag]) end)
        end
    end
    library:Notify({ title = "Config Loaded", message = name, type = "success", duration = 3 })
end

--============================================================================--
--                              MAIN WINDOW                                   --
--============================================================================--
function library:New(config)
    config = config or {}
    local windowName = config.name or "NexusLib"
    local sizeX = config.sizeX or 580
    local sizeY = config.sizeY or 460
    if config.accent then library.accent = config.accent end

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

    -- Outer glow
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

    -- Main outline
    window.objects.outline = createDrawing("Square", {
        Size = window.size,
        Position = window.pos,
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 1,
        Visible = true
    })
    registerTheme(window.objects.outline, "Color", "outline")

    -- Background
    window.objects.background = createDrawing("Square", {
        Size = Vector2.new(sizeX - 2, sizeY - 2),
        Position = window.pos + Vector2.new(1, 1),
        Color = library.theme.background,
        Filled = true,
        ZIndex = 2,
        Visible = true
    })
    registerTheme(window.objects.background, "Color", "background")

    -- Top bar
    window.objects.topbar = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, 24),
        Position = window.pos + Vector2.new(2, 2),
        Color = library.theme.topbar,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })
    registerTheme(window.objects.topbar, "Color", "topbar")

    -- Accent line
    window.objects.accentLine = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, 2),
        Position = window.pos + Vector2.new(2, 26),
        Color = library.accent,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })
    registerAccent(window.objects.accentLine, "Color")

    -- Title
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

    -- Content area outline
    window.objects.contentOutline = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, sizeY - 54),
        Position = window.pos + Vector2.new(2, 28),
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })
    registerTheme(window.objects.contentOutline, "Color", "outline")

    -- Content area
    window.objects.content = createDrawing("Square", {
        Size = Vector2.new(sizeX - 6, sizeY - 56),
        Position = window.pos + Vector2.new(3, 29),
        Color = library.theme.section,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })
    registerTheme(window.objects.content, "Color", "section")

    -- Sidebar outline
    window.objects.sidebarOutline = createDrawing("Square", {
        Size = Vector2.new(118, sizeY - 58),
        Position = window.pos + Vector2.new(4, 30),
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 5,
        Visible = true
    })
    registerTheme(window.objects.sidebarOutline, "Color", "outline")

    -- Sidebar
    window.objects.sidebar = createDrawing("Square", {
        Size = Vector2.new(116, sizeY - 60),
        Position = window.pos + Vector2.new(5, 31),
        Color = library.theme.sidebar,
        Filled = true,
        ZIndex = 6,
        Visible = true
    })
    registerTheme(window.objects.sidebar, "Color", "sidebar")

    -- Bottom bar outline
    window.objects.bottomOutline = createDrawing("Square", {
        Size = Vector2.new(sizeX - 4, 24),
        Position = window.pos + Vector2.new(2, sizeY - 26),
        Color = library.theme.outline,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })
    registerTheme(window.objects.bottomOutline, "Color", "outline")

    -- Bottom bar
    window.objects.bottombar = createDrawing("Square", {
        Size = Vector2.new(sizeX - 6, 22),
        Position = window.pos + Vector2.new(3, sizeY - 25),
        Color = library.theme.topbar,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })
    registerTheme(window.objects.bottombar, "Color", "topbar")

    -- Version text
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

    -- FPS text
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

    -- Toggle hint
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
        if #fpsBuffer > 20 then table.remove(fpsBuffer, 1) end
        local avg = 0
        for _, v in ipairs(fpsBuffer) do avg = avg + v end
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
            if page.UpdatePositions then page:UpdatePositions() end
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
            if window.activeDropdown then window.activeDropdown:Close() end
            if window.activeColorPicker then window.activeColorPicker:Close() end
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
    --                               PAGE                                     --
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

        -- Tab background (hidden by default)
        page.objects.tabBg = createDrawing("Square", {
            Size = Vector2.new(tabWidth, 21),
            Position = window.pos + Vector2.new(0, 4),
            Color = library.theme.section,
            Filled = true,
            Visible = false,
            ZIndex = 4
        })
        registerTheme(page.objects.tabBg, "Color", "section")

        -- Tab accent line
        page.objects.tabAccent = createDrawing("Square", {
            Size = Vector2.new(tabWidth - 4, 2),
            Position = window.pos + Vector2.new(2, 5),
            Color = library.accent,
            Filled = true,
            Visible = false,
            ZIndex = 5
        })
        registerAccent(page.objects.tabAccent, "Color")

        -- Tab text
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
                if btn.UpdatePositions then btn:UpdatePositions() end
            end
            for _, section in pairs(page.sections) do
                if section.UpdatePositions then section:UpdatePositions() end
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
                if btn.SetVisible then btn:SetVisible(state) end
            end
            for _, section in pairs(page.sections) do
                if section.SetVisible then
                    section:SetVisible(state and section == page.currentSection)
                end
            end
        end

        function page:Show()
            window:ClosePopups()
            for _, p in pairs(window.pages) do
                if p.SetVisible then p:SetVisible(false) end
            end
            page:SetVisible(true)
            window.currentPage = page
            if page.currentSection then
                page.currentSection:SetVisible(true)
            elseif page.sections[1] then
                page.sections[1]:Show()
            end
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

            -- Section button in sidebar
            local btnY = 10 + (#page.sections * 24)
            local sectionBtn = { yOffset = btnY, objects = {} }

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
                pcall(function() sectionBtn.objects.text.Visible = state end)
                pcall(function()
                    sectionBtn.objects.text.Color = (section == page.currentSection) and Color3.new(1, 1, 1) or library.theme.dimtext
                end)
            end

            table.insert(page.sectionButtons, sectionBtn)
            section.button = sectionBtn

            -- Content area dimensions
            local contentX = 126
            local contentWidth = ((sizeX - 136) / 2) - 6
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
                Text = string.upper(leftTitle),
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
                Text = string.upper(rightTitle),
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
            section.contentWidth = contentWidth
            section.contentY = contentY
            section.rightX = rightX
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
                for _, elem in pairs(section.leftElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                if section.button then
                    section.button:SetVisible(page.visible)
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

            -- Section button click handler
            table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and page.visible then
                    local p = window.pos
                    local btnX = p.X + 5
                    local btnY = p.Y + 32 + sectionBtn.yOffset
                    if isMouseOver(btnX, btnY, 116, 20) then
                        section:Show()
                    end
                end
            end))

            --================================================================--
            --                           TOGGLE                               --
            --================================================================--
            function section:Toggle(config)
                config = config or {}
                local name = config.name or "Toggle"
                local default = config.default or false
                local flag = config.flag or name
                local side = config.side or "left"
                local callback = config.callback or function() end

                local isLeft = side == "left"
                local baseX = isLeft and contentX or rightX
                local offset = isLeft and section.leftOffset or section.rightOffset

                local toggle = {
                    value = default,
                    objects = {},
                    flag = flag
                }

                toggle.objects.label = createDrawing("Text", {
                    Text = name,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(toggle.objects.label, "Color", "text")

                toggle.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(10, 10),
                    Position = window.pos + Vector2.new(baseX + contentWidth - 20, contentY + offset + 2),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(toggle.objects.outline, "Color", "outline")

                toggle.objects.fill = createDrawing("Square", {
                    Size = Vector2.new(8, 8),
                    Position = window.pos + Vector2.new(baseX + contentWidth - 19, contentY + offset + 3),
                    Color = default and library.accent or library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerToggle(toggle.objects.fill, toggle)

                function toggle:Set(value)
                    toggle.value = value
                    library.flags[flag] = value
                    pcall(function()
                        toggle.objects.fill.Color = value and library.accent or library.theme.elementbg
                    end)
                    pcall(function() callback(value) end)
                end

                function toggle:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        toggle.objects.label.Position = p + Vector2.new(baseX + 10, contentY + toggle.yOffset)
                    end)
                    pcall(function()
                        toggle.objects.outline.Position = p + Vector2.new(baseX + contentWidth - 20, contentY + toggle.yOffset + 2)
                    end)
                    pcall(function()
                        toggle.objects.fill.Position = p + Vector2.new(baseX + contentWidth - 19, contentY + toggle.yOffset + 3)
                    end)
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                toggle.yOffset = offset
                toggle:Set(default)
                library.flags[flag] = default
                library.pointers[flag] = toggle

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local p = window.pos
                        local toggleX = p.X + baseX + contentWidth - 20
                        local toggleY = p.Y + contentY + toggle.yOffset + 2
                        if isMouseOver(toggleX - 5, toggleY - 5, 20, 20) then
                            toggle:Set(not toggle.value)
                        end
                    end
                end))

                if isLeft then
                    section.leftOffset = section.leftOffset + 22
                    table.insert(section.leftElements, toggle)
                else
                    section.rightOffset = section.rightOffset + 22
                    table.insert(section.rightElements, toggle)
                end

                return toggle
            end

            --================================================================--
            --                           SLIDER                               --
            --================================================================--
            function section:Slider(config)
                config = config or {}
                local name = config.name or "Slider"
                local min = config.min or 0
                local max = config.max or 100
                local default = config.default or min
                local suffix = config.suffix or ""
                local flag = config.flag or name
                local side = config.side or "left"
                local callback = config.callback or function() end

                local isLeft = side == "left"
                local baseX = isLeft and contentX or rightX
                local offset = isLeft and section.leftOffset or section.rightOffset

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    objects = {},
                    flag = flag
                }

                slider.objects.label = createDrawing("Text", {
                    Text = name,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(slider.objects.label, "Color", "text")

                slider.objects.value = createDrawing("Text", {
                    Text = tostring(default) .. suffix,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + contentWidth - 10, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(slider.objects.value, "Color", "dimtext")

                local sliderWidth = contentWidth - 20
                slider.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(sliderWidth, 6),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset + 18),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(slider.objects.bg, "Color", "elementbg")

                local fillWidth = ((default - min) / (max - min)) * sliderWidth
                slider.objects.fill = createDrawing("Square", {
                    Size = Vector2.new(fillWidth, 6),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset + 18),
                    Color = library.accent,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerAccent(slider.objects.fill, "Color")

                function slider:Set(value)
                    value = math.clamp(value, min, max)
                    slider.value = value
                    library.flags[flag] = value
                    local percent = (value - min) / (max - min)
                    pcall(function()
                        slider.objects.fill.Size = Vector2.new(sliderWidth * percent, 6)
                    end)
                    pcall(function()
                        slider.objects.value.Text = tostring(math.floor(value)) .. suffix
                        local textWidth = getTextBounds(slider.objects.value.Text, 13).X
                        slider.objects.value.Position = window.pos + Vector2.new(baseX + contentWidth - 10 - textWidth, contentY + slider.yOffset)
                    end)
                    pcall(function() callback(value) end)
                end

                function slider:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        slider.objects.label.Position = p + Vector2.new(baseX + 10, contentY + slider.yOffset)
                    end)
                    pcall(function()
                        local textWidth = getTextBounds(slider.objects.value.Text, 13).X
                        slider.objects.value.Position = p + Vector2.new(baseX + contentWidth - 10 - textWidth, contentY + slider.yOffset)
                    end)
                    pcall(function()
                        slider.objects.bg.Position = p + Vector2.new(baseX + 10, contentY + slider.yOffset + 18)
                    end)
                    pcall(function()
                        slider.objects.fill.Position = p + Vector2.new(baseX + 10, contentY + slider.yOffset + 18)
                    end)
                end

                function slider:SetVisible(state)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                slider.yOffset = offset
                slider:Set(default)
                library.flags[flag] = default
                library.pointers[flag] = slider

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local p = window.pos
                        local sliderX = p.X + baseX + 10
                        local sliderY = p.Y + contentY + slider.yOffset + 18
                        if isMouseOver(sliderX, sliderY - 5, sliderWidth, 16) then
                            slider.dragging = true
                        end
                    end
                end))

                table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        slider.dragging = false
                    end
                end))

                table.insert(library.connections, RunService.RenderStepped:Connect(function()
                    if slider.dragging and library.open and section.visible then
                        local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
                        if success then
                            local p = window.pos
                            local sliderX = p.X + baseX + 10
                            local relativeX = math.clamp(mouse.X - sliderX, 0, sliderWidth)
                            local percent = relativeX / sliderWidth
                            local value = min + (max - min) * percent
                            slider:Set(value)
                        end
                    end
                end))

                if isLeft then
                    section.leftOffset = section.leftOffset + 32
                    table.insert(section.leftElements, slider)
                else
                    section.rightOffset = section.rightOffset + 32
                    table.insert(section.rightElements, slider)
                end

                return slider
            end

            --================================================================--
            --                           BUTTON                               --
            --================================================================--
            function section:Button(config)
                config = config or {}
                local name = config.name or "Button"
                local side = config.side or "left"
                local callback = config.callback or function() end

                local isLeft = side == "left"
                local baseX = isLeft and contentX or rightX
                local offset = isLeft and section.leftOffset or section.rightOffset

                local button = { objects = {} }

                button.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(contentWidth - 20, 22),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(button.objects.outline, "Color", "outline")

                button.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(contentWidth - 22, 20),
                    Position = window.pos + Vector2.new(baseX + 11, contentY + offset + 1),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerTheme(button.objects.bg, "Color", "elementbg")

                local textWidth = getTextBounds(name, 13).X
                button.objects.label = createDrawing("Text", {
                    Text = name,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 10 + (contentWidth - 20) / 2 - textWidth / 2, contentY + offset + 4),
                    Visible = section.visible,
                    ZIndex = 12
                })
                registerTheme(button.objects.label, "Color", "text")

                function button:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        button.objects.outline.Position = p + Vector2.new(baseX + 10, contentY + button.yOffset)
                    end)
                    pcall(function()
                        button.objects.bg.Position = p + Vector2.new(baseX + 11, contentY + button.yOffset + 1)
                    end)
                    pcall(function()
                        button.objects.label.Position = p + Vector2.new(baseX + 10 + (contentWidth - 20) / 2 - textWidth / 2, contentY + button.yOffset + 4)
                    end)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                button.yOffset = offset

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local p = window.pos
                        local btnX = p.X + baseX + 10
                        local btnY = p.Y + contentY + button.yOffset
                        if isMouseOver(btnX, btnY, contentWidth - 20, 22) then
                            pcall(function() button.objects.bg.Color = library.accent end)
                            task.delay(0.1, function()
                                pcall(function() button.objects.bg.Color = library.theme.elementbg end)
                            end)
                            pcall(callback)
                        end
                    end
                end))

                if isLeft then
                    section.leftOffset = section.leftOffset + 28
                    table.insert(section.leftElements, button)
                else
                    section.rightOffset = section.rightOffset + 28
                    table.insert(section.rightElements, button)
                end

                return button
            end

            --================================================================--
            --                          DROPDOWN                              --
            --================================================================--
            function section:Dropdown(config)
                config = config or {}
                local name = config.name or "Dropdown"
                local options = config.options or {}
                local default = config.default or (options[1] or "")
                local flag = config.flag or name
                local side = config.side or "left"
                local callback = config.callback or function() end

                local isLeft = side == "left"
                local baseX = isLeft and contentX or rightX
                local offset = isLeft and section.leftOffset or section.rightOffset

                local dropdown = {
                    value = default,
                    options = options,
                    open = false,
                    objects = {},
                    optionObjects = {},
                    flag = flag
                }

                dropdown.objects.label = createDrawing("Text", {
                    Text = name,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(dropdown.objects.label, "Color", "text")

                dropdown.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(contentWidth - 20, 22),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(dropdown.objects.outline, "Color", "outline")

                dropdown.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(contentWidth - 22, 20),
                    Position = window.pos + Vector2.new(baseX + 11, contentY + offset + 19),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 11
                })
                registerTheme(dropdown.objects.bg, "Color", "elementbg")

                dropdown.objects.selected = createDrawing("Text", {
                    Text = default,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 16, contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 12
                })
                registerTheme(dropdown.objects.selected, "Color", "dimtext")

                dropdown.objects.arrow = createDrawing("Text", {
                    Text = "v",
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + contentWidth - 20, contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 12
                })
                registerTheme(dropdown.objects.arrow, "Color", "dimtext")

                function dropdown:Set(value)
                    dropdown.value = value
                    library.flags[flag] = value
                    pcall(function() dropdown.objects.selected.Text = value end)
                    pcall(function() callback(value) end)
                end

                function dropdown:Open()
                    if window.activeDropdown and window.activeDropdown ~= dropdown then
                        window.activeDropdown:Close()
                    end
                    dropdown.open = true
                    window.activeDropdown = dropdown
                    library.blockingInput = true

                    local p = window.pos
                    local dropY = contentY + dropdown.yOffset + 40

                    dropdown.objects.listOutline = createDrawing("Square", {
                        Size = Vector2.new(contentWidth - 20, #options * 20 + 2),
                        Position = p + Vector2.new(baseX + 10, dropY),
                        Color = library.theme.outline,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })

                    dropdown.objects.listBg = createDrawing("Square", {
                        Size = Vector2.new(contentWidth - 22, #options * 20),
                        Position = p + Vector2.new(baseX + 11, dropY + 1),
                        Color = library.theme.background,
                        Filled = true,
                        Visible = true,
                        ZIndex = 51
                    })

                    for i, opt in ipairs(options) do
                        local optObj = {}
                        optObj.bg = createDrawing("Square", {
                            Size = Vector2.new(contentWidth - 22, 20),
                            Position = p + Vector2.new(baseX + 11, dropY + 1 + (i - 1) * 20),
                            Color = library.theme.background,
                            Filled = true,
                            Visible = true,
                            ZIndex = 52
                        })
                        optObj.text = createDrawing("Text", {
                            Text = opt,
                            Size = 13,
                            Font = 2,
                            Color = opt == dropdown.value and library.accent or library.theme.dimtext,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = p + Vector2.new(baseX + 16, dropY + 4 + (i - 1) * 20),
                            Visible = true,
                            ZIndex = 53
                        })
                        optObj.option = opt
                        optObj.index = i
                        table.insert(dropdown.optionObjects, optObj)
                    end
                end

                function dropdown:Close()
                    dropdown.open = false
                    if window.activeDropdown == dropdown then
                        window.activeDropdown = nil
                        library.blockingInput = false
                    end
                    pcall(function() removeDrawing(dropdown.objects.listOutline) end)
                    pcall(function() removeDrawing(dropdown.objects.listBg) end)
                    for _, optObj in pairs(dropdown.optionObjects) do
                        pcall(function() removeDrawing(optObj.bg) end)
                        pcall(function() removeDrawing(optObj.text) end)
                    end
                    dropdown.optionObjects = {}
                end

                function dropdown:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        dropdown.objects.label.Position = p + Vector2.new(baseX + 10, contentY + dropdown.yOffset)
                    end)
                    pcall(function()
                        dropdown.objects.outline.Position = p + Vector2.new(baseX + 10, contentY + dropdown.yOffset + 18)
                    end)
                    pcall(function()
                        dropdown.objects.bg.Position = p + Vector2.new(baseX + 11, contentY + dropdown.yOffset + 19)
                    end)
                    pcall(function()
                        dropdown.objects.selected.Position = p + Vector2.new(baseX + 16, contentY + dropdown.yOffset + 22)
                    end)
                    pcall(function()
                        dropdown.objects.arrow.Position = p + Vector2.new(baseX + contentWidth - 20, contentY + dropdown.yOffset + 22)
                    end)
                end

                function dropdown:SetVisible(state)
                    for key, obj in pairs(dropdown.objects) do
                        if key ~= "listOutline" and key ~= "listBg" then
                            pcall(function() obj.Visible = state end)
                        end
                    end
                    if not state and dropdown.open then
                        dropdown:Close()
                    end
                end

                dropdown.yOffset = offset
                dropdown:Set(default)
                library.flags[flag] = default
                library.pointers[flag] = dropdown

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
                        local p = window.pos

                        if dropdown.open then
                            local dropY = contentY + dropdown.yOffset + 40
                            for _, optObj in pairs(dropdown.optionObjects) do
                                local optX = p.X + baseX + 11
                                local optY = p.Y + dropY + 1 + (optObj.index - 1) * 20
                                if isMouseOver(optX, optY, contentWidth - 22, 20) then
                                    dropdown:Set(optObj.option)
                                    dropdown:Close()
                                    return
                                end
                            end
                            dropdown:Close()
                        elseif section.visible then
                            local btnX = p.X + baseX + 10
                            local btnY = p.Y + contentY + dropdown.yOffset + 18
                            if isMouseOver(btnX, btnY, contentWidth - 20, 22) then
                                dropdown:Open()
                            end
                        end
                    end
                end))

                if isLeft then
                    section.leftOffset = section.leftOffset + 48
                    table.insert(section.leftElements, dropdown)
                else
                    section.rightOffset = section.rightOffset + 48
                    table.insert(section.rightElements, dropdown)
                end

                return dropdown
            end

            --================================================================--
            --                           KEYBIND                              --
            --================================================================--
            function section:Keybind(config)
                config = config or {}
                local name = config.name or "Keybind"
                local default = config.default or Enum.KeyCode.Unknown
                local flag = config.flag or name
                local side = config.side or "left"
                local callback = config.callback or function() end
                local changedCallback = config.changed or function() end

                local isLeft = side == "left"
                local baseX = isLeft and contentX or rightX
                local offset = isLeft and section.leftOffset or section.rightOffset

                local keybind = {
                    value = default,
                    listening = false,
                    objects = {},
                    flag = flag
                }

                keybind.objects.label = createDrawing("Text", {
                    Text = name,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(keybind.objects.label, "Color", "text")

                local keyText = "[" .. getKeyName(default) .. "]"
                keybind.objects.key = createDrawing("Text", {
                    Text = keyText,
                    Size = 13,
                    Font = 2,
                    Color = library.accent,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + contentWidth - 10 - getTextBounds(keyText, 13).X, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerAccent(keybind.objects.key, "Color")

                function keybind:Set(key)
                    keybind.value = key
                    library.flags[flag] = key
                    local newText = "[" .. getKeyName(key) .. "]"
                    pcall(function()
                        keybind.objects.key.Text = newText
                        keybind.objects.key.Position = window.pos + Vector2.new(
                            baseX + contentWidth - 10 - getTextBounds(newText, 13).X,
                            contentY + keybind.yOffset
                        )
                    end)
                    pcall(function() changedCallback(key) end)
                end

                function keybind:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        keybind.objects.label.Position = p + Vector2.new(baseX + 10, contentY + keybind.yOffset)
                    end)
                    pcall(function()
                        local keyText = "[" .. getKeyName(keybind.value) .. "]"
                        keybind.objects.key.Position = p + Vector2.new(
                            baseX + contentWidth - 10 - getTextBounds(keyText, 13).X,
                            contentY + keybind.yOffset
                        )
                    end)
                end

                function keybind:SetVisible(state)
                    for _, obj in pairs(keybind.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                keybind.yOffset = offset
                keybind:Set(default)
                library.flags[flag] = default
                library.pointers[flag] = keybind

                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if keybind.listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            keybind:Set(input.KeyCode)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or
                               input.UserInputType == Enum.UserInputType.MouseButton2 or
                               input.UserInputType == Enum.UserInputType.MouseButton3 then
                            keybind:Set(input.UserInputType)
                        end
                        keybind.listening = false
                        pcall(function() keybind.objects.key.Text = "[" .. getKeyName(keybind.value) .. "]" end)
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local p = window.pos
                        local keyText = "[" .. getKeyName(keybind.value) .. "]"
                        local keyWidth = getTextBounds(keyText, 13).X
                        local keyX = p.X + baseX + contentWidth - 10 - keyWidth
                        local keyY = p.Y + contentY + keybind.yOffset
                        if isMouseOver(keyX - 5, keyY - 5, keyWidth + 10, 20) then
                            keybind.listening = true
                            pcall(function() keybind.objects.key.Text = "[...]" end)
                        end
                    end

                    if keybind.value and keybind.value ~= Enum.KeyCode.Unknown then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(function() callback(keybind.value) end)
                        end
                    end
                end))

                if isLeft then
                    section.leftOffset = section.leftOffset + 22
                    table.insert(section.leftElements, keybind)
                else
                    section.rightOffset = section.rightOffset + 22
                    table.insert(section.rightElements, keybind)
                end

                return keybind
            end

            --================================================================--
            --                           LABEL                                --
            --================================================================--
            function section:Label(config)
                config = config or {}
                local text = config.text or "Label"
                local side = config.side or "left"

                local isLeft = side == "left"
                local baseX = isLeft and contentX or rightX
                local offset = isLeft and section.leftOffset or section.rightOffset

                local label = { objects = {} }

                label.objects.text = createDrawing("Text", {
                    Text = text,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 10, contentY + offset),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(label.objects.text, "Color", "dimtext")

                function label:Set(newText)
                    pcall(function() label.objects.text.Text = newText end)
                end

                function label:UpdatePositions()
                    local p = window.pos
                    pcall(function()
                        label.objects.text.Position = p + Vector2.new(baseX + 10, contentY + label.yOffset)
                    end)
                end

                function label:SetVisible(state)
                    pcall(function() label.objects.text.Visible = state end)
                end

                label.yOffset = offset

                if isLeft then
                    section.leftOffset = section.leftOffset + 22
                    table.insert(section.leftElements, label)
                else
                    section.rightOffset = section.rightOffset + 22
                    table.insert(section.rightElements, label)
                end

                return label
            end

            table.insert(page.sections, section)
            if not page.currentSection then
                page.currentSection = section
            end

            return section
        end

        table.insert(window.pages, page)
        return page
    end

    --========================================================================--
    --                               INIT                                     --
    --========================================================================--
    function window:Init()
        -- Position tabs on the RIGHT side of topbar
        local totalTabWidth = 0
        for _, page in ipairs(window.pages) do
            totalTabWidth = totalTabWidth + page.tabWidth + 4
        end

        local startX = sizeX - totalTabWidth - 6
        local tabX = startX

        for _, page in ipairs(window.pages) do
            page.tabX = tabX
            page:UpdatePositions()
            tabX = tabX + page.tabWidth + 4
        end

        -- Show first page
        if window.pages[1] then
            window.pages[1]:Show()
        end

        -- Tab click handler
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
                local p = window.pos
                for _, page in pairs(window.pages) do
                    local tabX = p.X + page.tabX
                    local tabY = p.Y + 4
                    if isMouseOver(tabX, tabY, page.tabWidth, 21) then
                        page:Show()
                        break
                    end
                end
            end
        end))

        -- Window dragging
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and not library.blockingInput then
                local p = window.pos
                if isMouseOver(p.X, p.Y, sizeX, 26) then
                    window.dragging = true
                    local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
                    if success then
                        window.dragOffset = Vector2.new(mouse.X - p.X, mouse.Y - p.Y)
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
                    window.pos = Vector2.new(
                        mouse.X - window.dragOffset.X,
                        mouse.Y - window.dragOffset.Y
                    )
                    window:UpdatePositions()
                end
            end
        end))

        -- Menu toggle keybind
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == library.menuKeybind then
                window:Toggle()
            end
        end))

        -- Create watermark and keybind list
        library:CreateWatermark({ title = windowName })
        library:CreateKeybindList()

        table.insert(library.windows, window)

        return window
    end

    --========================================================================--
    --                              UNLOAD                                    --
    --========================================================================--
    function window:Unload()
        for _, connection in pairs(library.connections) do
            pcall(function() connection:Disconnect() end)
        end
        library.connections = {}

        for _, drawing in pairs(library.drawings) do
            pcall(function() drawing:Remove() end)
        end
        library.drawings = {}

        library.flags = {}
        library.pointers = {}
        library.notifications = {}
        library.windows = {}
        library.accentObjects = {}
        library.themeObjects = {}
        library.tabTextObjects = {}
        library.toggleObjects = {}
        library.colorPickerPreviews = {}
    end

    return window
end

return library
