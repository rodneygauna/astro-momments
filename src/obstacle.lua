-- Obstacle module
-- Handles environmental hazards and obstacles for sectors
local Obstacle = {}

-- Obstacle type definitions
Obstacle.types = {
    solar_flare = {
        id = "solar_flare",
        name = "Solar Flare Warning Zone",

        -- Create a new solar flare instance
        create = function(playArea, existingObstacles)
            local flare = {
                type = "solar_flare",
                x = 0,
                y = 0,
                radius = 60,
                warningTimer = 0,
                warningDuration = 1.5, -- Warning shows for 1.5 seconds
                activeTimer = 0,
                activeDuration = 2.0, -- Flare effect lasts 2 seconds
                cooldownTimer = 0,
                cooldownDuration = 4.0, -- 4 seconds between flares
                phase = "cooldown", -- cooldown, warning, active
                alpha = 0,
                pulseTimer = 0
            }

            -- Randomize initial cooldown so flares don't all activate at once
            flare.cooldownTimer = love.math.random() * flare.cooldownDuration

            -- Try to spawn at a location that's not too close to existing obstacles
            local maxAttempts = 10
            local minDistance = 150 -- Minimum distance from other obstacles
            local validPosition = false

            for attempt = 1, maxAttempts do
                -- Generate random position
                local angle = love.math.random() * 2 * math.pi
                -- Use more varied distance (0.3 to 0.9 of radius)
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
                    flare.x = testX
                    flare.y = testY
                    break
                end
            end

            -- If no valid position found after attempts, just use the last tested position
            if not validPosition then
                local angle = love.math.random() * 2 * math.pi
                local distance = (0.3 + love.math.random() * 0.6) * playArea.radius
                flare.x = playArea.x + math.cos(angle) * distance
                flare.y = playArea.y + math.sin(angle) * distance
            end

            return flare
        end,

        -- Update solar flare
        update = function(self, dt, asteroids, spaceship, playArea)
            self.pulseTimer = self.pulseTimer + dt

            if self.phase == "cooldown" then
                self.cooldownTimer = self.cooldownTimer + dt
                if self.cooldownTimer >= self.cooldownDuration then
                    -- Move to a new random position before showing warning
                    if playArea then
                        local angle = love.math.random() * 2 * math.pi
                        local distance = (0.3 + love.math.random() * 0.6) * playArea.radius
                        self.x = playArea.x + math.cos(angle) * distance
                        self.y = playArea.y + math.sin(angle) * distance
                    end

                    -- Start warning phase
                    self.phase = "warning"
                    self.cooldownTimer = 0
                    self.warningTimer = 0
                end

            elseif self.phase == "warning" then
                self.warningTimer = self.warningTimer + dt
                -- Pulse alpha for warning effect
                self.alpha = 0.3 + 0.3 * math.sin(self.pulseTimer * 8)

                if self.warningTimer >= self.warningDuration then
                    -- Start active phase
                    self.phase = "active"
                    self.warningTimer = 0
                    self.activeTimer = 0
                end

            elseif self.phase == "active" then
                self.activeTimer = self.activeTimer + dt
                self.alpha = 0.6 + 0.2 * math.sin(self.pulseTimer * 6)

                -- Slow down asteroids in range
                if asteroids then
                    for _, asteroid in ipairs(asteroids) do
                        local dx = asteroid.x - self.x
                        local dy = asteroid.y - self.y
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < self.radius then
                            -- Apply slow effect
                            asteroid.speedMultiplier = 0.3 -- Reduce speed to 30%
                            asteroid.slowedTimer = 0.5 -- Effect lasts 0.5s after leaving
                        end
                    end
                end

                -- Slow down spaceship if in range
                if spaceship then
                    local dx = spaceship.x - self.x
                    local dy = spaceship.y - self.y
                    local distance = math.sqrt(dx * dx + dy * dy)

                    if distance < self.radius then
                        -- Apply slow effect to spaceship velocity
                        spaceship.velocityX = spaceship.velocityX * 0.92 -- Reduce velocity by 8% per frame
                        spaceship.velocityY = spaceship.velocityY * 0.92
                    end
                end

                if self.activeTimer >= self.activeDuration then
                    -- Return to cooldown
                    self.phase = "cooldown"
                    self.activeTimer = 0
                end
            end
        end,

        -- Draw solar flare
        draw = function(self)
            if self.phase == "warning" then
                -- Draw pulsing warning circle
                love.graphics.setColor(1, 0.8, 0, self.alpha)
                love.graphics.circle("line", self.x, self.y, self.radius, 32)
                love.graphics.setColor(1, 0.8, 0, self.alpha * 0.2)
                love.graphics.circle("fill", self.x, self.y, self.radius, 32)

            elseif self.phase == "active" then
                -- Draw active solar flare effect
                love.graphics.setColor(1, 0.5, 0, self.alpha)
                love.graphics.circle("line", self.x, self.y, self.radius, 32)
                love.graphics.setColor(1, 0.5, 0, self.alpha * 0.3)
                love.graphics.circle("fill", self.x, self.y, self.radius, 32)

                -- Draw expanding ring
                local expandRadius = self.radius + (self.activeTimer / self.activeDuration) * 20
                love.graphics.setColor(1, 0.6, 0, self.alpha * 0.5)
                love.graphics.circle("line", self.x, self.y, expandRadius, 32)
            end
        end,

        -- Check collision (solar flares don't collide with player)
        checkCollision = function(self, target)
            return false
        end,

        -- Get warning message if obstacle is active
        getWarning = function(self)
            if self.phase == "warning" or self.phase == "active" then
                return "WARNING: Solar Flares detected!"
            end
            return nil
        end
    },

    cosmic_dust = {
        id = "cosmic_dust",
        name = "Cosmic Dust Cloud",

        -- Create a new cosmic dust instance
        create = function(playArea, existingObstacles, config)
            local obscurity = config and config.obscurity or 0.5 -- Default to medium obscurity
            local dust = {
                type = "cosmic_dust",
                x = playArea.x,
                y = playArea.y,
                radius = playArea.radius * 1.2, -- Cover entire play area plus extra
                intensity = 0,
                obscurity = obscurity, -- How much the dust obscures (0.0 - 1.0)
                maxIntensity = 0.4 + (obscurity * 0.5), -- Scale max intensity based on obscurity (0.4 to 0.9)
                phase = "building", -- building, active, fading
                timer = 0,
                buildDuration = 3.0, -- Takes 3 seconds to build up
                activeDuration = 8.0, -- Stays active for 8 seconds
                fadeDuration = 2.0, -- Takes 2 seconds to fade
                cycleCooldown = 6.0, -- 6 seconds between cycles
                cooldownTimer = 0,
                particles = {}
            }

            -- Generate dust particles for visual effect (more particles for higher obscurity)
            local particleCount = math.floor(60 + obscurity * 60) -- 60-120 particles based on obscurity
            for i = 1, particleCount do
                local angle = love.math.random() * 2 * math.pi
                local distance = love.math.random() * dust.radius
                table.insert(dust.particles, {
                    x = math.cos(angle) * distance,
                    y = math.sin(angle) * distance,
                    size = love.math.random(2, 6) + obscurity * 2, -- Larger particles for higher obscurity
                    alpha = (love.math.random() * 0.3 + 0.2) * obscurity, -- More visible particles for higher obscurity
                    speed = love.math.random() * 10 + 5,
                    angle = love.math.random() * 2 * math.pi
                })
            end

            return dust
        end,

        -- Update cosmic dust
        update = function(self, dt, asteroids, spaceship, playArea)
            -- Update particle positions
            for _, particle in ipairs(self.particles) do
                particle.x = particle.x + math.cos(particle.angle) * particle.speed * dt
                particle.y = particle.y + math.sin(particle.angle) * particle.speed * dt

                -- Wrap particles around the cloud area
                local dist = math.sqrt(particle.x ^ 2 + particle.y ^ 2)
                if dist > self.radius then
                    particle.angle = particle.angle + math.pi
                end
            end

            -- Phase management
            if self.phase == "building" then
                self.timer = self.timer + dt
                self.intensity = (self.timer / self.buildDuration) * self.maxIntensity

                if self.timer >= self.buildDuration then
                    self.phase = "active"
                    self.timer = 0
                end

            elseif self.phase == "active" then
                self.timer = self.timer + dt
                self.intensity = self.maxIntensity

                if self.timer >= self.activeDuration then
                    self.phase = "fading"
                    self.timer = 0
                end

            elseif self.phase == "fading" then
                self.timer = self.timer + dt
                self.intensity = self.maxIntensity * (1 - self.timer / self.fadeDuration)

                if self.timer >= self.fadeDuration then
                    self.phase = "cooldown"
                    self.cooldownTimer = self.cycleCooldown
                    self.intensity = 0
                end

            elseif self.phase == "cooldown" then
                self.cooldownTimer = self.cooldownTimer - dt

                if self.cooldownTimer <= 0 then
                    self.phase = "building"
                    self.timer = 0
                end
            end
        end,

        -- Draw cosmic dust
        draw = function(self)
            if self.intensity <= 0 then
                return
            end

            -- Draw overall fog overlay first (semi-transparent brownish haze that obscures vision)
            love.graphics.setColor(0.45, 0.35, 0.25, self.intensity)
            love.graphics.circle("fill", self.x, self.y, self.radius)

            -- Draw dust particles on top (brownish-orange dust clouds)
            for _, particle in ipairs(self.particles) do
                love.graphics.setColor(0.65, 0.5, 0.35, particle.alpha * self.intensity * 1.2)
                love.graphics.circle("fill", self.x + particle.x, self.y + particle.y, particle.size)
            end
        end,

        -- Cosmic dust doesn't have collision
        checkCollision = function(self, target)
            return false
        end,

        -- Get warning message if dust is active
        getWarning = function(self)
            if self.phase == "building" or self.phase == "active" or self.phase == "fading" then
                return "WARNING: Cosmic Dust detected!"
            end
            return nil
        end
    },

    radiation_belt = {
        id = "radiation_belt",
        name = "Radiation Belt",

        -- Create a new radiation belt instance
        create = function(playArea, existingObstacles, config)
            local belt = {
                type = "radiation_belt",
                x = playArea.x,
                y = playArea.y,
                width = playArea.radius * 2.5, -- Wide enough to cross play area
                height = 80, -- Height of the radiation band
                angle = love.math.random() * 2 * math.pi, -- Random direction
                speed = 15, -- Slow movement speed
                offset = 0, -- Current position along path
                color = {love.math.random() * 0.3 + 0.5, -- R: 0.5-0.8
                love.math.random() * 0.3 + 0.3, -- G: 0.3-0.6
                love.math.random() * 0.3 + 0.5 -- B: 0.5-0.8
                },
                pulseTimer = 0,
                debuffDuration = 2.5 -- How long the debuff lasts (2-3 seconds average)
            }

            return belt
        end,

        -- Update radiation belt
        update = function(self, dt, asteroids, spaceship, playArea)
            -- Move belt slowly across the play area
            self.offset = self.offset + self.speed * dt

            -- Reset offset when belt moves too far (creates looping effect)
            if self.offset > playArea.radius * 3 then
                self.offset = -playArea.radius
            end

            -- Update pulse timer for visual effect
            self.pulseTimer = self.pulseTimer + dt

            -- Check if spaceship is in the belt
            local shipCenter = {
                x = spaceship.x + 15,
                y = spaceship.y + 15
            }

            -- Transform target position to belt local space
            local centerX = self.x + math.cos(self.angle) * self.offset
            local centerY = self.y + math.sin(self.angle) * self.offset
            local dx = shipCenter.x - centerX
            local dy = shipCenter.y - centerY

            -- Rotate point into belt's local coordinate system
            local cos_rot = math.cos(-self.angle)
            local sin_rot = math.sin(-self.angle)
            local localX = dx * cos_rot - dy * sin_rot
            local localY = dx * sin_rot + dy * cos_rot

            -- Check if within belt bounds
            local halfWidth = self.width / 2
            local halfHeight = self.height / 2

            if math.abs(localX) < halfWidth and math.abs(localY) < halfHeight then
                -- Apply capture speed debuff
                if not spaceship.radiationDebuff or spaceship.radiationDebuffTimer <= 0 then
                    spaceship.radiationDebuff = true
                    spaceship.radiationDebuffTimer = self.debuffDuration
                end
            end
        end,

        -- Draw radiation belt
        draw = function(self)
            -- Calculate belt position
            local centerX = self.x + math.cos(self.angle) * self.offset
            local centerY = self.y + math.sin(self.angle) * self.offset

            -- Pulsing effect
            local pulse = 0.6 + 0.4 * math.sin(self.pulseTimer * 2)

            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            love.graphics.rotate(self.angle)

            -- Draw multiple layers for depth
            for i = 1, 3 do
                local layerOffset = (i - 2) * 15
                local alpha = pulse * (0.3 + i * 0.1)
                love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
                love.graphics
                    .rectangle("fill", -self.width / 2, -self.height / 2 + layerOffset, self.width, self.height)
            end

            love.graphics.pop()
        end,

        -- Check collision with target (rectangle collision)
        checkCollision = function(self, target)
            -- Transform target position to belt local space
            local dx = target.x - (self.x + math.cos(self.angle) * self.offset)
            local dy = target.y - (self.y + math.sin(self.angle) * self.offset)

            -- Rotate point into belt's local coordinate system
            local cos_rot = math.cos(-self.angle)
            local sin_rot = math.sin(-self.angle)
            local localX = dx * cos_rot - dy * sin_rot
            local localY = dx * sin_rot + dy * cos_rot

            -- Check if within belt bounds
            local halfWidth = self.width / 2
            local halfHeight = self.height / 2

            return math.abs(localX) < halfWidth and math.abs(localY) < halfHeight
        end,

        -- Get warning message if ship is affected
        getWarning = function(self)
            -- No warning - radiation belt is always visible
            return nil
        end
    },

    space_debris = {
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

        -- Draw space debris (placeholder rectangles)
        draw = function(self)
            love.graphics.push()
            love.graphics.translate(self.x, self.y)
            love.graphics.rotate(self.rotation)

            -- Draw rectangular debris
            love.graphics.setColor(0.4, 0.4, 0.45)
            love.graphics.rectangle("fill", -self.width / 2, -self.height / 2, self.width, self.height)
            love.graphics.setColor(0.6, 0.6, 0.65)
            love.graphics.rectangle("line", -self.width / 2, -self.height / 2, self.width, self.height)

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
}

-- Create obstacle from configuration
function Obstacle.create(obstacleConfig, playArea, existingObstacles)
    local obstacleType = Obstacle.types[obstacleConfig.type]
    if not obstacleType then
        print("Warning: Unknown obstacle type: " .. obstacleConfig.type)
        return nil
    end

    return obstacleType.create(playArea, existingObstacles, obstacleConfig)
end

-- Update obstacle
function Obstacle.update(obstacle, dt, asteroids, spaceship, playArea)
    local obstacleType = Obstacle.types[obstacle.type]
    if obstacleType and obstacleType.update then
        obstacleType.update(obstacle, dt, asteroids, spaceship, playArea)
    end
end

-- Draw obstacle
function Obstacle.draw(obstacle)
    local obstacleType = Obstacle.types[obstacle.type]
    if obstacleType and obstacleType.draw then
        obstacleType.draw(obstacle)
    end
end

-- Check collision with target
function Obstacle.checkCollision(obstacle, target)
    local obstacleType = Obstacle.types[obstacle.type]
    if obstacleType and obstacleType.checkCollision then
        return obstacleType.checkCollision(obstacle, target)
    end
    return false
end

-- Get warning message from obstacle
function Obstacle.getWarning(obstacle)
    local obstacleType = Obstacle.types[obstacle.type]
    if obstacleType and obstacleType.getWarning then
        return obstacleType.getWarning(obstacle)
    end
    return nil
end

return Obstacle
