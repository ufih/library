--[[
╔═══════════════════════════════════════════════════════════════════════════╗
║                            NexusLib v4.3.5                                ║
║                  Enhanced Drawing UI Library for Roblox                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  FIXES in v4.3.5:                                                         ║
║  • Fixed section overlap issues - only one section visible at a time      ║
║  • Fixed content box heights to match sidebar                             ║
║  • Fixed consistent margins (6px gaps everywhere)                         ║
║  • Fixed element spacing (22px for small, 36/46px for large elements)    ║
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
    drawings = {},
    connections = {},
    flags = {},
    pointers = {},
    notifications = {},
    windows = {},

    accentObjects = {},
    themeObjects = {},
    tabTextObjects = {},
    toggleObjects = {},
    colorPickerPreviews = {},

    open = true,
    blockingInput = false,

    accent = Color3.fromRGB(76, 162, 252),
    menuKeybind = Enum.KeyCode.RightShift,

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
    else r, g, b = v, p, q
    end
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
--                          REGISTRATION FUNCTIONS                            --
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
--                           NOTIFICATION SYSTEM                              --
--============================================================================--

function library:Notify(config)
    config = config or {}
    local title = config.title or "Notification"
    local message = config.message or ""
    local notifType = config.type or "info"
    local duration = config.duration or 4

    local colors = {
        info = library.accent,
        success = library.theme.success,
        warning = library.theme.warning,
        error = library.theme.error
    }

    local accentColor = colors[notifType] or library.accent
    local textWidth = math.max(getTextBounds(title, 14).X, getTextBounds(message, 13).X)
    local width = math.max(200, textWidth + 40)
    local height = 60
    local padding = 10

    local existingCount = #library.notifications
    local startY = padding + (existingCount * (height + 6))
    local startX = -width - padding

    local notif = { objects = {} }

    notif.objects.bg = createDrawing("Square", {
        Size = Vector2.new(width, height),
        Position = Vector2.new(startX, startY),
        Color = library.theme.background,
        Filled = true,
        Visible = true,
        ZIndex = 100
    })

    notif.objects.outline = createDrawing("Square", {
        Size = Vector2.new(width, height),
        Position = Vector2.new(startX, startY),
        Color = library.theme.outline,
        Filled = false,
        Thickness = 1,
        Visible = true,
        ZIndex = 101
    })

    notif.objects.accent = createDrawing("Square", {
        Size = Vector2.new(3, height - 2),
        Position = Vector2.new(startX + 1, startY + 1),
        Color = accentColor,
        Filled = true,
        Visible = true,
        ZIndex = 102
    })

    notif.objects.title = createDrawing("Text", {
        Text = title,
        Size = 14,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(startX + 14, startY + 10),
        Visible = true,
        ZIndex = 102
    })

    notif.objects.message = createDrawing("Text", {
        Text = message,
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(startX + 14, startY + 32),
        Visible = true,
        ZIndex = 102
    })

    table.insert(library.notifications, notif)
    local notifIndex = #library.notifications

    local targetX = padding

    task.spawn(function()
        -- Slide in
        for i = 0, 1, 0.08 do
            local x = lerp(startX, targetX, i)
            pcall(function()
                notif.objects.bg.Position = Vector2.new(x, startY)
                notif.objects.outline.Position = Vector2.new(x, startY)
                notif.objects.accent.Position = Vector2.new(x + 1, startY + 1)
                notif.objects.title.Position = Vector2.new(x + 14, startY + 10)
                notif.objects.message.Position = Vector2.new(x + 14, startY + 32)
            end)
            task.wait(0.016)
        end

        task.wait(duration)

        -- Slide out
        for i = 0, 1, 0.08 do
            local x = lerp(targetX, -width - padding, i)
            pcall(function()
                notif.objects.bg.Position = Vector2.new(x, startY)
                notif.objects.outline.Position = Vector2.new(x, startY)
                notif.objects.accent.Position = Vector2.new(x + 1, startY + 1)
                notif.objects.title.Position = Vector2.new(x + 14, startY + 10)
                notif.objects.message.Position = Vector2.new(x + 14, startY + 32)
            end)
            task.wait(0.016)
        end

        -- Remove
        for _, obj in pairs(notif.objects) do
            pcall(function() obj:Remove() end)
        end

        table.remove(library.notifications, notifIndex)

        -- Reposition remaining
        for i, n in ipairs(library.notifications) do
            local newY = padding + ((i - 1) * (height + 6))
            pcall(function()
                n.objects.bg.Position = Vector2.new(padding, newY)
                n.objects.outline.Position = Vector2.new(padding, newY)
                n.objects.accent.Position = Vector2.new(padding + 1, newY + 1)
                n.objects.title.Position = Vector2.new(padding + 14, newY + 10)
                n.objects.message.Position = Vector2.new(padding + 14, newY + 32)
            end)
        end
    end)
end

--============================================================================--
--                              WATERMARK                                     --
--============================================================================--

function library:CreateWatermark(config)
    config = config or {}
    local title = config.title or "NexusLib"

    if library.watermark._initialized then return library.watermark end
    library.watermark._initialized = true

    local wm = library.watermark
    local width = 220
    local height = 24

    wm.objects.bg = createDrawing("Square", {
        Size = Vector2.new(width, height),
        Position = wm.position,
        Color = library.theme.background,
        Filled = true,
        Visible = wm.enabled,
        ZIndex = 90
    })
    registerTheme(wm.objects.bg, "Color", "background")

    wm.objects.outline = createDrawing("Square", {
        Size = Vector2.new(width, height),
        Position = wm.position,
        Color = library.theme.outline,
        Filled = false,
        Thickness = 1,
        Visible = wm.enabled,
        ZIndex = 91
    })
    registerTheme(wm.objects.outline, "Color", "outline")

    wm.objects.accent = createDrawing("Square", {
        Size = Vector2.new(width - 2, 2),
        Position = wm.position + Vector2.new(1, 1),
        Color = library.accent,
        Filled = true,
        Visible = wm.enabled,
        ZIndex = 92
    })
    registerAccent(wm.objects.accent, "Color")

    wm.objects.text = createDrawing("Text", {
        Text = title .. " | 0 fps | 0ms",
        Size = 13,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = wm.position + Vector2.new(8, 6),
        Visible = wm.enabled,
        ZIndex = 93
    })
    registerTheme(wm.objects.text, "Color", "text")

    -- Update loop
    task.spawn(function()
        while task.wait(0.5) do
            if wm.enabled and wm.objects.text then
                local fps = math.floor(1 / RunService.RenderStepped:Wait())
                local ping = 0
                pcall(function()
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                pcall(function()
                    wm.objects.text.Text = title .. " | " .. fps .. " fps | " .. ping .. "ms"
                end)
            end
        end
    end)

    -- Dragging
    table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and wm.enabled then
            local pos = wm.objects.bg.Position
            if isMouseOver(pos.X, pos.Y, width, height) then
                wm.dragging = true
                local mouse = UserInputService:GetMouseLocation()
                wm.dragOffset = mouse - pos
            end
        end
    end))

    table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            wm.dragging = false
        end
    end))

    table.insert(library.connections, RunService.RenderStepped:Connect(function()
        if wm.dragging and wm.enabled then
            local mouse = UserInputService:GetMouseLocation()
            wm.position = mouse - wm.dragOffset
            pcall(function()
                wm.objects.bg.Position = wm.position
                wm.objects.outline.Position = wm.position
                wm.objects.accent.Position = wm.position + Vector2.new(1, 1)
                wm.objects.text.Position = wm.position + Vector2.new(8, 6)
            end)
        end
    end))

    return wm
end

--============================================================================--
--                             KEYBIND LIST                                   --
--============================================================================--

function library:CreateKeybindList(config)
    config = config or {}
    local title = config.title or "Keybinds"

    if library.keybindList._initialized then return library.keybindList end
    library.keybindList._initialized = true

    local kb = library.keybindList
    local width = 180
    local headerHeight = 24

    kb.objects.bg = createDrawing("Square", {
        Size = Vector2.new(width, headerHeight),
        Position = kb.position,
        Color = library.theme.background,
        Filled = true,
        Visible = kb.enabled,
        ZIndex = 90
    })
    registerTheme(kb.objects.bg, "Color", "background")

    kb.objects.outline = createDrawing("Square", {
        Size = Vector2.new(width, headerHeight),
        Position = kb.position,
        Color = library.theme.outline,
        Filled = false,
        Thickness = 1,
        Visible = kb.enabled,
        ZIndex = 91
    })
    registerTheme(kb.objects.outline, "Color", "outline")

    kb.objects.accent = createDrawing("Square", {
        Size = Vector2.new(width - 2, 2),
        Position = kb.position + Vector2.new(1, 1),
        Color = library.accent,
        Filled = true,
        Visible = kb.enabled,
        ZIndex = 92
    })
    registerAccent(kb.objects.accent, "Color")

    kb.objects.title = createDrawing("Text", {
        Text = title,
        Size = 13,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = kb.position + Vector2.new(8, 6),
        Visible = kb.enabled,
        ZIndex = 93
    })
    registerTheme(kb.objects.title, "Color", "text")

    function kb:AddItem(name, key)
        local item = {
            name = name,
            key = key,
            active = false,
            objects = {}
        }

        local idx = #kb.items + 1
        local y = kb.position.Y + headerHeight + (idx - 1) * 20

        item.objects.bg = createDrawing("Square", {
            Size = Vector2.new(width, 20),
            Position = Vector2.new(kb.position.X, y),
            Color = library.theme.elementbg,
            Filled = true,
            Visible = false,
            ZIndex = 90
        })

        item.objects.name = createDrawing("Text", {
            Text = name,
            Size = 13,
            Font = 2,
            Color = library.theme.text,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = Vector2.new(kb.position.X + 8, y + 3),
            Visible = false,
            ZIndex = 91
        })

        item.objects.key = createDrawing("Text", {
            Text = "[" .. getKeyName(key) .. "]",
            Size = 13,
            Font = 2,
            Color = library.accent,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = Vector2.new(kb.position.X + width - 8, y + 3),
            Visible = false,
            ZIndex = 91
        })

        table.insert(kb.items, item)
        return item
    end

    function kb:UpdateSize()
        local activeCount = 0
        for _, item in ipairs(kb.items) do
            if item.active then
                activeCount = activeCount + 1
            end
        end
        local totalHeight = headerHeight + (activeCount * 20)
        pcall(function()
            kb.objects.bg.Size = Vector2.new(width, totalHeight)
            kb.objects.outline.Size = Vector2.new(width, totalHeight)
        end)
    end

    return kb
end

--============================================================================--
--                           CONFIG FUNCTIONS                                 --
--============================================================================--

function library:SaveConfig(name, folder)
    local configData = {}
    for flag, value in pairs(library.flags) do
        if typeof(value) == "Color3" then
            configData[flag] = { type = "Color3", r = value.R * 255, g = value.G * 255, b = value.B * 255 }
        elseif typeof(value) == "EnumItem" then
            configData[flag] = { type = "EnumItem", enumType = tostring(value.EnumType), name = value.Name }
        elseif typeof(value) == "table" then
            configData[flag] = { type = "table", value = value }
        else
            configData[flag] = { type = typeof(value), value = value }
        end
    end

    local json = HttpService:JSONEncode(configData)
    local folderPath = folder or "NexusLib"
    local fileName = name .. ".json"

    pcall(function()
        if not isfolder(folderPath) then
            makefolder(folderPath)
        end
        writefile(folderPath .. "/" .. fileName, json)
    end)

    library:Notify({
        title = "Config Saved",
        message = "Saved as: " .. name,
        type = "success"
    })
end

function library:LoadConfig(name, folder)
    local folderPath = folder or "NexusLib"
    local fileName = name .. ".json"
    local fullPath = folderPath .. "/" .. fileName

    local success, data = pcall(function()
        if isfile(fullPath) then
            return readfile(fullPath)
        end
        return nil
    end)

    if not success or not data then
        library:Notify({
            title = "Config Error",
            message = "Config not found: " .. name,
            type = "error"
        })
        return
    end

    local configData = HttpService:JSONDecode(data)

    for flag, valueData in pairs(configData) do
        local pointer = library.pointers[flag]
        if pointer and pointer.Set then
            local value

            if valueData.type == "Color3" then
                value = Color3.fromRGB(valueData.r, valueData.g, valueData.b)
            elseif valueData.type == "EnumItem" then
                pcall(function()
                    local enumType = Enum[valueData.enumType:gsub("Enum.", "")]
                    value = enumType[valueData.name]
                end)
            elseif valueData.type == "table" then
                value = valueData.value
            else
                value = valueData.value
            end

            if value ~= nil then
                pcall(function() pointer:Set(value) end)
            end
        end
    end

    library:Notify({
        title = "Config Loaded",
        message = "Loaded: " .. name,
        type = "success"
    })
end

--============================================================================--
--                             CREATE WINDOW                                  --
--============================================================================--

function library:New(config)
    config = config or {}
    local windowName = config.name or "NexusLib"
    local sizeX = config.sizeX or 580
    local sizeY = config.sizeY or 460

    if config.accent then
        library.accent = config.accent
    end

    --========================================================================--
    --                        LAYOUT CONSTANTS                                --
    --========================================================================--

    -- FIXED: Consistent 6px margins everywhere
    local MARGIN = 6
    local TOPBAR_HEIGHT = 28
    local FOOTER_HEIGHT = 20
    local SIDEBAR_WIDTH = 120
    local TAB_HEIGHT = 24

    -- Content area calculations
    local contentStartY = TOPBAR_HEIGHT + MARGIN
    local contentEndY = sizeY - FOOTER_HEIGHT - MARGIN
    local contentHeight = contentEndY - contentStartY  -- This is the height for both sidebar and main content

    local sidebarX = MARGIN
    local sidebarY = contentStartY
    local sidebarH = contentHeight

    local mainX = MARGIN + SIDEBAR_WIDTH + MARGIN
    local mainY = contentStartY
    local mainW = sizeX - mainX - MARGIN
    local mainH = contentHeight

    -- Section header height
    local SECTION_HEADER_H = 22
    local COLUMN_HEADER_H = 16

    --========================================================================--
    --                            WINDOW OBJECT                               --
    --========================================================================--

    local window = {
        pos = Vector2.new(100, 100),
        pages = {},
        currentPage = nil,
        dragging = false,
        dragOffset = Vector2.new(0, 0),
        objects = {},
        activeDropdown = nil,
        activeColorPicker = nil
    }

    --========================================================================--
    --                          MAIN FRAME                                    --
    --========================================================================--

    -- Background
    window.objects.bg = createDrawing("Square", {
        Size = Vector2.new(sizeX, sizeY),
        Position = window.pos,
        Color = library.theme.background,
        Filled = true,
        Visible = library.open,
        ZIndex = 1
    })
    registerTheme(window.objects.bg, "Color", "background")

    -- Main outline
    window.objects.outline = createDrawing("Square", {
        Size = Vector2.new(sizeX, sizeY),
        Position = window.pos,
        Color = library.theme.outline,
        Filled = false,
        Thickness = 1,
        Visible = library.open,
        ZIndex = 2
    })
    registerTheme(window.objects.outline, "Color", "outline")

    -- Topbar
    window.objects.topbar = createDrawing("Square", {
        Size = Vector2.new(sizeX - 2, TOPBAR_HEIGHT),
        Position = window.pos + Vector2.new(1, 1),
        Color = library.theme.topbar,
        Filled = true,
        Visible = library.open,
        ZIndex = 2
    })
    registerTheme(window.objects.topbar, "Color", "topbar")

    -- Title
    window.objects.title = createDrawing("Text", {
        Text = windowName,
        Size = 14,
        Font = 2,
        Color = library.accent,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(10, 7),
        Visible = library.open,
        ZIndex = 3
    })
    registerAccent(window.objects.title, "Color")

    -- Topbar accent line
    window.objects.topbarAccent = createDrawing("Square", {
        Size = Vector2.new(sizeX - 2, 1),
        Position = window.pos + Vector2.new(1, TOPBAR_HEIGHT),
        Color = library.accent,
        Filled = true,
        Visible = library.open,
        ZIndex = 3
    })
    registerAccent(window.objects.topbarAccent, "Color")

    -- Footer background
    window.objects.footer = createDrawing("Square", {
        Size = Vector2.new(sizeX - 2, FOOTER_HEIGHT),
        Position = window.pos + Vector2.new(1, sizeY - FOOTER_HEIGHT - 1),
        Color = library.theme.topbar,
        Filled = true,
        Visible = library.open,
        ZIndex = 2
    })
    registerTheme(window.objects.footer, "Color", "topbar")

    -- Footer top line
    window.objects.footerLine = createDrawing("Square", {
        Size = Vector2.new(sizeX - 2, 1),
        Position = window.pos + Vector2.new(1, sizeY - FOOTER_HEIGHT - 1),
        Color = library.theme.outline,
        Filled = true,
        Visible = library.open,
        ZIndex = 3
    })
    registerTheme(window.objects.footerLine, "Color", "outline")

    -- Version text
    window.objects.version = createDrawing("Text", {
        Text = "v4.3.5",
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(10, sizeY - FOOTER_HEIGHT + 3),
        Visible = library.open,
        ZIndex = 3
    })
    registerTheme(window.objects.version, "Color", "dimtext")

    -- Toggle hint
    window.objects.toggleHint = createDrawing("Text", {
        Text = "[" .. getKeyName(library.menuKeybind) .. "] to toggle",
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX / 2 - 40, sizeY - FOOTER_HEIGHT + 3),
        Visible = library.open,
        ZIndex = 3
    })
    registerTheme(window.objects.toggleHint, "Color", "dimtext")

    -- FPS counter
    window.objects.fps = createDrawing("Text", {
        Text = "0 fps",
        Size = 13,
        Font = 2,
        Color = library.theme.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX - 50, sizeY - FOOTER_HEIGHT + 3),
        Visible = library.open,
        ZIndex = 3
    })
    registerTheme(window.objects.fps, "Color", "dimtext")

    -- FPS update loop
    task.spawn(function()
        while task.wait(0.5) do
            if window.objects.fps and library.open then
                local fps = math.floor(1 / RunService.RenderStepped:Wait())
                pcall(function()
                    window.objects.fps.Text = fps .. " fps"
                end)
            end
        end
    end)

    --========================================================================--
    --                          WINDOW METHODS                                --
    --========================================================================--

    function window:UpdatePositions()
        local p = window.pos

        pcall(function() window.objects.bg.Position = p end)
        pcall(function() window.objects.outline.Position = p end)
        pcall(function() window.objects.topbar.Position = p + Vector2.new(1, 1) end)
        pcall(function() window.objects.title.Position = p + Vector2.new(10, 7) end)
        pcall(function() window.objects.topbarAccent.Position = p + Vector2.new(1, TOPBAR_HEIGHT) end)
        pcall(function() window.objects.footer.Position = p + Vector2.new(1, sizeY - FOOTER_HEIGHT - 1) end)
        pcall(function() window.objects.footerLine.Position = p + Vector2.new(1, sizeY - FOOTER_HEIGHT - 1) end)
        pcall(function() window.objects.version.Position = p + Vector2.new(10, sizeY - FOOTER_HEIGHT + 3) end)
        pcall(function() window.objects.toggleHint.Position = p + Vector2.new(sizeX / 2 - 40, sizeY - FOOTER_HEIGHT + 3) end)
        pcall(function() window.objects.fps.Position = p + Vector2.new(sizeX - 50, sizeY - FOOTER_HEIGHT + 3) end)

        -- Update pages
        for _, page in ipairs(window.pages) do
            pcall(function() page:UpdatePositions() end)
        end
    end

    function window:SetVisible(state)
        library.open = state
        for _, obj in pairs(window.objects) do
            pcall(function() obj.Visible = state end)
        end
        for _, page in ipairs(window.pages) do
            pcall(function() page:SetVisible(state and page.visible) end)
        end
    end

    function window:Toggle()
        window:SetVisible(not library.open)
    end

    function window:UpdateToggleHint()
        pcall(function()
            window.objects.toggleHint.Text = "[" .. getKeyName(library.menuKeybind) .. "] to toggle"
        end)
    end

    function window:ClosePopups()
        if window.activeDropdown then
            pcall(function() window.activeDropdown:Close() end)
            window.activeDropdown = nil
        end
        if window.activeColorPicker then
            pcall(function() window.activeColorPicker:Close() end)
            window.activeColorPicker = nil
        end
        library.blockingInput = false
    end

    --========================================================================--
    --                            PAGE SYSTEM                                 --
    --========================================================================--

    function window:Page(config)
        config = config or {}
        local pageName = config.name or "Page"

        local page = {
            name = pageName,
            visible = false,
            sections = {},
            objects = {},
            currentSection = nil
        }

        -- Calculate tab width
        page.tabWidth = getTextBounds(pageName, 13).X + 16
        page.tabX = 0  -- Will be set in Init

        -- Tab background
        page.objects.tabBg = createDrawing("Square", {
            Size = Vector2.new(page.tabWidth, TAB_HEIGHT),
            Position = window.pos + Vector2.new(0, 4),
            Color = library.theme.topbar,
            Filled = true,
            Visible = false,
            ZIndex = 4
        })
        registerTheme(page.objects.tabBg, "Color", "topbar")

        -- Tab accent (only visible when active)
        page.objects.tabAccent = createDrawing("Square", {
            Size = Vector2.new(page.tabWidth - 4, 2),
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
            Position = window.pos + Vector2.new(8, 9),
            Visible = false,
            ZIndex = 5
        })
        registerTabText(page.objects.tabText, page)

        -- Sidebar background (matches contentHeight)
        page.objects.sidebar = createDrawing("Square", {
            Size = Vector2.new(SIDEBAR_WIDTH, sidebarH),
            Position = window.pos + Vector2.new(sidebarX, sidebarY),
            Color = library.theme.sidebar,
            Filled = true,
            Visible = false,
            ZIndex = 2
        })
        registerTheme(page.objects.sidebar, "Color", "sidebar")

        -- Sidebar outline
        page.objects.sidebarOutline = createDrawing("Square", {
            Size = Vector2.new(SIDEBAR_WIDTH, sidebarH),
            Position = window.pos + Vector2.new(sidebarX, sidebarY),
            Color = library.theme.outline,
            Filled = false,
            Thickness = 1,
            Visible = false,
            ZIndex = 3
        })
        registerTheme(page.objects.sidebarOutline, "Color", "outline")

        function page:UpdatePositions()
            local p = window.pos
            pcall(function() page.objects.tabBg.Position = p + Vector2.new(page.tabX, 4) end)
            pcall(function() page.objects.tabAccent.Position = p + Vector2.new(page.tabX + 2, 5) end)
            pcall(function() page.objects.tabText.Position = p + Vector2.new(page.tabX + 8, 9) end)
            pcall(function() page.objects.sidebar.Position = p + Vector2.new(sidebarX, sidebarY) end)
            pcall(function() page.objects.sidebarOutline.Position = p + Vector2.new(sidebarX, sidebarY) end)

            for _, section in pairs(page.sections) do
                pcall(function() section:UpdatePositions() end)
            end
        end

        function page:SetVisible(state)
            page.visible = state

            pcall(function() page.objects.tabBg.Visible = library.open end)
            pcall(function() page.objects.tabText.Visible = library.open end)
            pcall(function() page.objects.tabAccent.Visible = library.open and state end)
            pcall(function() page.objects.sidebar.Visible = library.open and state end)
            pcall(function() page.objects.sidebarOutline.Visible = library.open and state end)

            pcall(function()
                page.objects.tabText.Color = state and library.accent or library.theme.dimtext
            end)

            -- FIXED: Only show current section, hide others
            for _, section in pairs(page.sections) do
                local showSection = library.open and state and section == page.currentSection
                pcall(function() section:SetVisible(showSection) end)
            end
        end

        function page:Show()
            -- Hide other pages
            for _, p in ipairs(window.pages) do
                if p ~= page then
                    p:SetVisible(false)
                end
            end

            page:SetVisible(true)
            window.currentPage = page
            window:ClosePopups()

            -- Show first section if no current section
            if not page.currentSection and page.sections[1] then
                page.sections[1]:Show()
            end
        end

        --====================================================================--
        --                          SECTION SYSTEM                            --
        --====================================================================--

        function page:Section(config)
            config = config or {}
            local sectionName = config.name or "Section"
            local leftHeader = config.left or "options"
            local rightHeader = config.right or "settings"

            local sectionIndex = #page.sections

            local section = {
                name = sectionName,
                visible = false,
                leftElements = {},
                rightElements = {},
                objects = {},
                leftOffset = 6,  -- Starting offset for elements (after column header)
                rightOffset = 6
            }

            -- Calculate dimensions - FIXED to match sidebar exactly
            section.mainX = mainX
            section.mainY = mainY
            section.mainW = mainW
            section.mainH = mainH  -- Same as sidebar height

            -- Content area inside the section (after header)
            section.contentX = mainX
            section.contentY = mainY + SECTION_HEADER_H + COLUMN_HEADER_H
            section.contentW = mainW
            section.contentH = mainH - SECTION_HEADER_H - COLUMN_HEADER_H

            -- Column widths (split evenly with gap)
            local columnGap = MARGIN
            section.leftW = math.floor((mainW - columnGap) / 2)
            section.rightX = mainX + section.leftW + columnGap
            section.rightW = mainW - section.leftW - columnGap

            --================================================================--
            --                    SECTION BACKGROUND                          --
            --================================================================--

            -- Main content background (matches sidebar height)
            section.objects.bg = createDrawing("Square", {
                Size = Vector2.new(mainW, mainH),
                Position = window.pos + Vector2.new(mainX, mainY),
                Color = library.theme.section,
                Filled = true,
                Visible = false,
                ZIndex = 2
            })
            registerTheme(section.objects.bg, "Color", "section")

            -- Main outline
            section.objects.outline = createDrawing("Square", {
                Size = Vector2.new(mainW, mainH),
                Position = window.pos + Vector2.new(mainX, mainY),
                Color = library.theme.outline,
                Filled = false,
                Thickness = 1,
                Visible = false,
                ZIndex = 3
            })
            registerTheme(section.objects.outline, "Color", "outline")

            -- Section header bar
            section.objects.header = createDrawing("Square", {
                Size = Vector2.new(mainW - 2, SECTION_HEADER_H),
                Position = window.pos + Vector2.new(mainX + 1, mainY + 1),
                Color = library.theme.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 3
            })
            registerTheme(section.objects.header, "Color", "sectionheader")

            -- Section title
            section.objects.title = createDrawing("Text", {
                Text = sectionName,
                Size = 13,
                Font = 2,
                Color = library.theme.text,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(mainX + 10, mainY + 5),
                Visible = false,
                ZIndex = 4
            })
            registerTheme(section.objects.title, "Color", "text")

            -- Header bottom line
            section.objects.headerLine = createDrawing("Square", {
                Size = Vector2.new(mainW - 2, 1),
                Position = window.pos + Vector2.new(mainX + 1, mainY + SECTION_HEADER_H),
                Color = library.theme.outline,
                Filled = true,
                Visible = false,
                ZIndex = 4
            })
            registerTheme(section.objects.headerLine, "Color", "outline")

            --================================================================--
            --                     COLUMN HEADERS                             --
            --================================================================--

            -- Left column header
            section.objects.leftHeader = createDrawing("Text", {
                Text = leftHeader:upper(),
                Size = 11,
                Font = 2,
                Color = library.theme.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(mainX + 10, mainY + SECTION_HEADER_H + 4),
                Visible = false,
                ZIndex = 4
            })
            registerTheme(section.objects.leftHeader, "Color", "dimtext")

            -- Right column header
            section.objects.rightHeader = createDrawing("Text", {
                Text = rightHeader:upper(),
                Size = 11,
                Font = 2,
                Color = library.theme.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(section.rightX + 10, mainY + SECTION_HEADER_H + 4),
                Visible = false,
                ZIndex = 4
            })
            registerTheme(section.objects.rightHeader, "Color", "dimtext")

            -- Column divider
            section.objects.divider = createDrawing("Square", {
                Size = Vector2.new(1, mainH - SECTION_HEADER_H - 2),
                Position = window.pos + Vector2.new(mainX + section.leftW, mainY + SECTION_HEADER_H + 1),
                Color = library.theme.outline,
                Filled = true,
                Visible = false,
                ZIndex = 4
            })
            registerTheme(section.objects.divider, "Color", "outline")

            --================================================================--
            --                    SIDEBAR BUTTON                              --
            --================================================================--

            local buttonY = sidebarY + 8 + (sectionIndex * 26)

            section.button = {
                objects = {}
            }

            -- Button text
            section.button.objects.text = createDrawing("Text", {
                Text = sectionName,
                Size = 13,
                Font = 2,
                Color = library.theme.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(sidebarX + 12, buttonY),
                Visible = false,
                ZIndex = 4
            })

            -- Button indicator
            section.button.objects.indicator = createDrawing("Square", {
                Size = Vector2.new(3, 14),
                Position = window.pos + Vector2.new(sidebarX + 3, buttonY),
                Color = library.accent,
                Filled = true,
                Visible = false,
                ZIndex = 4
            })
            registerAccent(section.button.objects.indicator, "Color")

            section.buttonY = buttonY

            --================================================================--
            --                    SECTION METHODS                             --
            --================================================================--

            function section:UpdatePositions()
                local p = window.pos

                pcall(function() section.objects.bg.Position = p + Vector2.new(mainX, mainY) end)
                pcall(function() section.objects.outline.Position = p + Vector2.new(mainX, mainY) end)
                pcall(function() section.objects.header.Position = p + Vector2.new(mainX + 1, mainY + 1) end)
                pcall(function() section.objects.title.Position = p + Vector2.new(mainX + 10, mainY + 5) end)
                pcall(function() section.objects.headerLine.Position = p + Vector2.new(mainX + 1, mainY + SECTION_HEADER_H) end)
                pcall(function() section.objects.leftHeader.Position = p + Vector2.new(mainX + 10, mainY + SECTION_HEADER_H + 4) end)
                pcall(function() section.objects.rightHeader.Position = p + Vector2.new(section.rightX + 10, mainY + SECTION_HEADER_H + 4) end)
                pcall(function() section.objects.divider.Position = p + Vector2.new(mainX + section.leftW, mainY + SECTION_HEADER_H + 1) end)
                pcall(function() section.button.objects.text.Position = p + Vector2.new(sidebarX + 12, section.buttonY) end)
                pcall(function() section.button.objects.indicator.Position = p + Vector2.new(sidebarX + 3, section.buttonY) end)

                -- Update all elements
                for _, element in ipairs(section.leftElements) do
                    pcall(function() element:UpdatePositions() end)
                end
                for _, element in ipairs(section.rightElements) do
                    pcall(function() element:UpdatePositions() end)
                end
            end

            function section:SetVisible(state)
                section.visible = state

                for _, obj in pairs(section.objects) do
                    pcall(function() obj.Visible = state end)
                end

                -- Sidebar button always visible when page is visible
                pcall(function()
                    section.button.objects.text.Visible = page.visible and library.open
                    section.button.objects.indicator.Visible = state and library.open
                    section.button.objects.text.Color = state and library.accent or library.theme.dimtext
                end)

                -- Update all elements visibility
                for _, element in ipairs(section.leftElements) do
                    pcall(function() element:SetVisible(state) end)
                end
                for _, element in ipairs(section.rightElements) do
                    pcall(function() element:SetVisible(state) end)
                end
            end

            function section:Show()
                -- Hide other sections in this page
                for _, s in pairs(page.sections) do
                    if s ~= section then
                        s:SetVisible(false)
                    end
                end

                section:SetVisible(true)
                page.currentSection = section
                window:ClosePopups()
            end

            --================================================================--
            --                         TOGGLE                                 --
            --================================================================--

            function section:Toggle(config)
                config = config or {}
                local toggleName = config.name or "Toggle"
                local side = (config.side or "left"):lower()
                local default = config.default or false
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

                local toggle = {
                    value = default,
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                -- Checkbox background
                toggle.objects.box = createDrawing("Square", {
                    Size = Vector2.new(14, 14),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = default and library.accent or library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 8
                })
                registerToggle(toggle.objects.box, toggle)

                -- Checkbox outline
                toggle.objects.boxOutline = createDrawing("Square", {
                    Size = Vector2.new(14, 14),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = library.theme.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(toggle.objects.boxOutline, "Color", "outline")

                -- Label
                toggle.objects.label = createDrawing("Text", {
                    Text = toggleName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 20, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(toggle.objects.label, "Color", "text")

                toggle.baseX = baseX
                toggle.baseY = section.contentY + offset
                toggle.width = elemW

                function toggle:UpdatePositions()
                    local p = window.pos
                    pcall(function() toggle.objects.box.Position = p + Vector2.new(toggle.baseX, toggle.baseY) end)
                    pcall(function() toggle.objects.boxOutline.Position = p + Vector2.new(toggle.baseX, toggle.baseY) end)
                    pcall(function() toggle.objects.label.Position = p + Vector2.new(toggle.baseX + 20, toggle.baseY) end)
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function toggle:Set(value, noCallback)
                    toggle.value = value
                    pcall(function()
                        toggle.objects.box.Color = value and library.accent or library.theme.elementbg
                    end)

                    if flag then
                        library.flags[flag] = value
                    end

                    if not noCallback then
                        pcall(callback, value)
                    end
                end

                function toggle:Get()
                    return toggle.value
                end

                -- Click handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            local pos = toggle.objects.box.Position
                            if isMouseOver(pos.X - 2, pos.Y - 2, toggle.width + 4, 18) then
                                toggle:Set(not toggle.value)
                            end
                        end
                    end
                end))

                -- Initialize flag
                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = toggle
                end

                if default then
                    pcall(callback, default)
                end

                -- Update offset - FIXED: 22px for consistent 6px gaps (14px element + 8px gap for visual balance)
                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, toggle)
                return toggle
            end

            --================================================================--
            --                          SLIDER                                --
            --================================================================--

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
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                -- Label
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

                -- Value text
                local valueText = tostring(default) .. suffix
                slider.objects.value = createDrawing("Text", {
                    Text = valueText,
                    Size = 13,
                    Font = 2,
                    Color = library.accent,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + elemW - getTextBounds(valueText, 13).X, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerAccent(slider.objects.value, "Color")

                -- Track background
                slider.objects.track = createDrawing("Square", {
                    Size = Vector2.new(elemW, 10),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 8
                })
                registerTheme(slider.objects.track, "Color", "elementbg")

                -- Track outline
                slider.objects.trackOutline = createDrawing("Square", {
                    Size = Vector2.new(elemW, 10),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(slider.objects.trackOutline, "Color", "outline")

                -- Fill
                local fillPercent = (default - min) / (max - min)
                slider.objects.fill = createDrawing("Square", {
                    Size = Vector2.new(math.max(1, (elemW - 2) * fillPercent), 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = library.accent,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerAccent(slider.objects.fill, "Color")

                slider.baseX = baseX
                slider.baseY = section.contentY + offset
                slider.width = elemW

                function slider:UpdatePositions()
                    local p = window.pos
                    local valueText = tostring(slider.value) .. suffix

                    pcall(function() slider.objects.label.Position = p + Vector2.new(slider.baseX, slider.baseY) end)
                    pcall(function()
                        slider.objects.value.Text = valueText
                        slider.objects.value.Position = p + Vector2.new(slider.baseX + slider.width - getTextBounds(valueText, 13).X, slider.baseY)
                    end)
                    pcall(function() slider.objects.track.Position = p + Vector2.new(slider.baseX, slider.baseY + 18) end)
                    pcall(function() slider.objects.trackOutline.Position = p + Vector2.new(slider.baseX, slider.baseY + 18) end)
                    pcall(function() slider.objects.fill.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 19) end)
                end

                function slider:SetVisible(state)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function slider:Set(value, noCallback)
                    value = math.clamp(value, min, max)

                    if increment >= 1 then
                        value = math.floor(value / increment + 0.5) * increment
                    else
                        local mult = 1 / increment
                        value = math.floor(value * mult + 0.5) / mult
                    end

                    slider.value = value

                    local fillPercent = (value - min) / (max - min)
                    pcall(function()
                        slider.objects.fill.Size = Vector2.new(math.max(1, (slider.width - 2) * fillPercent), 8)
                    end)

                    local valueText = tostring(value) .. suffix
                    pcall(function()
                        slider.objects.value.Text = valueText
                        slider.objects.value.Position = window.pos + Vector2.new(
                            slider.baseX + slider.width - getTextBounds(valueText, 13).X,
                            slider.baseY
                        )
                    end)

                    if flag then
                        library.flags[flag] = value
                    end

                    if not noCallback then
                        pcall(callback, value)
                    end
                end

                function slider:Get()
                    return slider.value
                end

                -- Click/drag handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            local trackPos = slider.objects.track.Position
                            if isMouseOver(trackPos.X, trackPos.Y, slider.width, 10) then
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
                    if slider.dragging and library.open and section.visible then
                        local success, mouse = pcall(function()
                            return UserInputService:GetMouseLocation()
                        end)
                        if success then
                            local trackPos = slider.objects.track.Position
                            local relX = math.clamp((mouse.X - trackPos.X) / slider.width, 0, 1)
                            local newValue = min + (max - min) * relX
                            slider:Set(newValue)
                        end
                    end
                end))

                -- Initialize flag
                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = slider
                end

                pcall(callback, default)

                -- Update offset - 36px (28px element + 8px gap)
                if side == "left" then
                    section.leftOffset = section.leftOffset + 36
                else
                    section.rightOffset = section.rightOffset + 36
                end

                table.insert(elements, slider)
                return slider
            end

            --================================================================--
            --                          BUTTON                                --
            --================================================================--

            function section:Button(config)
                config = config or {}
                local buttonName = config.name or "Button"
                local side = (config.side or "left"):lower()
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

                local button = {
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                -- Background
                button.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(elemW, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 8
                })
                registerTheme(button.objects.bg, "Color", "elementbg")

                -- Outline
                button.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(elemW, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = library.theme.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(button.objects.outline, "Color", "outline")

                -- Text (centered)
                local textWidth = getTextBounds(buttonName, 13).X
                button.objects.text = createDrawing("Text", {
                    Text = buttonName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + (elemW - textWidth) / 2, section.contentY + offset + 4),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(button.objects.text, "Color", "text")

                button.baseX = baseX
                button.baseY = section.contentY + offset
                button.width = elemW

                function button:UpdatePositions()
                    local p = window.pos
                    local textWidth = getTextBounds(buttonName, 13).X

                    pcall(function() button.objects.bg.Position = p + Vector2.new(button.baseX, button.baseY) end)
                    pcall(function() button.objects.outline.Position = p + Vector2.new(button.baseX, button.baseY) end)
                    pcall(function() button.objects.text.Position = p + Vector2.new(button.baseX + (button.width - textWidth) / 2, button.baseY + 4) end)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                -- Click handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            local pos = button.objects.bg.Position
                            if isMouseOver(pos.X, pos.Y, button.width, 22) then
                                -- Visual feedback
                                pcall(function()
                                    button.objects.bg.Color = library.accent
                                end)

                                task.delay(0.1, function()
                                    pcall(function()
                                        button.objects.bg.Color = library.theme.elementbg
                                    end)
                                end)

                                pcall(callback)
                            end
                        end
                    end
                end))

                -- Update offset - 30px (22px element + 8px gap)
                if side == "left" then
                    section.leftOffset = section.leftOffset + 30
                else
                    section.rightOffset = section.rightOffset + 30
                end

                table.insert(elements, button)
                return button
            end

            --================================================================--
            --                         DROPDOWN                               --
            --================================================================--

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
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

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

                -- Label
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

                -- Box background
                dropdown.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(elemW, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 8
                })
                registerTheme(dropdown.objects.bg, "Color", "elementbg")

                -- Box outline
                dropdown.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(elemW, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(dropdown.objects.outline, "Color", "outline")

                -- Selected text
                local displayText = multi
                    and (#dropdown.value > 0 and table.concat(dropdown.value, ", ") or "None")
                    or default
                dropdown.objects.selected = createDrawing("Text", {
                    Text = displayText,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 8, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(dropdown.objects.selected, "Color", "text")

                -- Arrow
                dropdown.objects.arrow = createDrawing("Text", {
                    Text = "v",
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + elemW - 14, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(dropdown.objects.arrow, "Color", "dimtext")

                dropdown.baseX = baseX
                dropdown.baseY = section.contentY + offset
                dropdown.width = elemW

                function dropdown:UpdatePositions()
                    local p = window.pos
                    pcall(function() dropdown.objects.label.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY) end)
                    pcall(function() dropdown.objects.bg.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY + 18) end)
                    pcall(function() dropdown.objects.outline.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY + 18) end)
                    pcall(function() dropdown.objects.selected.Position = p + Vector2.new(dropdown.baseX + 8, dropdown.baseY + 22) end)
                    pcall(function() dropdown.objects.arrow.Position = p + Vector2.new(dropdown.baseX + dropdown.width - 14, dropdown.baseY + 22) end)
                end

                function dropdown:SetVisible(state)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                    if not state then
                        dropdown:Close()
                    end
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

                    local pos = dropdown.objects.bg.Position
                    local listH = math.min(#items * 20 + 4, 164)

                    dropdown.blockArea = {
                        x = pos.X,
                        y = pos.Y + 24,
                        w = dropdown.width,
                        h = listH
                    }

                    -- List background
                    local listBg = createDrawing("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 24),
                        Color = library.theme.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(dropdown.itemObjects, listBg)

                    -- List outline
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

                    -- Item texts
                    for i, item in ipairs(items) do
                        local isSelected = multi
                            and table.find(dropdown.value, item)
                            or dropdown.value == item

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
                        pcall(function()
                            dropdown.objects.selected.Text = #dropdown.value > 0
                                and table.concat(dropdown.value, ", ")
                                or "None"
                        end)
                    else
                        dropdown.value = value
                        pcall(function()
                            dropdown.objects.selected.Text = value
                        end)
                    end

                    if flag then
                        library.flags[flag] = dropdown.value
                    end

                    if not noCallback then
                        pcall(callback, dropdown.value)
                    end
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

                -- Click handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible then
                            local pos = dropdown.objects.bg.Position

                            -- Toggle dropdown
                            if isMouseOver(pos.X, pos.Y, dropdown.width, 22) then
                                dropdown:Open()
                                return
                            end

                            -- Handle item selection
                            if dropdown.open then
                                for i, item in ipairs(items) do
                                    local itemY = pos.Y + 24 + (i - 1) * 20
                                    if isMouseOver(pos.X, itemY, dropdown.width, 20) then
                                        if multi then
                                            local idx = table.find(dropdown.value, item)
                                            if idx then
                                                table.remove(dropdown.value, idx)
                                            else
                                                table.insert(dropdown.value, item)
                                            end
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

                                -- Close if clicked outside
                                if dropdown.blockArea then
                                    if not isMouseOver(
                                        dropdown.blockArea.x,
                                        dropdown.blockArea.y,
                                        dropdown.blockArea.w,
                                        dropdown.blockArea.h
                                    ) and not isMouseOver(pos.X, pos.Y, dropdown.width, 22) then
                                        dropdown:Close()
                                    end
                                end
                            end
                        end
                    end
                end))

                -- Initialize
                if flag then
                    library.flags[flag] = multi and {} or default
                    library.pointers[flag] = dropdown
                end

                if not multi and default ~= "" then
                    pcall(callback, default)
                end

                -- Update offset - 48px (40px element + 8px gap)
                if side == "left" then
                    section.leftOffset = section.leftOffset + 48
                else
                    section.rightOffset = section.rightOffset + 48
                end

                table.insert(elements, dropdown)
                return dropdown
            end

            --================================================================--
            --                          KEYBIND                               --
            --================================================================--

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
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

                local keybind = {
                    value = default,
                    listening = false,
                    side = side,
                    yOffset = offset,
                    objects = {},
                    ignoreNextClick = false
                }

                -- Label
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

                -- Key text
                local keyText = "[" .. getKeyName(default) .. "]"
                keybind.objects.key = createDrawing("Text", {
                    Text = keyText,
                    Size = 13,
                    Font = 2,
                    Color = library.accent,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + elemW - getTextBounds(keyText, 13).X, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerAccent(keybind.objects.key, "Color")

                keybind.baseX = baseX
                keybind.baseY = section.contentY + offset
                keybind.width = elemW

                function keybind:UpdatePositions()
                    local p = window.pos
                    local keyText = "[" .. getKeyName(keybind.value) .. "]"

                    pcall(function() keybind.objects.label.Position = p + Vector2.new(keybind.baseX, keybind.baseY + 2) end)
                    pcall(function()
                        keybind.objects.key.Position = p + Vector2.new(
                            keybind.baseX + keybind.width - getTextBounds(keyText, 13).X,
                            keybind.baseY + 2
                        )
                    end)
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
                        keybind.objects.key.Position = window.pos + Vector2.new(
                            keybind.baseX + keybind.width - getTextBounds(keyText, 13).X,
                            keybind.baseY + 2
                        )
                        keybind.objects.key.Color = library.accent
                    end)

                    if flag then
                        library.flags[flag] = key
                    end

                    if isMenuToggle then
                        library.menuKeybind = key
                        window:UpdateToggleHint()
                    end
                end

                function keybind:Get()
                    return keybind.value
                end

                -- Input handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    -- Start listening
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible and not library.blockingInput then
                            if not keybind.listening then
                                local pos = keybind.objects.label.Position
                                if isMouseOver(pos.X - 2, pos.Y - 4, keybind.width + 4, 22) then
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

                    -- Capture key
                    if keybind.listening then
                        if keybind.ignoreNextClick and input.UserInputType == Enum.UserInputType.MouseButton1 then
                            return
                        end

                        local key = nil

                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                key = Enum.KeyCode.Unknown
                            else
                                key = input.KeyCode
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or
                               input.UserInputType == Enum.UserInputType.MouseButton2 or
                               input.UserInputType == Enum.UserInputType.MouseButton3 then
                            if not keybind.ignoreNextClick then
                                key = input.UserInputType
                            end
                        end

                        if key then
                            keybind:Set(key)
                            keybind.listening = false
                            keybind.ignoreNextClick = false
                        end
                        return
                    end

                    -- Trigger callback
                    if keybind.value ~= Enum.KeyCode.Unknown and not keybind.listening then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(callback, keybind.value)
                        end
                    end
                end))

                table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and keybind.ignoreNextClick then
                        task.delay(0.1, function()
                            keybind.ignoreNextClick = false
                        end)
                    end
                end))

                -- Initialize
                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = keybind
                end

                -- Update offset - 22px
                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, keybind)
                return keybind
            end

            --================================================================--
            --                       COLORPICKER                              --
            --================================================================--

            function section:ColorPicker(config)
                config = config or {}
                local pickerName = config.name or "Color"
                local side = (config.side or "left"):lower()
                local default = config.default or Color3.fromRGB(255, 255, 255)
                local flag = config.flag
                local callback = config.callback or function() end
                local trackAccent = config.trackAccent or false

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

                local h, s, v = rgbToHsv(default.R * 255, default.G * 255, default.B * 255)

                local colorpicker = {
                    value = trackAccent and library.accent or default,
                    h = h,
                    s = s,
                    v = v,
                    open = false,
                    draggingSV = false,
                    draggingH = false,
                    side = side,
                    yOffset = offset,
                    objects = {},
                    pickerObjects = {},
                    blockArea = nil,
                    trackAccent = trackAccent
                }

                -- Label
                colorpicker.objects.label = createDrawing("Text", {
                    Text = pickerName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(colorpicker.objects.label, "Color", "dimtext")

                -- Preview box
                colorpicker.objects.preview = createDrawing("Square", {
                    Size = Vector2.new(26, 14),
                    Position = window.pos + Vector2.new(baseX + elemW - 28, section.contentY + offset),
                    Color = trackAccent and library.accent or default,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                if trackAccent then
                    table.insert(library.colorPickerPreviews, {
                        obj = colorpicker.objects.preview,
                        colorpicker = colorpicker,
                        trackAccent = true
                    })
                end

                -- Preview outline
                colorpicker.objects.previewOutline = createDrawing("Square", {
                    Size = Vector2.new(26, 14),
                    Position = window.pos + Vector2.new(baseX + elemW - 28, section.contentY + offset),
                    Color = library.theme.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 10
                })
                registerTheme(colorpicker.objects.previewOutline, "Color", "outline")

                colorpicker.baseX = baseX
                colorpicker.baseY = section.contentY + offset
                colorpicker.width = elemW

                function colorpicker:UpdatePositions()
                    local p = window.pos
                    pcall(function() colorpicker.objects.label.Position = p + Vector2.new(colorpicker.baseX, colorpicker.baseY + 2) end)
                    pcall(function() colorpicker.objects.preview.Position = p + Vector2.new(colorpicker.baseX + colorpicker.width - 28, colorpicker.baseY) end)
                    pcall(function() colorpicker.objects.previewOutline.Position = p + Vector2.new(colorpicker.baseX + colorpicker.width - 28, colorpicker.baseY) end)
                end

                function colorpicker:SetVisible(state)
                    for _, obj in pairs(colorpicker.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                    if not state then
                        colorpicker:Close()
                    end
                end

                function colorpicker:Close()
                    colorpicker.open = false
                    colorpicker.draggingSV = false
                    colorpicker.draggingH = false
                    library.blockingInput = false
                    colorpicker.blockArea = nil

                    for _, obj in pairs(colorpicker.pickerObjects) do
                        pcall(function() obj:Remove() end)
                    end
                    colorpicker.pickerObjects = {}

                    if window.activeColorPicker == colorpicker then
                        window.activeColorPicker = nil
                    end
                end

                function colorpicker:Open()
                    if colorpicker.open then
                        colorpicker:Close()
                        return
                    end

                    window:ClosePopups()
                    colorpicker.open = true
                    window.activeColorPicker = colorpicker
                    library.blockingInput = true

                    local pos = colorpicker.objects.preview.Position
                    local pickerW, pickerH = 200, 180

                    colorpicker.blockArea = {
                        x = pos.X - pickerW + 26,
                        y = pos.Y + 18,
                        w = pickerW,
                        h = pickerH
                    }

                    local pickerX = pos.X - pickerW + 26
                    local pickerY = pos.Y + 18

                    -- Background
                    local bg = createDrawing("Square", {
                        Size = Vector2.new(pickerW, pickerH),
                        Position = Vector2.new(pickerX, pickerY),
                        Color = library.theme.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(colorpicker.pickerObjects, bg)

                    -- Outline
                    local outline = createDrawing("Square", {
                        Size = Vector2.new(pickerW, pickerH),
                        Position = Vector2.new(pickerX, pickerY),
                        Color = library.theme.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 51
                    })
                    table.insert(colorpicker.pickerObjects, outline)

                    -- SV gradient area
                    local svX, svY = pickerX + 10, pickerY + 10
                    local svW, svH = 150, 130

                    colorpicker.svX = svX
                    colorpicker.svY = svY
                    colorpicker.svW = svW
                    colorpicker.svH = svH

                    local svBg = createDrawing("Square", {
                        Size = Vector2.new(svW, svH),
                        Position = Vector2.new(svX, svY),
                        Color = Color3.fromHSV(colorpicker.h, 1, 1),
                        Filled = true,
                        Visible = true,
                        ZIndex = 52
                    })
                    table.insert(colorpicker.pickerObjects, svBg)
                    colorpicker.svBg = svBg

                    -- SV cursor
                    local svCursor = createDrawing("Circle", {
                        Radius = 4,
                        Position = Vector2.new(svX + svW * colorpicker.s, svY + svH * (1 - colorpicker.v)),
                        Color = Color3.new(1, 1, 1),
                        Filled = false,
                        Thickness = 2,
                        Visible = true,
                        ZIndex = 54
                    })
                    table.insert(colorpicker.pickerObjects, svCursor)
                    colorpicker.svCursor = svCursor

                    -- Hue bar
                    local hueX, hueY = pickerX + 170, pickerY + 10
                    local hueW, hueH = 20, 130

                    colorpicker.hueX = hueX
                    colorpicker.hueY = hueY
                    colorpicker.hueW = hueW
                    colorpicker.hueH = hueH

                    local hueBg = createDrawing("Square", {
                        Size = Vector2.new(hueW, hueH),
                        Position = Vector2.new(hueX, hueY),
                        Color = Color3.new(1, 1, 1),
                        Filled = true,
                        Visible = true,
                        ZIndex = 52
                    })
                    table.insert(colorpicker.pickerObjects, hueBg)

                    -- Hue cursor
                    local hueCursor = createDrawing("Square", {
                        Size = Vector2.new(hueW + 4, 4),
                        Position = Vector2.new(hueX - 2, hueY + hueH * colorpicker.h - 2),
                        Color = Color3.new(1, 1, 1),
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 54
                    })
                    table.insert(colorpicker.pickerObjects, hueCursor)
                    colorpicker.hueCursor = hueCursor

                    -- Preview
                    local previewBg = createDrawing("Square", {
                        Size = Vector2.new(pickerW - 20, 24),
                        Position = Vector2.new(pickerX + 10, pickerY + 146),
                        Color = colorpicker.value,
                        Filled = true,
                        Visible = true,
                        ZIndex = 52
                    })
                    table.insert(colorpicker.pickerObjects, previewBg)
                    colorpicker.previewBg = previewBg
                end

                function colorpicker:UpdateColor()
                    local r, g, b = hsvToRgb(colorpicker.h, colorpicker.s, colorpicker.v)
                    local newColor = Color3.fromRGB(r, g, b)
                    colorpicker.value = newColor

                    pcall(function() colorpicker.objects.preview.Color = newColor end)
                    if colorpicker.previewBg then
                        pcall(function() colorpicker.previewBg.Color = newColor end)
                    end
                    if colorpicker.svBg then
                        pcall(function() colorpicker.svBg.Color = Color3.fromHSV(colorpicker.h, 1, 1) end)
                    end

                    if flag then
                        library.flags[flag] = newColor
                    end

                    pcall(callback, newColor)
                end

                function colorpicker:Set(color, noCallback)
                    local r, g, b = color.R * 255, color.G * 255, color.B * 255
                    colorpicker.h, colorpicker.s, colorpicker.v = rgbToHsv(r, g, b)
                    colorpicker.value = color

                    pcall(function() colorpicker.objects.preview.Color = color end)

                    if flag then
                        library.flags[flag] = color
                    end

                    if not noCallback then
                        pcall(callback, color)
                    end
                end

                function colorpicker:Get()
                    return colorpicker.value
                end

                -- Click handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible then
                            local pos = colorpicker.objects.preview.Position

                            if isMouseOver(pos.X, pos.Y, 26, 14) then
                                colorpicker:Open()
                                return
                            end

                            if colorpicker.open then
                                if isMouseOver(colorpicker.svX, colorpicker.svY, colorpicker.svW, colorpicker.svH) then
                                    colorpicker.draggingSV = true
                                    return
                                end

                                if isMouseOver(colorpicker.hueX, colorpicker.hueY, colorpicker.hueW, colorpicker.hueH) then
                                    colorpicker.draggingH = true
                                    return
                                end

                                if colorpicker.blockArea then
                                    if not isMouseOver(
                                        colorpicker.blockArea.x,
                                        colorpicker.blockArea.y,
                                        colorpicker.blockArea.w,
                                        colorpicker.blockArea.h
                                    ) then
                                        colorpicker:Close()
                                    end
                                end
                            end
                        end
                    end
                end))

                table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        colorpicker.draggingSV = false
                        colorpicker.draggingH = false
                    end
                end))

                table.insert(library.connections, RunService.RenderStepped:Connect(function()
                    if colorpicker.open and library.open then
                        local success, mouse = pcall(function()
                            return UserInputService:GetMouseLocation()
                        end)

                        if success then
                            if colorpicker.draggingSV then
                                local relX = math.clamp((mouse.X - colorpicker.svX) / colorpicker.svW, 0, 1)
                                local relY = math.clamp((mouse.Y - colorpicker.svY) / colorpicker.svH, 0, 1)
                                colorpicker.s = relX
                                colorpicker.v = 1 - relY

                                pcall(function()
                                    colorpicker.svCursor.Position = Vector2.new(
                                        colorpicker.svX + relX * colorpicker.svW,
                                        colorpicker.svY + relY * colorpicker.svH
                                    )
                                end)
                                colorpicker:UpdateColor()
                            end

                            if colorpicker.draggingH then
                                local relY = math.clamp((mouse.Y - colorpicker.hueY) / colorpicker.hueH, 0, 1)
                                colorpicker.h = relY

                                pcall(function()
                                    colorpicker.hueCursor.Position = Vector2.new(
                                        colorpicker.hueX - 2,
                                        colorpicker.hueY + relY * colorpicker.hueH - 2
                                    )
                                end)
                                colorpicker:UpdateColor()
                            end
                        end
                    end
                end))

                -- Initialize
                if flag then
                    library.flags[flag] = trackAccent and library.accent or default
                    library.pointers[flag] = colorpicker
                end

                if not trackAccent then
                    pcall(callback, default)
                end

                -- Update offset - 22px
                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, colorpicker)
                return colorpicker
            end

            --================================================================--
            --                          TEXTBOX                               --
            --================================================================--

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
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemW = side == "left" and (section.leftW - 20) or (section.rightW - 20)

                local textbox = {
                    value = default,
                    focused = false,
                    side = side,
                    yOffset = offset,
                    placeholder = placeholder,
                    objects = {}
                }

                -- Label
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

                -- Box background
                textbox.objects.bg = createDrawing("Square", {
                    Size = Vector2.new(elemW, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 8
                })
                registerTheme(textbox.objects.bg, "Color", "elementbg")

                -- Box outline
                textbox.objects.outline = createDrawing("Square", {
                    Size = Vector2.new(elemW, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = library.theme.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 9
                })
                registerTheme(textbox.objects.outline, "Color", "outline")

                -- Text
                textbox.objects.text = createDrawing("Text", {
                    Text = default ~= "" and default or placeholder,
                    Size = 13,
                    Font = 2,
                    Color = default ~= "" and library.theme.text or library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 8, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 10
                })

                textbox.baseX = baseX
                textbox.baseY = section.contentY + offset
                textbox.width = elemW

                function textbox:UpdatePositions()
                    local p = window.pos
                    pcall(function() textbox.objects.label.Position = p + Vector2.new(textbox.baseX, textbox.baseY) end)
                    pcall(function() textbox.objects.bg.Position = p + Vector2.new(textbox.baseX, textbox.baseY + 18) end)
                    pcall(function() textbox.objects.outline.Position = p + Vector2.new(textbox.baseX, textbox.baseY + 18) end)
                    pcall(function() textbox.objects.text.Position = p + Vector2.new(textbox.baseX + 8, textbox.baseY + 22) end)
                end

                function textbox:SetVisible(state)
                    for _, obj in pairs(textbox.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function textbox:Set(value)
                    textbox.value = value
                    pcall(function()
                        textbox.objects.text.Text = value ~= "" and value or textbox.placeholder
                        textbox.objects.text.Color = value ~= ""
                            and library.theme.text
                            or library.theme.dimtext
                    end)

                    if flag then
                        library.flags[flag] = value
                    end

                    pcall(callback, value)
                end

                function textbox:Get()
                    return textbox.value
                end

                function textbox:Focus()
                    textbox.focused = true
                    pcall(function()
                        textbox.objects.outline.Color = library.accent
                        textbox.objects.text.Text = textbox.value
                        textbox.objects.text.Color = library.theme.text
                    end)
                end

                function textbox:Unfocus()
                    textbox.focused = false
                    pcall(function()
                        textbox.objects.outline.Color = library.theme.outline
                        textbox.objects.text.Text = textbox.value ~= "" and textbox.value or textbox.placeholder
                        textbox.objects.text.Color = textbox.value ~= ""
                            and library.theme.text
                            or library.theme.dimtext
                    end)
                end

                -- Click handler
                table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and section.visible then
                            local pos = textbox.objects.bg.Position
                            if isMouseOver(pos.X, pos.Y, textbox.width, 22) then
                                textbox:Focus()
                            elseif textbox.focused then
                                textbox:Unfocus()
                            end
                        end
                    end

                    -- Text input
                    if textbox.focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode

                        if key == Enum.KeyCode.Return or key == Enum.KeyCode.Escape then
                            textbox:Unfocus()
                            if key == Enum.KeyCode.Return then
                                textbox:Set(textbox.value)
                            end
                        elseif key == Enum.KeyCode.Backspace then
                            textbox.value = textbox.value:sub(1, -2)
                            pcall(function()
                                textbox.objects.text.Text = textbox.value
                            end)
                        else
                            local char = UserInputService:GetStringForKeyCode(key)
                            if char and #char == 1 then
                                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
                                   UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                                    char = char:upper()
                                else
                                    char = char:lower()
                                end
                                textbox.value = textbox.value .. char
                                pcall(function()
                                    textbox.objects.text.Text = textbox.value
                                end)
                            end
                        end
                    end
                end))

                -- Initialize
                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = textbox
                end

                -- Update offset - 48px (40px element + 8px gap)
                if side == "left" then
                    section.leftOffset = section.leftOffset + 48
                else
                    section.rightOffset = section.rightOffset + 48
                end

                table.insert(elements, textbox)
                return textbox
            end

            --================================================================--
            --                           LABEL                                --
            --================================================================--

            function section:Label(config)
                config = config or {}
                local labelText = config.text or "Label"
                local side = (config.side or "left"):lower()

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)

                local label = {
                    text = labelText,
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                -- Text
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
                    pcall(function()
                        label.objects.text.Position = p + Vector2.new(label.baseX, label.baseY + 2)
                    end)
                end

                function label:SetVisible(state)
                    for _, obj in pairs(label.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function label:Set(text)
                    label.text = text
                    pcall(function()
                        label.objects.text.Text = text
                    end)
                end

                function label:Get()
                    return label.text
                end

                -- Update offset - 22px
                if side == "left" then
                    section.leftOffset = section.leftOffset + 22
                else
                    section.rightOffset = section.rightOffset + 22
                end

                table.insert(elements, label)
                return label
            end

            --================================================================--
            --                 SECTION BUTTON CLICK                           --
            --================================================================--

            table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
                    if library.blockingInput then return end

                    for _, s in pairs(page.sections) do
                        local btnPos = s.button.objects.text.Position
                        if isMouseOver(btnPos.X - 10, btnPos.Y - 4, SIDEBAR_WIDTH - 10, 22) then
                            s:Show()
                            return
                        end
                    end
                end
            end))

            table.insert(page.sections, section)
            return section
        end

        table.insert(window.pages, page)
        return page
    end

    --========================================================================--
    --                               INIT                                     --
    --========================================================================--

    function window:Init()
        -- Position tabs from right
        local totalTabWidth = 0
        for _, page in ipairs(window.pages) do
            totalTabWidth = totalTabWidth + page.tabWidth + 4
        end

        local startX = sizeX - totalTabWidth - 6
        local tabX = startX

        for _, page in ipairs(window.pages) do
            page.tabX = tabX
            pcall(function()
                page.objects.tabBg.Position = window.pos + Vector2.new(tabX, 4)
                page.objects.tabBg.Size = Vector2.new(page.tabWidth, TAB_HEIGHT)
            end)
            pcall(function()
                page.objects.tabAccent.Position = window.pos + Vector2.new(tabX + 2, 5)
                page.objects.tabAccent.Size = Vector2.new(page.tabWidth - 4, 2)
            end)
            pcall(function()
                page.objects.tabText.Position = window.pos + Vector2.new(tabX + 8, 9)
            end)
            tabX = tabX + page.tabWidth + 4
        end

        -- Show first page and first section
        if window.pages[1] then
            window.pages[1]:Show()
            window.currentPage = window.pages[1]

            if window.pages[1].sections[1] then
                window.pages[1].sections[1]:Show()
                window.pages[1].currentSection = window.pages[1].sections[1]
            end
        end

        -- Tab click handler
        table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
                if library.blockingInput then return end

                for _, page in ipairs(window.pages) do
                    local tabPos = window.pos + Vector2.new(page.tabX, 4)
                    if isMouseOver(tabPos.X, tabPos.Y, page.tabWidth, TAB_HEIGHT) then
                        page:Show()
                        return
                    end
                end
            end
        end))
    end

    --========================================================================--
    --                            DRAGGING                                    --
    --========================================================================--

    table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
            local pos = window.objects.topbar.Position
            if isMouseOver(pos.X, pos.Y, sizeX - 4, TOPBAR_HEIGHT) then
                window.dragging = true
                local mouse = UserInputService:GetMouseLocation()
                window.dragOffset = Vector2.new(mouse.X - window.pos.X, mouse.Y - window.pos.Y)
            end
        end
    end))

    table.insert(library.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
        end
    end))

    table.insert(library.connections, RunService.RenderStepped:Connect(function()
        if window.dragging and library.open then
            local mouse = UserInputService:GetMouseLocation()
            window.pos = Vector2.new(mouse.X - window.dragOffset.X, mouse.Y - window.dragOffset.Y)
            window:UpdatePositions()
        end
    end))

    --========================================================================--
    --                          MENU TOGGLE                                   --
    --========================================================================--

    table.insert(library.connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == library.menuKeybind then
            window:Toggle()
        end
    end))

    --========================================================================--
    --                            UNLOAD                                      --
    --========================================================================--

    function window:Unload()
        for _, conn in pairs(library.connections) do
            pcall(function() conn:Disconnect() end)
        end
        library.connections = {}

        for _, obj in pairs(library.drawings) do
            pcall(function() obj:Remove() end)
        end
        library.drawings = {}

        library.watermark.objects = {}
        library.watermark._initialized = false
        library.keybindList.objects = {}
        library.keybindList.items = {}
        library.keybindList._initialized = false

        library.flags = {}
        library.pointers = {}
        library.notifications = {}
        library.accentObjects = {}
        library.themeObjects = {}
        library.tabTextObjects = {}
        library.toggleObjects = {}
        library.colorPickerPreviews = {}
        library.windows = {}

        library:Notify({
            title = "NexusLib",
            message = "Unloaded successfully",
            type = "success",
            duration = 2
        })
    end

    table.insert(library.windows, window)
    return window
end

--============================================================================--
--                            RETURN LIBRARY                                  --
--============================================================================--

return library
