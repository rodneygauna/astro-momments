-- Save module
-- Handles saving and loading player data using JSON serialization
local Save = {}

local json = require("libs.dkjson.dkjson")

Save.SAVE_FILE = "player_save.json"
Save.VERSION = "1.0"

-- Check if save file exists
function Save.exists()
    return love.filesystem.getInfo(Save.SAVE_FILE) ~= nil
end

-- Save player data to file
function Save.write(player)
    local success, message = pcall(function()
        -- Wrap player data with metadata
        local saveData = {
            version = Save.VERSION,
            timestamp = os.time(),
            player = player
        }

        -- Encode to JSON with pretty printing
        local jsonString = json.encode(saveData, {
            indent = true
        })

        -- Write to file
        local writeSuccess, writeError = love.filesystem.write(Save.SAVE_FILE, jsonString)
        if not writeSuccess then
            error(writeError)
        end
    end)

    return success, message
end

-- Load player data from file
function Save.read()
    if not Save.exists() then
        return nil, "No save file found"
    end

    local success, result = pcall(function()
        -- Read file contents
        local contents, size = love.filesystem.read(Save.SAVE_FILE)
        if not contents then
            error("Failed to read save file")
        end

        -- Decode JSON
        local saveData, pos, err = json.decode(contents)
        if err then
            error("JSON decode error at position " .. pos .. ": " .. err)
        end

        -- Version checking for future migrations
        if saveData.version ~= Save.VERSION then
            print("Warning: Save version mismatch (expected " .. Save.VERSION .. ", got " .. saveData.version .. ")")
            -- Could add migration logic here in the future
        end

        return saveData.player
    end)

    if success then
        return result
    else
        return nil, result
    end
end

-- Delete save file
function Save.delete()
    if Save.exists() then
        return love.filesystem.remove(Save.SAVE_FILE)
    end
    return true
end

-- Get save file size in bytes (for debugging)
function Save.getSize()
    local info = love.filesystem.getInfo(Save.SAVE_FILE)
    return info and info.size or 0
end

-- Get save file timestamp
function Save.getTimestamp()
    if not Save.exists() then
        return nil
    end

    local success, result = pcall(function()
        local contents = love.filesystem.read(Save.SAVE_FILE)
        local saveData = json.decode(contents)
        return saveData.timestamp
    end)

    return success and result or nil
end

return Save
