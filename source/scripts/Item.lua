local pd = playdate
local gfx = pd.graphics

import "scripts/Interactable"
import "scripts/ItemDatabase"

class('Item').extends(Interactable)

--- Initializes a physical item in the world
---@param x number X coordinate
---@param y number Y coordinate
---@param itemId string The ID matching ItemDatabase
---@param uid string Unique ID (or LDtk iid)
---@param isDropping boolean True if it just exploded out of an enemy/chest
function Item:init(x, y, itemId, uid, isDropping)
    Item.super.init(self, x, y)
    
    self.itemId = itemId
    self.uid = uid
    self.isDropping = isDropping or false
    
    -- Load item properties from database
    local itemData = ItemDatabase[itemId]
    if itemData then
        self.targetName = itemData.name
        local img = gfx.image.new(itemData.imagePath)
        if img then
            self:setImage(img)
            self:setCenter(0.5, 1) -- anchor to feet
            
            -- Set up collision box to match sprite exactly (no ground blending for tiny items)
            self:setCollideRect(0, 0, self:getSize())
        else
            print("WARNING: Could not load item image for " .. itemId)
        end
    end
    
    -- Pop out physics setup
    if self.isDropping then
        self.startY = y
        self.yVelocity = -6 -- Shoot up
        self.xVelocity = (math.random() - 0.5) * 6 -- Random left/right
        self.gravity = 0.5
        -- Ensure it draws above characters while dropping
        self:setZIndex(20) 
    else
        self:setZIndex(1) -- Lie flat on the ground
    end
end

function Item:update()
    if self.isDropping then
        self.yVelocity = self.yVelocity + self.gravity
        self:moveBy(self.xVelocity, self.yVelocity)
        
        -- Did we land?
        if self.y >= self.startY then
            self:moveTo(self.x, self.startY)
            self.isDropping = false
            self:setZIndex(1)
            
            -- Lock it into the world spreadsheet permanently
            SaveManager.registerDroppedItem(self.uid, self.itemId, self.x, self.y)
        end
    end
end

function Item:onInteract()
    -- Only pick up if it's not mid-air
    if self.isDropping then return end
    
    local itemData = ItemDatabase[self.itemId]
    print("Picked up: " .. itemData.name)
    
    -- Add to player spreadsheet
    SaveManager.addItem("player", self.itemId, 1)
    
    -- If this item was placed via LDtk, it might have an LDtk iid instead of a normal uid
    -- We can safely flag it as killed just in case, so LDtk doesn't respawn it.
    SaveManager.setEntityKilled(self.uid)
    
    -- Remove from dynamic dropped items spreadsheet
    SaveManager.removeDroppedItem(self.uid)
    
    -- Delete the sprite
    self:remove()
end
