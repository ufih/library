--[[
    NexusLib - Drawing-Based UI Library
    Based on Splix/Linux/Deadcell style
    Modern syntax, no legacy executor dependencies
]]

-- Services
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

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

-- Create folders
for _, folder in pairs(library.folders) do
    if not isfolder(folder) then
        makefolder(folder)
    end
end

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
    font = Drawing.Fonts.Plex,
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

    if instanceType == "Frame" or instanceType == "frame" then
        local frame = Drawing.new("Square")
        frame.Visible = true
        frame.Filled = true
        frame.Thickness = 0
        frame.Color = Color3.fromRGB(255, 255, 255)
        frame.Size = Vector2.new(100, 100)
        frame.Position = Vector2.new(0, 0)
        frame.ZIndex = 1000
        frame.Transparency = library.shared.initialized and 1 or 0
        instance = frame
    elseif instanceType == "TextLabel" or instanceType == "textlabel" then
        local text = Drawing.new("Text")
        text.Font = Drawing.Fonts.Plex
        text.Visible = true
        text.Outline = true
        text.Center = false
        text.Color = Color3.fromRGB(255, 255, 255)
        text.ZIndex = 1000
        text.Transparency = library.shared.initialized and 1 or 0
        instance = text
    elseif instanceType == "Triangle" or instanceType == "triangle" then
        local tri = Drawing.new("Triangle")
        tri.Visible = true
        tri.Filled = true
        tri.Thickness = 0
        tri.Color = Color3.fromRGB(255, 255, 255)
        tri.ZIndex = 1000
        tri.Transparency = library.shared.initialized and 1 or 0
        instance = tri
    elseif instanceType == "Image" or instanceType == "image" then
        local image = Drawing.new("Image")
        image.Size = Vector2.new(12, 19)
        image.Position = Vector2.new(0, 0)
        image.Visible = true
        image.ZIndex = 1000
        image.Transparency = library.shared.initialized and 1 or 0
        instance = image
    elseif instanceType == "Circle" or instanceType == "circle" then
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Color = Color3.fromRGB(255, 0, 0)
        circle.Thickness = 1
        circle.NumSides = 30
        circle.Filled = true
        circle.ZIndex = 1000
        circle.Radius = 50
        circle.Transparency = library.shared.initialized and 1 or 0
        instance = circle
    elseif instanceType == "Line" or instanceType == "line" then
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 1.5
        line.ZIndex = 1000
        line.Transparency = library.shared.initialized and 1 or 0
        instance = line
    end

    if instance then
        for i, v in pairs(instanceProperties) do
            if i == "Hidden" or i == "hidden" then
                instanceHidden = v
            else
                if library.shared.initialized then
                    instance[i] = v
                elseif i ~= "Transparency" then
                    instance[i] = v
                end
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
    end

    return instance
end

function utility.Remove(instance, hidden)
    library.colors[instance] = nil
    for i, v in pairs(hidden and library.hidden or library.drawings) do
        if v[1] == instance then
            v[1] = nil
            v[2] = nil
            table.remove(hidden and library.hidden or library.drawings, i)
            break
        end
    end
    if instance.__OBJECT_EXISTS then
        instance:Remove()
    end
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
            v:Disconnect()
        end
    end
end

function utility.MouseLocation()
    return UserInputService:GetMouseLocation()
end

function utility.MouseOverDrawing(values, valuesAdd)
    valuesAdd = valuesAdd or {}
    values = {
        values[1] or 0 + (valuesAdd[1] or 0),
        values[2] or 0 + (valuesAdd[2] or 0),
        values[3] or 0 + (valuesAdd[3] or 0),
        values[4] or 0 + (valuesAdd[4] or 0)
    }
    local mouseLocation = utility.MouseLocation()
    return mouseLocation.X >= values[1] and mouseLocation.X <= values[3] and mouseLocation.Y >= values[2] and mouseLocation.Y <= values[4]
end

function utility.GetTextBounds(text, textSize, font)
    local textbounds = Vector2.new(0, 0)
    local textlabel = utility.Create("TextLabel", Vector2.new(0, 0), {
        Text = text,
        Size = textSize,
        Font = font,
        Hidden = true
    })
    textbounds = textlabel.TextBounds
    utility.Remove(textlabel, true)
    return textbounds
end

function utility.GetScreenSize()
    return workspace.CurrentCamera.ViewportSize
end

function utility.LoadImage(instance, imageName, imageLink)
    local data
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
    if data and instance then
        pcall(function()
            instance.Data = data
        end)
    end
end

function utility.Lerp(instance, instanceTo, instanceTime)
    local currentTime = 0
    local currentIndex = {}
    local connection

    for i, v in pairs(instanceTo) do
        currentIndex[i] = instance[i]
    end

    local function lerp()
        for i, v in pairs(instanceTo) do
            if instance.__OBJECT_EXISTS then
                if typeof(v) == "number" then
                    instance[i] = currentIndex[i] + (v - currentIndex[i]) * (currentTime / instanceTime)
                elseif typeof(v) == "Color3" then
                    instance[i] = currentIndex[i]:Lerp(v, currentTime / instanceTime)
                elseif typeof(v) == "Vector2" then
                    instance[i] = currentIndex[i]:Lerp(v, currentTime / instanceTime)
                end
            end
        end
    end

    connection = RunService.RenderStepped:Connect(function(delta)
        if currentTime < instanceTime then
            currentTime = currentTime + delta
            lerp()
        else
            for i, v in pairs(instanceTo) do
                if instance.__OBJECT_EXISTS then
                    instance[i] = v
                end
            end
            connection:Disconnect()
        end
    end)
end

-- Debug Console
local debugConsole = {
    logs = {},
    visible = false,
    maxLogs = 50
}

function library:Log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        time = timestamp,
        message = tostring(message),
        level = level
    }
    table.insert(debugConsole.logs, 1, logEntry)
    if #debugConsole.logs > debugConsole.maxLogs then
        table.remove(debugConsole.logs)
    end
end

-- Main Library Functions
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

    -- Accent line
    local frameinline = utility.Create("Frame", Vector2.new(1, 1), {mainframe}, {
        Size = utility.Size(1, -2, 0, 2, mainframe),
        Position = utility.Position(0, 1, 0, 1, mainframe),
        Color = theme.accent
    })
    library.colors[frameinline] = {Color = "accent"}

    -- Inner frame
    local innerframe = utility.Create("Frame", Vector2.new(1, 3), {mainframe}, {
        Size = utility.Size(1, -2, 1, -4, mainframe),
        Position = utility.Position(0, 1, 0, 3, mainframe),
        Color = theme.lightcontrast
    })
    library.colors[innerframe] = {Color = "lightcontrast"}

    -- Title
    local title = utility.Create("TextLabel", Vector2.new(8, 8), {innerframe}, {
        Text = name,
        Size = theme.textsize,
        Font = theme.font,
        Color = theme.textcolor,
        OutlineColor = theme.textborder,
        Position = utility.Position(0, 8, 0, 6, innerframe)
    })
    library.colors[title] = {OutlineColor = "textborder", Color = "textcolor"}

    -- Tab holder outline
    local tabholderoutline = utility.Create("Frame", Vector2.new(8, 28), {innerframe}, {
        Size = utility.Size(0, 120, 1, -36, innerframe),
        Position = utility.Position(0, 8, 0, 28, innerframe),
        Color = theme.outline
    })
    library.colors[tabholderoutline] = {Color = "outline"}

    -- Tab holder
    local tabholder = utility.Create("Frame", Vector2.new(1, 1), {tabholderoutline}, {
        Size = utility.Size(1, -2, 1, -2, tabholderoutline),
        Position = utility.Position(0, 1, 0, 1, tabholderoutline),
        Color = theme.darkcontrast
    })
    library.colors[tabholder] = {Color = "darkcontrast"}
    window.tabholder = tabholder

    -- Content holder outline
    local contentholderoutline = utility.Create("Frame", Vector2.new(136, 28), {innerframe}, {
        Size = utility.Size(1, -144, 1, -36, innerframe),
        Position = utility.Position(0, 136, 0, 28, innerframe),
        Color = theme.outline
    })
    library.colors[contentholderoutline] = {Color = "outline"}

    -- Content holder inline
    local contentholderinline = utility.Create("Frame", Vector2.new(1, 1), {contentholderoutline}, {
        Size = utility.Size(1, -2, 1, -2, contentholderoutline),
        Position = utility.Position(0, 1, 0, 1, contentholderoutline),
        Color = theme.inline
    })
    library.colors[contentholderinline] = {Color = "inline"}

    -- Content holder
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
            if v[2][2] then
                v[1].Position = utility.Position(0, v[2][1].X, 0, v[2][1].Y, v[2][2])
            else
                v[1].Position = utility.Position(0, vector.X + v[2].X, 0, vector.Y + v[2].Y)
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
            local modemenu = window.currentContent.keybind.modemenu
            window.currentContent.keybind.open = false
            for i, v in pairs(modemenu.drawings) do
                utility.Remove(v)
            end
            modemenu.drawings = {}
            window.currentContent.frame = nil
            window.currentContent.keybind = nil
        end
    end

    function window:IsOverContent()
        if window.currentContent.frame and utility.MouseOverDrawing({
            window.currentContent.frame.Position.X,
            window.currentContent.frame.Position.Y,
            window.currentContent.frame.Position.X + window.currentContent.frame.Size.X,
            window.currentContent.frame.Position.Y + window.currentContent.frame.Size.Y
        }) then
            return true
        end
        return false
    end

    function window:Unload()
        for i, v in pairs(library.connections) do
            v:Disconnect()
            v = nil
        end
        for i, v in next, library.hidden do
            if v[1] and v[1].Remove and v[1].__OBJECT_EXISTS then
                v[1]:Remove()
            end
        end
        for i, v in pairs(library.drawings) do
            if v[1] and v[1].__OBJECT_EXISTS then
                v[1]:Remove()
            end
        end
        library.drawings = {}
        library.hidden = {}
        library.connections = {}
        library.began = {}
        library.ended = {}
        library.changed = {}
        UserInputService.MouseIconEnabled = true
    end

    function window:Fade()
        window.fading = true
        window.isVisible = not window.isVisible

        for i, v in pairs(library.drawings) do
            utility.Lerp(v[1], {Transparency = window.isVisible and v[3] or 0}, 0.25)
        end

        if window.cursor then
            window.cursor.cursor.Transparency = window.isVisible and 1 or 0
            window.cursor.cursorinline.Transparency = window.isVisible and 1 or 0
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
        library.colors[cursor] = {Color = "cursoroutline"}

        local cursorinline = utility.Create("Triangle", nil, {
            Color = theme.accent,
            Filled = true,
            Thickness = 0,
            ZIndex = 2000,
            Hidden = true
        })
        window.cursor.cursorinline = cursorinline
        library.colors[cursorinline] = {Color = "accent"}

        utility.Connection(RunService.RenderStepped, function()
            local mouseLocation = utility.MouseLocation()
            cursor.PointA = Vector2.new(mouseLocation.X, mouseLocation.Y)
            cursor.PointB = Vector2.new(mouseLocation.X + 12, mouseLocation.Y + 4)
            cursor.PointC = Vector2.new(mouseLocation.X + 4, mouseLocation.Y + 12)
            cursorinline.PointA = Vector2.new(mouseLocation.X, mouseLocation.Y)
            cursorinline.PointB = Vector2.new(mouseLocation.X + 12, mouseLocation.Y + 4)
            cursorinline.PointC = Vector2.new(mouseLocation.X + 4, mouseLocation.Y + 12)
        end)

        return window.cursor
    end

    function window:Watermark(info)
        window.watermark = {visible = false}
        info = info or {}
        local watermarkname = info.name or info.Name or "NexusLib"

        local textbounds = utility.GetTextBounds(watermarkname, theme.textsize, theme.font)

        local watermarkoutline = utility.Create("Frame", Vector2.new(10, 10), {
            Size = utility.Size(0, textbounds.X + 80, 0, 21),
            Position = utility.Position(0, 10, 0, 10),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.outline,
            Visible = window.watermark.visible
        })
        window.watermark.outline = watermarkoutline
        library.colors[watermarkoutline] = {Color = "outline"}

        local watermarkinline = utility.Create("Frame", Vector2.new(1, 1), {watermarkoutline}, {
            Size = utility.Size(1, -2, 1, -2, watermarkoutline),
            Position = utility.Position(0, 1, 0, 1, watermarkoutline),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.inline,
            Visible = window.watermark.visible
        })
        library.colors[watermarkinline] = {Color = "inline"}

        local watermarkframe = utility.Create("Frame", Vector2.new(1, 1), {watermarkinline}, {
            Size = utility.Size(1, -2, 1, -2, watermarkinline),
            Position = utility.Position(0, 1, 0, 1, watermarkinline),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.lightcontrast,
            Visible = window.watermark.visible
        })
        library.colors[watermarkframe] = {Color = "lightcontrast"}

        local watermarkaccent = utility.Create("Frame", Vector2.new(0, 0), {watermarkframe}, {
            Size = utility.Size(1, 0, 0, 1, watermarkframe),
            Position = utility.Position(0, 0, 0, 0, watermarkframe),
            Hidden = true,
            ZIndex = 1010,
            Color = theme.accent,
            Visible = window.watermark.visible
        })
        library.colors[watermarkaccent] = {Color = "accent"}

        local watermarktitle = utility.Create("TextLabel", Vector2.new(6, 4), {watermarkoutline}, {
            Text = watermarkname .. " | FPS: 0 | Ping: 0",
            Size = theme.textsize,
            Font = theme.font,
            Color = theme.textcolor,
            OutlineColor = theme.textborder,
            Hidden = true,
            ZIndex = 1010,
            Position = utility.Position(0, 6, 0, 4, watermarkoutline),
            Visible = window.watermark.visible
        })
        library.colors[watermarktitle] = {OutlineColor = "textborder", Color = "textcolor"}

        function window.watermark:UpdateSize()
            watermarkoutline.Size = utility.Size(0, watermarktitle.TextBounds.X + 12, 0, 21)
            watermarkinline.Size = utility.Size(1, -2, 1, -2, watermarkoutline)
            watermarkframe.Size = utility.Size(1, -2, 1, -2, watermarkinline)
            watermarkaccent.Size = utility.Size(1, 0, 0, 1, watermarkframe)
        end

        function window.watermark:SetVisible(state)
            window.watermark.visible = state
            watermarkoutline.Visible = state
            watermarkinline.Visible = state
            watermarkframe.Visible = state
            watermarkaccent.Visible = state
            watermarktitle.Visible = state
        end

        -- FPS counter
        local lastTick = tick()
        local frameCount = 0
        task.spawn(function()
            while true do
                frameCount = 0
                task.wait(1)
                library.shared.fps = frameCount
            end
        end)

        utility.Connection(RunService.RenderStepped, function()
            frameCount = frameCount + 1
            local ping = "?"
            pcall(function()
                ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
            end)
            library.shared.ping = ping

            if tick() - lastTick >= 0.5 then
                watermarktitle.Text = watermarkname .. " | FPS: " .. tostring(library.shared.fps) .. " | Ping: " .. tostring(library.shared.ping)
                window.watermark:UpdateSize()
                lastTick = tick()
            end
        end)

        return window.watermark
    end

    -- Page creation
    function window:Page(info)
        info = info or {}
        local pagename = info.name or info.Name or info.title or info.Title or "New Page"

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

        local textbounds = utility.GetTextBounds(pagename, theme.textsize, theme.font)

        -- Tab button outline
        local taboutline = utility.Create("Frame", Vector2.new(4, tabYOffset), {tabholder}, {
            Size = utility.Size(1, -8, 0, 20, tabholder),
            Position = utility.Position(0, 4, 0, tabYOffset, tabholder),
            Color = theme.outline
        })
        page.taboutline = taboutline
        library.colors[taboutline] = {Color = "outline"}

        -- Tab button
        local tabbutton = utility.Create("Frame", Vector2.new(1, 1), {taboutline}, {
            Size = utility.Size(1, -2, 1, -2, taboutline),
            Position = utility.Position(0, 1, 0, 1, taboutline),
            Color = theme.lightcontrast
        })
        page.tabbutton = tabbutton
        library.colors[tabbutton] = {Color = "lightcontrast"}

        -- Tab title
        local tabtitle = utility.Create("TextLabel", Vector2.new(0, 3), {taboutline}, {
            Text = pagename,
            Size = theme.textsize,
            Font = theme.font,
            Color = theme.textcolor,
            OutlineColor = theme.textborder,
            Center = true,
            Position = utility.Position(0.5, 0, 0, 3, taboutline)
        })
        page.tabtitle = tabtitle
        library.colors[tabtitle] = {OutlineColor = "textborder", Color = "textcolor"}

        -- Content frame (hidden by default)
        local contentframe = utility.Create("Frame", Vector2.new(4, 4), {contentholder}, {
            Size = utility.Size(1, -8, 1, -8, contentholder),
            Position = utility.Position(0, 4, 0, 4, contentholder),
            Color = theme.darkcontrast,
            Visible = false,
            Transparency = 0
        })
        page.contentframe = contentframe
        library.colors[contentframe] = {Color = "darkcontrast"}

        -- Left section holder
        local leftsection = utility.Create("Frame", Vector2.new(0, 0), {contentframe}, {
            Size = utility.Size(0.5, -4, 1, 0, contentframe),
            Position = utility.Position(0, 0, 0, 0, contentframe),
            Color = theme.darkcontrast,
            Visible = false,
            Transparency = 0
        })
        page.leftsection = leftsection

        -- Right section holder  
        local rightsection = utility.Create("Frame", Vector2.new(0, 0), {contentframe}, {
            Size = utility.Size(0.5, -4, 1, 0, contentframe),
            Position = utility.Position(0.5, 4, 0, 0, contentframe),
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
                v.tabbutton.Color = theme.lightcontrast
                for _, sec in pairs(v.sections) do
                    sec:SetVisible(false)
                end
            end
            page.open = true
            page.contentframe.Visible = true
            page.leftsection.Visible = true
            page.rightsection.Visible = true
            page.tabbutton.Color = theme.darkcontrast
            for _, sec in pairs(page.sections) do
                sec:SetVisible(true)
            end
            window.currentPage = page
        end

        function page:Update()
            for _, sec in pairs(page.sections) do
                sec:Update()
            end
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

            -- Section outline
            local sectionoutline = utility.Create("Frame", Vector2.new(0, yOffset), {sideHolder}, {
                Size = utility.Size(1, 0, 0, sectionsize, sideHolder),
                Position = utility.Position(0, 0, 0, yOffset, sideHolder),
                Color = theme.outline,
                Visible = page.open
            })
            section.sectionoutline = sectionoutline
            library.colors[sectionoutline] = {Color = "outline"}

            -- Section inline
            local sectioninline = utility.Create("Frame", Vector2.new(1, 1), {sectionoutline}, {
                Size = utility.Size(1, -2, 1, -2, sectionoutline),
                Position = utility.Position(0, 1, 0, 1, sectionoutline),
                Color = theme.inline,
                Visible = page.open
            })
            library.colors[sectioninline] = {Color = "inline"}

            -- Section frame
            local sectionframe = utility.Create("Frame", Vector2.new(1, 1), {sectioninline}, {
                Size = utility.Size(1, -2, 1, -2, sectioninline),
                Position = utility.Position(0, 1, 0, 1, sectioninline),
                Color = theme.lightcontrast,
                Visible = page.open
            })
            section.sectionframe = sectionframe
            library.colors[sectionframe] = {Color = "lightcontrast"}

            -- Section title background
            local titlebg = utility.Create("Frame", Vector2.new(8, -6), {sectionframe}, {
                Size = utility.Size(0, utility.GetTextBounds(sectionname, theme.textsize, theme.font).X + 6, 0, 12, sectionframe),
                Position = utility.Position(0, 8, 0, -6, sectionframe),
                Color = theme.lightcontrast,
                Visible = page.open
            })
            library.colors[titlebg] = {Color = "lightcontrast"}

            -- Section title
            local sectiontitle = utility.Create("TextLabel", Vector2.new(10, -4), {sectionframe}, {
                Text = sectionname,
                Size = theme.textsize,
                Font = theme.font,
                Color = theme.textcolor,
                OutlineColor = theme.textborder,
                Position = utility.Position(0, 11, 0, -4, sectionframe),
                Visible = page.open
            })
            section.sectiontitle = sectiontitle
            library.colors[sectiontitle] = {OutlineColor = "textborder", Color = "textcolor"}

            -- Update section offset
            if sectionside == "left" then
                page.sectionOffset.left = page.sectionOffset.left + sectionsize + 8
            else
                page.sectionOffset.right = page.sectionOffset.right + sectionsize + 8
            end

            function section:SetVisible(state)
                sectionoutline.Visible = state
                sectioninline.Visible = state
                sectionframe.Visible = state
                titlebg.Visible = state
                sectiontitle.Visible = state
                for _, elem in pairs(section.elements) do
                    if elem.SetVisible then
                        elem:SetVisible(state)
                    end
                end
            end

            function section:Update()
                local totalHeight = 16
                for _, elem in pairs(section.elements) do
                    if elem.GetHeight then
                        totalHeight = totalHeight + elem:GetHeight() + 6
                    end
                end
                sectionoutline.Size = utility.Size(1, 0, 0, math.max(totalHeight, 50), sideHolder)
            end

            -- Toggle element
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

                -- Toggle holder
                local toggleholder = utility.Create("Frame", Vector2.new(8, toggle.axis), {sectionframe}, {
                    Size = utility.Size(1, -16, 0, 14, sectionframe),
                    Position = utility.Position(0, 8, 0, toggle.axis, sectionframe),
                    Color = theme.lightcontrast,
                    Visible = page.open,
                    Transparency = 0
                })
                toggle.holder = toggleholder

                -- Toggle box outline
                local toggleoutline = utility.Create("Frame", Vector2.new(0, 1), {toggleholder}, {
                    Size = utility.Size(0, 10, 0, 10),
                    Position = utility.Position(0, 0, 0, 1, toggleholder),
                    Color = theme.outline,
                    Visible = page.open
                })
                library.colors[toggleoutline] = {Color = "outline"}

                -- Toggle box
                local togglebox = utility.Create("Frame", Vector2.new(1, 1), {toggleoutline}, {
                    Size = utility.Size(1, -2, 1, -2, toggleoutline),
                    Position = utility.Position(0, 1, 0, 1, toggleoutline),
                    Color = toggledefault and theme.accent or theme.darkcontrast,
                    Visible = page.open
                })
                toggle.box = togglebox
                if not toggledefault then
                    library.colors[togglebox] = {Color = "darkcontrast"}
                end

                -- Toggle title
                local toggletitle = utility.Create("TextLabel", Vector2.new(16, 0), {toggleholder}, {
                    Text = togglename,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 16, 0, -1, toggleholder),
                    Visible = page.open
                })
                toggle.title = toggletitle
                library.colors[toggletitle] = {OutlineColor = "textborder", Color = "textcolor"}

                function toggle:Set(value)
                    toggle.value = value
                    togglebox.Color = value and theme.accent or theme.darkcontrast
                    if value then
                        library.colors[togglebox] = nil
                    else
                        library.colors[togglebox] = {Color = "darkcontrast"}
                    end
                    if toggleflag then
                        library.flags[toggleflag] = value
                    end
                    pcall(togglecallback, value)
                end

                function toggle:Get()
                    return toggle.value
                end

                function toggle:SetVisible(state)
                    toggleholder.Visible = state
                    toggleoutline.Visible = state
                    togglebox.Visible = state
                    toggletitle.Visible = state
                end

                function toggle:GetHeight()
                    return 14
                end

                -- Input handling
                library.began[#library.began + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and toggleholder.Visible then
                        if utility.MouseOverDrawing({
                            toggleholder.Position.X,
                            toggleholder.Position.Y,
                            toggleholder.Position.X + toggleholder.Size.X,
                            toggleholder.Position.Y + toggleholder.Size.Y
                        }) and not window:IsOverContent() then
                            toggle:Set(not toggle.value)
                        end
                    end
                end

                -- Initialize
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

            -- Slider element
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

                -- Slider title
                local slidertitle = utility.Create("TextLabel", Vector2.new(8, slider.axis), {sectionframe}, {
                    Text = slidername,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 8, 0, slider.axis, sectionframe),
                    Visible = page.open
                })
                slider.title = slidertitle
                library.colors[slidertitle] = {OutlineColor = "textborder", Color = "textcolor"}

                -- Slider value text
                local slidervalue = utility.Create("TextLabel", Vector2.new(0, slider.axis), {sectionframe}, {
                    Text = tostring(sliderdefault),
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(1, -8 - utility.GetTextBounds(tostring(sliderdefault), theme.textsize, theme.font).X, 0, slider.axis, sectionframe),
                    Visible = page.open
                })
                slider.valuetext = slidervalue
                library.colors[slidervalue] = {OutlineColor = "textborder", Color = "textcolor"}

                -- Slider outline
                local slideroutline = utility.Create("Frame", Vector2.new(8, slider.axis + 16), {sectionframe}, {
                    Size = utility.Size(1, -16, 0, 12, sectionframe),
                    Position = utility.Position(0, 8, 0, slider.axis + 16, sectionframe),
                    Color = theme.outline,
                    Visible = page.open
                })
                slider.outline = slideroutline
                library.colors[slideroutline] = {Color = "outline"}

                -- Slider background
                local sliderbg = utility.Create("Frame", Vector2.new(1, 1), {slideroutline}, {
                    Size = utility.Size(1, -2, 1, -2, slideroutline),
                    Position = utility.Position(0, 1, 0, 1, slideroutline),
                    Color = theme.darkcontrast,
                    Visible = page.open
                })
                library.colors[sliderbg] = {Color = "darkcontrast"}

                -- Slider fill
                local percent = (sliderdefault - slidermin) / (slidermax - slidermin)
                local sliderfill = utility.Create("Frame", Vector2.new(0, 0), {sliderbg}, {
                    Size = utility.Size(percent, 0, 1, 0, sliderbg),
                    Position = utility.Position(0, 0, 0, 0, sliderbg),
                    Color = theme.accent,
                    Visible = page.open
                })
                slider.fill = sliderfill
                library.colors[sliderfill] = {Color = "accent"}

                function slider:Set(value)
                    value = math.clamp(value, slidermin, slidermax)
                    value = math.floor(value / sliderincrement + 0.5) * sliderincrement
                    slider.value = value

                    local percent = (value - slidermin) / (slidermax - slidermin)
                    sliderfill.Size = utility.Size(percent, 0, 1, 0, sliderbg)
                    slidervalue.Text = tostring(value)
                    slidervalue.Position = utility.Position(1, -8 - utility.GetTextBounds(tostring(value), theme.textsize, theme.font).X, 0, slider.axis, sectionframe)

                    if sliderflag then
                        library.flags[sliderflag] = value
                    end
                    pcall(slidercallback, value)
                end

                function slider:Get()
                    return slider.value
                end

                function slider:SetVisible(state)
                    slidertitle.Visible = state
                    slidervalue.Visible = state
                    slideroutline.Visible = state
                    sliderbg.Visible = state
                    sliderfill.Visible = state
                end

                function slider:GetHeight()
                    return 30
                end

                function slider:Refresh()
                    if slider.dragging then
                        local mouseX = utility.MouseLocation().X
                        local sliderX = slideroutline.Position.X
                        local sliderWidth = slideroutline.Size.X - 2
                        local percent = math.clamp((mouseX - sliderX - 1) / sliderWidth, 0, 1)
                        local value = slidermin + (slidermax - slidermin) * percent
                        slider:Set(value)
                    end
                end

                -- Input handling
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

                -- Initialize
                if sliderflag then
                    library.flags[sliderflag] = sliderdefault
                    library.pointers[sliderflag] = slider
                end

                section.elementOffset = section.elementOffset + 36
                section.elements[#section.elements + 1] = slider
                return slider
            end

            -- Button element
            function section:Button(info)
                info = info or {}
                local buttonname = info.name or info.Name or "Button"
                local buttoncallback = info.callback or info.Callback or function() end

                local button = {
                    axis = section.elementOffset + 14
                }

                -- Button outline
                local buttonoutline = utility.Create("Frame", Vector2.new(8, button.axis), {sectionframe}, {
                    Size = utility.Size(1, -16, 0, 18, sectionframe),
                    Position = utility.Position(0, 8, 0, button.axis, sectionframe),
                    Color = theme.outline,
                    Visible = page.open
                })
                button.outline = buttonoutline
                library.colors[buttonoutline] = {Color = "outline"}

                -- Button inline
                local buttoninline = utility.Create("Frame", Vector2.new(1, 1), {buttonoutline}, {
                    Size = utility.Size(1, -2, 1, -2, buttonoutline),
                    Position = utility.Position(0, 1, 0, 1, buttonoutline),
                    Color = theme.inline,
                    Visible = page.open
                })
                library.colors[buttoninline] = {Color = "inline"}

                -- Button background
                local buttonbg = utility.Create("Frame", Vector2.new(1, 1), {buttoninline}, {
                    Size = utility.Size(1, -2, 1, -2, buttoninline),
                    Position = utility.Position(0, 1, 0, 1, buttoninline),
                    Color = theme.lightcontrast,
                    Visible = page.open
                })
                button.bg = buttonbg
                library.colors[buttonbg] = {Color = "lightcontrast"}

                -- Button title
                local buttontitle = utility.Create("TextLabel", Vector2.new(0, 2), {buttonoutline}, {
                    Text = buttonname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Center = true,
                    Position = utility.Position(0.5, 0, 0, 2, buttonoutline),
                    Visible = page.open
                })
                button.title = buttontitle
                library.colors[buttontitle] = {OutlineColor = "textborder", Color = "textcolor"}

                function button:SetVisible(state)
                    buttonoutline.Visible = state
                    buttoninline.Visible = state
                    buttonbg.Visible = state
                    buttontitle.Visible = state
                end

                function button:GetHeight()
                    return 18
                end

                -- Input handling
                library.began[#library.began + 1] = function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and buttonoutline.Visible then
                        if utility.MouseOverDrawing({
                            buttonoutline.Position.X,
                            buttonoutline.Position.Y,
                            buttonoutline.Position.X + buttonoutline.Size.X,
                            buttonoutline.Position.Y + buttonoutline.Size.Y
                        }) and not window:IsOverContent() then
                            buttonbg.Color = theme.darkcontrast
                            pcall(buttoncallback)
                            task.delay(0.1, function()
                                if buttonbg.__OBJECT_EXISTS then
                                    buttonbg.Color = theme.lightcontrast
                                end
                            end)
                        end
                    end
                end

                section.elementOffset = section.elementOffset + 24
                section.elements[#section.elements + 1] = button
                return button
            end

            -- Textbox element
            function section:Textbox(info)
                info = info or {}
                local textboxname = info.name or info.Name or "Textbox"
                local textboxdefault = info.default or info.Default or ""
                local textboxplaceholder = info.placeholder or info.Placeholder or "Enter text..."
                local textboxflag = info.flag or info.Flag or info.pointer or info.Pointer
                local textboxcallback = info.callback or info.Callback or function() end

                local textbox = {
                    value = textboxdefault,
                    axis = section.elementOffset + 14,
                    focused = false
                }

                -- Textbox title
                local textboxtitle = utility.Create("TextLabel", Vector2.new(8, textbox.axis), {sectionframe}, {
                    Text = textboxname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 8, 0, textbox.axis, sectionframe),
                    Visible = page.open
                })
                textbox.title = textboxtitle
                library.colors[textboxtitle] = {OutlineColor = "textborder", Color = "textcolor"}

                -- Textbox outline
                local textboxoutline = utility.Create("Frame", Vector2.new(8, textbox.axis + 16), {sectionframe}, {
                    Size = utility.Size(1, -16, 0, 18, sectionframe),
                    Position = utility.Position(0, 8, 0, textbox.axis + 16, sectionframe),
                    Color = theme.outline,
                    Visible = page.open
                })
                textbox.outline = textboxoutline
                library.colors[textboxoutline] = {Color = "outline"}

                -- Textbox background
                local textboxbg = utility.Create("Frame", Vector2.new(1, 1), {textboxoutline}, {
                    Size = utility.Size(1, -2, 1, -2, textboxoutline),
                    Position = utility.Position(0, 1, 0, 1, textboxoutline),
                    Color = theme.darkcontrast,
                    Visible = page.open
                })
                library.colors[textboxbg] = {Color = "darkcontrast"}

                -- Textbox text
                local textboxtext = utility.Create("TextLabel", Vector2.new(4, 2), {textboxoutline}, {
                    Text = textboxdefault ~= "" and textboxdefault or textboxplaceholder,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = textboxdefault ~= "" and theme.textcolor or Color3.fromRGB(150, 150, 150),
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 4, 0, 2, textboxoutline),
                    Visible = page.open
                })
                textbox.text = textboxtext

                function textbox:Set(value)
                    textbox.value = value
                    textboxtext.Text = value ~= "" and value or textboxplaceholder
                    textboxtext.Color = value ~= "" and theme.textcolor or Color3.fromRGB(150, 150, 150)
                    if textboxflag then
                        library.flags[textboxflag] = value
                    end
                    pcall(textboxcallback, value)
                end

                function textbox:Get()
                    return textbox.value
                end

                function textbox:SetVisible(state)
                    textboxtitle.Visible = state
                    textboxoutline.Visible = state
                    textboxbg.Visible = state
                    textboxtext.Visible = state
                end

                function textbox:GetHeight()
                    return 36
                end

                -- Initialize
                if textboxflag then
                    library.flags[textboxflag] = textboxdefault
                    library.pointers[textboxflag] = textbox
                end

                section.elementOffset = section.elementOffset + 42
                section.elements[#section.elements + 1] = textbox
                return textbox
            end

            -- Dropdown element
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

                -- Dropdown title
                local dropdowntitle = utility.Create("TextLabel", Vector2.new(8, dropdown.axis), {sectionframe}, {
                    Text = dropdownname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 8, 0, dropdown.axis, sectionframe),
                    Visible = page.open
                })
                dropdown.title = dropdowntitle
                library.colors[dropdowntitle] = {OutlineColor = "textborder", Color = "textcolor"}

                -- Dropdown outline
                local dropdownoutline = utility.Create("Frame", Vector2.new(8, dropdown.axis + 16), {sectionframe}, {
                    Size = utility.Size(1, -16, 0, 18, sectionframe),
                    Position = utility.Position(0, 8, 0, dropdown.axis + 16, sectionframe),
                    Color = theme.outline,
                    Visible = page.open
                })
                dropdown.outline = dropdownoutline
                library.colors[dropdownoutline] = {Color = "outline"}

                -- Dropdown inline
                local dropdowninline = utility.Create("Frame", Vector2.new(1, 1), {dropdownoutline}, {
                    Size = utility.Size(1, -2, 1, -2, dropdownoutline),
                    Position = utility.Position(0, 1, 0, 1, dropdownoutline),
                    Color = theme.inline,
                    Visible = page.open
                })
                library.colors[dropdowninline] = {Color = "inline"}

                -- Dropdown background
                local dropdownbg = utility.Create("Frame", Vector2.new(1, 1), {dropdowninline}, {
                    Size = utility.Size(1, -2, 1, -2, dropdowninline),
                    Position = utility.Position(0, 1, 0, 1, dropdowninline),
                    Color = theme.lightcontrast,
                    Visible = page.open
                })
                library.colors[dropdownbg] = {Color = "lightcontrast"}

                -- Dropdown text
                local dropdowntext = utility.Create("TextLabel", Vector2.new(4, 2), {dropdownoutline}, {
                    Text = dropdowndefault,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 4, 0, 2, dropdownoutline),
                    Visible = page.open
                })
                dropdown.text = dropdowntext
                library.colors[dropdowntext] = {OutlineColor = "textborder", Color = "textcolor"}

                -- Arrow indicator
                local dropdownarrow = utility.Create("TextLabel", Vector2.new(0, 2), {dropdownoutline}, {
                    Text = "v",
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(1, -12, 0, 2, dropdownoutline),
                    Visible = page.open
                })
                library.colors[dropdownarrow] = {OutlineColor = "textborder", Color = "textcolor"}

                function dropdown:Set(value)
                    dropdown.value = value
                    dropdowntext.Text = value
                    if dropdownflag then
                        library.flags[dropdownflag] = value
                    end
                    pcall(dropdowncallback, value)
                end

                function dropdown:Get()
                    return dropdown.value
                end

                function dropdown:SetVisible(state)
                    dropdowntitle.Visible = state
                    dropdownoutline.Visible = state
                    dropdowninline.Visible = state
                    dropdownbg.Visible = state
                    dropdowntext.Visible = state
                    dropdownarrow.Visible = state
                end

                function dropdown:GetHeight()
                    return 36
                end

                function dropdown:OpenDropdown()
                    if dropdown.open then
                        dropdown.open = false
                        for _, v in pairs(dropdown.holder.drawings) do
                            utility.Remove(v)
                        end
                        dropdown.holder.drawings = {}
                        window.currentContent.frame = nil
                        window.currentContent.dropdown = nil
                        return
                    end

                    window:CloseContent()
                    dropdown.open = true

                    local listHeight = math.min(#dropdown.items * 16 + 4, 150)

                    -- List outline
                    local listoutline = utility.Create("Frame", Vector2.new(0, 18), {dropdownoutline}, {
                        Size = utility.Size(1, 0, 0, listHeight, dropdownoutline),
                        Position = utility.Position(0, 0, 1, 2, dropdownoutline),
                        Color = theme.outline,
                        ZIndex = 1500,
                        Visible = true
                    })
                    dropdown.holder.drawings[#dropdown.holder.drawings + 1] = listoutline

                    -- List background
                    local listbg = utility.Create("Frame", Vector2.new(1, 1), {listoutline}, {
                        Size = utility.Size(1, -2, 1, -2, listoutline),
                        Position = utility.Position(0, 1, 0, 1, listoutline),
                        Color = theme.darkcontrast,
                        ZIndex = 1500,
                        Visible = true
                    })
                    dropdown.holder.drawings[#dropdown.holder.drawings + 1] = listbg

                    window.currentContent.frame = listoutline
                    window.currentContent.dropdown = dropdown

                    -- Create list items
                    for i, item in ipairs(dropdown.items) do
                        local itemY = (i - 1) * 16 + 2
                        local itemtext = utility.Create("TextLabel", Vector2.new(4, itemY), {listbg}, {
                            Text = item,
                            Size = theme.textsize,
                            Font = theme.font,
                            Color = item == dropdown.value and theme.accent or theme.textcolor,
                            OutlineColor = theme.textborder,
                            Position = utility.Position(0, 4, 0, itemY, listbg),
                            ZIndex = 1501,
                            Visible = true
                        })
                        dropdown.holder.drawings[#dropdown.holder.drawings + 1] = itemtext
                        dropdown.holder.buttons[item] = itemtext
                    end
                end

                -- Input handling
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
                                -- Check which item was clicked
                                for item, textobj in pairs(dropdown.holder.buttons) do
                                    if utility.MouseOverDrawing({
                                        textobj.Position.X - 4,
                                        textobj.Position.Y,
                                        textobj.Position.X + window.currentContent.frame.Size.X - 4,
                                        textobj.Position.Y + 16
                                    }) then
                                        dropdown:Set(item)
                                        dropdown:OpenDropdown() -- Close
                                        break
                                    end
                                end
                            else
                                dropdown:OpenDropdown() -- Close
                            end
                        end
                    end
                end

                -- Initialize
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

            -- Keybind element
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
                    [Enum.KeyCode.LeftShift] = "LShift",
                    [Enum.KeyCode.RightShift] = "RShift",
                    [Enum.KeyCode.LeftControl] = "LCtrl",
                    [Enum.KeyCode.RightControl] = "RCtrl",
                    [Enum.KeyCode.LeftAlt] = "LAlt",
                    [Enum.KeyCode.RightAlt] = "RAlt",
                    [Enum.UserInputType.MouseButton1] = "MB1",
                    [Enum.UserInputType.MouseButton2] = "MB2",
                    [Enum.UserInputType.MouseButton3] = "MB3"
                }

                local function getKeyName(key)
                    if keyNames[key] then
                        return keyNames[key]
                    elseif typeof(key) == "EnumItem" then
                        return key.Name
                    end
                    return "None"
                end

                -- Keybind holder
                local keybindholder = utility.Create("Frame", Vector2.new(8, keybind.axis), {sectionframe}, {
                    Size = utility.Size(1, -16, 0, 14, sectionframe),
                    Position = utility.Position(0, 8, 0, keybind.axis, sectionframe),
                    Color = theme.lightcontrast,
                    Visible = page.open,
                    Transparency = 0
                })
                keybind.holder = keybindholder

                -- Keybind title
                local keybindtitle = utility.Create("TextLabel", Vector2.new(0, 0), {keybindholder}, {
                    Text = keybindname,
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(0, 0, 0, -1, keybindholder),
                    Visible = page.open
                })
                keybind.title = keybindtitle
                library.colors[keybindtitle] = {OutlineColor = "textborder", Color = "textcolor"}

                -- Keybind value
                local keybindvalue = utility.Create("TextLabel", Vector2.new(0, 0), {keybindholder}, {
                    Text = "[" .. getKeyName(keybinddefault) .. "]",
                    Size = theme.textsize,
                    Font = theme.font,
                    Color = theme.textcolor,
                    OutlineColor = theme.textborder,
                    Position = utility.Position(1, -utility.GetTextBounds("[" .. getKeyName(keybinddefault) .. "]", theme.textsize, theme.font).X, 0, -1, keybindholder),
                    Visible = page.open
                })
                keybind.valuetext = keybindvalue
                library.colors[keybindvalue] = {OutlineColor = "textborder", Color = "textcolor"}

                function keybind:Set(key)
                    keybind.value = key
                    local keyName = getKeyName(key)
                    keybindvalue.Text = "[" .. keyName .. "]"
                    keybindvalue.Position = utility.Position(1, -utility.GetTextBounds("[" .. keyName .. "]", theme.textsize, theme.font).X, 0, -1, keybindholder)
                    if keybindflag then
                        library.flags[keybindflag] = key
                    end
                end

                function keybind:Get()
                    return keybind.value
                end

                function keybind:SetVisible(state)
                    keybindholder.Visible = state
                    keybindtitle.Visible = state
                    keybindvalue.Visible = state
                end

                function keybind:GetHeight()
                    return 14
                end

                -- Input handling
                library.began[#library.began + 1] = function(input)
                    if keybind.listening and window.isVisible then
                        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                        if key ~= Enum.KeyCode.Escape then
                            keybind:Set(key)
                        else
                            keybind:Set(Enum.KeyCode.Unknown)
                        end
                        keybind.listening = false
                        keybindvalue.Color = theme.textcolor
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and keybindholder.Visible then
                        if utility.MouseOverDrawing({
                            keybindholder.Position.X,
                            keybindholder.Position.Y,
                            keybindholder.Position.X + keybindholder.Size.X,
                            keybindholder.Position.Y + keybindholder.Size.Y
                        }) and not window:IsOverContent() then
                            keybind.listening = true
                            keybindvalue.Color = theme.accent
                        end
                    end

                    -- Trigger callback
                    if keybind.value ~= Enum.KeyCode.Unknown then
                        if input.KeyCode == keybind.value or input.UserInputType == keybind.value then
                            pcall(keybindcallback, keybind.value)
                        end
                    end
                end

                -- Initialize
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

    -- Initialize window
    function window:Initialize()
        if window.pages[1] then
            window.pages[1]:Show()
        end

        for i, v in pairs(window.pages) do
            v:Update()
        end

        library.shared.initialized = true

        window:Watermark({name = name})
        window:Cursor()

        window:Fade()

        library:Log("Window initialized", "INFO")
    end

    -- Input connections
    library.began[#library.began + 1] = function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible then
            if utility.MouseOverDrawing({
                mainframe.Position.X,
                mainframe.Position.Y,
                mainframe.Position.X + mainframe.Size.X,
                mainframe.Position.Y + 25
            }) then
                local mouseLocation = utility.MouseLocation()
                window.dragging = true
                window.drag = Vector2.new(mouseLocation.X - mainframe.Position.X, mouseLocation.Y - mainframe.Position.Y)
            end

            -- Tab clicking
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
        if window.dragging and window.isVisible then
            local mouseLocation = utility.MouseLocation()
            local screenSize = utility.GetScreenSize()
            local move = Vector2.new(
                math.clamp(mouseLocation.X - window.drag.X, 5, screenSize.X - mainframe.Size.X - 5),
                math.clamp(mouseLocation.Y - window.drag.Y, 5, screenSize.Y - mainframe.Size.Y - 5)
            )
            window:Move(move)
        end
    end

    library.began[#library.began + 1] = function(input)
        if input.KeyCode == window.uibind then
            window:Fade()
        end
    end

    -- Connect input events
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

    utility.Connection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
        window:Move(Vector2.new(utility.GetScreenSize().X/2 - size.X/2, utility.GetScreenSize().Y/2 - size.Y/2))
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
    local encoded = HttpService:JSONEncode(config)
    writefile(library.folders.configs .. "/" .. name .. ".json", encoded)
    library:Log("Config saved: " .. name, "INFO")
end

function library:LoadConfig(name)
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
end

function library:GetConfigs()
    local configs = {}
    for _, file in pairs(listfiles(library.folders.configs)) do
        if file:sub(-5) == ".json" then
            table.insert(configs, file:match("([^/\]+)%.json$"))
        end
    end
    return configs
end

return library
