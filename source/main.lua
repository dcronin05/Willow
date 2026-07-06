import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics

-- Setting the background color to white automatically clears the screen every frame for us!
gfx.setBackgroundColor(gfx.kColorWhite)

function playdate.update()
    -- This function tells the Playdate engine to draw all active sprites to the screen
    gfx.sprite.update()
end
