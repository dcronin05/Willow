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

--- Opens the Inventory Menu
function UIManager.showInventory()
    if UIManager.activeUI then return end
    
    local playerInv = SaveManager.state.inventories["player"] or {}
    local inventoryItems = playerInv.items or {}
    local consumableChildren = {}
    local equipmentChildren = {}
    local currencyChildren = {}
    
    for id, qty in pairs(inventoryItems) do
        local itemDef = ItemDatabase[id]
        if itemDef then
            local node = {
                title = itemDef.name,
                qty = qty,
                onSelect = function()
                    if itemDef.type == "consumable" then
                        if id == "potion" then
                            if _G.player then
                                local heal = itemDef.healAmount or 25
                                _G.player.health = math.min(_G.player.maxHealth, _G.player.health + heal)
                            end
                            SaveManager.consumeItem("player", id, 1)
                            
                            -- Rebuild UI to reflect new quantities or removed items
                            UIManager.clearUI()
                            UIManager.showInventory()
                        end
                    end
                end
            }
            if itemDef.type == "consumable" then
                table.insert(consumableChildren, node)
            elseif itemDef.type == "currency" then
                table.insert(currencyChildren, node)
            else
                table.insert(equipmentChildren, node)
            end
        end
    end
    
    local rootMenu = {}
    if #currencyChildren > 0 then table.insert(rootMenu, { title = "Currency", children = currencyChildren }) end
    if #consumableChildren > 0 then table.insert(rootMenu, { title = "Consumables", children = consumableChildren }) end
    if #equipmentChildren > 0 then table.insert(rootMenu, { title = "Equipment", children = equipmentChildren }) end
    if #rootMenu == 0 then table.insert(rootMenu, { title = "Inventory Empty" }) end
    
    UIManager.activeUI = TreeMenu(rootMenu)
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
    
    -- Draw the Target HUD centered underneath the top reserved row (at Y=20)
    if _G.player.currentInteractable then
        local target = _G.player.currentInteractable
        local targetName = target.targetName or target.className or "Unknown"
        
        -- If it's a character with health, display health too
        local text = targetName
        if target.health then
            text = text .. " (HP: " .. target.health .. ")"
        end
        
        -- Measure text width to draw a nice background box
        local textWidth = gfx.getTextSize(text)
        local boxWidth = textWidth + 16
        local boxHeight = 20
        local x = 200 - (boxWidth / 2)
        local y = 20
        
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(x, y, boxWidth, boxHeight, 4)
        
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(x + 1, y + 1, boxWidth - 2, boxHeight - 2, 4)
        
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(text, x + 8, y + 3)
    end
end
