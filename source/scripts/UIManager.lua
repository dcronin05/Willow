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
    UIManager.activeUI = InventoryUI()
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
        -- Playdate only has 1-bit color (black/white), so we'll use a patterned dither 
        -- or solid black to represent the health fill. Let's use a solid fill.
        gfx.fillRect(12, 12, fillWidth, 10)
    end
end
