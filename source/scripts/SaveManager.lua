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
        flags = {}, -- e.g. ["read_first_sign"] = true, ["chest_5_opened"] = true
        entities = {} -- Tracks all NPCs/Enemies by LDtk iid (x, y, health, dead)
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
            if type(data) == "table" and SaveManager.state[category] ~= nil then
                for k, v in pairs(data) do
                    SaveManager.state[category][k] = v
                end
            else
                SaveManager.state[category] = data
            end
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
    
    -- Dynamically save the state of any entity that has an iid
    for _, sprite in ipairs(pd.graphics.sprite.getAllSprites()) do
        if sprite.iid then
            -- Make sure the table for this iid exists
            SaveManager.state.world.entities[sprite.iid] = SaveManager.state.world.entities[sprite.iid] or {}
            
            -- Save its current properties
            SaveManager.state.world.entities[sprite.iid].x = sprite.x
            SaveManager.state.world.entities[sprite.iid].y = sprite.y
            if sprite.health then
                SaveManager.state.world.entities[sprite.iid].health = sprite.health
            end
        end
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

--- Marks an entity as permanently killed
function SaveManager.setEntityKilled(iid)
    SaveManager.state.world.entities[iid] = SaveManager.state.world.entities[iid] or {}
    SaveManager.state.world.entities[iid].dead = true
    SaveManager.saveGame()
end

--- Checks if an entity is dead
function SaveManager.isEntityKilled(iid)
    if not SaveManager.state.world.entities[iid] then return false end
    return SaveManager.state.world.entities[iid].dead == true
end
