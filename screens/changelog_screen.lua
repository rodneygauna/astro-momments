-- Changelog Screen
-- Displays version history and changelog
local ChangelogScreen = {}

local Version = require("src.version")

local scrollOffset = 0
local maxScroll = 0
local contentHeight = 0

-- Initialize changelog screen
function ChangelogScreen.load(gameStates, changeState)
    ChangelogScreen.gameStates = gameStates
    ChangelogScreen.changeState = changeState
end

-- Called when entering the changelog screen
function ChangelogScreen.enter()
    scrollOffset = 0
    contentHeight = 0
end

-- Draw a single changelog entry
local function drawChangelogEntry(entry, startY)
    local x = 100
    local maxWidth = love.graphics.getWidth() - 200
    local lineHeight = 30

    -- Version header
    love.graphics.setFont(GameFonts.large)
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.print("v" .. entry.version, x, startY)

    love.graphics.setFont(GameFonts.medium)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(entry.date, x + 200, startY + 5)

    startY = startY + 60

    -- Highlights section
    if entry.highlights and #entry.highlights > 0 then
        love.graphics.setFont(GameFonts.medium)
        for _, highlight in ipairs(entry.highlights) do
            -- Draw asteroid bullet point (jagged polygon like in-game)
            local asteroidX = x + 30
            local asteroidY = startY + 10
            local baseRadius = 6
            local numVertices = 7
            local vertices = {}

            -- Generate jagged vertices
            for i = 1, numVertices do
                local angleStep = (2 * math.pi) / numVertices
                local angle = (i - 1) * angleStep
                local radiusVariation = baseRadius * (0.7 + ((i * 13) % 10) / 16.0) -- Deterministic variation
                table.insert(vertices, asteroidX + math.cos(angle) * radiusVariation)
                table.insert(vertices, asteroidY + math.sin(angle) * radiusVariation)
            end

            -- Draw filled polygon
            love.graphics.setColor(0.5, 0.4, 0.3)
            love.graphics.polygon("fill", vertices)

            -- Draw outline
            love.graphics.setColor(0.7, 0.6, 0.5)
            love.graphics.polygon("line", vertices)

            -- Draw highlight text
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.print(highlight, x + 45, startY)
            startY = startY + lineHeight
        end
        startY = startY + 20
    end

    -- ADDED section
    if entry.changes.added and #entry.changes.added > 0 then
        love.graphics.setFont(GameFonts.medium)
        love.graphics.setColor(0.4, 1, 0.4)
        love.graphics.print("ADDED:", x + 20, startY)
        startY = startY + lineHeight

        love.graphics.setFont(GameFonts.small)
        for _, item in ipairs(entry.changes.added) do
            love.graphics.setColor(0.9, 0.9, 0.9)

            -- Word wrap long items
            local wrappedText, wrappedLines = GameFonts.small:getWrap(item, maxWidth - 60)
            for _, line in ipairs(wrappedLines) do
                love.graphics.print("  + " .. line, x + 40, startY)
                startY = startY + 25
            end
        end
        startY = startY + 15
    end

    -- FIXED section
    if entry.changes.fixed and #entry.changes.fixed > 0 then
        love.graphics.setFont(GameFonts.medium)
        love.graphics.setColor(1, 0.6, 0.4)
        love.graphics.print("FIXED:", x + 20, startY)
        startY = startY + lineHeight

        love.graphics.setFont(GameFonts.small)
        for _, item in ipairs(entry.changes.fixed) do
            love.graphics.setColor(0.9, 0.9, 0.9)

            -- Word wrap long items
            local wrappedText, wrappedLines = GameFonts.small:getWrap(item, maxWidth - 60)
            for _, line in ipairs(wrappedLines) do
                love.graphics.print("  • " .. line, x + 40, startY)
                startY = startY + 25
            end
        end
        startY = startY + 15
    end

    -- CHANGED section
    if entry.changes.changed and #entry.changes.changed > 0 then
        love.graphics.setFont(GameFonts.medium)
        love.graphics.setColor(0.6, 0.8, 1)
        love.graphics.print("CHANGED:", x + 20, startY)
        startY = startY + lineHeight

        love.graphics.setFont(GameFonts.small)
        for _, item in ipairs(entry.changes.changed) do
            love.graphics.setColor(0.9, 0.9, 0.9)

            -- Word wrap long items
            local wrappedText, wrappedLines = GameFonts.small:getWrap(item, maxWidth - 60)
            for _, line in ipairs(wrappedLines) do
                love.graphics.print("  ~ " .. line, x + 40, startY)
                startY = startY + 25
            end
        end
        startY = startY + 15
    end

    return startY
end

-- Draw changelog screen
function ChangelogScreen.draw()
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Title
    love.graphics.setFont(GameFonts.huge)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CHANGELOG", 0, 30, love.graphics.getWidth(), "center")

    -- Current version info
    love.graphics.setFont(GameFonts.medium)
    love.graphics.setColor(0.6, 0.8, 1)
    love.graphics.printf("Current Version: v" .. Version.current, 0, 90, love.graphics.getWidth(), "center")

    -- Scissor for scrollable content
    local contentY = 140
    local contentMaxHeight = love.graphics.getHeight() - contentY - 80
    love.graphics.setScissor(0, contentY, love.graphics.getWidth(), contentMaxHeight)

    -- Draw all changelog entries
    local entries = Version.getAllChanges()
    local startY = contentY - scrollOffset

    for i, entry in ipairs(entries) do
        startY = drawChangelogEntry(entry, startY)
        startY = startY + 40 -- Spacing between entries
    end

    contentHeight = startY - (contentY - scrollOffset)
    maxScroll = math.max(0, contentHeight - contentMaxHeight)

    love.graphics.setScissor()

    -- Draw scrollbar if content exceeds visible area
    if maxScroll > 0 then
        local scrollbarX = love.graphics.getWidth() - 30
        local scrollbarY = contentY
        local scrollbarWidth = 8
        local scrollbarHeight = contentMaxHeight

        -- Scrollbar background
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 4, 4)

        -- Scrollbar thumb
        local thumbHeight = (contentMaxHeight / contentHeight) * scrollbarHeight
        local thumbY = scrollbarY + (scrollOffset / maxScroll) * (scrollbarHeight - thumbHeight)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 4, 4)
    end

    -- Back button hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf("[ESC] Back to Menu  [UP/DOWN or SCROLL] Navigate", 0, love.graphics.getHeight() - 50,
        love.graphics.getWidth(), "center")
end

-- Update (for smooth scrolling if needed)
function ChangelogScreen.update(dt)
    -- Currently no updates needed
end

-- Handle keyboard input
function ChangelogScreen.keypressed(key)
    if key == "escape" then
        if ChangelogScreen.changeState and ChangelogScreen.gameStates then
            ChangelogScreen.changeState(ChangelogScreen.gameStates.MENU)
        end
    elseif key == "up" or key == "w" then
        scrollOffset = math.max(0, scrollOffset - 50)
    elseif key == "down" or key == "s" then
        scrollOffset = math.min(maxScroll, scrollOffset + 50)
    elseif key == "pageup" then
        scrollOffset = math.max(0, scrollOffset - 200)
    elseif key == "pagedown" then
        scrollOffset = math.min(maxScroll, scrollOffset + 200)
    elseif key == "home" then
        scrollOffset = 0
    elseif key == "end" then
        scrollOffset = maxScroll
    end
end

-- Handle mouse wheel scrolling
function ChangelogScreen.wheelmoved(x, y)
    scrollOffset = math.max(0, math.min(maxScroll, scrollOffset - y * 30))
end

-- Handle mouse clicks
function ChangelogScreen.mousepressed(x, y, button)
    -- Could add click zones if needed
end

return ChangelogScreen
