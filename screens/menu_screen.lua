-- Menu Screen
-- Handles main menu display and interaction
local MenuScreen = {}

-- Menu state
local menu = {}
local backgroundImage

-- Helper function: Get menu button Y position
local function getButtonY(index, totalButtons)
    local totalHeight = (totalButtons * menu.buttonHeight) + ((totalButtons - 1) * menu.buttonSpacing)
    local startY = (love.graphics.getHeight() - totalHeight) / 2
    return startY + (index - 1) * (menu.buttonHeight + menu.buttonSpacing)
end

-- Helper function: Check if mouse is over a button
local function isMouseOverButton(buttonIndex)
    local mouseX, mouseY = love.mouse.getPosition()
    local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
    local buttonY = getButtonY(buttonIndex, #menu.buttons)

    return mouseX >= buttonX and mouseX <= buttonX + menu.buttonWidth and mouseY >= buttonY and mouseY <= buttonY +
               menu.buttonHeight
end

-- Initialize menu
function MenuScreen.load(gameStates, changeState)
    -- Load background image
    backgroundImage = love.graphics.newImage("sprites/Nebula_God.png")
    backgroundImage:setFilter("nearest", "nearest") -- Prevents blurriness when scaling

    menu = {}
    menu.buttons = {{
        text = "Continue",
        action = "continue",
        enabled = false -- Will be enabled when save file exists
    }, {
        text = "New Game",
        action = "new_game",
        enabled = true
    }, {
        text = "Settings",
        action = "settings",
        enabled = true
    }, {
        text = "Credits",
        action = "credits",
        enabled = true
    }, {
        text = "Exit",
        action = "exit",
        enabled = true
    }}
    menu.selectedIndex = 2 -- Start with "New Game" selected (first enabled button)
    menu.buttonHeight = 50
    menu.buttonWidth = 200
    menu.buttonSpacing = 10
    menu.gameStates = gameStates
    menu.changeState = changeState
end

-- Handle menu button action
local function handleMenuAction(action)
    if not menu.changeState or not menu.gameStates then
        print("Error: menu.changeState or menu.gameStates is nil")
        return
    end

    if action == "continue" then
        -- Load save file and continue
        menu.changeState(menu.gameStates.SKILL_TREE)
    elseif action == "new_game" then
        -- Reset player progress and start new game
        menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
    elseif action == "settings" then
        menu.changeState(menu.gameStates.SETTINGS)
    elseif action == "credits" then
        menu.changeState(menu.gameStates.CREDITS)
    elseif action == "exit" then
        love.event.quit()
    end
end

-- Update menu (currently no animation/logic needed)
function MenuScreen.update(dt)
    -- Future: Add menu animations, background effects, etc.
end

-- Draw menu
function MenuScreen.draw()
    -- Draw background image (scaled to fit screen)
    if backgroundImage then
        local scaleX = love.graphics.getWidth() / backgroundImage:getWidth()
        local scaleY = love.graphics.getHeight() / backgroundImage:getHeight()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(backgroundImage, 0, 0, 0, scaleX, scaleY)
    end

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(48)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Astro Moments", 0, 100, love.graphics.getWidth(), "center")

    -- Reset to default font for buttons
    love.graphics.setFont(love.graphics.newFont(20))

    -- Draw buttons
    for i, button in ipairs(menu.buttons) do
        local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
        local buttonY = getButtonY(i, #menu.buttons)

        -- Determine button color
        if not button.enabled then
            love.graphics.setColor(0.3, 0.3, 0.3) -- Disabled
        elseif isMouseOverButton(i) or menu.selectedIndex == i then
            love.graphics.setColor(0.7, 0.7, 1) -- Highlighted
        else
            love.graphics.setColor(0.5, 0.5, 0.5) -- Normal
        end

        -- Draw button background
        love.graphics.rectangle("fill", buttonX, buttonY, menu.buttonWidth, menu.buttonHeight)

        -- Draw button border
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", buttonX, buttonY, menu.buttonWidth, menu.buttonHeight)

        -- Draw button text
        local textColor = button.enabled and {1, 1, 1} or {0.5, 0.5, 0.5}
        love.graphics.setColor(textColor)
        love.graphics.printf(button.text, buttonX, buttonY + (menu.buttonHeight - 20) / 2, menu.buttonWidth, "center")
    end

    -- Draw controls help
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(14))
    local controlsY = love.graphics.getHeight() - 50
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE or CLICK] Select  [ESC] Quit", 0, controlsY,
        love.graphics.getWidth(), "center")
end

-- Handle keyboard input
function MenuScreen.keypressed(key)
    if not menu or not menu.buttons then
        return
    end

    if key == "up" or key == "w" then
        -- Move selection up (skip disabled buttons)
        repeat
            menu.selectedIndex = menu.selectedIndex - 1
            if menu.selectedIndex < 1 then
                menu.selectedIndex = #menu.buttons
            end
        until menu.buttons[menu.selectedIndex].enabled
    elseif key == "down" or key == "s" then
        -- Move selection down (skip disabled buttons)
        repeat
            menu.selectedIndex = menu.selectedIndex + 1
            if menu.selectedIndex > #menu.buttons then
                menu.selectedIndex = 1
            end
        until menu.buttons[menu.selectedIndex].enabled
    elseif key == "return" or key == "space" then
        if menu.buttons[menu.selectedIndex] then
            handleMenuAction(menu.buttons[menu.selectedIndex].action)
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

-- Handle mouse input
function MenuScreen.mousepressed(x, y, button)
    if not menu or not menu.buttons then
        return
    end

    if button == 1 then
        for i, menuButton in ipairs(menu.buttons) do
            if menuButton.enabled and isMouseOverButton(i) then
                handleMenuAction(menuButton.action)
                break
            end
        end
    end
end

return MenuScreen
