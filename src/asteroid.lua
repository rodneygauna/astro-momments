-- Asteroid module
-- Handles asteroid spawning, movement, and collection logic
local Asteroid = {}

-- Asteroid type definitions (Interesting read: https://en.wikipedia.org/wiki/Asteroid_mining)
Asteroid.types = {{
    id = "silicates", -- Olivine, pyroxene; most common
    value = 1
}, {
    id = "carbonaceous", -- Organic-rich material
    value = 2
}, {
    id = "iron", -- Metallic iron
    value = 3
}, {
    id = "nickel", -- Iron-nickel alloy component
    value = 5
}, {
    id = "magnesium_silicates", -- Olivine variants
    value = 8
}, {
    id = "aluminum_minerals", -- Plagioclase group
    value = 13
}, {
    id = "calcium_minerals", -- Anorthite, etc.
    value = 31
}, {
    id = "sulfides", -- Troilite (FeS)
    value = 44
}, {
    id = "water_ice", -- Often found in outer-belt asteroids
    value = 75
}, {
    id = "carbonates", -- Calcite, dolomite
    value = 1109
}, {
    id = "clay_minerals", -- Phyllosilicates
    value = 11
}, {
    id = "graphite", -- Pure carbon crystals
    value = 12
}, {
    id = "chromium_oxides", -- Chromite and related minerals
    value = 13
}, {
    id = "cobalt", -- Trace metal in iron meteorites
    value = 14
}, {
    id = "titanium_oxides", -- Rutile, ilmenite
    value = 15
}, {
    id = "rare_earths", -- REE-bearing minerals
    value = 16
}, {
    id = "platinum_group", -- Pt, Ir, Os, Pd
    value = 17
}, {
    id = "gold", -- Present in trace amounts
    value = 18
}, {
    id = "microdiamonds", -- Nanodiamonds from impacts
    value = 19
}, {
    id = "amino_acids", -- Extremely rare organic precursors
    value = 20
}}

-- Asteroid configuration
Asteroid.maxAsteroids = 20
Asteroid.speed = 30
Asteroid.collectionSpeed = 50 -- Percentage per second when in field
Asteroid.decaySpeed = 30 -- Percentage per second when out of field

-- Create a new asteroid at a random position within the playable area
function Asteroid.spawn(playableArea, currentAsteroidCount, allowedTypes)
    -- Default to all types if not specified
    allowedTypes = allowedTypes or Asteroid.types

    -- Select random type from allowed types
    local typeIndex = math.random(1, #allowedTypes)
    local asteroidType = allowedTypes[typeIndex]

    local angle = math.random() * 2 * math.pi
    local radius = math.random() * playableArea.radius
    local asteroidX = playableArea.x + radius * math.cos(angle)
    local asteroidY = playableArea.y + radius * math.sin(angle)

    -- Calculate dynamic spawn duration based on asteroid count
    -- More asteroids = slower spawn (0.9s), fewer asteroids = faster spawn (0.1s)
    local asteroidRatio = currentAsteroidCount / Asteroid.maxAsteroids
    local dynamicSpawnDuration = 0.1 + (asteroidRatio * 0.8) -- Range: 0.1 to 0.9 seconds

    return {
        x = asteroidX,
        y = asteroidY,
        spawnTimer = 0,
        spawnDuration = dynamicSpawnDuration,
        direction = nil,
        collectionMeter = 0,
        asteroidType = asteroidType -- Store the type data
    }
end

-- Update asteroid position and state
function Asteroid.update(asteroid, dt, playableArea)
    -- Update spawn animation timer
    if asteroid.spawnTimer < asteroid.spawnDuration then
        asteroid.spawnTimer = asteroid.spawnTimer + dt
    end

    -- Initialize random direction if not set
    if not asteroid.direction then
        asteroid.direction = math.random() * 2 * math.pi
    end

    -- Calculate new position
    local newX = asteroid.x + math.cos(asteroid.direction) * Asteroid.speed * dt
    local newY = asteroid.y + math.sin(asteroid.direction) * Asteroid.speed * dt
    local distanceFromCenter = math.sqrt((newX - playableArea.x) ^ 2 + (newY - playableArea.y) ^ 2)

    -- Update position if within bounds, otherwise change direction
    if distanceFromCenter <= playableArea.radius then
        asteroid.x = newX
        asteroid.y = newY
    else
        asteroid.direction = math.random() * 2 * math.pi
    end
end

-- Update asteroid collection meter
function Asteroid.updateCollection(asteroid, dt, spaceshipCenterX, spaceshipCenterY, collectionRadius)
    local distance = math.sqrt((asteroid.x - spaceshipCenterX) ^ 2 + (asteroid.y - spaceshipCenterY) ^ 2)

    if distance < collectionRadius then
        -- Asteroid is in field - increase collection meter
        asteroid.collectionMeter = asteroid.collectionMeter + Asteroid.collectionSpeed * dt
        if asteroid.collectionMeter >= 100 then
            asteroid.collectionMeter = 100
            return true -- Asteroid is collected!
        end
    else
        -- Asteroid is out of field - decrease collection meter
        asteroid.collectionMeter = asteroid.collectionMeter - Asteroid.decaySpeed * dt
        if asteroid.collectionMeter < 0 then
            asteroid.collectionMeter = 0
        end
    end

    return false -- Not collected yet
end

-- Draw an asteroid
function Asteroid.draw(asteroid)
    -- Calculate spawn scale (ease in from 0 to 1)
    local spawnScale = 1
    if asteroid.spawnTimer < asteroid.spawnDuration then
        local progress = asteroid.spawnTimer / asteroid.spawnDuration
        -- Ease out cubic for smooth spawn
        spawnScale = 1 - math.pow(1 - progress, 3)
    end

    love.graphics.setColor(0.6, 0.4, 0.2) -- Brown/gray color for asteroids
    love.graphics.circle("fill", asteroid.x, asteroid.y, 10 * spawnScale)

    -- Draw collection meter above asteroid if it's being collected
    if asteroid.collectionMeter and asteroid.collectionMeter > 0 then
        -- Background bar
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", asteroid.x - 15, asteroid.y - 20, 30, 5)

        -- Progress bar
        love.graphics.setColor(0, 1, 1) -- Cyan
        love.graphics.rectangle("fill", asteroid.x - 15, asteroid.y - 20, 30 * (asteroid.collectionMeter / 100), 5)

        -- Outline
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", asteroid.x - 15, asteroid.y - 20, 30, 5)
    end
end

-- Update all asteroids in a list
function Asteroid.updateAll(asteroids, dt, playableArea, spaceship)
    -- Update positions
    for _, asteroid in ipairs(asteroids) do
        Asteroid.update(asteroid, dt, playableArea)
    end

    -- Check collection and remove collected asteroids
    local spaceshipCenterX, spaceshipCenterY = spaceship.x + 15, spaceship.y + 15
    for i = #asteroids, 1, -1 do
        local collected = Asteroid.updateCollection(asteroids[i], dt, spaceshipCenterX, spaceshipCenterY,
            spaceship.collectionRadius)
        if collected then
            -- Store the collected asteroid data
            table.insert(spaceship.collectedAsteroids, asteroids[i])
            table.remove(asteroids, i)
            spaceship.currentCargo = spaceship.currentCargo + 1
        end
    end
end

-- Draw all asteroids in a list
function Asteroid.drawAll(asteroids)
    for _, asteroid in ipairs(asteroids) do
        Asteroid.draw(asteroid)
    end
end

return Asteroid
