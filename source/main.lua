import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "scripts/Player"

local gfx = playdate.graphics

-- Setting the background color to white automatically clears the screen every frame for us!
gfx.setBackgroundColor(gfx.kColorWhite)

-- Instantiate our player in the center of the screen
local player = Player(200, 100)

function playdate.update()
    -- This function tells the Playdate engine to draw all active sprites to the screen
    gfx.sprite.update()
end
