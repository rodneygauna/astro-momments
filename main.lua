-- Love2D Imports
local love = require("love")

-- Module imports
local Player = require("src/player")
local MenuScreen = require("screens/menu_screen")
local MiningScreen = require("screens/mining_screen")
local CashoutScreen = require("screens/cashout_screen")
local MapScreen = require("screens/map_screen")
local BuffSelectionScreen = require("screens/buff_selection_screen")
local UpgradeScreen = require("screens/upgrade_screen")
local cameraFile = require("libs/hump/camera")

-- Global game fonts (will be initialized in love.load() and accessible to all screens)
GameFonts = {}

-- Global game state
local player
local cam
local currentScreen
local currentGameState

-- Game state definitions
local gameStates = {
    MENU = "menu",
    SKILL_TREE = "skill_tree",
    ROUND_START_BUFF_SELECTION = "round_start_buff_selection",
    MAP_SELECTION = "map_selection",
    MINING = "mining",
    CASHOUT = "cashout",
    PAUSED = "paused",
    GAME_OVER = "game_over",
    SETTINGS = "settings",
    CREDITS = "credits"
}

-- Function to change game state
local function changeGameState(newState, ...)
    currentGameState = newState

    if newState == gameStates.MENU then
        currentScreen = MenuScreen
    elseif newState == gameStates.MINING then
        local sectorId = ...
        MiningScreen.load(cam, player, gameStates, changeGameState, sectorId)
        currentScreen = MiningScreen
    elseif newState == gameStates.CASHOUT then
        local sector, cargo = ...
        CashoutScreen.load(player, gameStates, changeGameState, sector, cargo)
        currentScreen = CashoutScreen
    elseif newState == gameStates.MAP_SELECTION then
        local loadedPlayer = ...
        if loadedPlayer then
            player = loadedPlayer -- Update global player with loaded data
        end
        MapScreen.load(player, gameStates, changeGameState)
        currentScreen = MapScreen
    elseif newState == gameStates.PAUSED then
        -- TODO: Load paused screen
        currentScreen = nil
    elseif newState == gameStates.SETTINGS then
        -- TODO: Load settings screen
        currentScreen = nil
    elseif newState == gameStates.CREDITS then
        -- TODO: Load credits screen
        currentScreen = nil
    elseif newState == gameStates.SKILL_TREE then
        UpgradeScreen.load(player, gameStates, changeGameState)
        currentScreen = UpgradeScreen
    elseif newState == gameStates.ROUND_START_BUFF_SELECTION then
        BuffSelectionScreen.load(player, gameStates, changeGameState)
        currentScreen = BuffSelectionScreen
    end
end

-- Love2D load function
function love.load()
    -- Set random seed
    math.randomseed(os.time())

    -- Load custom fonts in various sizes (accessible globally as GameFonts)
    GameFonts.small = love.graphics.newFont("fonts/prstartk.ttf", 12)
    GameFonts.normal = love.graphics.newFont("fonts/prstartk.ttf", 14)
    GameFonts.medium = love.graphics.newFont("fonts/prstartk.ttf", 16)
    GameFonts.large = love.graphics.newFont("fonts/prstartk.ttf", 20)
    GameFonts.title = love.graphics.newFont("fonts/prstartk.ttf", 36)
    GameFonts.huge = love.graphics.newFont("fonts/prstartk.ttf", 48)

    -- Set default font
    love.graphics.setFont(GameFonts.medium)

    -- Initialize player
    player = Player.new()

    -- Initialize camera
    cam = cameraFile()

    -- Initialize menu screen
    MenuScreen.load(gameStates, changeGameState)

    -- Set starting game state
    currentGameState = gameStates.MENU
    currentScreen = MenuScreen

end

-- Love2D update function
function love.update(dt)
    -- Update player playtime
    Player.updatePlaytime(player, dt)

    -- Delegate to current screen
    if currentScreen and currentScreen.update then
        currentScreen.update(dt)
    end

    -- Placeholder screens that just wait for input (handled in keypressed)
end

-- Love2D draw function
function love.draw()
    -- Delegate to current screen
    if currentScreen and currentScreen.draw then
        currentScreen.draw()
    else
        -- Fallback for unimplemented screens
        love.graphics.setColor(1, 1, 1)
        if currentGameState == gameStates.SKILL_TREE then
            love.graphics.printf("Skill Tree Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.ROUND_START_BUFF_SELECTION then
            love.graphics.printf("Round Start Buff Selection Screen (Not Implemented)", 0,
                love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.MAP_SELECTION then
            love.graphics.printf("Map Selection Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.CASHOUT then
            love.graphics.printf("Cashout Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.PAUSED then
            love.graphics.printf("Paused Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.SETTINGS then
            love.graphics.printf("Settings Screen (Not Implemented)\nPress ESC to return", 0,
                love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.CREDITS then
            love.graphics.printf("Credits Screen (Not Implemented)\nPress ESC to return", 0,
                love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        end
    end
end

-- Love2D keypressed function
function love.keypressed(key)
    -- Delegate to current screen
    if currentScreen and currentScreen.keypressed then
        currentScreen.keypressed(key)
    else
        -- Fallback for unimplemented screens
        if currentGameState == gameStates.ROUND_START_BUFF_SELECTION and key == "return" then
            changeGameState(gameStates.MAP_SELECTION)
        elseif currentGameState == gameStates.MAP_SELECTION and key == "return" then
            changeGameState(gameStates.MINING)
        elseif currentGameState == gameStates.CASHOUT and key == "return" then
            changeGameState(gameStates.MAP_SELECTION)
        elseif currentGameState == gameStates.SETTINGS and key == "escape" then
            changeGameState(gameStates.MENU)
        elseif currentGameState == gameStates.CREDITS and key == "escape" then
            changeGameState(gameStates.MENU)
        end
    end
end

-- Love2D mousepressed function
function love.mousepressed(x, y, button)
    -- Delegate to current screen
    if currentScreen and currentScreen.mousepressed then
        currentScreen.mousepressed(x, y, button)
    end
end
