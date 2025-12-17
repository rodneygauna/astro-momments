-- Map Selection Screen
-- Displays available sectors and allows player to select one
local MapScreen = {}

local Player = require("src/player")
local Sector = require("src/sector")
local Save = require("src/save")
local Upgrades = require("src/upgrades")

-- Map screen state
local player
local gameStates
local changeState
local sectorButtons
local hoveredButton
local upgradeButton
local refuelButton
local scrollOffset
local maxVisibleSectors
local selectedIndex
local sectorButtonNormalImage
local sectorButtonHoverImage

-- Initialize map screen
function MapScreen.load(playerData, states, stateChanger)
    player = playerData
    gameStates = states
    changeState = stateChanger

    -- Ensure upgrade effects are applied to player stats
    Upgrades.applyUpgradeEffects(player)

    -- Load sector button images
    sectorButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_500x60.png")
    sectorButtonNormalImage:setFilter("nearest", "nearest")
    sectorButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_500x60.png")
    sectorButtonHoverImage:setFilter("nearest", "nearest")

    hoveredButton = nil
    scrollOffset = 0
    maxVisibleSectors = 6 -- Show 6 sectors at a time
    selectedIndex = 1 -- Start with first sector selected

    -- Create upgrade button
    upgradeButton = {
        x = 20,
        y = 20,
        width = 150,
        height = 50,
        text = "UPGRADES"
    }

    -- Create refuel button (positioned in right corner, opposite of upgrade button)
    refuelButton = {
        x = love.graphics.getWidth() - 220,
        y = 20,
        width = 200,
        height = 50,
        text = "REFUEL"
    }

    -- Create sector buttons
    sectorButtons = {}
    local buttonWidth = 500
    local buttonHeight = 60
    local buttonSpacing = 10
    local startX = (love.graphics.getWidth() - buttonWidth) / 2
    local startY = 120
    local currentY = startY

    -- Create buttons for each sector
    for i = 1, 10 do
        local sectorId = "sector_" .. string.format("%02d", i)
        local sector = Sector.definitions[sectorId]

        if sector then
            local isUnlocked = Player.isMapUnlocked(player, sectorId)

            table.insert(sectorButtons, {
                x = startX,
                y = currentY,
                width = buttonWidth,
                height = buttonHeight,
                sectorId = sectorId,
                sector = sector,
                isUnlocked = isUnlocked,
                canAfford = Player.canAfford(player, sector.unlock_cost, 0)
            })

            currentY = currentY + buttonHeight + buttonSpacing
        end
    end
end

-- Update map screen
function MapScreen.update(dt)
    -- Update hovered button
    local mouseX, mouseY = love.mouse.getPosition()
    hoveredButton = nil

    -- Check upgrade button hover
    if mouseX >= upgradeButton.x and mouseX <= upgradeButton.x + upgradeButton.width and mouseY >= upgradeButton.y and
        mouseY <= upgradeButton.y + upgradeButton.height then
        hoveredButton = upgradeButton
        return
    end

    -- Check refuel button hover
    if mouseX >= refuelButton.x and mouseX <= refuelButton.x + refuelButton.width and mouseY >= refuelButton.y and
        mouseY <= refuelButton.y + refuelButton.height then
        hoveredButton = refuelButton
        return
    end

    -- Only check visible sector buttons for hover
    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleSectors, #sectorButtons)

    for i = startIndex, endIndex do
        local button = sectorButtons[i]
        if mouseX >= button.x and mouseX <= button.x + button.width and mouseY >= button.y and mouseY <= button.y +
            button.height then
            hoveredButton = button
            break
        end
    end
end

-- Draw map screen
function MapScreen.draw()
    -- Draw background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw upgrade button
    local isUpgradeHovered = (hoveredButton == upgradeButton)
    if isUpgradeHovered then
        love.graphics.setColor(0.4, 0.6, 0.9)
    else
        love.graphics.setColor(0.3, 0.5, 0.8)
    end
    love.graphics.rectangle("fill", upgradeButton.x, upgradeButton.y, upgradeButton.width, upgradeButton.height, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(upgradeButton.text, upgradeButton.x, upgradeButton.y + 15, upgradeButton.width, "center")

    -- Draw refuel button
    local isRefuelHovered = (hoveredButton == refuelButton)
    local needsEmergency = Player.needsEmergencyBeacon(player)
    local cost, fuelGained = Player.calculateRefuelCost(player)
    local canRefuel = cost > 0 and fuelGained > 0 and player.currency.gold >= cost

    -- Determine button state and text
    local buttonText, buttonColor, textColor
    if needsEmergency then
        -- Emergency beacon mode
        buttonText = "EMERGENCY BEACON"
        if isRefuelHovered then
            buttonColor = {0.9, 0.4, 0.4}
        else
            buttonColor = {0.8, 0.3, 0.3}
        end
        textColor = {1, 1, 1}
    elseif fuelGained == 0 then
        -- Already at max fuel
        buttonText = "REFUEL (FULL)"
        buttonColor = {0.3, 0.3, 0.3}
        textColor = {0.6, 0.6, 0.6}
    elseif player.currency.gold == 0 then
        -- No gold - show disabled
        buttonText = "Refuel (+" .. fuelGained .. "): " .. cost .. "g"
        buttonColor = {0.3, 0.3, 0.3}
        textColor = {0.6, 0.6, 0.6}
    else
        -- Normal refuel mode
        buttonText = "Refuel (+" .. fuelGained .. "): " .. cost .. "g"
        if isRefuelHovered then
            buttonColor = {0.4, 0.7, 0.4}
        else
            buttonColor = {0.3, 0.6, 0.3}
        end
        textColor = {1, 1, 1}
    end

    -- Draw button
    love.graphics.setColor(buttonColor)
    love.graphics.rectangle("fill", refuelButton.x, refuelButton.y, refuelButton.width, refuelButton.height, 5, 5)
    love.graphics.setColor(textColor)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf(buttonText, refuelButton.x, refuelButton.y + 18, refuelButton.width, "center")
    love.graphics.setFont(GameFonts.medium)

    -- Draw gold display next to upgrade button
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.printf("Gold: " .. player.currency.gold, upgradeButton.x + upgradeButton.width + 20,
        upgradeButton.y + 15, 200, "left")

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT SECTOR", 0, 30, love.graphics.getWidth(), "center")

    -- Draw fuel display
    love.graphics.setColor(0.3, 0.8, 1)
    local maxFuel = Player.getMaxFuel(player)
    love.graphics
        .printf("Fuel: " .. player.currency.fuel .. " / " .. maxFuel, 0, 70, love.graphics.getWidth(), "center")

    -- Calculate visible range
    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleSectors, #sectorButtons)

    -- Draw sector buttons (only visible ones)
    for i = startIndex, endIndex do
        local button = sectorButtons[i]
        local isHovered = (hoveredButton == button) or (selectedIndex == i)

        -- Recalculate button Y position for scrolling
        local buttonWidth = 500
        local buttonHeight = 60
        local buttonSpacing = 10
        local startX = (love.graphics.getWidth() - buttonWidth) / 2
        local startY = 120
        button.y = startY + ((i - scrollOffset - 1) * (buttonHeight + buttonSpacing))

        -- Draw button sprite
        local buttonImage = isHovered and sectorButtonHoverImage or sectorButtonNormalImage
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(buttonImage, button.x, button.y)

        -- Determine text color based on state
        local textColor
        if button.isUnlocked then
            textColor = {1, 1, 1}
        else
            if button.canAfford then
                textColor = {1, 1, 0.7}
            else
                textColor = {0.5, 0.5, 0.5}
            end
        end

        -- Draw sector name
        love.graphics.setColor(textColor)
        love.graphics.printf(button.sector.name, button.x + 10, button.y + 10, button.width - 20, "left")

        -- Draw sector info
        if button.isUnlocked then
            -- Calculate actual fuel cost with efficiency upgrade
            local fuelEfficiency = (player.stats.fuelEfficiency or 0) / 100
            local actualFuelCost = math.ceil(button.sector.fuel_cost * (1 - fuelEfficiency))

            -- Show fuel cost
            love.graphics.setColor(0.7, 0.7, 0.7)
            local fuelText = "Fuel Cost: " .. actualFuelCost
            if fuelEfficiency > 0 then
                fuelText = fuelText .. " (" .. button.sector.fuel_cost .. " -" .. math.floor(fuelEfficiency * 100) ..
                               "%)"
            end
            love.graphics.printf(fuelText, button.x + 10, button.y + 35, button.width - 20, "left")
        else
            -- Show unlock cost
            love.graphics.setColor(textColor[1] * 0.8, textColor[2] * 0.8, textColor[3] * 0.8)
            love.graphics.printf("🔒 Unlock: " .. button.sector.unlock_cost .. " Gold", button.x + 10, button.y + 35,
                button.width - 20, "left")
        end
    end

    -- Draw scrollbar if needed
    if #sectorButtons > maxVisibleSectors then
        local buttonWidth = 500
        local buttonHeight = 60
        local buttonSpacing = 10
        local startX = (love.graphics.getWidth() - buttonWidth) / 2
        local listHeight = maxVisibleSectors * (buttonHeight + buttonSpacing)

        local scrollbarX = startX + buttonWidth + 10
        local scrollbarY = 120
        local scrollbarWidth = 8
        local scrollbarHeight = listHeight

        -- Scrollbar background
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 4, 4)

        -- Scrollbar thumb
        local thumbHeight = (maxVisibleSectors / #sectorButtons) * scrollbarHeight
        local thumbY = scrollbarY + (scrollOffset / (#sectorButtons - maxVisibleSectors)) *
                           (scrollbarHeight - thumbHeight)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 4, 4)
    end

    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE] Select  [U] Upgrades  [R] Refuel  [ESC] Menu", 0,
        love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

-- Handle keyboard input
function MapScreen.keypressed(key)
    if key == "escape" then
        changeState(gameStates.MENU)
    elseif key == "u" then
        changeState(gameStates.SKILL_TREE)
    elseif key == "r" then
        -- Handle refuel or emergency beacon
        if Player.needsEmergencyBeacon(player) then
            local success, message = Player.useEmergencyBeacon(player)
            if success then
                -- Save player progress
                Save.write(player)
            end
        else
            local success, message = Player.refuel(player)
            if success then
                -- Save player progress
                Save.write(player)
                -- Navigate to buff selection after refueling
                changeState(gameStates.ROUND_START_BUFF_SELECTION)
            end
        end
    elseif key == "w" or key == "up" then
        -- Navigate up
        if selectedIndex > 1 then
            selectedIndex = selectedIndex - 1
            -- Auto-scroll to keep selected button visible
            if selectedIndex < scrollOffset + 1 then
                scrollOffset = selectedIndex - 1
            end
        end
    elseif key == "s" or key == "down" then
        -- Navigate down
        if selectedIndex < #sectorButtons then
            selectedIndex = selectedIndex + 1
            -- Auto-scroll to keep selected button visible
            if selectedIndex > scrollOffset + maxVisibleSectors then
                scrollOffset = selectedIndex - maxVisibleSectors
            end
        end
    elseif key == "return" or key == "space" then
        -- Select the currently highlighted sector
        local btn = sectorButtons[selectedIndex]

        if btn.isUnlocked then
            -- Calculate actual fuel cost with efficiency upgrade
            local fuelEfficiency = (player.stats.fuelEfficiency or 0) / 100
            local actualFuelCost = math.ceil(btn.sector.fuel_cost * (1 - fuelEfficiency))

            -- Check if player has enough fuel
            if player.currency.fuel >= actualFuelCost then
                -- Deduct fuel and start mining
                Player.purchase(player, 0, actualFuelCost)
                changeState(gameStates.MINING, btn.sectorId)
            else
                -- Not enough fuel (could show error message)
            end
        else
            -- Try to unlock sector
            if Player.canAfford(player, btn.sector.unlock_cost, 0) then
                Player.purchase(player, btn.sector.unlock_cost, 0)
                Player.unlockMap(player, btn.sectorId)
                -- Refresh button state
                btn.isUnlocked = true
                btn.canAfford = Player.canAfford(player, btn.sector.unlock_cost, 0)

                -- Save player progress
                Save.write(player)
            else
                -- Cannot afford (could show error message)
            end
        end
    end
end

-- Handle mouse input
function MapScreen.mousepressed(x, y, button)
    if button == 1 then
        -- Check if upgrade button was clicked
        if x >= upgradeButton.x and x <= upgradeButton.x + upgradeButton.width and y >= upgradeButton.y and y <=
            upgradeButton.y + upgradeButton.height then
            changeState(gameStates.SKILL_TREE)
            return
        end

        -- Check if refuel button was clicked
        if x >= refuelButton.x and x <= refuelButton.x + refuelButton.width and y >= refuelButton.y and y <=
            refuelButton.y + refuelButton.height then
            if Player.needsEmergencyBeacon(player) then
                local success, message = Player.useEmergencyBeacon(player)
                if success then
                    print(message)
                    -- Save player progress
                    local saveSuccess, saveError = Save.write(player)
                    if not saveSuccess then
                        print("Failed to save player data:", saveError)
                    end
                end
            else
                local success, message = Player.refuel(player)
                if success then
                    print(message)
                    -- Save player progress
                    local saveSuccess, saveError = Save.write(player)
                    if not saveSuccess then
                        print("Failed to save player data:", saveError)
                    end
                    -- Navigate to buff selection after refueling
                    changeState(gameStates.ROUND_START_BUFF_SELECTION)
                else
                    print(message)
                end
            end
            return
        end

        -- Check sector buttons
        if hoveredButton and hoveredButton ~= upgradeButton then
            local btn = hoveredButton

            if btn.isUnlocked then
                -- Calculate actual fuel cost with efficiency upgrade
                local fuelEfficiency = (player.stats.fuelEfficiency or 0) / 100
                local actualFuelCost = math.ceil(btn.sector.fuel_cost * (1 - fuelEfficiency))

                -- Check if player has enough fuel
                if player.currency.fuel >= actualFuelCost then
                    -- Deduct fuel and start mining
                    Player.purchase(player, 0, actualFuelCost)
                    changeState(gameStates.MINING, btn.sectorId)
                else
                    -- Not enough fuel (could show error message)
                end
            else
                -- Try to unlock sector
                if Player.canAfford(player, btn.sector.unlock_cost, 0) then
                    Player.purchase(player, btn.sector.unlock_cost, 0)
                    Player.unlockMap(player, btn.sectorId)
                    -- Refresh button state
                    btn.isUnlocked = true
                    btn.canAfford = Player.canAfford(player, btn.sector.unlock_cost, 0)

                    -- Save player progress
                    Save.write(player)
                else
                    -- Cannot afford (could show error message)
                end
            end
        end
    end
end

return MapScreen
