local gfx = playdate.graphics

class('World').extends()

function World:init()
    -- Create a solid floor sprite
    local floor = gfx.sprite.new()
    
    -- Make the floor span a massive 2000 pixels wide!
    local floorImage = gfx.image.new(2000, 40, gfx.kColorBlack)
    floor:setImage(floorImage)
    
    -- Position it so the center of the 2000px floor is at X=1000
    floor:moveTo(1000, 220)
    
    -- Give it a collision rect matching the image size
    floor:setCollideRect(0, 0, floor:getSize())
    
    -- Add it to the active sprite list
    floor:add()
end
