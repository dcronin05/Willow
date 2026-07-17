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
    
    -- Always allow Left/Right movement, even if the menu is open!
    -- UNLESS a fullscreen UI is open (like the Map)
    if UIManager.activeUI and UIManager.activeUI.isFullScreen then
        self.xVelocity = self.xVelocity * self.friction
    else
        if pd.buttonIsPressed(pd.kButtonLeft) then
            self.xVelocity = self.xVelocity - self.acceleration
            self.facingRight = false
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            self.xVelocity = self.xVelocity + self.acceleration
            self.facingRight = true
        else
            self.xVelocity = self.xVelocity * self.friction
        end
    end
    
    -- Only allow jumping and opening the menu if the UI is NOT active
    if not UIManager.isUIActive() then
        if pd.buttonJustPressed(pd.kButtonUp) and self.grounded then
            self.yVelocity = self.jumpForce
        end
        
        if pd.buttonJustPressed(pd.kButtonB) then
            if UIManager.showInventory then
                UIManager.showInventory()
            end
        end
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
            -- Cooldown Check (Default 500ms if no weapon)
            local now = pd.getCurrentTimeMilliseconds()
            if self.lastAttackTime and (now - self.lastAttackTime) < self.attackCooldown then
                return -- Still on cooldown!
            end
            
            -- Fetch Equipped Weapon from Database
            local weaponId = SaveManager.state.equipment.weapon
            local weapon = ItemDatabase[weaponId]
            
            -- Default bare-hands attack if somehow unarmed
            if not weapon then 
                weapon = { attackType = "melee", damage = 5, range = 20, maxTargets = 1, cooldown = 500 }
            end
            
            self.lastAttackTime = now
            self.attackCooldown = weapon.cooldown or 500
            
            -- If we are standing directly in front of an interactable sign/chest/etc, we interact INSTEAD of attacking
            -- (Unless the currentInteractable is actually an Enemy we want to hit!)
            if self.currentInteractable and self.currentInteractable.className ~= "Enemy" then
                self.currentInteractable:onInteract()
                return
            end
            
            -- ========================================================
            -- HYBRID COMBAT ENGINE
            -- ========================================================
            
            if weapon.attackType == "melee" then
                -- PHYSICAL HITBOX
                -- Determine the hit area based on facing direction and weapon range
                local hitX = self.facingRight and self.x or (self.x - weapon.range)
                local hitY = self.y - 20
                local w = weapon.range
                local h = 40
                
                -- Query all sprites in the attack box
                local hitSprites = gfx.sprite.querySpritesInRect(hitX, hitY, w, h)
                local enemiesHit = {}
                
                for i=1, #hitSprites do
                    local s = hitSprites[i]
                    if s.className == "Enemy" then
                        table.insert(enemiesHit, { sprite = s, dist = math.abs(self.x - s.x) })
                    end
                end
                
                -- Sort by distance so we hit the closest enemies first
                table.sort(enemiesHit, function(a, b) return a.dist < b.dist end)
                
                -- Deal damage up to maxTargets limit
                local maxTargets = weapon.maxTargets or 1
                for i=1, math.min(#enemiesHit, maxTargets) do
                    enemiesHit[i].sprite:takeDamage(weapon.damage, self.x)
                end
                
            elseif weapon.attackType == "projectile" then
                -- RANGED PROJECTILE
                -- Projectile.lua handles its own splash damage on collision!
                Projectile(self.x, self.y - 10, weapon, self.facingRight)
                
            elseif weapon.attackType == "magic" and weapon.requiresTarget then
                -- HOMING / INSTANT TARGET-LOCK MAGIC
                if self.currentInteractable and self.currentInteractable.className == "Enemy" then
                    local target = self.currentInteractable
                    target:takeDamage(weapon.damage, self.x)
                    
                    if weapon.splashRadius and weapon.splashRadius > 0 then
                        -- Deal radial splash damage around the target!
                        local r = weapon.splashRadius
                        local blastSprites = gfx.sprite.querySpritesInRect(target.x - r, target.y - r, r*2, r*2)
                        for i=1, #blastSprites do
                            local s = blastSprites[i]
                            if s.className == "Enemy" and s ~= target then
                                local dist = math.sqrt((s.x - target.x)^2 + (s.y - target.y)^2)
                                if dist <= r then
                                    s:takeDamage(weapon.damage, target.x)
                                end
                            end
                        end
                    end
                else
                    -- Spell fizzles if no target!
                    print("No target for spell!")
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
