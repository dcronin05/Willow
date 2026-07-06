import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "scripts/LDtk"
import "scripts/World"
import "scripts/Player"
import "scripts/UIManager"
import "scripts/MessageBox"
import "scripts/Sign"

local gfx = playdate.graphics

-- Setting the background color to white automatically clears the screen every frame for us!
gfx.setBackgroundColor(gfx.kColorWhite)

-- Load LDtk project
LDtk.load("levels/world.ldtk")

-- Instantiate our world which builds the tilemaps and spawns the LDtk entities
local world = World("Room_1")

function playdate.update()
    -- CAMERA LOGIC:
    if _G.player then
        local offsetX = 200 - _G.player.x
        local offsetY = 120 - _G.player.y
        gfx.setDrawOffset(offsetX, offsetY)
    end

    -- This function tells the Playdate engine to draw all active sprites to the screen
    gfx.sprite.update()
    
    -- Draw subtle interaction indicator above the interactable item
    if _G.player and _G.player.currentInteractable and not UIManager.isUIActive() then
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
