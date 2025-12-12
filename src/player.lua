-- Player module
-- Handles player data, stats, progression, and settings
local Player = {}

-- Create a new player with default values
function Player.new()
    return {
        name = "Captain", -- Player's name
        shipName = "Starfarer", -- Ship's name
        currency = {
            gold = 0, -- Mining currency earned from collecting asteroids
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
            fuelCapacityBonus = 0, -- Flat bonus
            spawnRateBonus = 0 -- Percentage bonus
        },
        progress = {
            unlockedMaps = {"sector_01"}, -- List of unlocked map/sector IDs
            completedMissions = 0, -- Total missions completed
            totalAsteroidsCollected = 0, -- Lifetime asteroid count
            playTime = 0, -- Total playtime in seconds
            emergencyBeaconPenalty = false -- 10% cashout penalty on next mission
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

-- Reset fuel to maximum capacity
function Player.resetFuel(player)
    player.currency.fuel = Player.getMaxFuel(player)
end

-- Get maximum fuel capacity (base 5 + upgrades, max 25)
function Player.getMaxFuel(player)
    local baseFuel = 5
    local bonus = player.stats.fuelCapacityBonus or 0
    return math.min(baseFuel + bonus, 25)
end

-- Refuel to max capacity
-- Returns cost and fuel gained
function Player.calculateRefuelCost(player)
    local maxFuel = Player.getMaxFuel(player)
    local currentFuel = player.currency.fuel
    local fuelNeeded = maxFuel - currentFuel

    if fuelNeeded <= 0 then
        return 0, 0 -- Already at max
    end

    -- 5% of current gold, minimum 1g
    local cost = math.max(1, math.ceil(player.currency.gold * 0.05))

    return cost, fuelNeeded
end

-- Perform refuel purchase
function Player.refuel(player)
    local cost, fuelGained = Player.calculateRefuelCost(player)

    -- Debug output
    print("=== REFUEL DEBUG ===")
    print("fuelCapacityBonus:", player.stats.fuelCapacityBonus)
    print("Current fuel:", player.currency.fuel)
    print("Max fuel (calculated):", Player.getMaxFuel(player))
    print("Fuel gained:", fuelGained)
    print("Cost:", cost)

    if cost == 0 or fuelGained == 0 then
        return false, "Already at max fuel"
    end

    if player.currency.gold < cost then
        return false, "Not enough gold"
    end

    -- Deduct gold and add fuel
    player.currency.gold = player.currency.gold - cost
    player.currency.fuel = Player.getMaxFuel(player)

    print("New fuel after refuel:", player.currency.fuel)
    print("===================")

    return true, "Refueled"
end

-- Emergency beacon - gives fuel when player has 0 gold and 0 fuel
function Player.useEmergencyBeacon(player)
    -- Only available if truly stuck (0 gold AND 0 fuel)
    if player.currency.gold > 0 or player.currency.fuel > 0 then
        return false, "Emergency beacon only available when out of gold and fuel"
    end

    -- Give enough fuel for one sector (1 fuel)
    player.currency.fuel = 1

    -- Apply 10% penalty on next cashout
    player.progress.emergencyBeaconPenalty = true

    return true, "Emergency beacon activated - 10% penalty on next cashout"
end

-- Check if emergency beacon is needed/available
function Player.needsEmergencyBeacon(player)
    return player.currency.gold == 0 and player.currency.fuel == 0
end

return Player
