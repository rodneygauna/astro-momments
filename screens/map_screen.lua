-- Map Selection Screen
-- Displays available sectors and allows player to select one
local MapScreen = {}

local Player = require("src/player")
local Sector = require("src/sector")

-- Map screen state
local player
local gameStates
local changeState
local sectorButtons
local hoveredButton

-- Initialize map screen
function MapScreen.load(playerData, states, stateChanger)
    player = playerData
    gameStates = states
    changeState = stateChanger
    hoveredButton = nil

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

    for _, button in ipairs(sectorButtons) do
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

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT SECTOR", 0, 30, love.graphics.getWidth(), "center")

    -- Draw fuel display
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.printf("Fuel: " .. player.currency.fuel, 0, 70, love.graphics.getWidth(), "center")

    -- Draw sector buttons
    for _, button in ipairs(sectorButtons) do
        local isHovered = (hoveredButton == button)

        -- Determine button color based on state
        local bgColor, textColor
        if button.isUnlocked then
            -- Unlocked sector
            if isHovered then
                bgColor = {0.3, 0.5, 0.8}
            else
                bgColor = {0.2, 0.4, 0.7}
            end
            textColor = {1, 1, 1}
        else
            -- Locked sector
            if button.canAfford then
                -- Can afford to unlock
                if isHovered then
                    bgColor = {0.5, 0.5, 0.3}
                else
                    bgColor = {0.4, 0.4, 0.2}
                end
                textColor = {1, 1, 0.7}
            else
                -- Cannot afford
                bgColor = {0.2, 0.2, 0.2}
                textColor = {0.5, 0.5, 0.5}
            end
        end

        -- Draw button background
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 5, 5)

        -- Draw button border
        if isHovered then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 5, 5)
        love.graphics.setLineWidth(1)

        -- Draw sector name
        love.graphics.setColor(textColor)
        love.graphics.printf(button.sector.name, button.x + 10, button.y + 10, button.width - 20, "left")

        -- Draw sector info
        if button.isUnlocked then
            -- Show fuel cost
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf("Fuel Cost: " .. button.sector.fuel_cost, button.x + 10, button.y + 35,
                button.width - 20, "left")
        else
            -- Show unlock cost
            love.graphics.setColor(textColor[1] * 0.8, textColor[2] * 0.8, textColor[3] * 0.8)
            love.graphics.printf("🔒 Unlock: " .. button.sector.unlock_cost .. " Gold", button.x + 10, button.y + 35,
                button.width - 20, "left")
        end
    end

    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Click a sector to travel | ESC to return to menu", 0, love.graphics.getHeight() - 40,
        love.graphics.getWidth(), "center")
end

-- Handle keyboard input
function MapScreen.keypressed(key)
    if key == "escape" then
        changeState(gameStates.MENU)
    end
end

-- Handle mouse input
function MapScreen.mousepressed(x, y, button)
    if button == 1 and hoveredButton then
        local btn = hoveredButton

        if btn.isUnlocked then
            -- Check if player has enough fuel
            if player.currency.fuel >= btn.sector.fuel_cost then
                -- Deduct fuel and start mining
                Player.purchase(player, 0, btn.sector.fuel_cost)
                changeState(gameStates.MINING, btn.sectorId)
            else
                -- Not enough fuel (could show error message)
                print("Not enough fuel!")
            end
        else
            -- Try to unlock sector
            if Player.canAfford(player, btn.sector.unlock_cost, 0) then
                Player.purchase(player, btn.sector.unlock_cost, 0)
                Player.unlockMap(player, btn.sectorId)
                -- Refresh button state
                btn.isUnlocked = true
                btn.canAfford = Player.canAfford(player, btn.sector.unlock_cost, 0)
            else
                -- Cannot afford (could show error message)
                print("Cannot afford to unlock!")
            end
        end
    end
end

return MapScreen
