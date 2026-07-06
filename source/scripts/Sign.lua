---@class Sign
--- The Sign class represents a wooden sign object in the game world.
--- It inherits from the Interactable base class. When the player walks up to it and presses 'A',
--- it triggers a UI Dialog box displaying the text that was configured in the LDtk map editor.

local pd = playdate
local gfx = pd.graphics

import "scripts/Interactable"

-- Define the class and inherit from the custom Interactable class (which in turn inherits from gfx.sprite)
class('Sign').extends(Interactable)

--- Initializes a new Sign object at the given world coordinates with specific text.
---@param x number The starting X position in pixels (usually the top-left coordinate passed from LDtk).
---@param y number The starting Y position in pixels.
---@param text string The custom message this sign will display when interacted with.
function Sign:init(x, y, text)
    -- Call the base Interactable initialization to setup coordinates and collision flags
    Sign.super.init(self, x, y)
    
    -- Store the custom text directly on this instance so we can pass it to the UI later
    self.text = text
    
    -- Load the static sign graphic from the images folder
    local image = gfx.image.new("images/sign")
    self:setImage(image)
    
    -- Anchor to the bottom center (x=0.5, y=1.0) so it sits perfectly flush on the floor tiles!
    -- Without this, it would draw hanging down from the LDtk coordinate.
    self:setCenter(0.5, 1) 
    
    -- Define the physical bounding box for the physics engine using the exact size of the loaded image.
    -- The collision type (Overlap) is handled by the parent Interactable class.
    self:setCollideRect(0, 0, self:getSize())
end

--- Triggered automatically by the Player's vision box logic when the user presses 'A' nearby.
function Sign:onInteract()
    -- Tell the global UIManager singleton to pop up a dialog box containing this sign's text!
    -- We pass `self` as the second argument so the UIManager knows which object triggered it (useful for callbacks).
    UIManager.showDialog(self.text, self)
end
