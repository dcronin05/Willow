---@class Character
--- The Character class is the Universal Base Class for all living entities in the game.
--- It provides shared physics, gravity, collision resolution, health, and faction tracking.
--- Both the Player and all NPCs/Enemies inherit from this class!

local pd = playdate
local gfx = pd.graphics

class('Character').extends(gfx.sprite)

--- Initializes a new Character instance.
---@param x number The starting X position
---@param y number The starting Y position
---@param faction string The faction this character belongs to (e.g. "player", "monster", "townsfolk")
function Character:init(x, y, faction)
    Character.super.init(self)
    
    self:moveTo(x, y)
    
    -- Base Character Properties
    self.faction = faction or "neutral"
    self.health = 10
    self.maxHealth = 10
    
    -- Physics simulation constants
    self.xVelocity = 0      -- Current horizontal speed
    self.yVelocity = 0      -- Current vertical speed
    self.gravity = 1.0      -- Downward acceleration applied every frame
    self.jumpForce = -9     -- Initial negative upward velocity when jumping
    self.acceleration = 1.0 -- Horizontal acceleration rate
    self.maxSpeed = 3       -- Maximum horizontal speed
    self.friction = 0.75    -- Multiplier used to slow down when not actively moving
    
    -- State flags
    self.grounded = false   -- True if standing on a solid surface
    self.facingRight = true -- Tracks direction for sprite flipping
end

--- Standard collision response for all Characters.
function Character:collisionResponse(other)
    -- Walk in front of interactables (like signs)
    if other.isInteractable then
        return gfx.sprite.kCollisionTypeOverlap
    end
    -- Slide against solid walls and floors
    return gfx.sprite.kCollisionTypeSlide
end

--- Applies gravity and resolves collisions. 
--- Child classes (Player, NPC) should call this in their update loop AFTER calculating their xVelocity and jumping logic.
function Character:applyPhysics()
    -- Apply gravity every frame
    self.yVelocity = self.yVelocity + self.gravity
    
    -- Calculate target position
    local targetX = self.x + self.xVelocity
    local targetY = self.y + self.yVelocity
    
    -- Assume we are falling until a floor collision proves otherwise
    self.grounded = false
    
    -- Attempt to move the sprite
    local actualX, actualY, collisions, length = self:moveWithCollisions(targetX, targetY)
    
    if length > 0 then
        for i=1, length do
            local collision = collisions[i]
            
            -- Only resolve physics for solid Slide collisions
            if collision.type == gfx.sprite.kCollisionTypeSlide then
                if collision.normal.y < 0 then
                    -- Hit floor
                    self.yVelocity = 0
                    self.grounded = true
                elseif collision.normal.y > 0 then
                    -- Hit ceiling
                    self.yVelocity = 0
                end
            end
        end
    end
end

--- Handles taking damage. Can be expanded later for I-frames and death.
function Character:takeDamage(amount, attacker)
    self.health = self.health - amount
    print(self.className .. " took " .. amount .. " damage from " .. tostring(attacker) .. "! Health: " .. self.health)
    
    if self.health <= 0 then
        print(self.className .. " died!")
        self:remove() -- Remove from Playdate sprite list
    end
end

--- ==========================================
--- ANIMATION STATE MACHINE
--- ==========================================
--- Evaluates physical state (grounded, velocity) to determine the correct animation.
--- Flips the sprite based on self.facingRight.
function Character:updateAnimation()
    -- Only evaluate animations if the child class set up a self.animations table
    if self.animations then
        local nextAnimation = self.currentAnimation
        
        -- Determine which animation should be playing based on our physical state
        if not self.grounded and self.animations.jump then
            nextAnimation = self.animations.jump
        elseif math.abs(self.xVelocity) > 0.5 and self.animations.run then
            nextAnimation = self.animations.run
        elseif self.animations.idle then
            nextAnimation = self.animations.idle
        end
        
        -- If we switched to a new animation state this frame, reset its frame counter.
        if nextAnimation ~= self.currentAnimation then
            if nextAnimation.startFrame then
                nextAnimation.frame = nextAnimation.startFrame
            end
            self.currentAnimation = nextAnimation
        end
        
        -- Apply the current frame's image to the sprite
        if self.currentAnimation then
            self:setImage(self.currentAnimation:image())
        end
    end
    
    -- All characters (even static ones) should flip horizontally based on movement direction
    if self.facingRight then
        self:setImageFlip(gfx.kImageUnflipped)
    else
        self:setImageFlip(gfx.kImageFlippedX)
    end
end
