-- Black Hole obstacle module
local BlackHole = {
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

return BlackHole
