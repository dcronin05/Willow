import "CoreLibs/sprites"

local pd = playdate
local gfx = pd.graphics

class('Projectile').extends(gfx.sprite)

--- Initializes a new Projectile.
---@param x number Starting X position.
---@param y number Starting Y position.
---@param weaponDef table The weapon definition from ItemDatabase containing speed, damage, and splashRadius.
---@param facingRight boolean Direction the projectile should travel.
function Projectile:init(x, y, weaponDef, facingRight)
    Projectile.super.init(self)
    
    self.weaponDef = weaponDef
    self.facingRight = facingRight
    self.speed = weaponDef.projectileSpeed or 5
    
    self:moveTo(x, y)
    
    -- Draw a placeholder fireball sprite (just a red circle for now)
    local img = gfx.image.new(12, 12)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(6, 6, 6)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(6, 6, 4)
    gfx.popContext()
    self:setImage(img)
    
    self:setCollideRect(0, 0, 12, 12)
    -- Remove the group filtering so the projectile correctly registers overlaps with Enemies
    
    self:add()
end

-- Override default collision so the projectile doesn't physically push enemies back
function Projectile:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
end

--- Moves the projectile forward and checks for collisions.
function Projectile:update()
    local targetX = self.x + (self.facingRight and self.speed or -self.speed)
    local targetY = self.y
    
    local actualX, actualY, collisions, length = self:moveWithCollisions(targetX, targetY)
    
    if length > 0 then
        -- We hit something!
        for i=1, length do
            local col = collisions[i]
            local other = col.other
            
            if other.className == "Enemy" then
                -- Direct hit!
                other:takeDamage(self.weaponDef.damage, self.x)
                
                -- Splash damage check
                if self.weaponDef.splashRadius and self.weaponDef.splashRadius > 0 then
                    self:explode(other.x, other.y)
                end
                
                self:remove()
                return
            end
            
            -- If we hit a wall/solid
            if not other.className then
                if self.weaponDef.splashRadius and self.weaponDef.splashRadius > 0 then
                    self:explode(actualX, actualY)
                end
                self:remove()
                return
            end
        end
    end
    
    -- Destroy projectile if it flies too far off screen
    if not _G.player or math.abs(self.x - _G.player.x) > 400 then
        self:remove()
    end
end

--- Deals damage to all enemies within the splash radius.
function Projectile:explode(centerX, centerY)
    local r = self.weaponDef.splashRadius
    local sprites = gfx.sprite.querySpritesInRect(centerX - r, centerY - r, r * 2, r * 2)
    
    for i=1, #sprites do
        local sprite = sprites[i]
        if sprite.className == "Enemy" then
            -- Optional: check true distance for circular radius instead of square rect
            local dist = math.sqrt((sprite.x - centerX)^2 + (sprite.y - centerY)^2)
            if dist <= r then
                -- Deal splash damage (can be scaled down if desired, but we do full damage for now)
                sprite:takeDamage(self.weaponDef.damage, centerX)
            end
        end
    end
end
