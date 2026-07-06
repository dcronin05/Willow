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
