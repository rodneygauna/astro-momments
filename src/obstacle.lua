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
