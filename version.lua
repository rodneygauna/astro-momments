-- Version module
-- Tracks game version and changelog history
--
-- HOW TO USE:
-- 1. When releasing a new version, update Version.current and Version.buildDate
-- 2. Add a new changelog entry at the TOP of the Version.changelog array
-- 3. Maintain the structure for each entry:
--    - version: string matching Version.current (use semantic versioning: MAJOR.MINOR.PATCH)
--    - date: string in format "Month DD, YYYY"
--    - type: "major", "minor", or "patch"
--    - highlights: array of 1-3 key features/changes (shown as bullet points)
--    - changes: table with three arrays:
--      * added: new features or content
--      * fixed: bug fixes
--      * changed: modifications to existing features
-- 4. Keep entries user-friendly (not too technical)
-- 5. Save and the changelog will automatically appear in-game via the version badge
--
-- EXAMPLE:
-- {
--     version = "0.4.0",
--     date = "February 1, 2025",
--     type = "minor",
--     highlights = {"New asteroid types", "Sound effects system"},
--     changes = {
--         added = {"Ruby and diamond asteroids", "Background music and SFX"},
--         fixed = {"Rare crash in sector transition"},
--         changed = {"Improved UI responsiveness"}
--     }
-- }
local Version = {}

Version.current = "0.3.0"
Version.buildDate = "January 15, 2025"

Version.changelog = {{
    version = "0.3.0",
    date = "January 15, 2025",
    type = "minor",
    highlights = {"New visual effects for obstacles", "Performance optimizations"},
    changes = {
        added = {"Particle effects for solar flares", "Animated accretion disk for black holes",
                 "Visual trails for meteors"},
        fixed = {"Memory leak in cosmic dust particle system", "Frame rate drops in Sector 10"},
        changed = {"Improved rendering performance by 30%",
                   "Reduced particle count for better frame rates on older systems"}
    }
}, {
    version = "0.2.0",
    date = "January 5, 2025",
    type = "minor",
    highlights = {"Quality of life improvements", "Bug fixes and balance changes"},
    changes = {
        added = {"Pause menu in mining screen", "Ability to refuel from map screen",
                 "Scrollbars for better navigation in upgrade and map screens"},
        fixed = {"Crash when exiting to menu during mining", "Fuel not being refunded when stopping mining early",
                 "Asteroid spawn rate not applying upgrade bonuses correctly"},
        changed = {"Increased base fuel tank capacity from 100 to 120", "Reduced fuel cost for early sectors",
                   "Collection radius upgrade now provides 15% per level (was 10%)"}
    }
}, {
    version = "0.1.0",
    date = "December 19, 2024",
    type = "major",
    highlights = {"Initial release", "10 sectors with progressive difficulty",
                  "5 obstacle types including Black Hole boss"},
    changes = {
        added = {"Complete obstacle system (Solar Flares, Cosmic Dust, Space Debris, Meteors, Black Hole)",
                 "Collision-triggered warning system for environmental hazards",
                 "Refactored obstacle codebase into modular structure",
                 "Staggered meteor spawns for better gameplay flow",
                 "Inverse square law gravity for realistic Black Hole physics",
                 "Random obstacle generation for Sector 10 (Chaos Zone)",
                 "Velocity friction system for smooth bounce mechanics",
                 "Boundary protection to prevent players being pushed outside playable area"},
        fixed = {"Black hole spawning on top of player ship at session start",
                 "Asteroids not being deleted when consumed by black hole",
                 "Meteor bounce pushing player outside boundary",
                 "Ship deceleration fighting against black hole gravity",
                 "Collision detection using ship corner instead of center"},
        changed = {"Meteor bounce force adjusted to 800 (from 1000) for better feel",
                   "Black hole spawn location moved to 80% of play area radius",
                   "Increased meteor spawn distance to 300px outside play area",
                   "Sector 10 changed from 'Tranquility Zone' to 'Chaos Zone'"}
    }
} -- Future versions will be added here
}

-- Get the most recent changelog entries
function Version.getLatestChanges(count)
    count = count or 3
    local latest = {}
    for i = 1, math.min(count, #Version.changelog) do
        table.insert(latest, Version.changelog[i])
    end
    return latest
end

-- Get changelog for a specific version
function Version.getChangelogByVersion(versionString)
    for _, entry in ipairs(Version.changelog) do
        if entry.version == versionString then
            return entry
        end
    end
    return nil
end

-- Get all changelogs
function Version.getAllChanges()
    return Version.changelog
end

return Version
