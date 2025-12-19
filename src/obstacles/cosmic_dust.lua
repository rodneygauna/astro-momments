-- Cosmic Dust obstacle module
local CosmicDust = {
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

return CosmicDust
