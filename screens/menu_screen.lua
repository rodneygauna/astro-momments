-- Menu Screen
-- Handles main menu display and interaction
local MenuScreen = {}

local Save = require("src.save")
local Upgrades = require("src.upgrades")

-- Menu state
local menu = {}
local backgroundImage
local buttonImages = {} -- Store button sprite images
local confirmationDialog = {
    visible = false,
    selectedButton = 1 -- 1 = Yes, 2 = No
}

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

-- Helper function: Draw a button (sprite-based or fallback rectangle)
local function drawButton(button, buttonX, buttonY, isHovered)
    local action = button.action
    local normalImage = buttonImages[action]
    local hoverImage = buttonImages[action .. "Hover"]

    -- Use sprite-based button if images are available
    if normalImage then
        local buttonImage = (isHovered and hoverImage) or normalImage
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(buttonImage, buttonX, buttonY)
    else
        -- Fallback to rectangle-based button
        -- Determine button color
        if not button.enabled then
            love.graphics.setColor(0.3, 0.3, 0.3) -- Disabled
        elseif isHovered then
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
end

-- Helper function: Rebuild button list based on current save state
local function rebuildButtonList()
    menu.buttons = {}

    -- Add Continue button only if save file exists
    if Save.exists() then
        table.insert(menu.buttons, {
            text = "Continue",
            action = "continue",
            enabled = true
        })
    end

    -- Add remaining buttons
    table.insert(menu.buttons, {
        text = "New Game",
        action = "new_game",
        enabled = true
    })
    table.insert(menu.buttons, {
        text = "Settings",
        action = "settings",
        enabled = true
    })
    table.insert(menu.buttons, {
        text = "Credits",
        action = "credits",
        enabled = true
    })
    table.insert(menu.buttons, {
        text = "Exit",
        action = "exit",
        enabled = true
    })

    -- Ensure selectedIndex is valid
    if menu.selectedIndex > #menu.buttons then
        menu.selectedIndex = 1
    end

    -- Start with first enabled button selected if current selection is invalid
    if not menu.buttons[menu.selectedIndex] or not menu.buttons[menu.selectedIndex].enabled then
        menu.selectedIndex = 1
        for i, button in ipairs(menu.buttons) do
            if button.enabled then
                menu.selectedIndex = i
                break
            end
        end
    end
end

-- Initialize menu
function MenuScreen.load(gameStates, changeState)
    -- Load background image
    backgroundImage = love.graphics.newImage("sprites/background/Nebula_God.png")
    backgroundImage:setFilter("nearest", "nearest") -- Prevents blurriness when scaling

    -- Define button image paths
    local continueBtn = "sprites/buttons/Continue_Btn.png"
    local continueBtnHover = "sprites/buttons/Continue-Hover_Btn.png"
    local newGameBtn = "sprites/buttons/NewGame_Btn.png"
    local newGameBtnHover = "sprites/buttons/NewGame-Hover_Btn.png"
    local settingsBtn = "sprites/buttons/Settings_Btn.png"
    local settingsBtnHover = "sprites/buttons/Settings-Hover_Btn.png"
    local creditsBtn = "sprites/buttons/Credits_Btn.png"
    local creditsBtnHover = "sprites/buttons/Credits-Hover_Btn.png"
    local exitBtn = "sprites/buttons/Exit_Btn.png"
    local exitBtnHover = "sprites/buttons/Exit-Hover_Btn.png"

    -- Load button sprite images
    buttonImages = {}

    -- Continue button
    local success, image = pcall(love.graphics.newImage, continueBtn)
    if success then
        buttonImages.continue = image
        buttonImages.continue:setFilter("nearest", "nearest")
        success, image = pcall(love.graphics.newImage, continueBtnHover)
        if success then
            buttonImages.continueHover = image
            buttonImages.continueHover:setFilter("nearest", "nearest")
        end
    end

    -- New Game button
    success, image = pcall(love.graphics.newImage, newGameBtn)
    if success then
        buttonImages.new_game = image
        buttonImages.new_game:setFilter("nearest", "nearest")
        success, image = pcall(love.graphics.newImage, newGameBtnHover)
        if success then
            buttonImages.new_gameHover = image
            buttonImages.new_gameHover:setFilter("nearest", "nearest")
        end
    end

    -- Settings button
    success, image = pcall(love.graphics.newImage, settingsBtn)
    if success then
        buttonImages.settings = image
        buttonImages.settings:setFilter("nearest", "nearest")
        success, image = pcall(love.graphics.newImage, settingsBtnHover)
        if success then
            buttonImages.settingsHover = image
            buttonImages.settingsHover:setFilter("nearest", "nearest")
        end
    end

    -- Credits button
    success, image = pcall(love.graphics.newImage, creditsBtn)
    if success then
        buttonImages.credits = image
        buttonImages.credits:setFilter("nearest", "nearest")
        success, image = pcall(love.graphics.newImage, creditsBtnHover)
        if success then
            buttonImages.creditsHover = image
            buttonImages.creditsHover:setFilter("nearest", "nearest")
        end
    end

    -- Exit button
    success, image = pcall(love.graphics.newImage, exitBtn)
    if success then
        buttonImages.exit = image
        buttonImages.exit:setFilter("nearest", "nearest")
        success, image = pcall(love.graphics.newImage, exitBtnHover)
        if success then
            buttonImages.exitHover = image
            buttonImages.exitHover:setFilter("nearest", "nearest")
        end
    end

    menu = {}
    menu.buttonHeight = 50
    menu.buttonWidth = 200
    menu.buttonSpacing = 10
    menu.gameStates = gameStates
    menu.changeState = changeState
    menu.selectedIndex = 1

    -- Build initial button list
    rebuildButtonList()
end

-- Handle menu button action
local function handleMenuAction(action)
    if not menu.changeState or not menu.gameStates then
        return
    end

    if action == "continue" then
        -- Load save file and continue
        local player, error = Save.read()
        if player then
            -- Recalculate all upgrade effects from skills
            Upgrades.applyUpgradeEffects(player)
            -- Successfully loaded, go to map selection with loaded player
            menu.changeState(menu.gameStates.MAP_SELECTION, player)
        else
            -- Failed to load save
            -- Could show error message to user here
        end
    elseif action == "new_game" then
        -- Check if save file exists
        if Save.exists() then
            -- Show confirmation dialog
            confirmationDialog.visible = true
            confirmationDialog.selectedButton = 1 -- Default to "Yes"
        else
            -- No save file, proceed directly
            menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
        end
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

-- Called when entering the menu screen for the first time
function MenuScreen.enter()
    -- Rebuild button list to reflect current save state
    rebuildButtonList()
end

-- Called when returning to the menu screen from another state
function MenuScreen.resume()
    -- Rebuild button list to reflect current save state
    rebuildButtonList()
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
    love.graphics.setFont(GameFonts.huge)
    love.graphics.printf("Astro Moments", 0, 100, love.graphics.getWidth(), "center")

    -- Reset to default font for buttons
    love.graphics.setFont(GameFonts.large)

    -- Draw buttons
    for i, button in ipairs(menu.buttons) do
        local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
        local buttonY = getButtonY(i, #menu.buttons)
        local isHovered = isMouseOverButton(i) or menu.selectedIndex == i

        drawButton(button, buttonX, buttonY, isHovered)
    end

    -- Draw controls help
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    local controlsY = love.graphics.getHeight() - 50
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE or CLICK] Select  [ESC] Quit", 0, controlsY,
        love.graphics.getWidth(), "center")

    -- Draw confirmation dialog if visible
    if confirmationDialog.visible then
        -- Draw semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        -- Dialog box dimensions
        local dialogWidth = 500
        local dialogHeight = 200
        local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
        local dialogY = (love.graphics.getHeight() - dialogHeight) / 2

        -- Draw dialog background
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight, 10, 10)

        -- Draw dialog border
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight, 10, 10)
        love.graphics.setLineWidth(1)

        -- Draw warning message
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.large)
        love.graphics.printf("Start New Game?", dialogX, dialogY + 20, dialogWidth, "center")

        love.graphics.setFont(GameFonts.medium)
        love.graphics.setColor(1, 0.7, 0.7)
        love.graphics.printf("Your current save file will be deleted.", dialogX + 20, dialogY + 60, dialogWidth - 40,
            "center")
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf("This action cannot be undone.", dialogX + 20, dialogY + 85, dialogWidth - 40, "center")

        -- Draw Yes/No buttons
        local buttonWidth = 120
        local buttonHeight = 40
        local buttonSpacing = 20
        local yesButtonX = dialogX + (dialogWidth / 2) - buttonWidth - (buttonSpacing / 2)
        local noButtonX = dialogX + (dialogWidth / 2) + (buttonSpacing / 2)
        local buttonY = dialogY + dialogHeight - 60

        -- Yes button
        if confirmationDialog.selectedButton == 1 then
            love.graphics.setColor(0.8, 0.3, 0.3) -- Red when selected
        else
            love.graphics.setColor(0.5, 0.2, 0.2)
        end
        love.graphics.rectangle("fill", yesButtonX, buttonY, buttonWidth, buttonHeight, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", yesButtonX, buttonY, buttonWidth, buttonHeight, 5, 5)
        love.graphics.printf("Yes", yesButtonX, buttonY + 10, buttonWidth, "center")

        -- No button
        if confirmationDialog.selectedButton == 2 then
            love.graphics.setColor(0.3, 0.6, 0.3) -- Green when selected
        else
            love.graphics.setColor(0.2, 0.4, 0.2)
        end
        love.graphics.rectangle("fill", noButtonX, buttonY, buttonWidth, buttonHeight, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", noButtonX, buttonY, buttonWidth, buttonHeight, 5, 5)
        love.graphics.printf("No", noButtonX, buttonY + 10, buttonWidth, "center")

        -- Draw dialog controls hint
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(GameFonts.small)
        love.graphics.printf("[LEFT/RIGHT or A/D] Choose  [ENTER/SPACE] Confirm", dialogX, dialogY + dialogHeight - 20,
            dialogWidth, "center")
    end
end

-- Handle keyboard input
function MenuScreen.keypressed(key)
    if not menu or not menu.buttons then
        return
    end

    -- Handle confirmation dialog input separately
    if confirmationDialog.visible then
        if key == "left" or key == "a" then
            confirmationDialog.selectedButton = 1 -- Yes
        elseif key == "right" or key == "d" then
            confirmationDialog.selectedButton = 2 -- No
        elseif key == "return" or key == "space" then
            if confirmationDialog.selectedButton == 1 then
                -- Yes - Delete save and start new game
                Save.delete()
                confirmationDialog.visible = false
                menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
            else
                -- No - Close dialog
                confirmationDialog.visible = false
            end
        elseif key == "escape" then
            -- ESC also closes dialog (acts as "No")
            confirmationDialog.visible = false
        end
        return
    end

    -- Normal menu navigation
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
        -- Handle confirmation dialog clicks
        if confirmationDialog.visible then
            local dialogWidth = 500
            local dialogHeight = 200
            local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
            local dialogY = (love.graphics.getHeight() - dialogHeight) / 2

            local buttonWidth = 120
            local buttonHeight = 40
            local buttonSpacing = 20
            local yesButtonX = dialogX + (dialogWidth / 2) - buttonWidth - (buttonSpacing / 2)
            local noButtonX = dialogX + (dialogWidth / 2) + (buttonSpacing / 2)
            local buttonY = dialogY + dialogHeight - 60

            -- Check Yes button click
            if x >= yesButtonX and x <= yesButtonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                -- Yes - Delete save and start new game
                Save.delete()
                confirmationDialog.visible = false
                menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
                return
            end

            -- Check No button click
            if x >= noButtonX and x <= noButtonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                -- No - Close dialog
                confirmationDialog.visible = false
                return
            end

            -- Click outside dialog closes it
            if x < dialogX or x > dialogX + dialogWidth or y < dialogY or y > dialogY + dialogHeight then
                confirmationDialog.visible = false
            end
            return
        end

        -- Normal menu button clicks
        for i, menuButton in ipairs(menu.buttons) do
            if menuButton.enabled and isMouseOverButton(i) then
                handleMenuAction(menuButton.action)
                break
            end
        end
    end
end

return MenuScreen
