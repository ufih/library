--[[

NexusLib v3.2 - Enhanced Drawing UI Library

Added:
- TextBox/Input element
- ColorPicker element
- Multi-dropdown element
- Section scrolling support

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
        elementbg = Color3.fromRGB(20, 20, 20)
    }
}

-- Services (with pcall protection)
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")

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
    local h, s, v
    v = max
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

-- Main library
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
        activeColorPicker = nil
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

    window.objects.version = create("Text", {
        Text = "version: live",
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

    -- Page
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

        -- Section
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

            local contentX = 120
            local contentWidth = (sizeX - 130) / 2 - 8
            local contentY = 30
            local rightX = contentX + contentWidth + 10
            local contentHeight = sizeY - 84

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

            -- Left scrollbar
            section.objects.leftScrollBg = create("Square", {
                Size = Vector2.new(4, contentHeight - 24),
                Position = window.pos + Vector2.new(contentX + contentWidth - 5, contentY + 22),
                Color = t.elementbg,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })

            section.objects.leftScrollBar = create("Square", {
                Size = Vector2.new(4, 30),
                Position = window.pos + Vector2.new(contentX + contentWidth - 5, contentY + 22),
                Color = a,
                Filled = true,
                Visible = false,
                ZIndex = 9
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

            -- Right scrollbar
            section.objects.rightScrollBg = create("Square", {
                Size = Vector2.new(4, contentHeight - 24),
                Position = window.pos + Vector2.new(rightX + contentWidth - 5, contentY + 22),
                Color = t.elementbg,
                Filled = true,
                Visible = false,
                ZIndex = 8
            })

            section.objects.rightScrollBar = create("Square", {
                Size = Vector2.new(4, 30),
                Position = window.pos + Vector2.new(rightX + contentWidth - 5, contentY + 22),
                Color = a,
                Filled = true,
                Visible = false,
                ZIndex = 9
            })

            section.contentX = contentX
            section.rightX = rightX
            section.contentY = contentY
            section.contentWidth = contentWidth
            section.contentHeight = contentHeight

            -- Scrolling functions
            function section:UpdateScroll(side)
                local elements = side == "left" and section.leftElements or section.rightElements
                local scroll = side == "left" and section.leftScroll or section.rightScroll
                local scrollBar = side == "left" and section.objects.leftScrollBar or section.objects.rightScrollBar
                local scrollBg = side == "left" and section.objects.leftScrollBg or section.objects.rightScrollBg
                local totalOffset = side == "left" and section.leftOffset or section.rightOffset
                local viewHeight = section.contentHeight - 26
                local maxScroll = math.max(0, totalOffset - viewHeight)

                if side == "left" then
                    section.leftMaxScroll = maxScroll
                else
                    section.rightMaxScroll = maxScroll
                end

                -- Update scrollbar visibility and size
                local showScroll = maxScroll > 0
                pcall(function() scrollBg.Visible = section.visible and showScroll end)
                pcall(function() scrollBar.Visible = section.visible and showScroll end)

                if showScroll then
                    local barHeight = math.max(20, (viewHeight / totalOffset) * (section.contentHeight - 24))
                    local barY = (scroll / maxScroll) * (section.contentHeight - 24 - barHeight)
                    pcall(function() scrollBar.Size = Vector2.new(4, barHeight) end)
                    local baseX = side == "left" and section.contentX or section.rightX
                    pcall(function() scrollBar.Position = window.pos + Vector2.new(baseX + section.contentWidth - 5, section.contentY + 22 + barY) end)
                end

                -- Update element positions based on scroll
                for _, elem in pairs(elements) do
                    if elem.UpdateScroll then elem:UpdateScroll(scroll) end
                end
            end

            function section:Scroll(side, delta)
                local maxScroll = side == "left" and section.leftMaxScroll or section.rightMaxScroll
                if side == "left" then
                    section.leftScroll = math.clamp(section.leftScroll + delta, 0, maxScroll)
                else
                    section.rightScroll = math.clamp(section.rightScroll + delta, 0, maxScroll)
                end
                section:UpdateScroll(side)
            end

            -- Mouse wheel scrolling
            table.insert(library.connections, UIS.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel and library.open and section.visible then
                    local leftPos = window.pos + Vector2.new(section.contentX, section.contentY)
                    local rightPos = window.pos + Vector2.new(section.rightX, section.contentY)

                    if mouseOver(leftPos.X, leftPos.Y, section.contentWidth, section.contentHeight) then
                        section:Scroll("left", -input.Position.Z * 20)
                    elseif mouseOver(rightPos.X, rightPos.Y, section.contentWidth, section.contentHeight) then
                        section:Scroll("right", -input.Position.Z * 20)
                    end
                end
            end))

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
                pcall(function() section.objects.leftScrollBg.Position = p + Vector2.new(cX + section.contentWidth - 5, cY + 22) end)
                pcall(function() section.objects.rightOutline.Position = p + Vector2.new(rX, cY) end)
                pcall(function() section.objects.right.Position = p + Vector2.new(rX + 1, cY + 1) end)
                pcall(function() section.objects.rightHeader.Position = p + Vector2.new(rX + 1, cY + 1) end)
                pcall(function() section.objects.rightHeaderLine.Position = p + Vector2.new(rX + 1, cY + 21) end)
                pcall(function() section.objects.rightTitle.Position = p + Vector2.new(rX + 8, cY + 4) end)
                pcall(function() section.objects.rightScrollBg.Position = p + Vector2.new(rX + section.contentWidth - 5, cY + 22) end)
                section:UpdateScroll("left")
                section:UpdateScroll("right")
                for _, elem in pairs(section.leftElements) do
                    if elem.UpdatePositions then elem:UpdatePositions() end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.UpdatePositions then elem:UpdatePositions() end
                end
            end

            function section:SetVisible(state)
                section.visible = state
                for k, obj in pairs(section.objects) do
                    if k ~= "leftScrollBar" and k ~= "leftScrollBg" and k ~= "rightScrollBar" and k ~= "rightScrollBg" then
                        pcall(function() obj.Visible = state end)
                    end
                end
                pcall(function() section.button.objects.accent.Visible = state end)
                pcall(function() section.button.objects.text.Color = state and Color3.new(1, 1, 1) or t.dimtext end)
                for _, elem in pairs(section.leftElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                if state then
                    section:UpdateScroll("left")
                    section:UpdateScroll("right")
                end
            end

            function section:Show()
                for _, s in pairs(page.sections) do
                    if s.SetVisible then s:SetVisible(false) end
                end
                section:SetVisible(true)
                page.currentSection = section
            end

            -- Helper function to check if element is in visible scroll area
            local function isElementVisible(elem, scroll)
                local viewHeight = section.contentHeight - 26
                local elemY = elem.yOffset - scroll
                return elemY >= 0 and elemY < viewHeight
            end

            -- TOGGLE
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
                local elemWidth = section.contentWidth - 20

                local toggle = {
                    value = default,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
                    objects = {}
                }

                toggle.objects.box = create("Square", {
                    Size = Vector2.new(6, 6),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 4),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                toggle.objects.fill = create("Square", {
                    Size = Vector2.new(4, 4),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 5),
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
                    Position = window.pos + Vector2.new(baseX + 15, section.contentY + offset + 1),
                    Visible = section.visible,
                    ZIndex = 9
                })

                toggle.baseX = baseX
                toggle.baseY = section.contentY + offset
                toggle.width = elemWidth

                function toggle:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = toggle.baseYOffset - scroll
                    toggle.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() toggle.objects.box.Position = p + Vector2.new(toggle.baseX, section.contentY + 26 + newY + 4) end)
                    pcall(function() toggle.objects.fill.Position = p + Vector2.new(toggle.baseX + 1, section.contentY + 26 + newY + 5) end)
                    pcall(function() toggle.objects.label.Position = p + Vector2.new(toggle.baseX + 15, section.contentY + 26 + newY + 1) end)
                    pcall(function() toggle.objects.box.Visible = visible end)
                    pcall(function() toggle.objects.fill.Visible = visible end)
                    pcall(function() toggle.objects.label.Visible = visible end)
                end

                function toggle:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    toggle:UpdateScroll(scroll)
                end

                function toggle:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = toggle.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                function toggle:Set(value)
                    toggle.value = value
                    pcall(function() toggle.objects.fill.Color = value and a or t.elementbg end)
                    pcall(function() toggle.objects.label.Color = value and t.text or t.dimtext end)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function toggle:Get() return toggle.value end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = toggle.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = window.pos + Vector2.new(toggle.baseX, section.contentY + 26 + newY)
                            if mouseOver(pos.X - 2, pos.Y, toggle.width, 14) then
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
                    section.leftOffset = section.leftOffset + 18
                else
                    section.rightOffset = section.rightOffset + 18
                end

                table.insert(elements, toggle)
                return toggle
            end

            -- SLIDER
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
                local sliderWidth = section.contentWidth - 20

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
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

                function slider:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = slider.baseYOffset - scroll
                    slider.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    local valText = tostring(slider.value) .. slider.suffix
                    pcall(function() slider.objects.label.Position = p + Vector2.new(slider.baseX, section.contentY + 26 + newY) end)
                    pcall(function() slider.objects.value.Position = p + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, section.contentY + 26 + newY) end)
                    pcall(function() slider.objects.trackOutline.Position = p + Vector2.new(slider.baseX, section.contentY + 26 + newY + 16) end)
                    pcall(function() slider.objects.track.Position = p + Vector2.new(slider.baseX + 1, section.contentY + 26 + newY + 17) end)
                    pcall(function() slider.objects.fill.Position = p + Vector2.new(slider.baseX + 1, section.contentY + 26 + newY + 17) end)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                function slider:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    slider:UpdateScroll(scroll)
                end

                function slider:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = slider.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                function slider:Set(value)
                    value = math.clamp(value, min, max)
                    value = math.floor(value / increment + 0.5) * increment
                    slider.value = value
                    local pct = (value - min) / (max - min)
                    pcall(function() slider.objects.fill.Size = Vector2.new(math.max((slider.width - 2) * pct, 0), 8) end)
                    local valText = tostring(value) .. slider.suffix
                    pcall(function() slider.objects.value.Text = valText end)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = slider.baseYOffset - scroll
                    pcall(function() slider.objects.value.Position = window.pos + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, section.contentY + 26 + newY) end)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function slider:Get() return slider.value end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = slider.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = window.pos + Vector2.new(slider.baseX, section.contentY + 26 + newY + 16)
                            if mouseOver(pos.X, pos.Y, slider.width, 10) then
                                slider.dragging = true
                            end
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
                            local scroll = side == "left" and section.leftScroll or section.rightScroll
                            local newY = slider.baseYOffset - scroll
                            local pos = window.pos + Vector2.new(slider.baseX, section.contentY + 26 + newY + 16)
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

            -- BUTTON
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
                    baseYOffset = offset,
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

                function button:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = button.baseYOffset - scroll
                    button.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() button.objects.outline.Position = p + Vector2.new(button.baseX, section.contentY + 26 + newY) end)
                    pcall(function() button.objects.bg.Position = p + Vector2.new(button.baseX + 1, section.contentY + 26 + newY + 1) end)
                    pcall(function() button.objects.label.Position = p + Vector2.new(button.baseX + button.width/2, section.contentY + 26 + newY + 3) end)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                function button:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    button:UpdateScroll(scroll)
                end

                function button:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = button.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = button.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = window.pos + Vector2.new(button.baseX, section.contentY + 26 + newY)
                            if mouseOver(pos.X, pos.Y, button.width, 20) then
                                pcall(function() button.objects.bg.Color = t.inline end)
                                pcall(callback)
                                task.delay(0.1, function()
                                    pcall(function() button.objects.bg.Color = t.elementbg end)
                                end)
                            end
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

            -- DROPDOWN
            function section:Dropdown(config)
                config = config or {}
                local dropdownName = config.name or "Dropdown"
                local side = (config.side or "left"):lower()
                local items = config.items or {}
                local default = config.default or (items[1] or "")
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local ddWidth = section.contentWidth - 20

                local dropdown = {
                    value = default,
                    items = items,
                    open = false,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
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

                dropdown.objects.selected = create("Text", {
                    Text = default,
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

                function dropdown:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = dropdown.baseYOffset - scroll
                    dropdown.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() dropdown.objects.label.Position = p + Vector2.new(dropdown.baseX, section.contentY + 26 + newY) end)
                    pcall(function() dropdown.objects.outline.Position = p + Vector2.new(dropdown.baseX, section.contentY + 26 + newY + 16) end)
                    pcall(function() dropdown.objects.bg.Position = p + Vector2.new(dropdown.baseX + 1, section.contentY + 26 + newY + 17) end)
                    pcall(function() dropdown.objects.selected.Position = p + Vector2.new(dropdown.baseX + 6, section.contentY + 26 + newY + 19) end)
                    pcall(function() dropdown.objects.arrow.Position = p + Vector2.new(dropdown.baseX + dropdown.width - 12, section.contentY + 26 + newY + 19) end)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                    if not visible then dropdown:Close() end
                end

                function dropdown:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    dropdown:UpdateScroll(scroll)
                end

                function dropdown:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = dropdown.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = visible end)
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
                        local itemText = create("Text", {
                            Text = item,
                            Size = 13,
                            Font = 2,
                            Color = item == dropdown.value and a or t.text,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = Vector2.new(pos.X + 6, pos.Y + 24 + (i-1) * 18),
                            Visible = true,
                            ZIndex = 52
                        })
                        table.insert(dropdown.itemObjects, itemText)
                    end
                end

                function dropdown:Set(value)
                    dropdown.value = value
                    pcall(function() dropdown.objects.selected.Text = value end)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
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
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = dropdown.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = dropdown.objects.outline.Position
                            if mouseOver(pos.X, pos.Y, dropdown.width, 20) then
                                dropdown:Open()
                                return
                            end
                        end
                        if dropdown.open then
                            local pos = dropdown.objects.outline.Position
                            for i, item in ipairs(items) do
                                local itemY = pos.Y + 22 + (i-1) * 18
                                if mouseOver(pos.X, itemY, dropdown.width, 18) then
                                    dropdown:Set(item)
                                    dropdown:Close()
                                    return
                                end
                            end
                            dropdown:Close()
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = dropdown
                end

                if default ~= "" then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 42
                else
                    section.rightOffset = section.rightOffset + 42
                end

                table.insert(elements, dropdown)
                return dropdown
            end

            -- MULTI-DROPDOWN
            function section:MultiDropdown(config)
                config = config or {}
                local dropdownName = config.name or "Multi Dropdown"
                local side = (config.side or "left"):lower()
                local items = config.items or {}
                local default = config.default or {}
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local ddWidth = section.contentWidth - 20

                local dropdown = {
                    values = default,
                    items = items,
                    open = false,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
                    objects = {},
                    itemObjects = {}
                }

                local function getDisplayText()
                    if #dropdown.values == 0 then
                        return "None"
                    elseif #dropdown.values == 1 then
                        return dropdown.values[1]
                    elseif #dropdown.values == #items then
                        return "All"
                    else
                        return #dropdown.values .. " selected"
                    end
                end

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

                dropdown.objects.selected = create("Text", {
                    Text = getDisplayText(),
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
                    Text = "+",
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

                function dropdown:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = dropdown.baseYOffset - scroll
                    dropdown.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() dropdown.objects.label.Position = p + Vector2.new(dropdown.baseX, section.contentY + 26 + newY) end)
                    pcall(function() dropdown.objects.outline.Position = p + Vector2.new(dropdown.baseX, section.contentY + 26 + newY + 16) end)
                    pcall(function() dropdown.objects.bg.Position = p + Vector2.new(dropdown.baseX + 1, section.contentY + 26 + newY + 17) end)
                    pcall(function() dropdown.objects.selected.Position = p + Vector2.new(dropdown.baseX + 6, section.contentY + 26 + newY + 19) end)
                    pcall(function() dropdown.objects.arrow.Position = p + Vector2.new(dropdown.baseX + dropdown.width - 12, section.contentY + 26 + newY + 19) end)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                    if not visible then dropdown:Close() end
                end

                function dropdown:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    dropdown:UpdateScroll(scroll)
                end

                function dropdown:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = dropdown.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(dropdown.objects) do
                        pcall(function() obj.Visible = visible end)
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
                        local isSelected = table.find(dropdown.values, item) ~= nil
                        local checkBox = create("Square", {
                            Size = Vector2.new(10, 10),
                            Position = Vector2.new(pos.X + 6, pos.Y + 26 + (i-1) * 18),
                            Color = isSelected and a or t.outline,
                            Filled = true,
                            Visible = true,
                            ZIndex = 52
                        })
                        table.insert(dropdown.itemObjects, checkBox)

                        local itemText = create("Text", {
                            Text = item,
                            Size = 13,
                            Font = 2,
                            Color = isSelected and a or t.text,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = Vector2.new(pos.X + 22, pos.Y + 24 + (i-1) * 18),
                            Visible = true,
                            ZIndex = 52
                        })
                        table.insert(dropdown.itemObjects, itemText)
                    end
                end

                function dropdown:Toggle(item)
                    local idx = table.find(dropdown.values, item)
                    if idx then
                        table.remove(dropdown.values, idx)
                    else
                        table.insert(dropdown.values, item)
                    end
                    pcall(function() dropdown.objects.selected.Text = getDisplayText() end)
                    if flag then library.flags[flag] = dropdown.values end
                    pcall(callback, dropdown.values)
                    if dropdown.open then
                        dropdown:Close()
                        dropdown:Open()
                    end
                end

                function dropdown:Set(values)
                    dropdown.values = values
                    pcall(function() dropdown.objects.selected.Text = getDisplayText() end)
                    if flag then library.flags[flag] = values end
                    pcall(callback, values)
                end

                function dropdown:Get() return dropdown.values end

                function dropdown:Refresh(newItems)
                    dropdown.items = newItems
                    items = newItems
                    dropdown.values = {}
                    pcall(function() dropdown.objects.selected.Text = getDisplayText() end)
                    if dropdown.open then
                        dropdown:Close()
                        dropdown:Open()
                    end
                end

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = dropdown.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = dropdown.objects.outline.Position
                            if mouseOver(pos.X, pos.Y, dropdown.width, 20) then
                                dropdown:Open()
                                return
                            end
                        end
                        if dropdown.open then
                            local pos = dropdown.objects.outline.Position
                            for i, item in ipairs(items) do
                                local itemY = pos.Y + 22 + (i-1) * 18
                                if mouseOver(pos.X, itemY, dropdown.width, 18) then
                                    dropdown:Toggle(item)
                                    return
                                end
                            end
                            dropdown:Close()
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = dropdown
                end

                if #default > 0 then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 42
                else
                    section.rightOffset = section.rightOffset + 42
                end

                table.insert(elements, dropdown)
                return dropdown
            end

            -- TEXTBOX
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
                local tbWidth = section.contentWidth - 20

                local textbox = {
                    value = default,
                    focused = false,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
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
                    Size = Vector2.new(tbWidth, 20),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                textbox.objects.bg = create("Square", {
                    Size = Vector2.new(tbWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
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
                    Position = window.pos + Vector2.new(baseX + 6, section.contentY + offset + 19),
                    Visible = section.visible,
                    ZIndex = 11
                })

                textbox.objects.cursor = create("Square", {
                    Size = Vector2.new(1, 12),
                    Position = window.pos + Vector2.new(baseX + 6, section.contentY + offset + 20),
                    Color = t.text,
                    Filled = true,
                    Visible = false,
                    ZIndex = 12
                })

                textbox.baseX = baseX
                textbox.baseY = section.contentY + offset
                textbox.width = tbWidth
                textbox.placeholder = placeholder

                function textbox:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = textbox.baseYOffset - scroll
                    textbox.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() textbox.objects.label.Position = p + Vector2.new(textbox.baseX, section.contentY + 26 + newY) end)
                    pcall(function() textbox.objects.outline.Position = p + Vector2.new(textbox.baseX, section.contentY + 26 + newY + 16) end)
                    pcall(function() textbox.objects.bg.Position = p + Vector2.new(textbox.baseX + 1, section.contentY + 26 + newY + 17) end)
                    pcall(function() textbox.objects.text.Position = p + Vector2.new(textbox.baseX + 6, section.contentY + 26 + newY + 19) end)
                    local textWidth = textBounds(textbox.value, 13).X
                    pcall(function() textbox.objects.cursor.Position = p + Vector2.new(textbox.baseX + 6 + textWidth, section.contentY + 26 + newY + 20) end)
                    for k, obj in pairs(textbox.objects) do
                        if k ~= "cursor" then
                            pcall(function() obj.Visible = visible end)
                        end
                    end
                    if not visible then
                        textbox.focused = false
                        pcall(function() textbox.objects.cursor.Visible = false end)
                    end
                end

                function textbox:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    textbox:UpdateScroll(scroll)
                end

                function textbox:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = textbox.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for k, obj in pairs(textbox.objects) do
                        if k ~= "cursor" then
                            pcall(function() obj.Visible = visible end)
                        end
                    end
                    if not state then
                        textbox.focused = false
                        pcall(function() textbox.objects.cursor.Visible = false end)
                    end
                end

                function textbox:Set(value)
                    textbox.value = value
                    pcall(function() textbox.objects.text.Text = value ~= "" and value or textbox.placeholder end)
                    pcall(function() textbox.objects.text.Color = value ~= "" and t.text or t.dimtext end)
                    local textWidth = textBounds(value, 13).X
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = textbox.baseYOffset - scroll
                    pcall(function() textbox.objects.cursor.Position = window.pos + Vector2.new(textbox.baseX + 6 + textWidth, section.contentY + 26 + newY + 20) end)
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function textbox:Get() return textbox.value end

                function textbox:Focus()
                    textbox.focused = true
                    window.activeTextbox = textbox
                    pcall(function() textbox.objects.outline.Color = a end)
                    pcall(function() textbox.objects.cursor.Visible = true end)
                    pcall(function() textbox.objects.text.Text = textbox.value end)
                    pcall(function() textbox.objects.text.Color = t.text end)
                end

                function textbox:Unfocus()
                    textbox.focused = false
                    if window.activeTextbox == textbox then
                        window.activeTextbox = nil
                    end
                    pcall(function() textbox.objects.outline.Color = t.outline end)
                    pcall(function() textbox.objects.cursor.Visible = false end)
                    if textbox.value == "" then
                        pcall(function() textbox.objects.text.Text = textbox.placeholder end)
                        pcall(function() textbox.objects.text.Color = t.dimtext end)
                    end
                end

                -- Cursor blink
                task.spawn(function()
                    while true do
                        task.wait(0.5)
                        if textbox.focused then
                            pcall(function() textbox.objects.cursor.Visible = not textbox.objects.cursor.Visible end)
                        end
                    end
                end)

                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = textbox.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = window.pos + Vector2.new(textbox.baseX, section.contentY + 26 + newY + 16)
                            if mouseOver(pos.X, pos.Y, textbox.width, 20) then
                                textbox:Focus()
                                return
                            end
                        end
                        if textbox.focused then
                            textbox:Unfocus()
                        end
                    end

                    if textbox.focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Escape then
                            textbox:Unfocus()
                        elseif input.KeyCode == Enum.KeyCode.Backspace then
                            textbox:Set(textbox.value:sub(1, -2))
                        end
                    end
                end))

                table.insert(library.connections, UIS.InputChanged:Connect(function(input)
                    if textbox.focused and input.UserInputType == Enum.UserInputType.TextInput then
                        -- This won't work in most executors, so we use TextInputChanged
                    end
                end))

                -- Text input handling
                table.insert(library.connections, UIS.TextBoxFocusReleased:Connect(function()
                    -- Not applicable for Drawing API
                end))

                -- Character input via InputBegan
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if textbox.focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode
                        if key == Enum.KeyCode.Space then
                            textbox:Set(textbox.value .. " ")
                        elseif key.Name:len() == 1 then
                            local char = key.Name
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                char = char:upper()
                            else
                                char = char:lower()
                            end
                            textbox:Set(textbox.value .. char)
                        elseif key == Enum.KeyCode.Period then
                            textbox:Set(textbox.value .. ".")
                        elseif key == Enum.KeyCode.Comma then
                            textbox:Set(textbox.value .. ",")
                        elseif key == Enum.KeyCode.Minus then
                            textbox:Set(textbox.value .. "-")
                        elseif key == Enum.KeyCode.Equals then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "+")
                            else
                                textbox:Set(textbox.value .. "=")
                            end
                        elseif key == Enum.KeyCode.One then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "!")
                            else
                                textbox:Set(textbox.value .. "1")
                            end
                        elseif key == Enum.KeyCode.Two then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "@")
                            else
                                textbox:Set(textbox.value .. "2")
                            end
                        elseif key == Enum.KeyCode.Three then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "#")
                            else
                                textbox:Set(textbox.value .. "3")
                            end
                        elseif key == Enum.KeyCode.Four then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "$")
                            else
                                textbox:Set(textbox.value .. "4")
                            end
                        elseif key == Enum.KeyCode.Five then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "%")
                            else
                                textbox:Set(textbox.value .. "5")
                            end
                        elseif key == Enum.KeyCode.Six then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "^")
                            else
                                textbox:Set(textbox.value .. "6")
                            end
                        elseif key == Enum.KeyCode.Seven then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "&")
                            else
                                textbox:Set(textbox.value .. "7")
                            end
                        elseif key == Enum.KeyCode.Eight then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "*")
                            else
                                textbox:Set(textbox.value .. "8")
                            end
                        elseif key == Enum.KeyCode.Nine then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. "(")
                            else
                                textbox:Set(textbox.value .. "9")
                            end
                        elseif key == Enum.KeyCode.Zero then
                            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                                textbox:Set(textbox.value .. ")")
                            else
                                textbox:Set(textbox.value .. "0")
                            end
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = textbox
                end

                if default ~= "" then pcall(callback, default) end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 42
                else
                    section.rightOffset = section.rightOffset + 42
                end

                table.insert(elements, textbox)
                return textbox
            end

            -- COLORPICKER
            function section:ColorPicker(config)
                config = config or {}
                local pickerName = config.name or "Color"
                local side = (config.side or "left"):lower()
                local default = config.default or Color3.fromRGB(255, 255, 255)
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and section.leftElements or section.rightElements
                local offset = side == "left" and section.leftOffset or section.rightOffset
                local baseX = side == "left" and (section.contentX + 10) or (section.rightX + 10)
                local cpWidth = section.contentWidth - 20

                local h, s, v = rgbToHsv(default.R * 255, default.G * 255, default.B * 255)

                local colorpicker = {
                    value = default,
                    h = h,
                    s = s,
                    v = v,
                    open = false,
                    draggingSV = false,
                    draggingH = false,
                    side = side,
                    yOffset = offset,
                    baseYOffset = offset,
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
                    Size = Vector2.new(20, 12),
                    Position = window.pos + Vector2.new(baseX + cpWidth - 22, section.contentY + offset + 2),
                    Color = default,
                    Filled = true,
                    Visible = section.visible,
                    ZIndex = 9
                })

                colorpicker.objects.previewOutline = create("Square", {
                    Size = Vector2.new(20, 12),
                    Position = window.pos + Vector2.new(baseX + cpWidth - 22, section.contentY + offset + 2),
                    Color = t.outline,
                    Filled = false,
                    Thickness = 1,
                    Visible = section.visible,
                    ZIndex = 10
                })

                colorpicker.baseX = baseX
                colorpicker.baseY = section.contentY + offset
                colorpicker.width = cpWidth

                function colorpicker:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = colorpicker.baseYOffset - scroll
                    colorpicker.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() colorpicker.objects.label.Position = p + Vector2.new(colorpicker.baseX, section.contentY + 26 + newY + 2) end)
                    pcall(function() colorpicker.objects.preview.Position = p + Vector2.new(colorpicker.baseX + colorpicker.width - 22, section.contentY + 26 + newY + 2) end)
                    pcall(function() colorpicker.objects.previewOutline.Position = p + Vector2.new(colorpicker.baseX + colorpicker.width - 22, section.contentY + 26 + newY + 2) end)
                    for _, obj in pairs(colorpicker.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                    if not visible then colorpicker:Close() end
                end

                function colorpicker:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    colorpicker:UpdateScroll(scroll)
                end

                function colorpicker:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = colorpicker.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(colorpicker.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                    if not state then colorpicker:Close() end
                end

                function colorpicker:Close()
                    colorpicker.open = false
                    colorpicker.draggingSV = false
                    colorpicker.draggingH = false
                    window.activeColorPicker = nil
                    for _, obj in pairs(colorpicker.pickerObjects) do
                        pcall(function() obj:Remove() end)
                    end
                    colorpicker.pickerObjects = {}
                end

                function colorpicker:Open()
                    if colorpicker.open then
                        colorpicker:Close()
                        return
                    end
                    colorpicker.open = true
                    window.activeColorPicker = colorpicker

                    local pos = colorpicker.objects.preview.Position
                    local pickerW = 180
                    local pickerH = 160

                    -- Background
                    local bg = create("Square", {
                        Size = Vector2.new(pickerW, pickerH),
                        Position = Vector2.new(pos.X - pickerW + 22, pos.Y + 16),
                        Color = t.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(colorpicker.pickerObjects, bg)

                    local outline = create("Square", {
                        Size = Vector2.new(pickerW, pickerH),
                        Position = Vector2.new(pos.X - pickerW + 22, pos.Y + 16),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 51
                    })
                    table.insert(colorpicker.pickerObjects, outline)

                    -- SV picker area (120x120)
                    local svX = pos.X - pickerW + 30
                    local svY = pos.Y + 24
                    local svSize = 120

                    -- White gradient (left to right)
                    local svWhite = create("Square", {
                        Size = Vector2.new(svSize, svSize),
                        Position = Vector2.new(svX, svY),
                        Color = Color3.new(1, 1, 1),
                        Filled = true,
                        Visible = true,
                        ZIndex = 52
                    })
                    table.insert(colorpicker.pickerObjects, svWhite)

                    -- Hue color overlay
                    local r, g, b = hsvToRgb(colorpicker.h, 1, 1)
                    local svHue = create("Square", {
                        Size = Vector2.new(svSize, svSize),
                        Position = Vector2.new(svX, svY),
                        Color = Color3.fromRGB(r, g, b),
                        Filled = true,
                        Transparency = 0.5,
                        Visible = true,
                        ZIndex = 53
                    })
                    table.insert(colorpicker.pickerObjects, svHue)
                    colorpicker.svHue = svHue

                    -- SV outline
                    local svOutline = create("Square", {
                        Size = Vector2.new(svSize, svSize),
                        Position = Vector2.new(svX, svY),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 54
                    })
                    table.insert(colorpicker.pickerObjects, svOutline)

                    -- SV cursor
                    local svCursorX = svX + colorpicker.s * svSize - 3
                    local svCursorY = svY + (1 - colorpicker.v) * svSize - 3
                    local svCursor = create("Circle", {
                        Radius = 4,
                        Position = Vector2.new(svCursorX + 3, svCursorY + 3),
                        Color = Color3.new(1, 1, 1),
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 55
                    })
                    table.insert(colorpicker.pickerObjects, svCursor)
                    colorpicker.svCursor = svCursor

                    -- Hue bar (vertical, 20x120)
                    local hueX = svX + svSize + 10
                    local hueY = svY
                    local hueW = 20
                    local hueH = svSize

                    -- Draw hue gradient using multiple rectangles
                    local hueSteps = 12
                    local stepH = hueH / hueSteps
                    for i = 0, hueSteps - 1 do
                        local hueVal = i / hueSteps
                        local hr, hg, hb = hsvToRgb(hueVal, 1, 1)
                        local hueStep = create("Square", {
                            Size = Vector2.new(hueW, stepH + 1),
                            Position = Vector2.new(hueX, hueY + i * stepH),
                            Color = Color3.fromRGB(hr, hg, hb),
                            Filled = true,
                            Visible = true,
                            ZIndex = 52
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
                        ZIndex = 54
                    })
                    table.insert(colorpicker.pickerObjects, hueOutline)

                    -- Hue cursor
                    local hueCursorY = hueY + colorpicker.h * hueH - 2
                    local hueCursor = create("Square", {
                        Size = Vector2.new(hueW, 4),
                        Position = Vector2.new(hueX, hueCursorY),
                        Color = Color3.new(1, 1, 1),
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 55
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

                -- Click to open
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = colorpicker.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local previewPos = colorpicker.objects.preview.Position
                            if mouseOver(previewPos.X, previewPos.Y, 20, 12) then
                                colorpicker:Open()
                                return
                            end
                        end

                        if colorpicker.open then
                            -- Check SV area
                            if mouseOver(colorpicker.svX, colorpicker.svY, colorpicker.svSize, colorpicker.svSize) then
                                colorpicker.draggingSV = true
                                return
                            end
                            -- Check Hue bar
                            if mouseOver(colorpicker.hueX, colorpicker.hueY, colorpicker.hueW, colorpicker.hueH) then
                                colorpicker.draggingH = true
                                return
                            end
                            -- Click outside closes
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

                if side == "left" then
                    section.leftOffset = section.leftOffset + 20
                else
                    section.rightOffset = section.rightOffset + 20
                end

                table.insert(elements, colorpicker)
                return colorpicker
            end

            -- KEYBIND
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
                    baseYOffset = offset,
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

                function keybind:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = keybind.baseYOffset - scroll
                    keybind.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    local keyText = "[" .. keybind.getKeyName(keybind.value) .. "]"
                    pcall(function() keybind.objects.label.Position = p + Vector2.new(keybind.baseX, section.contentY + 26 + newY + 2) end)
                    pcall(function() keybind.objects.key.Position = p + Vector2.new(keybind.baseX + keybind.width - textBounds(keyText, 13).X, section.contentY + 26 + newY + 2) end)
                    for _, obj in pairs(keybind.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                function keybind:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    keybind:UpdateScroll(scroll)
                end

                function keybind:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = keybind.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    for _, obj in pairs(keybind.objects) do
                        pcall(function() obj.Visible = visible end)
                    end
                end

                function keybind:Set(key)
                    keybind.value = key
                    local keyText = "[" .. getKeyName(key) .. "]"
                    pcall(function() keybind.objects.key.Text = keyText end)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = keybind.baseYOffset - scroll
                    pcall(function() keybind.objects.key.Position = window.pos + Vector2.new(keybind.baseX + keybind.width - textBounds(keyText, 13).X, section.contentY + 26 + newY + 2) end)
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
                        local scroll = side == "left" and section.leftScroll or section.rightScroll
                        local newY = keybind.baseYOffset - scroll
                        if newY >= 0 and newY < (section.contentHeight - 26) then
                            local pos = window.pos + Vector2.new(keybind.baseX, section.contentY + 26 + newY)
                            if mouseOver(pos.X, pos.Y, keybind.width, 18) then
                                keybind.listening = true
                                pcall(function() keybind.objects.key.Color = a end)
                            end
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

            -- LABEL (simple text)
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
                    baseYOffset = offset,
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

                function label:UpdateScroll(scroll)
                    local p = window.pos
                    local newY = label.baseYOffset - scroll
                    label.yOffset = newY
                    local visible = section.visible and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() label.objects.text.Position = p + Vector2.new(label.baseX, section.contentY + 26 + newY + 2) end)
                    pcall(function() label.objects.text.Visible = visible end)
                end

                function label:UpdatePositions()
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    label:UpdateScroll(scroll)
                end

                function label:SetVisible(state)
                    local scroll = side == "left" and section.leftScroll or section.rightScroll
                    local newY = label.baseYOffset - scroll
                    local visible = state and newY >= 0 and newY < (section.contentHeight - 26)
                    pcall(function() label.objects.text.Visible = visible end)
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

            -- Section button click
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

    -- Dragging & Tab clicks
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
    end))

    function window:Init()
        if window.pages[1] then
            window.pages[1]:Show()
        end
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
