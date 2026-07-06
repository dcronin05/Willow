local pd = playdate
local gfx = pd.graphics

-- Define the Player class extending playdate.graphics.sprite
class('Player').extends(gfx.sprite)

function Player:init(x, y)
    -- Initialize the parent sprite class
    Player.super.init(self)
    
    -- Create a simple 16x32 black rectangle as a placeholder image for our player
    local playerImage = gfx.image.new(16, 32, gfx.kColorBlack)
    self:setImage(playerImage)
    
    -- Move the sprite to the starting coordinates
    self:moveTo(x, y)
    
    -- Define the collision box (the whole 16x32 image)
    self:setCollideRect(0, 0, self:getSize())
    
    -- Tell the game engine to actually add this sprite to the active update loop
    self:add()

    -- Physics Variables
    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 1.0
    self.jumpForce = -15
    self.acceleration = 1.5
    self.maxSpeed = 5
    self.friction = 0.75 -- 1.0 is no friction, 0.0 is instant stop
    
    -- State Variables
    self.grounded = false
end

function Player:collisionResponse(other)
    -- This tells the physics engine that when we hit something solid (like the floor),
    -- we should slide along it rather than bouncing or stopping completely.
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    -- Apply Gravity
    self.yVelocity = self.yVelocity + self.gravity
    
    -- Reset grounded state every frame; collisions will turn it back on if we hit the floor
    self.grounded = false
    
    -- Handle D-Pad Input (Acceleration)
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = self.xVelocity - self.acceleration
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.xVelocity + self.acceleration
    else
        -- Apply Friction when not holding left/right
        self.xVelocity = self.xVelocity * self.friction
        -- Snap to 0 if moving very slowly to prevent infinite micro-sliding
        if math.abs(self.xVelocity) < 0.1 then self.xVelocity = 0 end
    end
    
    -- Clamp X velocity to maxSpeed
    if self.xVelocity > self.maxSpeed then self.xVelocity = self.maxSpeed end
    if self.xVelocity < -self.maxSpeed then self.xVelocity = -self.maxSpeed end
    
    -- Handle Jumping (Only if grounded!)
    if pd.buttonJustPressed(pd.kButtonA) and self.grounded then
        self.yVelocity = self.jumpForce
    end
    
    -- Calculate where the player *wants* to go this frame
    local targetX = self.x + self.xVelocity
    local targetY = self.y + self.yVelocity
    
    -- self:moveWithCollisions tries to move the player, but stops if it hits a wall/floor
    -- For now, since we have no walls, it will just move freely!
    local actualX, actualY, collisions, length = self:moveWithCollisions(targetX, targetY)
    
    -- If we hit the floor (or ceiling), we need to stop accelerating downwards (or upwards)
    if length > 0 then
        for i=1, length do
            local collision = collisions[i]
            if collision.normal.y < 0 then
                -- Normal pointing up (-1) means we hit the top of something (a floor)
                self.yVelocity = 0
                self.grounded = true
            elseif collision.normal.y > 0 then
                -- Normal pointing down (1) means we hit the bottom of something (a ceiling)
                self.yVelocity = 0
            end
        end
    end
end
