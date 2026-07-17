---@class UIManager
--- The UIManager is a global singleton responsible for tracking the currently active UI overlay.
--- By centralizing this state, other scripts (like Player.lua) can easily check if a UI is open 
--- and pause gameplay logic (like movement or interactions) accordingly.

-- Create a global table so it can be accessed from any file without needing to be imported or passed around.
_G.UIManager = {}

-- Holds a reference to the currently active UI sprite (e.g. a MessageBox instance).
-- If this is nil, it means the player is free to walk around.
UIManager.activeUI = nil

--- Pops up a new dialog box on the screen, freezing gameplay.
---@param text string The message to display.
---@param sourceInteractable sprite (Optional) The object in the world that triggered this dialog.
function UIManager.showDialog(text, sourceInteractable)
    -- Prevent opening a new dialog if one is already open (prevents spamming the 'A' button)
    if UIManager.activeUI then return end
    
    -- Instantiate the MessageBox sprite. It automatically adds itself to the Playdate render loop.
    -- We save a reference to it here in the global singleton to lock out player movement.
    UIManager.activeUI = MessageBox(text, sourceInteractable)
end

--- Utility function to check if the game is currently paused by a UI overlay.
---@return boolean isUIActive True if a UI is open, false otherwise.
function UIManager.isUIActive()
    return UIManager.activeUI ~= nil
end

--- Closes the currently active UI
function UIManager.clearUI()
    if UIManager.activeUI then
        UIManager.activeUI:remove()
        UIManager.activeUI = nil
    end
end

--- Opens the Inventory Menu by dynamically generating a hierarchical Tree Menu structure.
--- This reads the latest inventory state from SaveManager, cross-references it with ItemDatabase,
--- and groups items into visual categories (Currency, Consumables, Equipment).
function UIManager.showInventory()
    -- Prevent opening the UI if another menu (like a dialog box) is already open
    if UIManager.activeUI then return end
    
    -- Safely retrieve the player's inventory from the global save state.
    -- We use 'or {}' to prevent nil reference crashes if the inventory hasn't been initialized yet.
    local playerInv = SaveManager.state.inventories["player"] or {}
    local inventoryItems = playerInv.items or {}
    
    -- These tables will act as the "sub-menus" or "folders" in our Tree Menu.
    local consumableChildren = {}
    local equipmentChildren = {}
    local currencyChildren = {}
    
    -- Loop over every item ID and quantity stored in the player's save data
    for id, qty in pairs(inventoryItems) do
        -- Look up the actual item data (name, description, type, healAmount) from our static database
        local itemDef = ItemDatabase[id]
        
        -- Only proceed if the item exists in the database (prevents crashing from deprecated items)
        if itemDef then
            
            -- Create a 'Node' representing this specific item in the menu list.
            -- We must declare the table first so the closure inside can reference it!
            local node = {}
            node.title = itemDef.name
            
            -- If this is the currently equipped item, append an indicator!
            if itemDef.type == "equipment" and itemDef.slot then
                if SaveManager.state.equipment and SaveManager.state.equipment[itemDef.slot] == id then
                    node.title = node.title .. " [E]"
                end
            end
            
            node.qty = qty
            
            -- This function is triggered dynamically by TreeMenu.lua when the player presses 'A' on this item
            node.onSelect = function(activeMenu)
                -- LOGIC: Consumable Items
                if itemDef.type == "consumable" then
                    
                    -- Specific logic for health potions
                    if id == "potion" then
                        if _G.player then
                            -- Read the healAmount from the DB, defaulting to 25 if missing
                            local heal = itemDef.healAmount or 25
                            -- Add health, but clamp it using math.min so we never exceed maxHealth
                            _G.player.health = math.min(_G.player.maxHealth, _G.player.health + heal)
                        end
                        
                        -- Tell the SaveManager to remove 1 potion from the inventory and save to disk
                        SaveManager.consumeItem("player", id, 1)
                        
                        -- In-place UI update so the user isn't kicked out of the menu!
                        -- We manually decrement the quantity on this specific UI node
                        -- activeMenu is the TreeMenu instance passed in by the TreeMenu script when called
                        node.qty = node.qty - 1
                        if node.qty <= 0 then
                            -- The item is gone! Remove it from the current list array
                            table.remove(activeMenu.currentData, activeMenu.selectedIndex)
                            
                            -- Clamp the cursor so it doesn't point out of bounds
                            activeMenu.selectedIndex = math.max(1, math.min(activeMenu.selectedIndex, #activeMenu.currentData))
                            
                            -- Note: We no longer auto-pop the user back up the menu tree when it empties.
                            -- Because categories are now permanent, the TreeMenu will simply render "*Empty*",
                            -- and the user can manually press B to go back when they are finished.
                        end
                        
                        -- Force the TreeMenu to redraw the screen with the new quantities
                        activeMenu:drawUI()
                    end
                elseif itemDef.type == "equipment" then
                    -- LOGIC: Equipping Weapons/Armor
                    -- For now we only have weapons, but we can check itemDef.slot later!
                    if itemDef.slot == "weapon" then
                        SaveManager.state.equipment.weapon = id
                        SaveManager.saveGame()
                        
                        -- Update the UI text dynamically so we don't lose our scroll position!
                        for i = 1, #activeMenu.currentData do
                            local n = activeMenu.currentData[i]
                            -- Strip out the [E] tag from all items in this category
                            n.title = string.gsub(n.title, " %[E%]", "")
                        end
                        -- Append it to the newly selected item
                        node.title = node.title .. " [E]"
                        
                        activeMenu:drawUI()
                    end
                end
            end
            
            -- Sort the dynamically generated node into the correct category table based on its type
            if itemDef.type == "consumable" then
                table.insert(consumableChildren, node)
            elseif itemDef.type == "currency" then
                table.insert(currencyChildren, node)
            else
                -- Fallback for weapons, armor, quest items, etc.
                table.insert(equipmentChildren, node)
            end
        end
    end
    
    -- Now that we have grouped all items, we build the "Root" of the tree menu.
    -- We always display the core categories so the UI layout is consistent and predictable.
    -- If a player selects an empty category, the TreeMenu will automatically display "*Empty*".
    local rootMenu = {
        { title = "World Map", addSeparator = true, onSelect = function(activeMenu)
            UIManager.clearUI()
            UIManager.activeUI = MapUI()
        end },
        { title = "Equipment", children = equipmentChildren },
        { title = "Consumables", children = consumableChildren },
        { title = "Currency", children = currencyChildren }
    }
    
    -- Instantiate our generic TreeMenu class, passing it our dynamically built hierarchical data!
    UIManager.activeUI = TreeMenu(rootMenu)
end

--- Draws text that is physically 2x thicker (by stamping it in a 2x2 grid) 
--- and wraps it in a solid 1px black outline.
function UIManager.drawThickOutlinedText(text, x, y)
    local gfx = playdate.graphics
    -- 1. Draw the Black Outline (Outer Ring)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawText(text, x - 1, y)
    gfx.drawText(text, x - 1, y + 1)
    gfx.drawText(text, x + 2, y)
    gfx.drawText(text, x + 2, y + 1)
    gfx.drawText(text, x, y - 1)
    gfx.drawText(text, x + 1, y - 1)
    gfx.drawText(text, x, y + 2)
    gfx.drawText(text, x + 1, y + 2)
    gfx.drawText(text, x - 1, y - 1)
    gfx.drawText(text, x + 2, y - 1)
    gfx.drawText(text, x - 1, y + 2)
    gfx.drawText(text, x + 2, y + 2)
    
    -- 2. Draw the White Core (2x2 thick)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(text, x, y)
    gfx.drawText(text, x + 1, y)
    gfx.drawText(text, x, y + 1)
    gfx.drawText(text, x + 1, y + 1)
end

--- Draws persistent Heads-Up Display elements (like the Health Bar) directly to the screen.
function UIManager.drawHUD()
    if not _G.player then return end
    
    local gfx = playdate.graphics
    
    -- Draw Health Bar Container (Border)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRect(10, 10, 104, 14)
    gfx.setLineWidth(1)
    
    -- Draw Filled Health Bar based on ratio
    local fillWidth = math.max(0, math.floor((_G.player.health / _G.player.maxHealth) * 100))
    if fillWidth > 0 then
        gfx.fillRect(12, 12, fillWidth, 10)
    end
    
    -- Draw the Target HUD centered underneath the top reserved row (at Y=25)
    if _G.player.currentInteractable then
        local target = _G.player.currentInteractable
        local targetName = target.targetName or target.className or "Unknown"
        
        -- If it's a character with health, display health too
        local text = targetName
        if target.health then
            text = text .. " (HP: " .. target.health .. ")"
        end
        
        -- Measure text width to center it
        local textWidth = gfx.getTextSize(text)
        local x = 200 - (textWidth / 2)
        local y = 25
        
        -- Draw the target name using our new transparent, thick text style!
        UIManager.drawThickOutlinedText(text, x, y)
    end
end
