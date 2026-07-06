-- SaveManager handles persisting game state to the Playdate flash storage.
local pd = playdate

SaveManager = {}

-- Internal state table to hold data we want to save.
-- Playdate's datastore natively serializes nested Lua tables into JSON, 
-- allowing us to easily save complex, deeply nested data structures!
SaveManager.state = {
    player = {
        x = nil,
        y = nil,
        xp = 0,
        level = 1
    },
    inventory = {
        items = {}, -- e.g. ["sword_1"] = { quantity = 1, equipped = true }
        gold = 0
    },
    world = {
        currentRoom = "Level_0",
        flags = {} -- e.g. ["read_first_sign"] = true, ["chest_5_opened"] = true
    },
    quests = {
        active = {},
        completed = {}
    }
}

function SaveManager.loadGame()
    local savedData = pd.datastore.read("willow_save")
    if savedData then
        -- We merge the savedData over our default state template.
        -- This ensures that if we add new features (like 'quests') in a future update,
        -- old save files won't crash the game for missing those keys.
        for category, data in pairs(savedData) do
            SaveManager.state[category] = data
        end
        print("Save loaded successfully!")
    else
        print("No save found, starting fresh.")
    end
end

function SaveManager.saveGame()
    if _G.player then
        SaveManager.state.player.x = _G.player.x
        SaveManager.state.player.y = _G.player.y
    end
    
    pd.datastore.write(SaveManager.state, "willow_save")
    print("Game saved!")
end

function SaveManager.hasSavedPlayerPosition()
    return SaveManager.state.player.x ~= nil and SaveManager.state.player.y ~= nil
end

function SaveManager.getSavedPlayerPosition()
    return SaveManager.state.player.x, SaveManager.state.player.y
end

-- ==========================================
-- STATE MANAGEMENT HELPERS
-- ==========================================

--- Sets a persistent world flag (e.g. for tracking if a chest is opened) and auto-saves the game!
function SaveManager.setFlag(flagName, value)
    SaveManager.state.world.flags[flagName] = value
    SaveManager.saveGame()
end

--- Checks if a world flag is set
function SaveManager.getFlag(flagName)
    return SaveManager.state.world.flags[flagName]
end
