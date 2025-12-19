-- Meteor obstacle module
local Meteor = {
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
}

return Meteor
