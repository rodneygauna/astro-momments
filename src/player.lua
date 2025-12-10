-- Player module
-- Handles player data, stats, progression, and settings
local Player = {}

-- Create a new player with default values
function Player.new()
    return {
        name = "Captain", -- Player's name
        shipName = "Starfarer", -- Ship's name
        currency = {
            gold = 50000000, -- Mining currency earned from collecting asteroids (starting with 500 for testing)
            fuel = 5 -- Fuel currency for traveling to sectors/maps
        },
        skills = {
            -- Purchased skills from skill tree (to be implemented)
            -- Example: {id = "faster_mining", level = 2, maxLevel = 5}
        },
        stats = {
            -- Permanent stat upgrades from skill tree
            movementSpeedBonus = 0, -- Percentage bonus
            accelerationBonus = 0, -- Percentage bonus
            collectionRadiusBonus = 0, -- Flat bonus
            collectionSpeedBonus = 0, -- Percentage bonus
            decayReduction = 0, -- Percentage bonus
            autoCollectThreshold = nil, -- Threshold percentage
            cargoCapacityBonus = 0, -- Flat bonus
            goldMultiplier = 0, -- Percentage bonus
            missionTimeBonus = 0, -- Flat bonus (seconds)
            fuelEfficiency = 0, -- Percentage bonus
            spawnRateBonus = 0 -- Percentage bonus
        },
        progress = {
            unlockedMaps = {"sector_01"}, -- List of unlocked map/sector IDs
            completedMissions = 0, -- Total missions completed
            totalAsteroidsCollected = 0, -- Lifetime asteroid count
            playTime = 0 -- Total playtime in seconds
        },
        settings = {
            -- Player preferences
            musicVolume = 1.0,
            sfxVolume = 1.0,
            fullscreen = false,
            vsync = true
        }
    }
end

-- Update player playtime
function Player.updatePlaytime(player, dt)
    player.progress.playTime = player.progress.playTime + dt
end

-- Add gold to player currency
function Player.addGold(player, amount)
    player.currency.gold = player.currency.gold + amount
end

-- Add fuel to player currency
function Player.addFuel(player, amount)
    player.currency.fuel = player.currency.fuel + amount
end

-- Check if player can afford a purchase
function Player.canAfford(player, goldCost, fuelCost)
    goldCost = goldCost or 0
    fuelCost = fuelCost or 0
    return player.currency.gold >= goldCost and player.currency.fuel >= fuelCost
end

-- Deduct currency from player
function Player.purchase(player, goldCost, fuelCost)
    goldCost = goldCost or 0
    fuelCost = fuelCost or 0
    if Player.canAfford(player, goldCost, fuelCost) then
        player.currency.gold = player.currency.gold - goldCost
        player.currency.fuel = player.currency.fuel - fuelCost
        return true
    end
    return false
end

-- Unlock a new map
function Player.unlockMap(player, mapId)
    for _, map in ipairs(player.progress.unlockedMaps) do
        if map == mapId then
            return false -- Already unlocked
        end
    end
    table.insert(player.progress.unlockedMaps, mapId)
    return true
end

-- Check if a map is unlocked
function Player.isMapUnlocked(player, mapId)
    for _, map in ipairs(player.progress.unlockedMaps) do
        if map == mapId then
            return true
        end
    end
    return false
end

-- Reset fuel to starting amount
function Player.resetFuel(player)
    player.currency.fuel = 5
end

return Player
