-- Space Debris obstacle module
local sprite = nil -- Module-level sprite variable

-- Load sprite (called once)
local function loadSprite()
    if not sprite then
        sprite = love.graphics.newImage("sprites/debris/SpaceDebris_40x40.png")
        sprite:setFilter("nearest", "nearest")
    end
end

local SpaceDebris = {
    id = "space_debris",
    name = "Space Debris",

    -- Create a new space debris instance
    create = function(playArea, existingObstacles, config)
        local movementSpeed = config and config.movementSpeed or 0 -- Default to stationary
        local debris = {
            type = "space_debris",
            x = 0,
            y = 0,
            width = 40,
            height = 40,
            rotation = love.math.random() * math.pi * 2,
            rotationSpeed = (love.math.random() - 0.5) * 0.5, -- Slow rotation
            movementSpeed = movementSpeed,
            movementAngle = love.math.random() * 2 * math.pi,
            warningTimer = 0 -- Timer for showing warning after collision
        }

        -- Try to spawn at a location that's not too close to existing obstacles
        local maxAttempts = 10
        local minDistance = 150 -- Minimum distance from other obstacles
        local validPosition = false

        for attempt = 1, maxAttempts do
            -- Generate random position
            local angle = love.math.random() * 2 * math.pi
            local distance = (0.3 + love.math.random() * 0.6) * playArea.radius
            local testX = playArea.x + math.cos(angle) * distance
            local testY = playArea.y + math.sin(angle) * distance

            -- Check distance from existing obstacles
            validPosition = true
            if existingObstacles then
                for _, obstacle in ipairs(existingObstacles) do
                    local dx = testX - obstacle.x
                    local dy = testY - obstacle.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < minDistance then
                        validPosition = false
                        break
                    end
                end
            end

            if validPosition then
                debris.x = testX
                debris.y = testY
                break
            end
        end

        -- If no valid position found, just use the last test position
        if not validPosition then
            local angle = love.math.random() * 2 * math.pi
            local distance = (0.3 + love.math.random() * 0.6) * playArea.radius
            debris.x = playArea.x + math.cos(angle) * distance
            debris.y = playArea.y + math.sin(angle) * distance
        end

        return debris
    end,

    -- Update space debris
    update = function(self, dt, asteroids, spaceship, playArea)
        -- Update warning timer
        if self.warningTimer > 0 then
            self.warningTimer = self.warningTimer - dt
        end

        -- Rotate debris
        self.rotation = self.rotation + self.rotationSpeed * dt

        -- Move debris if movement speed is set
        if self.movementSpeed > 0 then
            self.x = self.x + math.cos(self.movementAngle) * self.movementSpeed * dt
            self.y = self.y + math.sin(self.movementAngle) * self.movementSpeed * dt

            -- Keep debris within play area (bounce off edges)
            local dx = self.x - playArea.x
            local dy = self.y - playArea.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > playArea.radius - 50 then
                -- Bounce off edge
                self.movementAngle = math.atan2(playArea.y - self.y, playArea.x - self.x)
            end
        end

        -- Check collision with asteroids (rectangle vs circle collision)
        for _, asteroid in ipairs(asteroids) do
            -- Transform asteroid position to debris local space
            local dx = asteroid.x - self.x
            local dy = asteroid.y - self.y

            -- Rotate point into debris's local coordinate system
            local cos_rot = math.cos(-self.rotation)
            local sin_rot = math.sin(-self.rotation)
            local localX = dx * cos_rot - dy * sin_rot
            local localY = dx * sin_rot + dy * cos_rot

            -- Find closest point on the rectangle to the asteroid's center
            local halfWidth = self.width / 2
            local halfHeight = self.height / 2
            local closestX = math.max(-halfWidth, math.min(localX, halfWidth))
            local closestY = math.max(-halfHeight, math.min(localY, halfHeight))

            -- Calculate distance from closest point to asteroid center
            local distX = localX - closestX
            local distY = localY - closestY
            local distanceSquared = distX * distX + distY * distY

            local asteroidRadius = asteroid.radius or 10
            if distanceSquared < (asteroidRadius * asteroidRadius) then
                -- Bounce asteroid in opposite direction
                local bounceAngle = math.atan2(dy, dx)
                asteroid.direction = bounceAngle
            end
        end
    end,

    -- Draw space debris
    draw = function(self)
        -- Load sprite if not already loaded
        loadSprite()

        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.rotation)

        -- Draw sprite
        if sprite then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(sprite, -self.width / 2, -self.height / 2)
        else
            -- Fallback to placeholder rectangle if sprite fails to load
            love.graphics.setColor(0.4, 0.4, 0.45)
            love.graphics.rectangle("fill", -self.width / 2, -self.height / 2, self.width, self.height)
            love.graphics.setColor(0.6, 0.6, 0.65)
            love.graphics.rectangle("line", -self.width / 2, -self.height / 2, self.width, self.height)
        end

        love.graphics.pop()
    end,

    -- Check collision with spaceship (rectangle vs circle collision)
    checkCollision = function(self, target)
        -- Transform ship position to debris local space (accounting for rotation)
        local dx = target.x - self.x
        local dy = target.y - self.y

        -- Rotate point into debris's local coordinate system
        local cos_rot = math.cos(-self.rotation)
        local sin_rot = math.sin(-self.rotation)
        local localX = dx * cos_rot - dy * sin_rot
        local localY = dx * sin_rot + dy * cos_rot

        -- Find closest point on the rectangle to the ship's center
        local halfWidth = self.width / 2
        local halfHeight = self.height / 2
        local closestX = math.max(-halfWidth, math.min(localX, halfWidth))
        local closestY = math.max(-halfHeight, math.min(localY, halfHeight))

        -- Calculate distance from closest point to ship center
        local distX = localX - closestX
        local distY = localY - closestY
        local distanceSquared = distX * distX + distY * distY

        local shipRadius = 15
        return distanceSquared < (shipRadius * shipRadius)
    end,

    -- Warning for space debris (only shows after collision)
    getWarning = function(self)
        if self.warningTimer > 0 then
            return "WARNING: Space Debris detected!"
        end
        return nil
    end
}

return SpaceDebris
