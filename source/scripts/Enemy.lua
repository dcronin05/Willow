---@class Enemy
--- The Enemy class inherits from NPC.
--- Currently it just patrols, but in the future it will track and attack the player.

local pd = playdate
local gfx = pd.graphics

import "scripts/NPC"

class('Enemy').extends(NPC)

function Enemy:init(x, y)
    -- Initialize the base NPC class with the "monster" faction
    Enemy.super.init(self, x, y, "monster")
    
    -- Load the slime graphic
    local image = gfx.image.new("images/slime")
    if image then
        self:setImage(image)
        self:setCollideRect(0, 0, self:getSize())
    else
        print("WARNING: images/slime not found")
    end
    
    -- Anchor bottom center
    self:setCenter(0.5, 1)
    
    -- Register to the update loop
    self:add()
end
