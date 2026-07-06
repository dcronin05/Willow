import "CoreLibs/animation"
import "scripts/Interactable"
import "scripts/Character"

---@class Player
--- The Player class handles input, animation states, and environment interactions.
--- It inherits from the Character base class, which handles physics and health.

local pd = playdate
local gfx = pd.graphics

class('Player').extends(Character)

--- Initializes a new Player instance at the given world coordinates.
---@param x number The starting X position in pixels.
---@param y number The starting Y position in pixels.
function Player:init(x, y)
    -- Initialize the base Character class (handles coordinates, faction, and physics setup)
    Player.super.init(self, x, y, "player")
    
    -- ==========================================
    -- ANIMATION SETUP
    -- ==========================================
    local imageTable = gfx.imagetable.new("images/player")
    self.animations = {
        idle = gfx.animation.loop.new(200, imageTable, true),
        run = gfx.animation.loop.new(100, imageTable, true),
        jump = gfx.animation.loop.new(100, imageTable, true)
    }
    
    self.animations.idle.startFrame, self.animations.idle.endFrame = 1, 1
    self.animations.run.startFrame, self.animations.run.endFrame = 2, 5
    self.animations.jump.startFrame, self.animations.jump.endFrame = 6, 6
    
    self.currentAnimation = self.animations.idle
    self:setImage(self.currentAnimation:image())
    
    -- Define the physical bounding box for collisions. 
    self:setCollideRect(0, 0, 16, 28)
    self:setZIndex(10)
    
    self:add()
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
        self.xVelocity = self.xVelocity * self.friction
    end
    
    self.xVelocity = math.max(-self.maxSpeed, math.min(self.maxSpeed, self.xVelocity))
    
    if pd.buttonJustPressed(pd.kButtonUp) and self.grounded then
        self.yVelocity = self.jumpForce
    end
    
    -- ==========================================
    -- 2. PHYSICS (Via Base Class)
    -- ==========================================
    -- Applies gravity, resolves floor/wall collisions, and updates self.grounded
    self:applyPhysics()
    
    -- ==========================================
    -- 3. ANIMATION STATE MACHINE
    -- ==========================================
    -- Defers to the base Character class to evaluate grounded/velocity and swap animations
    self:updateAnimation()
    
    -- ==========================================
    -- 4. INTERACTION DETECTION (VISION BOX)
    -- ==========================================
    self.currentInteractable = nil
    
    if not UIManager.isUIActive() then
        local visionX = self.x
        local visionWidth = 32
        
        if not self.facingRight then
            visionX = self.x - 32
        end
        
        local sprites = gfx.sprite.querySpritesInRect(visionX, self.y, visionWidth, 32)
        local closestDist = math.huge
        local bestInteractable = nil
        
        for i=1, #sprites do
            if sprites[i].isInteractable then
                local dist = math.abs(self.x - sprites[i].x)
                if dist < closestDist then
                    closestDist = dist
                    bestInteractable = sprites[i]
                end
            end
        end
        
        if bestInteractable then
            self.currentInteractable = bestInteractable
            
            if pd.buttonJustPressed(pd.kButtonA) then
                self.currentInteractable:onInteract()
            end
        end
    end
end
