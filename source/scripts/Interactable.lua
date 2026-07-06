---@class Interactable
--- The Interactable class serves as a base class (or interface) for any object in the game world 
--- that the player can walk up to and interact with by pressing the 'A' button.
--- It inherits from the Playdate graphics sprite class so it can be drawn on screen and participate in physics.

local pd = playdate
local gfx = pd.graphics

-- Define the class and inherit from playdate.graphics.sprite
class('Interactable').extends(gfx.sprite)

--- Initializes a new Interactable object at the given world coordinates.
--- This method is meant to be called via `super.init(self)` by child classes like `Sign`.
---@param x number The starting X position in pixels.
---@param y number The starting Y position in pixels.
function Interactable:init(x, y)
    -- Call the base playdate.graphics.sprite initialization
    Interactable.super.init(self)
    
    -- Move the sprite to the requested starting coordinates
    self:moveTo(x, y)
    
    -- Custom flag so we can identify this as an interactable object 
    -- during physics collision checks and vision box queries in Player.lua.
    self.isInteractable = true
    
    -- Register the object with the Playdate sprite system so it can be drawn and updated automatically.
    self:add()
end

--- Determines how the object physically reacts when colliding with other sprites (like the Player).
---@param other sprite The other sprite we bumped into.
---@return integer collisionType The Playdate collision resolution enum.
function Interactable:collisionResponse(other)
    -- kCollisionTypeOverlap means the player can walk *through* it (like walking in front of a sign),
    -- but the physics engine still registers that they are touching so we can detect proximity!
    return gfx.sprite.kCollisionTypeOverlap
end

--- Fired when the player presses the 'A' button while standing in front of this object.
--- This is a virtual method meant to be overridden by child classes.
function Interactable:onInteract()
    -- Subclasses (like Sign or NPC) will override this method to provide specific behavior!
end
