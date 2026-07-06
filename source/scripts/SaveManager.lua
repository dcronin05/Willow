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
        health = nil,
        xp = 0,
        level = 1
    },
    inventories = {
        player = { items = {}, gold = 0 }
        -- Other inventories like 'chest_1' or 'npc_bob' can be added dynamically!
    },
    world = {
        currentRoom = "Level_0",
        flags = {}, -- e.g. ["read_first_sign"] = true, ["chest_5_opened"] = true
        entities = {}, -- Tracks all NPCs/Enemies by LDtk iid (x, y, health, dead)
        droppedItems = {} -- Tracks physical items on the floor: { [uid] = { itemId="potion", x=10, y=10 } }
    },
    quests = {
        active = {},
        completed = {}
    }
}

--- Loads the saved game state from Playdate datastore and merges it into memory.
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

--- Iterates through the game scene and serializes player and entity data into the datastore.
function SaveManager.saveGame()
    if _G.player then
        SaveManager.state.player.x = _G.player.x
        SaveManager.state.player.y = _G.player.y
        SaveManager.state.player.health = _G.player.health
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

--- Checks if there is a saved coordinate for the player to respawn at.
---@return boolean
function SaveManager.hasSavedPlayerPosition()
    return SaveManager.state.player.x ~= nil and SaveManager.state.player.y ~= nil
end

--- Retrieves the player's saved coordinates.
---@return number x
---@return number y
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
---@param flagName string The flag to query.
---@return boolean
function SaveManager.getFlag(flagName)
    return SaveManager.state.world.flags[flagName]
end

--- Marks an entity as permanently killed
---@param iid string The LDtk entity identifier.
function SaveManager.setEntityKilled(iid)
    SaveManager.state.world.entities[iid] = SaveManager.state.world.entities[iid] or {}
    SaveManager.state.world.entities[iid].dead = true
    SaveManager.saveGame()
end

--- Checks if an entity is dead
---@param iid string The LDtk entity identifier.
---@return boolean
function SaveManager.isEntityKilled(iid)
    if not SaveManager.state.world.entities[iid] then return false end
    return SaveManager.state.world.entities[iid].dead == true
end

-- ==========================================
-- INVENTORY & ITEM HELPERS
-- ==========================================

--- Adds an item to a specific inventory
---@param invName string The name of the inventory (e.g., "player")
---@param itemId string The ID of the item
---@param amount number (Optional) Amount to add, defaults to 1
function SaveManager.addItem(invName, itemId, amount)
    amount = amount or 1
    SaveManager.state.inventories[invName] = SaveManager.state.inventories[invName] or { items = {}, gold = 0 }
    
    local items = SaveManager.state.inventories[invName].items
    items[itemId] = (items[itemId] or 0) + amount
    SaveManager.saveGame()
end

--- Removes an item from a specific inventory
---@param invName string The name of the inventory (e.g., "player")
---@param itemId string The ID of the item
---@param amount number (Optional) Amount to remove, defaults to 1
---@return boolean success True if successfully consumed
function SaveManager.consumeItem(invName, itemId, amount)
    amount = amount or 1
    if not SaveManager.state.inventories[invName] then return false end
    
    local items = SaveManager.state.inventories[invName].items
    if (items[itemId] or 0) >= amount then
        items[itemId] = items[itemId] - amount
        if items[itemId] <= 0 then
            items[itemId] = nil
        end
        SaveManager.saveGame()
        return true
    end
    return false
end

--- Registers a physical item dropped in the world
---@param uid string Unique identifier for the dropped item instance
---@param itemId string The ID of the item
---@param x number X coordinate
---@param y number Y coordinate
function SaveManager.registerDroppedItem(uid, itemId, x, y)
    SaveManager.state.world.droppedItems[uid] = {
        itemId = itemId,
        x = x,
        y = y
    }
    SaveManager.saveGame()
end

--- Removes a dropped item from the world tracking (e.g., when picked up)
---@param uid string Unique identifier
function SaveManager.removeDroppedItem(uid)
    SaveManager.state.world.droppedItems[uid] = nil
    SaveManager.saveGame()
end
