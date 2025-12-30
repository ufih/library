--[[
    NexusLib v2 - Drawing UI Library
    Clean rewrite with fixed positioning
]]

local library = {
    drawings = {},
    connections = {},
    flags = {},
    pointers = {},
    theme = {
        accent = Color3.fromRGB(134, 87, 255),
        background = Color3.fromRGB(25, 25, 25),
        topbar = Color3.fromRGB(30, 30, 30),
        section = Color3.fromRGB(22, 22, 22),
        outline = Color3.fromRGB(0, 0, 0),
        inline = Color3.fromRGB(50, 50, 50),
        text = Color3.fromRGB(255, 255, 255),
        dimtext = Color3.fromRGB(180, 180, 180)
    }
}

-- Services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Drawing helper
local function create(class, props)
    local drawing = Drawing.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() drawing[k] = v end)
    end
    table.insert(library.drawings, drawing)
    return drawing
end

local function remove(drawing)
    for i, v in pairs(library.drawings) do
        if v == drawing then
            table.remove(library.drawings, i)
            break
        end
    end
    pcall(function() drawing:Remove() end)
end

local function getTextSize(text, size)
    local t = Drawing.new("Text")
    t.Text = text
    t.Size = size or 13
    t.Font = 2
    local bounds = t.TextBounds
    t:Remove()
    return bounds
end

local function isMouseOver(x, y, w, h)
    local mouse = UIS:GetMouseLocation()
    return mouse.X >= x and mouse.X <= x + w and mouse.Y >= y and mouse.Y <= y + h
end

function library:New(config)
    config = config or {}
    local name = config.name or "NexusLib"
    local sizeX = config.sizeX or 550
    local sizeY = config.sizeY or 400

    if config.accent then
        library.theme.accent = config.accent
    end

    local window = {
        position = Vector2.new(100, 100),
        size = Vector2.new(sizeX, sizeY),
        visible = true,
        dragging = false,
        dragOffset = Vector2.new(0, 0),
        pages = {},
        currentPage = nil,
        objects = {},
        toggleKey = Enum.KeyCode.RightShift
    }

    -- Main outline
    window.objects.outline = create("Square", {
        Size = Vector2.new(sizeX, sizeY),
        Position = window.position,
        Color = library.theme.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 1
    })

    -- Accent line
    window.objects.accent = create("Square", {
        Size = Vector2.new(sizeX - 2, 2),
        Position = window.position + Vector2.new(1, 1),
        Color = library.theme.accent,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 2
    })

    -- Main background
    window.objects.background = create("Square", {
        Size = Vector2.new(sizeX - 2, sizeY - 4),
        Position = window.position + Vector2.new(1, 3),
        Color = library.theme.topbar,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 2
    })

    -- Title
    window.objects.title = create("Text", {
        Text = name,
        Size = 13,
        Font = 2,
        Color = library.theme.text,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Position = window.position + Vector2.new(8, 6),
        Visible = true,
        ZIndex = 3
    })

    -- Tab holder outline
    window.objects.tabOutline = create("Square", {
        Size = Vector2.new(120, sizeY - 36),
        Position = window.position + Vector2.new(8, 28),
        Color = library.theme.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 2
    })

    -- Tab holder
    window.objects.tabHolder = create("Square", {
        Size = Vector2.new(118, sizeY - 38),
        Position = window.position + Vector2.new(9, 29),
        Color = library.theme.section,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 3
    })

    -- Content outline
    window.objects.contentOutline = create("Square", {
        Size = Vector2.new(sizeX - 144, sizeY - 36),
        Position = window.position + Vector2.new(136, 28),
        Color = library.theme.outline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 2
    })

    -- Content inline
    window.objects.contentInline = create("Square", {
        Size = Vector2.new(sizeX - 146, sizeY - 38),
        Position = window.position + Vector2.new(137, 29),
        Color = library.theme.inline,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 3
    })

    -- Content background
    window.objects.content = create("Square", {
        Size = Vector2.new(sizeX - 148, sizeY - 40),
        Position = window.position + Vector2.new(138, 30),
        Color = library.theme.section,
        Filled = true,
        Thickness = 0,
        Visible = true,
        ZIndex = 4
    })

    -- Update all positions
    function window:UpdatePositions()
        local pos = window.position
        local objs = window.objects

        objs.outline.Position = pos
        objs.accent.Position = pos + Vector2.new(1, 1)
        objs.background.Position = pos + Vector2.new(1, 3)
        objs.title.Position = pos + Vector2.new(8, 6)
        objs.tabOutline.Position = pos + Vector2.new(8, 28)
        objs.tabHolder.Position = pos + Vector2.new(9, 29)
        objs.contentOutline.Position = pos + Vector2.new(136, 28)
        objs.contentInline.Position = pos + Vector2.new(137, 29)
        objs.content.Position = pos + Vector2.new(138, 30)

        -- Update pages
        for _, page in pairs(window.pages) do
            page:UpdatePositions()
        end
    end

    function window:SetVisible(state)
        window.visible = state
        for _, obj in pairs(window.objects) do
            pcall(function() obj.Visible = state end)
        end
        for _, page in pairs(window.pages) do
            page:SetVisible(state and page == window.currentPage)
        end
    end

    function window:Toggle()
        window:SetVisible(not window.visible)
    end

    -- Page function
    function window:Page(config)
        config = config or {}
        local pageName = config.name or "Page"

        local page = {
            name = pageName,
            visible = false,
            sections = {},
            sectionOffsets = {left = 0, right = 0},
            objects = {},
            window = window
        }

        local tabY = 4
        for i, p in pairs(window.pages) do
            tabY = tabY + 22
        end

        -- Tab outline
        page.objects.tabOutline = create("Square", {
            Size = Vector2.new(110, 20),
            Position = window.position + Vector2.new(13, 33 + tabY - 4),
            Color = library.theme.outline,
            Filled = true,
            Thickness = 0,
            Visible = true,
            ZIndex = 4
        })

        -- Tab background
        page.objects.tabBg = create("Square", {
            Size = Vector2.new(108, 18),
            Position = window.position + Vector2.new(14, 34 + tabY - 4),
            Color = library.theme.topbar,
            Filled = true,
            Thickness = 0,
            Visible = true,
            ZIndex = 5
        })

        -- Tab text
        page.objects.tabText = create("Text", {
            Text = pageName,
            Size = 13,
            Font = 2,
            Color = library.theme.dimtext,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Position = window.position + Vector2.new(68, 36 + tabY - 4),
            Visible = true,
            ZIndex = 6
        })

        page.tabY = tabY

        function page:UpdatePositions()
            local pos = window.position
            page.objects.tabOutline.Position = pos + Vector2.new(13, 33 + page.tabY - 4)
            page.objects.tabBg.Position = pos + Vector2.new(14, 34 + page.tabY - 4)
            page.objects.tabText.Position = pos + Vector2.new(68, 36 + page.tabY - 4)

            for _, section in pairs(page.sections) do
                section:UpdatePositions()
            end
        end

        function page:SetVisible(state)
            page.visible = state
            page.objects.tabBg.Color = state and library.theme.section or library.theme.topbar
            page.objects.tabText.Color = state and library.theme.accent or library.theme.dimtext

            for _, section in pairs(page.sections) do
                section:SetVisible(state)
            end
        end

        function page:Show()
            for _, p in pairs(window.pages) do
                p:SetVisible(false)
            end
            page:SetVisible(true)
            window.currentPage = page
        end

        -- Section function
        function page:Section(config)
            config = config or {}
            local sectionName = config.name or "Section"
            local side = (config.side or "left"):lower()
            local sectionSize = config.size or 180

            local section = {
                name = sectionName,
                side = side,
                size = sectionSize,
                elements = {},
                elementOffset = 18,
                objects = {},
                page = page,
                window = window
            }

            local xOffset = side == "left" and 142 or (142 + (sizeX - 148) / 2 + 4)
            local yOffset = side == "left" and page.sectionOffsets.left or page.sectionOffsets.right
            local sectionWidth = (sizeX - 156) / 2

            section.xOffset = xOffset
            section.yOffset = yOffset
            section.width = sectionWidth

            -- Section outline
            section.objects.outline = create("Square", {
                Size = Vector2.new(sectionWidth, sectionSize),
                Position = window.position + Vector2.new(xOffset, 34 + yOffset),
                Color = library.theme.outline,
                Filled = true,
                Thickness = 0,
                Visible = page.visible,
                ZIndex = 5
            })

            -- Section inline
            section.objects.inline = create("Square", {
                Size = Vector2.new(sectionWidth - 2, sectionSize - 2),
                Position = window.position + Vector2.new(xOffset + 1, 35 + yOffset),
                Color = library.theme.inline,
                Filled = true,
                Thickness = 0,
                Visible = page.visible,
                ZIndex = 6
            })

            -- Section background
            section.objects.background = create("Square", {
                Size = Vector2.new(sectionWidth - 4, sectionSize - 4),
                Position = window.position + Vector2.new(xOffset + 2, 36 + yOffset),
                Color = library.theme.topbar,
                Filled = true,
                Thickness = 0,
                Visible = page.visible,
                ZIndex = 7
            })

            -- Section title background
            local titleWidth = getTextSize(sectionName, 13).X + 6
            section.objects.titleBg = create("Square", {
                Size = Vector2.new(titleWidth, 12),
                Position = window.position + Vector2.new(xOffset + 8, 30 + yOffset),
                Color = library.theme.topbar,
                Filled = true,
                Thickness = 0,
                Visible = page.visible,
                ZIndex = 8
            })

            -- Section title
            section.objects.title = create("Text", {
                Text = sectionName,
                Size = 13,
                Font = 2,
                Color = library.theme.text,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Position = window.position + Vector2.new(xOffset + 11, 29 + yOffset),
                Visible = page.visible,
                ZIndex = 9
            })

            -- Update section offset
            if side == "left" then
                page.sectionOffsets.left = page.sectionOffsets.left + sectionSize + 8
            else
                page.sectionOffsets.right = page.sectionOffsets.right + sectionSize + 8
            end

            function section:UpdatePositions()
                local pos = window.position
                local x = section.xOffset
                local y = section.yOffset
                local w = section.width

                section.objects.outline.Position = pos + Vector2.new(x, 34 + y)
                section.objects.inline.Position = pos + Vector2.new(x + 1, 35 + y)
                section.objects.background.Position = pos + Vector2.new(x + 2, 36 + y)
                section.objects.titleBg.Position = pos + Vector2.new(x + 8, 30 + y)
                section.objects.title.Position = pos + Vector2.new(x + 11, 29 + y)

                for _, elem in pairs(section.elements) do
                    if elem.UpdatePositions then
                        elem:UpdatePositions()
                    end
                end
            end

            function section:SetVisible(state)
                for _, obj in pairs(section.objects) do
                    pcall(function() obj.Visible = state end)
                end
                for _, elem in pairs(section.elements) do
                    if elem.SetVisible then
                        elem:SetVisible(state)
                    end
                end
            end

            -- Toggle
            function section:Toggle(config)
                config = config or {}
                local toggleName = config.name or "Toggle"
                local default = config.default or false
                local flag = config.flag
                local callback = config.callback or function() end

                local toggle = {
                    value = default,
                    yPos = section.elementOffset,
                    objects = {}
                }

                local baseX = section.xOffset + 8
                local baseY = 36 + section.yOffset + section.elementOffset

                -- Checkbox outline
                toggle.objects.outline = create("Square", {
                    Size = Vector2.new(10, 10),
                    Position = window.position + Vector2.new(baseX, baseY),
                    Color = library.theme.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Checkbox fill
                toggle.objects.fill = create("Square", {
                    Size = Vector2.new(8, 8),
                    Position = window.position + Vector2.new(baseX + 1, baseY + 1),
                    Color = default and library.theme.accent or library.theme.section,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 9
                })

                -- Label
                toggle.objects.label = create("Text", {
                    Text = toggleName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX + 16, baseY - 2),
                    Visible = page.visible,
                    ZIndex = 9
                })

                toggle.baseX = baseX
                toggle.baseY = baseY - 36 - section.yOffset

                function toggle:UpdatePositions()
                    local pos = window.position
                    local y = 36 + section.yOffset + toggle.baseY
                    toggle.objects.outline.Position = pos + Vector2.new(toggle.baseX, y)
                    toggle.objects.fill.Position = pos + Vector2.new(toggle.baseX + 1, y + 1)
                    toggle.objects.label.Position = pos + Vector2.new(toggle.baseX + 16, y - 2)
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(toggle.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                function toggle:Set(value)
                    toggle.value = value
                    toggle.objects.fill.Color = value and library.theme.accent or library.theme.section
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function toggle:Get()
                    return toggle.value
                end

                -- Click detection
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.visible and page.visible then
                        local pos = toggle.objects.outline.Position
                        if isMouseOver(pos.X, pos.Y, section.width - 16, 14) then
                            toggle:Set(not toggle.value)
                        end
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = toggle
                end
                if default then pcall(callback, default) end

                section.elementOffset = section.elementOffset + 18
                table.insert(section.elements, toggle)
                return toggle
            end

            -- Button
            function section:Button(config)
                config = config or {}
                local buttonName = config.name or "Button"
                local callback = config.callback or function() end

                local button = {
                    yPos = section.elementOffset,
                    objects = {}
                }

                local baseX = section.xOffset + 8
                local baseY = 36 + section.yOffset + section.elementOffset
                local btnWidth = section.width - 16

                -- Button outline
                button.objects.outline = create("Square", {
                    Size = Vector2.new(btnWidth, 18),
                    Position = window.position + Vector2.new(baseX, baseY),
                    Color = library.theme.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Button inline
                button.objects.inline = create("Square", {
                    Size = Vector2.new(btnWidth - 2, 16),
                    Position = window.position + Vector2.new(baseX + 1, baseY + 1),
                    Color = library.theme.inline,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 9
                })

                -- Button background
                button.objects.bg = create("Square", {
                    Size = Vector2.new(btnWidth - 4, 14),
                    Position = window.position + Vector2.new(baseX + 2, baseY + 2),
                    Color = library.theme.topbar,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 10
                })

                -- Button text
                button.objects.label = create("Text", {
                    Text = buttonName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Center = true,
                    Position = window.position + Vector2.new(baseX + btnWidth/2, baseY + 2),
                    Visible = page.visible,
                    ZIndex = 11
                })

                button.baseX = baseX
                button.baseY = baseY - 36 - section.yOffset
                button.width = btnWidth

                function button:UpdatePositions()
                    local pos = window.position
                    local y = 36 + section.yOffset + button.baseY
                    button.objects.outline.Position = pos + Vector2.new(button.baseX, y)
                    button.objects.inline.Position = pos + Vector2.new(button.baseX + 1, y + 1)
                    button.objects.bg.Position = pos + Vector2.new(button.baseX + 2, y + 2)
                    button.objects.label.Position = pos + Vector2.new(button.baseX + button.width/2, y + 2)
                end

                function button:SetVisible(state)
                    for _, obj in pairs(button.objects) do
                        pcall(function() obj.Visible = state end)
                    end
                end

                -- Click detection
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.visible and page.visible then
                        local pos = button.objects.outline.Position
                        if isMouseOver(pos.X, pos.Y, btnWidth, 18) then
                            button.objects.bg.Color = library.theme.section
                            pcall(callback)
                            task.delay(0.1, function()
                                button.objects.bg.Color = library.theme.topbar
                            end)
                        end
                    end
                end))

                section.elementOffset = section.elementOffset + 24
                table.insert(section.elements, button)
                return button
            end

            -- Slider
            function section:Slider(config)
                config = config or {}
                local sliderName = config.name or "Slider"
                local min = config.min or 0
                local max = config.max or 100
                local default = config.default or min
                local increment = config.increment or 1
                local flag = config.flag
                local callback = config.callback or function() end

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    yPos = section.elementOffset,
                    objects = {}
                }

                local baseX = section.xOffset + 8
                local baseY = 36 + section.yOffset + section.elementOffset
                local sliderWidth = section.width - 16

                -- Label
                slider.objects.label = create("Text", {
                    Text = sliderName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX, baseY),
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Value text
                slider.objects.value = create("Text", {
                    Text = tostring(default),
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX + sliderWidth - getTextSize(tostring(default), 13).X, baseY),
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Slider outline
                slider.objects.outline = create("Square", {
                    Size = Vector2.new(sliderWidth, 12),
                    Position = window.position + Vector2.new(baseX, baseY + 16),
                    Color = library.theme.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Slider background
                slider.objects.bg = create("Square", {
                    Size = Vector2.new(sliderWidth - 2, 10),
                    Position = window.position + Vector2.new(baseX + 1, baseY + 17),
                    Color = library.theme.section,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 9
                })

                -- Slider fill
                local percent = (default - min) / (max - min)
                slider.objects.fill = create("Square", {
                    Size = Vector2.new((sliderWidth - 2) * percent, 10),
                    Position = window.position + Vector2.new(baseX + 1, baseY + 17),
                    Color = library.theme.accent,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 10
                })

                slider.baseX = baseX
                slider.baseY = baseY - 36 - section.yOffset
                slider.width = sliderWidth

                function slider:UpdatePositions()
                    local pos = window.position
                    local y = 36 + section.yOffset + slider.baseY
                    slider.objects.label.Position = pos + Vector2.new(slider.baseX, y)
                    slider.objects.value.Position = pos + Vector2.new(slider.baseX + slider.width - getTextSize(tostring(slider.value), 13).X, y)
                    slider.objects.outline.Position = pos + Vector2.new(slider.baseX, y + 16)
                    slider.objects.bg.Position = pos + Vector2.new(slider.baseX + 1, y + 17)
                    slider.objects.fill.Position = pos + Vector2.new(slider.baseX + 1, y + 17)
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
                    slider.objects.fill.Size = Vector2.new((slider.width - 2) * pct, 10)
                    slider.objects.value.Text = tostring(value)
                    slider.objects.value.Position = window.position + Vector2.new(slider.baseX + slider.width - getTextSize(tostring(value), 13).X, 36 + section.yOffset + slider.baseY)

                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function slider:Get()
                    return slider.value
                end

                -- Drag detection
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.visible and page.visible then
                        local pos = slider.objects.outline.Position
                        if isMouseOver(pos.X, pos.Y, slider.width, 12) then
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
                    if slider.dragging and window.visible then
                        local mouse = UIS:GetMouseLocation()
                        local pos = slider.objects.outline.Position
                        local pct = math.clamp((mouse.X - pos.X) / slider.width, 0, 1)
                        local value = min + (max - min) * pct
                        slider:Set(value)
                    end
                end))

                if flag then
                    library.flags[flag] = default
                    library.pointers[flag] = slider
                end

                section.elementOffset = section.elementOffset + 36
                table.insert(section.elements, slider)
                return slider
            end

            -- Dropdown
            function section:Dropdown(config)
                config = config or {}
                local dropdownName = config.name or "Dropdown"
                local items = config.items or {}
                local default = config.default or (items[1] or "")
                local flag = config.flag
                local callback = config.callback or function() end

                local dropdown = {
                    value = default,
                    items = items,
                    open = false,
                    yPos = section.elementOffset,
                    objects = {},
                    itemObjects = {}
                }

                local baseX = section.xOffset + 8
                local baseY = 36 + section.yOffset + section.elementOffset
                local ddWidth = section.width - 16

                -- Label
                dropdown.objects.label = create("Text", {
                    Text = dropdownName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX, baseY),
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Dropdown outline
                dropdown.objects.outline = create("Square", {
                    Size = Vector2.new(ddWidth, 18),
                    Position = window.position + Vector2.new(baseX, baseY + 16),
                    Color = library.theme.outline,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Dropdown background
                dropdown.objects.bg = create("Square", {
                    Size = Vector2.new(ddWidth - 2, 16),
                    Position = window.position + Vector2.new(baseX + 1, baseY + 17),
                    Color = library.theme.topbar,
                    Filled = true,
                    Thickness = 0,
                    Visible = page.visible,
                    ZIndex = 9
                })

                -- Selected text
                dropdown.objects.selected = create("Text", {
                    Text = default,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX + 4, baseY + 18),
                    Visible = page.visible,
                    ZIndex = 10
                })

                -- Arrow
                dropdown.objects.arrow = create("Text", {
                    Text = "v",
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX + ddWidth - 12, baseY + 18),
                    Visible = page.visible,
                    ZIndex = 10
                })

                dropdown.baseX = baseX
                dropdown.baseY = baseY - 36 - section.yOffset
                dropdown.width = ddWidth

                function dropdown:UpdatePositions()
                    local pos = window.position
                    local y = 36 + section.yOffset + dropdown.baseY
                    dropdown.objects.label.Position = pos + Vector2.new(dropdown.baseX, y)
                    dropdown.objects.outline.Position = pos + Vector2.new(dropdown.baseX, y + 16)
                    dropdown.objects.bg.Position = pos + Vector2.new(dropdown.baseX + 1, y + 17)
                    dropdown.objects.selected.Position = pos + Vector2.new(dropdown.baseX + 4, y + 18)
                    dropdown.objects.arrow.Position = pos + Vector2.new(dropdown.baseX + dropdown.width - 12, y + 18)
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
                    local listHeight = #items * 16 + 4

                    -- List background
                    local listBg = create("Square", {
                        Size = Vector2.new(dropdown.width, listHeight),
                        Position = Vector2.new(pos.X, pos.Y + 20),
                        Color = library.theme.section,
                        Filled = true,
                        Thickness = 0,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(dropdown.itemObjects, listBg)

                    -- List outline
                    local listOutline = create("Square", {
                        Size = Vector2.new(dropdown.width, listHeight),
                        Position = Vector2.new(pos.X, pos.Y + 20),
                        Color = library.theme.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 51
                    })
                    table.insert(dropdown.itemObjects, listOutline)

                    -- Items
                    for i, item in ipairs(items) do
                        local itemText = create("Text", {
                            Text = item,
                            Size = 13,
                            Font = 2,
                            Color = item == dropdown.value and library.theme.accent or library.theme.text,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = Vector2.new(pos.X + 4, pos.Y + 22 + (i-1) * 16),
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

                function dropdown:Get()
                    return dropdown.value
                end

                -- Click detection
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.visible and page.visible then
                        local pos = dropdown.objects.outline.Position

                        -- Main dropdown click
                        if isMouseOver(pos.X, pos.Y, dropdown.width, 18) then
                            dropdown:Open()
                            return
                        end

                        -- Item selection
                        if dropdown.open then
                            for i, item in ipairs(items) do
                                local itemY = pos.Y + 20 + (i-1) * 16
                                if isMouseOver(pos.X, itemY, dropdown.width, 16) then
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

                section.elementOffset = section.elementOffset + 42
                table.insert(section.elements, dropdown)
                return dropdown
            end

            -- Keybind
            function section:Keybind(config)
                config = config or {}
                local keybindName = config.name or "Keybind"
                local default = config.default or Enum.KeyCode.Unknown
                local flag = config.flag
                local callback = config.callback or function() end

                local keybind = {
                    value = default,
                    listening = false,
                    yPos = section.elementOffset,
                    objects = {}
                }

                local keyNames = {
                    [Enum.KeyCode.LeftShift] = "LS",
                    [Enum.KeyCode.RightShift] = "RS",
                    [Enum.KeyCode.LeftControl] = "LC",
                    [Enum.KeyCode.RightControl] = "RC"
                }

                local function getKeyName(key)
                    if keyNames[key] then return keyNames[key] end
                    if typeof(key) == "EnumItem" then return key.Name end
                    return "None"
                end

                local baseX = section.xOffset + 8
                local baseY = 36 + section.yOffset + section.elementOffset

                -- Label
                keybind.objects.label = create("Text", {
                    Text = keybindName,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX, baseY),
                    Visible = page.visible,
                    ZIndex = 8
                })

                -- Key text
                local keyText = "[" .. getKeyName(default) .. "]"
                keybind.objects.key = create("Text", {
                    Text = keyText,
                    Size = 13,
                    Font = 2,
                    Color = library.theme.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.position + Vector2.new(baseX + section.width - 16 - getTextSize(keyText, 13).X, baseY),
                    Visible = page.visible,
                    ZIndex = 8
                })

                keybind.baseX = baseX
                keybind.baseY = baseY - 36 - section.yOffset

                function keybind:UpdatePositions()
                    local pos = window.position
                    local y = 36 + section.yOffset + keybind.baseY
                    local keyText = "[" .. getKeyName(keybind.value) .. "]"
                    keybind.objects.label.Position = pos + Vector2.new(keybind.baseX, y)
                    keybind.objects.key.Position = pos + Vector2.new(keybind.baseX + section.width - 16 - getTextSize(keyText, 13).X, y)
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
                    keybind.objects.key.Position = window.position + Vector2.new(keybind.baseX + section.width - 16 - getTextSize(keyText, 13).X, 36 + section.yOffset + keybind.baseY)
                    if flag then library.flags[flag] = key end
                end

                function keybind:Get()
                    return keybind.value
                end

                -- Input detection
                table.insert(library.connections, UIS.InputBegan:Connect(function(input)
                    if keybind.listening then
                        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                        if key == Enum.KeyCode.Escape then
                            key = Enum.KeyCode.Unknown
                        end
                        keybind:Set(key)
                        keybind.listening = false
                        keybind.objects.key.Color = library.theme.dimtext
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.visible and page.visible then
                        local pos = keybind.objects.label.Position
                        if isMouseOver(pos.X, pos.Y, section.width - 16, 14) then
                            keybind.listening = true
                            keybind.objects.key.Color = library.theme.accent
                        end
                    end

                    -- Callback when key pressed
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

                section.elementOffset = section.elementOffset + 18
                table.insert(section.elements, keybind)
                return keybind
            end

            table.insert(page.sections, section)
            return section
        end

        table.insert(window.pages, page)
        return page
    end

    -- Dragging
    table.insert(library.connections, UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and window.visible then
            local pos = window.position
            if isMouseOver(pos.X, pos.Y, sizeX, 25) then
                window.dragging = true
                local mouse = UIS:GetMouseLocation()
                window.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
            end

            -- Tab clicks
            for _, page in pairs(window.pages) do
                local tabPos = page.objects.tabOutline.Position
                if isMouseOver(tabPos.X, tabPos.Y, 110, 20) then
                    page:Show()
                end
            end
        end

        -- Toggle key
        if input.KeyCode == window.toggleKey then
            window:Toggle()
        end
    end))

    table.insert(library.connections, UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
        end
    end))

    table.insert(library.connections, RS.RenderStepped:Connect(function()
        if window.dragging and window.visible then
            local mouse = UIS:GetMouseLocation()
            window.position = Vector2.new(mouse.X - window.dragOffset.X, mouse.Y - window.dragOffset.Y)
            window:UpdatePositions()
        end
    end))

    -- Initialize
    function window:Init()
        if window.pages[1] then
            window.pages[1]:Show()
        end
    end

    -- Unload
    function window:Unload()
        for _, conn in pairs(library.connections) do
            pcall(function() conn:Disconnect() end)
        end
        for _, drawing in pairs(library.drawings) do
            pcall(function() drawing:Remove() end)
        end
        library.drawings = {}
        library.connections = {}
    end

    return window
end

return library
