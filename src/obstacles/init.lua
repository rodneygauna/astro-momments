-- Obstacle module
-- Handles environmental hazards and obstacles for sectors
-- This is the main entry point that aggregates all obstacle types
-- Import individual obstacle types
local SolarFlare = require("src.obstacles.solar_flare")
local CosmicDust = require("src.obstacles.cosmic_dust")
local SpaceDebris = require("src.obstacles.space_debris")
local Meteor = require("src.obstacles.meteor")
local BlackHole = require("src.obstacles.black_hole")

local Obstacle = {}

-- Obstacle type definitions
Obstacle.types = {
    solar_flare = SolarFlare,
    cosmic_dust = CosmicDust,
    space_debris = SpaceDebris,
    meteor = Meteor,
    black_hole = BlackHole
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
