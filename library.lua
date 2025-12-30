--[[
    NexusLib - Drawing-Based UI Library
    Based on Splix/Linux/Deadcell style
    Modern syntax, full executor compatibility
]]

-- Services
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

-- Library Variables
local library = {
    drawings = {},
    hidden = {},
    connections = {},
    pointers = {},
    began = {},
    ended = {},
    changed = {},
    colors = {},
    folders = {
        main = "NexusLib",
        assets = "NexusLib/assets",
        configs = "NexusLib/configs"
    },
    shared = {
        initialized = false,
        fps = 0,
        ping = 0
    },
    flags = {}
}

-- Create folders safely
pcall(function()
    for _, folder in pairs(library.folders) do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
end)

-- Theme
local theme = {
    accent = Color3.fromRGB(134, 87, 255),
    lightcontrast = Color3.fromRGB(30, 30, 30),
    darkcontrast = Color3.fromRGB(22, 22, 22),
    outline = Color3.fromRGB(0, 0, 0),
    inline = Color3.fromRGB(50, 50, 50),
    textcolor = Color3.fromRGB(255, 255, 255),
    textborder = Color3.fromRGB(0, 0, 0),
    cursoroutline = Color3.fromRGB(10, 10, 10),
    font = 2, -- Plex font enum
    textsize = 13
}

-- Utility Functions
local utility = {}

function utility.Size(xScale, xOffset, yScale, yOffset, instance)
    if instance then
        local x = xScale * instance.Size.X + xOffset
        local y = yScale * instance.Size.Y + yOffset
        return Vector2.new(x, y)
    else
        local vx, vy = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
        local x = xScale * vx + xOffset
        local y = yScale * vy + yOffset
        return Vector2.new(x, y)
    end
end

function utility.Position(xScale, xOffset, yScale, yOffset, instance)
    if instance then
        local x = instance.Position.X + xScale * instance.Size.X + xOffset
        local y = instance.Position.Y + yScale * instance.Size.Y + yOffset
        return Vector2.new(x, y)
    else
        local vx, vy = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
        local x = xScale * vx + xOffset
        local y = yScale * vy + yOffset
        return Vector2.new(x, y)
    end
end

function utility.Create(instanceType, instanceOffset, instanceProperties, instanceParent)
    instanceType = instanceType or "Frame"
    instanceOffset = instanceOffset or Vector2.new(0, 0)
    instanceProperties = instanceProperties or {}
    local instanceHidden = false
    local instance = nil

    local success, err = pcall(function()
        if instanceType == "Frame" or instanceType == "frame" then
            instance = Drawing.new("Square")
            instance.Visible = true
            instance.Filled = true
            instance.Thickness = 0
            instance.Color = Color3.fromRGB(255, 255, 255)
            instance.Size = Vector2.new(100, 100)
            instance.Position = Vector2.new(0, 0)
            instance.ZIndex = 1000
            instance.Transparency = library.shared.initialized and 1 or 0
        elseif instanceType == "TextLabel" or instanceType == "textlabel" then
            instance = Drawing.new("Text")
            instance.Font = 2
            instance.Visible = true
            instance.Outline = true
            instance.Center = false
            instance.Color = Color3.fromRGB(255, 255, 255)
            instance.Size = 13
            instance.ZIndex = 1000
            instance.Text = ""
            instance.Transparency = library.shared.initialized and 1 or 0
        elseif instanceType == "Triangle" or instanceType == "triangle" then
            instance = Drawing.new("Triangle")
            instance.Visible = true
            instance.Filled = true
            instance.Thickness = 0
            instance.Color = Color3.fromRGB(255, 255, 255)
            instance.ZIndex = 1000
            instance.Transparency = library.shared.initialized and 1 or 0
        elseif instanceType == "Image" or instanceType == "image" then
            instance = Drawing.new("Image")
            instance.Size = Vector2.new(12, 19)
            instance.Position = Vector2.new(0, 0)
            instance.Visible = true
            instance.ZIndex = 1000
            instance.Transparency = library.shared.initialized and 1 or 0
        elseif instanceType == "Circle" or instanceType == "circle" then
            instance = Drawing.new("Circle")
            instance.Visible = false
            instance.Color = Color3.fromRGB(255, 0, 0)
            instance.Thickness = 1
            instance.NumSides = 30
            instance.Filled = true
            instance.ZIndex = 1000
            instance.Radius = 50
            instance.Transparency = library.shared.initialized and 1 or 0
        elseif instanceType == "Line" or instanceType == "line" then
            instance = Drawing.new("Line")
            instance.Visible = false
            instance.Color = Color3.fromRGB(255, 255, 255)
            instance.Thickness = 1.5
            instance.ZIndex = 1000
            instance.Transparency = library.shared.initialized and 1 or 0
        end
    end)

    if not success or not instance then
        warn("NexusLib: Failed to create drawing - " .. tostring(err))
        return nil
    end

    -- Apply properties safely
    for i, v in pairs(instanceProperties) do
        if i == "Hidden" or i == "hidden" then
            instanceHidden = v
        else
            pcall(function()
                if library.shared.initialized then
                    instance[i] = v
                elseif i ~= "Transparency" then
                    instance[i] = v
                end
            end)
        end
    end

    if not instanceHidden then
        library.drawings[#library.drawings + 1] = {instance, instanceOffset, instanceProperties.Transparency or 1}
    else
        library.hidden[#library.hidden + 1] = {instance, instanceOffset, instanceProperties.Transparency or 1}
    end

    if instanceParent then
        instanceParent[#instanceParent + 1] = instance
    end

    return instance
end

function utility.Remove(instance, hidden)
    if not instance then return end
    library.colors[instance] = nil
    for i, v in pairs(hidden and library.hidden or library.drawings) do
        if v[1] == instance then
            v[1] = nil
            v[2] = nil
            table.remove(hidden and library.hidden or library.drawings, i)
            break
        end
    end
    pcall(function()
        instance:Remove()
    end)
end

function utility.Connection(connectionType, connectionCallback)
    local connection = connectionType:Connect(connectionCallback)
    library.connections[#library.connections + 1] = connection
    return connection
end

function utility.Disconnect(connection)
    for i, v in pairs(library.connections) do
        if v == connection then
            library.connections[i] = nil
            pcall(function() v:Disconnect() end)
        end
    end
end

function utility.MouseLocation()
    return UserInputService:GetMouseLocation()
end

function utility.MouseOverDrawing(values, valuesAdd)
    valuesAdd = valuesAdd or {}
    local v1 = (values[1] or 0) + (valuesAdd[1] or 0)
    local v2 = (values[2] or 0) + (valuesAdd[2] or 0)
    local v3 = (values[3] or 0) + (valuesAdd[3] or 0)
    local v4 = (values[4] or 0) + (valuesAdd[4] or 0)
    local mouseLocation = utility.MouseLocation()
    return mouseLocation.X >= v1 and mouseLocation.X <= v3 and mouseLocation.Y >= v2 and mouseLocation.Y <= v4
end

function utility.GetTextBounds(text, textSize, font)
    local textbounds = Vector2.new(0, 0)
    local textlabel = utility.Create("TextLabel", Vector2.new(0, 0), {
        Text = text,
        Size = textSize,
        Font = font or 2,
        Hidden = true
    })
    if textlabel then
        textbounds = textlabel.TextBounds
        utility.Remove(textlabel, true)
    end
    return textbounds
end

function utility.GetScreenSize()
    return workspace.CurrentCamera.ViewportSize
end

function utility.LoadImage(instance, imageName, imageLink)
    if not instance then return end
    local data
    pcall(function()
        if isfile(library.folders.assets .. "/" .. imageName .. ".png") then
            data = readfile(library.folders.assets .. "/" .. imageName .. ".png")
        else
            if imageLink then
                local success, result = pcall(function()
                    return game:HttpGet(imageLink)
                end)
                if success and result then
                    data = result
                    pcall(function()
                        writefile(library.folders.assets .. "/" .. imageName .. ".png", data)
                    end)
                end
            end
        end
        if data then
            instance.Data = data
        end
    end)
end

function utility.Lerp(instance, instanceTo, instanceTime)
    if not instance then return end
    local currentTime = 0
    local currentIndex = {}
    local connection

    for i, v in pairs(instanceTo) do
        pcall(function()
            currentIndex[i] = instance[i]
        end)
    end

    local function lerp()
        for i, v in pairs(instanceTo) do
            pcall(function()
                if typeof(v) == "number" then
                    instance[i] = currentIndex[i] + (v - currentIndex[i]) * math.min(currentTime / instanceTime, 1)
                elseif typeof(v) == "Color3" then
                    instance[i] = currentIndex[i]:Lerp(v, math.min(currentTime / instanceTime, 1))
                elseif typeof(v) == "Vector2" then
                    instance[i] = currentIndex[i]:Lerp(v, math.min(currentTime / instanceTime, 1))
                end
            end)
        end
    end

    connection = RunService.RenderStepped:Connect(function(delta)
        if currentTime < instanceTime then
            currentTime = currentTime + delta
            lerp()
        else
            for i, v in pairs(instanceTo) do
                pcall(function()
                    instance[i] = v
                end)
            end
            connection:Disconnect()
        end
    end)
end

-- Debug/Logging
function library:Log(message, level)
    level = level or "INFO"
    print("[NexusLib][" .. level .. "] " .. tostring(message))
end

-- Main Library
function library:New(info)
    info = info or {}
    local name = info.name or info.Name or info.title or info.Title or "NexusLib"
    local size = info.size or info.Size or Vector2.new(550, 400)
    local accent = info.accent or info.Accent or info.color or info.Color or theme.accent

    theme.accent = accent

    local window = {
        pages = {},
        isVisible = false,
        uibind = Enum.KeyCode.RightShift,
        currentPage = nil,
        fading = false,
        dragging = false,
        drag = Vector2.new(0, 0),
        currentContent = {
            frame = nil,
            dropdown = nil,
            colorpicker = nil,
            keybind = nil
        }
    }

    -- Main frame
    local mainframe = utility.Create("Frame", Vector2.new(0, 0), {
        Size = utility.Size(0, size.X, 0, size.Y),
        Position = utility.Position(0.5, -size.X/2, 0.5, -size.Y/2),
        Color = theme.outline
    })
    window.mainframe = mainframe
    library.colors[mainframe] = {Color = "outline"}

    -- Accent line at top
    local accentline = utility.Create("Frame", Vector2.new(1, 1), {mainframe}, {
        Size = utility.Size(1, -2, 0, 2, mainframe),
        Position = utility.Position(0, 1, 0, 1, mainframe),
        Color = theme.accent
    })
    library.colors[accentline] = {Color = "accent"}

    -- Inner frame
    local innerframe = utility.Create("Frame", Vector2.new(1, 3), {mainframe}, {
        Size = utility.Size(1, -2, 1, -4, mainframe),
        Position = utility.Position(0, 1, 0, 3, mainframe),
        Color = theme.lightcontrast
    })
    library.colors[innerframe] = {Color = "lightcontrast"}

    -- Title text
    local titletext = utility.Create("TextLabel", Vector2.new(8, 8), {innerframe}, {
        Text = name,
        Size = theme.textsize,
        Font = theme.font,
        Color = theme.textcolor,
        OutlineColor = theme.textborder,
        Position = utility.Position(0, 8, 0, 6, innerframe)
    })
    library.colors[titletext] = {OutlineColor = "textborder", Color = "textcolor"}

    -- Tab holder (left side)
    local tabholderoutline = utility.Create("Frame", Vector2.new(8, 28), {innerframe}, {
        Size = utility.Size(0, 120, 1, -36, innerframe),
        Position = utility.Position(0, 8, 0, 28, innerframe),
        Color = theme.outline
    })
    library.colors[tabholderoutline] = {Color = "outline"}

    local tabholder = utility.Create("Frame", Vector2.new(1, 1), {tabholderoutline}, {
        Size = utility.Size(1, -2, 1, -2, tabholderoutline),
        Position = utility.Position(0, 1, 0, 1, tabholderoutline),
        Color = theme.darkcontrast
    })
    library.colors[tabholder] = {Color = "darkcontrast"}
    window.tabholder = tabholder

    -- Content holder (right side)
    local contentholderoutline = utility.Create("Frame", Vector2.new(136, 28), {innerframe}, {
        Size = utility.Size(1, -144, 1, -36, innerframe),
        Position = utility.Position(0, 136, 0, 28, innerframe),
        Color = theme.outline
    })
    library.colors[contentholderoutline] = {Color = "outline"}

    local contentholderinline = utility.Create("Frame", Vector2.new(1, 1), {contentholderoutline}, {
        Size = utility.Size(1, -2, 1, -2, contentholderoutline),
        Position = utility.Position(0, 1, 0, 1, contentholderoutline),
        Color = theme.inline
    })
    library.colors[contentholderinline] = {Color = "inline"}

    local contentholder = utility.Create("Frame", Vector2.new(1, 1), {contentholderinline}, {
        Size = utility.Size(1, -2, 1, -2, contentholderinline),
        Position = utility.Position(0, 1, 0, 1, contentholderinline),
        Color = theme.darkcontrast
    })
    library.colors[contentholder] = {Color = "darkcontrast"}
    window.contentholder = contentholder

    -- Window functions
    function window:Move(vector)
        for i, v in pairs(library.drawings) do
            if v[1] and v[2] then
                pcall(function()
                    if type(v[2]) == "table" and v[2][2] then
                        v[1].Position = utility.Position(0, v[2][1].X, 0, v[2][1].Y, v[2][2])
                    else
                        v[1].Position = Vector2.new(vector.X + v[2].X, vector.Y + v[2].Y)
                    end
                end)
            end
        end
    end

    function window:CloseContent()
        if window.currentContent.dropdown and window.currentContent.dropdown.open then
            local dropdown = window.currentContent.dropdown
            dropdown.open = false
            for i, v in pairs(dropdown.holder.drawings) do
                utility.Remove(v)
            end
            dropdown.holder.drawings = {}
            window.currentContent.frame = nil
            window.currentContent.dropdown = nil
        elseif window.currentContent.colorpicker and window.currentContent.colorpicker.open then
            local colorpicker = window.currentContent.colorpicker
            colorpicker.open = false
            for i, v in pairs(colorpicker.holder.drawings) do
                utility.Remove(v)
            end
            colorpicker.holder.drawings = {}
            window.currentContent.frame = nil
            window.currentContent.colorpicker = nil
        elseif window.currentContent.keybind and window.currentContent.keybind.open then
            window.currentContent.keybind.open = false
            window.currentContent.frame = nil
            window.currentContent.keybind = nil
        end
    end

    function window:IsOverContent()
        if window.currentContent.frame then
            local success, result = pcall(function()
                return utility.MouseOverDrawing({
                    window.currentContent.frame.Position.X,
                    window.currentContent.frame.Position.Y,
                    window.currentContent.frame.Position.X + window.currentContent.frame.Size.X,
                    window.currentContent.frame.Position.Y + window.currentContent.frame.Size.Y
                })
            end)
            if success then return result end
        end
        return false
    end

    function window:Unload()
        for i, v in pairs(library.connections) do
            pcall(function() v:Disconnect() end)
        end
        for i, v in next, library.hidden do
            pcall(function() v[1]:Remove() end)
        end
        for i, v in pairs(library.drawings) do
            pcall(function() v[1]:Remove() end)
        end
        library.drawings = {}
        library.hidden = {}
        library.connections = {}
        library.began = {}
        library.ended = {}
        library.changed = {}
        UserInputService.MouseIconEnabled = true
        library:Log("UI Unloaded", "INFO")
    end

    function window:Fade()
        window.fading = true
        window.isVisible = not window.isVisible

        for i, v in pairs(library.drawings) do
            if v[1] then
                utility.Lerp(v[1], {Transparency = window.isVisible and (v[3] or 1) or 0}, 0.2)
            end
        end

        if window.cursor then
            pcall(function()
                window.cursor.cursor.Transparency = window.isVisible and 1 or 0
                window.cursor.cursorinline.Transparency = window.isVisible and 1 or 0
            end)
        end

        UserInputService.MouseIconEnabled = not window.isVisible
        window.fading = false
    end

    function window:Cursor()
        window.cursor = {}

        local cursor = utility.Create("Triangle", nil, {
            Color = theme.cursoroutline,
            Thickness = 2.5,
            Filled = false,
            ZIndex = 2000,
            Hidden = true
        })
        window.cursor.cursor = cursor

        local cursorinline = utility.Create("Triangle", nil, {
            Color = theme.accent,
            Filled = true,
            Thickness = 0,
            ZIndex = 2000,
            Hidden = true
        })
        window.cursor.cursorinline = cursorinline

        utility.Connection(RunService.RenderStepped, function()
            if cursor and cursorinline then
                local mouseLocation = utility.MouseLocation()
                pcall(function()
                    cursor.PointA = Vector2.new(mouseLocation.X, mouseLocation.Y)
                    cursor.PointB = Vector2.new(mouseLocation.X + 12, mouseLocation.Y + 4)
                    cursor.PointC = Vector2.new(mouseLocation.X + 4, mouseLocation.Y + 12)
                    cursorinline.PointA = Vector2.new(mouseLocation.X, mouseLocation.Y)
                    cursorinline.PointB = Vector2.new(mouseLocation.X + 12, mouseLocation.Y + 4)
                    cursorinline.PointC = Vector2.new(mouseLocation.X + 4, mouseLocation.Y + 12)
                end)
            end
        end)

        return window.cursor
    end

    function window:Watermark(info)
        window.watermark = {visible = false}
        info = info or {}
        local watermarkname = info.name or info.Name or "NexusLib"

        local textbounds = utility.GetTextBounds(watermarkname .. " | FPS: 000 | Ping: 000", theme.textsize, theme.font)

        local watermarkoutline = utility.Create("Frame", Vector2.new(10, 10), {
            Size = Vector2.new(textbounds.X + 16, 21),
            Position = Vector2.new(10, 10),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.outline,
            Visible = window.watermark.visible
        })
        window.watermark.outline = watermarkoutline

        local watermarkinline = utility.Create("Frame", Vector2.new(1, 1), {watermarkoutline}, {
            Size = Vector2.new(textbounds.X + 14, 19),
            Position = Vector2.new(11, 11),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.inline,
            Visible = window.watermark.visible
        })

        local watermarkframe = utility.Create("Frame", Vector2.new(1, 1), {watermarkinline}, {
            Size = Vector2.new(textbounds.X + 12, 17),
            Position = Vector2.new(12, 12),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.lightcontrast,
            Visible = window.watermark.visible
        })

        local watermarkaccent = utility.Create("Frame", Vector2.new(0, 0), {watermarkframe}, {
            Size = Vector2.new(textbounds.X + 12, 1),
            Position = Vector2.new(12, 12),
            Hidden = true,
            ZIndex = 1011,
            Color = theme.accent,
            Visible = window.watermark.visible
        })

        local watermarktitle = utility.Create("TextLabel", Vector2.new(6, 4), {watermarkoutline}, {
            Text = watermarkname .. " | FPS: 0 | Ping: 0",
            Size = theme.textsize,
            Font = theme.font,
            Color = theme.textcolor,
            OutlineColor = theme.textborder,
            Hidden = true,
            ZIndex = 1012,
            Position = Vector2.new(16, 14),
            Visible = window.watermark.visible
        })

        function window.watermark:SetVisible(state)
            window.watermark.visible = state
            pcall(function()
                watermarkoutline.Visible = state
                watermarkinline.Visible = state
                watermarkframe.Visible = state
                watermarkaccent.Visible = state
                watermarktitle.Visible = state
            end)
        end

        -- FPS/Ping updater
        local frameCount = 0
        task.spawn(function()
            while true do
                library.shared.fps = frameCount
                frameCount = 0
                task.wait(1)
            end
        end)

        utility.Connection(RunService.RenderStepped, function()
            frameCount = frameCount + 1
            pcall(function()
                local ping = "?"
                pcall(function()
                    ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
                end)
                library.shared.ping = ping
                watermarktitle.Text = watermarkname .. " | FPS: " .. tostring(library.shared.fps) .. " | Ping: " .. tostring(library.shared.ping)
            end)
        end)

        return window.watermark
    end

    -- Page creation
    function window:Page(info)
        info = info or {}
        local pagename = info.name or info.Name or info.title or info.Title or "Page"

        local page = {
            open = false,
            sections = {},
            sectionOffset = {left = 0, right = 0},
            window = window
        }

        local tabYOffset = 4
        for i, v in pairs(window.pages) do
            tabYOffset = tabYOffset + 22
        end

        -- Tab button
        local taboutline = utility.Create("Frame", Vector2.new(4, tabYOffset), {tabholder}, {
            Size = Vector2.new(tabholder.Size.X - 8, 20),
            Position = Vector2.new(tabholder.Position.X + 4, tabholder.Position.Y + tabYOffset),
            Color = theme.outline
        })
        page.taboutline = taboutline

        local tabbutton = utility.Create("Frame", Vector2.new(1, 1), {taboutline}, {
            Size = Vector2.new(taboutline.Size.X - 2, 18),
            Position = Vector2.new(taboutline.Position.X + 1, taboutline.Position.Y + 1),
            Color = theme.lightcontrast
        })
        page.tabbutton = tabbutton

        local tabtitle = utility.Create("TextLabel", Vector2.new(0, 3), {taboutline}, {
            Text = pagename,
            Size = theme.textsize,
            Font = theme.font,
            Color = theme.textcolor,
            OutlineColor = theme.textborder,
            Center = true,
            Position = Vector2.new(taboutline.Position.X + taboutline.Size.X/2, taboutline.Position.Y + 3)
        })
        page.tabtitle = tabtitle

        -- Content area
        local contentframe = utility.Create("Frame", Vector2.new(4, 4), {contentholder}, {
            Size = Vector2.new(contentholder.Size.X - 8, contentholder.Size.Y - 8),
            Position = Vector2.new(contentholder.Position.X + 4, contentholder.Position.Y + 4),
            Color = theme.darkcontrast,
            Visible = false,
            Transparency = 0
        })
        page.contentframe = contentframe

        -- Section holders
        local leftsection = utility.Create("Frame", Vector2.new(0, 0), {contentframe}, {
            Size = Vector2.new((contentframe.Size.X / 2) - 4, contentframe.Size.Y),
            Position = Vector2.new(contentframe.Position.X, contentframe.Position.Y),
            Color = theme.darkcontrast,
            Visible = false,
            Transparency = 0
        })
        page.leftsection = leftsection

        local rightsection = utility.Create("Frame", Vector2.new(0, 0), {contentframe}, {
            Size = Vector2.new((contentframe.Size.X / 2) - 4, contentframe.Size.Y),
            Position = Vector2.new(contentframe.Position.X + (contentframe.Size.X / 2) + 4, contentframe.Position.Y),
            Color = theme.darkcontrast,
            Visible = false,
            Transparency = 0
        })
        page.rightsection = rightsection

        function page:Show()
            for i, v in pairs(window.pages) do
                v.contentframe.Visible = false
                v.leftsection.Visible = false
                v.rightsection.Visible = false
                pcall(function() v.tabbutton.Color = theme.lightcontrast end)
                for _, sec in pairs(v.sections) do
                    if sec.SetVisible then sec:SetVisible(false) end
                end
            end
            page.open = true
            page.contentframe.Visible = true
            page.leftsection.Visible = true
            page.rightsection.Visible = true
            pcall(function() page.tabbutton.Color = theme.darkcontrast end)
            for _, sec in pairs(page.sections) do
                if sec.SetVisible then sec:SetVisible(true) end
            end
            window.currentPage = page
        end

        -- Section creation
        function page:Section(info)
            info = info or {}
            local sectionname = info.name or info.Name or "Section"
            local sectionside = (info.side or info.Side or "left"):lower()
            local sectionsize = info.size or info.Size or 200

            local section = {
                elements = {},
                elementOffset = 0,
                page = page
            }

            local sideHolder = sectionside == "left" and page.leftsection or page.rightsection
            local yOffset = sectionside == "left" and page.sectionOffset.left or page.sectionOffset.right

            -- Section frame
            local sectionoutline = utility.Create("Frame", Vector2.new(0, yOffset), {sideHolder}, {
                Size = Vector2.new(sideHolder.Size.X, sectionsize),
                Position = Vector2.new(sideHolder.Position.X, sideHolder.Position.Y + yOffset),
                Color = theme.outline,
                Visible = page.open
            })
            section.sectionoutline = sectionoutline

            local sectioninline = utility.Create("Frame", Vector2.new(1, 1), {sectionoutline}, {
                Size = Vector2.new(sectionoutline.Size.X - 2, sectionoutline.Size.Y - 2),
                Position = Vector2.new(sectionoutline.Position.X + 1, sectionoutline.Position.Y + 1),
                Color = theme.inline,
                Visible = page.open
            })

            local sectionframe = utility.Create("Frame", Vector2.new(1, 1), {sectioninline}, {
                Size = Vector2.new(sectioninline.Size.X - 2, sectioninline.Size.Y - 2),
                Position = Vector2.new(sectioninline.Position.X + 1, sectioninline.Position.Y + 1),
                Color = theme.lightcontrast,
                Visible = page.open
            })
            section.sectionframe = sectionframe

            -- Title background
            local titlebgwidth = utility.GetTextBounds(sectionname, theme.textsize, theme.font).X + 6
            local titlebg = utility.Create("Frame", Vector2.new(8, -6), {sectionframe}, {
                Size = Vector2.new(titlebgwidth, 12),
                Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y - 6),
                Color = theme.lightcontrast,
                Visible = page.open
            })

            local sectiontitle = utility.Create("TextLabel", Vector2.new(10, -4), {sectionframe}, {
                Text = sectionname,
                Size = theme.textsize,
                Font = theme.font,
                Color = theme.textcolor,
                OutlineColor = theme.textborder,
                Position = Vector2.new(sectionframe.Position.X + 11, sectionframe.Position.Y - 4),
                Visible = page.open
            })
            section.sectiontitle = sectiontitle

            -- Update offset
            if sectionside == "left" then
                page.sectionOffset.left = page.sectionOffset.left + sectionsize + 8
            else
                page.sectionOffset.right = page.sectionOffset.right + sectionsize + 8
            end

            function section:SetVisible(state)
                pcall(function()
                    sectionoutline.Visible = state
                    sectioninline.Visible = state
                    sectionframe.Visible = state
                    titlebg.Visible = state
                    sectiontitle.Visible = state
                end)
                for _, elem in pairs(section.elements) do
                    if elem.SetVisible then
                        pcall(function() elem:SetVisible(state) end)
                    end
                end
            end

            -- Toggle
            function section:Toggle(info)
                info = info or {}
                local togglename = info.name or info.Name or "Toggle"
                local toggledefault = info.default or info.Default or false
                local toggleflag = info.flag or info.Flag or info.pointer or info.Pointer
                local togglecallback = info.callback or info.Callback or function() end

                local toggle = {
                    value = toggledefault,
                    axis = section.elementOffset + 14
                }

                -- Toggle elements
                local toggleoutline = utility.Create("Frame", Vector2.new(8, toggle.axis), {sectionframe}, {
                    Size = Vector2.new(10, 10),
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + toggle.axis + 1),
                    Color = theme.outline,
                    Visible = page.open
                })

                local togglebox = utility.Create("Frame", Vector2.new(1, 1), {toggleoutline}, {
                    Size = Vector2.new(8, 8),
                    Position = Vector2.new(toggleoutline.Position.X + 1, toggleoutline.Position.Y + 1),
                    Color = toggledefault and theme.accent or theme.darkcontrast,
                    Visible = page.open
                })
                toggle.box = togglebox

                local toggletitle = utility.Create("TextLabel", Vector2.new(16, 0), {sectionframe}, {
                    Text = togglename,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(sectionframe.Position.X + 24, sectionframe.Position.Y + toggle.axis - 1),
                    Visible = page.open
                })
                toggle.title = toggletitle

                function toggle:Set(value)
                    toggle.value = value
                    pcall(function()
                        togglebox.Color = value and theme.accent or theme.darkcontrast
                    end)
                    if toggleflag then
                        library.flags[toggleflag] = value
                    end
                    pcall(togglecallback, value)
                end

                function toggle:Get()
                    return toggle.value
                end

                function toggle:SetVisible(state)
                    pcall(function()
                        toggleoutline.Visible = state
                        togglebox.Visible = state
                        toggletitle.Visible = state
                    end)
                end

                -- Click handler
                library.began[#library.began + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and toggleoutline.Visible then
                        if utility.MouseOverDrawing({
                            sectionframe.Position.X + 8,
                            sectionframe.Position.Y + toggle.axis,
                            sectionframe.Position.X + sectionframe.Size.X - 8,
                            sectionframe.Position.Y + toggle.axis + 14
                        }) and not window:IsOverContent() then
                            toggle:Set(not toggle.value)
                        end
                    end
                end

                if toggleflag then
                    library.flags[toggleflag] = toggledefault
                    library.pointers[toggleflag] = toggle
                end
                if toggledefault then
                    pcall(togglecallback, toggledefault)
                end

                section.elementOffset = section.elementOffset + 20
                section.elements[#section.elements + 1] = toggle
                return toggle
            end

            -- Slider
            function section:Slider(info)
                info = info or {}
                local slidername = info.name or info.Name or "Slider"
                local slidermin = info.min or info.Min or 0
                local slidermax = info.max or info.Max or 100
                local sliderdefault = info.default or info.Default or slidermin
                local sliderincrement = info.increment or info.Increment or 1
                local sliderflag = info.flag or info.Flag or info.pointer or info.Pointer
                local slidercallback = info.callback or info.Callback or function() end

                local slider = {
                    value = sliderdefault,
                    axis = section.elementOffset + 14,
                    dragging = false
                }

                local slidertitle = utility.Create("TextLabel", Vector2.new(8, slider.axis), {sectionframe}, {
                    Text = slidername,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + slider.axis),
                    Visible = page.open
                })

                local slidervalue = utility.Create("TextLabel", Vector2.new(0, slider.axis), {sectionframe}, {
                    Text = tostring(sliderdefault),
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(sectionframe.Position.X + sectionframe.Size.X - 8 - utility.GetTextBounds(tostring(sliderdefault), theme.textsize, theme.font).X, sectionframe.Position.Y + slider.axis),
                    Visible = page.open
                })
                slider.valuetext = slidervalue

                local slideroutline = utility.Create("Frame", Vector2.new(8, slider.axis + 16), {sectionframe}, {
                    Size = Vector2.new(sectionframe.Size.X - 16, 12),
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + slider.axis + 16),
                    Color = theme.outline,
                    Visible = page.open
                })
                slider.outline = slideroutline

                local sliderbg = utility.Create("Frame", Vector2.new(1, 1), {slideroutline}, {
                    Size = Vector2.new(slideroutline.Size.X - 2, 10),
                    Position = Vector2.new(slideroutline.Position.X + 1, slideroutline.Position.Y + 1),
                    Color = theme.darkcontrast,
                    Visible = page.open
                })

                local percent = (sliderdefault - slidermin) / (slidermax - slidermin)
                local sliderfill = utility.Create("Frame", Vector2.new(0, 0), {sliderbg}, {
                    Size = Vector2.new((sliderbg.Size.X) * percent, 10),
                    Position = Vector2.new(sliderbg.Position.X, sliderbg.Position.Y),
                    Color = theme.accent,
                    Visible = page.open
                })
                slider.fill = sliderfill

                function slider:Set(value)
                    value = math.clamp(value, slidermin, slidermax)
                    value = math.floor(value / sliderincrement + 0.5) * sliderincrement
                    slider.value = value

                    local pct = (value - slidermin) / (slidermax - slidermin)
                    pcall(function()
                        sliderfill.Size = Vector2.new((sliderbg.Size.X) * pct, 10)
                        slidervalue.Text = tostring(value)
                        slidervalue.Position = Vector2.new(sectionframe.Position.X + sectionframe.Size.X - 8 - utility.GetTextBounds(tostring(value), theme.textsize, theme.font).X, sectionframe.Position.Y + slider.axis)
                    end)

                    if sliderflag then
                        library.flags[sliderflag] = value
                    end
                    pcall(slidercallback, value)
                end

                function slider:Get()
                    return slider.value
                end

                function slider:SetVisible(state)
                    pcall(function()
                        slidertitle.Visible = state
                        slidervalue.Visible = state
                        slideroutline.Visible = state
                        sliderbg.Visible = state
                        sliderfill.Visible = state
                    end)
                end

                function slider:Refresh()
                    if slider.dragging then
                        local mouseX = utility.MouseLocation().X
                        local sliderX = slideroutline.Position.X + 1
                        local sliderWidth = slideroutline.Size.X - 2
                        local pct = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
                        local value = slidermin + (slidermax - slidermin) * pct
                        slider:Set(value)
                    end
                end

                library.began[#library.began + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and slideroutline.Visible then
                        if utility.MouseOverDrawing({
                            slideroutline.Position.X,
                            slideroutline.Position.Y,
                            slideroutline.Position.X + slideroutline.Size.X,
                            slideroutline.Position.Y + slideroutline.Size.Y
                        }) and not window:IsOverContent() then
                            slider.dragging = true
                            slider:Refresh()
                        end
                    end
                end

                library.ended[#library.ended + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        slider.dragging = false
                    end
                end

                library.changed[#library.changed + 1] = function()
                    if slider.dragging and window.isVisible then
                        slider:Refresh()
                    end
                end

                if sliderflag then
                    library.flags[sliderflag] = sliderdefault
                    library.pointers[sliderflag] = slider
                end

                section.elementOffset = section.elementOffset + 36
                section.elements[#section.elements + 1] = slider
                return slider
            end

            -- Button
            function section:Button(info)
                info = info or {}
                local buttonname = info.name or info.Name or "Button"
                local buttoncallback = info.callback or info.Callback or function() end

                local button = {
                    axis = section.elementOffset + 14
                }

                local buttonoutline = utility.Create("Frame", Vector2.new(8, button.axis), {sectionframe}, {
                    Size = Vector2.new(sectionframe.Size.X - 16, 18),
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + button.axis),
                    Color = theme.outline,
                    Visible = page.open
                })
                button.outline = buttonoutline

                local buttoninline = utility.Create("Frame", Vector2.new(1, 1), {buttonoutline}, {
                    Size = Vector2.new(buttonoutline.Size.X - 2, 16),
                    Position = Vector2.new(buttonoutline.Position.X + 1, buttonoutline.Position.Y + 1),
                    Color = theme.inline,
                    Visible = page.open
                })

                local buttonbg = utility.Create("Frame", Vector2.new(1, 1), {buttoninline}, {
                    Size = Vector2.new(buttoninline.Size.X - 2, 14),
                    Position = Vector2.new(buttoninline.Position.X + 1, buttoninline.Position.Y + 1),
                    Color = theme.lightcontrast,
                    Visible = page.open
                })
                button.bg = buttonbg

                local buttontitle = utility.Create("TextLabel", Vector2.new(0, 2), {buttonoutline}, {
                    Text = buttonname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Center = true,
                    Position = Vector2.new(buttonoutline.Position.X + buttonoutline.Size.X/2, buttonoutline.Position.Y + 2),
                    Visible = page.open
                })

                function button:SetVisible(state)
                    pcall(function()
                        buttonoutline.Visible = state
                        buttoninline.Visible = state
                        buttonbg.Visible = state
                        buttontitle.Visible = state
                    end)
                end

                library.began[#library.began + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and buttonoutline.Visible then
                        if utility.MouseOverDrawing({
                            buttonoutline.Position.X,
                            buttonoutline.Position.Y,
                            buttonoutline.Position.X + buttonoutline.Size.X,
                            buttonoutline.Position.Y + buttonoutline.Size.Y
                        }) and not window:IsOverContent() then
                            pcall(function() buttonbg.Color = theme.darkcontrast end)
                            pcall(buttoncallback)
                            task.delay(0.1, function()
                                pcall(function() buttonbg.Color = theme.lightcontrast end)
                            end)
                        end
                    end
                end

                section.elementOffset = section.elementOffset + 24
                section.elements[#section.elements + 1] = button
                return button
            end

            -- Dropdown
            function section:Dropdown(info)
                info = info or {}
                local dropdownname = info.name or info.Name or "Dropdown"
                local dropdownitems = info.items or info.Items or info.options or info.Options or {}
                local dropdowndefault = info.default or info.Default or (dropdownitems[1] or "")
                local dropdownflag = info.flag or info.Flag or info.pointer or info.Pointer
                local dropdowncallback = info.callback or info.Callback or function() end

                local dropdown = {
                    value = dropdowndefault,
                    axis = section.elementOffset + 14,
                    open = false,
                    items = dropdownitems,
                    holder = {drawings = {}, buttons = {}}
                }

                local dropdowntitle = utility.Create("TextLabel", Vector2.new(8, dropdown.axis), {sectionframe}, {
                    Text = dropdownname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + dropdown.axis),
                    Visible = page.open
                })

                local dropdownoutline = utility.Create("Frame", Vector2.new(8, dropdown.axis + 16), {sectionframe}, {
                    Size = Vector2.new(sectionframe.Size.X - 16, 18),
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + dropdown.axis + 16),
                    Color = theme.outline,
                    Visible = page.open
                })
                dropdown.outline = dropdownoutline

                local dropdowninline = utility.Create("Frame", Vector2.new(1, 1), {dropdownoutline}, {
                    Size = Vector2.new(dropdownoutline.Size.X - 2, 16),
                    Position = Vector2.new(dropdownoutline.Position.X + 1, dropdownoutline.Position.Y + 1),
                    Color = theme.inline,
                    Visible = page.open
                })

                local dropdownbg = utility.Create("Frame", Vector2.new(1, 1), {dropdowninline}, {
                    Size = Vector2.new(dropdowninline.Size.X - 2, 14),
                    Position = Vector2.new(dropdowninline.Position.X + 1, dropdowninline.Position.Y + 1),
                    Color = theme.lightcontrast,
                    Visible = page.open
                })

                local dropdowntext = utility.Create("TextLabel", Vector2.new(4, 2), {dropdownoutline}, {
                    Text = dropdowndefault,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(dropdownoutline.Position.X + 4, dropdownoutline.Position.Y + 2),
                    Visible = page.open
                })
                dropdown.text = dropdowntext

                local dropdownarrow = utility.Create("TextLabel", Vector2.new(0, 2), {dropdownoutline}, {
                    Text = "v",
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(dropdownoutline.Position.X + dropdownoutline.Size.X - 12, dropdownoutline.Position.Y + 2),
                    Visible = page.open
                })

                function dropdown:Set(value)
                    dropdown.value = value
                    pcall(function() dropdowntext.Text = value end)
                    if dropdownflag then
                        library.flags[dropdownflag] = value
                    end
                    pcall(dropdowncallback, value)
                end

                function dropdown:Get()
                    return dropdown.value
                end

                function dropdown:SetVisible(state)
                    pcall(function()
                        dropdowntitle.Visible = state
                        dropdownoutline.Visible = state
                        dropdowninline.Visible = state
                        dropdownbg.Visible = state
                        dropdowntext.Visible = state
                        dropdownarrow.Visible = state
                    end)
                end

                function dropdown:OpenDropdown()
                    if dropdown.open then
                        dropdown.open = false
                        for _, v in pairs(dropdown.holder.drawings) do
                            utility.Remove(v)
                        end
                        dropdown.holder.drawings = {}
                        dropdown.holder.buttons = {}
                        window.currentContent.frame = nil
                        window.currentContent.dropdown = nil
                        return
                    end

                    window:CloseContent()
                    dropdown.open = true

                    local listHeight = math.min(#dropdown.items * 16 + 4, 150)

                    local listoutline = utility.Create("Frame", Vector2.new(0, 18), {dropdownoutline}, {
                        Size = Vector2.new(dropdownoutline.Size.X, listHeight),
                        Position = Vector2.new(dropdownoutline.Position.X, dropdownoutline.Position.Y + 20),
                        Color = theme.outline,
                        ZIndex = 1500,
                        Visible = true
                    })
                    dropdown.holder.drawings[#dropdown.holder.drawings + 1] = listoutline

                    local listbg = utility.Create("Frame", Vector2.new(1, 1), {listoutline}, {
                        Size = Vector2.new(listoutline.Size.X - 2, listoutline.Size.Y - 2),
                        Position = Vector2.new(listoutline.Position.X + 1, listoutline.Position.Y + 1),
                        Color = theme.darkcontrast,
                        ZIndex = 1500,
                        Visible = true
                    })
                    dropdown.holder.drawings[#dropdown.holder.drawings + 1] = listbg

                    window.currentContent.frame = listoutline
                    window.currentContent.dropdown = dropdown

                    for i, item in ipairs(dropdown.items) do
                        local itemY = (i - 1) * 16 + 2
                        local itemtext = utility.Create("TextLabel", Vector2.new(4, itemY), {listbg}, {
                            Text = item,
                            Size = theme.textsize,
                            Font = theme.font,
                            Color = item == dropdown.value and theme.accent or theme.textcolor,
                            OutlineColor = theme.textborder,
                            Position = Vector2.new(listbg.Position.X + 4, listbg.Position.Y + itemY),
                            ZIndex = 1501,
                            Visible = true
                        })
                        dropdown.holder.drawings[#dropdown.holder.drawings + 1] = itemtext
                        dropdown.holder.buttons[item] = {text = itemtext, y = itemY}
                    end
                end

                library.began[#library.began + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and dropdownoutline.Visible then
                        if utility.MouseOverDrawing({
                            dropdownoutline.Position.X,
                            dropdownoutline.Position.Y,
                            dropdownoutline.Position.X + dropdownoutline.Size.X,
                            dropdownoutline.Position.Y + dropdownoutline.Size.Y
                        }) then
                            dropdown:OpenDropdown()
                        elseif dropdown.open and window.currentContent.frame then
                            if utility.MouseOverDrawing({
                                window.currentContent.frame.Position.X,
                                window.currentContent.frame.Position.Y,
                                window.currentContent.frame.Position.X + window.currentContent.frame.Size.X,
                                window.currentContent.frame.Position.Y + window.currentContent.frame.Size.Y
                            }) then
                                for item, data in pairs(dropdown.holder.buttons) do
                                    if utility.MouseOverDrawing({
                                        window.currentContent.frame.Position.X,
                                        window.currentContent.frame.Position.Y + data.y,
                                        window.currentContent.frame.Position.X + window.currentContent.frame.Size.X,
                                        window.currentContent.frame.Position.Y + data.y + 16
                                    }) then
                                        dropdown:Set(item)
                                        dropdown:OpenDropdown()
                                        break
                                    end
                                end
                            else
                                dropdown:OpenDropdown()
                            end
                        end
                    end
                end

                if dropdownflag then
                    library.flags[dropdownflag] = dropdowndefault
                    library.pointers[dropdownflag] = dropdown
                end
                if dropdowndefault ~= "" then
                    pcall(dropdowncallback, dropdowndefault)
                end

                section.elementOffset = section.elementOffset + 42
                section.elements[#section.elements + 1] = dropdown
                return dropdown
            end

            -- Keybind
            function section:Keybind(info)
                info = info or {}
                local keybindname = info.name or info.Name or "Keybind"
                local keybinddefault = info.default or info.Default or Enum.KeyCode.Unknown
                local keybindflag = info.flag or info.Flag or info.pointer or info.Pointer
                local keybindcallback = info.callback or info.Callback or function() end

                local keybind = {
                    value = keybinddefault,
                    axis = section.elementOffset + 14,
                    listening = false
                }

                local keyNames = {
                    [Enum.KeyCode.LeftShift] = "LS",
                    [Enum.KeyCode.RightShift] = "RS",
                    [Enum.KeyCode.LeftControl] = "LC",
                    [Enum.KeyCode.RightControl] = "RC",
                    [Enum.KeyCode.LeftAlt] = "LA",
                    [Enum.KeyCode.RightAlt] = "RA",
                    [Enum.UserInputType.MouseButton1] = "M1",
                    [Enum.UserInputType.MouseButton2] = "M2",
                    [Enum.UserInputType.MouseButton3] = "M3"
                }

                local function getKeyName(key)
                    if keyNames[key] then return keyNames[key] end
                    if typeof(key) == "EnumItem" then return key.Name end
                    return "None"
                end

                local keybindtitle = utility.Create("TextLabel", Vector2.new(8, keybind.axis), {sectionframe}, {
                    Text = keybindname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(sectionframe.Position.X + 8, sectionframe.Position.Y + keybind.axis - 1),
                    Visible = page.open
                })
                keybind.title = keybindtitle

                local keyText = "[" .. getKeyName(keybinddefault) .. "]"
                local keybindvalue = utility.Create("TextLabel", Vector2.new(0, keybind.axis), {sectionframe}, {
                    Text = keyText,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = Vector2.new(sectionframe.Position.X + sectionframe.Size.X - 8 - utility.GetTextBounds(keyText, theme.textsize, theme.font).X, sectionframe.Position.Y + keybind.axis - 1),
                    Visible = page.open
                })
                keybind.valuetext = keybindvalue

                function keybind:Set(key)
                    keybind.value = key
                    local keyName = "[" .. getKeyName(key) .. "]"
                    pcall(function()
                        keybindvalue.Text = keyName
                        keybindvalue.Position = Vector2.new(sectionframe.Position.X + sectionframe.Size.X - 8 - utility.GetTextBounds(keyName, theme.textsize, theme.font).X, sectionframe.Position.Y + keybind.axis - 1)
                    end)
                    if keybindflag then
                        library.flags[keybindflag] = key
                    end
                end

                function keybind:Get()
                    return keybind.value
                end

                function keybind:SetVisible(state)
                    pcall(function()
                        keybindtitle.Visible = state
                        keybindvalue.Visible = state
                    end)
                end

                library.began[#library.began + 1] = function(input)
                    if keybind.listening and window.isVisible then
                        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                        if key ~= Enum.KeyCode.Escape then
                            keybind:Set(key)
                        else
                            keybind:Set(Enum.KeyCode.Unknown)
                        end
                        keybind.listening = false
                        pcall(function() keybindvalue.Color = theme.textcolor end)
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and keybindtitle.Visible then
                        if utility.MouseOverDrawing({
                            sectionframe.Position.X + 8,
                            sectionframe.Position.Y + keybind.axis - 2,
                            sectionframe.Position.X + sectionframe.Size.X - 8,
                            sectionframe.Position.Y + keybind.axis + 14
                        }) and not window:IsOverContent() then
                            keybind.listening = true
                            pcall(function() keybindvalue.Color = theme.accent end)
                        end
                    end

                    if keybind.value ~= Enum.KeyCode.Unknown then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(keybindcallback, keybind.value)
                        end
                    end
                end

                if keybindflag then
                    library.flags[keybindflag] = keybinddefault
                    library.pointers[keybindflag] = keybind
                end

                section.elementOffset = section.elementOffset + 20
                section.elements[#section.elements + 1] = keybind
                return keybind
            end

            page.sections[#page.sections + 1] = section
            return section
        end

        window.pages[#window.pages + 1] = page
        return page
    end

    -- Initialize
    function window:Initialize()
        if window.pages[1] then
            window.pages[1]:Show()
        end

        library.shared.initialized = true

        window:Watermark({name = name})
        window:Cursor()
        window:Fade()

        library:Log("Window initialized", "INFO")
    end

    -- Input handling
    library.began[#library.began + 1] = function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible then
            if mainframe and utility.MouseOverDrawing({
                mainframe.Position.X,
                mainframe.Position.Y,
                mainframe.Position.X + mainframe.Size.X,
                mainframe.Position.Y + 25
            }) then
                local mouseLocation = utility.MouseLocation()
                window.dragging = true
                window.drag = Vector2.new(mouseLocation.X - mainframe.Position.X, mouseLocation.Y - mainframe.Position.Y)
            end

            for i, page in pairs(window.pages) do
                if page.taboutline and utility.MouseOverDrawing({
                    page.taboutline.Position.X,
                    page.taboutline.Position.Y,
                    page.taboutline.Position.X + page.taboutline.Size.X,
                    page.taboutline.Position.Y + page.taboutline.Size.Y
                }) then
                    page:Show()
                end
            end
        end
    end

    library.ended[#library.ended + 1] = function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.dragging = false
            window.drag = Vector2.new(0, 0)
        end
    end

    library.changed[#library.changed + 1] = function()
        if window.dragging and window.isVisible and mainframe then
            local mouseLocation = utility.MouseLocation()
            local screenSize = utility.GetScreenSize()
            local newX = math.clamp(mouseLocation.X - window.drag.X, 5, screenSize.X - mainframe.Size.X - 5)
            local newY = math.clamp(mouseLocation.Y - window.drag.Y, 5, screenSize.Y - mainframe.Size.Y - 5)

            local delta = Vector2.new(newX - mainframe.Position.X, newY - mainframe.Position.Y)

            for i, v in pairs(library.drawings) do
                if v[1] then
                    pcall(function()
                        v[1].Position = Vector2.new(v[1].Position.X + delta.X, v[1].Position.Y + delta.Y)
                    end)
                end
            end
        end
    end

    library.began[#library.began + 1] = function(input)
        if input.KeyCode == window.uibind then
            window:Fade()
        end
    end

    -- Connect events
    utility.Connection(UserInputService.InputBegan, function(input)
        for _, func in pairs(library.began) do
            pcall(func, input)
        end
    end)

    utility.Connection(UserInputService.InputChanged, function(input)
        for _, func in pairs(library.changed) do
            pcall(func, input)
        end
    end)

    utility.Connection(UserInputService.InputEnded, function(input)
        for _, func in pairs(library.ended) do
            pcall(func, input)
        end
    end)

    return setmetatable(window, library)
end

-- Config functions
function library:SaveConfig(name)
    local config = {}
    for flag, pointer in pairs(library.pointers) do
        if pointer.Get then
            local value = pointer:Get()
            if typeof(value) == "EnumItem" then
                config[flag] = {Type = "Enum", EnumType = tostring(value.EnumType), Name = value.Name}
            elseif typeof(value) == "Color3" then
                config[flag] = {Type = "Color3", R = value.R, G = value.G, B = value.B}
            else
                config[flag] = value
            end
        end
    end
    pcall(function()
        writefile(library.folders.configs .. "/" .. name .. ".json", HttpService:JSONEncode(config))
    end)
    library:Log("Config saved: " .. name, "INFO")
end

function library:LoadConfig(name)
    pcall(function()
        if isfile(library.folders.configs .. "/" .. name .. ".json") then
            local decoded = HttpService:JSONDecode(readfile(library.folders.configs .. "/" .. name .. ".json"))
            for flag, value in pairs(decoded) do
                if library.pointers[flag] and library.pointers[flag].Set then
                    if type(value) == "table" then
                        if value.Type == "Enum" then
                            library.pointers[flag]:Set(Enum[value.EnumType][value.Name])
                        elseif value.Type == "Color3" then
                            library.pointers[flag]:Set(Color3.new(value.R, value.G, value.B))
                        end
                    else
                        library.pointers[flag]:Set(value)
                    end
                end
            end
            library:Log("Config loaded: " .. name, "INFO")
        end
    end)
end

return library
