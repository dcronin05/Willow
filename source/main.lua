import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "scripts/World"
import "scripts/Player"

local gfx = playdate.graphics

-- Setting the background color to white automatically clears the screen every frame for us!
gfx.setBackgroundColor(gfx.kColorWhite)

-- Instantiate our world (the floor) first
local world = World()

-- Instantiate our player in the center of the screen
local player = Player(200, 100)

function playdate.update()
    -- CAMERA LOGIC:
    -- We want the player to always be in the center of the screen (X: 200, Y: 120)
    -- So we calculate how far the player has moved from the center, and shift the entire drawing canvas in the opposite direction!
    local offsetX = 200 - player.x
    local offsetY = 120 - player.y
    
    -- Apply the offset to the graphics context
    gfx.setDrawOffset(offsetX, offsetY)

    -- This function tells the Playdate engine to draw all active sprites to the screen
    gfx.sprite.update()
end
