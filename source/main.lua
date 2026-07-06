import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "scripts/World"
import "scripts/Player"
import "scripts/UIManager"
import "scripts/MessageBox"
import "scripts/Sign"

local gfx = playdate.graphics

-- Setting the background color to white automatically clears the screen every frame for us!
gfx.setBackgroundColor(gfx.kColorWhite)

-- Instantiate our world (the floor) first
local world = World()

-- Instantiate two test Signs right next to each other
local sign1 = Sign(250, 192, "Sign 1: I am the left sign!")
local sign2 = Sign(270, 192, "Sign 2: I am the right sign!")

-- Instantiate our player in the center of the screen (make it global)
_G.player = Player(200, 100)

function playdate.update()
    -- CAMERA LOGIC:
    -- We want the player to always be in the center of the screen (X: 200, Y: 120)
    -- So we calculate how far the player has moved from the center, and shift the entire drawing canvas in the opposite direction!
    local offsetX = 200 - _G.player.x
    local offsetY = 120 - _G.player.y
    
    -- Apply the offset to the graphics context
    gfx.setDrawOffset(offsetX, offsetY)

    -- This function tells the Playdate engine to draw all active sprites to the screen
    gfx.sprite.update()
    
    -- Draw subtle interaction indicator above the interactable item
    if _G.player.currentInteractable and not UIManager.isUIActive() then
        local ix = _G.player.currentInteractable.x
        local iy = _G.player.currentInteractable.y
        local _, _, width, height = _G.player.currentInteractable:getBounds()
        
        -- Because the sign is anchored at (0.5, 1.0), 'iy' is its bottom coordinate.
        -- We calculate its top coordinate to draw the indicator just above it.
        local topY = iy - height - 6
        
        -- Draw a small inverted triangle
        gfx.drawLine(ix - 2, topY, ix + 2, topY)
        gfx.drawLine(ix - 1, topY + 1, ix + 1, topY + 1)
        gfx.drawPixel(ix, topY + 2)
    end
end
