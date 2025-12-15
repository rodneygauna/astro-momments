-- Upgrade Screen
-- Displays available upgrades and allows purchasing permanent stat boosts
local UpgradeScreen = {}

local Upgrades = require("src/upgrades")
local Save = require("src/save")

-- Screen state
local player
local gameStates
local changeState
local selectedUpgradeId
local upgradeList -- Ordered list of upgrade IDs for navigation
local selectedIndex
local scrollOffset
local maxVisibleUpgrades
local categoryColors

-- Initialize upgrade screen
function UpgradeScreen.load(playerData, states, stateChanger)
    player = playerData
    gameStates = states
    changeState = stateChanger
    selectedIndex = 1
    scrollOffset = 0
    maxVisibleUpgrades = 6

    -- Build ordered upgrade list (12 total upgrades)
    upgradeList = {"engine_boost", "thruster_efficiency", "magnetic_field", "collection_speed", "decay_resistance",
                   "auto_collect", "cargo_expansion", "cashout_multiplier", "extended_mission", "fuel_efficiency",
                   "fuel_tank_expansion", "asteroid_density"}

    selectedUpgradeId = upgradeList[selectedIndex]

    -- Category colors for visual organization
    categoryColors = {
        movement = {0.3, 0.7, 1.0}, -- Blue
        collection = {0.3, 1.0, 0.5}, -- Green
        cargo = {1.0, 0.8, 0.3}, -- Orange
        economy = {1.0, 0.8, 0.0}, -- Gold
        time = {0.8, 0.3, 1.0}, -- Purple
        efficiency = {0.5, 0.9, 0.9}, -- Cyan
        spawning = {1.0, 0.5, 0.5} -- Red
    }

    -- Apply all upgrade effects to player stats
    Upgrades.applyUpgradeEffects(player)
end

-- Handle navigation
local function navigateUp()
    if selectedIndex > 1 then
        selectedIndex = selectedIndex - 1
        selectedUpgradeId = upgradeList[selectedIndex]

        -- Adjust scroll if needed
        if selectedIndex < scrollOffset + 1 then
            scrollOffset = selectedIndex - 1
        end
    end
end

local function navigateDown()
    if selectedIndex < #upgradeList then
        selectedIndex = selectedIndex + 1
        selectedUpgradeId = upgradeList[selectedIndex]

        -- Adjust scroll if needed
        if selectedIndex > scrollOffset + maxVisibleUpgrades then
            scrollOffset = selectedIndex - maxVisibleUpgrades
        end
    end
end

-- Attempt to purchase selected upgrade
local function purchaseUpgrade()
    local success, message = Upgrades.purchase(player, selectedUpgradeId)

    if success then
        -- Play purchase sound (TODO)
        -- Save player progress
        Save.write(player)
    else
        -- Play error sound (TODO)
    end
end

-- Return to previous screen
local function exitUpgradeScreen()
    changeState(gameStates.MAP_SELECTION)
end

-- Update upgrade screen
function UpgradeScreen.update(dt)
    -- Nothing to update currently
end

-- Draw upgrade screen
function UpgradeScreen.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(36)
    love.graphics.setFont(titleFont)
    love.graphics.printf("UPGRADE STATION", 0, 30, screenWidth, "center")

    -- Draw player currency
    local defaultFont = love.graphics.newFont(18)
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.printf("Gold: " .. player.currency.gold, 0, 80, screenWidth, "center")

    -- Layout dimensions
    local listPanelX = 50
    local listPanelY = 130
    local listPanelWidth = 400
    local listPanelHeight = screenHeight - 200

    local detailPanelX = listPanelX + listPanelWidth + 20
    local detailPanelY = 130
    local detailPanelWidth = screenWidth - detailPanelX - 50
    local detailPanelHeight = screenHeight - 200

    -- Draw upgrade list panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", listPanelX, listPanelY, listPanelWidth, listPanelHeight, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", listPanelX, listPanelY, listPanelWidth, listPanelHeight, 8, 8)

    -- Draw upgrade list items
    local itemHeight = 70
    local itemPadding = 10
    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleUpgrades, #upgradeList)

    for i = startIndex, endIndex do
        local upgradeId = upgradeList[i]
        local upgrade = Upgrades.catalog[upgradeId]
        local currentLevel = Upgrades.getPlayerUpgradeLevel(player, upgradeId)
        local cost = Upgrades.getCost(upgradeId, currentLevel)
        local canAfford = Upgrades.canAfford(player, upgradeId)
        local isMaxLevel = currentLevel >= upgrade.maxLevel

        local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
        local itemX = listPanelX + itemPadding
        local itemWidth = listPanelWidth - (itemPadding * 2)

        -- Draw selection highlight
        if i == selectedIndex then
            love.graphics.setColor(0.3, 0.4, 0.6, 0.5)
            love.graphics.rectangle("fill", itemX, itemY, itemWidth, itemHeight - itemPadding, 5, 5)
        end

        -- Draw category color bar
        local categoryColor = categoryColors[upgrade.category] or {0.5, 0.5, 0.5}
        love.graphics.setColor(categoryColor[1], categoryColor[2], categoryColor[3])
        love.graphics.rectangle("fill", itemX, itemY, 5, itemHeight - itemPadding, 2, 2)

        -- Draw upgrade name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print(upgrade.name, itemX + 15, itemY + 5)

        -- Draw level indicator
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Level: " .. currentLevel .. "/" .. upgrade.maxLevel, itemX + 15, itemY + 28)

        -- Draw cost or max level indicator
        if isMaxLevel then
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.print("MAX", itemX + 15, itemY + 48)
        else
            if canAfford then
                love.graphics.setColor(1, 0.9, 0.3)
            else
                love.graphics.setColor(0.8, 0.3, 0.3)
            end
            love.graphics.print("Cost: " .. cost .. " gold", itemX + 15, itemY + 48)
        end
    end

    -- Draw scrollbar if needed
    if #upgradeList > maxVisibleUpgrades then
        local scrollbarX = listPanelX + listPanelWidth - 15
        local scrollbarY = listPanelY + 10
        local scrollbarHeight = listPanelHeight - 20
        local scrollbarWidth = 5

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 2, 2)

        local thumbHeight = (maxVisibleUpgrades / #upgradeList) * scrollbarHeight
        local thumbY = scrollbarY + (scrollOffset / (#upgradeList - maxVisibleUpgrades)) *
                           (scrollbarHeight - thumbHeight)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 2, 2)
    end

    -- Draw detail panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", detailPanelX, detailPanelY, detailPanelWidth, detailPanelHeight, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", detailPanelX, detailPanelY, detailPanelWidth, detailPanelHeight, 8, 8)

    -- Draw selected upgrade details
    if selectedUpgradeId then
        local upgrade = Upgrades.catalog[selectedUpgradeId]
        local currentLevel = Upgrades.getPlayerUpgradeLevel(player, selectedUpgradeId)
        local cost = Upgrades.getCost(selectedUpgradeId, currentLevel)
        local isMaxLevel = currentLevel >= upgrade.maxLevel
        local categoryColor = categoryColors[upgrade.category] or {0.5, 0.5, 0.5}

        local detailX = detailPanelX + 20
        local detailY = detailPanelY + 20

        -- Draw upgrade name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.print(upgrade.name, detailX, detailY)

        -- Draw category
        love.graphics.setColor(categoryColor[1], categoryColor[2], categoryColor[3])
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(upgrade.category:upper(), detailX, detailY + 30)

        -- Draw description
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf(upgrade.description, detailX, detailY + 60, detailPanelWidth - 40, "left")

        -- Draw current level and max level
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Current Level: " .. currentLevel .. " / " .. upgrade.maxLevel, detailX, detailY + 110)

        -- Draw current effect
        if currentLevel > 0 then
            local effectValue = Upgrades.getEffectValue(selectedUpgradeId, currentLevel)
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.setFont(love.graphics.newFont(16))

            local effectText
            if upgrade.effect.type == "percentage" then
                effectText = "Current Bonus: +" .. effectValue .. "%"
            elseif upgrade.effect.type == "threshold" then
                effectText = "Current Threshold: " .. effectValue .. "%"
            else
                effectText = "Current Bonus: +" .. effectValue
            end
            love.graphics.print(effectText, detailX, detailY + 140)
        end

        -- Draw next level preview
        if not isMaxLevel then
            local nextLevel = currentLevel + 1
            local nextEffectValue = Upgrades.getEffectValue(selectedUpgradeId, nextLevel)
            love.graphics.setColor(0.7, 0.7, 1)
            love.graphics.setFont(love.graphics.newFont(16))

            local nextEffectText
            if upgrade.effect.type == "percentage" then
                nextEffectText = "Next Level: +" .. nextEffectValue .. "%"
            elseif upgrade.effect.type == "threshold" then
                nextEffectText = "Next Level: " .. nextEffectValue .. "%"
            else
                nextEffectText = "Next Level: +" .. nextEffectValue
            end
            love.graphics.print(nextEffectText, detailX, detailY + 170)

            -- Draw cost
            love.graphics.setColor(1, 0.9, 0.3)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print("Cost: " .. cost .. " gold", detailX, detailY + 210)
        else
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print("MAX LEVEL REACHED", detailX, detailY + 170)
        end
    end

    -- Draw controls help
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(14))
    local controlsY = screenHeight - 50
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE or CLICK] Purchase  [ESC] Exit", 0, controlsY,
        screenWidth, "center")

    -- Reset line width
    love.graphics.setLineWidth(1)
end

-- Handle keyboard input
function UpgradeScreen.keypressed(key)
    if key == "w" or key == "up" then
        navigateUp()
    elseif key == "s" or key == "down" then
        navigateDown()
    elseif key == "space" or key == "return" then
        purchaseUpgrade()
    elseif key == "escape" then
        exitUpgradeScreen()
    end
end

-- Handle mouse input
function UpgradeScreen.mousepressed(x, y, button)
    if button == 1 then
        -- Check if clicking on upgrade list items
        local listPanelX = 50
        local listPanelY = 130
        local listPanelWidth = 400
        local itemHeight = 70
        local itemPadding = 10

        local startIndex = scrollOffset + 1
        local endIndex = math.min(scrollOffset + maxVisibleUpgrades, #upgradeList)

        for i = startIndex, endIndex do
            local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
            local itemX = listPanelX + itemPadding
            local itemWidth = listPanelWidth - (itemPadding * 2)

            if x >= itemX and x <= itemX + itemWidth and y >= itemY and y <= itemY + itemHeight - itemPadding then
                selectedIndex = i
                selectedUpgradeId = upgradeList[selectedIndex]
                return
            end
        end
    end
end

return UpgradeScreen
