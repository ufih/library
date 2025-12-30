--[[
    NexusLib v4.1 - Ultimate Enhanced Drawing UI Library

    FIXES:
    - Tooltips now properly disappear when mouse leaves
    - Tooltips require 2 second hover delay before showing
    - Improved visual styling
    - Better element spacing
    - Enhanced accent usage
]]

-- Check Drawing API support
if not Drawing or not Drawing.new then
    warn("NexusLib: Drawing API not supported")
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
        background = Color3.fromRGB(12, 12, 12),
        topbar = Color3.fromRGB(16, 16, 16),
        sidebar = Color3.fromRGB(14, 14, 14),
        section = Color3.fromRGB(16, 16, 16),
        sectionheader = Color3.fromRGB(18, 18, 18),
        outline = Color3.fromRGB(32, 32, 32),
        inline = Color3.fromRGB(45, 45, 45),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(120, 120, 120),
        elementbg = Color3.fromRGB(22, 22, 22),
        success = Color3.fromRGB(80, 200, 120),
        warning = Color3.fromRGB(255, 180, 50),
        error = Color3.fromRGB(240, 80, 80)
    },
    watermark = { enabled = false, objects = {} },
    cursor = { enabled = false, objects = {} }
}

-- Theme Presets
library.themes = {
    Default = {
        accent = Color3.fromRGB(76, 162, 252),
        background = Color3.fromRGB(12, 12, 12),
        topbar = Color3.fromRGB(16, 16, 16),
        outline = Color3.fromRGB(32, 32, 32),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(120, 120, 120),
        elementbg = Color3.fromRGB(22, 22, 22)
    },
    Midnight = {
        accent = Color3.fromRGB(138, 92, 224),
        background = Color3.fromRGB(14, 14, 20),
        topbar = Color3.fromRGB(18, 18, 26),
        outline = Color3.fromRGB(40, 40, 55),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(100, 100, 130),
        elementbg = Color3.fromRGB(24, 24, 34)
    },
    Rose = {
        accent = Color3.fromRGB(226, 80, 130),
        background = Color3.fromRGB(14, 12, 14),
        topbar = Color3.fromRGB(20, 16, 20),
        outline = Color3.fromRGB(45, 38, 45),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(130, 100, 120),
        elementbg = Color3.fromRGB(28, 22, 28)
    },
    Ocean = {
        accent = Color3.fromRGB(60, 180, 220),
        background = Color3.fromRGB(10, 14, 18),
        topbar = Color3.fromRGB(14, 20, 26),
        outline = Color3.fromRGB(30, 42, 52),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(90, 120, 140),
        elementbg = Color3.fromRGB(18, 26, 34)
    },
    Emerald = {
        accent = Color3.fromRGB(80, 200, 120),
        background = Color3.fromRGB(10, 14, 12),
        topbar = Color3.fromRGB(14, 20, 16),
        outline = Color3.fromRGB(32, 48, 40),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(90, 130, 110),
        elementbg = Color3.fromRGB(18, 28, 22)
    }
}

-- Services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Safe Drawing creation
local function create(class, props)
    local success, obj = pcall(function() return Drawing.new(class) end)
    if not success or not obj then
        return { Remove = function() end, Visible = false, Position = Vector2.new(0, 0), Size = Vector2.new(0, 0), Color = Color3.new(1, 1, 1), Text = "" }
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
        if v == obj then table.remove(library.drawings, i) break end
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
    local success, m = pcall(function() return UIS:GetMouseLocation() end)
    if not success then return false end
    return m.X >= x and m.X <= x + w and m.Y >= y and m.Y <= y + h
end

-- Color utilities
local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    s = max == 0 and 0 or d / max
    if max ~= min then
        if max == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, s, v
end

local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function lerp(a, b, t) return a + (b - a) * t end

local function lerpColor(c1, c2, t)
    return Color3.new(lerp(c1.R, c2.R, t), lerp(c1.G, c2.G, t), lerp(c1.B, c2.B, t))
end

--==================================--
--     IMPROVED TOOLTIP SYSTEM      --
--==================================--
local tooltip = {
    objects = {},
    visible = false,
    currentElement = nil,
    hoverStart = 0,
    delay = 2, -- 2 second delay before showing
    lastMousePos = Vector2.new(0, 0)
}

local function createTooltipObjects()
    local t = library.theme

    tooltip.objects.outline = create("Square", {
        Size = Vector2.new(100, 22),
        Position = Vector2.new(0, 0),
        Color = t.outline,
        Filled = true,
        Visible = false,
        ZIndex = 500
    })

    tooltip.objects.bg = create("Square", {
        Size = Vector2.new(98, 20),
        Position = Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        Visible = false,
        ZIndex = 501
    })

    tooltip.objects.accent = create("Square", {
        Size = Vector2.new(2, 16),
        Position = Vector2.new(3, 3),
        Color = library.accent,
        Filled = true,
        Visible = false,
        ZIndex = 502
    })

    tooltip.objects.text = create("Text", {
        Text = "",
        Size = 13,
        Font = 2,
        Color = t.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = Vector2.new(10, 4),
        Visible = false,
        ZIndex = 503
    })
end

function library:ShowTooltip(text, x, y)
    if not tooltip.objects.outline then createTooltipObjects() end

    local width = textBounds(text, 13).X + 20
    pcall(function()
        tooltip.objects.outline.Size = Vector2.new(width, 22)
        tooltip.objects.outline.Position = Vector2.new(x + 15, y - 5)
        tooltip.objects.bg.Size = Vector2.new(width - 2, 20)
        tooltip.objects.bg.Position = Vector2.new(x + 16, y - 4)
        tooltip.objects.accent.Position = Vector2.new(x + 18, y - 1)
        tooltip.objects.text.Text = text
        tooltip.objects.text.Position = Vector2.new(x + 24, y - 1)

        tooltip.objects.outline.Visible = true
        tooltip.objects.bg.Visible = true
        tooltip.objects.accent.Visible = true
        tooltip.objects.text.Visible = true
    end)
    tooltip.visible = true
end

function library:HideTooltip()
    if not tooltip.objects.outline then return end
    pcall(function()
        tooltip.objects.outline.Visible = false
        tooltip.objects.bg.Visible = false
        tooltip.objects.accent.Visible = false
        tooltip.objects.text.Visible = false
    end)
    tooltip.visible = false
    tooltip.currentElement = nil
    tooltip.hoverStart = 0
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

    local initialText = title .. " | 0 fps | 0ms | 00:00:00"
    local width = textBounds(initialText, 13).X + 20

    watermark.objects.outline = create("Square", {
        Size = Vector2.new(width, 24),
        Position = Vector2.new(10, 10),
        Color = t.outline,
        Filled = true,
        Visible = false,
        ZIndex = 100
    })

    watermark.objects.bg = create("Square", {
        Size = Vector2.new(width - 2, 22),
        Position = Vector2.new(11, 11),
        Color = t.background,
        Filled = true,
        Visible = false,
        ZIndex = 101
    })

    watermark.objects.accent = create("Square", {
        Size = Vector2.new(width - 4, 2),
        Position = Vector2.new(12, 12),
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
        Position = Vector2.new(18, 16),
        Visible = false,
        ZIndex = 103
    })

    watermark.title = title

    local lastUpdate = 0
    local fpsBuffer = {}
    table.insert(library.connections, RS.RenderStepped:Connect(function(dt)
        if not watermark.enabled then return end

        table.insert(fpsBuffer, 1/dt)
        if #fpsBuffer > 30 then table.remove(fpsBuffer, 1) end

        local now = tick()
        if now - lastUpdate < 0.5 then return end
        lastUpdate = now

        local avgFps = 0
        for _, v in ipairs(fpsBuffer) do avgFps = avgFps + v end
        avgFps = math.floor(avgFps / #fpsBuffer)

        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local time = os.date("%H:%M:%S")

        local newText = watermark.title .. " | " .. avgFps .. " fps | " .. ping .. "ms | " .. time
        pcall(function()
            watermark.objects.text.Text = newText
            local newWidth = textBounds(newText, 13).X + 20
            watermark.objects.outline.Size = Vector2.new(newWidth, 24)
            watermark.objects.bg.Size = Vector2.new(newWidth - 2, 22)
            watermark.objects.accent.Size = Vector2.new(newWidth - 4, 2)
        end)
    end))

    function watermark:SetEnabled(state)
        watermark.enabled = state
        for _, obj in pairs(watermark.objects) do
            pcall(function() obj.Visible = state end)
        end
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
    local notifType = config.type or "info"

    local t = library.theme
    local typeColors = {
        info = library.accent,
        success = t.success,
        warning = t.warning,
        error = t.error
    }
    local accentColor = typeColors[notifType] or library.accent

    local notification = { objects = {}, startTime = tick() }

    local titleWidth = textBounds(title, 13).X
    local msgWidth = textBounds(message, 13).X
    local width = math.max(titleWidth, msgWidth) + 30
    width = math.max(width, 220)
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
        Size = Vector2.new(3, height - 6),
        Position = Vector2.new(startX + 3, posY + 3),
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
        Position = Vector2.new(startX + 14, posY + 8),
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
            Position = Vector2.new(startX + 14, posY + 26),
            Visible = true,
            ZIndex = 203
        })
    end

    notification.objects.progress = create("Square", {
        Size = Vector2.new(width - 6, 2),
        Position = Vector2.new(startX + 3, posY + height - 5),
        Color = accentColor,
        Filled = true,
        Visible = true,
        ZIndex = 202
    })

    table.insert(library.notifications, notification)

    local currentX = startX
    local slideSpeed = 0.12

    task.spawn(function()
        while currentX > targetX do
            currentX = lerp(currentX, targetX, slideSpeed)
            if math.abs(currentX - targetX) < 1 then currentX = targetX end

            pcall(function()
                notification.objects.outline.Position = Vector2.new(currentX, posY)
                notification.objects.bg.Position = Vector2.new(currentX + 1, posY + 1)
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
            currentX = lerp(currentX, outTarget, slideSpeed)
            if math.abs(currentX - outTarget) < 1 then currentX = outTarget end

            pcall(function()
                notification.objects.outline.Position = Vector2.new(currentX, posY)
                notification.objects.bg.Position = Vector2.new(currentX + 1, posY + 1)
                notification.objects.accent.Position = Vector2.new(currentX + 3, posY + 3)
                notification.objects.title.Position = Vector2.new(currentX + 14, posY + 8)
                if notification.objects.message then
                    notification.objects.message.Position = Vector2.new(currentX + 14, posY + 26)
                end
                notification.objects.progress.Position = Vector2.new(currentX + 3, posY + height - 5)
            end)
            task.wait()
        end

        for _, obj in pairs(notification.objects) do remove(obj) end
        for i, n in pairs(library.notifications) do
            if n == notification then table.remove(library.notifications, i) break end
        end
    end)

    return notification
end

--==================================--
--      KEYBIND INDICATOR LIST      --
--==================================--
function library:CreateKeybindList(config)
    config = config or {}
    local title = config.title or "Active Keybinds"

    local list = {
        objects = {},
        items = {},
        enabled = false,
        position = Vector2.new(10, 50)
    }

    local t = library.theme
    local a = library.accent
    local width = 160

    list.objects.outline = create("Square", {
        Size = Vector2.new(width, 26),
        Position = list.position,
        Color = t.outline,
        Filled = true,
        Visible = false,
        ZIndex = 90
    })

    list.objects.bg = create("Square", {
        Size = Vector2.new(width - 2, 24),
        Position = list.position + Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        Visible = false,
        ZIndex = 91
    })

    list.objects.accent = create("Square", {
        Size = Vector2.new(width - 4, 2),
        Position = list.position + Vector2.new(2, 2),
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
        Position = list.position + Vector2.new(8, 7),
        Visible = false,
        ZIndex = 93
    })

    function list:SetEnabled(state)
        list.enabled = state
        for _, obj in pairs(list.objects) do
            pcall(function() obj.Visible = state end)
        end
    end

    function list:AddKeybind(name, key)
        local item = { name = name, key = key, active = false, objects = {} }

        local yOffset = 26 + (#list.items * 20)

        item.objects.bg = create("Square", {
            Size = Vector2.new(width - 2, 20),
            Position = list.position + Vector2.new(1, yOffset),
            Color = t.elementbg,
            Filled = true,
            Visible = false,
            ZIndex = 91
        })

        item.objects.name = create("Text", {
            Text = name,
            Size = 13,
            Font = 2,
            Color = t.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = list.position + Vector2.new(8, yOffset + 3),
            Visible = false,
            ZIndex = 93
        })

        local keyText = "[" .. key .. "]"
        item.objects.key = create("Text", {
            Text = keyText,
            Size = 13,
            Font = 2,
            Color = a,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Position = list.position + Vector2.new(width - 10 - textBounds(keyText, 13).X, yOffset + 3),
            Visible = false,
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
            list.objects.bg.Size = Vector2.new(width - 2, totalHeight - 2)
        end)

        local yOffset = 26
        for _, item in pairs(list.items) do
            if item.active then
                pcall(function()
                    item.objects.bg.Position = list.position + Vector2.new(1, yOffset)
                    item.objects.name.Position = list.position + Vector2.new(8, yOffset + 3)
                    local keyText = "[" .. item.key .. "]"
                    item.objects.key.Position = list.position + Vector2.new(width - 10 - textBounds(keyText, 13).X, yOffset + 3)
                end)
                yOffset = yOffset + 20
            end
        end
    end

    library.keybindList = list
    return list
end

--==================================--
--          CONFIG SYSTEM           --
--==================================--
function library:SaveConfig(name, folder)
    folder = folder or "NexusLib"
    pcall(function() if not isfolder(folder) then makefolder(folder) end end)

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

    pcall(function() writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
    library:Notify({title = "Config Saved", message = name, type = "success", duration = 3})
end

function library:LoadConfig(name, folder)
    folder = folder or "NexusLib"
    local path = folder .. "/" .. name .. ".json"

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not success then
        library:Notify({title = "Config Error", message = "Failed to load: " .. name, type = "error", duration = 3})
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

    library:Notify({title = "Config Loaded", message = name, type = "success", duration = 3})
end

--==================================--
--         MAIN LIBRARY             --
--==================================--
function library:New(config)
    config = config or {}
    local name = config.name or "NexusLib"
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
        tooltipElements = {} -- Track elements with tooltips
    }

    local t = library.theme
    local a = library.accent

    -- Main outline with slight glow effect
    window.objects.outerGlow = create("Square", {
        Size = Vector2.new(sizeX + 2, sizeY + 2),
        Position = window.pos - Vector2.new(1, 1),
        Color = a,
        Transparency = 0.1,
        Filled = true,
        ZIndex = 0,
        Visible = true
    })

    window.objects.outline = create("Square", {
        Size = window.size,
        Position = window.pos,
        Color = t.outline,
        Filled = true,
        ZIndex = 1,
        Visible = true
    })

    window.objects.bg = create("Square", {
        Size = Vector2.new(sizeX - 2, sizeY - 2),
        Position = window.pos + Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        ZIndex = 2,
        Visible = true
    })

    -- Top bar with gradient-like effect
    window.objects.topbar = create("Square", {
        Size = Vector2.new(sizeX - 4, 24),
        Position = window.pos + Vector2.new(2, 2),
        Color = t.topbar,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })

    -- Accent line (thicker, more visible)
    window.objects.accentLine = create("Square", {
        Size = Vector2.new(sizeX - 4, 2),
        Position = window.pos + Vector2.new(2, 26),
        Color = a,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })

    -- Title with accent color
    window.objects.title = create("Text", {
        Text = name,
        Size = 14,
        Font = 2,
        Color = a,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(10, 6),
        Visible = true,
        ZIndex = 5
    })

    -- Content area
    window.objects.contentOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, sizeY - 54),
        Position = window.pos + Vector2.new(2, 28),
        Color = t.outline,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })

    window.objects.content = create("Square", {
        Size = Vector2.new(sizeX - 6, sizeY - 56),
        Position = window.pos + Vector2.new(3, 29),
        Color = t.section,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })

    -- Sidebar
    window.objects.sidebarOutline = create("Square", {
        Size = Vector2.new(118, sizeY - 58),
        Position = window.pos + Vector2.new(4, 30),
        Color = t.outline,
        Filled = true,
        ZIndex = 5,
        Visible = true
    })

    window.objects.sidebar = create("Square", {
        Size = Vector2.new(116, sizeY - 60),
        Position = window.pos + Vector2.new(5, 31),
        Color = t.sidebar,
        Filled = true,
        ZIndex = 6,
        Visible = true
    })

    -- Bottom bar
    window.objects.bottomOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, 24),
        Position = window.pos + Vector2.new(2, sizeY - 26),
        Color = t.outline,
        Filled = true,
        ZIndex = 3,
        Visible = true
    })

    window.objects.bottombar = create("Square", {
        Size = Vector2.new(sizeX - 6, 22),
        Position = window.pos + Vector2.new(3, sizeY - 25),
        Color = t.topbar,
        Filled = true,
        ZIndex = 4,
        Visible = true
    })

    window.objects.version = create("Text", {
        Text = "v4.1",
        Size = 13,
        Font = 2,
        Color = t.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(10, sizeY - 21),
        Visible = true,
        ZIndex = 5
    })

    window.objects.fpsText = create("Text", {
        Text = "0 fps",
        Size = 13,
        Font = 2,
        Color = t.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX - 55, sizeY - 21),
        Visible = true,
        ZIndex = 5
    })

    -- Toggle hint
    window.objects.toggleHint = create("Text", {
        Text = "[RShift] to toggle",
        Size = 13,
        Font = 2,
        Color = t.dimtext,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.pos + Vector2.new(sizeX / 2 - 50, sizeY - 21),
        Visible = true,
        ZIndex = 5
    })

    local tabStartX = textBounds(name, 14).X + 22
    window.tabStartX = tabStartX

    -- FPS counter
    local fpsBuffer = {}
    table.insert(library.connections, RS.RenderStepped:Connect(function(dt)
        if not library.open then return end
        table.insert(fpsBuffer, 1/dt)
        if #fpsBuffer > 20 then table.remove(fpsBuffer, 1) end

        local avg = 0
        for _, v in ipairs(fpsBuffer) do avg = avg + v end
        avg = math.floor(avg / #fpsBuffer)
        pcall(function() window.objects.fpsText.Text = avg .. " fps" end)
    end))

    function window:UpdatePositions()
        local p = window.pos
        local o = window.objects
        pcall(function() o.outerGlow.Position = p - Vector2.new(1, 1) end)
        pcall(function() o.outline.Position = p end)
        pcall(function() o.bg.Position = p + Vector2.new(1, 1) end)
        pcall(function() o.topbar.Position = p + Vector2.new(2, 2) end)
        pcall(function() o.accentLine.Position = p + Vector2.new(2, 26) end)
        pcall(function() o.title.Position = p + Vector2.new(10, 6) end)
        pcall(function() o.contentOutline.Position = p + Vector2.new(2, 28) end)
        pcall(function() o.content.Position = p + Vector2.new(3, 29) end)
        pcall(function() o.sidebarOutline.Position = p + Vector2.new(4, 30) end)
        pcall(function() o.sidebar.Position = p + Vector2.new(5, 31) end)
        pcall(function() o.bottomOutline.Position = p + Vector2.new(2, sizeY - 26) end)
        pcall(function() o.bottombar.Position = p + Vector2.new(3, sizeY - 25) end)
        pcall(function() o.version.Position = p + Vector2.new(10, sizeY - 21) end)
        pcall(function() o.fpsText.Position = p + Vector2.new(sizeX - 55, sizeY - 21) end)
        pcall(function() o.toggleHint.Position = p + Vector2.new(sizeX / 2 - 50, sizeY - 21) end)
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
        if not state then library:HideTooltip() end
    end

    function window:Toggle()
        window:SetVisible(not library.open)
    end

    -- Tooltip hover checking with delay
    table.insert(library.connections, RS.RenderStepped:Connect(function()
        if not library.open then
            library:HideTooltip()
            return
        end

        local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
        if not success then return end

        local foundHover = false

        for _, elemData in pairs(window.tooltipElements) do
            local elem = elemData.element
            local tooltipText = elemData.tooltip
            local getHoverArea = elemData.getHoverArea

            if elem and tooltipText and getHoverArea then
                local area = getHoverArea()
                if area and mouseOver(area.x, area.y, area.w, area.h) then
                    foundHover = true

                    if tooltip.currentElement ~= elem then
                        tooltip.currentElement = elem
                        tooltip.hoverStart = tick()
                        library:HideTooltip()
                    elseif tick() - tooltip.hoverStart >= tooltip.delay then
                        library:ShowTooltip(tooltipText, mouse.X, mouse.Y)
                    end
                    break
                end
            end
        end

        if not foundHover then
            library:HideTooltip()
        end
    end))

    -- Page function
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
            tabX = tabX + textBounds(p.name, 13).X + 18
        end

        local tabWidth = textBounds(pageName, 13).X + 14

        page.objects.tabBg = create("Square", {
            Size = Vector2.new(tabWidth, 21),
            Position = window.pos + Vector2.new(tabX, 4),
            Color = t.section,
            Filled = true,
            Visible = false,
            ZIndex = 4
        })

        page.objects.tabAccent = create("Square", {
            Size = Vector2.new(tabWidth - 4, 2),
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
            Position = window.pos + Vector2.new(tabX + 7, 8),
            Visible = true,
            ZIndex = 6
        })

        page.tabX = tabX
        page.tabWidth = tabWidth

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

        -- Section function
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
            local sectionBtn = { yOffset = btnY, objects = {} }

            sectionBtn.objects.accent = create("Square", {
                Size = Vector2.new(2, 18),
                Position = window.pos + Vector2.new(7, 32 + btnY),
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
                Position = window.pos + Vector2.new(16, 34 + btnY),
                Visible = page.visible,
                ZIndex = 7
            })

            function sectionBtn:UpdatePositions()
                local p = window.pos
                pcall(function() sectionBtn.objects.accent.Position = p + Vector2.new(7, 32 + sectionBtn.yOffset) end)
                pcall(function() sectionBtn.objects.text.Position = p + Vector2.new(16, 34 + sectionBtn.yOffset) end)
            end

            function sectionBtn:SetVisible(state)
                pcall(function() sectionBtn.objects.accent.Visible = state and section == page.currentSection end)
                pcall(function() sectionBtn.objects.text.Visible = state end)
                pcall(function() sectionBtn.objects.text.Color = (section == page.currentSection) and Color3.new(1, 1, 1) or t.dimtext end)
            end

            table.insert(page.sectionButtons, sectionBtn)
            section.button = sectionBtn

            local contentX = 126
            local contentWidth = (sizeX - 136) / 2 - 6
            local contentY = 32
            local rightX = contentX + contentWidth + 8
            local contentHeight = sizeY - 90

            -- Left column
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
                Size = Vector2.new(contentWidth, 22),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = t.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })

            section.objects.leftHeaderAccent = create("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 23),
                Color = a,
                Transparency = 0.5,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })

            section.objects.leftTitle = create("Text", {
                Text = leftTitle:upper(),
                Size = 12,
                Font = 2,
                Color = t.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(contentX + 10, contentY + 6),
                Visible = false,
                ZIndex = 8
            })

            -- Right column
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
                Size = Vector2.new(contentWidth, 22),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = t.sectionheader,
                Filled = true,
                Visible = false,
                ZIndex = 7
            })

            section.objects.rightHeaderAccent = create("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 23),
                Color = a,
                Transparency = 0.5,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })

            section.objects.rightTitle = create("Text", {
                Text = rightTitle:upper(),
                Size = 12,
                Font = 2,
                Color = t.dimtext,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.pos + Vector2.new(rightX + 10, contentY + 6),
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
                local cX, rX, cY = section.contentX, section.rightX, section.contentY
                pcall(function() section.objects.leftOutline.Position = p + Vector2.new(cX, cY) end)
                pcall(function() section.objects.left.Position = p + Vector2.new(cX + 1, cY + 1) end)
                pcall(function() section.objects.leftHeader.Position = p + Vector2.new(cX + 1, cY + 1) end)
                pcall(function() section.objects.leftHeaderAccent.Position = p + Vector2.new(cX + 1, cY + 23) end)
                pcall(function() section.objects.leftTitle.Position = p + Vector2.new(cX + 10, cY + 6) end)
                pcall(function() section.objects.rightOutline.Position = p + Vector2.new(rX, cY) end)
                pcall(function() section.objects.right.Position = p + Vector2.new(rX + 1, cY + 1) end)
                pcall(function() section.objects.rightHeader.Position = p + Vector2.new(rX + 1, cY + 1) end)
                pcall(function() section.objects.rightHeaderAccent.Position = p + Vector2.new(rX + 1, cY + 23) end)
                pcall(function() section.objects.rightTitle.Position = p + Vector2.new(rX + 10, cY + 6) end)
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

            --=============== TOGGLE ===============--
            function section:Toggle(config)
                config = config or {}
                local toggleName = config.name or "Toggle"
                local side = (config.side or "left"):lower()
                local default = config.default or false
                local flag = config.flag
                local tooltipText = config.tooltip
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

                toggle.objects.box = create("Square", {
                    Size = Vector2.new(10, 10),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                toggle.objects.fill = create("Square", {
                    Size = Vector2.new(8, 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 3),
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
                        if mouseOver(pos.X - 2, pos.Y - 2, toggle.width, 16) then
                            toggle:Set(not toggle.value)
                        end
                    end
                end))

                -- Register for tooltip
                if tooltipText then
                    table.insert(window.tooltipElements, {
                        element = toggle,
                        tooltip = tooltipText,
                        getHoverArea = function()
                            local pos = toggle.objects.box.Position
                            return section.visible and { x = pos.X - 2, y = pos.Y - 2, w = toggle.width, h = 16 } or nil
                        end
                    })
                end

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = toggle
                end

                if default then pcall(callback, default) end

                if side == "left" then section.leftOffset = section.leftOffset + 20
                else section.rightOffset = section.rightOffset + 20 end

                table.insert(elements, toggle)
                return toggle
            end

            --=============== SLIDER ===============--
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
                local tooltipText = config.tooltip
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
                    Color = a,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + sliderWidth - textBounds(valText, 13).X, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                slider.objects.trackOutline = create("Square", {
                    Size = Vector2.new(sliderWidth, 12),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                slider.objects.track = create("Square", {
                    Size = Vector2.new(sliderWidth - 2, 10),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                local pct = (default - min) / (max - min)
                slider.objects.fill = create("Square", {
                    Size = Vector2.new(math.max((sliderWidth - 2) * pct, 0), 10),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
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
                    pcall(function() slider.objects.trackOutline.Position = p + Vector2.new(slider.baseX, slider.baseY + 18) end)
                    pcall(function() slider.objects.track.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 19) end)
                    pcall(function() slider.objects.fill.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 19) end)
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
                    pcall(function() slider.objects.fill.Size = Vector2.new(math.max((slider.width - 2) * pct, 0), 10) end)
                    local valText = tostring(value) .. slider.suffix
                    pcall(function() slider.objects.value.Text = valText end)
                    pcall(function() slider.objects.value.Position = window.pos + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, slider.baseY) end)
                    if flag then library.flags[flag] = value end
                    if not nocallback then pcall(callback, value) end
                end

                function slider:Get() return slider.value end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = slider.objects.trackOutline.Position
                        if mouseOver(pos.X, pos.Y, slider.width, 12) then
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

                if tooltipText then
                    table.insert(window.tooltipElements, {
                        element = slider,
                        tooltip = tooltipText,
                        getHoverArea = function()
                            local pos = slider.objects.label.Position
                            return section.visible and { x = pos.X, y = pos.Y, w = slider.width, h = 34 } or nil
                        end
                    })
                end

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = slider
                end

                if side == "left" then section.leftOffset = section.leftOffset + 36
                else section.rightOffset = section.rightOffset + 36 end

                table.insert(elements, slider)
                return slider
            end

            --=============== BUTTON ===============--
            function section:Button(config)
                config = config or {}
                local buttonName = config.name or "Button"
                local side = (config.side or "left"):lower()
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local btnWidth = section.contentWidth - 24

                local button = { side = side, yOffset = offset, objects = {} }

                button.objects.outline = create("Square", {
                    Size = Vector2.new(btnWidth, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                button.objects.bg = create("Square", {
                    Size = Vector2.new(btnWidth - 2, 20),
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
                    Position = window.pos + Vector2.new(baseX + btnWidth/2, section.contentY + offset + 4),
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
                    pcall(function() button.objects.label.Position = p + Vector2.new(button.baseX + button.width/2, button.baseY + 4) end)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = button.objects.outline.Position
                        if mouseOver(pos.X, pos.Y, button.width, 22) then
                            pcall(function() button.objects.bg.Color = a end)
                            pcall(function() button.objects.label.Color = t.text end)
                            pcall(callback)
                            task.delay(0.15, function()
                                pcall(function() button.objects.bg.Color = t.elementbg end)
                                pcall(function() button.objects.label.Color = t.dimtext end)
                            end)
                        end
                    end
                end))

                if side == "left" then section.leftOffset = section.leftOffset + 28
                else section.rightOffset = section.rightOffset + 28 end

                table.insert(elements, button)
                return button
            end

            --=============== DROPDOWN ===============--
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
                    Size = Vector2.new(ddWidth, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                dropdown.objects.bg = create("Square", {
                    Size = Vector2.new(ddWidth - 2, 20),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                local displayText = multi and (#dropdown.value > 0 and table.concat(dropdown.value, ", ") or "None") or default
                dropdown.objects.selected = create("Text", {
                    Text = displayText,
                    Size = 13,
                    Font = 2,
                    Color = t.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 8, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 11
                })

                dropdown.objects.arrow = create("Text", {
                    Text = "v",
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + ddWidth - 14, section.contentY + offset + 22),
                    Visible = section.visible,
                    ZIndex = 11
                })

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
                    for _, obj in pairs(dropdown.itemObjects) do
                        pcall(function() obj:Remove() end)
                    end
                    dropdown.itemObjects = {}
                end

                function dropdown:Open()
                    if dropdown.open then dropdown:Close() return end
                    dropdown.open = true
                    window.activeDropdown = dropdown

                    local pos = dropdown.objects.outline.Position
                    local listH = math.min(#items * 20 + 4, 164)

                    local listBg = create("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 24),
                        Color = t.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(dropdown.itemObjects, listBg)

                    local listOutline = create("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 24),
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
                            Position = Vector2.new(pos.X + 8, pos.Y + 28 + (i-1) * 20),
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

                function dropdown:Refresh(newItems)
                    dropdown.items = newItems
                    items = newItems
                    if dropdown.open then
                        dropdown:Close()
                        dropdown:Open()
                    end
                end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = dropdown.objects.outline.Position

                        if mouseOver(pos.X, pos.Y, dropdown.width, 22) then
                            dropdown:Open()
                            return
                        end

                        if dropdown.open then
                            for i, item in ipairs(items) do
                                local itemY = pos.Y + 24 + (i-1) * 20
                                if mouseOver(pos.X, itemY, dropdown.width, 20) then
                                    if multi then
                                        local idx = table.find(dropdown.value, item)
                                        if idx then table.remove(dropdown.value, idx)
                                        else table.insert(dropdown.value, item) end
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
                            dropdown:Close()
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = multi and {} or default
                    library.pointers[flag] = dropdown
                end

                if not multi and default ~= "" then pcall(callback, default) end

                if side == "left" then section.leftOffset = section.leftOffset + 46
                else section.rightOffset = section.rightOffset + 46 end

                table.insert(elements, dropdown)
                return dropdown
            end

            --=============== KEYBIND ===============--
            function section:Keybind(config)
                config = config or {}
                local keybindName = config.name or "Keybind"
                local side = (config.side or "left"):lower()
                local default = config.default or Enum.KeyCode.Unknown
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local kbWidth = section.contentWidth - 24

                local keyNames = {
                    [Enum.KeyCode.LeftShift] = "LSHIFT", [Enum.KeyCode.RightShift] = "RSHIFT",
                    [Enum.KeyCode.LeftControl] = "LCTRL", [Enum.KeyCode.RightControl] = "RCTRL",
                    [Enum.KeyCode.LeftAlt] = "LALT", [Enum.KeyCode.RightAlt] = "RALT",
                    [Enum.UserInputType.MouseButton1] = "M1", [Enum.UserInputType.MouseButton2] = "M2"
                }

                local function getKeyName(key)
                    if keyNames[key] then return keyNames[key] end
                    if typeof(key) == "EnumItem" then return key.Name:upper() end
                    return "NONE"
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
                    Color = a,
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
                        pcall(function() keybind.objects.key.Color = a end)
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = keybind.objects.label.Position
                        if mouseOver(pos.X, pos.Y - 2, keybind.width, 18) then
                            keybind.listening = true
                            pcall(function() keybind.objects.key.Text = "[...]" end)
                            pcall(function() keybind.objects.key.Color = t.warning end)
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

                if side == "left" then section.leftOffset = section.leftOffset + 22
                else section.rightOffset = section.rightOffset + 22 end

                table.insert(elements, keybind)
                return keybind
            end

            --=============== COLORPICKER ===============--
            function section:ColorPicker(config)
                config = config or {}
                local pickerName = config.name or "Color"
                local side = (config.side or "left"):lower()
                local default = config.default or Color3.fromRGB(255, 255, 255)
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)
                local cpWidth = section.contentWidth - 24

                local h, s, v = rgbToHsv(default.R * 255, default.G * 255, default.B * 255)

                local colorpicker = {
                    value = default,
                    h = h, s = s, v = v,
                    open = false,
                    draggingSV = false,
                    draggingH = false,
                    side = side,
                    yOffset = offset,
                    objects = {},
                    pickerObjects = {}
                }

                colorpicker.objects.label = create("Text", {
                    Text = pickerName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 2),
                    Visible = section.visible,
                    ZIndex = 9
                })

                colorpicker.objects.preview = create("Square", {
                    Size = Vector2.new(24, 14),
                    Position = window.pos + Vector2.new(baseX + cpWidth - 26, section.contentY + offset + 1),
                    Color = default,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                colorpicker.objects.previewOutline = create("Square", {
                    Size = Vector2.new(24, 14),
                    Position = window.pos + Vector2.new(baseX + cpWidth - 26, section.contentY + offset + 1),
                    Color = t.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 10
                })

                colorpicker.baseX = baseX
                colorpicker.baseY = section.contentY + offset
                colorpicker.width = cpWidth

                function colorpicker:UpdatePositions()
                    local p = window.pos
                    pcall(function() colorpicker.objects.label.Position = p + Vector2.new(colorpicker.baseX, colorpicker.baseY + 2) end)
                    pcall(function() colorpicker.objects.preview.Position = p + Vector2.new(colorpicker.baseX + colorpicker.width - 26, colorpicker.baseY + 1) end)
                    pcall(function() colorpicker.objects.previewOutline.Position = p + Vector2.new(colorpicker.baseX + colorpicker.width - 26, colorpicker.baseY + 1) end)
                end

                function colorpicker:SetVisible(state)
                    for _, obj in pairs(colorpicker.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                    if not state then colorpicker:Close() end
                end

                function colorpicker:Close()
                    colorpicker.open = false
                    colorpicker.draggingSV = false
                    colorpicker.draggingH = false
                    for _, obj in pairs(colorpicker.pickerObjects) do
                        pcall(function() obj:Remove() end)
                    end
                    colorpicker.pickerObjects = {}
                end

                function colorpicker:Open()
                    if colorpicker.open then colorpicker:Close() return end
                    colorpicker.open = true

                    local pos = colorpicker.objects.preview.Position
                    local pickerW, pickerH = 180, 160

                    local bg = create("Square", {
                        Size = Vector2.new(pickerW, pickerH),
                        Position = Vector2.new(pos.X - pickerW + 24, pos.Y + 18),
                        Color = t.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 60
                    })
                    table.insert(colorpicker.pickerObjects, bg)

                    local outline = create("Square", {
                        Size = Vector2.new(pickerW, pickerH),
                        Position = Vector2.new(pos.X - pickerW + 24, pos.Y + 18),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 61
                    })
                    table.insert(colorpicker.pickerObjects, outline)

                    local svX = pos.X - pickerW + 32
                    local svY = pos.Y + 26
                    local svSize = 120

                    local svWhite = create("Square", {
                        Size = Vector2.new(svSize, svSize),
                        Position = Vector2.new(svX, svY),
                        Color = Color3.new(1, 1, 1),
                        Filled = true,
                        Visible = true,
                        ZIndex = 62
                    })
                    table.insert(colorpicker.pickerObjects, svWhite)

                    local r, g, b = hsvToRgb(colorpicker.h, 1, 1)
                    local svHue = create("Square", {
                        Size = Vector2.new(svSize, svSize),
                        Position = Vector2.new(svX, svY),
                        Color = Color3.fromRGB(r, g, b),
                        Filled = true,
                        Transparency = 0.5,
                        Visible = true,
                        ZIndex = 63
                    })
                    table.insert(colorpicker.pickerObjects, svHue)
                    colorpicker.svHue = svHue

                    local svOutline = create("Square", {
                        Size = Vector2.new(svSize, svSize),
                        Position = Vector2.new(svX, svY),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 64
                    })
                    table.insert(colorpicker.pickerObjects, svOutline)

                    local svCursorX = svX + colorpicker.s * svSize - 4
                    local svCursorY = svY + (1 - colorpicker.v) * svSize - 4
                    local svCursor = create("Circle", {
                        Radius = 5,
                        Position = Vector2.new(svCursorX + 4, svCursorY + 4),
                        Color = Color3.new(1, 1, 1),
                        Filled = false,
                        Thickness = 2,
                        Visible = true,
                        ZIndex = 65
                    })
                    table.insert(colorpicker.pickerObjects, svCursor)
                    colorpicker.svCursor = svCursor

                    local hueX = svX + svSize + 10
                    local hueY = svY
                    local hueW, hueH = 20, svSize

                    for i = 0, 11 do
                        local hueVal = i / 12
                        local hr, hg, hb = hsvToRgb(hueVal, 1, 1)
                        local hueStep = create("Square", {
                            Size = Vector2.new(hueW, hueH / 12 + 1),
                            Position = Vector2.new(hueX, hueY + i * (hueH / 12)),
                            Color = Color3.fromRGB(hr, hg, hb),
                            Filled = true,
                            Visible = true,
                            ZIndex = 62
                        })
                        table.insert(colorpicker.pickerObjects, hueStep)
                    end

                    local hueOutline = create("Square", {
                        Size = Vector2.new(hueW, hueH),
                        Position = Vector2.new(hueX, hueY),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 64
                    })
                    table.insert(colorpicker.pickerObjects, hueOutline)

                    local hueCursorY = hueY + colorpicker.h * hueH - 2
                    local hueCursor = create("Square", {
                        Size = Vector2.new(hueW, 4),
                        Position = Vector2.new(hueX, hueCursorY),
                        Color = Color3.new(1, 1, 1),
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 65
                    })
                    table.insert(colorpicker.pickerObjects, hueCursor)
                    colorpicker.hueCursor = hueCursor

                    colorpicker.svX = svX
                    colorpicker.svY = svY
                    colorpicker.svSize = svSize
                    colorpicker.hueX = hueX
                    colorpicker.hueY = hueY
                    colorpicker.hueW = hueW
                    colorpicker.hueH = hueH
                end

                function colorpicker:UpdateColor()
                    local r, g, b = hsvToRgb(colorpicker.h, colorpicker.s, colorpicker.v)
                    colorpicker.value = Color3.fromRGB(r, g, b)
                    pcall(function() colorpicker.objects.preview.Color = colorpicker.value end)
                    if colorpicker.svHue then
                        local hr, hg, hb = hsvToRgb(colorpicker.h, 1, 1)
                        pcall(function() colorpicker.svHue.Color = Color3.fromRGB(hr, hg, hb) end)
                    end
                    if flag then library.flags[flag] = colorpicker.value end
                    pcall(callback, colorpicker.value)
                end

                function colorpicker:Set(color)
                    colorpicker.value = color
                    colorpicker.h, colorpicker.s, colorpicker.v = rgbToHsv(color.R * 255, color.G * 255, color.B * 255)
                    pcall(function() colorpicker.objects.preview.Color = color end)
                    if flag then library.flags[flag] = color end
                    pcall(callback, color)
                end

                function colorpicker:Get() return colorpicker.value end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local previewPos = colorpicker.objects.preview.Position
                        if mouseOver(previewPos.X, previewPos.Y, 24, 14) then
                            colorpicker:Open()
                            return
                        end

                        if colorpicker.open then
                            if mouseOver(colorpicker.svX, colorpicker.svY, colorpicker.svSize, colorpicker.svSize) then
                                colorpicker.draggingSV = true
                                return
                            end
                            if mouseOver(colorpicker.hueX, colorpicker.hueY, colorpicker.hueW, colorpicker.hueH) then
                                colorpicker.draggingH = true
                                return
                            end
                            local bgPos = colorpicker.pickerObjects[1] and colorpicker.pickerObjects[1].Position
                            if bgPos and not mouseOver(bgPos.X, bgPos.Y, 180, 160) then
                                colorpicker:Close()
                            end
                        end
                    end
                end))

                table.insert(library.connections, UIS.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        colorpicker.draggingSV = false
                        colorpicker.draggingH = false
                    end
                end))

                table.insert(library.connections, RS.RenderStepped:Connect(function()
                    if colorpicker.open and library.open then
                        local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
                        if success then
                            if colorpicker.draggingSV then
                                local relX = math.clamp((mouse.X - colorpicker.svX) / colorpicker.svSize, 0, 1)
                                local relY = math.clamp((mouse.Y - colorpicker.svY) / colorpicker.svSize, 0, 1)
                                colorpicker.s = relX
                                colorpicker.v = 1 - relY
                                if colorpicker.svCursor then
                                    pcall(function() colorpicker.svCursor.Position = Vector2.new(colorpicker.svX + relX * colorpicker.svSize, colorpicker.svY + relY * colorpicker.svSize) end)
                                end
                                colorpicker:UpdateColor()
                            end
                            if colorpicker.draggingH then
                                local relY = math.clamp((mouse.Y - colorpicker.hueY) / colorpicker.hueH, 0, 1)
                                colorpicker.h = relY
                                if colorpicker.hueCursor then
                                    pcall(function() colorpicker.hueCursor.Position = Vector2.new(colorpicker.hueX, colorpicker.hueY + relY * colorpicker.hueH - 2) end)
                                end
                                colorpicker:UpdateColor()
                            end
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = colorpicker
                end

                pcall(callback, default)

                if side == "left" then section.leftOffset = section.leftOffset + 22
                else section.rightOffset = section.rightOffset + 22 end

                table.insert(elements, colorpicker)
                return colorpicker
            end

            --=============== TEXTBOX ===============--
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

                textbox.objects.label = create("Text", {
                    Text = textboxName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Visible = section.visible,
                    ZIndex = 9
                })

                textbox.objects.outline = create("Square", {
                    Size = Vector2.new(tbWidth, 22),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 18),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                textbox.objects.bg = create("Square", {
                    Size = Vector2.new(tbWidth - 2, 20),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 19),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 10
                })

                textbox.objects.text = create("Text", {
                    Text = default ~= "" and default or placeholder,
                    Size = 13,
                    Font = 2,
                    Color = default ~= "" and t.text or t.dimtext,
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

                function textbox:Set(value)
                    textbox.value = value
                    pcall(function() textbox.objects.text.Text = value ~= "" and value or textbox.placeholder end)
                    pcall(function() textbox.objects.text.Color = value ~= "" and t.text or t.dimtext end)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function textbox:Get() return textbox.value end

                function textbox:Focus()
                    textbox.focused = true
                    pcall(function() textbox.objects.outline.Color = a end)
                    pcall(function() textbox.objects.text.Text = textbox.value end)
                    pcall(function() textbox.objects.text.Color = t.text end)
                end

                function textbox:Unfocus()
                    textbox.focused = false
                    pcall(function() textbox.objects.outline.Color = t.outline end)
                    if textbox.value == "" then
                        pcall(function() textbox.objects.text.Text = textbox.placeholder end)
                        pcall(function() textbox.objects.text.Color = t.dimtext end)
                    end
                    pcall(callback, textbox.value)
                end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = textbox.objects.outline.Position
                        if mouseOver(pos.X, pos.Y, textbox.width, 22) then
                            textbox:Focus()
                            return
                        end
                        if textbox.focused then textbox:Unfocus() end
                    end

                    if textbox.focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Escape then
                            textbox:Unfocus()
                        elseif input.KeyCode == Enum.KeyCode.Backspace then
                            textbox.value = textbox.value:sub(1, -2)
                            pcall(function() textbox.objects.text.Text = textbox.value end)
                        elseif input.KeyCode == Enum.KeyCode.Space then
                            textbox.value = textbox.value .. " "
                            pcall(function() textbox.objects.text.Text = textbox.value end)
                        elseif #input.KeyCode.Name == 1 then
                            local char = input.KeyCode.Name
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                char = char:upper()
                            else
                                char = char:lower()
                            end
                            textbox.value = textbox.value .. char
                            pcall(function() textbox.objects.text.Text = textbox.value end)
                        end
                        if flag then library.flags[flag] = textbox.value end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = textbox
                end

                if side == "left" then section.leftOffset = section.leftOffset + 46
                else section.rightOffset = section.rightOffset + 46 end

                table.insert(elements, textbox)
                return textbox
            end

            --=============== LABEL ===============--
            function section:Label(config)
                config = config or {}
                local labelText = config.text or "Label"
                local side = (config.side or "left"):lower()

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 12) or (section.rightX + 12)

                local label = { side = side, yOffset = offset, objects = {} }

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

                if side == "left" then section.leftOffset = section.leftOffset + 20
                else section.rightOffset = section.rightOffset + 20 end

                table.insert(elements, label)
                return label
            end

            -- Section button click
            table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and page.visible then
                    local pos = sectionBtn.objects.text.Position
                    if mouseOver(pos.X - 10, pos.Y - 4, 110, 22) then
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

    -- Dragging & Tab clicks & Toggle
    table.insert(library.connections, UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
            local pos = window.pos
            if mouseOver(pos.X, pos.Y, sizeX, 28) then
                window.dragging = true
                local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
                if success then window.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y) end
            end

            for _, page in pairs(window.pages) do
                local tabPos = page.objects.tabText.Position
                if mouseOver(tabPos.X - 7, tabPos.Y - 4, page.tabWidth, 22) then
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
    end))

    function window:Init()
        if window.pages[1] then window.pages[1]:Show() end
        library:CreateWatermark({title = name})
        library:CreateKeybindList({title = "Active Keybinds"})
    end

    function window:Unload()
        for _, conn in pairs(library.connections) do pcall(function() conn:Disconnect() end) end
        for _, obj in pairs(library.drawings) do pcall(function() obj:Remove() end) end
        library.drawings = {}
        library.connections = {}
    end

    return window
end

return library
