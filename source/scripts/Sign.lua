local pd = playdate
local gfx = pd.graphics

import "scripts/Interactable"

class('Sign').extends(Interactable)

function Sign:init(x, y, text)
    Sign.super.init(self, x, y)
    
    self.text = text
    
    local image = gfx.image.new("images/sign")
    self:setImage(image)
    
    -- Anchor to the bottom center so it sits nicely on the floor
    self:setCenter(0.5, 1) 
    self:setCollideRect(0, 0, self:getSize())
end

function Sign:onInteract()
    UIManager.showDialog(self.text, self)
end
