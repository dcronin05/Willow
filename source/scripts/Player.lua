import "CoreLibs/animation"

local pd = playdate
local gfx = pd.graphics

class('Player').extends(gfx.sprite)

function Player:init(x, y)
    Player.super.init(self)
    
    -- Load the animation spritesheet
    local playerImageTable = gfx.imagetable.new("images/player")
    
    -- Setup animations
    self.animations = {
        idle = gfx.animation.loop.new(100, playerImageTable, true),
        run = gfx.animation.loop.new(150, playerImageTable, true),
        jump = gfx.animation.loop.new(100, playerImageTable, false)
    }
    
    -- Assign frames (1-based index)
    self.animations.idle.startFrame = 1
    self.animations.idle.endFrame = 1
    self.animations.run.startFrame = 2
    self.animations.run.endFrame = 3
    self.animations.jump.startFrame = 4
    self.animations.jump.endFrame = 4
    
    self.currentAnimation = self.animations.idle
    self:setImage(self.currentAnimation:image())
    
    -- Move the sprite to the starting coordinates
    self:moveTo(x, y)
    
    -- Define the collision box (the 16x32 frame size)
    self:setCollideRect(0, 0, 16, 32)
    self:add()

    -- Physics Variables
    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 1.0
    self.jumpForce = -15
    self.acceleration = 1.5
    self.maxSpeed = 5
    self.friction = 0.75
    
    -- State Variables
    self.grounded = false
    self.facingRight = true
end

function Player:collisionResponse(other)
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    -- Apply Gravity
    self.yVelocity = self.yVelocity + self.gravity
    
    -- Handle D-Pad Input
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = self.xVelocity - self.acceleration
        self.facingRight = false
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.xVelocity + self.acceleration
        self.facingRight = true
    else
        self.xVelocity = self.xVelocity * self.friction
        if math.abs(self.xVelocity) < 0.1 then self.xVelocity = 0 end
    end
    
    -- Clamp X velocity
    if self.xVelocity > self.maxSpeed then self.xVelocity = self.maxSpeed end
    if self.xVelocity < -self.maxSpeed then self.xVelocity = -self.maxSpeed end
    
    -- Handle Jumping
    if pd.buttonJustPressed(pd.kButtonUp) and self.grounded then
        self.yVelocity = self.jumpForce
    end
    
    -- State Machine for Animation
    local nextAnimation = self.currentAnimation
    
    if not self.grounded then
        nextAnimation = self.animations.jump
    elseif self.xVelocity ~= 0 then
        nextAnimation = self.animations.run
    else
        nextAnimation = self.animations.idle
    end
    
    -- If we switched animations, reset the new one so it starts from frame 1
    if nextAnimation ~= self.currentAnimation then
        nextAnimation.frame = nextAnimation.startFrame
        self.currentAnimation = nextAnimation
    end
    
    -- Apply the current frame image
    self:setImage(self.currentAnimation:image())
    
    -- Apply flipping
    if self.facingRight then
        self:setImageFlip(gfx.kImageUnflipped)
    else
        self:setImageFlip(gfx.kImageFlippedX)
    end
    
    -- Movement and Collisions
    local targetX = self.x + self.xVelocity
    local targetY = self.y + self.yVelocity
    self.grounded = false
    local actualX, actualY, collisions, length = self:moveWithCollisions(targetX, targetY)
    
    if length > 0 then
        for i=1, length do
            local collision = collisions[i]
            if collision.normal.y < 0 then
                self.yVelocity = 0
                self.grounded = true
            elseif collision.normal.y > 0 then
                self.yVelocity = 0
            end
        end
    end
end
