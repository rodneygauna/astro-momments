-- Sector module
-- Handles sector data, including asteroid spawning and layout
local Sector = {}

-- Sector definitions
Sector.definitions = {
    sector_01 = {
        id = "sector_01",
        name = "Silicate Plains",
        description = "A common mining zone filled with basic silicate and carbonaceous asteroids. Perfect for beginners learning the ropes.",
        asteroidTypes = {"silicates", "carbonaceous"},
        spawnRate = 1.0,
        unlock_cost = 0, -- Free sector to start with
        fuel_cost = 1, -- Fuel cost to travel to this sector
        planetImage = "sprites/Planet-Green-Blue.png" -- Background planet sprite
    },
    sector_02 = {
        id = "sector_02",
        name = "Ironclad Belt",
        description = "Dense metallic asteroids drift through this industrial sector. Iron and nickel deposits make this a staple mining route.",
        asteroidTypes = {"iron", "nickel"},
        spawnRate = 1.0,
        unlock_cost = 100, -- Cost to unlock this sector
        fuel_cost = 2 -- Fuel cost to travel to this sector
    },
    sector_03 = {
        id = "sector_03",
        name = "Magnesium Expanse",
        description = "Shimmering green-tinted asteroids rich in magnesium silicates and aluminum minerals dominate this vast field.",
        asteroidTypes = {"magnesium_silicates", "aluminum_minerals"},
        spawnRate = 1.0,
        unlock_cost = 200, -- Cost to unlock this sector
        fuel_cost = 3 -- Fuel cost to travel to this sector
    },
    sector_04 = {
        id = "sector_04",
        name = "Calcite Reef",
        description = "Ancient calcium-rich asteroids intermingle with sulfide deposits in this chemically diverse sector.",
        asteroidTypes = {"calcium_minerals", "sulfides"},
        spawnRate = 1.0,
        unlock_cost = 300, -- Cost to unlock this sector
        fuel_cost = 4 -- Fuel cost to travel to this sector
    },
    sector_05 = {
        id = "sector_05",
        name = "Frozen Frontier",
        description = "Ice-laden asteroids glimmer in the void alongside carbonates. Water and mineral wealth await hardy prospectors.",
        asteroidTypes = {"water_ice", "carbonates"},
        spawnRate = 1.0,
        unlock_cost = 400, -- Cost to unlock this sector
        fuel_cost = 5 -- Fuel cost to travel to this sector
    },
    sector_06 = {
        id = "sector_06",
        name = "Clay Fields",
        description = "A sediment-rich zone where clay minerals and graphite crystals form unusual asteroid compositions.",
        asteroidTypes = {"clay_minerals", "graphite"},
        spawnRate = 1.0,
        unlock_cost = 500, -- Cost to unlock this sector
        fuel_cost = 6 -- Fuel cost to travel to this sector
    },
    sector_07 = {
        id = "sector_07",
        name = "Chromium Wastes",
        description = "Dark asteroids bearing chromium oxides and cobalt deposits drift through this hazardous mining zone.",
        asteroidTypes = {"chromium_oxides", "cobalt"},
        spawnRate = 1.0,
        unlock_cost = 600, -- Cost to unlock this sector
        fuel_cost = 7 -- Fuel cost to travel to this sector
    },
    sector_08 = {
        id = "sector_08",
        name = "Titanium Reaches",
        description = "Valuable titanium oxide asteroids cluster alongside rare earth deposits in this contested sector.",
        asteroidTypes = {"titanium_oxides", "rare_earths"},
        spawnRate = 1.0,
        unlock_cost = 700, -- Cost to unlock this sector
        fuel_cost = 8 -- Fuel cost to travel to this sector
    },
    sector_09 = {
        id = "sector_09",
        name = "Platinum Verge",
        description = "The crown jewel of mining territories. Platinum group metals and gold asteroids drift in dangerous proximity.",
        asteroidTypes = {"platinum_group", "gold"},
        spawnRate = 1.0,
        unlock_cost = 800, -- Cost to unlock this sector
        fuel_cost = 9 -- Fuel cost to travel to this sector
    },
    sector_10 = {
        id = "sector_10",
        name = "Genesis Cluster",
        description = "The rarest sector in known space. Microdiamonds and organic amino acid asteroids hold mysteries of cosmic origins.",
        asteroidTypes = {"microdiamonds", "amino_acids"},
        spawnRate = 1.0,
        unlock_cost = 900, -- Cost to unlock this sector
        fuel_cost = 10 -- Fuel cost to travel to this sector
    }
}

return Sector
