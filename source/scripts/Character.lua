---@class Character
--- The Character class is the Universal Base Class for all living entities in the game.
--- It provides shared physics, gravity, collision resolution, health, and faction tracking.
--- Both the Player and all NPCs/Enemies inherit from this class!

local pd = playdate
local gfx = pd.graphics

class('Character').extends(gfx.sprite)

--- Initializes a new Character instance.
---@param x number The starting X position in pixels.
---@param y number The starting Y position in pixels.
---@param faction string (Optional) The team this character belongs to ("player", "monster", etc).
---@param iid string (Optional) The LDtk unique entity ID for persisting state.
---@param health number (Optional) The starting health, overriding maxHealth if provided.
function Character:init(x, y, faction, iid, health)
    Character.super.init(self)
    
    self:moveTo(x, y)
    
    -- The team this character belongs to (e.g. "player", "monster", "npc")
    self.faction = faction or "neutral"
    self.iid = iid
    
    -- Health & Combat
    self.maxHealth = 100
    self.health = health or self.maxHealth
    self.invincible = false
    
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
    -- Walk in front of interactables (like signs) or through other Characters
    if other.isInteractable or other:isa(Character) then
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
function Character:takeDamage(amount, sourceX)
    if self.invincible then return end
    
    self.health = math.max(0, self.health - amount)
    print(self.className .. " took " .. amount .. " damage! Health: " .. self.health)
    
    -- Knockback
    self.yVelocity = -4
    if sourceX then
        if self.x > sourceX then
            self.xVelocity = 6
        else
            self.xVelocity = -6
        end
    end
    
    -- I-Frames
    self.invincible = true
    pd.timer.performAfterDelay(1000, function()
        self.invincible = false
        self:setVisible(true)
    end)
    
    if self.health <= 0 then
        self:die()
    end
end

--- Handles the death sequence. Overridden by child classes for custom behavior.
function Character:die()
    print(self.className .. " died!")
    
    -- If this character has a unique ID, mark them as dead forever in the save file
    if self.iid then
        SaveManager.setEntityKilled(self.iid)
    end
    
    self:remove() -- Remove from Playdate sprite list
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
    
    -- Handle Invincibility Flickering
    if self.invincible then
        local ms = pd.getCurrentTimeMilliseconds()
        self:setVisible(ms % 200 < 100)
    end
end
