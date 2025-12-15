-- Mining Screen
-- Handles the mining gameplay phase
local MiningScreen = {}

local Spaceship = require("src/spaceship")
local Asteroid = require("src/asteroid")
local Sector = require("src/sector")
local Buff = require("src/buff")

-- Mining state
local cam
local spaceship
local asteroids
local playableArea
local timeLeft
local maxTime
local maxAsteroidsAllowed
local player
local gameStates
local changeState
local currentSector
local gameState -- For storing buff-related state like value multiplier
local farStars -- Background star layer (slow parallax)
local nearStars -- Foreground star layer (fast parallax)
local planetSprite -- Planet background image
local planetPosition -- Planet position and scale data

-- Helper function to get asteroid types for current sector
local function getSectorAsteroidTypes()
    local allowedTypes = {}
    for _, typeId in ipairs(currentSector.asteroidTypes) do
        -- Find the matching type in Asteroid.types by id
        for _, asteroidType in ipairs(Asteroid.types) do
            if asteroidType.id == typeId then
                table.insert(allowedTypes, asteroidType)
                break
            end
        end
    end
    return allowedTypes
end

-- Initialize mining screen
function MiningScreen.load(camera, playerData, states, stateChanger, sectorId)
    cam = camera
    player = playerData
    gameStates = states
    changeState = stateChanger
    currentSector = Sector.definitions[sectorId] or Sector.definitions["sector_01"]
    maxTime = 30 + (player.stats.missionTimeBonus or 0) -- Base time + mission time bonus
    timeLeft = maxTime

    -- Set the playable area size (circle)
    playableArea = {}
    local smallerDimension = math.min(love.graphics.getWidth(), love.graphics.getHeight())
    playableArea.radius = (smallerDimension * 0.9) / 2
    playableArea.x = love.graphics.getWidth() / 2
    playableArea.y = love.graphics.getHeight() / 2

    -- Load and position planet sprite if sector has one
    planetSprite = nil
    planetPosition = nil
    if currentSector.planetImage then
        planetSprite = love.graphics.newImage(currentSector.planetImage)
        planetSprite:setFilter("nearest", "nearest") -- Pixel art filter

        -- Generate random position just outside playable area but still visible
        local angle = math.random() * 2 * math.pi
        local distance = playableArea.radius * (1.0 + math.random() * 0.4) -- Between 1.0x and 1.4x radius
        planetPosition = {
            x = playableArea.x + math.cos(angle) * distance,
            y = playableArea.y + math.sin(angle) * distance,
            scale = 1.2 + math.random() * 0.8 -- Random scale between 1.2 and 2.0 for better visibility
        }
    end

    -- Generate parallax star field
    -- Far layer: smaller, dimmer stars across a larger area
    farStars = {}
    local starFieldSize = playableArea.radius * 3 -- Larger than playable area
    for i = 1, 150 do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * starFieldSize
        local colorVariant = math.random()
        local starColor
        if colorVariant < 0.6 then
            starColor = {1, 1, 1} -- White
        elseif colorVariant < 0.85 then
            starColor = {0.7, 0.8, 1} -- Blue-white
        else
            starColor = {1, 0.95, 0.7} -- Yellow-white
        end
        table.insert(farStars, {
            x = playableArea.x + math.cos(angle) * distance,
            y = playableArea.y + math.sin(angle) * distance,
            size = 1,
            brightness = 0.3 + math.random() * 0.3,
            color = starColor
        })
    end

    -- Near layer: larger, brighter stars
    nearStars = {}
    for i = 1, 80 do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * starFieldSize
        local colorVariant = math.random()
        local starColor
        if colorVariant < 0.6 then
            starColor = {1, 1, 1} -- White
        elseif colorVariant < 0.85 then
            starColor = {0.7, 0.8, 1} -- Blue-white
        else
            starColor = {1, 0.95, 0.7} -- Yellow-white
        end
        table.insert(nearStars, {
            x = playableArea.x + math.cos(angle) * distance,
            y = playableArea.y + math.sin(angle) * distance,
            size = 1.5 + math.random() * 0.5,
            brightness = 0.5 + math.random() * 0.5,
            color = starColor
        })
    end

    -- Initialize spaceship
    spaceship = Spaceship.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, player)

    -- Calculate max asteroids with spawn rate bonus
    local spawnRateBonus = (player.stats.spawnRateBonus or 0) / 100
    maxAsteroidsAllowed = math.floor(Asteroid.maxAsteroids * (1 + spawnRateBonus))

    -- Initialize game state for buffs
    gameState = {
        maxTime = maxTime,
        timeLeft = timeLeft,
        valueMultiplier = 1.0
    }

    -- Apply active buffs if any
    if player.activeBuffs then
        for _, buff in ipairs(player.activeBuffs) do
            Buff.apply(buff, spaceship, gameState)
        end
        -- Update time values if buffs modified them
        maxTime = gameState.maxTime
        timeLeft = gameState.timeLeft
    end

    -- Initialize asteroids list
    asteroids = {}
end

-- Reset mining screen for a new round
function MiningScreen.reset()
    timeLeft = maxTime
    Spaceship.reset(spaceship, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    asteroids = {}
end

-- Update mining screen
function MiningScreen.update(dt)
    -- Check if cargo is full
    if Spaceship.isCargoFull(spaceship) then
        changeState(gameStates.CASHOUT, currentSector, {
            used = spaceship.currentCargo,
            max = spaceship.maxCargo,
            items = spaceship.collectedAsteroids,
            valueMultiplier = gameState.valueMultiplier
        })
        return
    end

    -- Check if time is up
    if timeLeft <= 0 then
        changeState(gameStates.CASHOUT, currentSector, {
            used = spaceship.currentCargo,
            max = spaceship.maxCargo,
            items = spaceship.collectedAsteroids,
            valueMultiplier = gameState.valueMultiplier
        })
        return
    end

    -- Decrease time left
    timeLeft = timeLeft - dt
    if timeLeft < 0 then
        timeLeft = 0
    end

    -- Spawn asteroids periodically
    if #asteroids < maxAsteroidsAllowed then
        local allowedTypes = getSectorAsteroidTypes()
        table.insert(asteroids, Asteroid.spawn(playableArea, #asteroids, allowedTypes))
    end

    -- Update camera position to follow the spaceship
    local centerX, centerY = Spaceship.getCenter(spaceship)
    cam:lookAt(centerX, centerY)

    -- Update spaceship
    Spaceship.update(spaceship, dt, playableArea)

    -- Update all asteroids
    Asteroid.updateAll(asteroids, dt, playableArea, spaceship, player.stats)
end

-- Draw mining screen
function MiningScreen.draw()
    -- Draw background stars with parallax (before camera attach)
    local camX, camY = cam:position()
    local centerX, centerY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2

    -- Draw far stars (20% parallax - slower movement)
    for _, star in ipairs(farStars) do
        local offsetX = (camX - centerX) * 0.2
        local offsetY = (camY - centerY) * 0.2
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], star.brightness)
        love.graphics.circle("fill", star.x - offsetX, star.y - offsetY, star.size)
    end

    -- Draw near stars (60% parallax - faster movement)
    for _, star in ipairs(nearStars) do
        local offsetX = (camX - centerX) * 0.6
        local offsetY = (camY - centerY) * 0.6
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], star.brightness)
        love.graphics.circle("fill", star.x - offsetX, star.y - offsetY, star.size)
    end

    -- Draw planet sprite with subtle parallax (20% - slower than stars)
    if planetSprite and planetPosition then
        local offsetX = (camX - centerX) * 0.2
        local offsetY = (camY - centerY) * 0.2
        love.graphics.setColor(1, 1, 1, 0.9) -- Slight transparency
        local planetX = planetPosition.x - offsetX - (planetSprite:getWidth() * planetPosition.scale / 2)
        local planetY = planetPosition.y - offsetY - (planetSprite:getHeight() * planetPosition.scale / 2)
        love.graphics.draw(planetSprite, planetX, planetY, 0, planetPosition.scale, planetPosition.scale)
    end

    -- Attach camera for world rendering
    cam:attach()

    -- Draw playable area (space sector)
    love.graphics.setColor(0.1, 0.1, 0.2, 0.3) -- Dark space with transparency
    love.graphics.circle("fill", playableArea.x, playableArea.y, playableArea.radius)
    love.graphics.setColor(0.5, 0.5, 0.7) -- Light gray outline
    love.graphics.circle("line", playableArea.x, playableArea.y, playableArea.radius)

    -- Draw spaceship
    Spaceship.draw(spaceship)

    -- Draw all asteroids
    Asteroid.drawAll(asteroids)

    -- Detach camera
    cam:detach()

    -- Draw UI elements in screen space (after detaching camera)
    love.graphics.setColor(1, 1, 1)

    -- Draw cargo capacity (middle top)
    love.graphics.printf("Cargo: " .. spaceship.currentCargo .. " / " .. spaceship.maxCargo, 0, 10,
        love.graphics.getWidth(), "center")

    -- Draw time left (top right)
    love.graphics.printf("Time Left: " .. math.ceil(timeLeft) .. "s", love.graphics.getWidth() - 200, 10, 200, "right")

    -- Draw gold (top left)
    love.graphics.print("Gold: " .. player.currency.gold, 10, 10)
end

-- Handle keyboard input
function MiningScreen.keypressed(key)
    if key == "escape" then
        changeState(gameStates.PAUSED)
    end
end

return MiningScreen
