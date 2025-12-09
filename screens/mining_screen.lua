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
local player
local gameStates
local changeState
local currentSector
local gameState -- For storing buff-related state like value multiplier

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
    maxTime = 30 -- Maximum time for mining phase in seconds
    timeLeft = maxTime

    -- Set the playable area size (circle)
    playableArea = {}
    local smallerDimension = math.min(love.graphics.getWidth(), love.graphics.getHeight())
    playableArea.radius = (smallerDimension * 0.9) / 2
    playableArea.x = love.graphics.getWidth() / 2
    playableArea.y = love.graphics.getHeight() / 2

    -- Initialize spaceship
    spaceship = Spaceship.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, player)

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
    if #asteroids < Asteroid.maxAsteroids then
        local allowedTypes = getSectorAsteroidTypes()
        table.insert(asteroids, Asteroid.spawn(playableArea, #asteroids, allowedTypes))
    end

    -- Update camera position to follow the spaceship
    local centerX, centerY = Spaceship.getCenter(spaceship)
    cam:lookAt(centerX, centerY)

    -- Update spaceship
    Spaceship.update(spaceship, dt, playableArea)

    -- Update all asteroids
    Asteroid.updateAll(asteroids, dt, playableArea, spaceship)
end

-- Draw mining screen
function MiningScreen.draw()
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
