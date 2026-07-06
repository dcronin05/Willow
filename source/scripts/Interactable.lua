local pd = playdate
local gfx = pd.graphics

class('Interactable').extends(gfx.sprite)

function Interactable:init(x, y)
    Interactable.super.init(self)
    self:moveTo(x, y)
    
    -- Custom flag so we can identify this as an interactable object
    self.isInteractable = true
    
    -- Add to the sprite system
    self:add()
end

function Interactable:collisionResponse(other)
    -- kCollisionTypeOverlap means the player can walk *through* it,
    -- but the physics engine still registers that they are touching!
    return gfx.sprite.kCollisionTypeOverlap
end

function Interactable:onInteract()
    -- Subclasses will override this!
end
