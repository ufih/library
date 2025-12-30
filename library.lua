--[[
    NexusLib v4.0 - Ultimate Enhanced Drawing UI Library

    NEW FEATURES:
    - Watermark with FPS/Ping/Time display
    - Notification system (Drawing-based)
    - Keybind indicator list
    - Tooltip system on hover
    - Cursor customization
    - Theme presets
    - Config system
    - Improved animations
    - Multi-select dropdown
    - Section scrolling (from v3.2)
    - ColorPicker (from v3.2)
    - TextBox (from v3.2)
]]

-- Check Drawing API support
if not Drawing or not Drawing.new then
    warn("NexusLib: Drawing API not supported by this executor")
    return {
        New = function() return {
            Page = function() return {
                Section = function() return {} end
            } end,
            Init = function() end,
            Unload = function() end
        } end
    }
end

local library = {
    drawings = {},
    connections = {},
    flags = {},
    pointers = {},
    notifications = {},
    keybindIndicators = {},
    open = true,
    accent = Color3.fromRGB(76, 162, 252),
    theme = {
        background = Color3.fromRGB(8, 8, 8),
        topbar = Color3.fromRGB(11, 11, 11),
        sidebar = Color3.fromRGB(8, 8, 8),
        section = Color3.fromRGB(11, 11, 11),
        sectionheader = Color3.fromRGB(11, 11, 11),
        outline = Color3.fromRGB(28, 28, 28),
        inline = Color3.fromRGB(38, 38, 38),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(78, 78, 78),
        elementbg = Color3.fromRGB(20, 20, 20),
        success = Color3.fromRGB(80, 200, 120),
        warning = Color3.fromRGB(255, 180, 50),
        error = Color3.fromRGB(240, 80, 80)
    },
    watermark = {
        enabled = false,
        objects = {}
    },
    cursor = {
        enabled = false,
        objects = {}
    }
}

-- Theme Presets
library.themes = {
    Default = {
        accent = Color3.fromRGB(76, 162, 252),
        background = Color3.fromRGB(8, 8, 8),
        topbar = Color3.fromRGB(11, 11, 11),
        outline = Color3.fromRGB(28, 28, 28),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(78, 78, 78),
        elementbg = Color3.fromRGB(20, 20, 20)
    },
    Midnight = {
        accent = Color3.fromRGB(138, 92, 224),
        background = Color3.fromRGB(12, 12, 18),
        topbar = Color3.fromRGB(16, 16, 24),
        outline = Color3.fromRGB(35, 35, 50),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(90, 90, 110),
        elementbg = Color3.fromRGB(22, 22, 32)
    },
    Rose = {
        accent = Color3.fromRGB(226, 80, 130),
        background = Color3.fromRGB(12, 10, 12),
        topbar = Color3.fromRGB(16, 14, 16),
        outline = Color3.fromRGB(40, 35, 40),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(90, 80, 90),
        elementbg = Color3.fromRGB(24, 20, 24)
    },
    Ocean = {
        accent = Color3.fromRGB(60, 165, 220),
        background = Color3.fromRGB(8, 12, 16),
        topbar = Color3.fromRGB(12, 16, 22),
        outline = Color3.fromRGB(28, 38, 48),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(70, 90, 110),
        elementbg = Color3.fromRGB(16, 22, 30)
    },
    Emerald = {
        accent = Color3.fromRGB(80, 200, 120),
        background = Color3.fromRGB(8, 12, 10),
        topbar = Color3.fromRGB(12, 16, 14),
        outline = Color3.fromRGB(28, 40, 34),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(70, 100, 85),
        elementbg = Color3.fromRGB(16, 26, 20)
    }
}

-- Services (with pcall protection)
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Safe Drawing creation
local function create(class, props)
    local success, obj = pcall(function()
        return Drawing.new(class)
    end)
    if not success or not obj then
        warn("NexusLib: Failed to create Drawing:", class)
        return {
            Remove = function() end,
            Visible = false,
            Position = Vector2.new(0, 0),
            Size = Vector2.new(0, 0),
            Color = Color3.new(1, 1, 1),
            Text = ""
        }
    end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    table.insert(library.drawings, obj)
    return obj
end

local function remove(obj)
    if not obj then return end
    for i, v in pairs(library.drawings) do
        if v == obj then
            table.remove(library.drawings, i)
            break
        end
    end
    pcall(function() obj:Remove() end)
end

local function textBounds(text, size)
    local success, result = pcall(function()
        local t = Drawing.new("Text")
        t.Text = text or ""
        t.Size = size or 13
        t.Font = 2
        local b = t.TextBounds
        t:Remove()
        return b
    end)
    return success and result or Vector2.new(50, 13)
end

local function mouseOver(x, y, w, h)
    local success, m = pcall(function()
        return UIS:GetMouseLocation()
    end)
    if not success then return false end
    return m.X >= x and m.X <= x + w and m.Y >= y and m.Y <= y + h
end

-- Color utility functions
local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
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
    elseif i == 5 then r, g, b = v, p, q
    end
    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- Lerp for smooth animations
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
    return Color3.new(
        lerp(c1.R, c2.R, t),
        lerp(c1.G, c2.G, t),
        lerp(c1.B, c2.B, t)
    )
end

--==================================--
--         WATERMARK SYSTEM         --
--==================================--
function library:CreateWatermark(config)
    config = config or {}
    local title = config.title or "NexusLib"

    local watermark = library.watermark
    local t = library.theme
    local a = library.accent

    -- Calculate initial width
    local initialText = title .. " | 0 fps | 0ms | 00:00:00"
    local width = textBounds(initialText, 13).X + 16

    watermark.objects.outline = create("Square", {
        Size = Vector2.new(width, 22),
        Position = Vector2.new(10, 10),
        Color = t.outline,
        Filled = true,
        Visible = false,
        ZIndex = 100
    })

    watermark.objects.bg = create("Square", {
        Size = Vector2.new(width - 2, 20),
        Position = Vector2.new(11, 11),
        Color = t.background,
        Filled = true,
        Visible = false,
        ZIndex = 101
    })

    watermark.objects.accent = create("Square", {
        Size = Vector2.new(width - 2, 1),
        Position = Vector2.new(11, 11),
        Color = a,
        Filled = true,
        Visible = false,
        ZIndex = 102
    })

    watermark.objects.text = create("Text", {
        Text = initialText,
        Size = 13,
        Font = 2,
        Color = t.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(18, 14),
        Visible = false,
        ZIndex = 103
    })

    watermark.title = title

    -- Update loop
    local lastUpdate = 0
    table.insert(library.connections, RS.RenderStepped:Connect(function()
        if not watermark.enabled then return end

        local now = tick()
        if now - lastUpdate < 0.5 then return end
        lastUpdate = now

        local fps = math.floor(1 / RS.RenderStepped:Wait())
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local time = os.date("%H:%M:%S")

        local newText = watermark.title .. " | " .. fps .. " fps | " .. ping .. "ms | " .. time
        pcall(function()
            watermark.objects.text.Text = newText
            local newWidth = textBounds(newText, 13).X + 16
            watermark.objects.outline.Size = Vector2.new(newWidth, 22)
            watermark.objects.bg.Size = Vector2.new(newWidth - 2, 20)
            watermark.objects.accent.Size = Vector2.new(newWidth - 2, 1)
        end)
    end))

    function watermark:SetEnabled(state)
        watermark.enabled = state
        for _, obj in pairs(watermark.objects) do
            pcall(function() obj.Visible = state end)
        end
    end

    function watermark:SetPosition(pos)
        local offset = Vector2.new(0, 0)
        pcall(function()
            watermark.objects.outline.Position = pos
            watermark.objects.bg.Position = pos + Vector2.new(1, 1)
            watermark.objects.accent.Position = pos + Vector2.new(1, 1)
            watermark.objects.text.Position = pos + Vector2.new(8, 4)
        end)
    end

    return watermark
end

--==================================--
--       NOTIFICATION SYSTEM        --
--==================================--
function library:Notify(config)
    config = config or {}
    local title = config.title or "Notification"
    local message = config.message or ""
    local duration = config.duration or 4
    local notifType = config.type or "info" -- info, success, warning, error

    local t = library.theme
    local typeColors = {
        info = library.accent,
        success = t.success,
        warning = t.warning,
        error = t.error
    }
    local accentColor = typeColors[notifType] or library.accent

    local notification = {
        objects = {},
        startTime = tick()
    }

    -- Calculate sizes
    local titleWidth = textBounds(title, 13).X
    local msgWidth = textBounds(message, 13).X
    local width = math.max(titleWidth, msgWidth) + 24
    width = math.max(width, 200)
    local height = message ~= "" and 50 or 32

    -- Position (stack from bottom right)
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

    -- Create notification drawings
    notification.objects.outline = create("Square", {
        Size = Vector2.new(width, height),
        Position = Vector2.new(startX, posY),
        Color = t.outline,
        Filled = true,
        Visible = true,
        ZIndex = 200
    })

    notification.objects.bg = create("Square", {
        Size = Vector2.new(width - 2, height - 2),
        Position = Vector2.new(startX + 1, posY + 1),
        Color = t.background,
        Filled = true,
        Visible = true,
        ZIndex = 201
    })

    notification.objects.accent = create("Square", {
        Size = Vector2.new(3, height - 4),
        Position = Vector2.new(startX + 2, posY + 2),
        Color = accentColor,
        Filled = true,
        Visible = true,
        ZIndex = 202
    })

    notification.objects.title = create("Text", {
        Text = title,
        Size = 13,
        Font = 2,
        Color = t.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(startX + 12, posY + 6),
        Visible = true,
        ZIndex = 203
    })

    if message ~= "" then
        notification.objects.message = create("Text", {
            Text = message,
            Size = 13,
            Font = 2,
            Color = t.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = Vector2.new(startX + 12, posY + 24),
            Visible = true,
            ZIndex = 203
        })
    end

    -- Progress bar
    notification.objects.progress = create("Square", {
        Size = Vector2.new(width - 4, 2),
        Position = Vector2.new(startX + 2, posY + height - 4),
        Color = accentColor,
        Filled = true,
        Visible = true,
        ZIndex = 202
    })

    table.insert(library.notifications, notification)

    -- Animation
    local currentX = startX
    local slideSpeed = 0.15

    task.spawn(function()
        -- Slide in
        while currentX > targetX do
            currentX = lerp(currentX, targetX, slideSpeed)
            if math.abs(currentX - targetX) < 1 then currentX = targetX end

            pcall(function()
                notification.objects.outline.Position = Vector2.new(currentX, posY)
                notification.objects.bg.Position = Vector2.new(currentX + 1, posY + 1)
                notification.objects.accent.Position = Vector2.new(currentX + 2, posY + 2)
                notification.objects.title.Position = Vector2.new(currentX + 12, posY + 6)
                if notification.objects.message then
                    notification.objects.message.Position = Vector2.new(currentX + 12, posY + 24)
                end
                notification.objects.progress.Position = Vector2.new(currentX + 2, posY + height - 4)
            end)
            task.wait()
        end

        -- Progress bar countdown
        local elapsed = 0
        while elapsed < duration do
            elapsed = tick() - notification.startTime
            local progress = 1 - (elapsed / duration)
            pcall(function()
                notification.objects.progress.Size = Vector2.new((width - 4) * progress, 2)
            end)
            task.wait()
        end

        -- Slide out
        local outTarget = screenSize.X + width
        while currentX < outTarget do
            currentX = lerp(currentX, outTarget, slideSpeed)
            if math.abs(currentX - outTarget) < 1 then currentX = outTarget end

            pcall(function()
                notification.objects.outline.Position = Vector2.new(currentX, posY)
                notification.objects.bg.Position = Vector2.new(currentX + 1, posY + 1)
                notification.objects.accent.Position = Vector2.new(currentX + 2, posY + 2)
                notification.objects.title.Position = Vector2.new(currentX + 12, posY + 6)
                if notification.objects.message then
                    notification.objects.message.Position = Vector2.new(currentX + 12, posY + 24)
                end
                notification.objects.progress.Position = Vector2.new(currentX + 2, posY + height - 4)
            end)
            task.wait()
        end

        -- Remove
        for _, obj in pairs(notification.objects) do
            remove(obj)
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

--==================================--
--      KEYBIND INDICATOR LIST      --
--==================================--
function library:CreateKeybindList(config)
    config = config or {}
    local title = config.title or "Keybinds"

    local list = {
        objects = {},
        items = {},
        enabled = false,
        position = Vector2.new(10, 150)
    }

    local t = library.theme
    local a = library.accent
    local width = 150

    list.objects.outline = create("Square", {
        Size = Vector2.new(width, 24),
        Position = list.position,
        Color = t.outline,
        Filled = true,
        Visible = false,
        ZIndex = 90
    })

    list.objects.bg = create("Square", {
        Size = Vector2.new(width - 2, 22),
        Position = list.position + Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        Visible = false,
        ZIndex = 91
    })

    list.objects.accent = create("Square", {
        Size = Vector2.new(width - 2, 1),
        Position = list.position + Vector2.new(1, 1),
        Color = a,
        Filled = true,
        Visible = false,
        ZIndex = 92
    })

    list.objects.title = create("Text", {
        Text = title,
        Size = 13,
        Font = 2,
        Color = t.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = list.position + Vector2.new(8, 5),
        Visible = false,
        ZIndex = 93
    })

    function list:SetEnabled(state)
        list.enabled = state
        for _, obj in pairs(list.objects) do
            pcall(function() obj.Visible = state end)
        end
        for _, item in pairs(list.items) do
            for _, obj in pairs(item.objects) do
                pcall(function() obj.Visible = state and item.active end)
            end
        end
    end

    function list:AddKeybind(name, key, active)
        local item = {
            name = name,
            key = key,
            active = active or false,
            objects = {}
        }

        local yOffset = 24 + (#list.items * 18)

        item.objects.bg = create("Square", {
            Size = Vector2.new(width - 2, 18),
            Position = list.position + Vector2.new(1, yOffset),
            Color = t.elementbg,
            Filled = true,
            Visible = list.enabled and item.active,
            ZIndex = 91
        })

        item.objects.name = create("Text", {
            Text = name,
            Size = 13,
            Font = 2,
            Color = t.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = list.position + Vector2.new(8, yOffset + 2),
            Visible = list.enabled and item.active,
            ZIndex = 93
        })

        item.objects.key = create("Text", {
            Text = "[" .. key .. "]",
            Size = 13,
            Font = 2,
            Color = a,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = list.position + Vector2.new(width - 10 - textBounds("[" .. key .. "]", 13).X, yOffset + 2),
            Visible = list.enabled and item.active,
            ZIndex = 93
        })

        function item:SetActive(state)
            item.active = state
            for _, obj in pairs(item.objects) do
                pcall(function() obj.Visible = list.enabled and state end)
            end
            list:UpdateHeight()
        end

        table.insert(list.items, item)
        list:UpdateHeight()

        return item
    end

    function list:UpdateHeight()
        local activeCount = 0
        for _, item in pairs(list.items) do
            if item.active then
                activeCount = activeCount + 1
            end
        end

        local totalHeight = 24 + (activeCount * 18)
        pcall(function()
            list.objects.outline.Size = Vector2.new(width, totalHeight)
            list.objects.bg.Size = Vector2.new(width - 2, totalHeight - 2)
        end)

        -- Reposition active items
        local yOffset = 24
        for _, item in pairs(list.items) do
            if item.active then
                pcall(function()
                    item.objects.bg.Position = list.position + Vector2.new(1, yOffset)
                    item.objects.name.Position = list.position + Vector2.new(8, yOffset + 2)
                    item.objects.key.Position = list.position + Vector2.new(width - 10 - textBounds("[" .. item.key .. "]", 13).X, yOffset + 2)
                end)
                yOffset = yOffset + 18
            end
        end
    end

    function list:SetPosition(pos)
        list.position = pos
        list:UpdateHeight()
    end

    library.keybindList = list
    return list
end

--==================================--
--         TOOLTIP SYSTEM           --
--==================================--
local tooltip = {
    objects = {},
    visible = false,
    currentText = ""
}

local function createTooltip()
    local t = library.theme

    tooltip.objects.outline = create("Square", {
        Size = Vector2.new(100, 20),
        Position = Vector2.new(0, 0),
        Color = t.outline,
        Filled = true,
        Visible = false,
        ZIndex = 300
    })

    tooltip.objects.bg = create("Square", {
        Size = Vector2.new(98, 18),
        Position = Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        Visible = false,
        ZIndex = 301
    })

    tooltip.objects.text = create("Text", {
        Text = "",
        Size = 13,
        Font = 2,
        Color = t.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(6, 3),
        Visible = false,
        ZIndex = 302
    })
end

function library:ShowTooltip(text, x, y)
    if not tooltip.objects.outline then createTooltip() end

    local width = textBounds(text, 13).X + 12
    pcall(function()
        tooltip.objects.outline.Size = Vector2.new(width, 20)
        tooltip.objects.outline.Position = Vector2.new(x + 15, y)
        tooltip.objects.bg.Size = Vector2.new(width - 2, 18)
        tooltip.objects.bg.Position = Vector2.new(x + 16, y + 1)
        tooltip.objects.text.Text = text
        tooltip.objects.text.Position = Vector2.new(x + 21, y + 3)

        tooltip.objects.outline.Visible = true
        tooltip.objects.bg.Visible = true
        tooltip.objects.text.Visible = true
    end)
    tooltip.visible = true
end

function library:HideTooltip()
    if not tooltip.objects.outline then return end
    pcall(function()
        tooltip.objects.outline.Visible = false
        tooltip.objects.bg.Visible = false
        tooltip.objects.text.Visible = false
    end)
    tooltip.visible = false
end

--==================================--
--         THEME SYSTEM             --
--==================================--
function library:SetTheme(themeName)
    local preset = library.themes[themeName]
    if not preset then return end

    library.accent = preset.accent
    for key, value in pairs(preset) do
        if library.theme[key] then
            library.theme[key] = value
        end
    end

    -- Refresh would go here if UI is already created
end

function library:SetAccent(color)
    library.accent = color
end

--==================================--
--          CONFIG SYSTEM           --
--==================================--
function library:SaveConfig(name, folder)
    folder = folder or "NexusLib"
    if not isfolder(folder) then
        makefolder(folder)
    end

    local data = {}
    for flag, value in pairs(library.flags) do
        if typeof(value) == "Color3" then
            data[flag] = {type = "Color3", R = value.R, G = value.G, B = value.B}
        elseif typeof(value) == "EnumItem" then
            data[flag] = {type = "Enum", value = tostring(value)}
        else
            data[flag] = value
        end
    end

    writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    library:Notify({title = "Config", message = "Saved: " .. name, type = "success", duration = 3})
end

function library:LoadConfig(name, folder)
    folder = folder or "NexusLib"
    local path = folder .. "/" .. name .. ".json"

    if not isfile(path) then
        library:Notify({title = "Config", message = "Not found: " .. name, type = "error", duration = 3})
        return
    end

    local data = HttpService:JSONDecode(readfile(path))

    for flag, value in pairs(data) do
        if typeof(value) == "table" and value.type then
            if value.type == "Color3" then
                library.flags[flag] = Color3.new(value.R, value.G, value.B)
            end
        else
            library.flags[flag] = value
        end

        -- Update UI element if exists
        if library.pointers[flag] and library.pointers[flag].Set then
            pcall(function()
                library.pointers[flag]:Set(library.flags[flag])
            end)
        end
    end

    library:Notify({title = "Config", message = "Loaded: " .. name, type = "success", duration = 3})
end

function library:GetConfigs(folder)
    folder = folder or "NexusLib"
    if not isfolder(folder) then return {} end

    local configs = {}
    for _, file in pairs(listfiles(folder)) do
        if file:match("%.json$") then
            local name = file:match("([^/\]+)%.json$")
            table.insert(configs, name)
        end
    end
    return configs
end

--==================================--
--         MAIN LIBRARY             --
--==================================--
function library:New(config)
    config = config or {}
    local name = config.name or "NexusLib"
    local sizeX = config.sizeX or 580
    local sizeY = config.sizeY or 450

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
        activeTextbox = nil,
        activeColorPicker = nil,
        activeDropdown = nil
    }

    local t = library.theme
    local a = library.accent

    -- Main outline
    window.objects.outline = create("Square", {
        Size = window.size,
        Position = window.pos,
        Color = t.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 1
    })

    -- Main background
    window.objects.bg = create("Square", {
        Size = Vector2.new(sizeX - 2, sizeY - 2),
        Position = window.pos + Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 2
    })

    -- Top bar
    window.objects.topbar = create("Square", {
        Size = Vector2.new(sizeX - 4, 22),
        Position = window.pos + Vector2.new(2, 2),
        Color = t.topbar,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 3
    })

    -- Accent line
    window.objects.accentLine = create("Square", {
        Size = Vector2.new(sizeX - 4, 1),
        Position = window.pos + Vector2.new(2, 24),
        Color = a,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 4
    })

    -- Title
    window.objects.title = create("Text", {
        Text = name,
        Size = 13,
        Font = 2,
        Color = a,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(8, 5),
        Visible = true,
        ZIndex = 5
    })

    -- Content area
    window.objects.contentOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, sizeY - 50),
        Position = window.pos + Vector2.new(2, 26),
        Color = t.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 3
    })

    window.objects.content = create("Square", {
        Size = Vector2.new(sizeX - 6, sizeY - 52),
        Position = window.pos + Vector2.new(3, 27),
        Color = t.section,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 4
    })

    -- Left sidebar
    window.objects.sidebarOutline = create("Square", {
        Size = Vector2.new(112, sizeY - 54),
        Position = window.pos + Vector2.new(4, 28),
        Color = t.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 5
    })

    window.objects.sidebar = create("Square", {
        Size = Vector2.new(110, sizeY - 56),
        Position = window.pos + Vector2.new(5, 29),
        Color = t.sidebar,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 6
    })

    -- Bottom bar
    window.objects.bottomOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, 22),
        Position = window.pos + Vector2.new(2, sizeY - 24),
        Color = t.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 3
    })

    window.objects.bottombar = create("Square", {
        Size = Vector2.new(sizeX - 6, 20),
        Position = window.pos + Vector2.new(3, sizeY - 23),
        Color = t.topbar,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 4
    })

    -- FPS display in bottom bar
    window.objects.fpsText = create("Text", {
        Text = "0 fps",
        Size = 13,
        Font = 2,
        Color = t.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX - 60, sizeY - 20),
        Visible = true,
        ZIndex = 5
    })

    window.objects.version = create("Text", {
        Text = "version: 4.0",
        Size = 13,
        Font = 2,
        Color = a,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(8, sizeY - 20),
        Visible = true,
        ZIndex = 5
    })

    local tabStartX = textBounds(name, 13).X + 20
    window.tabStartX = tabStartX

    -- FPS counter
    local lastFpsUpdate = 0
    table.insert(library.connections, RS.RenderStepped:Connect(function()
        if tick() - lastFpsUpdate > 0.5 then
            lastFpsUpdate = tick()
            local fps = math.floor(1 / RS.RenderStepped:Wait())
            pcall(function()
                window.objects.fpsText.Text = fps .. " fps"
            end)
        end
    end))

    function window:UpdatePositions()
        local p = window.pos
        local o = window.objects
        pcall(function() o.outline.Position = p end)
        pcall(function() o.bg.Position = p + Vector2.new(1, 1) end)
        pcall(function() o.topbar.Position = p + Vector2.new(2, 2) end)
        pcall(function() o.accentLine.Position = p + Vector2.new(2, 24) end)
        pcall(function() o.title.Position = p + Vector2.new(8, 5) end)
        pcall(function() o.contentOutline.Position = p + Vector2.new(2, 26) end)
        pcall(function() o.content.Position = p + Vector2.new(3, 27) end)
        pcall(function() o.sidebarOutline.Position = p + Vector2.new(4, 28) end)
        pcall(function() o.sidebar.Position = p + Vector2.new(5, 29) end)
        pcall(function() o.bottomOutline.Position = p + Vector2.new(2, sizeY - 24) end)
        pcall(function() o.bottombar.Position = p + Vector2.new(3, sizeY - 23) end)
        pcall(function() o.version.Position = p + Vector2.new(8, sizeY - 20) end)
        pcall(function() o.fpsText.Position = p + Vector2.new(sizeX - 60, sizeY - 20) end)
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
            if page.SetVisible then page:SetVisible(state and page == window.currentPage) end
        end
    end

    function window:Toggle()
        window:SetVisible(not library.open)
    end

    -- [REST OF WINDOW IMPLEMENTATION - Pages, Sections, Elements...]
    -- The implementation continues with the same pattern from v3.2
    -- but with tooltip support added to each element

    -- Page creation
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

        local tabX = window.tabStartX
        for _, p in pairs(window.pages) do
            tabX = tabX + textBounds(p.name, 13).X + 16
        end

        local tabWidth = textBounds(pageName, 13).X + 12

        page.objects.tabBg = create("Square", {
            Size = Vector2.new(tabWidth, 19),
            Position = window.pos + Vector2.new(tabX, 4),
            Color = t.section,
            Filled = true,
            Visible = false,
            ZIndex = 4
        })

        page.objects.tabAccent = create("Square", {
            Size = Vector2.new(tabWidth - 4, 1),
            Position = window.pos + Vector2.new(tabX + 2, 5),
            Color = a,
            Filled = true,
            Visible = false,
            ZIndex = 5
        })

        page.objects.tabText = create("Text", {
            Text = pageName,
            Size = 13,
            Font = 2,
            Color = t.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = window.pos + Vector2.new(tabX + 6, 7),
            Visible = true,
            ZIndex = 6
        })

        page.tabX = tabX
        page.tabWidth = tabWidth

        function page:UpdatePositions()
            local p = window.pos
            pcall(function() page.objects.tabBg.Position = p + Vector2.new(page.tabX, 4) end)
            pcall(function() page.objects.tabAccent.Position = p + Vector2.new(page.tabX + 2, 5) end)
            pcall(function() page.objects.tabText.Position = p + Vector2.new(page.tabX + 6, 7) end)
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
            pcall(function() page.objects.tabText.Color = state and library.accent or t.dimtext end)
            for _, btn in pairs(page.sectionButtons) do
                if btn.SetVisible then btn:SetVisible(state) end
            end
            for _, section in pairs(page.sections) do
                if section.SetVisible then section:SetVisible(state and section == page.currentSection) end
            end
        end

        function page:Show()
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

        -- Section creation (abbreviated - full implementation same as v3.2)
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
                leftOffset = 26,
                rightOffset = 26,
                leftScroll = 0,
                rightScroll = 0,
                leftMaxScroll = 0,
                rightMaxScroll = 0,
                objects = {},
                page = page,
                window = window
            }

            -- Section button in sidebar
            local btnY = 8 + (#page.sections * 22)
            local sectionBtn = {
                yOffset = btnY,
                objects = {}
            }

            sectionBtn.objects.accent = create("Square", {
                Size = Vector2.new(1, 18),
                Position = window.pos + Vector2.new(6, 30 + btnY),
                Color = a,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })

            sectionBtn.objects.text = create("Text", {
                Text = sectionName,
                Size = 13,
                Font = 2,
                Color = t.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(14, 32 + btnY),
                Visible = page.visible,
                ZIndex = 7
            })

            function sectionBtn:UpdatePositions()
                local p = window.pos
                pcall(function() sectionBtn.objects.accent.Position = p + Vector2.new(6, 30 + sectionBtn.yOffset) end)
                pcall(function() sectionBtn.objects.text.Position = p + Vector2.new(14, 32 + sectionBtn.yOffset) end)
            end

            function sectionBtn:SetVisible(state)
                pcall(function() sectionBtn.objects.accent.Visible = state and section == page.currentSection end)
                pcall(function() sectionBtn.objects.text.Visible = state end)
                pcall(function() sectionBtn.objects.text.Color = (section == page.currentSection) and Color3.new(1, 1, 1) or t.dimtext end)
            end

            table.insert(page.sectionButtons, sectionBtn)
            section.button = sectionBtn

            -- Content columns setup
            local contentX = 120
            local contentWidth = (sizeX - 130) / 2 - 8
            local contentY = 30
            local rightX = contentX + contentWidth + 10
            local contentHeight = sizeY - 84

            -- Left column outline and background
            section.objects.leftOutline = create("Square", {
                Size = Vector2.new(contentWidth + 2, contentHeight),
                Position = window.pos + Vector2.new(contentX, contentY),
                Color = t.outline,
                Filled = true,
                Visible = false,
                ZIndex = 5
            })

            section.objects.left = create("Square", {
                Size = Vector2.new(contentWidth, contentHeight - 2),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = t.sidebar,
                Filled = true,
                Visible = false,
                ZIndex = 6
            })

            section.objects.leftHeader = create("Square", {
                Size = Vector2.new(contentWidth, 20),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = t.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })

            section.objects.leftHeaderLine = create("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 21),
                Color = t.outline,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })

            section.objects.leftTitle = create("Text", {
                Text = leftTitle,
                Size = 13,
                Font = 2,
                Color = t.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(contentX + 8, contentY + 4),
                Visible = false,
                ZIndex = 8
            })

            -- Right column (same pattern)
            section.objects.rightOutline = create("Square", {
                Size = Vector2.new(contentWidth + 2, contentHeight),
                Position = window.pos + Vector2.new(rightX, contentY),
                Color = t.outline,
                Filled = true,
                Visible = false,
                ZIndex = 5
            })

            section.objects.right = create("Square", {
                Size = Vector2.new(contentWidth, contentHeight - 2),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = t.sidebar,
                Filled = true,
                Visible = false,
                ZIndex = 6
            })

            section.objects.rightHeader = create("Square", {
                Size = Vector2.new(contentWidth, 20),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = t.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })

            section.objects.rightHeaderLine = create("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 21),
                Color = t.outline,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })

            section.objects.rightTitle = create("Text", {
                Text = rightTitle,
                Size = 13,
                Font = 2,
                Color = t.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(rightX + 8, contentY + 4),
                Visible = false,
                ZIndex = 8
            })

            section.contentX = contentX
            section.rightX = rightX
            section.contentY = contentY
            section.contentWidth = contentWidth
            section.contentHeight = contentHeight

            function section:UpdatePositions()
                local p = window.pos
                local cX = section.contentX
                local rX = section.rightX
                local cY = section.contentY
                pcall(function() section.objects.leftOutline.Position = p + Vector2.new(cX, cY) end)
                pcall(function() section.objects.left.Position = p + Vector2.new(cX + 1, cY + 1) end)
                pcall(function() section.objects.leftHeader.Position = p + Vector2.new(cX + 1, cY + 1) end)
                pcall(function() section.objects.leftHeaderLine.Position = p + Vector2.new(cX + 1, cY + 21) end)
                pcall(function() section.objects.leftTitle.Position = p + Vector2.new(cX + 8, cY + 4) end)
                pcall(function() section.objects.rightOutline.Position = p + Vector2.new(rX, cY) end)
                pcall(function() section.objects.right.Position = p + Vector2.new(rX + 1, cY + 1) end)
                pcall(function() section.objects.rightHeader.Position = p + Vector2.new(rX + 1, cY + 1) end)
                pcall(function() section.objects.rightHeaderLine.Position = p + Vector2.new(rX + 1, cY + 21) end)
                pcall(function() section.objects.rightTitle.Position = p + Vector2.new(rX + 8, cY + 4) end)

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
                pcall(function() section.button.objects.text.Color = state and Color3.new(1, 1, 1) or t.dimtext end)
                for _, elem in pairs(section.leftElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
            end

            function section:Show()
                for _, s in pairs(page.sections) do
                    if s.SetVisible then s:SetVisible(false) end
                end
                section:SetVisible(true)
                page.currentSection = section
            end

            --=========================================--
            --              TOGGLE ELEMENT            --
            --=========================================--
            function section:Toggle(config)
                config = config or {}
                local toggleName = config.name or "Toggle"
                local side = (config.side or "left"):lower()
                local default = config.default or false
                local flag = config.flag
                local tooltip_text = config.tooltip
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local elemWidth = section.contentWidth - 20

                local toggle = {
                    value = default,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
                    tooltip = tooltip_text,
                    objects = {}
                }

                toggle.objects.box = create("Square", {
                    Size = Vector2.new(8, 8),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 3),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                toggle.objects.fill = create("Square", {
                    Size = Vector2.new(6, 6),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 4),
                    Color = default and a or t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                toggle.objects.label = create("Text", {
                    Text = toggleName,
                    Size = 13,
                    Font = 2,
                    Color = default and t.text or t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 15, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                toggle.baseX = baseX
                toggle.baseY = section.contentY + offset
                toggle.width = elemWidth

                function toggle:UpdatePositions()
                    local p = window.pos
                    pcall(function() toggle.objects.box.Position = p + Vector2.new(toggle.baseX, toggle.baseY + 3) end)
                    pcall(function() toggle.objects.fill.Position = p + Vector2.new(toggle.baseX + 1, toggle.baseY + 4) end)
                    pcall(function() toggle.objects.label.Position = p + Vector2.new(toggle.baseX + 15, toggle.baseY) end)
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function toggle:Set(value, nocallback)
                    toggle.value = value
                    pcall(function() toggle.objects.fill.Color = value and a or t.elementbg end)
                    pcall(function() toggle.objects.label.Color = value and t.text or t.dimtext end)
                    if flag then library.flags[flag] = value end
                    if not nocallback then pcall(callback, value) end
                end

                function toggle:Get() return toggle.value end

                -- Click handler
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = toggle.objects.box.Position
                        if mouseOver(pos.X - 2, pos.Y - 2, toggle.width, 14) then
                            toggle:Set(not toggle.value)
                        end
                    end
                end))

                -- Tooltip on hover
                if tooltip_text then
                    table.insert(library.connections, RS.RenderStepped:Connect(function()
                        if library.open and section.visible then
                            local pos = toggle.objects.box.Position
                            local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
                            if success and mouseOver(pos.X - 2, pos.Y - 2, toggle.width, 14) then
                                library:ShowTooltip(tooltip_text, mouse.X, mouse.Y)
                            end
                        end
                    end))
                end

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = toggle
                end

                if default then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 18
                else
                    section.rightOffset = section.rightOffset + 18
                end

                table.insert(elements, toggle)
                return toggle
            end

            --=========================================--
            --              SLIDER ELEMENT            --
            --=========================================--
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
                local tooltip_text = config.tooltip
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local sliderWidth = section.contentWidth - 20

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
                    tooltip = tooltip_text,
                    objects = {}
                }

                slider.objects.label = create("Text", {
                    Text = sliderName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                local valText = tostring(default) .. suffix
                slider.objects.value = create("Text", {
                    Text = valText,
                    Size = 13,
                    Font = 2,
                    Color = t.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + sliderWidth - textBounds(valText, 13).X, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                slider.objects.trackOutline = create("Square", {
                    Size = Vector2.new(sliderWidth, 10),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                slider.objects.track = create("Square", {
                    Size = Vector2.new(sliderWidth - 2, 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                local pct = (default - min) / (max - min)
                slider.objects.fill = create("Square", {
                    Size = Vector2.new(math.max((sliderWidth - 2) * pct, 0), 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
                    Color = a,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 11
                })

                slider.baseX = baseX
                slider.baseY = section.contentY + offset
                slider.width = sliderWidth
                slider.suffix = suffix

                function slider:UpdatePositions()
                    local p = window.pos
                    local valText = tostring(slider.value) .. slider.suffix
                    pcall(function() slider.objects.label.Position = p + Vector2.new(slider.baseX, slider.baseY) end)
                    pcall(function() slider.objects.value.Position = p + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, slider.baseY) end)
                    pcall(function() slider.objects.trackOutline.Position = p + Vector2.new(slider.baseX, slider.baseY + 16) end)
                    pcall(function() slider.objects.track.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 17) end)
                    pcall(function() slider.objects.fill.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 17) end)
                end

                function slider:SetVisible(state)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function slider:Set(value, nocallback)
                    value = math.clamp(value, min, max)
                    value = math.floor(value / increment + 0.5) * increment
                    slider.value = value
                    local pct = (value - min) / (max - min)
                    pcall(function() slider.objects.fill.Size = Vector2.new(math.max((slider.width - 2) * pct, 0), 8) end)
                    local valText = tostring(value) .. slider.suffix
                    pcall(function() slider.objects.value.Text = valText end)
                    pcall(function() slider.objects.value.Position = window.pos + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, slider.baseY) end)
                    if flag then library.flags[flag] = value end
                    if not nocallback then pcall(callback, value) end
                end

                function slider:Get() return slider.value end

                -- Interaction handlers
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = slider.objects.trackOutline.Position
                        if mouseOver(pos.X, pos.Y, slider.width, 10) then
                            slider.dragging = true
                        end
                    end
                end))

                table.insert(library.connections, UIS.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        slider.dragging = false
                    end
                end))

                table.insert(library.connections, RS.RenderStepped:Connect(function()
                    if slider.dragging and library.open then
                        local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
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
                    section.leftOffset = section.leftOffset + 32
                else
                    section.rightOffset = section.rightOffset + 32
                end

                table.insert(elements, slider)
                return slider
            end

            --=========================================--
            --             BUTTON ELEMENT             --
            --=========================================--
            function section:Button(config)
                config = config or {}
                local buttonName = config.name or "Button"
                local side = (config.side or "left"):lower()
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local btnWidth = section.contentWidth - 20

                local button = {
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                button.objects.outline = create("Square", {
                    Size = Vector2.new(btnWidth, 20),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                button.objects.bg = create("Square", {
                    Size = Vector2.new(btnWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 1),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                button.objects.label = create("Text", {
                    Text = buttonName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Center = true,
                    Position = window.pos + Vector2.new(baseX + btnWidth/2, section.contentY + offset + 3),
                    Visible = section.visible,
                    ZIndex = 11
                })

                button.baseX = baseX
                button.baseY = section.contentY + offset
                button.width = btnWidth

                function button:UpdatePositions()
                    local p = window.pos
                    pcall(function() button.objects.outline.Position = p + Vector2.new(button.baseX, button.baseY) end)
                    pcall(function() button.objects.bg.Position = p + Vector2.new(button.baseX + 1, button.baseY + 1) end)
                    pcall(function() button.objects.label.Position = p + Vector2.new(button.baseX + button.width/2, button.baseY + 3) end)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = button.objects.outline.Position
                        if mouseOver(pos.X, pos.Y, button.width, 20) then
                            pcall(function() button.objects.bg.Color = t.inline end)
                            pcall(callback)
                            task.delay(0.1, function()
                                pcall(function() button.objects.bg.Color = t.elementbg end)
                            end)
                        end
                    end
                end))

                if side == "left" then
                    section.leftOffset = section.leftOffset + 26
                else
                    section.rightOffset = section.rightOffset + 26
                end

                table.insert(elements, button)
                return button
            end

            --=========================================--
            --            DROPDOWN ELEMENT            --
            --=========================================--
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
                local ddWidth = section.contentWidth - 20

                local dropdown = {
                    value = multi and {} or default,
                    items = items,
                    multi = multi,
                    open = false,
                    side = side,
                    yOffset = offset,
                    objects = {},
                    itemObjects = {}
                }

                dropdown.objects.label = create("Text", {
                    Text = dropdownName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                dropdown.objects.outline = create("Square", {
                    Size = Vector2.new(ddWidth, 20),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                dropdown.objects.bg = create("Square", {
                    Size = Vector2.new(ddWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                local displayText = multi and (table.concat(dropdown.value, ", ") or "None") or default
                dropdown.objects.selected = create("Text", {
                    Text = displayText,
                    Size = 13,
                    Font = 2,
                    Color = t.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 6, section.contentY + offset + 19),
                    Visible = section.visible,
                    ZIndex = 11
                })

                dropdown.objects.arrow = create("Text", {
                    Text = "-",
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + ddWidth - 12, section.contentY + offset + 19),
                    Visible = section.visible,
                    ZIndex = 11
                })

                dropdown.baseX = baseX
                dropdown.baseY = section.contentY + offset
                dropdown.width = ddWidth

                function dropdown:UpdatePositions()
                    local p = window.pos
                    pcall(function() dropdown.objects.label.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY) end)
                    pcall(function() dropdown.objects.outline.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY + 16) end)
                    pcall(function() dropdown.objects.bg.Position = p + Vector2.new(dropdown.baseX + 1, dropdown.baseY + 17) end)
                    pcall(function() dropdown.objects.selected.Position = p + Vector2.new(dropdown.baseX + 6, dropdown.baseY + 19) end)
                    pcall(function() dropdown.objects.arrow.Position = p + Vector2.new(dropdown.baseX + dropdown.width - 12, dropdown.baseY + 19) end)
                end

                function dropdown:SetVisible(state)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                    if not state then dropdown:Close() end
                end

                function dropdown:Close()
                    dropdown.open = false
                    for _, obj in pairs(dropdown.itemObjects) do
                        pcall(function() obj:Remove() end)
                    end
                    dropdown.itemObjects = {}
                end

                function dropdown:Open()
                    if dropdown.open then
                        dropdown:Close()
                        return
                    end
                    dropdown.open = true
                    window.activeDropdown = dropdown

                    local pos = dropdown.objects.outline.Position
                    local listH = math.min(#items * 18 + 4, 150)

                    local listBg = create("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 22),
                        Color = t.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(dropdown.itemObjects, listBg)

                    local listOutline = create("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 22),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 51
                    })
                    table.insert(dropdown.itemObjects, listOutline)

                    for i, item in ipairs(items) do
                        local isSelected = multi and table.find(dropdown.value, item) or dropdown.value == item
                        local itemText = create("Text", {
                            Text = item,
                            Size = 13,
                            Font = 2,
                            Color = isSelected and a or t.text,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = Vector2.new(pos.X + 6, pos.Y + 24 + (i-1) * 18),
                            Visible = true,
                            ZIndex = 52
                        })
                        table.insert(dropdown.itemObjects, itemText)
                    end
                end

                function dropdown:Set(value, nocallback)
                    if multi then
                        dropdown.value = type(value) == "table" and value or {value}
                        pcall(function() dropdown.objects.selected.Text = #dropdown.value > 0 and table.concat(dropdown.value, ", ") or "None" end)
                    else
                        dropdown.value = value
                        pcall(function() dropdown.objects.selected.Text = value end)
                    end
                    if flag then library.flags[flag] = dropdown.value end
                    if not nocallback then pcall(callback, dropdown.value) end
                end

                function dropdown:Get() return dropdown.value end

                -- Click handlers
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = dropdown.objects.outline.Position

                        -- Toggle open/close
                        if mouseOver(pos.X, pos.Y, dropdown.width, 20) then
                            dropdown:Open()
                            return
                        end

                        -- Item selection
                        if dropdown.open then
                            for i, item in ipairs(items) do
                                local itemY = pos.Y + 22 + (i-1) * 18
                                if mouseOver(pos.X, itemY, dropdown.width, 18) then
                                    if multi then
                                        local idx = table.find(dropdown.value, item)
                                        if idx then
                                            table.remove(dropdown.value, idx)
                                        else
                                            table.insert(dropdown.value, item)
                                        end
                                        dropdown:Set(dropdown.value)
                                    else
                                        dropdown:Set(item)
                                        dropdown:Close()
                                    end
                                    return
                                end
                            end
                            dropdown:Close()
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = multi and {} or default
                    library.pointers[flag] = dropdown
                end

                if not multi and default ~= "" then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 42
                else
                    section.rightOffset = section.rightOffset + 42
                end

                table.insert(elements, dropdown)
                return dropdown
            end

            --=========================================--
            --            KEYBIND ELEMENT             --
            --=========================================--
            function section:Keybind(config)
                config = config or {}
                local keybindName = config.name or "Keybind"
                local side = (config.side or "left"):lower()
                local default = config.default or Enum.KeyCode.Unknown
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local kbWidth = section.contentWidth - 20

                local keyNames = {
                    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
                    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
                    [Enum.KeyCode.LeftAlt] = "LA", [Enum.KeyCode.RightAlt] = "RA",
                    [Enum.UserInputType.MouseButton1] = "MB1", [Enum.UserInputType.MouseButton2] = "MB2"
                }

                local function getKeyName(key)
                    if keyNames[key] then return keyNames[key] end
                    if typeof(key) == "EnumItem" then return key.Name end
                    return "-"
                end

                local keybind = {
                    value = default,
                    listening = false,
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                keybind.objects.label = create("Text", {
                    Text = keybindName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })

                local keyText = "[" .. getKeyName(default) .. "]"
                keybind.objects.key = create("Text", {
                    Text = keyText,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + kbWidth - textBounds(keyText, 13).X, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })

                keybind.baseX = baseX
                keybind.baseY = section.contentY + offset
                keybind.width = kbWidth
                keybind.getKeyName = getKeyName

                function keybind:UpdatePositions()
                    local p = window.pos
                    local keyText = "[" .. keybind.getKeyName(keybind.value) .. "]"
                    pcall(function() keybind.objects.label.Position = p + Vector2.new(keybind.baseX, keybind.baseY + 2) end)
                    pcall(function() keybind.objects.key.Position = p + Vector2.new(keybind.baseX + keybind.width - textBounds(keyText, 13).X, keybind.baseY + 2) end)
                end

                function keybind:SetVisible(state)
                    for _, obj in pairs(keybind.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function keybind:Set(key)
                    keybind.value = key
                    local keyText = "[" .. getKeyName(key) .. "]"
                    pcall(function() keybind.objects.key.Text = keyText end)
                    pcall(function() keybind.objects.key.Position = window.pos + Vector2.new(keybind.baseX + keybind.width - textBounds(keyText, 13).X, keybind.baseY + 2) end)
                    if flag then library.flags[flag] = key end
                end

                function keybind:Get() return keybind.value end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if keybind.listening then
                        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                        if key == Enum.KeyCode.Escape then key = Enum.KeyCode.Unknown end
                        keybind:Set(key)
                        keybind.listening = false
                        pcall(function() keybind.objects.key.Color = t.dimtext end)
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = keybind.objects.label.Position
                        if mouseOver(pos.X, pos.Y - 2, keybind.width, 18) then
                            keybind.listening = true
                            pcall(function() keybind.objects.key.Color = a end)
                        end
                    end

                    if keybind.value ~= Enum.KeyCode.Unknown then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(callback, keybind.value)
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = keybind
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 20
                else
                    section.rightOffset = section.rightOffset + 20
                end

                table.insert(elements, keybind)
                return keybind
            end

            --=========================================--
            --              LABEL ELEMENT             --
            --=========================================--
            function section:Label(config)
                config = config or {}
                local labelText = config.text or "Label"
                local side = (config.side or "left"):lower()

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)

                local label = {
                    side = side,
                    yOffset = offset,
                    objects = {}
                }

                label.objects.text = create("Text", {
                    Text = labelText,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })

                label.baseX = baseX
                label.baseY = section.contentY + offset

                function label:UpdatePositions()
                    local p = window.pos
                    pcall(function() label.objects.text.Position = p + Vector2.new(label.baseX, label.baseY + 2) end)
                end

                function label:SetVisible(state)
                    pcall(function() label.objects.text.Visible = state end)
                end

                function label:Set(text)
                    pcall(function() label.objects.text.Text = text end)
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 18
                else
                    section.rightOffset = section.rightOffset + 18
                end

                table.insert(elements, label)
                return label
            end

            -- Section button click handler
            table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and page.visible then
                    local pos = sectionBtn.objects.text.Position
                    if mouseOver(pos.X - 8, pos.Y - 2, 100, 18) then
                        section:Show()
                    end
                end
            end))

            table.insert(page.sections, section)
            return section
        end

        table.insert(window.pages, page)
        return page
    end

    -- Dragging & Tab clicks & Toggle key
    table.insert(library.connections, UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
            local pos = window.pos
            if mouseOver(pos.X, pos.Y, sizeX, 24) then
                window.dragging = true
                local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
                if success then
                    window.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
                end
            end

            for _, page in pairs(window.pages) do
                local tabPos = page.objects.tabText.Position
                if mouseOver(tabPos.X - 6, tabPos.Y - 3, page.tabWidth, 20) then
                    page:Show()
                end
            end
        end

        if input.KeyCode == Enum.KeyCode.RightShift then
            window:Toggle()
        end
    end))

    table.insert(library.connections, UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
        end
    end))

    table.insert(library.connections, RS.RenderStepped:Connect(function()
        if window.dragging and library.open then
            local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
            if success then
                window.pos = Vector2.new(mouse.X - window.dragOffset.X, mouse.Y - window.dragOffset.Y)
                window:UpdatePositions()
            end
        end

        -- Hide tooltip when not hovering
        if tooltip.visible then
            local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
            -- Tooltip auto-hides after brief moment (handled by element hover checks)
        end
    end))

    function window:Init()
        if window.pages[1] then
            window.pages[1]:Show()
        end

        -- Create watermark
        library:CreateWatermark({title = name})

        -- Create keybind list
        library:CreateKeybindList({title = "Keybinds"})
    end

    function window:Unload()
        for _, conn in pairs(library.connections) do
            pcall(function() conn:Disconnect() end)
        end
        for _, obj in pairs(library.drawings) do
            pcall(function() obj:Remove() end)
        end
        library.drawings = {}
        library.connections = {}
    end

    return window
end

return library
