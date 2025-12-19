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
    },

    meteor = {
        id = "meteor",
        name = "Meteor",

        -- Create a new meteor instance
        create = function(playArea, existingObstacles, config, index)
            local speed = config and config.speed or 150 -- Default meteor speed
            local size = config and config.size or 20 -- Default meteor radius
            local spawnDelay = (index and (index - 1) or 0) * 2.5 -- Stagger spawns by 2.5 seconds

            -- Choose a random side to spawn from (0=top, 1=right, 2=bottom, 3=left)
            local side = love.math.random(0, 3)
            local startX, startY, targetX, targetY

            -- Set spawn position and target based on side
            if side == 0 then -- Top
                startX = playArea.x + (love.math.random() - 0.5) * playArea.radius * 2
                startY = playArea.y - playArea.radius - 300
                targetX = playArea.x + (love.math.random() - 0.5) * playArea.radius * 2
                targetY = playArea.y + playArea.radius + 300
            elseif side == 1 then -- Right
                startX = playArea.x + playArea.radius + 300
                startY = playArea.y + (love.math.random() - 0.5) * playArea.radius * 2
                targetX = playArea.x - playArea.radius - 300
                targetY = playArea.y + (love.math.random() - 0.5) * playArea.radius * 2
            elseif side == 2 then -- Bottom
                startX = playArea.x + (love.math.random() - 0.5) * playArea.radius * 2
                startY = playArea.y + playArea.radius + 300
                targetX = playArea.x + (love.math.random() - 0.5) * playArea.radius * 2
                targetY = playArea.y - playArea.radius - 300
            else -- Left
                startX = playArea.x - playArea.radius - 300
                startY = playArea.y + (love.math.random() - 0.5) * playArea.radius * 2
                targetX = playArea.x + playArea.radius + 300
                targetY = playArea.y + (love.math.random() - 0.5) * playArea.radius * 2
            end

            -- Calculate direction vector
            local dx = targetX - startX
            local dy = targetY - startY
            local distance = math.sqrt(dx * dx + dy * dy)

            local meteor = {
                type = "meteor",
                x = startX,
                y = startY,
                radius = size,
                speed = speed,
                directionX = dx / distance,
                directionY = dy / distance,
                rotation = love.math.random() * math.pi * 2,
                rotationSpeed = (love.math.random() - 0.5) * 2,
                active = spawnDelay == 0, -- Only active if no spawn delay
                spawnDelay = spawnDelay, -- Time until meteor becomes active
                warningTimer = 0,
                playAreaRadius = playArea.radius,
                playAreaX = playArea.x,
                playAreaY = playArea.y
            }

            return meteor
        end,

        -- Update meteor
        update = function(self, dt, asteroids, spaceship, playArea)
            -- Update warning timer
            if self.warningTimer > 0 then
                self.warningTimer = self.warningTimer - dt
            end

            -- Handle spawn delay countdown
            if not self.active and self.spawnDelay > 0 then
                self.spawnDelay = self.spawnDelay - dt
                if self.spawnDelay <= 0 then
                    self.active = true
                end
                return -- Don't update position while waiting to spawn
            end

            if self.active then
                -- Move meteor
                self.x = self.x + self.directionX * self.speed * dt
                self.y = self.y + self.directionY * self.speed * dt

                -- Rotate meteor
                self.rotation = self.rotation + self.rotationSpeed * dt

                -- Check if meteor has left the play area (plus buffer)
                local dx = self.x - self.playAreaX
                local dy = self.y - self.playAreaY
                local dist = math.sqrt(dx * dx + dy * dy)

                if dist > self.playAreaRadius + 400 then
                    -- Respawn from random edge
                    local side = love.math.random(0, 3)
                    local startX, startY, targetX, targetY

                    if side == 0 then -- Top
                        startX = self.playAreaX + (love.math.random() - 0.5) * self.playAreaRadius * 2
                        startY = self.playAreaY - self.playAreaRadius - 300
                        targetX = self.playAreaX + (love.math.random() - 0.5) * self.playAreaRadius * 2
                        targetY = self.playAreaY + self.playAreaRadius + 300
                    elseif side == 1 then -- Right
                        startX = self.playAreaX + self.playAreaRadius + 300
                        startY = self.playAreaY + (love.math.random() - 0.5) * self.playAreaRadius * 2
                        targetX = self.playAreaX - self.playAreaRadius - 300
                        targetY = self.playAreaY + (love.math.random() - 0.5) * self.playAreaRadius * 2
                    elseif side == 2 then -- Bottom
                        startX = self.playAreaX + (love.math.random() - 0.5) * self.playAreaRadius * 2
                        startY = self.playAreaY + self.playAreaRadius + 300
                        targetX = self.playAreaX + (love.math.random() - 0.5) * self.playAreaRadius * 2
                        targetY = self.playAreaY - self.playAreaRadius - 300
                    else -- Left
                        startX = self.playAreaX - self.playAreaRadius - 300
                        startY = self.playAreaY + (love.math.random() - 0.5) * self.playAreaRadius * 2
                        targetX = self.playAreaX + self.playAreaRadius + 300
                        targetY = self.playAreaY + (love.math.random() - 0.5) * self.playAreaRadius * 2
                    end

                    self.x = startX
                    self.y = startY

                    local dx2 = targetX - startX
                    local dy2 = targetY - startY
                    local distance = math.sqrt(dx2 * dx2 + dy2 * dy2)
                    self.directionX = dx2 / distance
                    self.directionY = dy2 / distance
                end
            end
        end,

        -- Draw meteor (placeholder)
        draw = function(self)
            if self.active then
                love.graphics.push()
                love.graphics.translate(self.x, self.y)
                love.graphics.rotate(self.rotation)

                -- Draw rocky meteor shape (irregular circle)
                love.graphics.setColor(0.5, 0.4, 0.3)
                love.graphics.circle("fill", 0, 0, self.radius)

                -- Add some crater details
                love.graphics.setColor(0.4, 0.3, 0.25)
                love.graphics.circle("fill", -self.radius * 0.3, -self.radius * 0.2, self.radius * 0.3)
                love.graphics.circle("fill", self.radius * 0.2, self.radius * 0.3, self.radius * 0.25)

                -- Outline
                love.graphics.setColor(0.6, 0.5, 0.4)
                love.graphics.circle("line", 0, 0, self.radius)

                love.graphics.pop()
            end
        end,

        -- Check collision with spaceship
        checkCollision = function(self, target)
            if not self.active then
                return false
            end

            local dx = target.x - self.x
            local dy = target.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            local shipRadius = 15
            return distance < (self.radius + shipRadius)
        end,

        -- Warning for meteor (only shows after collision)
        getWarning = function(self)
            if self.warningTimer > 0 then
                return "WARNING: Meteor impact!"
            end
            return nil
        end
    },

    black_hole = {
        id = "black_hole",
        name = "Black Hole",

        -- Create a new black hole instance
        create = function(playArea, existingObstacles, config, index)
            local size = config and config.size or 80 -- Visual radius
            local dangerRadius = config and config.dangerRadius or 30 -- Center danger zone
            local gravityRadius = config and config.gravityRadius or 400 -- Gravitational influence radius (adjustable for balance)
            local gravityStrength = config and config.gravityStrength or 100 -- Pull strength (adjustable for balance)
            local moveSpeed = config and config.moveSpeed or 30 -- Movement speed

            -- Start at the edge of the play area to avoid spawning on top of ship
            local angle = love.math.random() * 2 * math.pi
            local distance = playArea.radius * 0.8 -- Spawn near the edge (80% of radius)
            local startX = playArea.x + math.cos(angle) * distance
            local startY = playArea.y + math.sin(angle) * distance

            -- Random initial movement direction
            local moveAngle = love.math.random() * 2 * math.pi

            local blackHole = {
                type = "black_hole",
                x = startX,
                y = startY,
                radius = size, -- Visual size
                dangerRadius = dangerRadius, -- Instant death zone
                gravityRadius = gravityRadius, -- How far gravity reaches
                gravityStrength = gravityStrength, -- Pull force
                moveSpeed = moveSpeed,
                directionX = math.cos(moveAngle),
                directionY = math.sin(moveAngle),
                rotation = 0,
                rotationSpeed = 0.5, -- Slow rotation for visual effect
                playAreaRadius = playArea.radius,
                playAreaX = playArea.x,
                playAreaY = playArea.y,
                warningTimer = 0
            }

            return blackHole
        end,

        -- Update black hole
        update = function(self, dt, asteroids, spaceship, playArea)
            -- Update warning timer
            if self.warningTimer > 0 then
                self.warningTimer = self.warningTimer - dt
            end

            -- Move black hole slowly
            self.x = self.x + self.directionX * self.moveSpeed * dt
            self.y = self.y + self.directionY * self.moveSpeed * dt

            -- Rotate for visual effect
            self.rotation = self.rotation + self.rotationSpeed * dt

            -- Bounce off play area boundaries
            local dx = self.x - self.playAreaX
            local dy = self.y - self.playAreaY
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > self.playAreaRadius - self.radius then
                -- Reflect direction when hitting boundary
                local angle = math.atan2(dy, dx)
                local normalX = -math.cos(angle)
                local normalY = -math.sin(angle)

                -- Reflect velocity
                local dotProduct = self.directionX * normalX + self.directionY * normalY
                self.directionX = self.directionX - 2 * dotProduct * normalX
                self.directionY = self.directionY - 2 * dotProduct * normalY

                -- Push back inside boundary
                self.x = self.playAreaX + math.cos(angle) * (self.playAreaRadius - self.radius)
                self.y = self.playAreaY + math.sin(angle) * (self.playAreaRadius - self.radius)
            end

            -- Apply gravitational pull to spaceship
            local shipCenterX = spaceship.x + 15
            local shipCenterY = spaceship.y + 15
            local shipDx = self.x - shipCenterX
            local shipDy = self.y - shipCenterY
            local shipDist = math.sqrt(shipDx * shipDx + shipDy * shipDy)

            if shipDist < self.gravityRadius and shipDist > 0 then
                -- Calculate pull strength (stronger when closer)
                -- Inverse square law for realistic gravity, with minimum distance to avoid singularity
                local safeDist = math.max(shipDist, 50)
                local pullStrength = self.gravityStrength * (self.gravityRadius / safeDist) ^ 2
                local pullX = (shipDx / shipDist) * pullStrength * dt
                local pullY = (shipDy / shipDist) * pullStrength * dt

                -- Apply pull to spaceship velocity
                spaceship.velocityX = spaceship.velocityX + pullX
                spaceship.velocityY = spaceship.velocityY + pullY
            end

            -- Apply gravitational pull to asteroids
            if asteroids then
                for _, asteroid in ipairs(asteroids) do
                    local astDx = self.x - asteroid.x
                    local astDy = self.y - asteroid.y
                    local astDist = math.sqrt(astDx * astDx + astDy * astDy)

                    if astDist < self.gravityRadius and astDist > 0 then
                        -- Stronger pull on asteroids with inverse square law
                        local safeDist = math.max(astDist, 50)
                        local pullStrength = (self.gravityStrength * 0.7) * (self.gravityRadius / safeDist) ^ 2
                        asteroid.x = asteroid.x + (astDx / astDist) * pullStrength * dt
                        asteroid.y = asteroid.y + (astDy / astDist) * pullStrength * dt
                    end
                end
            end
        end,

        -- Draw black hole
        draw = function(self)
            -- Draw gravitational influence (faint circle showing actual pull radius)
            love.graphics.setColor(0.4, 0.2, 0.6, 0.15)
            love.graphics.circle("fill", self.x, self.y, self.gravityRadius)

            -- Draw event horizon (outer black hole)
            love.graphics.setColor(0.1, 0.05, 0.15, 0.9)
            love.graphics.circle("fill", self.x, self.y, self.radius)

            -- Draw accretion disk effect (rotating rings)
            love.graphics.push()
            love.graphics.translate(self.x, self.y)
            love.graphics.rotate(self.rotation)

            for i = 1, 3 do
                local ringRadius = self.radius + i * 10
                love.graphics.setColor(0.5, 0.3, 0.7, 0.3 - i * 0.08)
                love.graphics.circle("line", 0, 0, ringRadius)
            end

            love.graphics.pop()

            -- Draw danger zone (black center)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.circle("fill", self.x, self.y, self.dangerRadius)

            -- Draw pulsing inner glow (dark purple)
            local pulse = math.abs(math.sin(love.timer.getTime() * 2))
            love.graphics.setColor(0.1, 0, 0.1, pulse * 0.3)
            love.graphics.circle("fill", self.x, self.y, self.dangerRadius * (0.5 + pulse * 0.3))

            love.graphics.setColor(1, 1, 1, 1)
        end,

        -- Check collision with danger zone
        checkCollision = function(self, target)
            local dx = target.x - self.x
            local dy = target.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Only collision with danger zone (center) matters
            return distance < self.dangerRadius
        end,

        -- Warning for black hole
        getWarning = function(self)
            if self.warningTimer > 0 then
                return "CRITICAL: Black Hole proximity!"
            end
            return nil
        end
    }
}

-- Create obstacle from configuration
function Obstacle.create(obstacleConfig, playArea, existingObstacles, index)
    local obstacleType = Obstacle.types[obstacleConfig.type]
    if not obstacleType then
        print("Warning: Unknown obstacle type: " .. obstacleConfig.type)
        return nil
    end

    return obstacleType.create(playArea, existingObstacles, obstacleConfig, index)
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
