---@module 'main'
--- Main entry point for the Willow game engine.
--- Responsible for importing all core dependencies, initializing the game world,
--- handling the main update loop, and managing camera logic.

-- Import Playdate Core Libraries
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"
import "CoreLibs/timer"

-- Import Custom Engine Scripts
import "scripts/World"
import "scripts/Player"
import "scripts/UIManager"
import "scripts/MessageBox"
import "scripts/Sign"
import "scripts/SaveManager"
import "scripts/ItemDatabase"
import "scripts/TreeMenu"
import "scripts/Item"
import "scripts/Projectile"

-- Cache the graphics API for performance
local gfx = playdate.graphics

-- Setting the background color to white automatically clears the screen every frame for us!
gfx.setBackgroundColor(gfx.kColorWhite)

-- Initialize the SaveManager to read any existing save data from flash storage
SaveManager.loadGame()

-- DEBUG: Give the player 22 silver coins for testing the new currency system
if not SaveManager.state.inventories["player"] or not SaveManager.state.inventories["player"].items["silver_coin"] then
    SaveManager.addItem("player", "silver_coin", 22)
end

-- Instantiate our world which natively parses the LDtk JSON and spawns entities
-- By default, LDtk names the first room "Level_0" using its auto-identifier logic.
local world = World("Level_0")

--- Main game loop called by the Playdate OS every frame (typically 30 or 50 fps).
--- This handles camera math, sprite updates, and custom interaction UI.
function playdate.update()
    
    -- ==========================================
    -- CAMERA LOGIC
    -- ==========================================
    if _G.player and world then
        -- We calculate a target camera offset that would perfectly center the player on screen.
        -- 200 is half the screen width (400 / 2), 120 is half the screen height (240 / 2).
        local targetX = 200 - _G.player.x
        local targetY = 120 - _G.player.y
        
        -- We must clamp the camera so it doesn't scroll past the boundaries of the level!
        -- If the level is 400x240, minOffsetX and minOffsetY will be 0, locking the camera in place.
        local minOffsetX = math.min(0, 400 - world.width)
        local minOffsetY = math.min(0, 240 - world.height)
        
        -- Apply the clamp. math.min(0, targetX) ensures we never scroll past the left/top edges.
        local offsetX = math.max(minOffsetX, math.min(0, targetX))
        local offsetY = math.max(minOffsetY, math.min(0, targetY))
        
        -- Apply the calculated offset to the Playdate graphics context
        gfx.setDrawOffset(offsetX, offsetY)
    end

    -- ==========================================
    -- UPDATE ENGINES
    -- ==========================================
    
    -- This function tells the Playdate engine to process movement, animations, 
    -- and collisions for all active sprites, and then draws them to the screen.
    gfx.sprite.update()
    playdate.timer.updateTimers()
    
    -- ==========================================
    -- CUSTOM RENDER OVERLAYS
    -- ==========================================
    
    -- Draw a subtle interaction indicator (an inverted triangle) hovering above the interactable item
    -- We only draw this if the player is currently within range of an interactable AND the UI isn't already active.
    if _G.player and _G.player.currentInteractable and not UIManager.isUIActive() then
        -- Get the coordinates and dimensions of the interactable object
        local ix = _G.player.currentInteractable.x
        local iy = _G.player.currentInteractable.y
        
        gfx.setColor(gfx.kColorBlack)
        gfx.fillTriangle(ix - 4, iy - 20, ix + 4, iy - 20, ix, iy - 12)
    end
    
    -- ==========================================
    -- HUD RENDERING (Screen Space)
    -- ==========================================
    
    -- Save current draw offset so we can draw HUD on top of screen, not world
    local offsetX, offsetY = gfx.getDrawOffset()
    gfx.setDrawOffset(0, 0)
    
    UIManager.drawHUD()
    
    -- Restore draw offset for anything else that might draw in world space
    gfx.setDrawOffset(offsetX, offsetY)
    
    -- ==========================================
    
    -- Check for global pause menu / debug overlay toggles here if needed.
end

-- ==========================================
-- OS LIFECYCLE HOOKS
-- ==========================================
-- These functions are automatically called by the Playdate OS when the game is 
-- interrupted or closed, ensuring we save state without dropping frames during gameplay.

function playdate.gameWillTerminate()
    SaveManager.saveGame()
end

function playdate.deviceWillSleep()
    SaveManager.saveGame()
end

function playdate.deviceWillLock()
    SaveManager.saveGame()
end
