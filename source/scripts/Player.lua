import "CoreLibs/animation"

---@class Player
--- The Player class handles all character physics, input, animation states, 
--- and interactions with the environment (e.g. Signs, Items).
--- It inherits from the Playdate graphics sprite class.

local pd = playdate
local gfx = pd.graphics

import "scripts/Interactable"

class('Player').extends(gfx.sprite)

--- Initializes a new Player instance at the given world coordinates.
---@param x number The starting X position in pixels.
---@param y number The starting Y position in pixels.
function Player:init(x, y)
    -- Initialize the base sprite class
    Player.super.init(self)
    
    -- ==========================================
    -- ANIMATION SETUP
    -- ==========================================
    -- Load the sprite sheet containing all the player's animation frames
    local imageTable = gfx.imagetable.new("images/player")
    
    -- Create an animation loop object using the custom loop library.
    -- We define three core states: idle, run, and jump.
    self.animations = {
        idle = gfx.animation.loop.new(200, imageTable, true),
        run = gfx.animation.loop.new(100, imageTable, true),
        jump = gfx.animation.loop.new(100, imageTable, true)
    }
    
    -- Assign specific frames from the sprite sheet to each animation state.
    -- Our generated player-table-16-32.png now has 6 frames!
    self.animations.idle.startFrame, self.animations.idle.endFrame = 1, 1
    self.animations.run.startFrame, self.animations.run.endFrame = 2, 5
    self.animations.jump.startFrame, self.animations.jump.endFrame = 6, 6
    
    -- Set the default starting animation
    self.currentAnimation = self.animations.idle
    self:setImage(self.currentAnimation:image())
    
    -- ==========================================
    -- PHYSICS SETUP
    -- ==========================================
    -- Move the sprite to the requested starting coordinates
    self:moveTo(x, y)
    
    -- Define the physical bounding box for collisions. 
    -- We make the collision box 28 pixels tall (instead of the full 32 visual pixels).
    -- This allows the bottom 4 pixels of the player's feet to overlap "into" the ground tiles!
    self:setCollideRect(0, 0, 16, 28)
    
    -- Set the Z-Index to 10 so the player is always drawn on top of background interactables (which default to 0).
    self:setZIndex(10)
    
    -- Register the player with the Playdate sprite system so its update() loop is called automatically.
    self:add()

    -- Physics simulation constants
    self.xVelocity = 0      -- Current horizontal speed
    self.yVelocity = 0      -- Current vertical speed
    self.gravity = 1.0      -- Downward acceleration applied every frame
    self.jumpForce = -9     -- Initial negative upward velocity when jumping
    self.acceleration = 1.0 -- Horizontal acceleration rate
    self.maxSpeed = 3       -- Maximum horizontal speed
    self.friction = 0.75    -- Multiplier used to slow down the player when no keys are pressed
    
    -- Player state flags
    self.grounded = false   -- True if standing on a solid surface
    self.facingRight = true -- Tracks direction for sprite flipping
end

--- Determines how the player physically reacts when colliding with other objects.
---@param other sprite The other sprite we bumped into.
---@return integer collisionType The Playdate collision resolution enum.
function Player:collisionResponse(other)
    -- If the object is marked as interactable (e.g. a Sign), we want to be able to walk IN FRONT of it.
    -- kCollisionTypeOverlap tells the physics engine to not block our movement.
    if other.isInteractable then
        return gfx.sprite.kCollisionTypeOverlap
    end
    -- For everything else (like walls and floors), we slide against them so we don't pass through.
    return gfx.sprite.kCollisionTypeSlide
end

--- Called automatically every frame by the Playdate sprite system.
function Player:update()
    
    -- ==========================================
    -- 1. INPUT HANDLING
    -- ==========================================
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = self.xVelocity - self.acceleration
        self.facingRight = false
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.xVelocity + self.acceleration
        self.facingRight = true
    else
        -- Apply friction when no directional buttons are pressed to slide to a stop
        self.xVelocity = self.xVelocity * self.friction
    end
    
    -- Clamp the horizontal velocity so the player doesn't exceed maxSpeed
    self.xVelocity = math.max(-self.maxSpeed, math.min(self.maxSpeed, self.xVelocity))
    
    -- Apply gravity to the vertical velocity every frame (pulling the player down)
    self.yVelocity = self.yVelocity + self.gravity
    
    -- Handle Jumping
    -- We can only jump if the Up button was JUST pressed, and we are currently touching the ground.
    if pd.buttonJustPressed(pd.kButtonUp) and self.grounded then
        self.yVelocity = self.jumpForce
    end
    
    -- ==========================================
    -- 2. ANIMATION STATE MACHINE
    -- ==========================================
    local nextAnimation = self.currentAnimation
    
    -- Determine which animation should be playing based on our physical state
    if not self.grounded then
        nextAnimation = self.animations.jump
    elseif math.abs(self.xVelocity) > 0.5 then -- Use a small threshold instead of exactly 0 due to friction float math
        nextAnimation = self.animations.run
    else
        nextAnimation = self.animations.idle
    end
    
    -- If we switched to a new animation state this frame, reset its frame counter so it starts from the beginning.
    if nextAnimation ~= self.currentAnimation then
        nextAnimation.frame = nextAnimation.startFrame
        self.currentAnimation = nextAnimation
    end
    
    -- Apply the current frame's image to the sprite
    self:setImage(self.currentAnimation:image())
    
    -- Flip the sprite horizontally based on which way we are walking
    if self.facingRight then
        self:setImageFlip(gfx.kImageUnflipped)
    else
        self:setImageFlip(gfx.kImageFlippedX)
    end
    
    -- ==========================================
    -- 3. PHYSICS & COLLISION RESOLUTION
    -- ==========================================
    -- Calculate where we *want* to move this frame
    local targetX = self.x + self.xVelocity
    local targetY = self.y + self.yVelocity
    
    -- Assume we are in the air until a collision proves otherwise
    self.grounded = false
    
    -- Attempt to move the sprite. The physics engine returns our actual allowed position, 
    -- as well as an array of all collisions that occurred during the movement.
    local actualX, actualY, collisions, length = self:moveWithCollisions(targetX, targetY)
    
    if length > 0 then
        -- Loop through every object we bumped into during this frame's movement
        for i=1, length do
            local collision = collisions[i]
            
            -- CRITICAL: Only resolve physical bouncing/stopping for solid Slide collisions!
            -- Overlaps (like Signs) should not act as ground, otherwise the player can jump off thin air!
            if collision.type == playdate.graphics.sprite.kCollisionTypeSlide then
                
                -- collision.normal.y is -1 if we hit something below us (a floor)
                if collision.normal.y < 0 then
                    self.yVelocity = 0
                    self.grounded = true
                    
                -- collision.normal.y is 1 if we hit something above us (a ceiling)
                elseif collision.normal.y > 0 then
                    self.yVelocity = 0
                end
            end
        end
    end
    
    -- ==========================================
    -- 4. INTERACTION DETECTION (VISION BOX)
    -- ==========================================
    self.currentInteractable = nil
    
    if not UIManager.isUIActive() then
        -- We create a virtual "vision box" extending 32 pixels in front of the player.
        local visionX = self.x
        local visionWidth = 32
        
        -- If facing left, we push the vision box 32 pixels behind our current X coordinate.
        if not self.facingRight then
            visionX = self.x - 32
        end
        
        -- Query the physics engine for ALL sprites overlapping this vision box
        local sprites = gfx.sprite.querySpritesInRect(visionX, self.y, visionWidth, 32)
        
        local closestDist = math.huge
        local bestInteractable = nil
        
        -- Loop through every sprite found in the vision box
        for i=1, #sprites do
            -- Check if the sprite is actually an Interactable object
            if sprites[i].isInteractable then
                -- Calculate the absolute horizontal distance between the player and the object
                local dist = math.abs(self.x - sprites[i].x)
                
                -- We want to prioritize the object that is CLOSEST to the player, 
                -- in case multiple signs are clumped together.
                if dist < closestDist then
                    closestDist = dist
                    bestInteractable = sprites[i]
                end
            end
        end
        
        -- If we found a valid interactable in our vision box, save a reference to it.
        -- This allows main.lua to draw the hover indicator, and allows the A button to trigger it.
        if bestInteractable then
            self.currentInteractable = bestInteractable
            
            -- If the user presses A, fire the interaction event!
            if pd.buttonJustPressed(pd.kButtonA) then
                self.currentInteractable:onInteract()
            end
        end
    end
end
