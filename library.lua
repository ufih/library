--[[
    NexusLib v3.2 - Seliware Compatible
    Fixed return statement and Drawing checks
]]

local library = {}
library.drawings = {}
library.connections = {}
library.flags = {}
library.pointers = {}
library.open = true
library.accent = Color3.fromRGB(76, 162, 252)
library.theme = {
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

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local function create(class, props)
    local success, obj = pcall(function()
        return Drawing.new(class)
    end)
    if not success or not obj then
        return nil
    end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    table.insert(library.drawings, obj)
    return obj
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
    if success and result then return result end
    return Vector2.new(#(text or "") * 7, 13)
end

local function mouseOver(x, y, w, h)
    local success, m = pcall(function()
        return UIS:GetMouseLocation()
    end)
    if not success or not m then return false end
    return m.X >= x and m.X <= x + w and m.Y >= y and m.Y <= y + h
end

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

    -- Create main window drawings
    window.objects.outline = create("Square", {
        Size = window.size,
        Position = window.pos,
        Color = t.outline,
        Filled = true,
        Visible = true,
        ZIndex = 1
    })

    window.objects.bg = create("Square", {
        Size = Vector2.new(sizeX - 2, sizeY - 2),
        Position = window.pos + Vector2.new(1, 1),
        Color = t.background,
        Filled = true,
        Visible = true,
        ZIndex = 2
    })

    window.objects.topbar = create("Square", {
        Size = Vector2.new(sizeX - 4, 22),
        Position = window.pos + Vector2.new(2, 2),
        Color = t.topbar,
        Filled = true,
        Visible = true,
        ZIndex = 3
    })

    window.objects.accentLine = create("Square", {
        Size = Vector2.new(sizeX - 4, 1),
        Position = window.pos + Vector2.new(2, 24),
        Color = a,
        Filled = true,
        Visible = true,
        ZIndex = 4
    })

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

    window.objects.contentOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, sizeY - 50),
        Position = window.pos + Vector2.new(2, 26),
        Color = t.outline,
        Filled = true,
        Visible = true,
        ZIndex = 3
    })

    window.objects.content = create("Square", {
        Size = Vector2.new(sizeX - 6, sizeY - 52),
        Position = window.pos + Vector2.new(3, 27),
        Color = t.section,
        Filled = true,
        Visible = true,
        ZIndex = 4
    })

    window.objects.sidebarOutline = create("Square", {
        Size = Vector2.new(112, sizeY - 54),
        Position = window.pos + Vector2.new(4, 28),
        Color = t.outline,
        Filled = true,
        Visible = true,
        ZIndex = 5
    })

    window.objects.sidebar = create("Square", {
        Size = Vector2.new(110, sizeY - 56),
        Position = window.pos + Vector2.new(5, 29),
        Color = t.sidebar,
        Filled = true,
        Visible = true,
        ZIndex = 6
    })

    window.objects.bottomOutline = create("Square", {
        Size = Vector2.new(sizeX - 4, 22),
        Position = window.pos + Vector2.new(2, sizeY - 24),
        Color = t.outline,
        Filled = true,
        Visible = true,
        ZIndex = 3
    })

    window.objects.bottombar = create("Square", {
        Size = Vector2.new(sizeX - 6, 20),
        Position = window.pos + Vector2.new(3, sizeY - 23),
        Color = t.topbar,
        Filled = true,
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
        local p = self.pos
        local o = self.objects
        if o.outline then o.outline.Position = p end
        if o.bg then o.bg.Position = p + Vector2.new(1, 1) end
        if o.topbar then o.topbar.Position = p + Vector2.new(2, 2) end
        if o.accentLine then o.accentLine.Position = p + Vector2.new(2, 24) end
        if o.title then o.title.Position = p + Vector2.new(8, 5) end
        if o.contentOutline then o.contentOutline.Position = p + Vector2.new(2, 26) end
        if o.content then o.content.Position = p + Vector2.new(3, 27) end
        if o.sidebarOutline then o.sidebarOutline.Position = p + Vector2.new(4, 28) end
        if o.sidebar then o.sidebar.Position = p + Vector2.new(5, 29) end
        if o.bottomOutline then o.bottomOutline.Position = p + Vector2.new(2, sizeY - 24) end
        if o.bottombar then o.bottombar.Position = p + Vector2.new(3, sizeY - 23) end
        if o.version then o.version.Position = p + Vector2.new(8, sizeY - 20) end

        for _, page in pairs(self.pages) do
            if page and page.UpdatePositions then page:UpdatePositions() end
        end
    end

    function window:SetVisible(state)
        library.open = state
        for _, obj in pairs(self.objects) do
            if obj then pcall(function() obj.Visible = state end) end
        end
        for _, page in pairs(self.pages) do
            if page and page.SetVisible then
                page:SetVisible(state and page == self.currentPage)
            end
        end
    end

    function window:Toggle()
        self:SetVisible(not library.open)
    end

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
            if self.objects.tabBg then self.objects.tabBg.Position = p + Vector2.new(self.tabX, 4) end
            if self.objects.tabAccent then self.objects.tabAccent.Position = p + Vector2.new(self.tabX + 2, 5) end
            if self.objects.tabText then self.objects.tabText.Position = p + Vector2.new(self.tabX + 6, 7) end

            for _, btn in pairs(self.sectionButtons) do
                if btn and btn.UpdatePositions then btn:UpdatePositions() end
            end
            for _, section in pairs(self.sections) do
                if section and section.UpdatePositions then section:UpdatePositions() end
            end
        end

        function page:SetVisible(state)
            self.visible = state
            if self.objects.tabBg then self.objects.tabBg.Visible = state end
            if self.objects.tabAccent then self.objects.tabAccent.Visible = state end
            if self.objects.tabText then self.objects.tabText.Color = state and library.accent or t.dimtext end

            for _, btn in pairs(self.sectionButtons) do
                if btn and btn.SetVisible then btn:SetVisible(state) end
            end
            for _, section in pairs(self.sections) do
                if section and section.SetVisible then
                    section:SetVisible(state and section == self.currentSection)
                end
            end
        end

        function page:Show()
            for _, p in pairs(window.pages) do
                if p and p.SetVisible then p:SetVisible(false) end
            end
            self:SetVisible(true)
            window.currentPage = self

            if self.currentSection then
                self.currentSection:SetVisible(true)
            elseif self.sections[1] then
                self.sections[1]:Show()
            end
        end

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
                if self.objects.accent then self.objects.accent.Position = p + Vector2.new(6, 30 + self.yOffset) end
                if self.objects.text then self.objects.text.Position = p + Vector2.new(14, 32 + self.yOffset) end
            end

            function sectionBtn:SetVisible(state)
                if self.objects.accent then self.objects.accent.Visible = state and section == page.currentSection end
                if self.objects.text then 
                    self.objects.text.Visible = state 
                    self.objects.text.Color = (section == page.currentSection) and Color3.new(1,1,1) or t.dimtext
                end
            end

            table.insert(page.sectionButtons, sectionBtn)
            section.button = sectionBtn

            local contentX = 120
            local contentWidth = (sizeX - 130) / 2 - 8
            local contentY = 30
            local rightX = contentX + contentWidth + 10

            section.objects.leftOutline = create("Square", {
                Size = Vector2.new(contentWidth + 2, sizeY - 84),
                Position = window.pos + Vector2.new(contentX, contentY),
                Color = t.outline,
                Filled = true,
                Visible = false,
                ZIndex = 5
            })

            section.objects.left = create("Square", {
                Size = Vector2.new(contentWidth, sizeY - 86),
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

            section.objects.rightOutline = create("Square", {
                Size = Vector2.new(contentWidth + 2, sizeY - 84),
                Position = window.pos + Vector2.new(rightX, contentY),
                Color = t.outline,
                Filled = true,
                Visible = false,
                ZIndex = 5
            })

            section.objects.right = create("Square", {
                Size = Vector2.new(contentWidth, sizeY - 86),
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

            function section:UpdatePositions()
                local p = window.pos
                local cX, rX, cY = self.contentX, self.rightX, self.contentY

                if self.objects.leftOutline then self.objects.leftOutline.Position = p + Vector2.new(cX, cY) end
                if self.objects.left then self.objects.left.Position = p + Vector2.new(cX + 1, cY + 1) end
                if self.objects.leftHeader then self.objects.leftHeader.Position = p + Vector2.new(cX + 1, cY + 1) end
                if self.objects.leftHeaderLine then self.objects.leftHeaderLine.Position = p + Vector2.new(cX + 1, cY + 21) end
                if self.objects.leftTitle then self.objects.leftTitle.Position = p + Vector2.new(cX + 8, cY + 4) end
                if self.objects.rightOutline then self.objects.rightOutline.Position = p + Vector2.new(rX, cY) end
                if self.objects.right then self.objects.right.Position = p + Vector2.new(rX + 1, cY + 1) end
                if self.objects.rightHeader then self.objects.rightHeader.Position = p + Vector2.new(rX + 1, cY + 1) end
                if self.objects.rightHeaderLine then self.objects.rightHeaderLine.Position = p + Vector2.new(rX + 1, cY + 21) end
                if self.objects.rightTitle then self.objects.rightTitle.Position = p + Vector2.new(rX + 8, cY + 4) end

                for _, elem in pairs(self.leftElements) do
                    if elem and elem.UpdatePositions then elem:UpdatePositions() end
                end
                for _, elem in pairs(self.rightElements) do
                    if elem and elem.UpdatePositions then elem:UpdatePositions() end
                end
            end

            function section:SetVisible(state)
                self.visible = state
                for _, obj in pairs(self.objects) do
                    if obj then pcall(function() obj.Visible = state end) end
                end
                if self.button then
                    if self.button.objects.accent then self.button.objects.accent.Visible = state end
                    if self.button.objects.text then 
                        self.button.objects.text.Color = state and Color3.new(1,1,1) or t.dimtext 
                    end
                end

                for _, elem in pairs(self.leftElements) do
                    if elem and elem.SetVisible then elem:SetVisible(state) end
                end
                for _, elem in pairs(self.rightElements) do
                    if elem and elem.SetVisible then elem:SetVisible(state) end
                end
            end

            function section:Show()
                for _, s in pairs(page.sections) do
                    if s and s.SetVisible then s:SetVisible(false) end
                end
                self:SetVisible(true)
                page.currentSection = self
            end

            -- TOGGLE
            function section:Toggle(config)
                config = config or {}
                local toggleName = config.name or "Toggle"
                local side = (config.side or "left"):lower()
                local default = config.default or false
                local flag = config.flag
                local callback = config.callback or function() end

                local elements = side == "left" and self.leftElements or self.rightElements
                local offset = side == "left" and self.leftOffset or self.rightOffset
                local baseX = side == "left" and (self.contentX + 10) or (self.rightX + 10)
                local elemWidth = self.contentWidth - 20

                local toggle = {
                    value = default,
                    side = side,
                    yOffset = offset,
                    baseX = baseX,
                    baseY = self.contentY + offset,
                    width = elemWidth,
                    objects = {}
                }

                toggle.objects.box = create("Square", {
                    Size = Vector2.new(6, 6),
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset + 4),
                    Color = t.outline,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 9
                })

                toggle.objects.fill = create("Square", {
                    Size = Vector2.new(4, 4),
                    Position = window.pos + Vector2.new(baseX + 1, self.contentY + offset + 5),
                    Color = default and a or t.elementbg,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 10
                })

                toggle.objects.label = create("Text", {
                    Text = toggleName,
                    Size = 13,
                    Font = 2,
                    Color = default and t.text or t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 15, self.contentY + offset + 1),
                    Visible = self.visible,
                    ZIndex = 9
                })

                function toggle:UpdatePositions()
                    local p = window.pos
                    if self.objects.box then self.objects.box.Position = p + Vector2.new(self.baseX, self.baseY + 4) end
                    if self.objects.fill then self.objects.fill.Position = p + Vector2.new(self.baseX + 1, self.baseY + 5) end
                    if self.objects.label then self.objects.label.Position = p + Vector2.new(self.baseX + 15, self.baseY + 1) end
                end

                function toggle:SetVisible(state)
                    for _, obj in pairs(self.objects) do
                        if obj then pcall(function() obj.Visible = state end) end
                    end
                end

                function toggle:Set(value)
                    self.value = value
                    if self.objects.fill then self.objects.fill.Color = value and a or t.elementbg end
                    if self.objects.label then self.objects.label.Color = value and t.text or t.dimtext end
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function toggle:Get() return self.value end

                local conn = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        if toggle.objects.box then
                            local pos = toggle.objects.box.Position
                            if mouseOver(pos.X - 2, pos.Y - 2, toggle.width, 14) then
                                toggle:Set(not toggle.value)
                            end
                        end
                    end
                end)
                table.insert(library.connections, conn)

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

                local elements = side == "left" and self.leftElements or self.rightElements
                local offset = side == "left" and self.leftOffset or self.rightOffset
                local baseX = side == "left" and (self.contentX + 10) or (self.rightX + 10)
                local sliderWidth = self.contentWidth - 20

                local slider = {
                    value = default,
                    min = min,
                    max = max,
                    dragging = false,
                    side = side,
                    yOffset = offset,
                    baseX = baseX,
                    baseY = self.contentY + offset,
                    width = sliderWidth,
                    suffix = suffix,
                    objects = {}
                }

                slider.objects.label = create("Text", {
                    Text = sliderName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset),
                    Visible = self.visible,
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
                    Position = window.pos + Vector2.new(baseX + sliderWidth - textBounds(valText, 13).X, self.contentY + offset),
                    Visible = self.visible,
                    ZIndex = 9
                })

                slider.objects.trackOutline = create("Square", {
                    Size = Vector2.new(sliderWidth, 10),
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 9
                })

                slider.objects.track = create("Square", {
                    Size = Vector2.new(sliderWidth - 2, 8),
                    Position = window.pos + Vector2.new(baseX + 1, self.contentY + offset + 17),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 10
                })

                local pct = (default - min) / (max - min)
                slider.objects.fill = create("Square", {
                    Size = Vector2.new(math.max((sliderWidth - 2) * pct, 0), 8),
                    Position = window.pos + Vector2.new(baseX + 1, self.contentY + offset + 17),
                    Color = a,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 11
                })

                function slider:UpdatePositions()
                    local p = window.pos
                    local valText = tostring(self.value) .. self.suffix
                    if self.objects.label then self.objects.label.Position = p + Vector2.new(self.baseX, self.baseY) end
                    if self.objects.value then self.objects.value.Position = p + Vector2.new(self.baseX + self.width - textBounds(valText, 13).X, self.baseY) end
                    if self.objects.trackOutline then self.objects.trackOutline.Position = p + Vector2.new(self.baseX, self.baseY + 16) end
                    if self.objects.track then self.objects.track.Position = p + Vector2.new(self.baseX + 1, self.baseY + 17) end
                    if self.objects.fill then self.objects.fill.Position = p + Vector2.new(self.baseX + 1, self.baseY + 17) end
                end

                function slider:SetVisible(state)
                    for _, obj in pairs(self.objects) do
                        if obj then pcall(function() obj.Visible = state end) end
                    end
                end

                function slider:Set(value)
                    value = math.clamp(value, min, max)
                    value = math.floor(value / increment + 0.5) * increment
                    self.value = value

                    local pct = (value - min) / (max - min)
                    if self.objects.fill then self.objects.fill.Size = Vector2.new(math.max((self.width - 2) * pct, 0), 8) end

                    local valText = tostring(value) .. self.suffix
                    if self.objects.value then 
                        self.objects.value.Text = valText
                        self.objects.value.Position = window.pos + Vector2.new(self.baseX + self.width - textBounds(valText, 13).X, self.baseY)
                    end

                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function slider:Get() return self.value end

                local conn1 = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        if slider.objects.trackOutline then
                            local pos = slider.objects.trackOutline.Position
                            if mouseOver(pos.X, pos.Y, slider.width, 10) then
                                slider.dragging = true
                            end
                        end
                    end
                end)
                table.insert(library.connections, conn1)

                local conn2 = UIS.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        slider.dragging = false
                    end
                end)
                table.insert(library.connections, conn2)

                local conn3 = RS.RenderStepped:Connect(function()
                    if slider.dragging and library.open then
                        local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
                        if success and mouse and slider.objects.trackOutline then
                            local pos = slider.objects.trackOutline.Position
                            local pct = math.clamp((mouse.X - pos.X) / slider.width, 0, 1)
                            slider:Set(min + (max - min) * pct)
                        end
                    end
                end)
                table.insert(library.connections, conn3)

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

                local elements = side == "left" and self.leftElements or self.rightElements
                local offset = side == "left" and self.leftOffset or self.rightOffset
                local baseX = side == "left" and (self.contentX + 10) or (self.rightX + 10)
                local btnWidth = self.contentWidth - 20

                local button = {
                    side = side,
                    yOffset = offset,
                    baseX = baseX,
                    baseY = self.contentY + offset,
                    width = btnWidth,
                    objects = {}
                }

                button.objects.outline = create("Square", {
                    Size = Vector2.new(btnWidth, 20),
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset),
                    Color = t.outline,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 9
                })

                button.objects.bg = create("Square", {
                    Size = Vector2.new(btnWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, self.contentY + offset + 1),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = self.visible,
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
                    Position = window.pos + Vector2.new(baseX + btnWidth/2, self.contentY + offset + 3),
                    Visible = self.visible,
                    ZIndex = 11
                })

                function button:UpdatePositions()
                    local p = window.pos
                    if self.objects.outline then self.objects.outline.Position = p + Vector2.new(self.baseX, self.baseY) end
                    if self.objects.bg then self.objects.bg.Position = p + Vector2.new(self.baseX + 1, self.baseY + 1) end
                    if self.objects.label then self.objects.label.Position = p + Vector2.new(self.baseX + self.width/2, self.baseY + 3) end
                end

                function button:SetVisible(state)
                    for _, obj in pairs(self.objects) do
                        if obj then pcall(function() obj.Visible = state end) end
                    end
                end

                local conn = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        if button.objects.outline then
                            local pos = button.objects.outline.Position
                            if mouseOver(pos.X, pos.Y, button.width, 20) then
                                if button.objects.bg then button.objects.bg.Color = t.inline end
                                pcall(callback)
                                task.delay(0.1, function()
                                    if button.objects.bg then button.objects.bg.Color = t.elementbg end
                                end)
                            end
                        end
                    end
                end)
                table.insert(library.connections, conn)

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

                local elements = side == "left" and self.leftElements or self.rightElements
                local offset = side == "left" and self.leftOffset or self.rightOffset
                local baseX = side == "left" and (self.contentX + 10) or (self.rightX + 10)
                local ddWidth = self.contentWidth - 20

                local dropdown = {
                    value = default,
                    items = items,
                    open = false,
                    side = side,
                    yOffset = offset,
                    baseX = baseX,
                    baseY = self.contentY + offset,
                    width = ddWidth,
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
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset),
                    Visible = self.visible,
                    ZIndex = 9
                })

                dropdown.objects.outline = create("Square", {
                    Size = Vector2.new(ddWidth, 20),
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset + 16),
                    Color = t.outline,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 9
                })

                dropdown.objects.bg = create("Square", {
                    Size = Vector2.new(ddWidth - 2, 18),
                    Position = window.pos + Vector2.new(baseX + 1, self.contentY + offset + 17),
                    Color = t.elementbg,
                    Filled = true,
                    Visible = self.visible,
                    ZIndex = 10
                })

                dropdown.objects.selected = create("Text", {
                    Text = default,
                    Size = 13,
                    Font = 2,
                    Color = t.text,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + 6, self.contentY + offset + 19),
                    Visible = self.visible,
                    ZIndex = 11
                })

                dropdown.objects.arrow = create("Text", {
                    Text = "-",
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX + ddWidth - 12, self.contentY + offset + 19),
                    Visible = self.visible,
                    ZIndex = 11
                })

                function dropdown:UpdatePositions()
                    local p = window.pos
                    if self.objects.label then self.objects.label.Position = p + Vector2.new(self.baseX, self.baseY) end
                    if self.objects.outline then self.objects.outline.Position = p + Vector2.new(self.baseX, self.baseY + 16) end
                    if self.objects.bg then self.objects.bg.Position = p + Vector2.new(self.baseX + 1, self.baseY + 17) end
                    if self.objects.selected then self.objects.selected.Position = p + Vector2.new(self.baseX + 6, self.baseY + 19) end
                    if self.objects.arrow then self.objects.arrow.Position = p + Vector2.new(self.baseX + self.width - 12, self.baseY + 19) end
                end

                function dropdown:SetVisible(state)
                    for _, obj in pairs(self.objects) do
                        if obj then pcall(function() obj.Visible = state end) end
                    end
                    if not state then self:Close() end
                end

                function dropdown:Close()
                    self.open = false
                    for _, obj in pairs(self.itemObjects) do
                        if obj then pcall(function() obj:Remove() end) end
                    end
                    self.itemObjects = {}
                end

                function dropdown:Open()
                    if self.open then
                        self:Close()
                        return
                    end
                    self.open = true

                    if not self.objects.outline then return end
                    local pos = self.objects.outline.Position
                    local listH = math.min(#items * 18 + 4, 150)

                    local listBg = create("Square", {
                        Size = Vector2.new(self.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 22),
                        Color = t.elementbg,
                        Filled = true,
                        Visible = true,
                        ZIndex = 50
                    })
                    table.insert(self.itemObjects, listBg)

                    local listOutline = create("Square", {
                        Size = Vector2.new(self.width, listH),
                        Position = Vector2.new(pos.X, pos.Y + 22),
                        Color = t.outline,
                        Filled = false,
                        Thickness = 1,
                        Visible = true,
                        ZIndex = 51
                    })
                    table.insert(self.itemObjects, listOutline)

                    for i, item in ipairs(items) do
                        local itemText = create("Text", {
                            Text = item,
                            Size = 13,
                            Font = 2,
                            Color = item == self.value and a or t.text,
                            Outline = true,
                            OutlineColor = Color3.new(0, 0, 0),
                            Position = Vector2.new(pos.X + 6, pos.Y + 24 + (i-1) * 18),
                            Visible = true,
                            ZIndex = 52
                        })
                        table.insert(self.itemObjects, itemText)
                    end
                end

                function dropdown:Set(value)
                    self.value = value
                    if self.objects.selected then self.objects.selected.Text = value end
                    if flag then library.flags[flag] = value end
                    pcall(callback, value)
                end

                function dropdown:Get() return self.value end

                local conn = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        if dropdown.objects.outline then
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
                    end
                end)
                table.insert(library.connections, conn)

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

                local elements = side == "left" and self.leftElements or self.rightElements
                local offset = side == "left" and self.leftOffset or self.rightOffset
                local baseX = side == "left" and (self.contentX + 10) or (self.rightX + 10)
                local kbWidth = self.contentWidth - 20

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
                    baseX = baseX,
                    baseY = self.contentY + offset,
                    width = kbWidth,
                    getKeyName = getKeyName,
                    objects = {}
                }

                keybind.objects.label = create("Text", {
                    Text = keybindName,
                    Size = 13,
                    Font = 2,
                    Color = t.dimtext,
                    Outline = true,
                    OutlineColor = Color3.new(0, 0, 0),
                    Position = window.pos + Vector2.new(baseX, self.contentY + offset + 2),
                    Visible = self.visible,
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
                    Position = window.pos + Vector2.new(baseX + kbWidth - textBounds(keyText, 13).X, self.contentY + offset + 2),
                    Visible = self.visible,
                    ZIndex = 9
                })

                function keybind:UpdatePositions()
                    local p = window.pos
                    local keyText = "[" .. self.getKeyName(self.value) .. "]"
                    if self.objects.label then self.objects.label.Position = p + Vector2.new(self.baseX, self.baseY + 2) end
                    if self.objects.key then self.objects.key.Position = p + Vector2.new(self.baseX + self.width - textBounds(keyText, 13).X, self.baseY + 2) end
                end

                function keybind:SetVisible(state)
                    for _, obj in pairs(self.objects) do
                        if obj then pcall(function() obj.Visible = state end) end
                    end
                end

                function keybind:Set(key)
                    self.value = key
                    local keyText = "[" .. getKeyName(key) .. "]"
                    if self.objects.key then 
                        self.objects.key.Text = keyText
                        self.objects.key.Position = window.pos + Vector2.new(self.baseX + self.width - textBounds(keyText, 13).X, self.baseY + 2)
                    end
                    if flag then library.flags[flag] = key end
                end

                function keybind:Get() return self.value end

                local conn = UIS.InputBegan:Connect(function(input)
                    if keybind.listening then
                        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                        if key == Enum.KeyCode.Escape then key = Enum.KeyCode.Unknown end
                        keybind:Set(key)
                        keybind.listening = false
                        if keybind.objects.key then keybind.objects.key.Color = t.dimtext end
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and section.visible then
                        if keybind.objects.label then
                            local pos = keybind.objects.label.Position
                            if mouseOver(pos.X, pos.Y - 2, keybind.width, 18) then
                                keybind.listening = true
                                if keybind.objects.key then keybind.objects.key.Color = a end
                            end
                        end
                    end

                    if keybind.value ~= Enum.KeyCode.Unknown then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(callback, keybind.value)
                        end
                    end
                end)
                table.insert(library.connections, conn)

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

            -- Section button click
            local conn = UIS.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open and page.visible then
                    if sectionBtn.objects.text then
                        local pos = sectionBtn.objects.text.Position
                        if mouseOver(pos.X - 8, pos.Y - 2, 100, 18) then
                            section:Show()
                        end
                    end
                end
            end)
            table.insert(library.connections, conn)

            table.insert(page.sections, section)
            return section
        end

        table.insert(window.pages, page)
        return page
    end

    -- Dragging & Tab clicks
    local conn1 = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and library.open then
            local pos = window.pos
            if mouseOver(pos.X, pos.Y, sizeX, 24) then
                window.dragging = true
                local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
                if success and mouse then
                    window.dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
                end
            end

            for _, page in pairs(window.pages) do
                if page.objects.tabText then
                    local tabPos = page.objects.tabText.Position
                    if mouseOver(tabPos.X - 6, tabPos.Y - 3, page.tabWidth, 20) then
                        page:Show()
                    end
                end
            end
        end

        if input.KeyCode == Enum.KeyCode.RightShift then
            window:Toggle()
        end
    end)
    table.insert(library.connections, conn1)

    local conn2 = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
        end
    end)
    table.insert(library.connections, conn2)

    local conn3 = RS.RenderStepped:Connect(function()
        if window.dragging and library.open then
            local success, mouse = pcall(function() return UIS:GetMouseLocation() end)
            if success and mouse then
                window.pos = Vector2.new(mouse.X - window.dragOffset.X, mouse.Y - window.dragOffset.Y)
                window:UpdatePositions()
            end
        end
    end)
    table.insert(library.connections, conn3)

    function window:Init()
        if self.pages[1] then
            self.pages[1]:Show()
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
