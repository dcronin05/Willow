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
---@param spawnX number (Optional) The original LDtk X spawn point to respawn at.
---@param spawnY number (Optional) The original LDtk Y spawn point to respawn at.
function Player:init(x, y, spawnX, spawnY)
    -- Initialize the base Character class (handles coordinates, faction, and physics setup)
    Player.super.init(self, x, y, "player")
    
    -- Save our spawn point for respawning on death
    self.spawnX = spawnX or x
    self.spawnY = spawnY or y
    
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
    
    -- Configure the standard 2.5D physical bounding box for collisions. 
    self:setupCollision(16, 32)
    self:setZIndex(10)
    
    self:add()
end

--- Called automatically every frame by the Playdate sprite system.
function Player:update()
    
    -- ==========================================
    -- 1. INPUT HANDLING
    -- ==========================================
    if not UIManager.isUIActive() then
        if pd.buttonIsPressed(pd.kButtonLeft) then
            self.xVelocity = self.xVelocity - self.acceleration
            self.facingRight = false
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self.xVelocity = self.xVelocity + self.acceleration
            self.facingRight = true
        else
            self.xVelocity = self.xVelocity * self.friction
        end
        
        if pd.buttonJustPressed(pd.kButtonUp) and self.grounded then
            self.yVelocity = self.jumpForce
        end
        
        if pd.buttonJustPressed(pd.kButtonB) then
            if UIManager.showInventory then
                UIManager.showInventory()
            end
        end
    else
        -- If UI is active, force the player to slide to a stop.
        self.xVelocity = self.xVelocity * self.friction
    end
    
    self.xVelocity = math.max(-self.maxSpeed, math.min(self.maxSpeed, self.xVelocity))
    
    -- ==========================================
    -- 2. PHYSICS (Via Base Class)
    -- ==========================================
    -- Applies gravity, resolves floor/wall collisions, and updates self.grounded
    self:applyPhysics()
    
    -- ==========================================
    -- 3. ANIMATION STATE MACHINE
    -- ==========================================
    
    -- Allow the base Character to evaluate physics and update the current animation frame
    Player.super.updateAnimation(self)
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
        
        -- Shift Y up by 32 so we scan the player's body height, not underground!
        local sprites = gfx.sprite.querySpritesInRect(visionX, self.y - 32, visionWidth, 32)
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
        
        self.currentInteractable = bestInteractable
        
        -- Press A to Interact or Attack!
        if pd.buttonJustPressed(pd.kButtonA) then
            if self.currentInteractable then
                self.currentInteractable:onInteract()
            else
                -- DEBUG: Attack nearest enemy in front of us
                for i=1, #sprites do
                    if sprites[i].className == "Enemy" then
                        sprites[i]:takeDamage(50, self.x)
                        break
                    end
                end
            end
        end
    end
end

--- Overrides the base Character death to respawn the player instantly.
function Player:die()
    print("Player died! Respawning at " .. self.spawnX .. ", " .. self.spawnY)
    
    -- Reset health and velocity
    self.health = self.maxHealth
    self.xVelocity = 0
    self.yVelocity = 0
    
    -- Move back to spawn
    self:moveTo(self.spawnX, self.spawnY)
    
    -- Give a generous invincibility window so they don't get spawn camped
    self.invincible = true
    pd.timer.performAfterDelay(2000, function()
        self.invincible = false
        self:setVisible(true)
    end)
end
