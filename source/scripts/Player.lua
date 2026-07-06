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
    self.jumpForce = -10
    self.runSpeed = 4
end

function Player:update()
    -- Apply Gravity to our vertical velocity every frame
    self.yVelocity = self.yVelocity + self.gravity
    
    -- Reset horizontal velocity every frame unless a button is held
    self.xVelocity = 0
    
    -- Handle D-Pad Input
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.runSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.runSpeed
    end
    
    -- Handle Jumping
    if pd.buttonJustPressed(pd.kButtonA) then
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
            if collision.normal.y ~= 0 then -- Hit the floor or ceiling
                self.yVelocity = 0
            end
        end
    end
    
    -- Quick hack to keep the player from falling off the bottom of the screen
    -- (We will remove this when we add a real floor in Step 3!)
    if actualY > 200 then
        self:moveTo(actualX, 200)
        self.yVelocity = 0
    end
end
