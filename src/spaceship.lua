-- Spaceship module
-- Handles spaceship physics, movement, and state
local Spaceship = {}

-- Load spaceship sprite
local spaceshipImage = love.graphics.newImage("sprites/ships/Spaceship.png")
spaceshipImage:setFilter("nearest", "nearest") -- Crisp pixel art

-- Create a new spaceship
function Spaceship.new(x, y, player)
    local baseCollectionRadius = 100 + (player.stats.collectionRadiusBonus or 0)
    local baseAcceleration = 200 + (200 * (player.stats.accelerationBonus or 0) / 100)
    local baseDeceleration = 150 + (150 * (player.stats.accelerationBonus or 0) / 100)

    return {
        x = x,
        y = y,
        maxSpeed = 100 + (100 * player.stats.movementSpeedBonus / 100), -- Base speed + bonus
        acceleration = baseAcceleration, -- Base acceleration + bonus
        deceleration = baseDeceleration, -- Base deceleration + bonus (same as acceleration)
        velocityX = 0,
        velocityY = 0,
        stunned = false,
        stunTimer = 0,
        radiationDebuff = false,
        radiationDebuffTimer = 0,
        currentSpeed = 0,
        collectionRadius = baseCollectionRadius,
        baseCollectionRadius = baseCollectionRadius, -- Store base value for resets
        minCollectionRadius = 20 + (player.stats.collectionRadiusBonus or 0), -- Minimum when moving
        maxCollectionRadius = 40 + (player.stats.collectionRadiusBonus or 0), -- Maximum when stationary
        isMoving = false,
        maxCargo = 5 + player.stats.cargoCapacityBonus, -- Base cargo + bonus from skills
        currentCargo = 0,
        collectedAsteroids = {}, -- Track collected asteroids for cashout
        rotation = 0 -- Current rotation angle in radians
    }
end

-- Reset spaceship to starting position
function Spaceship.reset(spaceship, x, y)
    spaceship.x = x
    spaceship.y = y
    spaceship.velocityX = 0
    spaceship.velocityY = 0
    spaceship.currentSpeed = 0
    spaceship.currentCargo = 0
    spaceship.collectedAsteroids = {}
    spaceship.collectionRadius = spaceship.baseCollectionRadius
    spaceship.isMoving = false
end

-- Update spaceship physics and movement
function Spaceship.update(spaceship, dt, playableArea)
    -- Update stun timer
    if spaceship.stunned then
        spaceship.stunTimer = spaceship.stunTimer - dt
        if spaceship.stunTimer <= 0 then
            spaceship.stunned = false
            spaceship.stunTimer = 0
        end
        -- Slow down while stunned
        spaceship.velocityX = spaceship.velocityX * 0.9
        spaceship.velocityY = spaceship.velocityY * 0.9
        -- Update position but skip input handling
        spaceship.x = spaceship.x + spaceship.velocityX * dt
        spaceship.y = spaceship.y + spaceship.velocityY * dt
        return
    end

    -- Update radiation debuff timer
    if spaceship.radiationDebuff then
        spaceship.radiationDebuffTimer = spaceship.radiationDebuffTimer - dt
        if spaceship.radiationDebuffTimer <= 0 then
            spaceship.radiationDebuff = false
            spaceship.radiationDebuffTimer = 0
        end
    end

    -- Get player input direction
    spaceship.isMoving = false
    local inputX = 0
    local inputY = 0

    if love.keyboard.isDown("w", "up") then
        inputY = inputY - 1
        spaceship.isMoving = true
    end
    if love.keyboard.isDown("s", "down") then
        inputY = inputY + 1
        spaceship.isMoving = true
    end
    if love.keyboard.isDown("a", "left") then
        inputX = inputX - 1
        spaceship.isMoving = true
    end
    if love.keyboard.isDown("d", "right") then
        inputX = inputX + 1
        spaceship.isMoving = true
    end

    -- Apply friction only to excessive velocity (from bounces), not normal movement
    local currentVelMagnitude = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                              spaceship.velocityY)
    if currentVelMagnitude > spaceship.maxSpeed * 1.5 then
        -- Strong velocity from bounce - apply friction for gradual slowdown
        local friction = 0.92
        spaceship.velocityX = spaceship.velocityX * friction
        spaceship.velocityY = spaceship.velocityY * friction
    end

    if spaceship.isMoving then
        -- Normalize input direction
        local inputLength = math.sqrt(inputX * inputX + inputY * inputY)
        if inputLength > 0 then
            inputX = inputX / inputLength
            inputY = inputY / inputLength
        end

        -- Calculate angle between current velocity and input direction
        local currentVelLength = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                               spaceship.velocityY)
        local speedMultiplier = 1.0

        if currentVelLength > 0.1 then
            -- Normalize current velocity
            local currentDirX = spaceship.velocityX / currentVelLength
            local currentDirY = spaceship.velocityY / currentVelLength

            -- Calculate angle difference using dot product
            local dotProduct = currentDirX * inputX + currentDirY * inputY
            dotProduct = math.max(-1, math.min(1, dotProduct)) -- Clamp to [-1, 1]
            local angleDifference = math.acos(dotProduct) -- Result in radians

            -- Apply speed penalty based on angle difference
            if angleDifference < math.rad(45) then
                speedMultiplier = 0.9 + (1 - angleDifference / math.rad(45)) * 0.1 -- 90-100%
            elseif angleDifference < math.rad(90) then
                speedMultiplier = 0.7 + (1 - (angleDifference - math.rad(45)) / math.rad(45)) * 0.2 -- 70-90%
            else
                speedMultiplier = 0.5 + (1 - (angleDifference - math.rad(90)) / math.rad(90)) * 0.2 -- 50-70%
            end
        end

        -- Target velocity with speed multiplier
        local targetVelX = inputX * spaceship.maxSpeed * speedMultiplier
        local targetVelY = inputY * spaceship.maxSpeed * speedMultiplier

        -- Accelerate toward target velocity
        local accel = spaceship.acceleration * dt
        spaceship.velocityX = spaceship.velocityX + (targetVelX - spaceship.velocityX) *
                                  math.min(accel / spaceship.maxSpeed, 1)
        spaceship.velocityY = spaceship.velocityY + (targetVelY - spaceship.velocityY) *
                                  math.min(accel / spaceship.maxSpeed, 1)
    else
        -- Decelerate when no input
        local decel = spaceship.deceleration * dt
        local currentVelLength = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                               spaceship.velocityY)

        if currentVelLength > 0 then
            local decelAmount = math.min(decel, currentVelLength)
            spaceship.velocityX = spaceship.velocityX * (1 - decelAmount / currentVelLength)
            spaceship.velocityY = spaceship.velocityY * (1 - decelAmount / currentVelLength)
        end
    end

    -- Update current speed for reference
    spaceship.currentSpeed = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                           spaceship.velocityY)

    -- Update rotation to point in direction of movement
    if spaceship.currentSpeed > 1 then -- Only rotate if moving at reasonable speed
        spaceship.rotation = math.atan2(spaceship.velocityY, spaceship.velocityX)
    end

    -- Apply velocity to position
    local newX = spaceship.x + spaceship.velocityX * dt
    local newY = spaceship.y + spaceship.velocityY * dt

    -- Check if new position is within circular playable area
    local spaceshipCenterX = newX + 15
    local spaceshipCenterY = newY + 15
    local distanceFromCenter = math.sqrt((spaceshipCenterX - playableArea.x) ^ 2 + (spaceshipCenterY - playableArea.y) ^
                                             2)

    -- Keep spaceship within circular boundary
    if distanceFromCenter <= playableArea.radius then
        spaceship.x = newX
        spaceship.y = newY
    else
        -- Clamp spaceship to edge of circle and stop velocity in that direction
        local angle = math.atan2(spaceshipCenterY - playableArea.y, spaceshipCenterX - playableArea.x)
        spaceship.x = playableArea.x + math.cos(angle) * playableArea.radius - 15
        spaceship.y = playableArea.y + math.sin(angle) * playableArea.radius - 15

        -- Reduce velocity when hitting boundary
        spaceship.velocityX = spaceship.velocityX * 0.5
        spaceship.velocityY = spaceship.velocityY * 0.5
    end

    -- Update collection field radius based on movement
    if spaceship.isMoving then
        spaceship.collectionRadius = math.max(spaceship.minCollectionRadius, spaceship.collectionRadius - 20 * dt)
    else
        spaceship.collectionRadius = math.min(spaceship.maxCollectionRadius, spaceship.collectionRadius + 20 * dt)
    end
end

-- Draw the spaceship
function Spaceship.draw(spaceship)
    -- Draw spaceship sprite
    love.graphics.setColor(1, 1, 1) -- White (no tint)
    local spriteWidth = spaceshipImage:getWidth()
    local spriteHeight = spaceshipImage:getHeight()
    -- Draw sprite rotated around its center
    love.graphics.draw(spaceshipImage, spaceship.x + 15, -- Draw at ship center X
    spaceship.y + 15, -- Draw at ship center Y
    spaceship.rotation + math.pi / 2, -- Rotation in radians + 90 degree offset (sprite faces up by default)
    1, 1, -- Scale X, Y
    spriteWidth / 2, -- Origin X (center of sprite)
    spriteHeight / 2 -- Origin Y (center of sprite)
    )

    -- Collection field around the spaceship
    -- Blue (RGB: 99, 155, 255) with transparency
    love.graphics.setColor(99 / 255, 155 / 255, 255 / 255, 0.7)
    love.graphics.circle("line", spaceship.x + 15, spaceship.y + 15, spaceship.collectionRadius)
end

-- Get spaceship center position
function Spaceship.getCenter(spaceship)
    return spaceship.x + 15, spaceship.y + 15
end

-- Check if cargo is full
function Spaceship.isCargoFull(spaceship)
    return spaceship.currentCargo >= spaceship.maxCargo
end

-- Add cargo to spaceship
function Spaceship.addCargo(spaceship, amount)
    amount = amount or 1
    spaceship.currentCargo = math.min(spaceship.currentCargo + amount, spaceship.maxCargo)
end

return Spaceship
