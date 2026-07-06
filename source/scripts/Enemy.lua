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
    
    -- Ensure enemies render in front of the terrain (which is Z-Index -1)
    self:setZIndex(5)
    
    -- Register to the update loop
    self:add()
end

--- Update logic for the Enemy. Handles Aggro AI and collisions.
function Enemy:update()
    -- Calculate distance to the player
    local distance = 9999
    if _G.player then
        -- Simple Pythagorean theorem to find distance
        local dx = _G.player.x - self.x
        local dy = _G.player.y - self.y
        distance = math.sqrt(dx*dx + dy*dy)
    end
    
    -- Aggro State Machine overrides Patrol
    if distance < 100 then
        -- Within Aggro Radius: Chase the Player!
        self.state = "aggro"
        
        -- Override the patrol timer logic and just walk towards the player
        if _G.player.x > self.x then
            self.xVelocity = self.maxSpeed
        else
            self.xVelocity = -self.maxSpeed
        end
    elseif distance > 150 then
        -- Outside Leash Radius: Return to Patrol state
        self.state = "patrol"
    end
    
    -- If we are touching the player, deal damage!
    if _G.player then
        for _, sprite in ipairs(self:overlappingSprites()) do
            if sprite == _G.player then
                _G.player:takeDamage(20, self.x)
                break
            end
        end
    end
    
    -- Allow the base NPC update to apply our velocities, gravity, and animations
    Enemy.super.update(self)
end
