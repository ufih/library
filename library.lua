--[[
    NexusLib v3 - Enhanced Drawing UI Library
    Inspired by Pandora, Specter, Splix styles
    Clean modern look with horizontal tabs
]]

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

-- Services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Helper functions
local function create(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    table.insert(library.drawings, obj)
    return obj
end

local function remove(obj)
    for i, v in pairs(library.drawings) do
        if v == obj then
            table.remove(library.drawings, i)
            break
        end
    end
    pcall(function() obj:Remove() end)
end

local function textBounds(text, size)
    local t = Drawing.new("Text")
    t.Text = text or ""
    t.Size = size or 13
    t.Font = 2
    local b = t.TextBounds
    t:Remove()
    return b
end

local function mouseOver(x, y, w, h)
    local m = UIS:GetMouseLocation()
    return m.X >= x and m.X <= x + w and m.Y >= y and m.Y <= y + h
end

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
        objects = {}
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

    -- Accent gradient line under topbar
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

    -- Content area outline
    window.objects.contentOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, sizeY - 50),
        Position = window.pos + Vector2.new(2, 26),
        Color = t.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 3
    })

    -- Content area
    window.objects.content = create("Square", {
        Size = Vector2.new(sizeX - 6, sizeY - 52),
        Position = window.pos + Vector2.new(3, 27),
        Color = t.section,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 4
    })

    -- Left sidebar outline
    window.objects.sidebarOutline = create("Square", {
        Size = Vector2.new(112, sizeY - 54),
        Position = window.pos + Vector2.new(4, 28),
        Color = t.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 5
    })

    -- Left sidebar
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

    -- Version text
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

    -- Tab holder X position (after title)
    local tabStartX = textBounds(name, 13).X + 20
    window.tabStartX = tabStartX

    function window:UpdatePositions()
        local p = window.pos
        local o = window.objects

        o.outline.Position = p
        o.bg.Position = p + Vector2.new(1, 1)
        o.topbar.Position = p + Vector2.new(2, 2)
        o.accentLine.Position = p + Vector2.new(2, 24)
        o.title.Position = p + Vector2.new(8, 5)
        o.contentOutline.Position = p + Vector2.new(2, 26)
        o.content.Position = p + Vector2.new(3, 27)
        o.sidebarOutline.Position = p + Vector2.new(4, 28)
        o.sidebar.Position = p + Vector2.new(5, 29)
        o.bottomOutline.Position = p + Vector2.new(2, sizeY - 24)
        o.bottombar.Position = p + Vector2.new(3, sizeY - 23)
        o.version.Position = p + Vector2.new(8, sizeY - 20)

        for _, page in pairs(window.pages) do
            page:UpdatePositions()
        end
    end

    function window:SetVisible(state)
        library.open = state
        for _, obj in pairs(window.objects) do
            pcall(function() obj.Visible = state end)
        end
        for _, page in pairs(window.pages) do
            page:SetVisible(state and page == window.currentPage)
        end
    end

    function window:Toggle()
        window:SetVisible(not library.open)
    end

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

        -- Calculate tab position
        local tabX = window.tabStartX
        for _, p in pairs(window.pages) do
            tabX = tabX + textBounds(p.name, 13).X + 16
        end

        local tabWidth = textBounds(pageName, 13).X + 12

        -- Tab background (shows when active)
        page.objects.tabBg = create("Square", {
            Size = Vector2.new(tabWidth, 19),
            Position = window.pos + Vector2.new(tabX, 4),
            Color = t.section,
            Filled = true,
            Thickness = 0,
            Visible = false,
            ZIndex = 4
        })

        -- Tab accent line
        page.objects.tabAccent = create("Square", {
            Size = Vector2.new(tabWidth - 4, 1),
            Position = window.pos + Vector2.new(tabX + 2, 5),
            Color = a,
            Filled = true,
            Thickness = 0,
            Visible = false,
            ZIndex = 5
        })

        -- Tab text
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
            page.objects.tabBg.Position = p + Vector2.new(page.tabX, 4)
            page.objects.tabAccent.Position = p + Vector2.new(page.tabX + 2, 5)
            page.objects.tabText.Position = p + Vector2.new(page.tabX + 6, 7)

            for i, btn in pairs(page.sectionButtons) do
                btn:UpdatePositions()
            end

            for _, section in pairs(page.sections) do
                section:UpdatePositions()
            end
        end

        function page:SetVisible(state)
            page.visible = state
            page.objects.tabBg.Visible = state
            page.objects.tabAccent.Visible = state
            page.objects.tabText.Color = state and library.accent or t.dimtext

            for _, btn in pairs(page.sectionButtons) do
                btn:SetVisible(state)
            end

            for _, section in pairs(page.sections) do
                section:SetVisible(state and section == page.currentSection)
            end
        end

        function page:Show()
            for _, p in pairs(window.pages) do
                p:SetVisible(false)
            end
            page:SetVisible(true)
            window.currentPage = page

            if page.currentSection then
                page.currentSection:SetVisible(true)
            elseif page.sections[1] then
                page.sections[1]:Show()
            end
        end

        -- Section function (appears in sidebar)
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
                objects = {},
                page = page,
                window = window
            }

            -- Button in sidebar
            local btnY = 8 + (#page.sections * 22)
            local sectionBtn = {
                yOffset = btnY,
                objects = {}
            }

            -- Accent bar (shows when active)
            sectionBtn.objects.accent = create("Square", {
                Size = Vector2.new(1, 18),
                Position = window.pos + Vector2.new(6, 30 + btnY),
                Color = a,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 7
            })

            -- Button text
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
                sectionBtn.objects.accent.Position = p + Vector2.new(6, 30 + sectionBtn.yOffset)
                sectionBtn.objects.text.Position = p + Vector2.new(14, 32 + sectionBtn.yOffset)
            end

            function sectionBtn:SetVisible(state)
                sectionBtn.objects.accent.Visible = state and section == page.currentSection
                sectionBtn.objects.text.Visible = state
                sectionBtn.objects.text.Color = (section == page.currentSection) and Color3.new(1, 1, 1) or t.dimtext
            end

            table.insert(page.sectionButtons, sectionBtn)
            section.button = sectionBtn

            -- Content area dimensions
            local contentX = 120
            local contentWidth = (sizeX - 130) / 2 - 8
            local contentY = 30

            -- Left column outline
            section.objects.leftOutline = create("Square", {
                Size = Vector2.new(contentWidth + 2, sizeY - 84),
                Position = window.pos + Vector2.new(contentX, contentY),
                Color = t.outline,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 5
            })

            -- Left column
            section.objects.left = create("Square", {
                Size = Vector2.new(contentWidth, sizeY - 86),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = t.sidebar,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 6
            })

            -- Left header
            section.objects.leftHeader = create("Square", {
                Size = Vector2.new(contentWidth, 20),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 1),
                Color = t.sectionheader,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 7
            })

            -- Left header line
            section.objects.leftHeaderLine = create("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(contentX + 1, contentY + 21),
                Color = t.outline,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 8
            })

            -- Left title
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

            -- Right column outline
            local rightX = contentX + contentWidth + 10
            section.objects.rightOutline = create("Square", {
                Size = Vector2.new(contentWidth + 2, sizeY - 84),
                Position = window.pos + Vector2.new(rightX, contentY),
                Color = t.outline,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 5
            })

            -- Right column
            section.objects.right = create("Square", {
                Size = Vector2.new(contentWidth, sizeY - 86),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = t.sidebar,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 6
            })

            -- Right header
            section.objects.rightHeader = create("Square", {
                Size = Vector2.new(contentWidth, 20),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 1),
                Color = t.sectionheader,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 7
            })

            -- Right header line
            section.objects.rightHeaderLine = create("Square", {
                Size = Vector2.new(contentWidth, 1),
                Position = window.pos + Vector2.new(rightX + 1, contentY + 21),
                Color = t.outline,
                Filled = true,
                Thickness = 0,
                Visible = false,
                ZIndex = 8
            })

            -- Right title
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

            function section:UpdatePositions()
                local p = window.pos
                local cX = section.contentX
                local rX = section.rightX
                local cY = section.contentY
                local cW = section.contentWidth

                section.objects.leftOutline.Position = p + Vector2.new(cX, cY)
                section.objects.left.Position = p + Vector2.new(cX + 1, cY + 1)
                section.objects.leftHeader.Position = p + Vector2.new(cX + 1, cY + 1)
                section.objects.leftHeaderLine.Position = p + Vector2.new(cX + 1, cY + 21)
                section.objects.leftTitle.Position = p + Vector2.new(cX + 8, cY + 4)

                section.objects.rightOutline.Position = p + Vector2.new(rX, cY)
                section.objects.right.Position = p + Vector2.new(rX + 1, cY + 1)
                section.objects.rightHeader.Position = p + Vector2.new(rX + 1, cY + 1)
                section.objects.rightHeaderLine.Position = p + Vector2.new(rX + 1, cY + 21)
                section.objects.rightTitle.Position = p + Vector2.new(rX + 8, cY + 4)

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
                section.button.objects.accent.Visible = state
                section.button.objects.text.Color = state and Color3.new(1, 1, 1) or t.dimtext

                for _, elem in pairs(section.leftElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
                for _, elem in pairs(section.rightElements) do
                    if elem.SetVisible then elem:SetVisible(state) end
                end
            end

            function section:Show()
                for _, s in pairs(page.sections) do
                    s:SetVisible(false)
                end
                section:SetVisible(true)
                page.currentSection = section
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
                    objects = {}
                }

                -- Checkbox outline
                toggle.objects.box = create("Square", {
                    Size = Vector2.new(6, 6),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 4),
                    Color = t.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 9
                })

                -- Checkbox fill
                toggle.objects.fill = create("Square", {
                    Size = Vector2.new(4, 4),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 5),
                    Color = default and a or t.elementbg,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 10
                })

                -- Label
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

                function toggle:UpdatePositions()
                    local p = window.pos
                    toggle.objects.box.Position = p + Vector2.new(toggle.baseX, toggle.baseY + 4)
                    toggle.objects.fill.Position = p + Vector2.new(toggle.baseX + 1, toggle.baseY + 5)
                    toggle.objects.label.Position = p + Vector2.new(toggle.baseX + 15, toggle.baseY + 1)
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function toggle:Set(value)
                    toggle.value = value
                    toggle.objects.fill.Color = value and a or t.elementbg
                    toggle.objects.label.Color = value and t.text or t.dimtext
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function toggle:Get() return toggle.value end

                -- Click
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = toggle.objects.box.Position
                        if mouseOver(pos.X - 2, pos.Y - 2, elemWidth, 14) then
                            toggle:Set(not toggle.value)
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
                    objects = {}
                }

                -- Label
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

                -- Value
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

                -- Track outline
                slider.objects.trackOutline = create("Square", {
                    Size = Vector2.new(sliderWidth, 10),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 9
                })

                -- Track background
                slider.objects.track = create("Square", {
                    Size = Vector2.new(sliderWidth - 2, 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
                    Color = t.elementbg,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 10
                })

                -- Fill
                local pct = (default - min) / (max - min)
                slider.objects.fill = create("Square", {
                    Size = Vector2.new((sliderWidth - 2) * pct, 8),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
                    Color = a,
                    Filled = true,
                    Thickness = 0,
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
                    slider.objects.label.Position = p + Vector2.new(slider.baseX, slider.baseY)
                    slider.objects.value.Position = p + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, slider.baseY)
                    slider.objects.trackOutline.Position = p + Vector2.new(slider.baseX, slider.baseY + 16)
                    slider.objects.track.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 17)
                    slider.objects.fill.Position = p + Vector2.new(slider.baseX + 1, slider.baseY + 17)
                end

                function slider:SetVisible(state)
                    for _, obj in pairs(slider.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function slider:Set(value)
                    value = math.clamp(value, min, max)
                    value = math.floor(value / increment + 0.5) * increment
                    slider.value = value

                    local pct = (value - min) / (max - min)
                    slider.objects.fill.Size = Vector2.new((slider.width - 2) * pct, 8)

                    local valText = tostring(value) .. slider.suffix
                    slider.objects.value.Text = valText
                    slider.objects.value.Position = window.pos + Vector2.new(slider.baseX + slider.width - textBounds(valText, 13).X, slider.baseY)

                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function slider:Get() return slider.value end

                -- Drag
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
                        local mouse = UIS:GetMouseLocation()
                        local pos = slider.objects.trackOutline.Position
                        local pct = math.clamp((mouse.X - pos.X) / slider.width, 0, 1)
                        slider:Set(min + (max - min) * pct)
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
                    objects = {}
                }

                -- Outline
                button.objects.outline = create("Square", {
                    Size = Vector2.new(btnWidth, 20),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = t.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 9
                })

                -- Background
                button.objects.bg = create("Square", {
                    Size = Vector2.new(btnWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 1),
                    Color = t.elementbg,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 10
                })

                -- Label
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
                    button.objects.outline.Position = p + Vector2.new(button.baseX, button.baseY)
                    button.objects.bg.Position = p + Vector2.new(button.baseX + 1, button.baseY + 1)
                    button.objects.label.Position = p + Vector2.new(button.baseX + button.width/2, button.baseY + 3)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                -- Click
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = button.objects.outline.Position
                        if mouseOver(pos.X, pos.Y, button.width, 20) then
                            button.objects.bg.Color = t.inline
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
                    objects = {},
                    itemObjects = {}
                }

                -- Label
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

                -- Outline
                dropdown.objects.outline = create("Square", {
                    Size = Vector2.new(ddWidth, 20),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 9
                })

                -- Background
                dropdown.objects.bg = create("Square", {
                    Size = Vector2.new(ddWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 17),
                    Color = t.elementbg,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 10
                })

                -- Selected text
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

                -- Arrow
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
                    dropdown.objects.label.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY)
                    dropdown.objects.outline.Position = p + Vector2.new(dropdown.baseX, dropdown.baseY + 16)
                    dropdown.objects.bg.Position = p + Vector2.new(dropdown.baseX + 1, dropdown.baseY + 17)
                    dropdown.objects.selected.Position = p + Vector2.new(dropdown.baseX + 6, dropdown.baseY + 19)
                    dropdown.objects.arrow.Position = p + Vector2.new(dropdown.baseX + dropdown.width - 12, dropdown.baseY + 19)
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

                    local pos = dropdown.objects.outline.Position
                    local listH = math.min(#items * 18 + 4, 150)

                    local listBg = create("Square", {
                        Size = Vector2.new(dropdown.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 22),
                        Color = t.elementbg,
                        Filled = true,
                        Thickness = 0,
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
                    dropdown.objects.selected.Text = value
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function dropdown:Get() return dropdown.value end

                -- Click
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = dropdown.objects.outline.Position

                        if mouseOver(pos.X, pos.Y, dropdown.width, 20) then
                            dropdown:Open()
                            return
                        end

                        if dropdown.open then
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
                    objects = {}
                }

                -- Label
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

                -- Key display
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
                    keybind.objects.label.Position = p + Vector2.new(keybind.baseX, keybind.baseY + 2)
                    keybind.objects.key.Position = p + Vector2.new(keybind.baseX + keybind.width - textBounds(keyText, 13).X, keybind.baseY + 2)
                end

                function keybind:SetVisible(state)
                    for _, obj in pairs(keybind.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function keybind:Set(key)
                    keybind.value = key
                    local keyText = "[" .. getKeyName(key) .. "]"
                    keybind.objects.key.Text = keyText
                    keybind.objects.key.Position = window.pos + Vector2.new(keybind.baseX + keybind.width - textBounds(keyText, 13).X, keybind.baseY + 2)
                    if flag then library.flags[flag] = key end
                end

                function keybind:Get() return keybind.value end

                -- Input
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if keybind.listening then
                        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                        if key == Enum.KeyCode.Escape then key = Enum.KeyCode.Unknown end
                        keybind:Set(key)
                        keybind.listening = false
                        keybind.objects.key.Color = t.dimtext
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = keybind.objects.label.Position
                        if mouseOver(pos.X, pos.Y - 2, keybind.width, 18) then
                            keybind.listening = true
                            keybind.objects.key.Color = a
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

            -- TEXTBOX
            function section:Textbox(config)
                config = config or {}
                local textboxName = config.name or "Textbox"
                local side = (config.side or "left"):lower()
                local placeholder = config.placeholder or "Enter text..."
                local default = config.default or ""
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
                    objects = {}
                }

                -- Outline
                textbox.objects.outline = create("Square", {
                    Size = Vector2.new(tbWidth, 20),
                    Position = window.pos + Vector2.new(baseX, section.contentY + offset),
                    Color = t.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 9
                })

                -- Background
                textbox.objects.bg = create("Square", {
                    Size = Vector2.new(tbWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, section.contentY + offset + 1),
                    Color = t.elementbg,
                    Filled = true,
                    Thickness = 0,
                    Visible = section.visible,
                    ZIndex = 10
                })

                -- Text
                textbox.objects.text = create("Text", {
                    Text = default ~= "" and default or placeholder,
                    Size = 13,
                    Font = 2,
                    Color = default ~= "" and t.text or t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 6, section.contentY + offset + 3),
                    Visible = section.visible,
                    ZIndex = 11
                })

                -- Label (right side)
                textbox.objects.label = create("Text", {
                    Text = textboxName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + tbWidth + 6, section.contentY + offset + 3),
                    Visible = section.visible,
                    ZIndex = 9
                })

                textbox.baseX = baseX
                textbox.baseY = section.contentY + offset
                textbox.width = tbWidth
                textbox.placeholder = placeholder

                function textbox:UpdatePositions()
                    local p = window.pos
                    textbox.objects.outline.Position = p + Vector2.new(textbox.baseX, textbox.baseY)
                    textbox.objects.bg.Position = p + Vector2.new(textbox.baseX + 1, textbox.baseY + 1)
                    textbox.objects.text.Position = p + Vector2.new(textbox.baseX + 6, textbox.baseY + 3)
                    textbox.objects.label.Position = p + Vector2.new(textbox.baseX + textbox.width + 6, textbox.baseY + 3)
                end

                function textbox:SetVisible(state)
                    for _, obj in pairs(textbox.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function textbox:Set(value)
                    textbox.value = value
                    textbox.objects.text.Text = value ~= "" and value or placeholder
                    textbox.objects.text.Color = value ~= "" and t.text or t.dimtext
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function textbox:Get() return textbox.value end

                -- Focus handling
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        local pos = textbox.objects.outline.Position
                        if mouseOver(pos.X, pos.Y, textbox.width, 20) then
                            textbox.focused = true
                            textbox.objects.outline.Color = a
                            textbox.objects.text.Text = textbox.value
                            textbox.objects.text.Color = t.text
                        else
                            if textbox.focused then
                                textbox.focused = false
                                textbox.objects.outline.Color = t.outline
                                if textbox.value == "" then
                                    textbox.objects.text.Text = placeholder
                                    textbox.objects.text.Color = t.dimtext
                                end
                            end
                        end
                    end

                    if textbox.focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode
                        if key == Enum.KeyCode.Backspace then
                            textbox.value = textbox.value:sub(1, -2)
                        elseif key == Enum.KeyCode.Return then
                            textbox.focused = false
                            textbox.objects.outline.Color = t.outline
                            pcall(callback, textbox.value)
                        elseif key == Enum.KeyCode.Space then
                            textbox.value = textbox.value .. " "
                        else
                            local char = UIS:GetStringForKeyCode(key)
                            if char and #char == 1 then
                                local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
                                textbox.value = textbox.value .. (shift and char:upper() or char:lower())
                            end
                        end
                        textbox.objects.text.Text = textbox.value ~= "" and textbox.value or placeholder
                        textbox.objects.text.Color = textbox.value ~= "" and t.text or t.dimtext
                        if flag then library.flags[flag] = textbox.value end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = textbox
                end

                if side == "left" then
                    section.leftOffset = section.leftOffset + 26
                else
                    section.rightOffset = section.rightOffset + 26
                end
                table.insert(elements, textbox)
                return textbox
            end

            -- Click handler for section button
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

    -- Dragging
    table.insert(library.connections, UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
            local pos = window.pos
            if mouseOver(pos.X, pos.Y, sizeX, 24) then
                window.dragging = true
                local mouse = UIS:GetMouseLocation()
                window.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
            end

            -- Tab clicks
            for _, page in pairs(window.pages) do
                local tabPos = page.objects.tabText.Position
                if mouseOver(tabPos.X - 6, tabPos.Y - 3, page.tabWidth, 20) then
                    page:Show()
                end
            end
        end

        -- Toggle key
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
            local mouse = UIS:GetMouseLocation()
            window.pos = Vector2.new(mouse.X - window.dragOffset.X, mouse.Y - window.dragOffset.Y)
            window:UpdatePositions()
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
