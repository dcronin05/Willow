---@class Enemy
--- The Enemy class inherits from NPC.
--- Currently it just patrols, but in the future it will track and attack the player.

local pd = playdate
local gfx = pd.graphics

import "scripts/NPC"

class('Enemy').extends(NPC)

--- Initializes a new Enemy instance.
---@param x number The starting X position in pixels.
---@param y number The starting Y position in pixels.
---@param iid string (Optional) The LDtk unique entity ID for persisting state.
---@param health number (Optional) The starting health.
function Enemy:init(x, y, iid, health)
    -- Initialize the base NPC class with the "monster" faction
    Enemy.super.init(self, x, y, "monster", iid, health)
    
    -- Load the slime graphic
    local image = gfx.image.new("images/slime")
    if image then
        self:setImage(image)
        self:setupCollision()
    else
        print("WARNING: images/slime not found")
    end
    
    

    -- Ensure enemies render in front of the terrain (which is Z-Index -1)
    self:setZIndex(5)
    
    -- Make enemies targetable by the interaction vision box!
    self.isInteractable = true
    self.targetName = "Slime"
    
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

function Enemy:die()
    -- Generate a unique ID for the dropped item using current time and random number
    local uid = "drop_" .. pd.getCurrentTimeMilliseconds() .. "_" .. math.random(1000)
    
    -- Spawn a potion! (x, y, itemId, uid, isDropping=true)
    Item(self.x, self.y, "potion", uid, true)
    
    -- Call the base class die to handle cleanup and SaveManager state
    Enemy.super.die(self)
end

function Enemy:onInteract()
    -- Taking damage from the player's attack!
    if _G.player then
        self:takeDamage(50, _G.player.x)
    end
end
