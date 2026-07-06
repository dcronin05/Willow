local gfx = playdate.graphics

class('World').extends()

function World:init()
    -- Create a solid floor sprite
    local floor = gfx.sprite.new()
    
    -- Make the floor span the entire width of the screen, and 40 pixels tall
    local floorImage = gfx.image.new(400, 40, gfx.kColorBlack)
    floor:setImage(floorImage)
    
    -- Position it at the bottom of the screen
    -- (Y=220 is the exact center of a 40px tall block resting at the bottom of a 240px screen)
    floor:moveTo(200, 220)
    
    -- Give it a collision rect matching the image size
    floor:setCollideRect(0, 0, floor:getSize())
    
    -- Add it to the active sprite list
    floor:add()
end
