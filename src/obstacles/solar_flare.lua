-- Solar Flare obstacle module
local SolarFlare = {
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
}

return SolarFlare
